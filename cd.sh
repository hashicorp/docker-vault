#!/bin/bash

CONFIG_FILE="cd/config.json"
DOCKERFILE_PATH="0.X/Dockerfile"
CE_VAULT_CLUSTER=$(jq -r .ce_vault_cluster $CONFIG_FILE)
CE_ENTERPRISE_DEPLOYMENT=$(jq -r .ce_enterprise_deployment $CONFIG_FILE)
AWS_COUPADEV_VAULT_REGION_CLUSTERS=$(jq -r '.aws_coupadev_vault_clusters|to_entries[]|.key+"="+.value' $CONFIG_FILE)
VAULT_VERSION=$(grep 'VAULT_VERSION=' ${DOCKERFILE_PATH} | awk -F'=' '{print $2}')
REGISTRY_NAME="899991151204.dkr.ecr.us-east-1.amazonaws.com"
IMAGE_NAME="vault"
IMAGE_TAG=${REGISTRY_NAME}/${IMAGE_NAME}:${VAULT_VERSION}

function log
{
  echo "$(date +"%Y-%m-%d %H:%M:%S") : $*"
}

function vaultImageVersion
{
  echo $VAULT_VERSION
}

function vaultImageTag
{
  echo $IMAGE_TAG
}

function vaultDockerfileLint
{
  log "Scanning Vault Dockerfile with tool ${hadolint}"
  /usr/bin/docker run --rm -i hadolint/hadolint hadolint --no-fail - < ${DOCKERFILE_PATH}
}

function vaultImageBuild
{
  log "Building Vault Image with tag ${IMAGE_TAG}"
  /usr/bin/docker build -t ${IMAGE_TAG} $(dirname ${DOCKERFILE_PATH})
}

function ecrDockerLogin
{
  REGION=$1
  ECR_REPO=$2
  log "Doing docker login to registry ${ECR_REPO}"
  /usr/bin/aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin ${ECR_REPO}
}

function vaultImagePush
{
  ecrDockerLogin 'us-east-1' "${REGISTRY_NAME}"
  log "Pushing Vault Image ${IMAGE_TAG}"
	/usr/bin/docker push ${IMAGE_TAG}
  for region_cluster in $AWS_COUPADEV_VAULT_REGION_CLUSTERS; do
    region=${region_cluster%=*}
    if [[ "$region" == 'us-east-1' ]]; then
      continue
    fi

    REGION_TAG=${IMAGE_TAG/us-east-1/$region}
    log "Tagging Vault Image ${IMAGE_TAG} as ${REGION_TAG}"
    /usr/bin/docker tag ${IMAGE_TAG} ${REGION_TAG}

    ecrDockerLogin ${region} "${REGION_TAG}"

    log "Pushing Vault Image ${REGION_TAG}"
    /usr/bin/docker push ${REGION_TAG}
  done
}

function upgradeCEVaultCluster
{
  upgradeVaultCluster 'us-east-1' $CE_VAULT_CLUSTER
}

function vaultIntegrationTests
{
  log "Running Integration Tests on ${CE_VAULT_CLUSTER}"
  log "Checking health of ${CE_VAULT_CLUSTER} from ${CE_ENTERPRISE_DEPLOYMENT}"
  cd /opt/coupa-flash/main && bundle exec rake common:swift:run_command["${CE_ENTERPRISE_DEPLOYMENT}","${CE_ENTERPRISE_DEPLOYMENT}utl1","curl -s https://${CE_VAULT_CLUSTER}.io.coupadev.com/v1/sys/health| jq",false,true]
}

function upgradeDevVaultClusters
{
  for region_cluster in $AWS_COUPADEV_VAULT_REGION_CLUSTERS; do
    region=${region_cluster%=*}
    cluster=${region_cluster#*=}
    upgradeVaultCluster $region $cluster
  done
}

function upgradeVaultCluster
{ 
  region=$1
  cluster=$2
  log "Upgrading AWS Coupadev Vault Cluster ${cluster} from region ${region} with Vault Image tag ${VAULT_VERSION}"
  cd /opt/coupa-flash/CE-15118 && bundle exec rake services:ecs:update_docker_image["${cluster}","${VAULT_VERSION}"]
}

CD_OPERATION="$1"
shift
$CD_OPERATION $*


