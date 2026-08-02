public class ApplicationResult {

    @AuraEnabled public Boolean success;
    @AuraEnabled public String message;
    @AuraEnabled public String recordType; // Lead or Opportunity
    @AuraEnabled public Id recordId;

    // Constructor for failed application
    public ApplicationResult(String message) {
        this.success = false;
        this.message = message;
    }

    // Constructor for successful application
    public ApplicationResult(String recordType, Id recordId) {
        this.success = true;
        this.message = 'Application processed successfully';
        this.recordType = recordType;
        this.recordId = recordId;
    }
}