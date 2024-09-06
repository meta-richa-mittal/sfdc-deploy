/** 
* Author: Richa Mittal
* Since: Oct 11, 2023
* Name: PayrollAndJobClockingAutoClockOffBatch 
* Description: Batch Apex class to clock will automatically clock out any payroll or job clocking entries which are still active.
**/
global without sharing class PayrollAndJobClockingAutoClockOffBatch implements Database.Batchable<sobject>, Schedulable {
    
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new PayrollAndJobClockingAutoClockOffBatch(), 100);
    }

    global Iterable<sObject> start(Database.BatchableContext bc) {
        List<sObject> sObjList = new List<sObject>();
        sObjList.addAll([SELECT Id, Start_Date_Time__c, Service_Order_Header__c, Technician__c, Paused_Date_Time__c, Paused_Hours__c, End_Date_Time__c 
                            FROM Hours_Logged__c WHERE Start_Date_Time__c != null AND End_Date_Time__c = null]);
        sObjList.addAll([SELECT Id FROM Payroll_Time__c WHERE Start_Date__c != null AND End_Date__c = null]);
        return sObjList;
    }
      
    global void execute(Database.batchableContext bc, List<sObject> sObjList) {
        List<Hours_Logged__c> hoursLoggedList = new List<Hours_Logged__c>();
        List<Payroll_Time__c> payrollList = new List<Payroll_Time__c>();
        for(sObject sObjRec: sObjList) {
            String objectName = (Id.valueOf(sObjRec.Id)).getSObjectType().getDescribe().getName();
            if(objectName == Constants.NAMESPACE + 'Hours_Logged__c') {
                hoursLoggedList.add((Hours_Logged__c)sObjRec);
            } else if(objectName == Constants.NAMESPACE + 'Payroll_Time__c') {
                DateTime clockOffDtTime = DateTime.newInstance(System.now().year(), System.now().month(), System.now().day(), 
                                                                System.now().hour(), System.now().minute(), 0);
                sObjRec.put('End_Date__c', clockOffDtTime);
                payrollList.add((Payroll_Time__c)sObjRec);
            }
        }
        if(!hoursLoggedList.isEmpty()) {
            TechnicianService.setHoursLoggedDataWhenClcokedOff(null, null, hoursLoggedList);
        }
        DMLUtility.updateSobjectList('Payroll_Time__c', payrollList);
    }
      
    global void finish(Database.batchableContext bc) {
        syncHoursLoggedToAccounting();
    }

    private void syncHoursLoggedToAccounting() {
        if(GeneralConfiguration.isTechnicianHoursCostingEnabled() && String.isNotBlank(IntegrationServiceFactory.getActiveAccountingIntegrationName())) {
            // Sync to QB/Xero
            AccountingScriptUtil.syncHoursLogged(25, 60);
        }
    }
}