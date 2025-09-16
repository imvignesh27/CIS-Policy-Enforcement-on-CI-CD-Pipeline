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
              def rules = ["ec2-imdsv2-check", "vpc-flow-logs-enabled"]
              def nonCompliantRules = []

              for (rule in rules) {
                def status = sh(
                  script: """
                    aws configservice describe-compliance-by-config-rule \
                      --config-rule-names ${rule} \
                      --region $AWS_DEFAULT_REGION \
                      --query 'ComplianceByConfigRules[0].Compliance.ComplianceType' \
                      --output text
                  """,
                  returnStdout: true
                ).trim()

                if (status == "NON_COMPLIANT") {
                  nonCompliantRules << rule
                }
              }

              if (nonCompliantRules.size() > 0) {
                echo "Found non-compliant rules: ${nonCompliantRules.join(', ')}"
                writeFile file: 'noncompliant-rules.txt', text: nonCompliantRules.join(',')
              } else {
                echo "All monitored rules (IMDSv2, VPC Flow Logs) are compliant."
                writeFile file: 'noncompliant-rules.txt', text: ""
              }
            }
          }
        }
      }
    }

    stage('Terraform Apply') {
      when {
        expression { 
          return params.APPLY_TF && fileExists('noncompliant-rules.txt') && readFile('noncompliant-rules.txt').trim() != "" 
        }
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
        if (fileExists('noncompliant-rules.txt')) {
          archiveArtifacts artifacts: 'noncompliant-rules.txt', fingerprint: true
        }
      }
      cleanWs()
    }
  }
}
