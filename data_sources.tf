data "external" "noncompliant_ec2" {
  program = [
    "bash", "-c",
    <<EOT
      aws configservice get-compliance-details-by-config-rule \
        --config-rule-name ec2-instance-imdsv2-check \
        --compliance-types NON_COMPLIANT \
        --region ${AWS_REGION:-ap-south-1} \
        --query 'EvaluationResults[].EvaluationResultIdentifier.EvaluationResultQualifier.ResourceId' \
        --output json
    EOT
  ]
}

data "external" "noncompliant_vpcs" {
  program = [
    "bash", "-c",
    <<EOT
      aws configservice get-compliance-details-by-config-rule \
        --config-rule-name vpc-flow-logs-enabled \
        --compliance-types NON_COMPLIANT \
        --region ${AWS_REGION:-ap-south-1} \
        --query 'EvaluationResults[].EvaluationResultIdentifier.EvaluationResultQualifier.ResourceId' \
        --output json
    EOT
  ]
}
