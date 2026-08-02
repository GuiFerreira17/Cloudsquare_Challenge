@IsTest
private class ApplicationFormControllerTest {

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
    static void successfulSubmitApplication_createLead() {
        Test.startTest();
            ApplicationResult result = ApplicationFormController.submitApplication(buildBody('Lead1234', 'LD1234'));
        Test.stopTest();

        Lead lead = [SELECT Id, Company, Federal_Tax_Id__c, FirstName, LastName, Application_Source__c FROM Lead WHERE Company = 'Lead1234' LIMIT 1];

        System.assertEquals(true, result.success);
        System.assertEquals(true, result.recordType == 'Lead');
        System.assertNotEquals(null, result.recordId);
        System.assertEquals('Lead1234', lead.Company);
        System.assertEquals('LD1234', lead.Federal_Tax_Id__c);
        System.assertEquals('Community', lead.Application_Source__c);
    }

    @isTest
    static void successfulSubmitApplication_createOpportunity() {
        Test.startTest();
            ApplicationResult result_FederalTaxId = ApplicationFormController.submitApplication(buildBody('NewName', 'CN1234'));
            ApplicationResult result_CompanyName = ApplicationFormController.submitApplication(buildBody('Company Name', 'LD1234'));
        Test.stopTest();

        List<Opportunity> opportunity = [SELECT Id,AccountId, Application_Source__c FROM Opportunity];

        System.assertEquals(true, result_FederalTaxId.success);
        System.assertEquals(true, result_FederalTaxId.recordType == 'Opportunity');
        System.assertNotEquals(null, result_FederalTaxId.recordId);
        System.assertEquals(true, result_CompanyName.success);
        System.assertEquals(true, result_CompanyName.recordType == 'Opportunity');
        System.assertNotEquals(null, result_CompanyName.recordId);

        System.assertEquals(2, opportunity.size());
        System.assertEquals('Community', opportunity[0].Application_Source__c);
        for (Opportunity o : opportunity) {
            System.assertEquals(o.Application_Source__c, 'Community');
        }
    }
    
    private class Successful_ServiceMock extends ApplicationProcessingService {
        
        public override ApplicationResult processApplication(ApplicationDTO input) {
            Lead lead = LeadFactory.create('Mock Co', 'TAX-MOCK-CTRL', 'John', 'Doe', 'Webhook');
            return new ApplicationResult('Lead', lead.Id);
        }
    }
    

    @IsTest
    static void submitApplication_mock_successFull() {
        ApplicationFormController.service = new Successful_ServiceMock();

        ApplicationDTO input = new ApplicationDTO();
        input.contact = new ApplicationDTO.ContactDTO();

        Test.startTest();
            ApplicationResult result = ApplicationFormController.submitApplication(buildBody('Lead1234', 'CN1234'));
        Test.stopTest();

        System.assertEquals(true, result.success);
        System.assertEquals('Lead', result.recordType);
        System.assertNotEquals(null, result.recordId);
    }

    @IsTest
    static void submitApplication_mock_error() {
        ApplicationFormController.service = new Successful_ServiceMock();

        ApplicationDTO input = new ApplicationDTO();
        input.contact = new ApplicationDTO.ContactDTO();

        String error_body = '{"errorAttribute":"errorValue"}';

        Test.startTest();
            ApplicationResult result = ApplicationFormController.submitApplication(null);
        Test.stopTest();

        System.assertEquals(false, result.success);
        System.assertNotEquals(null, result.message);
        System.assert(result.message == 'Unable to submit the application. Please try again later.');
    }

}