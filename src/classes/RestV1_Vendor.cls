@RestResource(urlMapping='/v1/vendor')
global without sharing class RestV1_Vendor {
    
    @HttpPost
    global static void doPost(RestV1_VendorRequestWrapper data) {}
}