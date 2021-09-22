REGISTRY_NAME?=899991151204.dkr.ecr.us-east-1.amazonaws.com
IMAGE_NAME=vault
VERSION=1.8.2
IMAGE_TAG=$(REGISTRY_NAME)/$(IMAGE_NAME):$(VERSION)

.PHONY: build image push

build: image push

image: 
	docker build --build-arg VAULT_VERSION=$(VERSION) -t $(IMAGE_TAG) 0.X

publish: 
	/usr/bin/aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $(REGISTRY_NAME)
	docker push $(IMAGE_TAG)
