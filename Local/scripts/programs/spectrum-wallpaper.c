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

static void fft(float *restrict re, float *restrict im, int n) {
    for (int i = 1, j = 0; i < n; i++) {
        int b = n >> 1;
        for (; j & b; b >>= 1) j ^= b;
        j ^= b;
        if (i < j) {
            float t = re[i]; re[i] = re[j]; re[j] = t;
            t = im[i]; im[i] = im[j]; im[j] = t;
        }
    }
    for (int len = 2; len <= n; len <<= 1) {
        float wr = cosf(2 * M_PI / len), wi = -sinf(2 * M_PI / len);
        for (int i = 0; i < n; i += len) {
            float w = 1, wI = 0;
            for (int k = 0; k < len / 2; k++) {
                int a = i + k, b = i + k + len / 2;
                float tr = w * re[b] - wI * im[b], ti = w * im[b] + wI * re[b];
                re[b] = re[a] - tr; im[b] = im[a] - ti;
                re[a] += tr; im[a] += ti;
                float nw = w * wr - wI * wi;
                wI = w * wi + wI * wr; w = nw;
            }
        }
    }
}

int main(int argc, char *argv[])
{
    signal(SIGINT, sigint);
    signal(SIGTERM, sigint);

    Display *dpy = XOpenDisplay(NULL);
    if (!dpy) return 1;
    int scr = DefaultScreen(dpy);
    Window root = RootWindow(dpy, scr);
    int W = DisplayWidth(dpy, scr), H = DisplayHeight(dpy, scr);
    fprintf(stderr, "Root window: %dx%d\n", W, H);

    Atom xroot = XInternAtom(dpy, "_XROOTPMAP_ID", False);
    Atom eroot = XInternAtom(dpy, "ESETROOT_PMAP_ID", False);

    int have_monitor = 0;
    pa_simple *pa = NULL;
    float rate = RATE;
    char *mon = pactl_monitor();
    if (mon) {
        pa_sample_spec ss = {PA_SAMPLE_S16NE, RATE, 1};
        int err;
        pa = pa_simple_new(NULL, "spectrum", PA_STREAM_RECORD, mon,
                           "analyzer", &ss, NULL, NULL, &err);
        if (pa) have_monitor = 1;
        free(mon);
    }

    float *buf = malloc(N * sizeof(float));

    int glx_attrs[] = {GLX_RGBA, GLX_RED_SIZE,8, GLX_GREEN_SIZE,8,
                       GLX_BLUE_SIZE,8, GLX_DEPTH_SIZE,0, None};
    XVisualInfo *vi = glXChooseVisual(dpy, scr, glx_attrs);
    if (!vi) { fprintf(stderr, "glXChooseVisual failed\n"); return 1; }

    Colormap cmap = XCreateColormap(dpy, root, vi->visual, AllocNone);
    XSetWindowAttributes swa = {.colormap = cmap, .border_pixel = 0};
    Window win = XCreateWindow(dpy, root, 0, 0, W, H, 0, vi->depth,
        InputOutput, vi->visual, CWColormap | CWBorderPixel, &swa);

    GLXContext ctx = glXCreateContext(dpy, vi, NULL, True);
    if (!ctx) { fprintf(stderr, "No GLX context\n"); return 1; }

    Pixmap pm[2] = {XCreatePixmap(dpy, root, W, H, vi->depth),
                    XCreatePixmap(dpy, root, W, H, vi->depth)};
    GLXPixmap glxp[2];
    glxp[0] = glXCreateGLXPixmap(dpy, vi, pm[0]);
    glxp[1] = glXCreateGLXPixmap(dpy, vi, pm[1]);
    if (!glxp[0] || !glxp[1]) {
        fprintf(stderr, "glXCreateGLXPixmap failed\n"); return 1;
    }

    glXMakeCurrent(dpy, glxp[0], ctx);
    glViewport(0, 0, W, H);
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glOrtho(0, W, H, 0, -1, 1);
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
    glXMakeCurrent(dpy, None, NULL);

    GLuint tex = 0;
    if (argc > 1) {
        imlib_set_cache_size(0);
        imlib_context_set_display(dpy);
        imlib_context_set_visual(vi->visual);
        imlib_context_set_colormap(cmap);
        Imlib_Image img = imlib_load_image(argv[1]);
        if (img) {
            imlib_context_set_image(img);
            int iw = imlib_image_get_width(), ih = imlib_image_get_height();
            DATA32 *px = imlib_image_get_data_for_reading_only();
            glXMakeCurrent(dpy, glxp[0], ctx);
            glGenTextures(1, &tex);
            glBindTexture(GL_TEXTURE_2D, tex);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
            glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, iw, ih, 0,
                         GL_BGRA, GL_UNSIGNED_BYTE, px);
            glXMakeCurrent(dpy, None, NULL);
            imlib_free_image();
            fprintf(stderr, "Loaded image: %dx%d\n", iw, ih);
        }
    }

    int nbars = clamp(W / 10, 32, 256);
    float *bars = calloc(nbars, sizeof(float));
    float *peaks = calloc(nbars, sizeof(float));
    float *re = malloc(N * sizeof(float));
    float *im = malloc(N * sizeof(float));
    int *barv = malloc(nbars * 8 * sizeof(int));
    int *peakv = malloc(nbars * 8 * sizeof(int));

    float *hann = malloc(N * sizeof(float));
    for (int i = 0; i < N; i++)
        hann[i] = .5f * (1.f - cosf(M_PI * 2 * i / (N - 1)));

    int *bar_ilo = malloc(nbars * sizeof(int));
    int *bar_ihi = malloc(nbars * sizeof(int));
    float *bar_fc = malloc(nbars * sizeof(float));
    float *bar_norm = malloc(nbars * sizeof(float));
    float *bar_pre = malloc(nbars * sizeof(float));
    for (int b = 0; b < nbars; b++) {
        float lo = 60.0f * powf(250.0f, (float)b / nbars);
        float hi = 60.0f * powf(250.0f, (float)(b + 1) / nbars);
        bar_ilo[b] = clamp((int)(lo * N / rate), 0, N / 2 - 1);
        bar_ihi[b] = clamp((int)(hi * N / rate), bar_ilo[b] + 1, N / 2 - 1);
        bar_fc[b] = (lo + hi) * .5f;
        float cnt = bar_ihi[b] - bar_ilo[b] + 1;
        bar_norm[b] = cnt * N;
        bar_pre[b] = 5.0f * log2f(bar_fc[b] / 1000.0f) + 8.61f;
    }

    int cur = 0;
    int first = 1;
    while (running) {
        static int16_t raw[N];
        int new_n = N / 8;
        if (first) {
            if (pa) pa_simple_read(pa, raw, sizeof(raw), NULL);
            else {
                static float ph = 0;
                for (int i = 0; i < N; i++) {
                    raw[i] = 32768 * (sinf(ph)*.4f + sinf(ph*2.3f)*.25f
                           + sinf(ph*5.1f)*.15f + sinf(ph*9.7f)*.1f);
                    ph += M_PI * 440.0f / RATE;
                    if (ph > M_PI * 2) ph -= M_PI * 2;
                }
            }
            first = 0;
        } else {
            memmove(raw, raw + new_n, (N - new_n) * sizeof(int16_t));
            if (pa)
                pa_simple_read(pa, raw + N - new_n, new_n * sizeof(int16_t), NULL);
            else {
                static float ph = 0;
                for (int i = 0; i < new_n; i++) {
                    raw[N - new_n + i] = 32768 * (sinf(ph)*.4f
                        + sinf(ph*2.3f)*.25f + sinf(ph*5.1f)*.15f
                        + sinf(ph*9.7f)*.1f);
                    ph += M_PI * 440.0f / RATE;
                    if (ph > M_PI * 2) ph -= M_PI * 2;
                }
            }
        }
        for (int i = 0; i < N; i++) buf[i] = raw[i] / 32768.0f;

        int silent = 0;
        if (have_monitor) {
            float e = 0;
            for (int i = 0; i < new_n; i++)
                e += fabsf(buf[N - new_n + i]);
            e /= new_n;
            if (e < 0.001f)
                silent = 1;
        }

        if (silent) {
            for (int b = 0; b < nbars; b++)
                bars[b] *= .82f;
        } else {
            for (int i = 0; i < N; i++) {
                re[i] = buf[i] * hann[i];
                im[i] = 0;
            }
            fft(re, im, N);
            for (int b = 0; b < nbars; b++) {
                int ilo = bar_ilo[b], ihi = bar_ihi[b];
                if (b == nbars - 1) ihi = N / 2 - 1;
                float sum = 0;
                for (int i = ilo; i <= ihi; i++)
                    sum += sqrtf(re[i]*re[i] + im[i]*im[i]);
                float n = ihi - ilo + 1;
                float db = 20.0f * log10f(sum / n / N + 1e-10f);
                if (b == nbars - 1) db += 6.0f;
                db += bar_pre[b];
                float v = clamp((db + 70.0f) / 100.0f, 0, 1);
                bars[b] = bars[b] * .82f + v * .18f;
            }
        }

        {
            float prev = bars[0];
            for (int b = 0; b < nbars; b++) {
                float cur = bars[b];
                float next = b + 1 < nbars ? bars[b + 1] : cur;
                bars[b] = prev * .15f + cur * .7f + next * .15f;
                prev = cur;
            }
        }

        glXMakeCurrent(dpy, glxp[cur], ctx);
        if (tex) {
            glClear(GL_COLOR_BUFFER_BIT);
            glEnable(GL_TEXTURE_2D);
            glBindTexture(GL_TEXTURE_2D, tex);
            glColor4f(1, 1, 1, 1);
            glBegin(GL_QUADS);
                glTexCoord2f(0, 0); glVertex2i(0, 0);
                glTexCoord2f(1, 0); glVertex2i(W, 0);
                glTexCoord2f(1, 1); glVertex2i(W, H);
                glTexCoord2f(0, 1); glVertex2i(0, H);
            glEnd();
            glDisable(GL_TEXTURE_2D);
        } else {
            glClearColor(0.03f, 0.03f, 0.06f, 1.0f);
            glClear(GL_COLOR_BUFFER_BIT);
        }

        int base = H;
        float step = (float)W / nbars;
        for (int b = 0; b < nbars; b++) {
            if (bars[b] >= peaks[b])
                peaks[b] = bars[b];
            else
                peaks[b] *= 0.92f;
            int x = b * step;
            int x2 = (b + 1) * step - 1;
            int bh = bars[b] * base * 0.65;
            if (x2 < x) x2 = x;
            int j = b * 8;
            barv[j]   = x;  barv[j+1] = base;
            barv[j+2] = x2; barv[j+3] = base;
            barv[j+4] = x2; barv[j+5] = base - bh;
            barv[j+6] = x;  barv[j+7] = base - bh;
            int ph = peaks[b] * base * 0.65;
            peakv[j]   = x;  peakv[j+1] = base - ph + 1;
            peakv[j+2] = x2; peakv[j+3] = base - ph + 1;
            peakv[j+4] = x2; peakv[j+5] = base - ph - 1;
            peakv[j+6] = x;  peakv[j+7] = base - ph - 1;
        }
        glEnableClientState(GL_VERTEX_ARRAY);
        glVertexPointer(2, GL_INT, 0, barv);
        glColor4f(0.0120f, 0.0450f, 0.0800f, 0.7f);
        glDrawArrays(GL_QUADS, 0, nbars * 4);
        glVertexPointer(2, GL_INT, 0, peakv);
        glColor4f(0.992f, 0.737f, 0.294f, 0.9f);
        glDrawArrays(GL_QUADS, 0, nbars * 4);
        glDisableClientState(GL_VERTEX_ARRAY);
        glFlush();

        XSetWindowBackgroundPixmap(dpy, root, pm[cur]);
        { unsigned long d = pm[cur];
          XChangeProperty(dpy, root, xroot, XA_PIXMAP, 32,
                          PropModeReplace, (unsigned char *)&d, 1);
          XChangeProperty(dpy, root, eroot, XA_PIXMAP, 32,
                          PropModeReplace, (unsigned char *)&d, 1); }
        XClearWindow(dpy, root);
        XFlush(dpy);

        cur = 1 - cur;
    }

    XDestroyWindow(dpy, win);
    XFreeColormap(dpy, cmap);
    glXMakeCurrent(dpy, None, NULL);
    if (tex) glDeleteTextures(1, &tex);
    glXDestroyGLXPixmap(dpy, glxp[0]);
    glXDestroyGLXPixmap(dpy, glxp[1]);
    glXDestroyContext(dpy, ctx);
    XFree(vi);
    XFreePixmap(dpy, pm[0]);
    XFreePixmap(dpy, pm[1]);
    XSetWindowBackgroundPixmap(dpy, root, None);
    XClearWindow(dpy, root);
    XDeleteProperty(dpy, root, xroot);
    XDeleteProperty(dpy, root, eroot);
    XFlush(dpy);
    XCloseDisplay(dpy);

    if (pa) pa_simple_free(pa);
    free(buf); free(bars); free(peaks); free(re); free(im);
    free(hann); free(bar_ilo); free(bar_ihi); free(bar_fc); free(bar_norm); free(bar_pre);
    free(barv); free(peakv);
    return 0;
}
