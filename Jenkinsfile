#!/usr/bin/env groovy

def imageName = 'jenkinsciinfra/ldap'

properties([
    buildDiscarder(logRotator(numToKeepStr: '5', artifactNumToKeepStr: '5')),
    pipelineTriggers([[$class:"SCMTrigger", scmpoll_spec:"H/15 * * * *"]]),
])

node('docker') {
    checkout scm
    def containerBase
    def containerCron
    stage('Prepare Container') {
        timestamps {
            sh 'git rev-parse HEAD > GIT_COMMIT'
            shortCommit = readFile('GIT_COMMIT').take(6)
            def imageTag = "${env.BUILD_ID}-build${shortCommit}"
            echo "Creating the container ${imageName}:${imageTag}"
            containerBase = docker.build("${imageName}:${imageTag}")
            containerCron = docker.build("${imageName}:cron-${imageTag}", "--build-arg BASE_IMAGE=${imageName}:${imageTag} -f Dockerfile.cron .")
        }
    }

    /* Assuming we're not inside of a pull request or multibranch pipeline */
    if (!(env.CHANGE_ID || env.BRANCH_NAME)) {
        stage('Publish container') {
            infra.withDockerCredentials {
                timestamps {
                  containerBase.push()
                  containerCron.push()
                }
            }
        }
    }
}

