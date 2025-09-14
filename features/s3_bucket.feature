
Feature: Enforce CIS controls for S3 buckets

  Scenario: Ensure S3 buckets are not public
    Given I have aws_s3_bucket defined
    Then it must not contain public_access_block_configuration
    And its value must contain "block_public_acls"
    And its value must contain "block_public_policy"

  Scenario: Ensure S3 buckets have encryption enabled
    Given I have aws_s3_bucket defined
    Then it must contain server_side_encryption_configuration
