global without sharing class FetchVendorFromQBBatch implements Database.Batchable<Integer>, Database.AllowsCallouts, Database.Stateful {
    
    public Integer APICounter = 0;
    public Boolean recordFound = false;
    public String defaultPurchaseTaxId;
    public String defaultVendorAccountTypeId;

    global FetchVendorFromQBBatch() {
    }

    global FetchVendorFromQBBatch(Integer APICounter) {
        this.APICounter = APICounter;
    }
    
    global Iterable<Integer> start(Database.BatchableContext bc) {
        List<Account_Type__c> accTypeList = [Select Id From Account_Type__c Where Applies_To__c = 'Vendors' AND Active__c = true AND Default__c = true Limit 1];
        if(accTypeList.size() > 0) {
            defaultVendorAccountTypeId = accTypeList[0].Id;
        }
        defaultPurchaseTaxId = GeneralConfiguration.getOrderingTaxRate();
        if(String.isBlank(defaultPurchaseTaxId)) {
            List<Sales_Tax__c> salesTaxList = [Select Id From Sales_Tax__c Where Tax_Type__c = 'Purchase' AND Active__c = true AND Default__c = true Limit 1];
            if(salesTaxList.size() > 0) {
                defaultPurchaseTaxId = salesTaxList[0].Id;
            }
        }
        return new List<Integer>{APICounter};
    }
    
    global void execute(Database.batchableContext bc, List<Integer> apiCountList) {
        QueryResponseWrapper vendorInfo = new QueryResponseWrapper();
        List<VendorWrapper> vendorList = new List<VendorWrapper>();
        String query = 'SELECT * FROM Vendor WHERE Active = true';
        if(APICounter != 0) {
            query += ' STARTPOSITION '+ ((APICounter * 100) + 1);
        }
        query = EncodingUtil.urlEncode(query, 'UTF-8').replaceAll('\\+','%20');
        
        QuickbookConnector.ResponseWrapper responseObj = QuickbookConnector.getRequestFromQB('query?query='+query, null);
        HttpResponse res = responseObj.Response;
        if(responseObj.RefreshToken !=  null) {
            QBUtil.saveRefreshToken(responseObj.RefreshToken, responseObj.RefreshTokenExpiresIn);
        }
        if(res.getStatusCode() == 200){
            vendorInfo = (QueryResponseWrapper) System.JSON.deserialize(res.getBody(), QueryResponseWrapper.class);
            if(vendorInfo.QueryResponse != null && vendorInfo.QueryResponse.Vendor != null && vendorInfo.QueryResponse.Vendor.size() > 0) {
                vendorList.addAll(vendorInfo.QueryResponse.Vendor);
                updateVendorInBlackPurl(vendorList);
                recordFound = true;
            }
        } else {
            /*new LogService().createErrorLog('FetchVendorFromQBBatch', 'updateVendorInBlackPurl()', res.getBody(), res.getStatusCode(), null, 
                                          null, LogService.QUICKBOOKS);*/
        }
    }
    
    global void finish(Database.batchableContext bc) {
        APICounter++;
        if(recordFound) {
            Database.executeBatch(new FetchVendorFromQBBatch(APICounter));
        }
    }

    public void updateVendorInBlackPurl(List<VendorWrapper> vendorList) { 
       Set<String> vendorNameSet = getVendorNameSet(vendorList);
        List<Account> bpVendorList = [SELECT Name FROM Account WHERE Name IN: vendorNameSet AND Is_Vendor__c = true];
        Map<String, List<Account>> nameToVendorListMap = new Map<String, List<Account>>();
        for(Account acc : bpVendorList) {
            if(!nameToVendorListMap.containsKey(acc.Name)) {
                nameToVendorListMap.put(acc.Name, new List<Account>());
            }
            nameToVendorListMap.get(acc.Name).add(acc);
        }
        
        List<Account> vendorListToUpsert = new List<Account>();
        for(VendorWrapper vendorObj : vendorList) {
            Account vendorRec = new Account();
            vendorRec.Vendor_AccountingId__c = vendorObj.Id;
            vendorRec.Vendor_SyncToken__c = vendorObj.SyncToken;
            if(nameToVendorListMap.containsKey(vendorObj.DisplayName)) {
                vendorRec.Id = nameToVendorListMap.get(vendorObj.DisplayName)[0].Id;
            } else {
            vendorRec.Name = vendorObj.DisplayName;
            vendorRec.Company_Name__c = String.isNotBlank(vendorObj.CompanyName) ? vendorObj.CompanyName : vendorObj.DisplayName;
            vendorRec.Active__c = true;
            vendorRec.Is_Vendor__c = true;
            vendorRec.Type__c = 'Business';
            vendorRec.Vendor_Account_Type__c = defaultVendorAccountTypeId;
            vendorRec.Purchase_Tax__c = defaultPurchaseTaxId;
            
            vendorRec.Work_Email__c = (vendorObj.PrimaryEmailAddr != null && vendorObj.PrimaryEmailAddr.Address != null) ? 
                                        vendorObj.PrimaryEmailAddr.Address : null;
            vendorRec.Work_Number__c = (vendorObj.PrimaryPhone != null && vendorObj.PrimaryPhone.FreeFormNumber != null) ? 
                                        vendorObj.PrimaryPhone.FreeFormNumber : null;

            vendorRec.Website = (vendorObj.WebAddr != null && vendorObj.WebAddr.URI != null) ? 
                                 vendorObj.WebAddr.URI : null;

            if(vendorObj.BillAddr != null) {
                vendorRec.BillingStreet = (vendorObj.BillAddr.Line1 != null ? vendorObj.BillAddr.Line1 : '') + '\n' + (vendorObj.BillAddr.Line2 != null ? vendorObj.BillAddr.Line2 : '');
                vendorRec.BillingCity = vendorObj.BillAddr.City != null ? vendorObj.BillAddr.City : '';
                vendorRec.BillingCountry = vendorObj.BillAddr.Country != null ? vendorObj.BillAddr.Country : '';
                vendorRec.BillingState = vendorObj.BillAddr.CountrySubDivisionCode != null ? vendorObj.BillAddr.CountrySubDivisionCode : '';
                vendorRec.BillingPostalCode = vendorObj.BillAddr.PostalCode != null ? vendorObj.BillAddr.PostalCode : '';
            }
            if(vendorObj.ShipAddr != null) {
                vendorRec.ShippingStreet = (vendorObj.ShipAddr.Line1 != null ? vendorObj.ShipAddr.Line1 : '') + '\n' + (vendorObj.ShipAddr.Line2 != null ? vendorObj.ShipAddr.Line2 : '');
                vendorRec.ShippingCity = vendorObj.ShipAddr.City != null ? vendorObj.ShipAddr.City : '';
                vendorRec.ShippingCountry = vendorObj.ShipAddr.Country != null ? vendorObj.ShipAddr.Country : '';
                vendorRec.ShippingState = vendorObj.ShipAddr.CountrySubDivisionCode != null ? vendorObj.ShipAddr.CountrySubDivisionCode : '';
                vendorRec.ShippingPostalCode = vendorObj.ShipAddr.PostalCode != null ? vendorObj.ShipAddr.PostalCode : '';
            }
        }
            vendorListToUpsert.add(vendorRec);
        }

        if(vendorListToUpsert.size() > 0) {
            if(!AccessControl.ifObjectFieldIsCreateable('Account')) { throw new BlackPurlException('Account' + DMLUtility.NOT_CREATABLE); }
            if(!AccessControl.ifObjectFieldIsUpdateable('Account')) { throw new BlackPurlException('Account' + DMLUtility.NOT_UPDATABLE); }
            List<Database.UpsertResult> upsertResultList = Database.upsert(vendorListToUpsert, false);
            List<Log__c> logList = new List<Log__c>();
            
            for(Integer i = 0; i < upsertResultList.size(); i++) {
                if(!upsertResultList[i].isSuccess()) {
                    Log__c logRec = new Log__c();
                    logRec.Type__c = 'Info';
                    logRec.Apex_Class__c = 'FetchVendorFromQBBatch';
                    logRec.Method_Params__c = vendorListToUpsert[i].AccountingId__c;
                    logRec.Log_Info__c = upsertResultList[i].getErrors()[0].getFields() + '  \n' + upsertResultList[i].getErrors()[0].getMessage();
                    logList.add(logRec);
                }
            }
            if(logList.size() > 0) {
                insert logList;
            }
        }
    }
    
    public Set<String> getVendorNameSet(List<VendorWrapper> vendorList) {
        Set<String> vendorNameSet = new Set<String>();
        for(VendorWrapper vendor : vendorList) {
            vendorNameSet.add(vendor.DisplayName);
        }
        return vendorNameSet;
    }
    
    public class QueryResponseWrapper{
        public AccountQueryResponseWrapper QueryResponse;
    }
    public class AccountQueryResponseWrapper {
        public List<VendorWrapper> Vendor;
    }
    public class VendorWrapper {
        public String Id;
        public String SyncToken;
        public String DisplayName;
        public String CompanyName;
        public Boolean Active;
        public Boolean sparse;
        public QuickBooksPhoneWrapper PrimaryPhone;
        public QuickBooksPhoneWrapper AlternatePhone;
        public QuickBooksPhoneWrapper Mobile;
        public QuickBooksPhoneWrapper Fax;
        public QuickBooksEmailWrapper PrimaryEmailAddr;
        public QuickBooksAddressWrapper BillAddr;
        public QuickBooksAddressWrapper ShipAddr;
        public QuickBooksWebWrapper WebAddr;
    }
    
    public class QuickBooksPhoneWrapper{
        public String FreeFormNumber;
    }
     
    public class QuickBooksEmailWrapper{
        public String Address;
    }
     
    public class QuickBooksWebWrapper{
        public String URI;
    }

    public class QuickBooksAddressWrapper {
        public String Line1;
        public String Line2;
        public String City;
        public String Country;
        public String CountrySubDivisionCode;
        public String PostalCode;
    }
}