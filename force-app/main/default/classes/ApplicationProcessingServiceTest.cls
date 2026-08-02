@IsTest
private class ApplicationProcessingServiceTest {

    private class NoDuplicate_MatcherMock extends SObjectDuplicateMatcher {
        public override Map<String, List<Id>> findDuplicateRecords(SObject input) {
            return new Map<String, List<Id>>();
        }
    }

    private class AccountDuplicate_MatcherMock extends SObjectDuplicateMatcher {
        private final Id accountId;

        AccountDuplicate_MatcherMock(Id accountId) {
            this.accountId = accountId;
        }

        public override Map<String, List<Id>> findDuplicateRecords(SObject input) {
            return new Map<String, List<Id>>{
                'Account' => new List<Id>{ accountId }
            };
        }
    }

    private class LeadDuplicate_MatcherMock extends SObjectDuplicateMatcher {
        private final Id leadId;

        LeadDuplicate_MatcherMock(Id leadId) {
            this.leadId = leadId;
        }

        public override Map<String, List<Id>> findDuplicateRecords(SObject input) {
            return new Map<String, List<Id>>{
                'Lead' => new List<Id>{ leadId }
            };
        }
    }

    @IsTest
    static void processApplication_mock_successFull() {
        ApplicationProcessingService.matcher = new NoDuplicate_MatcherMock();
        ApplicationDTO input = buildValidDto('TAX-NEW');

        Test.startTest();
            ApplicationResult result = new ApplicationProcessingService().processApplication(input);
        Test.stopTest();

        System.assertEquals(true, result.success, 'Expected success');
        System.assertEquals('Lead', result.recordType);
        System.assertNotEquals(null, result.recordId);

        Lead created = [
            SELECT FirstName, LastName, Company, Email, Phone, AnnualRevenue, Federal_Tax_Id__c
            FROM Lead
            WHERE Id = :result.recordId
        ];
        System.assertEquals('Ivan', created.FirstName);
        System.assertEquals('Ivanov', created.LastName);
        System.assertEquals('Acme Corp', created.Company);
        System.assertEquals('ivan@example.com', created.Email);
        System.assertEquals('+359888123456', created.Phone);
        System.assertEquals(500000, created.AnnualRevenue);
        System.assertEquals('TAX-NEW', created.Federal_Tax_Id__c);
    }

    @IsTest
    static void processApplication_mock_leadDuplicate_successFull() {
        Lead existing = LeadFactory.create('Acme Corp', 'TAX-LEAD', 'Ivan', 'Ivanov', 'Webhook');
        ApplicationProcessingService.matcher = new LeadDuplicate_MatcherMock(existing.Id);
        ApplicationDTO input = buildValidDto('TAX-LEAD');

        Test.startTest();
            ApplicationResult result = new ApplicationProcessingService().processApplication(input);
        Test.stopTest();

        System.assertEquals(true, result.success, 'Expected success');
        System.assertEquals('Lead', result.recordType);
        System.assertEquals(existing.Id, result.recordId);
        System.assertEquals(1, [SELECT COUNT() FROM Lead WHERE Federal_Tax_Id__c = 'TAX-LEAD']);
        System.assertEquals(0, [SELECT COUNT() FROM Opportunity]);
    }

    @IsTest
    static void processApplication_mock_accountDuplicate_successFull() {
        Account existing = AccountFactory.create('Existing Corp', 'TAX-EXISTING');
        ApplicationProcessingService.matcher = new AccountDuplicate_MatcherMock(existing.Id);
        ApplicationDTO input = buildValidDto('TAX-EXISTING');

        Test.startTest();
            ApplicationResult result = new ApplicationProcessingService().processApplication(input);
        Test.stopTest();

        System.assertEquals(true, result.success, 'Expected success');
        System.assertEquals('Opportunity', result.recordType);
        System.assertNotEquals(null, result.recordId);

        Opportunity opp = [
            SELECT Name, AccountId, StageName, CloseDate
            FROM Opportunity
            WHERE Id = :result.recordId
        ];
        System.assertEquals(existing.Id, opp.AccountId);
        System.assertEquals('Acme Corp - New Application', opp.Name);
        System.assertEquals('Prospecting', opp.StageName);
        System.assertEquals(Date.today().addDays(30), opp.CloseDate);
        System.assertEquals(1, [
            SELECT COUNT()
            FROM Contact
            WHERE AccountId = :existing.Id AND Email = 'ivan@example.com'
        ]);
        System.assertEquals(0, [SELECT COUNT() FROM Lead WHERE Federal_Tax_Id__c = 'TAX-EXISTING']);
    }

