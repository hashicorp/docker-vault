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
    VAULT_VERSION = sh (returnStdout: true, script: "./cd.sh vaultImageVersion").trim()
    VAULT_IMAGE_TAG = sh (returnStdout: true, script: "./cd.sh vaultImageTag").trim()
    IMAGE_SCAN_RESULTS = 'vault-scan-results.json'
    APPROVERS = 'parvez.kazi@coupa.com,ramesh.sencha@coupa.com,marutinandan.pandya@coupa.com'
  }

  stages {
    stage('Dockerfile Lint') {
      steps {
        sh label: "Lint Vault Dockerfile", script: "./cd.sh vaultDockerfileLint"
      }
    }

    stage('Build Image') {
      steps {
        sh label: "Build Vault Image", script: "./cd.sh vaultImageBuild"
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
          sh label: "Push Vault Image", script: "./cd.sh vaultImagePush"
        }
      }
    }

    stage('Upgrade CE Vault Cluster') {
      when { expression { BRANCH_NAME == 'master' } }
      steps {
        sh label: "Upgrade CE Vault cluster", script: "./cd.sh upgradeCEVaultCluster"
      }
    }

    stage('Integration Tests') {
      when { expression { BRANCH_NAME == 'master' } }
      steps {
        sh label: "Integration Tests", script: "./cd.sh vaultIntegrationTests"
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
        sh label: "Upgrade AWS Dev Clusters", script: "./cd.sh upgradeDevVaultClusters"
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
