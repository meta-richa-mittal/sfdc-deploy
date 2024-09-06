global without sharing class ServiceJobLaborCostCalculation extends PostInstallScriptBaseBatch {

    private Datetime fromDateTime, toDateTime;

    global ServiceJobLaborCostCalculation() {
        this.scriptName = 'executeServiceJobLaborCostCalculation()';
    }

    global ServiceJobLaborCostCalculation(Datetime fromDateTimeVal) {
        this.scriptName = 'executeServiceJobLaborCostCalculation()';
        this.fromDateTime = fromDateTimeVal;
    }

    global ServiceJobLaborCostCalculation(Datetime fromDateTimeVal, DateTime toDateTimeVal) {
        this.scriptName = 'executeServiceJobLaborCostCalculation()';
        this.fromDateTime = fromDateTimeVal;
        this.toDateTime = toDateTimeVal;
    }
    
    global override Database.QueryLocator startScript(Database.BatchableContext bc) {
        if(!GeneralConfiguration.isTechnicianHoursCostingEnabled()) {
            return null;
        }
        if(fromDateTime == null) fromDateTime = Datetime.newInstance(2023, 01, 31, 0, 0, 0);

        String strQuery = 'SELECT Id, Invoice_Number__c, Invoice_Number__r.JournalEntryAccountingId__c, ' +
        'Invoice_Number__r.Xero_CO_Invoice_JE_Accounting_Id__c FROM Service_Order_Header__c ' +
        'WHERE Id IN (Select Service_Order_Header__c FROM Service_Order_Line_Item__c WHERE Labour_Code__c != null) AND '+
        '(SO_Status__c IN (\'Job Complete\',\'Ready to invoice\') OR '+
        '(Is_Technician_Hours_Costing_Enabled__c = true AND Invoice_Number__r.Closed_Invoice_Date__c >=: fromDateTime '+
        (toDateTime != null ? ' AND Invoice_Number__r.Closed_Invoice_Date__c <=: toDateTime ' : '') + '))';
        return Database.getQueryLocator(strQuery);
    }
    
    global override void executeScript(Database.BatchableContext bc, List<SObject> jobList) {
        updateSOLILaborCost(jobList);
        updateInvoicedServiceJobLaborCost(jobList);
        updateInvoiceHeaderCost(jobList);
    }
    
    global override void finishScript(Database.BatchableContext bc) {
        AccountingScriptUtil.syncCOInvoiceJE(25, 60);
    }

    private static void updateSOLILaborCost(List<Service_Order_Header__c> jobList) {
        jobList = [SELECT Id, (select Service_Order_Header__c, Qty_Needed__c, Total_Cost__c, Cost__c, 
            Labour_Code__r.Cost_Method__c, Labour_Code__r.Cost_Rate__c from Service_Order_Line_Items__r where Labour_Code__c != NULL),
            (select Total_Cost__c from Hours_Logged__r where Is_Removed__c = false) FROM Service_Order_Header__c WHERE Id IN :jobList];

        List<Service_Order_Line_Item__c> soliListToUpdate = ServiceJobService.populateCostOnLaborSOLI(jobList);
        ServiceOrderLineItemTriggerHelper.shouldTriggerRunStop = true;
        DMLUtility.updateSobjectList('Service_Order_Line_Item__c', soliListToUpdate);
        ServiceOrderLineItemTriggerHelper.shouldTriggerRunStop = false;
    }

    private static void updateInvoicedServiceJobLaborCost(List<Service_Order_Header__c> jobList) {
        List<Service_Order_Header__c> invoicedJobList = [select Id, Total_Labour_Cost__c, (select Total_Cost__c from Service_Order_Line_Items__r where Labour_Code__c != null AND Total_Cost__c != null) 
        from Service_Order_Header__c where Id IN: jobList AND Invoice_Number__c != null];
        
        List<Service_Order_Header__c> soUpdateList = new List<Service_Order_Header__c>();
        for(Service_Order_Header__c soRec : invoicedJobList) {
            Decimal prevValue = soRec.Total_Labour_Cost__c;
            soRec.Total_Labour_Cost__c = 0;
            for(Service_Order_Line_Item__c soli : soRec.Service_Order_Line_Items__r) {
                soRec.Total_Labour_Cost__c += soli.Total_Cost__c;
            }
            if(prevValue != soRec.Total_Labour_Cost__c) {
                soUpdateList.add(soRec);
            }
        }
        SOTriggerHelper.isForceStopTrigger = true;
        DMLUtility.updateSobjectList('Service_Order_Header__c', soUpdateList);
        SOTriggerHelper.isForceStopTrigger = false;
    }

    private static void updateInvoiceHeaderCost(List<Service_Order_Header__c> jobList) {
        Map<Id, CO_Invoice_Header__c> coInvoiceHeaderRecMap = new Map<Id, CO_Invoice_Header__c>();
        for(Service_Order_Header__c soRec : jobList) {
            if(soRec.Invoice_Number__c != null) coInvoiceHeaderRecMap.put(soRec.Invoice_Number__c, soRec.Invoice_Number__r);
        }
        if(!coInvoiceHeaderRecMap.isEmpty()) {
            List<CO_Invoice_Header__c> coInvUpdateList = new List<CO_Invoice_Header__c>();
            for(Id coInvoiceHeaderId : coInvoiceHeaderRecMap.keySet()) {
                CO_Invoice_Header__c coInvHeaderRecToUpdate = COService.populateFieldsOnInvoice(coInvoiceHeaderId);
                CO_Invoice_Header__c originalCOInvHeaderRec = coInvoiceHeaderRecMap.get(coInvoiceHeaderId);
                if(originalCOInvHeaderRec.Invoice_Cost__c != coInvHeaderRecToUpdate.Invoice_Cost__c) {
                    if(String.isNotBlank(originalCOInvHeaderRec.JournalEntryAccountingId__c)) {
                        coInvHeaderRecToUpdate.availForQBJournalEntrySync__c = true;
                    } else if(String.isNotBlank(originalCOInvHeaderRec.Xero_CO_Invoice_JE_Accounting_Id__c)) {
                        coInvHeaderRecToUpdate.Available_For_Xero_CO_Invoice_JE_Sync__c = true;
                    }
                    coInvUpdateList.add(coInvHeaderRecToUpdate);
                }
            }
            COInvoiceTriggerHelper.isForceStopTrigger = true;
            DMLUtility.updateSobjectList('CO_Invoice_Header__c', coInvUpdateList);
            COInvoiceTriggerHelper.isForceStopTrigger = false;
        }
    }
}