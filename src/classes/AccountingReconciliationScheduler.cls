/**
 * Author: Nidhi Sharma
 * Since: April 20, 2022
 * Name: AccountingReconciliationScheduler
 * Description: Accounting daily reconciliation scheduler classes.
**/
global without sharing class AccountingReconciliationScheduler implements Database.Batchable<String>, Database.Stateful, Database.AllowsCallouts, Schedulable {

    private static final String PARTS = 'Parts';
    private static final String UNITS = 'Units';
    private static final String DEPOSITS = 'Deposits';
    private static final String WIP_LABOR = 'WIP Labor';
    private static final String AP_INVENTORY = 'AP Inventory';
    private static final String STORE_CREDIT = 'Store Credit';
    private static final String STOCKED_TRADE = 'Stocked Trade';
    private static final String DEAL_OPTION = 'Deal Option';
    private static final String DEDUCTIBLE = 'Deductible';

    private Map<String, String> accNumberToActiveAccIdMap = getAccountingNumberToActiveAccountingIdMap();    //For Xero
    private Map<String, General_Account__c> accUniqueIdToGeneralAccountRecMap = getGLNumToGeneralAccountRecMap();
    private Map<String, Decimal> accountIdToNetIncomeMap = new Map<String, Decimal>();

    private static Map<String, String> controlAccountNameByReconciliationType = new Map<String, String>{
        DEPOSITS => 'Customer Deposits',
        WIP_LABOR => 'WIP Labor Inventory',
        AP_INVENTORY => 'A/P Inventory Accrual',
        STORE_CREDIT => 'Store Credit Accrual',
        DEAL_OPTION => 'Deal Option Clearing'
    };

    global Iterable<String> start(Database.BatchableContext bc) {
        DateTime reconcileDateTime = System.now();
        this.accountIdToNetIncomeMap = getAccountIdToNetIncomeMap(reconcileDateTime);

        if(Test.isRunningTest()) {
            return new List<String>{PARTS};
        }
        return new List<String>{PARTS, UNITS, DEPOSITS, WIP_LABOR, AP_INVENTORY, STORE_CREDIT, STOCKED_TRADE, DEAL_OPTION, DEDUCTIBLE};
    }

    global void execute(Database.BatchableContext bc, List<String> reconciliationTypeList) {
        if(reconciliationTypeList.size() > 0) {
            switch on reconciliationTypeList[0] {
                when 'Parts' {
                    generatePartReconciliation();
                } when 'Units' {
                    generateUnitReconciliation();
                } when 'Deposits' {
                    generateDepositsReconciliation();
                } when 'WIP Labor' {
                    generateWIPLaborReconciliation();
                } when 'AP Inventory' {
                    generateAPInventoryReconciliation();
                } when 'Store Credit' {
                    generateStoreCreditReconciliation();
                } when 'Stocked Trade' {
                    generateStockedTradeReconciliation();
                } when 'Deal Option' {
                    generateDealOptionReconciliation();
                } when 'Deductible' {
                    generateDeductibleReconciliation();
                } 
            }
        }
    }

    global void finish(Database.BatchableContext bc) {
    }

    global void execute(SchedulableContext sc) {
		Database.executeBatch(new AccountingReconciliationScheduler(), 1);
	}

    public void generatePartReconciliation() {
        String reconciliationType = PARTS;
        DateTime reconcileDateTime = System.now();
        List<Accounting_Reconciliation__c> accReconciliationInsertList = new List<Accounting_Reconciliation__c>();
        
        //Category to aggregate results from part object
        Map<String, AggregateResult> invGLToAggregateResultMap = new Map<String, AggregateResult>();
        for(AggregateResult aggResult : [Select Category__r.Inventory_GL__c InventoryGL, Count(Id) TotalParts, SUM(Qty_In_Stock__c) InstockQty, SUM(Total_Cost__c) InstockCost, SUM(Oversold_Qty__c) OversoldQty, SUM(Oversold_Cost__c) OversoldCost FROM Part__c WHERE (Qty_In_Stock__c != null AND Qty_In_Stock__c != 0) OR (Oversold_Qty__c != null AND Oversold_Qty__c != 0) group by Category__r.Inventory_GL__c]) {
            invGLToAggregateResultMap.put(String.valueOf(aggResult.get('InventoryGL')), aggResult);
        }
        
        if(String.isBlank(AccountingUtil.activeAccIntegrationName)) {
            Accounting_Reconciliation__c accReconcileRec = createAccountingReconciliationRec(reconcileDateTime, reconciliationType, null);
            accReconcileRec.Parts_Instock_Qty__c = accReconcileRec.Parts_Instock_Cost__c = accReconcileRec.Parts_Oversold_Qty__c = accReconcileRec.Parts_Oversold_Cost__c = 0;
            for(AggregateResult aggResult : invGLToAggregateResultMap.values()) {
                accReconcileRec.Number_of_BP_records__c += aggResult.get('TotalParts') != null ? Decimal.valueOf(String.valueOf(aggResult.get('TotalParts'))) : 0;
                accReconcileRec.Parts_Instock_Qty__c += aggResult.get('InstockQty') != null ? Decimal.valueOf(String.valueOf(aggResult.get('InstockQty'))) : 0;
                accReconcileRec.Parts_Instock_Cost__c += aggResult.get('InstockCost') != null ? Decimal.valueOf(String.valueOf(aggResult.get('InstockCost'))) : 0;
                accReconcileRec.Parts_Oversold_Qty__c += aggResult.get('OversoldQty') != null ? Decimal.valueOf(String.valueOf(aggResult.get('OversoldQty'))) : 0;
                accReconcileRec.Parts_Oversold_Cost__c += aggResult.get('OversoldCost') != null ? Decimal.valueOf(String.valueOf(aggResult.get('OversoldCost'))) : 0;
            }
            accReconcileRec.Blackpurl_Balance__c = accReconcileRec.Parts_Instock_Cost__c - accReconcileRec.Parts_Oversold_Cost__c;
            accReconciliationInsertList.add(accReconcileRec);
        } else {            
            for(AggregateResult catAggResult : (List<AggregateResult>)SOQLUtility.getQueryResults('Category__c', 'Select Inventory_GL__c InventoryGL FROM Category__c WHERE Type__c = \'Part\' Group By Inventory_GL__c')) {
                String inventoryGL = String.valueOf(catAggResult.get('InventoryGL'));
                Accounting_Reconciliation__c accReconcileRec = createAccountingReconciliationRec(reconcileDateTime, reconciliationType, inventoryGL);
                if(invGLToAggregateResultMap.containsKey(inventoryGL)) {
                    AggregateResult aggResult = invGLToAggregateResultMap.get(inventoryGL);
                    accReconcileRec.Number_of_BP_records__c = aggResult.get('TotalParts') != null ? Decimal.valueOf(String.valueOf(aggResult.get('TotalParts'))) : 0;
                    accReconcileRec.Parts_Instock_Qty__c = aggResult.get('InstockQty') != null ? Decimal.valueOf(String.valueOf(aggResult.get('InstockQty'))) : 0;
                    accReconcileRec.Parts_Instock_Cost__c = aggResult.get('InstockCost') != null ? Decimal.valueOf(String.valueOf(aggResult.get('InstockCost'))) : 0;
                    accReconcileRec.Parts_Oversold_Qty__c = aggResult.get('OversoldQty') != null ? Decimal.valueOf(String.valueOf(aggResult.get('OversoldQty'))) : 0;
                    accReconcileRec.Parts_Oversold_Cost__c = aggResult.get('OversoldCost') != null ? Decimal.valueOf(String.valueOf(aggResult.get('OversoldCost'))) : 0;
                    accReconcileRec.Blackpurl_Balance__c = accReconcileRec.Parts_Instock_Cost__c - accReconcileRec.Parts_Oversold_Cost__c;
                }
                accReconcileRec.GL_Balance__c = getGLBalance(inventoryGL, this.accountIdToNetIncomeMap, reconciliationType);
                setVarianceChange(accReconcileRec);
                accReconciliationInsertList.add(accReconcileRec);
            }
        }
        DMLUtility.insertSobjectList('Accounting_Reconciliation__c', accReconciliationInsertList);
    }

    public void generateUnitReconciliation() {
        String reconciliationType = UNITS;
        DateTime reconcileDateTime = System.now();
        List<Accounting_Reconciliation__c> accReconciliationInsertList = new List<Accounting_Reconciliation__c>();
        
        //Category to aggregate results from unit object
        Map<String, AggregateResult> invGLToAggregateResultMap = new Map<String, AggregateResult>();
        for(AggregateResult aggResult : [Select Category__r.Inventory_GL__c InventoryGL, Count(Id) TotalUnits, SUM(Total_Cost__c) TotalCost, SUM(Deal_Options_WIP__c) DealOptionsWIP FROM Customer_Owned_Unit__c WHERE Status__c IN ('Available', 'Reserved') group by Category__r.Inventory_GL__c]) {
            invGLToAggregateResultMap.put(String.valueOf(aggResult.get('InventoryGL')), aggResult);
        }
        
        if(String.isBlank(AccountingUtil.activeAccIntegrationName)) {
            Accounting_Reconciliation__c accReconcileRec = createAccountingReconciliationRec(reconcileDateTime, reconciliationType, null);
            accReconcileRec.Units_Deal_Options_WIP__c = accReconcileRec.Units_Instock_Cost__c = 0;
            for(AggregateResult aggResult : invGLToAggregateResultMap.values()) {
                accReconcileRec.Number_of_BP_records__c += aggResult.get('TotalUnits') != null ? Decimal.valueOf(String.valueOf(aggResult.get('TotalUnits'))) : 0;
                accReconcileRec.Units_Instock_Cost__c += aggResult.get('TotalCost') != null ? Decimal.valueOf(String.valueOf(aggResult.get('TotalCost'))) : 0;
                accReconcileRec.Units_Deal_Options_WIP__c += aggResult.get('DealOptionsWIP') != null ? Decimal.valueOf(String.valueOf(aggResult.get('DealOptionsWIP'))) : 0;
            }
            accReconcileRec.Blackpurl_Balance__c = accReconcileRec.Units_Instock_Cost__c + accReconcileRec.Units_Deal_Options_WIP__c;
            accReconciliationInsertList.add(accReconcileRec);
        } else {            
            for(AggregateResult catAggResult : (List<AggregateResult>)SOQLUtility.getQueryResults('Category__c', 'Select Inventory_GL__c InventoryGL FROM Category__c WHERE Type__c = \'Unit\' Group By Inventory_GL__c')) {
                String inventoryGL = String.valueOf(catAggResult.get('InventoryGL'));
                Accounting_Reconciliation__c accReconcileRec = createAccountingReconciliationRec(reconcileDateTime, reconciliationType, inventoryGL);
                if(invGLToAggregateResultMap.containsKey(inventoryGL)) {
                    AggregateResult aggResult = invGLToAggregateResultMap.get(inventoryGL);
                    accReconcileRec.Number_of_BP_records__c = aggResult.get('TotalUnits') != null ? Decimal.valueOf(String.valueOf(aggResult.get('TotalUnits'))) : 0;
                    accReconcileRec.Units_Instock_Cost__c = aggResult.get('TotalCost') != null ? Decimal.valueOf(String.valueOf(aggResult.get('TotalCost'))) : 0;
                    accReconcileRec.Units_Deal_Options_WIP__c = aggResult.get('DealOptionsWIP') != null ? Decimal.valueOf(String.valueOf(aggResult.get('DealOptionsWIP'))) : 0;
                    accReconcileRec.Blackpurl_Balance__c = accReconcileRec.Units_Instock_Cost__c + accReconcileRec.Units_Deal_Options_WIP__c;
                }
                accReconcileRec.GL_Balance__c = getGLBalance(inventoryGL, this.accountIdToNetIncomeMap, reconciliationType);
                setVarianceChange(accReconcileRec);
                accReconciliationInsertList.add(accReconcileRec);
            }
        }
        DMLUtility.insertSobjectList('Accounting_Reconciliation__c', accReconciliationInsertList);
    }

    public void generateDepositsReconciliation() {
        Accounting_Reconciliation__c accReconcileRec = setReconciliationFieldsForControlAccounts(DEPOSITS);
        List<AggregateResult> aggResults = [Select Count(Id) TotalOrders, SUM(Total_Deposit_And_Payment__c) TotalDepositsAndPayment FROM CO_Header__c WHERE Status__c != 'Closed' AND ((Total_Deposit__c != null AND Total_Deposit__c != 0) OR (Total_Payment__c != null AND Total_Payment__c != 0))];
        if(!aggResults.isEmpty()) {
            accReconcileRec.Number_of_BP_records__c = aggResults[0].get('TotalOrders') != null ? Decimal.valueOf(String.valueOf(aggResults[0].get('TotalOrders'))) : 0;
            accReconcileRec.Blackpurl_Balance__c = aggResults[0].get('TotalDepositsAndPayment') != null ? (Decimal.valueOf(String.valueOf(aggResults[0].get('TotalDepositsAndPayment')))) * -1 : 0;
        }
        setVarianceChange(accReconcileRec);
        DMLUtility.insertSobjectList('Accounting_Reconciliation__c', new List<Accounting_Reconciliation__c>{accReconcileRec});
    }

    public void generateWIPLaborReconciliation() {
        if(GeneralConfiguration.isTechnicianHoursCostingEnabled()) {
            Accounting_Reconciliation__c accReconcileRec = setReconciliationFieldsForControlAccounts(WIP_LABOR);
            accReconcileRec.WIP_Hours_Logged__c = 0;
            List<AggregateResult> aggResults = [Select SUM(Calculated_Hours__c) TotalHoursLogged, SUM(Total_Cost__c) TotalCost From Hours_Logged__c WHERE Service_Order_header__c != null AND TOtal_Cost__c != null AND TOtal_Cost__c != 0 AND Service_Order_header__r.Invoice_Number__c = null AND Service_Order_header__r.SO_Status__c != :ServiceJobUtil.INVOICED Group By Service_Order_header__c];
            for(AggregateResult aggResult : aggResults) {
                accReconcileRec.WIP_Hours_Logged__c += aggResult.get('TotalHoursLogged') != null ? Decimal.valueOf(String.valueOf(aggResult.get('TotalHoursLogged'))) : 0;
                accReconcileRec.Blackpurl_Balance__c += aggResult.get('TotalCost') != null ? Decimal.valueOf(String.valueOf(aggResult.get('TotalCost'))) : 0;
            }
            accReconcileRec.Number_of_BP_records__c = aggResults.size();
            setVarianceChange(accReconcileRec);
            DMLUtility.insertSobjectList('Accounting_Reconciliation__c', new List<Accounting_Reconciliation__c>{accReconcileRec});
        }
    }

    public void generateAPInventoryReconciliation() {
        Accounting_Reconciliation__c accReconcileRec = setReconciliationFieldsForControlAccounts(AP_INVENTORY);
        accReconcileRec.AP_Inventory_VR_Stocked__c = accReconcileRec.AP_Inventory_Return_Approved__c = 0;
        
        List<AggregateResult> aggVRResults = [Select COUNT(Id) TotalReceivingHeader, SUM(Receiving_Total__c) TotalReceiving FROM Vendor_Receiving_Header__c WHERE Status__c = 'Stocked'];
        if(!aggVRResults.isEmpty()) {
            accReconcileRec.Number_of_BP_records__c += aggVRResults[0].get('TotalReceivingHeader') != null ? Decimal.valueOf(String.valueOf(aggVRResults[0].get('TotalReceivingHeader'))) : 0;
            accReconcileRec.AP_Inventory_VR_Stocked__c = aggVRResults[0].get('TotalReceiving') != null ? Decimal.valueOf(String.valueOf(aggVRResults[0].get('TotalReceiving'))) : 0;
        }
        List<AggregateResult> aggRVOResults = [Select COUNT(Id) TotalRVO, SUM(Credits_Pending__c) TotalReturn FROM Return_VO_Header__c WHERE Status__c IN ('Approved', 'Partially Credited')];
        if(!aggRVOResults.isEmpty()) {
            accReconcileRec.Number_of_BP_records__c += aggRVOResults[0].get('TotalRVO') != null ? Decimal.valueOf(String.valueOf(aggRVOResults[0].get('TotalRVO'))) : 0;
            accReconcileRec.AP_Inventory_Return_Approved__c = aggRVOResults[0].get('TotalReturn') != null ? Decimal.valueOf(String.valueOf(aggRVOResults[0].get('TotalReturn'))) : 0;
        }
        accReconcileRec.Blackpurl_Balance__c = (accReconcileRec.AP_Inventory_VR_Stocked__c - accReconcileRec.AP_Inventory_Return_Approved__c) * -1;
        setVarianceChange(accReconcileRec);
        DMLUtility.insertSobjectList('Accounting_Reconciliation__c', new List<Accounting_Reconciliation__c>{accReconcileRec});
    }

    public void generateStoreCreditReconciliation() {
        Accounting_Reconciliation__c accReconcileRec = setReconciliationFieldsForControlAccounts(STORE_CREDIT);
        List<AggregateResult> aggResults = [Select COUNT(Id) TotalCustomers, SUM(Total_Store_Credit__c) TotalStoreCredit FROM Account WHERE Is_Customer__c = true AND Total_Store_Credit__c != null AND Total_Store_Credit__c != 0];
        if(!aggResults.isEmpty()) {
            accReconcileRec.Number_of_BP_records__c = aggResults[0].get('TotalCustomers') != null ? Decimal.valueOf(String.valueOf(aggResults[0].get('TotalCustomers'))) : 0;
            accReconcileRec.Blackpurl_Balance__c = aggResults[0].get('TotalStoreCredit') != null ? (Decimal.valueOf(String.valueOf(aggResults[0].get('TotalStoreCredit')))) * -1 : 0;
        }
        setVarianceChange(accReconcileRec);
        DMLUtility.insertSobjectList('Accounting_Reconciliation__c', new List<Accounting_Reconciliation__c>{accReconcileRec});
    }

    public void generateStockedTradeReconciliation() {
        Accounting_Reconciliation__c accReconcileRec = setReconciliationFieldsForControlAccounts(STOCKED_TRADE);
        List<AggregateResult> aggResults = [Select COUNT(Id) TotalStockedInTrade, SUM(Actual_Cash_Value__c) TotalACV FROM Deal_Item__c WHERE Type__c = 'Trade In' AND Is_Stocked_In__c = true AND Deal__r.Invoice_Number__c = null];
        if(!aggResults.isEmpty()) {
            accReconcileRec.Number_of_BP_records__c = aggResults[0].get('TotalStockedInTrade') != null ? Decimal.valueOf(String.valueOf(aggResults[0].get('TotalStockedInTrade'))) : 0;
            accReconcileRec.Blackpurl_Balance__c = aggResults[0].get('TotalACV') != null ? (Decimal.valueOf(String.valueOf(aggResults[0].get('TotalACV')))) * -1 : 0;
        }
        setVarianceChange(accReconcileRec);
        DMLUtility.insertSobjectList('Accounting_Reconciliation__c', new List<Accounting_Reconciliation__c>{accReconcileRec});
    }

    public void generateDealOptionReconciliation() {
        Accounting_Reconciliation__c accReconcileRec = setReconciliationFieldsForControlAccounts(DEAL_OPTION);
        List<AggregateResult> aggDealMerchResults = [Select COUNT(Id) TotalItems, SUM(Option_Clearing__c) TotalPrice FROM Deal__c WHERE Option_Clearing__c != 0 AND Option_Clearing__c != null];
        if(!aggDealMerchResults.isEmpty()) {
            accReconcileRec.Number_of_BP_records__c += aggDealMerchResults[0].get('TotalItems') != null ? Decimal.valueOf(String.valueOf(aggDealMerchResults[0].get('TotalItems'))) : 0;
            accReconcileRec.Blackpurl_Balance__c += aggDealMerchResults[0].get('TotalPrice') != null ? Decimal.valueOf(String.valueOf(aggDealMerchResults[0].get('TotalPrice'))) : 0;
        }
        setVarianceChange(accReconcileRec);
        DMLUtility.insertSobjectList('Accounting_Reconciliation__c', new List<Accounting_Reconciliation__c>{accReconcileRec});
    }

    public void generateDeductibleReconciliation() {
        Accounting_Reconciliation__c accReconcileRec = setReconciliationFieldsForControlAccounts(DEDUCTIBLE);
        LIst<AggregateResult> aggResults = [Select SUM(Pre_Tax_Total__c) TotalDeductible FROM SO_Payment_Role__c WHERE RecordType.DeveloperName = 'Deductible' AND Service_Order_Header__r.Transaction_Type__r.Type__c = 'Third-Party' AND Status__c = 'Invoiced' AND Service_Order_Header__r.Invoice_Number__c = null group by Service_Order_Header__c];
        for(AggregateResult aggResult : aggResults) {
            accReconcileRec.Blackpurl_Balance__c += aggResult.get('TotalDeductible') != null ? (Decimal.valueOf(String.valueOf(aggResult.get('TotalDeductible')))) * -1 : 0;
        }
        accReconcileRec.Number_of_BP_records__c = aggResults.size();
        setVarianceChange(accReconcileRec);
        DMLUtility.insertSobjectList('Accounting_Reconciliation__c', new List<Accounting_Reconciliation__c>{accReconcileRec});
    }

    private Accounting_Reconciliation__c setReconciliationFieldsForControlAccounts(String reconciliationType) {
        Accounting_Reconciliation__c accReconcileRec = new Accounting_Reconciliation__c();
        if(String.isNotBlank(reconciliationType)) {
            DateTime reconcileDateTime = System.now();
            if(String.isBlank(AccountingUtil.activeAccIntegrationName)) {
                accReconcileRec = createAccountingReconciliationRec(reconcileDateTime, reconciliationType, null);
            } else {          
                String inventoryGL;
                if(controlAccountNameByReconciliationType.containsKey(reconciliationType)) {
                    inventoryGL = AccountingUtil.getChartofAccount(controlAccountNameByReconciliationType.get(reconciliationType));
                } else {
                    for(Category__c catRec : [SELECT Income_GL__c FROM Category__c WHERE Type__c =: reconciliationType AND Default__c = true]) {
                        inventoryGL = catRec.Income_GL__c;
                    }
                }
                accReconcileRec = createAccountingReconciliationRec(reconcileDateTime, reconciliationType, inventoryGL);
                accReconcileRec.GL_Balance__c = getGLBalance(inventoryGL, this.accountIdToNetIncomeMap, reconciliationType);
            }
        }
        return accReconcileRec;
    }

    public Map<String, Decimal> getAccountIdToNetIncomeMap(DateTime reconcileDateTime) {
        String startDateStr = reconcileDateTime.year() + '-' + reconcileDateTime.month() + '-' + reconcileDateTime.day();
        if(QBUtil.isQBEnabled()) {
            List<IFW_IntegrationConfig__c> integrationConfigList = IFW_SOQLUtil.getIntegrationConfigWithItems(QBUtil.QUICKBOOKS_ONLINE, null);
            try{
                if(integrationConfigList.isEmpty()) throw new BlackpurlException(QBUtil.QUICKBOOKS_ONLINE + ' config is not defined');
                QBReportWrapper responseObj = QBCalloutManager.getReportData('BalanceSheet?start_date='+startDateStr+'&end_date='+startDateStr , integrationConfigList[0]);
        
                if(responseObj != null && responseObj.Rows != null && responseObj.Rows.Row != null) {
                    parseQBResponse(responseObj.Rows.Row, this.accountIdToNetIncomeMap);
                }
            } catch (system.Exception e) {
                new LogService().createErrorLog('AccountingReconciliationScheduler', 'start()', e.getMessage(), LogService.NOT_APPLICABLE, e.getStackTraceString(), 
                                                    startDateStr, '', true, 'Info');
            }
            if(!integrationConfigList.isEmpty()) QBCalloutManager.updateRecords(integrationConfigList[0]);

        } else if(XeroUtility.isXeroEnabled()) {
            List<IFW_IntegrationConfig__c> integrationConfigList = BaseIntegration.getParentByName('Xero');
            try{
                XeroResponseWrapper responseObj = XeroFusionReportService.getReportData(startDateStr, startDateStr, 'BalanceSheet');
                if(responseObj != null && responseObj.Reports != null && responseObj.Reports.size() > 0 && responseObj.Reports[0].Rows != null) {
                    for(XeroReportWrapper.cls_Rows rowObj : responseObj.Reports[0].Rows) {
                        parseXeroResponse(rowObj.Rows, this.accountIdToNetIncomeMap);
                    }
                }
            } catch(Exception e) {
                new LogService().createErrorLog('AccountingReconciliationScheduler', 'start()', e.getMessage(), LogService.NOT_APPLICABLE, e.getStackTraceString(), 
                                                    startDateStr, '', true, 'Info');
            }
            if(!integrationConfigList.isEmpty()) {
                if(XeroFusionReportService.accessToken != null) integrationConfigList[0].Access_Token__c = XeroFusionReportService.accessToken;
                if(XeroFusionReportService.refreshToken != null) integrationConfigList[0].Refresh_Token__c = XeroFusionReportService.refreshToken;
                QBCalloutManager.updateRecords(integrationConfigList[0]);
            }
        }
        return this.accountIdToNetIncomeMap;
    }

    private void parseXeroResponse(List<XeroReportWrapper.cls_InnerRows> rowList, Map<String, Decimal> accountIdToNetIncomeMap) {
        if(rowList != null) {
            for(XeroReportWrapper.cls_InnerRows rowObj : rowList) {
                if(rowObj.RowType != null) {
                    if(rowObj.RowType.equalsIgnoreCase('Row') && rowObj.Cells != null && rowObj.Cells.size() >= 2) {
                        Decimal amount = (String.isNotBlank(rowObj.Cells[1].Value)) ? Decimal.valueOf(rowObj.Cells[1].Value) : 0;
                        if(rowObj.Cells[1].Attributes != null && !rowObj.Cells[1].Attributes.isEmpty() && String.isNotBlank(rowObj.Cells[1].Attributes[0].Value)) {
                            accountIdToNetIncomeMap.put(rowObj.Cells[1].Attributes[0].Value.toLowerCase(), amount);
                        }
                    } else if(rowObj.RowType.equalsIgnoreCase('Section') && rowObj.Rows != null && !rowObj.Rows.isEmpty()) {
                        parseXeroResponse(rowObj.Rows, accountIdToNetIncomeMap);
                    }
                }
            }
        }
    }

    private void parseQBResponse(List<QBReportWrapper.cls_Row> responseObj, Map<String, Decimal> accountIdToNetIncomeMap) {
        if(responseObj != null) {
            List<QBReportWrapper.cls_ColData> colObjList;
            for(QBReportWrapper.cls_Row rowObj : responseObj) {
                if(rowObj.Header != null && rowObj.Header.ColData.size() > 1) {
                    colObjList = rowObj.Header.ColData;
                    if(colObjList.size() > 1 && colObjList[0].id != null && colObjList[1].value != null) {
                        accountIdToNetIncomeMap.put(colObjList[0].id, (String.isNotBlank(colObjList[1].value)) ? Decimal.valueof(colObjList[1].value) : 0);
                    }                
                }
                if(rowObj.Rows != null && rowObj.Rows.Row != null) {
                    parseQBResponse(rowObj.Rows.Row, accountIdToNetIncomeMap);
                } else if(rowObj.ColData != null) {
                    colObjList = rowObj.ColData;
                    if(colObjList.size() > 1 && colObjList[0].id != null && colObjList[1].value != null) {
                        accountIdToNetIncomeMap.put(colObjList[0].id, (String.isNotBlank(colObjList[1].value)) ? Decimal.valueof(colObjList[1].value) : 0);
                    }
                }
            }
        }
    }

    private Accounting_Reconciliation__c createAccountingReconciliationRec(DateTime reconcileDateTime, String type, String inventoryGL) {
        Accounting_Reconciliation__c accReconcileRec =  new Accounting_Reconciliation__c();
        accReconcileRec.Reconciliation_Date__c = reconcileDateTime;
        accReconcileRec.Type__c = type;
        accReconcileRec.Number_of_BP_records__c = accReconcileRec.Blackpurl_Balance__c = accReconcileRec.Variance_Change__c = 0;
        if(String.isNotBlank(inventoryGL)) {
            accReconcileRec.GL_Account_ID__c = inventoryGL;
            accReconcileRec.GL_Account_Number__c = QBUtil.isQBEnabled() && accUniqueIdToGeneralAccountRecMap.containsKey(inventoryGL) ? accUniqueIdToGeneralAccountRecMap.get(inventoryGL).Account_Number__c : inventoryGL;
            accReconcileRec.GL_Account_Name__c = accUniqueIdToGeneralAccountRecMap.containsKey(inventoryGL) ? accUniqueIdToGeneralAccountRecMap.get(inventoryGL).Account_Name__c : null;
        }
        return accReconcileRec;
    }

    private Map<String, String> getAccountingNumberToActiveAccountingIdMap() {
    	Map<String, String> accountNumberToActiveAccIdMap = new Map<String, String>();
        if(String.isNotBlank(AccountingUtil.activeAccIntegrationName)) {
            for(General_Account__c generalAcc : [SELECT Accounting_Id__c, Account_Number__c from General_Account__c WHERE Is_Active__c = true LIMIT : SOQLUtil.getAvailableQueryRowsLimit()]) {
                accountNumberToActiveAccIdMap.put(generalAcc.Account_Number__c, generalAcc.Accounting_Id__c);
            }
        }
	    return accountNumberToActiveAccIdMap;
    }
    
    private Decimal getGLBalance(String inventoryGL, Map<String, Decimal> accountIdToNetIncomeMap, String reconciliationType) {
        Decimal glBalance;
        if(String.isNotBlank(inventoryGL)) {
            if(QBUtil.isQBEnabled()) {
                glBalance = accountIdToNetIncomeMap.containsKey(inventoryGL) ? accountIdToNetIncomeMap.get(inventoryGL) : 0;
            } else if(accNumberToActiveAccIdMap.containsKey(inventoryGL) && accountIdToNetIncomeMap.size() > 0) {
                String activeAccId = accNumberToActiveAccIdMap.get(inventoryGL);
                glBalance = accountIdToNetIncomeMap.containsKey(activeAccId) ? accountIdToNetIncomeMap.get(accNumberToActiveAccIdMap.get(inventoryGL)) : 0;
            }
        }
        if(glBalance != null && reconciliationType != null && (reconciliationType == DEPOSITS || reconciliationType == DEDUCTIBLE || reconciliationType == AP_INVENTORY || reconciliationType == STORE_CREDIT || reconciliationType == STOCKED_TRADE)) {
            if((reconciliationType == DEPOSITS || reconciliationType == DEDUCTIBLE) && !isNeedToMultiplyByMinusOne(inventoryGL, reconciliationType)) {
                return glBalance;
            }
            glBalance = glBalance * -1;
        }
        return glBalance;
    }

    private Boolean isNeedToMultiplyByMinusOne(String inventoryGL, String reconciliationType) {
        Boolean isNeedToMultiplyByMinusOne = (reconciliationType == DEDUCTIBLE ? true : false);
        List<General_Account__c> generalAccountList = [SELECT Id, Account_Type__c FROM General_Account__c WHERE Account_Number__c = :inventoryGL AND Is_Active__c = true LIMIT 1];
        if(!QBUtil.isQBEnabled() && !generalAccountList.isEmpty()) {
        	// Multiply by -1 if the org has Xero integration AND the customer deposits GL account in Xero has an account type of Current Liability when storing it in the Accounting Reconciliation record.
            if(reconciliationType == DEPOSITS && generalAccountList[0].Account_Type__c == 'CURRLIAB') {
            	isNeedToMultiplyByMinusOne = true;
            } else if(reconciliationType == DEDUCTIBLE && generalAccountList[0].Account_Type__c == 'CURRENT') {
                isNeedToMultiplyByMinusOne = false;
            }
        }
        return isNeedToMultiplyByMinusOne;
    }

    private Map<String, General_Account__c> getGLNumToGeneralAccountRecMap() {
		Map<String, General_Account__c> accountingUniqueIdToGeneralAccountRecMap = new Map<String, General_Account__c>();
        if(String.isNotBlank(AccountingUtil.activeAccIntegrationName)) {
            for(General_Account__c genAccRec : [Select Accounting_Id__c, Account_Number__c, Account_Name__c From General_Account__c Where Accounting_Id__c != null]) {
                if(QBUtil.isQBEnabled()) {
                    accountingUniqueIdToGeneralAccountRecMap.put(genAccRec.Accounting_Id__c, genAccRec);
                } else {
                    accountingUniqueIdToGeneralAccountRecMap.put(genAccRec.Account_Number__c, genAccRec);
                }
            }
        }
		return accountingUniqueIdToGeneralAccountRecMap;
	}

    private void setVarianceChange(Accounting_Reconciliation__c accReconcileRec) {
        List<Accounting_Reconciliation__c> recList = [SELECT Variance__c FROM Accounting_Reconciliation__c WHERE 
                                                        Reconciliation_Date__c = YESTERDAY AND Type__c =: accReconcileRec.Type__c AND 
                                                        GL_Account_ID__c =: accReconcileRec.GL_Account_ID__c AND GL_Account_Number__c =: accReconcileRec.GL_Account_Number__c Order By CreatedDate DESC];
        Accounting_Reconciliation__c prevDayReconciliationRec = new Accounting_Reconciliation__c();
        if(!recList.isEmpty()) {
            prevDayReconciliationRec = recList[0];
        }
        accReconcileRec.Blackpurl_Balance__c = accReconcileRec.Blackpurl_Balance__c != null ? accReconcileRec.Blackpurl_Balance__c.setScale(2, RoundingMode.HALF_UP) : 0;
        accReconcileRec.GL_Balance__c = accReconcileRec.GL_Balance__c != null ? accReconcileRec.GL_Balance__c.setScale(2, RoundingMode.HALF_UP) : 0;
        Decimal currVariance = accReconcileRec.Blackpurl_Balance__c - accReconcileRec.GL_Balance__c;
        accReconcileRec.Variance_Change__c = (currVariance - (prevDayReconciliationRec.Variance__c != null ? prevDayReconciliationRec.Variance__c : 0)).setScale(2, RoundingMode.HALF_UP);
    }
}