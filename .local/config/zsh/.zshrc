autoload -Uz compinit promptinit
compinit -d "$XDG_STATE_HOME"/zsh/zcompdump-"$ZSH_VERSION"
promptinit
zstyle ':completion::complete:*' gain-privileges 1
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

HISTFILE="$XDG_STATE_HOME"/zsh/zsh_history
HISTSIZE=5000
SAVEHIST=5000
setopt appendhistory

PROMPT='%F{226}%~/ '

alias sudo=doas
alias cat=bat
alias ls="ls -a --color=auto"
alias yeet="doas pacman -Rns"
alias wget=wget --hsts-file="$XDG_DATA_HOME/wget-hsts"
alias iotop="doas iotop"
alias ps_mem="doas ps_mem"
alias zramen="doas zramen"
alias debloat="pacman -Qdtq | doas pacman -Rsn -"

lfcd () {
    tmp="$(mktemp)"
    lf -last-dir-path="$tmp" "$@"
    if [ -f "$tmp" ]; then
        dir="$(cat "$tmp")"
        rm -f "$tmp"
        [ -d "$dir" ] && [ "$dir" != "$(pwd)" ] && cd "$dir"
    fi
}

alias lf="lfcd"
bindkey -s '^o' 'lfcd\n'
bindkey '^U' backward-kill-line

function preexec() {
  timer=$(($(date +%s%0N)/1000000))
}

function precmd() {
  if [ $timer ]; then
    now=$(($(date +%s%0N)/1000000))
    elapsed=$(($now-$timer))
    export RPROMPT="%F{cyan}${elapsed}ms %{$reset_color%}"
    unset timer
  fi
}

fastfetch --physicaldisk-temp

autoload bashcompinit
bashcompinit
source /home/samuel/.local/config/zsh/.bash_completion
