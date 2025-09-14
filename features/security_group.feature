Feature: Restrict open access in security groups

  Scenario: No open ingress from 0.0.0.0/0 on sensitive ports
    Given I have aws_security_group defined
    When it contains ingress
    Then its value must not contain "cidr_blocks = [\"0.0.0.0/0\"]"
    And its value must not contain "from_port = 22"
    And its value must not contain "from_port = 3389"
