# login stuff here
if [[ -o login ]]; then
	# Make user owned tmp dir
	export USER="${LOGNAME:-${USER:-${USERNAME}}}"
	if [ ! -e /tmp/"$USER" ]; then
		mkdir -p /tmp/"$USER"/Volatile && chmod 700 /tmp/"$USER" || exit 1
		ln -s /tmp/"$USER"/Volatile "$HOME" >/dev/null 2>&1
		ln -s /tmp/"$USER" "$HOME"/Local/tmp >/dev/null 2>&1
	fi

	# Force XDG Base Dir Compliance
	export XDG_BIN_HOME="$HOME"/Local/bin \
		XDG_SBIN_HOME="$HOME"/Local/sbin \
		XDG_DATA_HOME="$HOME"/Local/share \
		XDG_STATE_HOME="$HOME"/Local/state \
		XDG_CONFIG_HOME="$HOME"/Local/config \
		XDG_CACHE_HOME=/tmp/"$USER"/cache

	export ZDOTDIR="$HOME"/Local/config/zsh \
		XCURSOR_PATH="$XDG_DATA_HOME/icons:$XCURSOR_PATH" \
		WINEPREFIX="$XDG_DATA_HOME"/wineprefixes/default \
		SANDBOXDIR="$HOME"/Local/am-sandboxes \
		HISTFILE="$XDG_STATE_HOME"/zsh/zsh_history \
		WGETRC="$XDG_CONFIG_HOME"/wgetrc \
		XAUTHORITY="$XDG_RUNTIME_DIR"/Xauthority \
		GNUPGHOME="$XDG_DATA_HOME"/gnupg \
		ICEAUTHORITY="$XDG_CACHE_HOME"/ICEauthority \
		GTK2_RC_FILES="$XDG_CONFIG_HOME"/gtk-2.0/gtkrc \
		ANDROID_HOME="$XDG_STATE_HOME"/android

	# Others
	export ARCH="$(uname -m)" \
		PATH="$XDG_BIN_HOME:$XDG_SBIN_HOME:$PATH" \
		DBIN_INSTALL_DIR="$XDG_SBIN_HOME" \
		EDITOR="nano" \
		FUSERMOUNT_PROG="$(which fusermount3 2>/dev/null)" \
		HISTSIZE=6000 \
		SAVEHIST=6000 \
		MESA_SHADER_CACHE_DIR="$XDG_STATE_HOME/mesa_shader_cache" \
		TMPDIR=/tmp/"$USER" \
		TERMINAL=xfce4-terminal \
		QT_QPA_PLATFORMTHEME=qt6ct

	# Start i3wm
	if [ -z "$DISPLAY" ] && [ "$XDG_VTNR" = 1 ]; then
		clear
		exec startx "$XDG_CONFIG_HOME/X11/xinitrc" -keeptty >/dev/null 2>&1
	fi
fi

# Interactive stuff here
if [[ -o interactive ]]; then
	setopt appendhistory
	autoload -Uz compinit promptinit bashcompinit
	compinit -d "$XDG_STATE_HOME"/zsh/zcompdump-"$ZSH_VERSION"
	promptinit
	bashcompinit
	zstyle ':completion::complete:*' gain-privileges 1
	. /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
	. /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
	. /home/samuel/Local/share/bash-completion/completions/am
	. /home/samuel/Local/share/bash-completion/completions/appman

	preexec() {
		preexec_timestart=$(($(date +%s%0N)/1000000))
	}

	precmd() {
		PROMPT="%F{226}$(printf "$PWD" | sed "s|$HOME/|~/|; s|$HOME|~/|") "
		[ -z "$preexec_timestart" ] && return 1
		now=$(($(date +%s%0N)/1000000))
		elapsed=$(($now-$preexec_timestart))
		RPROMPT="%F{226}${elapsed}ms %{$reset_color%}"
		export PROMPT RPROMPT
		unset preexec_timestart
	}

	lfcd() {
		cd "$(command lf -print-last-dir)"
	}

	bindkey -s '^o' 'lfcd\n'
	bindkey '^U' backward-kill-line
	alias lf="lfcd"
	alias sudo=doas
	alias chx='chmod +x'
	alias cat=bat
	alias ls="ls -a --color=auto"
	alias yeet="doas pacman -Rns"
	alias yeetfr="doas pacman -Rnsdd"
	alias wget=wget --hsts-file="$XDG_STATE_HOME/wget-hsts"
	alias iotop="doas iotop"
	alias ps_mem="doas ps_mem"
	alias zramen="doas zramen"
	alias debloat="pacman -Qdtq | doas pacman -Rsn -"

	# commands to run on terminal window
	fastfetch --physicaldisk-temp
fi
