#!/bin/bash

# Source: https://docs.docker.com/install/linux/docker-ee/ubuntu/
# Source: https://docs.docker.com/ee/end-to-end-install/#step-2-install-universal-control-plane

if [ ! -f "docker_installed" ]; then

	ZONE=$(curl -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/zone)

	DOCKER_EE_URL=$(curl -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/attributes/docker-ee-url)
	DOCKER_EE_LIC=$(curl -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/attributes/docker-ee-lic)

	MANAGER_INTERNAL_IP=$(curl -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/network-interfaces/0/ip)
	MANAGER_EXTERNAL_IP=$(curl -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip)

	echo "Install Docker EE..."
	
	sudo apt-get update
	sudo apt-get -y install apt-transport-https ca-certificates curl software-properties-common

	curl -fsSL "${DOCKER_EE_URL}/ubuntu/gpg" | sudo apt-key add -

	sudo add-apt-repository "deb [arch=amd64] $DOCKER_EE_URL/ubuntu $(lsb_release -cs) stable-17.06"

	sudo apt-get update
	sudo apt-get -y install docker-ee
	
	echo "Install UCP..."

	gsutil cp $DOCKER_EE_LIC docker.lic
		
	docker container run --rm --name ucp \
		-v /var/run/docker.sock:/var/run/docker.sock \
		docker/ucp:3.0.6 install \
		--admin-username admin \
		--admin-password password \
		--host-address $MANAGER_INTERNAL_IP \
		--external-service-lb $MANAGER_EXTERNAL_IP \
		--license $(cat docker.lic) \
		--debug

	gcloud compute project-info add-metadata --metadata swarm-worker-token=$(docker swarm join-token -q worker)
	gcloud compute project-info add-metadata --metadata swarm-manager-token=$(docker swarm join-token -q manager)
	gcloud compute project-info add-metadata --metadata swarm-manager-ip=$MANAGER_INTERNAL_IP
				
	gcloud compute instances add-metadata $(hostname) --metadata docker-install-status=finished --zone $ZONE
	
	rm -f docker.lic
	
	touch "docker_installed"
	
fi
