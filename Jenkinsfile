pipeline {
  agent any
  environment {
    AWS_DEFAULT_REGION = 'ap-south-1'
    SLACK_WEBHOOK = credentials('slack-webhook')
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
        withCredentials([[
          $class: 'AmazonWebServicesCredentialsBinding',
          credentialsId: 'AWS'
        ]]) {
          sh 'terraform fmt'
          sh 'terraform init'
          sh 'terraform validate'
          sh 'terraform plan -out=tfplan.out'
          sh 'terraform show -json tfplan.out > plan.json'
        }
      }
    }
    stage('Terraform Compliance Check') {
      steps {
        script {
          def status = sh(script: '''
            pip install terraform-compliance --break-system-packages
            terraform-compliance -p plan.json -f features/ | tee compliance-report.txt
          ''', returnStatus: true)
          if (status != 0) {
            def message = "❌ Terraform compliance checks failed."
            slackNotify(message)
            error message
          } else {
            def message = "✅ Terraform compliance checks passed."
            slackNotify(message)
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
          script {
            slackNotify("✅ Terraform apply completed successfully.")
          }
        }
      }
    }
  }
  post {
    failure {
      script {
        slackNotify("❌ Build failed.")
      }
    }
    always {
      script {
        archiveArtifacts artifacts: 'plan.json,compliance-report.txt', fingerprint: true
        cleanWs()
      }
    }
  }
}

// Slack notification helper function
def slackNotify(String message) {
  sh """
    curl -X POST -H 'Content-type: application/json' --data '{\"text\": \"${message}\"}' ${env.SLACK_WEBHOOK}
  """
}
