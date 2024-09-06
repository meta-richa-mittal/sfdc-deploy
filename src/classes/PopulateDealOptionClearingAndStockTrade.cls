global without sharing class PopulateDealOptionClearingAndStockTrade extends PostInstallScriptBaseBatch {
    global PopulateDealOptionClearingAndStockTrade() {
        this.scriptName = 'executePopulateDealOptionClearingAndStockTradeBatch()';
    }

    global override Database.QueryLocator startScript(Database.BatchableContext bc) {
        String strQuery = 'SELECT Id, Invoice_Number__c, Option_Clearing__c, Stocked_Trades__c, Reopen_Invoice_Created_Date__c, (SELECT Id, Actual_Cash_Value__c FROM Deal_Items__r WHERE Is_Stocked_In__c = true) FROM Deal__c ';
        return Database.getQueryLocator(strQuery);
    }
    
    global override void executeScript(Database.BatchableContext bc, List<SObject> sobjectList) {
        List<Deal__c> dealList = (List<Deal__c>) sobjectList;

        Map<Id, List<CO_Line_Item__c>> dealIdToColiMap = new Map<Id, List<CO_Line_Item__c>>();
        for(CO_Line_Item__c coliRec : [SELECT Revenue__c, Deal__c, Actual_Invoice_Date_Time__c, Invoice_Number__c, Invoice_Number__r.Closed_Invoice_Date__c FROM CO_Line_Item__c WHERE Deal__c IN :dealList AND Service_Order_Line_Item__c = null]) {
            if(!dealIdToColiMap.containsKey(coliRec.Deal__c)) {
                dealIdToColiMap.put(coliRec.Deal__c, new List<CO_Line_Item__c>());
            }
            dealIdToColiMap.get(coliRec.Deal__c).add(coliRec);
        }

        Map<Id, List<Service_Order_Header__c>> dealIdToSoMap = new Map<Id, List<Service_Order_Header__c>>();
        for(Service_Order_Header__c soRec : [SELECT Total__c, Deal__c, Actual_Invoice_Date_Time__c, Invoice_Number__c, Invoice_Number__r.Closed_Invoice_Date__c FROM Service_Order_Header__c WHERE Deal__c IN :dealList]) {
            if(!dealIdToSoMap.containsKey(soRec.Deal__c)) {
                dealIdToSoMap.put(soRec.Deal__c, new List<Service_Order_Header__c>());
            }
            dealIdToSoMap.get(soRec.Deal__c).add(soRec);
        }

        for(Deal__c dealRec : dealList) {
            if(dealRec.Invoice_Number__c != null) {
                dealRec.Stocked_Trades__c = 0;
                Decimal optionClearing = 0;
                if(dealIdToColiMap.containsKey(dealRec.Id)) {
                    for(CO_Line_Item__c coliRec : dealIdToColiMap.get(dealRec.Id)) {
                        if(coliRec.Invoice_Number__c == null) {
                            optionClearing += coliRec.Revenue__c != null ? coliRec.Revenue__c.setScale(2, RoundingMode.HALF_UP) : 0;
                        }
                    }
                }

                if(dealIdToSoMap.containsKey(dealRec.Id)) {
                    for(Service_Order_Header__c soRec : dealIdToSoMap.get(dealRec.Id)) {
                        if(soRec.Invoice_Number__c == null) {
                            optionClearing += soRec.Total__c != null ? soRec.Total__c.setScale(2, RoundingMode.HALF_UP) : 0;
                        }
                    }
                }
                dealRec.Option_Clearing__c = optionClearing;
            } else {
                Decimal optionClearing = 0;
                if(dealRec.Reopen_Invoice_Created_Date__c != null) {
                    if(dealIdToColiMap.containsKey(dealRec.Id)) {
                        for(CO_Line_Item__c coliRec : dealIdToColiMap.get(dealRec.Id)) {
                            if(coliRec.Actual_Invoice_Date_Time__c != null) {
                                if(coliRec.Actual_Invoice_Date_Time__c > dealList[0].Reopen_Invoice_Created_Date__c) {
                                    optionClearing -= coliRec.Revenue__c != null ? coliRec.Revenue__c.setScale(2, RoundingMode.HALF_UP) : 0;
                                }
                            } else if(coliRec.Invoice_Number__c != null) {
                                if(coliRec.Invoice_Number__r.Closed_Invoice_Date__c > dealList[0].Reopen_Invoice_Created_Date__c) {
                                    optionClearing -= coliRec.Revenue__c != null ? coliRec.Revenue__c.setScale(2, RoundingMode.HALF_UP) : 0;
                                }
                            }
                        }
                    }
                    
                    if(dealIdToSoMap.containsKey(dealRec.Id)) {
                        for(Service_Order_Header__c soRec : dealIdToSoMap.get(dealRec.Id)) {
                            if(soRec.Actual_Invoice_Date_Time__c != null) {
                                if(soRec.Actual_Invoice_Date_Time__c > dealRec.Reopen_Invoice_Created_Date__c) {
                                    optionClearing -= soRec.Total__c != null ? soRec.Total__c.setScale(2, RoundingMode.HALF_UP) : 0;
                                }
                            } else if(soRec.Invoice_Number__c != null) {
                                if(soRec.Invoice_Number__r.Closed_Invoice_Date__c > dealRec.Reopen_Invoice_Created_Date__c) {
                                    optionClearing -= soRec.Total__c != null ? soRec.Total__c.setScale(2, RoundingMode.HALF_UP) : 0;
                                }
                            }
                        }
                    }
                }
                dealRec.Option_Clearing__c = optionClearing;
                
                Decimal stockTrade = 0;
                for(Deal_Item__c dealItem : dealRec.Deal_Items__r) {
                    stockTrade += dealItem.Actual_Cash_Value__c.setScale(2, RoundingMode.HALF_UP);
                }
                dealRec.Stocked_Trades__c = stockTrade;
            }
        }

        DealTriggerHelper.isForceStopTrigger = true;
        DMLUtility.updateSobjectList('Deal__c', dealList);
        DealTriggerHelper.isForceStopTrigger = false;
    }
    
    global override void finishScript(Database.BatchableContext bc) {}

}