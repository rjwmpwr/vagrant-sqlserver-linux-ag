#!/bin/bash -e

## stonith disabled for dev only
pcs property set stonith-enabled=false  
pcs property set start-failure-is-fatal=true
pcs property set cluster-recheck-interval=2min
