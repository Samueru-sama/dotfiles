# Force XDG Base Dir Compliance
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/var/state"
export XDG_CONFIG_HOME="$HOME/.local/config"
export XDG_CACHE_HOME="$HOME/.local/var/cache"
export XDG_BIN_HOME="$HOME/.local/bin"
export XCURSOR_PATH=${XCURSOR_PATH}:$XDG_DATA_HOME/icons
export WINEPREFIX="$XDG_DATA_HOME"/wineprefixes/default

export WGETRC="$XDG_CONFIG_HOME/wgetrc"
export XAUTHORITY="$XDG_RUNTIME_DIR"/Xauthority
export GNUPGHOME="$XDG_DATA_HOME"/gnupg
export ICEAUTHORITY="$XDG_CACHE_HOME"/ICEauthority 
export GTK2_RC_FILES="$XDG_CONFIG_HOME"/gtk-2.0/gtkrc
export ANDROID_HOME="$XDG_DATA_HOME"/android
export GTK2_RC_FILES="$XDG_CONFIG_HOME"/gtk-2.0/gtkrc
export ZDOTDIR="$HOME"/.local/config/zsh

# Others
export PATH="$HOME/.local/bin:$PATH"
export TERMINAL=xfce4-terminal 
export QT_QPA_PLATFORMTHEME=qt5ct
export EDITOR="nano"


# Start i3wm
if [[ "$(tty)" = "/dev/tty1" ]]; then

pgrep i3 || exec startx "$XDG_CONFIG_HOME/X11/xinitrc" > /dev/null 2>&1

fi
