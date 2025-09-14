Feature: Enforce CIS controls for VPC

  Scenario: Ensure VPC has flow logs enabled
    Given I have aws_flow_log defined
    Then it must contain traffic_type
    And its value must be "ALL"

  Scenario: Ensure VPC does not allow unrestricted access
    Given I have aws_security_group defined
    When it contains ingress
    Then its value must not contain "cidr_blocks = [\"0.0.0.0/0\"]"
