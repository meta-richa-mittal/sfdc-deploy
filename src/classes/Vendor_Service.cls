public without sharing class Vendor_Service {
    
     public static List<Vendor> getVendorList() {
    	List<Account> vendorList = [Select Id, Name from Account where Is_Vendor__c = true AND Active__c = true Order By Name ASC];
    	List<Vendor> vendorObjList = new List<Vendor>();
    	for(Account vendorRec : vendorList) {
    		vendorObjList.add(new Vendor(vendorRec.Id, vendorRec.Name));
    	}
    	return vendorObjList;
    }

    public static Id getDefaultPOTypeForVendor(Id vendorId) {
        if(String.isNotBlank(vendorId)) {
            for(PO_Type__c poType : (List<PO_Type__c>) SOQLUtility.getQueryResults('PO_Type__c', ('Select Id from PO_Type__c where IsDefault__c = true AND Vendor__c = \'' + vendorId + '\' LIMIT 1'))) {
                return poType.Id;
            }
        }
        return null;
    }
}