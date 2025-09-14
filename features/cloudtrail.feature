Feature: Ensure CloudTrail is enabled

  Scenario: CloudTrail must be configured
    Given I have aws_cloudtrail defined
    Then it must contain is_multi_region_trail
    And its value must be true
