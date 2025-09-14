pipeline {
  agent any
  environment {
    AWS_DEFAULT_REGION = 'ap-south-1'
    AWS_CREDENTIALS = credentials('aws-creds-id')
  }
  stages {
    stage('Checkout') {
      steps {
        git 'https://github.com/your-org/your-terraform-repo.git'
      }
    }
    stage('Terraform Init & Plan') {
      steps {
        sh 'terraform init'
        sh 'terraform plan -out=tfplan.out'
        sh 'terraform show -json tfplan.out > plan.json'
      }
    }
  } 
}
