@RestResource(urlMapping = '/PlivoIncomingMessage/*')
global without sharing class PlivoIncomingMessageRestAPI {
    @HttpPost
    global static void doPost() {
        PlivoIncomingMessageService.handleIncomingMessage(RestContext.request.requestBody.toString());
    }
}
