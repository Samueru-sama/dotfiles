#include <X11/Xlib.h>
#include <X11/Xutil.h>
#include <X11/Xatom.h>
#include <GL/gl.h>
#include <GL/glx.h>
#include <pulse/simple.h>
#include <pulse/error.h>
#include <signal.h>
#include <string.h>
#include <stdio.h>
#include <math.h>
#include <stdlib.h>
#include <unistd.h>
#include <Imlib2.h>

// CPU usage is lower with 8192 than with 4096, compiler bug most likely
#define N 8192
#define RATE 44100

static volatile int running = 1;
static void sigint(int s) { running = 0; }

static float clamp(float x, float lo, float hi) {
    return x < lo ? lo : x > hi ? hi : x;
}

static char *pactl_monitor(void) {
    FILE *f = popen("pactl info 2>/dev/null", "r");
    if (!f) return NULL;
    char s[256] = {0}, l[256];
    while (fgets(l, 256, f))
        if (sscanf(l, "Default Sink: %255s", s) == 1) break;
    pclose(f);
    if (!s[0]) return NULL;
    int n = strlen(s) + 10;
    char *m = malloc(n);
    snprintf(m, n, "%s.monitor", s);
    return m;
}

struct state {
    Display   *dpy;
    Window     root, win;
    int        W, H, scr;
    Atom       xroot, eroot;
    Colormap   cmap;
    XVisualInfo *vi;
    GLXContext ctx;
    GLuint    tex;
    Pixmap    pm[2];
    GLXPixmap glxp[2];
    int       cur;

pa_simple   *pa;
    int   nbars;
    float *bars, *peaks;
    float *re, *im, *buf;
    float *mag;
    float *tw_re, *tw_im;
    int   *barv, *peakv;
    float *hann;
    int   *bar_ilo, *bar_ihi;
    float *bar_fc, *bar_norm, *bar_pre;

    int     first;
    int16_t raw[N];
};

static void sampling(struct state *s)
{
    int new_n = N / 8;
    if (s->first) {
        pa_simple_read(s->pa, s->raw, sizeof(s->raw), NULL);
        s->first = 0;
    } else {
        memmove(s->raw, s->raw + new_n, (N - new_n) * sizeof(int16_t));
        pa_simple_read(s->pa, s->raw + N - new_n, new_n * sizeof(int16_t), NULL);
    }
    for (int i = 0; i < N; i++)
        s->buf[i] = s->raw[i] / 32768.0f;
}

static void cfft(float *restrict re, float *restrict im, int n)
{
    static const float wr[] = {
        -1.f, 0.f, 0.707107f, 0.92388f, 0.980785f, 0.995185f,
        0.998795f, 0.999699f, 0.999925f, 0.999981f,
        0.999995f, 0.999999f, 1.f
    };
    static const float wi[] = {
        0.f, -1.f, -0.707107f, -0.382683f, -0.19509f, -0.0980171f,
        -0.0490677f, -0.0245412f, -0.0122715f, -0.00613588f,
        -0.00306796f, -0.00153398f, -0.00076699f
    };
    for (int i = 1, j = 0; i < n; i++) {
        int b = n >> 1;
        for (; j & b; b >>= 1) j ^= b;
        j ^= b;
        if (i < j) {
            float t = re[i]; re[i] = re[j]; re[j] = t;
            t = im[i]; im[i] = im[j]; im[j] = t;
        }
    }
    for (int s = 0, len = 2; len <= n; len <<= 1, s++) {
        float wnr = wr[s], wni = wi[s];
        for (int i = 0; i < n; i += len) {
            float w = 1, wI = 0;
            for (int k = 0; k < len / 2; k++) {
                int a = i + k, b = i + k + len / 2;
                float tr = w * re[b] - wI * im[b], ti = w * im[b] + wI * re[b];
                re[b] = re[a] - tr; im[b] = im[a] - ti;
                re[a] += tr; im[a] += ti;
                float nw = w * wnr - wI * wni;
                wI = w * wni + wI * wnr; w = nw;
            }
        }
    }
}

