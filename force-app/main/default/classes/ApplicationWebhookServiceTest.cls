@IsTest
public class ApplicationWebhookServiceTest {

    @TestSetup
    static void makeData(){
        Account account = AccountFactory.create('Company Name', 'CN1234');
    }

    private static String buildBody(String companyName, String federalTaxId) {
        return 
        '    {'+
        '        "contact": {' + 
        '            "firstName": "John",' + 
        '            "lastName": "Doe",' + 
        '            "email": "john.doe@example.com",' + 
        '            "phone": "1234567890"' + 
        '        },' + 
        '        "companyName": "' + companyName + '",' + 
        '        "federalTaxId": "' + federalTaxId + '",' + 
        '        "annualRevenue": 100000,' + 
        '        "applicationSource": "Community"' + 
        '    }' ;
    }

    @isTest
    static void successful_createLead() {
        ApplicationWebhookService webhookService = new ApplicationWebhookService();

        RestRequest request = new RestRequest();
        request.requestBody = Blob.valueOf(buildBody('Lead1234', 'LD1234'));
        RestResponse response = new RestResponse();

        Test.startTest();
            webhookService.processApplicationPost(request, response);
        Test.stopTest();

        Lead lead = [SELECT Id, Company, Federal_Tax_Id__c, FirstName, LastName, Application_Source__c FROM Lead WHERE Company = 'Lead1234' LIMIT 1];

        ApplicationResult result = (ApplicationResult) JSON.deserialize(
            response.responseBody.toString(),
            ApplicationResult.class
        );

        System.assertEquals(200, response.statusCode);
        System.assertEquals(true, result.success);
        System.assertEquals('Lead', result.recordType);
        System.assertNotEquals(null, result.recordId);
        System.assertEquals('Lead1234', lead.Company);
        System.assertEquals('LD1234', lead.Federal_Tax_Id__c);
        System.assertEquals('Webhook', lead.Application_Source__c);
    }

    @isTest
    static void successful_createOpportunity() {
        ApplicationWebhookService webhookService = new ApplicationWebhookService();

        RestRequest request_Federal = new RestRequest();
        request_Federal.requestBody = Blob.valueOf(buildBody('Opp1234', 'CN1234'));
        RestResponse response_Federal = new RestResponse();

        RestRequest request_Name = new RestRequest();
        request_Name.requestBody = Blob.valueOf(buildBody('Company Name', 'Opp1234'));
        RestResponse response_Name = new RestResponse();

        Test.startTest();
            webhookService.processApplicationPost(request_Federal, response_Federal);
            webhookService.processApplicationPost(request_Name, response_Name);
        Test.stopTest();

        ApplicationResult result_Federal = (ApplicationResult) JSON.deserialize(
            response_Federal.responseBody.toString(),
            ApplicationResult.class
        );
        ApplicationResult result_Name = (ApplicationResult) JSON.deserialize(
            response_Name.responseBody.toString(),
            ApplicationResult.class
        );

        List<Opportunity> opportunity = [SELECT Id,AccountId, Application_Source__c FROM Opportunity];
        for (Opportunity o : opportunity) {
            System.assertEquals(o.Application_Source__c, 'Webhook');
        }

        System.assertEquals(200, response_Federal.statusCode);
        System.assertEquals(true, result_Federal.success);
        System.assertEquals('Opportunity', result_Federal.recordType);
        System.assertNotEquals(null, result_Federal.recordId);
    }


    public class Successful_ServiceMock extends ApplicationProcessingService {
        public override ApplicationResult processApplication(ApplicationDTO input) {
            Lead lead = LeadFactory.create('Mock Co', 'TAX-MOCK-WH', 'John', 'Doe', 'Webhook');
            return new ApplicationResult('Lead', lead.Id);
        }
    }

    public class Error_ServiceMock extends ApplicationProcessingService {
        public override ApplicationResult processApplication(ApplicationDTO input) {
            return new ApplicationResult('Company Name is required.');
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
    static void processApplicationPost_mock_successFull() {
        ApplicationWebhookService webhookService = new ApplicationWebhookService();
        webhookService.service = new Successful_ServiceMock();

        RestRequest request = new RestRequest();
        request.requestBody = Blob.valueOf(successFull_body);
        RestResponse response = new RestResponse();

        Test.startTest();
            webhookService.processApplicationPost(request, response);
        Test.stopTest();

        ApplicationResult result = (ApplicationResult) JSON.deserialize(
            response.responseBody.toString(),
            ApplicationResult.class
        );

        System.assertEquals(200, response.statusCode);
        System.assertEquals(true, result.success);
        System.assertEquals('Lead', result.recordType);
        System.assertNotEquals(null, result.recordId);
    }

    @IsTest
    static void processApplicationPost_mock_error() {
        ApplicationWebhookService webhookService = new ApplicationWebhookService();
        webhookService.service = new Error_ServiceMock();

        RestRequest request = new RestRequest();
        request.requestBody = Blob.valueOf(successFull_body);
        RestResponse response = new RestResponse();

        Test.startTest();
            webhookService.processApplicationPost(request, response);
        Test.stopTest();

        ApplicationResult result = (ApplicationResult) JSON.deserialize(
            response.responseBody.toString(),
            ApplicationResult.class
        );

        System.assertEquals(500, response.statusCode);
        System.assertEquals(false, result.success);
        System.assertEquals('Company Name is required.', result.message);
    }

    @IsTest
    static void processApplicationPost_mock_nullRequestError() {
        ApplicationWebhookService webhookService = new ApplicationWebhookService();
        RestResponse response = new RestResponse();

        Test.startTest();
            webhookService.processApplicationPost(null, response);
        Test.stopTest();

        ApplicationResult result = (ApplicationResult) JSON.deserialize(
            response.responseBody.toString(),
            ApplicationResult.class
        );

        System.assertEquals(500, response.statusCode);
        System.assertEquals(false, result.success);
        System.assertEquals('Request is required.', result.message);
    }

    @IsTest
    static void processApplicationPost_mock_invalidJsonError() {
        ApplicationWebhookService webhookService = new ApplicationWebhookService();
        webhookService.service = new Successful_ServiceMock();

        RestRequest request = new RestRequest();
        // Malformed JSON forces JSONException into the generic catch
        request.requestBody = Blob.valueOf('{not-valid-json');
        RestResponse response = new RestResponse();

        Test.startTest();
            webhookService.processApplicationPost(request, response);
        Test.stopTest();

        ApplicationResult result = (ApplicationResult) JSON.deserialize(
            response.responseBody.toString(),
            ApplicationResult.class
        );

        System.assertEquals(500, response.statusCode);
        System.assertEquals(false, result.success);
        System.assertEquals('Unable to process the application. Please try again later.', result.message);
    }

    @IsTest
    static void getApplicationDTO_mock_successFull() {
        ApplicationWebhookService webhookService = new ApplicationWebhookService();

        RestRequest request = new RestRequest();
        request.requestBody = Blob.valueOf(successFull_body);

        Test.startTest();
            ApplicationDTO appDTO = webhookService.getApplicationDTO(request);
        Test.stopTest();

        System.assertEquals('Acme Corp', appDTO.companyName);
        System.assertEquals('1234567890', appDTO.federalTaxId);
        System.assertEquals(100000, appDTO.annualRevenue);
        System.assertEquals('Webhook', appDTO.applicationSource);
        System.assertEquals('John', appDTO.contact.firstName);
        System.assertEquals('Doe', appDTO.contact.lastName);
        System.assertEquals('john.doe@example.com', appDTO.contact.email);
        System.assertEquals('1234567890', appDTO.contact.phone);
    }
}