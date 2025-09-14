pipeline {
  agent any

  environment {
    AWS_DEFAULT_REGION = 'ap-south-1'
  }

  stages {
    stage('Checkout Code') {
      steps {
        // This repo is public, so no credentials needed.
        git branch: 'main',
            url: 'https://github.com/imvignesh27/CIS-Policy-Enforcement-on-CI-CD-Pipeline.git'
      }
    }

    stage('Terraform Init & Plan') {
      steps {
        withCredentials([[ 
          $class: 'AmazonWebServicesCredentialsBinding', 
          credentialsId: 'AWS' // Replace with your actual AWS creds ID in Jenkins
        ]]) {
          sh 'terraform init'
          // Use the .tfvars file for Terraform plan
          sh 'terraform plan -out=tfplan.out -var-file=variables.tfvars'
          sh 'terraform show -json tfplan.out > plan.json'
        }
      }
    }
  }

  post {
    failure {
      echo 'Build failed.'
    }
    success {
      echo 'Build completed successfully.'
    }
  }
}
