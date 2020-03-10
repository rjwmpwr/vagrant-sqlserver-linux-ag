#!/bin/bash -e

pcs resource create ${AG_NAME} ocf:mssql:ag ag_name=${AG_NAME} meta failure-timeout=60s master notify=true
pcs resource create ${AG_VIP_NAME} ocf:heartbeat:IPaddr2 ip=${AG_VIP_IP} cidr_netmask=24 op monitor interval=30s
pcs constraint colocation add ${AG_VIP_NAME} ${AG_NAME}-master INFINITY with-rsc-role=Master
pcs constraint order promote ${AG_NAME}-master then start ${AG_VIP_NAME}

pcs status --full
pcs constraint show --full
pcs resource show --full
