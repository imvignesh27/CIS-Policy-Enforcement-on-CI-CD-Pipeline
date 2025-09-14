pipeline {
    agent any

    environment {
        SLACK_WEBHOOK = credentials('slack-webhook') // Optional
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
                        echo ">> Running terraform init"
                        terraform init

                        echo ">> Creating plan"
                        terraform plan -out=tfplan

                        echo ">> Generating plan.json"
                        terraform show -json tfplan > plan.json
                    '''
                }
            }
        }

        stage('Terraform Compliance Check') {
            steps {
                sh '''
                    echo ">> Running terraform-compliance"
                    terraform-compliance -p plan.json -f compliance/ > compliance-report.txt || true
                '''
            }
        }

        stage('Terraform Apply') {
            steps {
                input message: "Do you want to apply the Terraform changes?"
                sh 'terraform apply -auto-approve tfplan'
            }
        }
    }

    post {
        always {
            node {
                script {
                    echo ">> Archiving files"
                    archiveArtifacts artifacts: 'plan.json, compliance-report.txt', fingerprint: true

                    if (fileExists('plan.json') && fileExists('compliance-report.txt')) {
                        def targetPath = '/var/lib/jenkins/cis-dashboard/data/'
                        echo ">> Copying plan.json and compliance-report.txt to $targetPath"
                        sh "cp plan.json compliance-report.txt ${targetPath}"
                    } else {
                        echo ">> Skipping file copy: plan.json or compliance-report.txt not found."
                    }

                    cleanWs()
                }
            }
        }

        success {
            echo "✅ Build succeeded."
        }

        failure {
            echo "❌ Build failed."
        }
    }
}
