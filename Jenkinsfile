pipeline {
  agent any
  environment {
    AWS_DEFAULT_REGION = 'a--south-1'
    AWS_CREDENTIALS = credentials('aws-creds-id')  // Ensure this credential ID exists
    SLACK_WEBHOOK = credentials('slack-webhook')
  }
  options {
    buildDiscarder(logRotator(numToKeepStr: '10'))
    timeout(time: 30, unit: 'MINUTES')
  }
  triggers {
    pollSCM('H/10 * * * *')
  }
  stages {
    stage('Checkout SCM') {
      steps {
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
      node {
        script {
          def message = "Terraform deployment for main branch failed."
          def payload = """{
            \"text\": \"${message}\"
          }"""
          sh "curl -X POST -H 'Content-type: application/json' --data '${payload}' ${env.SLACK_WEBHOOK}"
        }
      }
    }
    always {
      node {
        archiveArtifacts artifacts: '**/*.tfplan,**/*.tfstate,**/*.log', allowEmptyArchive: true
        cleanWs()
      }
    }
  }
}
