variable "SOURCE_DATE_EPOCH" {
  default = "0"
}

variable "REPOSITORY" {
  default = "islandora"
}

variable "TAG" {
  # "local" is to distinguish remote images from those produced locally.
  default = "local"
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
  result = ["type=registry,ref=${REPOSITORY}/cache:${image}-main-${arch}", "type=registry,ref=${REPOSITORY}/cache:${image}-${TAG}-${arch}"]
}

function "cacheTo" {
  params = [image, arch]
  result = ["type=registry,oci-mediatypes=true,mode=max,compression=estargz,compression-level=5,ref=${REPOSITORY}/cache:${image}-${TAG}-${arch}"]
}

###############################################################################
# Groups
###############################################################################
group "default" {
  targets = [
    "nodejs",
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
# Targets
###############################################################################
target "common" {
  args = {
    # Required for reproduciable builds.
    # Requires Buildkit 0.11+
    # See: https://reproducible-builds.org/docs/source-date-epoch/
    SOURCE_DATE_EPOCH = "${SOURCE_DATE_EPOCH}",
  }
}

target "nodejs-common" {
  inherits = ["common"]
  context  = "nodejs"
  contexts = {
    # The digest (sha256 hash) is not platform specific but the digest for the manifest of all platforms.
    # It will be the digest printed when you do: docker pull alpine:3.17.1
    # Not the one displayed on DockerHub.
    # N.B. This should match the value used in <https://github.com/Islandora-Devops/isle-buildkit>
    alpine = "docker-image://alpine:3.20.2@sha256:0a4eaa0eecf5f8c050e5bba433f58c052be7587ee8af3e8b3910ef9ab5fbe9f5"
  }
}

target "nodejs-amd64" {
  inherits   = ["nodejs-common"]
  tags       = tags("nodejs", "amd64")
  cache-from = cacheFrom("nodejs", "amd64")
  platforms  = ["linux/amd64"]
}

target "nodejs-amd64-ci" {
  inherits = ["nodejs-amd64"]
  cache-to = cacheTo("nodejs", "amd64")
}

target "nodejs-arm64" {
  inherits   = ["nodejs-common"]
  tags       = tags("nodejs", "arm64")
  cache-from = cacheFrom("nodejs", "arm64")
  platforms  = ["linux/arm64"]
}

target "nodejs-arm64-ci" {
  inherits = ["nodejs-arm64"]
  cache-to = cacheTo("nodejs", "arm64")
}

target "nodejs" {
  inherits   = ["nodejs-common"]
  cache-from = cacheFrom("nodejs", hostArch())
  tags       = tags("nodejs", "")
}
