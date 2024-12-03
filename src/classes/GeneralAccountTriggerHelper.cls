/**
 * Author: Nidhi Sharma
 * Since: August 24, 2023
 * Name: GeneralAccountTriggerHelper
 * Description: Trigger executes on events of General_Account__c object
**/
public without sharing class GeneralAccountTriggerHelper {

    public static void afterUpdate(List<General_Account__c> newList, Map<Id, General_Account__c> genAccOldMap) {
        removeGenAccReferences(newList, genAccOldMap);
    }

    public static void afterDelete(List<General_Account__c> oldList, Map<Id, General_Account__c> genAccOldMap) {
        removeGenAccReferences(oldList, genAccOldMap);
    }

    private static void removeGenAccReferences(List<General_Account__c> genAccList, Map<Id, General_Account__c> genAccOldMap) {
        if(String.isNotBlank(AccountingUtil.activeAccIntegrationName)) {
            Set<String> accIdSet = new Set<String>();
            for(General_Account__c genAcc: genAccList) {
                if((trigger.isDelete && genAcc.Is_Active__c) || (trigger.isUpdate && !genAcc.Is_Active__c && genAccOldMap.get(genAcc.Id).Is_Active__c)) {
                    if(AccountingUtil.activeAccIntegrationName.equalsIgnoreCase(XeroUtility.XERO)) {
                        accIdSet.add(genAcc.Account_Number__c);
                    } else {
                        accIdSet.add(genAcc.Accounting_Id__c);
                    }
                }
            }
            accIdSet.remove(null);
            if(!accIdSet.isEmpty()) {
                //Category
                List<Category__c> categoryUpdateList = [Select Id, Income_GL__c, Inventory_GL__c, COGS_GL__c FROM Category__c WHERE Income_GL__c IN: accIdSet OR Inventory_GL__c IN: accIdSet OR COGS_GL__c IN: accIdSet];
                for(Category__c catRec : categoryUpdateList) {
                    if(accIdSet.contains(catRec.Income_GL__c)) {
                        catRec.Income_GL__c = null;
                    }
                    if(accIdSet.contains(catRec.Inventory_GL__c)) {
                        catRec.Inventory_GL__c = null;
                    }
                    if(accIdSet.contains(catRec.COGS_GL__c)) {
                        catRec.COGS_GL__c = null;
                    }
                }
                DMLUtility.updateSobjectList('Category__c', categoryUpdateList);

                //Accounting Default Accounts
                Accounting_Default_Accounts__c defaultAccConfig = Accounting_Default_Accounts__c.getOrgDefaults();
                Map<String, Object> defaultAccMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(defaultAccConfig));
                for(String fieldAPIName : defaultAccMap.keySet()) {
                    if(fieldAPIName.endsWith('__c') && defaultAccMap.get(fieldAPIName) != null && 
                    accIdSet.contains(String.valueOf(defaultAccMap.get(fieldAPIName)))) {
                        defaultAccMap.put(fieldAPIName, null);
                    }
                }
                upsert defaultAccConfig;

                //Payment Methods
                List<Payment_Method__c> paymentMethodList = [Select Id from Payment_Method__c where Undeposited_Funds__c IN: accIdSet];
                for(Payment_Method__c paymentMethodRec : paymentMethodList) {
                    paymentMethodRec.Undeposited_Funds__c = null;
                }
                DMLUtility.updateSobjectList('Payment_Method__c', paymentMethodList);

            }
        }
    }
}