pipeline {
  agent any
  environment {
    AWS_DEFAULT_REGION = 'ap-south-1'
    AWS_CREDENTIALS = credentials('aws-creds-id')    // If using Jenkins stored credentials
  }
  stages {
    stage('Checkout') {
      steps {
        git 'https://github.com/your-org/your-terraform-repo.git'
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
