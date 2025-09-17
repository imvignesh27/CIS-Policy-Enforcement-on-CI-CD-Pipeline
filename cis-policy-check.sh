# Check All S3 Buckets Have Versioning Enabled
echo "Checking S3 bucket versioning status..."
if jq -e '.planned_values.root_module.resources[] | select(.type=="aws_s3_bucket") | has("values") and (.values.versioning|.enabled==true)' plan.json > /dev/null; then
    echo "All S3 buckets with versioning block have it enabled."
else
    echo "ERROR: One or more S3 buckets do NOT have versioning enabled!" >&2
    exit 1
fi

# Check All EC2 Instances Enforce IMDSv2
echo "Checking EC2 IMDSv2 enforcement..."
if jq -e '.planned_values.root_module.resources[] | select(.type=="aws_instance") | has("values") and .values.metadata_options.http_tokens=="required"' plan.json > /dev/null; then
    echo "All EC2 instances enforce IMDSv2 (http_tokens==required)."
else
    echo "ERROR: One or more EC2 instances do NOT enforce IMDSv2!" >&2
    exit 1
fi
