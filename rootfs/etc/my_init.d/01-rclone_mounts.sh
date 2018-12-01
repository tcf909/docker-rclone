#!/usr/bin/env bash
[[ "${DEBUG,,}" ]] && set -x

#ENVS SUPPORTED:
# RCLONE_DEFAULT_OPTIONS
# RCLONE_MOUNT_#
# RCLONE_MOUNT_#_OPTIONS

###ENVS###
RCLONE_DEFAULT_OPTIONS="${RCLONE_DEFAULT_OPTIONS:---allow-other}"

###VARS###
PREFIX="RCLONE"
SERVICES_DIR="/etc/service"

#Don't continue if mounts are not setup
[[ -z $(eval "echo \$${PREFIX}_MOUNT_0") ]] && exit 0

COUNT=0
while [[ true  ]]; do

    #########################
    ## START STANDARD LOOP ##
    #########################
    MOUNT=$(eval "echo \$${PREFIX}_MOUNT_${COUNT}")
    MOUNT_NAME="\$${PREFIX}_MOUNT_${COUNT}"
    OPTIONS=$(eval "echo \$${PREFIX}_MOUNT_${COUNT}_OPTIONS")
    DEFAULT_OPTIONS=$(eval "echo \$${PREFIX}_DEFAULT_OPTIONS")

    #Increment count here so continue cmds later on don't cause infinite loop
    ((COUNT++))

    [[ -z "${MOUNT}" ]] && break

    IFS='|' read -r MOUNT_REMOTE MOUNT_LOCAL MOUNT_ENSURE_TYPE <<< "${MOUNT}"

    [[ -z "${MOUNT_REMOTE}" ]] && echo "Missing remote path for ${MOUNT_NAME}. Skipping." && continue

    [[ -z "${MOUNT_LOCAL}" ]] && echo "Missing local path for ${MOUNT_NAME}. Skipping." && continue

     RCLONE_REMOTE="${MOUNT_REMOTE%%:*}"
     RCLONE_REMOTE_TYPE=$(eval "echo \$RCLONE_CONFIG_${RCLONE_REMOTE}_TYPE");

    [[ -z "${RCLONE_REMOTE_TYPE}" ]] && echo "RCLONE_\$REMOTE_TYPE is not specified in environment. Skipping." && continue

    { [[ -z "$OPTIONS" ]] && OPTIONS="${DEFAULT_OPTIONS}"; } || { [[ -n "${RCLONE_DEFAULT_OPTIONS}" ]] && OPTIONS="${RCLONE_DEFAULT_OPTIONS} ${OPTIONS}"; }

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
[[ "${DEBUG}" ]] && set -x && VERBOSE="-v"

if [[ ! -d ${MOUNT_LOCAL} ]]; then

  fusermount -u -z -q ${MOUNT_LOCAL}

  [[ -e ${MOUNT_LOCAL} ]] && echo "RCLONE ERROR: Something exists where there should be a directory." && exit 1

  mkdir -p ${MOUNT_LOCAL} || { echo "RCLONE ERROR: Unable to create directory" && exit 1; }

fi;

echo "RCLONE: Mounting ${MOUNT_REMOTE} to ${MOUNT_LOCAL} with options (${OPTIONS})"

#trap '{ /bin/fusermount -u -z -q "${MOUNT_LOCAL}"; exit \$1; }' INT TERM KILL QUIT EXIT
#exec nice -n -10 /usr/local/bin/rclone mount "${MOUNT_REMOTE}" "${MOUNT_LOCAL}" \${VERBOSE} ${OPTIONS} &
#wait \$!

nice -n -10 /usr/local/bin/rclone mount "${MOUNT_REMOTE}" "${MOUNT_LOCAL}" \${VERBOSE} ${OPTIONS}

EOF
    chmod +x ${RUN}; }

done;