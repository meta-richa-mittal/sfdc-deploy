@isTest
public class AccountingReconciliationSchedulerTest {
    @testSetup
    private static void setupTestData() {
        TestDataFactory.disableFLSChecks();

        Accounting_Default_Accounts__c defaultAccounts = Accounting_Default_Accounts__c.getOrgDefaults();
        defaultAccounts.A_P_Inventory_Accrual__c = defaultAccounts.Customer_Deposits__c = defaultAccounts.Store_Credit_Accrual__c = defaultAccounts.Deal_Option_Clearing__c = defaultAccounts.WIP_Labor_Inventory__c = '111';
        upsert defaultAccounts;
        
        General_Account__c genAcc1 = new General_Account__c(Is_Active__c = true);
        genAcc1.Accounting_Id__c = '111';
        genAcc1.Account_Name__c = 'BP Customer DepositsQA';
        genAcc1.Account_Number__c = '111';

        General_Account__c genAcc2 = new General_Account__c(Is_Active__c = true);
        genAcc2.Accounting_Id__c = '105';
        genAcc2.Account_Name__c = 'Westpac - EveryBusiness';
        genAcc2.Account_Number__c = '105';
        insert new List<General_Account__c>{genAcc1, genAcc2};

        Account vendor = TestUtil.createVendor(true, 'Test Vendor');
        Category__c partCategory = TestUtil.createCategory(false, 'Part Cat', 'Part', 'Cat Desc', true, true);
        Category__c UnitCategory = TestUtil.createCategory(false, 'Unit Cat', 'Unit', 'Cat Desc', true, true);
        Category__c stCategory = TestUtil.createCategory(false, 'Stocked Trade', 'Stocked Trade', 'Cat Desc', true, true);
        Category__c deductibleCategory = TestUtil.createCategory(false, 'Deductible', 'Deductible', 'Cat Desc', true, true);
        partCategory.Inventory_GL__c = UnitCategory.Inventory_GL__c = stCategory.Income_GL__c = deductibleCategory.Income_GL__c = '105';
        insert new List<Category__c>{partCategory,UnitCategory,stCategory,deductibleCategory};

        Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(true, 'Default Price Level', 'Cost', 10 , true, true);
        
        Part__c part = TestUtil.createPart(true, 'part', vendor.Id, 'Test Part', partCategory.Id, 10, 20, 50, 100, 100);
        
        Account customer =  TestUtil.createCustomer(true, 'customerName', 'abc@abc.com', 'jaipur', '1111111111', null, null, false, true,'Individual');
        Store_Credit__c storecreditRec = new Store_Credit__c();
        storecreditRec.Customer__c = customer.Id;
        storecreditRec.Amount__c = 10000;
        insert storecreditRec;

        Unit_Make__c unitmake = TestUtil.createUnitMake(true, 'unitMakeName', '12A', true);
        Unit_Model__c unitmodel = TestUtil.createUnitModel(true, 'unitModelName', '12A', true, unitMake.Id);
        Customer_Owned_Unit__c customerOwnedUnit = TestUtil.createCustomerOwnedUnit(false, customer.Id, UnitMake.Id, UnitModel.Id, null);
        customerOwnedUnit.Unit_Type__c = 'Stock';
        customerOwnedUnit.Status__c = 'Available';
        insert customerOwnedUnit;

        Unit_Price_Cost__c unitPriceAndCostRec = new Unit_Price_Cost__c();
        unitPriceAndCostRec.Customer_Owned_Unit__c = customerOwnedUnit.Id;
        unitPriceAndCostRec.Type__c = 'Base';
        unitPriceAndCostRec.Total_Price__c = 100;
        unitPriceAndCostRec.Total_Cost__c = 100;
        unitPriceAndCostRec.Item_Description__c = 'ItemDesc';
        insert unitPriceAndCostRec;
        
        CO_Header__c coHeader = new CO_Header__c(CO_Type__c='Customer', Selling_Group__c='Unit Deal', Customer__c=customer.Id);
        insert coHeader;
        DealService.createDeal(BPUtility.getEncodedString(coHeader.Id));
        List<Deal__c> dealList = [Select id from Deal__c where CO_Header__c = :coHeader.Id];
        CO_Line_Item__c coli = new CO_Line_Item__c(Part__c = part.Id, CO_Header__c = coHeader.Id, Deal__c = dealList[0].Id);
        insert coli;
    }
    
