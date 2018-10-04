# base-files version 4.0-4
# ~/.bashrc: executed by bash(1) for interactive shells.

# I guess Centos expects this, while Ubuntu doesn't
[[ -f /etc/bashrc ]] && source /etc/bashrc

# If not running interactively, don't do anything
[[ "$-" != *i* ]] && return

# export http_proxy=http://proxy.foo.com:port

# Disable the following: DISPLAY should be set in any circumstance where it is
# useful.  If it is not set it is because user doesn't want to use it.
# If DISPLAY is not set, but we can find an X server, use it
#if [[ -z "${DISPLAY}" ]] && xset q -display localhost:0.0 &>/dev/null; then
#  export DISPLAY=localhost:0.0
#fi

# ON THIS SYSTEM I'VE ONLY INSTALLED EMACS-NOX AND EMACS IS MAPPED TO
# THE LATEST VERSION OF EMACS-NOX

# standard options
#export EDITOR="emacs -nw"
export EDITOR=emacs
export P4CONFIG=.p4config
# Shell Options
#
# See man bash for more options...
#
# Don't wait for job termination notification
# set -o notify
#
# Don't use ^D to exit
set -o ignoreeof
#
# Use case-insensitive filename globbing
# shopt -s nocaseglob
#
# Make bash append rather than overwrite the history on disk
shopt -s histappend

# allow window to resize correctly!
shopt -s checkwinsize
#
# When changing directory small typos can be ignored by bash
# for example, cd /vr/lgo/apaache would find /var/log/apache
# shopt -s cdspell

# Completion options
#
# These completion tuning parameters change the default behavior of bash_completion:
#
# Define to access remotely checked-out files over passwordless ssh for CVS
# COMP_CVS_REMOTE=1
#
# Define to avoid stripping description in --option=description of './configure --help'
# COMP_CONFIGURE_HINTS=1
#
# Define to avoid flattening internal contents of tar files
# COMP_TAR_INTERNAL_PATHS=1
#
# Uncomment to turn on programmable completion enhancements.
# Any completions you add in ~/.bash_completion are sourced last.
# [[ -f /etc/bash_completion ]] && . /etc/bash_completion

# History Options
HISTSIZE=1000
HISTFILESIZE=2000
#
# Don't put duplicate lines in the history.
# export HISTCONTROL=$HISTCONTROL${HISTCONTROL+,}ignoredups
#
# Ignore some controlling instructions
# HISTIGNORE is a colon-delimited list of patterns which should be excluded.
# The '&' is a special pattern which suppresses duplicate entries.
# export HISTIGNORE=$'[ \t]*:&:[fb]g:exit'
# export HISTIGNORE=$'[ \t]*:&:[fb]g:exit:ls' # Ignore the ls command as well
#
# Whenever displaying the prompt, write the previous line to disk
# export PROMPT_COMMAND="history -a"

if [[ \@${TERM} == \@xterm* ]] ; then

  # simple 16 color xterm is better than 256 color for me
  TERM=xterm

  # PROMPT_COMMAND gets executed between each prompt.  This is the
  # escape sequence to put the cwd in the window title:
  export PROMPT_COMMAND='echo -ne "\033]0;${HOSTNAME}:${PWD}\007"'

  # this sets the prompt to something cheerful:
  PS1='[\[\e[32m\]\h \[\e[33m\]\W\[\e[0m\]]\$ '
else
  # no color!
  export PROMPT_COMMAND=""
  unset PROMPT_COMMAND
  PS1='[\h \W]\$ '
fi

# Aliases
#
# Some people use a different file for aliases
# if [ -f "${HOME}/.bash_aliases" ]; then
#   source "${HOME}/.bash_aliases"
# fi
#
# Some example alias instructions
# If these are enabled they will be used instead of any instructions
# they may mask.  For example, alias rm='rm -i' will mask the rm
# application.  To override the alias instruction use a \ before, ie
# \rm will call the real rm not the alias.
#
# Interactive operation...
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

alias gpu-top='watch -n 0.5 nvidia-smi'
#
# Default to human readable figures
# alias df='df -h'
# alias du='du -h'
#
# Misc :)
# alias less='less -r'                          # raw control characters
# alias whence='type -a'                        # where, of a sort
# alias grep='grep --color'                     # show differences in colour
# alias egrep='egrep --color=auto'              # show differences in colour
# alias fgrep='fgrep --color=auto'              # show differences in colour

#
# Some shortcuts for different directory listings
if [[ \@${TERM} == \@xterm* ]] ; then
  alias ls='ls -aF --color=auto'
  d=~/.dircolors
  test -r $d && eval "$(dircolors -b $d)" || eval "$(dircolors -b)"
  alias grep='grep --color=auto'
else
  alias ls='ls -aF'
fi

# alias ls='ls -hF --color=tty'                 # classify files in colour
# alias dir='ls --color=auto --format=vertical'
# alias vdir='ls --color=auto --format=long'
# alias ll='ls -l'                              # long list
# alias la='ls -A'                              # all but . and ..
# alias l='ls -CF'                              #

alias nl-to-null='tr \\n \\0'

#alias emacs='/usr/bin/emacs -nw'
#alias emacs-x='/usr/bin/emacs'

