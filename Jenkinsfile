pipeline {
  agent any

  environment {
    AWS_DEFAULT_REGION = 'ap-south-1'
  }

  parameters {
    booleanParam(name: 'APPLY_TF', defaultValue: false, description: 'Set to true to apply Terraform changes')
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
        withCredentials([[ $class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'AWS' ]]) {
          script {
            try {
              sh 'terraform fmt'
              sh 'terraform init'
              sh 'terraform validate'
              sh 'terraform plan -out=tfplan.out'
              sh 'terraform show -json tfplan.out > plan.json'
              if (!fileExists('plan.json')) {
                error("plan.json not found. Aborting.")
              }
            } catch (err) {
              error("Terraform Init & Plan failed: ${err}")
            }
          }
        }
      }
    }

    stage('AWS Config Compliance Check') {
      steps {
        withCredentials([[ $class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'AWS' ]]) {
          script {
            def result = sh(script: '''
              aws configservice describe-compliance-by-config-rule \
                --region $AWS_DEFAULT_REGION \
                --output json > aws-config-compliance.json
            ''', returnStatus: true)

            if (result != 0 || !fileExists('aws-config-compliance.json')) {
              error("AWS Config compliance check failed.")
            }

            def complianceData = readFile('aws-config-compliance.json')
            def nonCompliantCount = complianceData.count("NON_COMPLIANT")

            echo "AWS Config compliance check completed. Non-compliant rules: ${nonCompliantCount}"
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
        withCredentials([[ $class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'AWS' ]]) {
          sh 'terraform apply tfplan.out'
          echo "Terraform apply completed successfully."
        }
      }
    }
  }

  post {
    failure {
      echo "Build failed."
    }
    always {
      archiveArtifacts artifacts: 'plan.json,aws-config-compliance.json', fingerprint: true
      cleanWs()
    }
  }
}
