global without sharing class FetchVendorFromQBBatch implements Database.Batchable<Integer>, Database.AllowsCallouts, Database.Stateful {
    
    public Integer APICounter = 0;
    public Boolean recordFound = false;
    public String defaultPurchaseTaxId;
    public String defaultVendorAccountTypeId;
    String homeCurr;
    List<IFW_IntegrationConfig__c> integrationConfigList;

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
        homeCurr = AccountingUtil.getHomeCurrency();
        if(integrationConfigList == null) {
            integrationConfigList = IFW_SOQLUtil.getIntegrationConfigWithItems(QBUtil.QUICKBOOKS_ONLINE, null);
            if(integrationConfigList.isEmpty()) throw new BlackPurlException('IFW record for ' + QBUtil.QUICKBOOKS_ONLINE + ' doesn\'t exists');
        }
        return new List<Integer>{APICounter};
    }
    
    global void execute(Database.batchableContext bc, List<Integer> apiCountList) {
        List<QBVendorDTO> vendorList = new List<QBVendorDTO>();
        String query = 'SELECT * FROM Vendor WHERE Active = true';
        if(APICounter != 0) {
            query += ' STARTPOSITION '+ ((APICounter * 100) + 1);
        }
        query = EncodingUtil.urlEncode(query, 'UTF-8').replaceAll('\\+','%20');
        try {
            QBQueryResponseWrapper.QBResponseWrapper responseObj = QBCalloutManager.getDataAndUpdateRecords('Vendor', query, integrationConfigList[0]);
            if(responseObj != null && responseObj.Vendor != null && responseObj.Vendor.size() > 0) {
                vendorList.addAll(responseObj.Vendor);
                updateVendorInBlackPurl(vendorList);
                recordFound = true;
            }
        } catch(Exception e) {}
    }
    
    global void finish(Database.batchableContext bc) {
        APICounter++;
        if(recordFound) {
            Database.executeBatch(new FetchVendorFromQBBatch(APICounter));
        }
    }

    public void updateVendorInBlackPurl(List<QBVendorDTO> vendorList) {
        Set<String> currCodeSet = new Set<String>();
        Set<String> vendorNameSet = getVendorNameSet(vendorList, currCodeSet);
        Map<String, Country__c> currCodeToCountryRecMap = new Map<String, Country__c>();
        if(currCodeSet.size() > 0) {
            for(Country__c countryRec: [SELECT Id, Currency_Code__c FROM Country__c WHERE Currency_Code__c IN :currCodeSet]) {
                if(!currCodeToCountryRecMap.containsKey(countryRec.Currency_Code__c)) {
                    currCodeToCountryRecMap.put(countryRec.Currency_Code__c, countryRec);
                }
            }
        }

        List<Account> bpVendorList = [SELECT Name, Is_Foreign_Vendor__c, Country__r.Currency_Code__c FROM Account WHERE Name IN: vendorNameSet AND Is_Vendor__c = true];
        Map<String, List<Account>> nameToVendorListMap = new Map<String, List<Account>>();
        for(Account acc : bpVendorList) {
            if(!nameToVendorListMap.containsKey((acc.Name).toLowerCase())) {
                nameToVendorListMap.put((acc.Name).toLowerCase(), new List<Account>());
            }
            nameToVendorListMap.get((acc.Name).toLowerCase()).add(acc);
        }
        
        List<Account> vendorListToUpsert = new List<Account>();
        for(QBVendorDTO vendorObj : vendorList) {
            Account vendorRec = new Account();
            vendorRec.Vendor_AccountingId__c = vendorObj.Id;
            vendorRec.Vendor_SyncToken__c = vendorObj.SyncToken;
            if(nameToVendorListMap.containsKey((vendorObj.DisplayName).toLowerCase())) {
                setMatchedVendorDataInBP(vendorRec, nameToVendorListMap.get((vendorObj.DisplayName).toLowerCase()), vendorObj, currCodeToCountryRecMap);
            } else {
                setVendorDataForNewVendorInBP(vendorRec, vendorObj, currCodeToCountryRecMap);
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

    private void setMatchedVendorDataInBP(Account vendorRec, List<Account> matchedVendorList, QBVendorDTO vendorObj, Map<String, Country__c> currCodeToCountryRecMap) {
        if(matchedVendorList.size() > 0) {
            if(String.isBlank(homeCurr)) {
                vendorRec.Id = matchedVendorList[0].Id;
            } else {
                if(vendorObj.CurrencyRef == null || String.isBlank(vendorObj.CurrencyRef.value)  || (homeCurr == vendorObj.CurrencyRef.value)) {
                    for(Account accRec: matchedVendorList) {
                        if(!accRec.Is_Foreign_Vendor__c) {
                            vendorRec.Id = accRec.Id;
                            break;
                        }
                    }
                } else if(vendorObj.CurrencyRef != null) {
                    for(Account accRec: matchedVendorList) {
                        if(accRec.Is_Foreign_Vendor__c && (accRec.Country__r.Currency_Code__c == vendorObj.CurrencyRef.value)) {
                            vendorRec.Id = accRec.Id;
                            break;
                        }
                    }
                }
            }
        }
        if(vendorRec.Id == null) {
            setVendorDataForNewVendorInBP(vendorRec, vendorObj, currCodeToCountryRecMap);
        }
	}

    private void setVendorDataForNewVendorInBP(Account vendorRec, QBVendorDTO vendorObj, Map<String, Country__c> currCodeToCountryRecMap) {
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
            vendorRec.BillingState = (vendorObj.BillAddr.CountrySubDivisionCode != null && (vendorObj.BillAddr.CountrySubDivisionCode).length() != 2) ? AbbreviationsUtil.getStateAbbreviationsByName(vendorRec.BillingCountry , vendorObj.BillAddr.CountrySubDivisionCode) : vendorObj.BillAddr.CountrySubDivisionCode;
            vendorRec.BillingPostalCode = vendorObj.BillAddr.PostalCode != null ? vendorObj.BillAddr.PostalCode : '';
        }
        if(vendorObj.ShipAddr != null) {
            vendorRec.ShippingStreet = (vendorObj.ShipAddr.Line1 != null ? vendorObj.ShipAddr.Line1 : '') + '\n' + (vendorObj.ShipAddr.Line2 != null ? vendorObj.ShipAddr.Line2 : '');
            vendorRec.ShippingCity = vendorObj.ShipAddr.City != null ? vendorObj.ShipAddr.City : '';
            vendorRec.ShippingCountry = vendorObj.ShipAddr.Country != null ? vendorObj.ShipAddr.Country : '';
            vendorRec.ShippingState = (vendorObj.ShipAddr.CountrySubDivisionCode != null && (vendorObj.ShipAddr.CountrySubDivisionCode).length() != 2) ? AbbreviationsUtil.getStateAbbreviationsByName(vendorRec.ShippingCountry , vendorObj.ShipAddr.CountrySubDivisionCode) : vendorObj.ShipAddr.CountrySubDivisionCode;
            vendorRec.ShippingPostalCode = vendorObj.ShipAddr.PostalCode != null ? vendorObj.ShipAddr.PostalCode : '';
        }
        if(String.isNotBlank(homeCurr) && vendorObj.CurrencyRef != null && String.isNotBlank(vendorObj.CurrencyRef.value) && 
            (homeCurr != vendorObj.CurrencyRef.value) && currCodeToCountryRecMap.containsKey(vendorObj.CurrencyRef.value)) { // if multi-curr enabled in BP
            vendorRec.Is_Foreign_Vendor__c = true;
            vendorRec.Country__c = currCodeToCountryRecMap.get(vendorObj.CurrencyRef.value).Id;
        }
    }
    
    public Set<String> getVendorNameSet(List<QBVendorDTO> vendorList, Set<String> currCodeSet) {
        Set<String> vendorNameSet = new Set<String>();
        for(QBVendorDTO vendor : vendorList) {
            vendorNameSet.add(vendor.DisplayName);
            if(String.isNotBlank(homeCurr) && vendor.CurrencyRef != null && String.isNotBlank(vendor.CurrencyRef.value) && 
                (homeCurr != vendor.CurrencyRef.value)) {
                currCodeSet.add(vendor.CurrencyRef.value);
            }
        }
        return vendorNameSet;
    }
}