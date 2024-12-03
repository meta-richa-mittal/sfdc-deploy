@RestResource(urlMapping='/v1/part/*/decrement')
global without sharing class RestV1_PartDecrement {

    @HttpPost
    global static void decrement(RestV1_PartDecrementRequestWrapper data) {}
}