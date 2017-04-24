if [[ -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]]; then
  source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
fi

alias ll='ls -lh'
alias la='ls -lha'
alias l='less -SI $1'
alias pa='ps aux | grep $1'
alias ..='cd ..'
alias ...='cd ../..'
alias h='head'
alias t='tail'
alias fts='firefox& thunderbird & skype &'
alias rm='rm -i'
alias rmr='rm -rfd'
alias git='/usr/local/git/bin/git'
alias slack='/usr/local/slack/Slack.app/Contents/MacOS/Slack'
alias lg='ll | grep $1'
alias lein='/opt/local/lein'
alias node='/usr/local/bin/node'
alias npm='/usr/local/bin/npm'
alias yo='/opt/local/bin/yo'

bindkey "^R" history-incremental-search-backward

SHELL_SESSION_HISTORY=0
unsetopt share_history
unsetopt correct
CASE_SENSITIVE="true"

zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'

export GRADLE_HOME=/usr/local/gradle/
export SPARK_HOME=/opt/local/spark/spark-2.0.0-bin-hadoop2.7
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
export PATH=$GRADLE_HOME/bin:/usr/local/maven/bin:/usr/local/digital_alexandria:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export PATH=/Library/TeX/texbin/:/opt/local/bin:/opt/local/sbin:$PATH
export PATH=/opt/local/lib/mysql5/bin:$PATH
export PATH=/opt/local/cassandra/bin:$PATH
export PATH=/opt/local/lib/postgresql93/bin:$PATH
export PATH=/Applications/Julia-0.5.app/Contents/Resources/julia/bin:$PATH
export PATH=/opt/local/scala/scala-2.12.0/bin:$PATH
export JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk1.8.0_60.jdk/Contents/Home
export PKG_CONFIG_PATH=/usr/local/Cellar/cpputest/3.7.2/lib/pkgconfig/
alias subl="/Applications/Sublime\ Text.app/Contents/SharedSupport/bin/subl"
alias GITTOK="d783116b77de394e4fd7b89cebbbe8c7"
export DYLD_LIBRARY_PATH=$DYLD_LIBRARY_PATH:/opt/intel/compilers_and_libraries_2017/mac/lib
