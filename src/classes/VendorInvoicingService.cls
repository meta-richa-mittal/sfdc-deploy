/**
 * Author: Richa Mittal
 * Since: Nov 21, 2022
 * Name: VendorInvoicingService
 * Description: service class for vendor invoicing related actions
**/
public with sharing class VendorInvoicingService {
    public static void saveLCAData(String lcaJsonStr) {
        VendorInvoicingCtrl.VIHeaderWrapper lcaJson = (VendorInvoicingCtrl.VIHeaderWrapper)System.JSON.deserialize(BPUtility.getDecodedString(lcaJsonStr), VendorInvoicingCtrl.VIHeaderWrapper.class);
		
        Decimal totalAppliedCharge = 0;
        List<Vendor_Invoicing_Group__c> viGroupListToUpdate = new List<Vendor_Invoicing_Group__c>();
		List<Other_Charges__c> otherChargeListToUpdate = new List<Other_Charges__c>();
		for(VendorInvoicingCtrl.VIGroup viGrpRec: lcaJson.VIGroupList) {
            viGrpRec.AppliedCharge = viGrpRec.AppliedCharge != null ? viGrpRec.AppliedCharge.setScale(2, RoundingMode.HALF_DOWN) : 0;
			viGroupListToUpdate.add(new Vendor_Invoicing_Group__c(Id=viGrpRec.VIGroupId, Applied_Charge__c = viGrpRec.AppliedCharge));
            totalAppliedCharge += viGrpRec.AppliedCharge;
		}

        if(totalAppliedCharge > lcaJson.TotalOtherCharges) throw new BlackPurlException('Allocated charges can not be more than the total of other charges.');
		
        for(VendorInvoicingCtrl.OtherChargesWrapper otherChargeRec: lcaJson.OtherChargesList) {
            otherChargeRec.AppliedAmount = otherChargeRec.AppliedAmount != null ? otherChargeRec.AppliedAmount.setScale(2, RoundingMode.HALF_DOWN) : 0;
			otherChargeListToUpdate.add(new Other_Charges__c(Id=otherChargeRec.Id, Applied_Amount__c = otherChargeRec.AppliedAmount));
		}

		DMLUtility.updateSobjectList('Vendor_Invoicing_Group__c', viGroupListToUpdate);
		DMLUtility.updateSobjectList('Other_Charges__c', otherChargeListToUpdate);
    }
}