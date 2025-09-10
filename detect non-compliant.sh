#!/usr/bin/env bash
set -euo pipefail

REGION=${AWS_REGION:-us-east-1}

# get all rules compliance summary
aws configservice describe-compliance-by-config-rule \
  --region "$REGION" \
  --output json > /tmp/config_compliance.json

# list noncompliant rules (name + compliantCount)
jq -r '.ComplianceByConfigRules[] | select(.Compliance.ComplianceType!="COMPLIANT") | .ConfigRuleName' /tmp/config_compliance.json
