@IsTest
public class ApplicationWebhookTest {

    public class Successful_WebhookServiceMock extends ApplicationWebhookService {
        public override void processApplicationPost(RestRequest request, RestResponse response) {
            Lead lead = LeadFactory.create('Mock Co', 'TAX-MOCK-WH2', 'John', 'Doe', 'Webhook');
            response.statusCode = 200;
            response.responseBody = Blob.valueOf(
                JSON.serialize(new ApplicationResult('Lead', lead.Id))
            );
        }
    }

    public class Error_WebhookServiceMock extends ApplicationWebhookService {
        public override void processApplicationPost(RestRequest request, RestResponse response) {
            response.statusCode = 500;
            response.responseBody = Blob.valueOf(
                JSON.serialize(new ApplicationResult('Unable to process the application. Please try again later.'))
            );
        }
    }

    public static String successFull_body =
    '''
    {
        "contact": {
            "firstName": "John",
            "lastName": "Doe",
            "email": "john.doe@example.com",
            "phone": "1234567890"
        },
        "companyName": "Acme Corp",
        "federalTaxId": "1234567890",
        "annualRevenue": 100000
    }
    ''';

    @IsTest
    static void handlePost_mock_successFull() {
        ApplicationWebhook.service = new Successful_WebhookServiceMock();

        RestRequest request = new RestRequest();
        request.requestURI = '/services/apexrest/external/applications';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(successFull_body);
        RestContext.request = request;
        RestContext.response = new RestResponse();

        Test.startTest();
            ApplicationWebhook.handlePost();
        Test.stopTest();

        ApplicationResult result = (ApplicationResult) JSON.deserialize(
            RestContext.response.responseBody.toString(),
            ApplicationResult.class
        );

        System.assertEquals(200, RestContext.response.statusCode);
        System.assertEquals(true, result.success);
        System.assertEquals('Lead', result.recordType);
        System.assertNotEquals(null, result.recordId);
    }

    @IsTest
    static void handlePost_mock_error() {
        ApplicationWebhook.service = new Error_WebhookServiceMock();

        RestRequest request = new RestRequest();
        request.requestURI = '/services/apexrest/external/applications';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(successFull_body);
        RestContext.request = request;
        RestContext.response = new RestResponse();

        Test.startTest();
            ApplicationWebhook.handlePost();
        Test.stopTest();

        ApplicationResult result = (ApplicationResult) JSON.deserialize(
            RestContext.response.responseBody.toString(),
            ApplicationResult.class
        );

        System.assertEquals(500, RestContext.response.statusCode);
        System.assertEquals(false, result.success);
        System.assertNotEquals(null, result.message);
        System.assertEquals('Unable to process the application. Please try again later.', result.message);
    }
}