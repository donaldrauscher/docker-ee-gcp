#!/bin/bash

DOCKER_EE_URL="https://storebits.docker.com/ee/ubuntu/sub-bb5613f5-4248-4a2e-bc1f-c3f968378620"
DOCKER_EE_LIC="gs://djr-data/docker-ee/docker_subscription.lic"

REGION=$(gcloud config get-value compute/region)
ZONE=$(gcloud config get-value compute/zone)

NUM_WORKERS=$(gcloud compute instance-groups list-instances swarm --filter "NAME~swarm-w[0-9]+" --format "table[no-heading](NAME)" | wc -l)
((NUM_WORKERS++))

NEW_WORKER="swarm-w${NUM_WORKERS}"

gcloud beta compute instances create $NEW_WORKER \
    --zone "${ZONE}" \
    --machine-type "n1-standard-2" \
    --image-family "ubuntu-1604-lts" --image-project "ubuntu-os-cloud" \
    --boot-disk-size "50" --boot-disk-type "pd-ssd" \
    --maintenance-policy "TERMINATE" \
    --metadata docker-install-status="pending",startup-script="$(cat worker_setup.sh)",docker-ee-url="${DOCKER_EE_URL}" \
    --tags "http-server,https-server" \
    --scopes "cloud-platform"

gcloud compute instance-groups unmanaged add-instances swarm --zone "${ZONE}" --instances $NEW_WORKER
	
WORKER_STATUS=$(gcloud compute instances describe $NEW_WORKER --zone "${ZONE}" | awk '/docker-install-status/{getline;print $2;}' | awk 'FNR ==1 {print $1}')
while [ "$WORKER_STATUS" = "pending" ]; do
	echo $WORKER_STATUS
	sleep 5
	WORKER_STATUS=$(gcloud compute instances describe $NEW_WORKER --zone "${ZONE}" | awk '/docker-install-status/{getline;print $2;}' | awk 'FNR ==1 {print $1}')
done
echo $WORKER_STATUS
