pipeline {
    agent any

    environment {
        // Slack webhook and AWS credentials (masked)
        SLACK_WEBHOOK = credentials('slack-webhook')
        AWS_ACCESS_KEY_ID = credentials('aws-access-key-id')
        AWS_SECRET_ACCESS_KEY = credentials('aws-secret-access-key')
    }

    stages {
        stage('Checkout Code') {
            steps {
                git url: 'https://github.com/imvignesh27/CIS-Policy-Enforcement-on-CI-CD-Pipeline.git', branch: 'main'
            }
        }

        stage('Terraform Init & Plan') {
            steps {
                withCredentials([
                    string(credentialsId: 'aws-access-key-id', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'aws-secret-access-key', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    sh '''
                        terraform init
                        terraform plan -out=tfplan
                        terraform show -json tfplan > plan.json
                    '''
                }
            }
        }

        stage('Terraform Compliance Check') {
            steps {
                sh '''
                    terraform-compliance -p plan.json -f compliance/ > compliance-report.txt
                '''
            }
        }

        stage('Terraform Apply') {
            steps {
                input message: "Do you want to apply the changes?"
                sh 'terraform apply -auto-approve tfplan'
            }
        }
    }

    post {
        always {
            archiveArtifacts artifacts: 'plan.json, compliance-report.txt', fingerprint: true

            script {
                if (fileExists('plan.json') && fileExists('compliance-report.txt')) {
                    sh 'cp plan.json compliance-report.txt /var/lib/jenkins/cis-dashboard/data/'
                } else {
                    echo "Skipping file copy: plan.json or compliance-report.txt not found."
                }
            }

            cleanWs()
            echo "Build completed."
        }

        failure {
            echo "Build failed."
        }

        success {
            echo "Build succeeded."
        }
    }
}
