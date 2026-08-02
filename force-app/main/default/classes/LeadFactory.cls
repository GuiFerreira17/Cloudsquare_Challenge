@IsTest
public with sharing class LeadFactory {
    public static Lead create ( Lead lead ) {
        insert lead;
        return lead;
    }
    public static Lead create ( String companyName, String federalTaxId, String firstName, String lastName, String applicationSource ) {
        return create ( build( companyName, federalTaxId, firstName, lastName, applicationSource ) );
    }

    public static Lead build ( String companyName, String federalTaxId, String firstName, String lastName, String applicationSource ) {
        return new Lead (
            Company = companyName,
            Federal_Tax_Id__c = federalTaxId,
            FirstName = firstName,
            LastName = lastName,
            Application_Source__c = applicationSource
        );
    }
}