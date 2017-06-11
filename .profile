#
# ~/.profile: executed by the command interpreter for login shells.
#
# bash login shells invoke /etc/profile, then one of ~/.bash_profile,
# ~/.bash_login, or ~/.profile (in that order).  So for bash-only
# setup you probably want to modify ~/.bash_profile if it exists.
#
# sh login shells (including bash invoked as sh) invoke
# /etc/profile and then ~/.profile.
#
# for non-login bash shells see .bashrc

# function names can use underscores, but not dashes

# Set PATH so it includes user's private bin if it exists
if [ -d "${HOME}/bin" ] ; then
    # the ${parameter:+word} syntax substitutes <word> conditional on
    # parameter (<word> here is ":$PATH")
    export PATH="${HOME}/bin"${PATH:+:$PATH}
fi

# for sh interactive shells the interpreter executes the file named in
# ENV
case $- in
    *i*) [ -z "${ENV}" ] && [ -f "${HOME}/.shinit" ] && ENV=${HOME}/.shinit && export ENV ;;
esac
