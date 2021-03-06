#!/bin/bash

# Source: https://docs.docker.com/install/linux/docker-ee/ubuntu/
# Source: https://docs.docker.com/ee/ucp/admin/configure/join-nodes/join-linux-nodes-to-cluster/

DOCKER_INSTALL_STATUS=$(curl -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/attributes/docker-install-status)

if [ "${DOCKER_INSTALL_STATUS}" = "pending" ]; then

	ZONE=$(curl -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/zone)
	
	DOCKER_EE_URL=$(curl -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/attributes/docker-ee-url)
	
	SWARM_UCP_IP=$(curl -H 'Metadata-Flavor: Google' http://metadata/computeMetadata/v1/project/attributes/swarm-ucp-ip)
	SWARM_TOKEN=$(curl -H 'Metadata-Flavor: Google' http://metadata/computeMetadata/v1/project/attributes/swarm-worker-token)
	
	echo "Install Docker EE..."
	
	sudo apt-get update
	sudo apt-get -y install apt-transport-https ca-certificates curl software-properties-common

	curl -fsSL "${DOCKER_EE_URL}/ubuntu/gpg" | sudo apt-key add -

	sudo add-apt-repository "deb [arch=amd64] $DOCKER_EE_URL/ubuntu $(lsb_release -cs) stable-17.06"

	sudo apt-get update
	sudo apt-get -y install docker-ee
	
	echo "Join Swarm..."

	sudo docker swarm join --token $SWARM_TOKEN $SWARM_UCP_IP:2377
	sleep 60

	gcloud compute ssh swarm-m --zone $ZONE --command="sudo docker node update --label-add com.docker.ucp.orchestrator.kubernetes=true $(hostname)"
	gcloud compute ssh swarm-m --zone $ZONE --command="sudo docker node update --label-rm com.docker.ucp.orchestrator.swarm $(hostname)"
	
	gcloud compute instances add-metadata $(hostname) --metadata docker-install-status=finished --zone $ZONE
	
fi
