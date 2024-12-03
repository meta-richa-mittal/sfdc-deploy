/** 
* Author: Nidhi Sharma
* Since: May 09, 2023
* Name: ArchiveDeleteCOBatchScheduler 
* Description: Batch Apex class which archive/delete customer orders
**/
global without sharing class ArchiveDeleteCOBatchScheduler implements Database.Batchable<sobject>, Schedulable, Database.Stateful {
    
    private List<Log__c> errorLogToInsert = new List<Log__c>();

    global void execute(SchedulableContext sc) {
        Database.executeBatch(new ArchiveDeleteCOBatchScheduler(), 10);
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {

        Integer archiveInDays, deleteInDays;

        //Subtracting 1 from the dates as Last N days filter includes (N + 1) day.
        //https://developer.salesforce.com/docs/atlas.en-us.soql_sosl.meta/soql_sosl/sforce_api_calls_soql_select_dateformats.htm
        if(GeneralConfiguration.getConfigurations().Automatically_Archive_Quotes__c) {
            archiveInDays = ((GeneralConfiguration.getConfigurations().Automatically_Archive_After_Days__c != null ? 
            Integer.valueOf(GeneralConfiguration.getConfigurations().Automatically_Archive_After_Days__c) : 180) - 1);

            if(GeneralConfiguration.getConfigurations().Automatically_Delete_Quotes__c) {
                deleteInDays = ((GeneralConfiguration.getConfigurations().Automatically_Delete_After_Days__c != null ? 
                Integer.valueOf(GeneralConfiguration.getConfigurations().Automatically_Delete_After_Days__c) : 180) - 1);
            }
        }
        String strQuery = 'Select Id FROM CO_Header__c WHERE Id = null LIMIT 0';
        if(archiveInDays != null && archiveInDays > 0) {
            strQuery = 'Select Id, Is_Archived__c, Archived_Date_Time__c from CO_Header__c where Order_Status__c = \'Quote\' AND ((Is_Archived__c = false AND LastModifiedDate < Last_N_Days:'+archiveInDays+')';
            if(deleteInDays != null && deleteInDays > 0) {
                strQuery += ' OR (Is_Archived__c = true AND Archived_Date_Time__c < Last_N_Days:'+deleteInDays+'))';
            } else {
                strQuery += ')';
            }
        }
        if(Test.isRunningTest()) {
            strQuery = 'Select Id, Is_Archived__c, Archived_Date_Time__c from CO_Header__c';
        }
        system.debug('strQuery:: ' + strQuery);
        return Database.getQueryLocator(strQuery);
    }
      
    global void execute(Database.batchableContext bc, List<CO_Header__c> coHeaderList) {
        List<CO_Header__c> coDeleteList = new List<CO_Header__c>();
        List<CO_Header__c> coArchiveList = new List<CO_Header__c>();
        for(CO_Header__c coRec : coHeaderList) {
            if(coRec.Is_Archived__c) {
                coDeleteList.add(coRec);
            } else {
                coArchiveList.add(coRec);
            }
        }
        system.debug('coDeleteList size:: ' + coDeleteList.size() + ', coArchiveList size:: ' + coArchiveList.size());
        system.debug('coDeleteList:: ' + coDeleteList);
        system.debug('coArchiveList:: ' + coArchiveList);

        deleteCustomerOrders(coDeleteList);
        archiveCustomerOrders(coArchiveList);
    }
      
    global void finish(Database.batchableContext bc) {
        DMLUtility.insertSobjectList('Log__c', errorLogToInsert);
    }

    private void archiveCustomerOrders(List<CO_Header__c> coArchiveList) {
        try {
            for(CO_Header__c coRec : coArchiveList){
                coRec.Is_Archived__c = true;
                coRec.Archived_Date_Time__c = System.now();
            }
            DMLUtility.updateSobjectList('CO_Header__c', coArchiveList);
        } catch(Exception e) {
            system.debug('Exception in archiving quote CO :: ' + e.getMessage());
            String failedCOHeaderIds = '';
            for(CO_Header__c coRec : coArchiveList) {
                failedCOHeaderIds += coRec.Id + ';';
            }
            errorLogToInsert.add(new LogService().createErrorLog('ArchiveDeleteCOBatchScheduler', 'archiveCustomerOrders', e.getMessage(), LogService.NOT_APPLICABLE, e.getStackTraceString(), 
            failedCOHeaderIds, 'Archive Quote CO', false, 'Error'));
        }
    }

    private void deleteCustomerOrders(List<CO_Header__c> coDeleteList) {
        Savepoint sp;
        try {
            if(coDeleteList != null && !coDeleteList.isEmpty()) {
                sp = Database.setSavepoint();

                List<SObject> sobjDeleteList = new List<SObject>();

                //Delete Related records
                sobjDeleteList.addAll([Select Id From Individual_Tax__c where CO_Line_Item__r.CO_Header__c IN: coDeleteList 
                                    OR Service_Order_Line_Item__r.Service_Order_Header__r.CO_Header__c IN: coDeleteList 
                                    OR Option_Fee__r.Deal__r.CO_Header__c IN: coDeleteList 
                                    OR Deal_Unit_Price_Cost__r.Deal_Item__r.Deal__r.CO_Header__c IN: coDeleteList 
                                    OR F_I_Product__r.Deal_Finance__r.Deal__r.CO_Header__c IN: coDeleteList 
                                    OR Deal_Item__r.Deal__r.CO_Header__c IN: coDeleteList
                OR Deal__r.CO_Header__c IN: coDeleteList]);

                sobjDeleteList.addAll([Select Id FROM CO_Invoice_Item__c WHERE CO_Invoice_Header__r.CO_Header__c IN: coDeleteList]);
                
                sobjDeleteList.addAll([Select Id FROM CO_Form__c WHERE CO_Header__c IN: coDeleteList]);
                sobjDeleteList.addAll([Select Id FROM Message_History__c WHERE CO_Header__c IN: coDeleteList]);
                sobjDeleteList.addAll([Select Id FROM Internal_Comment__c WHERE CO_Header__c IN: coDeleteList]);
                sobjDeleteList.addAll([Select Id FROM Tax_Exemption__c WHERE CO_Header__c IN: coDeleteList]);
                sobjDeleteList.addAll([Select Id FROM Suppress_CO_Item__c WHERE CO_Header__c IN: coDeleteList]);                
                
                DMLUtility.deleteSobjectList('CO_Header__c', sobjDeleteList);

                sobjDeleteList = new List<SObject>();
                sobjDeleteList.addAll([Select Id FROM Deal_Unit_Price_Cost__c WHERE Deal_Item__r.Deal__r.CO_Header__c IN: coDeleteList]);
                sobjDeleteList.addAll([Select Id FROM Option_Fee__c WHERE Deal_Item__r.Deal__r.CO_Header__c IN: coDeleteList]);
                sobjDeleteList.addAll([Select Id FROM Deal_Kit_Header__c WHERE Deal_Item__r.Deal__r.CO_Header__c IN: coDeleteList]);
                sobjDeleteList.addAll([Select Id FROM F_I_Product__c WHERE Deal_Finance__r.Deal__r.CO_Header__c IN: coDeleteList]);
                sobjDeleteList.addAll([Select Id FROM Deal_Finance__c WHERE Deal__r.CO_Header__c IN: coDeleteList]);
                sobjDeleteList.addAll([Select Id FROM Deal_Item__c WHERE Deal__r.CO_Header__c IN: coDeleteList]);
                sobjDeleteList.addAll([Select Id FROM Deal__c WHERE CO_Header__c IN: coDeleteList]);

                DealUnitPriceAndCostTriggerHelper.isForceStopTrigger = OptionAndFeeTriggerHelper.isForceStopTrigger = 
                DealItemTriggerHelper.isForceStopTrigger = FIProductTriggerHelper.isForceStopTrigger = 
                DealTriggerHelper.isForceStopTrigger = true;
                DMLUtility.deleteSobjectList('CO_Header__c', sobjDeleteList);
                DealUnitPriceAndCostTriggerHelper.isForceStopTrigger = OptionAndFeeTriggerHelper.isForceStopTrigger = 
                DealItemTriggerHelper.isForceStopTrigger = FIProductTriggerHelper.isForceStopTrigger = 
                DealTriggerHelper.isForceStopTrigger = false;

                sobjDeleteList = new List<SObject>();
                sobjDeleteList.addAll([Select Id FROM Service_Order_Line_Item__c WHERE Service_Order_Header__r.CO_Header__c IN: coDeleteList]);
                sobjDeleteList.addAll([Select Id FROM Service_Order_Kit_Header__c WHERE Service_Order_Header__r.CO_Header__c IN: coDeleteList]);
                sobjDeleteList.addAll([Select Id FROM Service_Order_Header__c WHERE CO_Header__c IN: coDeleteList]);
                
                sobjDeleteList.addAll([Select Id FROM CO_Line_Item__c WHERE CO_Header__c IN: coDeleteList]);
                sobjDeleteList.addAll([Select Id FROM CO_Kit_Header__c WHERE CO_Header__c IN: coDeleteList]);
                sobjDeleteList.addAll([Select Id FROM CO_Invoice_Header__c WHERE CO_Header__c IN: coDeleteList]);
                sobjDeleteList.addAll([Select Id FROM CO_Section_Detail__c WHERE CO_Header__c IN: coDeleteList]);
                sobjDeleteList.addAll(coDeleteList);                
                
                ServiceOrderLineItemTriggerHelper.shouldTriggerRunStop = SOTriggerHelper.isForceStopTrigger = 
                COLineItemTriggerHelper.isForceStopTrigger = COTriggerHelper.isForceStopTrigger = 
                COInvoiceTriggerHelper.isForceStopTrigger = true;
                DMLUtility.deleteSobjectList('CO_Header__c', sobjDeleteList);
                ServiceOrderLineItemTriggerHelper.shouldTriggerRunStop = SOTriggerHelper.isForceStopTrigger = 
                COLineItemTriggerHelper.isForceStopTrigger = COTriggerHelper.isForceStopTrigger = 
                COInvoiceTriggerHelper.isForceStopTrigger = false;
            }
        } catch(Exception e) {
            if(sp != null) {
                Database.rollback(sp);
            }
            system.debug('Exception in deleting quote CO :: ' + e.getMessage());
            String failedCOHeaderIds = '';
            for(CO_Header__c coRec : coDeleteList) {
                failedCOHeaderIds += coRec.Id + ';';
            }
            errorLogToInsert.add(new LogService().createErrorLog('ArchiveCustomerOrderBatchScheduler', 'deleteCustomerOrders', e.getMessage(), LogService.NOT_APPLICABLE, e.getStackTraceString(), 
            failedCOHeaderIds, 'Delete Quote CO', false, 'Error'));
        }
    }
}