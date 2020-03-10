#!/bin/bash -e

pcs resource create ${AG_NAME} ocf:mssql:ag ag_name=${AG_NAME} meta failure-timeout=60s promotable notify=true
pcs resource create ${AG_VIP_NAME} ocf:heartbeat:IPaddr2 ip=${AG_VIP_IP} cidr_netmask=24 op monitor interval=30s
pcs constraint colocation add ${AG_VIP_NAME} with master ${AG_NAME}-clone INFINITY with-rsc-role=Master
pcs constraint order promote ${AG_NAME}-clone then start ${AG_VIP_NAME}
pcs status --full
pcs constraint
pcs resource status
