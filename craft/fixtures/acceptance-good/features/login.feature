Feature: Login
  Scenario: Valid user signs in
    Given a registered user exists
    When the user signs in with valid credentials
    Then the dashboard is shown
