@isTest
private class BPScriptUtilityTest {
    
    @testSetup
    private static void setup(){
        TestDataFactory.disableFLSChecks();
        Cash_Drawer__c cashDrawer = new Cash_Drawer__c(Name = 'Main Cash Drawer', Active__c = true);
        insert cashDrawer;
        Message_History__c messageHistory = new Message_History__c(Activity__c = 'Text Message');
        insert messageHistory;
        Customer_Owned_Unit__c COU = new Customer_Owned_Unit__c(Unit_Type__c = 'ORDU', Status__c = 'Received');
        insert COU;
    }
    
    @isTest
    private static void testBPScriptUtilityMethods(){
    	Test.startTest();
        BPScriptUtility nonStaticMethods = new BPScriptUtility();
    	BPScriptUtility.updateStatusAndTotalsForMerchSectionOnCOHeader();
        nonStaticMethods.populateFieldsOnInvoice();
        BPScriptUtility.populateTotalFieldsOnDealAndDealItem();
        BPScriptUtility.shopSettingConfigScript();
        nonStaticMethods.populateDealOptionsWIPCostOnUnit();
        BPScriptUtility.updateUnitPricesAndCostsForInvoiceDeal();
        BPScriptUtility.populateRetailPriceOnKitLineItems();
        BPScriptUtility.updateUnitInvServiceJobTransactionType();
        BPScriptUtility.upsertTransactionTypes();
        BPScriptUtility.insertFusionLineItems();
        BPScriptUtility.updateTradeInActualCashValue();
        BPScriptUtility.updateTradeInActualCashValueForAusOn();
        BPScriptUtility.updateSubletSoliAndCreateVoliForOpenCO();
        BPScriptUtility.updateTaxAndTotalForDealWithTradeIn();
        BPScriptUtility.populateSOHeaderOnExistingAppointments();
        BPScriptUtility.deleteNonDefaultSpecialCategories();
        BPScriptUtility.createDefaultSpecialCategories();
        BPScriptUtility.populatePurchaseTaxOnVendorInvoice();
        BPScriptUtility.populateDefaultTTypeOnExistingAppointmentsAndSOUsingJobType();
        BPScriptUtility.resetVINField();
        BPScriptUtility.setCOInvoiceJEFlagForInvoicedDeals();
        BPScriptUtility.insertDefaultAccountTypes();
        BPScriptUtility.populateTaxFieldsOnDealItem();
        BPScriptUtility.populateIndividualTaxesOnVendorInvoices();
        BPScriptUtility.executeAccountTypeBatch();
        BPScriptUtility.populateTaxExemptions();
        BPScriptUtility.createUniqueMakeModelSubmodel();
        BPScriptUtility.createUniqueSubmodel();
        BPScriptUtility.changesStatusOfInvoicedVRs();
        BPScriptUtility.updateTradeInDefaultCategory();
        BPScriptUtility.populateCashDrawerReconciliationForExistingCashReconciliationRec();
        BPScriptUtility.populateCashDrawerOnPayments();
        BPScriptUtility.populateCashDrawerOnDeposits();
        Test.stopTest();
        List<Shop_Settings__c> shopSettingConfigList = [select id from Shop_Settings__c where Is_Working__c = true AND From_Time__c = '8:00AM' AND To_Time__c = '5:00PM' limit 7];
    	system.assertEquals(5, shopSettingConfigList.size());
    }
    @isTest
    private static void testBPScriptUtilityMethods1(){
        Test.startTest();
        BPScriptUtility.populateMerchandiseTransactionTypeOnHistoricalRecords();
        BPScriptUtility.deleteDuplicateCashReconciliationPaymentRecords();
        BPScriptUtility.updatePaymentDateOnCODeposit();
        BPScriptUtility.updatePaymentDateOnCOInvoicePayment();
        BPScriptUtility.setOrderLotsWhenIsOrderLotFlagDisabled();
        BPScriptUtility.populateDealOptionClearingControlAccount();
        BPScriptUtility.populateClosedDateOnInvoice();
        BPScriptUtility.changeFinancedToFinancingForDeal();
        BPScriptUtility.updateUnitPriceAndCostAdjustments();
        BPScriptUtility.populateLabourCostingOnSOLIBasedOnTechHoursCosting();
        BPScriptUtility.updateCostingRateOnHoursLogged();
        BPScriptUtility.updateLaborCostingControlAccounts();
        BPScriptUtility.updateDealAndTradeInPreTaxTotalOnInvoice();
        BPScriptUtility.updateExpectedDateOnVendorOrders();
        BPScriptUtility.syncQBTerms();
        BPScriptUtility.createLocations();
        Test.stopTest();
        system.assertEquals(0, [SELECT Id FROM LEAD LIMIT 1].size());
    }
    @isTest
    private static void testBPScriptUtilityMethods2(){
        Test.startTest();
        BPScriptUtility.setFeeTypeOnDefaultFee();
        BPScriptUtility.setMaxNumberOfTechniciansInConfig();
        BPScriptUtility.populateNameSpaceInConfig();
        BPScriptUtility.fixAccountingSettingsNameForQB();
        BPScriptUtility.updateAppointmentEndTime();
        BPScriptUtility.copyEvents();
        BPScriptUtility.createConfigurationForUnitDataFields();
        BPScriptUtility.createDUPfromUPCForSoldUnits();
        BPScriptUtility.setFTPFileStorageName();
        BPScriptUtility.updateBRPVendorListType();
        BPScriptUtility.createPartSaleTransactionType();
        BPScriptUtility.updateQuoteTransactionType();
        BPScriptUtility.turnOffSyncFlagForTask();
        BPScriptUtility.enablePublishInFeedsOnStockUnit();
        BPScriptUtility.updateHerokuEndPointInFTPConfig();
        BPScriptUtility.setBaseTypeDUPCDescription();
        BPScriptUtility.updateCheckoutTypeOnInvToThirdParty();
        BPScriptUtility.updateCompletedFlagOnCountSession();
        BPScriptUtility.cleanUpMakeModelSubmodel();
        BPScriptUtility.updatePaymentMethodUndepositedFunds();
        BPScriptUtility.enableIncomingMessageFeature();
        BPScriptUtility.setOrderUnitDates();
        //BPScriptUtility.reSyncLaborDealJE();
        BPScriptUtility.setShopifyConfiguration();
        //BPScriptUtility.populateTradeInTaxTotalOnDealAndInvoiceHeader();
        Test.stopTest();
        system.assertEquals(0, [SELECT Id FROM LEAD LIMIT 1].size());
        
    }
        
}