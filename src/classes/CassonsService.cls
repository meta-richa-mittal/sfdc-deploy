public without sharing class CassonsService {
    
    public static String getCassonsInventoryByPartId(String partId) {
        if(!AccessControl.ifObjectFieldIsAccessible('Part__c')) {throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE);}
        List<Part__c> partList = [SELECT Part_Number__c, Cassons_SOH__c, Cassons_Description__c, Description__c FROM Part__c WHERE Id =: partId];
        String jsonString = '';
        if(partList.size() > 0) {
            CassonsPartWrapper cassonsPartObj = new CassonsPartWrapper();
            populateCassonsField(cassonsPartObj, partList[0]);
            jsonString = system.JSON.serialize(cassonsPartObj);
        }
        return jsonString;
    }

    private static CassonsPartWrapper populateCassonsField(CassonsPartWrapper cassonsPartObj, Part__c partRec) {
        cassonsPartObj.PartNumber = partRec.Part_Number__c;
        cassonsPartObj.PartDescription = (String.isNotBlank(partRec.Cassons_Description__c) ? partRec.Cassons_Description__c : partRec.Description__c);
        cassonsPartObj.AvailableParts = (partRec.Cassons_SOH__c != null ? partRec.Cassons_SOH__c : 0);
        return cassonsPartObj;
    }
}