export REGISTRY_NAME?=docker.io/hashicorp
export VERSION=1.11.8

.PHONY: build ent-image oss-image

build: ent-image oss-image fips-ent-image

ent-image: export PROJECT_NAME=vault-enterprise
ent-image: export TAG_SUFFIX=-ent-ubi
ent-image:
	docker build --label version=$(VERSION) --build-arg VAULT_VERSION=$(VERSION)+ent --no-cache -t $(REGISTRY_NAME)/$(PROJECT_NAME):$(VERSION)$(TAG_SUFFIX) .
	@../scripts/tag-images.sh

fips-ent-image: export PROJECT_NAME=vault-enterprise-fips
fips-ent-image: export TAG_SUFFIX=-ent-ubi
fips-ent-image:
	docker build --label version=$(VERSION) --build-arg VAULT_VERSION=$(VERSION)+ent.fips1402 --no-cache -t $(REGISTRY_NAME)/$(PROJECT_NAME):$(VERSION)$(TAG_SUFFIX) .
	@../scripts/tag-images.sh

oss-image: export PROJECT_NAME=vault
oss-image: export TAG_SUFFIX=-ubi
oss-image:
	docker build --label version=$(VERSION) --build-arg VAULT_VERSION=$(VERSION) --no-cache -t $(REGISTRY_NAME)/$(PROJECT_NAME):$(VERSION)$(TAG_SUFFIX) .
	@../scripts/tag-images.sh

push-images: oss-push-image ent-push-image fips-ent-push-image

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
ent-push-image: export TAG_SUFFIX=-ent-ubi
ent-push-image:
	@./push_image.sh

fips-ent-push-image: export REGISTRY_KEY=${FIPS_ENT_REGISTRY_KEY}
fips-ent-push-image: export VAULT_PID=${FIPS_ENT_VAULT_PID}
fips-ent-push-image: export VAULT_VERSION=$(VERSION)
fips-ent-push-image: export PROJECT_NAME=vault-enterprise-fips
fips-ent-push-image: export TAG_SUFFIX=-ent-ubi
fips-ent-push-image:
	@./push_image.sh