static void fft(float *restrict re, float *restrict im, int n,
                const float *restrict tw_r, const float *restrict tw_i)
{
    int nh = n / 2;
    for (int i = 0; i < nh; i++) {
        float a = re[2*i], b = re[2*i+1];
        re[i] = a;
        im[i] = b;
    }
    cfft(re, im, nh);
    float dc = re[0] + im[0], ny = re[0] - im[0];
    im[0] = 0;
    re[0] = dc;
    re[nh] = ny;
    im[nh] = 0;
    for (int k = 1; k <= nh / 2; k++) {
        int k2 = nh - k;
        float Hkr = re[k], Hki = im[k];
        float Hk2r = re[k2], Hk2i = im[k2];
        float Ar = 0.5f * (Hkr + Hk2r);
        float Ai = 0.5f * (Hki - Hk2i);
        float Br = 0.5f * (Hki + Hk2i);
        float Bi = 0.5f * (Hk2r - Hkr);
        float w = tw_r[k], wi = tw_i[k];
        re[k] = Ar + w * Br - wi * Bi;
        im[k] = Ai + w * Bi + wi * Br;
        if (k != k2) {
            float w2 = tw_r[k2], wi2 = tw_i[k2];
            re[k2] = Ar + w2 * Br - wi2 * (-Bi);
            im[k2] = -Ai + w2 * (-Bi) + wi2 * Br;
        }
    }
}

static void calculate(struct state *s)
{
    int nb = s->nbars, N2 = N / 2;

    int silent = 0;
    int new_n = N / 8;
    float e = 0;
    for (int i = 0; i < new_n; i++)
        e += fabsf(s->buf[N - new_n + i]);
    e /= new_n;
    if (e < 0.001f)
        silent = 1;

    if (silent) {
        for (int b = 0; b < nb; b++)
            s->bars[b] *= .82f;
    } else {
        for (int i = 0; i < N; i++)
            s->re[i] = s->buf[i] * s->hann[i];
        fft(s->re, s->im, N, s->tw_re, s->tw_im);
        for (int i = 0; i < N2; i++)
            s->mag[i] = sqrtf(s->re[i]*s->re[i] + s->im[i]*s->im[i]);
        for (int b = 0; b < nb; b++) {
            int ilo = s->bar_ilo[b], ihi = s->bar_ihi[b];
            if (b == nb - 1) ihi = N2 - 1;
            float sum = 0;
            for (int i = ilo; i <= ihi; i++)
                sum += s->mag[i];
            float n = ihi - ilo + 1;
            float db = 6.0206f * log2f(sum / n / N + 1e-10f);
            if (b == nb - 1) db += 6.0f;
            db += s->bar_pre[b];
            float v = clamp((db + 70.0f) / 100.0f, 0, 1);
            s->bars[b] = s->bars[b] * .82f + v * .18f;
        }
    }

    {
        float prev = s->bars[0];
        for (int b = 0; b < nb; b++) {
            float cur = s->bars[b];
            float next = b + 1 < nb ? s->bars[b + 1] : cur;
            s->bars[b] = prev * .15f + cur * .7f + next * .15f;
            prev = cur;
        }
    }
}

static void render(struct state *s)
{
    int nb = s->nbars;

    glXMakeCurrent(s->dpy, s->glxp[s->cur], s->ctx);
    if (s->tex) {
        glClear(GL_COLOR_BUFFER_BIT);
        glEnable(GL_TEXTURE_2D);
        glBindTexture(GL_TEXTURE_2D, s->tex);
        glColor4f(1, 1, 1, 1);
        glBegin(GL_QUADS);
            glTexCoord2f(0, 0); glVertex2i(0, 0);
            glTexCoord2f(1, 0); glVertex2i(s->W, 0);
            glTexCoord2f(1, 1); glVertex2i(s->W, s->H);
            glTexCoord2f(0, 1); glVertex2i(0, s->H);
        glEnd();
        glDisable(GL_TEXTURE_2D);
    } else {
        glClearColor(0.03f, 0.03f, 0.06f, 1.0f);
        glClear(GL_COLOR_BUFFER_BIT);
    }

    int base = s->H;
    float step = (float)s->W / nb;
    for (int b = 0; b < nb; b++) {
        if (s->bars[b] >= s->peaks[b])
            s->peaks[b] = s->bars[b];
        else
            s->peaks[b] *= 0.92f;
        int x = b * step;
        int x2 = (b + 1) * step - 1;
        int bh = s->bars[b] * base * 0.65;
        if (x2 < x) x2 = x;
        int j = b * 8;
        s->barv[j]   = x;   s->barv[j+1] = base;
        s->barv[j+2] = x2;  s->barv[j+3] = base;
        s->barv[j+4] = x2;  s->barv[j+5] = base - bh;
        s->barv[j+6] = x;   s->barv[j+7] = base - bh;
        int ph = s->peaks[b] * base * 0.65;
        s->peakv[j]   = x;   s->peakv[j+1] = base - ph + 1;
        s->peakv[j+2] = x2;  s->peakv[j+3] = base - ph + 1;
        s->peakv[j+4] = x2;  s->peakv[j+5] = base - ph - 1;
        s->peakv[j+6] = x;   s->peakv[j+7] = base - ph - 1;
    }
    glEnableClientState(GL_VERTEX_ARRAY);
    glVertexPointer(2, GL_INT, 0, s->barv);
    glColor4f(0.0120f, 0.0450f, 0.0800f, 0.7f);
    glDrawArrays(GL_QUADS, 0, nb * 4);
    glVertexPointer(2, GL_INT, 0, s->peakv);
    glColor4f(0.992f, 0.737f, 0.294f, 0.9f);
    glDrawArrays(GL_QUADS, 0, nb * 4);
    glDisableClientState(GL_VERTEX_ARRAY);
    glFlush();

    XSetWindowBackgroundPixmap(s->dpy, s->root, s->pm[s->cur]);
    { unsigned long d = s->pm[s->cur];
      XChangeProperty(s->dpy, s->root, s->xroot, XA_PIXMAP, 32,
                      PropModeReplace, (unsigned char *)&d, 1);
      XChangeProperty(s->dpy, s->root, s->eroot, XA_PIXMAP, 32,
                      PropModeReplace, (unsigned char *)&d, 1); }
    XClearWindow(s->dpy, s->root);
    XFlush(s->dpy);

    s->cur = 1 - s->cur;
}

