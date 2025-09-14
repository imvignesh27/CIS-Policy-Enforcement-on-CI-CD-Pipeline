pipeline {
  agent any

  environment {
    AWS_DEFAULT_REGION = 'ap-south-1'
  }

  stages {
    stage('Checkout Code') {
      steps {
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
          sh 'terraform plan -out=tfplan.out -var-file=terraform.tfvars'  // Reference tfvars file
        }
      }
    }

    stage('Terraform Apply') {
      when {
        expression { return params.APPLY_TF == true }
      }
      steps {
        input message: 'Apply Terraform changes?', ok: 'Apply'
        withCredentials([[
          $class: 'AmazonWebServicesCredentialsBinding',
          credentialsId: 'AWS'
        ]]) {
          sh 'terraform apply -var-file=terraform.tfvars tfplan.out'  // Reference tfvars file
        }
      }
    }
  }

  parameters {
    booleanParam(name: 'APPLY_TF', defaultValue: false, description: 'Set to true to apply Terraform changes')
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
