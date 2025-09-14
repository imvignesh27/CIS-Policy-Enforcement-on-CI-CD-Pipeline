pipeline {
  agent any

  environment {
    AWS_DEFAULT_REGION = 'ap-south-1'
    SLACK_WEBHOOK = credentials('slack-webhook') // Store webhook securely in Jenkins credentials
    DASHBOARD_PATH = '/home/vignesh/cis-dashboard/data/' // Flask dashboard data folder
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
          sh 'terraform fmt -check'
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
          def result = sh(script: '''
            pip install terraform-compliance --break-system-packages
            terraform-compliance -p plan.json -f features/ | tee compliance-report.txt
          ''', returnStatus: true)

          def violations = readFile('compliance-report.txt').split('\n').findAll { it.contains('FAILED') }
          def critical = violations.findAll { it.toLowerCase().contains('public') || it.contains('0.0.0.0/0') || it.contains('*') || it.toLowerCase().contains('mfa') }
          def high = violations.findAll { it.toLowerCase().contains('encryption') || it.toLowerCase().contains('cloudtrail') || it.toLowerCase().contains('admin') }
          def riskScore = (critical.size() * 5) + (high.size() * 4) + ((violations.size() - critical.size() - high.size()) * 2)
          riskScore = Math.min(riskScore, 100)

          if (riskScore >= 70 || critical.size() > 0) {
            def message = "*🚨 CIS Compliance Alert*\nRisk Score: ${riskScore}/100\n"
            if (critical.size() > 0) {
              message += "*Critical Violations:* ${critical.size()}\n"
              critical.take(5).each { v -> message += "• ${v}\n" }
            } else {
              message += "No critical violations, but overall risk is high.\n"
            }

            sh """
              curl -X POST -H 'Content-type: application/json' \
              --data '{"text": "${message.replaceAll('"', '\\"')}"}' \
              $SLACK_WEBHOOK
            """
          }

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
      sh 'cp plan.json compliance-report.txt $DASHBOARD_PATH'
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
