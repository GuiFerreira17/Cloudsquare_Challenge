@IsTest
public class AccountFactory {
    public static Account create ( Account account ) {
        insert account;
        return account;
    }

    public static Account create ( String name, String federalTaxId ) {
        return create ( build( name, federalTaxId ) );
    }

    public static Account build ( String name, String federalTaxId ) {
        return new Account (
            Name = name,
            Federal_Tax_Id__c = federalTaxId
        );
    }

}