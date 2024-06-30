# Make user owned tmp dir
CURRENTUSER="${USER:-${USERNAME:-${LOGNAME}}}"
mkdir "/tmp/$CURRENTUSER"; export TMPDIR="/tmp/$CURRENTUSER" && chmod 700 "/tmp/$CURRENTUSER"
mkdir "/tmp/$CURRENTUSER/Volatile" && ln -s "/tmp/$CURRENTUSER/Volatile" "$HOME" >/dev/null 2>&1

if ! cat /etc/fstab | grep /tmp 1>/dev/null; then
	touch $HOME/"WARNING tmp is not on memory"
fi

# Force XDG Base Dir Compliance
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"
export XDG_CONFIG_HOME="$HOME/.local/config"
export XDG_CACHE_HOME="/tmp/$CURRENTUSER/cache"
export XDG_BIN_HOME="$HOME/.local/bin"
export XCURSOR_PATH="$XDG_DATA_HOME/icons:$XCURSOR_PATH"
export WINEPREFIX="$XDG_DATA_HOME/wineprefixes/default"

export WGETRC="$XDG_CONFIG_HOME/wgetrc"
export XAUTHORITY="$XDG_RUNTIME_DIR/Xauthority"
export GNUPGHOME="$XDG_DATA_HOME/gnupg"
export ICEAUTHORITY="$XDG_CACHE_HOME/ICEauthority "
export GTK2_RC_FILES="$XDG_CONFIG_HOME/gtk-2.0/gtkrc"
export ANDROID_HOME="$XDG_DATA_HOME/android"
export GTK2_RC_FILES="$XDG_CONFIG_HOME/gtk-2.0/gtkrc"
export ZDOTDIR="$HOME/.local/config/zsh"

# Others
export PATH="$XDG_BIN_HOME:$PATH"
export MESA_SHADER_CACHE_DIR="$XDG_STATE_HOME/mesa_shader_cache"
export TERMINAL=xfce4-terminal 
export QT_QPA_PLATFORMTHEME=qt6ct
export EDITOR="nano"
export NO_STRIP=true
#export APPIMAGE_EXTRACT_AND_RUN=1

# Start i3wm
if [ "$(tty)" = "/dev/tty1" ]; then
	pgrep i3 || clear && exec startx "$XDG_CONFIG_HOME/X11/xinitrc" >/dev/null 2>&1
fi
