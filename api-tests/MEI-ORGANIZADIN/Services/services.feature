# language: en
Feature: Services

  Background:
    Given I log in as user
      | USER               |
      | EXAMPLE_CREDENTIAL |

  Scenario: Create and list services
    Given I generate a unique value with prefix 'pw-service-create' and store it in variable 'serviceDescription'
    When I send a POST request to endpoint '/api/services' with body
      | BODY                                                  |
      | {"description":"{serviceDescription}","value":125.50} |
    Then The response status code should be '201'
    And I store response field '$.id' in variable 'serviceId'
    And The response field '$.description' should equal '{serviceDescription}'
    And The response field '$.value' should equal '125.5'
    When I send a GET request to endpoint '/api/services?description={serviceDescription}'
    Then The response status code should be '200'
    And The response field '$.totalItems' should equal '1'
    And The response field '$.items[0].description' should equal '{serviceDescription}'
    And The response field '$.items[0].value' should equal '125.5'
    When I send a DELETE request to endpoint '/api/services/{serviceId}'
    Then The response status code should be '204'

  Scenario: Get service by ID
    Given I generate a unique value with prefix 'pw-service-get' and store it in variable 'serviceDescription'
    When I send a POST request to endpoint '/api/services' with body
      | BODY                                              |
      | {"description":"{serviceDescription}","value":30} |
    Then I store response field '$.id' in variable 'serviceId'
    When I send a GET request to endpoint '/api/services/{serviceId}'
    Then The response status code should be '200'
    And The response field '$.id' should equal '{serviceId}'
    And The response field '$.description' should equal '{serviceDescription}'
    And The response field '$.value' should equal '30'
    When I send a DELETE request to endpoint '/api/services/{serviceId}'
    Then The response status code should be '204'

  Scenario: Update service
    Given I generate a unique value with prefix 'pw-service-before' and store it in variable 'originalDescription'
    And I generate a unique value with prefix 'pw-service-after' and store it in variable 'updatedDescription'
    When I send a POST request to endpoint '/api/services' with body
      | BODY                                               |
      | {"description":"{originalDescription}","value":40} |
    Then I store response field '$.id' in variable 'serviceId'
    When I send a PUT request to endpoint '/api/services/{serviceId}' with body
      | BODY                                                 |
      | {"description":"{updatedDescription}","value":75.25} |
    Then The response status code should be '200'
    And The response field '$.description' should equal '{updatedDescription}'
    And The response field '$.value' should equal '75.25'
    When I send a GET request to endpoint '/api/services/{serviceId}'
    Then The response field '$.description' should equal '{updatedDescription}'
    When I send a DELETE request to endpoint '/api/services/{serviceId}'
    Then The response status code should be '204'

  Scenario: Delete service
    Given I generate a unique value with prefix 'pw-service-delete' and store it in variable 'serviceDescription'
    When I send a POST request to endpoint '/api/services' with body
      | BODY                                              |
      | {"description":"{serviceDescription}","value":50} |
    Then I store response field '$.id' in variable 'serviceId'
    When I send a DELETE request to endpoint '/api/services/{serviceId}'
    Then The response status code should be '204'
    And The response body should be empty
    When I send a GET request to endpoint '/api/services/{serviceId}'
    Then The response status code should be '404'
    And The response field '$.code' should equal 'NOT_FOUND'

  Scenario: Bulk delete services
    Given I generate a unique value with prefix 'pw-service-bulk-one' and store it in variable 'firstDescription'
    And I generate a unique value with prefix 'pw-service-bulk-two' and store it in variable 'secondDescription'
    When I send a POST request to endpoint '/api/services' with body
      | BODY                                            |
      | {"description":"{firstDescription}","value":10} |
    Then I store response field '$.id' in variable 'firstServiceId'
    When I send a POST request to endpoint '/api/services' with body
      | BODY                                             |
      | {"description":"{secondDescription}","value":20} |
    Then I store response field '$.id' in variable 'secondServiceId'
    When I send a POST request to endpoint '/api/services/delete' with body
      | BODY                                     |
      | ["{firstServiceId}","{secondServiceId}"] |
    Then The response status code should be '200'
    And The response field '$.deleted' should equal '2'
    And The response field '$.hasLink' should equal '0'

  Scenario Outline: Reject invalid service creation payloads
    When I send a POST request to endpoint '/api/services' with raw body
      | BODY   |
      | <body> |
    Then The response status code should be '400'
    And The response field '$.code' should equal 'VALIDATION_ERROR'

    Examples:
      | body                                  |
      | {                                     |
      | {}                                    |
      | {"description":null,"value":10}       |
      | {"description":"","value":10}         |
      | {"description":"   ","value":10}      |
      | {"description":"Negative","value":0}  |
      | {"description":"Negative","value":-1} |

  Scenario: Reject service creation without a body
    When I send a POST request to endpoint '/api/services' without a body
    Then The response status code should be '400'
    And The response field '$.code' should equal 'VALIDATION_ERROR'

  Scenario: Reject duplicate service descriptions
    Given I generate a unique value with prefix 'pw-service-duplicate' and store it in variable 'serviceDescription'
    When I send a POST request to endpoint '/api/services' with body
      | BODY                                              |
      | {"description":"{serviceDescription}","value":10} |
    Then I store response field '$.id' in variable 'serviceId'
    When I send a POST request to endpoint '/api/services' with body
      | BODY                                                  |
      | {"description":"  {serviceDescription}  ","value":20} |
    Then The response status code should be '422'
    And The response field '$.code' should equal 'BUSINESS_ERROR'
    When I send a DELETE request to endpoint '/api/services/{serviceId}'
    Then The response status code should be '204'

  Scenario: Reject updating a service to another service description
    Given I generate a unique value with prefix 'pw-service-conflict' and store it in variable 'servicePrefix'
    When I send a POST request to endpoint '/api/services' with body
      | BODY                                             |
      | {"description":"{servicePrefix} One","value":10} |
    Then I store response field '$.id' in variable 'firstServiceId'
    When I send a POST request to endpoint '/api/services' with body
      | BODY                                             |
      | {"description":"{servicePrefix} Two","value":20} |
    Then I store response field '$.id' in variable 'secondServiceId'
    When I send a PUT request to endpoint '/api/services/{firstServiceId}' with body
      | BODY                                             |
      | {"description":"{servicePrefix} Two","value":30} |
    Then The response status code should be '422'
    And The response field '$.code' should equal 'BUSINESS_ERROR'
    When I send a POST request to endpoint '/api/services/delete' with body
      | BODY                                     |
      | ["{firstServiceId}","{secondServiceId}"] |
    Then The response field '$.deleted' should equal '2'

  @persistent-test-data
  Scenario: Preserve services linked to manual appointments
    Given I generate a unique value with prefix 'pw-service-linked-client' and store it in variable 'clientName'
    And I generate a unique value with prefix 'pw-service-linked' and store it in variable 'serviceDescription'
    When I send a POST request to endpoint '/api/clients' with body
      | BODY                    |
      | {"name":"{clientName}"} |
    Then I store response field '$.id' in variable 'clientId'
    When I send a POST request to endpoint '/api/services' with body
      | BODY                                              |
      | {"description":"{serviceDescription}","value":10} |
    Then I store response field '$.id' in variable 'serviceId'
    When I send a POST request to endpoint '/api/calendar/events' with body
      | BODY                                                                                                                        |
      | {"clientId":"{clientId}","appointmentDate":"2099-02-15","startTime":"10:00","endTime":"11:00","serviceIds":["{serviceId}"]} |
    Then The response status code should be '201'
    When I send a DELETE request to endpoint '/api/services/{serviceId}'
    Then The response status code should be '422'
    And The response field '$.code' should equal 'BUSINESS_ERROR'
    When I send a POST request to endpoint '/api/services/delete' with body
      | BODY            |
      | ["{serviceId}"] |
    Then The response status code should be '200'
    And The response field '$.deleted' should equal '0'
    And The response field '$.hasLink' should equal '1'

  @persistent-test-data
  Scenario: Bulk delete services with and without linked appointments
    Given I generate a unique value with prefix 'pw-service-mixed-client' and store it in variable 'clientName'
    And I generate a unique value with prefix 'pw-service-mixed-unlinked' and store it in variable 'unlinkedDescription'
    And I generate a unique value with prefix 'pw-service-mixed-linked' and store it in variable 'linkedDescription'
    When I send a POST request to endpoint '/api/clients' with body
      | BODY                    |
      | {"name":"{clientName}"} |
    Then I store response field '$.id' in variable 'clientId'
    When I send a POST request to endpoint '/api/services' with body
      | BODY                                               |
      | {"description":"{unlinkedDescription}","value":10} |
    Then I store response field '$.id' in variable 'unlinkedServiceId'
    When I send a POST request to endpoint '/api/services' with body
      | BODY                                             |
      | {"description":"{linkedDescription}","value":20} |
    Then I store response field '$.id' in variable 'linkedServiceId'
    When I send a POST request to endpoint '/api/calendar/events' with body
      | BODY                                                                                                                              |
      | {"clientId":"{clientId}","appointmentDate":"2099-03-15","startTime":"10:00","endTime":"11:00","serviceIds":["{linkedServiceId}"]} |
    Then The response status code should be '201'
    When I send a POST request to endpoint '/api/services/delete' with body
      | BODY                                        |
      | ["{unlinkedServiceId}","{linkedServiceId}"] |
    Then The response status code should be '200'
    And The response field '$.deleted' should equal '1'
    And The response field '$.hasLink' should equal '1'
    When I send a GET request to endpoint '/api/services/{unlinkedServiceId}'
    Then The response status code should be '404'
    When I send a GET request to endpoint '/api/services/{linkedServiceId}'
    Then The response status code should be '200'

  Scenario Outline: Reject invalid service list parameters
    When I send a GET request to endpoint '<endpoint>'
    Then The response status code should be '400'

    Examples:
      | endpoint                         |
      | /api/services?sortBy=notAllowed  |
      | /api/services?direction=sideways |
      | /api/services?page=-1            |
      | /api/services?size=0             |
      | /api/services?size=101           |

  Scenario Outline: Return not found for a missing service
    When I send a <method> request to endpoint '/api/services/999999999999'
    Then The response status code should be '404'
    And The response field '$.code' should equal 'NOT_FOUND'

    Examples:
      | method |
      | GET    |
      | DELETE |

  Scenario: Reject update without a body
    When I send a PUT request to endpoint '/api/services/999999999999' without a body
    Then The response status code should be '400'

  Scenario Outline: Reject invalid service update payloads
    When I send a PUT request to endpoint '/api/services/999999999999' with raw body
      | BODY   |
      | <body> |
    Then The response status code should be '400'

    Examples:
      | body                              |
      | {                                 |
      | {}                                |
      | {"description":null,"value":10}   |
      | {"description":"","value":10}     |
      | {"description":"Valid","value":0} |

  Scenario: Bulk delete accepts empty and unknown service IDs
    When I send a POST request to endpoint '/api/services/delete' with body
      | BODY |
      | []   |
    Then The response status code should be '200'
    And The response field '$.deleted' should equal '0'
    And The response field '$.hasLink' should equal '0'
    When I send a POST request to endpoint '/api/services/delete' with body
      | BODY           |
      | [999999999999] |
    Then The response status code should be '200'
    And The response field '$.deleted' should equal '0'
    And The response field '$.hasLink' should equal '0'

  Scenario Outline: Reject unauthenticated service endpoints
    When I send a <method> request to endpoint '<endpoint>' without authentication
    Then The response status code should be '401'
    And The response field '$.code' should equal 'UNAUTHORIZED'

    Examples:
      | method | endpoint                   |
      | GET    | /api/services              |
      | GET    | /api/services/999999999999 |
      | POST   | /api/services              |
      | PUT    | /api/services/999999999999 |
      | DELETE | /api/services/999999999999 |
      | POST   | /api/services/delete       |

  Scenario: Reject an invalid access token for services
    When I send a GET request to endpoint '/api/services' with an invalid access token
    Then The response status code should be '401'
    And The response field '$.code' should equal 'UNAUTHORIZED'
