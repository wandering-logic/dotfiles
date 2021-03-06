#
# ~/.bash_profile: executed by bash(1) for login shells (after /etc/profile)

# source the users bashrc if it exists
if [ -f "${HOME}/.bashrc" ] ; then
    source "${HOME}/.bashrc"
fi

echo "path in bashrc is [[${PATH}]]"

# Set PATH so it includes user's private bin if it exists
# path-add defined in .bashrc
if [ -d "${HOME}/bin" ] ; then
    path-add -p "${HOME}/bin"
fi

if [ -d /home/utils/bin ] ; then
    path-add /home/utils/bin
fi

# the following is wrong except _maybe_ on Selene, where it is also wrong
# Selene may need the ssh-add but starting another agent is definitely wrong.
# We should be doing the add on an existing agent
# eval $(ssh-agent) && ssh-add

# Set MANPATH so it includes users' private man if it exists
# if [ -d "${HOME}/man" ]; then
#   MANPATH="${HOME}/man:${MANPATH}"
# fi

# Set INFOPATH so it includes users' private info if it exists
# if [ -d "${HOME}/info" ]; then
#   INFOPATH="${HOME}/info:${INFOPATH}"
# fi

