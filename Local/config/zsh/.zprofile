# Make user owned tmp dir
CURRENTUSER="${LOGNAME:-${USER:-${USERNAME}}}"
if [ ! -e "/tmp/$CURRENTUSER" ]; then
	mkdir -p /tmp/"$CURRENTUSER"/Volatile \
		&& chmod 700 /tmp/"$CURRENTUSER" || exit 1
	ln -s /tmp/"$CURRENTUSER"/Volatile "$HOME" >/dev/null 2>&1
	ln -s /tmp/"$CURRENTUSER" "$HOME"/Local/tmp >/dev/null 2>&1
	export TMPDIR=/tmp/"$CURRENTUSER"
fi

if ! cat /etc/fstab | grep "/tmp.*tmpfs" 1>/dev/null; then
	touch "$HOME/WARNING tmp is not on memory"
fi

# Force XDG Base Dir Compliance
export XDG_BIN_HOME="$HOME/Local/bin"
export XDG_SBIN_HOME="$HOME/Local/sbin"
export XDG_DATA_HOME="$HOME/Local/share"
export XDG_STATE_HOME="$HOME/Local/state"
export XDG_CONFIG_HOME="$HOME/Local/config"
export XDG_CACHE_HOME="/tmp/$CURRENTUSER/cache"
export XCURSOR_PATH="$XDG_DATA_HOME/icons:$XCURSOR_PATH"
export WINEPREFIX="$XDG_DATA_HOME/wineprefixes/default"
export SANDBOXDIR="$HOME/Local/am-sandboxes"

export WGETRC="$XDG_CONFIG_HOME/wgetrc"
export XAUTHORITY="$XDG_RUNTIME_DIR/Xauthority"
export GNUPGHOME="$XDG_DATA_HOME/gnupg"
export ICEAUTHORITY="$XDG_CACHE_HOME/ICEauthority "
export GTK2_RC_FILES="$XDG_CONFIG_HOME/gtk-2.0/gtkrc"
export ANDROID_HOME="$XDG_DATA_HOME/android"
export GTK2_RC_FILES="$XDG_CONFIG_HOME/gtk-2.0/gtkrc"
export ZDOTDIR="$HOME/Local/config/zsh"

# Others
export PATH="$XDG_BIN_HOME:$XDG_SBIN_HOME:$PATH"
export MESA_SHADER_CACHE_DIR="$XDG_STATE_HOME/mesa_shader_cache"
export TERMINAL=xfce4-terminal 
export QT_QPA_PLATFORMTHEME=qt6ct
export EDITOR="nano"
export NO_STRIP=true
export DBIN_INSTALL_DIR="$XDG_SBIN_HOME"
#export APPIMAGE_EXTRACT_AND_RUN=1

# Start i3wm
if [ "$(tty)" = "/dev/tty1" ]; then
	pgrep i3 || clear && exec startx "$XDG_CONFIG_HOME/X11/xinitrc" >/dev/null 2>&1
fi
