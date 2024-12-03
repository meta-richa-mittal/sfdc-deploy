/**
* Author: Nidhi Sharma
* Since: September 24, 2016
* Name: ServiceJobWorksheetCtrl
* Description: Wrapper class to handle JSON variables for SO worksheet. Created for ticket #129
**/
global without sharing class ServiceJobWorksheetCtrl {
    
    public static String Application{get;set;}
    public static String Assests{get;set;}
    public static String Application_Images{get;set;}
    public String BarCodeQRCodeURL{get;set;}
    public Boolean isPrintReview {get;private set;}
    public ServiceJobWorksheetWrapper soWorkSheetObj {get; private set;}
    public Boolean isHidePartNumbersOnDocuments{get{return GeneralConfiguration.isHidePartNumbersOnDocuments();} private set;}
    public Boolean isIncludeMSRPAndDiscountOnPartLines{get{return GeneralConfiguration.isIncludeMSRPAndDiscountOnPartLines();} private set;}
    public Boolean isQRCodesOnServiceDocuments{get{return GeneralConfiguration.isQRCodesOnServiceDocuments();} private set;}
    
    public ServiceJobWorksheetCtrl() {
    	Application = GlobalController.GetResourceURL('Application');
    	Application_Images = GlobalController.GetResourceURL('Application_Images');
    	Assests = GlobalController.GetResourceURL('Assests');
    	getPDFDetail();
    }
    
    public void getPDFDetail() {
        String coHeaderId = ApexPages.currentPage().getParameters().get('id');
        String brandingLocationId = ApexPages.currentPage().getParameters().get('brandingLocationId');
        isPrintReview = Boolean.valueOf(ApexPages.currentPage().getParameters().get('isPrintReview'));
        String selectedSOIds = BPUtility.getDecodedString(ApexPages.currentPage().getParameters().get('SelectedSOIds'));
        List<String> selectedSOIdList = String.isNotBlank(selectedSOIds) ? selectedSOIds.split(',') : new List<String>();

        soWorkSheetObj = getSOHeaderData(coHeaderId, new Set<String>(selectedSOIdList), brandingLocationId);	
    }

    private ServiceJobWorksheetWrapper getSOHeaderData(String coHeaderId, Set<String> selectedSOIdSet, String brandingLocationId) {
        if(AccessControl.ifObjectFieldIsAccessible('CO_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<CO_Header__c> coHeaderList = [select Name, Status__c, CO_Type__c, Customer_PO_Number__c, Customer__c, CreatedBy.Name, 
            SO_Worksheet_User_selection__c, (Select Id, Amount__c, Deal__c, Payment_method__c from CO_Deposits__r where Deal__c = null AND Amount__c != null) from CO_Header__c where Id=: coHeaderId];
        if(coHeaderList.size() == 0) {
            return null;
        }
        if(isQRCodesOnServiceDocuments) {
            BarCodeQRCodeURL = 'https://ms-universal-internal-api-910142783210.us-central1.run.app/api/generate-bar-qr-code/qrcode?text=' + EncodingUtil.urlEncode(AccountingUtil.getURL(coHeaderId, 'CustomerOrder_V2'), 'UTF-8') + '&scale=1&includetext=false&textxalign=center';
        } else {
            BarCodeQRCodeURL = 'https://ms-universal-internal-api-910142783210.us-central1.run.app/api/generate-bar-qr-code/barcode?text=' + EncodingUtil.urlEncode(coHeaderList[0].Name, 'UTF-8') + '&scale=1&includetext=false&textxalign=center';
        }
        Set<String> finalizedSOIdSet = new Set<String>();
        ServiceJobWorksheetWrapper workSheetWrapperObj;
        BrandingLocationWrapper brandingLocationObj = COService.getBrandingLocationDataForPrint(brandingLocationId);
        if(selectedSOIdSet != null && selectedSOIdSet.size() > 0) {
            
            List<Service_Order_Header__c> soHeaderList = getSODetailsByFieldName(selectedSOIdSet);
            List<Service_Order_Header__c> soHeaderRecList = new List<Service_Order_Header__c>();
            Map<String, String> unitIdToProductTypeIdMap = new Map<String, String>();
            for(Service_Order_Header__c soHeaderRec : soHeaderList) {
                if(selectedSOIdSet.contains(soHeaderRec.Id)) {
                    soHeaderRecList.add(soHeaderRec);
                    if(String.isNotBlank(soHeaderRec.Customer_Owned_Unit__r.Product_type__c)) unitIdToProductTypeIdMap.put(soHeaderRec.Customer_Owned_Unit__c, soHeaderRec.Customer_Owned_Unit__r.Product_type__c);
                    if(soHeaderRec.Invoice_Number__c != null){
                        finalizedSOIdSet.add(soHeaderRec.Id);
                    }
                }
            }
            List<FilterJSON> filerObjList = new List<FilterJSON>{
                new FilterJSON('Unit_Product_Type__c', 'IN', String.join(unitIdToProductTypeIdMap.values(), ',')),
                new FilterJSON('Active__c', SOQLUtility.EQUALS, SOQLUtility.TRUE_VALUE),
                new FilterJSON('Include_In_SO_Document__c', SOQLUtility.EQUALS, SOQLUtility.TRUE_VALUE)
            };

            UnitProductTypeService.OptionalFieldAPINameToRecMap = UnitProductTypeService.getUnitOptionalFieldAPINameToRecMap(filerObjList);
            UnitProductTypeService.UnitDataFieldsAPINameToLabelMap = GeneralConfiguration.getUnitDataFieldsAPINameToLabelMap();
            Map<Id, Customer_Owned_Unit__c> unitIdToRecMap = Unit_Service.getUnitIdToRecMap(unitIdToProductTypeIdMap.keySet(), Unit_Service.UnitPrimaryFields, new List<String>(UnitProductTypeService.OptionalFieldAPINameToRecMap.keySet()));
            List<Account> customerList = new List<Account>();
            if(coHeaderList[0].Customer__c != null) {
                customerList = SOQLUtil.getCustomerDetailsByFieldName(new Map<String, String>{'Id' => coHeaderList[0].Customer__c});
            } 

            Map<String, Decimal> salesTaxNameToTaxValue = new Map<String, Decimal>();  
            Map<String, Decimal> finalizedSalesTaxNameToTaxValue = new Map<String, Decimal>();  
            if(isPrintReview) {
                List<Individual_Tax__c> individualItemsList = [select CO_Line_Item__c, Deal__c, Tax_Rate__c, Form_Label__c, Sales_Tax_Item_Name__c, SO_Payment_Role__c,
                                                                            Taxable_Amount__c, Tax_Amount__c, Enhanced_Tax_Amount__c, Sales_Tax_Item__r.Name__c,
                                                                            Applicable_Tax__c, List_Tax_items_on_forms__c, SO_Payment_Role__r.Applicable_Tax_Name__c 
                                                                                from Individual_Tax__c 
                                                                                where Service_Order_Line_Item__r.Service_Order_Header__c IN :selectedSOIdSet 
                                                                                AND Service_Order_Line_Item__r.Service_Order_Header__r.Transaction_Type__r.Type__c = 'Customer'];
                salesTaxNameToTaxValue = TaxCalculation.getTaxAmountWithFormLabel(individualItemsList); 
                
                List<Individual_Tax__c> finalizedIndividualItemsList = [select CO_Line_Item__c, Deal__c, Tax_Rate__c, Form_Label__c, Sales_Tax_Item_Name__c, SO_Payment_Role__c,
                                                                            Taxable_Amount__c, Tax_Amount__c, Enhanced_Tax_Amount__c, Sales_Tax_Item__r.Name__c,
                                                                            Applicable_Tax__c, List_Tax_items_on_forms__c, SO_Payment_Role__r.Applicable_Tax_Name__c 
                                                                                from Individual_Tax__c 
                                                                                where Service_Order_Line_Item__r.Service_Order_Header__c IN :finalizedSOIdSet 
                                                                                AND Service_Order_Line_Item__r.Service_Order_Header__r.Transaction_Type__r.Type__c = 'Customer'];
                finalizedSalesTaxNameToTaxValue = TaxCalculation.getTaxAmountWithFormLabel(finalizedIndividualItemsList); 
            }            
            workSheetWrapperObj = new ServiceJobWorksheetWrapper(coHeaderList[0], customerList, soHeaderRecList, unitIdToRecMap, 
                                                                    brandingLocationObj, salesTaxNameToTaxValue, finalizedSalesTaxNameToTaxValue);
        }
        return workSheetWrapperObj;
    }

    public static List<Sobject> getSODetailsByFieldName(Set<String> soIdSet) {
        String query;   
        query = 'SELECT '; 
        for(String fieldName : ServiceJobWorksheetWrapper.getSOHeaderFieldsList()){
            fieldName = BPUtility.escapeSingleQuotes(fieldName);
            query += fieldName + ', ';
        }
        query += ' (Select Id, Start_DateTime__c from Events__r where Start_DateTime__c != null LIMIT 1), ';
        query += ' (Select Id, CO_Invoice_Header__r.Status__c, SO_Payment_Role__r.RecordType.DeveloperName from CO_Invoice_Items__r where SO_Payment_Role__r.RecordType.DeveloperName = \'Deductible\' AND CO_Invoice_Header__r.Status__c = \'Closed\'), ';
        query += ' (Select Id, Total_Amount__c,Status__c,RecordType.DeveloperName from SO_Payment_Roles__r ' +
        'where RecordType.DeveloperName = \'Deductible\' AND Total_Amount__c != null AND Total_Amount__c != 0), ';
        
        // Child Query
        query += '( SELECT '; 
        for(String fieldName : SOHeaderWrapper.getSOLineItemFieldsList()){
            fieldName = BPUtility.escapeSingleQuotes(fieldName);
            query += fieldName + ', ';
        }
        query = query.substring(0, query.length()-2);
        query += ' FROM Service_Order_Line_Items__r ORDER BY Name)';
        
        query += ' FROM Service_Order_Header__c WHERE Id IN: soIdSet';
        query += ' ORDER BY Deal__c ASC NULLS LAST, CreatedDate ASC LIMIT ' + SOQLUtil.getAvailableQueryRowsLimit();
        
        if(AccessControl.ifObjectFieldIsAccessible('Service_Order_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectFieldIsAccessible('Service_Order_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<Service_Order_Header__c> soHeaderList = new List<Service_Order_Header__c>();
        for(Service_Order_Header__c soHeaderRec :  Database.query(query)) {
        	soHeaderList.add(soHeaderRec);
        }
        return soHeaderList;
    }
}