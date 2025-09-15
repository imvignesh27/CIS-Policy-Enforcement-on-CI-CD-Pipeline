pipeline {
  agent any
  environment {
    AWS_DEFAULT_REGION = 'ap-south-1'
  }
  parameters {
    booleanParam(name: 'APPLY_TF', defaultValue: false, description: 'Set to true to apply Terraform changes')
  }
  options {
    buildDiscarder(logRotator(numToKeepStr: '10'))
    timeout(time: 45, unit: 'MINUTES')
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
                echo "Formatting Terraform files recursively..."
                terraform fmt -recursive
                echo "Initializing Terraform with no input and no color..."
                terraform init -input=false -no-color
                echo "Validating Terraform files..."
                terraform validate
                echo "Planning Terraform changes with no input and no color..."
                terraform plan -input=false -no-color -out=tfplan.out
                echo "Exporting plan to JSON..."
                terraform show -json tfplan.out > plan.json
              '''
              script {
                if (!fileExists('plan.json')) {
                  error("plan.json not found after terraform show. Aborting.")
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
              def status = sh(script: '''
                echo "🔍 Fetching AWS Config compliance data..."
                aws configservice describe-compliance-by-config-rule \
                  --region $AWS_DEFAULT_REGION \
                  --output json > aws-config-compliance.json
              ''', returnStatus: true)
              if (status != 0 || !fileExists('aws-config-compliance.json')) {
                error("Failed to fetch AWS Config compliance data.")
              }
              def complianceData = readFile('aws-config-compliance.json')
              def nonCompliantCount = (complianceData =~ /NON_COMPLIANT/).size()
              echo "✅ AWS Config compliance check complete. Non-compliant rules: ${nonCompliantCount}"
            }
          }
        }
      }
    }
    stage('Terraform Apply') {
      when {
        expression { params.APPLY_TF }
      }
      steps {
        input message: 'Apply Terraform changes?', ok: 'Apply'
        withCredentials([[ $class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'AWS' ]]) {
          sh '''
            echo "Applying Terraform changes with no input and no color..."
            terraform apply -input=false -no-color tfplan.out
          '''
          echo " Terraform apply completed successfully."
        }
      }
    }
  }
  post {
    failure {
      echo "Build failed. Please check the logs for more details."
    }
    always {
      script {
        archiveArtifacts artifacts: 'plan.json,aws-config-compliance.json', allowEmptyArchive: true, fingerprint: true
      }
      cleanWs()
    }
  }
}
