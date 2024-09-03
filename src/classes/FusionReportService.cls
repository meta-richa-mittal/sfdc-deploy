/**
 * Author: Tarun Khandelwal
 * Since: August 23, 2018
 * Name: FusionReportService
 * Description: Service class for Fusion Report Ctrl
**/
public without sharing class FusionReportService {
    
    private static String QB_TOTOL_ASSETS = 'total assets';
    private static String XERO_TOTOL_ASSETS = 'total assets';
    
    private static String QB_NET_INCOME = 'net earnings';
    private static String QB_TOTAL_EXPENSES = 'total expenses';
    private static String XERO_NET_INCOME = 'net profit';
    private static String XERO_TOTAL_EXPENSES = 'total operating expenses';
    
    // Line 1
    public static void getBalanceSheet(String month, String year) {
        String totalAssets = (QBUtil.isQBEnabled()) ? QB_TOTOL_ASSETS : XERO_TOTOL_ASSETS;
        getBalanceSheetFromAccountingIntegration(month, year, totalAssets);
    }
    
    public static void getBalanceSheetFromAccountingIntegration(String month, String year, String totalAsset) {
        Boolean isQBEnable = QBUtil.isQBEnabled();
        List<IFW_IntegrationConfig__c> integrationConfigList;
        if(isQBEnable) {
            integrationConfigList = IFW_SOQLUtil.getIntegrationConfigWithItems(QBUtil.QUICKBOOKS_ONLINE, null);
            if(integrationConfigList.isEmpty()) throw new BlackpurlException(QBUtil.QUICKBOOKS_ONLINE + ' config is not defined');    
        }
        Map<String, Decimal> objKeyToNetIncomeMap;
        Map<String, Decimal> objKeyToNetIncomeYearlyMap;
        try {
            objKeyToNetIncomeMap = getReportData(month, year, true, 'BalanceSheet', new Set<String>{totalAsset}, integrationConfigList);
            objKeyToNetIncomeYearlyMap = getReportData(month, year, false, 'BalanceSheet', new Set<String>{totalAsset}, integrationConfigList);
        } catch(Exception e) {}

        if(!isQBEnable && XeroUtility.isXeroEnabled()) {
        	integrationConfigList = BaseIntegration.getParentByName('Xero');
        	if(integrationConfigList.size() > 0) {
        		if(XeroFusionReportService.accessToken != null) integrationConfigList[0].Access_Token__c = XeroFusionReportService.accessToken;
        		if(XeroFusionReportService.refreshToken != null) integrationConfigList[0].Refresh_Token__c = XeroFusionReportService.refreshToken;
        		update integrationConfigList;
        	}
        }  else if(isQBEnable){
            QBCalloutManager.updateRecords(integrationConfigList[0]);
        }
        
        List<Fusion_Report_Line_Item__c> fusionLineItemList = FusionSOQLUtil.getFusionLineItemsByOrderNumber(new List<Integer>{1});
        if(fusionLineItemList.size() > 0) {
            fusionLineItemList[0].Monthly_Value__c = objKeyToNetIncomeMap.containsKey(totalAsset) ? objKeyToNetIncomeMap.get(totalAsset) : 0;
            fusionLineItemList[0].Yearly_Value__c = objKeyToNetIncomeYearlyMap.containsKey(totalAsset) ? objKeyToNetIncomeYearlyMap.get(totalAsset) : 0;
            update fusionLineItemList;
        }
    }
    
    // Line 2 and 3
    public static void getProfitAndLoss(String month, String year) {
        String netIncome = (QBUtil.isQBEnabled()) ? QB_NET_INCOME : XERO_NET_INCOME;
        String totalExpenses = (QBUtil.isQBEnabled()) ? QB_TOTAL_EXPENSES : XERO_TOTAL_EXPENSES;
        getProfitAndLossFromAccountingIntegration(month, year, netIncome, totalExpenses);
    }
    
    public static void getProfitAndLossFromAccountingIntegration(String month, String year, String netIncome, String totalExpenses) {
        Boolean isQBEnable = QBUtil.isQBEnabled();
        List<IFW_IntegrationConfig__c> integrationConfigList;
        if(isQBEnable) {
            integrationConfigList = IFW_SOQLUtil.getIntegrationConfigWithItems(QBUtil.QUICKBOOKS_ONLINE, null);
            if(integrationConfigList.isEmpty()) throw new BlackpurlException(QBUtil.QUICKBOOKS_ONLINE + ' config is not defined');    
        }
        Map<String, Decimal> objKeyToNetIncomeMap;
        Map<String, Decimal> objKeyToNetIncomeYearlyMap;
        try {
            objKeyToNetIncomeMap = getReportData(month, year, true, 'ProfitAndLoss', new Set<String>{netIncome, totalExpenses}, integrationConfigList);
            objKeyToNetIncomeYearlyMap = getReportData(month, year, false, 'ProfitAndLoss', new Set<String>{netIncome, totalExpenses}, integrationConfigList);    
        } catch(Exception e) {}

        if(!isQBEnable && XeroUtility.isXeroEnabled()) {
        	integrationConfigList = BaseIntegration.getParentByName('Xero');
        	if(integrationConfigList.size() > 0) {
        		if(XeroFusionReportService.accessToken != null) integrationConfigList[0].Access_Token__c = XeroFusionReportService.accessToken;
        		if(XeroFusionReportService.refreshToken != null) integrationConfigList[0].Refresh_Token__c = XeroFusionReportService.refreshToken;
        		update integrationConfigList;
        	}
        } else if(isQBEnable){
            QBCalloutManager.updateRecords(integrationConfigList[0]);
        }
        
        List<Fusion_Report_Line_Item__c> fusionLineItemList = FusionSOQLUtil.getFusionLineItemsByOrderNumber(new List<Integer>{2, 3});
        for(Fusion_Report_Line_Item__c fusionLineItemRec : fusionLineItemList) {
            if(fusionLineItemRec.HDNet_Account__c == 'Net Profit') {
                fusionLineItemRec.Monthly_Value__c = objKeyToNetIncomeMap.containsKey(netIncome) ? objKeyToNetIncomeMap.get(netIncome) : 0;
                fusionLineItemRec.Yearly_Value__c = objKeyToNetIncomeYearlyMap.containsKey(netIncome) ? objKeyToNetIncomeYearlyMap.get(netIncome) : 0;
            } else if(fusionLineItemRec.HDNet_Account__c == 'Total Dealership Expense') {
                fusionLineItemRec.Monthly_Value__c = objKeyToNetIncomeMap.containsKey(totalExpenses) ? objKeyToNetIncomeMap.get(totalExpenses) : 0;
                fusionLineItemRec.Yearly_Value__c = objKeyToNetIncomeYearlyMap.containsKey(totalExpenses) ? objKeyToNetIncomeYearlyMap.get(totalExpenses) : 0;
            }
        }
        if(fusionLineItemList.size() > 0) {
            update fusionLineItemList;
        }
    }
    
    // Other Integration Line item - 46 line items
    public static void getOtherAccountInfo(String month, String year) {
        String activeAccountingIntegration = IntegrationServiceFactory.getActiveAccountingIntegrationName();
        List<Fusion_Report_Line_Item__c> fusionLineItemList = FusionSOQLUtil.getFusionLienItem(new Map<String, String>{'Source__c' => activeAccountingIntegration});
        Map<String, Decimal> GLAccountNameToAmountMap = getAccountsInfo(month, year, true);
        updateAccountsInfoInBP(fusionLineItemList, GLAccountNameToAmountMap, true);
    }
    
    public static void getOtherAccountInfo_Yearly(String month, String year) {
        String activeAccountingIntegration = IntegrationServiceFactory.getActiveAccountingIntegrationName();
        List<Fusion_Report_Line_Item__c> fusionLineItemList = FusionSOQLUtil.getFusionLienItem(new Map<String, String>{'Source__c' => activeAccountingIntegration});
        Map<String, Decimal> GLAccountNameToAmountMap = getAccountsInfo(month, year, false);
        updateAccountsInfoInBP(fusionLineItemList, GLAccountNameToAmountMap, false);
    }
    
    private static Map<String, Decimal> getAccountsInfo(String month, String year, Boolean isMonthly) {
        String startDate = getStartDateForMonth(month, year, isMonthly);
        String endDate = getEndDateForMonth(month, year);
        Map<String, Decimal> glAccountNameToAmountMap = new Map<String, Decimal>();
        
        if(QBUtil.isQBEnabled()) {
            glAccountNameToAmountMap = getAccountsInfoQB(startDate, endDate);
        } else {
            glAccountNameToAmountMap = XeroFusionReportService.getReportData(startDate, endDate, 'ProfitAndLoss', new Set<String>());
            if(XeroUtility.isXeroEnabled()) {
	        	List<IFW_IntegrationConfig__c> integrationConfigList = BaseIntegration.getParentByName('Xero');
	        	if(integrationConfigList.size() > 0) {
	        		if(XeroFusionReportService.accessToken != null) integrationConfigList[0].Access_Token__c = XeroFusionReportService.accessToken;
	        		if(XeroFusionReportService.refreshToken != null) integrationConfigList[0].Refresh_Token__c = XeroFusionReportService.refreshToken;
	        		update integrationConfigList;
	        	}
	        }
        }
        return glAccountNameToAmountMap;
    }
    
    private static Map<String, Decimal> getAccountsInfoQB(String startDate, String endDate) {
        Map<String, Decimal> GLAccountNameToAmountMap = new Map<String, Decimal>();
        List<IFW_IntegrationConfig__c> integrationConfigList = IFW_SOQLUtil.getIntegrationConfigWithItems(QBUtil.QUICKBOOKS_ONLINE, null);
        if(integrationConfigList.isEmpty()) throw new BlackpurlException(QBUtil.QUICKBOOKS_ONLINE + ' config is not defined');
        try {
            QBReportWrapper responseObj = QBCalloutManager.getReportData('ProfitAndLoss?start_date='+startDate+'&end_date='+endDate , integrationConfigList[0]);
        if(responseObj != null && responseObj.Rows != null && responseObj.Rows.Row != null) {
            for(QBReportWrapper.cls_Row rowObj : responseObj.Rows.Row) {
                setColData(rowObj, GLAccountNameToAmountMap);
            }
        }
        } catch(Exception e) {}
        QBCalloutManager.updateRecords(integrationConfigList[0]);
        return GLAccountNameToAmountMap;
    }
    
    private static void setColData(QBReportWrapper.cls_Row rowObj, Map<String, Decimal> GLAccountNameToAmountMap) {
    	if(rowObj.Rows != null) {
            for(QBReportWrapper.cls_Row innerRowObj : rowObj.Rows.Row) {
                if(innerRowObj.ColData != null && innerRowObj.ColData.size() > 1) {
                    Decimal amount = (String.isNotBlank(innerRowObj.ColData[1].value) ? Decimal.valueOf(innerRowObj.ColData[1].value) : 0);
                    GLAccountNameToAmountMap.put(innerRowObj.ColData[0].value, amount);
                } else {
                    setColData(innerRowObj, GLAccountNameToAmountMap);
                }
            }
        }
    }
    
    private static void updateAccountsInfoInBP(List<Fusion_Report_Line_Item__c> fusionLineItemList, Map<String, Decimal> GLAccountNameToAmountMap,
                                                Boolean isMonthly) {
        for(Fusion_Report_Line_Item__c fusionLineItemRec : fusionLineItemList) {
            if(fusionLineItemRec.Order_Number__c != 1 && fusionLineItemRec.Order_Number__c != 2 && fusionLineItemRec.Order_Number__c != 3) {
                Decimal amount = 0;
                for(Fusion_Line_Item_To_GL_Account_Junction__c junctionRec : fusionLineItemRec.Fusion_Line_Item_To_GL_Account_Junctions__r) {
                    String uniqueKey = (junctionRec.General_Account__r.Account_Number__c != null ? junctionRec.General_Account__r.Account_Number__c + ' ' : '') +
                                (junctionRec.General_Account__r.Account_Name__c != null ? junctionRec.General_Account__r.Account_Name__c : ''); 
                    if(GLAccountNameToAmountMap.containsKey(uniqueKey)) {
                        amount += GLAccountNameToAmountMap.get(uniqueKey);
                    } else if(junctionRec.General_Account__r.Account_Name__c != null) {
	                    if(GLAccountNameToAmountMap.containsKey(junctionRec.General_Account__r.Account_Name__c.toLowerCase())) {
	                        amount += GLAccountNameToAmountMap.get(junctionRec.General_Account__r.Account_Name__c.toLowerCase());
	                    }
                    }
                }
                if(isMonthly) {
                    fusionLineItemRec.Monthly_Value__c = amount;
                } else {
                    fusionLineItemRec.Yearly_Value__c = amount;
                }
            }
        }
        if(fusionLineItemList.size() > 0) {
            update fusionLineItemList;
        }
    }
    
    // BlackPurl Data
    public static String populateBlackpurlData(String month, String year) {
        List<Fusion_Report_Line_Item__c> fusionLineItemList = FusionSOQLUtil.getFusionLienItem(new Map<String, String>{'Source__c' => 'Blackpurl'});
        Map<Integer, Set<String>> orderNumberToSetOfMappedGLsIdMap = new Map<Integer, Set<String>>();
        
        Map<Integer, Decimal> orderNumberToMontlyAmountMap = new Map<Integer, Decimal>();
        Map<Integer, Decimal> orderNumberToYearlyAmountMap = new Map<Integer, Decimal>();
        
        Date monthStartDate = getStartDateForMonth_BP(month, year);
        Date monthEndDate = getEndDateForMonth_BP(month, year);
        
        Date yearStartDate = getStartDateForYear_BP(year);
        Date yearEndDate = monthEndDate;
        
        for(Fusion_Report_Line_Item__c fusionLineItemRec : fusionLineItemList) {
            if(!orderNumberToSetOfMappedGLsIdMap.containsKey(Integer.valueOf(fusionLineItemRec.Order_Number__c))) {
                orderNumberToSetOfMappedGLsIdMap.put(Integer.valueOf(fusionLineItemRec.Order_Number__c), new Set<String>{});
            }
            for(Fusion_Line_Item_To_GL_Account_Junction__c junctionRec : fusionLineItemRec.Fusion_Line_Item_To_GL_Account_Junctions__r) {
            	if(QBUtil.isQBEnabled()) {
                	orderNumberToSetOfMappedGLsIdMap.get(Integer.valueOf(fusionLineItemRec.Order_Number__c)).add(junctionRec.General_Account__r.Accounting_Id__c);
            	} else {
            		orderNumberToSetOfMappedGLsIdMap.get(Integer.valueOf(fusionLineItemRec.Order_Number__c)).add(junctionRec.General_Account__r.Account_Number__c);
            	}
            }
            orderNumberToMontlyAmountMap.put(Integer.valueOf(fusionLineItemRec.Order_Number__c), 0);
            orderNumberToYearlyAmountMap.put(Integer.valueOf(fusionLineItemRec.Order_Number__c), 0);
        }
        
        // Line 11
        List<Customer_Owned_Unit__c> unitList = [SELECT Id , (SELECT Id, Total_Cost__c FROM Unit_Prices_Costs__r 
                                                                    WHERE (Adjustment_Date__c <: monthEndDate ) OR (Type__c = 'Base' AND Adjustment_Date__c = null)  
                                                                    OR (Type__c = 'Dealer' AND CreatedDate <:  monthEndDate )) 
                                                    FROM Customer_Owned_Unit__c 
                    WHERE (Status__c = 'Available' OR Status__c = 'Reserved') AND 
                    Category__r.Inventory_GL__c IN: orderNumberToSetOfMappedGLsIdMap.get(11) AND 
                    New_Unit__c = false AND Date_Stocked_In__c <= : monthEndDate];
        Decimal totalCost = 0;
        for(Customer_Owned_Unit__c unit : unitList) {
            for(Unit_Price_Cost__c unitPriceCost : unit.Unit_Prices_Costs__r) {
                totalCost += unitPriceCost.Total_Cost__c != null ? unitPriceCost.Total_Cost__c : 0;
            }
        }
        orderNumberToMontlyAmountMap.put(11, totalCost);
        orderNumberToYearlyAmountMap.put(11, totalCost);
        
        // Line 12
        unitList = [SELECT Id, (SELECT Id, Total_Cost__c FROM Unit_Prices_Costs__r 
                                WHERE (Adjustment_Date__c <: monthEndDate ) OR (Type__c = 'Base' AND Adjustment_Date__c = null)  
                                OR (Type__c = 'Dealer' AND CreatedDate <:  monthEndDate )) 
                    FROM Customer_Owned_Unit__c 
                    WHERE (Status__c = 'Available' OR Status__c = 'Reserved')
                    AND Category__r.Inventory_GL__c IN: orderNumberToSetOfMappedGLsIdMap.get(12) AND 
                    New_Unit__c = True AND Date_Stocked_In__c <= : monthEndDate];
        totalCost = 0;
        for(Customer_Owned_Unit__c unit : unitList) {
            for(Unit_Price_Cost__c unitPriceCost : unit.Unit_Prices_Costs__r) {
                totalCost += unitPriceCost.Total_Cost__c != null ? unitPriceCost.Total_Cost__c : 0;
            }
        }
        orderNumberToMontlyAmountMap.put(12, totalCost);
        orderNumberToYearlyAmountMap.put(12, totalCost);
        
        // Line 27 to 32 - New units
        // Line 39 - Used Units
        // Line 35, 36, 41, 42 - Parts & Labor Options
        List<Deal_Item__c> dealItemList = 
            [SELECT Customer_Owned_Unit__r.Category__r.Inventory_GL__c, Customer_Owned_Unit__r.New_Unit__c, 
                    Deal__r.Invoice_Number__r.Invoice_Date_Formula__c, Part_Total__c, Labour_Total__c FROM Deal_Item__c 
                WHERE Customer_Owned_Unit__r.Unit_Type__c = 'STOCK' AND
                      Customer_Owned_Unit__r.Status__c = 'Sold' AND
                      Customer_Owned_Unit__r.Category__c != null AND 
                      Deal__r.Invoice_Number__r.Invoice_Date_Formula__c >= : yearStartDate AND
                      Deal__r.Invoice_Number__r.Invoice_Date_Formula__c <= : yearEndDate];
        
        for(Deal_Item__c dealItemRec : dealItemList) {
            Date invoiceDate = dealItemRec.Deal__r.Invoice_Number__r.Invoice_Date_Formula__c;
            if(invoiceDate != null) {
                dealItemRec.Part_Total__c = dealItemRec.Part_Total__c != null ? dealItemRec.Part_Total__c : 0;
                dealItemRec.Labour_Total__c = dealItemRec.Labour_Total__c != null ? dealItemRec.Labour_Total__c : 0;
                String inventoryGL = dealItemRec.Customer_Owned_Unit__r.Category__r.Inventory_GL__c;
                if(dealItemRec.Customer_Owned_Unit__r.New_Unit__c) {
                    //Unit
                    if(String.isNotBlank(inventoryGL)) {
                        for(Integer orderNumber : newSoldUnitOrderNumberList) {
                            if(orderNumberToSetOfMappedGLsIdMap.get(orderNumber).contains(inventoryGL)) {
                                if(invoiceDate >= monthStartDate && invoiceDate <= monthEndDate) {
                                    orderNumberToMontlyAmountMap.put(orderNumber, orderNumberToMontlyAmountMap.get(orderNumber) + 1);
                                }
                                orderNumberToYearlyAmountMap.put(orderNumber, orderNumberToYearlyAmountMap.get(orderNumber) + 1);
                            }
                        }
                    }
                    //Part & Labor for new units
                    if(invoiceDate >= monthStartDate && invoiceDate <= monthEndDate) {
                        orderNumberToMontlyAmountMap.put(35, orderNumberToMontlyAmountMap.get(35) + dealItemRec.Part_Total__c);
                        orderNumberToMontlyAmountMap.put(36, orderNumberToMontlyAmountMap.get(36) + dealItemRec.Labour_Total__c);
                    }
                    orderNumberToYearlyAmountMap.put(35, (orderNumberToYearlyAmountMap.get(35) + dealItemRec.Part_Total__c));
                    orderNumberToYearlyAmountMap.put(36, (orderNumberToYearlyAmountMap.get(36) + dealItemRec.Labour_Total__c));
                } else {
                	if(String.isNotBlank(inventoryGL) && orderNumberToSetOfMappedGLsIdMap.get(39).contains(inventoryGL)) {
	                    if(invoiceDate >= monthStartDate && invoiceDate <= monthEndDate) {
	                        orderNumberToMontlyAmountMap.put(39, orderNumberToMontlyAmountMap.get(39) + 1);             
	                    }
	                    orderNumberToYearlyAmountMap.put(39, orderNumberToYearlyAmountMap.get(39) + 1);
                	}
                    //Part & Labor for used units
                    if(invoiceDate >= monthStartDate && invoiceDate <= monthEndDate) {
                        orderNumberToMontlyAmountMap.put(41, orderNumberToMontlyAmountMap.get(41) + dealItemRec.Part_Total__c);
                        orderNumberToMontlyAmountMap.put(42, orderNumberToMontlyAmountMap.get(42) + dealItemRec.Labour_Total__c);
                    }
                    orderNumberToYearlyAmountMap.put(41, (orderNumberToYearlyAmountMap.get(41) + dealItemRec.Part_Total__c));
                    orderNumberToYearlyAmountMap.put(42, (orderNumberToYearlyAmountMap.get(42) + dealItemRec.Labour_Total__c));
                }
            }
        }
        
        // Line 81, 82
        dealItemList = [SELECT Deal__c, Deal__r.Type__c, Customer_Owned_Unit__r.New_Unit__c, Deal__r.Invoice_Number__r.Invoice_Date_Formula__c 
                            FROM Deal_Item__c 
                            WHERE Customer_Owned_Unit__c != null AND
                                  Customer_Owned_Unit__r.Unit_Type__c = 'STOCK' AND
                                  Deal__r.Type__c = 'Financed' AND
                                  Deal__r.Invoice_Number__c != null AND
                                  Deal__r.Invoice_Number__r.Invoice_Date_Formula__c >=: yearStartDate AND
                                  Deal__r.Invoice_Number__r.Invoice_Date_Formula__c <=: yearEndDate];
        
        Set<Id> newUnitDealSet = new Set<Id>();
        Set<Id> usedUnitDealSet = new Set<Id>();
        Set<Id> newUnitDealYearSet = new Set<Id>();
        Set<Id> usedUnitDealYearSet = new Set<Id>();
        for(Deal_Item__c dealItemRec : dealItemList) {
            Date invoiceDate = dealItemRec.Deal__r.Invoice_Number__r.Invoice_Date_Formula__c;
            if(invoiceDate != null) {
                if(dealItemRec.Customer_Owned_Unit__r.New_Unit__c) {
                    if(invoiceDate >= monthStartDate && invoiceDate <= monthEndDate) {
                        newUnitDealSet.add(dealItemRec.Deal__c);
                    }
                    newUnitDealYearSet.add(dealItemRec.Deal__c);
                } else if(!dealItemRec.Customer_Owned_Unit__r.New_Unit__c) {
                    if(invoiceDate >= monthStartDate && invoiceDate <= monthEndDate) {
                        usedUnitDealSet.add(dealItemRec.Deal__c);
                    }
                    usedUnitDealYearSet.add(dealItemRec.Deal__c);
                }
            }
        }
        orderNumberToMontlyAmountMap.put(81, newUnitDealSet.size());
        orderNumberToMontlyAmountMap.put(82, usedUnitDealSet.size());
        orderNumberToYearlyAmountMap.put(81, newUnitDealYearSet.size());
        orderNumberToYearlyAmountMap.put(82, usedUnitDealYearSet.size());
        
        // Line 86
        List<AggregateResult> dealFinanceAggregateList = 
                [SELECT SUM(Amount_Financed__c) AMOUNT from Deal__c
                    WHERE Type__c = 'Financed' AND
                          Invoice_Number__c != null AND
                          Invoice_Number__r.Invoice_Date_Formula__c >=: yearStartDate AND
                          Invoice_Number__r.Invoice_Date_Formula__c <=: yearEndDate];
        
        if(dealFinanceAggregateList.size() > 0) {
            Decimal amount = (dealFinanceAggregateList[0].get('AMOUNT') != null) ? (Decimal)dealFinanceAggregateList[0].get('AMOUNT') : 0;
            orderNumberToYearlyAmountMap.put(86, amount);
        }
        
        // Line 86
        dealFinanceAggregateList = [SELECT SUM(Amount_Financed__c) AMOUNT from Deal__c
                                    WHERE Type__c = 'Financed' AND
                                          Invoice_Number__c != null AND
                                          Invoice_Number__r.Invoice_Date_Formula__c >=: monthStartDate AND
                                          Invoice_Number__r.Invoice_Date_Formula__c <=: monthEndDate];
        
        if(dealFinanceAggregateList.size() > 0) {
            Decimal amount = (dealFinanceAggregateList[0].get('AMOUNT') != null) ? (Decimal)dealFinanceAggregateList[0].get('AMOUNT') : 0;
            orderNumberToMontlyAmountMap.put(86, amount);
        }
        
        // Line 69, 71
        List<AggregateResult> hoursLoggedAggregateList = 
                [SELECT SUM(Billed_Hours__c) BillHours, SUM(Calculated_Hours__c) CalculateHours FROM Hours_Logged__c 
                            WHERE Service_Order_Header__c != null AND 
                                  Start_Date_Time__c >=: monthStartDate AND Start_Date_Time__c <=: monthEndDate];
        
        if(hoursLoggedAggregateList.size() > 0) {
            if(hoursLoggedAggregateList[0].get('BillHours') != null) {
                Decimal totalHours = (hoursLoggedAggregateList[0].get('BillHours') != null) ? (Decimal)hoursLoggedAggregateList[0].get('BillHours') : 0;
                orderNumberToMontlyAmountMap.put(71, totalHours);
            }
            if(hoursLoggedAggregateList[0].get('CalculateHours') != null) {
                Decimal calHours = (hoursLoggedAggregateList[0].get('CalculateHours') != null) ? (Decimal)hoursLoggedAggregateList[0].get('CalculateHours') : 0;
                orderNumberToMontlyAmountMap.put(69, calHours);
            }
        }
        
        // Line 69, 71
        hoursLoggedAggregateList = [SELECT SUM(Billed_Hours__c) BillHours, SUM(Calculated_Hours__c) CalculateHours FROM Hours_Logged__c 
                                    WHERE Service_Order_Header__c != null AND 
                                          Start_Date_Time__c >=: yearStartDate AND Start_Date_Time__c <=: yearEndDate];
        
        if(hoursLoggedAggregateList.size() > 0) {
            if(hoursLoggedAggregateList[0].get('BillHours') != null) {
                Decimal totalHours = (hoursLoggedAggregateList[0].get('BillHours') != null) ? (Decimal)hoursLoggedAggregateList[0].get('BillHours') : 0;
                orderNumberToYearlyAmountMap.put(71, totalHours);
            }
            if(hoursLoggedAggregateList[0].get('CalculateHours') != null) {
                Decimal calHours = (hoursLoggedAggregateList[0].get('CalculateHours') != null) ? (Decimal)hoursLoggedAggregateList[0].get('CalculateHours') : 0;
                orderNumberToYearlyAmountMap.put(69, calHours);
            }
        }
                
        // Line 73
        List<AggregateResult> serviceJobAggregateList = 
                    [SELECT count(Id) TotalSO from Service_Order_Header__c 
                        WHERE Invoice_Number__c != null AND
                              Invoice_Number__r.Invoice_Date_Formula__c >=: monthStartDate AND 
                              Invoice_Number__r.Invoice_Date_Formula__c <=: monthEndDate];
        
        if(serviceJobAggregateList.size() > 0) {
            Decimal totalSO = (serviceJobAggregateList[0].get('TotalSO') != null) ? (Decimal)serviceJobAggregateList[0].get('TotalSO') : 0;
            orderNumberToMontlyAmountMap.put(73, totalSO);
        }
        
        serviceJobAggregateList = [SELECT count(Id) TotalSO from Service_Order_Header__c 
                                    WHERE Invoice_Number__c != null AND
                                          Invoice_Number__r.Invoice_Date_Formula__c >=: yearStartDate AND 
                                          Invoice_Number__r.Invoice_Date_Formula__c <=: yearEndDate];
        
        if(serviceJobAggregateList.size() > 0) {
            Decimal totalSO = (serviceJobAggregateList[0].get('TotalSO') != null) ? (Decimal)serviceJobAggregateList[0].get('TotalSO') : 0;
            orderNumberToYearlyAmountMap.put(73, totalSO);
        }
        return System.JSON.serialize(new FusionLineItemWrapper.LineItemValueWrapper(orderNumberToMontlyAmountMap, orderNumberToYearlyAmountMap));
    }
    
    private static Set<Integer> blackpurlDataLineItemSet2 = new Set<Integer>{65, 66, 67, 68, 70}; 
    
    public static String populateBlackpurlData2(String month, String year) {
        List<Fusion_Report_Line_Item__c> fusionLineItemList = FusionSOQLUtil.getFusionLienItem(new Map<String, String>{'Source__c' => 'Blackpurl'});
        Map<Integer, Set<String>> orderNumberToSetOfMappedGLsIdMap = new Map<Integer, Set<String>>();
        
        Map<Integer, Decimal> orderNumberToMontlyAmountMap = new Map<Integer, Decimal>();
        Map<Integer, Decimal> orderNumberToYearlyAmountMap = new Map<Integer, Decimal>();
        
        Date monthStartDate = getStartDateForMonth_BP(month, year);
        Date monthEndDate = getEndDateForMonth_BP(month, year);
        
        Date yearStartDate = getStartDateForYear_BP(year);
        Date yearEndDate = monthEndDate;
        
        for(Fusion_Report_Line_Item__c fusionLineItemRec : fusionLineItemList) {
            Integer orderNumber = Integer.valueOf(fusionLineItemRec.Order_Number__c);
            if(blackpurlDataLineItemSet2.contains(orderNumber)) {
                if(!orderNumberToSetOfMappedGLsIdMap.containsKey(orderNumber)) {
                    orderNumberToSetOfMappedGLsIdMap.put(orderNumber, new Set<String>{});
                }
                for(Fusion_Line_Item_To_GL_Account_Junction__c junctionRec : fusionLineItemRec.Fusion_Line_Item_To_GL_Account_Junctions__r) {
                    if(QBUtil.isQBEnabled()) {
                        orderNumberToSetOfMappedGLsIdMap.get(Integer.valueOf(orderNumber)).add(junctionRec.General_Account__r.Accounting_Id__c);
                    } else {
                        orderNumberToSetOfMappedGLsIdMap.get(Integer.valueOf(orderNumber)).add(junctionRec.General_Account__r.Account_Number__c);
                    }
                }
                orderNumberToMontlyAmountMap.put(orderNumber, 0);
                orderNumberToYearlyAmountMap.put(orderNumber, 0);
            }
        }
        
        // Line 65
        List<AggregateResult> partAggregateList = [SELECT SUM(Inventory_Valuation__c) AMOUNT from Part__c 
                                                        WHERE Part_Type__c = 'Part' AND
                                                        Inventory_Valuation__c != null AND Inventory_Valuation__c != 0 AND 
                                                        Category__r.Inventory_GL__c IN: orderNumberToSetOfMappedGLsIdMap.get(65)];
        if(partAggregateList.size() > 0) {
            Decimal amount = (partAggregateList[0].get('AMOUNT') != null) ? (Decimal)partAggregateList[0].get('AMOUNT') : 0;
            orderNumberToMontlyAmountMap.put(65, amount);
            orderNumberToYearlyAmountMap.put(65, amount);
        }
        
        // Line 66
        partAggregateList = [SELECT SUM(Inventory_Valuation__c) AMOUNT from Part__c
                                    WHERE Part_Type__c = 'Merchandise' AND
                                    Inventory_Valuation__c != null AND Inventory_Valuation__c != 0AND 
                                    Category__r.Inventory_GL__c IN: orderNumberToSetOfMappedGLsIdMap.get(66)];
        if(partAggregateList.size() > 0) {
            Decimal amount = (partAggregateList[0].get('AMOUNT') != null) ? (Decimal)partAggregateList[0].get('AMOUNT') : 0;
            orderNumberToMontlyAmountMap.put(66, amount);
            orderNumberToYearlyAmountMap.put(66, amount);
        }

        // Line 67, 68
        partAggregateList = [SELECT SUM(Total__c) AMOUNT FROM Part_FIFO_Bucket__c 
                                    WHERE Is_FIFO_Bucket__c = true AND Age__c > 365 AND Remaining_Qty__c > 0 AND Part__r.Part_Type__c = 'Part' AND 
                                    Part__r.Category__r.Inventory_GL__c IN: orderNumberToSetOfMappedGLsIdMap.get(67)];
        if(partAggregateList.size() > 0) {
            Decimal amount = (partAggregateList[0].get('AMOUNT') != null) ? (Decimal)partAggregateList[0].get('AMOUNT') : 0;
            orderNumberToMontlyAmountMap.put(67, amount);
            orderNumberToYearlyAmountMap.put(67, amount);
        }

        partAggregateList = [SELECT SUM(Total__c) AMOUNT FROM Part_FIFO_Bucket__c 
                                    WHERE Is_FIFO_Bucket__c = true AND Age__c > 365 AND Remaining_Qty__c > 0 AND Part__r.Part_Type__c = 'Merchandise' AND 
                                    Part__r.Category__r.Inventory_GL__c IN: orderNumberToSetOfMappedGLsIdMap.get(68)];
        if(partAggregateList.size() > 0) {
            Decimal amount = (partAggregateList[0].get('AMOUNT') != null) ? (Decimal)partAggregateList[0].get('AMOUNT') : 0;
            orderNumberToMontlyAmountMap.put(68, amount);
            orderNumberToYearlyAmountMap.put(68, amount);
        }
        
        // Line 70
        List<AggregateResult> payrollList = [SELECT SUM(Total_Time__c) WorkedHours from Payroll_Time__c 
                                                WHERE Technician__c != null AND
                                                      Payroll_Date__c >=: monthStartDate AND 
                                                      Payroll_Date__c <=: monthEndDate];
        
        if(payrollList.size() > 0) {
            Decimal workedHours = (payrollList[0].get('WorkedHours') != null) ? (Decimal)payrollList[0].get('WorkedHours') : 0;
            orderNumberToMontlyAmountMap.put(70, workedHours);
        }
        
        payrollList = [SELECT SUM(Total_Time__c) WorkedHours from Payroll_Time__c 
                            WHERE Technician__c != null AND
                                  Payroll_Date__c >=: yearStartDate AND 
                                  Payroll_Date__c <=: yearEndDate];
        
        if(payrollList.size() > 0) {
            Decimal workedHours = (payrollList[0].get('WorkedHours') != null) ? (Decimal)payrollList[0].get('WorkedHours') : 0;
            orderNumberToYearlyAmountMap.put(70, workedHours);
        }
        return System.JSON.serialize(new FusionLineItemWrapper.LineItemValueWrapper(orderNumberToMontlyAmountMap, orderNumberToYearlyAmountMap));
    }
    
    public static void saveFusionLineItemValues(String lineItemValuesJson) {
        FusionLineItemWrapper.LineItemValueWrapper lineItemValueWrapperObj = (FusionLineItemWrapper.LineItemValueWrapper) System.JSON.deserialize(lineItemValuesJson, FusionLineItemWrapper.LineItemValueWrapper.class);
        List<Fusion_Report_Line_Item__c> fusionLineItemList = FusionSOQLUtil.getFusionLienItem(new Map<String, String>{'Source__c' => 'Blackpurl'});
        for(Fusion_Report_Line_Item__c fusionLineItemRec : fusionLineItemList) {
            Integer orderNumber = Integer.valueOf(fusionLineItemRec.Order_Number__c);
            if(lineItemValueWrapperObj.OrderNumberToMontlyAmountMap.containsKey(orderNumber)) {
                fusionLineItemRec.Monthly_Value__c = lineItemValueWrapperObj.OrderNumberToMontlyAmountMap.get(orderNumber);
            }
            if(lineItemValueWrapperObj.OrderNumberToYearlyAmountMap.containsKey(orderNumber)) {
                fusionLineItemRec.Yearly_Value__c = lineItemValueWrapperObj.OrderNumberToYearlyAmountMap.get(orderNumber);
            }
        }
        
        if(fusionLineItemList.size() > 0) {
            update fusionLineItemList;
        }
    }
    
    private static List<Integer> newSoldUnitOrderNumberList = new List<Integer> {27, 28, 29, 30, 31, 32};
    
    public static void populateCalculatedData() {
        List<Fusion_Report_Line_Item__c> fusionLineItemList = FusionSOQLUtil.getFusionLienItem(new Map<String, String>{});
        Map<Integer, Fusion_Report_Line_Item__c> orderNumberToFusionLineItemMap = new Map<Integer, Fusion_Report_Line_Item__c>();
        for(Fusion_Report_Line_Item__c fusionLineItemRec : fusionLineItemList) {
            orderNumberToFusionLineItemMap.put(Integer.valueOf(fusionLineItemRec.Order_Number__c), fusionLineItemRec);
        }
        
        List<Fusion_Report_Line_Item__c> fusionLineItemListToUpdate = new List<Fusion_Report_Line_Item__c>();
        for(Integer orderNumber : calculatedValuesMap.keyset()) {
            Decimal monthlyAmount = 0;
            Decimal yearlyAmount = 0;
            for(Integer relatedOrderNumber : calculatedValuesMap.get(orderNumber)) {
                monthlyAmount += orderNumberToFusionLineItemMap.get(relatedOrderNumber).Monthly_Value__c;
                yearlyAmount += orderNumberToFusionLineItemMap.get(relatedOrderNumber).Yearly_Value__c;
            }
            Fusion_Report_Line_Item__c fusionRec = orderNumberToFusionLineItemMap.get(orderNumber);
            fusionRec.Monthly_Value__c = monthlyAmount;
            fusionRec.Yearly_Value__c = yearlyAmount;
            fusionLineItemListToUpdate.add(fusionRec);
        }
        
        if(fusionLineItemListToUpdate.size() > 0) {
            update fusionLineItemListToUpdate;
        }
    }
    
    
    private static Map<Integer, List<Integer>> calculatedValuesMap = new Map<Integer, List<Integer>> {
            19 => new List<Integer>{13, 14, 15, 16, 17, 18},
            26 => new List<Integer>{20, 21, 22, 23, 24, 25},
            33 => new List<Integer>{27, 28, 29, 30, 31, 32}
    };
    
    private static Map<String, Decimal> getReportData(String month, String year, Boolean isMonthly, String reportObject, Set<String> objKeyToFindSet, List<IFW_IntegrationConfig__c> integrationConfigList) {
        String startDate = getStartDateForMonth(month, year, isMonthly);
        String endDate = getEndDateForMonth(month, year);
        
        Map<String, Decimal> objKeyToAmountMap;
        if(QBUtil.isQBEnabled()) {
            QBReportWrapper responseObj = QBCalloutManager.getReportData(reportObject+'?start_date='+startDate+'&end_date='+endDate , integrationConfigList[0]);
            objKeyToAmountMap = parseResponse(responseObj, objKeyToFindSet);
        } else {
            objKeyToAmountMap = XeroFusionReportService.getReportData(startDate, endDate, reportObject, objKeyToFindSet);
        }
        return objKeyToAmountMap;
    }
    
    public static Map<String, Decimal> parseResponse(QBReportWrapper responseObj, Set<String> objKeyToFindSet) {
        Map<String, Decimal> objKetToAmountMap = new Map<String, Decimal>();
        if(responseObj != null && responseObj.Rows != null && responseObj.Rows.Row != null) {
            for(QBReportWrapper.cls_Row rowObj : responseObj.Rows.Row) {
                if(rowObj != null && rowObj.Summary != null && rowObj.Summary.ColData != null) {
                    List<QBReportWrapper.cls_ColData> colObjList = rowObj.Summary.ColData;
                    if(colObjList.size() > 1 && colObjList[0].value != null && objKeyToFindSet.contains(colObjList[0].value.toLowerCase())) {
                        objKetToAmountMap.put(colObjList[0].value.toLowerCase(), (String.isNotBlank(colObjList[1].value)) ? Decimal.valueof(colObjList[1].value) : 0);
                    }
                }
            }
        }
        return objKetToAmountMap;
    }
    
    private static Date getStartDateForMonth_BP(String month, String year) {
        return Date.newInstance(Integer.valueOf(year), monthsMap.get(month), 1);
    }
    
    private static Date getEndDateForMonth_BP(String month, String year) {
        return date.newinstance(Integer.valueOf(year), monthsMap.get(month), Date.daysInMonth(Integer.valueOf(year), monthsMap.get(month)));
    }
    
    private static Date getStartDateForYear_BP(String year) {
        return Date.newInstance(Integer.valueOf(year), 1, 1);
    }
    
    private static String getStartDateForMonth(String month, String year, Boolean isMonthly) {
        String startDateString;
        if(isMonthly) {
            startDateString = year + '-' + monthsMap.get(month) + '-' + '1';
        } else {
            startDateString = year + '-' + monthsMap.get('January') + '-' + '1';
        }
        return startDateString;
    }
    
    private static String getEndDateForMonth(String month, String year) {
        Integer numberDays = Date.daysInMonth(Integer.valueOf(year), monthsMap.get(month));
        return year + '-' + monthsMap.get(month) + '-' + String.valueOf(numberDays);
    }
    
    private static Map<String, Integer> monthsMap = new Map<String, Integer>{
       'January'  => 1,
       'February' => 2,
       'March' => 3,
       'April' => 4,
       'May' => 5,
       'June'  => 6,
       'July' => 7,
       'August' => 8,
       'September' => 9,
       'October' => 10,
       'November' => 11,
       'December' => 12
    };
}