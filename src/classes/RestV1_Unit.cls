@RestResource(urlMapping='/v1/unit/*')
global without sharing class RestV1_Unit {
    @HttpGet
    global static void doGet() {}
}