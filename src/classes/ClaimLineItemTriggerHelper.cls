/**
 * Author: Richa ittal
 * Since: Jan. 23, 2019
 * Name: ClaimLineItemTriggerHelper
 * Description: Helper class for triggers on Claim Line Item object
**/
public without sharing class ClaimLineItemTriggerHelper {
    
    public static Boolean isUpdateSOLI = true;
    // List to store trigger new list
    public static List<Claim_Line_Item__c> claimLineItemNewList = new List<Claim_Line_Item__c>();
    
    // List to store trigger old list
    public static List<Claim_Line_Item__c> claimLineItemOldList = new List<Claim_Line_Item__c>();
    
    // Map to store new Trigger Map
    public static Map<Id, Claim_Line_Item__c> claimLineItemNewMap = new Map<Id, Claim_Line_Item__c>();
    
    // Map to store Old Trigger Map
    public static Map<Id, Claim_Line_Item__c> claimLineItemOldMap = new Map<Id, Claim_Line_Item__c>();

    public static void afterInsert() {
        updateClaimTotals();
    }

    public static void afterUpdate() {
        updateSOLIForClaimLI();
        updateClaimTotals();
    }
    
    private static void updateSOLIForClaimLI() {
        if(!isUpdateSOLI) return;
        List<Service_Order_Line_Item__c> soliListToUpdate = new List<Service_Order_Line_Item__c>();
        for(Claim_Line_Item__c claimLIRec: claimLineItemNewList) {
            if(claimLIRec.Claimed_Qty__c != claimLineItemOldMap.get(claimLIRec.Id).Claimed_Qty__c ||
                claimLIRec.Claimed_Price__c != claimLineItemOldMap.get(claimLIRec.Id).Claimed_Price__c) {
                    Decimal claimedPrice = (claimLIRec.Claimed_Price__c != null ? claimLIRec.Claimed_Price__c : 0);
                    Service_Order_Line_Item__c soliRec = new Service_Order_Line_Item__c(Id = claimLIRec.Service_Order_Line_Item__c, Qty_Needed__c = claimLIRec.Claimed_Qty__c);
                    if(GeneralConfiguration.getTaxIncludingPricing()) {
                        soliRec.Price_When_Tax_Included__c = claimedPrice;
                        soliRec.kit_Price__c = (claimedPrice / (1 + claimLIRec.Tax__c / 100 ));
                    } else {
                        soliRec.Kit_Price__c = claimedPrice;
                    }
                    soliListToUpdate.add(soliRec);
                }
        }
        if(soliListToUpdate.size() > 0) {
            ServiceOrderLineItemTriggerHelper.isUpdateClaimLI = false;
    		Boolean isTriggerExecute = ServiceOrderLineItemTriggerHelper.isTriggerExecuted;
    		ServiceOrderLineItemTriggerHelper.isTriggerExecuted = false;
            DMLUtility.updateSobjectList('Service_Order_Line_Item__c', soliListToUpdate);
			ServiceOrderLineItemTriggerHelper.isTriggerExecuted = isTriggerExecute;
            ServiceOrderLineItemTriggerHelper.isUpdateClaimLI = true;
        }
    }

    private static void updateClaimTotals() {
        Set<Id> claimIdSet = new Set<Id>();
        for (Claim_Line_Item__c claimLIRec : claimLineItemNewList) {
            if(Trigger.isInsert) {
                claimIdSet.add(claimLIRec.Claim__c);
            } else if(Trigger.isUpdate && (claimLIRec.Claimed_Qty__c != claimLineItemOldMap.get(claimLIRec.Id).Claimed_Qty__c ||
                    claimLIRec.Claimed_Price__c != claimLineItemOldMap.get(claimLIRec.Id).Claimed_Price__c || claimLIRec.Approved_Qty__c != claimLineItemOldMap.get(claimLIRec.Id).Approved_Qty__c ||
                    claimLIRec.Approved_Price__c != claimLineItemOldMap.get(claimLIRec.Id).Approved_Price__c)) {
                claimIdSet.add(claimLIRec.Claim__c);
            }
        }

        List<Claim__c> claimList = [SELECT Id, Claimed_Total__c, Total_Variance__c, (SELECT Claimed_Subtotal__c, Variance__c FROM Claim_Line_Items__r WHERE Is_Variance__c = false) FROM Claim__c WHERE Id IN :claimIdSet];

        Decimal claimedAmount = 0;
        Decimal varianceAmount = 0;
        for (Claim__c claimRec : claimList) {
            claimedAmount = 0;
            varianceAmount = 0;
            for(Claim_Line_Item__c cliRec : claimRec.Claim_Line_Items__r) {
                claimedAmount += cliRec.Claimed_Subtotal__c != null ? cliRec.Claimed_Subtotal__c : 0;
                varianceAmount += cliRec.Variance__c != null ? cliRec.Variance__c : 0;
            }
            claimRec.Claimed_Total__c = claimedAmount;
            claimRec.Total_Variance__c = varianceAmount;
        }
        DMLUtility.updateSobjectList('Claim__c', claimList);
    }
}