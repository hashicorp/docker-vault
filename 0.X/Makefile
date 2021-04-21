export REGISTRY_NAME?=docker.io/hashicorp
export VERSION=1.7.1

.PHONY: build ent-image oss-image

build: ent-image oss-image

ent-image: export PROJECT_NAME=vault-enterprise
ent-image: export TAG_SUFFIX=_ent
ent-image: 
	docker build --label version=$(VERSION) --build-arg VAULT_VERSION=$(VERSION)+ent --no-cache -t $(REGISTRY_NAME)/$(PROJECT_NAME):$(VERSION)$(TAG_SUFFIX) .
	@../scripts/tag-images.sh

oss-image: export PROJECT_NAME=vault
oss-image:
	docker build --label version=$(VERSION) --build-arg VAULT_VERSION=$(VERSION) --no-cache -t $(REGISTRY_NAME)/$(PROJECT_NAME):$(VERSION) .
	@../scripts/tag-images.sh

