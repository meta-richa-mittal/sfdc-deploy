public without sharing class CassonsUtility {
    public static Set<String> getAllCassonsVendorsIdSet() {
        List<CASSONS_Vendor_List__c> cassonsVendorList =  CASSONS_Vendor_List__c.getAll().values();
        Set<String> cassonsVendorIdSet = new Set<String>();
        for(CASSONS_Vendor_List__c cassonsVendorRec : cassonsVendorList) {
            if(cassonsVendorRec.Active__c) {
                cassonsVendorIdSet.add(cassonsVendorRec.Name);
            }
        }
        return cassonsVendorIdSet;
    }

    public static Integer getPartsPerRequest() {
        return CASSONS_Configuration__c.getOrgDefaults().Parts_Per_Request__c != null ? (Integer)CASSONS_Configuration__c.getOrgDefaults().Parts_Per_Request__c : 200;
    }

    public static String getHerokuEndPoint() {
        return CASSONS_Configuration__c.getOrgDefaults().Heroku_End_Point_URL__c;
    }

    public static Integer getSchedulerInterval() {
        return CASSONS_Configuration__c.getOrgDefaults().Scheduler_Interval__c != null ? (Integer)CASSONS_Configuration__c.getOrgDefaults().Scheduler_Interval__c : 120;
    }
}