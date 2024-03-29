###############################################################################
# Variables
###############################################################################
variable "REPOSITORY" {
  default = "islandora"
}

variable "CACHE_FROM_REPOSITORY" {
  default = "islandora"
}

variable "CACHE_TO_REPOSITORY" {
  default = "islandora"
}

variable "TAG" {
  # "local" is to distinguish that from builds produced locally.
  default = "local"
}

variable "SOURCE_DATE_EPOCH" {
  default = "0"
}

###############################################################################
# Functions
###############################################################################
function hostArch {
  params = []
  result = equal("linux/amd64", BAKE_LOCAL_PLATFORM) ? "amd64" : "arm64" # Only two platforms supported.
}

function "tags" {
  params = [image, arch]
  result = ["${REPOSITORY}/${image}:${TAG}-${arch}"]
}

function "cacheFrom" {
  params = [image, arch]
  result = ["type=registry,ref=${CACHE_FROM_REPOSITORY}/cache:${image}-main-${arch}", "type=registry,ref=${CACHE_FROM_REPOSITORY}/cache:${image}-${TAG}-${arch}"]
}

function "cacheTo" {
  params = [image, arch]
  result =  ["type=registry,oci-mediatypes=true,mode=max,compression=estargz,compression-level=5,ref=${CACHE_TO_REPOSITORY}/cache:${image}-${TAG}-${arch}"]
}

###############################################################################
# Groups
###############################################################################
group "default" {
  targets = [
    "nodejs"
  ]
}

group "amd64" {
  targets = [
    "nodejs-amd64",
  ]
}

group "arm64" {
  targets = [
    "nodejs-arm64",
  ]
}

# CI should build both and push to the remote cache.
group "ci" {
  targets = [
    "nodejs-amd64-ci",
    "nodejs-arm64-ci",
  ]
}

###############################################################################
# Common target properties.
###############################################################################
target "common" {
  args = {
    # Required for reproduciable builds.
    # Requires Buildkit 0.11+
    # See: https://reproducible-builds.org/docs/source-date-epoch/
    SOURCE_DATE_EPOCH = "${SOURCE_DATE_EPOCH}",
  }
}

target "amd64-common" {
  platforms = ["linux/amd64"]
}

target "arm64-common" {
  platforms = ["linux/arm64"]
}

target "nodejs-common" {
  inherits = ["common"]
  context  = "nodejs"
  contexts = {
    # The digest (sha256 hash) is not platform specific but the digest for the manifest of all platforms.
    # It will be the digest printed when you do: docker pull alpine:3.17.1
    # Not the one displayed on DockerHub.
    # N.B. This should match the value used in:
    # - <https://github.com/Islandora-Devops/isle-imagemagick>
    # - <https://github.com/Islandora-Devops/isle-nodejs>
    alpine = "docker-image://alpine:3.19.1@sha256:c5b1261d6d3e43071626931fc004f70149baeba2c8ec672bd4f27761f8e1ad6b"
  }
}

###############################################################################
# Default Image targets for local builds.
###############################################################################
target "nodejs" {
  inherits   = ["nodejs-common"]
  cache-from = cacheFrom("nodejs", hostArch())
  tags       = tags("nodejs", "")
}

###############################################################################
# linux/amd64 targets.
###############################################################################
target "nodejs-amd64" {
  inherits   = ["nodejs-common", "amd64-common"]
  cache-from = cacheFrom("nodejs", "amd64")
  tags       = tags("nodejs", "amd64")
}

target "nodejs-amd64-ci" {
  inherits = ["nodejs-amd64"]
  cache-to = cacheTo("nodejs", "amd64")
}

###############################################################################
# linux/arm64 targets.
###############################################################################
target "nodejs-arm64" {
  inherits   = ["nodejs-common", "arm64-common"]
  cache-from = cacheFrom("nodejs", "arm64")
  tags       = tags("nodejs", "arm64")
}

target "nodejs-arm64-ci" {
  inherits = ["nodejs-arm64"]
  cache-to = cacheTo("nodejs", "arm64")
}