public without sharing class IntegrationSyncFlagService {
    
    public static String activeIntegrationName = IntegrationServiceFactory.getActiveAccountingIntegrationName();
    private static Map<String, Integration_Entity__mdt> integrationEntityNameToRecMap;
    private static List<String> categoryFieldListToSync = new List<String> {
        'Active__c', 'Name', 'Type__c', 'Description__c', 'Income_GL__c', 'Inventory_GL__c', 'COGS_GL__c'
    };

    private static Set<String> preventReinitiatingAccountingSyncSetForUnit = new Set<String> {
        IntegrationUtility.STOCK_UNIT_CATEGORY, 
        IntegrationUtility.UNIT_INVOICE_JE, 
        IntegrationUtility.UNIT_NITC_JE, 
        IntegrationUtility.Unit_Consignment
    };

    private static Map<String, String> entityNameToStatusToSyncMap = new Map<String, String>{
                                                                        IntegrationUtility.VO_INVOICE => IntegrationUtility.INVOICED,
                                                                        IntegrationUtility.VO_RETURN => IntegrationUtility.CREDITED,
                                                                        IntegrationUtility.VENDOR_RECEIVING => IntegrationUtility.STOCKED
                                                                    };
                                                                    
    private static Map<String, String> entityNameToRelatedEntityMap = new Map<String, String>{
                                                                        IntegrationUtility.INVOICE => IntegrationUtility.CO_INVOICE_JE,
                                                                        IntegrationUtility.UNIT_INVOICE => IntegrationUtility.UNIT_INVOICE_JE
                                                                    };
    
    public static void setUpdatedFieldsForSparse(List<BaseIntegrationService> baseIntegrationServiceList, List<Sobject> newList, Map<Id, Sobject> oldMap) {
        new IntegrationUtility().getIntegrationEntityMetadata(baseIntegrationServiceList, IntegrationUtility.ITEM_CATEGORY);
        
        for(Sobject rec : newList) {
            String changedFieldsString = '';
            Sobject oldRec = oldMap.get(rec.Id);
            if(rec.get(baseIntegrationServiceList[0].integrationEntityNameToRecMap.get(IntegrationUtility.ITEM_CATEGORY).Integration_Id_API_Name__c) != null) {
                rec = updateSparseFieldForTheRecord(rec, oldRec, new Set<String>{'QB_Updated_Fields__c'}, categoryFieldListToSync);
            }
        }
    }
    
    private static Sobject updateSparseFieldForTheRecord(SObject newRec, SObject oldRec, Set<String> updatedFieldsAPINameSet, List<String> fieldsToSyncList) {
        String changedFieldsString = '';
        for(String fieldName : fieldsToSyncList) {
            if(newRec.get(fieldName) != oldRec.get(fieldName)) {
                if(newRec.getsObjectType() == Account.sObjectType){
                    Account newRecord = (Account)newRec;
                    Account oldRecord = (Account)oldRec;
                    if(!oldRecord.Is_Vendor__c && newRecord.Is_Vendor__c) {
                        newRecord.Vendor_QB_Updated_Fields__c = null;
                    } else {
                        changedFieldsString += fieldName + ','; 
                    }
                } else {
                    changedFieldsString += fieldName + ','; 
                }   
                 
            }
        }
        for(String updatedFieldsAPIName : updatedFieldsAPINameSet) {
            if(String.isNotBlank((String)newRec.get(updatedFieldsAPIName))) {
                newRec.put(updatedFieldsAPIName, newRec.get(updatedFieldsAPIName) + changedFieldsString);
            } else {
                newRec.put(updatedFieldsAPIName, changedFieldsString);
            }
        }
        return newRec;
    }
    
    public static void managePartFIFOBucketSyncFlag( List<Part_FIFO_Bucket__c> newList) {
        if(!isIntegrationActive()) return;
        integrationEntityNameToRecMap = IntegrationUtility.getIntegrationEntityMetadata(new List<String>{IntegrationUtility.PART_FIFO}, activeIntegrationName);
                                                                        
        for(Part_FIFO_Bucket__c partFIFOBucketRec : newList) {
            if((partFIFOBucketRec.Is_FIFO_Bucket__c && partFIFOBucketRec.Vendor_Receiving_Header__c == null && partFIFOBucketRec.Customer_Return__c == null && 
                partFIFOBucketRec.Count_Session_Line_Item__c == null && partFIFOBucketRec.Source_Name__c != QBUtil.OVERSOLD && 
                partFIFOBucketRec.Cost__c != null && partFIFOBucketRec.Cost__c != 0) || (!partFIFOBucketRec.Is_FIFO_Bucket__c && 
                partFIFOBucketRec.Source_Name__c == LogService.REOPEN_INVOICE && partFIFOBucketRec.Cost__c != partFIFOBucketRec.VRCost__c)) {
                    partFIFOBucketRec.put(integrationEntityNameToRecMap.get(IntegrationUtility.PART_FIFO).Sync_Flag_API_Name__c, true);
            }
        }
    }
    
    public static void managePartFIFOBucketLISyncFlag(List<Part_FIFO_Bucket_Activity_Line_Item__c> fifoActivityLIList) {
        if(!isIntegrationActive()) return;
        integrationEntityNameToRecMap = IntegrationUtility.getIntegrationEntityMetadata(new List<String>{IntegrationUtility.PART_FIFO_BUCKET_ACTIVITY_LINE_ITEM}, activeIntegrationName);
        Set<Id> fifoBucketIds = new Set<Id>();
        for(Part_FIFO_Bucket_Activity_Line_Item__c partFIFOBucketActivityLIRec : fifoActivityLIList) {
            fifoBucketIds.add(partFIFOBucketActivityLIRec.Part_FIFO_Bucket__c);
        }
        if(fifoBucketIds.size() > 0) {
            Map<Id, Part_FIFO_Bucket__c> fifoBucketIdToRecMap = 
                                new Map<Id, Part_FIFO_Bucket__c>([SELECT Id, Cost__c FROM Part_FIFO_Bucket__c WHERE Id IN :fifoBucketIds AND Is_FIFO_Bucket__c = true]);
            
            for(Part_FIFO_Bucket_Activity_Line_Item__c partFIFOBucketActivityLIRec : fifoActivityLIList) {
                if(fifoBucketIdToRecMap.containsKey(partFIFOBucketActivityLIRec.Part_FIFO_Bucket__c) && partFIFOBucketActivityLIRec.CO_Invoice_Header__c == null && 
        			partFIFOBucketActivityLIRec.Count_Session_Line_Item__c == null && 
                    fifoBucketIdToRecMap.get(partFIFOBucketActivityLIRec.Part_FIFO_Bucket__c).Cost__c != null && fifoBucketIdToRecMap.get(partFIFOBucketActivityLIRec.Part_FIFO_Bucket__c).Cost__c != 0) {
                    partFIFOBucketActivityLIRec.put(integrationEntityNameToRecMap.get(IntegrationUtility.PART_FIFO_BUCKET_ACTIVITY_LINE_ITEM).Sync_Flag_API_Name__c, true);
                }
            }
        }
    }
    

    public static void manageStockUnitCategorySyncFlag( List<Customer_Owned_Unit__c> newList, Map<Id, Customer_Owned_Unit__c> oldMap) {
        if(!isIntegrationActive()) return;
        integrationEntityNameToRecMap = IntegrationUtility.getIntegrationEntityMetadata(new List<String>{IntegrationUtility.STOCK_UNIT_CATEGORY}, activeIntegrationName);
       
        Set<Id> categoryIdSet = new Set<Id>();
        for(Customer_Owned_Unit__c unitRec : newList) {
            Id oldCategory = oldMap.get(unitRec.Id).Category__c;
            if(unitRec.Unit_Type__c == 'STOCK' && unitRec.Status__c != 'Sold' && oldCategory != null && oldCategory != unitRec.Category__c) {
                categoryIdSet.add(oldCategory);
                categoryIdSet.add(unitRec.Category__c);
            }
        }
        Map<Id, Category__c> categoryIdToCategoryRecordMap;
        if(categoryIdSet.size() > 0) {
            categoryIdToCategoryRecordMap = new Map<Id, Category__c>([SELECT Id, Inventory_GL__c FROM Category__c WHERE Id IN :categoryIdSet]);
            for(Customer_Owned_Unit__c unitRec : newList) {
                Id oldCategory = oldMap.get(unitRec.Id).Category__c;
                if(unitRec.Unit_Type__c == 'STOCK' && unitRec.Status__c != 'Sold' && unitRec.Total_Cost__c != null && unitRec.Total_Cost__c != 0 && oldCategory != null && oldCategory != unitRec.Category__c && 
                    categoryIdToCategoryRecordMap.get(oldCategory).Inventory_GL__c != categoryIdToCategoryRecordMap.get(unitRec.Category__c).Inventory_GL__c) {
                        unitRec.put(integrationEntityNameToRecMap.get(IntegrationUtility.STOCK_UNIT_CATEGORY).Sync_Flag_API_Name__c, true);
                }
            }
        }
    }
    

    public static void managePartCategorySyncFlag(List<Part__c> partNewList, Map<Id, Part__c> oldMap) {
        if(!isIntegrationActive()) return;
        integrationEntityNameToRecMap = IntegrationUtility.getIntegrationEntityMetadata(new List<String>{IntegrationUtility.PART_CATEGORY}, activeIntegrationName);

        Set<Id> categoryIdSet = new Set<Id>();
        for(Part__c partRec : partNewList) {
            Id oldCategory = oldMap.get(partRec.Id).Category__c;
            if(oldCategory != null && oldCategory != partRec.Category__c) {
                categoryIdSet.add(oldCategory);
                categoryIdSet.add(partRec.Category__c);
            }
        }
        
        Map<Id, Category__c> categoryIdToCategoryRecordMap;
        if(categoryIdSet.size() > 0) {
            categoryIdToCategoryRecordMap = new Map<Id, Category__c>([SELECT Id, Inventory_GL__c FROM Category__c WHERE Id IN :categoryIdSet]);
            for(Part__c partRec : partNewList) {
                Id oldCategory = oldMap.get(partRec.Id).Category__c;
                if(partRec.Total_Cost__c != null && partRec.Total_Cost__c != 0 && oldCategory != null && oldCategory != partRec.Category__c && 
                    categoryIdToCategoryRecordMap.get(oldCategory).Inventory_GL__c != categoryIdToCategoryRecordMap.get(partRec.Category__c).Inventory_GL__c) {
                        partRec.put(integrationEntityNameToRecMap.get(IntegrationUtility.PART_CATEGORY).Sync_Flag_API_Name__c, true);
                }
            }
        }
    }

    public static void manageCODepositSyncFlag(List<CO_Deposit__c> newList) {
        if(!isIntegrationActive()) return;
        integrationEntityNameToRecMap = IntegrationUtility.getIntegrationEntityMetadata(new List<String>{IntegrationUtility.CO_DEPOSIT}, activeIntegrationName);
        for(CO_Deposit__c coDepositRec : newList) {
            if(coDepositRec.Payment_Method__c != AccountingUtil.INVOICE && coDepositRec.Payment_Method__c != Constants.AR_CREDIT && !coDepositRec.Is_Reversal_Of_Payment__c) {
                coDepositRec.put(integrationEntityNameToRecMap.get(IntegrationUtility.CO_DEPOSIT).Sync_Flag_API_Name__c, true);
            }
        }
    }

    public static void manageCOInvoicePaymentSyncFlag(List<CO_Invoice_Payment__c> newList) {
        if(!isIntegrationActive()) return;
        integrationEntityNameToRecMap = IntegrationUtility.getIntegrationEntityMetadata(new List<String>{IntegrationUtility.CO_INVOICE_PAYMENT}, activeIntegrationName);
        for(CO_Invoice_Payment__c coInvoicePaymentRec : newList) {
            if((coInvoicePaymentRec.Payment_Method__c != QBUtil.CHARGE_ACCOUNT && coInvoicePaymentRec.Payment_Method__c != AccountingUtil.USE_DEPOSIT && 
            	coInvoicePaymentRec.Payment_Method__c != AccountingUtil.USE_DEAL_DEPOSIT && coInvoicePaymentRec.Payment_Method__c != Constants.AR_CREDIT) || ((coInvoicePaymentRec.Payment_Method__c == AccountingUtil.USE_DEAL_DEPOSIT || coInvoicePaymentRec.Payment_Method__c == AccountingUtil.USE_DEPOSIT) && General_Configurations__c.getOrgDefaults().Use_new_payment_accounting__c)) {
                coInvoicePaymentRec.put(integrationEntityNameToRecMap.get(IntegrationUtility.CO_INVOICE_PAYMENT).Sync_Flag_API_Name__c, true);
            }
        }
    }
    
    public static void manageCOInvoiceSyncFlag(List<CO_Invoice_Header__c> newList, Map<Id, CO_Invoice_Header__c> oldMap) {
        if(!isIntegrationActive()) return;
        integrationEntityNameToRecMap = IntegrationUtility.getIntegrationEntityMetadata(new List<String>{IntegrationUtility.INVOICE, IntegrationUtility.CO_INVOICE_JE, IntegrationUtility.INVOICE_PAYMENT}, activeIntegrationName);
        for(CO_Invoice_Header__c coInvoiceRec : newList) {
            if(checkForExtraConditionsForCOInvoice(coInvoiceRec, oldMap.get(coInvoiceRec.Id))) {
                coInvoiceRec.put(integrationEntityNameToRecMap.get(IntegrationUtility.INVOICE).Sync_Flag_API_Name__c, true);
            }
            if(checkForExtraConditionsForCOInvoiceJE(coInvoiceRec, oldMap.get(coInvoiceRec.Id))) {
                coInvoiceRec.put(integrationEntityNameToRecMap.get(IntegrationUtility.CO_INVOICE_JE).Sync_Flag_API_Name__c, true);
            }
            if(checkForExtraConditionsForCOInvoicePayments(coInvoiceRec, oldMap.get(coInvoiceRec.Id))) {
                coInvoiceRec.put(integrationEntityNameToRecMap.get(IntegrationUtility.INVOICE_PAYMENT).Sync_Flag_API_Name__c, true);
            }
        }
    }

    public static void manageDealItemSyncFlag( List<Deal_Item__c> newList, Map<Id, Deal_Item__c> oldMap) {
        if(!isIntegrationActive()) return;
        integrationEntityNameToRecMap = IntegrationUtility.getIntegrationEntityMetadata(new List<String>{IntegrationUtility.STOCK_TRADE_IN}, activeIntegrationName);

        for(Deal_Item__c dealItemRec : newList) {
            if(dealItemRec.Type__c == QBUtil.DEAL_ITEM_TYPE_TRADE_IN && dealItemRec.Is_Stocked_In__c && !oldMap.get(dealItemRec.Id).Is_Stocked_In__c) {
                dealItemRec.put(integrationEntityNameToRecMap.get(IntegrationUtility.STOCK_TRADE_IN).Sync_Flag_API_Name__c, true);
            }
        }
    }
    
    public static void manageVOInvoiceSyncFlag(List<Vendor_Invoicing_Header__c> newList, Map<Id, Vendor_Invoicing_Header__c> oldMap) {
        if(!isIntegrationActive()) return;
        if(newList.size() > 0) {
            integrationEntityNameToRecMap = IntegrationUtility.getIntegrationEntityMetadata(new List<String>{IntegrationUtility.VO_INVOICE, IntegrationUtility.VO_INVOICE_VARIANCE_JE}, activeIntegrationName);
        }
        Set<Id> voInvoiceIdSet = new Set<Id>();
        for(Vendor_Invoicing_Header__c voInvoiceRec : newList) {
            if(checkForExtraConditionsForVOInvoice(voInvoiceRec, oldMap.get(voInvoiceRec.Id))) {
                voInvoiceRec.put(integrationEntityNameToRecMap.get(IntegrationUtility.VO_INVOICE).Sync_Flag_API_Name__c, true);
                voInvoiceIdSet.add(voInvoiceRec.Id);
            }
        }
        if(!voInvoiceIdSet.isEmpty()) {
            Map<Id, List<Vendor_Invoicing_Group__c>> viToVIGroupListMap = new Map<Id, List<Vendor_Invoicing_Group__c>>();
            for(Vendor_Invoicing_Group__c vigRec : [SELECT Id, Vendor_Invoicing_Header__c, Applied_Charge__c, VI_Cost__c, Vendor_Receiving_Group__r.Recieved__c, VI_Discount__c, Vendor_Receiving_Group__r.Cost__c, Vendor_Receiving_Group__r.Discount__c, Vendor_Receiving_Group__r.Vendor_Receiving_Header__r.Finalized_VR_Conversion_Rate__c FROM Vendor_Invoicing_Group__c WHERE Vendor_Invoicing_Header__c IN :newList]) {
                if(!viToVIGroupListMap.containsKey(vigRec.Vendor_Invoicing_Header__c)) {
                    viToVIGroupListMap.put(vigRec.Vendor_Invoicing_Header__c, new List<Vendor_Invoicing_Group__c>{});
                }
                viToVIGroupListMap.get(vigRec.Vendor_Invoicing_Header__c).add(vigRec);
            }   
            for(Vendor_Invoicing_Header__c voInvoiceRec : newList) {
                if(viToVIGroupListMap.containsKey(voInvoiceRec.Id) && viToVIGroupListMap.get(voInvoiceRec.Id).size() > 0 && hasVarianceOnVI(viToVIGroupListMap.get(voInvoiceRec.Id), voInvoiceRec)) {
                    voInvoiceRec.put(integrationEntityNameToRecMap.get(IntegrationUtility.VO_INVOICE_VARIANCE_JE).Sync_Flag_API_Name__c, true);
                }
            }
        }
    }
    
    public static void manageVOReturnSyncFlag(List<Return_CR_Header__c> newList, Map<Id, Return_CR_Header__c> oldMap) {
        if(!isIntegrationActive()) return;
        integrationEntityNameToRecMap = IntegrationUtility.getIntegrationEntityMetadata(new List<String>{IntegrationUtility.VO_RETURN, IntegrationUtility.VO_RETURN_VARIANCE_JE}, activeIntegrationName);
        
        Map<Id, List<Return_CR_Line_Item__c>> rcrToRCRLIListMap = new Map<Id, List<Return_CR_Line_Item__c>>();
        for(Return_CR_Line_Item__c rcrliRec : [SELECT Id, Return_CR_Header__c, Return_Cost__c, Credit_Cost__c, Return_Qty__c, Return_CR_Header__r.Vendor__r.Is_Foreign_Vendor__c, (SELECT Inventory_Cost__c FROM Return_VO_Line_Items__r) FROM Return_CR_Line_Item__c WHERE Return_CR_Header__c IN :newList]) {
            if(!rcrToRCRLIListMap.containsKey(rcrliRec.Return_CR_Header__c)) {
                rcrToRCRLIListMap.put(rcrliRec.Return_CR_Header__c, new List<Return_CR_Line_Item__c>{});
            }
            rcrToRCRLIListMap.get(rcrliRec.Return_CR_Header__c).add(rcrliRec);
        }  
        for(Return_CR_Header__c returnCRHeader: newList) {
            if(returnCRHeader.Status__c == 'Credited' && returnCRHeader.Status__c != oldMap.get(returnCRHeader.Id).Status__c) {
                returnCRHeader.put(integrationEntityNameToRecMap.get(IntegrationUtility.VO_RETURN).Sync_Flag_API_Name__c, true);
                if(rcrToRCRLIListMap.containsKey(returnCRHeader.Id) && rcrToRCRLIListMap.get(returnCRHeader.Id).size() > 0 && hasVarianceOnRCR(rcrToRCRLIListMap.get(returnCRHeader.Id), returnCRHeader)) {
                    returnCRHeader.put(integrationEntityNameToRecMap.get(IntegrationUtility.VO_RETURN_VARIANCE_JE).Sync_Flag_API_Name__c, true);
                }
            }
        }
    }
    
    private static Boolean checkForExtraConditionsForVOInvoice(Vendor_Invoicing_Header__c newRec, Vendor_Invoicing_Header__c oldRec) {
        return (newRec.Status__c != oldRec.Status__c && newRec.Status__c == IntegrationUtility.INVOICED);
    }

    public static void manageAccountSyncFlag(List<Account> accNewList, Map<Id, Account> accOldMap) {
        if(!isIntegrationActive()) return;
        if(accNewList.size() > 0) {
            integrationEntityNameToRecMap = IntegrationUtility.getIntegrationEntityMetadata(new List<String>{IntegrationUtility.CUSTOMER, IntegrationUtility.VENDOR}, activeIntegrationName);
        }
        for(Account accRec : accNewList) {
            Account oldRec = accOldMap.get(accRec.Id);
            String changedFieldsString = '';
            if(accRec.FirstName__c != oldRec.FirstName__c || accRec.LastName__c != oldRec.LastName__c || accRec.Type__c != oldRec.Type__c || 
                accRec.Name != oldRec.Name || accRec.Customer_Number__c != oldRec.Customer_Number__c || accRec.Active__c != oldRec.Active__c ||
                accRec.Home_Number__c != oldRec.Home_Number__c || accRec.Mobile__c != oldRec.Mobile__c || accRec.Work_Number__c != oldRec.Work_Number__c ||
                accRec.Email__c != oldRec.Email__c || accRec.Other_Email__c != oldRec.Other_Email__c || accRec.Work_Email__c != oldRec.Work_Email__c || 
                accRec.BillingStreet != oldRec.BillingStreet || accRec.BillingCity != oldRec.BillingCity || accRec.BillingState != oldRec.BillingState ||
                accRec.BillingCountry != oldRec.BillingCountry || accRec.BillingPostalCode != oldRec.BillingPostalCode ||
                accRec.ShippingStreet != oldRec.ShippingStreet || accRec.ShippingCity != oldRec.ShippingCity || accRec.ShippingState != oldRec.ShippingState ||
                accRec.ShippingCountry != oldRec.ShippingCountry || accRec.ShippingPostalCode != oldRec.ShippingPostalCode ||
                accRec.Vendor_Code__c != oldRec.Vendor_Code__c || accRec.Is_Vendor__c != oldRec.Is_Vendor__c || 
                accRec.Claims_for_Service_Work__c != oldRec.Claims_for_Service_Work__c  || 
                accRec.Website != oldRec.Website  || 
                accRec.Preferred_Email__c != oldRec.Preferred_Email__c || 
                accRec.Vendor_Tax_Id__c != oldRec.Vendor_Tax_Id__c ||
                accRec.AccountNumber != oldRec.AccountNumber ||
                accRec.Vendor_Number__c != oldRec.Vendor_Number__c ) {
                    
                if(checkForExtraConditionsForCustomer(accRec)) {
                    accRec.put(integrationEntityNameToRecMap.get(IntegrationUtility.CUSTOMER).Sync_Flag_API_Name__c, true);
                } 
                if(checkForExtraConditionsForVendor(accRec)) {
                   accRec.put(integrationEntityNameToRecMap.get(IntegrationUtility.VENDOR).Sync_Flag_API_Name__c, true);
                } 
            }
            if((accRec.Is_Customer__c || (accRec.Is_Vendor__c && accRec.Claims_for_Service_Work__c)) &&
             accRec.get(integrationEntityNameToRecMap.get(IntegrationUtility.CUSTOMER).Integration_Id_API_Name__c) != null) {
                    accRec = (Account) updateSparseFieldForTheRecord(accRec, oldRec, new Set<String>{'QB_Updated_Fields__c', 'Vendor_QB_Updated_Fields__c'}, customerFieldListToSync);
            } else if(accRec.Is_Vendor__c && accRec.get(integrationEntityNameToRecMap.get(IntegrationUtility.VENDOR).Integration_Id_API_Name__c) != null) {
                accRec = (Account) updateSparseFieldForTheRecord(accRec, oldRec, new Set<String>{'QB_Updated_Fields__c', 'Vendor_QB_Updated_Fields__c'}, customerFieldListToSync);
            }
        }
    }
    
     public static void manageStoreCreditSyncFlag(List<Store_Credit__c> newList) {
        if(!isIntegrationActive()) return;
        integrationEntityNameToRecMap = IntegrationUtility.getIntegrationEntityMetadata(new List<String>{IntegrationUtility.STORE_CREDIT}, activeIntegrationName);
        
         for(Store_Credit__c storeCreditRec : newList) {
            if(storeCreditRec.CO_Invoice_Header__c == null && storeCreditRec.CO_Header__c == null) {
                storeCreditRec.put(integrationEntityNameToRecMap.get(IntegrationUtility.STORE_CREDIT).Sync_Flag_API_Name__c, true);
            }
        }
                                                                        
    }
    
    public static void manageAdjustmentSyncFlag(List<Unit_Price_Cost__c> newList) {
        if(!isIntegrationActive()) return;
        integrationEntityNameToRecMap = IntegrationUtility.getIntegrationEntityMetadata(new List<String>{IntegrationUtility.UNIT_PRICE_COST}, activeIntegrationName);
            for(Unit_Price_Cost__c upcRec : newList) {
            if(upcRec.Ref_No__c != null && upcRec.Ref_No__c.startsWith('UA-') && upcRec.Unit_Type__c == 'STOCK' &&
                upcRec.Total_Cost__c != null && upcRec.Total_Cost__c != 0 && upcRec.Type__c != 'Dealer') {
                upcRec.put(integrationEntityNameToRecMap.get(IntegrationUtility.UNIT_PRICE_COST).Sync_Flag_API_Name__c, true);
            }
        }
    }

    public static void manageCategorySyncFlag(List<Category__c> categoryNewList, Map<Id, Category__c> oldMap) {
        if(!isIntegrationActive()) return;
        integrationEntityNameToRecMap = IntegrationUtility.getIntegrationEntityMetadata(new List<String>{IntegrationUtility.ITEM_CATEGORY}, activeIntegrationName);
        Category__c oldRec = new Category__c(); 
        Boolean isUpdateTrigger = false;
        if(oldMap != null) isUpdateTrigger = true;

        for(Category__c catRec : categoryNewList) {
            if(isUpdateTrigger) oldRec = oldMap.get(catRec.Id);

            if(!isUpdateTrigger && catRec.Active__c && catRec.Name != null && catRec.Type__c != null && catRec.Description__c != null && 
                (catRec.Income_GL__c != null || catRec.Inventory_GL__c != null || catRec.COGS_GL__c != null)) {
                catRec.put(integrationEntityNameToRecMap.get(IntegrationUtility.ITEM_CATEGORY).Sync_Flag_API_Name__c, true);
            } else if(isUpdateTrigger && catRec.Active__c && 
                    (catRec.Name != oldRec.Name || catRec.Type__c != oldRec.Type__c || catRec.Description__c != oldRec.Description__c || 
                     catRec.Income_GL__c != oldRec.Income_GL__c || catRec.Inventory_GL__c != oldRec.Inventory_GL__c || 
                     catRec.COGS_GL__c != oldRec.COGS_GL__c || catRec.Active__c != oldRec.Active__c)) {
                catRec.put(integrationEntityNameToRecMap.get(IntegrationUtility.ITEM_CATEGORY).Sync_Flag_API_Name__c, true);
            }

            if(isUpdateTrigger && catRec.AccountingId__c != null) {
            	catRec = (Category__c) pushUpdatedFieldsForSparseUpdate(catRec, oldRec, new Set<String>{'QB_Updated_Fields__c'}, categoryFieldListToSync);
        	}
        }
    }
    
    public static SObject pushUpdatedFieldsForSparseUpdate(SObject updatedRec, SObject oldRec, Set<String> updatedFieldsAPINameSet, List<String> fieldsToSyncList) {
        String changedFieldsString = '';
        for(String fieldName : fieldsToSyncList) {
            if(updatedRec.get(fieldName) != oldRec.get(fieldName)) {
                changedFieldsString += fieldName + ',';
            }
        }
        for(String updatedFieldsAPIName : updatedFieldsAPINameSet) {
            if(String.isNotBlank((String)updatedRec.get(updatedFieldsAPIName))) {
                updatedRec.put(updatedFieldsAPIName,  updatedRec.get(updatedFieldsAPIName)+changedFieldsString);
            } else {
                updatedRec.put(updatedFieldsAPIName, changedFieldsString);
            }
        }                                                                       
        return updatedRec;
    }
    
    public static void manageVendorReceivingSyncFlag( List<Vendor_Receiving_Header__c> receivingNewList,Map<Id, Vendor_Receiving_Header__c> receivingOldMap) {
        if(!isIntegrationActive()) return;
        integrationEntityNameToRecMap = IntegrationUtility.getIntegrationEntityMetadata(new List<String>{IntegrationUtility.VENDOR_RECEIVING}, activeIntegrationName);
        for(Vendor_Receiving_Header__c vendorReceivingRec : receivingNewList) {
            if(vendorReceivingRec.Receiving_Total__c != null && vendorReceivingRec.Receiving_Total__c != 0 && AccountingUtil.isSyncVRToAccounting(vendorReceivingRec, receivingOldMap.get(vendorReceivingRec.Id)))  {
                vendorReceivingRec.put(integrationEntityNameToRecMap.get(IntegrationUtility.VENDOR_RECEIVING).Sync_Flag_API_Name__c, true);
            }
        }
    }
    // need to check
    public static void manageLienPayoutSyncFlag(List<Deal__c> newList, Map<Id, Deal__c> oldMap) {
        if(!isIntegrationActive()) return;
        integrationEntityNameToRecMap = IntegrationUtility.getIntegrationEntityMetadata(new List<String>{IntegrationUtility.LIEN_PAYOUT}, activeIntegrationName);
        Set<Id> dealIdSet = new Set<Id>();
        for(Deal__c dealRec : newList) {
            if(dealRec.Status__c != oldMap.get(dealRec.Id).Status__c && dealRec.Status__c == Constants.DEAL_STATUS_INVOICED) {
                dealIdSet.add(dealRec.Id);
            }
        }
        if(dealIdSet.size() == 0) {
            return;
        }
        
        if(!AccessControl.ifObjectFieldIsAccessible('Deal_Item__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<Deal_Item__c> dealItemList = [SELECT Id FROM Deal_Item__c WHERE Type__c =: Constants.DEAL_ITEM_TYPE_TRADE_IN AND Lien_Payout__c > 0 AND Deal__c IN: dealIdSet];
        for(Deal_Item__c dealItemRec : dealItemList) {
            dealItemRec.put(integrationEntityNameToRecMap.get(IntegrationUtility.LIEN_PAYOUT).Sync_Flag_API_Name__c, true);
        }
        
        if(!AccessControl.ifObjectFieldIsUpdateable('Deal_Item__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
        BPScriptUtility.disbaleTrigger('DealItemTrigger');
        update dealItemList;
        BPScriptUtility.enableTrigger('DealItemTrigger');
        //system.assert(false, dealItemList);
    }
    public static void manageUnitSyncFlag(List<Customer_Owned_Unit__c> newList) {
        if(!isIntegrationActive()) return;
        integrationEntityNameToRecMap = IntegrationUtility.getIntegrationEntityMetadata(new List<String>{IntegrationUtility.UNIT_INVOICE, IntegrationUtility.UNIT_INVOICE_JE}, activeIntegrationName);
        Set<Id> orderedUnitIdSet = new Set<Id>();
        for(Customer_Owned_Unit__c couRec : newList) {
            if(couRec.Unit_Type__c == 'STOCK' && couRec.Referenced_Unit__c != null) {
                orderedUnitIdSet.add(couRec.Referenced_Unit__c);
            }
        }
        if(orderedUnitIdSet.size() > 0) {
            Map<Id, Customer_Owned_Unit__c> orderedUnitIdToOrderedUnitRecMap = 
                new Map<Id, Customer_Owned_Unit__c>([SELECT Unit_Type__c, Status__c, Total_Cost__c From Customer_Owned_Unit__c WHERE Id IN: orderedUnitIdSet
                					AND Total_Cost__c != null]);
            for(Customer_Owned_Unit__c couRec : newList) {
                if(orderedUnitIdToOrderedUnitRecMap.containsKey(couRec.Referenced_Unit__c)) {
                    Customer_Owned_Unit__c orderedUnit = orderedUnitIdToOrderedUnitRecMap.get(couRec.Referenced_Unit__c);
                    if(orderedUnit.Unit_Type__c == 'ORDU' && orderedUnit.Status__c == 'Received') {
                    	if(orderedUnit.Total_Cost__c != null && orderedUnit.Total_Cost__c != 0) {
                    		couRec.put(integrationEntityNameToRecMap.get(IntegrationUtility.UNIT_INVOICE).Sync_Flag_API_Name__c, true);
                    	}
                    }
                }
            }
            
        }
    }
    
    public static void manageUnitInvoiceJESyncFlag(List<Customer_Owned_Unit__c> newList) {
        if(!isIntegrationActive()) return;
        integrationEntityNameToRecMap = IntegrationUtility.getIntegrationEntityMetadata(new List<String>{IntegrationUtility.UNIT_INVOICE_JE}, activeIntegrationName);
        Set<Id> orderedUnitIdSet = new Set<Id>();
        for(Customer_Owned_Unit__c couRec : newList) {
            if(couRec.Unit_Type__c == 'STOCK' && couRec.Referenced_Unit__c != null) {
                orderedUnitIdSet.add(couRec.Referenced_Unit__c);
            }
        }
        if(orderedUnitIdSet.size() > 0) {
            Map<Id, Customer_Owned_Unit__c> orderedUnitIdToOrderedUnitRecMap = 
                new Map<Id, Customer_Owned_Unit__c>([SELECT Unit_Type__c, Status__c, Total_Cost__c From Customer_Owned_Unit__c WHERE Id IN: orderedUnitIdSet
                					AND Total_Cost__c != null]);
            for(Customer_Owned_Unit__c couRec : newList) {
                if(orderedUnitIdToOrderedUnitRecMap.containsKey(couRec.Referenced_Unit__c)) {
                    Customer_Owned_Unit__c orderedUnit = orderedUnitIdToOrderedUnitRecMap.get(couRec.Referenced_Unit__c);
                    if(orderedUnit.Unit_Type__c == 'ORDU' && orderedUnit.Status__c == 'Received') {
                    	if(GeneralConfiguration.getAccrueTradeTaxUntilUnitSold() && couRec.Purchase_Tax_Credit__c != null && couRec.Purchase_Tax_Credit__c != 0) {
                    		couRec.put(integrationEntityNameToRecMap.get(IntegrationUtility.UNIT_INVOICE_JE).Sync_Flag_API_Name__c, true);
                    	}
                    }
                }
            }
            
        }
    }
    
    public static void manageARPaymentSyncFlag(List<AR_Payment__c> arPaymentNewList) {
        if(!isIntegrationActive()) return;
        integrationEntityNameToRecMap = IntegrationUtility.getIntegrationEntityMetadata(new List<String>{IntegrationUtility.AR_PAYMENT}, activeIntegrationName);
        for(AR_Payment__c arPaymentRec : arPaymentNewList) {
        	if(arPaymentRec.Amount_Paid__c != null && arPaymentRec.Amount_Paid__c != 0) {
            	arPaymentRec.put(integrationEntityNameToRecMap.get(IntegrationUtility.AR_PAYMENT).Sync_Flag_API_Name__c, true);
        	}
        }
    }

    public static void manageARPaymentSyncFlagForQB(List<Payment_on_Account__c> newList, Map<Id, Payment_on_Account__c> oldMap) {
        if(!isIntegrationActive()) return;
        for(Payment_on_Account__c paymentOnAccountRec : newList) {
            if(activeIntegrationName == 'QuickBooks Online' && paymentOnAccountRec.Total_Payment__c != null && paymentOnAccountRec.Total_Payment__c > 0 
                && paymentOnAccountRec.Total_Payment__c != oldMap.get(paymentOnAccountRec.Id).Total_Payment__c) {
                    integrationEntityNameToRecMap = IntegrationUtility.getIntegrationEntityMetadata(new List<String>{IntegrationUtility.QB_AR_PAYMENT}, activeIntegrationName);
                    paymentOnAccountRec.put(integrationEntityNameToRecMap.get(IntegrationUtility.QB_AR_PAYMENT).Sync_Flag_API_Name__c, true);
            }
        }
    }
    
    public static void manageHoursLoggedSyncFlag(List<Hours_Logged__c> newList, Map<Id, Hours_Logged__c> oldMap) {
        if(!isIntegrationActive()) return;
        integrationEntityNameToRecMap = IntegrationUtility.getIntegrationEntityMetadata(new List<String>{IntegrationUtility.HOURS_LOGGED}, activeIntegrationName);
        for(Hours_Logged__c hoursLoggedRec : newList) {
        	if(hoursLoggedRec.End_Date_Time__c != null) {
        		hoursLoggedRec.Time_Spent_d__c = hoursLoggedRec.Time_Spent_d__c != null ? hoursLoggedRec.Time_Spent_d__c : 0;
	        	hoursLoggedRec.Time_Spent_h__c = hoursLoggedRec.Time_Spent_h__c != null ? hoursLoggedRec.Time_Spent_h__c : 0;
	        	hoursLoggedRec.Time_Spent_m__c = hoursLoggedRec.Time_Spent_m__c != null ? hoursLoggedRec.Time_Spent_m__c : 0;
                hoursLoggedRec.Paused_Hours__c = hoursLoggedRec.Paused_Hours__c != null ? hoursLoggedRec.Paused_Hours__c : 0;
	        	
	        	Decimal calculatedHours = (((hoursLoggedRec.Time_Spent_d__c * 24) + hoursLoggedRec.Time_Spent_h__c + (hoursLoggedRec.Time_Spent_m__c / 60)).setScale(2, RoundingMode.HALF_UP) - hoursLoggedRec.Paused_Hours__c);
	        	Decimal totalCost = calculatedHours * (hoursLoggedRec.Costing_Rate__c != null ? hoursLoggedRec.Costing_Rate__c : 0);
	        	Decimal oldTotalCost = (hoursLoggedRec.Old_Total_Hours__c != null ? hoursLoggedRec.Old_Total_Hours__c : 0) * 
	        								(hoursLoggedRec.Old_Costing_Rate__c != null ? hoursLoggedRec.Old_Costing_Rate__c : 0);
	        	
        		if(((oldMap == null && totalCost != 0) ||
	                    (oldMap != null && (totalCost != 0 || (oldTotalCost != 0 && !hoursLoggedRec.Is_Removed__c)) && 
	                    ((oldMap.get(hoursLoggedRec.Id).End_Date_Time__c == null) ||
	                    (hoursLoggedRec.Old_Costing_Rate__c != oldMap.get(hoursLoggedRec.Id).Old_Costing_Rate__c || 
	                    hoursLoggedRec.Old_Total_Hours__c != oldMap.get(hoursLoggedRec.Id).Old_Total_Hours__c) || 
	                    (hoursLoggedRec.Is_Removed__c && hoursLoggedRec.Is_Removed__c != oldMap.get(hoursLoggedRec.Id).Is_Removed__c && totalCost != 0)))) 
	                    && hoursLoggedRec.Task__c == null) {
	                hoursLoggedRec.put(integrationEntityNameToRecMap.get(IntegrationUtility.HOURS_LOGGED).Sync_Flag_API_Name__c, true);
	            }
        	}
        }
    }
    
    public static void managePaymentOnAccountSyncFlag(List<Payment_on_Account__c> newList) {
        if(!isIntegrationActive()) return;
        for(Payment_on_Account__c paymentOnAccountRec : newList) {
            if(paymentOnAccountRec.Total_Amount__c != null && paymentOnAccountRec.Total_Amount__c != 0) {
                integrationEntityNameToRecMap = IntegrationUtility.getIntegrationEntityMetadata(new List<String>{IntegrationUtility.PAYMENT_ON_ACCOUNT}, activeIntegrationName);
            	paymentOnAccountRec.put(integrationEntityNameToRecMap.get(IntegrationUtility.PAYMENT_ON_ACCOUNT).Sync_Flag_API_Name__c, true);
            }
        }
    }
    
    public static void manageCountSessionSyncFlag( List<Count_Session__c> newList, Map<Id, Count_Session__c> oldMap) {
        if(!isIntegrationActive()) return;
        integrationEntityNameToRecMap = IntegrationUtility.getIntegrationEntityMetadata(new List<String>{IntegrationUtility.COUNT_SESSION_JE}, activeIntegrationName);
        for(Count_Session__c countSessionRec : newList) {
            if(String.isNotBlank(countSessionRec.Status__c) && countSessionRec.Status__c == 'Closed' && 
            			countSessionRec.Status__c != oldMap.get(countSessionRec.Id).Status__c && 
            			countSessionRec.Net_Adjustment_After_Finalize__c != null && countSessionRec.Net_Adjustment_After_Finalize__c != 0) {
                countSessionRec.put(integrationEntityNameToRecMap.get(IntegrationUtility.COUNT_SESSION_JE).Sync_Flag_API_Name__c, true);
            }
        }
    }
    
    public static void manageNITCJESyncFlag( List<Customer_Owned_Unit__c> newList, Map<Id, Customer_Owned_Unit__c> oldMap) {
        if(!isIntegrationActive()) return;
        integrationEntityNameToRecMap = IntegrationUtility.getIntegrationEntityMetadata(new List<String>{IntegrationUtility.UNIT_NITC_JE}, activeIntegrationName);
        for(Customer_Owned_Unit__c unitRec : newList) {
        	if(unitRec.Unit_Type__c == 'STOCK' && unitRec.Status__c != 'Sold' && (unitRec.Sales_Tax_Credit__c != null || unitRec.Purchase_Tax_Credit__c != null)
        		&& unitRec.NITC_Claimed_Manually__c && unitRec.NITC_Claimed_Manually__c != oldMap.get(unitRec.Id).NITC_Claimed_Manually__c) {
        		unitRec.put(integrationEntityNameToRecMap.get(IntegrationUtility.UNIT_NITC_JE).Sync_Flag_API_Name__c, true);
        	}
        }
    }
    
    public static void manageConsignmentSyncFlag(List<Customer_Owned_Unit__c> newList, Map<Id, Customer_Owned_Unit__c> oldMap) {
        if(!isIntegrationActive()) return;
        integrationEntityNameToRecMap = IntegrationUtility.getIntegrationEntityMetadata(new List<String>{IntegrationUtility.STOCK_UNIT_CATEGORY, IntegrationUtility.UNIT_NITC_JE, IntegrationUtility.Unit_Consignment}, activeIntegrationName);
        for(Customer_Owned_Unit__c unitRec : newList) {
        	if(unitRec.Consignment__c == true && unitRec.Unit_Type__c == 'COU' && unitRec.Status__c == 'Transferred' && 
        			unitRec.Status__c != oldMap.get(unitRec.Id).Status__c && unitRec.Agreed_Payout__c != null && unitRec.Agreed_Payout__c > 0) {
        		unitRec.put(integrationEntityNameToRecMap.get(IntegrationUtility.Unit_Consignment).Sync_Flag_API_Name__c, true);
        	}
        }
    }
    
    private static Boolean checkForExtraConditionsForCustomer(Account customerRec) {
        return (customerRec.Is_Customer__c || (customerRec.Is_Vendor__c && customerRec.Claims_for_Service_Work__c));
    }
    
    private static Boolean checkForExtraConditionsForVendor(Account vendorRec) {
        return (vendorRec.Is_Vendor__c);
    }
    
    private static List<String> customerFieldListToSync = new List<String> {
        'FirstName__c', 'LastName__c', 'Home_Number__c', 'Mobile__c', 'BillingStreet', 'BillingCity', 'BillingCountry', 'BillingState', 'BillingPostalCode',
        'ShippingStreet', 'ShippingCity', 'ShippingCountry', 'ShippingState', 'ShippingPostalCode', 'Active__c',
        'Name', 'Work_Number__c', 'Fax', 'Website', 'AccountNumber', 'Email__c', 'Other_Email__c', 'Work_Email__c','Preferred_Email__c', 'Vendor_Number__c', 'Vendor_Tax_Id__c','Is_Vendor__c'
    };
    
    private static Boolean checkForExtraConditionsForCOInvoice(CO_Invoice_Header__c newRec, CO_Invoice_Header__c oldRec) {
        return (newRec.Invoice_Status__c != oldRec.Invoice_Status__c && newRec.Invoice_Status__c == IntegrationUtility.CLOSED && 
                    newRec.Checkout_Type__c != IntegrationUtility.INTERNAL && newRec.Checkout_Type__c != IntegrationUtility.DEAL);
    }
    
    private static Boolean checkForExtraConditionsForCOInvoiceJE(CO_Invoice_Header__c newRec, CO_Invoice_Header__c oldRec) {
        return (newRec.Invoice_Status__c != oldRec.Invoice_Status__c && newRec.Invoice_Status__c == IntegrationUtility.CLOSED);
    }
    
    private static Boolean checkForExtraConditionsForCOInvoicePayments(CO_Invoice_Header__c newRec, CO_Invoice_Header__c oldRec) {
        return (QBUtil.isQBEnabled() ? (newRec.Invoice_Status__c != oldRec.Invoice_Status__c && newRec.Invoice_Status__c == QBUtil.CLOSED && 
                newRec.Checkout_Type__c != QBUtil.INTERNAL && newRec.Checkout_Type__c != QBUtil.DEAL && newRec.Total_Charge_On_Account__c != 0 
                && newRec.Total_Amount_Except_Charge_Account__c > 0 && newRec.Total_Amount_Except_Charge_Account__c != newRec.Total_Payment__c) : 
                (newRec.Invoice_Status__c != oldRec.Invoice_Status__c && newRec.Invoice_Status__c == QBUtil.CLOSED && 
                    newRec.Checkout_Type__c != QBUtil.INTERNAL && newRec.Checkout_Type__c != QBUtil.DEAL && newRec.Checkout_Type__c != AccountingUtil.THIRD_PARTY
                    && newRec.Total_Amount_Except_Charge_Account__c != 0)) && (newRec.Total_Finance_Commission__c != null ? newRec.Total_Amount_Except_Charge_Account__c > newRec.Total_Finance_Commission__c : true);
    }

    private static Set<Id> getEntityIdSetToSync(Map<Id, SObject> sObjMapOld, List<SObject> sObjListNew, String entityName) {
            integrationEntityNameToRecMap = IntegrationUtility.getIntegrationEntityMetadata(new List<String>{entityName}, activeIntegrationName);
        Set<Id> entityIdSetToSync = new Set<Id>();
        for(SObject sObjRec: sObjListNew) {
            Id recordId = (Id)sObjRec.get('Id');
    		if(sObjRec.get(integrationEntityNameToRecMap.get(entityName).Sync_Flag_API_Name__c) != null 
                && Boolean.valueOf(sObjRec.get(integrationEntityNameToRecMap.get(entityName).Sync_Flag_API_Name__c)) 
                && (sObjMapOld == null || validateBeforeSync(sObjMapOld.get(recordId), sObjRec, entityName))) {
                    entityIdSetToSync.add(recordId);
            }
    	}
        return entityIdSetToSync;
    }

    private static Boolean validateBeforeSync(SObject sObjRecOld, SObject sObjRecnew, String entityName) {
        if(entityName == IntegrationUtility.STOCK_UNIT_CATEGORY) {
            return (sObjRecOld.get('Category__c') != null && sObjRecnew.get('Category__c') != null && sObjRecOld.get('Category__c') != sObjRecnew.get('Category__c'));
        } else if(entityNameToStatusToSyncMap.containsKey(entityName)) {
            return ((String)sObjRecnew.get('Status__c') == entityNameToStatusToSyncMap.get(entityName) && 
                    (String)sObjRecOld.get('Status__c') != entityNameToStatusToSyncMap.get(entityName));
        }
        return true;
    }

    public static void checkAndInitiateSyncBatch(List<SObject> sObjListNew, String entityName) {
        checkAndInitiateSyncBatch(null, sObjListNew, entityName);
    }

    public static void checkAndInitiateSyncBatch(Map<Id, SObject> sObjMapOld, List<SObject> sObjListNew, String entityName) {
        if(!isIntegrationActive()) return;
        Set<Id> sObjIdSet = getEntityIdSetToSync(sObjMapOld, sObjListNew, entityName);
        if(sObjIdSet.size() > 0) {
            if(preventReinitiatingAccountingSyncSetForUnit.contains(entityName)) {
                CustomerOwnedUnitTriggerHelper.preventOnAccountingSync = true;
            }
            IntegrationBatchService.initiateBatch(sObjIdSet, null, entityName);
        } else if(entityNameToRelatedEntityMap.containsKey(entityName)) {
            IntegrationSyncFlagService.checkAndInitiateSyncBatch(sObjMapOld, sObjListNew, entityNameToRelatedEntityMap.get(entityName));
        }
    }

    private static Boolean isIntegrationActive() {
        if(String.isBlank(activeIntegrationName)) return false;
        return true;
    }
    
    public static Boolean hasVarianceOnVI(List<Vendor_Invoicing_Group__c> vigList, Vendor_Invoicing_Header__c voInvoiceHeaderRec) {
        Decimal viTotal,vrTotal;
        for(Vendor_Invoicing_Group__c vigRec : vigList) {
            if(vigRec.Applied_Charge__c != null && vigRec.Applied_Charge__c != 0) {
                return true;
            } else if(vigRec.Vendor_Receiving_Group__r.Recieved__c != 0) {
                viTotal = (vigRec.VI_Cost__c != null ? vigRec.VI_Cost__c  : 0) * (1 - (vigRec.VI_Discount__c != null ? vigRec.VI_Discount__c/100 : 0)) * (voInvoiceHeaderRec.FX_Conversion_Rate__c != null && voInvoiceHeaderRec.FX_Conversion_Rate__c != 0 ? voInvoiceHeaderRec.FX_Conversion_Rate__c : 1);
                vrTotal = (vigRec.Vendor_Receiving_Group__r.Cost__c != null ? vigRec.Vendor_Receiving_Group__r.Cost__c : 0) * (1 - (vigRec.Vendor_Receiving_Group__r.Discount__c != null ? vigRec.Vendor_Receiving_Group__r.Discount__c/100 : 0)) * ((vigRec.Vendor_Receiving_Group__r.Vendor_Receiving_Header__r.Finalized_VR_Conversion_Rate__c != null && vigRec.Vendor_Receiving_Group__r.Vendor_Receiving_Header__r.Finalized_VR_Conversion_Rate__c != 0) ? vigRec.Vendor_Receiving_Group__r.Vendor_Receiving_Header__r.Finalized_VR_Conversion_Rate__c : 1);
                if(viTotal.setScale(2, RoundingMode.HALF_UP) != vrTotal.setScale(2, RoundingMode.HALF_UP)) {
                    return true;
                }
            }
        }
        return false;
    }

    public static Boolean hasVarianceOnRCR(List<Return_CR_Line_Item__c> rcrliList, Return_CR_Header__c returnCRHeader) {
        Boolean hasVariance = false;
        for(Return_CR_Line_Item__c rcrliRec: rcrliList) {
            if(rcrliRec.Return_Qty__c != null && rcrliRec.Return_Qty__c != 0 && !rcrliRec.Return_VO_Line_Items__r.isEmpty()) {
                if(rcrliRec.Return_CR_Header__r.Vendor__r.Is_Foreign_Vendor__c && returnCRHeader.FX_Conversion_Rate__c != 0) {
                    hasVariance = ((rcrliRec.Return_VO_Line_Items__r[0].Inventory_Cost__c.setScale(2, RoundingMode.HALF_UP)) != (ForeignExchangeUtil.getConvertedAmountInLocalCurrency(rcrliRec.Credit_Cost__c * rcrliRec.Return_Qty__c, returnCRHeader.FX_Conversion_Rate__c)));
                } else {
                    hasVariance = ((rcrliRec.Return_VO_Line_Items__r[0].Inventory_Cost__c.setScale(2, RoundingMode.HALF_UP)) != ((rcrliRec.Credit_Cost__c * rcrliRec.Return_Qty__c).setScale(2, RoundingMode.HALF_UP)));
                }
                if(hasVariance) {
                    return true;
                }
            }
        }
        return false;
    }
}