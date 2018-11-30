#!/bin/bash

DTR_URL="dtr.donaldrauscher.com"

DOCKER_EE_URL="https://storebits.docker.com/ee/ubuntu/sub-bb5613f5-4248-4a2e-bc1f-c3f968378620"
DOCKER_EE_LIC="gs://djr-data/docker-ee/docker_subscription.lic"

REGION=$(gcloud config get-value compute/region)
ZONE=$(gcloud config get-value compute/zone)

DTR_STATIC=$(gcloud compute addresses list --filter "NAME=swarm-dtr" --format "table[no-heading](NAME)")
if [ -z "$DTR_STATIC" ]; then
    gcloud compute addresses create swarm-dtr --region $REGION
fi
DTR_IP=$(gcloud compute addresses describe swarm-dtr --region $REGION --format "value(ADDRESS)")

gcloud compute project-info add-metadata --metadata swarm-dtr-url=$DTR_URL

gcloud beta compute instances create swarm-w-dtr \
    --address "${DTR_IP}" --zone "${ZONE}" \
    --machine-type "n1-standard-4" \
    --image-family "ubuntu-1604-lts" --image-project "ubuntu-os-cloud" \
    --boot-disk-size "100" --boot-disk-type "pd-ssd" \
    --maintenance-policy "TERMINATE" \
    --metadata docker-install-status="pending",startup-script="$(cat dtr_setup.sh)",docker-ee-url="${DOCKER_EE_URL}" \
    --tags "http-server,https-server" \
    --scopes "cloud-platform"

gcloud compute instance-groups unmanaged add-instances swarm --instances swarm-w-dtr --zone "${ZONE}"
	
DTR_STATUS=$(gcloud compute instances describe swarm-w-dtr --zone $ZONE | awk '/docker-install-status/{getline;print $2;}' | awk 'FNR ==1 {print $1}')
while [ "$DTR_STATUS" = "pending" ]; do
	echo $DTR_STATUS
	sleep 5
	DTR_STATUS=$(gcloud compute instances describe swarm-w-dtr --zone $ZONE | awk '/docker-install-status/{getline;print $2;}' | awk 'FNR ==1 {print $1}')
done
echo $DTR_STATUS

#gcloud compute ssh swarm-m --command="sudo docker node update --availability pause swarm-w-dtr"
#gcloud compute ssh swarm-m --command="sudo docker node update --label-rm com.docker.ucp.orchestrator.kubernetes swarm-w-dtr"
