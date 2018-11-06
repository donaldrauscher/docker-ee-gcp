#!/bin/bash

REGION=$(gcloud config get-value compute/region)

SWARM_STATIC=$(gcloud compute addresses list --filter "NAME=swarm" --format "table(name)")

if [ -z "$SWARM_STATIC" ]; then
    gcloud compute addresses create "swarm" --region $REGION
fi

SWARM_IP=$(gcloud compute addresses describe "swarm" --region $REGION --format "value(address)")

DOCKER_EE_URL="https://storebits.docker.com/ee/ubuntu/sub-bb5613f5-4248-4a2e-bc1f-c3f968378620"
DOCKER_EE_LIC="gs://djr-data/docker-ee/docker_subscription.lic"

gcloud beta compute instances create "swarm-m" \
    --address "$SWARM_IP" \
    --machine-type "n1-standard-2" \
    --image-family "ubuntu-1604-lts" --image-project "ubuntu-os-cloud" \
    --boot-disk-size "50" --boot-disk-type "pd-ssd" \
    --maintenance-policy "TERMINATE" \
    --metadata startup-script="$(cat manager_setup.sh)",docker-ee-url="${DOCKER_EE_URL}",docker-ee-lic="${DOCKER_EE_LIC}" \
    --tags "http-server,https-server" \
    --scopes "cloud-platform"
	