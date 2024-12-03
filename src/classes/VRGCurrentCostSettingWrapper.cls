/**
 * Author: Nidhi Sharma
 * Since: September 14, 2022
 * Name: VRGCurrentCostSettingWrapper
 * Description: VRG current cost setting wrapper class
**/
public class VRGCurrentCostSettingWrapper {
    public String VRGId;
    public String ItemDesc;
    public Boolean IsUpdateCurrentCost;

    public VRGCurrentCostSettingWrapper(Vendor_Receiving_Group__c vrGroup, PO_Type__c vendorDefaultPOType) {
        if(vrGroup != null && vrGroup.Part__c != null) {
            this.VRGId = vrGroup.Id;
            this.ItemDesc = vrGroup.Part__r.Part_Number__c + ' - ' + vrGroup.Part__r.Description__c + 
                            (vrGroup.Is_Order_As_Individual_Item__c ? ' (Ordered as individual items)' : '');
            if(vrGroup.Cost_Update_Reviewed__c) {
                this.IsUpdateCurrentCost = !vrGroup.Ignore_Current_Cost_Update__c;
            } else {
                this.IsUpdateCurrentCost = VendorOrderReceivingService.getCurrentCostUpdateSetting(vrGroup, vendorDefaultPOType);
            }
        }
    }
}