// Example to run in the Developer Console (Execute Anonymous Window):
// Build an example JSON for ApplicationDTO
// String body = '{"companyName":"Test Company","federalTaxId":"123456789","annualRevenue":100000,"applicationSource":"Webhook","contact":{"firstName":"João","lastName":"Silva","email":"joao@exemplo.com","phone":"11988887777"}}';
String body =
'''
{
  "companyName": "Acme Corp",
  "federalTaxId": "BG123456789",
  "contact": {
    "firstName": "Ivan",
    "lastName": "Ivanov",
    "email": "ivan@example.com",
    "phone": "+359888123456"
  },
  "annualRevenue": 500000
}
''';

// Create mock RestRequest and RestResponse
RestRequest req = new RestRequest();
RestResponse res = new RestResponse();
req.requestBody = Blob.valueOf(body);

// Set the REST context (required for Apex REST)
// This needs to be done before calling the method!
RestContext.request = req;
RestContext.response = res;

// Call the service method
(new ApplicationWebhookService()).processApplicationPost(req, res);

// View the serialized result in the response
System.debug(res.responseBody.toString());