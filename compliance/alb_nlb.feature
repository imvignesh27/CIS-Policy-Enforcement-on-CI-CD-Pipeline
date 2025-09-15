Feature: Enforce CIS controls for ALB and NLB

  Scenario: Ensure ALB uses HTTPS listener
    Given I have aws_lb_listener defined
    Then it must contain protocol
    And its value must be "HTTPS"

  Scenario: Ensure NLB does not expose sensitive ports
    Given I have aws_lb_listener defined
    Then it must not contain port
    And its value must not be 22
    And its value must not be 3389
