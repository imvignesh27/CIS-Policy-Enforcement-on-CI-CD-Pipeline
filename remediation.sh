#!/usr/bin/env bash
set -euo pipefail

REGION=${AWS_REGION:-us-east-1}

# get all non-compliant rule names
RULES=$(aws configservice describe-compliance-by-config-rule --region "$REGION" \
  --query 'ComplianceByConfigRules[?Compliance.ComplianceType!=`COMPLIANT`].ConfigRuleName' --output text)

for RULE in $RULES; do
  echo "Processing rule: $RULE"

  # fetch noncompliant resources for this rule
  RESOURCES=$(aws configservice get-compliance-details-by-config-rule --config-rule-name "$RULE" \
    --query 'EvaluationResults[?ComplianceType==`NON_COMPLIANT`].EvaluationResultIdentifier.EvaluationResultQualifier' \
    --output json)

  # Parse and invoke remediation on each resource (max 100 per API call)
  # Build resource-keys payload
  RESOURCE_KEYS=$(echo $RESOURCES | jq -c '[.[] | {resourceType:.resourceType, resourceId:.resourceId}]' )

  if [ "$RESOURCE_KEYS" = "[]" ]; then
    echo "No resource keys for $RULE"
    continue
  fi

  # call start-remediation-execution (this triggers remediation configured for the rule)
  aws configservice start-remediation-execution \
    --config-rule-name "$RULE" \
    --resource-keys "$RESOURCE_KEYS" \
    --region "$REGION"

  echo "Started remediation for $RULE"
done
