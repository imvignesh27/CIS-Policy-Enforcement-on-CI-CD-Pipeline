pipeline {
  agent any

  environment {
    AWS_REGION = 'ap-south-1'
    TF_WORKSPACE = 'default'
  }

  stages {
    stage('Clone Terraform Repo from GitHub') {
      steps {
        git branch: 'main',
            url: 'https://github.com/your-org/your-terraform-repo.git'
      }
    }

    stage('Terraform Init') {
      steps {
        sh '''
          terraform init
          terraform workspace select ${TF_WORKSPACE} || terraform workspace new ${TF_WORKSPACE}
        '''
      }
    }
