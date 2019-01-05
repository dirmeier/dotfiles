if [[ -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]]; then
  source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
fi

if [ -f ~/.aliases ]; then
      . ~/.aliases
fi

bindkey "^R" history-incremental-search-backward

SHELL_SESSION_HISTORY=0
unsetopt share_history
unsetopt correct
CASE_SENSITIVE="true"

zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'

PS1=" 🚀  ${PS1}"

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8

source ~/miniconda3/bin/activate default
