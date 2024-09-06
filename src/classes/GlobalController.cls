public without sharing class GlobalController  {
    
    public static String Application{get;}
    public static String Assests{get;}
    public static String Application_Images{get;}
    public static Map<String, String> resourceMap;
    public static String lastUpdatedTimeStamp {get;}
    public Integer cacheExpiresIn {get {return 86400;} set;}
    
    public Boolean IsLoadNewCustomerOrder {get{return GeneralConfiguration.isLoadNewCustomerOrder();} set;}
    public Boolean IsLoadTechScheduling {get{return GeneralConfiguration.isLoadTechnicianScheduling();} set;} 
    public String PreferredPaymentPublicKey {get{return PreferredPaymentService.getPublicKey();} set;} 
    
    public GlobalController() {
        lastUpdatedTimeStamp = '';
        Application = getResourceURL('Application');
        Application_Images = getResourceURL('Application_Images');
        Assests = getResourceURL('Assests');
    }
   
    public static String getResourceURL(String resourceName) {
        return (BP_Configurations__c.getOrgDefaults().isLoadStaticResource__c ? getURL(resourceName) : 'https://localhost/blackpurl/app/' + resourceName);
    }
    
    private static String getURL(String resourceName) {
        if(resourceMap == null) {
            resourceMap = getResourceMap();
        }
        return (resourceMap.containsKey(resourceName) ? resourceMap.get(resourceName) : '');
    }
    
    private static Map<String, String> getResourceMap() {
        List<String> resourceNameList = new List<String>{'Application', 'Application_Images', 'Assests', 'Locale'};
        List<StaticResource> resourceList = [SELECT Name, NamespacePrefix, SystemModStamp, LastModifiedDate FROM StaticResource WHERE Name IN :resourceNameList];
        Map<String, String> resourceMap = new Map<String, String>();
        for(StaticResource resource : resourceList) {
            lastUpdatedTimeStamp = resource.LastModifiedDate.format('yyyyMMddhhmmss');
            String url = ('/resource/' + resource.SystemModStamp.getTime() + '/' + (String.isNotBlank(resource.NamespacePrefix) ? resource.NamespacePrefix + '__' : '') + resource.Name);
            resourceMap.put(resource.Name, url);
        }
        return resourceMap;
    }
}