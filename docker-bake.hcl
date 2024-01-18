group "default" {
  targets = [
    "ldap",
    "ldap-cron",
  ]
}

variable "IMAGE_NAME" {
  default = "ldap"
}

variable "TAG_NAME" {
  default = ""
}

variable "REGISTRY" {
  default = "docker.io"
}

variable "GIT_COMMIT_REV" {
  default = ""
}
variable "GIT_SCM_URL" {
  default = ""
}
variable "BUILD_DATE" {
  default = ""
}
variable "SCM_URI" {
  default = ""
}

variable "GIT_TREE_STATE" {
  default = ""
}

target "ldap" {
  dockerfile = "Dockerfile"
  context = "."
  target = "ldap"
  platforms = ["linux/amd64"]
  tags = [
    "${REGISTRY}/${IMAGE_NAME}:latest",
    notequal("", TAG_NAME) ? "${REGISTRY}/${IMAGE_NAME}:${TAG_NAME}" : ""
  ]
  args = {
    GIT_COMMIT_REV="${GIT_COMMIT_REV}",
    GIT_SCM_URL="${GIT_SCM_URL}",
    BUILD_DATE="${BUILD_DATE}",
  }
  labels = {
    "org.opencontainers.image.source"="${GIT_SCM_URL}",
    "org.label-schema.vcs-url"="${GIT_SCM_URL}",
    "org.opencontainers.image.url"="${SCM_URI}",
    "org.label-schema.url"="${SCM_URI}",
    "org.opencontainers.image.revision"="${GIT_COMMIT_REV}",
    "org.label-schema.vcs-ref"="${GIT_COMMIT_REV}",
    "org.opencontainers.image.created"="${BUILD_DATE}",
    "org.label-schema.build-date"="${BUILD_DATE}",
    "io.jenkins-tools.tree.state"="${GIT_TREE_STATE}"
  }
}

target "ldap-cron" {
  dockerfile = "Dockerfile"
  context = "."
  target = "ldap"
  platforms = ["linux/amd64"]
  tags = [
    "${REGISTRY}/${IMAGE_NAME}:cron-latest",
    notequal("", TAG_NAME) ? "${REGISTRY}/${IMAGE_NAME}:cron-${TAG_NAME}" : ""
  ]
}
