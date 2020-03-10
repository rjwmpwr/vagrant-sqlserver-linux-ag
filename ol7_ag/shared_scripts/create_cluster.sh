#!/bin/bash -e

# create linux cluster
pcs cluster auth ${NODE1_HOSTNAME} ${NODE2_HOSTNAME} ${NODE3_HOSTNAME} -u hacluster -p $HACLUSTER_PASSWORD
pcs cluster setup --start  --name ${HACLUSTER_NAME} ${NODE1_HOSTNAME} ${NODE2_HOSTNAME} ${NODE3_HOSTNAME}

pcs cluster enable --all
pcs status --full
