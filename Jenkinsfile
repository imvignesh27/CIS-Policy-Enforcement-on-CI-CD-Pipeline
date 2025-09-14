pipeline {
  agent any

  environment {
    AWS_DEFAULT_REGION = 'ap-south-1'
    // This injects the credentials as environment variables AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY
  }

  stages {
    stage('Checkout') {
      steps {
        git 'https://github.com/your-org/your-terraform-repo.git'
      }
    }

    stage('Terraform Init & Plan') {
      steps {
        withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds-id']]) {
          sh 'terraform init'
          sh 'terraform plan -out=tfplan.out'
          sh 'terraform show -json tfplan.out > plan.json'
        }
      }
    }
  }
}
