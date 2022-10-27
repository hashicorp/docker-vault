export REGISTRY_NAME?=docker.io/hashicorp
export VERSION=1.12.1

.PHONY: build ent-image oss-image xc-prod-image

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

# This target is used in CI to cross compile vault and vault-ent for 4 different architectures
# and publish (when XC_PUBLISH="--push") using docker buildx
xc-prod-image:
	docker buildx build --platform linux/amd64,linux/arm64,linux/386,linux/arm/v6 \
	--build-arg VAULT_VERSION=$(VERSION)$(VAULT_VERSION_SUFFIX) \
	--label version=$(VERSION) \
	$(XC_PUBLISH) \
	-t $(IMAGE_TAG) \
	.
