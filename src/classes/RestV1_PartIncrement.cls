@RestResource(urlMapping='/v1/part/*/increment')
global without sharing class RestV1_PartIncrement {

    @HttpPost
    global static void increment(RestV1_PartIncrementRequestWrapper data) {}
}