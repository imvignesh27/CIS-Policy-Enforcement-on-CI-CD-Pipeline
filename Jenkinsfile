pipeline {
  agent any

  environment {
    AWS_DEFAULT_REGION = 'ap-south-1'
  }

  parameters {
    booleanParam(name: 'APPLY_TF', defaultValue: false, description: 'Apply Terraform changes')
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
          credentialsId: 'AWS'
        ]]) {
          sh 'terraform fmt -check'
          sh 'terraform init'
          sh 'terraform validate'
          sh 'terraform plan -out=tfplan.out -var-file=variables.tfvars'
          sh 'terraform show -json tfplan.out > plan.json'
        }
      }
    }

    stage('Terraform Compliance Check') {
      steps {
        script {
          def result = sh(script: '''
            pip install terraform-compliance --break-system-packages
            terraform-compliance -p plan.json -f features/ | tee compliance-report.txt
          ''', returnStatus: true)
          if (result != 0) {
            error("Terraform compliance check failed. Aborting build.")
          }
        }
      }
    }

    stage('Terraform Apply') {
      when {
        expression { return params.APPLY_TF }
      }
      steps {
        input message: 'Apply Terraform changes?', ok: 'Apply'
        withCredentials([[
          $class: 'AmazonWebServicesCredentialsBinding',
          credentialsId: 'AWS'
        ]]) {
          sh 'terraform apply tfplan.out'
        }
      }
    }
  }

  post {
    always {
      archiveArtifacts artifacts: 'plan.json,compliance-report.txt', fingerprint: true
      cleanWs()
    }
    failure {
      echo 'Build failed.'
    }
    success {
      echo 'Build completed successfully.'
    }
  }
}