    @IsTest
    static void processApplication_mock_validationError() {
        ApplicationProcessingService.matcher = new NoDuplicate_MatcherMock();
        ApplicationDTO input = new ApplicationDTO();
        input.contact = new ApplicationDTO.ContactDTO();

        Test.startTest();
            ApplicationResult result = new ApplicationProcessingService().processApplication(input);
        Test.stopTest();

        System.assertEquals(false, result.success);
        System.assertNotEquals(null, result.message);
        System.assert(result.message.contains('Company Name'), result.message);
        System.assert(result.message.contains('Federal Tax Id'), result.message);
        System.assert(result.message.contains('Annual Revenue'), result.message);
        System.assert(result.message.contains('First Name'), result.message);
        System.assert(result.message.contains('Last Name'), result.message);
        System.assert(result.message.contains('Email'), result.message);
        System.assert(result.message.contains('Phone'), result.message);
    }

    @IsTest
    static void processApplication_mock_invalidEmailError() {
        ApplicationProcessingService.matcher = new NoDuplicate_MatcherMock();
        ApplicationDTO input = buildValidDto('TAX-1');
        input.contact.email = 'not-an-email';

        Test.startTest();
            ApplicationResult result = new ApplicationProcessingService().processApplication(input);
        Test.stopTest();

        System.assertEquals(false, result.success);
        System.assert(result.message.contains('Email format is invalid.'), result.message);
    }

    @IsTest
    static void processApplication_mock_nullInputError() {
        ApplicationProcessingService.matcher = new NoDuplicate_MatcherMock();
        Boolean threw = false;

        Test.startTest();
            try {
                new ApplicationProcessingService().processApplication(null);
            } catch (ApplicationProcessingService.ApplicationProcessingServiceException e) {
                threw = true;
                System.assert(e.getMessage().contains('required'), e.getMessage());
            }
        Test.stopTest();

        System.assertEquals(true, threw, 'Expected ApplicationProcessingServiceException');
    }

    @IsTest
    static void createLead_mock_error() {
        ApplicationProcessingService.matcher = new NoDuplicate_MatcherMock();
        ApplicationDTO input = buildValidDto('TAX-LEAD-ERR');
        input.contact.lastName = 'X'.repeat(81);

        Test.startTest();
            ApplicationResult result = new ApplicationProcessingService().processApplication(input);
        Test.stopTest();

        System.assertEquals(false, result.success);
        System.assertNotEquals(null, result.message);
        System.assertEquals(0, [SELECT COUNT() FROM Lead WHERE Federal_Tax_Id__c = 'TAX-LEAD-ERR']);
    }

    @IsTest
    static void createOpportunity_mock_error() {
        Account existing = AccountFactory.create('Existing Corp', 'TAX-OPP-ERR');
        ApplicationProcessingService.matcher = new AccountDuplicate_MatcherMock(existing.Id);
        ApplicationDTO input = buildValidDto('TAX-OPP-ERR');
        input.companyName = 'X'.repeat(121);

        Test.startTest();
            ApplicationResult result = new ApplicationProcessingService().processApplication(input);
        Test.stopTest();

        System.assertEquals(false, result.success);
        System.assertNotEquals(null, result.message);
        System.assertEquals(0, [SELECT COUNT() FROM Opportunity WHERE AccountId = :existing.Id]);
    }

    private static ApplicationDTO buildValidDto(String taxId) {
        ApplicationDTO input = new ApplicationDTO();
        input.companyName = 'Acme Corp';
        input.federalTaxId = taxId;
        input.annualRevenue = 500000;
        input.applicationSource = 'Webhook';
        input.contact = new ApplicationDTO.ContactDTO();
        input.contact.firstName = 'Ivan';
        input.contact.lastName = 'Ivanov';
        input.contact.email = 'ivan@example.com';
        input.contact.phone = '+359888123456';
        return input;
    }
}