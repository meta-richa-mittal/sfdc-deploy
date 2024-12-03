global without sharing class SalesTaxCodeAndRateCleanupBatch implements Database.Batchable<sObject> {
    public Boolean isTaxRateCleanUp = false;

    global SalesTaxCodeAndRateCleanupBatch(Boolean isTaxRateCleanUp) {
        this.isTaxRateCleanUp = isTaxRateCleanUp;
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        String strQuery; 
        if(this.isTaxRateCleanUp) {
            strQuery = 'SELECT Id, Active__c, (SELECT Id FROM Individual_Taxes__r Limit 1), (SELECT Id FROM Tax_Exemptions__r Limit 1), (SELECT Id FROM Applicable_Taxes__r WHERE Sales_Tax__c != null Limit 1), (SELECT Id FROM Part_Taxes__r Limit 1) FROM Sales_Tax_Item__c WHERE Tax_Type__c = \'Sell\'';
        } else {
            strQuery = 'SELECT Id, '; 
            strQuery += '( SELECT Id FROM Accounts1__r LIMIT 1)';
            strQuery += ', ( SELECT Id FROM Customer_Owned_Units__r LIMIT 1)';
            strQuery += ', ( SELECT Id FROM Fees__r LIMIT 1)';
            strQuery += ', ( SELECT Id FROM Labour_Codes__r LIMIT 1)';
            strQuery += ', ( SELECT Id FROM Parts__r LIMIT 1)';
            strQuery += ', ( SELECT Id FROM Products__r LIMIT 1)';
            strQuery += ', ( SELECT Id FROM Deals_Items__r LIMIT 1)';
            strQuery += ' FROM Sales_Tax__c WHERE Tax_Type__c = \'Sell\'' ;
        }
        return Database.getQueryLocator(strQuery); 
    }

    global void execute(Database.batchableContext bc, List<SObject> sObjectList) {
        if(this.isTaxRateCleanUp) {
            List<Sales_Tax_Item__c> salesTaxItemToDelete = new List<Sales_Tax_Item__c>();
            List<Sales_Tax_Item__c> salesTaxItemToUpdate = new List<Sales_Tax_Item__c>();
            for(Sales_Tax_Item__c salesTaxItem : (List<Sales_Tax_Item__c>) sObjectList) {
                
                if(salesTaxItem.Individual_Taxes__r.isEmpty() && salesTaxItem.Tax_Exemptions__r.isEmpty() && salesTaxItem.Part_Taxes__r.isEmpty()) {
                    if(salesTaxItem.Applicable_Taxes__r.isEmpty()) {
                        salesTaxItemToDelete.add(salesTaxItem);
                    } else {
                        salesTaxItem.Active__c = false;
                        salesTaxItemToUpdate.add(salesTaxItem);
                    }
                }
            }
            DMLUtility.deleteSobjectList('Sales_Tax_Item__c', salesTaxItemToDelete);
            DMLUtility.updateSobjectList('Sales_Tax_Item__c', salesTaxItemToUpdate);
        } else {
            Map<String, List<Applicable_Taxes__c>> salesTaxIdToAppTaxListMap = new Map<String, List<Applicable_Taxes__c>>();
            for(Applicable_Taxes__c appTaxRec : [SELECT Id, Sales_Tax_Item__c, Sales_Tax_Item__r.Active__c, Sales_Tax_Item__r.Rate__c, Sales_Tax__c FROM Applicable_Taxes__c WHERE Sales_Tax__c IN :sObjectList]) {
                if(!salesTaxIdToAppTaxListMap.containsKey(appTaxRec.Sales_Tax__c)) {
                    salesTaxIdToAppTaxListMap.put(appTaxRec.Sales_Tax__c, new List<Applicable_Taxes__c>());
                }
                salesTaxIdToAppTaxListMap.get(appTaxRec.Sales_Tax__c).add(appTaxRec);

            }
            
            List<Sales_Tax__c> salesTaxToDelete = new List<Sales_Tax__c>();
            List<Sales_Tax_Item__c> salesTaxItemToDelete = new List<Sales_Tax_Item__c>();
            List<Applicable_Taxes__c> ApplicableTaxToDelete = new List<Applicable_Taxes__c>();
            List<Sales_Tax__c> salesTaxToUpdate = new List<Sales_Tax__c>();
            Configurations__c config = Configurations__c.getOrgDefaults();
            List<String> defaultTaxSettingList = new List<String>{
                                                                config.Default_Sales_Tax_on_Internal_Service__c,
    															config.Default_Tax_on_Fee__c,
    															config.Default_Tax_on_Labor__c,
    															config.Default_Tax_on_Part__c,
    															config.Default_Tax_on_Unit__c,
    															config.Default_Tax_on_Vendor_Product__c
    														};
            for(Sales_Tax__c salesTaxRec : (List<Sales_Tax__c>) sObjectList) {
                
                if((salesTaxRec.Accounts1__r.isEmpty()
                    && salesTaxRec.Customer_Owned_Units__r.isEmpty()
                    && salesTaxRec.Fees__r.isEmpty()
                    && salesTaxRec.Labour_Codes__r.isEmpty()
                    && salesTaxRec.Parts__r.isEmpty()
                    && salesTaxRec.Products__r.isEmpty())
                    && salesTaxRec.Deals_Items__r.isEmpty()
                    && !defaultTaxSettingList.contains(salesTaxRec.Id)) {
                    if(!salesTaxIdToAppTaxListMap.containsKey(salesTaxRec.Id)) {
                        salesTaxToDelete.add(salesTaxRec);
                    } else {
                        Boolean isAllRateInactive = true;
                        List<Sales_Tax_Item__c> inactiveSalesTaxItems = new List<Sales_Tax_Item__c>();
                        if(salesTaxIdToAppTaxListMap.containsKey(salesTaxRec.Id)) {
                            for(Applicable_Taxes__c appTax : salesTaxIdToAppTaxListMap.get(salesTaxRec.Id)) {
                                if(appTax.Sales_Tax_Item__r.Active__c) {
                                    isAllRateInactive = false;
                                    break;
                                } else {
                                    inactiveSalesTaxItems.add(new Sales_Tax_Item__c(Id = appTax.Sales_Tax_Item__C));
                                }
                            }
                        }
                        if(isAllRateInactive) {
                            salesTaxToDelete.add(salesTaxRec);
                            salesTaxItemToDelete.addAll(inactiveSalesTaxItems);
                            ApplicableTaxToDelete.addAll(salesTaxIdToAppTaxListMap.get(salesTaxRec.Id));
                        }
                    }
			    } else if(salesTaxIdToAppTaxListMap.containsKey(salesTaxRec.Id)) {
                    salesTaxRec.Rate__c = 0;
                    for(Applicable_Taxes__c app : salesTaxIdToAppTaxListMap.get(salesTaxRec.Id)) {
                        salesTaxRec.Rate__c += app.Sales_Tax_Item__r.Rate__c;      
                    }
                    salesTaxToUpdate.add(salesTaxRec);
                }
            }

            DMLUtility.deleteSobjectList('Applicable_Taxes__c', ApplicableTaxToDelete);
            DMLUtility.deleteSobjectList('Sales_Tax_Item__c', salesTaxItemToDelete);
            SalesTaxTriggerHelper.isForceStopTrigger = true;
            DMLUtility.deleteSobjectList('Sales_Tax__c', salesTaxToDelete);
            SalesTaxTriggerHelper.isForceStopTrigger = false;

            DMLUtility.updateSobjectList('Sales_Tax__c', salesTaxToUpdate);
        }
    }

    global void finish(Database.batchableContext bc) {
        if(this.isTaxRateCleanUp) {
            this.isTaxRateCleanUp = false;
            Database.executeBatch(new SalesTaxCodeAndRateCleanupBatch(this.isTaxRateCleanUp), 50);
        }
    }
}