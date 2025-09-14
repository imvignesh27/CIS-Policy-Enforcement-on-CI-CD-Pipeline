pipeline {
  agent any
  environment {
    AWS_DEFAULT_REGION = 'ap-south-1'
    AWS_CREDENTIALS = credentials('AWS')    // If using Jenkins stored credentials
  }
  stages {
    stage('Checkout') {
      steps {
        git branch: 'main',
        git 'https://github.com/imvignesh27/CIS-Policy-Enforcement-on-CI-CD-Pipeline.git'
      }
    }
    stage('Terraform Init') {
      steps {
        sh 'terraform init'
      }
    }
    stage('Terraform Plan') {
      steps {
        sh 'terraform plan -out=tfplan.out'
      }
    }
    stage('Terraform Apply') {
      steps {
        sh 'terraform apply -auto-approve tfplan.out'
      }
    }
  }
}
