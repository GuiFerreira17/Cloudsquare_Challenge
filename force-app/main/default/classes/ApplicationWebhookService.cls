/**
 * @description Service layer for the ApplicationWebhook REST resource. Deserializes the incoming
 *              request into an ApplicationDTO, delegates the business rules to
 *              ApplicationProcessingService and builds the HTTP response returned to the caller.
 * @author      Guilherme Ferreira
 * @date        08/02/2026
 */
public virtual class ApplicationWebhookService {
    
    /**
     * @description Thrown when the incoming request cannot be interpreted as a valid application.
     */
    public class ApplicationWebhookServiceException extends Exception {}

    @TestVisible
    private ApplicationProcessingService service;

    /**
     * @description Default constructor. Instantiates the ApplicationProcessingService used to
     *              process the applications received by the webhook.
     */
    public ApplicationWebhookService() {
        service = new ApplicationProcessingService();
    }

    /**
     * @description Processes an application received via HTTP POST. Validation errors are returned
     *              to the caller as-is, while unexpected exceptions are logged and replaced by a
     *              generic message to avoid exposing internal details.
     * @param       request  Inbound REST request holding the application JSON payload.
     * @param       response REST response that is populated with the status code and the serialized ApplicationResult.
     * @return      void
     */
    public virtual void processApplicationPost(RestRequest request, RestResponse response) {
        try {
            ApplicationDTO applicationDTO = getApplicationDTO(request);
            ApplicationResult result = service.processApplication(applicationDTO);
            processResponse(response, result);

        } catch (ApplicationWebhookServiceException e) {
            processResponse(response, new ApplicationResult(e.getMessage()));
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'ApplicationWebhookService.processApplicationPost: ' + e.getMessage());
            System.debug(LoggingLevel.ERROR, e.getStackTraceString());
            processResponse(response, new ApplicationResult('Unable to process the application. Please try again later.'));
        }
    }


    /**
     * @description Deserializes the request body into an ApplicationDTO and stamps the application
     *              source as 'Webhook' so the record origin can be tracked.
     * @param       request Inbound REST request holding the application JSON payload.
     * @return      ApplicationDTO built from the request body.
     * @throws      ApplicationWebhookServiceException When the request is null or the payload does not produce a valid DTO.
     */
    @TestVisible
    private ApplicationDTO getApplicationDTO(RestRequest request) {
        if (request == null) {
            throw new ApplicationWebhookServiceException('Request is required.');
        }
        ApplicationDTO appDTO = (ApplicationDTO) JSON.deserialize(request.requestBody.toString(), ApplicationDTO.class);
        if (appDTO == null) {
            throw new ApplicationWebhookServiceException('Invalid application data. Please try again.');
        }
        appDTO.applicationSource = 'Webhook';
        return appDTO;
    }


    /**
     * @description Writes the processing outcome to the REST response, using HTTP 200 for a
     *              successful application and HTTP 500 otherwise.
     * @param       response REST response to be populated.
     * @param       result   Outcome of the application processing, serialized as the response body.
     * @return      void
     */
    @TestVisible
    private void processResponse(RestResponse response, ApplicationResult result) {
        response.statusCode = result.success ? 200 : 500; 
        response.responseBody = Blob.valueOf(JSON.serialize(result));

    }


}