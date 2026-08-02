/**
 * @description Apex controller exposed to the `applicationForm` LWC. Converts the JSON payload
 *              submitted by the form into an ApplicationDTO and delegates the business logic to
 *              ApplicationProcessingService.
 * @author      Guilherme Ferreira
 * @date        08/02/2026
 */
public with sharing class ApplicationFormController {

    @TestVisible
    private static ApplicationProcessingService service;

    static {
        service = new ApplicationProcessingService();
    }


    /**
     * @description Entry point called by the LWC to submit a new application. Any unexpected
     *              exception is logged and translated into a generic failure result so that
     *              internal details are never exposed to the end user.
     * @param       inputJson JSON string matching the ApplicationDTO structure.
     * @return      ApplicationResult with the created record type/id on success, or the error message on failure.
     */
    @AuraEnabled
    public static ApplicationResult submitApplication(String inputJson) {
        try {
            ApplicationDTO input = (ApplicationDTO) JSON.deserialize(inputJson, ApplicationDTO.class);
            System.debug('input: ' + JSON.serialize(input));
            return service.processApplication(input);
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'ApplicationFormController.submitApplication: ' + e.getMessage());
            System.debug(LoggingLevel.ERROR, e.getStackTraceString());
            return new ApplicationResult('Unable to submit the application. Please try again later.');
        }
    }
}