export REGISTRY_NAME?=docker.io/hashicorp
export VERSION=1.7.3
export ORACLE_VERSION=0.4.1
export ORACLE_PLUGIN_URL=https://releases.hashicorp.com/vault-plugin-database-oracle/$(ORACLE_VERSION)/vault-plugin-database-oracle_$(ORACLE_VERSION)_SHA256SUMS
ORACLE_SHA := $(shell curl -s $(ORACLE_PLUGIN_URL) | awk '{ print $$1 }')

.PHONY: build ent-image

build: ent-image

ent-image: export PROJECT_NAME=vault-enterprise-oracle
ent-image: export TAG_SUFFIX=-ubi-ent
ent-image:
	echo $(ORACLE_SHA)
	docker build --label version=$(VERSION) --build-arg VAULT_VERSION=$(VERSION)+ent --build-arg ORACLE_VERSION=$(ORACLE_VERSION) --build-arg ORACLE_SHA=$(ORACLE_SHA) --no-cache -t $(REGISTRY_NAME)/$(PROJECT_NAME):$(VERSION)$(TAG_SUFFIX) .
	@../scripts/tag-images.sh
