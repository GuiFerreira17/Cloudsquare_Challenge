@IsTest
public class SObjectDuplicateMatcherTest {

    @TestSetup
    static void setup() {
        Account account = AccountFactory.create('Test Account', 'TA1234');
        Lead lead = LeadFactory.create('Test Company', 'L1234', 'First', 'Last', 'Webhook');
    }

    @IsTest
    static void accountDuplicateMatcherTest() {
        SObjectDuplicateMatcher matcher = new SObjectDuplicateMatcher();
        Account account = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];

        Test.startTest();
            Map<String, List<Id>> duplicates = matcher.findDuplicateRecords(LeadFactory.build('Test Account', 'TA1234', 'First', 'Last', 'Webhook'));
        Test.stopTest();

        System.assertEquals(1, duplicates.size());
        System.assertEquals(1, duplicates.get('Account').size());
        System.assertEquals(account.Id, duplicates.get('Account').get(0));
    }

    @IsTest
    static void noDuplicateMatcherTest() {
        SObjectDuplicateMatcher matcher = new SObjectDuplicateMatcher();

        Test.startTest();
            Map<String, List<Id>> duplicates = matcher.findDuplicateRecords(LeadFactory.build('Test New Lead', 'L9876', 'First', 'Last', 'Webhook'));
        Test.stopTest();

        System.assertEquals(0, duplicates.size());
    }
}