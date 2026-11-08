# language: en
Feature: Clients

  Background:
    Given I log in as user
      | USER               |
      | EXAMPLE_CREDENTIAL |

  Scenario: Create and list clients
    Given I generate a unique value with prefix 'pw-create' and store it in variable 'clientName'
    And I send a POST request to endpoint '/api/clients' with body
      | BODY                                                                                                                                     |
      | {"name":"{clientName}","cpf":"123.456.789-09","dateOfBirth":"1990-01-15","email":"test.playwright@example.com","phone":"+5511999999999"} |
    Then The response status code should be '201'
    And I store response field '$.id' in variable 'clientId'
    And The response field '$.name' should equal '{clientName}'
    When I send a GET request to endpoint '/api/clients?name={clientName}'
    Then The response status code should be '200'
    And The response field '$.totalItems' should equal '1'
    And The response field '$.items[0].name' should equal '{clientName}'
    And The response field '$.items[0].cpf' should equal '123.456.789-09'
    And The response field '$.items[0].dateOfBirth' should equal '1990-01-15'
    And The response field '$.items[0].email' should equal 'test.playwright@example.com'
    And The response field '$.items[0].phone' should equal '+5511999999999'
    When I send a DELETE request to endpoint '/api/clients/{clientId}'
    Then The response status code should be '204'

  Scenario: List clients by name
    Given I generate a unique value with prefix 'pw-list' and store it in variable 'clientName'
    And I send a POST request to endpoint '/api/clients' with body
      | BODY                                                                                                                                 |
      | {"name":"{clientName}","cpf":"101.202.303-40","dateOfBirth":"1990-01-15","email":"list.client@example.com","phone":"+5511999990000"} |
    Then The response status code should be '201'
    And I store response field '$.id' in variable 'clientId'
    When I send a GET request to endpoint '/api/clients?name={clientName}'
    Then The response status code should be '200'
    And The response field '$.totalItems' should equal '1'
    And The response field '$.items[0].name' should equal '{clientName}'
    And The response field '$.items[0].email' should equal 'list.client@example.com'
    When I send a DELETE request to endpoint '/api/clients/{clientId}'
    Then The response status code should be '204'

  Scenario: Get client by ID
    Given I generate a unique value with prefix 'pw-get' and store it in variable 'clientName'
    And I send a POST request to endpoint '/api/clients' with body
      | BODY                                                                                                                                |
      | {"name":"{clientName}","cpf":"111.222.333-44","dateOfBirth":"1991-02-16","email":"get.client@example.com","phone":"+5511988888888"} |
    Then The response status code should be '201'
    And I store response field '$.id' in variable 'clientId'
    When I send a GET request to endpoint '/api/clients/{clientId}'
    Then The response status code should be '200'
    And The response field '$.id' should equal '{clientId}'
    And The response field '$.name' should equal '{clientName}'
    And The response field '$.email' should equal 'get.client@example.com'
    When I send a DELETE request to endpoint '/api/clients/{clientId}'
    Then The response status code should be '204'

  Scenario: Update client
    Given I generate a unique value with prefix 'pw-update-before' and store it in variable 'originalClientName'
    And I generate a unique value with prefix 'pw-update-after' and store it in variable 'updatedClientName'
    And I send a POST request to endpoint '/api/clients' with body
      | BODY                                                                                                                                           |
      | {"name":"{originalClientName}","cpf":"222.333.444-55","dateOfBirth":"1992-03-17","email":"before.update@example.com","phone":"+5511977777777"} |
    Then I store response field '$.id' in variable 'clientId'
    When I send a PUT request to endpoint '/api/clients/{clientId}' with body
      | BODY                                                                                                                                         |
      | {"name":"{updatedClientName}","cpf":"555.444.333-22","dateOfBirth":"1993-04-18","email":"after.update@example.com","phone":"+5511966666666"} |
    Then The response status code should be '200'
    And The response field '$.name' should equal '{updatedClientName}'
    And The response field '$.cpf' should equal '555.444.333-22'
    And The response field '$.dateOfBirth' should equal '1993-04-18'
    And The response field '$.email' should equal 'after.update@example.com'
    And The response field '$.phone' should equal '+5511966666666'
    When I send a GET request to endpoint '/api/clients/{clientId}'
    Then The response field '$.email' should equal 'after.update@example.com'
    When I send a DELETE request to endpoint '/api/clients/{clientId}'
    Then The response status code should be '204'

  Scenario: Delete client
    Given I generate a unique value with prefix 'pw-delete' and store it in variable 'clientName'
    And I send a POST request to endpoint '/api/clients' with body
      | BODY                                                                                                                                   |
      | {"name":"{clientName}","cpf":"333.444.555-66","dateOfBirth":"1994-05-19","email":"delete.client@example.com","phone":"+5511955555555"} |
    Then The response status code should be '201'
    And I store response field '$.id' in variable 'clientId'
    When I send a DELETE request to endpoint '/api/clients/{clientId}'
    Then The response status code should be '204'
    And The response body should be empty
    When I send a GET request to endpoint '/api/clients/{clientId}'
    Then The response status code should be '404'
    And The response field '$.status' should equal '404'
    And The response field '$.code' should equal 'NOT_FOUND'

  Scenario: Bulk delete clients
    Given I generate a unique value with prefix 'pw-bulk-one' and store it in variable 'firstClientName'
    And I generate a unique value with prefix 'pw-bulk-two' and store it in variable 'secondClientName'
    And I send a POST request to endpoint '/api/clients' with body
      | BODY                                                                                                                                   |
      | {"name":"{firstClientName}","cpf":"444.555.666-77","dateOfBirth":"1995-06-20","email":"bulk.one@example.com","phone":"+5511944444444"} |
    Then I store response field '$.id' in variable 'firstClientId'
    When I send a POST request to endpoint '/api/clients' with body
      | BODY                                                                                                                                    |
      | {"name":"{secondClientName}","cpf":"666.555.444-33","dateOfBirth":"1996-07-21","email":"bulk.two@example.com","phone":"+5511933333333"} |
    Then I store response field '$.id' in variable 'secondClientId'
    When I send a POST request to endpoint '/api/clients/delete' with body
      | BODY                                   |
      | ["{firstClientId}","{secondClientId}"] |
    Then The response status code should be '200'
    And The response field '$.deleted' should equal '2'
    And The response field '$.hasLink' should equal '0'
    When I send a GET request to endpoint '/api/clients/{firstClientId}'
    Then The response status code should be '404'

  Scenario: Check client appointment link
    Given I generate a unique value with prefix 'pw-link' and store it in variable 'clientName'
    And I send a POST request to endpoint '/api/clients' with body
      | BODY                                                                                                                                 |
      | {"name":"{clientName}","cpf":"777.888.999-00","dateOfBirth":"1997-08-22","email":"link.client@example.com","phone":"+5511922222222"} |
    Then The response status code should be '201'
    And I store response field '$.id' in variable 'clientId'
    When I send a GET request to endpoint '/api/clients/client-has-link-with-appointment?name={clientName}'
    Then The response status code should be '200'
    And The response field '$' should equal 'false'
    When I send a DELETE request to endpoint '/api/clients/{clientId}'
    Then The response status code should be '204'

  Scenario: Reject client creation without a body
    When I send a POST request to endpoint '/api/clients' without a body
    Then The response status code should be '400'
    And The response field '$.code' should equal 'VALIDATION_ERROR'

  Scenario: Reject a null client creation body
    When I send a POST request to endpoint '/api/clients' with raw body
      | BODY |
      | null |
    Then The response status code should be '400'
    And The response field '$.code' should equal 'VALIDATION_ERROR'

  Scenario Outline: Reject invalid client creation payloads
    When I send a POST request to endpoint '/api/clients' with raw body
      | BODY   |
      | <body> |
    Then The response status code should be '400'
    And The response field '$.code' should equal 'VALIDATION_ERROR'

    Examples:
      | body                                                     |
      | {"name":                                                 |
      | {"name":null}                                            |
      | {"name":""}                                              |
      | {"name":"   "}                                           |
      | {"name":"Invalid Birth Date","dateOfBirth":"2026-02-30"} |

  Scenario: Reject duplicate client name
    Given I generate a unique value with prefix 'pw-duplicate' and store it in variable 'clientName'
    And I send a POST request to endpoint '/api/clients' with body
      | BODY                                                                                                                                      |
      | {"name":"{clientName}","cpf":"888.999.000-11","dateOfBirth":"1998-09-23","email":"duplicate.client@example.com","phone":"+5511911111111"} |
    Then The response status code should be '201'
    And I store response field '$.id' in variable 'clientId'
    When I send a POST request to endpoint '/api/clients' with body
      | BODY                                                                                                                                          |
      | {"name":"  {clientName}  ","cpf":"888.999.000-11","dateOfBirth":"1998-09-23","email":"duplicate.client@example.com","phone":"+5511911111111"} |
    Then The response status code should be '422'
    And The response field '$.code' should equal 'BUSINESS_ERROR'
    When I send a DELETE request to endpoint '/api/clients/{clientId}'
    Then The response status code should be '204'

  Scenario: Reject updating a client to another client name
    Given I generate a unique value with prefix 'Playwright Update Conflict' and store it in variable 'clientPrefix'
    When I send a POST request to endpoint '/api/clients' with body
      | BODY                          |
      | {"name":"{clientPrefix} One"} |
    Then The response status code should be '201'
    And I store response field '$.id' in variable 'firstClientId'
    When I send a POST request to endpoint '/api/clients' with body
      | BODY                          |
      | {"name":"{clientPrefix} Two"} |
    Then The response status code should be '201'
    And I store response field '$.id' in variable 'secondClientId'
    When I send a PUT request to endpoint '/api/clients/{firstClientId}' with body
      | BODY                          |
      | {"name":"{clientPrefix} Two"} |
    Then The response status code should be '422'
    And The response field '$.code' should equal 'BUSINESS_ERROR'
    When I send a DELETE request to endpoint '/api/clients/{firstClientId}'
    Then The response status code should be '204'
    When I send a DELETE request to endpoint '/api/clients/{secondClientId}'
    Then The response status code should be '204'

  Scenario Outline: Reject invalid client list parameters
    When I send a GET request to endpoint '<endpoint>'
    Then The response status code should be '400'
    And The response field '$.code' should equal 'VALIDATION_ERROR'

    Examples:
      | endpoint                          |
      | /api/clients?sortBy=notAllowed    |
      | /api/clients?direction=sideways   |
      | /api/clients?pageIndex=0          |
      | /api/clients?itemsPerPage=0       |
      | /api/clients?itemsPerPage=101     |
      | /api/clients?pageIndex=notANumber |

  Scenario: Reject a client link query without a name
    When I send a GET request to endpoint '/api/clients/client-has-link-with-appointment'
    Then The response status code should be '400'

  Scenario Outline: Reject a non-numeric client ID
    When I send a <method> request to endpoint '/api/clients/not-a-number'
    Then The response status code should be '400'
    And The response field '$.code' should equal 'VALIDATION_ERROR'

    Examples:
      | method |
      | GET    |
      | DELETE |

  Scenario: Reject an update with a non-numeric client ID
    When I send a PUT request to endpoint '/api/clients/not-a-number' with body
      | BODY                  |
      | {"name":"Valid Name"} |
    Then The response status code should be '400'
    And The response field '$.code' should equal 'VALIDATION_ERROR'

  Scenario Outline: Return not found for a client outside the authenticated user scope
    When I send a <method> request to endpoint '/api/clients/999999999999'
    Then The response status code should be '404'
    And The response field '$.code' should equal 'NOT_FOUND'

    Examples:
      | method |
      | GET    |
      | DELETE |

  Scenario: Return not found when updating a missing client
    When I send a PUT request to endpoint '/api/clients/999999999999' with body
      | BODY                      |
      | {"name":"Missing Client"} |
    Then The response status code should be '404'
    And The response field '$.code' should equal 'NOT_FOUND'

  Scenario: Reject an update without a body
    When I send a PUT request to endpoint '/api/clients/999999999999' without a body
    Then The response status code should be '400'

  Scenario Outline: Reject invalid client update payloads
    When I send a PUT request to endpoint '/api/clients/999999999999' with raw body
      | BODY   |
      | <body> |
    Then The response status code should be '400'
    And The response field '$.code' should equal 'VALIDATION_ERROR'

    Examples:
      | body                                                      |
      | {"name":                                                  |
      | {"name":null}                                             |
      | {"name":""}                                               |
      | {"name":"   "}                                            |
      | {"name":"Invalid Update Date","dateOfBirth":"2026-02-30"} |

  Scenario: Bulk delete accepts an empty list and ignores unknown IDs
    When I send a POST request to endpoint '/api/clients/delete' with body
      | BODY |
      | []   |
    Then The response status code should be '200'
    And The response field '$.deleted' should equal '0'
    And The response field '$.hasLink' should equal '0'

  Scenario: Reject a bulk delete without a body
    When I send a POST request to endpoint '/api/clients/delete' without a body
    Then The response status code should be '400'
    When I send a POST request to endpoint '/api/clients/delete' with body
      | BODY           |
      | [999999999999] |
    Then The response status code should be '200'
    And The response field '$.deleted' should equal '0'
    And The response field '$.hasLink' should equal '0'

  Scenario Outline: Reject an invalid bulk delete payload
    When I send a POST request to endpoint '/api/clients/delete' with raw body
      | BODY   |
      | <body> |
    Then The response status code should be '400'

    Examples:
      | body        |
      | [           |
      | ["invalid"] |

  @persistent-test-data
  Scenario: Preserve clients linked to manual appointments
    Given I generate a unique value with prefix 'Playwright Linked Client' and store it in variable 'linkedClientName'
    And I generate a unique value with prefix 'Playwright Linked Service' and store it in variable 'linkedServiceDescription'
    When I send a POST request to endpoint '/api/clients' with body
      | BODY                          |
      | {"name":"{linkedClientName}"} |
    Then The response status code should be '201'
    And I store response field '$.id' in variable 'linkedClientId'
    When I send a POST request to endpoint '/api/services' with body
      | BODY                                                   |
      | {"description":"{linkedServiceDescription}","value":1} |
    Then The response status code should be '201'
    And I store response field '$.id' in variable 'linkedServiceId'
    When I send a POST request to endpoint '/api/calendar/events' with body
      | BODY                                                                                                                                    |
      | {"clientId":"{linkedClientId}","appointmentDate":"2099-01-15","startTime":"10:00","endTime":"11:00","serviceIds":["{linkedServiceId}"]} |
    Then The response status code should be '201'
    When I send a GET request to endpoint '/api/clients/client-has-link-with-appointment?name={linkedClientName}'
    Then The response status code should be '200'
    And The response field '$' should equal 'true'
    When I send a DELETE request to endpoint '/api/clients/{linkedClientId}'
    Then The response status code should be '422'
    And The response field '$.code' should equal 'BUSINESS_ERROR'
    When I send a POST request to endpoint '/api/clients/delete' with body
      | BODY                 |
      | ["{linkedClientId}"] |
    Then The response status code should be '200'
    And The response field '$.deleted' should equal '0'
    And The response field '$.hasLink' should equal '1'

  @persistent-test-data
  Scenario: Bulk delete clients with and without linked appointments
    Given I generate a unique value with prefix 'Playwright Bulk Unlinked Client' and store it in variable 'unlinkedClientName'
    And I generate a unique value with prefix 'Playwright Bulk Linked Client' and store it in variable 'linkedClientName'
    And I generate a unique value with prefix 'Playwright Bulk Linked Service' and store it in variable 'linkedServiceDescription'
    When I send a POST request to endpoint '/api/clients' with body
      | BODY                            |
      | {"name":"{unlinkedClientName}"} |
    Then The response status code should be '201'
    And I store response field '$.id' in variable 'unlinkedClientId'
    When I send a POST request to endpoint '/api/clients' with body
      | BODY                          |
      | {"name":"{linkedClientName}"} |
    Then The response status code should be '201'
    And I store response field '$.id' in variable 'linkedClientId'
    When I send a POST request to endpoint '/api/services' with body
      | BODY                                                   |
      | {"description":"{linkedServiceDescription}","value":1} |
    Then The response status code should be '201'
    And I store response field '$.id' in variable 'linkedServiceId'
    When I send a POST request to endpoint '/api/calendar/events' with body
      | BODY                                                                                                                                    |
      | {"clientId":"{linkedClientId}","appointmentDate":"2099-01-15","startTime":"10:00","endTime":"11:00","serviceIds":["{linkedServiceId}"]} |
    Then The response status code should be '201'
    When I send a POST request to endpoint '/api/clients/delete' with body
      | BODY                                      |
      | ["{unlinkedClientId}","{linkedClientId}"] |
    Then The response status code should be '200'
    And The response field '$.deleted' should equal '1'
    And The response field '$.hasLink' should equal '1'
    When I send a GET request to endpoint '/api/clients/{unlinkedClientId}'
    Then The response status code should be '404'
    When I send a GET request to endpoint '/api/clients/{linkedClientId}'
    Then The response status code should be '200'
    And The response field '$.id' should equal '{linkedClientId}'

  Scenario Outline: Reject unauthenticated client endpoints
    When I send a <method> request to endpoint '<endpoint>' without authentication
    Then The response status code should be '401'
    And The response field '$.code' should equal 'UNAUTHORIZED'

    Examples:
      | method | endpoint                                               |
      | GET    | /api/clients                                           |
      | GET    | /api/clients/client-has-link-with-appointment?name=Any |
      | GET    | /api/clients/999999999999                              |
      | POST   | /api/clients                                           |
      | PUT    | /api/clients/999999999999                              |
      | DELETE | /api/clients/999999999999                              |
      | POST   | /api/clients/delete                                    |

  Scenario: Reject an invalid access token
    When I send a GET request to endpoint '/api/clients' with an invalid access token
    Then The response status code should be '401'
    And The response field '$.code' should equal 'UNAUTHORIZED'
