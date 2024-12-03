@RestResource(urlMapping='/v1/customer')
global without sharing class RestV1_Customer {
    
    @HttpPost
    global static void doPost(RestV1_CustomerRequestWrapper data) {}
}