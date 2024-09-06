/**
 * Author: Nidhi Sharma
 * Since: April 01, 2022
 * Name: BPWebServiceManager
 * Description: Apex class for all web services
**/
global with sharing class BPWebServiceManager {

    webservice static String unsubmitClaim(String soId) {
        return unsubmitClaimBySOId(soId);
    }

    global static String unsubmitClaimBySOId(String soId) {
        String errorMsg;
        if(String.isNotBlank(soId)) {
            List<Service_Order_Header__c> soRecList = SOQLUtility.getQueryResults('Service_Order_Header__c', 'Select Id, Work_Status__c, Invoice_Number__c,  Claim_Status__c, (Select Id from SO_Payment_Roles__r), (Select Id FROM Claims__r), (Select Id FROM CO_Invoice_Items__r ORDER BY CreatedDate) FROM Service_Order_Header__c WHERE Id = \'' + soId + '\'');
            if(!soRecList.isEmpty()) {
                if(soRecList[0].Work_Status__c.equalsIgnoreCase('Invoiced') || soRecList[0].Invoice_Number__c != null) {
                    errorMsg = 'Unsubmitting claim for an invoiced job is not allowed';
                }  else if(soRecList[0].Claims__r.isEmpty()) {
                    errorMsg = 'Claim not found';
                } else {
                    delete SOQLUtility.getQueryResults('Claim_Line_Item__c', 'Select Id FROM Claim_Line_Item__c WHERE Claim__r.Service_Order_Header__c = \'' + soId + '\'');
                    if(!soRecList[0].CO_Invoice_Items__r.isEmpty()) {
                        CO_Invoice_Item__c coInvItemRec = soRecList[0].CO_Invoice_Items__r[0];
                        coInvItemRec.SO_Payment_Role__c = null;
                        DMLUtility.updateSobjectList('CO_Invoice_Item__c', coInvItemRec);
                    }
                    DMLUtility.deleteSobjectList('SO_Payment_Role__c', soRecList[0].SO_Payment_Roles__r);
                    DMLUtility.deleteSobjectList('Claim__c', soRecList[0].Claims__r);

                    soRecList[0].Claim_Status__c = 'Unsubmitted';
                    DMLUtility.updateSobjectList('Service_Order_Header__c', soRecList[0]);
                }
            } else {
                errorMsg = 'No Service job found with id ' + soId;
            }
        } else {
            errorMsg = 'Service job id cannot be blank';
        }
        return errorMsg;
    }
}