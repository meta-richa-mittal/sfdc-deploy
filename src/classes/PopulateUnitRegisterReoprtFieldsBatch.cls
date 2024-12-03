global without sharing class PopulateUnitRegisterReoprtFieldsBatch extends PostInstallScriptBaseBatch  {
    global PopulateUnitRegisterReoprtFieldsBatch() {
        this.scriptName = 'executePopulateUnitRegisterReoprtFieldsBatch()';
    }
    
    global override Database.QueryLocator startScript(Database.BatchableContext bc) {
        String strQuery = 'SELECT Id FROM Customer_Owned_Unit__c WHERE (Unit_Type__c = \'STOCK\') OR (Unit_Type__c = \'COU\' AND Consignment__c = true)';
        return Database.getQueryLocator(strQuery);
    }
    
    global override void executeScript(Database.BatchableContext bc, List<SObject> couList) {
        List<Customer_Owned_Unit__c> couListToUpdate = new List<Customer_Owned_Unit__c>();
        List<Customer_Owned_Unit__c> stockUnitList = [SELECT Id, Account__c, Date_Stocked_In__c, Acquisition_Cost__c, Invoice_Number__c, Vendor__c, Agreed_Payout__c, Status__c, Referenced_Unit__c, Referenced_Unit__r.Total_Cost__c, (SELECT Id, Deal__r.CO_Header__r.Name, Total_Cost__c, Deal__r.CO_Header__r.Customer__c, Unit_Price__c, Type__c FROM Deals_Items__r WHERE Type__c = 'Trade In' Limit 1), (SELECT Id, Deal__r.CO_Header__r.Name, Total_Cost__c, Deal__r.CO_Header__r.Customer__c, Unit_Price__c, Type__c FROM Deals_Units_Junction__r ), (SELECT Id, Total_Cost__c, Adjustment_Date__c FROM Unit_Prices_Costs__r) FROM Customer_Owned_Unit__c WHERE Unit_Type__c = 'STOCK' AND Id IN :couList];
        for(Customer_Owned_Unit__c stockUnit : stockUnitList) {
            stockUnit.Reference_Number__c = 'Unknown';
            stockUnit.How_Acquired__c = 'Add unit';
            if(stockUnit.Referenced_Unit__c != null) {
                stockUnit.How_Acquired__c = 'Purchase';
                stockUnit.Acquired_From__c = stockUnit.Vendor__c;
                stockUnit.Acquisition_Cost__c = stockUnit.Referenced_Unit__r.Total_Cost__c;
                stockUnit.Reference_Number__c = stockUnit.Invoice_Number__c;
            }

            for(Deal_Item__c dealItem : stockUnit.Deals_Units_Junction__r) {
                if(stockUnit.Status__c == 'Sold') {
                    stockUnit.Sale_Number__c = dealItem.Deal__r.CO_Header__r.Name;
                    stockUnit.Sold_To__c = dealItem.Deal__r.CO_Header__r.Customer__c;
                    stockUnit.Sold_Price__c = dealItem.Unit_Price__c;
                }
            }

            for(Deal_Item__c dealItem : stockUnit.Deals_Items__r) {
                if(dealItem.Type__c == 'Trade In') {
                    stockUnit.How_Acquired__c = 'Trade-in';
                    stockUnit.Acquired_From__c = dealItem.Deal__r.CO_Header__r.Customer__c;
                    stockUnit.Acquisition_Cost__c = dealItem.Total_Cost__c * -1;
                    stockUnit.Reference_Number__c = dealItem.Deal__r.CO_Header__r.Name;
                }
            }

            if(stockUnit.Acquisition_Cost__c == null || stockUnit.Acquisition_Cost__c == 0) {
                Decimal acquisitionCost = 0;
                for(Unit_Price_Cost__c upcRec : stockUnit.Unit_Prices_Costs__r) {
                    if(upcRec.Adjustment_Date__c != null && stockUnit.Date_Stocked_In__c == upcRec.Adjustment_Date__c.date()) {
                        acquisitionCost += (upcRec.Total_Cost__c == null) ? 0 : upcRec.Total_Cost__c.setScale(2, RoundingMode.HALF_UP);
                    }
                }
                stockUnit.Acquisition_Cost__c = acquisitionCost;
            }
        }
        
        
        List<Customer_Owned_Unit__c> consignmentUnitList = [SELECT Id, Account__c, Date_Stocked_In__c, Date_Stocked_Out__c, Agreed_Payout__c, Status__c, (SELECT Id, Deal__r.CO_Header__r.Name, Deal__r.CO_Header__r.Customer__c, Unit_Price__c FROM Deals_Units_Junction__r limit 1) FROM Customer_Owned_Unit__c WHERE Consignment__c = true AND Id IN :couList];
        for(Customer_Owned_Unit__c consignmentUnit : consignmentUnitList) {
            consignmentUnit.How_Acquired__c = 'Consignment';
            consignmentUnit.Acquired_From__c = consignmentUnit.Account__c;
            consignmentUnit.Acquisition_Cost__c = consignmentUnit.Agreed_Payout__c;
            consignmentUnit.Date_Stocked_In__c = consignmentUnit.Date_Stocked_Out__c;
            if(consignmentUnit.Status__c == 'Transferred' && !consignmentUnit.Deals_Units_Junction__r.isEmpty()) {
                consignmentUnit.Reference_Number__c = consignmentUnit.Deals_Units_Junction__r[0].Deal__r.CO_Header__r.Name;
                consignmentUnit.Sale_Number__c = consignmentUnit.Deals_Units_Junction__r[0].Deal__r.CO_Header__r.Name;
                consignmentUnit.Sold_To__c = consignmentUnit.Deals_Units_Junction__r[0].Deal__r.CO_Header__r.Customer__c;
                consignmentUnit.Sold_Price__c = consignmentUnit.Deals_Units_Junction__r[0].Unit_Price__c;
            }
        }
        couListToUpdate.addAll(consignmentUnitList);
        couListToUpdate.addAll(stockUnitList);
        CustomerOwnedUnitTriggerHelper.isForceStopTrigger = true;
        DMLUtility.updateSobjectList('Customer_Owned_Unit__c', couListToUpdate);
        CustomerOwnedUnitTriggerHelper.isForceStopTrigger = false;
    }
    
    global override void finishScript(Database.BatchableContext bc) {
    }
}