#!/usr/bin/env bash
[[ "${DEBUG,,}" == "true" ]] && set -x

if [[ ! -e "/.firstRun" ]]; then

    export FIRST_RUN=true

    touch "/.firstRun"

else

    export FIRST_RUN=false

fi;

#
# RUN EVERY START
#

# COMMAND HERE

[[ "${FIRST_RUN}" == "true" ]] && exit 0
#
# BELOW THIS LINE: RUN ONLY ON CONTAINER CREATION
#
echo "HISTCONTROL=ignoreboth" >>~/.bashrc