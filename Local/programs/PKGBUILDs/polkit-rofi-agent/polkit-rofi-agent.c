#define POLKIT_AGENT_I_KNOW_API_IS_SUBJECT_TO_CHANGE
#define GLIB_DISABLE_DEPRECATION_WARNINGS
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <pwd.h>
#include <sys/types.h>
#include <unistd.h>
#include <polkit/polkit.h>
#include <polkitagent/polkitagent.h>

typedef struct {
	PolkitAgentListener parent;
	GSimpleAsyncResult *result;
	PolkitAgentSession *session;
	GCancellable *cancellable;
	gulong cancel_id;
	char *identity_name;
	char *action_message;
	char *command_line;
} RofiListener;

typedef struct {
	PolkitAgentListenerClass parent_class;
} RofiListenerClass;

static void rofi_listener_init(RofiListener *self);
static void rofi_listener_class_init(RofiListenerClass *klass);
static void rofi_listener_finalize(GObject *obj);

G_DEFINE_TYPE(RofiListener, rofi_listener, POLKIT_AGENT_TYPE_LISTENER)

static char *shell_escape_sq(const char *str) {
	size_t count = 0;
	for (const char *p = str; *p; p++)
		if (*p == '\'') count++;
	char *out = g_malloc(strlen(str) + count * 3 + 1);
	char *dst = out;
	for (const char *p = str; *p; p++) {
		if (*p == '\'') {
			*dst++ = '\'';
			*dst++ = '\\';
			*dst++ = '\'';
			*dst++ = '\'';
		} else {
			*dst++ = *p;
		}
	}
	*dst = '\0';
	return out;
}

static char *get_identity_name(PolkitIdentity *identity) {
	if (POLKIT_IS_UNIX_USER(identity)) {
		struct passwd pw, *ppw;
		char buf[2048];
		if (!getpwuid_r(polkit_unix_user_get_uid(POLKIT_UNIX_USER(identity)),
				&pw, buf, sizeof(buf), &ppw))
			return g_strdup(ppw->pw_name);
	}
	return polkit_identity_to_string(identity);
}

static void on_completed(PolkitAgentSession *session, gboolean gained, gpointer data) {
	RofiListener *self = data;
	g_simple_async_result_set_op_res_gboolean(self->result, gained);
	g_simple_async_result_complete_in_idle(self->result);
	g_object_unref(self->result);
	g_object_unref(self->session);
	g_cancellable_disconnect(self->cancellable, self->cancel_id);
	g_object_unref(self->cancellable);
	self->result = NULL;
	self->session = NULL;
	self->cancel_id = 0;
}

static void on_request(PolkitAgentSession *session, const char *request,
		gboolean echo, gpointer data) {
	RofiListener *self = data;

	char *mesg_content = NULL;
	if (self->command_line)
		mesg_content = g_strdup_printf("Command: %s", self->command_line);
	else if (self->action_message)
		mesg_content = g_strdup(self->action_message);

	char *esc_mesg = mesg_content ? shell_escape_sq(mesg_content) : NULL;
	char *esc_identity = shell_escape_sq(self->identity_name);

	char *prompt;
	if (esc_mesg)
		prompt = g_strdup_printf(
			"rofi -dmenu -password -p 'Password for %s:' -mesg '%s' -lines 0",
			esc_identity, esc_mesg);
	else
		prompt = g_strdup_printf(
			"rofi -dmenu -password -p 'Password for %s:' -lines 0",
			esc_identity);

	g_free(esc_mesg);
	g_free(esc_identity);
	g_free(mesg_content);

	FILE *fp = popen(prompt, "r");
	g_free(prompt);
	char passwd[256] = {0};
	if (fp) {
		if (fgets(passwd, sizeof(passwd), fp)) {
			size_t len = strlen(passwd);
			if (len > 0 && passwd[len-1] == '\n') passwd[len-1] = '\0';
		}
		pclose(fp);
	}
	polkit_agent_session_response(session, passwd[0] ? passwd : NULL);
}

static void on_cancelled(GCancellable *c, gpointer data) {
	RofiListener *self = data;
	polkit_agent_session_cancel(self->session);
}

