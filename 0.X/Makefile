REGISTRY_NAME?=docker.io/hashicorp
IMAGE_NAME=vault-enterprise
VERSION=1.4.0-rc1
IMAGE_TAG=$(REGISTRY_NAME)/$(IMAGE_NAME):$(VERSION)

.PHONY: build image publish

build: image publish

image: 
	docker build --build-arg VAULT_VERSION=$(VERSION)+ent --no-cache -t $(IMAGE_TAG)_ent .


publish: 
	docker push $(IMAGE_TAG)_ent
