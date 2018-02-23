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

export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/local/lib:/Applications/HDF_Group/HDFJAVA/3.2.1/lib
export GRADLE_HOME=/usr/local/gradle/
export SPARK_HOME=/usr/local/spark/spark
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
export PATH=/usr/local/mongodb/bin:$PATH
export PATH=/usr/local/sonarcube/bin:$PATH

export JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk1.8.0_60.jdk/Contents/Home
export PKG_CONFIG_PATH=/usr/local/Cellar/cpputest/3.7.2/lib/pkgconfig/
export DYLD_LIBRARY_PATH=$DYLD_LIBRARY_PATH:/opt/intel/compilers_and_libraries_2017/mac/lib
export R_HOME="/Library/Frameworks/R.framework/Resources/"

