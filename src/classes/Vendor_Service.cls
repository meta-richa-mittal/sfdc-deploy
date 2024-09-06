public without sharing class Vendor_Service {
    
     public static List<Vendor> getVendorList() {
    	List<Account> vendorList = [Select Id, Name from Account where Is_Vendor__c = true AND Active__c = true Order By Name ASC];
    	List<Vendor> vendorObjList = new List<Vendor>();
    	for(Account vendorRec : vendorList) {
    		vendorObjList.add(new Vendor(vendorRec.Id, vendorRec.Name));
    	}
    	return vendorObjList;
    }
}