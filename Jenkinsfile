pipeline {
  agent {
    node {
      label 'rundeck'
      customWorkspace '/mnt/ephemeral/jenkins/workspace/' + env.JOB_NAME
    }
  }

  options {
    ansiColor('xterm')
    timestamps()
  }

  environment {
    BRANCH_NAME = "${ghprbSourceBranch ? ghprbSourceBranch : GIT_BRANCH.split("/")[1]}"
    ECR_REPO = "899991151204.dkr.ecr.us-east-1.amazonaws.com"
    IMAGE_NAME = 'vault'
    VAULT_VERSION = sh (returnStdout: true, script: "grep '^VERSION=' 0.X/Makefile | awk -F'=' '{print \$2}'").trim()
    VAULT_IMAGE_TAG = "${ECR_REPO}/${IMAGE_NAME}:${VAULT_VERSION}"
    IMAGE_SCAN_RESULTS = 'vault-scan-results.json'
    APPROVERS = 'parvez.kazi@coupa.com,ramesh.sencha@coupa.com,marutinandan.pandya@coupa.com'
  }

  stages {
    stage('Dockerfile Lint') {
      steps {
        sh label: "Lint Vault Dockerfile", script: "/usr/bin/docker run --rm -i hadolint/hadolint hadolint --no-fail - < 0.X/Dockerfile"
      }
    }

    stage('Build Image') {
      steps {
        sh label: "Build Vault Image", script: "/usr/bin/make image -f 0.X/Makefile"
      }
    }

    stage('Scan Image') {
      steps {
        echo 'Scanning Vault image using Twistlock plugin'
        prismaCloudScanImage ca: '',
        cert: '',
        dockerAddress: 'unix:///var/run/docker.sock',
        image: "${VAULT_IMAGE_TAG}",
        key: '',
        logLevel: 'info',
        podmanPath: '',
        project: '',
        resultsFile: "${IMAGE_SCAN_RESULTS}",
        ignoreImageBuildTime: true
        echo 'Scanning completed for vulnerabilities in the image!!'
      }
    }

    stage('Push Image') {
      when { expression { BRANCH_NAME == 'master' } }
      steps {
        withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', accessKeyVariable: 'AWS_ACCESS_KEY_ID', credentialsId: 'ECR_PUSH_COUPADEV', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY']]) {
          sh label: "Push Vault Image", script: "/usr/bin/make publish -f 0.X/Makefile"
        }
      }
    }

    stage('Upgrade CE Vault Cluster') {
      when { expression { BRANCH_NAME == 'master' } }
      steps {
        sh label: "Upgrade Dev Vault cluster", script: "echo 'Here we will be deploying $VAULT_IMAGE_TAG to CE vault cluster'"
      }
    }

    stage('Integration Tests') {
      when { expression { BRANCH_NAME == 'master' } }
      steps {
        sh label: "Integration Tests", script: "echo 'Here we will be running integration tests against Dev vault cluster'"
      }
    }

    stage('Send Slack notification') {
      when { expression { BRANCH_NAME == 'master' } }
      steps {
        echo 'Sending Slack notification for approval....'
        slackSend (
          channel: '#parveztest',
          color: 'good',
          message: "Vault CD Pipeline - Waiting for manual approval from any of ${env.APPROVERS.split(',').collect { '@' + it.trim().replace('@coupa.com', '') }.join(',')} to upgrade Dev Vault clusters to ${env.VAULT_VERSION} version : '${env.JOB_NAME}' (${env.BUILD_NUMBER})! (<${env.RUN_DISPLAY_URL}|Open>)"
        )
        echo 'Sent Slack notification for approval!!'
      }
    }

    stage('Upgrade Dev Clusters') {
      when {
        expression { BRANCH_NAME == 'master' }
        beforeInput true
        beforeOptions true
      }
      options {
        timeout(time: 24, unit: "HOURS")
      }
      input {
        message "Should we continue to upgrade ALL Vault Dev clusters with new version ${env.VAULT_VERSION}?"
        ok "Yes, we should."
        submitter "${env.APPROVERS}"
      }
      steps {
        sh label: "Integration Tests", script: """
          echo "Upgrading ALL dev vault clusters with version ${VAULT_VERSION}..."
          echo 'Here we will be running integration tests against Dev vault cluster'
        """
      }
    }
  }

  post {
    success {
      prismaCloudPublish resultsFilePattern: "${IMAGE_SCAN_RESULTS}"
    }

    always {
      notifyBuild(currentBuild.currentResult, 'imageVulnerabilities')
    }
  }
}
