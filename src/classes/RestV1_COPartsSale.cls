@RestResource(urlMapping='/v1/coPartsSale/*')
global without sharing class RestV1_COPartsSale {
    
    @HttpPost
    global static void doPost(RestV1_COPartsSaleRequestWrapper data) {}

    @HttpGet
    global static void doGet() {}
}