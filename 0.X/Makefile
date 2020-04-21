REGISTRY_NAME?=docker.io/hashicorp
IMAGE_NAME=vault-enterprise
VERSION=1.4.0
IMAGE_TAG=$(REGISTRY_NAME)/$(IMAGE_NAME):$(VERSION)

.PHONY: build image image-openshift publish

build: image image-openshift publish

image: 
	docker build --build-arg VAULT_VERSION=$(VERSION)+ent --no-cache -t $(IMAGE_TAG)_ent .

image-openshift: 
	docker build --build-arg VAULT_VERSION=$(VERSION)+ent --no-cache -t $(IMAGE_TAG)_ent_ocp -f Dockerfile.openshift .

publish: 
	docker push $(IMAGE_TAG)_ent
