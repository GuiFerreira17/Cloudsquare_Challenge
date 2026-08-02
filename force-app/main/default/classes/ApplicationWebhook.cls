/**
 * @description REST endpoint (/services/apexrest/external/applications) that receives applications
 *              posted by external systems. Acts only as a thin entry point: all parsing, processing
 *              and response handling is delegated to ApplicationWebhookService.
 * @author      Guilherme Ferreira
 * @date        08/02/2026
 */
@RestResource(urlMapping='/external/applications')
global class ApplicationWebhook {
    
    @TestVisible
    private static ApplicationWebhookService service;
 
    static {
        service = new ApplicationWebhookService();
    }
    
    /**
     * @description Handles the HTTP POST requests sent to the endpoint, forwarding the current
     *              RestContext request/response to the service layer. The response body and status
     *              code are written by ApplicationWebhookService.processApplicationPost.
     * @return      void
     */
    @HttpPost
    global static void handlePost() {
        service.processApplicationPost(RestContext.request, RestContext.response);
    }



}