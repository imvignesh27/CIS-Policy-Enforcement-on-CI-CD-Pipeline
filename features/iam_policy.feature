Feature: Enforce least privilege in IAM policies

  Scenario: Deny wildcard actions in IAM policies
    Given I have aws_iam_policy defined
    When it contains policy
    Then its value must not match the regex ".*\*.*"