    static testMethod void testScheduler() {
        Test.startTest();
            String cronExp = '0 0 22 ? * * *';
            system.schedule('TestAccountingReconciliationScheduler', cronExp, new AccountingReconciliationScheduler());
        Test.stopTest();
    }

    static testMethod void testQBScheduler() {
        TestUtil.setQuickBooksConfigurations(false);
        Accounting_Settings__c config = Accounting_Settings__c.getOrgDefaults();
        config.Provider_Name__c = 'Quickbooks Online';
        upsert config;

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Test.startTest();
            String cronExp = '0 0 22 ? * * *';
            system.schedule('TestAccountingReconciliationScheduler', cronExp, new AccountingReconciliationScheduler());
        Test.stopTest();
    }

    public class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"Header":{"Time":"2022-04-27T23:49:29-07:00","ReportName":"BalanceSheet","ReportBasis":"Accrual","StartPeriod":"2022-04-28","EndPeriod":"2022-04-28","SummarizeColumnsBy":"Total","Currency":"AUD","Option":[{"Name":"AccountingStandard","Value":"PE"},{"Name":"NoReportData","Value":"false"}]},"Columns":{"Column":[{"ColTitle":"","ColType":"Account","MetaData":[{"Name":"ColKey","Value":"account"}]},{"ColTitle":"Total","ColType":"Money","MetaData":[{"Name":"ColKey","Value":"total"}]}]},"Rows":{"Row":[{"Header":{"ColData":[{"value":"Assets"},{"value":""}]},"Rows":{"Row":[{"Header":{"ColData":[{"value":"Current Assets"},{"value":""}]},"Rows":{"Row":[{"Header":{"ColData":[{"value":"Accounts receivable"},{"value":""}]},"Rows":{"Row":[{"ColData":[{"value":"Accounts Receivable (AR)","id":"95"},{"value":"282136.17"}],"type":"Data"},{"ColData":[{"value":"MyJobs_test","id":"198"},{"value":"326.00"}],"type":"Data"}]},"Summary":{"ColData":[{"value":"Total Accounts receivable"},{"value":"282462.17"}]},"type":"Section","group":"AssetsReceivable"},{"ColData":[{"value":"BP Customer DepositsQA","id":"111"},{"value":"-1308566.11"}],"type":"Data"},{"ColData":[{"value":"Cash and cash equivalents","id":"13"},{"value":"46110.46"}],"type":"Data"},{"ColData":[{"value":"Westpac - EveryBusiness","id":"105"},{"value":"-1375.00"}],"type":"Data"},{"ColData":[{"value":"AP Inventory Accrual","id":"32"},{"value":"1083350.39"}],"type":"Data"},{"ColData":[{"value":"BP New Unit InventoryQA1","id":"118"},{"value":"112116.55"}],"type":"Data"},{"ColData":[{"value":"BP New Unit InventoryQA2","id":"119"},{"value":"-1040906.14"}],"type":"Data"},{"ColData":[{"value":"BP New Unit InventoryQA3","id":"120"},{"value":"-776.96"}],"type":"Data"},{"ColData":[{"value":"BP Parts InventoryQA1","id":"112"},{"value":"2234622.84"}],"type":"Data"},{"ColData":[{"value":"BP Parts InventoryQA2","id":"113"},{"value":"180.00"}],"type":"Data"},{"ColData":[{"value":"BP Used Unit InventoryQA1","id":"121"},{"value":"-16726.67"}],"type":"Data"},{"ColData":[{"value":"BP Used Unit InventoryQA2","id":"122"},{"value":"-19271.02"}],"type":"Data"},{"ColData":[{"value":"Customer Deposits","id":"108"},{"value":"72063.48"}],"type":"Data"},{"ColData":[{"value":"Harley-Davidson Dyna - Inventory","id":"196"},{"value":"9104140.40"}],"type":"Data"},{"ColData":[{"value":"Harley-Davidson Dyna - Inventory F","id":"197"},{"value":"92.17"}],"type":"Data"},{"ColData":[{"value":"Inventory","id":"87"},{"value":"7709.70"}],"type":"Data"},{"ColData":[{"value":"Inventory Asset","id":"199"},{"value":"1682.05"}],"type":"Data"},{"ColData":[{"value":"Inventory GL","id":"110"},{"value":"8405702302.45"}],"type":"Data"},{"ColData":[{"value":"Prepaid expenses","id":"50"},{"value":"36363.64"}],"type":"Data"},{"ColData":[{"value":"Testing Active Account","id":"190"},{"value":"40308.37"}],"type":"Data"},{"ColData":[{"value":"Uncategorised Asset","id":"100"},{"value":"38.09"}],"type":"Data"},{"ColData":[{"value":"Undeposited PIN Payment","id":"124"},{"value":"14644.73"}],"type":"Data"},{"ColData":[{"value":"Undeposited Webstore","id":"7"},{"value":"100913.54"}],"type":"Data"},{"ColData":[{"value":"WIP Labor Expense","id":"117"},{"value":"-107630.10"}],"type":"Data"},{"ColData":[{"value":"WIP Labor Inventory","id":"116"},{"value":"-31259.08"}],"type":"Data"}]},"Summary":{"ColData":[{"value":"Total Current Assets"},{"value":"8416312589.95"}]},"type":"Section","group":"TotalAssetLessCurrentLiabilities"},{"Header":{"ColData":[{"value":"Long-term assets"},{"value":""}]},"Rows":{"Row":[{"ColData":[{"value":"Accumulated depreciation on property, plant and equipment","id":"6"},{"value":"-399.96"}],"type":"Data"},{"ColData":[{"value":"BP Labor InventoryQA1","id":"115"},{"value":"14240.95"}],"type":"Data"},{"ColData":[{"value":"Furniture and Equipment","id":"78"},{"value":"2750.00"}],"type":"Data"}]},"Summary":{"ColData":[{"value":"Total long-term assets"},{"value":"16590.99"}]},"type":"Section","group":"TotalLongTermAssets"}]},"Summary":{"ColData":[{"value":"Total Assets"},{"value":"8416329180.94"}]},"type":"Section","group":"NetAssets"},{"Header":{"ColData":[{"value":"Liabilities and shareholders equity"},{"value":""}]},"Rows":{"Row":[{"Header":{"ColData":[{"value":"Current liabilities:"},{"value":""}]},"Rows":{"Row":[{"Header":{"ColData":[{"value":"Accounts payable"},{"value":""}]},"Rows":{"Row":[{"ColData":[{"value":"Accounts Payable (AP) - HKD","id":"91"},{"value":"0.00"}],"type":"Data"},{"ColData":[{"value":"Accounts Payable (Rohit)","id":"92"},{"value":"136348310.33"}],"type":"Data"}]},"Summary":{"ColData":[{"value":"Total Accounts payable"},{"value":"136348310.33"}]},"type":"Section","group":"AccountsPayable"},{"ColData":[{"value":"Visa Credit Card","id":"86"},{"value":"8135.92"}],"type":"Data"},{"ColData":[{"value":"Accrued liabilities","id":"4"},{"value":"-551279.42"}],"type":"Data"},{"ColData":[{"value":"BP Sublet AccrualQA1","id":"131"},{"value":"-320.00"}],"type":"Data"},{"ColData":[{"value":"BP Sublet AccrualQA2","id":"132"},{"value":"-210381.19"}],"type":"Data"},{"ColData":[{"value":"BP Sublet COGS_QA2","id":"170"},{"value":"421236.44"}],"type":"Data"},{"ColData":[{"value":"BP Unit COGS_QA3","id":"165"},{"value":"-949130.80"}],"type":"Data"},{"ColData":[{"value":"BP Unit SalesQA3","id":"140"},{"value":"4910.14"}],"type":"Data"},{"ColData":[{"value":"Claim Deductible Clearing","id":"134"},{"value":"-2090.60"}],"type":"Data"},{"ColData":[{"value":"Deal Option Clearing","id":"171"},{"value":"31978.47"}],"type":"Data"},{"ColData":[{"value":"Stamp Duty Clearing","id":"136"},{"value":"20133.62"}],"type":"Data"},{"ColData":[{"value":"Store Credit Accrual","id":"127"},{"value":"-20469.55"}],"type":"Data"},{"ColData":[{"value":"Undeposited Amex","id":"72"},{"value":"-2186458.57"}],"type":"Data"},{"ColData":[{"value":"Undeposited Cash 1","id":"71"},{"value":"-829.15"}],"type":"Data"},{"ColData":[{"value":"Undeposited Cheque","id":"25"},{"value":"8407834400.39"}],"type":"Data"},{"ColData":[{"value":"Undeposited Debit","id":"47"},{"value":"-321772.65"}],"type":"Data"},{"ColData":[{"value":"Undeposited Direct deposit","id":"49"},{"value":"-1009512.90"}],"type":"Data"},{"ColData":[{"value":"Undeposited Discover","id":"189"},{"value":"782767.72"}],"type":"Data"},{"ColData":[{"value":"Undeposited EFTPOS","id":"59"},{"value":"-204.00"}],"type":"Data"},{"ColData":[{"value":"Undeposited Gift card","id":"128"},{"value":"-2845.42"}],"type":"Data"},{"ColData":[{"value":"Undeposited Mastercard","id":"129"},{"value":"-89671.53"}],"type":"Data"},{"ColData":[{"value":"Undeposited PayPal","id":"130"},{"value":"40559.23"}],"type":"Data"}]},"Summary":{"ColData":[{"value":"Total current liabilities"},{"value":"8540147466.48"}]},"type":"Section","group":"TotalLongTermLiabilities"},{"Header":{"ColData":[{"value":"Non-current liabilities:"},{"value":""}]},"Rows":{"Row":[{"ColData":[{"value":"Accrued non-current liabilities","id":"5"},{"value":"1508224.83"}],"type":"Data"},{"ColData":[{"value":"Long-term debit","id":"35"},{"value":"-248.20"}],"type":"Data"},{"ColData":[{"value":"Undeposited Financing","id":"3"},{"value":"199.99"}],"type":"Data"}]},"Summary":{"ColData":[{"value":"Total non-current liabilities"},{"value":"1508176.62"}]},"type":"Section","group":"TotalNonCurLiabilities"},{"Header":{"ColData":[{"value":"Shareholders equity:"},{"value":""}]},"Rows":{"Row":[{"ColData":[{"value":"Net Income"},{"value":"-127269933.34"}],"type":"Data","group":"NetIncome"},{"ColData":[{"value":"Equity in earnings of subsidiaries","id":"21"},{"value":"173096.57"}],"type":"Data"},{"ColData":[{"value":"Opening Balance Equity","id":"90"},{"value":"9845.10"}],"type":"Data"},{"ColData":[{"value":"Owner Contribution","id":"97"},{"value":"10000.00"}],"type":"Data"},{"ColData":[{"value":"Owner Drawings","id":"96"},{"value":"-2000.00"}],"type":"Data"},{"ColData":[{"value":"Retained Earnings","id":"2"},{"value":"1739779.51"}],"type":"Data"},{"ColData":[{"value":"Share capital","id":"57"},{"value":"12750.00"}],"type":"Data"}]},"Summary":{"ColData":[{"value":"Total shareholders equity"},{"value":"-125326462.16"}]},"type":"Section","group":"TotalShareHoldersEquityNode"}]},"Summary":{"ColData":[{"value":"Total liabilities and equity"},{"value":"8416329180.94"}]},"type":"Section","group":"NetLiabilitiesAndShareHolderEquity"}]}}');
            res.setStatusCode(200);
            return res;
        }
    }
}