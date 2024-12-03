/**
 * Author: Nidhi Sharma
 * Since: March 20, 2019
 * Name: VendorMasterSubscriberResource
 * Description: VendorMasterSubscriberResource class.
**/
@RestResource(urlMapping='/bp/NotifySubscriber/*')
global without sharing class VendorMasterSubscriberResource {
    
    public static List<Log__c> errorLogList = new List<Log__c>();
    public static String VENDOR_MASTER_REC_NOT_FOUND = 'Vendor master not found';
    
    @HttpPost
    global static String notifyVendorMasterSubscriber(VendorMasterWrapper VendorMasterObj) {
    	
    	updateSubscriberAboutNewNotification(VendorMasterObj);
    	if(errorLogList.size() > 0) {
    		insert errorLogList;
    		return 'Error';
    	}
    	return 'Success';
    }
    
    private static void updateSubscriberAboutNewNotification(VendorMasterWrapper VendorMasterObj) {
    	Vendor_Master__c originalVMRec = getVendorMasterRec(VendorMasterObj.VendorMasterUID);
    	if(originalVMRec != null) {
    		Vendor_Master__c vmRec = setVendorMasterFieldsToUpdate(originalVMRec.Id, VendorMasterObj);
    		vmRec.Is_Update_Available__c = true;
			update vmRec;
			if(String.isNotBlank(originalVMRec.Vendor_Master_Type__c) && originalVMRec.Vendor_Master_Type__c.equalsIgnoreCase(Label.VM_Automated)) {
				AutomatedPriceFileService.queueAPFImport(vmRec.Id);
			}
    	} else {
    		errorLogList.add(new LogService().createErrorLog('VendorMasterSubscriberResource', 'getVendorMasterRec() ', VENDOR_MASTER_REC_NOT_FOUND, 
            			null, null, VendorMasterObj.VendorMasterUID, LogService.AUTOMATED_PRICE_FILE, false, 'Error'));
    	}
    }
    
    private static Vendor_Master__c setVendorMasterFieldsToUpdate(String recId, VendorMasterWrapper VendorMasterObj) {
    	Vendor_Master__c vmRec = new Vendor_Master__c(Id = recId);
    	vmRec.Category__c = VendorMasterObj.Category;
		vmRec.Cost_New__c = VendorMasterObj.Cost;
		vmRec.Description_EN__c = VendorMasterObj.DescriptionEN;
		vmRec.Description_FR__c = VendorMasterObj.DescriptionFR;
		vmRec.Mfg_Num__c = VendorMasterObj.MFGNum;
		vmRec.Other_Cost_New__c = VendorMasterObj.OtherCost;
		vmRec.Other_Price_New__c = VendorMasterObj.OtherPrice;
		vmRec.Part_Num__c = VendorMasterObj.PartNum;
		vmRec.Pkg_Qty__c = VendorMasterObj.PkgQty;
		vmRec.Price_New__c = VendorMasterObj.Price;
		vmRec.Replaced_By__c = VendorMasterObj.ReplacedBy;
		vmRec.Replaces__c = VendorMasterObj.Replaces;
		vmRec.SKU_Num__c = VendorMasterObj.SKUNum;
		vmRec.Vendor_Name__c = VendorMasterObj.VendorName;
		vmRec.Price_File_Location_URL__c = VendorMasterObj.PriceFileLocation;
		
		return vmRec;
    }
	
    private static Vendor_Master__c getVendorMasterRec(String vendorMasterUID) {
    	List<Vendor_Master__c> vmRecList = [Select Id, Is_Update_Available__c, Vendor_Master_Type__c from Vendor_Master__c where Partner_Vendor_Master_Identifier__c =: vendorMasterUID];
    	if(vmRecList.size() > 0) return vmRecList[0];
    	
    	return null;
    }
    
}