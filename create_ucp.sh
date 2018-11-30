#!/bin/bash

UCP_URL="ucp.donaldrauscher.com"

DOCKER_EE_URL="https://storebits.docker.com/ee/ubuntu/sub-bb5613f5-4248-4a2e-bc1f-c3f968378620"
DOCKER_EE_LIC="gs://djr-data/docker-ee/docker_subscription.lic"

REGION=$(gcloud config get-value compute/region)
ZONE=$(gcloud config get-value compute/zone)

UCP_STATIC=$(gcloud compute addresses list --filter "NAME=swarm-ucp" --format "table[no-heading](NAME)")
if [ -z "$UCP_STATIC" ]; then
    gcloud compute addresses create swarm-ucp --region $REGION
fi
UCP_IP=$(gcloud compute addresses describe swarm-ucp --region $REGION --format "value(ADDRESS)")

gcloud compute project-info add-metadata --metadata swarm-ucp-url=$UCP_URL

gcloud beta compute instances create swarm-m \
    --address "${UCP_IP}" --zone "${ZONE}" \
    --machine-type "n1-standard-2" \
    --image-family "ubuntu-1604-lts" --image-project "ubuntu-os-cloud" \
    --boot-disk-size "50" --boot-disk-type "pd-ssd" \
    --maintenance-policy "TERMINATE" \
    --metadata docker-install-status="pending",startup-script="$(cat ucp_setup.sh)",docker-ee-url="${DOCKER_EE_URL}" \
    --tags "http-server,https-server,kubectl" \
    --scopes "cloud-platform"

gcloud compute instance-groups unmanaged create swarm --zone "${ZONE}"
gcloud compute instance-groups unmanaged add-instances swarm --instances swarm-m --zone "${ZONE}"
	
UCP_STATUS=$(gcloud compute instances describe swarm-m --zone $ZONE | awk '/docker-install-status/{getline;print $2;}' | awk 'FNR ==1 {print $1}')
while [ "$UCP_STATUS" = "pending" ]; do
	echo $UCP_STATUS
	sleep 5
	UCP_STATUS=$(gcloud compute instances describe swarm-m --zone $ZONE | awk '/docker-install-status/{getline;print $2;}' | awk 'FNR ==1 {print $1}')
done
echo $UCP_STATUS
