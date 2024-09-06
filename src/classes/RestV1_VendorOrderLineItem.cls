@RestResource(urlMapping='/v1/vendorOrderLineItemGroup/*')
global without sharing class RestV1_VendorOrderLineItem {
    
    @HttpPost
    global static void doPost(RestV1_VOLIGRequestWrapper data) {}
    
    @HttpPut
    global static void doPut(RestV1_VOLIGRequestWrapper data) {}
    
    @HttpGet
    global static void doGet() {}
    
    @HttpDelete
    global static void doDelete() {}
}