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

date > /tmp/,dockerPS.sh

/usr/local/bin/docker ps --format '{{.Names}}\t{{.Image}}\t{{.Ports}}' | awk -F $'\t' '{ printf "%-25s %-40s %-s\n", $1, $2, $3 }'
exit 0

