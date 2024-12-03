@RestResource(urlMapping='/v1/vendorOrder/*')
global without sharing class RestV1_VendorOrder {

    @HttpPost
    global static void doPost(RestV1_VendorOrderRequestWrapper data) {}

    @HttpPut
    global static void doPut(RestV1_VendorOrderRequestWrapper data) {}
    
    @HttpGet
    global static void doGet() {}
}