# Umask
#
# /etc/profile sets 022, removing write perms to group + others.
# Set a more restrictive umask: i.e. no exec perms for others:
# umask 027
# Paranoid: neither group nor others have any perms:
# umask 077
# When working with a group, on the other hand, it is sometimes useful
# to allow group members to write shared files:
# umask 002

# Functions
#
# Some people use a different file for functions
# if [ -f "${HOME}/.bash_functions" ]; then
#   source "${HOME}/.bash_functions"
# fi
#

path-add () {
    local whichpath=PATH
    local prepend=""
    local newplace=$(pwd)

    for i in "$@"; do
	case $i in
	    -p|--pre*)
		prepend="yes"
		;;
	    -l|--lib*)
		whichpath=LD_LIBRARY_PATH
		;;
	    *)
		newplace=$(realpath "$i")
		;;
	esac
    done

    if [ -n "${prepend}" ]; then
	# the ${parameter:+word} syntax substitutes <word> conditional on
	# parameter (<word> here is ":${!whichpath}") the ${!param} is an
	# indirect variabl.  So if whichpath=PATH then we get the contents of
	# PATH, if it is LD_LIBRARY_PATH we get the contents of that.
	export ${whichpath}=${newplace}${!whichpath:+:${!whichpath}}
    else
	export ${whichpath}=${!whichpath:+${!whichpath}:}${newplace}
    fi
}

export -f path-add

# OSTYPE is a "bashism", use "uname -s" outside .bashrc
# https://stackoverflow.com/questions/3466166/how-to-check-if-running-in-cygwin-mac-or-linux
case "${OSTYPE}" in
    linux*)
	# putclip and getclip are defined commands on Cygwin
	alias putclip='xclip -selection clipboard'
	alias getclip='xclip -out -selection clipboard'
	;;
esac

mfrank_xdiscard() {
    echo -n "${READLINE_LINE:0:$READLINE_POINT}" | putclip
    READLINE_LINE="${READLINE_LINE:$READLINE_POINT}"
    READLINE_POINT=0
}
mfrank_xkill() {
    echo -n "${READLINE_LINE:$READLINE_POINT}" | putclip
    READLINE_LINE="${READLINE_LINE:0:$READLINE_POINT}"
}
mfrank_xyank() {
    CLIP=$(getclip)
    COUNT=$(echo -n "$CLIP" | wc -c)
    READLINE_LINE="${READLINE_LINE:0:$READLINE_POINT}${CLIP}${READLINE_LINE:$READLINE_POINT}"
    READLINE_POINT=$(($READLINE_POINT + $COUNT))
}

# only works if there is an xserver to handle the clipboard:
if [[ -n "${DISPLAY}" ]]; then
    bind -m emacs -x '"\C-u": mfrank_xdiscard'
    bind -m emacs -x '"\C-k": mfrank_xkill'
    bind -m emacs -x '"\C-y": mfrank_xyank'
fi

# Some example functions:
#
# a) function settitle
# settitle () 
# { 
#   echo -ne "\e]2;$@\a\e]1;$@\a"; 
# }
# 
# b) function cd_func
# This function defines a 'cd' replacement function capable of keeping, 
# displaying and accessing history of visited directories, up to 10 entries.
# To use it, uncomment it, source this file and try 'cd --'.
# acd_func 1.0.5, 10-nov-2004
# Petar Marinov, http:/geocities.com/h2428, this is public domain
# cd_func ()
# {
#   local x2 the_new_dir adir index
#   local -i cnt
# 
#   if [[ $1 ==  "--" ]]; then
#     dirs -v
#     return 0
#   fi
# 
#   the_new_dir=$1
#   [[ -z $1 ]] && the_new_dir=$HOME
# 
#   if [[ ${the_new_dir:0:1} == '-' ]]; then
#     #
#     # Extract dir N from dirs
#     index=${the_new_dir:1}
#     [[ -z $index ]] && index=1
#     adir=$(dirs +$index)
#     [[ -z $adir ]] && return 1
#     the_new_dir=$adir
#   fi
# 
#   #
#   # '~' has to be substituted by ${HOME}
#   [[ ${the_new_dir:0:1} == '~' ]] && the_new_dir="${HOME}${the_new_dir:1}"
# 
#   #
#   # Now change to the new dir and add to the top of the stack
#   pushd "${the_new_dir}" > /dev/null
#   [[ $? -ne 0 ]] && return 1
#   the_new_dir=$(pwd)
# 
#   #
#   # Trim down everything beyond 11th entry
#   popd -n +11 2>/dev/null 1>/dev/null
# 
#   #
#   # Remove any other occurence of this dir, skipping the top of the stack
#   for ((cnt=1; cnt <= 10; cnt++)); do
#     x2=$(dirs +${cnt} 2>/dev/null)
#     [[ $? -ne 0 ]] && return 0
#     [[ ${x2:0:1} == '~' ]] && x2="${HOME}${x2:1}"
#     if [[ "${x2}" == "${the_new_dir}" ]]; then
#       popd -n +$cnt 2>/dev/null 1>/dev/null
#       cnt=cnt-1
#     fi
#   done
# 
#   return 0
# }
# 
# alias cd=cd_func
