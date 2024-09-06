@RestResource(urlMapping='/v1/part/*')
global without sharing class RestV1_Part {
    
    @HttpGet
    global static void doGet() {}
}