int main(int argc, char *argv[])
{
    signal(SIGINT, sigint);
    signal(SIGTERM, sigint);

    struct state S = {0};
    S.first = 1;

    S.dpy = XOpenDisplay(NULL);
    if (!S.dpy) return 1;
    S.scr = DefaultScreen(S.dpy);
    S.root = RootWindow(S.dpy, S.scr);
    S.W = DisplayWidth(S.dpy, S.scr);
    S.H = DisplayHeight(S.dpy, S.scr);
    fprintf(stderr, "Root window: %dx%d\n", S.W, S.H);

    S.xroot = XInternAtom(S.dpy, "_XROOTPMAP_ID", False);
    S.eroot = XInternAtom(S.dpy, "ESETROOT_PMAP_ID", False);

    char *mon = pactl_monitor();
    if (!mon) { fprintf(stderr, "No PulseAudio monitor\n"); return 1; }
    {
        pa_sample_spec ss = {PA_SAMPLE_S16NE, RATE, 1};
        int err;
        S.pa = pa_simple_new(NULL, "spectrum", PA_STREAM_RECORD, mon,
                             "analyzer", &ss, NULL, NULL, &err);
        free(mon);
        if (!S.pa) { fprintf(stderr, "pa_simple_new failed\n"); return 1; }
    }

    {
        int glx_attrs[] = {GLX_RGBA, GLX_RED_SIZE,8, GLX_GREEN_SIZE,8,
                           GLX_BLUE_SIZE,8, GLX_DEPTH_SIZE,0, None};
        S.vi = glXChooseVisual(S.dpy, S.scr, glx_attrs);
        if (!S.vi) { fprintf(stderr, "glXChooseVisual failed\n"); return 1; }
        S.cmap = XCreateColormap(S.dpy, S.root, S.vi->visual, AllocNone);
        XSetWindowAttributes swa = {.colormap = S.cmap, .border_pixel = 0};
        S.win = XCreateWindow(S.dpy, S.root, 0, 0, S.W, S.H, 0, S.vi->depth,
                              InputOutput, S.vi->visual, CWColormap | CWBorderPixel, &swa);
        S.ctx = glXCreateContext(S.dpy, S.vi, NULL, True);
        if (!S.ctx) { fprintf(stderr, "No GLX context\n"); return 1; }
        S.pm[0] = XCreatePixmap(S.dpy, S.root, S.W, S.H, S.vi->depth);
        S.pm[1] = XCreatePixmap(S.dpy, S.root, S.W, S.H, S.vi->depth);
        S.glxp[0] = glXCreateGLXPixmap(S.dpy, S.vi, S.pm[0]);
        S.glxp[1] = glXCreateGLXPixmap(S.dpy, S.vi, S.pm[1]);
        if (!S.glxp[0] || !S.glxp[1]) {
            fprintf(stderr, "glXCreateGLXPixmap failed\n"); return 1;
        }
        glXMakeCurrent(S.dpy, S.glxp[0], S.ctx);
        glViewport(0, 0, S.W, S.H);
        glMatrixMode(GL_PROJECTION);
        glLoadIdentity();
        glOrtho(0, S.W, S.H, 0, -1, 1);
        glMatrixMode(GL_MODELVIEW);
        glLoadIdentity();
        glXMakeCurrent(S.dpy, None, NULL);

        if (argc > 1) {
            imlib_set_cache_size(0);
            imlib_context_set_display(S.dpy);
            imlib_context_set_visual(S.vi->visual);
            imlib_context_set_colormap(S.cmap);
            Imlib_Image img = imlib_load_image(argv[1]);
            if (img) {
                imlib_context_set_image(img);
                int iw = imlib_image_get_width(), ih = imlib_image_get_height();
                DATA32 *px = imlib_image_get_data_for_reading_only();
                glXMakeCurrent(S.dpy, S.glxp[0], S.ctx);
                glGenTextures(1, &S.tex);
                glBindTexture(GL_TEXTURE_2D, S.tex);
                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
                glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, iw, ih, 0,
                             GL_BGRA, GL_UNSIGNED_BYTE, px);
                glXMakeCurrent(S.dpy, None, NULL);
                imlib_free_image();
                fprintf(stderr, "Loaded image: %dx%d\n", iw, ih);
            }
        }
    }

    S.nbars = clamp(S.W / 10, 32, 256);
    int nb = S.nbars;
    S.bars  = calloc(nb, sizeof(float));
    S.peaks = calloc(nb, sizeof(float));
    S.re  = malloc(N * sizeof(float));
    S.im  = malloc(N * sizeof(float));
    S.buf = malloc(N * sizeof(float));
    S.mag = malloc(N / 2 * sizeof(float));
    S.tw_re = malloc(N / 2 * sizeof(float));
    S.tw_im = malloc(N / 2 * sizeof(float));
    for (int i = 0; i < N / 2; i++) {
        float a = 2 * M_PI * i / N;
        S.tw_re[i] = cosf(a);
        S.tw_im[i] = -sinf(a);
    }
    S.barv  = malloc(nb * 8 * sizeof(int));
    S.peakv = malloc(nb * 8 * sizeof(int));
    S.hann = malloc(N * sizeof(float));
    for (int i = 0; i < N; i++)
        S.hann[i] = .5f * (1.f - cosf(M_PI * 2 * i / (N - 1)));
    S.bar_ilo  = malloc(nb * sizeof(int));
    S.bar_ihi  = malloc(nb * sizeof(int));
    S.bar_fc   = malloc(nb * sizeof(float));
    S.bar_norm = malloc(nb * sizeof(float));
    S.bar_pre  = malloc(nb * sizeof(float));
    for (int b = 0; b < nb; b++) {
        float lo = 60.0f * powf(250.0f, (float)b / nb);
        float hi = 60.0f * powf(250.0f, (float)(b + 1) / nb);
        S.bar_ilo[b] = clamp((int)(lo * N / RATE), 0, N / 2 - 1);
        S.bar_ihi[b] = clamp((int)(hi * N / RATE), S.bar_ilo[b] + 1, N / 2 - 1);
        S.bar_fc[b] = (lo + hi) * .5f;
        float cnt = S.bar_ihi[b] - S.bar_ilo[b] + 1;
        S.bar_norm[b] = cnt * N;
        S.bar_pre[b] = 5.0f * log2f(S.bar_fc[b] / 1000.0f) + 8.61f;
    }

    while (running) {
        sampling(&S);
        calculate(&S);
        render(&S);
    }

    XDestroyWindow(S.dpy, S.win);
    XFreeColormap(S.dpy, S.cmap);
    glXMakeCurrent(S.dpy, None, NULL);
    if (S.tex) glDeleteTextures(1, &S.tex);
    glXDestroyGLXPixmap(S.dpy, S.glxp[0]);
    glXDestroyGLXPixmap(S.dpy, S.glxp[1]);
    glXDestroyContext(S.dpy, S.ctx);
    XFree(S.vi);
    XFreePixmap(S.dpy, S.pm[0]);
    XFreePixmap(S.dpy, S.pm[1]);
    XSetWindowBackgroundPixmap(S.dpy, S.root, None);
    XClearWindow(S.dpy, S.root);
    XDeleteProperty(S.dpy, S.root, S.xroot);
    XDeleteProperty(S.dpy, S.root, S.eroot);
    XFlush(S.dpy);
    XCloseDisplay(S.dpy);

    pa_simple_free(S.pa);
    free(S.buf); free(S.bars); free(S.peaks); free(S.re); free(S.im);
    free(S.mag); free(S.hann); free(S.bar_ilo); free(S.bar_ihi); free(S.bar_fc);
    free(S.tw_re); free(S.tw_im);
    free(S.bar_norm); free(S.bar_pre);
    free(S.barv); free(S.peakv);
    return 0;
}
