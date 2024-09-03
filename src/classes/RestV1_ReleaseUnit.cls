@RestResource(urlMapping='/v1/unit/*/release')
global without sharing class RestV1_ReleaseUnit {

    @HttpPost
    global static void releaseUnit(RestV1_UnitReleaseRequestWrapper data) {}
}