public class ApplicationDTO {

    @AuraEnabled public String companyName;
    @AuraEnabled public String federalTaxId;
    @AuraEnabled public ContactDTO contact;
    @AuraEnabled public Decimal annualRevenue;
    @AuraEnabled public String applicationSource;
    
    public class ContactDTO {
        @AuraEnabled public String firstName;
        @AuraEnabled public String lastName;
        @AuraEnabled public String email;
        @AuraEnabled public String phone;
    }
}