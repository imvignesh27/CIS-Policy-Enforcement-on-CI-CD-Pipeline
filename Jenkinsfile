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
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'AWS']]) {
                    catchError(buildResult: 'FAILURE', stageResult: 'FAILURE') {
                        retry(2) {
                            sh '''
                                echo "Formatting Terraform files..."
                                terraform fmt -recursive

                                echo "Initializing Terraform..."
                                terraform init -input=false -no-color

                                echo "Validating Terraform configuration..."
                                terraform validate
                            '''
                        }
                    }
                }
            }
        }

        stage('Fetch Noncompliant Resources') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'AWS']]) {
                    script {
                        echo "Fetching non-compliant resources from AWS Config..."

                        // EC2 IMDSv2 noncompliant instances
                        sh '''
                        aws configservice get-compliance-details-by-config-rule \
                            --config-rule-name EC2_IMDSv2_CHECK \
                            --compliance-types NON_COMPLIANT \
                            --query "EvaluationResults[].EvaluationResultIdentifier.EvaluationResultQualifier.ResourceId" \
                            --output json > noncompliant_ec2.json || echo "No non-compliant EC2 instances"
                        '''

                        // VPC Flow Logs noncompliant VPCs
                        sh '''
                        aws configservice get-compliance-details-by-config-rule \
                            --config-rule-name VPC_FLOW_LOGS_ENABLED \
                            --compliance-types NON_COMPLIANT \
                            --query "EvaluationResults[].EvaluationResultIdentifier.EvaluationResultQualifier.ResourceId" \
                            --output json > noncompliant_vpcs.json || echo "No non-compliant VPCs"
                        '''

                        // S3 Bucket Versioning noncompliant buckets
                        sh '''
                        aws configservice get-compliance-details-by-config-rule \
                            --config-rule-name S3_BUCKET_VERSIONING_ENABLED \
                            --compliance-types NON_COMPLIANT \
                            --query "EvaluationResults[].EvaluationResultIdentifier.EvaluationResultQualifier.ResourceId" \
                            --output json > noncompliant_s3.json || echo "No non-compliant S3 buckets"
                        '''

                        // Read JSON and export as env variables for Terraform
                        env.NONCOMPLIANT_EC2 = readJSON(file: 'noncompliant_ec2.json') ?: '[]'
                        env.NONCOMPLIANT_VPCS = readJSON(file: 'noncompliant_vpcs.json') ?: '[]'
                        env.NONCOMPLIANT_S3 = readJSON(file: 'noncompliant_s3.json') ?: '[]'

                        echo "Non-compliant EC2 Instances: ${env.NONCOMPLIANT_EC2}"
                        echo "Non-compliant VPCs: ${env.NONCOMPLIANT_VPCS}"
                        echo "Non-compliant S3 Buckets: ${env.NONCOMPLIANT_S3}"
                    }
                }
            }
        }

        stage('Generate Terraform Vars') {
            steps {
                script {
                    def tfvarsContent = """
                    vpc_ids = ${env.NONCOMPLIANT_VPCS}
                    s3_bucket_ids = ${env.NONCOMPLIANT_S3}
                    """
                    writeFile file: 'terraform.tfvars', text: tfvarsContent
                    echo "terraform.tfvars created with noncompliant resources"
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'AWS']]) {
                    sh '''
                        echo "Planning Terraform remediation..."
                        terraform plan -input=false -no-color -var-file=terraform.tfvars -out=tfplan.out
                        terraform show -json tfplan.out > plan.json
                    '''
                    archiveArtifacts artifacts: 'plan.json', fingerprint: true
                }
            }
        }

        stage('Terraform Apply') {
            when { expression { return params.APPLY_TF } }
            steps {
                input message: 'Apply Terraform changes?', ok: 'Apply'
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'AWS']]) {
                    sh '''
                        echo "Applying Terraform remediation..."
                        terraform apply -input=false -no-color tfplan.out
                    '''
                }
            }
        }
    }

    post {
        failure { echo "Build failed. Check the logs!" }
        always {
            cleanWs()
        }
    }
}
