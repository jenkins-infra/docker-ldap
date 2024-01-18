group "default" {
  targets = ["infra-ci", "weekly-ci"]
}

variable "IMAGE_DEPLOY_NAME" {}

variable "TAG_NAME" {
  default = ""
}

variable "REGISTRY" {
  default = "docker.io"
}

variable "PLUGINS_FILE" {
  default = "plugins-infra.ci.jenkins.io.txt"
}

target "infra-ci" {
  platforms = ["linux/amd64", "linux/arm64"]
  tags = [
    "${REGISTRY}/${IMAGE_DEPLOY_NAME}:latest",
    notequal("", TAG_NAME) ? "${REGISTRY}/${IMAGE_DEPLOY_NAME}:${TAG_NAME}" : ""
  ]
}

target "weekly-ci" {
  inherits = ["infra-ci"]
  args = {
    PLUGINS_FILE = "plugins-weekly.ci.jenkins.io.txt",
  }
  tags = [
    "${REGISTRY}/${IMAGE_DEPLOY_NAME}:latest-weeklyci",
    notequal("", TAG_NAME) ? "${REGISTRY}/${IMAGE_DEPLOY_NAME}:${TAG_NAME}-weeklyci" : ""
  ]
}
