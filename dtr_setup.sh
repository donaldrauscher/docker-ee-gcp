#!/bin/bash

# Source: https://docs.docker.com/install/linux/docker-ee/ubuntu/
# Source: https://docs.docker.com/ee/dtr/admin/install/

DOCKER_INSTALL_STATUS=$(curl -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/attributes/docker-install-status)

if [ "${DOCKER_INSTALL_STATUS}" = "pending" ]; then

	ZONE=$(curl -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/zone)

	DOCKER_EE_URL=$(curl -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/attributes/docker-ee-url)
	
	UCP_IP=$(curl -H 'Metadata-Flavor: Google' http://metadata/computeMetadata/v1/project/attributes/swarm-ucp-ip)
	UCP_URL=$(curl -H 'Metadata-Flavor: Google' http://metadata/computeMetadata/v1/project/attributes/swarm-ucp-url)
	WORKER_TOKEN=$(curl -H 'Metadata-Flavor: Google' http://metadata/computeMetadata/v1/project/attributes/swarm-worker-token)
	
	echo "Install Docker EE..."
	
	sudo apt-get update
	sudo apt-get -y install apt-transport-https ca-certificates curl software-properties-common

	curl -fsSL "${DOCKER_EE_URL}/ubuntu/gpg" | sudo apt-key add -

	sudo add-apt-repository "deb [arch=amd64] $DOCKER_EE_URL/ubuntu $(lsb_release -cs) stable-17.06"

	sudo apt-get update
	sudo apt-get -y install docker-ee
	
	echo "Join Swarm..."

	sudo docker swarm join --token $WORKER_TOKEN $UCP_IP:2377
	sleep 60

	echo "Install DTR..."
	
	sudo docker container run --rm --name dtr \
		docker/dtr:2.5.0 install \
		--ucp-node $(hostname) \
		--ucp-url "https://${UCP_URL}" \
		--ucp-username admin \
		--ucp-password password \
		--ucp-insecure-tls \
		--debug
		
	gcloud compute ssh swarm-m --zone $ZONE --command="sudo docker node update --availability pause $(hostname)"
	
	gcloud compute instances add-metadata $(hostname) --metadata docker-install-status=finished --zone $ZONE
	
fi
