#!/bin/bash -e

# create linux cluster
pcs host auth ${NODE1_HOSTNAME} ${NODE2_HOSTNAME}  ${NODE3_HOSTNAME} -u hacluster -p $HACLUSTER_PASSWORD
pcs cluster setup ${HACLUSTER_NAME} ${NODE1_HOSTNAME} ${NODE2_HOSTNAME} ${NODE3_HOSTNAME}

pcs cluster start --all
pcs cluster enable --all
pcs status --full
