#!/bin/sh

#  DockerPS.sh
#  deploymentMonster
#
#  Created by Philip Callender on 15/09/2016.
#  Copyright © 2016 Philip Callender. All rights reserved.
export DOCKER_HOST=tcp://192.168.99.100:2376
#export DOCKER_MACHINE_NAME=default
export DOCKER_TLS_VERIFY=1
export DOCKER_CERT_PATH=${HOME}/.docker/machine/machines/default


/usr/local/bin/docker ps --all --format '{{.Names}}|{{.Image}}|{{.Status}}|{{.Ports}}' \
    | awk -F $'|' '{
        gsub(/0.0.0.0:/, "", $4)
        gsub(/\/tcp/, "", $4)
        printf "%s|%s|%s|%s\n", $1, $2, $3, $4
    }'

exit 0

