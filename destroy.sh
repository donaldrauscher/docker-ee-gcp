#!/bin/bash

SWARM_NODES=$(gcloud compute instance-groups list-instances swarm --format "table[no-heading](NAME)")

gcloud beta compute instances delete $SWARM_NODES --quiet
gcloud compute instance-groups unmanaged delete swarm --quiet
