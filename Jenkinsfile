pipeline {
  agent any

  environment {
    AWS_DEFAULT_REGION = 'us-east-1'
    AWS_CREDENTIALS = credentials('aws-creds-id')
    SLACK_WEBHOOK = credentials('slack-webhook')
  }

  options {
    // Keep only last 10 builds
    buildDiscarder(logRotator(numToKeepStr: '10'))
    // Timeout after 30 minutes
    timeout(time: 30, unit: 'MINUTES')
  }

  triggers {
    pollSCM('H/10 * * * *') // Poll Git every 10 minutes
  }

  stages {
    stage('Checkout SCM') {
      steps {
        // Checkout main branch explicitly
        git branch: 'main', url: 'https://github.com/imvignesh27/CIS-Policy-Enforcement-on-CI-CD-Pipeline.git'
      }
    }

    stage('Terraform Init') {
      steps {
        withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: "${env.AWS_CREDENTIALS}"]]) {
          sh 'terraform init'
        }
      }
    }

    stage('Terraform Plan') {
      steps {
        withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: "${env.AWS_CREDENTIALS}"]]) {
          sh 'terraform plan -out=tfplan.out'
        }
      }
    }

    stage('Terraform Apply') {
      steps {
        withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: "${env.AWS_CREDENTIALS}"]]) {
          sh 'terraform apply -auto-approve tfplan.out'
        }
      }
    }

    stage('Notify Slack') {
      steps {
        script {
          def message = "Terraform deployment for main branch completed successfully!"
          def payload = """{
            \"text\": \"${message}\"
          }"""
          sh "curl -X POST -H 'Content-type: application/json' --data '${payload}' ${env.SLACK_WEBHOOK}"
        }
      }
    }
  }

  post {
    failure {
      script {
        def message = "Terraform deployment for main branch failed."
        def payload = """{
          \"text\": \"${message}\"
        }"""
        sh "curl -X POST -H 'Content-type: application/json' --data '${payload}' ${env.SLACK_WEBHOOK}"
      }
    }
    always {
      archiveArtifacts artifacts: '**/*.tfplan,**/*.tfstate,**/*.log', allowEmptyArchive: true
      cleanWs()
    }
  }
}
