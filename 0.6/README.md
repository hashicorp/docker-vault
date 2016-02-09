# HashiCorp Official Docker Consul Image

There are several pieces that are used to build this image:

* A bootstrapping tool called docker-basetool has a released version that's
  actually checked in to this repository. This contains SSL certificates and
  a simple Go binary that are used to fetch the rest of the released materials
  during the build. See https://github.com/hashicorp/docker-basetool for
  details.
* Official HashiCorp builds of some base utilities are then included in the
  image by pulling a release of docker-base. This includes dumb-init and gosu.
  See https://github.com/hashicorp/docker-base for more details.
* Finally a specific Consul build is fetched and the rest of the Consul-specific
  configuration happens according to the Dockerfile.