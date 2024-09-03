@RestResource(urlMapping='/v1/unit/receive')
global without sharing class RestV1_ReceiveUnit {

    @HttpPost
    global static void receiveUnit(RestV1_UnitReceiveRequestWrapper data) {}
}