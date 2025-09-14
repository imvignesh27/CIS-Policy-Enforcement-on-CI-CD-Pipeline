Feature: Enforce CIS controls for EC2 instances

  Scenario: Ensure EC2 instances use approved AMIs
    Given I have aws_instance defined
    Then it must contain ami
    And its value must match the regex "^ami-[a-zA-Z0-9]+$"

  Scenario: Ensure EC2 instances have monitoring enabled
    Given I have aws_instance defined
    Then it must contain monitoring
    And its value must be true
