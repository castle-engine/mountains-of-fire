/* -*- mode: groovy -*-
  Confgure how to run our job in Jenkins.
  See https://github.com/castle-engine/castle-engine/wiki/Cloud-Builds-(Jenkins) .
*/

pipeline {
  triggers {
    pollSCM('H/4 * * * *')
    upstream(upstreamProjects: 'castle_game_engine_update_docker_image', threshold: hudson.model.Result.SUCCESS)
  }
  agent {
    docker {
      image 'kambi/castle-engine-cloud-builds-tools:cge-unstable'
    }
  }
  stages {
    stage('Build Desktop') {
      steps {
        sh 'rm -f mountains_of_fire-*.tar.gz mountains_of_fire-*.zip mountains_of_fire*.apk'
	sh 'castle-engine auto-generate-textures'
        sh 'castle-engine package --os=win64 --cpu=x86_64 --verbose'
        sh 'castle-engine package --os=win32 --cpu=i386 --verbose'
        sh 'castle-engine package --os=linux --cpu=x86_64 --verbose'
      }
    }
  }
  post {
    success {
      archiveArtifacts artifacts: 'mountains_of_fire*.tar.gz,mountains_of_fire*.zip,mountains_of_fire*.apk'
    }
    regression {
      mail to: 'michalis@castle-engine.io',
        subject: "[jenkins] Build started failing: ${currentBuild.fullDisplayName}",
        body: "See the build details on ${env.BUILD_URL}"
    }
    failure {
      mail to: 'michalis@castle-engine.io',
        subject: "[jenkins] Build failed: ${currentBuild.fullDisplayName}",
        body: "See the build details on ${env.BUILD_URL}"
    }
    fixed {
      mail to: 'michalis@castle-engine.io',
        subject: "[jenkins] Build is again successfull: ${currentBuild.fullDisplayName}",
        body: "See the build details on ${env.BUILD_URL}"
    }
  }
}
