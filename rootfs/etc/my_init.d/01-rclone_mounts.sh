#!/usr/bin/env bash
[[ "${DEBUG,,}" == "true" ]] && set -x

#ENVS SUPPORTED:
# RCLONE_CONF_PATH
# RCLONE_OPTIONS
# RCLONE_DEFAULT_OPTIONS
# RCLONE_MOUNT_#
# RCLONE_MOUNT_#_OPTIONS

###ENVS###
RCLONE_CONF_PATH="${RCLONE_CONF_PATH:-}"
RCLONE_OPTIONS="${RCLONE_OPTIONS:-}"
RCLONE_DEFAULT_OPTIONS="${RCLONE_DEFAULT_OPTIONS:---allow-other}"

if [[ -n ${RCLONE_CONF_PATH} ]]; then
    RCLONE_OPTIONS="--config '${RCLONE_CONF_PATH}' ${RCLONE_OPTIONS}"
fi


###VARS###
PREFIX="RCLONE"
SERVICES_DIR="/etc/service"

###CODE###
#Don't continue if mounts are not setup
[[ -z $(eval "echo \$${PREFIX}_MOUNT_0") ]] && echo "RCLONE: No mounts are setup. Exiting." && exit 0

#If RCLONE config doesn't exist exit
command -v rclone >/dev/null 2>&1 || { echo "ERROR: Unable to find rclone." && exit 1; }

DEFAULT_OPTIONS=$(eval "echo \$${PREFIX}_DEFAULT_OPTIONS")

COUNT=0
while [[ true  ]]; do

    #########################
    ## START STANDARD LOOP ##
    #########################
    MOUNT=$(eval "echo \$${PREFIX}_MOUNT_$COUNT")
    MOUNT_NAME="\$${PREFIX}_MOUNT_$COUNT"
    OPTIONS=$(eval "echo \$${PREFIX}_MOUNT_${COUNT}_OPTIONS")

    #Increment count here so continue cmds later on don't cause infinite loop
    ((COUNT++))

    [[ -z "${MOUNT}" ]] && break

    IFS='|' read -r MOUNT_REMOTE MOUNT_LOCAL MOUNT_ENSURE_TYPE <<< "${MOUNT}"

    [[ -z "${MOUNT_REMOTE}" ]] && echo "Missing remote path for ${MOUNT_NAME}. Skipping." && continue

    [[ -z "${MOUNT_LOCAL}" ]] && echo "Missing local path for ${MOUNT_NAME}. Skipping." && continue

    [[ -z "$OPTIONS" ]] && OPTIONS="${DEFAULT_OPTIONS}"

    SERVICE=${MOUNT_NAME:1}
    DIR=${SERVICES_DIR}/${SERVICE}
    RUN=${DIR}/run

    #Create service directory
    [[ ! -e ${DIR} ]] && { mkdir -p ${DIR} || { echo "ERROR: Cannot create service directory: ${DIR}. Skipping." && continue; }; }
    #######################
    ## END STANDARD LOOP ##
    #######################

    [[ ! -e ${RUN} ]] && { cat << EOF > ${RUN}
#!/bin/bash
[[ "${DEBUG}" == "true" ]] && set -x && VERBOSE="-v"

#export HOME=/config

if [[ ! -d ${MOUNT_LOCAL} ]]; then

  fusermount -u -z -q ${MOUNT_LOCAL}

  [[ -e ${MOUNT_LOCAL} ]] && echo "RCLONE ERROR: Something exists where there should be a directory." && exit 1

  mkdir -p ${MOUNT_LOCAL} || { echo "RCLONE ERROR: Unable to create directory" && exit 1; }

fi;

echo "RCLONE: Mounting ${MOUNT_REMOTE} to ${MOUNT_LOCAL} with options (${OPTIONS})"

trap '{ /bin/fusermount -u -z -q "${MOUNT_LOCAL}"; exit \$1; }' INT TERM KILL QUIT EXIT

nice -n -10 /usr/local/bin/rclone ${RCLONE_OPTIONS} mount ${OPTIONS} \${VERBOSE} "${MOUNT_REMOTE}" "${MOUNT_LOCAL}" &

wait \$!

EOF
    chmod +x ${RUN}; }

done;