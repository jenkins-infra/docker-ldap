pipeline {
  agent {
    label 'docker&&linux'
  }

  options {
    buildDiscarder logRotator(artifactDaysToKeepStr: '', artifactNumToKeepStr: '', daysToKeepStr: '', numToKeepStr: '10')
    timeout(time: 1, unit: 'HOURS')
    timestamps()
  }

  triggers {
    pollSCM('H/15 * * * *')
  }

  stages {
    stage('Build') {
      steps {
          sh 'make build'
      }
    }
    stage('Publish'){
      when {
        environment name: 'JENKINS_URL', value: 'https://trusted.ci.jenkins.io:1443/'
      }
      steps {
        script {
          infra.withDockerCredentials {
            sh 'make publish'
          }
        }
      }
    }
  }
}

