#include <stdio.h>
#include <string.h>
#include <pulse/pulseaudio.h>

static pa_mainloop *mainloop;
static pa_context *context;
static char prev_output[64] = "";

static void print_volume(int muted, double db) {
	char output[64];

	if (muted) {
		snprintf(output, sizeof(output), "Muted");
	} else {
		snprintf(output, sizeof(output), "%.0f dB", db);
	}

	if (strcmp(output, prev_output) != 0) {
		printf("%s\n", output);
		fflush(stdout);
		strcpy(prev_output, output);
	}
}

static void sink_info_cb(pa_context *c, const pa_sink_info *info, int eol, void *userdata) {
	if (eol || ! info)
		return;

	double db = pa_sw_volume_to_dB(pa_cvolume_avg(&info->volume));
	print_volume(info->mute, db);
}

static void server_info_cb(pa_context *c, const pa_server_info *info, void *userdata) {
	if (! info || !info->default_sink_name)
		return;
	pa_context_get_sink_info_by_name(c, info->default_sink_name, sink_info_cb, NULL);
}

static void subscribe_cb(pa_context *c, pa_subscription_event_type_t type, uint32_t idx, void *userdata) {
	unsigned facility = type & PA_SUBSCRIPTION_EVENT_FACILITY_MASK;

	if (facility == PA_SUBSCRIPTION_EVENT_SINK ||
		facility == PA_SUBSCRIPTION_EVENT_SERVER) {
		pa_context_get_server_info(c, server_info_cb, NULL);
	}
}

static void context_state_cb(pa_context *c, void *userdata) {
	switch (pa_context_get_state(c)) {
		case PA_CONTEXT_READY:
			pa_context_set_subscribe_callback(c, subscribe_cb, NULL);
			pa_context_subscribe(c, PA_SUBSCRIPTION_MASK_SINK | PA_SUBSCRIPTION_MASK_SERVER, NULL, NULL);
			pa_context_get_server_info(c, server_info_cb, NULL);
			break;

		case PA_CONTEXT_FAILED:
		case PA_CONTEXT_TERMINATED:
			pa_mainloop_quit(mainloop, 1);
			break;

		default:
			break;
	}
}

int main(void) {
	pa_mainloop_api *mainloop_api;
	int ret;

	mainloop = pa_mainloop_new();
	if (!mainloop) {
		fprintf(stderr, "Failed to create mainloop\n");
		return 1;
	}

	mainloop_api = pa_mainloop_get_api(mainloop);
	context = pa_context_new(mainloop_api, "getvol");
	if (!context) {
		fprintf(stderr, "Failed to create context\n");
		pa_mainloop_free(mainloop);
		return 1;
	}

	pa_context_set_state_callback(context, context_state_cb, NULL);

	if (pa_context_connect(context, NULL, PA_CONTEXT_NOFLAGS, NULL) < 0) {
		fprintf(stderr, "Failed to connect to PulseAudio\n");
		pa_context_unref(context);
		pa_mainloop_free(mainloop);
		return 1;
	}

	pa_mainloop_run(mainloop, &ret);
	pa_context_disconnect(context);
	pa_context_unref(context);
	pa_mainloop_free(mainloop);

	return ret;
}

