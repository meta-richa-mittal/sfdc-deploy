public without sharing class BRPRetailTransactionService {
    public static Set<String> brpVendorsIdSet = BRPUtility.getAllBRPVendorsIdSet();
    public static Set<String> brpUnitMakeIdSet = BRPUtility.getAllBRPUnitMakeIdSet();

    public static String createRequestBody(CO_Invoice_Header__c coInvoiceHeaderRec, List<CO_Line_Item__c> coliList, List<Service_Order_Header__c> soList, List<Deal__c> dealList) {
        String requestBody = System.JSON.serialize(getTransactionsData(coInvoiceHeaderRec, coliList, soList, dealList), true);
        requestBody = requestBody.replace('currency_code', 'currency');
        if(requestBody.containsIgnoreCase('\"customer_hash_value\"')) {
            requestBody = requestBody.replace('\"customer_hash_value\"', 'null');
        }
        return requestBody;
    }
    
    private static BRPRetailTransactionWrapper getTransactionsData(CO_Invoice_Header__c coInvoiceHeaderRec, List<CO_Line_Item__c> coliList, List<Service_Order_Header__c> soList, List<Deal__c> dealList) {
        BRPRetailTransactionWrapper transactionsObj = new BRPRetailTransactionWrapper(); 
        transactionsObj.transactions = new List<BRPRetailTransactionWrapper.TransactionWrapper>();
        if(coInvoiceHeaderRec != null) {
            transactionsObj.transactions.add(setTransactionData(coInvoiceHeaderRec, coliList, soList, dealList)); 
        }
        return transactionsObj;
    }

    private static BRPRetailTransactionWrapper.TransactionWrapper setTransactionData(CO_Invoice_Header__c coInvoiceHeader, List<CO_Line_Item__c> coliList, List<Service_Order_Header__c> soList, List<Deal__c> dealList) {
        BRPRetailTransactionWrapper.TransactionWrapper transactionObj = new BRPRetailTransactionWrapper.TransactionWrapper();
        transactionObj.header = setCoInvoiceHeaderData(coInvoiceHeader);
        transactionObj.parts = new List<BRPRetailTransactionWrapper.PartWrapper>();
        transactionObj.jobs = new List<BRPRetailTransactionWrapper.JobWrapper>();
        transactionObj.units = new List<BRPRetailTransactionWrapper.UnitWrapper>();
        if(!coliList.isEmpty()) {
            transactionObj.parts = setPartsData(coInvoiceHeader, coliList);
        }
        if(!soList.isEmpty()) {
            transactionObj.jobs = setJobsData(coInvoiceHeader, soList);
        }
        if(!dealList.isEmpty()) {
            transactionObj.units = setUnitsData(coInvoiceHeader, dealList);
        }
        return transactionObj;
    }

    private static BRPRetailTransactionWrapper.HeaderWrapper setCoInvoiceHeaderData(CO_Invoice_Header__c coInvoiceHeader) { 
        BRPRetailTransactionWrapper.HeaderWrapper header = new BRPRetailTransactionWrapper.HeaderWrapper();
        header.transaction_number = coInvoiceHeader.Invoice_Number__c;
        header.transaction_open_date = (coInvoiceHeader.CO_Header__r.CreatedDate).format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
        header.transaction_close_date = (coInvoiceHeader.Closed_Invoice_Date__c).format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
        header.transaction_source = 'In-Store';
        header.cancel_flag  = false;
        header.transaction_uuid = BRPUtility.generateBodId();
        header.customers = setCustomersData(coInvoiceHeader);
        return header;
    }

    private static List<BRPRetailTransactionWrapper.CustomerWrapper> setCustomersData(CO_Invoice_Header__c coInvoiceHeader) { 
        BRPRetailTransactionWrapper.CustomerWrapper customer = new BRPRetailTransactionWrapper.CustomerWrapper();
        if(coInvoiceHeader.CO_Header__r.Customer__c != null) {
            customer.customer_id = coInvoiceHeader.CO_Header__r.Customer__r.Customer_Number__c;
            if(String.isNotBlank(coInvoiceHeader.CO_Header__r.Customer__r.Phone_Number__c) && String.isNotBlank(coInvoiceHeader.CO_Header__r.Customer__r.Email_Address__c)) {
                customer.customer_hash = BRPUtility.generateHash(coInvoiceHeader.CO_Header__r.Customer__r.Phone_Number__c + ' ' + coInvoiceHeader.CO_Header__r.Customer__r.Email_Address__c);
            } else {
                customer.customer_hash = 'customer_hash_value';
            }
            customer.recipient = coInvoiceHeader.CO_Header__r.Customer__r.Type__c == 'Business' ? 'Dealership' : 'Customer';
            customer.city = coInvoiceHeader.CO_Header__r.Customer__r.BillingCity;
            customer.state_province = coInvoiceHeader.CO_Header__r.Customer__r.BillingState;
            customer.country = coInvoiceHeader.CO_Header__r.Customer__r.BillingCountry;
        } else {
            customer.customer_id = 'GUEST';
            customer.customer_hash = 'customer_hash_value';
            customer.recipient = coInvoiceHeader.CO_Header__r.CO_Type__c == 'Internal Service' ? 'Self' : 'Customer';
        }
        return new List<BRPRetailTransactionWrapper.CustomerWrapper> {customer};
    }

    private static List<BRPRetailTransactionWrapper.PartWrapper> setPartsData(CO_Invoice_Header__c coInvoiceHeader, List<CO_Line_Item__c> coliList) { 
        List<BRPRetailTransactionWrapper.PartWrapper> partsList = new List<BRPRetailTransactionWrapper.PartWrapper>();
        for(CO_Line_Item__c coliRec: coliList) {
            BRPRetailTransactionWrapper.PartWrapper partObj = new BRPRetailTransactionWrapper.PartWrapper();
            if(brpVendorsIdSet.contains(coliRec.Part__r.Vendor__c)) {
                partObj.part_description =  coliRec.Part__r.Description__c;
                partObj.part_number = coliRec.Part__r.Part_Number__c;
            } else {
                partObj.part_description =  'NON-BRP-PARTS';
                partObj.part_number = 'NON-BRP-PARTS';
            }
            partObj.part_description = BPUtility.getTrimedStringByGivenLimit(partObj.part_description, 128);
            partObj.part_number = BPUtility.getTrimedStringByGivenLimit(partObj.part_number, 18);

            partObj.quantity = (coliRec.Qty__c != null ? coliRec.Qty__c : 1);
            partObj.quantity_uom = coliRec.Part__r.Packaged_Part__c ? coliRec.Part__r.Package_Unit__c : 'PC';
            partObj.is_special_order = false;
            partObj.total_customer_price = coliRec.Sub_Total_Without_Tax__c != null ? coliRec.Sub_Total_Without_Tax__c : 0; 
            if(!coliRec.Individual_Taxes__r.isEmpty()) {
                partObj.total_customer_price += TaxCalculation.getTaxAmount_V2(coliRec.Individual_Taxes__r);
            }
            partObj.currency_code = BRPUtility.CurrencyCode;
            partObj.dealer_price = coliRec.Part__r.Retail_Price__c;
            partObj.dealer_cost = coliRec.Part__r.Last_Cost__c;
            partObj.msrp = coliRec.Part__r.MSRP__c;
            if(coliRec.Service_Order_Line_Item__c != null && (brpVendorsIdSet.contains(coliRec.Service_Order_Line_Item__r.Service_Order_Header__r.Customer_Owned_Unit__r.Vendor__c) 
                || brpUnitMakeIdSet.contains(coliRec.Service_Order_Line_Item__r.Service_Order_Header__r.Customer_Owned_Unit__r.Unit_Make__c))) {
                partObj.associated_job_number = coliRec.Service_Order_Line_Item__r.Service_Order_Header__r.Name;
                partObj.associated_job_number = BPUtility.getTrimedStringByGivenLimit(partObj.associated_job_number, 36);
            }

            partObj.additional_costs = new List<BRPRetailTransactionWrapper.AdditionalCostsWrapper>();
            
            for(Individual_Tax__c indTaxRec: coliRec.Individual_Taxes__r) {
                partObj.additional_costs.add(setTaxTypeAdditionalCosts(indTaxRec));
            }

            if(coliRec.Discount__c != null && coliRec.Discount__c != 0) {
                BRPRetailTransactionWrapper.AdditionalCostsWrapper additionalCostObj = new BRPRetailTransactionWrapper.AdditionalCostsWrapper();
                additionalCostObj.type = 'Discount';
                additionalCostObj.description = 'Discount'; 
                additionalCostObj.amount = (coliRec.Discount__c * -1 * partObj.quantity).setScale(2, RoundingMode.HALF_UP);
                partObj.additional_costs.add(additionalCostObj);
            }

            partsList.add(partObj);
        }   
        return partsList;
    }


    private static BRPRetailTransactionWrapper.AdditionalCostsWrapper setTaxTypeAdditionalCosts(Individual_Tax__c indTaxRec) {
    	indTaxRec.Tax_Rate__c = indTaxRec.Tax_Rate__c != null ? indTaxRec.Tax_Rate__c : 0.00;
        Decimal taxAmount = TaxCalculation.getTaxAmount_V2(new List<Individual_Tax__c>{indTaxRec});
        BRPRetailTransactionWrapper.AdditionalCostsWrapper additionalCostObj = new BRPRetailTransactionWrapper.AdditionalCostsWrapper();
        additionalCostObj.type = 'Tax';
        additionalCostObj.description = String.isNotBlank(indTaxRec.Sales_Tax_Item_Name__c) ? indTaxRec.Sales_Tax_Item_Name__c : ''; 
        additionalCostObj.amount = taxAmount;
        return additionalCostObj;
    }

    private static List<BRPRetailTransactionWrapper.UnitWrapper> setUnitsData(CO_Invoice_Header__c coInvoiceHeader, List<Deal__c> dealList) { 
        List<BRPRetailTransactionWrapper.UnitWrapper> unitsList = new List<BRPRetailTransactionWrapper.UnitWrapper>();
        Map<String, List<Option_Fee__c>> dealItemToOptionFeeListMap;
        for(Deal__c dealRec : dealList) {
            List<Deal_Item__c> tradeInUnitList = new List<Deal_Item__c>();
            dealItemToOptionFeeListMap = new Map<String, List<Option_Fee__c>>();

            for(Option_Fee__c optionFeeRec : dealRec.Options_Fees__r) {
                if(!dealItemToOptionFeeListMap.containsKey(optionFeeRec.Deal_Item__c)) {
                    dealItemToOptionFeeListMap.put(optionFeeRec.Deal_Item__c, new List<Option_Fee__c>());
                }
                dealItemToOptionFeeListMap.get(optionFeeRec.Deal_Item__c).add(optionFeeRec);
            }


            Decimal adjustmentRatio = (dealRec.Subtotal__c != null && dealRec.Subtotal__c != 0) ? (dealRec.Deal_Tax_Total__c / dealRec.Subtotal__c) : 0;
        	if(adjustmentRatio < 0) {
                adjustmentRatio *= -1;
            }
            for(Deal_Item__c dealItemRec : dealRec.Deal_Items__r) {
                if(dealItemRec.Type__c != 'Trade In' || (dealItemRec.Type__c == 'Trade In' && dealRec.Deal_Section_Trade_Only__c)) {
                    BRPRetailTransactionWrapper.UnitWrapper unitWrapperObj = new BRPRetailTransactionWrapper.UnitWrapper();
                    unitWrapperObj.vin = dealItemRec.Customer_Owned_Unit__r.VIN_Number_Formula__c;
                    unitWrapperObj.vin = BPUtility.getTrimedStringByGivenLimit(unitWrapperObj.vin, 17);
                    Decimal MileageValue = dealItemRec.Customer_Owned_Unit__r.Mileage_Value__c != null ? dealItemRec.Customer_Owned_Unit__r.Mileage_Value__c : 0;
                    
                    if(dealItemRec.Customer_Owned_Unit__r.Mileage_Type__c == 'Km' || dealItemRec.Customer_Owned_Unit__r.Mileage_Type__c == 'Mi') {
                        MileageValue = (dealItemRec.Customer_Owned_Unit__r.Mileage_Type__c == 'Km') ? MileageValue : (MileageValue * 1.60934).setScale(2, RoundingMode.HALF_UP);
                        unitWrapperObj.odometer_reading = MileageValue;
                    } else {
                        unitWrapperObj.hours = MileageValue;
                    }
                    unitWrapperObj.class_code = dealItemRec.Customer_Owned_Unit__r.New_Unit__c ? 'New' : 'Used';
                    unitWrapperObj.currency_code = BRPUtility.CurrencyCode;
                    unitWrapperObj.dealer_price = dealItemRec.Total_Price__c - (dealItemRec.Unit_Option_Price__c != null ? dealItemRec.Unit_Option_Price__c : 0);
                    unitWrapperObj.dealer_cost = dealItemRec.Customer_Owned_Unit__r.Total_Cost__c != null ? dealItemRec.Customer_Owned_Unit__r.Total_Cost__c : 0.00;
                    unitWrapperObj.msrp = unitWrapperObj.dealer_price;
                    unitWrapperObj.total_customer_price = dealItemRec.Total_Price__c - (dealItemRec.Fee_Total_Included_In_Profitability__c != null ? dealItemRec.Fee_Total_Included_In_Profitability__c : 0) + (dealItemRec.Fee_Total__c != null ? dealItemRec.Fee_Total__c : 0);
                    unitWrapperObj.additional_costs = new List<BRPRetailTransactionWrapper.AdditionalCostsWrapper>();

                    if(dealItemToOptionFeeListMap.containsKey(dealItemRec.Id)) {
                        for(Option_Fee__c optionFee : dealItemToOptionFeeListMap.get(dealItemRec.Id)) {
                            BRPRetailTransactionWrapper.AdditionalCostsWrapper additionalCostObj = new BRPRetailTransactionWrapper.AdditionalCostsWrapper();
                            additionalCostObj.type = 'Logistic';
                            additionalCostObj.description = optionFee.Item_Code__c + ' - ' + optionFee.Item_Description__c; 
                            additionalCostObj.description = BPUtility.getTrimedStringByGivenLimit(additionalCostObj.description, 255);
                            additionalCostObj.amount = optionFee.Revenue__c;
                            unitWrapperObj.additional_costs.add(additionalCostObj);
                        }
                    }
                    
                    if(adjustmentRatio != 0) {
                        BRPRetailTransactionWrapper.AdditionalCostsWrapper additionalCostObj = new BRPRetailTransactionWrapper.AdditionalCostsWrapper();
                        additionalCostObj.type = 'Tax';
                        additionalCostObj.description = 'Deal tax'; 
                        additionalCostObj.amount = (unitWrapperObj.total_customer_price * adjustmentRatio).setScale(2, RoundingMode.HALF_UP);
                        unitWrapperObj.total_customer_price += additionalCostObj.amount;
                        unitWrapperObj.additional_costs.add(additionalCostObj);
                    }
                    if(dealRec.Type__c == 'Financed' && !dealRec.Deal_Finances__r.isEmpty()) {
                        unitWrapperObj.financed_amount = dealRec.Deal_Finances__r[0].Approved_Amount_Financed__c;
                        unitWrapperObj.financed_rate = dealRec.Deal_Finances__r[0].Interest_Rate__c;
                        unitWrapperObj.financed_term_duration = (dealRec.Deal_Finances__r[0].Loan_Term__c != null ? dealRec.Deal_Finances__r[0].Loan_Term__c : 0) * (dealRec.Deal_Finances__r[0].Term_Type__c == 'Years' ? 12 : 1);
                    }
                    unitWrapperObj.trade_ins = new List<BRPRetailTransactionWrapper.TradeInswrapper>();
                    unitsList.add(unitWrapperObj);
                } else {
                    tradeInUnitList.add(dealItemRec);
                }
            }

            if(!tradeInUnitList.isEmpty()) {
                setTradeInData(unitsList, tradeInUnitList, adjustmentRatio);
            }
        }
        return unitsList;
    }

    private static void setTradeInData(List<BRPRetailTransactionWrapper.UnitWrapper> unitsList, List<Deal_Item__c> tradeInUnitList, Decimal adjustmentRatio) {
        if (tradeInUnitList.isEmpty() || unitsList.isEmpty()) {
            return;
        }
    
        Integer unitIndex = 0;
        for (Deal_Item__c tradeInUnit : tradeInUnitList) {
            BRPRetailTransactionWrapper.TradeInswrapper tradeInObj = new BRPRetailTransactionWrapper.TradeInswrapper();
            tradeInObj.manufacturer = tradeInUnit.Customer_Owned_Unit__r.Make_Name__c;
            tradeInObj.manufacturer = BPUtility.getTrimedStringByGivenLimit(tradeInObj.manufacturer, 36);
            tradeInObj.vin = tradeInUnit.Customer_Owned_Unit__r.VIN_Number_Formula__c;
            tradeInObj.vin = BPUtility.getTrimedStringByGivenLimit(tradeInObj.vin, 17);
            Decimal mileageValue = tradeInUnit.Customer_Owned_Unit__r.Mileage_Value__c != null ? tradeInUnit.Customer_Owned_Unit__r.Mileage_Value__c : 0;
            if (tradeInUnit.Customer_Owned_Unit__r.Mileage_Type__c == 'Km' || tradeInUnit.Customer_Owned_Unit__r.Mileage_Type__c == 'Mi') {
                mileageValue = (tradeInUnit.Customer_Owned_Unit__r.Mileage_Type__c == 'Km') ? mileageValue : (mileageValue * 1.60934).setScale(2, RoundingMode.HALF_UP);
                tradeInObj.odometer_reading = mileageValue;
            } else {
                tradeInObj.hours = mileageValue;
            }
    
            tradeInObj.price = -1 * tradeInUnit.Agreed_Value__c;
            tradeInObj.year = (Integer) tradeInUnit.Customer_Owned_Unit__r.Year__c;

            if(adjustmentRatio != 0) {
                BRPRetailTransactionWrapper.AdditionalCostsWrapper additionalCostObj = new BRPRetailTransactionWrapper.AdditionalCostsWrapper();
                additionalCostObj.type = 'Tax';
                additionalCostObj.description = 'Trade-in tax'; 
                additionalCostObj.amount = (tradeInObj.price * adjustmentRatio).setScale(2, RoundingMode.HALF_UP);
                unitsList[unitIndex].total_customer_price += additionalCostObj.amount;
                unitsList[unitIndex].additional_costs.add(additionalCostObj);
            }
    
            unitsList[unitIndex].total_customer_price += tradeInObj.price;
            unitsList[unitIndex].trade_ins.add(tradeInObj);
    
            // Move to the next unit in the list, wrap around if necessary
            unitIndex++;
            if (unitIndex >= unitsList.size()) {
                unitIndex = 0;
            }
        }
    }

    private static List<BRPRetailTransactionWrapper.JobWrapper> setJobsData(CO_Invoice_Header__c coInvoiceHeader, List<Service_Order_Header__c> soList) { 
        Map<String, List<Individual_Tax__c>> soIdToIndividualTaxListMap = getSOIdToIndividualTaxListMap(soList);
        List<BRPRetailTransactionWrapper.JobWrapper> jobsList = new List<BRPRetailTransactionWrapper.JobWrapper>();
        for(Service_Order_Header__c soHeaderRec: soList) {
            BRPRetailTransactionWrapper.JobWrapper soObj = new BRPRetailTransactionWrapper.JobWrapper();
            soObj.additional_costs = new List<BRPRetailTransactionWrapper.AdditionalCostsWrapper>();
            soObj.job_number = BPUtility.getTrimedStringByGivenLimit(soHeaderRec.Name, 36);
            soObj.job_code = 'RPR';
            String miscNotes = ((soHeaderRec.SO_Cause__c != null ? soHeaderRec.SO_Cause__c + ' ' : '') +
    					(soHeaderRec.SO_Concern__c != null ? soHeaderRec.SO_Concern__c + ' ' : '') +
    					(soHeaderRec.SO_Correction__c != null ? soHeaderRec.SO_Correction__c : ''));
    	    miscNotes = miscNotes.length() > 255 ? miscNotes.subString(0, 255) : miscNotes;
            soObj.description = miscNotes;
            if(soHeaderRec.Transaction_Type__r.Type__c == 'Third-Party') {
                soObj.is_warranty_job = true;
                if(!soHeaderRec.Claims__r.isEmpty()) {
                    soObj.warranty_claim_number = BPUtility.getTrimedStringByGivenLimit(soHeaderRec.Claims__r[0].Provider_Claim_Number__c, 36);
                }
            } else {
                soObj.is_warranty_job = false;
            }
            soObj.total_customer_job_price = soHeaderRec.Total__c - soHeaderRec.Total_Parts__c;
            if(!GeneralConfiguration.getTaxIncludingPricing()) {
                Decimal taxAmount = soIdToIndividualTaxListMap.containsKey(soHeaderRec.Id) && !soIdToIndividualTaxListMap.get(soHeaderRec.Id).isEmpty() ? TaxCalculation.getTaxAmount_V2(soIdToIndividualTaxListMap.get(soHeaderRec.Id)) : 0;
                soObj.total_customer_job_price += taxAmount;
            }

            Decimal MileageValue = soHeaderRec.Customer_Owned_Unit__r.Mileage_Value__c != null ? soHeaderRec.Customer_Owned_Unit__r.Mileage_Value__c : 0;
            if(soHeaderRec.Customer_Owned_Unit__r.Mileage_Type__c == 'Km' || soHeaderRec.Customer_Owned_Unit__r.Mileage_Type__c == 'Mi') {
                MileageValue = (soHeaderRec.Customer_Owned_Unit__r.Mileage_Type__c == 'Km') ? MileageValue : (MileageValue * 1.60934).setScale(2, RoundingMode.HALF_UP);
                soObj.odometer_reading = MileageValue;
            } else {
                soObj.hours = MileageValue;
            }

            soObj.currency_code = BRPUtility.CurrencyCode;
            soObj.vin = soHeaderRec.Customer_Owned_Unit__r.VIN_Number__c;
            soObj.vin = BPUtility.getTrimedStringByGivenLimit(soObj.vin, 17);
            soObj.manufacturer = soHeaderRec.Customer_Owned_Unit__r.Make_Name__c;
            soObj.manufacturer = BPUtility.getTrimedStringByGivenLimit(soObj.manufacturer, 36);
            soObj.model = soHeaderRec.Customer_Owned_Unit__r.Model_Name__c;
            soObj.year = (Integer)soHeaderRec.Customer_Owned_Unit__r.Year__c;
            soObj.time_cards = new List<BRPRetailTransactionWrapper.TimeCardWrapper>();
            for(Service_Order_Line_Item__c soliRec : soHeaderRec.Service_Order_Line_Items__r) {
                if(soliRec.Labour_Code__c != null) {
                    BRPRetailTransactionWrapper.TimeCardWrapper timeCardObj = new BRPRetailTransactionWrapper.TimeCardWrapper();
                    timeCardObj.labour_worked_hours = soliRec.Qty_Needed__c;
                    timeCardObj.labour_billed_hours = soliRec.Qty_Needed__c;
                    timeCardObj.technician_party_id = BPUtility.getTrimedStringByGivenLimit(soliRec.Item_Desc__c, 36); 
                    timeCardObj.labour_rate = soliRec.Kit_Price__c;
                    soObj.time_cards.add(timeCardObj);
                } else {
                    BRPRetailTransactionWrapper.AdditionalCostsWrapper additionalCostObj = new BRPRetailTransactionWrapper.AdditionalCostsWrapper();
                    additionalCostObj.type = 'Logistic';
                    additionalCostObj.description = soliRec.Item_Desc__c; 
                    additionalCostObj.description = BPUtility.getTrimedStringByGivenLimit(additionalCostObj.description, 255);
                    additionalCostObj.amount = (soliRec.Kit_Price__c * soliRec.Qty_Needed__c).setScale(2, RoundingMode.HALF_UP);
                    soObj.additional_costs.add(additionalCostObj);
                }
            }
            if(soIdToIndividualTaxListMap.containsKey(soHeaderRec.Id)) {
                for(Individual_Tax__c indTaxRec: soIdToIndividualTaxListMap.get(soHeaderRec.Id)) {
                    soObj.additional_costs.add(setTaxTypeAdditionalCosts(indTaxRec));
                }
            }
            
            jobsList.add(soObj);
        }   
        return jobsList;
    }

    public static Map<String, List<CO_Line_Item__c>> getCOInvHeaderToCOLIListMap(List<CO_Invoice_Header__c> coInvList) {
    	String query = 'SELECT ' + String.join(objectToFieldMap.get('COLineItem'), ',') + ', ';
        
        query += '( SELECT ' + String.join(objectToFieldMap.get('IndividualTax'), ',') + ' FROM Individual_Taxes__r )';
        query += ' FROM CO_Line_Item__c WHERE Invoice_Number__c IN: coInvList AND Part__c != null AND ((Service_Order_Line_Item__c != null AND (Service_Order_Line_Item__r.Service_Order_Header__r.Customer_Owned_Unit__r.Vendor__c IN: brpVendorsIdSet OR Service_Order_Line_Item__r.Service_Order_Header__r.Customer_Owned_Unit__r.Unit_Make__c IN: brpUnitMakeIdSet)) OR (Part__r.Vendor__c IN: brpVendorsIdSet)) ';
        
        Map<String, List<CO_Line_Item__c>> coInvHeaderIdToCOLIListMap = new Map<String, List<CO_Line_Item__c>>();
        for(CO_Line_Item__c coliRec: Database.query(query)) {
        	if(!coInvHeaderIdToCOLIListMap.containsKey(coliRec.Invoice_Number__c)) {
        		coInvHeaderIdToCOLIListMap.put(coliRec.Invoice_Number__c, new List<CO_Line_Item__c>());
        	}
        	coInvHeaderIdToCOLIListMap.get(coliRec.Invoice_Number__c).add(coliRec);
        }
        
        return coInvHeaderIdToCOLIListMap;
    }

    public static Map<String, List<Service_Order_Header__c>> getCOInvHeaderToSOListMap(List<CO_Invoice_Header__c> coInvList) {
    	String query = 'SELECT ' + String.join(objectToFieldMap.get('SoHeader'), ',') + ', ';
        query += ' (Select ' + String.join(objectToFieldMap.get('SOLI'), ',') + ' FROM Service_Order_Line_Items__r WHERE Part__c = null), ';
        query += ' (Select Id, Provider_Claim_Number__c From Claims__r limit 1) ';
        query += ' FROM Service_Order_Header__c WHERE Invoice_Number__c IN: coInvList AND (Customer_Owned_Unit__r.Vendor__c IN: brpVendorsIdSet OR Customer_Owned_Unit__r.Unit_Make__c IN: brpUnitMakeIdSet) ';
        
        Map<String, List<Service_Order_Header__c>> coInvHeaderIdToSOListMap = new Map<String, List<Service_Order_Header__c>>();
        for(Service_Order_Header__c soRec: Database.query(query)) {
        	if(!coInvHeaderIdToSOListMap.containsKey(soRec.Invoice_Number__c)) {
        		coInvHeaderIdToSOListMap.put(soRec.Invoice_Number__c, new List<Service_Order_Header__c>());
        	}
        	coInvHeaderIdToSOListMap.get(soRec.Invoice_Number__c).add(soRec);
        }
        
        return coInvHeaderIdToSOListMap;
    }
    
    public static Map<String, List<Individual_Tax__c>> getSOIdToIndividualTaxListMap(List<Service_Order_Header__c> soHeaderList) {
    	String query = 'SELECT ' + String.join(objectToFieldMap.get('IndividualTax'), ',');
        query += ' FROM Individual_Tax__c WHERE Service_Order_Line_Item__r.Service_Order_Header__c IN: soHeaderList AND Service_Order_Line_Item__r.Part__c = null'; 
        
        Map<String, List<Individual_Tax__c>> soIdToIndividualTaxListMap = new Map<String, List<Individual_Tax__c>>();
        for(Individual_Tax__c individualTaxRec : Database.query(query)) {
        	String soId;
        	
    		soId = individualTaxRec.Service_Order_Line_Item__r.Service_Order_Header__c;
        	if(!soIdToIndividualTaxListMap.containsKey(soId)) {
        		soIdToIndividualTaxListMap.put(soId, new List<Individual_Tax__c>());
        	}
        	soIdToIndividualTaxListMap.get(soId).add(individualTaxRec);
        }
        
        return soIdToIndividualTaxListMap;
    }

    public static Map<String, List<Deal__c>> getCOInvHeaderToDealListMap(List<CO_Invoice_Header__c> coInvList) {
    	String query = 'SELECT ' + String.join(objectToFieldMap.get('Deal'), ',') + ', ';
        query += ' (Select ' + String.join(objectToFieldMap.get('OptionFees'), ',') + ' FROM Options_Fees__r), ';

        query += ' (Select ' + String.join(objectToFieldMap.get('DealFinance'), ',') + ' FROM Deal_Finances__r ), ';

        query += ' (Select ' + String.join(objectToFieldMap.get('DealItem'), ',');
        query += ' FROM Deal_Items__r WHERE Customer_Owned_Unit__r.Vendor__c IN: brpVendorsIdSet OR Customer_Owned_Unit__r.Unit_Make__c IN: brpUnitMakeIdSet OR Type__c = \'Trade In\') ';
        
        query += ' FROM Deal__c WHERE Invoice_Number__c IN: coInvList';
        
        Map<String, List<Deal__c>> coInvHeaderIdToDealListMap = new Map<String, List<Deal__c>>();
        System.debug(query);
        for(Deal__c dealRec: Database.query(query)) {
        	if(!coInvHeaderIdToDealListMap.containsKey(dealRec.Invoice_Number__c)) {
        		coInvHeaderIdToDealListMap.put(dealRec.Invoice_Number__c, new List<Deal__c>());
        	}
        	coInvHeaderIdToDealListMap.get(dealRec.Invoice_Number__c).add(dealRec);
        }
        return coInvHeaderIdToDealListMap;
    }

    public static Map<String, Set<String>> objectToFieldMap = new Map<String, Set<String>>{
        'COInvoiceHeader'       => new Set<String>{ 
                                            'Invoice_Date__c',
                                            'Invoice_Number__c',
                                            'Total__c',
                                            'Checkout_Type__c',
                                            'CO_Header__r.Customer__c',
                                            'Sub_Total__c',
                                            'Salesperson__c',
                                            'CO_Header__r.CO_Type__c',
                                            'CO_Header__r.CreatedDate',
                                            'Closed_Invoice_Date__c',
                                            'CO_Header__r.Customer__c',
                                            'CO_Header__r.Customer__r.Customer_Number__c',
                                            'CO_Header__r.Customer__r.Phone_Number__c',
                                            'CO_Header__r.Customer__r.Email_Address__c',
                                            'CO_Header__r.Customer__r.Type__c',
                                            'CO_Header__r.Customer__r.BillingCity',
                                            'CO_Header__r.Customer__r.BillingState',
                                            'CO_Header__r.Customer__r.BillingCountry',
                                            'Available_For_BRP_Repair_Order_Sync__c',
                                            'Available_For_BRP_RDR_Sync__c'
                                            },
        'COLineItem'            => new Set<String>{ 
                                                'Qty__c',
                                                'Price__c',
                                                'Adjusted_Cost_Coli__c',
                                                'Part__r.Part_Number__c',
                                                'Part__r.Description__c',
                                                'Part__r.Vendor__c',
                                                'Part__r.Last_Cost__c',
                                                'Part__r.Retail_Price__c',
                                                'Part__r.Package_Unit__c',
                                                'Part__r.Packaged_Part__c',
                                                'Sub_Total_Without_Tax__c',
                                                'Deal__c',
                                                'Invoice_Number__c',
                                                'Discount__c',
                                                'Part__r.MSRP__c',
                                                'Service_Order_Line_Item__c',
                                                'Service_Order_Line_Item__r.Service_Order_Header__r.Name',
                                                'Service_Order_Line_Item__r.Service_Order_Header__r.Customer_Owned_Unit__r.Unit_Make__c',
                                                'Service_Order_Line_Item__r.Service_Order_Header__r.Customer_Owned_Unit__r.Vendor__c'
                                },
       'SoHeader'            => new Set<String>{ 
        										'Name__c',
                                                'Name',
        										'SO_Cause__c',
        										'SO_Concern__c',
        										'SO_Correction__c',
        										'Odometer_on_Departure__c',
        										'Customer_Owned_Unit__r.VIN_Number__c',
        										'Customer_Owned_Unit__r.Mileage_Type__c',
                                                'Customer_Owned_Unit__r.Mileage_Value__c',
        										'Total__c',
        										'Tax_Amount__c',
        										'Transaction_Type__r.Type__c',
        										'CreatedDate',
        										'Invoice_Number__r.Invoice_Date__c',
                                                'Invoice_Number__r.Invoice_Number__c',
                                                'CO_Header__r.Name',
                                                'CO_Header__r.CO_Type__c',
                                                'Total_Parts__c',
                                                'Customer_Owned_Unit__r.Make_Name__c',
                                                'Customer_Owned_Unit__r.Model_Name__c',
                                                'Customer_Owned_Unit__r.Year__c'
                                },
        'SOLI'            => new Set<String>{ 
        										'Service_Order_Header__c',
                                                'Qty_Needed__c',
                                                'Kit_Price__c',
                                                'Retail_Price__c',
                                                'Total_Cost__c',
                                                'Part__r.Part_Number__c',
                                                'Part__r.Description__c',
                                                'Sublet__c',
                                                'Labour_Code__c',
                                                'CO_Line_Item__r.Adjusted_Cost_Coli__c',
                                                'CO_Line_Item__r.Qty__c',
                                                'Item_Desc__c'
                                },
       'IndividualTax'            => new Set<String>{ 
       											'Tax_Amount__c',
                                                'Tax_Rate__c',
                                                'Taxable_Amount__c',
                                                'Service_Order_Line_Item__c',
                                                'Sales_Tax_Item_Name__c',
                                                'CO_Line_Item__r.Service_Order_Line_Item__c',
                                                'Service_Order_Line_Item__r.Service_Order_Header__c',
                                                'CO_Line_Item__r.Service_Order_Line_Item__r.Service_Order_Header__c',
                                                'Service_Order_Line_Item__r.Service_Order_Header__r.Invoice_Number__c',
                                                'CO_Line_Item__r.Service_Order_Line_Item__r.Service_Order_Header__r.Invoice_Number__c',
												'Sales_Tax_Item__r.Name__c',
                                                'Enhanced_Tax_Amount__c',
                                                'Deal__c',
                                                'Taxable_Amount_for_Section_Header__c',
                                                'CO_Line_Item__c',
                                                'Form_Label__c',
                                                'Tax_Amount_To_Invoice__c',
                                                'Taxable_Amount_To_Invoice__c',
                                                'Applicable_Tax__c',
                                                'List_Tax_items_on_forms__c',
                                                'SO_Payment_Role__c'
                                },
        'Deal'            => new Set<String>{ 
        										'Name',
        										'Invoice_Number__r.Invoice_Date_Formula__c',
        										'Invoice_Number__r.Invoice_Date__c',
                                                'Invoice_Number__r.Invoice_Number__c',
                                                'CO_Header__r.Name',
                                                'CO_Header__r.Customer__r.Type__c',
												'CO_Header__r.Customer__r.Name',
												'CO_Header__r.Customer__r.Work_Number__c',
												'CO_Header__r.Customer__r.Work_Email__c',
												'CO_Header__r.Customer__r.FirstName__c',
												'CO_Header__r.Customer__r.LastName__c',
												'CO_Header__r.Customer__r.Home_Number__c',
												'CO_Header__r.Customer__r.Email__c',
												'CO_Header__r.Customer__r.Other_Email__c',
												'CO_Header__r.Customer__r.BillingCity',
												'CO_Header__r.Customer__r.BillingStreet',
												'CO_Header__r.Customer__r.BillingState',
												'CO_Header__r.Customer__r.BillingCountry',
												'CO_Header__r.Customer__r.BillingPostalCode',
												'CO_Header__r.Customer__r.Mobile__c',
												'Type__c',
												'Salesperson_Name__c',
												'Deal_Tax_Total__c',
												'Amount_Financed__c',
                                                'Subtotal__c',
                                                'Deal_Section_Trade_Only__c'
                                                },
		'DealItem'       => new Set<String> { 
													'Name',
													'Type__c',
													'Agreed_Value__c',
													'Customer_Owned_Unit__c',
													'Customer_Owned_Unit__r.Unit_Make__c',
													'Customer_Owned_Unit__r.Unit_Model__r.Name__c',
													'Customer_Owned_Unit__r.Year__c',
													'Customer_Owned_Unit__r.Sub_Model__r.Sub_Model_Name__c',
													'Customer_Owned_Unit__r.VIN_Number_Formula__c',
													'Customer_Owned_Unit__r.Make_Name__c',
													'Customer_Owned_Unit__r.Mileage_Type__c',
													'Customer_Owned_Unit__r.Mileage_Value__c',
													'Customer_Owned_Unit__r.New_Unit__c',
													'Total_Price__c',
                                                    'Fee_Total_Included_In_Profitability__c',
                                                    'Fee_Total__c',
                                                    'Unit_Option_Price__c',
													'Customer_Owned_Unit__r.Total_Cost__c',
													'Customer_Owned_Unit__r.Stock_Id__c'
												},
        'OptionFees'       => new Set<String> { 
													'Revenue__c',
													'Item_Code__c',
													'Item_Description__c',
                                                    'Deal_Item__c'
												},
        'DealFinance'       => new Set<String> { 
                                                    'Approved_Amount_Financed__c',
                                                    'Term_Type__c',
                                                    'Loan_Term__c',
                                                    'Interest_Rate__c'
                                                }
    };
}