public without sharing class UnitInvoiceJournalEntryService {
    
    public static Integer MAX_RECORDS_UPDATE_LIMIT = 500;
    public static String refreshToken;
	public static Decimal refreshTokenExpiresIn;
    
    public static void syncUnitInvoiceJE(Set<Id> unitIds){
        AccSync_UnitInvoiceJournalEntry_Batch.runUnitInvoiceJEForSync(unitIds, 10);
    }
    
    public static QBUtil.BatchResultWrapper syncAccountingServer(AccountingUnit unitRecord, List<Customer_Owned_Unit__c> unitListToUpdate){
        List<Log__c> errorLogToInsert = new List<Log__c>();
        if(QBUtil.isQBEnabled()){
            errorLogToInsert = syncToQuickBooks(unitRecord, unitListToUpdate);
        }
        return new QBUtil.BatchResultWrapper(errorLogToInsert, refreshToken, refreshTokenExpiresIn);
    }
    
    public static List<Log__c> syncToQuickBooks(AccountingUnit unitRecord, List<Customer_Owned_Unit__c> unitListToUpdate){
        Customer_Owned_Unit__c skuRec = new Customer_Owned_Unit__c();
        skuRec.Id = unitRecord.Id;
        Boolean isAnyLineItemAvailableTOPostJEToQB = true;
        List<Log__c> errorLogList = new List<Log__c>();
        try {
            if(unitRecord.SyncTokenForUnitInvoiceJE != null){
                //HttpResponse getResponse = QuickbookConnector.getRequestFromQuickBooks('journalentry', unitRecord.QBAccountingIdUnitInvoiceJE);
                QuickbookConnector.ResponseWrapper responseObj = QuickbookConnector.getRequestFromQB('journalentry', unitRecord.QBAccountingIdUnitInvoiceJE);
				HttpResponse getResponse = responseObj.Response;
				refreshToken = responseObj.RefreshToken;
				refreshTokenExpiresIn = responseObj.RefreshTokenExpiresIn;
                if(getResponse.getStatusCode() == 200) { 
                    QBJournalEntryServiceHelper.ResponseQuickBooksJournalEntry unitInvoiceJEGetResponce = (QBJournalEntryServiceHelper.ResponseQuickBooksJournalEntry)System.JSON.deserialize(getResponse.getBody(), QBJournalEntryServiceHelper.ResponseQuickBooksJournalEntry.class);
                    unitRecord.SyncTokenForUnitInvoiceJE = unitInvoiceJEGetResponce.JournalEntry.SyncToken;
                } else {
                    errorLogList.add(new LogService().createErrorLog('UnitInvoiceJournalEntryService', 'syncToQuickBooks() - Get sync token Request From QuickBooks Online', getResponse.getBody(), getResponse.getStatusCode(), null, 
                                              unitRecord + LogService.METHOD_PARAM_SEPERATOR + unitListToUpdate, LogService.QUICKBOOKS,false));
                }
            }
            QBJournalEntryServiceHelper.QuickBooksJournalEntry QCIJE = new QBJournalEntryServiceHelper.QuickBooksJournalEntry(unitRecord, IntegrationUtility.UNIT_INVOICE_JE);
            if(QCIJE.line != null && QCIJE.line.size() == 0) {
                isAnyLineItemAvailableTOPostJEToQB = false;
                skuRec.Accounting_Response_Unit_Invoice_JE__c = QBUtil.CO_INVOICE_NO_JE_MSG;
                skuRec.Available_For_QB_Unit_Invoice_JE_Sync__c = false;
            } else {
                String unitInvoiceJEJSONBody = system.JSON.serialize(QCIJE);
                system.debug('*************'); 
                system.debug(unitInvoiceJEJSONBody);
                String response = unitInvoiceJEJSONBody;
                //HttpResponse res = QuickbookConnector.sendRequestToQuickBooks('journalentry', unitInvoiceJEJSONBody);
                QuickbookConnector.ResponseWrapper responseObj = QuickbookConnector.sendRequestToQB('journalentry', unitInvoiceJEJSONBody);
				HttpResponse res = responseObj.Response;
				refreshToken = responseObj.RefreshToken;
				refreshTokenExpiresIn = responseObj.RefreshTokenExpiresIn;
                System.debug(res);
                if(res.getStatusCode() == 200) { 
                    String resParams = res.getBody();
                    QBJournalEntryServiceHelper.ResponseQuickBooksJournalEntry unitInvoiceJEPostResponse = (QBJournalEntryServiceHelper.ResponseQuickBooksJournalEntry)System.JSON.deserialize(resParams, QBJournalEntryServiceHelper.ResponseQuickBooksJournalEntry.class);
                    skuRec.QB_Accounting_Id_Unit_Invoice_JE__c = unitInvoiceJEPostResponse.JournalEntry.Id;
                    skuRec.Sync_Token_For_Unit_Invoice_JE__c = unitInvoiceJEPostResponse.JournalEntry.SyncToken;
                    response += '\n\n'+resParams; 
                    skuRec.Available_For_QB_Unit_Invoice_JE_Sync__c = false;
                    skuRec.Accounting_Last_Sync_Time_Unit_JE__c = System.now(); 
                } else {
                    response += '\n\n'+res.getBody();
                    response += '\n\n'+res.getStatus();
                    errorLogList.add(new LogService().createErrorLog('UnitInvoiceJournalEntryService', 'syncToQuickBooks() -  post request to save', res.getBody(), res.getStatusCode(), null, 
                                                  unitRecord + LogService.METHOD_PARAM_SEPERATOR + unitListToUpdate, LogService.QUICKBOOKS, false));
                }
                skuRec.Accounting_Response_Unit_Invoice_JE__c = QBUtil.truncateString(response, 131072); 
            }
        } catch(Exception e) {
            if(isAnyLineItemAvailableTOPostJEToQB) {
                skuRec.Available_For_QB_Unit_Invoice_JE_Sync__c = true;
                skuRec.Accounting_Response_Unit_Invoice_JE__c = e.getMessage();
                errorLogList.add(new LogService().createErrorLog('UnitInvoiceJournalEntryService', 'syncToQuickBooks() - exception', e.getMessage(),LogService.NOT_APPLICABLE, e.getStackTraceString(), 
                                                  unitRecord + LogService.METHOD_PARAM_SEPERATOR + unitListToUpdate, LogService.QUICKBOOKS, false));
            } else {
                skuRec.Accounting_Response_Unit_Invoice_JE__c = QBUtil.CO_INVOICE_NO_JE_MSG;
                skuRec.Available_For_QB_Unit_Invoice_JE_Sync__c = false;
            }
        }
        if(unitListToUpdate.size() > MAX_RECORDS_UPDATE_LIMIT){
            AccSync_UnitInvoiceJournalEntry_Batch.updateUnitInvoices(unitListToUpdate);
            unitListToUpdate = new List<Customer_Owned_Unit__c>();
        }
        unitListToUpdate.add(skuRec); 
        
        return errorLogList;
    }
    /*
    public static List<QuickBooksUnitInvoiceItemsHelper> getAllAccountingCOInvoiceItemsRecs(AccountingUnit unitRecord) {
        Boolean isTaxIncludingPricing = GeneralConfiguration.getTaxIncludingPricing();
        Decimal taxInclusiveAmount;
        String itemCategoryAccountingId, itemCategoryName;
        String COGS_GL, Income_GL, Inventory_GL, DealUnit_Inventory_GL;
        Decimal price = 0, cost = 0, total = 0;
        Boolean IsDealMerchOrService = false, IsInternalService = false;
        String entityType;
        Boolean isDealInvoiced;
        List<QuickBooksUnitInvoiceItemsHelper> itemsList = new List<QuickBooksUnitInvoiceItemsHelper>();
        
        if(unitRecord.AccountingCOInvoiceItemsRecs.size() > 0) {
            List<Id> coliIds = new List<Id>();
            List<Id> sohIds = new List<Id>();
            List<Id> cokhIds = new List<Id>();
            List<Id> dealIds = new List<Id>();
            
            for(AccountingUnit.AccountingCOInvoiceItem coInvoiceItem : unitRecord.AccountingCOInvoiceItemsRecs) {
                if(coInvoiceItem.COLineItemId != null) {
                    coliIds.add(coInvoiceItem.COLineItemId);
                }
                if(coInvoiceItem.SOHeaderId != null) {
                    sohIds.add(coInvoiceItem.SOHeaderId);
                }
                if(coInvoiceItem.COKitHeaderId != null) {
                    cokhIds.add(coInvoiceItem.COKitHeaderId);
                }
                if(coInvoiceItem.DealId != null) {
                    dealIds.add(coInvoiceItem.DealId);
                }
            }
            
            // This is due to there may be multiple type of Price and Cost options.
        }
        return new List<QuickBooksUnitInvoiceItemsHelper> ();
    }
    /*
    private static List<AccountingSalesTax> getSalesTaxList(String soHeaderId){
        Map<String, Decimal> salesTaxNameToTaxValue = new Map<String, Decimal>(); 
        Map<String, Sales_Tax_Item__c> salesTaxNameToSalesTax = new Map<String, Sales_Tax_Item__c>();  
        List<Sales_Tax_Item__c> salesTaxList = [SELECT AccountingId__c, Name__c, Category__r.Income_GL__c
                                                FROM Sales_Tax_Item__c where Active__c = true];
        
        for(Sales_Tax_Item__c STI : salesTaxList){
            salesTaxNameToSalesTax.put(STI.Name__c, STI);
        }
        List<Individual_Tax__c> individualItemsList = [select CO_Line_Item__c, Tax_Rate__c, Sales_Tax_Item_Name__c, 
                                                        Taxable_Amount__c, Tax_Amount__c,
                                                        Applicable_Tax__c, List_Tax_items_on_forms__c
                                                        from Individual_Tax__c where Service_Order_Line_Item__r.Service_Order_Header__c = :soHeaderId];
        
        salesTaxNameToTaxValue = TaxCalculation.getTaxAmount(individualItemsList);  
        List<AccountingSalesTax> taxDetails = new List<AccountingSalesTax>();
        for(String salesTaxName : salesTaxNameToTaxValue.keyset()){
            taxDetails.add(new AccountingSalesTax(salesTaxName, salesTaxNameToTaxValue.get(salesTaxName), salesTaxNameToSalesTax.get(salesTaxName).Category__r.Income_GL__c));
        }
        
        return taxDetails;
    }
       
    private static String getDealUnitName(Deal_Item__c dealItem){
        String Item = '';
        if(dealItem.Customer_Owned_Unit__c != null) {
            if(dealItem.Customer_Owned_Unit__r.Stock_Id__c != null){
                Item += dealItem.Customer_Owned_Unit__r.Stock_Id__c + ';';
            }
            if(dealItem.Customer_Owned_Unit__r.VIN_Number__c != null){
                Item += dealItem.Customer_Owned_Unit__r.VIN_Number__c + ';';
            }           
        }
        return Item;
    }
    
    private static List<CO_Header__c> getCustomerOrderHeaders(List<Id> coIdsList, List<Id> coliIds) {
        List<CO_Header__c> coHeadersList = new List<CO_Header__c>();
        if(AccessControl.ifObjectFieldIsAccessible('CO_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectFieldIsAccessible('CO_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        
        if(coIdsList != null && coIdsList.size() > 0) {
            String query = 'SELECT ';
            for(String fieldsName : AccountingUnitInvoice.objectToFieldMap.get('COHeader')){
                fieldsName = BPUtility.escapeSingleQuotes(fieldsName);
                query += fieldsName + ', ';
            }
            
            query += '(SELECT ';
            for(String fieldsName : AccountingUnitInvoice.objectToFieldMap.get('COLineItem')){
                fieldsName = BPUtility.escapeSingleQuotes(fieldsName);
                query += fieldsName + ', ';
            }
            query = query.substring(0, query.length()-2);
            query += ' FROM CO_Line_Items__r WHERE Is_In_Service_Order__c = false AND Id IN: coliIds) FROM CO_Header__c WHERE Id IN: coIdsList';
            system.debug('query ' + query);
            coHeadersList = Database.query(query);
        }
        return coHeadersList;
    }
    
    private static List<Service_Order_Header__c> getServiceOrderHeaders(List<Id> coIdsList, List<Id> sohIds) {
        List<Service_Order_Header__c> soHeadersList = new List<Service_Order_Header__c>();
        if(AccessControl.ifObjectFieldIsAccessible('Service_Order_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectFieldIsAccessible('Service_Order_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectFieldIsAccessible('Customer_Owned_Unit__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        
        if(coIdsList != null && coIdsList.size() > 0) {
            soHeadersList = [SELECT Name__c, Total__c, Correction__c, Cause__c, Concern__c, Customer_Owned_Unit__c, Customer_Owned_Unit__r.VIN_Number__c,
                                    Customer_Owned_Unit__r.Unit_Make__r.Name, Customer_Owned_Unit__r.Unit_Model__r.Name__c, Customer_Owned_Unit__r.Year__c,
                                    Odometer_on_Arrival__c, Odometer_on_Departure__c, CO_Header__c, CO_Header__r.CO_Type__c, Notes_For_Customer__c,
                                    Deal__c, Transaction_Type__r.Type__c, Transaction_Type__r.Part_Category__r.COGS_GL__c,
                                    Transaction_Type__r.Part_Category__r.Income_GL__c, Transaction_Type__r.Labour_Category__r.COGS_GL__c, Is_Technician_Hours_Costing_Enabled__c,
                                    Transaction_Type__r.Labour_Category__r.Income_GL__c, Transaction_Type__r.Part_Category__r.AccountingId__c, 
                                    Transaction_Type__r.Part_Category__r.Name, Transaction_Type__r.Labour_Category__r.AccountingId__c, 
                                    Transaction_Type__r.Labour_Category__r.Name, Category__r.Income_GL__c, Customer_Owned_Unit__r.Category__r.Inventory_GL__c,
                                    Customer_Owned_Unit__r.Unit_Id__c, Customer_Owned_Unit__r.Stock_Id__c, SO_Type__c,
                                    Deal__r.Invoice_Number__r.CreatedDate,
                                    (SELECT Item_Code__c, Item_Description__c, Item_Desc__c, Kit_Price__c, Labour_Code__c, Part__c, Qty_Needed__c, 
                                            Total__c, Fee__c, Tax_Percent__c, Tax_Amount__c, Price_When_Tax_Included__c,
                                            Part__r.Category__c, Part__r.Category__r.AccountingId__c, Part__r.Category__r.Name, Part__r.Category__r.COGS_GL__c,
                                            Part__r.Category__r.Income_GL__c, Part__r.Category__r.Inventory_GL__c,
                                            Fee__r.Category__c, Fee__r.Category__r.AccountingId__c, Fee__r.Category__r.Name, Fee__r.Category__r.COGS_GL__c,
                                            Fee__r.Category__r.Income_GL__c, Fee__r.Category__r.Inventory_GL__c, Fee__r.Cost_Method__c, Fee__r.Cost_Rate__c,
                                            Labour_Code__r.Category__c, Labour_Code__r.Category__r.AccountingId__c, Labour_Code__r.Category__r.Name,
                                            Labour_Code__r.Category__r.COGS_GL__c, Labour_Code__r.Category__r.Income_GL__c, Labour_Code__r.Category__r.Inventory_GL__c,
                                            Labour_Code__r.Cost_Method__c, Labour_Code__r.Cost_Rate__c,
                                            Sublet__c, Sublet__r.Category__c, Sublet__r.Category__r.AccountingId__c, Sublet__r.Category__r.Name,
                                            Sublet__r.Category__r.COGS_GL__c, Sublet__r.Category__r.Income_GL__c, Sublet__r.Category__r.Inventory_GL__c,
                                            Sublet__r.Cost_Method__c, Sublet__r.Cost__c, Cost__c, Total_Cost__c,
                                            Deal_Item__r.Customer_Owned_Unit__r.Stock_Id__c, Deal_Item__r.Customer_Owned_Unit__r.Category__r.Inventory_GL__c,
                                            CO_Line_Item__r.Adjusted_Cost_Coli__c, CO_Line_Item__r.Avg_Cost__c, CO_Line_Item__r.Part__r.Average_Cost__c
                                            FROM Service_Order_Line_Items__r)
                                    FROM Service_Order_Header__c WHERE Id IN: sohIds ];
        }
        return soHeadersList;
    }
    
    private static Map<Id, Service_Order_Line_Item__c> getSoliIdToSOLIRecordMap(List<Id> sohIds) { 
    	Map<ID, Service_Order_Line_Item__c> soliIdToSOLIRecordMap = new Map<ID, Service_Order_Line_Item__c>([SELECT Id, Service_Order_Header__r.Provider__r.Name, 
    																	Service_Order_Header__r.CO_Header__r.Name, (SELECT Total_Variance_Amount__c, Category__r.COGS_GL__c, 
    																	Category__r.Income_GL__c, Category__r.Inventory_GL__c FROM Claim_Line_Items__r 
    																	WHERE SO_Payment_Role__r.RecordType.DeveloperName = 'Internal') FROM Service_Order_Line_Item__c WHERE Service_Order_Header__c IN: sohIds]);
    	return soliIdToSOLIRecordMap;
    }
      
    private static List<CO_Kit_Header__c> getKitHeaders(List<Id> coIdsList, List<Id> cokhIds) {
        List<CO_Kit_Header__c> coKitHeadersList = new List<CO_Kit_Header__c>();
        if(AccessControl.ifObjectFieldIsAccessible('CO_Kit_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectFieldIsAccessible('CO_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        
        if(coIdsList != null && cokhIds.size() > 0) {
            coKitHeadersList = [SELECT CO_Header__c, Kit_Header__c, Price__c, Tax_Amount__c, Actual_Kit_Price__c, CreatedDate, Kit_Header__r.Kit_Unique_Name__c,
                                    Can_Split__c, Service_Kit__c, Fixed_Price_Flag__c, CO_Fixed_KitHeader__c,
                                    (SELECT Name, Item_ID__c, CO_Header__c, CO_Header__r.Name, CO_Header__r.Customer__c, CO_Header__r.Customer__r.Name,
                                            CO_Header__r.Owner__c, CO_Header__r.Owner__r.Name, CO_Header__r.Order_status__c, Qty__c, Qty_Committed__c,
                                            Item_Code__c, Item_Description__c, Price__c, Part__r.Name, Part__r.Part_Id__c, Part__r.Part_Number__c,
                                            Part__r.Description__c, Part__r.AvailableParts__c, Part__r.Vendor__c, Part__r.Average_Cost__c,
                                            Special_Order__c, Tax__c, Retail__c, Closed_CO_Invoice_link__c, VO_Number__c, VO_Status__c,
                                            Expected_Delivery_Date__c, CreatedDate, Fee__c, Fee__r.Fee_Unique_Name__c, Fixed_Price__c, CO_Fixed_KitLineItem__c,
                                            Price_When_Tax_Included__c, Actual_Kit_Price__c, Kit_Price_With_Price_Level__c, CO_Kit_Header__r.Id,
                                            Sub_Total_With_Tax__c, Sub_Total_Without_Tax__c, Tax_Amount__c, Oversold_Qty__c, Is_Temporary__c,
                                            Part__r.Category__c, Part__r.Category__r.AccountingId__c, Part__r.Category__r.Name, Part__r.Category__r.COGS_GL__c,
                                            Part__r.Category__r.Income_GL__c, Part__r.Category__r.Inventory_GL__c, Fee__r.Category__c,
                                            Fee__r.Category__r.AccountingId__c, Fee__r.Category__r.Name, Fee__r.Category__r.COGS_GL__c,
                                            Fee__r.Category__r.Income_GL__c, Fee__r.Category__r.Inventory_GL__c, Fee__r.Cost_Method__c, Fee__r.Cost_Rate__c,
                                            Deal__c, Related_Option_And_Fees__c, Adjusted_Cost_Coli__c, Avg_Cost__c,
                                            Deal__r.Invoice_Number__r.CreatedDate
                                            FROM CO_Line_Items__r  WHERE Is_In_Service_Order__c = false )
                                    FROM CO_Kit_Header__c WHERE Id IN: cokhIds ];
        }
        return coKitHeadersList;
    }
    
    private static List<Deal_Item__c> getDealHeaders(List<Id> coIdsList, List<Id> dealIds) {
        List<Deal_Item__c> dealItemList = new List<Deal_Item__c>();
        if(AccessControl.ifObjectFieldIsAccessible('Deal__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectFieldIsAccessible('Deal_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectFieldIsAccessible('Customer_Owned_Unit__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(dealIds != null && dealIds.size() > 0) {
            String query = 'SELECT Id, (SELECT Id FROM Deal_Items__r), ';
            // Child Query For Deal F&I Products
            query += '(SELECT ';
            for(String fieldsName : AccountingUnitInvoice.objectToFieldMap.get('DealFIProduct')){
                fieldsName = BPUtility.escapeSingleQuotes(fieldsName);
                query += fieldsName + ', ';
            }
            query = query.substring(0, query.length()-2);
            query += ' FROM F_I_Products__r) FROM Deal__c WHERE Id IN: dealIds';
    
            List<Deal__c> dealList = Database.query(query);
            
            if(dealList.size() > 0) {
                Set<String> dealItemId = new Set<String>();
                for(Deal__c dealRec : dealList) {
                    for(Deal_Item__c dealItemRec : dealRec.Deal_Items__r) {
                        dealItemId.add(dealItemRec.Id);
                    }
                    
                    if(dealIdToFIProductsMap != null) {
                        dealIdToFIProductsMap.put(dealRec.Id, dealRec.F_I_Products__r);
                    }
                }
                
                query = 'SELECT ';
                for(String fieldsName : AccountingUnitInvoice.objectToFieldMap.get('DealItems')){
                    fieldsName = BPUtility.escapeSingleQuotes(fieldsName);
                    query += fieldsName + ', ';
                }
                query += '(SELECT ';
                for(String fieldsName : AccountingUnitInvoice.objectToFieldMap.get('OptionAndFees')){
                    fieldsName = BPUtility.escapeSingleQuotes(fieldsName);
                    query += fieldsName + ', ';
                }
                query = query.substring(0, query.length()-2);
                query += ' FROM Options_Fees__r), ';
                
                query += '(SELECT ';
                for(String fieldsName : AccountingUnitInvoice.objectToFieldMap.get('DealUnitPriceCost')){
                    fieldsName = BPUtility.escapeSingleQuotes(fieldsName);
                    query += fieldsName + ', ';
                }
                query = query.substring(0, query.length()-2);
                query += ' FROM Deal_Unit_Prices_Costs__r) FROM Deal_Item__c WHERE Id IN: dealItemId';
                dealItemList = Database.query(query);
            }
        }
        return dealItemList;
    }
     
    public class QuickBooksUnitInvoiceItemsHelper {
        public String Description;
        public String DealUnitDescription;
        public Decimal UnitCost;
        public Decimal UnitPrice;
        public Decimal Qty;
        public Decimal TaxInclusiveAmt;
        public String ItemCategoryAccountingId;
        public String ItemCategoryName;
        public String COGS_GL;
        public String Income_GL;
        public String Inventory_GL;
        public Boolean IsDealMerchOrService;
        public String DealUnit_Inventory_GL;
        public Boolean IsInternalService;
        public Boolean IsInternalServiceTax;
        public String EntityType;
        public Boolean IsBillToInternalClaimLI;
        public String PostingType;
        public Boolean IsLaborWithTechnicianHoursCostingEnabled;
        
        public QuickBooksUnitInvoiceItemsHelper(String Description, String DealUnitDescription, Decimal UnitCost, Decimal UnitPrice, Decimal Qty, Decimal TaxInclusiveAmt, String ItemCategoryAccountingId, String ItemCategoryName, String COGS_GL, String Income_GL, String Inventory_GL, Boolean IsDealMerchOrService, String DealUnit_Inventory_GL, Boolean IsInternalService, Boolean IsInternalServiceTax, String entityType) {
            this.Description = Description;
            this.DealUnitDescription = DealUnitDescription;
            this.UnitCost = UnitCost;
            this.UnitPrice = UnitPrice;
            this.Qty = Qty;
            this.TaxInclusiveAmt = TaxInclusiveAmt;
            this.ItemCategoryAccountingId = ItemCategoryAccountingId;
            this.ItemCategoryName = ItemCategoryName;
            this.COGS_GL = COGS_GL;
            this.Income_GL = Income_GL;
            this.Inventory_GL = Inventory_GL;
            this.IsDealMerchOrService = IsDealMerchOrService;
            this.DealUnit_Inventory_GL = DealUnit_Inventory_GL;
            this.IsInternalService = IsInternalService;
            this.IsInternalServiceTax = IsInternalServiceTax;
            this.EntityType = entityType != null ? entityType : '';
            this.IsBillToInternalClaimLI = false;
            this.IsLaborWithTechnicianHoursCostingEnabled = false;
        }        
        
        public QuickBooksUnitInvoiceItemsHelper(String description, Decimal unitCost, Decimal unitPrice, Decimal qty, String COGS_GL, String Income_GL, String Inventory_GL, Boolean IsDealMerchOrService, Boolean IsInternalService, Boolean IsInternalServiceTax, Boolean isBillToInternalVariance, String postingType) {
            this.Description = description;
            this.UnitCost = unitCost;
            this.UnitPrice = unitPrice;
            this.Qty = qty;
            this.COGS_GL = COGS_GL;
            this.Income_GL = Income_GL;
            this.Inventory_GL = Inventory_GL;
            this.IsDealMerchOrService = IsDealMerchOrService;
            this.IsInternalService = IsInternalService;
            this.IsInternalServiceTax = IsInternalServiceTax;
            this.IsBillToInternalClaimLI = isBillToInternalVariance;
            this.PostingType = postingType != null ? postingType : '';
        }        
     }
     
     public class AccountingSalesTax {
        public String SalesTaxName {get; set;}        
        public Decimal SalesTaxAmount {get; set;}       
        public String CategoyRef {get; set;}
        
        // Constructor
        public AccountingSalesTax(String SalesTaxName, Decimal SalesTaxAmount, String CategoyRef) { 
            this.SalesTaxName = SalesTaxName;
            this.SalesTaxAmount = SalesTaxAmount;
            this.CategoyRef = CategoyRef;
        }
    }*/
}