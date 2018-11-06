#!/bin/bash

DOCKER_EE_URL="https://storebits.docker.com/ee/ubuntu/sub-bb5613f5-4248-4a2e-bc1f-c3f968378620"
DOCKER_EE_LIC="gs://djr-data/docker-ee/docker_subscription.lic"

REGION=$(gcloud config get-value compute/region)
ZONE=$(gcloud config get-value compute/zone)

SWARM_STATIC=$(gcloud compute addresses list --filter "NAME=swarm" --format "table[no-heading](NAME)")
if [ -z "$SWARM_STATIC" ]; then
    gcloud compute addresses create swarm --region $REGION
fi
SWARM_STATIC_IP=$(gcloud compute addresses describe swarm --region $REGION --format "value(ADDRESS)")

gcloud beta compute instances create swarm-m \
    --address "${SWARM_STATIC_IP}" --zone "${ZONE}" \
    --machine-type "n1-standard-2" \
    --image-family "ubuntu-1604-lts" --image-project "ubuntu-os-cloud" \
    --boot-disk-size "50" --boot-disk-type "pd-ssd" \
    --maintenance-policy "TERMINATE" \
    --metadata docker-install-status="pending",startup-script="$(cat manager_setup.sh)",docker-ee-url="${DOCKER_EE_URL}",docker-ee-lic="${DOCKER_EE_LIC}" \
    --tags "http-server,https-server" \
    --scopes "cloud-platform"

gcloud compute instance-groups unmanaged create swarm --zone "${ZONE}"
	
SWARM_STATUS=$(gcloud compute instances describe swarm-m --zone $ZONE | awk '/docker-install-status/{getline;print $2;}' | awk 'FNR ==1 {print $1}')
while [ "$SWARM_STATUS" = "pending" ]; do
	echo $SWARM_STATUS
	sleep 5
	SWARM_STATUS=$(gcloud compute instances describe swarm-m --zone $ZONE | awk '/docker-install-status/{getline;print $2;}' | awk 'FNR ==1 {print $1}')
done
echo $SWARM_STATUS