static void initiate_authentication(PolkitAgentListener *listener,
	const char *action_id, const char *message, const char *icon_name,
	PolkitDetails *details, const char *cookie, GList *identities,
	GCancellable *cancellable, GAsyncReadyCallback callback,
	gpointer user_data)
{
	RofiListener *self = (RofiListener *)listener;
	GSimpleAsyncResult *simple = g_simple_async_result_new(
		G_OBJECT(self), callback, user_data, initiate_authentication);

	if (self->session) {
		g_simple_async_result_set_error(simple, POLKIT_ERROR,
			POLKIT_ERROR_FAILED,
			"An authentication session is already underway.");
		g_simple_async_result_complete_in_idle(simple);
		g_object_unref(simple);
		return;
	}

	if (!identities || !identities->data) {
		g_simple_async_result_set_error(simple, POLKIT_ERROR,
			POLKIT_ERROR_FAILED, "No identities.");
		g_simple_async_result_complete_in_idle(simple);
		g_object_unref(simple);
		return;
	}

	PolkitIdentity *identity = identities->data;
	g_free(self->identity_name);
	self->identity_name = get_identity_name(identity);

	g_free(self->action_message);
	self->action_message = g_strdup(message ? message : action_id);

	g_free(self->command_line);
	const char *cmd = polkit_details_lookup(details, "command-line");
	self->command_line = cmd ? g_strdup(cmd) : NULL;

	self->session = polkit_agent_session_new(identity, cookie);
	g_signal_connect(self->session, "completed",
		G_CALLBACK(on_completed), self);
	g_signal_connect(self->session, "request",
		G_CALLBACK(on_request), self);

	self->result = simple;
	self->cancellable = g_object_ref(cancellable);
	self->cancel_id = g_cancellable_connect(cancellable,
		G_CALLBACK(on_cancelled), self, NULL);

	polkit_agent_session_initiate(self->session);
}

static gboolean initiate_authentication_finish(PolkitAgentListener *listener,
	GAsyncResult *res, GError **error)
{
	if (g_simple_async_result_propagate_error(
			G_SIMPLE_ASYNC_RESULT(res), error))
		return FALSE;
	return g_simple_async_result_get_op_res_gboolean(
		G_SIMPLE_ASYNC_RESULT(res));
}

static void rofi_listener_init(RofiListener *self) {
	self->identity_name = g_strdup("Administrator");
	self->action_message = NULL;
	self->command_line = NULL;
}

static void rofi_listener_finalize(GObject *obj) {
	RofiListener *self = (RofiListener *)obj;
	g_free(self->identity_name);
	g_free(self->action_message);
	g_free(self->command_line);
	G_OBJECT_CLASS(rofi_listener_parent_class)->finalize(obj);
}

static void rofi_listener_class_init(RofiListenerClass *klass) {
	GObjectClass *gobject_class = G_OBJECT_CLASS(klass);
	PolkitAgentListenerClass *listener_class =
		POLKIT_AGENT_LISTENER_CLASS(klass);
	gobject_class->finalize = rofi_listener_finalize;
	listener_class->initiate_authentication = initiate_authentication;
	listener_class->initiate_authentication_finish =
		initiate_authentication_finish;
}

int main(int argc, char *argv[]) {
	GError *error = NULL;

	PolkitSubject *subject =
		polkit_unix_session_new_for_process_sync(getpid(), NULL, &error);
	if (!subject) {
		fprintf(stderr, "Failed to create subject\n");
		return 1;
	}

	RofiListener *listener =
		g_object_new(rofi_listener_get_type(), NULL);

	gpointer handle = polkit_agent_listener_register(
		POLKIT_AGENT_LISTENER(listener),
		POLKIT_AGENT_REGISTER_FLAGS_NONE,
		subject, NULL, NULL, &error);

	if (!handle) {
		fprintf(stderr, "Failed to register: %s\n", error->message);
		return 1;
	}

	GMainLoop *loop = g_main_loop_new(NULL, FALSE);
	g_main_loop_run(loop);

	polkit_agent_listener_unregister(handle);
	g_main_loop_unref(loop);
	g_object_unref(listener);
	g_object_unref(subject);
	return 0;
}
