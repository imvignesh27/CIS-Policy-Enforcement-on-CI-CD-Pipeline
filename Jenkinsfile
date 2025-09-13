pipeline {
  agent any

  environment {
    AWS_REGION = 'ap-south-1'
    TF_WORKSPACE = 'default'
  }

  stages {
    stage('Terraform Init') {
      steps {
        sh '''
          terraform init
          terraform workspace select ${TF_WORKSPACE} || terraform workspace new ${TF_WORKSPACE}
        '''
      }
    }
}

  stages {
    stage('Terraform plan') {
      steps {
        sh '''
          terraform plan
          terraform workspace select ${TF_WORKSPACE} || terraform workspace new ${TF_WORKSPACE}
        '''
      }
    }
}
