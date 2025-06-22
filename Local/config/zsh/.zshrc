# login stuff here
if [[ -o login ]]; then
	# Make user owned tmp dir
	export USER="${LOGNAME:-${USER:-${USERNAME}}}"
	export TMPDIR="/tmp/$USER"

	if [ ! -e "$TMPDIR" ]; then
		mkdir -p "$TMPDIR"/Volatile && chmod -R 700 "$TMPDIR" || exit 1
		ln -s "$TMPDIR"/Volatile "$HOME" >/dev/null 2>&1
		ln -s "$TMPDIR" "$HOME"/Local/tmp >/dev/null 2>&1
	fi

	# Force XDG Base Dir Compliance
	export XDG_BIN_HOME="$HOME"/Local/bin \
		XDG_DATA_HOME="$HOME"/Local/share \
		XDG_STATE_HOME="$HOME"/Local/state \
		XDG_CONFIG_HOME="$HOME"/Local/config \
		XDG_CACHE_HOME="$TMPDIR"/cache

	export ZDOTDIR="$HOME"/Local/config/zsh \
		XCURSOR_PATH="$XDG_DATA_HOME/icons:$XCURSOR_PATH" \
		WINEPREFIX="$XDG_DATA_HOME"/wineprefixes/default \
		SANDBOXDIR="$HOME"/Local/am-sandboxes \
		HISTFILE="$XDG_STATE_HOME"/zsh/zsh_history \
		WGETRC="$XDG_CONFIG_HOME"/wget/wgetrc \
		XAUTHORITY="$XDG_RUNTIME_DIR"/Xauthority \
		GNUPGHOME="$XDG_DATA_HOME"/gnupg \
		ICEAUTHORITY="$XDG_CACHE_HOME"/ICEauthority \
		GTK2_RC_FILES="$XDG_CONFIG_HOME"/gtk-2.0/gtkrc \
		ANDROID_HOME="$XDG_STATE_HOME"/android \
		GOPATH="$XDG_CACHE_HOME"/go

	# Others
	export ARCH="$(uname -m)" \
		PATH="$XDG_BIN_HOME:$PATH" \
		EDITOR="nano" \
		HISTSIZE=5000 \
		SAVEHIST=5000 \
		MESA_SHADER_CACHE_DIR="$XDG_STATE_HOME/mesa_shader_cache" \
		TERMINAL=xfce4-terminal \
		QT_QPA_PLATFORMTHEME=gtk3 \
		LITE_SCALE=0.85 \
		GDK_BACKEND=x11

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
	autoload -U url-quote-magic bracketed-paste-magic
	zle -N self-insert url-quote-magic
	zle -N bracketed-paste bracketed-paste-magic
	. /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
	. /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
	. /home/samuel/Local/share/bash-completion/completions/am
	. /home/samuel/Local/share/bash-completion/completions/appman

	ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20

	pasteinit() {
		OLD_SELF_INSERT=${${(s.:.)widgets[self-insert]}[2,3]}
		zle -N self-insert url-quote-magic
	}

	pastefinish() {
		zle -N self-insert $OLD_SELF_INSERT
	}

	zstyle :bracketed-paste-magic paste-init pasteinit
	zstyle :bracketed-paste-magic paste-finish pastefinish
	ZSH_AUTOSUGGEST_CLEAR_WIDGETS+=(bracketed-paste)

	preexec() {
		preexec_timestart=$(($(date +%s%0N)/1000000))
	}

	precmd() {
		PROMPT="%F{178}$(printf "$PWD" | sed "s|$HOME/|~/|; s|$HOME|~/|") "
		[ -z "$preexec_timestart" ] && return 1
		now=$(($(date +%s%0N)/1000000))
		elapsed=$(($now-$preexec_timestart))
		RPROMPT="%F{178}${elapsed}ms %{$reset_color%}"
		export PROMPT RPROMPT
		unset preexec_timestart
	}

	lfcd() {
		cd "$(command lf -print-last-dir)"
	}

	diff(){
		printf '%.30s%65s\n' "$1" "$2" "================" "==================="
		command diff --color -y "$1" "$2"
	}

	bindkey -s '^o' 'lfcd\n'
	bindkey '^U' backward-kill-line
	alias lf="lfcd"
	alias chx='chmod +x'
	alias cat=bat
	alias ls="ls -a --color=auto"
	alias yeet="doas pacman -Rns"
	alias yeetfr="doas pacman -Rnsdd"
	alias wget=wget --hsts-file="$XDG_STATE_HOME/wget-hsts"
	alias iotop="doas iotop"
	alias ps_mem="doas $XDG_BIN_HOME/ps_mem"
	alias zramen="doas zramen"
	alias debloat="pacman -Qdtq | doas pacman -Rsn -"
	alias dbin="dbin-wrapper"

	# commands to run on terminal window
	fastfetch
fi

autoload bashcompinit
bashcompinit
source "/home/samuel/Local/share/bash-completion/completions/am"
