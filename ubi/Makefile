export REGISTRY_NAME?=docker.io/hashicorp
export VERSION=1.9.0

.PHONY: build ent-image oss-image

build: ent-image oss-image

ent-image: export PROJECT_NAME=vault-enterprise
ent-image: export TAG_SUFFIX=-ubi-ent
ent-image:
	docker build --label version=$(VERSION) --build-arg VAULT_VERSION=$(VERSION)+ent --no-cache -t $(REGISTRY_NAME)/$(PROJECT_NAME):$(VERSION)$(TAG_SUFFIX) .
	@../scripts/tag-images.sh

oss-image: export PROJECT_NAME=vault
oss-image: export TAG_SUFFIX=-ubi
oss-image:
	docker build --label version=$(VERSION) --build-arg VAULT_VERSION=$(VERSION) --no-cache -t $(REGISTRY_NAME)/$(PROJECT_NAME):$(VERSION)$(TAG_SUFFIX) .
	@../scripts/tag-images.sh

push-images: oss-push-image ent-push-image

oss-push-image: export REGISTRY_KEY=${OSS_REGISTRY_KEY}
oss-push-image: export VAULT_PID=${OSS_VAULT_PID}
oss-push-image: export VAULT_VERSION=$(VERSION)
oss-push-image: export PROJECT_NAME=vault
oss-push-image: export TAG_SUFFIX=-ubi
oss-push-image:
	@./push_image.sh

ent-push-image: export REGISTRY_KEY=${ENT_REGISTRY_KEY}
ent-push-image: export VAULT_PID=${ENT_VAULT_PID}
ent-push-image: export VAULT_VERSION=$(VERSION)
ent-push-image: export PROJECT_NAME=vault-enterprise
ent-push-image: export TAG_SUFFIX=-ubi-ent
ent-push-image:
	@./push_image.sh
