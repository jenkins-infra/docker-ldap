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
            env.BASE_IMAGE = "${imageName}:${imageTag}"
            env.CRON_IMAGE = "${imageName}:cron-${imageTag}"
            echo "Creating the container ${env.BASE_IMAGE}"
            containerBase = docker.build("${env.BASE_IMAGE}")
            containerCron = docker.build("${env.CRON_IMAGE}", "--build-arg BASE_IMAGE=${env.BASE_IMAGE} -f Dockerfile.cron .")
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

