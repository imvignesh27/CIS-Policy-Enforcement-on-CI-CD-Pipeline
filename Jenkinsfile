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
          catchError(buildResult: 'FAILURE', stageResult: 'FAILURE') {
            retry(2) {
              sh '''
                echo "Formatting Terraform files..."
                terraform fmt -recursive

                echo "Initializing Terraform..."
                terraform init -input=false -no-color

                echo "Validating Terraform configuration..."
                terraform validate

                echo "Planning Terraform changes..."
                terraform plan -input=false -no-color -out=tfplan.out

                echo "Exporting plan to JSON..."
                terraform show -json tfplan.out > plan.json
              '''
              script {
                if (!fileExists('plan.json')) {
                  error("plan.json not found. Aborting.")
                }
              }
            }
          }
        }
      }
    }

    stage('AWS Config Compliance Check') {
      steps {
        withCredentials([[ $class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'AWS' ]]) {
          catchError(buildResult: 'FAILURE', stageResult: 'FAILURE') {
            script {
              def result = sh(script: '''
                echo "🔍 Running AWS Config compliance check..."
                aws configservice describe-compliance-by-config-rule \
                  --region $AWS_DEFAULT_REGION \
                  --output json > aws-config-compliance.json
              ''', returnStatus: true)

              if (result != 0 || !fileExists('aws-config-compliance.json')) {
                error("AWS Config compliance check failed.")
              }

              def complianceData = readFile('aws-config-compliance.json')
              def nonCompliantCount = complianceData.count("NON_COMPLIANT")

              echo "Compliance check completed. Non-compliant rules: ${nonCompliantCount}"
            }
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
          sh '''
            echo "Applying Terraform changes..."
            terraform apply -input=false -no-color tfplan.out
          '''
          echo "Terraform apply completed successfully."
        }
      }
    }
  }

  post {
    failure {
      echo "Build failed. Please review the logs."
    }
    always {
      script {
        if (fileExists('plan.json')) {
          archiveArtifacts artifacts: 'plan.json', fingerprint: true
        }
        if (fileExists('aws-config-compliance.json')) {
          archiveArtifacts artifacts: 'aws-config-compliance.json', fingerprint: true
        }
      }
      cleanWs()
    }
  }
}
