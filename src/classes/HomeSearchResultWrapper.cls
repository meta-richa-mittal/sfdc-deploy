/**
 * Author: Tarun Khandelwal
 * Since: March 10, 2016
 * Name: HomeSearchResultWrapper
 * Description: Apex class which gives JSON format for searched result
**/
public without sharing class HomeSearchResultWrapper {
    public static ResultWrapper result;

    /** 
     * Name: getJSONForSObjectRecords 
     * Description: Method used to get search records JSON String
     * @param: 1. List<sObject> records : Searched Sobject record  
     *         2. String objName : Searched Object Name
     *         3. Integer totalRecordsFound : Count of searched Records
     *         4. List<HomeSearchFilterInterface.FilterLabel> filterLabelList - List of filter labels applied on UI.
     * @return: String 
     */
    public static String getJSONForSObjectRecords(List<sObject> records, String objName, Integer totalRecordsFound, List<HomeSearchFilterInterface.FilterLabel> filterLabelList,
    				 Boolean isIncludeInactiveRecords, Boolean isSummaryFormat, Set<String> searchNameSet) {
        return getJSONForSObjectRecords(records, objName, totalRecordsFound, filterLabelList, true, isIncludeInactiveRecords, isSummaryFormat, searchNameSet, null);
    }  
    
    /** 
     * Name: getJSONForSObjectRecords 
     * Description: Method used to get search records JSON String
     * @param: 1. List<sObject> records : Searched Sobject record 
     *         2. String objName : Searched Object Name
     *         3. Integer totalRecordsFound : Count of searched Records
     *         4. List<HomeSearchFilterInterface.FilterLabel> filterLabelList - List of filter labels applied on UI.
     * @return: String
     */
    public static String getJSONForSObjectRecords(  List<sObject> records, 
                                                    String objName, 
                                                    Integer totalRecordsFound, 
                                                    List<HomeSearchFilterInterface.FilterLabel> filterLabelList,
                                                    boolean ifToSerialzeResult, Boolean isIncludeInactiveRecords,
                                                    Boolean isSummaryFormat,
                                                    Set<String> searchNameSet ) {
		return getJSONForSObjectRecords(records, objName, totalRecordsFound, filterLabelList, ifToSerialzeResult, isIncludeInactiveRecords, isSummaryFormat, searchNameSet, null);
	}
                                                    
    public static String getJSONForSObjectRecords(  List<sObject> records, 
                                                    String objName, 
                                                    Integer totalRecordsFound, 
                                                    List<HomeSearchFilterInterface.FilterLabel> filterLabelList,
                                                    boolean ifToSerialzeResult, Boolean isIncludeInactiveRecords,
                                                    Boolean isSummaryFormat,
                                                    Set<String> searchNameSet, HomeSearchFilterWrapper filterWrapperObj
                                                ) {
                                                    
        if(objName == 'Customers') {
            List<Customer> customerRecords = new List<Customer>();
            for(Account acc : (List<Account>)records) {
                customerRecords.add(new Customer(acc));
            }
            result = new ResultWrapper(totalRecordsFound, 'CustomerRecords');
            result.CustomerRecords = customerRecords;
            
        } else if(objName == 'Vendors') {
            List<Vendor> vendorRecords = new List<Vendor>();
            for(Account acc : (List<Account>)records){
                vendorRecords.add(new Vendor(acc));
            }
            result = new ResultWrapper(totalRecordsFound, 'VendorRecords');
            result.VendorRecords = vendorRecords;
        
        } else if(objName == 'People') {
            List<People> peopleRecords = new List<People>();
            for(Account acc : (List<Account>)records){
                peopleRecords.add(new People(acc));
            }
            result = new ResultWrapper(totalRecordsFound, 'PeopleRecords');
            result.PeopleRecords = peopleRecords;
            
        } else if(objName == 'Parts') {
            List<Part> partRecords = new List<Part>();
            for(Part__c partRec : (List<Part__c>)records) {
                partRecords.add(new Part(partRec));
            }
            result = new ResultWrapper(totalRecordsFound, 'PartRecords');
            result.PartRecords = partRecords;
            
        } else if(objName == 'Kits') {
            List<KitHeader> kitRecords = new List<KitHeader>();
            for(Kit_Header__c kitHeaderRec : (List<Kit_Header__c>)records) {
                kitRecords.add(new KitHeader(kitHeaderRec));
            }
            result = new ResultWrapper(totalRecordsFound, 'KitRecords');
            result.KitRecords = kitRecords;
            
        } else if(objName == 'Fees') {
            List<Fee> feeRecords = new List<Fee>();
            for(Fee__c feeRec : (List<Fee__c>)records) {
                feeRecords.add(new Fee(feeRec));
            }
            result = new ResultWrapper(totalRecordsFound, 'FeeRecords');
            result.FeeRecords = feeRecords;
            
        } else if(objName == 'Labor Codes') {
            List<LabourCode> labourRecords = new List<LabourCode>();
            for(Labour_Code__c labourRec : (List<Labour_Code__c>)records) {
                labourRecords.add(new LabourCode(labourRec));
            }
            result = new ResultWrapper(totalRecordsFound, 'LabourRecords');
            result.LabourRecords = labourRecords;
        
        } /*else if(objName == 'Sublets') {
            List<VendorProduct> vendorProductRecords = new List<VendorProduct>();
            for(Product__c subletRec : (List<Product__c>)records) {
                vendorProductRecords.add(new VendorProduct(subletRec));
            }
            result = new ResultWrapper(totalRecordsFound, 'SubletRecords');
            result.SubletRecords = vendorProductRecords;
            
        }*/ else if(objName == 'Vendor Product') {
            List<VendorProduct> vendorProductRecords = new List<VendorProduct>();
            for(Product__c vendorProductRec : (List<Product__c>)records) {
                vendorProductRecords.add(new VendorProduct(vendorProductRec));
            }
            result = new ResultWrapper(totalRecordsFound, 'VendorProductRecords');
            result.VendorProductRecords = vendorProductRecords;
            
        } else if(objName == 'Products') {
            List<Product> productRecords = new List<Product>();
            for(Sobject sobjRec : records) {
                productRecords.add(new Product(sobjRec));
            }
            result = new ResultWrapper(totalRecordsFound, 'ProductRecords');
            result.ProductRecords = productRecords;
            
        } else if(objName == 'Customer Orders') {
            List<CustomerOrders> customerOrdersRecords = new List<CustomerOrders>();
            for(CO_Header__c coHeaderRec : (List<CO_Header__c>)records) {
                customerOrdersRecords.add(new CustomerOrders(coHeaderRec));
            }
            result = new ResultWrapper(totalRecordsFound, 'CustomerOrderRecords');
            result.CustomerOrderRecords = customerOrdersRecords;
            
        } else if(objName == 'Special Order') {
            List<SpecialOrder> specialOrderRecords = new List<SpecialOrder>();
            for(Sobject sobj : records) {
                if(sobj.getSObjectType().getDescribe().getName() == Constants.NAMESPACE + 'CO_Section_Detail__c') {
                    specialOrderRecords.add(new SpecialOrder((CO_Section_Detail__c)sobj));
                } else if(sobj.getSObjectType().getDescribe().getName() == Constants.NAMESPACE + 'Service_Order_Header__c') {
                    specialOrderRecords.add(new SpecialOrder((Service_Order_Header__c)sobj));
                }
            }
            
            result = new ResultWrapper(totalRecordsFound, 'SpecialOrderRecords');
            result.SpecialOrderRecords = specialOrderRecords;
            
        } else if(objName == 'Customer Invoices') {
            List<CustomerInvoice> customerInvoiceRecords = new List<CustomerInvoice>();
            for(CO_Invoice_Header__c coInvoiceHeaderRec : (List<CO_Invoice_Header__c>)records) {
                customerInvoiceRecords.add(new CustomerInvoice(coInvoiceHeaderRec));
            }
            //System.assert(false, records);
            result = new ResultWrapper(totalRecordsFound, 'CustomerInvoiceRecords');
            result.CustomerInvoiceRecords = customerInvoiceRecords;
            
        } else if(objName == 'Customer Payments') {
            List<CO_Invoice_Payment__c> coInvoicePaymentList = new List<CO_Invoice_Payment__c>();
            List<CO_Deposit__c> coDepositList = new List<CO_Deposit__c>();
            List<Payment_on_Account__c> paymentOnAccountList = new List<Payment_on_Account__c>();
            List<CustomerPayment> customerPaymentAndDepositRecords = new List<CustomerPayment>();
            
            for(Sobject sobj : records) {
                if(sobj.getSObjectType().getDescribe().getName() == Constants.NAMESPACE + 'CO_Invoice_Payment__c') {
                    customerPaymentAndDepositRecords.add(new CustomerPayment((CO_Invoice_Payment__c)sobj));
                } else if (sobj.getSObjectType().getDescribe().getName() == Constants.NAMESPACE + 'CO_Deposit__c'){
                    if(sobj.get(Constants.NAMESPACE + 'Payment_Method__c') != null && 
                        String.valueOf(sobj.get(Constants.NAMESPACE + 'Payment_Method__c')) != 'Invoice') {
                        customerPaymentAndDepositRecords.add(new CustomerPayment((CO_Deposit__c)sobj));
                    }
                } else if(sobj.getSObjectType().getDescribe().getName() == Constants.NAMESPACE + 'Payment_on_Account__c') {
                    	customerPaymentAndDepositRecords.add(new CustomerPayment((Payment_on_Account__c)sobj));
                }
            }
            
            result = new ResultWrapper(totalRecordsFound, 'CustomerPaymentRecords');
            result.CustomerPaymentRecords = customerPaymentAndDepositRecords;
            
        } /*else if(objName == 'Customer Deposits') {
            system.assert(false, records);
            for(CO_Deposit__c coDepositRec : (List<CO_Deposit__c>)records) {
                customerPaymentAndDepositRecords.add(new CustomerPayment(coDepositRec));
            }
            result = new ResultWrapper(totalRecordsFound, 'CustomerPaymentRecords');
            result.CustomerPaymentRecords = customerPaymentAndDepositRecords;
            
        } */else if(objName == 'Customer Sales') {
            List<CustomerSales> customerSalesRecords = new List<CustomerSales>();
            Set<String> iteratedIdSet = (searchNameSet.contains('Parts Order')) ? new Set<String>() : null;
            for(Sobject sobjRec : records) {
            	if(searchNameSet.contains('Parts Order')) {
            		String Id = String.valueOf(sobjRec.get('Id'));
            		String objectName = ((Id)sobjRec.get('Id')).getSObjectType().getDescribe().getName();
            		
            		if(objectName == Constants.NAMESPACE + 'CO_Header__c' && sobjRec.get(Constants.NAMESPACE +'CO_Type__c') != Constants.INTERNAL_SERVICE &&
            				!Boolean.valueOf(String.valueOf(sobjRec.get(Constants.NAMESPACE +'Hide_Merchandise_Section__c'))) && 
            				!iteratedIdSet.contains(Id)) {
            			customerSalesRecords.add(new CustomerSales(sobjRec, 'Parts Order'));
            			iteratedIdSet.add(Id);
            		} else {
		                customerSalesRecords.add(new CustomerSales(sobjRec));
		            }
            	} else {
            		customerSalesRecords.add(new CustomerSales(sobjRec));
            	}
            }
            result = new ResultWrapper(totalRecordsFound, 'CustomerSalesRecords');
            result.CustomerSalesRecords = customerSalesRecords;
            
        } else if(objName == 'Vendor Orders') {
            List<VendorOrder> vendorOrderRecords = new List<VendorOrder>();
            for(Vendor_Order_Header__c vendorOrderRec : (List<Vendor_Order_Header__c>)records) {
                vendorOrderRecords.add(new VendorOrder(vendorOrderRec));
            }
            result = new ResultWrapper(totalRecordsFound, 'VendorOrderRecords');
            result.VendorOrderRecords = vendorOrderRecords;
        } else if(objName == 'Vendor Invoices') {
            List<VendorInvoice> vendorInvoiceRecords = new List<VendorInvoice>();
            for(Vendor_Invoicing_Header__c vendorInvoiceRec : (List<Vendor_Invoicing_Header__c>)records) {
                vendorInvoiceRecords.add(new VendorInvoice(vendorInvoiceRec));
            }
            result = new ResultWrapper(totalRecordsFound, 'VendorInvoiceRecords');
            result.VendorInvoiceRecords = vendorInvoiceRecords;
            
        } else if(objName == 'Vendor Receivings') {
            List<VendorRecieving> vendorRecievingRecords = new List<VendorRecieving>();
            for(Vendor_Receiving_Header__c vendorRecievingRec : (List<Vendor_Receiving_Header__c>)records) {
                vendorRecievingRecords.add(new VendorRecieving(vendorRecievingRec));
            }
            result = new ResultWrapper(totalRecordsFound, 'VendorRecievingRecords');
            result.VendorRecievingRecords = vendorRecievingRecords;
            
        } else if(objName == 'Vendor Ordering') {
            List<VendorOrdering> vendorOrderingRecords = new List<VendorOrdering>();
            for(Sobject sobjRec : records) {
                vendorOrderingRecords.add(new VendorOrdering(sobjRec));
            }
            result = new ResultWrapper(totalRecordsFound, 'VendorOrderingRecords');
            result.VendorOrderingRecords = vendorOrderingRecords;

        } else if(objName == 'Item Categories') {
            List<Category> CategoryRecords = new List<Category>();
            for(Category__c sobjRec : (List<Category__c>)records) {
                CategoryRecords.add(new Category(sobjRec));
            }
            result = new ResultWrapper(totalRecordsFound, 'CategoryRecords');
            result.CategoryRecords = CategoryRecords;

        } else if(objName == 'Price Levels') {
            List<PriceLevel> PriceLevelRecords = new List<PriceLevel>();
            for(Price_Level__c sobjRec : (List<Price_Level__c>)records) {
                PriceLevelRecords.add(new PriceLevel(sobjRec));
            }
            result = new ResultWrapper(totalRecordsFound, 'PriceLevelRecords');
            result.PriceLevelRecords = PriceLevelRecords;

        } else if(objName == 'Sales Taxes') {
            List<SalesTax> SalesTaxRecords = new List<SalesTax>();
            for(Sales_Tax__c sobjRec : (List<Sales_Tax__c>)records) {
                SalesTaxRecords.add(new SalesTax(sobjRec));
            }
            result = new ResultWrapper(totalRecordsFound, 'SalesTaxRecords');
            result.SalesTaxRecords = SalesTaxRecords;

        } else if(objName == 'Setting') {
            List<Setting> SettingRecords = new List<Setting>();
            for(Sobject sobjRec : records) {
                SettingRecords.add(new Setting(sobjRec));
            }
            result = new ResultWrapper(totalRecordsFound, 'SettingRecords');
            result.SettingRecords = SettingRecords;

        } else if(objName == 'Users') {
            List<UserRec> UserRecords = new List<UserRec>();
            for(User userRecord : (List<User>)records) {
                UserRecords.add(new UserRec(userRecord));
            }
            result = new ResultWrapper(totalRecordsFound, 'UserRecords');
            result.UserRecords = UserRecords;
            
        } else if(objName == 'Parts Needed') { // Dinesh Kumar 10/10/2016
            List<PartNeeded> PartNeededRecords = new List<PartNeeded>();
            
            // Special case : Need Business Profile Detail - Added by TK - 10/14/2016
            List<Business_Profile__c> dealerInfoList = [select Business_Name__c from Business_Profile__c limit 1];
            Business_Profile__c dealerInfoRec;
            if(dealerInfoList.size() > 0) {
                dealerInfoRec = dealerInfoList[0]; 
            } else {
                dealerInfoRec = new Business_Profile__c();
            }
            
            for(Vendor_Order_Line_Item__c PartNeededRecord : (List<Vendor_Order_Line_Item__c>)records) {
                PartNeededRecords.add(new PartNeeded(PartNeededRecord, dealerInfoRec));
            }
            result = new ResultWrapper(totalRecordsFound, 'PartNeededRecords');
            result.PartNeededRecords = PartNeededRecords;

        } else if(objName == 'Service Jobs') {
        	
            List<Service_Order_Line_Item__c> soliList = [Select Id, Service_Order_Header__c, Part__c, Part__r.Average_Cost__c, Part__r.Last_Cost__c, Qty_Committed__c 
            				from Service_Order_Line_Item__c where Part__c != null AND Service_Order_Header__c IN: records];
            
            Map<String, List<Service_Order_Line_Item__c>> soIdToSoliListMap = new Map<String, List<Service_Order_Line_Item__c>>();
            for(Service_Order_Line_Item__c soliRec : soliList) {
            	if(!soIdToSoliListMap.containsKey(soliRec.Service_Order_Header__c)) {
            		soIdToSoliListMap.put(soliRec.Service_Order_Header__c, new List<Service_Order_Line_Item__c>());
            	}
            	soIdToSoliListMap.get(soliRec.Service_Order_Header__c).add(soliRec);
            }
            soliList = null;
            
            List<Hours_Logged__c> hrLoggedList = [Select Id, Service_Order_Header__c, Total_Cost__c, End_Date_Time__c from Hours_Logged__c 
            				where Is_Removed__c = false AND Service_Order_Header__c IN: records];
            Map<String, List<Hours_Logged__c>> soIdToHrsLoggedListMap = new Map<String, List<Hours_Logged__c>>();
            for(Hours_Logged__c hrsLoggedRec : hrLoggedList) {
            	if(!soIdToHrsLoggedListMap.containsKey(hrsLoggedRec.Service_Order_Header__c)) {
            		soIdToHrsLoggedListMap.put(hrsLoggedRec.Service_Order_Header__c, new List<Hours_Logged__c>());
            	}
            	soIdToHrsLoggedListMap.get(hrsLoggedRec.Service_Order_Header__c).add(hrsLoggedRec);
            }
            hrLoggedList = null;
            		
            List<ServiceJob> ServiceJobs = new List<ServiceJob>();
            for(Service_Order_Header__c soHeaderRec : (List<Service_Order_Header__c>)records) {
            	soliList = soIdToSoliListMap.containsKey(soHeaderRec.Id) ? soIdToSoliListMap.get(soHeaderRec.Id) : new List<Service_Order_Line_Item__c>();
            	hrLoggedList = soIdToHrsLoggedListMap.containsKey(soHeaderRec.Id) ? soIdToHrsLoggedListMap.get(soHeaderRec.Id) : new List<Hours_Logged__c>();
                ServiceJobs.add(new ServiceJob(soHeaderRec, soliList, hrLoggedList));
            }
            
            result = new ResultWrapper(totalRecordsFound, 'ServiceJobs');
            result.ServiceJobs = ServiceJobs;
            
        } else if(objName == 'Part FIFO') {
           result = new ResultWrapper(totalRecordsFound, 'PartMovementRecords');
           result.PartMovementRecords = new List<PartMovement>();
           result.PartMovementRecords.addAll(getPartMovementRecordsFromPartFIFO(records, filterWrapperObj));
        
        } else if(objName == 'Tax Detail') {
           result = new ResultWrapper(totalRecordsFound, 'TaxDetailRecords');
           result.TaxDetailRecords = new List<TaxReporting>();
           result.TaxDetailRecords.addAll(getTaxReportingFromInvoiceHeader(records, filterWrapperObj));
           
        } else if(objName == 'Invoiced Items') {
            List<InvoicedItems> invoiceItems = new List<InvoicedItems>();
            
            if(isSummaryFormat != null && isSummaryFormat) {
                List<CO_Line_Item__c> coliRecList = new List<CO_Line_Item__c>();
                List<Service_Order_Line_Item__c> soliRecList = new List<Service_Order_Line_Item__c>();
                List<Option_Fee__c> optionAndFeeRecList = new List<Option_Fee__c>();
                
                Map<String, List<sObject>> entityIdToSobjectListMap = new Map<String, List<sObject>>();
                for(Sobject sobj : records) {
                    Boolean isSOLI = (sobj.getSObjectType().getDescribe().getName() == Constants.NAMESPACE + 'Service_Order_Line_Item__c');
                    Boolean isOptionFee = (sobj.getSObjectType().getDescribe().getName() == Constants.NAMESPACE + 'Option_Fee__c');
                    
                    if(sobj.get(Constants.NAMESPACE + 'Part__c') != null) {
                        String partId = String.valueOf(sobj.get(Constants.NAMESPACE + 'Part__c'));
                        if(!entityIdToSobjectListMap.containsKey(partId)) {
                            entityIdToSobjectListMap.put(partId, new List<sObject>());
                        }
                        entityIdToSobjectListMap.get(partId).add(sobj);
                    } else if(sobj.get(Constants.NAMESPACE + 'Fee__c') != null) {
                        String feeId = String.valueOf(sobj.get(Constants.NAMESPACE + 'Fee__c'));
                        if(!entityIdToSobjectListMap.containsKey(feeId)) {
                            entityIdToSobjectListMap.put(feeId, new List<sObject>());
                        }
                        entityIdToSobjectListMap.get(feeId).add(sobj);
                    } else if((isSOLI || isOptionFee) && sobj.get(Constants.NAMESPACE + 'Labour_Code__c') != null) {
                        String laborId = String.valueOf(sobj.get(Constants.NAMESPACE + 'Labour_Code__c'));
                        if(!entityIdToSobjectListMap.containsKey(laborId)) {
                            entityIdToSobjectListMap.put(laborId, new List<sObject>());
                        }
                        entityIdToSobjectListMap.get(laborId).add(sobj);
                    } else if(isSOLI && sobj.get(Constants.NAMESPACE + 'Sublet__c') != null) {
                        String subletId = String.valueOf(sobj.get(Constants.NAMESPACE + 'Sublet__c'));
                        if(!entityIdToSobjectListMap.containsKey(subletId)) {
                            entityIdToSobjectListMap.put(subletId, new List<sObject>());
                        }
                        entityIdToSobjectListMap.get(subletId).add(sobj);
                    } else if(isOptionFee && sobj.get(Constants.NAMESPACE + 'Product__c') != null) {
                        String productId = String.valueOf(sobj.get(Constants.NAMESPACE + 'Product__c'));
                        if(!entityIdToSobjectListMap.containsKey(productId)) {
                            entityIdToSobjectListMap.put(productId, new List<sObject>());
                        }
                        entityIdToSobjectListMap.get(productId).add(sobj);
                    }
                }
                
                for(String entityId : entityIdToSobjectListMap.keySet()) {
                    invoiceItems.add(new InvoicedItems(entityIdToSobjectListMap.get(entityId)));
                }
                
            } else {
                for(Sobject sobj : records) {
                    if(sobj.getSObjectType().getDescribe().getName() == Constants.NAMESPACE + 'CO_Line_Item__c') {
                        invoiceItems.add(new InvoicedItems((CO_Line_Item__c)sobj));
                    } else if(sobj.getSObjectType().getDescribe().getName() == Constants.NAMESPACE + 'Service_Order_Line_Item__c') {
                        invoiceItems.add(new InvoicedItems((Service_Order_Line_Item__c)sobj));
                    }  else if(sobj.getSObjectType().getDescribe().getName() == Constants.NAMESPACE + 'Option_Fee__c') {
                        invoiceItems.add(new InvoicedItems((Option_Fee__c)sobj));
                    }
                }
            }
            result = new ResultWrapper(totalRecordsFound, 'InvoicedItems');
            result.InvoicedItems = invoiceItems;
                
        } else if(objName == 'Technician Hours') {
            List<TechnicianHours> technicianHoursList = new List<TechnicianHours>();
            for(Hours_Logged__c hoursLoggedRec : (List<Hours_Logged__c>)records) {
                technicianHoursList.add(new TechnicianHours(hoursLoggedRec));
            }
            result = new ResultWrapper(totalRecordsFound, 'TechnicianHourRecords');
            result.TechnicianHourRecords = technicianHoursList;
            
        } else if(objName == 'Payroll Hours') {
            List<PayrollHours> payrollHoursList = new List<PayrollHours>();
            for(Payroll_Time__c payrollHourRec : (List<Payroll_Time__c>)records) {
                payrollHoursList.add(new PayrollHours(payrollHourRec));
            }
            result = new ResultWrapper(totalRecordsFound, 'PayrollHourRecords');
            result.PayrollHourRecords = payrollHoursList;
            
        } else if(objName == 'Technician Performance') {
            List<TechnicianPerformance> technicianPerformanceList = new List<TechnicianPerformance>();
            for(Technician__c technicianRec : (List<Technician__c>)records) {
                if(technicianRec.Payroll_Times__r.size() > 0 || technicianRec.Hours_Logged__r.size() > 0) {
                    technicianPerformanceList.add(new TechnicianPerformance(technicianRec));
                }
            }
            result = new ResultWrapper(totalRecordsFound, 'TechnicianPerformanceRecords');
            result.TechnicianPerformanceRecords = technicianPerformanceList;
            
        } else if(objName == 'Inventory Unit') {
            DateTime dtValue;
            if(filterWrapperObj.Inventory_Unit_In_Stock_As_Of != null && !String.isBlank(filterWrapperObj.Inventory_Unit_In_Stock_As_Of.SelectedOption)) {
                DateTime dtTime;
                if(filterWrapperObj.Inventory_Unit_In_Stock_As_Of.SelectedOption != '0') {
                    dtTime = HomeSearchFilterInterface.getDateFromString(filterWrapperObj.Inventory_Unit_In_Stock_As_Of.Value1);
                    String dtStringValue = dtTime.addDays(1).formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
                    dtValue = (DateTime)JSON.deserialize('"' + dtStringValue + '"', DateTime.class);
                }
            }
            List<Id> couIdList = new List<Id>();
            for(Customer_Owned_Unit__c couRec: (List<Customer_Owned_Unit__c>) records) {
                couIdList.add(couRec.Id);
            }
            Map<Id,List<Unit_Price_Cost__c>> couToUPCMap = getCouToUpcMapForStockUnitValution(filterWrapperObj, couIdList, dtValue);
            Map<Id, Decimal> couToOptionsWIPMap = getCouToOptionsWIPForStockUnitValution(filterWrapperObj, couIdList, dtValue);
            result = new ResultWrapper(totalRecordsFound, 'InventoryUnits');
            result.InventoryUnits = new List<InventoryUnit>();
            result.InventoryUnits.addAll(getTotalsFormChildQueryForStockUnitValution(records, couToUPCMap, couToOptionsWIPMap));
        
        } else if(objName == 'Customer Unit') {
            List<CustomerUnit> customerUnitList = new List<CustomerUnit>();
            for(Customer_Owned_Unit__c unitRec : (List<Customer_Owned_Unit__c>)records) {
                customerUnitList.add(new CustomerUnit(unitRec));
            }
            result = new ResultWrapper(totalRecordsFound, 'CustomerUnits');
            result.CustomerUnits = customerUnitList;
        
        }else if(objName == 'Unit Deals') {
            List<UnitDeal> unitDealList = new List<UnitDeal>();
            for(Deal__c unitDealRec : (List<Deal__c>)records) {
                unitDealList.add(new UnitDeal(unitDealRec));
            }
            result = new ResultWrapper(totalRecordsFound, 'UnitDealRecords');
            result.UnitDealRecords = unitDealList;
        
        }else if(objName == 'Deal Units') {
            List<DealUnit> dealUnitList = new List<DealUnit>();
            for(Deal_Item__c dealUnitRec : (List<Deal_Item__c>)records) {
                dealUnitList.add(new DealUnit(dealUnitRec));
            }
            
            result = new ResultWrapper(totalRecordsFound, 'DealUnitRecords');
            result.DealUnitRecords = dealUnitList;
            //system.assert(false,result);
        
        } else if(objName == 'Parts Order') {
            List<PartsOrder> partsOrderList = new List<PartsOrder>();
            for(CO_Header__c coHeaderRec : (List<CO_Header__c>)records) {
                partsOrderList.add(new PartsOrder(coHeaderRec));
            }
            
            result = new ResultWrapper(totalRecordsFound, 'PartsOrderRecords');
            result.PartsOrderRecords = partsOrderList;
            //system.assert(false,result);
        
        } else if(objName == Label.Generic_Object_Label) {
            List<AnyObject> anyObjectRecords = new List<AnyObject>();
            Set<String> iteratedIdSet = (searchNameSet.contains('Parts Order')) ? new Set<String>() : null;
            for(Sobject sobjRec : records) {
            	if(searchNameSet.contains('Parts Order')) {
            		String Id = String.valueOf(sobjRec.get('Id'));
            		String objectName = ((Id)sobjRec.get('Id')).getSObjectType().getDescribe().getName();
            		
            		if(objectName == Constants.NAMESPACE + 'CO_Header__c' && !iteratedIdSet.contains(Id)) {
            			anyObjectRecords.add(new AnyObject(sobjRec, 'Parts Order'));
            			iteratedIdSet.add(Id);
            		} else {
                anyObjectRecords.add(new AnyObject(sobjRec));
            }
            	} else {
            		anyObjectRecords.add(new AnyObject(sobjRec));
            	}
            }
            result = new ResultWrapper(totalRecordsFound, 'AnyObjectRecords');
            result.AnyObjectRecords = anyObjectRecords;
            
        } else if(objName == 'Customer Invoice Details') {
           result = new ResultWrapper(totalRecordsFound, 'CustomerInvoiceDetailRecords');
           result.CustomerInvoiceDetailRecords = new List<HSCustomerInvoiceDetailWrapper>();
           result.CustomerInvoiceDetailRecords.addAll(getCustomerInvoiceDetailRecords(records));
           
        } else if(objName == 'Parts to Pull') {
            //system.assert(false, records.size());
            List<PartsToPull> partsToPullList = new List<PartsToPull>();
            for(CO_Line_Item__c coliRec : (List<CO_Line_Item__c>)records) {
                partsToPullList.add(new PartsToPull(coliRec));
            }
            result = new ResultWrapper(totalRecordsFound, 'PartsToPullRecords');
            result.PartsToPullRecords = partsToPullList;
           
        } else if(objName == 'Order Unit') {
            List<OrderedUnit> unitList = new List<OrderedUnit>();
            for(Customer_Owned_Unit__c unitRec : (List<Customer_Owned_Unit__c>)records) {
                unitList.add(new OrderedUnit(unitRec));
            }
            result = new ResultWrapper(totalRecordsFound, 'OrderedUnits');
            result.OrderedUnits = unitList;
           
        } else if(objName == 'VO Items') {
            List<VOItems> voItemList = new List<VOItems>();
            for(Vendor_Order_Line_Item__c voliRec : (List<Vendor_Order_Line_Item__c>)records) {
                voItemList.add(new VOItems(voliRec));
            }
            result = new ResultWrapper(totalRecordsFound, 'VOItems');
            result.VOItems = voItemList;
           
        }  else if(objName == 'Sublet Items') {
            List<SubletItems> subletItemsList = new List<SubletItems>();
            Map<Id, Vendor_Invoicing_Group__c> vrgIdToVigRecMap = new Map<Id, Vendor_Invoicing_Group__c>();
            for(Vendor_Order_Line_Item__c voliRec : (List<Vendor_Order_Line_Item__c>)records) {
                if(voliRec.Vendor_Receiving_Group__c != null) {
                    vrgIdToVigRecMap.put(voliRec.Vendor_Receiving_Group__c, null);
                }
            }
            List<Vendor_Invoicing_Group__c> vigList = [Select Vendor_Receiving_Group__c, Vendor_Invoicing_Header__r.Name, Vendor_Invoicing_Header__r.Invoice_Number__c FROM Vendor_Invoicing_Group__c Where Vendor_Receiving_Group__c In: vrgIdToVigRecMap.keySet()];
            for(Vendor_Invoicing_Group__c vigRec : vigList) {
                vrgIdToVigRecMap.put(vigRec.Vendor_Receiving_Group__c, vigRec);
            }
            for(Vendor_Order_Line_Item__c voliRec : (List<Vendor_Order_Line_Item__c>)records) {
                SubletItems subletItemsObj = new SubletItems(voliRec);
                if(vrgIdToVigRecMap.containsKey(voliRec.Vendor_Receiving_Group__c) && vrgIdToVigRecMap.get(voliRec.Vendor_Receiving_Group__c) != null) {
                    subletItemsObj.VI_Invoice = vrgIdToVigRecMap.get(voliRec.Vendor_Receiving_Group__c).Vendor_Invoicing_Header__r.Invoice_Number__c;
                    subletItemsObj.VI_Number = vrgIdToVigRecMap.get(voliRec.Vendor_Receiving_Group__c).Vendor_Invoicing_Header__r.Name;
                }
                subletItemsList.add(subletItemsObj);
            }
            result = new ResultWrapper(totalRecordsFound, 'SubletItems');
            result.SubletItems = subletItemsList;
           
        } else if(objName.equalsIgnoreCase('Vendor Returns')) {
            List<VendorReturn> vendorReturnList = new List<VendorReturn>();
            for(Return_VO_Header__c returnRec : (List<Return_VO_Header__c>)records) {
                vendorReturnList.add(new VendorReturn(returnRec));
            }
            result = new ResultWrapper(totalRecordsFound, 'VendorReturns');
            result.VendorReturns = vendorReturnList;
           
        } else if(objName.equalsIgnoreCase('Claim Jobs')) {
            List<ClaimJobs> claimJobsList = new List<ClaimJobs>();
            for(Service_Order_Header__c soRec : (List<Service_Order_Header__c>)records) {
                claimJobsList.add(new ClaimJobs(soRec));
            }
            result = new ResultWrapper(totalRecordsFound, 'ClaimJobs');
            result.ClaimJobs = claimJobsList;
           
        } else if(objName.equalsIgnoreCase('Unit Register')) {
            List<UnitRegister> unitRegisterList = new List<UnitRegister>();
            for(Customer_Owned_Unit__c unitRec : (List<Customer_Owned_Unit__c>)records) {
                unitRegisterList.add(new UnitRegister(unitRec));
            }
            result = new ResultWrapper(totalRecordsFound, 'UnitRegister');
            result.UnitRegister = unitRegisterList;
           
        } else {
            result = new ResultWrapper(0, 'NoMatchedRecords');
        }
        
        result.FilterLabelList = filterLabelList;
        result.IsIncludeInactiveRecords = isIncludeInactiveRecords;
        result.isSummaryFormat = isSummaryFormat;
        if(ifToSerialzeResult) {
            return System.Json.serialize(result);
        }
        return '';
    }
    
    private static List<HSCustomerInvoiceDetailWrapper> getCustomerInvoiceDetailRecords(List<sObject> records) {
    	List<HSCustomerInvoiceDetailWrapper> customerInvoiceDetailRecords = new List<HSCustomerInvoiceDetailWrapper>();
        for(sObject record : records) {
            if(record.getSObjectType().getDescribe().getName() == Constants.NAMESPACE + 'CO_Line_Item__c') {
                customerInvoiceDetailRecords.add(new HSCustomerInvoiceDetailWrapper((CO_Line_Item__c) record));
            } else if(record.getSObjectType().getDescribe().getName() == Constants.NAMESPACE + 'Service_Order_Line_Item__c') {
                customerInvoiceDetailRecords.add(new HSCustomerInvoiceDetailWrapper((Service_Order_Line_Item__c) record));
            } else if(record.getSObjectType().getDescribe().getName() == Constants.NAMESPACE + 'Option_Fee__c') {
                customerInvoiceDetailRecords.add(new HSCustomerInvoiceDetailWrapper((Option_Fee__c) record));
            } else if(record.getSObjectType().getDescribe().getName() == Constants.NAMESPACE + 'Deal_Unit_Price_Cost__c') {
                customerInvoiceDetailRecords.add(new HSCustomerInvoiceDetailWrapper((Deal_Unit_Price_Cost__c) record));
            } else if(record.getSObjectType().getDescribe().getName() == Constants.NAMESPACE + 'Deal_Item__c') {
                Deal_Item__c dealItemRec = (Deal_Item__c) record;
                customerInvoiceDetailRecords.add(new HSCustomerInvoiceDetailWrapper(dealItemRec, 'Trade In'));
                if(dealItemRec.Lien_Payout__c != null && dealItemRec.Lien_Payout__c != 0) customerInvoiceDetailRecords.add(new HSCustomerInvoiceDetailWrapper(dealItemRec, 'Lien'));
            } else if(record.getSObjectType().getDescribe().getName() == Constants.NAMESPACE + 'F_I_Product__c') {
                customerInvoiceDetailRecords.add(new HSCustomerInvoiceDetailWrapper((F_I_Product__c) record));
            } else if(record.getSObjectType().getDescribe().getName() == Constants.NAMESPACE + 'Deal_Finance__c') {
                Deal_Finance__c financeRec = (Deal_Finance__c) record;
                if(financeRec.Finance_Commission__c != null && financeRec.Finance_Commission__c != 0) customerInvoiceDetailRecords.add(new HSCustomerInvoiceDetailWrapper(financeRec, 'Financing Commission'));
                if(financeRec.Buy_Rate_Commission__c != null && financeRec.Buy_Rate_Commission__c != 0) customerInvoiceDetailRecords.add(new HSCustomerInvoiceDetailWrapper(financeRec, 'Buy Rate Commission'));
            } else if(record.getSObjectType().getDescribe().getName() == Constants.NAMESPACE + 'Deal__c') {
                Deal__c dealRec = (Deal__c) record;
                if(dealRec.Deal_Commission__c != null && dealRec.Deal_Commission__c != 0) customerInvoiceDetailRecords.add(new HSCustomerInvoiceDetailWrapper(dealRec));
            }
        }
        return customerInvoiceDetailRecords;
    }
    
    private static List<TaxReporting> getTaxReportingFromInvoiceHeader(List<sObject> records, HomeSearchFilterWrapper filterWrapperObj) {
        List<TaxReporting> taxReportingRecs = new List<TaxReporting>();
        
        Map<String, Map<String,List<Decimal>>> invoiceHeaderToTaxItemMap = getTaxReportingTaxItemFields(records, filterWrapperObj);
        Map<String, Set<String>> invoiceIdToContentsMap = getInvoiceIdToContentsMap(records);
        for(sObject record : records) {
            if(record.getSObjectType().getDescribe().getName() == Constants.NAMESPACE + 'Vendor_Invoicing_Header__c') {
                Vendor_Invoicing_Header__c voInvoiceRec = ((Vendor_Invoicing_Header__c) record);
                List<String> contentsList = new List<String>(invoiceIdToContentsMap.get(voInvoiceRec.Id));
                contentsList.sort();
                String contents = String.join(contentsList, ', ');
                if(voInvoiceRec.Taxable_Total__c != null && voInvoiceRec.Taxable_Total__c != 0) {
                    for(Individual_Tax__c individualTax : voInvoiceRec.getSObjects(Constants.NAMESPACE +'Individual_Taxes__r')) {
                        if(individualTax.Tax_Rate__c != null && 
                            (filterWrapperObj.Selected_Sales_Tax_Items.contains('All') || filterWrapperObj.Selected_Sales_Tax_Items.contains(individualTax.Sales_Tax_Item__r.Name__c))) {
                            taxReportingRecs.add(new TaxReporting(voInvoiceRec, individualTax.Sales_Tax_Item__r.Name__c, voInvoiceRec.Taxable_Total__c, 
                            (individualTax.Tax_Rate__c * voInvoiceRec.Taxable_Total__c) / 100,  0.0, contents));
                        }
                    }
                } 
                if(voInvoiceRec.Non_Taxable_Total__c != null && voInvoiceRec.Non_Taxable_Total__c != 0 && (filterWrapperObj.Selected_Sales_Tax_Items.contains('All') || filterWrapperObj.Selected_Sales_Tax_Items.contains(HomeSearchUtil.nonTaxablePurchases))) {
                    taxReportingRecs.add(new TaxReporting(voInvoiceRec, HomeSearchUtil.nonTaxablePurchases, 0.0, 0.0, 
                    voInvoiceRec.Non_Taxable_Total__c, contents));
                }

            } else if(record.getSObjectType().getDescribe().getName() == Constants.NAMESPACE + 'CO_Invoice_Header__c') {
                CO_Invoice_Header__c coInvoiceRec = ((CO_Invoice_Header__c) record);
                List<String> contentsList = new List<String>(invoiceIdToContentsMap.get(coInvoiceRec.Id));
                contentsList.sort();
                String contents = String.join(contentsList, ', ');
                Map<String,List<Decimal>> taxItemDetailMap = invoiceHeaderToTaxItemMap.get(record.Id);
                if(taxItemDetailMap != null) {
                    for(String taxName : taxItemDetailMap.keySet()) {
                        if(taxItemDetailMap.get(taxName).size() > 1) {
                            taxReportingRecs.add(new TaxReporting((CO_Invoice_Header__c)record, taxName, taxItemDetailMap.get(taxName)[0], 
                            taxItemDetailMap.get(taxName)[1], 0.0, contents));
                        }
                    }
                } 
                if(coInvoiceRec.Non_Taxable_Total__c != null && coInvoiceRec.Non_Taxable_Total__c != 0 && (filterWrapperObj.Selected_Sales_Tax_Items.contains('All') || filterWrapperObj.Selected_Sales_Tax_Items.contains(HomeSearchUtil.nonTaxableSales))){
                    taxReportingRecs.add(new TaxReporting((CO_Invoice_Header__c)record, HomeSearchUtil.nonTaxableSales, 0.0, 0.0, 
                    coInvoiceRec.Non_Taxable_Total__c, contents));
                }                                                       /*
                taxReportingRecs.add(new TaxReporting((CO_Invoice_Header__c)record, (invoiceHeaderToTaxItemMap.containsKey(record.Id) ? 
                                                                        invoiceHeaderToTaxItemMap.get(record.Id) :
                                                                           new Map<String, List<Decimal>>())));*/
            }
        }
        return taxReportingRecs;
    }

    private static Map<Id, CO_Invoice_Item__c> getSOPaymentRoleIdToInvoiceItemMap(List<SObject> invoiceList) {
        Map<Id, CO_Invoice_Item__c> soPaymentRoleIdToInvoiceItemMap = new Map<Id, CO_Invoice_Item__c>();
        for(CO_Invoice_Item__c coInvItem: [SELECT SO_Payment_Role__r.Total_Amount__c, SO_Payment_Role__r.Tax_Amount__c, SO_Payment_Role__r.Tax__c, CO_Invoice_Header__c FROM CO_Invoice_Item__c WHERE CO_Invoice_Header__c IN: invoiceList AND SO_Payment_Role__r.RecordType.DeveloperName = 'Deductible']) {
            soPaymentRoleIdToInvoiceItemMap.put(coInvItem.SO_Payment_Role__c, coInvItem);
        }
        return soPaymentRoleIdToInvoiceItemMap;
    }

    public static Map<Id, SO_Payment_Role__c> getSOPaymentRoleIdToRecMap(Set<Id> idSet) {
        return new Map<Id, SO_Payment_Role__c>([SELECT Total_Amount__c, Tax_Amount__c, Tax__c FROM SO_Payment_Role__c WHERE Id IN: idSet AND RecordType.DeveloperName = 'Deductible']);
    }

    public static Map<Id, Id> getSOPaymentRoleIdToThirdPartInvoiceIdMap(List<Id> thirdPartyCOInvIdList) {
        Map<Id, Id> soPaymentRoleIdToThirdPartInvoiceIdMap = new Map<Id, Id>();
        if(!thirdPartyCOInvIdList.isEmpty()) {
            for(SO_Payment_Role__c soPaymentRoleRec: [SELECT Id, Service_Order_Header__r.Invoice_Number__c FROM SO_Payment_Role__c WHERE RecordType.DeveloperName = 'Deductible' 
                                                        AND Service_Order_Header__r.Invoice_Number__c IN: thirdPartyCOInvIdList]) {
                soPaymentRoleIdToThirdPartInvoiceIdMap.put(soPaymentRoleRec.Id, soPaymentRoleRec.Service_Order_Header__r.Invoice_Number__c);
            }
        }
        return soPaymentRoleIdToThirdPartInvoiceIdMap;
    }
    
    private static Map<String, Set<String>> getInvoiceIdToContentsMap(List<SObject> invoiceList) {
        Map<String, Set<String>> coInvoiceIdToContentsMap = new Map<String, Set<String>>();
        Map<String, Set<String>> voInvoiceIdToContentsMap = new Map<String, Set<String>>();
        for(SObject record: invoiceList) {
            String objName = record.getSObjectType().getDescribe().getName();
            if(objName == Constants.NAMESPACE + 'CO_Invoice_Header__c') {
                coInvoiceIdToContentsMap.put(String.valueOf(record.get('Id')), new Set<String>());
            } else if(objName == Constants.NAMESPACE + 'Vendor_Invoicing_Header__c') {
                voInvoiceIdToContentsMap.put(String.valueOf(record.get('Id')), new Set<String>());
            }
        }
        if(!coInvoiceIdToContentsMap.isEmpty()) {
            for(CO_Line_Item__c coli : [Select Invoice_Number__c, Part__c, Fee__c FROM CO_Line_Item__c WHERE Invoice_Number__c IN: coInvoiceIdToContentsMap.keySet() AND Service_Order_Line_Item__c = null AND (Part__c != null OR Fee__c != null)]) {
                coInvoiceIdToContentsMap.get(coli.Invoice_Number__c).add(
                    (coli.Part__c != null ? 'Parts' : 'Fees')
                );
            }
            for(Service_Order_Line_Item__c soli : [Select Service_Order_Header__r.Invoice_Number__c, Part__c, Fee__c, Labour_Code__c, Sublet__c FROM Service_Order_Line_Item__c WHERE Service_Order_Header__r.Invoice_Number__c IN: coInvoiceIdToContentsMap.keySet()]) {
                coInvoiceIdToContentsMap.get(soli.Service_Order_Header__r.Invoice_Number__c).add(
                    (soli.Part__c != null ? 'Parts' : 
                    (soli.Labour_Code__c != null ? 'Labor' : 
                    (soli.Sublet__c != null ? 'Sublet' : 
                    (soli.Fee__c != null ? 'Fees' : null))))
                );
            }
            for(Deal_Item__c dealItem : [Select Deal__r.Invoice_Number__c, Customer_Owned_Unit__r.Consignment__c, Customer_Owned_Unit__r.Unit_Number__c, Customer_Owned_Unit__r.Stock_Id__c FROM Deal_Item__c WHERE Deal__r.Invoice_Number__c IN: coInvoiceIdToContentsMap.keySet()]) {
                coInvoiceIdToContentsMap.get(dealItem.Deal__r.Invoice_Number__c).add(
                    (dealItem.Customer_Owned_Unit__r.Consignment__c ? dealItem.Customer_Owned_Unit__r.Unit_Number__c : dealItem.Customer_Owned_Unit__r.Stock_Id__c)
                );
            }
        }
        if(!voInvoiceIdToContentsMap.isEmpty()) {
            for(Vendor_Invoicing_Group__c vig : [Select Vendor_Invoicing_Header__c, Vendor_Receiving_Group__r.Part__c, Vendor_Receiving_Group__r.Sublet__c FROM Vendor_Invoicing_Group__c WHERE Vendor_Invoicing_Header__c IN: voInvoiceIdToContentsMap.keySet() AND (Vendor_Receiving_Group__r.Part__c != null OR Vendor_Receiving_Group__r.Sublet__c != null)]) {
                voInvoiceIdToContentsMap.get(vig.Vendor_Invoicing_Header__c).add(
                    (vig.Vendor_Receiving_Group__r.Part__c != null ? 'Parts purchase' : 'Sublet purchase')
                );
            }
        }
        Map<String, Set<String>> invoiceIdToContentsMap = new Map<String, Set<String>>(coInvoiceIdToContentsMap);
        invoiceIdToContentsMap.putAll(voInvoiceIdToContentsMap);
        return invoiceIdToContentsMap;
    }
    
    private static Map<String, Map<String,List<Decimal>>> getTaxReportingTaxItemFields(List<SObject> invoiceList, HomeSearchFilterWrapper filterWrapperObj) {
        Boolean isTaxIncludingPricing = GeneralConfiguration.getTaxIncludingPricing();

        Set<String> selectedSalesTaxItemNames = filterWrapperObj.Selected_Sales_Tax_Items;
        String indiTaxWhereClause = (selectedSalesTaxItemNames != null && !selectedSalesTaxItemNames.isEmpty() && (selectedSalesTaxItemNames.size() > 1 || !selectedSalesTaxItemNames.contains('All'))) ?
            ' AND Sales_Tax_Item__r.Name__c IN: selectedSalesTaxItemNames' : '';
            
        system.debug('indiTaxWhereClause::' + indiTaxWhereClause);
        
        List<Id> thirdPartyCOInvIdList = new List<Id>();
        for(SObject record: invoiceList) {
            if(record.getSObjectType().getDescribe().getName() == Constants.NAMESPACE + 'CO_Invoice_Header__c') {
                CO_Invoice_Header__c coInvRec = (CO_Invoice_Header__c)record;
                if(coInvRec.Checkout_Type__c == 'Third-Party') {
                    thirdPartyCOInvIdList.add(coInvRec.Id);
                }
            }
        }
        Map<Id, Id> soPaymentRoleIdToThirdPartInvoiceIdMap = getSOPaymentRoleIdToThirdPartInvoiceIdMap(thirdPartyCOInvIdList);
        Map<Id, CO_Invoice_Item__c> soPaymentRoleIdToInvoiceItemMap = getSOPaymentRoleIdToInvoiceItemMap(invoiceList);

        Map<Id, SO_Payment_Role__c> soPaymentRoleIdToRecMap = getSOPaymentRoleIdToRecMap(soPaymentRoleIdToThirdPartInvoiceIdMap.keySet());

        Map<String, Map<String,List<Decimal>>> invoiceHeaderIdToTaxItemDetailMap = new Map<String, Map<String,List<Decimal>>>();
        List<Id> soPaymentRoleIdList = new List<Id>(soPaymentRoleIdToInvoiceItemMap.keySet());
        soPaymentRoleIdList.addAll(new List<Id>(soPaymentRoleIdToThirdPartInvoiceIdMap.KeySet()));
        
        String indiQuery = 'SELECT SO_Payment_Role__c, Taxable_Amount__c, Enhanced_Tax_Amount__c, Tax_Amount__c, Tax_Rate__c, Deal_Item__r.Deal__r.Invoice_Number__c, '+
            'Deal_Unit_Price_Cost__r.Deal_Item__r.Deal__r.Invoice_Number__c, F_I_Product__r.Deal_Finance__r.Deal__r.Invoice_Number__c, Sales_Tax_Item__r.Name__c, '+
            'CO_Line_Item__r.Invoice_Number__c, Service_Order_Line_Item__r.Service_Order_Header__r.Invoice_Number__c,'+
            'Option_Fee__r.Deal_Item__r.Deal__r.Invoice_Number__c, Deal__r.Invoice_Number__c '+
            'FROM Individual_Tax__c WHERE (Deal_Unit_Price_Cost__r.Deal_Item__r.Deal__r.Invoice_Number__c IN: invoiceList ' +
            'OR F_I_Product__r.Deal_Finance__r.Deal__r.Invoice_Number__c IN: invoiceList ' +
            'OR (CO_Line_Item__r.Invoice_Number__c IN: invoiceList AND CO_Line_Item__r.Is_In_Merch_Section__c = true AND Deal__c = null)' +
            'OR (Service_Order_Line_Item__r.Service_Order_Header__r.Invoice_Number__c IN: invoiceList AND Deal__c = null)' +
            'OR (Option_Fee__r.Deal_Item__r.Deal__r.Invoice_Number__c IN: invoiceList)' +
            'OR (Deal_Item__r.Deal__r.Invoice_Number__c IN :invoiceList AND Deal_Item__r.Type__c = \'Trade In\')'+
            'OR Deal__r.Invoice_Number__c IN :invoiceList OR SO_Payment_Role__c IN :soPaymentRoleIdList) ' + indiTaxWhereClause;
        system.debug( indiQuery);

        for(Individual_Tax__c individualTax : Database.query(indiQuery)) {
            String invoiceId;
            if(individualTax.Deal__r.Invoice_Number__c != null) {
                invoiceId = individualTax.Deal__r.Invoice_Number__c;
            } else if(individualTax.Deal_Unit_Price_Cost__r.Deal_Item__r.Deal__r.Invoice_Number__c != null) {
                invoiceId = individualTax.Deal_Unit_Price_Cost__r.Deal_Item__r.Deal__r.Invoice_Number__c;
            } else if(individualTax.F_I_Product__r.Deal_Finance__r.Deal__r.Invoice_Number__c != null) {
                invoiceId = individualTax.F_I_Product__r.Deal_Finance__r.Deal__r.Invoice_Number__c;
            } else if(individualTax.Service_Order_Line_Item__r.Service_Order_Header__r.Invoice_Number__c != null) {
                invoiceId = individualTax.Service_Order_Line_Item__r.Service_Order_Header__r.Invoice_Number__c;
            } else if(individualTax.CO_Line_Item__r.Invoice_Number__c != null) {
                invoiceId = individualTax.CO_Line_Item__r.Invoice_Number__c;
            } else if(individualTax.Option_Fee__r.Deal_Item__r.Deal__r.Invoice_Number__c != null) {
                invoiceId = individualTax.Option_Fee__r.Deal_Item__r.Deal__r.Invoice_Number__c;
            } else if(individualTax.SO_Payment_Role__c != null) {
                if(soPaymentRoleIdToInvoiceItemMap.containsKey(individualTax.SO_Payment_Role__c)) {
                    invoiceId = soPaymentRoleIdToInvoiceItemMap.get(individualTax.SO_Payment_Role__c).CO_Invoice_Header__c;
                } else if(soPaymentRoleIdToThirdPartInvoiceIdMap.containsKey(individualTax.SO_Payment_Role__c)) {
                    invoiceId = soPaymentRoleIdToThirdPartInvoiceIdMap.get(individualTax.SO_Payment_Role__c);
                }
            } else {
                invoiceId = individualTax.Deal_Item__r.Deal__r.Invoice_Number__c;
            }
            
            if(String.isNotBlank(invoiceId)) {
                if(!invoiceHeaderIdToTaxItemDetailMap.containsKey(invoiceId)) {
                    invoiceHeaderIdToTaxItemDetailMap.put(invoiceId, new Map<String,List<Decimal>>());
                }
                if(individualTax.SO_Payment_Role__c != null && soPaymentRoleIdToThirdPartInvoiceIdMap.containsKey(individualTax.SO_Payment_Role__c) && !invoiceHeaderIdToTaxItemDetailMap.containsKey(soPaymentRoleIdToThirdPartInvoiceIdMap.get(individualTax.SO_Payment_Role__c))) {
                    invoiceHeaderIdToTaxItemDetailMap.put(soPaymentRoleIdToThirdPartInvoiceIdMap.get(individualTax.SO_Payment_Role__c), new Map<String,List<Decimal>>());
                }
                if(!invoiceHeaderIdToTaxItemDetailMap.get(invoiceId).containsKey(individualTax.Sales_Tax_Item__r.Name__c)) {
                    invoiceHeaderIdToTaxItemDetailMap.get(invoiceId).put(individualTax.Sales_Tax_Item__r.Name__c, new List<Decimal>{0,0});
                }
                if(individualTax.SO_Payment_Role__c != null && soPaymentRoleIdToThirdPartInvoiceIdMap.containsKey(individualTax.SO_Payment_Role__c) && !invoiceHeaderIdToTaxItemDetailMap.get(soPaymentRoleIdToThirdPartInvoiceIdMap.get(individualTax.SO_Payment_Role__c)).containsKey(individualTax.Sales_Tax_Item__r.Name__c)) {
                    invoiceHeaderIdToTaxItemDetailMap.get(soPaymentRoleIdToThirdPartInvoiceIdMap.get(individualTax.SO_Payment_Role__c)).put(individualTax.Sales_Tax_Item__r.Name__c, new List<Decimal>{0,0});    
                }
                if(individualTax.SO_Payment_Role__c != null) {
                    Decimal totalAmount = 0;
                    if(soPaymentRoleIdToInvoiceItemMap.containsKey(individualTax.SO_Payment_Role__c)) {
                        totalAmount = soPaymentRoleIdToInvoiceItemMap.get(individualTax.SO_Payment_Role__c).SO_Payment_Role__r.Total_Amount__c;
                    }
                    invoiceHeaderIdToTaxItemDetailMap.get(invoiceId).get(individualTax.Sales_Tax_Item__r.Name__c)[0] += totalAmount;

                    if(soPaymentRoleIdToThirdPartInvoiceIdMap.containsKey(individualTax.SO_Payment_Role__c)) {
                        totalAmount = (soPaymentRoleIdToRecMap.get(individualTax.SO_Payment_Role__c).Total_Amount__c)*-1;
                        invoiceHeaderIdToTaxItemDetailMap.get(soPaymentRoleIdToThirdPartInvoiceIdMap.get(individualTax.SO_Payment_Role__c)).get(individualTax.Sales_Tax_Item__r.Name__c)[0] += totalAmount;
                    }
                } else {
                    invoiceHeaderIdToTaxItemDetailMap.get(invoiceId).get(individualTax.Sales_Tax_Item__r.Name__c)[0] += individualTax.Taxable_Amount__c;
                }
                if(isTaxIncludingPricing) {
                    if(individualTax.SO_Payment_Role__c != null) {
                        Decimal taxAmount = 0;
                        if(soPaymentRoleIdToInvoiceItemMap.containsKey(individualTax.SO_Payment_Role__c)) {
                            taxAmount = (soPaymentRoleIdToInvoiceItemMap.get(individualTax.SO_Payment_Role__c).SO_Payment_Role__r.Tax_Amount__c*(individualTax.Tax_Rate__c/soPaymentRoleIdToInvoiceItemMap.get(individualTax.SO_Payment_Role__c).SO_Payment_Role__r.Tax__c)).setScale(2, RoundingMode.HALF_UP);
                        }
                        invoiceHeaderIdToTaxItemDetailMap.get(invoiceId).get(individualTax.Sales_Tax_Item__r.Name__c)[1] += taxAmount;
                        if(soPaymentRoleIdToThirdPartInvoiceIdMap.containsKey(individualTax.SO_Payment_Role__c)) {
                            taxAmount = (soPaymentRoleIdToRecMap.get(individualTax.SO_Payment_Role__c).Tax_Amount__c*(individualTax.Tax_Rate__c/soPaymentRoleIdToRecMap.get(individualTax.SO_Payment_Role__c).Tax__c)).setScale(2, RoundingMode.HALF_UP);
                            taxAmount*=-1;
                            invoiceHeaderIdToTaxItemDetailMap.get(soPaymentRoleIdToThirdPartInvoiceIdMap.get(individualTax.SO_Payment_Role__c)).get(individualTax.Sales_Tax_Item__r.Name__c)[1] += taxAmount;
                        }
                    } else {
                        invoiceHeaderIdToTaxItemDetailMap.get(invoiceId).get(individualTax.Sales_Tax_Item__r.Name__c)[1] += individualTax.Tax_Amount__c;
                    }
                } else {
                    if(individualTax.Enhanced_Tax_Amount__c != null) {
                        invoiceHeaderIdToTaxItemDetailMap.get(invoiceId).get(individualTax.Sales_Tax_Item__r.Name__c)[1] += individualTax.Enhanced_Tax_Amount__c;
                    } else {
                        if(individualTax.SO_Payment_Role__c != null) {
                            Decimal taxAmount = 0;
                            if(soPaymentRoleIdToInvoiceItemMap.containsKey(individualTax.SO_Payment_Role__c)) {
                                taxAmount = ((soPaymentRoleIdToInvoiceItemMap.get(individualTax.SO_Payment_Role__c).SO_Payment_Role__r.Total_Amount__c*individualTax.Tax_Rate__c)/100).setScale(2, RoundingMode.HALF_UP);
                            }
                            invoiceHeaderIdToTaxItemDetailMap.get(invoiceId).get(individualTax.Sales_Tax_Item__r.Name__c)[1] += taxAmount;
                            if(soPaymentRoleIdToThirdPartInvoiceIdMap.containsKey(individualTax.SO_Payment_Role__c)) {
                                taxAmount = ((soPaymentRoleIdToRecMap.get(individualTax.SO_Payment_Role__c).Total_Amount__c*individualTax.Tax_Rate__c)/100).setScale(2, RoundingMode.HALF_UP);
                                taxAmount*=-1;
                                invoiceHeaderIdToTaxItemDetailMap.get(soPaymentRoleIdToThirdPartInvoiceIdMap.get(individualTax.SO_Payment_Role__c)).get(individualTax.Sales_Tax_Item__r.Name__c)[1] += taxAmount;
                            }
                        } else {
                            invoiceHeaderIdToTaxItemDetailMap.get(invoiceId).get(individualTax.Sales_Tax_Item__r.Name__c)[1] += (individualTax.Taxable_Amount__c * individualTax.Tax_Rate__c) / 100;
                        }
                    }
                }
            }
        }
        return invoiceHeaderIdToTaxItemDetailMap;
    }
    
    private static Map<String, Map<String,List<Decimal>>> getTaxReportingTaxItemFieldsForVendorInvoiceHeader(List<String> salesTaxList, List<TaxReporting> taxReportingRecsGenerated) {
       Map<String, Sales_Tax_item__c> salesTaxToChildrenSalesTaxItemMap = new Map<String, Sales_Tax_item__c>();    
       List<Applicable_Taxes__c> applicableTaxesRecs = [SELECT Sales_Tax__c,Sales_Tax_Item__c, Sales_Tax_Item__r.Name__c, Sales_Tax_Item__r.Rate__c FROM Applicable_Taxes__c WHERE  Sales_Tax__c in :salesTaxList];
        return null;
    }
    
    public static Boolean validatePartFIFO(PartMovement partMovementObject, HomeSearchFilterWrapper filterWrapperObj) {
    	Boolean isValidLine = true;
    	if(filterWrapperObj.Part_FIFO_Sales_Qty != null && !String.isBlank(filterWrapperObj.Part_FIFO_Sales_Qty.SelectedOption) && 
    												filterWrapperObj.Part_FIFO_Sales_Qty.SelectedOption != '0') {
    		isValidLine = validatePartFIFONumericField(partMovementObject.Sales_Qty, filterWrapperObj.Part_FIFO_Sales_Qty);
		}
		
		if(isValidLine && filterWrapperObj.Part_FIFO_Purchase_Qty != null && !String.isBlank(filterWrapperObj.Part_FIFO_Purchase_Qty.SelectedOption) && 
    												filterWrapperObj.Part_FIFO_Purchase_Qty.SelectedOption != '0') {
			isValidLine = validatePartFIFONumericField(partMovementObject.Purchased_Qty, filterWrapperObj.Part_FIFO_Purchase_Qty);
		}
		
		if(isValidLine && filterWrapperObj.Part_FIFO_Adjusted_Qty != null && !String.isBlank(filterWrapperObj.Part_FIFO_Adjusted_Qty.SelectedOption) && 
    												filterWrapperObj.Part_FIFO_Adjusted_Qty.SelectedOption != '0') {
			isValidLine = validatePartFIFONumericField(partMovementObject.Adjusted_Qty, filterWrapperObj.Part_FIFO_Adjusted_Qty);
		}
		return isValidLine;
    }
    
    
    private static Boolean validatePartFIFONumericField(Decimal fieldValue, HomeSearchFilterWrapper.BetweenFilter numericJSON) {
    		
		if(numericJSON.SelectedOption != '0' && String.isNotBlank(numericJSON.Value1)) {
        	if(fieldValue == null) {
        		fieldValue = 0;
        	}
			if(numericJSON.SelectedOption == '1') {
        		if(fieldValue != Decimal.ValueOf(numericJSON.Value1)) {
        			return false;
        		}
	        } else if(numericJSON.SelectedOption == '2') {
	        	if(fieldValue == Decimal.ValueOf(numericJSON.Value1)) {
        			return false;
        		}
	        } else if(numericJSON.SelectedOption == '3') {
	        	if(fieldValue <= Decimal.ValueOf(numericJSON.Value1)) {
        			return false;
        		}
	        } else if(numericJSON.SelectedOption == '4') {
	        	if(fieldValue >= Decimal.ValueOf(numericJSON.Value1)) {
        			return false;
        		}
	        } else if(numericJSON.SelectedOption == '5' && !String.isBlank(numericJSON.Value2)) {
	        	if(fieldValue < Decimal.ValueOf(numericJSON.Value1)) {
        			return false;
        		}
        		if(fieldValue > Decimal.ValueOf(numericJSON.Value2)) {
        			return false;
        		}
	        }
		}
	        
    	return true;
    }
    
    private static List<PartMovement> getPartMovementRecordsFromPartFIFO(List<sObject> records, HomeSearchFilterWrapper filterWrapperObj) {
        List<PartMovement> partMovementItems = new List<PartMovement>();
				
        Map<String, List<Part_FIFO_Bucket__c>> partIdToFifoBucketsMap = new Map<String, List<Part_FIFO_Bucket__c>>();
        Map<String, List<Part_FIFO_Bucket_Activity_Line_Item__c>> partIdToFifoBucketLineItemsMap = new Map<String, List<Part_FIFO_Bucket_Activity_Line_Item__c>>();
        for(sObject record : records) {
            if(record.getSObjectType().getDescribe().getName() == Constants.NAMESPACE + 'Part_FIFO_Bucket__c') {
                Part_FIFO_Bucket__c fifoBucketRec = (Part_FIFO_Bucket__c) record;
                if(fifoBucketRec.Part__c != null) {
                    if(!partIdToFifoBucketsMap.containsKey(fifoBucketRec.Part__c)) {
                        partIdToFifoBucketsMap.put(fifoBucketRec.Part__c, new List<Part_FIFO_Bucket__c>());
                    }
                    partIdToFifoBucketsMap.get(fifoBucketRec.Part__c).add(fifoBucketRec);
                }
            } else if(record.getSObjectType().getDescribe().getName() == Constants.NAMESPACE + 'Part_FIFO_Bucket_Activity_Line_Item__c') {
                Part_FIFO_Bucket_Activity_Line_Item__c fifoBucketLineItemRec = (Part_FIFO_Bucket_Activity_Line_Item__c) record;
                if(fifoBucketLineItemRec.Part_FIFO_Bucket__r.Part__c != null) {
                    if(!partIdToFifoBucketLineItemsMap.containsKey(fifoBucketLineItemRec.Part_FIFO_Bucket__r.Part__c)) {
                        partIdToFifoBucketLineItemsMap.put(fifoBucketLineItemRec.Part_FIFO_Bucket__r.Part__c, new List<Part_FIFO_Bucket_Activity_Line_Item__c>());
                    }
                    partIdToFifoBucketLineItemsMap.get(fifoBucketLineItemRec.Part_FIFO_Bucket__r.Part__c).add(fifoBucketLineItemRec);
                }
            }
        }
        
        // Query Part record to remove Heap Size issue.
        Map<Id, Part__c> partIdToPartRecordMap = 
            new Map<Id, Part__c>([SELECT Vendor__r.Name, Category__r.Name, Part_Type__c, Location__c, Status__c, Last_Sold__c, AvailableParts__c, 
                                         Last_Stocked__c, Auto_reorder_Min__c, Auto_reorder_Max__c, Part_Number__c, Description__c 
                                     FROM Part__c WHERE Id IN: partIdToFifoBucketsMap.keySet()
                                                    OR Id IN: partIdToFifoBucketLineItemsMap.keySet()]);
        
        PartMovement partMovementObject;
        //loop over all parts that have a FIFO bucket object created between the date range
        Decimal openingQty, openingCost, closingQty, closingCost, purchaseQty, purchaseCost, salesQty, salesCost, adjustedQty, adjustedCost, totalSales;
        for(String partId : partIdToFifoBucketsMap.keySet()) {
           List<Part_FIFO_Bucket__c> partFifoBuckets = partIdToFifoBucketsMap.get(partId);
           if(partFifoBuckets.size() > 0) {
               partMovementObject = new PartMovement(partIdToPartRecordMap.containsKey(partId) ? partIdToPartRecordMap.get(partId) : new Part__c());
               openingQty = openingCost = closingQty = closingCost = purchaseQty = purchaseCost = salesQty = salesCost = adjustedQty = adjustedCost = totalSales = 0;
               system.debug('FIFO Bucket ' + partFifoBuckets[0] + ' ' + partFifoBuckets[0].Qty_In_Stock_When_Created__c);
               if(partFifoBuckets[0].Qty_In_Stock_When_Created__c != null) {
                   openingQty = partFifoBuckets[0].Qty_In_Stock_When_Created__c;
                   openingCost = openingQty * 
                        (partFifoBuckets[0].Average_Cost_When_Created__c != null? partFifoBuckets[0].Average_Cost_When_Created__c : 0);
               }
               if(partFifoBuckets[partFifoBuckets.size() - 1] != null && partFifoBuckets[partFifoBuckets.size() - 1].Qty_In_Stock_When_Created__c != null) {
                   partFifoBuckets[partFifoBuckets.size() - 1].Qty_In__c = partFifoBuckets[partFifoBuckets.size() - 1].Qty_In__c != null ? partFifoBuckets[partFifoBuckets.size() - 1].Qty_In__c : 0;
                    partFifoBuckets[partFifoBuckets.size() - 1].Average_Cost_When_Created__c = partFifoBuckets[partFifoBuckets.size() - 1].Average_Cost_When_Created__c != null? partFifoBuckets[partFifoBuckets.size() - 1].Average_Cost_When_Created__c : 0.0;
                    partFifoBuckets[partFifoBuckets.size() - 1].Cost__c = partFifoBuckets[partFifoBuckets.size() - 1].Cost__c != null ? partFifoBuckets[partFifoBuckets.size() - 1].Cost__c : 0;
                   closingQty = partFifoBuckets[partFifoBuckets.size() - 1].Qty_In_Stock_When_Created__c + (partFifoBuckets[partFifoBuckets.size() - 1].Qty_In__c);
                   closingCost = (closingQty == 0 ? 0 : (partFifoBuckets[partFifoBuckets.size() - 1].Qty_In_Stock_When_Created__c * partFifoBuckets[partFifoBuckets.size() - 1].Average_Cost_When_Created__c)
                        + (partFifoBuckets[partFifoBuckets.size() - 1].Qty_In__c * partFifoBuckets[partFifoBuckets.size() - 1].Cost__c));
               }
               for(Part_FIFO_Bucket__c fifoBucketObject : partFifoBuckets) {
                   //stores  qty values for current fifo bucket object in iteration 
                   Decimal partFifoBucketQtyIn = 0;
                   fifoBucketObject.Cost__c = fifoBucketObject.Cost__c != null ? fifoBucketObject.Cost__c : 0;
                   partFifoBucketQtyIn =  fifoBucketObject.Qty_In__c != null ? fifoBucketObject.Qty_In__c : 0;
                   
                   //Purchase Qty & Cost
                   if(fifoBucketObject.Source_Name__c == 'Vendor Receiving' || fifoBucketObject.Source_Name__c == 'Vendor Invoice') {
                       purchaseQty += partFifoBucketQtyIn;
                       purchaseCost += partFifoBucketQtyIn * fifoBucketObject.Cost__c;
                   } 
                   //Sales QTy & cost
                   else if(fifoBucketObject.Source_Name__c == 'Customer Return' || fifoBucketObject.Source_Name__c == 'Oversold') {
                       salesQty -= partFifoBucketQtyIn;
                       salesCost -= (partFifoBucketQtyIn * fifoBucketObject.Cost__c);
                       List<Coli_Fifo_Line_Item_Junction__c> coliJunction = (List<Coli_Fifo_Line_Item_Junction__c>) fifoBucketObject.getSObjects(Constants.NAMESPACE + 'Coli_Fifo_Line_Items_Junction__r');
                        if(fifoBucketObject.getSObjects(Constants.NAMESPACE + 'Coli_Fifo_Line_Items_Junction__r') != null && fifoBucketObject.getSObjects(Constants.NAMESPACE + 'Coli_Fifo_Line_Items_Junction__r').size() > 0
                            && fifoBucketObject.getSObjects(Constants.NAMESPACE + 'Coli_Fifo_Line_Items_Junction__r')[0].getSObject(Constants.NAMESPACE + 'CO_Line_Item__r') != null) {
                            
                            CO_Line_Item__c coli = (CO_Line_Item__c) (fifoBucketObject.getSObjects(Constants.NAMESPACE + 'Coli_Fifo_Line_Items_Junction__r')[0].getSObject(Constants.NAMESPACE + 'CO_Line_Item__r'));
                            Decimal price = coli.Service_Order_Line_Item__c != null ? coli.Service_Order_Line_Item__r.Kit_Price__c : coli.Price__c;
                            if(price != null && price != 0) {
                                totalSales -= (partFifoBucketQtyIn * price);
                            }
                        }
                   }
                   
                   //Adjusted Cost
                   if(FIFOTransaction.sourceNamesForAdjusmentSet.contains(fifoBucketObject.Source_Name__c)) {
                       adjustedQty += partFifoBucketQtyIn;
                       adjustedCost += (partFifoBucketQtyIn * fifoBucketObject.Cost__c);
                   }
               }
               
               
               // Update values for the parts already processed with fifo bucket to include chanegs in value for related activity line items
               if(partIdToFifoBucketLineItemsMap.containsKey(partId)){
                   List<Part_FIFO_Bucket_Activity_Line_Item__c> partFIFOLineItemsList = partIdToFifoBucketLineItemsMap.get(partId);
                   if(partFIFOLineItemsList.size() > 0) {
                       //update opening cost
                       if(partFIFOLineItemsList[0].CreatedDate < partFifoBuckets[0].CreatedDate && 
                                partFIFOLineItemsList[0].Qty_In_Stock_When_Created__c != null) {
                           openingQty = partFIFOLineItemsList[0].Qty_In_Stock_When_Created__c;
                           openingCost = openingQty * 
                                (partFIFOLineItemsList[0].Average_Cost_When_Created__c != null ? partFIFOLineItemsList[0].Average_Cost_When_Created__c : 0);
                       }
                       
                       //update closing cost 
                       if(partFIFOLineItemsList[partFIFOLineItemsList.size() - 1].CreatedDate >= partFifoBuckets[partFifoBuckets.size()-1].CreatedDate
                            && partFIFOLineItemsList[partFIFOLineItemsList.size() - 1].Qty_In_Stock_When_Created__c != null) {
                            partFIFOLineItemsList[partFIFOLineItemsList.size() - 1].Average_Cost_When_Created__c = ((partFIFOLineItemsList[partFIFOLineItemsList.size() - 1].Average_Cost_When_Created__c != null) ? partFIFOLineItemsList[partFIFOLineItemsList.size() - 1].Average_Cost_When_Created__c : 0);
                            partFIFOLineItemsList[partFIFOLineItemsList.size() - 1].Qty_Out__c = ((partFIFOLineItemsList[partFIFOLineItemsList.size() - 1].Qty_Out__c != null) ? partFIFOLineItemsList[partFIFOLineItemsList.size() - 1].Qty_Out__c : 0); 
                            partFIFOLineItemsList[partFIFOLineItemsList.size() - 1].Cost__c = partFIFOLineItemsList[partFIFOLineItemsList.size() - 1].Cost__c != null ? partFIFOLineItemsList[partFIFOLineItemsList.size() - 1].Cost__c 
                                                                    : (partFIFOLineItemsList[partFIFOLineItemsList.size() - 1].Part_FIFO_Bucket__r.Cost__c != null? partFIFOLineItemsList[partFIFOLineItemsList.size() - 1].Part_FIFO_Bucket__r.Cost__c : 0);
                   
                            closingQty = partFIFOLineItemsList[partFIFOLineItemsList.size() - 1].Qty_In_Stock_When_Created__c 
                                - (partFIFOLineItemsList[partFIFOLineItemsList.size() - 1].Qty_Out__c );
                            closingCost = (closingQty == 0 ? 0 : (partFIFOLineItemsList[partFIFOLineItemsList.size() - 1].Qty_In_Stock_When_Created__c * partFIFOLineItemsList[partFIFOLineItemsList.size() - 1].Average_Cost_When_Created__c ) - (partFIFOLineItemsList[partFIFOLineItemsList.size() - 1].Qty_Out__c * partFIFOLineItemsList[partFIFOLineItemsList.size() - 1].Cost__c));
                        }
                        
                        Decimal partFifoBucketLineItemQtyOut;
                        for(Part_FIFO_Bucket_Activity_Line_Item__c fifoBucketActivityLineItemObject : partFIFOLineItemsList) {
                            partFifoBucketLineItemQtyOut = fifoBucketActivityLineItemObject.Qty_Out__c != null ? fifoBucketActivityLineItemObject.Qty_Out__c: 0.0;
                            fifoBucketActivityLineItemObject.Cost__c = fifoBucketActivityLineItemObject.Cost__c != null ? fifoBucketActivityLineItemObject.Cost__c 
                                                                            : (fifoBucketActivityLineItemObject.Part_FIFO_Bucket__r.Cost__c != null? fifoBucketActivityLineItemObject.Part_FIFO_Bucket__r.Cost__c : 0);
                            //// Sales Qty And Cost
                            if(fifoBucketActivityLineItemObject.CO_Invoice_Header__c !=null) {
                               salesQty += partFifoBucketLineItemQtyOut;
                               salesCost += partFifoBucketLineItemQtyOut * fifoBucketActivityLineItemObject.Cost__c;
                               List<Coli_Fifo_Line_Item_Junction__c> coliJunction =(List<Coli_Fifo_Line_Item_Junction__c>)fifoBucketActivityLineItemObject.getSObjects(Constants.NAMESPACE + 'Coli_Fifo_Line_Items_Junction__r');
                               if( coliJunction != null && coliJunction.size() >0) {
                                   CO_Line_Item__c coli = (CO_Line_Item__c) coliJunction[0].getSObject(Constants.NAMESPACE + 'CO_Line_Item__r');
                                    Decimal price = coli.Service_Order_Line_Item__c != null ? coli.Service_Order_Line_Item__r.Kit_Price__c : coli.Price__c;
                                    if(price != null && price != 0) {
                                        totalSales +=  partFifoBucketLineItemQtyOut * price;
                                    }
                               }
                            }
                            //Adjusted Cost
                            if(FIFOTransaction.referenceNamesForAdjusmentSet.contains(fifoBucketActivityLineItemObject.Reference__c)) {
                               adjustedQty -= partFifoBucketLineItemQtyOut;
                               adjustedCost -= partFifoBucketLineItemQtyOut * fifoBucketActivityLineItemObject.Cost__c;
                            }
                            
                            //Purchase Cost
                            if(fifoBucketActivityLineItemObject.Reference__c == 'Vendor Return') {
                                purchaseQty -= partFifoBucketLineItemQtyOut;
                                purchaseCost -= partFifoBucketLineItemQtyOut * fifoBucketActivityLineItemObject.Cost__c;
                            }
                        }
                   }
               } 
               // set properties for part movement object from above processed data
               partMovementObject.Opening_Value = openingCost;
               partMovementObject.Opening_Qty = openingQty;
               partMovementObject.Closing_Value = closingCost;
               partMovementObject.Closing_Qty = closingQty;
               partMovementObject.Purchased_Qty = purchaseQty;
               partMovementObject.Purchased_Cost = purchaseCost;
               partMovementObject.Sales_Qty = salesQty;
               partMovementObject.Cost_of_Sales = salesCost;
               partMovementObject.Adjusted_Qty = adjustedQty;
               partMovementObject.Adjusted_Cost = adjustedCost;
               partMovementObject.Total_Sales = totalSales;
               
               if(partMovementObject.Opening_Value !=0 ||  partMovementObject.Opening_Qty!=0 || partMovementObject.Closing_Value!=0 
                   || partMovementObject.Closing_Qty !=0 || partMovementObject.Purchased_Qty != 0 || partMovementObject.Purchased_Cost !=0
                   || partMovementObject.Sales_Qty !=0 || partMovementObject.Cost_of_Sales!=0 || partMovementObject.Adjusted_Qty!=0
                   || partMovementObject.Adjusted_Cost != 0 || partMovementObject.Total_Sales != 0) {
                   	
              		if(validatePartFIFO(partMovementObject, filterWrapperObj)) {
                   partMovementItems.add(partMovementObject);
               }
           }
        }
        }
        
        //loop over all parts that do not have a part fifo object in the range
        for(String partId : partIdToFifoBucketLineItemsMap.keySet()) {
            if(!partIdToFifoBucketsMap.containsKey(partId) && partIdToFifoBucketLineItemsMap.get(partId).size() > 0) {
                partMovementObject = new PartMovement(partIdToPartRecordMap.containsKey(partId) ? partIdToPartRecordMap.get(partId) : new Part__c());
                openingQty = openingCost = closingQty = closingCost = purchaseQty = purchaseCost = salesQty = salesCost = adjustedQty = adjustedCost = totalSales = 0.0;
                Decimal partFifoBucketLineItemQtyOut;
                List<Part_FIFO_Bucket_Activity_Line_Item__c> partFIFOLineItemsList = partIdToFifoBucketLineItemsMap.get(partId);
                if(partFIFOLineItemsList.size() > 0 && partFIFOLineItemsList[0].Qty_In_Stock_When_Created__c !=null){
                system.debug('FIFO Bucket LI ' + partFIFOLineItemsList[0] + ' ' + partFIFOLineItemsList[0].Qty_In_Stock_When_Created__c);
                   openingQty = partFIFOLineItemsList[0].Qty_In_Stock_When_Created__c;
                   openingCost = openingQty * 
                        (partFIFOLineItemsList[0].Average_Cost_When_Created__c != null? partFIFOLineItemsList[0].Average_Cost_When_Created__c : 0.0);
                }
                for(Part_FIFO_Bucket_Activity_Line_Item__c fifoBucketActivityLineItemObject 
                    : partIdToFifoBucketLineItemsMap.get(partId)) {
                    partFifoBucketLineItemQtyOut = fifoBucketActivityLineItemObject.Qty_Out__c != null ? fifoBucketActivityLineItemObject.Qty_Out__c: 0.0;
                    fifoBucketActivityLineItemObject.Cost__c = fifoBucketActivityLineItemObject.Cost__c != null ? fifoBucketActivityLineItemObject.Cost__c 
                                                                    : (fifoBucketActivityLineItemObject.Part_FIFO_Bucket__r.Cost__c != null? fifoBucketActivityLineItemObject.Part_FIFO_Bucket__r.Cost__c : 0);
                    //// Sales Qty And Cost
                    if(fifoBucketActivityLineItemObject.CO_Invoice_Header__c != null) {
                        salesQty += partFifoBucketLineItemQtyOut;
                        salesCost += partFifoBucketLineItemQtyOut * fifoBucketActivityLineItemObject.Cost__c;
                        List<Coli_Fifo_Line_Item_Junction__c> coliJunction =(List<Coli_Fifo_Line_Item_Junction__c>) fifoBucketActivityLineItemObject.getSObjects(Constants.NAMESPACE + 'Coli_Fifo_Line_Items_Junction__r');
                        if( coliJunction != null && coliJunction.size() >0) {
                            CO_Line_Item__c coli = (CO_Line_Item__c) coliJunction[0].getSObject(Constants.NAMESPACE + 'CO_Line_Item__r');
                            Decimal price = coli.Service_Order_Line_Item__c != null ? coli.Service_Order_Line_Item__r.Kit_Price__c : coli.Price__c;
                            if(price != null && price != 0) {
                                totalSales += partFifoBucketLineItemQtyOut * price;
                            }
                        }
                    }
                    //Adjusted Cost
                    if(FIFOTransaction.referenceNamesForAdjusmentSet.contains(fifoBucketActivityLineItemObject.Reference__c)) {
                        adjustedQty -= partFifoBucketLineItemQtyOut;
                        adjustedCost -= partFifoBucketLineItemQtyOut * fifoBucketActivityLineItemObject.Cost__c;
                    }
                    
                    //Purchase Cost
                    if(fifoBucketActivityLineItemObject.Reference__c == 'Vendor Return') {
                        purchaseQty -= partFifoBucketLineItemQtyOut;
                        purchaseCost -= partFifoBucketLineItemQtyOut * fifoBucketActivityLineItemObject.Cost__c;
                    }
               }
               if(partFIFOLineItemsList.size() > 0 && partFIFOLineItemsList[partFIFOLineItemsList.size() - 1].Qty_In_Stock_When_Created__c !=null){
                    partFIFOLineItemsList[partFIFOLineItemsList.size() - 1].Average_Cost_When_Created__c = ((partFIFOLineItemsList[partFIFOLineItemsList.size() - 1].Average_Cost_When_Created__c != null) ? partFIFOLineItemsList[partFIFOLineItemsList.size() - 1].Average_Cost_When_Created__c : 0);
                    partFIFOLineItemsList[partFIFOLineItemsList.size() - 1].Qty_Out__c = ((partFIFOLineItemsList[partFIFOLineItemsList.size() - 1].Qty_Out__c != null) ? partFIFOLineItemsList[partFIFOLineItemsList.size() - 1].Qty_Out__c : 0); 
                     partFIFOLineItemsList[partFIFOLineItemsList.size() - 1].Cost__c = partFIFOLineItemsList[partFIFOLineItemsList.size() - 1].Cost__c != null ? partFIFOLineItemsList[partFIFOLineItemsList.size() - 1].Cost__c 
                                                                    : (partFIFOLineItemsList[partFIFOLineItemsList.size() - 1].Part_FIFO_Bucket__r.Cost__c != null? partFIFOLineItemsList[partFIFOLineItemsList.size() - 1].Part_FIFO_Bucket__r.Cost__c : 0);
                    closingQty = partFIFOLineItemsList[partFIFOLineItemsList.size() - 1].Qty_In_Stock_When_Created__c 
                        - (partFIFOLineItemsList[partFIFOLineItemsList.size() - 1].Qty_Out__c );
                    closingCost = (closingQty == 0 ? 0 : ( partFIFOLineItemsList[partFIFOLineItemsList.size() - 1].Qty_In_Stock_When_Created__c * partFIFOLineItemsList[partFIFOLineItemsList.size() - 1].Average_Cost_When_Created__c ) - (partFIFOLineItemsList[partFIFOLineItemsList.size() - 1].Qty_Out__c * partFIFOLineItemsList[partFIFOLineItemsList.size() - 1].Cost__c));
                }
               partMovementObject.Opening_Value = openingCost;
               partMovementObject.Opening_Qty = openingQty;
               partMovementObject.Closing_Value = closingCost;
               partMovementObject.Closing_Qty = closingQty;
               partMovementObject.Purchased_Qty = purchaseQty;
               partMovementObject.Purchased_Cost = purchaseCost;
               partMovementObject.Sales_Qty = salesQty;
               partMovementObject.Cost_of_Sales = salesCost;
               partMovementObject.Adjusted_Qty = adjustedQty;
               partMovementObject.Adjusted_Cost = adjustedCost;
               partMovementObject.Total_Sales = totalSales;
               if(partMovementObject.Opening_Value !=0 ||  partMovementObject.Opening_Qty!=0 || partMovementObject.Closing_Value!=0 
                   || partMovementObject.Closing_Qty!=0 || partMovementObject.Purchased_Qty != 0 || partMovementObject.Purchased_Cost !=0
                   || partMovementObject.Sales_Qty !=0 || partMovementObject.Cost_of_Sales!=0 || partMovementObject.Adjusted_Qty!=0
                   || partMovementObject.Adjusted_Cost != 0 || partMovementObject.Total_Sales != 0) {
                   	
                   if(validatePartFIFO(partMovementObject, filterWrapperObj)) {
                   partMovementItems.add(partMovementObject);
               }
                   
               }
            }
        }
        partIdToFifoBucketsMap = new Map<String, List<Part_FIFO_Bucket__c>>();
        partIdToFifoBucketLineItemsMap = new Map<String, List<Part_FIFO_Bucket_Activity_Line_Item__c>>();
        
        return partMovementItems;
    }

    private static Map<Id,List<Unit_Price_Cost__c>> getCouToUpcMapForStockUnitValution(HomeSearchFilterWrapper filterWrapperObj, List<Id> couIdList, DateTime dtValue) {
        Map<Id,List<Unit_Price_Cost__c>> couToUPCMap = new Map<Id,List<Unit_Price_Cost__c>>();
        List<Unit_Price_Cost__c> upcList = new List<Unit_Price_Cost__c>();

        if(dtValue != null) {
            upcList = [Select Id, Customer_Owned_Unit__c, Type__c, Total_Cost__c, Total_Price__c From Unit_Price_Cost__c where ((Adjustment_Date__c <: dtValue ) OR (Type__c = 'Base' AND Adjustment_Date__c = null)  OR (Type__c = 'Dealer' AND CreatedDate <:  dtValue )) AND Customer_Owned_Unit__c IN: couIdList];
        } else {
            upcList = [Select Id, Customer_Owned_Unit__c, Type__c, Total_Cost__c, Total_Price__c From Unit_Price_Cost__c where Customer_Owned_Unit__c IN: couIdList];
        }
        
        for(Unit_Price_Cost__c upcRec: upcList) {
            if(!couToUPCMap.containsKey(upcRec.Customer_Owned_Unit__c)) {
                couToUPCMap.put(upcRec.Customer_Owned_Unit__c, new List<Unit_Price_Cost__c>());
            } 
            couToUPCMap.get(upcRec.Customer_Owned_Unit__c).add(upcRec);
            
        }
        return couToUPCMap;
    }

    private static Map<Id, Decimal> getCouToOptionsWIPForStockUnitValution(HomeSearchFilterWrapper filterWrapperObj, List<Id> couIdList, DateTime dtValue) {
        List<Option_Fee__c> opList = [SELECT Deal_Item__r.Customer_Owned_Unit__c, Deal_Kit_Header__c, Per_Item_Cost__c, Qty__c, CO_Line_Item__r.Invoice_Number__r.Closed_Invoice_Date__c, 
                                        Service_Order_Line_Item__r.Service_Order_Header__r.Invoice_Number__r.Closed_Invoice_Date__c 
                                        FROM Option_Fee__c WHERE Deal_Item__r.Customer_Owned_Unit__c IN :couIdList AND Status__c = :Constants.FULFILLED];
        
        Map<Id, Decimal> couToOptionsWIPMap = new Map<Id, Decimal>();
        if(dtValue == null) {
            dtValue = datetime.newInstance(System.today().year(), System.today().month(), System.today().day(), 0, 0, 0);
            String dtStringValue = dtValue.addDays(1).formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
            dtValue = (DateTime)JSON.deserialize('"' + dtStringValue + '"', DateTime.class);
        }
        for(Option_Fee__c optionFeeRec: opList) {
            if(!couToOptionsWIPMap.containsKey(optionFeeRec.Deal_Item__r.Customer_Owned_Unit__c)) {
                couToOptionsWIPMap.put(optionFeeRec.Deal_Item__r.Customer_Owned_Unit__c, 0);
            }

            if((optionFeeRec.CO_Line_Item__c != null && optionFeeRec.Service_Order_Line_Item__c == null && optionFeeRec.CO_Line_Item__r.Invoice_Number__c != null && 
                dtValue >= optionFeeRec.CO_Line_Item__r.Invoice_Number__r.Closed_Invoice_Date__c) || 
                (optionFeeRec.Service_Order_Line_Item__c != null && optionFeeRec.Service_Order_Line_Item__r.Service_Order_Header__r.Invoice_Number__c != null && 
                dtValue >= optionFeeRec.Service_Order_Line_Item__r.Service_Order_Header__r.Invoice_Number__r.Closed_Invoice_Date__c)) {
                optionFeeRec.Per_Item_Cost__c = (optionFeeRec.Per_Item_Cost__c != null ? (optionFeeRec.Per_Item_Cost__c).setScale(2, RoundingMode.HALF_UP) : 0);
                optionFeeRec.Qty__c = (optionFeeRec.Qty__c != null ? optionFeeRec.Qty__c : 0);
                Decimal cost = (optionFeeRec.Per_Item_Cost__c * optionFeeRec.Qty__c).setScale(2, RoundingMode.HALF_UP);
                couToOptionsWIPMap.put(optionFeeRec.Deal_Item__r.Customer_Owned_Unit__c, couToOptionsWIPMap.get(optionFeeRec.Deal_Item__r.Customer_Owned_Unit__c) + cost);
            }
        }
        return couToOptionsWIPMap;
    }

    private static List<InventoryUnit> getTotalsFormChildQueryForStockUnitValution(List<sObject> records, Map<Id,List<Unit_Price_Cost__c>> couToUPCMap, 
                                                                                    Map<Id, Decimal> couToOptionsWIPMap) {
        List<InventoryUnit> unitList = new List<InventoryUnit>();
        InventoryUnit invUnit;

        for(Customer_Owned_Unit__c unitRec : (List<Customer_Owned_Unit__c>)records) {
            invUnit = new InventoryUnit(unitRec);
            if(!unitRec.Unit_Type__c.equalsIgnoreCase('COU')) {
                invUnit.Base_Unit_Price = 0;
                invUnit.Factory_Options = 0;
                invUnit.Dealer_Options = 0;
                invUnit.Total_Price = 0;
                invUnit.Base_Unit_Cost = 0;
                invUnit.Factory_Option_Cost = 0;
                invUnit.Dealer_Option_Cost = 0;
                invUnit.Total_Cost = 0;
                invUnit.Deal_Options_WIP = 0;
                
                if(unitRec.Id != null && couToUPCMap != null && couToUPCMap.containsKey(unitRec.Id)){
                    for(Unit_Price_Cost__c unitPriceAndCost : couToUPCMap.get(unitRec.Id)) {
                        if(unitPriceAndCost.Type__c != null && unitPriceAndCost.Type__c == UnitPriceAndCostTriggerHelper.TYPE_BASE) {
                            invUnit.Base_Unit_Cost += (unitPriceAndCost.Total_Cost__c == null) ? 0 : unitPriceAndCost.Total_Cost__c;
                            invUnit.Base_Unit_Price += (unitPriceAndCost.Total_Price__c == null) ? 0 : unitPriceAndCost.Total_Price__c;
                        } else if(unitPriceAndCost.Type__c != null && unitPriceAndCost.Type__c == UnitPriceAndCostTriggerHelper.TYPE_DEALER) {
                            invUnit.Dealer_Option_Cost += (unitPriceAndCost.Total_Cost__c == null) ? 0 : unitPriceAndCost.Total_Cost__c;
                            invUnit.Dealer_Options += (unitPriceAndCost.Total_Price__c == null) ? 0 : unitPriceAndCost.Total_Price__c;
                        } else if(unitPriceAndCost.Type__c != null && unitPriceAndCost.Type__c == UnitPriceAndCostTriggerHelper.TYPE_FACTORY) {
                            invUnit.Factory_Option_Cost += (unitPriceAndCost.Total_Cost__c == null) ? 0 : unitPriceAndCost.Total_Cost__c;
                            invUnit.Factory_Options += (unitPriceAndCost.Total_Price__c == null) ? 0 : unitPriceAndCost.Total_Price__c;
                        }
                        
                        invUnit.Total_Cost = invUnit.Base_Unit_Cost + invUnit.Factory_Option_Cost + invUnit.Dealer_Option_Cost;
                        invUnit.Total_Price = invUnit.Base_Unit_Price + invUnit.Factory_Options + invUnit.Dealer_Options;
                    }
                }

                if(couToOptionsWIPMap.containsKey(unitRec.Id)) {
                    invUnit.Deal_Options_WIP = couToOptionsWIPMap.get(unitRec.Id);
                }
            }
            unitList.add(invUnit);
        }
        return unitList;
    }
    /**
     * Name: ResultWrapper
     * Desc: RESULT records wrapper class used to get records in json format
    **/
    public class ResultWrapper {
        
        
        public Integer Total_Records {get; private set;}
        public String RecordsVariableName {get; private set;}
        public List<HomeSearchFilterInterface.FilterLabel> FilterLabelList {get; set;}
        
        // People
        public List<Customer> CustomerRecords {get; set;}
        public List<Vendor> VendorRecords {get; set;}
        public List<People> PeopleRecords {get; set;}
        
        // Products
        public List<Part> PartRecords {get; set;}
        public List<LabourCode> LabourRecords {get; set;}
        public List<Fee> FeeRecords {get; set;}
        public List<KitHeader> KitRecords {get; set;}
        public List<Product> ProductRecords {get; set;}
        //public List<VendorProduct> SubletRecords {get; set;}
        public List<VendorProduct> VendorProductRecords {get; set;}
        // Customer Sales
        public List<CustomerSales> CustomerSalesRecords {get; set;}
        public List<CustomerOrders> CustomerOrderRecords {get; set;}
        public List<SpecialOrder> SpecialOrderRecords {get; set;}
        
        public List<CustomerInvoice> CustomerInvoiceRecords {get; set;}
        public List<CustomerPayment> CustomerPaymentRecords {get; set;}
        
        // Vendor Orders
        public List<VendorOrder> VendorOrderRecords {get; set;}
        public List<VendorInvoice> VendorInvoiceRecords {get; set;}
        public List<VendorRecieving> VendorRecievingRecords {get; set;}
        public List<VendorOrdering> VendorOrderingRecords {get; set;}
        
        // Setting
        public List<Category> CategoryRecords {get; set;}
        public List<PriceLevel> PriceLevelRecords {get; set;}
        public List<salesTax> SalesTaxRecords {get; set;}
        public List<Setting> SettingRecords {get; set;}
        
        // User
        public List<UserRec> UserRecords {get; set;}
        //PartNeeded Dinesh Kumar 10/10/2016
        public List<PartNeeded> PartNeededRecords {get; set;}
        public List<InvoicedItems> InvoicedItems {get; set;}
        public List<TechnicianHours> TechnicianHourRecords {get; set;}
        public List<PayrollHours> PayrollHourRecords {get; set;}
        // Service Order Header
        public List<ServiceJob> ServiceJobs {get; set;}
        public List<TechnicianPerformance> TechnicianPerformanceRecords {get; set;}
        //Start: Added by Nidhi - #1152 - 19-10-2016
        // Inventory Unit
        public List<InventoryUnit> InventoryUnits {get; set;}
        //END: Added by Nidhi - #1152 - 19-10-2016        
        public List<CustomerUnit> CustomerUnits {get; set;}
        public List<UnitDeal> UnitDealRecords {get; set;}
        public List<DealUnit> DealUnitRecords {get; set;}
        public List<PartsOrder> PartsOrderRecords {get; set;}
        public List<PartsToPull> PartsToPullRecords;
        
        public List<PartMovement> PartMovementRecords {get; set;}
        public List<TaxReporting> TaxDetailRecords {get; set;}
        public List<HSCustomerInvoiceDetailWrapper> CustomerInvoiceDetailRecords {get; set;}
        public List<OrderedUnit> OrderedUnits {get; set;} 
        // Any Object(Generic Type)
        public List<AnyObject> AnyObjectRecords {get; set;}
        public Boolean IsIncludeInactiveRecords {get; set;}
        public Boolean IsSummaryFormat {get; set;}
        public List<VOItems> VOItems {get; set;} 
        public List<SubletItems> SubletItems {get; set;} 
        public List<VendorReturn> VendorReturns {get; set;} 
        public List<ClaimJobs> ClaimJobs {get; set;}
        public List<UnitRegister> UnitRegister {get; set;}
        public ResultWrapper(Integer Total_Records, String RecordsVariableName){
            this.Total_Records = Total_Records;
            this.RecordsVariableName = RecordsVariableName;
        }
    }
    
    public class OrderedUnit {
    	public Integer Type {get; private set;}
        public String Id {get; private set;}
        public String Make {get; private set;}
        public String Model {get; private set;}
        public String SubModel {get; private set;}
        public Decimal Year {get; private set;}
        public String Unit_ID {get; private set;}
        public String Category {get; private set;}
        public String Ordered {get; private set;}
        public String Expected {get; private set;}
        public Decimal Days_Out {get; private set;}
        public String FO_Number {get; private set;}
        public String Committed {get; private set;}
        public Decimal Unit_Cost {get; private set;}
        public Decimal Tax {get; private set;}
        public Decimal Total_Cost {get; private set;}
        public Decimal Retail_Price {get; private set;}
        public String Vendor {get; private set;}
        public String VIN {get; private set;}
        public String Stock_Number {get; private set;}
        public String Ext_Color {get; private set;}
        public String Int_Color {get; private set;}
        public String VendorId {get; private set;}
        public String Status {get; private set;}
        
    	public OrderedUnit(Customer_Owned_Unit__c unitRec) {
    		this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Order Unit');
            this.Id = unitRec.Id;
            this.Make = (unitRec.Unit_Make__c != null) ? unitRec.Unit_Make__r.Name : '';
            this.Model = (unitRec.Unit_Model__c != null) ? unitRec.Unit_Model__r.Name__c : '';
            this.SubModel = (unitRec.Sub_Model__c != null) ? unitRec.Sub_Model__r.Sub_Model_Name__c : '';
            this.Year = unitRec.Year__c;
            this.Unit_ID = unitRec.Unit_Number__c;
            this.Category = (unitRec.Category__c != null) ? unitRec.Category__r.Name : '';
            this.Ordered = (unitRec.Date_Ordered__c != null) ? BPUtility.getFormatedDateTime(datetime.newInstance(unitRec.Date_Ordered__c.year(), unitRec.Date_Ordered__c.month(),unitRec.Date_Ordered__c.day())) : '';
            this.Expected = (unitRec.Date_Expected__c != null) ? BPUtility.getFormatedDateTime(datetime.newInstance(unitRec.Date_Expected__c.year(), unitRec.Date_Expected__c.month(),unitRec.Date_Expected__c.day())) : '';
            this.Days_Out = unitRec.Age__c;
            this.FO_Number = (unitRec.Factory_Order_No__c != null) ? unitRec.Factory_Order_No__c : '';
            this.Committed = unitRec.Deal_Item__c != null ? 'Yes' : 'No';
            this.Unit_Cost = ((unitRec.Total_Cost__c == null) ? 0 : unitRec.Total_Cost__c).setScale(2, RoundingMode.HALF_UP);
            this.Tax = ((unitRec.Tax_Amount__c == null) ? 0 : unitRec.Tax_Amount__c).setScale(2, RoundingMode.HALF_UP);
            this.Total_Cost = ((unitRec.Total_Cost_With_Tax__c != null) ? unitRec.Total_Cost_With_Tax__c : 0).setScale(2, RoundingMode.HALF_UP);
            this.Retail_Price = ((unitRec.Total_Price__c == null) ? 0 : unitRec.Total_Price__c).setScale(2, RoundingMode.HALF_UP);
            this.Vendor = (unitRec.Vendor__c != null) ? unitRec.Vendor__r.Name : '';
            this.VIN = (unitRec.VIN_Number_Formula__c == null) ? '' : unitRec.VIN_Number_Formula__c;
            this.Stock_Number = unitRec.Stock_Id__c != null ? unitRec.Stock_Id__c : unitRec.Unit_Number__c;
            this.Ext_Color = unitRec.Colour__c;
            this.Int_Color = unitRec.Interior_Colour__c;
            this.VendorId = unitRec.Vendor__c;
            this.Status = unitRec.Status__c;
    	}
    }
    
    public class TechnicianPerformance {
       public String Id {get; private set;}
       public Integer Type {get; private set;}
       public String Technician {get; private set;}
       public Decimal Hours_Worked {get; private set;}
       public Decimal Hrs_Clocked_On {get; private set;}
       public String Productivity {get; private set;}
       public Decimal Clocked_Hrs_Invoiced {get; private set;}
       public Decimal Invoice_Hrs {get; private set;}
       public String Efficiency {get; private set;}
       public String Proficiency {get; private set;}
       public Decimal Clocked_Hrs_WIP {get; private set;}
       public Decimal Paused_Hrs;
       public Decimal Other_Tasks_Hrs {get; private set;}
       public Decimal Invoice_Hrs_WIP {get; private set;}
       public Decimal Invoiced_Cost {get; private set;}
       public Decimal Uninvoiced_Cost {get; private set;}
       
       public TechnicianPerformance(Technician__c technicianRec) {
            this.Id  = technicianRec.Id;
            this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Technician Performance');
            this.Technician  = technicianRec.Technician_Name__c;
            
            this.Hrs_Clocked_On = 0;
            this.Clocked_Hrs_Invoiced = 0;
            this.Clocked_Hrs_WIP = 0;
            this.Invoice_Hrs = 0;
            this.Paused_Hrs = 0;
            this.Other_Tasks_Hrs = 0;
            this.Invoice_Hrs_WIP = 0;
            this.Invoiced_Cost = 0;
            this.Uninvoiced_Cost = 0;
            for(Hours_Logged__c hrsLoggedRec : technicianRec.Hours_Logged__r) {
                if(!hrsLoggedRec.Is_Removed__c) {
					if(String.isNotBlank(hrsLoggedRec.Service_Order_Header__c)) {
						this.Hrs_Clocked_On += (hrsLoggedRec.Calculated_Hours__c != null) ? hrsLoggedRec.Calculated_Hours__c : 0;
                        this.Paused_Hrs += (hrsLoggedRec.Paused_Hours__c != null ? hrsLoggedRec.Paused_Hours__c : 0);
						
						if(hrsLoggedRec.Service_Order_Header__r.SO_Status__c == 'Invoiced') {
							this.Clocked_Hrs_Invoiced += (hrsLoggedRec.Calculated_Hours__c != null) ? hrsLoggedRec.Calculated_Hours__c : 0;
							this.Invoice_Hrs += (hrsLoggedRec.Billed_Hours__c != null) ? hrsLoggedRec.Billed_Hours__c : 0;
							this.Invoiced_Cost += (hrsLoggedRec.Total_Cost__c != null) ? hrsLoggedRec.Total_Cost__c : 0;
						} else {
							this.Clocked_Hrs_WIP += (hrsLoggedRec.Calculated_Hours__c != null) ? hrsLoggedRec.Calculated_Hours__c : 0;
							this.Invoice_Hrs_WIP += (hrsLoggedRec.WIP_Invoice_Hours__c != null) ? hrsLoggedRec.WIP_Invoice_Hours__c : 0;
							this.Uninvoiced_Cost += (hrsLoggedRec.Total_Cost__c != null) ? hrsLoggedRec.Total_Cost__c : 0;
						}
					} else if(String.isNotBlank(hrsLoggedRec.Task__c)) {
						this.Other_Tasks_Hrs += (hrsLoggedRec.Calculated_Hours__c != null) ? hrsLoggedRec.Calculated_Hours__c : 0;
					}
				}
            }
            
            this.Hrs_Clocked_On = (this.Hrs_Clocked_On == null ? 0 : this.Hrs_Clocked_On).setScale(2, RoundingMode.HALF_UP);
            this.Clocked_Hrs_WIP = (this.Clocked_Hrs_WIP == null ? 0 : this.Clocked_Hrs_WIP).setScale(2, RoundingMode.HALF_UP);
            this.Clocked_Hrs_Invoiced = (this.Clocked_Hrs_Invoiced == null ? 0 : this.Clocked_Hrs_Invoiced).setScale(2, RoundingMode.HALF_UP);
            this.Invoice_Hrs = (this.Invoice_Hrs == null ? 0 : this.Invoice_Hrs).setScale(2, RoundingMode.HALF_UP);
            this.Invoice_Hrs_WIP = (this.Invoice_Hrs_WIP == null ? 0 : this.Invoice_Hrs_WIP).setScale(2, RoundingMode.HALF_UP);
            this.Paused_Hrs = (this.Paused_Hrs == null ? 0 : this.Paused_Hrs).setScale(2, RoundingMode.HALF_UP);
            this.Other_Tasks_Hrs = (this.Other_Tasks_Hrs == null ? 0 : this.Other_Tasks_Hrs).setScale(2, RoundingMode.HALF_UP);
            this.Invoiced_Cost = (this.Invoiced_Cost == null ? 0 : this.Invoiced_Cost).setScale(2, RoundingMode.HALF_UP);
            this.Uninvoiced_Cost = (this.Uninvoiced_Cost == null ? 0 : this.Uninvoiced_Cost).setScale(2, RoundingMode.HALF_UP);
            
            Decimal totalInvoiceHours = (this.Invoice_Hrs + Invoice_Hrs_WIP);
            Decimal totalClockedHours = (this.Clocked_Hrs_WIP + Clocked_Hrs_Invoiced);
            Decimal eff = (totalClockedHours != 0) ? 
            				(totalInvoiceHours / totalClockedHours) : totalInvoiceHours;
            this.Efficiency = String.valueOf((eff * 100).setScale(2, RoundingMode.HALF_UP)) + '%';
            
            this.Hours_Worked = 0;
            for(Payroll_Time__c payrollTimeRec : technicianRec.Payroll_Times__r) {
                this.Hours_Worked += (payrollTimeRec.Total_Time__c != null) ? payrollTimeRec.Total_Time__c : 0;
            }
            
            this.Hours_Worked = (this.Hours_Worked == null ? 0 : this.Hours_Worked).setScale(2, RoundingMode.HALF_UP);
            Decimal prdctivity = (this.Hours_Worked != null && this.Hours_Worked != 0) ? this.Hrs_Clocked_On / this.Hours_Worked : this.Hrs_Clocked_On;
            this.Productivity = String.valueOf((prdctivity * 100).setScale(2, RoundingMode.HALF_UP)) + '%';

            Decimal prf = (prdctivity * eff * 100).setScale(2, RoundingMode.HALF_UP);
            this.Proficiency = String.valueOf(prf) + '%';
        }
    }
    
    /**
     * Name: Customer
     * Description: Sets the value of customer 
     * 
    **/
    public class Customer {
        public Integer Type {get; private set;}
        public String Customer_Number {get; private set;}
        public String Customer_Name {get; private set;}
        public String Phone_Number {get; private set;}
        public String Email {get; private set;}
        public String Owner {get; private set;}
        public String Modified {get; private set;}
        public String Status {get; private set;}
        public String Id {get; private set;}
        
        public String First_Name {get; private set;}
        public String Last_Name {get; private set;}
        public String Nickname {get; private set;}
        public String Birth_Date {get; private set;}
        public String VIP_Number {get; private set;} 
        public String Job_Title {get; private set;}
        
        public String Billing_Address {get; private set;}
        public String Billing_City {get; private set;}
        public String Billing_State {get; private set;}
        public String Shipping_Address {get; private set;}
        public String Shipping_City {get; private set;}
        public String Shipping_State {get; private set;}
        
        public String Home_Number {get; private set;}
        public String Mobile_Number {get; private set;}
        public String Other_Email {get; private set;}
        public String Work_Email {get; private set;}
        public String Work_Number {get; private set;}
        
        public String Facebook {get; private set;}
        public String LinkedIn {get; private set;}
        public String Twitter {get; private set;}
        public String Website {get; private set;}
        public String Sales_Tax {get; private set;}
        public String Price_Level {get; private set;}
        
        public Decimal Open_Orders {get; private set;}
        public Decimal Orders_Lifetime {get; private set;} 
        public Decimal Average_Spend_per_Order {get; private set;}
        public String Created {get; private set;}
        public String Parent_Account {get; private set;}
        public String Active {get; private set;}
        public String Postal_Code {get; private set;}
        public String Account_Type {get; private set;}
        public String Drivers_License {get; private set;}
        public Decimal Store_Credits {get; private set;}
        
        public Customer(Account acc) {
            this.Id = acc.Id;
            this.Customer_Number = acc.Customer_Number__c;
            this.Customer_Name = acc.Name;
            
            if(acc.Email__c != null && acc.Type__c == 'Individual') {
                this.Email = acc.Email__c;
            } else if(acc.Work_Email__c != null && acc.Type__c == 'Business') {
                this.Email = acc.Work_Email__c;
            } else if(acc.Other_Email__c != null) {
                this.Email = acc.Other_Email__c;
            }
            
            if(acc.Type__c == 'Individual' && acc.Home_Number__c != null) {
                this.Phone_Number = acc.Formatted_Home_number__c;
            } else if(acc.Type__c == 'Business' && acc.Work_Number__c != null) {
                this.Phone_Number = acc.Formatted_Work_Number__c;
            }
            
            //this.Phone_Number = acc.Preferred_Phone__c;
            //this.Email = acc.Email__c;
            this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Customers');
            this.Modified = BPUtility.getLastModifiedDateStr(acc);
            this.Owner = (acc.Owner.Name != null) ? acc.Owner.Name : null;
            this.Status = acc.Status__c;
                        
            this.First_Name = acc.FirstName__c;
            this.Last_Name =  acc.LastName__c;
            this.Nickname = acc.Nickname__c;
                        
            this.Birth_Date = (acc.Birth_Date__c != null) ? BPUtility.getFormatedDateTime((datetime.newInstance(acc.Birth_Date__c.year(), acc.Birth_Date__c.month(), acc.Birth_Date__c.day()))) : null;
            this.VIP_Number = acc.VIP__c;
            this.Job_Title = acc.Job_Title__c;
            
            String billingStreet = (acc.BillingStreet == null ) ? '' : acc.BillingStreet;
	        List<String> bsList = billingStreet.split('\n');
            this.Billing_Address = (bsList.size() > 0) ? bsList[0].replaceAll('\r', ' ') : '';
            this.Billing_Address += (bsList.size() > 1) ? ' ' + bsList[1].replaceAll('\r', ' ') : '';
            
            this.Billing_City = acc.BillingCity;
            this.Billing_State = acc.BillingState;
            
            if(!acc.Contacts.isEmpty()) {
                String shippingStreet = (acc.Contacts[0].MailingStreet == null ) ? '' : acc.Contacts[0].MailingStreet;
                List<String> spList = shippingStreet.split('\n');
                this.Shipping_Address = (spList.size() > 0) ? spList[0].replaceAll('\r', ' ') : '';
                this.Shipping_Address += (spList.size() > 1) ? ' ' + spList[1].replaceAll('\r', ' ') : '';
                
                this.Shipping_City = acc.Contacts[0].MailingCity;
                this.Shipping_State = acc.Contacts[0].MailingState;
            }
            
            this.Home_Number = acc.Formatted_Home_number__c;
            this.Mobile_Number = acc.Formatted_Mobile_Number__c;
            this.Other_Email = acc.Other_Email__c;
            this.Work_Email = acc.Work_Email__c;
            this.Work_Number = acc.Formatted_Work_Number__c;
            
            this.Facebook = acc.Facebook__c;
            this.LinkedIn = acc.LinkedIn__c;
            this.Twitter = acc.Twitter__c;
            this.Website = acc.Website;
            this.Sales_Tax = (acc.Sales_Tax__c != null) ? acc.Sales_Tax__r.Name__c : null;
            this.Price_Level = (acc.Price_Level__c != null) ? acc.Price_Level__r.Name__c : null;
             
            this.Open_Orders = acc.Open_Orders__c;
            this.Orders_Lifetime = acc.Orders_Lifetime__c;
            this.Average_Spend_per_Order = acc.Average_Spend_per_Order__c;
            this.Created = (acc.CreatedDate != null) ?  BPUtility.getFormatedDateTime(acc.CreatedDate) : null;
            this.Parent_Account = '';  
            this.Active = (acc.Active__c) ? 'Active' : 'Inactive';
            this.Postal_Code = acc.BillingPostalCode;
            this.Account_Type = (acc.Account_type__c != null) ? acc.Account_type__r.Name : '';
            this.Drivers_License = acc.Drivers_License__c;
            this.Store_Credits = acc.Total_Store_Credit__c != null ? acc.Total_Store_Credit__c : 0;
        }
    }
    
    /**
     * Name: Vendor
     * Description: Sets the value of vendor
    **/
    
    public class Vendor {
        public Integer Type {get; private set;}
        public String Vendor_Code {get; private set;}
        public String Vendor_Name {get; private set;}
        public String Phone_Number {get; private set;}
        public String Email {get; private set;}
        public String Modified {get; private set;}
        public String Owner {get; private set;}
        public String Status {get; private set;}
        public String Id {get; private set;}
        
        public String Billing_Address {get; private set;}
        public String Billing_City {get; private set;}
        public String Billing_State {get; private set;}
        public String Shipping_Address {get; private set;}
        public String Shipping_City {get; private set;}
        public String Shipping_State {get; private set;}
        public String Billing_Zipcode {get; private set;}
        public String Shipping_Zipcode {get; private set;}
        
        
        public String Mobile_Number {get; private set;}
        public String Other_Email {get; private set;}
        public String Work_Email {get; private set;}
        public String Work_Number {get; private set;}
        
        public String Facebook {get; private set;}
        public String LinkedIn {get; private set;}
        public String Twitter {get; private set;}
        public String Website {get; private set;}
        public String Sales_Tax {get; private set;}
        public String Price_Level {get; private set;}
        
        public Decimal Open_Orders {get; private set;}
        public Decimal Orders_Lifetime {get; private set;} 
        public Decimal Average_Spend_per_Order {get; private set;}
        public String Created {get; private set;}
        public String Parent_Account {get; private set;}
        
        
        public String Last_Order {get; private set;}
        public String Purchase_Tax {get; private set;}
        public String Vendor_Account_Number {get; private set;}
        public String Part_Category_Default {get; private set;}
        public String Unit_Category_Default {get; private set;}
        public Boolean Claims_for_Service_Work {get; private set;}
        public Boolean Flooring_Company  {get; private set;}
        public Boolean Part_Purchases {get; private set;}
        public Boolean Sublet_Purchases {get; private set;}
        public Boolean Unit_Purchases {get; private set;}
        public Boolean Warranty_Plan_Sales_on_Unit_Deals {get; private set;}
        public String Active {get; private set;}
        public String Account_Type {get; private set;}
        
            
        public Vendor(Account acc) {
            this.Id = acc.Id;
            this.Vendor_Code = acc.Vendor_Code__c;
            this.Vendor_Name = acc.Name;
            
            if(acc.Work_Email__c != null) {
                this.Email = acc.Work_Email__c;
            } else if(acc.Other_Email__c != null) {
                this.Email = acc.Other_Email__c;
            }
            
            if(acc.Work_Number__c != null) {
                this.Phone_Number = acc.Formatted_Work_Number__c;
            } else if(acc.Mobile__c != null) {
                this.Phone_Number = acc.Formatted_Mobile_Number__c;
            }
            
            //this.Phone_Number = acc.Preferred_Phone__c;
            //this.Email = acc.Email__c;
            this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Vendors');
            this.Modified = BPUtility.getLastModifiedDateStr(acc);
            this.Owner = (acc.Owner.Name != null) ? acc.Owner.Name : null;
            this.Status = acc.Status__c;
            
            String billingStreet = (acc.BillingStreet == null ) ? '' : acc.BillingStreet;
	        List<String> bsList = billingStreet.split('\n');
            this.Billing_Address = (bsList.size() > 0) ? bsList[0].replaceAll('\r', ' ') : '';
            this.Billing_Address += (bsList.size() > 1) ? ' ' + bsList[1].replaceAll('\r', ' ') : '';
            
            this.Billing_City = acc.BillingCity;
            this.Billing_State = acc.BillingState;
            this.Billing_Zipcode = acc.BillingPostalCode;
            
            if(!acc.Contacts.isEmpty()) {
                String shippingStreet = (acc.Contacts[0].MailingStreet == null ) ? '' : acc.Contacts[0].MailingStreet;
                List<String> spList = shippingStreet.split('\n');
                this.Shipping_Address = (spList.size() > 0) ? spList[0].replaceAll('\r', ' ') : '';
                this.Shipping_Address += (spList.size() > 1) ? ' ' + spList[1].replaceAll('\r', ' ') : '';
                
                this.Shipping_City = acc.Contacts[0].MailingCity;
                this.Shipping_State = acc.Contacts[0].MailingState;
                this.Shipping_Zipcode = acc.Contacts[0].MailingPostalCode;
            }
            
            this.Mobile_Number = acc.Formatted_Mobile_Number__c;
            this.Other_Email = acc.Other_Email__c;
            this.Work_Email = acc.Work_Email__c;
            this.Work_Number = acc.Formatted_Work_Number__c;
            
            this.Facebook = acc.Facebook__c;
            this.LinkedIn = acc.LinkedIn__c;
            this.Twitter = acc.Twitter__c;
            this.Website = acc.Website;
            this.Sales_Tax = (acc.Sales_Tax__c != null) ? acc.Sales_Tax__r.Name__c : null;
            this.Price_Level = (acc.Price_Level__c != null) ? acc.Price_Level__r.Name__c : null;
            
            this.Open_Orders = acc.Open_Orders__c;
            this.Orders_Lifetime = acc.Orders_Lifetime__c;
            this.Average_Spend_per_Order = acc.Average_Spend_per_Order__c;
            this.Created = (acc.CreatedDate != null) ?  BPUtility.getFormatedDateTime(acc.CreatedDate) : null;
            this.Parent_Account = '';  //
            
            this.Last_Order = acc.Last_Visit_Order__c;
            this.Purchase_Tax = (acc.Purchase_Tax__c != null) ? acc.Purchase_Tax__r.Name__c : null;
            this.Vendor_Account_Number = acc.AccountNumber;
            
            this.Part_Category_Default = (acc.Part_Category_Default__c != null) ? acc.Part_Category_Default__r.Name : null;
            this.Unit_Category_Default = (acc.Unit_Category_Default__c != null) ? acc.Unit_Category_Default__r.Name : null;
            this.Claims_for_Service_Work = acc.Claims_for_Service_Work__c;
            this.Flooring_Company = acc.Flooring_Company__c;
            this.Part_Purchases = acc.Part_Purchases__c;
            this.Sublet_Purchases = acc.Sublet_Purchases__c;
            this.Unit_Purchases = acc.Unit_Purchases__c;
            this.Warranty_Plan_Sales_on_Unit_Deals = acc.Warranty_Plan_Sales_on_Unit_Deals__c;
            this.Active = (acc.Active__c) ? 'Active' : 'Inactive';
            this.Account_Type = (acc.Vendor_Account_Type__c != null) ? acc.Vendor_Account_Type__r.Name : '';
        }
    }
    
    /**
     * Name: People
     * Description: Sets the value of the People 
    **/
    public class People {
        public Integer Type {get; private set;}
        public String Id_Number {get; private set;}
        public String Name {get; private set;}
        public String Phone_Number {get; private set;}
        public String Email {get; private set;}
        public String Owner {get; private set;}
        public String Modified {get; private set;}
        public String Status {get; private set;}
        
        public String Billing_Address {get; private set;}
        public String Billing_City {get; private set;}
        public String Billing_State {get; private set;}
        public String Shipping_Address {get; private set;}
        public String Shipping_City {get; private set;}
        public String Shipping_State {get; private set;}
        
        public String Mobile_Number {get; private set;}
        public String Other_Email {get; private set;}
        public String Work_Email {get; private set;}
        public String Work_Number {get; private set;}
        
        public String Facebook {get; private set;}
        public String LinkedIn {get; private set;}
        public String Twitter {get; private set;}
        public String Website {get; private set;}
        public String Sales_Tax {get; private set;}
        public String Price_Level {get; private set;}
        
        public Decimal Open_Orders {get; private set;}
        public String Created {get; private set;}
        public String Parent_Account {get; private set;}
        public String Id {get; private set;}
        public String Active {get; private set;}
        
        public People(Account acc) {
            this.Id = acc.Id;
            this.Name = acc.Name;
            if(acc.Is_Customer__c) {
                if(acc.Type__c == 'Individual') {
                    this.Phone_Number = acc.Home_Number__c;
                    this.Email = acc.Email__c;
                } else if(acc.Type__c == 'Business') {
                    this.Phone_Number = acc.Work_Number__c;
                    this.Email = acc.Work_Email__c;
                }
            } else if(acc.Is_Vendor__c) {
                this.Phone_Number = acc.Work_Number__c;
            }
            
            String billingStreet = (acc.BillingStreet == null ) ? '' : acc.BillingStreet;
	        List<String> bsList = billingStreet.split('\n');
            this.Billing_Address = (bsList.size() > 0) ? bsList[0].replaceAll('\r', ' ') : '';
            this.Billing_Address += (bsList.size() > 1) ? ' ' + bsList[1].replaceAll('\r', ' ') : '';
            
            this.Billing_City = acc.BillingCity;
            this.Billing_State = acc.BillingState;
            this.Id_Number = acc.Id_Number__c;
            
            if(acc.Is_Customer__c) {
                this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Customers');
                //this.Id_Number = acc.Customer_Number__c;
            } else {
                this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Vendors');
                //this.Id_Number = acc.Vendor_Code__c;
            }
            this.Modified = BPUtility.getLastModifiedDateStr(acc);
            this.Owner = (acc.Owner.Name != null) ? acc.Owner.Name : null;
            this.Status = acc.Status__c;
            
            String shippingStreet = (acc.ShippingStreet == null ) ? '' : acc.ShippingStreet;
	        List<String> spList = shippingStreet.split('\n');
            this.Shipping_Address = (spList.size() > 0) ? spList[0].replaceAll('\r', ' ') : '';
            this.Shipping_Address += (spList.size() > 1) ? ' ' + spList[1].replaceAll('\r', ' ') : '';
            
            this.Shipping_City = acc.ShippingCity;
            this.Shipping_State = acc.ShippingState; 
             
            this.Mobile_Number = acc.Mobile__c;
            this.Other_Email = acc.Other_Email__c;
            this.Work_Email = acc.Work_Email__c;
            this.Work_Number = acc.Work_Number__c;
            
            this.Facebook = acc.Facebook__c;
            this.LinkedIn = acc.LinkedIn__c;
            this.Twitter = acc.Twitter__c;
            this.Website = acc.Website;
            this.Sales_Tax = (acc.Sales_Tax__c != null) ? acc.Sales_Tax__r.Name__c : null;
            this.Price_Level = (acc.Price_Level__c != null) ? acc.Price_Level__r.Name__c : null;
            
            this.Open_Orders = acc.Open_Orders__c;
            this.Created = (acc.CreatedDate != null) ?  BPUtility.getFormatedDateTime(acc.CreatedDate) : null;
            this.Parent_Account = '';  
            this.Active = (acc.Active__c) ? 'Active' : 'Inactive';
        }
    }
    
    /**
     * Name: Part
     * Description: Sets the value of the Parts
    **/
    public class Part {
        public Integer Type {get; private set;}
        public String Part_Number {get; private set;}
        public String Description {get; private set;}
        public String Category {get; private set;}
        public Decimal Retail {get; private set;}
        public Decimal Qty_Available {get; private set;}
        public String Modified {get; private set;}
        public String Status {get; private set;}
        public String Vendor {get; private set;}
        public Decimal Cost {get; private set;}
        public String Location {get; private set;}
        public String Id {get; private set;}
        
        public Decimal Qty_In_Stock {get; private set;}
        public Decimal Qty_Committed {get; private set;} 
        public Decimal Qty_On_Order {get; private set;}
        public Decimal MSRP {get; private set;}
        public Decimal Enviro_Fee {get; private set;}
        public Decimal Average_Cost {get; private set;}
        public Decimal Package_Cost {get; private set;}
        public Decimal Package_Qty {get; private set;}
        public String Package_Unit {get; private set;}
        public String Last_Counted {get; private set;}
        public String Last_Sold {get; private set;}
        public String Last_Stocked {get; private set;}
        public Decimal Reorder_At {get; private set;}
        public Decimal Reorder_To {get; private set;}
        public Decimal Order_Lots {get; private set;}
        public String Replaced_By {get; private set;}
        public Decimal Oversold_Qty {get; private set;}
        public Decimal Oversold_Cost {get; private set;}
        public Decimal In_Stock_Cost {get; private set;}
        public String Mfg_Part {get; private set;} // Added by richa 29/11/2016
        public String SKU {get; private set;} // Added by richa 29/11/2016 SKU_Number
        public Boolean Non_Inventory_Part {get; private set;} // Added by richa 29/11/2016
        public String Active {get; private set;}
        public String Tags {get; private set;}
        public Decimal PRD1_Qty {get; private set;}
        public Decimal PRD1_Cost {get; private set;}
        public Decimal PRD2_Qty {get; private set;}
        public Decimal PRD2_Cost {get; private set;}
        public Decimal PRD3_Qty {get; private set;}
        public Decimal PRD3_Cost {get; private set;}
        public Decimal PRD4_Qty {get; private set;}
        public Decimal PRD4_Cost {get; private set;}
        public String Part_Type {get; private set;}
        public Decimal Sale_Price {get; private set;}
        public String Publish_In_Feeds {get; private set;}
        public Decimal Inventory_Qty {get; private set;}
        public String Last_Edited {get; private set;}
        public String Last_Price_Update {get; private set;}
        public String Last_Edited_By {get; private set;}
        public Decimal Inventory_Valuation {get; private set;}
        public Decimal Available_Cost {get; private set;}
        public Decimal Committed_Cost {get; private set;}
        
        public Part(Part__c partRec) {
            this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Parts');
            this.Part_Number = partRec.Part_Number__c;
            this.Description = partRec.Description__c;
            this.Qty_Available = partRec.AvailableParts__c;
            this.Retail = partRec.Retail_Price__c;
            this.Location = LocationManagementService.getLocationsListString(partRec);
            this.Category = partRec.Category__r.Name;
            this.Status = partRec.Status__c;
            this.Modified = BPUtility.getLastModifiedDateStr(partRec);
            this.Vendor = (partRec.Vendor__c != null) ? partRec.Vendor__r.Vendor_Code__c : null;
            this.Cost = (partRec.Last_Cost__c != null) ? partRec.Last_Cost__c : null;
            this.Status = partRec.Status__c;
            this.Id = partRec.Id;
            
            this.Qty_In_Stock = partRec.Qty_In_Stock__c;
            this.Qty_Committed = partRec.Qty_Committed__c;
            this.Qty_On_Order = partRec.Qty_On_Order__c;
            this.MSRP = partRec.MSRP__c;
            this.Enviro_Fee = partRec.Enviro_Fee__c;
            this.Average_Cost = partRec.Average_Cost__c;
            this.Package_Cost =  partRec.Package_Cost__c;
            this.Package_Qty = partRec.Package_Qty__c;
            this.Package_Unit = partRec.Package_Unit__c;
            this.Last_Counted = (partRec.Last_Counted__c != null) ?  BPUtility.getFormatedDateTime(partRec.Last_Counted__c) : null;
            this.Last_Sold = (partRec.Last_Sold__c != null) ?  BPUtility.getFormatedDateTime(partRec.Last_Sold__c) : null;
            this.Last_Stocked = (partRec.Last_Stocked__c != null) ?  BPUtility.getFormatedDateTime(partRec.Last_Stocked__c) : null;
            this.Reorder_At = partRec.Auto_reorder_Min__c;
            this.ReOrder_To = partRec.Auto_reorder_Max__c;
            this.Order_Lots =  partRec.Order_Lots__c;
            this.Replaced_By = (partRec.Superseded_To__c != null) ? partRec.Superseded_To__r.Part_Number__c : null;
            this.Oversold_Qty = (partRec.Oversold_Qty__c != null) ? partRec.Oversold_Qty__c : 0;
            this.Oversold_Cost = (partRec.Oversold_Cost__c != null) ? partRec.Oversold_Cost__c : 0.00;
            this.In_Stock_Cost = (partRec.Total_Cost__c != null) ? partRec.Total_Cost__c : 0.00;
            this.Mfg_Part = partRec.Mfg_Part__c; // Added by richa 29/11/2016
            this.SKU = partRec.SKU_Number__c; // Added by richa 29/11/2016 SKU_Number
            this.Non_Inventory_Part = partRec.Non_Inventory_Part__c; // Added by richa 29/11/2016
            this.Active = (partRec.Active__c) ? 'Active' : 'Inactive';
            this.Publish_In_Feeds = partRec.Publish_In_Feeds__c ? 'Yes' : 'No';
            
            this.PRD1_Qty = (partRec.Part_Aging_Detail__c != null && partRec.Part_Aging_Detail__r.PRD1Qty__c != null) ? partRec.Part_Aging_Detail__r.PRD1Qty__c : 0;
            this.PRD1_Cost = (partRec.Part_Aging_Detail__c != null && partRec.Part_Aging_Detail__r.PRD1Cost__c != null) ? partRec.Part_Aging_Detail__r.PRD1Cost__c : 0;
            this.PRD2_Qty = (partRec.Part_Aging_Detail__c != null && partRec.Part_Aging_Detail__r.PRD2Qty__c != null) ? partRec.Part_Aging_Detail__r.PRD2Qty__c : 0;
            this.PRD2_Cost = (partRec.Part_Aging_Detail__c != null && partRec.Part_Aging_Detail__r.PRD2Cost__c != null) ? partRec.Part_Aging_Detail__r.PRD2Cost__c : 0;
            this.PRD3_Qty = (partRec.Part_Aging_Detail__c != null && partRec.Part_Aging_Detail__r.PRD3Qty__c != null) ? partRec.Part_Aging_Detail__r.PRD3Qty__c : 0;
            this.PRD3_Cost = (partRec.Part_Aging_Detail__c != null && partRec.Part_Aging_Detail__r.PRD3Cost__c != null) ? partRec.Part_Aging_Detail__r.PRD3Cost__c : 0;
            this.PRD4_Qty = (partRec.Part_Aging_Detail__c != null && partRec.Part_Aging_Detail__r.PRD4Qty__c != null) ? partRec.Part_Aging_Detail__r.PRD4Qty__c : 0;
            this.PRD4_Cost = (partRec.Part_Aging_Detail__c != null && partRec.Part_Aging_Detail__r.PRD4Cost__c != null) ? partRec.Part_Aging_Detail__r.PRD4Cost__c : 0;
            
            this.Tags = getTagString(partRec);
            this.Part_Type = (partRec.Part_Type__c != null) ? partRec.Part_Type__c :'Part';
            this.Sale_Price = (partRec.Sale_Price__c != null) ? partRec.Sale_Price__c.setScale(2, RoundingMode.HALF_UP) : 0.00;
            this.Inventory_Qty = partRec.Inventory_Qty__c;
            this.Last_Edited = (partRec.Last_Edited__c != null) ?  BPUtility.getFormatedDateTime(partRec.Last_Edited__c) : null;
            this.Last_Price_Update = (partRec.Last_Price_Update__c != null) ?  BPUtility.getFormatedDateTime(partRec.Last_Price_Update__c) : null;
            this.Last_Edited_By = (partRec.Last_Edited_By__c != null ? partRec.Last_Edited_By__r.Name : null);
            this.Inventory_Valuation = partRec.BP_Inventory_valuation__c;
            this.Committed_Cost = (partRec.Committed_Cost__c != null ? partRec.Committed_Cost__c : 0).setScale(2, RoundingMode.HALF_UP);
            this.Available_Cost = (partRec.Available_Cost__c != null ? partRec.Available_Cost__c : 0).setScale(2, RoundingMode.HALF_UP);
        }
    }
    
    public static String getTagString(Sobject sobj) {
        String tagsNameStr = '';
        if(sobj.get('Assigned_Tag_1__c') != null && String.valueOf(sobj.get('Assigned_Tag_1__c')).length() > 1) {
            tagsNameStr = String.valueOf(sobj.get('Assigned_Tag_1__c')).substring(1, (String.valueOf(sobj.get('Assigned_Tag_1__c'))).length() - 1);
        }
        if(sobj.get('Assigned_Tag_2__c') != null && String.valueOf(sobj.get('Assigned_Tag_2__c')).length() > 1) {
            tagsNameStr += (String.isNotBlank(tagsNameStr)) ? 
                            (';' + String.valueOf(sobj.get('Assigned_Tag_2__c')).substring(1, (String.valueOf(sobj.get('Assigned_Tag_2__c'))).length() - 1)) : 
                            (String.valueOf(sobj.get('Assigned_Tag_2__c')).substring(1, (String.valueOf(sobj.get('Assigned_Tag_2__c'))).length() - 1));
        }
        tagsNameStr = tagsNameStr.replace(';', ', ');
        return tagsNameStr;
    }
    
    /**
     * Name: KitHeader
     * Description:  Sets the value of the Kit
    **/
    public class KitHeader {
        public String Id {get; private set;}
        public String Code {get; private set;}
        public Integer Type {get; private set;}
        public String Description {get; private set;}
        public Decimal Qty_Available {get; private set;}
        public Decimal Price {get; private set;}
        public String Status {get; private set;}
        public String Modified {get; private set;}
        public String Active {get; private set;}
        
        public KitHeader(Kit_Header__c kitHeaderRec) {
            this.Id = kitHeaderRec.Id;
            this.Code = kitHeaderRec.Code__c;
            this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Kits');
            this.Description = kitHeaderRec.Kit_Unique_Name__c;
            this.Price = kitHeaderRec.Fixed_Price__c;
            this.Qty_Available = 1;
            this.Modified = BPUtility.getLastModifiedDateStr(kitHeaderRec);
            this.Status = kitHeaderRec.Status__c;
            this.Active = (kitHeaderRec.Active__c) ? 'Active' : 'Inactive';
        }
    }
    
    
    /**
     * Name: Fee
     * Description: Sets the value of the Kit
    **/
    public class Fee {
        public String Id {get; private set;}
        public String Code {get; private set;}
        public Integer Type {get; private set;}
        public String Description {get; private set;}
        public String Category {get; private set;}
        public Decimal Price {get; private set;}
        public String Status {get; private set;}
        public String Modified {get; private set;}
        public String Active {get; private set;}
        public String Forms_Tags {get; private set;}
        public String Fee_Type {get; private set;}

        public Fee(Fee__c feeRec) {
            this.Id = feeRec.Id;
            this.Code = feeRec.Code__c;
            this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Fees');
            this.Description = feeRec.Fee_Unique_Name__c;
            this.Category = (feeRec.Category__c != null && feeRec.Category__r.Name != null) ? feeRec.Category__r.Name : null;
            this.Price = feeRec.Price__c;
            this.Status = feeRec.Status__c;
            this.Modified = BPUtility.getLastModifiedDateStr(feeRec);
            this.Active = (feeRec.Active__c) ? 'Active' : 'Inactive';
            this.Forms_Tags = getTagString(feeRec);
            this.Fee_Type = feeRec.Type__c;
        }
    }
    
    /**
     * Name: LabourCode
     * Description: Sets the value of LabourCode 
    **/
    public class LabourCode {
        
        public String Id {get; private set;}
        public String Code {get; private set;}
        public Integer Type {get; private set;}
        public String Description {get; private set;}
        public String Category {get; private set;}
        public Decimal Price {get; private set;}
        public String Status {get; private set;}
        public String Modified {get; private set;}
        public String Hours {get; private set;}
        public String Active {get; private set;}
        public String Forms_Tags {get; private set;}
        
        public LabourCode(Labour_Code__c labourRec) {
            this.Id = labourRec.Id;
            this.Code = labourRec.Code__c;
            this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Labor Codes');
            this.Description = labourRec.Description__c;
            this.Category = (labourRec.Category__c != null && labourRec.Category__r.Name != null) ? labourRec.Category__r.Name : null;
            this.Price = labourRec.Rate__c;
            this.Status = labourRec.Status__c;
            this.Modified = BPUtility.getLastModifiedDateStr(labourRec);
            this.Hours = (labourRec.Hours__c != null) ? String.valueOf(labourRec.Hours__c) : '0';
            this.Active = (labourRec.Active__c) ? 'Active' : 'Inactive';
            this.Forms_Tags = getTagString(labourRec);
        }
    }
    
    
    public class VendorProduct {
        public String Id {get; private set;}
        public String Code {get; private set;}
        public Integer Type {get; private set;}
        public String Category {get; private set;}
        public Decimal Price {get; private set;}
        public String Description {get; private set;}
        public String Status {get; private set;}
        public String Modified {get; private set;}
        public String Vendor {get; private set;}
        public Decimal Cost {get; private set;}
        public String Active {get; private set;}
        public String Product_Type {get; private set;}
        public String Account_Type {get; private set;}
        public String Cost_Method {get; private set;}
        
        public VendorProduct(Product__c productRec) {
            this.Id = productRec.Vendor__c;
            this.Code = productRec.Code__c;
            if(productRec.Type__c == Constants.SUBLET) {
                this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Sublets');
            } else if(productRec.Type__c == Constants.FINANCING_PRODUCT) {
                this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Financing Product');
            } else if(productRec.Type__c == Constants.DEAL_PRODUCT) {
                this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Deal Product');
            } else if(productRec.Type__c == Constants.WARRANTY_PLAN) {
                this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Warranty Plan');
            }
            
            this.Description = productRec.Description__c;
            this.Price = productRec.Price__c;
            this.Modified = BPUtility.getLastModifiedDateStr(productRec);
            this.Category = (productRec.Category__c != null && productRec.Category__r.Name != null) ? productRec.Category__r.Name : null;
            this.Vendor = (productRec.Vendor__c != null) ? productRec.Vendor__r.Vendor_Code__c : null;
            this.Cost = (productRec.Cost__c != null) ? productRec.Cost__c : null;
            this.Active = (productRec.Status__c == 'Active') ? 'Active' : 'Inactive';
            //this.Status = productRec.Status__c;
            this.Product_Type = productRec.Type__c;
            this.Account_Type = (productRec.Vendor__c != null && productRec.Vendor__r.Vendor_Account_Type__c != null) 
                                ? productRec.Vendor__r.Vendor_Account_Type__r.Name : null;
            this.Cost_Method = productRec.Cost_Method__c;
        }
    }
    
    /**
     * Name: Product
     * Description: Sets the value of Product by filtering out the fields of the entity
    **/
    public class Product {
        public Integer Type {get; private set;}
        public String Code {get; private set;}
        public String Description {get; private set;}
        public String Category {get; private set;}
        public Decimal Price {get; private set;}
        public Decimal Available {get; private set;}
        public String Modified {get; private set;}
        public String Status {get; private set;}
        public String Vendor {get; private set;}
        public Decimal Cost {get; private set;}
        public String Location {get; private set;}
        public String Id {get; private set;}
        public String Active {get; private set;}
        
        public Product(Sobject sobjRec) {
            this.Id = String.valueOf(sobjRec.get('Id'));
            String objectName = ((Id)sobjRec.get('Id')).getSObjectType().getDescribe().getName();
            this.Active = 'Active';
            // If the entity is of part type or kit or labourcode or fee then it will be assigned from here accordingly
            if(objectName == Constants.NAMESPACE + 'Part__c') {
                this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Parts');
                this.Description = (sobjRec.get(Constants.NAMESPACE +'Part_Number__c') != null) ? String.valueOf(sobjRec.get(Constants.NAMESPACE +'Part_Number__c')) : null;
                this.Price = (sobjRec.get(Constants.NAMESPACE +'Retail_Price__c') != null) ? Decimal.valueOf(String.valueOf(sobjRec.get(Constants.NAMESPACE +'Retail_Price__c'))) : null;
                this.Code = (sobjRec.get(Constants.NAMESPACE +'Part_Number__c') != null) ? String.valueOf(sobjRec.get(Constants.NAMESPACE +'Part_Number__c')) : null;
                this.Available = (sobjRec.get(Constants.NAMESPACE +'AvailableParts__c') != null) ? Decimal.valueOf(String.valueOf(sobjRec.get(Constants.NAMESPACE +'AvailableParts__c'))) : null;
                this.Category = (sobjRec.getSobject(Constants.NAMESPACE + 'Category__r') != null && sobjRec.getSobject(Constants.NAMESPACE + 'Category__r').get('Name') != null) ? String.valueOf(sobjRec.getSobject(Constants.NAMESPACE +'Category__r').get('Name')) : null;
                this.Location = (sobjRec.get(Constants.NAMESPACE + 'Location__c') != null) ? String.valueOf(sobjRec.get('Location__c')) : null;
                this.Vendor = (sobjRec.get(Constants.NAMESPACE +'Vendor__c') != null && String.valueOf(sobjRec.getSobject(Constants.NAMESPACE + 'Vendor__r').get(Constants.NAMESPACE +'Vendor_Code__c')) != null) ? String.valueOf(sobjRec.getSobject(Constants.NAMESPACE +'Vendor__r').get(Constants.NAMESPACE +'Vendor_Code__c')) : null;
                this.Cost = (sobjRec.get(Constants.NAMESPACE +'Last_Cost__c') != null) ? Decimal.valueOf(String.valueOf(sobjRec.get(Constants.NAMESPACE + 'Last_Cost__c'))) : null;
                this.Active = Boolean.valueOf(String.valueOf(sobjRec.get('Active__c'))) ? 'Active' : 'Inactive';
                this.Status = String.valueOf(sobjRec.get(Constants.NAMESPACE +'Status__c'));
            } else if(objectName == Constants.NAMESPACE +'Kit_Header__c') {
                this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Kits');
                this.Description = (sobjRec.get(Constants.NAMESPACE +'Kit_Unique_Name__c') != null) ? String.valueOf(sobjRec.get(Constants.NAMESPACE +'Kit_Unique_Name__c')) : null;
                this.Price = (sobjRec.get(Constants.NAMESPACE +'Fixed_Price__c') != null) ? Decimal.valueOf(String.valueOf(sobjRec.get(Constants.NAMESPACE +'Fixed_Price__c'))) : null;
                this.Available = 1;
                this.Code = (sobjRec.get(Constants.NAMESPACE +'Code__c') != null) ? String.valueOf(sobjRec.get(Constants.NAMESPACE +'Code__c')) : null;
                this.Active = Boolean.valueOf(String.valueOf(sobjRec.get('Active__c'))) ? 'Active' : 'Inactive';
            } else if(objectName == Constants.NAMESPACE +'Labour_Code__c') {
                this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Labor Codes');
                this.Description = (sobjRec.get('Description__c') != null) ? String.valueOf(sobjRec.get(Constants.NAMESPACE +'Description__c')) : null;
                this.Category = (sobjRec.getSobject(Constants.NAMESPACE +'Category__r') != null && sobjRec.getSobject(Constants.NAMESPACE +'Category__r').get('Name') != null) ? String.valueOf(sobjRec.getSobject(Constants.NAMESPACE +'Category__r').get('Name')) : null;
                this.Price = (sobjRec.get(Constants.NAMESPACE +'Rate__c') != null) ? Decimal.valueOf(String.valueOf(sobjRec.get(Constants.NAMESPACE +'Rate__c'))) : null;
                this.Code = (sobjRec.get(Constants.NAMESPACE +'Code__c') != null) ? String.valueOf(sobjRec.get(Constants.NAMESPACE +'Code__c')) : null;
                this.Active = Boolean.valueOf(String.valueOf(sobjRec.get('Active__c'))) ? 'Active' : 'Inactive';
            } else if(objectName == Constants.NAMESPACE +'Fee__c') {
                this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Fees');
                this.Description = (sobjRec.get(Constants.NAMESPACE +'Fee_Unique_Name__c') != null) ? String.valueOf(sobjRec.get('Fee_Unique_Name__c')) : null;
                this.Category = (sobjRec.getSobject(Constants.NAMESPACE +'Category__r') != null && sobjRec.getSobject(Constants.NAMESPACE +'Category__r').get('Name') != null) ? String.valueOf(sobjRec.getSobject(Constants.NAMESPACE +'Category__r').get('Name')) : null;
                this.Price = (sobjRec.get(Constants.NAMESPACE +'Price__c') != null) ? Decimal.valueOf(String.valueOf(sobjRec.get(Constants.NAMESPACE +'Price__c'))) : null;
                this.Code = (sobjRec.get(Constants.NAMESPACE +'Code__c') != null) ? String.valueOf(sobjRec.get(Constants.NAMESPACE +'Code__c')) : null;
                this.Active = Boolean.valueOf(String.valueOf(sobjRec.get('Active__c'))) ? 'Active' : 'Inactive';
            } else if(objectName == Constants.NAMESPACE +'Product__c') {
                this.Id = sobjRec.get(Constants.NAMESPACE + 'Vendor__c') != null ? String.valueOf(sobjRec.get(Constants.NAMESPACE + 'Vendor__c')) : null;
                String productType = (sobjRec.get(Constants.NAMESPACE +'Type__c') != null) ? String.valueOf(sobjRec.get(Constants.NAMESPACE +'Type__c')) : '';
                if(productType == Constants.SUBLET) {
                    this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Sublets');
                } else if(productType == Constants.FINANCING_PRODUCT) {
                    this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Financing Product');
                } else if(productType == Constants.DEAL_PRODUCT) {
                    this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Deal Product');
                } else if(productType == Constants.WARRANTY_PLAN) {
                    this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Warranty Plan');
                }
                this.Description = (sobjRec.get(Constants.NAMESPACE +'Description__c') != null) ? String.valueOf(sobjRec.get(Constants.NAMESPACE +'Description__c')) : null;
                this.Category = (sobjRec.getSobject(Constants.NAMESPACE +'Category__r') != null && sobjRec.getSobject(Constants.NAMESPACE +'Category__r').get('Name') != null) ? String.valueOf(sobjRec.getSobject(Constants.NAMESPACE +'Category__r').get('Name')) : null;
                this.Price = (sobjRec.get(Constants.NAMESPACE +'Price__c') != null) ? Decimal.valueOf(String.valueOf(sobjRec.get(Constants.NAMESPACE +'Price__c'))) : null;
                this.Code = (sobjRec.get(Constants.NAMESPACE +'Code__c') != null) ? String.valueOf(sobjRec.get(Constants.NAMESPACE +'Code__c')) : null;
                this.Vendor = (sobjRec.get(Constants.NAMESPACE +'Vendor__c') != null && String.valueOf(sobjRec.getSobject(Constants.NAMESPACE +'Vendor__r').get(Constants.NAMESPACE +'Vendor_Code__c')) != null) ? String.valueOf(sobjRec.getSobject(Constants.NAMESPACE +'Vendor__r').get(Constants.NAMESPACE +'Vendor_Code__c')) : null;
                this.Cost = (sobjRec.get(Constants.NAMESPACE +'Cost__c') != null) ? Decimal.valueOf(String.valueOf(sobjRec.get(Constants.NAMESPACE +'Cost__c'))) : null;
                this.Active = (String.valueOf(sobjRec.get('Status__c')) == 'Active') ? 'Active' : 'Inactive';
            } else if(objectName == Constants.NAMESPACE +'Customer_Owned_Unit__c') {
                this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Inventory Unit');
                //this.Description = (sobjRec.get(Constants.NAMESPACE +'Description__c') != null) ? String.valueOf(sobjRec.get(Constants.NAMESPACE +'Description__c')) : null;
                this.Category = (sobjRec.getSobject(Constants.NAMESPACE +'Category__r') != null && sobjRec.getSobject(Constants.NAMESPACE +'Category__r').get('Name') != null) ? String.valueOf(sobjRec.getSobject(Constants.NAMESPACE +'Category__r').get('Name')) : null;
                this.Code = (sobjRec.get(Constants.NAMESPACE +'Stock_Id__c') != null) ? String.valueOf(sobjRec.get(Constants.NAMESPACE +'Stock_Id__c')) : null;
                this.Price = (sobjRec.get(Constants.NAMESPACE +'Total_Price__c') != null) ? Decimal.valueOf(String.valueOf(sobjRec.get(Constants.NAMESPACE +'Total_Price__c'))) : null;
                this.Cost = (sobjRec.get(Constants.NAMESPACE +'Total_Cost__c') != null) ? Decimal.valueOf(String.valueOf(sobjRec.get(Constants.NAMESPACE +'Total_Cost__c'))) : null;
                //this.Cost = (sobjRec.get(Constants.NAMESPACE +'Cost__c') != null) ? Decimal.valueOf(String.valueOf(sobjRec.get(Constants.NAMESPACE +'Cost__c'))) : null;
                this.Location = (sobjRec.get(Constants.NAMESPACE + 'Location__c') != null) ? String.valueOf(sobjRec.get('Location__c')) : null;
                this.Available = 1;
                this.Status = String.valueOf(sobjRec.get(Constants.NAMESPACE +'Status__c'));
            }
            
            this.Modified = BPUtility.getLastModifiedDateStr(sobjRec);
        }
    }
    
    public class TechnicianHours {
        public Integer Type {get; private set;}
        public String Technician {get; private set;}
        public String Clocked_Date {get; private set;}
        public String Time_In {get; private set;}
        public String Time_Out {get; private set;}
        public String Reference {get; private set;}
        public Decimal Clocked_Hours {get; private set;}
        public Decimal Invoiced_Hours {get; private set;}
        public Decimal WIP_Invoice_Hours {get; private set;}
        public String Efficiency {get; private set;}
        public String Job_Status {get; private set;}
        
        public String Job_Type {get; private set;}
        public String Customer {get; private set;}
        public String Job_Name {get; private set;}
        public String Notes {get; private set;}
        public String Id {get; private set;}
        public Decimal Cost {get; private set;}
        public Decimal Total_Hours;
        public Decimal Paused;
        
        public TechnicianHours(Hours_Logged__c hoursLoggedRec) {
            this.Id  = hoursLoggedRec.Id;
            this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Technician Hours');
            this.Technician = hoursLoggedRec.Technician__r.Technician_Name__c;
            
            this.Clocked_Date = '';
            if(hoursLoggedRec.Start_Date_Time__c != null) {
                Date clockedDate = date.newinstance(hoursLoggedRec.Start_Date_Time__c.year(), hoursLoggedRec.Start_Date_Time__c.month(), hoursLoggedRec.Start_Date_Time__c.day());
                this.Clocked_Date = (clockedDate != null) ? BPUtility.getFormatedDateTime(datetime.newInstance(clockedDate.year(), 
                                                                                                         clockedDate.month(), clockedDate.day())) : '';
            }
                    
            this.Time_In = (hoursLoggedRec.Start_Date_Time__c != null) ? hoursLoggedRec.Start_Date_Time__c.format('hh:mm a'): '';
            this.Time_Out = (hoursLoggedRec.End_Date_Time__c != null) ? hoursLoggedRec.End_Date_Time__c.format('hh:mm a') : '';
            this.Reference = (hoursLoggedRec.Service_Order_Header__c != null) ? hoursLoggedRec.Service_Order_Header__r.CO_Header__r.Name : 
                                (hoursLoggedRec.Task__c != null) ? hoursLoggedRec.Task__r.Name__c : '';
            this.Total_Hours = hoursLoggedRec.Total_Hours__c != null ? hoursLoggedRec.Total_Hours__c : 0.00;
            this.Paused = hoursLoggedRec.Paused_Hours__c != null ? hoursLoggedRec.Paused_Hours__c : 0.00;
            this.Clocked_Hours = (hoursLoggedRec.Calculated_Hours__c != null ? hoursLoggedRec.Calculated_Hours__c : 0.00);
            this.Invoiced_Hours = (hoursLoggedRec.Service_Order_Header__c != null) ? hoursLoggedRec.Billed_Hours__c : 0.00;
            this.WIP_Invoice_Hours = (hoursLoggedRec.Service_Order_Header__c != null) ? hoursLoggedRec.WIP_Invoice_Hours__c : 0.00;
            this.Efficiency = (hoursLoggedRec.Service_Order_Header__c != null ? (String.valueOf(hoursLoggedRec.Efficiency__c * 100) + '%') : '');
            this.Job_Status = (hoursLoggedRec.Service_Order_Header__c != null) ? hoursLoggedRec.Service_Order_Header__r.SO_Status__c : '';
            this.Job_Type = (hoursLoggedRec.Service_Order_Header__c != null) ? ((hoursLoggedRec.Service_Order_Header__r.Transaction_Type__c != null) ? 
                            hoursLoggedRec.Service_Order_Header__r.Transaction_Type__r.Code_Label__c : '') : '';
            this.Customer = (hoursLoggedRec.Service_Order_Header__c != null) ? hoursLoggedRec.Service_Order_Header__r.CO_Header__r.Customer_name__c : '';
            this.Job_Name = (hoursLoggedRec.Service_Order_Header__c != null) ? hoursLoggedRec.Service_Order_Header__r.Name__c : '';
            this.Notes = (hoursLoggedRec.Notes__c != null) ? hoursLoggedRec.Notes__c : '';
            this.Cost = (hoursLoggedRec.Total_Cost__c != null) ? hoursLoggedRec.Total_Cost__c : 0.00;
        }
    }
    
    public class PayrollHours {
        public Integer Type {get; private set;}
        public String Employee {get; private set;}
        public String Clocked_Date {get; private set;}
        public String Time_In {get; private set;}
        public String Time_Out {get; private set;}
        public Decimal Clocked_Hours {get; private set;}
        public String Id {get; private set;}
        
        public PayrollHours(Payroll_Time__c payrollHourRec) {
            this.Id  = payrollHourRec.Id;
            this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Payroll Hours');
            this.Employee = payrollHourRec.Technician__r.Technician_Name__c;
            
            this.Clocked_Date = '';
            if(payrollHourRec.Start_Date__c != null) {
                Date clockedDate = date.newinstance(payrollHourRec.Start_Date__c.year(), payrollHourRec.Start_Date__c.month(), payrollHourRec.Start_Date__c.day());
                this.Clocked_Date = (clockedDate != null) ? BPUtility.getFormatedDateTime(datetime.newInstance(clockedDate.year(), 
                                                                                                         clockedDate.month(), clockedDate.day())) : '';
            }
                    
            this.Time_In = (payrollHourRec.Start_Date__c != null) ? payrollHourRec.Start_Date__c.format('hh:mm a'): '';
            this.Time_Out = (payrollHourRec.End_Date__c != null) ? payrollHourRec.End_Date__c.format('hh:mm a') : '';
            this.Clocked_Hours = payrollHourRec.Total_Time__c;
        }
    }
    
    public class PartsToPull {
        public String Id;
        public Integer Type;
        public String Order_Number;
        public String Customer;
        public String Sale_Type;
        public String Item_Description;
        public String Location;
        public Decimal Needed;
        public Decimal In_Stock;
        public Decimal Pulled;
        public Decimal To_Pull;
        
        public PartsToPull(CO_Line_Item__c coliRec) {
            this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Parts to Pull');
            this.Id = coliRec.CO_Header__c;
            this.Order_Number = coliRec.CO_Header__r.Name;
            this.Customer = coliRec.CO_Header__r.Customer_Name__c;
            this.Sale_Type = coliRec.Parts_To_Pull_Sale_Type__c;
            this.Item_Description = coliRec.Item_Code__c + ' - ' + coliRec.Item_Description__c;
            this.Location = LocationManagementService.getLocationsListString(coliRec.Part__r);
            this.Needed = (coliRec.Qty__c != null ? coliRec.Qty__c : 0);
            this.In_Stock = (coliRec.Qty_Committed__c != null ? coliRec.Qty_Committed__c : 0);
            this.Pulled = coliRec.Qty_Pulled_Formula__c;
            this.To_Pull = coliRec.Qty_To_Pull__c;
        }
    }
    
    public class InvoicedItems {
        public Integer Type {get; private set;}
        public String Item {get; private set;}
        public String Description {get; private set;}
        public Decimal Qty_Sold {get; private set;}
        public Decimal Total_Revenue {get; private set;}
        
        public Decimal Total_Profit {get; private set;}
        public String Last_Sale {get; private set;}
        public Decimal Average_Price {get; private set;}
        public Decimal Average_Profit {get; private set;}
        public String Category {get; private set;}
        public String Vendor {get; private set;}
        
        public String Customer {get; private set;}
        public String Invoice {get; private set;}
        public Decimal Price {get; private set;}
        public Decimal Revenue {get; private set;}
        public Decimal Profit {get; private set;}
        public String Id {get; private set;}
        public String Part_Type {get; private set;}
        
        public InvoicedItems(CO_Line_Item__c coliRec) {
            Boolean isTaxIncludingPricing = GeneralConfiguration.getTaxIncludingPricing();
            if(String.isNotBlank(coliRec.Part__c)) {
                this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Parts');
                this.Id = coliRec.Part__c;
                this.Category = (String.isNotBlank(coliRec.Part__r.Category__c)) ? coliRec.Part__r.Category__r.Name : '';
                this.Vendor = (String.isNotBlank(coliRec.Part__r.Vendor__c)) ? coliRec.Part__r.Vendor__r.Name : '';
            } else if(String.isNotBlank(coliRec.Fee__c)) {
                this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Fees');
                this.Id = coliRec.Fee__c;
                this.Category = (String.isNotBlank(coliRec.Fee__r.Category__c)) ? coliRec.Fee__r.Category__r.Name : '';
            }
            this.Item = coliRec.Item_Code__c;
            this.Description = coliRec.Item_Description__c;
            this.Customer = coliRec.CO_Header__r.Customer_Name__c;
            this.Invoice = coliRec.Invoice_Number__r.Invoice_Number__c;
            this.Qty_Sold = coliRec.Qty__c;
            /*this.Price = (isTaxIncludingPricing) ? (coliRec.Price_When_Tax_Included__c != null ? coliRec.Price_When_Tax_Included__c : 0): 
                                                (coliRec.Price__c != null ? coliRec.Price__c : 0);*/
            this.Price = coliRec.Price__c != null ? coliRec.Price__c : 0;
            this.Revenue = (coliRec.Revenue__c).setScale(2, RoundingMode.HALF_UP);
            this.Profit = coliRec.Per_Item_Profit__c;
            this.Part_Type = (coliRec.Part__r.Part_Type__c != null) ? coliRec.Part__r.Part_Type__c :'Part';
        }
        
        public InvoicedItems(Service_Order_Line_Item__c soliRec) {
            Boolean isTaxIncludingPricing = GeneralConfiguration.getTaxIncludingPricing();
            if(String.isNotBlank(soliRec.Part__c)) {
                this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Parts');
                this.Vendor = soliRec.Part__r.Vendor__r.Name;
                this.Id = soliRec.Part__c;
                this.Category = (String.isNotBlank(soliRec.Part__r.Category__c)) ? soliRec.Part__r.Category__r.Name : '';
                this.Vendor = (String.isNotBlank(soliRec.Part__r.Vendor__c)) ? soliRec.Part__r.Vendor__r.Name : '';
            } else if(String.isNotBlank(soliRec.Fee__c)) {
                this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Fees');
                this.Id = soliRec.Fee__c;
                this.Category = (String.isNotBlank(soliRec.Fee__r.Category__c)) ? soliRec.Fee__r.Category__r.Name : '';
            } else if(String.isNotBlank(soliRec.Labour_Code__c)) {
                this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Labor Codes');
                this.Id = soliRec.Labour_Code__c;
                this.Category = (String.isNotBlank(soliRec.Labour_Code__r.Category__c)) ? soliRec.Labour_Code__r.Category__r.Name : '';
            }  else if(String.isNotBlank(soliRec.Sublet__c)) {
                this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Sublets');
                this.Id = soliRec.Sublet__r.Vendor__c;
                this.Category = (String.isNotBlank(soliRec.Sublet__r.Category__c)) ? soliRec.Sublet__r.Category__r.Name : '';
                this.Vendor = (String.isNotBlank(soliRec.Sublet__r.Vendor__c)) ? soliRec.Sublet__r.Vendor__r.Name : '';
            }
            this.Item = soliRec.Item_Code__c;
            this.Description = soliRec.Item_Description__c;
            this.Customer = soliRec.Service_Order_Header__r.CO_Header__r.Customer_Name__c;
            this.Invoice = soliRec.Service_Order_Header__r.Invoice_Number__r.Invoice_Number__c;
            this.Qty_Sold = soliRec.Qty_Needed__c;
            /*this.Price = (isTaxIncludingPricing) ? (soliRec.Price_When_Tax_Included__c != null ? soliRec.Price_When_Tax_Included__c : 0): 
                                                (soliRec.Kit_Price__c != null ? soliRec.Kit_Price__c : 0);*/
            this.Price = soliRec.Kit_Price__c != null ? soliRec.Kit_Price__c : 0;
            this.Revenue = (soliRec.Revenue__c).setScale(2, RoundingMode.HALF_UP);
            this.Profit = soliRec.Per_Item_Profit__c;
            this.Part_Type = (soliRec.Part__r.Part_Type__c != null) ? soliRec.Part__r.Part_Type__c :'Part';
        } 
        
        public InvoicedItems(Option_Fee__c optionAndFeeRec) {
            Boolean isTaxIncludingPricing = GeneralConfiguration.getTaxIncludingPricing();
            if(String.isNotBlank(optionAndFeeRec.Part__c)) {
                this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Parts');
                this.Vendor = optionAndFeeRec.Part__r.Vendor__r.Name;
                this.Id = optionAndFeeRec.Part__c;
                this.Category = (String.isNotBlank(optionAndFeeRec.Part__r.Category__c)) ? optionAndFeeRec.Part__r.Category__r.Name : '';
                this.Vendor = (String.isNotBlank(optionAndFeeRec.Part__r.Vendor__c)) ? optionAndFeeRec.Part__r.Vendor__r.Name : '';
            } else if(String.isNotBlank(optionAndFeeRec.Fee__c)) {
                this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Fees');
                this.Id = optionAndFeeRec.Fee__c;
                this.Category = (String.isNotBlank(optionAndFeeRec.Fee__r.Category__c)) ? optionAndFeeRec.Fee__r.Category__r.Name : '';
            } else if(String.isNotBlank(optionAndFeeRec.Labour_Code__c)) {
                this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Labor Codes');
                this.Id = optionAndFeeRec.Labour_Code__c;
                this.Category = (String.isNotBlank(optionAndFeeRec.Labour_Code__r.Category__c)) ? optionAndFeeRec.Labour_Code__r.Category__r.Name : '';
            } else if(String.isNotBlank(optionAndFeeRec.Product__c)) {
                if(optionAndFeeRec.Product__r.Type__c == 'Sublet') {
                    this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Sublets');
                } else if(optionAndFeeRec.Product__r.Type__c == 'Warranty Plan') {
                    this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Warranty Plan');
                } else {
                    this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Other Product');
                }
                this.Id = optionAndFeeRec.Product__r.Vendor__c;
                this.Category = (String.isNotBlank(optionAndFeeRec.Product__r.Category__c)) ? optionAndFeeRec.Product__r.Category__r.Name : '';
                this.Vendor = (String.isNotBlank(optionAndFeeRec.Product__r.Vendor__c)) ? optionAndFeeRec.Product__r.Vendor__r.Name : '';
            }
            this.Item = optionAndFeeRec.Item_Code__c;
            this.Description = optionAndFeeRec.Item_Description__c;
            this.Customer = optionAndFeeRec.Deal__r.CO_Header__r.Customer_Name__c;
            this.Invoice = optionAndFeeRec.Deal__r.Invoice_Number__r.Invoice_Number__c;
            this.Qty_Sold = optionAndFeeRec.Qty__c;
            /*this.Price = (isTaxIncludingPricing) ? (optionAndFeeRec.Price_When_Tax_Included__c != null ? optionAndFeeRec.Price_When_Tax_Included__c : 0): 
                                                (optionAndFeeRec.Price__c != null ? optionAndFeeRec.Price__c : 0);*/
            this.Price = (optionAndFeeRec.Price__c != null ? optionAndFeeRec.Price__c : 0);                                    
            this.Revenue = (optionAndFeeRec.Revenue__c).setScale(2, RoundingMode.HALF_UP);
            this.Profit = optionAndFeeRec.Per_Item_Profit__c;
            this.Part_Type = (optionAndFeeRec.Part__r.Part_Type__c != null) ? optionAndFeeRec.Part__r.Part_Type__c :'Part';
        }
        
        public InvoicedItems(List<sObject> sObjectList) {
            this.Qty_Sold = 0;
            this.Total_Revenue = 0;
            this.Total_Profit = 0;
            DateTime lastSaleDate;
            DateTime invoiceDate;
            
            for(sObject sobj : sObjectList) {
                Boolean isSOLI = (sobj.getSObjectType().getDescribe().getName() == Constants.NAMESPACE + 'Service_Order_Line_Item__c');
                Boolean isOptionFee = (sobj.getSObjectType().getDescribe().getName() == Constants.NAMESPACE + 'Option_Fee__c');
                Boolean isCOLI = (sobj.getSObjectType().getDescribe().getName() == Constants.NAMESPACE + 'CO_Line_Item__c');
                if(this.Type == null && sobj.get(Constants.NAMESPACE + 'Part__c') != null) {
                    this.Id = String.valueOf(sobj.get(Constants.NAMESPACE + 'Part__c'));
                    this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Parts');
                    this.Item = (sobj.getSobject(Constants.NAMESPACE + 'Part__r').get(Constants.NAMESPACE + 'Part_Number__c') != null) ? 
                                String.valueOf(sobj.getSobject(Constants.NAMESPACE + 'Part__r').get(Constants.NAMESPACE + 'Part_Number__c')) : '';
                    this.Description = (sobj.getSobject(Constants.NAMESPACE + 'Part__r').get(Constants.NAMESPACE + 'Description__c') != null) ? 
                                String.valueOf(sobj.getSobject(Constants.NAMESPACE + 'Part__r').get(Constants.NAMESPACE + 'Description__c')) : '';
                    this.Category = (sobj.getSobject(Constants.NAMESPACE + 'Part__r').get(Constants.NAMESPACE + 'Category__c') != null) && 
                                     (sobj.getSobject(Constants.NAMESPACE + 'Part__r').getSobject(Constants.NAMESPACE + 'Category__r').get('Name') != null) ?
                                     String.valueOf(sobj.getSobject(Constants.NAMESPACE + 'Part__r').getSobject(Constants.NAMESPACE + 'Category__r').get('Name')) : ''; 
                    
                    this.Vendor = (sobj.getSobject(Constants.NAMESPACE + 'Part__r').get(Constants.NAMESPACE + 'Vendor__c') != null) && 
                                     (sobj.getSobject(Constants.NAMESPACE + 'Part__r').getSobject(Constants.NAMESPACE + 'Vendor__r').get('Name') != null) ?
                                     String.valueOf(sobj.getSobject(Constants.NAMESPACE + 'Part__r').getSobject(Constants.NAMESPACE + 'Vendor__r').get('Name')) : ''; 
                                     
                    this.Part_Type = (sobj.getSobject(Constants.NAMESPACE + 'Part__r').get(Constants.NAMESPACE + 'Part_Type__c') != null) ?
                                     String.valueOf(sobj.getSobject(Constants.NAMESPACE + 'Part__r').get(Constants.NAMESPACE + 'Part_Type__c')) : 'Part'; 
                    
                } else if(this.Type == null && sobj.get(Constants.NAMESPACE + 'Fee__c') != null) {
                    this.Id = String.valueOf(sobj.get(Constants.NAMESPACE + 'Fee__c'));
                    this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Fees');
                    this.Item = (sobj.getSobject(Constants.NAMESPACE + 'Fee__r').get(Constants.NAMESPACE + 'Code__c') != null) ? 
                                String.valueOf(sobj.getSobject(Constants.NAMESPACE + 'Fee__r').get(Constants.NAMESPACE + 'Code__c')) : '';
                    this.Description = (sobj.getSobject(Constants.NAMESPACE + 'Fee__r').get(Constants.NAMESPACE + 'Description__c') != null) ? 
                                String.valueOf(sobj.getSobject(Constants.NAMESPACE + 'Fee__r').get(Constants.NAMESPACE + 'Description__c')) : '';
                    this.Category = (sobj.getSobject(Constants.NAMESPACE + 'Fee__r').get(Constants.NAMESPACE + 'Category__c') != null) && 
                                     (sobj.getSobject(Constants.NAMESPACE + 'Fee__r').getSobject(Constants.NAMESPACE + 'Category__r').get('Name') != null) ?
                                     String.valueOf(sobj.getSobject(Constants.NAMESPACE + 'Fee__r').getSobject(Constants.NAMESPACE + 'Category__r').get('Name')) : ''; 
                
                } else if(this.Type == null && (isSOLI || isOptionFee) && sobj.get(Constants.NAMESPACE + 'Labour_Code__c') != null) {
                    this.Id = String.valueOf(sobj.get(Constants.NAMESPACE + 'Labour_Code__c'));
                    this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Labor Codes');
                    this.Item = (sobj.getSobject(Constants.NAMESPACE + 'Labour_Code__r').get(Constants.NAMESPACE + 'Code__c') != null) ? 
                                String.valueOf(sobj.getSobject(Constants.NAMESPACE + 'Labour_Code__r').get(Constants.NAMESPACE + 'Code__c')) : '';
                    this.Description = (sobj.getSobject(Constants.NAMESPACE + 'Labour_Code__r').get(Constants.NAMESPACE + 'Description__c') != null) ? 
                                String.valueOf(sobj.getSobject(Constants.NAMESPACE + 'Labour_Code__r').get(Constants.NAMESPACE + 'Description__c')) : '';
                    this.Category = (sobj.getSobject(Constants.NAMESPACE + 'Labour_Code__r').get(Constants.NAMESPACE + 'Category__c') != null) && 
                                     (sobj.getSobject(Constants.NAMESPACE + 'Labour_Code__r').getSobject(Constants.NAMESPACE + 'Category__r').get('Name') != null) ?
                                     String.valueOf(sobj.getSobject(Constants.NAMESPACE + 'Labour_Code__r').getSobject(Constants.NAMESPACE + 'Category__r').get('Name')) : ''; 
                
                } else if(isSOLI && this.Type == null && sobj.get(Constants.NAMESPACE + 'Sublet__c') != null) {
                    this.Id = String.valueOf(sobj.get(Constants.NAMESPACE + 'Sublet__c'));
                    this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Sublets');
                    this.Item = (sobj.getSobject(Constants.NAMESPACE + 'Sublet__r').get(Constants.NAMESPACE + 'Code__c') != null) ? 
                                String.valueOf(sobj.getSobject(Constants.NAMESPACE + 'Sublet__r').get(Constants.NAMESPACE + 'Code__c')) : '';
                    this.Description = (sobj.getSobject(Constants.NAMESPACE + 'Sublet__r').get(Constants.NAMESPACE + 'Description__c') != null) ? 
                                String.valueOf(sobj.getSobject(Constants.NAMESPACE + 'Sublet__r').get(Constants.NAMESPACE + 'Description__c')) : '';
                    this.Category = (sobj.getSobject(Constants.NAMESPACE + 'Sublet__r').get(Constants.NAMESPACE + 'Category__c') != null) && 
                                     (sobj.getSobject(Constants.NAMESPACE + 'Sublet__r').getSobject(Constants.NAMESPACE + 'Category__r').get('Name') != null) ?
                                     String.valueOf(sobj.getSobject(Constants.NAMESPACE + 'Sublet__r').getSobject(Constants.NAMESPACE + 'Category__r').get('Name')) : ''; 
                    this.Vendor = (sobj.getSobject(Constants.NAMESPACE + 'Sublet__r').get(Constants.NAMESPACE + 'Vendor__c') != null) && 
                                     (sobj.getSobject(Constants.NAMESPACE + 'Sublet__r').getSobject(Constants.NAMESPACE + 'Vendor__r').get('Name') != null) ?
                                     String.valueOf(sobj.getSobject(Constants.NAMESPACE + 'Sublet__r').getSobject(Constants.NAMESPACE + 'Vendor__r').get('Name')) : ''; 
                    
                } else if(isOptionFee && this.Type == null && sobj.get(Constants.NAMESPACE + 'Product__c') != null) {
                    if(sobj.getSobject(Constants.NAMESPACE + 'Product__r').get(Constants.NAMESPACE + 'Type__c') != null) {
                        if(String.valueOf(sobj.getSobject(Constants.NAMESPACE + 'Product__r').get(Constants.NAMESPACE + 'Type__c')) == 'Sublet') {
                            this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Sublets');
                        } else if(String.valueOf(sobj.getSobject(Constants.NAMESPACE + 'Product__r').get(Constants.NAMESPACE + 'Type__c')) == 'Warranty Plan') {
                            this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Warranty Plan');
                        } else {
                            this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Other Product');
                        }
                    }   
                    this.Id = String.valueOf(sobj.get(Constants.NAMESPACE + 'Product__c'));
                    this.Item = (sobj.getSobject(Constants.NAMESPACE + 'Product__r').get(Constants.NAMESPACE + 'Code__c') != null) ? 
                                String.valueOf(sobj.getSobject(Constants.NAMESPACE + 'Product__r').get(Constants.NAMESPACE + 'Code__c')) : '';
                    this.Description = (sobj.getSobject(Constants.NAMESPACE + 'Product__r').get(Constants.NAMESPACE + 'Description__c') != null) ? 
                                String.valueOf(sobj.getSobject(Constants.NAMESPACE + 'Product__r').get(Constants.NAMESPACE + 'Description__c')) : '';
                    this.Category = (sobj.getSobject(Constants.NAMESPACE + 'Product__r').get(Constants.NAMESPACE + 'Category__c') != null) && 
                                     (sobj.getSobject(Constants.NAMESPACE + 'Product__r').getSobject(Constants.NAMESPACE + 'Category__r').get('Name') != null) ?
                                     String.valueOf(sobj.getSobject(Constants.NAMESPACE + 'Product__r').getSobject(Constants.NAMESPACE + 'Category__r').get('Name')) : ''; 
                    
                    this.Vendor = (sobj.getSobject(Constants.NAMESPACE + 'Product__r').get(Constants.NAMESPACE + 'Vendor__c') != null) && 
                                     (sobj.getSobject(Constants.NAMESPACE + 'Product__r').getSobject(Constants.NAMESPACE + 'Vendor__r').get('Name') != null) ?
                                     String.valueOf(sobj.getSobject(Constants.NAMESPACE + 'Product__r').getSobject(Constants.NAMESPACE + 'Vendor__r').get('Name')) : ''; 
                }
                
                Decimal qty, revenue = 0;
                if(isCOLI) {
                    qty = (sobj.get(Constants.NAMESPACE + 'Qty__c') != null) ? 
                                Decimal.valueOf(String.valueOf(sobj.get(Constants.NAMESPACE + 'Qty__c'))) : 0;
                    /*if(sobj.get(Constants.NAMESPACE + 'Price_When_Tax_Included__c') != null) {
                        price = Decimal.valueOf(String.valueOf(sobj.get(Constants.NAMESPACE + 'Price_When_Tax_Included__c')));
                    } else */
                    if(sobj.get(Constants.NAMESPACE + 'Revenue__c') != null) {
                        revenue = Decimal.valueOf(String.valueOf(sobj.get(Constants.NAMESPACE + 'Revenue__c')));
                    }
                    invoiceDate = (sobj.get(Constants.NAMESPACE + 'Invoice_Number__c') != null && 
                                        sobj.getSobject(Constants.NAMESPACE + 'Invoice_Number__r').get(Constants.NAMESPACE + 'Invoice_Date__c') != null) ?
                                        Datetime.valueOf(String.valueOf(sobj.getSobject(Constants.NAMESPACE + 'Invoice_Number__r').get(Constants.NAMESPACE + 'Invoice_Date__c'))) :  
                                        null;
                    
                } else if(isSOLI) {
                    qty = (sobj.get(Constants.NAMESPACE + 'Qty_Needed__c') != null) ? 
                                Decimal.valueOf(String.valueOf(sobj.get(Constants.NAMESPACE + 'Qty_Needed__c'))) : 0;
                    /*if(sobj.get(Constants.NAMESPACE + 'Price_When_Tax_Included__c') != null) {
                        price = Decimal.valueOf(String.valueOf(sobj.get(Constants.NAMESPACE + 'Price_When_Tax_Included__c')));
                    } else */
                    if(sobj.get(Constants.NAMESPACE + 'Revenue__c') != null) {
                        revenue = Decimal.valueOf(String.valueOf(sobj.get(Constants.NAMESPACE + 'Revenue__c')));
                    }
                    
                    invoiceDate = (sobj.get(Constants.NAMESPACE + 'Service_Order_Header__c') != null && 
                                        sobj.getSobject(Constants.NAMESPACE + 'Service_Order_Header__r').get(Constants.NAMESPACE + 'Invoice_Number__c') != null &&
                                        sobj.getSobject(Constants.NAMESPACE + 'Service_Order_Header__r').getSobject(Constants.NAMESPACE + 'Invoice_Number__r').get(Constants.NAMESPACE + 'Invoice_Date__c') != null) ?
                                        Datetime.valueOf(String.valueOf(sobj.getSobject(Constants.NAMESPACE + 'Service_Order_Header__r').getSobject(Constants.NAMESPACE + 'Invoice_Number__r').get(Constants.NAMESPACE + 'Invoice_Date__c'))) :  
                                        null;           
                } else if(isOptionFee) {
                    qty = (sobj.get(Constants.NAMESPACE + 'Qty__c') != null) ? 
                                Decimal.valueOf(String.valueOf(sobj.get(Constants.NAMESPACE + 'Qty__c'))) : 0;
                    /*if(sobj.get(Constants.NAMESPACE + 'Price_When_Tax_Included__c') != null) {
                        price = Decimal.valueOf(String.valueOf(sobj.get(Constants.NAMESPACE + 'Price_When_Tax_Included__c')));
                    } else */
                    if(sobj.get(Constants.NAMESPACE + 'Revenue__c') != null) {
                        revenue = Decimal.valueOf(String.valueOf(sobj.get(Constants.NAMESPACE + 'Revenue__c')));
                    }
                
                    invoiceDate = (sobj.get(Constants.NAMESPACE + 'Deal__c') != null && 
                                        sobj.getSobject(Constants.NAMESPACE + 'Deal__r').get(Constants.NAMESPACE + 'Invoice_Number__c') != null &&
                                        sobj.getSobject(Constants.NAMESPACE + 'Deal__r').getSobject(Constants.NAMESPACE + 'Invoice_Number__r').get(Constants.NAMESPACE + 'Invoice_Date__c') != null) ?
                                        Datetime.valueOf(String.valueOf(sobj.getSobject(Constants.NAMESPACE + 'Deal__r').getSobject(Constants.NAMESPACE + 'Invoice_Number__r').get(Constants.NAMESPACE + 'Invoice_Date__c'))) :  
                                        null;
                }
                
                this.Total_Profit += (sobj.get(Constants.NAMESPACE + 'Per_Item_Profit__c') != null) ? 
                                        Decimal.valueOf(String.valueOf(sobj.get(Constants.NAMESPACE + 'Per_Item_Profit__c'))) : 0;
                this.Qty_Sold += qty;
                this.Total_Revenue += revenue;
                if(lastSaleDate == null || lastSaleDate < invoiceDate) {
                    lastSaleDate = invoiceDate;
                } 
            }
            this.Last_Sale = BPUtility.getFormatedDateTime(lastSaleDate);
            this.Average_Price = (this.Qty_Sold != 0) ? (this.Total_Revenue / ((this.Qty_Sold < 0) ? (-1) * this.Qty_Sold : this.Qty_Sold)) : 0;
            this.Average_Profit = (this.Qty_Sold != 0) ? (this.Total_Profit / ((this.Qty_Sold < 0) ? (-1) * this.Qty_Sold : this.Qty_Sold)) : 0;
        }
    }
    
    public class SpecialOrder {
        public Integer Type {get; private set;}
        public String Id {get; private set;}
        public String Order_Number {get; private set;}
        public String Customer {get; private set;}
        public String Sale_Type {get; private set;}
        public String Created {get; private set;}
        public String Modified {get; private set;}
        public String SO_Status {get; private set;}
        public String Notes {get; private set;}
        
        public SpecialOrder(CO_Section_Detail__c coSectionDetailRec) {
        	this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Parts Order');
        	this.Id = coSectionDetailRec.CO_Header__c;
            this.Order_Number =  coSectionDetailRec.CO_Header__r.Name;
            if(coSectionDetailRec.CO_Header__r.CO_Type__c == Constants.CASH_SALE){
                this.Customer = Constants.CASH_SALE.toUpperCase();
            } else if(coSectionDetailRec.CO_Header__r.CO_Type__c == Constants.INTERNAL_SERVICE){
                this.Customer = Constants.UNIT_INVENTORY;
            } else {
                this.Customer = coSectionDetailRec.CO_Header__r.Customer__r.Name;
            }
            
            this.Sale_Type = 'Part Sale';
            this.Created = (coSectionDetailRec.CO_Header__r.CreatedDate != null) ?  BPUtility.getFormatedDateTime(coSectionDetailRec.CO_Header__r.CreatedDate) : null;
            this.Modified = BPUtility.getLastModifiedDateStr(coSectionDetailRec.CO_Header__r);
            this.SO_Status = coSectionDetailRec.Special_Order_Status__c;
            this.Notes = (coSectionDetailRec.CO_Header__r.Last_Comment__c != null) ? coSectionDetailRec.CO_Header__r.Last_Comment__c : '';
        } 
        
        public SpecialOrder(Service_Order_Header__c soHeaderRec) {
        	this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Service Jobs');
        	this.Id = soHeaderRec.CO_Header__c;
            this.Order_Number =  soHeaderRec.CO_Header__r.Name;
            if(soHeaderRec.CO_Header__r.CO_Type__c == Constants.CASH_SALE){
                this.Customer = Constants.CASH_SALE.toUpperCase();
            } else if(soHeaderRec.CO_Header__r.CO_Type__c == Constants.INTERNAL_SERVICE){
                this.Customer = Constants.UNIT_INVENTORY;
            } else {
                this.Customer = soHeaderRec.CO_Header__r.Customer__r.Name;
            }
            
            this.Sale_Type = 'Service';
            this.Created = (soHeaderRec.CO_Header__r.CreatedDate != null) ?  BPUtility.getFormatedDateTime(soHeaderRec.CO_Header__r.CreatedDate) : null;
            this.Modified = BPUtility.getLastModifiedDateStr(soHeaderRec.CO_Header__r);
            this.SO_Status = soHeaderRec.Special_Order_Status__c;
            this.Notes = (soHeaderRec.CO_Header__r.Last_Comment__c != null) ? soHeaderRec.CO_Header__r.Last_Comment__c : '';
        }
    }
    
    /**
     * Name: CustomerOrders
     * Description:  Sets the value of the customerOrder
    **/
    public class CustomerOrders {
        public Integer Type {get; private set;}
        public String Order_Number {get; private set;}
        public String Customer_Name {get; private set;}
        public String Status {get; private set;}
        public Decimal Total {get; private set;}
        public Decimal Deal_Total {get; private set;}
        public Decimal Balance_Due {get; private set;}
        public String Owner {get; private set;}
        public String Created {get; private set;}
        public String Modified {get; private set;}
        public String Notes {get; private set;}
        
        public Decimal Deposits {get; private set;}
        public Decimal Invoiced {get; private set;}
        public Decimal Uninvoiced {get; private set;}
        public String Id {get; private set;}
        public String Account_Type {get; private set;}
        
        public String First_Name;
		public String Last_Name;
		public String Address;
        public String City;
        public String State;
        public String Postal;
        public String Phone;
        public String Mobile;
        public String Email;
        public String Other_Email;
        public String Salesperson;
        
        public CustomerOrders(CO_Header__c coHeaderRec) {
            this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Customer Orders');
            this.Order_Number =  coHeaderRec.Name;
            if(coHeaderRec.CO_Type__c == Constants.CASH_SALE){
                this.Customer_Name = Constants.CASH_SALE.toUpperCase();
            } else if(coHeaderRec.CO_Type__c == Constants.INTERNAL_SERVICE){
                this.Customer_Name = Constants.UNIT_INVENTORY;
            } else {
                this.Customer_Name = coHeaderRec.Customer__r.Name;
            }
            
            this.Status = coHeaderRec.Status__c;
            //START: Modified by nidhi
            //this.Total = (coHeaderRec.Total_Order_Value__c != null) ? coHeaderRec.Total_Order_Value__c : 0;
            this.Deal_Total = (coHeaderRec.Deal_Total__c != null) ? coHeaderRec.Deal_Total__c : 0;
            this.Total = ((coHeaderRec.Order_Total__c != null) ? coHeaderRec.Order_Total__c : 0);
            //END: Modified by nidhi
            this.Balance_Due = coHeaderRec.Total_Balance_Due__c;
            this.Owner = coHeaderRec.Owner__r.Name;
            this.Created = (coHeaderRec.CreatedDate != null) ?  BPUtility.getFormatedDateTime(coHeaderRec.CreatedDate) : null;
            this.Modified = BPUtility.getLastModifiedDateStr(coHeaderRec);
            this.Notes = (coHeaderRec.Last_Comment__c != null) ? coHeaderRec.Last_Comment__c : '';
            this.Id = coHeaderRec.Id;
            this.Deposits = (coHeaderRec.Total_Deposit_And_Payment__c != null) ? coHeaderRec.Total_Deposit_And_Payment__c : 0;
            this.Invoiced = (coHeaderRec.Invoiced_Amount__c != null) ? coHeaderRec.Invoiced_Amount__c : 0;
            this.Uninvoiced = (coHeaderRec.Uninvoiced_Amount__c != null) ? coHeaderRec.Uninvoiced_Amount__c : 0;
            this.Account_Type = (coHeaderRec.Account_Type__c != null) ? coHeaderRec.Account_Type__r.Name : '';
            //this.Balance_Due = coHeaderRec.Total_Balance_Due__c;
            
            this.First_Name = coHeaderRec.Customer__r.FirstName__c;
            this.Last_Name = coHeaderRec.Customer__r.LastName__c;
            
            String billingStreet = (coHeaderRec.Customer__r.BillingStreet == null ) ? '' : coHeaderRec.Customer__r.BillingStreet;
	        List<String> bsList = billingStreet.split('\n');
            this.Address = (bsList.size() > 0) ? bsList[0].replaceAll('\r', ' ') : '';
            this.Address += (bsList.size() > 1) ? ' ' + bsList[1].replaceAll('\r', ' ') : '';
            
            this.City = coHeaderRec.Customer__r.BillingCity;
            this.State = coHeaderRec.Customer__r.BillingState;
            this.Postal = coHeaderRec.Customer__r.BillingPostalCode;
            
            if(coHeaderRec.Customer__r.Type__c == 'Individual') {
                this.Phone = coHeaderRec.Customer__r.Formatted_Home_Number__c;
                this.Email = coHeaderRec.Customer__r.Email__c;
            } else if(coHeaderRec.Customer__r.Type__c == 'Business') {
                this.Phone = coHeaderRec.Customer__r.Formatted_Work_Number__c;
                this.Email = coHeaderRec.Customer__r.Work_Email__c;
            }
            this.Mobile = coHeaderRec.Customer__r.Formatted_Mobile_Number__c;
            this.Other_Email = coHeaderRec.Customer__r.Other_Email__c;
            this.Salesperson = String.isNotBlank(coHeaderRec.CO_Salesperson_Names__c) ? coHeaderRec.CO_Salesperson_Names__c : 'Unassigned'; 
        }
    }
    
    public class PartsOrder {
        public Integer Type {get; private set;}
        public String Order_Number {get; private set;}
        public String Customer {get; private set;}
        public String Sale_Type {get; private set;}
        public Decimal Total {get; private set;}
        public String Status {get; private set;}
        public String SO_Status {get; private set;}
        public Decimal Deposits {get; private set;}
        public Decimal Invoiced {get; private set;}
        public String Modified {get; private set;}
        public Decimal Parts {get; private set;}
        public Decimal Fees {get; private set;}
        public Decimal Sales_Tax {get; private set;}
        public Decimal Parts_Profit{get; private set;}
        public String Id {get; private set;}
        
        public String First_Name;
        public String Last_Name;
        public String Address;
        public String City;
        public String State;
        public String Postal;
        public String Phone;
        public String Mobile;
        public String Email;
        public String Other_Email;
        public String Salesperson;
        
        public PartsOrder(CO_Header__c coHeaderRec) {
            this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Parts Order');
            this.Order_Number =  coHeaderRec.Name;
            this.Customer = coHeaderRec.Customer_Name__c;
            this.Total = ((coHeaderRec.Parts_And_Accessories_Total__c != null) ? coHeaderRec.Parts_And_Accessories_Total__c : 0);
            this.Status = (coHeaderRec.Merchandise_Status__c != null) ? coHeaderRec.Merchandise_Status__c : 'Active';
            
            if(coHeaderRec.Order_Status__c != 'Quote') {
                this.Sale_Type = coHeaderRec.Transaction_Type__r.Code_Label__c;
            	this.SO_Status = (coHeaderRec.CO_Section_Details__r.size() > 0 && coHeaderRec.CO_Section_Details__r[0].Special_Order_Status__c != null) ? 
        				coHeaderRec.CO_Section_Details__r[0].Special_Order_Status__c : 'None';
            } else {
            	this.SO_Status = '';
                this.Sale_Type = coHeaderRec.Order_Status__c;
            }
            
            this.Modified = BPUtility.getLastModifiedDateStr(coHeaderRec);
            this.Deposits = (coHeaderRec.Total_Deposit_And_Payment__c != null) ? coHeaderRec.Total_Deposit_And_Payment__c : 0;
            this.Invoiced = (coHeaderRec.Parts_And_Accessories_Invoiced_Total__c != null) ? coHeaderRec.Parts_And_Accessories_Invoiced_Total__c : 0;
            this.Parts = (coHeaderRec.Merchandise_Pre_Tax_Part_Total__c  != null ? coHeaderRec.Merchandise_Pre_Tax_Part_Total__c : 0);
            this.Fees = (coHeaderRec.Merchandise_Pre_Tax_Fee_Total__c != null ? coHeaderRec.Merchandise_Pre_Tax_Fee_Total__c : 0);
            this.Sales_Tax = (coHeaderRec.Parts_And_Accessories_Tax_Amount__c != null ? coHeaderRec.Parts_And_Accessories_Tax_Amount__c : 0);
            this.Parts_Profit = (coHeaderRec.Merchandise_Profit__c != null ? coHeaderRec.Merchandise_Profit__c : 0);
            this.Id = coHeaderRec.Id;
            
            this.First_Name = coHeaderRec.Customer__r.FirstName__c;
            this.Last_Name = coHeaderRec.Customer__r.LastName__c;
            String billingStreet = (coHeaderRec.Customer__r.BillingStreet == null ) ? '' : coHeaderRec.Customer__r.BillingStreet;
	        List<String> bsList = billingStreet.split('\n');
            this.Address = (bsList.size() > 0) ? bsList[0].replaceAll('\r', ' ') : '';
            this.Address += (bsList.size() > 1) ? ' ' + bsList[1].replaceAll('\r', ' ') : '';
            
            this.City = coHeaderRec.Customer__r.BillingCity;
            this.State = coHeaderRec.Customer__r.BillingState;
            this.Postal = coHeaderRec.Customer__r.BillingPostalCode;
            
            if(coHeaderRec.Customer__r.Type__c == 'Individual') {
                this.Phone = coHeaderRec.Customer__r.Formatted_Home_Number__c;
                this.Email = coHeaderRec.Customer__r.Email__c;
            } else if(coHeaderRec.Customer__r.Type__c == 'Business') {
                this.Phone = coHeaderRec.Customer__r.Formatted_Work_Number__c;
                this.Email = coHeaderRec.Customer__r.Work_Email__c;
            }
            this.Mobile = coHeaderRec.Customer__r.Formatted_Mobile_Number__c;
            this.Other_Email = coHeaderRec.Customer__r.Other_Email__c;
            this.Salesperson = String.isNotBlank(coHeaderRec.Salesperson_Names__c) ? coHeaderRec.Salesperson_Names__c : 'Unassigned';
        }
    }
    
    /**
     * Name: CustomerInvoice
     * Description: Sets the Value of the Customer Invoice
    **/ 
    
    public class CustomerInvoice {
        public Integer Type {get; private set;}
        public String Invoice_Number {get; private set;}
        public String Customer_Name {get; private set;}
        public String Status {get; private set;}
        public Decimal Total {get; private set;}
        public String Order_Number {get; private set;}
        public String Owner {get; private set;}
        public String Modified {get; private set;}
        public String Created {get; private set;}
        public String Id {get; private set;}
        public Decimal Part_Total{get; private set;}
        public Decimal Fee_Total{get; private set;}
        public Decimal Lien_Payout{get; private set;}
        public Decimal Labor_Total{get; private set;}
        public Decimal Unit_Total{get; private set;}
        public Decimal Warranty_Product_Total{get; private set;}
        public Decimal Other_Product_Total{get; private set;}
        public Decimal Trade_In_Total{get; private set;}
        public Decimal Sublet_Total{get; private set;}
        public Decimal SalesTax_Total{get; private set;}
        public String Invoice_Date{get; private set;}
        public Decimal Invoice_Profit{get; private set;}
        public Decimal Deal_Profit{get; private set;}
        public Decimal Stamp_Duty_Total{get; private set;}
        public Decimal Taxable_Total{get; private set;}
        public Decimal Non_Taxable_Total{get; private set;} 
        public Decimal Sales_Commission{get; private set;}
        public String Salesperson {get; private set;}
        public String Account_Type {get; private set;}
        public Decimal Finance_Commission;
        public String AR_Balance;
        
        public CustomerInvoice(CO_Invoice_Header__c coInvoiceHeader) {
            this.Id = coInvoiceHeader.CO_Header__c;
            this.Invoice_Number = coInvoiceHeader.Invoice_Number__c;
            this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Customer Invoices');
            if(coInvoiceHeader.CO_Header__r.CO_Type__c == Constants.CASH_SALE){
                this.Customer_Name = Constants.CASH_SALE.toUpperCase();
            } else if(coInvoiceHeader.CO_Header__r.CO_Type__c == Constants.INTERNAL_SERVICE){
                this.Customer_Name = Constants.UNIT_INVENTORY;
            } else {
                this.Customer_Name = coInvoiceHeader.CO_Header__r.Customer__r.Name;
            }
            this.Account_Type = (coInvoiceHeader.CO_Header__c != null && coInvoiceHeader.CO_Header__r.Account_Type__c != null) 
                                ? coInvoiceHeader.CO_Header__r.Account_Type__r.Name : '';
            this.Total = coInvoiceHeader.Total__c;
            this.Status = coInvoiceHeader.Status__c;
            this.Order_Number = coInvoiceHeader.CO_Header__r.Name;
            this.Owner = coInvoiceHeader.CO_Header__r.Owner__r.Name; 
            //this.Created = (coInvoiceHeader.CreatedDate != null) ?  BPUtility.getFormatedDateTime(coInvoiceHeader.CreatedDate) : null;
            this.Created = (coInvoiceHeader.Closed_Invoice_Date__c != null) ?  BPUtility.getFormatedDateTime(coInvoiceHeader.Closed_Invoice_Date__c) : null;
            this.Modified = BPUtility.getLastModifiedDateStr(coInvoiceHeader);
            //this.Balance_Due = coInvoiceHeader.CO_Header__r.Total_Balance_Due__c;
            this.Part_Total = coInvoiceHeader.Pre_Tax_Part_Total__c;
            this.Fee_Total = coInvoiceHeader.Total_Fee_With_Shop_Supplies__c;
            this.Lien_Payout = coInvoiceHeader.Lien_Payout_Total__c;
            this.Labor_Total = coInvoiceHeader.Pre_Tax_Labour_Total__c;
            this.Sublet_Total = coInvoiceHeader.Pre_Tax_Sublet_Total__c;
            this.Unit_Total = coInvoiceHeader.Pre_Tax_Unit_Total__c;
            if(coInvoiceHeader.Is_Deal_Invoiced__c) {
                this.Unit_Total += (this.Part_Total + this.Labor_Total + this.Sublet_Total);
                this.Part_Total =  this.Labor_Total = this.Sublet_Total = 0;
            }
            
            this.Warranty_Product_Total = (coInvoiceHeader.Pre_Tax_Warranty_Product_Total__c != null) ? coInvoiceHeader.Pre_Tax_Warranty_Product_Total__c : 0;
            this.Other_Product_Total = (coInvoiceHeader.Pre_Tax_Other_Product_Total__c != null) ? coInvoiceHeader.Pre_Tax_Other_Product_Total__c : 0;
            this.Trade_In_Total = (coInvoiceHeader.Pre_Tax_Trade_In_Total__c != null) ? coInvoiceHeader.Pre_Tax_Trade_In_Total__c : 0;
            
            this.SalesTax_Total = coInvoiceHeader.SalesTax_Total__c;
            this.Invoice_Date = (coInvoiceHeader.Invoice_Date__c != null) ?  BPUtility.getFormatedDateTime(coInvoiceHeader.Invoice_Date__c) : null;
            this.Invoice_Profit = coInvoiceHeader.Invoice_Profitability__c;
            this.Deal_Profit = (coInvoiceHeader.Deal_Profitability__c != null) ? coInvoiceHeader.Deal_Profitability__c : 0;
            this.Stamp_Duty_Total = (coInvoiceHeader.Stamp_Duty_Total__c != null) ? coInvoiceHeader.Stamp_Duty_Total__c : 0;
            this.Taxable_Total = (coInvoiceHeader.Taxable_Total__c != null) ? coInvoiceHeader.Taxable_Total__c : 0;
            this.Non_Taxable_Total = (coInvoiceHeader.Non_Taxable_Total__c != null) ? coInvoiceHeader.Non_Taxable_Total__c : 0;
            this.Sales_Commission = (coInvoiceHeader.Deal_Commission__c != null) ? coInvoiceHeader.Deal_Commission__c : 0;
            this.Salesperson = String.isNotBlank(coInvoiceHeader.Salesperson__c) ? coInvoiceHeader.Salesperson__c : 'Unassigned';
            this.Finance_Commission = (coInvoiceHeader.Total_Finance_Commission__c != null) ? coInvoiceHeader.Total_Finance_Commission__c : 0;
            this.AR_Balance = BPUtility.getFormattedCurrencyValue(coInvoiceHeader.Calculated_AR_Balance__c);
        }
    }
    
    /**
     * Name: CustomerPayment
     * Description: Sets the Value of the Customer Invoice
    **/ 
    
    public class CustomerPayment {
        public Integer Type {get; private set;}
        public String Payment_Number {get; private set;}
        public String Customer_Name {get; private set;}
        public Decimal Total {get; private set;}
        public String Status {get; private set;}
        public String Order_Number {get; private set;}
        public String Owner {get; private set;}
        public String Modified {get; private set;}
        public String Created {get; private set;}
        public String Payment_Method {get; private set;}
        public String Reverse_Payment_Id {get; private set;}
        public String Id {get; private set;}
        //Dinesh Kumar 07/10/2015
        public String Invoice_Number {get; private set;}
        public String Cash_Drawer {get; private set;}
        public String Account_Type {get; private set;}
        public String Payment_Date {get; private set;}
        public String Reference_Number {get; private set;}
        
        public CustomerPayment(CO_Invoice_Payment__c coPaymentRec) {
            this.Id = (coPaymentRec.CO_Invoice_Header__c != null) ? coPaymentRec.CO_Invoice_Header__r.CO_Header__c : null;
            this.Payment_Number = coPaymentRec.Name;
            this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Customer Payments');
            if(coPaymentRec.CO_Invoice_Header__c != null) {
                if(coPaymentRec.Customer_Name__c != null) {
                    this.Customer_Name = coPaymentRec.Customer_Name__r.Name;
                } else if(coPaymentRec.CO_Invoice_Header__r.CO_Header__r.CO_Type__c == Constants.INTERNAL_SERVICE){
                    this.Customer_Name = Constants.UNIT_INVENTORY;
                } else {
                    this.Customer_Name = Constants.CASH_SALE.toUpperCase();
                }
            }
            this.Total = coPaymentRec.Amount__c;
            this.Status = (coPaymentRec.CO_Invoice_Header__c != null) ? coPaymentRec.CO_Invoice_Header__r.Status__c : null;
            this.Order_Number = (coPaymentRec.CO_Invoice_Header__c != null) ? coPaymentRec.CO_Invoice_Header__r.CO_Header__r.Name : null;
            this.Owner = (coPaymentRec.CO_Invoice_Header__c != null && coPaymentRec.CO_Invoice_Header__r.CO_Header__r.Owner__c != null) ? coPaymentRec.CO_Invoice_Header__r.CO_Header__r.Owner__r.Name : null;
            this.Created =  BPUtility.getFormatedDateTime(coPaymentRec.CreatedDate);
            this.Modified = BPUtility.getLastModifiedDateStr(coPaymentRec);
            this.Payment_Method = coPaymentRec.Payment_Method__c;
            this.Reverse_Payment_Id = (coPaymentRec.Reverse_Payment_From__c != null) ? coPaymentRec.Reverse_Payment_From__r.Name : null;
            //Dinesh Kumar 07/10/2015
            this.Invoice_Number = (coPaymentRec.CO_Invoice_Header__c != null) ? coPaymentRec.CO_Invoice_Header__r.Invoice_Number__c : null;
            this.Account_Type = (coPaymentRec.CO_Invoice_Header__c != null && coPaymentRec.CO_Invoice_Header__r.CO_Header__c != null 
                                    && coPaymentRec.CO_Invoice_Header__r.CO_Header__r.Account_Type__c != null) 
                                    ? coPaymentRec.CO_Invoice_Header__r.CO_Header__r.Account_Type__r.Name : null;
            
			this.Cash_Drawer = (coPaymentRec.Cash_Drawer__c != null) ? coPaymentRec.Cash_Drawer__r.Name : '';
			this.Payment_Date = (coPaymentRec.Payment_Date__c != null) ? coPaymentRec.Payment_Date__c.format() : system.today().format();
            this.Reference_Number = coPaymentRec.Reference__c != null ? coPaymentRec.Reference__c : '';
        }
        
        public CustomerPayment(CO_Deposit__c coDepositRec) {
            this.Id = (coDepositRec.CO_Header__c != null) ? coDepositRec.CO_Header__c : null;
            this.Payment_Number = coDepositRec.Name;
            this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Customer Payments');
            if(coDepositRec.CO_Header__c != null) {
                if(coDepositRec.Customer_Name__c != null){
                    this.Customer_Name = coDepositRec.Customer_Name__r.Name;
                } else if(coDepositRec.CO_Header__r.CO_Type__c == Constants.INTERNAL_SERVICE){
                    this.Customer_Name = Constants.UNIT_INVENTORY;
                } else {
                    this.Customer_Name = Constants.CASH_SALE.toUpperCase();
                }
            }
            this.Total = coDepositRec.Amount__c;
            this.Status = (coDepositRec.CO_Invoice_Header__c != null) ? coDepositRec.CO_Invoice_Header__r.Status__c : null;
            this.Order_Number = (coDepositRec.CO_Header__c != null) ? coDepositRec.CO_Header__r.Name : null;
            this.Owner = (coDepositRec.CO_Header__c != null && coDepositRec.CO_Header__r.Owner__c != null) ? coDepositRec.CO_Header__r.Owner__r.Name : null;
            this.Created =  BPUtility.getFormatedDateTime(coDepositRec.CreatedDate);
            this.Modified = BPUtility.getLastModifiedDateStr(coDepositRec);
            this.Payment_Method = coDepositRec.Payment_Method__c;
            this.Cash_Drawer = (coDepositRec.Cash_Drawer__c != null) ? coDepositRec.Cash_Drawer__r.Name : '';
            //this.Reverse_Payment_Id = (coPaymentRec.Reverse_Payment_From__c != null) ? coPaymentRec.Reverse_Payment_From__r.Name : null;
            this.Payment_Date = (coDepositRec.Payment_Date__c != null) ? coDepositRec.Payment_Date__c.format() : system.today().format();
            this.Reference_Number = coDepositRec.Reference__c != null ? coDepositRec.Reference__c : '';
        }
        
        public CustomerPayment(Payment_on_Account__c paymentOnAccountRec) {
            this.Id = (paymentOnAccountRec.Customer__c != null) ? paymentOnAccountRec.Customer__c : null;
            this.Payment_Number = paymentOnAccountRec.Name;
            this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('AR Payments');
            if(paymentOnAccountRec.Customer__c != null) {
            	this.Customer_Name = paymentOnAccountRec.Customer__r.Name;
            }
            this.Total = paymentOnAccountRec.Total_Amount__c;
            this.Status = '';
            this.Order_Number = 'Paid on account';
            this.Owner = (paymentOnAccountRec.Customer__r.Owner.Name != null) ? paymentOnAccountRec.Customer__r.Owner.Name : null;
            this.Created =  BPUtility.getFormatedDateTime(paymentOnAccountRec.CreatedDate);
            this.Modified = BPUtility.getLastModifiedDateStr(paymentOnAccountRec);
            this.Payment_Method = paymentOnAccountRec.Payment_Method__c;
            this.Cash_Drawer = (paymentOnAccountRec.Cash_Drawer__c != null) ? paymentOnAccountRec.Cash_Drawer__r.Name : '';
            this.Payment_Date = (paymentOnAccountRec.Payment_Date__c != null) ? paymentOnAccountRec.Payment_Date__c.format() : system.today().format();
        	this.Account_Type = (paymentOnAccountRec.Customer__r.Account_Type__r.Name != null) ? paymentOnAccountRec.Customer__r.Account_Type__r.Name : null;
            this.Reference_Number = paymentOnAccountRec.Reference__c != null ? paymentOnAccountRec.Reference__c : '';
        }
    }
    
    
    /**
     * Name: CustomerSales
     * Description: Sets the value of Customer Sales
    **/ 
    public class CustomerSales {
        
        public Integer Type {get; private set;}
        public String Id_Number {get; private set;}
        public String Name {get; private set;}
        public String Status {get; private set;}
        public Decimal Total {get; private set;}
        public Decimal Balance_Due {get; private set;}
        public String Order_Number {get; private set;}
        public String Owner {get; private set;}
        public String Modified {get; private set;}
        public String Created {get; private set;}
        public Decimal Deposits {get; private set;}
        public Decimal Payments {get; private set;}
        
        public String Id {get; private set;}
          
         public CustomerSales(Sobject sobjRec, String searchName) {
            this.Id = String.valueOf(sobjRec.get('Id'));
            String objectName = ((Id)sobjRec.get('Id')).getSObjectType().getDescribe().getName();
            this.Id_Number = (sobjRec.get('Name') != null) ? String.valueOf(sobjRec.get('Name')) : null;
            this.Balance_Due = 0;
            this.Deposits = 0;
            this.Payments = 0;
            
            this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get(searchName);
            this.Created =  BPUtility.getFormatedDateTime(DateTime.valueOf(String.valueOf(sobjRec.get('CreatedDate'))));
            this.Modified = BPUtility.getLastModifiedDateStr(sobjRec);
            if(objectName == Constants.NAMESPACE +'CO_Header__c') {
            	this.Name = 'Parts & accessories';
                if(sobjRec.getSobject(Constants.NAMESPACE +'Customer__r') == null) {
                    if(sobjRec.get(Constants.NAMESPACE +'CO_Type__c') == Constants.CASH_SALE) {
                        this.Name += ' - ' + Constants.CASH_SALE.toUpperCase();
                    } else if(sobjRec.get(Constants.NAMESPACE +'CO_Type__c') == Constants.INTERNAL_SERVICE) {
                        this.Name += ' - ' + Constants.UNIT_INVENTORY.toUpperCase();
                    }
                } else {
                    this.Name += (sobjRec.getSobject(Constants.NAMESPACE +'Customer__r') != null &&
                    	 sobjRec.getSobject(Constants.NAMESPACE +'Customer__r').get('Name') != null ) ? 
                    	 ' - ' + String.valueOf(sobjRec.getSobject(Constants.NAMESPACE +'Customer__r').get('Name')) : null;
                }
                this.Status = (sobjRec.get(Constants.NAMESPACE +'Merchandise_Status__c') != null) ? String.valueOf(sobjRec.get(Constants.NAMESPACE +'Merchandise_Status__c')) : 'Active';
                this.Total =  ((sobjRec.get(Constants.NAMESPACE +'Order_Total__c') != null) ?  Decimal.valueOf(String.valueOf(sobjRec.get(Constants.NAMESPACE +'Order_Total__c'))) : 0); 
                this.Owner = (sobjRec.getSobject(Constants.NAMESPACE +'Owner__r') != null && sobjRec.getSobject(Constants.NAMESPACE +'Owner__r').get('Name') != null) ? String.valueOf(sobjRec.getSobject(Constants.NAMESPACE +'Owner__r').get('Name')) : null;
                
            }
         }
         
        public CustomerSales(Sobject sobjRec) {
            this.Id = String.valueOf(sobjRec.get('Id'));
            String objectName = ((Id)sobjRec.get('Id')).getSObjectType().getDescribe().getName();
            this.Id_Number = (sobjRec.get('Name') != null) ? String.valueOf(sobjRec.get('Name')) : null;
            
            this.Deposits = 0;
            this.Payments = 0;
            
            
            // Matches for the Object of the CustomerSales group and then assigns to it
            if(objectName == Constants.NAMESPACE +'CO_Header__c') {
                
                this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Customer Orders');
                
                if(sobjRec.getSobject(Constants.NAMESPACE +'Customer__r') == null) {
                    if(sobjRec.get(Constants.NAMESPACE +'CO_Type__c') == Constants.CASH_SALE) {
                        this.Name = Constants.CASH_SALE.toUpperCase();
                    } else if(sobjRec.get(Constants.NAMESPACE +'CO_Type__c') == Constants.INTERNAL_SERVICE) {
                        this.Name = Constants.UNIT_INVENTORY.toUpperCase();
                    }
                } else {
                    this.Name =  (sobjRec.getSobject(Constants.NAMESPACE +'Customer__r') != null &&  sobjRec.getSobject(Constants.NAMESPACE +'Customer__r').get('Name') != null ) ? String.valueOf(sobjRec.getSobject(Constants.NAMESPACE +'Customer__r').get('Name')) : null;
                }
                
                this.Status = (sobjRec.get(Constants.NAMESPACE +'Status__c') != null) ? String.valueOf(sobjRec.get(Constants.NAMESPACE +'Status__c')) : null;
                this.Total =  ((sobjRec.get(Constants.NAMESPACE +'Order_Total__c') != null) ?  Decimal.valueOf(String.valueOf(sobjRec.get(Constants.NAMESPACE +'Order_Total__c'))) : 0); 
                this.Owner = (sobjRec.getSobject(Constants.NAMESPACE +'Owner__r') != null && sobjRec.getSobject(Constants.NAMESPACE +'Owner__r').get('Name') != null) ? String.valueOf(sobjRec.getSobject(Constants.NAMESPACE +'Owner__r').get('Name')) : null;
                this.Balance_Due = (sobjRec.get(Constants.NAMESPACE +'Total_Balance_Due__c') != null) ?  Decimal.valueOf(String.valueOf(sobjRec.get(Constants.NAMESPACE +'Total_Balance_Due__c'))) : null;
                this.Deposits = (sobjRec.get(Constants.NAMESPACE +'Total_Deposit_And_Payment__c') != null) ?  Decimal.valueOf(String.valueOf(sobjRec.get(Constants.NAMESPACE +'Total_Deposit_And_Payment__c'))) : 0;
                this.Payments = (sobjRec.get(Constants.NAMESPACE +'Invoiced_Amount__c') != null) ?  Decimal.valueOf(String.valueOf(sobjRec.get(Constants.NAMESPACE +'Invoiced_Amount__c'))) : 0;
                
            } else if(objectName == Constants.NAMESPACE +'CO_Invoice_Header__c') {
                this.Id = ((sobjRec.get(Constants.NAMESPACE +'CO_Header__c') != null) ? 
                                    String.valueOf(sobjRec.get(Constants.NAMESPACE +'CO_Header__c')) : '');
                
                this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Customer Invoices');
                this.Id_Number = (sobjRec.get('Invoice_Number__c') != null) ? String.valueOf(sobjRec.get('Invoice_Number__c')) : null;
                
                if(sobjRec.getSobject(Constants.NAMESPACE +'CO_Header__r') != null && sobjRec.getSobject(Constants.NAMESPACE +'CO_Header__r').getSobject(Constants.NAMESPACE +'Customer__r') == null) {
                    if(sobjRec.getSobject(Constants.NAMESPACE +'CO_Header__r').get(Constants.NAMESPACE +'CO_Type__c') == Constants.CASH_SALE) {
                        this.Name = Constants.CASH_SALE.toUpperCase();
                    } else if(sobjRec.getSobject(Constants.NAMESPACE +'CO_Header__r').get(Constants.NAMESPACE +'CO_Type__c') == Constants.INTERNAL_SERVICE) {
                        this.Name = Constants.UNIT_INVENTORY.toUpperCase();
                    }
                } else {
                    this.Name = (sobjRec.getSobject(Constants.NAMESPACE +'CO_Header__r') != null && 
                             sobjRec.getSobject(Constants.NAMESPACE +'CO_Header__r').getSobject(Constants.NAMESPACE +'Customer__r') != null && sobjRec.getSobject(Constants.NAMESPACE +'CO_Header__r').getSobject(Constants.NAMESPACE +'Customer__r').get('Name') != null) ? String.valueOf(sobjRec.getSobject(Constants.NAMESPACE +'CO_Header__r').getSobject(Constants.NAMESPACE +'Customer__r').get('Name')) : null;
                }
                this.Status = (sobjRec.get(Constants.NAMESPACE +'Status__c') != null) ? String.valueOf(sobjRec.get(Constants.NAMESPACE +'Status__c')) : null;
                
                //this.Total =  (sobjRec.getSobject('CO_Header__r') != null &&  sobjRec.getSobject('CO_Header__r').get('Total_Order_Value__c') != null) ? Decimal.valueOf(String.valueOf(sobjRec.getSobject('CO_Header__r').get('Total_Order_Value__c'))) : null;
                
                this.Order_Number = (sobjRec.getSobject(Constants.NAMESPACE +'CO_Header__r') != null &&
                                        sobjRec.getSobject(Constants.NAMESPACE +'CO_Header__r').get('Name') != null ) ? 
                                        String.valueOf(sobjRec.getSobject(Constants.NAMESPACE +'CO_Header__r').get('Name')) : null;
                this.Owner = (sobjRec.getSobject(Constants.NAMESPACE +'CO_Header__r') != null &&  sobjRec.getSobject(Constants.NAMESPACE +'CO_Header__r').get(Constants.NAMESPACE +'Owner__c') != null &&  sobjRec.getSobject('CO_Header__r').getSobject(Constants.NAMESPACE +'Owner__r').get('Name') != null) ? String.valueOf(sobjRec.getSobject(Constants.NAMESPACE +'CO_Header__r').getSobject(Constants.NAMESPACE +'Owner__r').get('Name')) : null;
                this.Total = (sobjRec.get(Constants.NAMESPACE +'Total__c') != null) ?  Decimal.valueOf(String.valueOf(sobjRec.get(Constants.NAMESPACE +'Total__c'))) : null;
                //this.Balance_Due = (sobjRec.getSobject(Constants.NAMESPACE +'CO_Header__r') != null && sobjRec.getSobject(Constants.NAMESPACE +'CO_Header__r').get(Constants.NAMESPACE +'Total_Balance_Due__c') != null) ? Decimal.valueOf(String.valueOf(sobjRec.getSobject(Constants.NAMESPACE +'CO_Header__r').get(Constants.NAMESPACE +'Total_Balance_Due__c'))) : null;              
                
                Decimal amountPaid = (sobjRec.get(Constants.NAMESPACE +'Total_Amount_Except_Charge_Account__c') != null) ?  Decimal.valueOf(String.valueOf(sobjRec.get(Constants.NAMESPACE +'Total_Amount_Except_Charge_Account__c'))) : 0;             
                
                this.Balance_Due = (this.Total != null ? this.Total : 0) - amountPaid;
            } else if(objectName == Constants.NAMESPACE +'CO_Invoice_Payment__c') {
                this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Customer Payments');
                this.Id = ((sobjRec.getSobject(Constants.NAMESPACE +'CO_Invoice_Header__r') != null) ? 
                                    String.valueOf(sobjRec.getSobject(Constants.NAMESPACE +'CO_Invoice_Header__r').get('CO_Header__c')) : '');
                
                if(sobjRec.getSobject(Constants.NAMESPACE +'CO_Invoice_Header__r') != null && sobjRec.getSobject(Constants.NAMESPACE +'CO_Invoice_Header__r').getSobject(Constants.NAMESPACE +'CO_Header__r') != null && 
                            sobjRec.getSobject(Constants.NAMESPACE +'CO_Invoice_Header__r').getSobject(Constants.NAMESPACE +'CO_Header__r').getSobject(Constants.NAMESPACE +'Customer__r') == null) {
                    
                    if(sobjRec.getSobject(Constants.NAMESPACE +'CO_Invoice_Header__r').getSobject(Constants.NAMESPACE +'CO_Header__r').get(Constants.NAMESPACE +'CO_Type__c') == Constants.CASH_SALE) {
                        this.Name = Constants.CASH_SALE.toUpperCase();
                    } else if(sobjRec.getSobject(Constants.NAMESPACE +'CO_Invoice_Header__r').getSobject(Constants.NAMESPACE +'CO_Header__r').get(Constants.NAMESPACE +'CO_Type__c') == Constants.INTERNAL_SERVICE) {
                        this.Name = Constants.UNIT_INVENTORY.toUpperCase();
                    }           
                } else {
                    this.Name = (sobjRec.getSobject(Constants.NAMESPACE +'CO_Invoice_Header__r') != null && sobjRec.getSobject(Constants.NAMESPACE +'CO_Invoice_Header__r').getSobject(Constants.NAMESPACE +'CO_Header__r') != null && 
                                sobjRec.getSobject(Constants.NAMESPACE +'CO_Invoice_Header__r').getSobject(Constants.NAMESPACE +'CO_Header__r').getSobject(Constants.NAMESPACE +'Customer__r') != null && 
                                sobjRec.getSobject(Constants.NAMESPACE +'CO_Invoice_Header__r').getSobject(Constants.NAMESPACE +'CO_Header__r').getSobject(Constants.NAMESPACE +'Customer__r').get('Name') != null) ? 
                                        String.valueOf(sobjRec.getSobject(Constants.NAMESPACE +'CO_Invoice_Header__r').getSobject(Constants.NAMESPACE +'CO_Header__r').getSobject(Constants.NAMESPACE +'Customer__r').get('Name')) : 
                                        null;
                }
                this.Total = (sobjRec.get(Constants.NAMESPACE +'Amount__c') != null) ? Decimal.valueOf(String.valueOf(sobjRec.get(Constants.NAMESPACE +'Amount__c'))) : null;
                
                this.Order_Number = ( (sobjRec.getSobject(Constants.NAMESPACE +'CO_Invoice_Header__r').getSobject(Constants.NAMESPACE +'CO_Header__r') != null) &&  
                                      (sobjRec.getSobject(Constants.NAMESPACE +'CO_Invoice_Header__r').getSobject(Constants.NAMESPACE +'CO_Header__r').get('Name')) != null) ? 
                                    String.valueOf(sobjRec.getSobject(Constants.NAMESPACE +'CO_Invoice_Header__r').getSobject(Constants.NAMESPACE +'CO_Header__r').get('Name')) : null;
                this.Owner = (sobjRec.getSobject(Constants.NAMESPACE +'CO_Invoice_Header__r').getSobject(Constants.NAMESPACE +'CO_Header__r') != null &&  sobjRec.getSobject(Constants.NAMESPACE +'CO_Invoice_Header__r').getSobject(Constants.NAMESPACE +'CO_Header__r').get(Constants.NAMESPACE +'Owner__c') != null &&
                            sobjRec.getSobject(Constants.NAMESPACE +'CO_Invoice_Header__r').getSobject(Constants.NAMESPACE +'CO_Header__r').getSobject(Constants.NAMESPACE +'Owner__r').get('Name') != null) ? String.valueOf(sobjRec.getSobject(Constants.NAMESPACE +'CO_Invoice_Header__r').getSobject(Constants.NAMESPACE +'CO_Header__r').getSobject(Constants.NAMESPACE +'Owner__r').get('Name')) : null;
            
            } else if(objectName == Constants.NAMESPACE +'CO_Deposit__c') {
                this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Customer Payments');
                this.Id = ((sobjRec.get(Constants.NAMESPACE +'CO_Header__c') != null) ? 
                                    String.valueOf(sobjRec.get(Constants.NAMESPACE +'CO_Header__c')) : '');
                                    
                if(sobjRec.getSobject(Constants.NAMESPACE +'CO_Header__r') != null && 
                            sobjRec.getSobject(Constants.NAMESPACE +'CO_Header__r').getSobject(Constants.NAMESPACE +'Customer__r') == null) {
                    
                    if(sobjRec.getSobject(Constants.NAMESPACE +'CO_Header__r').get(Constants.NAMESPACE +'CO_Type__c') == Constants.CASH_SALE) {
                        this.Name = Constants.CASH_SALE.toUpperCase();
                    } else if(sobjRec.getSobject(Constants.NAMESPACE +'CO_Header__r').get(Constants.NAMESPACE +'CO_Type__c') == Constants.INTERNAL_SERVICE) {
                        this.Name = Constants.UNIT_INVENTORY.toUpperCase();
                    }           
                } else {
                    this.Name = (sobjRec.getSobject(Constants.NAMESPACE +'CO_Header__r') != null &&  
                                sobjRec.getSobject(Constants.NAMESPACE +'CO_Header__r').getSobject(Constants.NAMESPACE +'Customer__r') != null && 
                                sobjRec.getSobject(Constants.NAMESPACE +'CO_Header__r').getSobject(Constants.NAMESPACE +'Customer__r').get('Name') != null) ? 
                                        String.valueOf(sobjRec.getSobject(Constants.NAMESPACE +'CO_Header__r').getSobject(Constants.NAMESPACE +'Customer__r').get('Name')) : 
                                        null;
                }
                this.Total = (sobjRec.get(Constants.NAMESPACE +'Amount__c') != null) ? Decimal.valueOf(String.valueOf(sobjRec.get(Constants.NAMESPACE +'Amount__c'))) : null;
                
                this.Order_Number = ( (sobjRec.getSobject(Constants.NAMESPACE +'CO_Header__r') != null) &&  
                                      (sobjRec.getSobject(Constants.NAMESPACE +'CO_Header__r').get('Name')) != null) ? 
                                    String.valueOf(sobjRec.getSobject(Constants.NAMESPACE +'CO_Header__r').get('Name')) : null;
                this.Owner = (sobjRec.getSobject(Constants.NAMESPACE +'CO_Header__r') != null &&  sobjRec.getSobject(Constants.NAMESPACE +'CO_Header__r').get(Constants.NAMESPACE +'Owner__c') != null &&
                            sobjRec.getSobject(Constants.NAMESPACE +'CO_Header__r').getSobject(Constants.NAMESPACE +'Owner__r').get('Name') != null) ? String.valueOf(sobjRec.getSobject(Constants.NAMESPACE +'CO_Header__r').getSobject(Constants.NAMESPACE +'Owner__r').get('Name')) : null;
            
            } else if(objectName == Constants.NAMESPACE +'Payment_on_Account__c') {
            	 this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Customer Payments');
            	 this.Id = (sobjRec.get(Constants.NAMESPACE +'Customer__c') != null) ? String.valueOf(sobjRec.get(Constants.NAMESPACE +'Customer__c')) : null;
            	 
            	 this.Name = sobjRec.getSobject(Constants.NAMESPACE +'Customer__c') != null ?
                            String.valueOf(sobjRec.getSobject(Constants.NAMESPACE +'Customer__r').get('Name')) : '';
                
                 this.Total = (sobjRec.get(Constants.NAMESPACE +'Total_Amount__c') != null) ? Decimal.valueOf(String.valueOf(sobjRec.get(Constants.NAMESPACE +'Total_Amount__c'))) : null;           
                 this.Order_Number = 'Paid on account';
                 this.Owner = (sobjRec.getSobject(Constants.NAMESPACE +'Customer__c') != null) ? 
                 			   String.valueOf(sobjRec.getSobject(Constants.NAMESPACE +'Customer__r').getSobject('Owner').get('Name')) : null;
                 
            } else if(objectName == Constants.NAMESPACE + 'Service_Order_Header__c') {
                this.Id = ((sobjRec.getSobject(Constants.NAMESPACE +'CO_Header__r') != null) ? 
                                    String.valueOf(sobjRec.getSobject(Constants.NAMESPACE +'CO_Header__r').get('Id')) : '');
                this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Service Jobs');
                this.Id_Number = ((sobjRec.getSobject(Constants.NAMESPACE +'CO_Header__r') != null) &&  
                                      (sobjRec.getSobject(Constants.NAMESPACE +'CO_Header__r').get('Name')) != null) ? 
                                    String.valueOf(sobjRec.getSobject(Constants.NAMESPACE +'CO_Header__r').get('Name')) : null;
                if(sobjRec.get('SO_Type__c') != null && sobjRec.get('SO_Type__c') == Constants.INTERNAL_SERVICE) {
                    this.Name = Constants.UNIT_INVENTORY;
                } else {
                    this.Name = (sobjRec.get('Name__c') != null) ? sobjRec.get('Name__c') + '': '';
                    if((sobjRec.get('Name__c') != null) && (sobjRec.getSobject(Constants.NAMESPACE +'CO_Header__r') != null &&  
                                    sobjRec.getSobject(Constants.NAMESPACE +'CO_Header__r').getSobject(Constants.NAMESPACE +'Customer__r') != null && 
                                    sobjRec.getSobject(Constants.NAMESPACE +'CO_Header__r').getSobject(Constants.NAMESPACE +'Customer__r').get('Name') != null)) {
                        this.Name += ' - ';
                    }
                    this.Name += (sobjRec.getSobject(Constants.NAMESPACE +'CO_Header__r') != null &&  
                                    sobjRec.getSobject(Constants.NAMESPACE +'CO_Header__r').getSobject(Constants.NAMESPACE +'Customer__r') != null && 
                                    sobjRec.getSobject(Constants.NAMESPACE +'CO_Header__r').getSobject(Constants.NAMESPACE +'Customer__r').get('Name') != null) ? 
                                            String.valueOf(sobjRec.getSobject(Constants.NAMESPACE +'CO_Header__r').getSobject(Constants.NAMESPACE +'Customer__r').get('Name')) : 
                                            '';
                }
                
                this.Total = (sobjRec.get(Constants.NAMESPACE +'Total__c') != null) ? Decimal.valueOf(String.valueOf(sobjRec.get(Constants.NAMESPACE +'Total__c'))) : 0;
                //if(sobjRec.get(Constants.NAMESPACE +'SO_Type__c') != null && sobjRec.get(Constants.NAMESPACE +'SO_Type__c') != 'Deal') {
                    this.Total += (sobjRec.get(Constants.NAMESPACE +'Tax_Amount__c') != null) ? Decimal.valueOf(String.valueOf(sobjRec.get(Constants.NAMESPACE +'Tax_Amount__c'))) : 0;
                //} 
                
                this.Order_Number = '';
                
                this.Owner = (sobjRec.getSobject(Constants.NAMESPACE +'CO_Header__r') != null &&  sobjRec.getSobject(Constants.NAMESPACE +'CO_Header__r').get(Constants.NAMESPACE +'Owner__c') != null &&
                            sobjRec.getSobject(Constants.NAMESPACE +'CO_Header__r').getSobject(Constants.NAMESPACE +'Owner__r').get('Name') != null) ? String.valueOf(sobjRec.getSobject(Constants.NAMESPACE +'CO_Header__r').getSobject(Constants.NAMESPACE +'Owner__r').get('Name')) : null;
                
                this.Status = (sobjRec.get(Constants.NAMESPACE +'SO_Status__c') != null) ? String.valueOf(sobjRec.get(Constants.NAMESPACE +'SO_Status__c')) : null;
            } else if(objectName == Constants.NAMESPACE +'Deal__c') {
                this.Id = ((sobjRec.get(Constants.NAMESPACE +'CO_Header__c') != null) ? 
                                    String.valueOf(sobjRec.get(Constants.NAMESPACE +'CO_Header__c')) : '');
                this.Id_Number = ((sobjRec.getSobject(Constants.NAMESPACE +'CO_Header__r') != null) &&  
                                      (sobjRec.getSobject(Constants.NAMESPACE +'CO_Header__r').get('Name')) != null) ? 
                                    String.valueOf(sobjRec.getSobject(Constants.NAMESPACE +'CO_Header__r').get('Name')) : null;
                this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Unit Deals');
				if(sobjRec.get(Constants.NAMESPACE +'Type__c') != null){
					if(sobjRec.getSobject(Constants.NAMESPACE +'CO_Header__r').getSobject(Constants.NAMESPACE +'Customer__r') != null && 
			                sobjRec.getSobject(Constants.NAMESPACE +'CO_Header__r').getSobject(Constants.NAMESPACE +'Customer__r').get('Name') != null){
						this.Name = String.valueOf(sobjRec.get(Constants.NAMESPACE +'Type__c')) + ' ' + String.valueOf(sobjRec.getSobject(Constants.NAMESPACE +'CO_Header__r').getSobject(Constants.NAMESPACE +'Customer__r').get('Name')); 							
					} else {
							this.Name = String.valueOf(sobjRec.get(Constants.NAMESPACE +'Type__c'));
					}
	
				} else {
					if((sobjRec.getSobject(Constants.NAMESPACE +'CO_Header__r').getSobject(Constants.NAMESPACE +'Customer__r') != null && 
				                sobjRec.getSobject(Constants.NAMESPACE +'CO_Header__r').getSobject(Constants.NAMESPACE +'Customer__r').get('Name') != null)){
						this.Name = String.valueOf(sobjRec.getSobject(Constants.NAMESPACE +'CO_Header__r').getSobject(Constants.NAMESPACE +'Customer__r').get('Name')); 							
					} else {
						this.Name = null;
					}
				}				
                this.Status = (sobjRec.get(Constants.NAMESPACE +'Status__c') != null) ? String.valueOf(sobjRec.get(Constants.NAMESPACE +'Status__c')) : null;
                this.Total =  ((sobjRec.getSobject(Constants.NAMESPACE +'CO_Header__r').get(Constants.NAMESPACE +'Deal_Total__c') != null) ?  Decimal.valueOf(String.valueOf(sobjRec.getSobject(Constants.NAMESPACE +'CO_Header__r').get(Constants.NAMESPACE +'Deal_Total__c'))) : 0); 
                this.Owner = (sobjRec.getSobject(Constants.NAMESPACE +'CO_Header__r') != null &&  sobjRec.getSobject(Constants.NAMESPACE +'CO_Header__r').get(Constants.NAMESPACE +'Owner__c') != null &&
                            sobjRec.getSobject(Constants.NAMESPACE +'CO_Header__r').getSobject(Constants.NAMESPACE +'Owner__r').get('Name') != null) ? String.valueOf(sobjRec.getSobject(Constants.NAMESPACE +'CO_Header__r').getSobject(Constants.NAMESPACE +'Owner__r').get('Name')) : null;
                this.Balance_Due = null;
                this.Deposits = null;
                this.Payments = null;
                this.Order_Number = null;
            }
            
            this.Created =  BPUtility.getFormatedDateTime(DateTime.valueOf(String.valueOf(sobjRec.get('CreatedDate'))));
            this.Modified = BPUtility.getLastModifiedDateStr(sobjRec);
        }
    }   
    
    
    /**
     * Name: Category
     * Description: Sets the value of the Category
    **/ 
    
    public class Category{
        public String Id {get; private set;}
        public Integer Type {get; private set;}
        public String Code {get; private set;}
        public String Status {get; private set;}
        public String Owner {get; private set;}
        public String OwnerId {get; private set;}
        public String Modified {get; private set;}
        public String Created {get; private set;}
        public String Description {get; private set;}
        public String Active {get; private set;}
        
        public Category(Category__c categoryRecord) {
            this.Id = categoryRecord.Id;
            this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Item Categories');
            this.Code = categoryRecord.Unique_Category__c;
            this.Status = categoryRecord.Status__c;
            this.Owner = categoryRecord.Owner.Name;
            this.Created = (categoryRecord.CreatedDate != null) ?  BPUtility.getFormatedDateTime(categoryRecord.CreatedDate) : null;
            this.Modified = BPUtility.getLastModifiedDateStr(categoryRecord);
            this.Description = categoryRecord.Description__c;
            this.Active = (categoryRecord.Active__c) ? 'Active' : 'Inactive';
        }
    }
    
    /**
     * Name: PriceLevel
     * Description: Sets the value of the PriceLevel
    **/ 
    
    public class PriceLevel{
        public String Id {get; private set;}
        public String Code {get; private set;}
        public Integer Type {get; private set;}
        public String Status {get; private set;}
        public String Owner {get; private set;}
        public String OwnerId {get; private set;}
        public String Modified {get; private set;}
        public String Created {get; private set;}
        public String Description {get; private set;}
        public String Active {get; private set;}
        
        public PriceLevel(Price_Level__c priceLevel) {
            this.Id = priceLevel.Id;
            this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Price Levels');
            this.Code = priceLevel.Name__c;
            this.Status = priceLevel.Status__c;
            this.Owner = priceLevel.Owner.Name;
            this.Created = (priceLevel.CreatedDate != null) ?  BPUtility.getFormatedDateTime(priceLevel.CreatedDate): null;
            this.Modified = BPUtility.getLastModifiedDateStr(priceLevel);
            this.Description = priceLevel.Description__c;
            this.Active = (priceLevel.Active__c) ? 'Active' : 'Inactive';
        }
    }
    
    /**
     * Name: SalesTax
     * Description: Sets the value of the SalesTax
    **/ 
    
    public class SalesTax{
        public String Id {get; private set;}
        public String Code {get; private set;}
        public Integer Type {get; private set;}
        public String Tax_Type {get; private set;}
        public String Rates_Included {get; private set;}
        public String Total_Rate {get; private set;}
        public String Status {get; private set;}
        public String Owner {get; private set;}
        public String Modified {get; private set;}
        public String Created {get; private set;}
        public String Description {get; private set;}
        public String Active {get; private set;}
        
        public SalesTax(Sales_Tax__c salesTax) {
            this.Id = salesTax.Id;
            this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Sales Taxes');
            
            this.Tax_Type = salesTax.Tax_Type__c;
            this.Rates_Included = '';
            this.Total_Rate = '';
            
            Boolean isTaxRateOtherThanFixedRate = false;
            Decimal totalRate = 0;
            for(Applicable_Taxes__c appTaxRec: salesTax.Applicable_Taxes__r) {
            	this.Rates_Included += appTaxRec.Sales_Tax_Item__r.Name__c + ', ';
            	
            	if(!appTaxRec.Sales_Tax_Item__r.Rate_Type__c.equalsIgnoreCase(TaxManagementService.FIXED_RATE)) {
            		isTaxRateOtherThanFixedRate = true;
            		break;
            	} else {
            		totalRate += appTaxRec.Sales_Tax_Item__r.Rate__c;
            	}
			}
			
			this.Rates_Included = (this.Rates_Included.length() > 2) ? this.Rates_Included.subString(0, this.Rates_Included.length() - 2) : this.Rates_Included;
			this.Total_Rate = isTaxRateOtherThanFixedRate ? TaxManagementService.MULTIPLE_RATES : String.valueOf(totalRate) + '%';
			
            this.Code = salesTax.Name__c;
            this.Status = salesTax.Status__c;
            this.Owner = salesTax.Owner.Name;
            this.Created = (salesTax.CreatedDate != null) ?  BPUtility.getFormatedDateTime(salesTax.CreatedDate) : null;
            this.Modified = BPUtility.getLastModifiedDateStr(salesTax);
            this.Description = salesTax.Forms_Label__c;
            this.Active = (salesTax.Active__c) ? 'Active' : 'Inactive';
        }
    }
    
    /**
     * Name: Setting
     * Description: Sets the value of the Setting according to its entity type
    **/ 
    
    public class Setting{
        public String Id {get; private set;}
        public Integer Type {get; private set;}
        public String Code {get; private set;}
        public String Status {get; private set;}
        public String Owner {get; private set;}
        public String OwnerId {get; private set;}
        public String Modified {get; private set;}
        public String Created {get; private set;}
        public String Description {get; private set;}
        public String Active {get; private set;}
        
        public Setting(sObject setting) {
            this.Id = String.valueOf(setting.get('Id'));
            this.Status = String.valueOf(setting.get(Constants.NAMESPACE +'Status__c'));
            this.Owner = (setting.getSObject('Owner') != null) ? String.valueOf(setting.getSObject('Owner').get('Name')) : null;
            this.OwnerId =  (setting.getSObject('Owner') != null) ? String.valueOf(setting.getSObject('Owner').get('Id')) : null;
            this.Created =  BPUtility.getFormatedDateTime(DateTime.valueOf(String.valueOf(setting.get('CreatedDate'))));
            this.Modified = BPUtility.getLastModifiedDateStr(setting);
            this.Active = 'Yes';
            // Checks for the Object and assigns value accordingly
            String objectName = ((Id)setting.get('Id')).getSObjectType().getDescribe().getName();
            if(objectName == Constants.NAMESPACE + 'Category__c') {
                this.Code = String.valueOf(setting.get(Constants.NAMESPACE +'Unique_Category__c'));
                this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Item Categories');
                this.Description = String.valueOf(setting.get(Constants.NAMESPACE +'Description__c'));
            } else if(objectName == Constants.NAMESPACE +'Price_Level__c') {
                this.Code = String.valueOf(setting.get(Constants.NAMESPACE +'Name__c'));
                this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Price Levels');
                this.Description = String.valueOf(setting.get(Constants.NAMESPACE +'Description__c'));
            } else if(objectName == Constants.NAMESPACE +'Sales_Tax__c') {
                this.Code = String.valueOf(setting.get(Constants.NAMESPACE +'Name__c'));
                this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Sales Taxes');
                this.Description = String.valueOf(setting.get(Constants.NAMESPACE +'Forms_Label__c'));
            }
            this.Active = Boolean.valueOf(String.valueOf(setting.get(Constants.NAMESPACE +'Active__c'))) ? 'Active' : 'Inactive';
        }
    }

    public class VendorReturn {
        
        public String Id {get; private set;}
        public Integer Type {get; private set;}
        public String Return_Number {get; private set;}
        public String Vendor {get; private set;}
        public String Status {get; private set;}
        public String Submitted {get; private set;}
        public String Approved {get; private set;}
        public String Returned {get; private set;}
        public Decimal Sub_Total {get; private set;}
        public Decimal Taxes {get; private set;}
        public Decimal Total {get; private set;}
        public Decimal Credits_Pending {get; private set;}
        public String RMA_Number {get; private set;}
        public String Tracking_Number {get; private set;}
        public String Reason {get; private set;}
        public String Created {get; private set;}
        public String Modified {get; private set;}
        public String Notes {get; private set;}
        
        public VendorReturn(Return_VO_Header__c returnVORec) {
            this.Id = returnVORec.Id;
            this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Vendor Returns');
            this.Return_Number = returnVORec.Name;
            this.Vendor =  returnVORec.Vendor__r.Name;
            this.Status = returnVORec.Status__c;
            this.Submitted = (returnVORec.Submitted_Date__c != null) ?  BPUtility.getFormatedDateTime(returnVORec.Submitted_Date__c) : null;
            this.Approved = (returnVORec.Approved_Date__c != null) ?  BPUtility.getFormatedDateTime(returnVORec.Approved_Date__c) : null;
            this.Returned = (returnVORec.Returned_Date__c != null) ?  BPUtility.getFormatedDateTime(returnVORec.Returned_Date__c) : null;
            this.Sub_Total = returnVORec.SubTotal_Reporting__c.setScale(2, RoundingMode.HALF_UP);
            this.Taxes = returnVORec.Tax_Reporting__c.setScale(2, RoundingMode.HALF_UP);
            this.Credits_Pending = returnVORec.Credits_Pending_Reporting__c.setScale(2, RoundingMode.HALF_UP);
            this.Total = returnVORec.Total__c != null ? (returnVORec.Total__c).setScale(2, RoundingMode.HALF_UP) : 0;
            this.RMA_Number = returnVORec.RMA__c;
            this.Tracking_Number = returnVORec.Tracking_Number__c;
            this.Reason = returnVORec.Reason__c;
            this.Created = (returnVORec.CreatedDate != null) ?  BPUtility.getFormatedDateTime(returnVORec.CreatedDate) : null;
            this.Modified = BPUtility.getLastModifiedDateStr(returnVORec);
            this.Notes = returnVORec.Notes__c;
        }
    }
    
    /**
     * Name: VendorOrder
     * Description: Sets the value of the VendorOrder
    **/ 
    public class VendorOrder {
        
        public Integer Type;
        public String Order_Number;
        public String Vendor;
        public String Status;
        public Decimal Total;
        public String Created_Date;
        public String Last_Modified;
        public String Order_Type;
        public Decimal Received;
        public String Account_Type;
        public String Expected;
        public String Ordered;
        public String Created_By;
        public String Modified_By; 
        public String Notes;
        
        public String Id {get; private set;}
        
        public VendorOrder(Vendor_Order_Header__c voHeaderRec) {
            this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Vendor Orders');
            this.Order_Number = voHeaderRec.Name;
            this.Vendor =  voHeaderRec.Vendor__r.Name;
            this.Status = voHeaderRec.Status__c;
            this.Total = voHeaderRec.Total__c; 
            this.Received = voHeaderRec.Total_Recieved__c; 
            this.Created_By = voHeaderRec.CreatedBy.Name;
            this.Modified_By = voHeaderRec.Last_Modified_By__r.Name;
            this.Created_Date = (voHeaderRec.CreatedDate != null) ?  BPUtility.getFormatedDateTime(voHeaderRec.CreatedDate) : null;
            this.Last_Modified = BPUtility.getLastModifiedDateStr(voHeaderRec);
            this.Order_Type = (voHeaderRec.Purchase_Order_Type__c != null) ? voHeaderRec.Purchase_Order_Type__r.Code__c : null;
            this.Id = voHeaderRec.Id;
            this.Account_Type = (voHeaderRec.Vendor__c != null && voHeaderRec.Vendor__r.Vendor_Account_Type__c != null) ? voHeaderRec.Vendor__r.Vendor_Account_Type__r.Name : null;
            this.Expected = (voHeaderRec.Expected_Date_Formula__c != null) ?  BPUtility.getFormatedDateTime(voHeaderRec.Expected_Date_Formula__c) : null;
            this.Ordered = (voHeaderRec.Ordered_Date__c != null) ?  BPUtility.getFormatedDateTime(datetime.newInstance(voHeaderRec.Ordered_Date__c.year(), voHeaderRec.Ordered_Date__c.month(), voHeaderRec.Ordered_Date__c.day())) : null;
            this.Notes = (voHeaderRec.Notes__c != null) ? voHeaderRec.Notes__c : '';
        }
    }
    
    /**
     * Name: VendorInvoice
     * Description: Sets the value of the VendorInvoice
    **/ 
    public class VendorInvoice {
        
        public Integer Type {get; private set;}
        public String Invoice_Number {get; private set;}
        public String Vendor {get; private set;}
        public string VendorId {get; private set;}
        public Decimal Total {get; private set;}
        public String Status {get; private set;}
        public String Owner {get; private set;}
        public String OwnerId {get; private set;}
        public String Modified {get; private set;}
        public String Created {get; private set;}
        public String Id {get; private set;}
        public String Account_Type {get; private set;}
        
        public VendorInvoice(Vendor_Invoicing_Header__c voInvoiceRec) {
            this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Vendor Invoices');
            this.Invoice_Number = voInvoiceRec.Vendor_Invoice_Number__c;
            this.Vendor =  voInvoiceRec.Vendor__r.Name;
            this.Status = voInvoiceRec.Status__c;
            this.Owner = voInvoiceRec.Owner__r.Name;
            this.Created = (voInvoiceRec.CreatedDate != null) ?  BPUtility.getFormatedDateTime(voInvoiceRec.CreatedDate) : null;
            this.Modified = BPUtility.getLastModifiedDateStr(voInvoiceRec);
            this.Account_Type = (voInvoiceRec.Vendor__c != null && voInvoiceRec.Vendor__r.Vendor_Account_Type__c != null) ? voInvoiceRec.Vendor__r.Vendor_Account_Type__r.Name : null;
            this.Total = voInvoiceRec.Total_With_Tax__c;
            this.Id = voInvoiceRec.Id;
        }
    }
    
    //Dinesh Kumar 10/10/2016
    /**
     * Name: Part Needed
     * Description: Sets the value of the VendorInvoice
    **/ 
    public class PartNeeded {
        public Integer Type {get; private set;}
        public String Customer {get; private set;}
        public String Item_Description {get; private set;}
        public string Needed_For {get; private set;}
        public Decimal Qty_Needed {get; private set;}
        public String Status {get; private set;}
        public Decimal Total_Cost {get; private set;}
        public String Vendor {get; private set;}
        public String Id {get; private set;}
        public String PartId {get; private set;}
        public String CustomerOrderId {get; private set;}
        public String Created {get; private set;}
        public String Modified {get; private set;}
        public String Part_Type {get; private set;}
        public Decimal Quantity_Available {get; private set;}
        public Decimal Quantity_On_Order {get; private set;}

        public PartNeeded(Vendor_Order_Line_Item__c partNeededRec, Business_Profile__c dealerInfoRec) {
            this.Needed_For = partNeededRec.Needed_For__c;  
            this.Customer = partNeededRec.Customer__c;
            
            if(partNeededRec.Part__c != null) {
                this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('VO Items Parts');
            	this.Vendor = partNeededRec.Part__r.Vendor__r.Name;
            	this.Item_Description = partNeededRec.Part__r.Item_Description__c;
                this.Part_Type = (partNeededRec.Part__r.Part_Type__c != null) ? partNeededRec.Part__r.Part_Type__c :'Part';
            } else if(partNeededRec.Sublet__c != null) {
                this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('VO Items Sublets');
            	this.Vendor = partNeededRec.Sublet__r.Vendor__r.Name;
            	
            	String itemDesc = (partNeededRec.Service_Order_Line_Item__r.Item_Code__c != null) ? partNeededRec.Service_Order_Line_Item__r.Item_Code__c : '';
	        	itemDesc += (partNeededRec.Service_Order_Line_Item__r.Item_Description__c != null) ? 
	        		((itemDesc.length() > 0 ? ' - ' : '' ) + partNeededRec.Service_Order_Line_Item__r.Item_Description__c) : '';
	        	this.Item_Description = itemDesc;
            	this.Part_Type = 'Sublet';
            }
            if(partNeededRec.Is_required_For_Customer__c || partNeededRec.Is_Service__c) {
                //this.Needed_For = partNeededRec.CO_Header__r.Name;    
                //this.Customer = partNeededRec.CO_Header__r.Customer__r.Name;
                this.Id = partNeededRec.CO_Header__c;
                this.CustomerOrderId = partNeededRec.CO_Header__c;
            } else {
                //this.Needed_For = 'STOCK';    
                this.PartId = partNeededRec.Part__c;
                this.Id = partNeededRec.Part__c;
                //this.Customer = partNeededRec.Dealer_Name__c;
            }

                        this.Qty_Needed = partNeededRec.Qty_Needed__c;
            this.Quantity_Available = (partNeededRec.Part__r.AvailableParts__c != null) ? partNeededRec.Part__r.AvailableParts__c : 0;
            this.Quantity_On_Order =  (partNeededRec.Part__r.Qty_On_Order__c != null) ? partNeededRec.Part__r.Qty_On_Order__c : 0;
            this.Status = 'Required';
            if(partNeededRec.Qty_Needed__c != null && partNeededRec.Cost__c != null) {
                this.Total_Cost = partNeededRec.Total_Cost__c;
            } else {
                this.Total_Cost = 0;
            }
            
            this.Created =  BPUtility.getFormatedDateTime(partNeededRec.CreatedDate);
            this.Modified = BPUtility.getLastModifiedDateStr(partNeededRec);
        }
    }
    
    /**
     * Name: User
     * Description: Sets the value of the VendorInvoice
    **/ 
    public class UserRec {
        
        public Integer Type {get; private set;}
        public String Name {get; private set;}
        public String Email {get; private set;}
        public Boolean Status {get; private set;}
        public String Modified {get; private set;}
        public String Created {get; private set;}
        public String Id {get; private set;}
        
        public UserRec(User userRec) {
            this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Users');
            this.Name = userRec.Name;
            this.Email =  userRec.Email;
            this.Status = userRec.IsActive ? true : false;
            this.Created = (userRec.CreatedDate__c != null) ? getFormattedDate(String.valueOf(userRec.CreatedDate__c)) : null;
            this.Modified = (userRec.LastModifiedDate__c != null) ? getFormattedDate(String.valueOf(userRec.LastModifiedDate__c)) : null;
            this.Id = userRec.Id;
        }
    }
    
    public class ServiceJob {
        
        public Integer Type;
        public String Order_Number;
        public String Customer;
        public String Job_Type;
        public String Status;
        public String SO_Status;
        public String Job;
        public String Unit_Description;
        public String Technician;
        public String Opened;
        public String Modified;
        public String Id;
        public String SOId;
        
        public String Concern;
        public String VIN;
        public String Plate_Number;
        public String Engine_Number;
        public String Unit_Number;
        public String Scheduled;
        public String Invoice_Date;
        public String Invoice_Number;
        
        public Decimal Hrs_Billed;
        public Decimal Hrs_Logged;
        public Decimal Parts_Total;
        public Decimal Labor_Total;
        public Decimal Sublet_Total;
        public Decimal Fees_Total;
        public Decimal Tax_Total;
        public Decimal Total;
        public Decimal WIP_Part_Cost;
        public Decimal WIP_Labor_Cost;
        public Decimal Odometer_In;
        public Decimal Odometer_Out;
        
        public String SO_Type;
        public String Provider;
        public String Claim_Status;
        public String Make;
        public String Model;
        public String SubModel;
        
        public String First_Name;
        public String Last_Name;
        public String Address;
        public String City;
        public String State;
        public String Postal;
        public String Phone;
        public String Mobile;
        public String Email;
        public String Other_Email;
        public String Salesperson;
        public String Date_Due_In;
        public String Date_Promised;
        public String Unit_Arrived;
        
        public String Unit_Data_01;
        public String Unit_Data_02;
        public String Unit_Data_03;
        public String Unit_Data_04;
        public String Unit_Data_05;
        public String Unit_Data_06;
        public String Unit_Data_07;
        public String Unit_Data_08;
        public String Unit_Data_09;
        public String Unit_Data_10;
        public String Unit_Data_11;
        public String Unit_Data_12;
        public String Unit_Data_13;
        public String Unit_Data_14;
        public String Unit_Data_15;

        
        public ServiceJob(Service_Order_Header__c soHeaderRec, List<Service_Order_Line_Item__c> soliList, List<Hours_Logged__c> hrsLoggedList) {
            this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Service Jobs');
            this.Order_Number = (soHeaderRec.CO_Header__c != null ) ? (soHeaderRec.CO_Header__r.Name) : '';
            
            if(soHeaderRec.SO_Type__c == Constants.CASH_SALE) {
                this.Customer = Constants.CASH_SALE.toUpperCase();
            } else if(soHeaderRec.SO_Type__c == Constants.INTERNAL_SERVICE){
                this.Customer = Constants.UNIT_INVENTORY;
            } else {
                this.Customer = soHeaderRec.CO_Header__r.Customer__r.Name;
            }
            this.Job_Type = (soHeaderRec.Transaction_Type__c != null) ? soHeaderRec.Transaction_Type__r.Code_Label__c : '';
            this.Status = soHeaderRec.SO_Status__c;
            this.SO_Status = soHeaderRec.Special_Order_Status_Formula__c;
            
            this.Job = soHeaderRec.Name__c;
            this.Unit_Description = soHeaderRec.Customer_Owned_Unit__r.Formatted_Name__c;
            this.Technician = soHeaderRec.Technician_Name__c;
            this.Opened = (soHeaderRec.CreatedDate != null) ? BPUtility.getFormatedDateTime(soHeaderRec.CreatedDate) : null;
            this.Modified = BPUtility.getLastModifiedDateStr(soHeaderRec);
            this.Id = soHeaderRec.CO_Header__c;
            this.SOId = soHeaderRec.Id;
            
            this.Concern = (soHeaderRec.SO_Concern__c != null) ? soHeaderRec.SO_Concern__c.replaceAll('\n',',') : '';
            if(soHeaderRec.Customer_Owned_Unit__c != null) {
                if(soHeaderRec.Customer_Owned_Unit__r.Unit_Type__c == 'STOCK') {
                    this.Unit_Number = soHeaderRec.Customer_Owned_Unit__r.Stock_Id__c;
                } else {
                    this.Unit_Number = soHeaderRec.Customer_Owned_Unit__r.Unit_Id__c;
                }
                this.VIN = soHeaderRec.Customer_Owned_Unit__r.VIN_Number__c;
                this.Plate_Number = soHeaderRec.Customer_Owned_Unit__r.Plate__c;
                this.Engine_Number = soHeaderRec.Customer_Owned_Unit__r.Engine_Serial_No__c;
                
                this.Make = soHeaderRec.Customer_Owned_Unit__r.Unit_Make__r.Name;
                this.Model = soHeaderRec.Customer_Owned_Unit__r.Unit_Model__r.Name__c;
                this.SubModel = soHeaderRec.Customer_Owned_Unit__r.Sub_Model__r.Sub_Model_Name__c;
            }
            
            if(soHeaderRec.Scheduled_Date__c != null) {
                this.Scheduled = BPUtility.getFormatedDateTime(DateTime.newInstance(soHeaderRec.Scheduled_Date__c.year(), 
                                                                soHeaderRec.Scheduled_Date__c.month(), soHeaderRec.Scheduled_Date__c.day()));
            }
            this.Invoice_Number = soHeaderRec.Invoice_Number__r.Invoice_Number__c;
            this.Invoice_Date = (soHeaderRec.Invoice_Number__c != null && soHeaderRec.Invoice_Number__r.Invoice_Date__c != null) ? 
                                BPUtility.getFormatedDateTime(soHeaderRec.Invoice_Number__r.Invoice_Date__c) : null;
            this.Hrs_Billed = (soHeaderRec.Total_Hours_Billed__c != null) ? soHeaderRec.Total_Hours_Billed__c : 0;
            this.Hrs_Logged = (soHeaderRec.Hrs_Logged__c != null) ? soHeaderRec.Hrs_Logged__c : 0;
            
            this.Parts_Total = (soHeaderRec.Total_Parts__c != null) ? soHeaderRec.Total_Parts__c : 0;
            this.Labor_Total = (soHeaderRec.Total_Labor__c != null) ? soHeaderRec.Total_Labor__c : 0;
            this.Fees_Total = (soHeaderRec.Total_Fee_With_Shop_Supplies__c != null) ? soHeaderRec.Total_Fee_With_Shop_Supplies__c : 0;
            this.Sublet_Total = (soHeaderRec.Total_Sublet__c != null) ? soHeaderRec.Total_Sublet__c : 0;
            this.Tax_Total = (soHeaderRec.Total_Tax__c != null) ? soHeaderRec.Total_Tax__c : 0;
            this.Total = (soHeaderRec.Total_With_Tax__c != null) ? soHeaderRec.Total_With_Tax__c : 0;
            
            this.WIP_Part_Cost = 0;
            this.WIP_Labor_Cost = 0;
            if(String.isBlank(soHeaderRec.Invoice_Number__c)) {
	            for(Service_Order_Line_Item__c soli : soliList) {
	        		if(soli.Part__c != null) {
	                	WIP_Part_Cost += ((soli.Part__r.Average_Cost__c != null && soli.Part__r.Average_Cost__c != 0) ? (soli.Part__r.Average_Cost__c * soli.Qty_Committed__c).setScale(2, RoundingMode.HALF_UP) : (soli.Part__r.Last_Cost__c != null ? (soli.Part__r.Last_Cost__c * soli.Qty_Committed__c).setScale(2, RoundingMode.HALF_UP) : 0));
	        		}
	            }
	            for(Hours_Logged__c hrsLoggedRec : hrsLoggedList) {
	        		if(hrsLoggedRec.End_Date_Time__c != null) {
	                	WIP_Labor_Cost += (hrsLoggedRec.Total_Cost__c != null ? hrsLoggedRec.Total_Cost__c : 0).setScale(2, RoundingMode.HALF_UP);
	        		}
	            }
            }
            
            this.Odometer_In = (soHeaderRec.Odometer_on_Arrival__c != null) ? soHeaderRec.Odometer_on_Arrival__c : 0;
            this.Odometer_Out = (soHeaderRec.Odometer_on_Departure__c != null) ? soHeaderRec.Odometer_on_Departure__c : 0;
            this.SO_Type = soHeaderRec.Transaction_Type__r.Type__c;
            this.Provider = soHeaderRec.Provider__r.Name;
            this.Claim_Status = soHeaderRec.Claim_Status__c;
            
            this.First_Name = soHeaderRec.CO_Header__r.Customer__r.FirstName__c;
            this.Last_Name = soHeaderRec.CO_Header__r.Customer__r.LastName__c;
            
            String billingStreet = (soHeaderRec.CO_Header__r.Customer__r.BillingStreet == null ) ? '' : soHeaderRec.CO_Header__r.Customer__r.BillingStreet;
	        List<String> bsList = billingStreet.split('\n');
            this.Address = (bsList.size() > 0) ? bsList[0].replaceAll('\r', ' ') : '';
            this.Address += (bsList.size() > 1) ? ' ' + bsList[1].replaceAll('\r', ' ') : '';
            
            this.City = soHeaderRec.CO_Header__r.Customer__r.BillingCity;
            this.State = soHeaderRec.CO_Header__r.Customer__r.BillingState;
            this.Postal = soHeaderRec.CO_Header__r.Customer__r.BillingPostalCode;
            
            if(soHeaderRec.CO_Header__r.Customer__r.Type__c == 'Individual') {
                this.Phone = soHeaderRec.CO_Header__r.Customer__r.Formatted_Home_Number__c;
                this.Email = soHeaderRec.CO_Header__r.Customer__r.Email__c;
            } else if(soHeaderRec.CO_Header__r.Customer__r.Type__c == 'Business') {
                this.Phone = soHeaderRec.CO_Header__r.Customer__r.Formatted_Work_Number__c;
                this.Email = soHeaderRec.CO_Header__r.Customer__r.Work_Email__c;
            }
            this.Mobile = soHeaderRec.CO_Header__r.Customer__r.Formatted_Mobile_Number__c;
            this.Other_Email = soHeaderRec.CO_Header__r.Customer__r.Other_Email__c;
            this.Salesperson = String.isNotBlank(soHeaderRec.Salesperson_Names__c) ? soHeaderRec.Salesperson_Names__c : 'Unassigned';

            this.Date_Due_In = (soHeaderRec.Due_In_DateTime__c != null) ?  BPUtility.getFormatedDateTime(soHeaderRec.Due_In_DateTime__c) : null;
            this.Date_Promised = (soHeaderRec.Promised_By_DateTime__c != null) ?  BPUtility.getFormatedDateTime(soHeaderRec.Promised_By_DateTime__c) : null;
			this.Unit_Arrived = (soHeaderRec.Unit_Arrived__c ? 'Yes' : 'No');
			
			this.Unit_Data_01 = String.isNotBlank(soHeaderRec.Customer_Owned_Unit__r.Unit_Data_01__c) ? soHeaderRec.Customer_Owned_Unit__r.Unit_Data_01__c : '';
            this.Unit_Data_02 = String.isNotBlank(soHeaderRec.Customer_Owned_Unit__r.Unit_Data_02__c) ? soHeaderRec.Customer_Owned_Unit__r.Unit_Data_02__c : '';
            this.Unit_Data_03 = String.isNotBlank(soHeaderRec.Customer_Owned_Unit__r.Unit_Data_03__c) ? soHeaderRec.Customer_Owned_Unit__r.Unit_Data_03__c : '';
            this.Unit_Data_04 = String.isNotBlank(soHeaderRec.Customer_Owned_Unit__r.Unit_Data_04__c) ? soHeaderRec.Customer_Owned_Unit__r.Unit_Data_04__c : '';
            this.Unit_Data_05 = String.isNotBlank(soHeaderRec.Customer_Owned_Unit__r.Unit_Data_05__c) ? soHeaderRec.Customer_Owned_Unit__r.Unit_Data_05__c : '';
            this.Unit_Data_06 = String.isNotBlank(soHeaderRec.Customer_Owned_Unit__r.Unit_Data_06__c) ? soHeaderRec.Customer_Owned_Unit__r.Unit_Data_06__c : '';
            this.Unit_Data_07 = String.isNotBlank(soHeaderRec.Customer_Owned_Unit__r.Unit_Data_07__c) ? soHeaderRec.Customer_Owned_Unit__r.Unit_Data_07__c : '';
            this.Unit_Data_08 = String.isNotBlank(soHeaderRec.Customer_Owned_Unit__r.Unit_Data_08__c) ? soHeaderRec.Customer_Owned_Unit__r.Unit_Data_08__c : '';
            this.Unit_Data_09 = String.isNotBlank(soHeaderRec.Customer_Owned_Unit__r.Unit_Data_09__c) ? soHeaderRec.Customer_Owned_Unit__r.Unit_Data_09__c : '';
            this.Unit_Data_10 = String.isNotBlank(soHeaderRec.Customer_Owned_Unit__r.Unit_Data_10__c) ? soHeaderRec.Customer_Owned_Unit__r.Unit_Data_10__c : '';
            this.Unit_Data_11 = String.isNotBlank(soHeaderRec.Customer_Owned_Unit__r.Unit_Data_11__c) ? soHeaderRec.Customer_Owned_Unit__r.Unit_Data_11__c : '';
            this.Unit_Data_12 = String.isNotBlank(soHeaderRec.Customer_Owned_Unit__r.Unit_Data_12__c) ? soHeaderRec.Customer_Owned_Unit__r.Unit_Data_12__c : '';
            this.Unit_Data_13 = String.isNotBlank(soHeaderRec.Customer_Owned_Unit__r.Unit_Data_13__c) ? soHeaderRec.Customer_Owned_Unit__r.Unit_Data_13__c : '';
            this.Unit_Data_14 = String.isNotBlank(soHeaderRec.Customer_Owned_Unit__r.Unit_Data_14__c) ? soHeaderRec.Customer_Owned_Unit__r.Unit_Data_14__c : '';
            this.Unit_Data_15 = String.isNotBlank(soHeaderRec.Customer_Owned_Unit__r.Unit_Data_15__c) ? soHeaderRec.Customer_Owned_Unit__r.Unit_Data_15__c : '';
        }
    }
    
    /**
     * Name: VendorRecieving
     * Description: Sets the value of the VendorRecieving
    **/
    public class VendorRecieving { 
        
        public Integer Type {get; private set;}
        public String Receipt_Number {get; private set;}
        public String Vendor {get; private set;}
        public Decimal Total {get; private set;}
        public String Status {get; private set;}
        public String Owner {get; private set;}
        public String Modified {get; private set;}
        public String Created {get; private set;}
        public String Account_Type {get; private set;}
        public String Id {get; private set;}
        
        public VendorRecieving(Vendor_Receiving_Header__c vrHeaderRec) {
            this.Id = vrHeaderRec.Id;
            this.Receipt_Number = vrHeaderRec.Receipt_Number__c;
            this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Vendor Receivings');
            this.Vendor =  vrHeaderRec.Vendor__r.Name;
            this.Status = vrHeaderRec.Status__c;
            this.Owner = vrHeaderRec.Owner__r.Name;
            this.Created = (vrHeaderRec.CreatedDate != null) ?  BPUtility.getFormatedDateTime(vrHeaderRec.CreatedDate) : null;
            this.Modified = BPUtility.getLastModifiedDateStr(vrHeaderRec);
            this.Account_Type = (vrHeaderRec.Vendor__c != null && vrHeaderRec.Vendor__r.Vendor_Account_Type__c != null) ? vrHeaderRec.Vendor__r.Vendor_Account_Type__r.Name : null;
            this.Total = vrHeaderRec.Receiving_Total__c;
        }
        
    }
    
    //START: Added by Nidhi - #1152 - 19-10-2016
    public class InventoryUnit {
        
        public Integer Type {get; private set;}
        public String Id {get; private set;}
        //public String Name {get; private set;}
        public String Stock_Number {get; private set;}
        public Decimal Year {get; private set;}
        public String Make {get; private set;}
        public String Model {get; private set;}
        public String SubModel {get; private set;}
        public String Ext_Colour {get; private set;}
        public String Status {get; private set;}
        public String Modified {get; private set;}
        public String VIN {get; private set;}
        public String New_Unit {get; private set;}
        
        public Decimal Base_Unit_Price {get; private set;}
        public Decimal Factory_Options {get; private set;}
        public Decimal Dealer_Options {get; private set;}
        public Decimal Total_Price {get; private set;}
        public Decimal Base_Unit_Cost {get; private set;}
        public Decimal Factory_Option_Cost {get; private set;}
        public Decimal Dealer_Option_Cost {get; private set;}
        public Decimal Deal_Options_WIP {get; private set;}
        public Decimal Total_Cost {get; private set;}
        
        public String Category {get; private set;}
        public String Stocked {get; private set;}
        public Decimal Age {get; private set;}
        public String Key_Number {get; private set;}
        public String Engine_Number {get; private set;}
        public String Other_Number {get; private set;}
        public String Int_Colour {get; private set;}
        public String Location {get; private set;}
        public String Vendor {get; private set;}
        
        public String Date_Stocked_Out {get; private set;}
        public String Taxable {get; private set;}
        public String Applicable_Tax {get; private set;}
        public Decimal Cylinders {get; private set;}
        public String Automatic {get; private set;}
        public String Manufactured_Date {get; private set;}
        public Decimal Mileage {get; private set;}
        public String Plate_Number {get; private set;}
        public String Reg_Expiry {get; private set;}
        public String Tags {get; private set;}
        public String Unit_Type;
        public String Mileage_Type {get; private set;}
        public String Compliance_Date {get; private set;}
        public String Year_Of_1st_Rego {get; private set;}
        public String Registration_Serial {get; private set;}
        public Decimal NITC_Withheld {get; private set;}
        public String Unit_Data_01 {get; private set;}
        public String Unit_Data_02 {get; private set;}
        public String Unit_Data_03 {get; private set;}
        public String Unit_Data_04 {get; private set;}
        public String Unit_Data_05 {get; private set;}
        public String Unit_Data_06 {get; private set;}
        public String Unit_Data_07 {get; private set;}
        public String Unit_Data_08 {get; private set;}
        public String Unit_Data_09 {get; private set;}
        public String Unit_Data_10 {get; private set;}
        public String Unit_Data_11 {get; private set;}
        public String Unit_Data_12 {get; private set;}
        public String Unit_Data_13 {get; private set;}
        public String Unit_Data_14 {get; private set;}
        public String Unit_Data_15 {get; private set;}
        public String Consignment {get; private set;}
        
        public InventoryUnit(Customer_Owned_Unit__c stockUnitRec) {
            this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Inventory Unit');
            this.Id = stockUnitRec.Id;
            //this.Name = stockUnitRec.Name;
            this.Stock_Number = stockUnitRec.Stock_Id__c != null ? stockUnitRec.Stock_Id__c : stockUnitRec.Unit_Number__c;
            this.Year = stockUnitRec.Year__c;
            this.Make = (stockUnitRec.Unit_Make__c != null) ? stockUnitRec.Unit_Make__r.Name : '';
            this.Model = (stockUnitRec.Unit_Model__c != null) ? stockUnitRec.Unit_Model__r.Name__c : '';
            this.SubModel = (stockUnitRec.Sub_Model__c != null) ? stockUnitRec.Sub_Model__r.Sub_Model_Name__c : '';
            this.Ext_Colour = stockUnitRec.Colour__c;
            this.Status = stockUnitRec.Status__c;
            this.Vendor = (stockUnitRec.Vendor__c != null) ? stockUnitRec.Vendor__r.Name : '';
            this.Modified = BPUtility.getLastModifiedDateStr(stockUnitRec);
            this.VIN = (stockUnitRec.VIN_Number_Formula__c == null) ? '' : stockUnitRec.VIN_Number_Formula__c;
            if(stockUnitRec.New_Unit__c != null) {
                if(stockUnitRec.New_Unit__c) {
                    this.New_Unit = 'Yes';
                } else {
                    this.New_Unit = 'No';
                }
            }
            
            this.Base_Unit_Price = ((stockUnitRec.Total_Base_Unit_Price__c == null) ? 0 : stockUnitRec.Total_Base_Unit_Price__c).setScale(2, RoundingMode.HALF_UP);
            this.Factory_Options = ((stockUnitRec.Total_Factory_Options_Price__c == null) ? 0 : stockUnitRec.Total_Factory_Options_Price__c).setScale(2, RoundingMode.HALF_UP);
            this.Dealer_Options = ((stockUnitRec.Total_Dealer_Options_Price__c == null) ? 0 : stockUnitRec.Total_Dealer_Options_Price__c).setScale(2, RoundingMode.HALF_UP);
            this.Total_Price = ((stockUnitRec.Total_Price__c == null) ? 0 : stockUnitRec.Total_Price__c).setScale(2, RoundingMode.HALF_UP);
            this.Base_Unit_Cost = ((stockUnitRec.Total_Base_Units_Cost__c == null) ? 0 : stockUnitRec.Total_Base_Units_Cost__c).setScale(2, RoundingMode.HALF_UP);
            this.Factory_Option_Cost = ((stockUnitRec.Total_Factory_Options_Cost__c == null) ? 0 : stockUnitRec.Total_Factory_Options_Cost__c).setScale(2, RoundingMode.HALF_UP);
            this.Dealer_Option_Cost = ((stockUnitRec.Total_Dealer_Options_Cost__c == null) ? 0 : stockUnitRec.Total_Dealer_Options_Cost__c).setScale(2, RoundingMode.HALF_UP);
            this.Deal_Options_WIP = ((stockUnitRec.Deal_Options_WIP__c == null) ? 0 : stockUnitRec.Deal_Options_WIP__c).setScale(2, RoundingMode.HALF_UP);
            this.Total_Cost = ((stockUnitRec.Total_Cost__c == null) ? 0 : stockUnitRec.Total_Cost__c).setScale(2, RoundingMode.HALF_UP);
            
            this.Location = (stockUnitRec.get(Constants.NAMESPACE + 'Location__c') != null) ? String.valueOf(stockUnitRec.get('Location__c')) : null;
            this.Category = (stockUnitRec.Category__c != null) ? stockUnitRec.Category__r.Name : '';
            if(stockUnitRec.Date_Stocked_In__c != null){
                this.Stocked =  BPUtility.getFormatedDateTime(datetime.newInstance(stockUnitRec.Date_Stocked_In__c.year(), stockUnitRec.Date_Stocked_In__c.month(),stockUnitRec.Date_Stocked_In__c.day()));
            }
            this.Age = stockUnitRec.Age__c;
            this.Key_Number = stockUnitRec.Key_No__c;
            this.Engine_Number = stockUnitRec.Engine_Serial_No__c;
            this.Other_Number = stockUnitRec.Other_Serial_No__c;
            this.Int_Colour = stockUnitRec.Interior_Colour__c;
            
            if(stockUnitRec.Date_Stocked_Out__c != null){
                this.Date_Stocked_Out =  BPUtility.getFormatedDateTime((datetime.newInstance(stockUnitRec.Date_Stocked_Out__c.year(), stockUnitRec.Date_Stocked_Out__c.month(),stockUnitRec.Date_Stocked_Out__c.day())));
            }
            this.Taxable = (stockUnitRec.Taxable__c != null) ? ((stockUnitRec.Taxable__c) ? 'Yes' : 'No') : '';
            
            if(stockUnitRec.Taxable__c) {
                this.Applicable_Tax = (stockUnitRec.Applicable_Tax__c != null) ? stockUnitRec.Applicable_Tax__r.Name__c : '';
            }
            this.Cylinders = stockUnitRec.Cylinders__c;
            this.Automatic = (stockUnitRec.Automatic__c != null) ? ((stockUnitRec.Automatic__c) ? 'Yes' : 'No') : '';
            if(stockUnitRec.Manufactured_Date__c != null){
                this.Manufactured_Date =  BPUtility.getFormatedDateTime(datetime.newInstance(stockUnitRec.Manufactured_Date__c.year(), stockUnitRec.Manufactured_Date__c.month(),stockUnitRec.Manufactured_Date__c.day()));
            }
            this.Mileage = stockUnitRec.Mileage_Value__c;
            this.Plate_Number = stockUnitRec.Plate__c;
            
            if(stockUnitRec.Reg_Expiry_Date__c != null){
                this.Reg_Expiry =  BPUtility.getFormatedDateTime(datetime.newInstance(stockUnitRec.Reg_Expiry_Date__c.year(), stockUnitRec.Reg_Expiry_Date__c.month(),stockUnitRec.Reg_Expiry_Date__c.day()));
            }
            
            String tagsNameStr1 = '';
            if(String.isNotBlank(stockUnitRec.Assigned_Tag_1__c) && stockUnitRec.Assigned_Tag_1__c.length() > 1) {
                tagsNameStr1 = stockUnitRec.Assigned_Tag_1__c.substring(1, (stockUnitRec.Assigned_Tag_1__c).length() - 1);
            }
            if(String.isNotBlank(stockUnitRec.Assigned_Tag_2__c) && stockUnitRec.Assigned_Tag_2__c.length() > 1) {
                tagsNameStr1 += (String.isNotBlank(tagsNameStr1)) ? (';' + stockUnitRec.Assigned_Tag_2__c.substring(1, (stockUnitRec.Assigned_Tag_2__c).length() - 1)) : 
                                                                    (stockUnitRec.Assigned_Tag_2__c.substring(1, (stockUnitRec.Assigned_Tag_2__c).length() - 1));
            }
            this.Tags = tagsNameStr1.replace(';', ',');
            this.Mileage_Type = stockUnitRec.Mileage_Type__c;
            this.Compliance_Date = stockUnitRec.Compliance_Date__c;
			this.Year_Of_1st_Rego = stockUnitRec.Year_Of_1st_Rego__c; 
			this.Registration_Serial = stockUnitRec.Registration_Serial__c;
            this.NITC_Withheld = ((stockUnitRec.NITC_Withheld__c == null) ? 0 : stockUnitRec.NITC_Withheld__c).setScale(2, RoundingMode.HALF_UP);
            
            this.Unit_Data_01 = String.isNotBlank(stockUnitRec.Unit_Data_01__c) ? stockUnitRec.Unit_Data_01__c : '';
            this.Unit_Data_02 = String.isNotBlank(stockUnitRec.Unit_Data_02__c) ? stockUnitRec.Unit_Data_02__c : '';
            this.Unit_Data_03 = String.isNotBlank(stockUnitRec.Unit_Data_03__c) ? stockUnitRec.Unit_Data_03__c : '';
            this.Unit_Data_04 = String.isNotBlank(stockUnitRec.Unit_Data_04__c) ? stockUnitRec.Unit_Data_04__c : '';
            this.Unit_Data_05 = String.isNotBlank(stockUnitRec.Unit_Data_05__c) ? stockUnitRec.Unit_Data_05__c : '';
            this.Unit_Data_06 = String.isNotBlank(stockUnitRec.Unit_Data_06__c) ? stockUnitRec.Unit_Data_06__c : '';
            this.Unit_Data_07 = String.isNotBlank(stockUnitRec.Unit_Data_07__c) ? stockUnitRec.Unit_Data_07__c : '';
            this.Unit_Data_08 = String.isNotBlank(stockUnitRec.Unit_Data_08__c) ? stockUnitRec.Unit_Data_08__c : '';
            this.Unit_Data_09 = String.isNotBlank(stockUnitRec.Unit_Data_09__c) ? stockUnitRec.Unit_Data_09__c : '';
            this.Unit_Data_10 = String.isNotBlank(stockUnitRec.Unit_Data_10__c) ? stockUnitRec.Unit_Data_10__c : '';
            this.Unit_Data_11 = String.isNotBlank(stockUnitRec.Unit_Data_11__c) ? stockUnitRec.Unit_Data_11__c : '';
            this.Unit_Data_12 = String.isNotBlank(stockUnitRec.Unit_Data_12__c) ? stockUnitRec.Unit_Data_12__c : '';
            this.Unit_Data_13 = String.isNotBlank(stockUnitRec.Unit_Data_13__c) ? stockUnitRec.Unit_Data_13__c : '';
            this.Unit_Data_14 = String.isNotBlank(stockUnitRec.Unit_Data_14__c) ? stockUnitRec.Unit_Data_14__c : '';
            this.Unit_Data_15 = String.isNotBlank(stockUnitRec.Unit_Data_15__c) ? stockUnitRec.Unit_Data_15__c : '';
            this.Consignment =  (stockUnitRec.Consignment__c == true) ? 'Yes' : 'No';
            if(stockUnitRec.Unit_Type__c == 'ORDU') {
            	this.Unit_Type = 'Order Unit';
            } else if(stockUnitRec.Unit_Type__c == 'STOCK') {
            	this.Unit_Type = 'Stock Unit';
            } else if(stockUnitRec.Unit_Type__c == 'COU' && stockUnitRec.Consignment__c) {
                this.Unit_Type = 'Consignment Unit';
                this.Base_Unit_Price = ((stockUnitRec.Suggested_Price__c == null) ? 0 : stockUnitRec.Suggested_Price__c).setScale(2, RoundingMode.HALF_UP);
                this.Total_Price = ((stockUnitRec.Suggested_Price__c == null) ? 0 : stockUnitRec.Suggested_Price__c).setScale(2, RoundingMode.HALF_UP);
                this.Base_Unit_Cost = ((stockUnitRec.Agreed_Payout__c == null) ? 0 : stockUnitRec.Agreed_Payout__c).setScale(2, RoundingMode.HALF_UP);
                this.Total_Cost = ((stockUnitRec.Agreed_Payout__c == null) ? 0 : stockUnitRec.Agreed_Payout__c).setScale(2, RoundingMode.HALF_UP);
                this.Stock_Number = stockUnitRec.Unit_Id__c != null ? stockUnitRec.Unit_Id__c : stockUnitRec.Unit_Number__c;
            }
        }
    }
    //END: Added by Nidhi - #1152 - 19-10-2016
    
    public class UnitDeal {
        
        public Integer Type {get; private set;}
        public String Id {get; private set;}
        public String Order_Number {get; private set;}
        public String Customer {get; private set;}
        public String Deal_Type {get; private set;}
        public Decimal Total {get; private set;}
        public String Status {get; private set;}
        public String Modified {get; private set;}
        public String Delivery {get; private set;}
        public Decimal Units {get; private set;}
        public Decimal Trade_Ins {get; private set;}
        public Decimal Parts_And_Labour {get; private set;}
        public Decimal Deal_Products {get; private set;}
        public Decimal Fees {get; private set;}
        public Decimal Sales_Tax {get; private set;}
        public Decimal Lien_Payout {get; private set;}
        public Decimal Stamp_Duty {get; private set;}
        public Decimal Financing_Products {get; private set;}
        
        public String First_Name;
		public String Last_Name;
		public String Address;
        public String City;
        public String State;
        public String Postal;
        public String Phone;
        public String Mobile;
        public String Email;
        public String Other_Email;
        public String Salesperson;
        public Decimal Finance_Commission;
        public Decimal Sales_Commission;
        public String Unit_Information;
        public Decimal Option_Clearing;
        public Decimal Stocked_Trades;
        
        public UnitDeal(Deal__c dealRec) { 
            this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Unit Deals');
            this.Id = dealRec.CO_Header__c;
            this.Order_Number = dealRec.CO_Header__r.Name;
            this.Customer = dealRec.CO_Header__r.Customer_Name__c;
            this.Deal_Type = dealRec.Type__c;
            this.Total = dealRec.CO_Header__r.Deal_Total__c;
            this.Status = dealRec.Status__c;
            this.Modified = BPUtility.getLastModifiedDateStr(dealRec);
            this.Delivery = (dealRec.Delivery_Date__c != null) ?  BPUtility.getFormatedDateTime(datetime.newInstance(dealRec.Delivery_Date__c.year(),dealRec.Delivery_Date__c.month(),dealRec.Delivery_Date__c.day())) : null;
            this.Units = dealRec.Pre_Tax_Unit_Price_And_Cost_Total__c;
            this.Trade_Ins = dealRec.Pre_Tax_Trade_In_Total__c;
            this.Parts_And_Labour = dealRec.Pre_Tax_Part_And_Labor_Total__c;
            this.Deal_Products = dealRec.Pre_Tax_Other_Product_Total__c;
            this.Fees = dealRec.Pre_Tax_Fee_Total__c;
            this.Sales_Tax = dealRec.Sales_Tax_Total__c;
            this.Lien_Payout = dealRec.Lien_Payout_Total__c;
            this.Stamp_Duty = dealRec.Stamp_Duty_Total__c;
            this.Financing_Products = dealRec.F_I_Total__c;
            
            this.First_Name = dealRec.CO_Header__r.Customer__r.FirstName__c;
            this.Last_Name = dealRec.CO_Header__r.Customer__r.LastName__c;
            
            String billingStreet = (dealRec.CO_Header__r.Customer__r.BillingStreet == null ) ? '' : dealRec.CO_Header__r.Customer__r.BillingStreet;
	        List<String> bsList = billingStreet.split('\n');
            this.Address = (bsList.size() > 0) ? bsList[0].replaceAll('\r', ' ') : '';
            this.Address += (bsList.size() > 1) ? ' ' + bsList[1].replaceAll('\r', ' ') : '';
            
            this.City = dealRec.CO_Header__r.Customer__r.BillingCity;
            this.State = dealRec.CO_Header__r.Customer__r.BillingState;
            this.Postal = dealRec.CO_Header__r.Customer__r.BillingPostalCode;
            
            if(dealRec.CO_Header__r.Customer__r.Type__c == 'Individual') {
                this.Phone = dealRec.CO_Header__r.Customer__r.Formatted_Home_Number__c;
                this.Email = dealRec.CO_Header__r.Customer__r.Email__c;
            } else if(dealRec.CO_Header__r.Customer__r.Type__c == 'Business') {
                this.Phone = dealRec.CO_Header__r.Customer__r.Formatted_Work_Number__c;
                this.Email = dealRec.CO_Header__r.Customer__r.Work_Email__c;
            }
            this.Mobile = dealRec.CO_Header__r.Customer__r.Formatted_Mobile_Number__c;
            this.Other_Email = dealRec.CO_Header__r.Customer__r.Other_Email__c;
            this.Salesperson = String.isNotBlank(dealRec.Salesperson_Name__c) ? dealRec.Salesperson_Name__c : 'Unassigned';
            this.Finance_Commission = dealRec.Total_Finance_Commission__c != null ? dealRec.Total_Finance_Commission__c : 0;
            this.Sales_Commission = dealRec.Deal_Commission__c != null ? dealRec.Deal_Commission__c : 0;
            if(!dealRec.Deal_Items__r.isEmpty()) {
                if(dealRec.Deal_Items__r.size() > 1) {
                    this.Unit_Information = 'Multiple units';
                } else {
                    this.Unit_Information = dealRec.Deal_Items__r[0].Customer_Owned_Unit__r.Formatted_Name__c;
                }
            }
            this.Option_Clearing = dealRec.Option_Clearing__c != null ? dealRec.Option_Clearing__c : 0;
            this.Stocked_Trades = dealRec.Stocked_Trades__c != null ? dealRec.Stocked_Trades__c : 0;
        }
    }
    
    public class DealUnit {
    	
    	public String Id;
    	public String Unit_Id;
    	public Integer Type;
    	public String Order_Number;
    	public String Stock_Number;
    	public String Status;
    	public String Date_Sold;
        public String Invoice_Number;
        public String Unit_Information;
        public String Make;
        public String Model;
        public String Submodel;
        public Decimal Year;
    	public String Customer;
    	public String Deal_Type;
        public String Salesperson;
    	public Decimal Total_Price;
    	public Decimal Total_Cost;
    	public Decimal Total_Profit;
    	public Decimal Total_Unit_Price;
    	public Decimal Total_Unit_Cost;
    	public Decimal Total_Unit_Profit;
    	public Decimal Total_Unit_Option_Price;
    	public Decimal Total_Unit_Option_Cost;
    	public Decimal Total_Unit_Option_Profit;
    	public Decimal Base_Price;
    	public Decimal Factory_Options;
    	public Decimal Dealer_Installed;
    	public Decimal Part_Options;
    	public Decimal Labor_Options;
    	public Decimal Sublet_Options;
    	public Decimal Fee_Options;
    	public Decimal Warranty_Options;
    	public Decimal Other_Products;
    	public Decimal Stamp_Duty;
    	public String VIN;
    	public String New_Unit;
    	public String Category;
    	public String Stocked_In;
    	public Decimal Age;
        public String Confirmed_Sale;
        public String Unit_Type;
    	public String Tags;
    	public Decimal Mileage;
    	public String Mileage_Type;
    	public String Ext_Color;
    	public String Int_Color;
    	public String Compliance_Date;
        public String Registration_Serial;
        public String Year_of_1st_Rego;
        public String Manufactured_Date;
        public String First_Name;
        public String Last_Name;
        public String Address;
        public String City;
        public String State;
        public String Postal;
        public String Phone;
        public String Mobile;
        public String Email;
        public String Other_Email;
        public String Unit_Data_01;
        public String Unit_Data_02;
        public String Unit_Data_03;
        public String Unit_Data_04;
        public String Unit_Data_05;
        public String Unit_Data_06;
        public String Unit_Data_07;
        public String Unit_Data_08;
        public String Unit_Data_09;
        public String Unit_Data_10;
        public String Unit_Data_11;
        public String Unit_Data_12;
        public String Unit_Data_13;
        public String Unit_Data_14;
        public String Unit_Data_15;

    	public DealUnit(Deal_Item__c dealtemRec) {
	    	this.Id = dealtemRec.Deal__r.CO_Header__c;
	    	this.Unit_Id = dealtemRec.Customer_Owned_Unit__r.Id;
	    	this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Deal Units');
	    	this.Order_Number = dealtemRec.Deal__r.CO_Header__r.Name; 		
			this.Stock_Number = (dealtemRec.Unit_Type__c == 'Stock unit' && dealtemRec.Customer_Owned_Unit__r.Stock_Id__c != null) ? dealtemRec.Customer_Owned_Unit__r.Stock_Id__c : dealtemRec.Customer_Owned_Unit__r.Unit_Number__c;
	    	this.Status = dealtemRec.Unit_Status__c;
			if(dealtemRec.Deal__r.Status__c == 'Invoiced' && dealtemRec.Date_Sold__c != null) {
                this.Date_Sold =  BPUtility.getFormatedDateTime(datetime.newInstance(dealtemRec.Date_Sold__c.year(), dealtemRec.Date_Sold__c.month(),dealtemRec.Date_Sold__c.day()));
                this.Invoice_Number = dealtemRec.Deal__r.Invoice_Number__c != null ? dealtemRec.Deal__r.Invoice_Number__r.Invoice_Number__c : null;
            }
			this.Unit_Information = dealtemRec.Customer_Owned_Unit__c != null ? dealtemRec.Customer_Owned_Unit__r.Formatted_Name__c : null;
	    	this.Make = dealtemRec.Customer_Owned_Unit__c != null ? ((dealtemRec.Customer_Owned_Unit__r.Make_Name__c != null) ? dealtemRec.Customer_Owned_Unit__r.Make_Name__c : '') : 
                            (dealtemRec.Unit_Make__c != null ? dealtemRec.Unit_Make__r.Name : '');
			this.Model = dealtemRec.Customer_Owned_Unit__c != null ? ((dealtemRec.Customer_Owned_Unit__r.Model_Name__c != null) ? dealtemRec.Customer_Owned_Unit__r.Model_Name__c : '') : 
                            (dealtemRec.Unit_Model__c != null ? dealtemRec.Unit_Model__r.Name__c : '');
			this.Submodel = dealtemRec.Customer_Owned_Unit__c != null ? ((dealtemRec.Customer_Owned_Unit__r.Sub_Model__r.Sub_Model_Name__c != null) ? dealtemRec.Customer_Owned_Unit__r.Sub_Model__r.Sub_Model_Name__c : '') : 
                            (dealtemRec.Sub_Model__c != null ? dealtemRec.Sub_Model__r.Sub_Model_Name__c : '');
			this.Year = dealtemRec.Customer_Owned_Unit__c != null ? dealtemRec.Customer_Owned_Unit__r.Year__c : dealtemRec.Year__c;
			this.Customer = dealtemRec.Deal__r.CO_Header__r.Customer_Name__c;	
			this.Deal_Type = dealtemRec.Deal__r.Type__c;			
			this.Salesperson = String.isNotBlank(dealtemRec.Deal__r.Salesperson_Name__c) ? dealtemRec.Deal__r.Salesperson_Name__c : 'Unassigned';
            
            this.Total_Price = ((dealtemRec.Total_Price__c == null) ? 0 : dealtemRec.Total_Price__c).setScale(2, RoundingMode.HALF_UP);	
			this.Total_Cost = ((dealtemRec.Total_Cost__c == null) ? 0 : dealtemRec.Total_Cost__c).setScale(2, RoundingMode.HALF_UP);	
			this.Total_Profit = ((dealtemRec.Total_Profit__c == null) ? 0 : dealtemRec.Total_Profit__c).setScale(2, RoundingMode.HALF_UP);	
			
            this.Total_Unit_Price = ((dealtemRec.Unit_Price__c == null) ? 0 : dealtemRec.Unit_Price__c).setScale(2, RoundingMode.HALF_UP);	
			this.Total_Unit_Cost = ((dealtemRec.Unit_Cost__c == null) ? 0 : dealtemRec.Unit_Cost__c).setScale(2, RoundingMode.HALF_UP);	
			this.Total_Unit_Profit = ((dealtemRec.Unit_Profit__c == null) ? 0 : dealtemRec.Unit_Profit__c).setScale(2, RoundingMode.HALF_UP);	
			
            this.Total_Unit_Option_Price = ((dealtemRec.Unit_Option_Price__c == null) ? 0 : dealtemRec.Unit_Option_Price__c).setScale(2, RoundingMode.HALF_UP);	
			this.Total_Unit_Option_Cost = ((dealtemRec.Unit_Option_Cost__c == null) ? 0 : dealtemRec.Unit_Option_Cost__c).setScale(2, RoundingMode.HALF_UP);	
			this.Total_Unit_Option_Profit = ((dealtemRec.Unit_Option_Profit__c == null) ? 0 : dealtemRec.Unit_Option_Profit__c).setScale(2, RoundingMode.HALF_UP);	
			
            this.Base_Price = ((dealtemRec.Base_Price__c == null) ? 0 : dealtemRec.Base_Price__c).setScale(2, RoundingMode.HALF_UP);			
			this.Factory_Options = ((dealtemRec.Factory_Option_Total__c == null) ? 0 : dealtemRec.Factory_Option_Total__c).setScale(2, RoundingMode.HALF_UP); 	
			this.Dealer_Installed =	((dealtemRec.Dealer_Option_Total__c == null) ? 0 : dealtemRec.Dealer_Option_Total__c).setScale(2, RoundingMode.HALF_UP);
			this.Part_Options =	((dealtemRec.Part_Total__c == null) ? 0 : dealtemRec.Part_Total__c).setScale(2, RoundingMode.HALF_UP);	
			this.Labor_Options = ((dealtemRec.Labour_Total__c == null) ? 0 : dealtemRec.Labour_Total__c).setScale(2, RoundingMode.HALF_UP);		
			this.Sublet_Options = ((dealtemRec.Sublet_Total__c == null) ? 0 : dealtemRec.Sublet_Total__c).setScale(2, RoundingMode.HALF_UP);			
			this.Fee_Options =	((dealtemRec.Fee_Total__c == null) ? 0 : dealtemRec.Fee_Total__c).setScale(2, RoundingMode.HALF_UP);	
			this.Warranty_Options =	((dealtemRec.Warranty_Product_Total__c == null) ? 0 : dealtemRec.Warranty_Product_Total__c).setScale(2, RoundingMode.HALF_UP);		
			this.Other_Products = ((dealtemRec.Other_Product_Total__c == null) ? 0 : dealtemRec.Other_Product_Total__c).setScale(2, RoundingMode.HALF_UP);		
			this.Stamp_Duty = ((dealtemRec.Stamp_Duty_Total__c == null) ? 0 : dealtemRec.Stamp_Duty_Total__c).setScale(2, RoundingMode.HALF_UP);		
			
            this.VIN =	(dealtemRec.Customer_Owned_Unit__r.VIN_Number_Formula__c == null) ? '' : dealtemRec.Customer_Owned_Unit__r.VIN_Number_Formula__c;				
            this.New_Unit = (dealtemRec.Customer_Owned_Unit__r.New_Unit__c) ? 'Yes' : 'No';
			this.Category = (dealtemRec.Customer_Owned_Unit__r.Category__c != null) ? dealtemRec.Customer_Owned_Unit__r.Category__r.Name : '';		
			if(dealtemRec.Customer_Owned_Unit__r.Date_Stocked_In__c != null) {
                this.Stocked_In =  BPUtility.getFormatedDateTime(datetime.newInstance(dealtemRec.Customer_Owned_Unit__r.Date_Stocked_In__c.year(), dealtemRec.Customer_Owned_Unit__r.Date_Stocked_In__c.month(),dealtemRec.Customer_Owned_Unit__r.Date_Stocked_In__c.day()));
            }			
			this.Age = dealtemRec.Customer_Owned_Unit__r.Age__c;
            if(dealtemRec.Deal__r.Confirmed_Sale_Date__c != null) {
                this.Confirmed_Sale = BPUtility.getFormatedDateTime(Datetime.newInstance(dealtemRec.Deal__r.Confirmed_Sale_Date__c.year(), 
                                                dealtemRec.Deal__r.Confirmed_Sale_Date__c.month(),dealtemRec.Deal__r.Confirmed_Sale_Date__c.day()));
            }
            this.Unit_Type = dealtemRec.Unit_Type__c;
			String tagsNameStr1 = '';
            if(String.isNotBlank(dealtemRec.Customer_Owned_Unit__r.Assigned_Tag_1__c) && dealtemRec.Customer_Owned_Unit__r.Assigned_Tag_1__c.length() > 1) {
                tagsNameStr1 = dealtemRec.Customer_Owned_Unit__r.Assigned_Tag_1__c.substring(1, (dealtemRec.Customer_Owned_Unit__r.Assigned_Tag_1__c).length() - 1);
            }
            if(String.isNotBlank(dealtemRec.Customer_Owned_Unit__r.Assigned_Tag_2__c) && dealtemRec.Customer_Owned_Unit__r.Assigned_Tag_2__c.length() > 1) {
                tagsNameStr1 += (String.isNotBlank(tagsNameStr1)) ? (';' + dealtemRec.Customer_Owned_Unit__r.Assigned_Tag_2__c.substring(1, (dealtemRec.Customer_Owned_Unit__r.Assigned_Tag_2__c).length() - 1)) : 
                                                                    (dealtemRec.Customer_Owned_Unit__r.Assigned_Tag_2__c.substring(1, (dealtemRec.Customer_Owned_Unit__r.Assigned_Tag_2__c).length() - 1));
            }
            this.Tags = tagsNameStr1.replace(';', ',');

			this.Mileage = dealtemRec.Customer_Owned_Unit__r.Mileage_Value__c;	
			this.Mileage_Type =	dealtemRec.Customer_Owned_Unit__r.Mileage_Type__c;
			this.Ext_Color = dealtemRec.Customer_Owned_Unit__c != null ? dealtemRec.Customer_Owned_Unit__r.Colour__c : dealtemRec.Colour__c;
			this.Int_Color = dealtemRec.Customer_Owned_Unit__r.Interior_Colour__c;
			this.Compliance_Date = dealtemRec.Customer_Owned_Unit__r.Compliance_Date__c;
			this.Year_of_1st_Rego = dealtemRec.Customer_Owned_Unit__r.Year_Of_1st_Rego__c; 
			this.Registration_Serial = dealtemRec.Customer_Owned_Unit__r.Registration_Serial__c;
			if(dealtemRec.Customer_Owned_Unit__r.Manufactured_Date__c != null){
                this.Manufactured_Date =  BPUtility.getFormatedDateTime(datetime.newInstance(dealtemRec.Customer_Owned_Unit__r.Manufactured_Date__c.year(), dealtemRec.Customer_Owned_Unit__r.Manufactured_Date__c.month(),dealtemRec.Customer_Owned_Unit__r.Manufactured_Date__c.day()));
            }
            
            this.First_Name = dealtemRec.Deal__r.CO_Header__r.Customer__r.FirstName__c;
            this.Last_Name = dealtemRec.Deal__r.CO_Header__r.Customer__r.LastName__c;
            
            String billingStreet = (dealtemRec.Deal__r.CO_Header__r.Customer__r.BillingStreet == null ) ? '' : dealtemRec.Deal__r.CO_Header__r.Customer__r.BillingStreet;
	        List<String> bsList = billingStreet.split('\n');
            this.Address = (bsList.size() > 0) ? bsList[0].replaceAll('\r', ' ') : '';
            this.Address += (bsList.size() > 1) ? ' ' + bsList[1].replaceAll('\r', ' ') : '';
            
            this.City = dealtemRec.Deal__r.CO_Header__r.Customer__r.BillingCity;
            this.State = dealtemRec.Deal__r.CO_Header__r.Customer__r.BillingState;
            this.Postal = dealtemRec.Deal__r.CO_Header__r.Customer__r.BillingPostalCode;
            
            if(dealtemRec.Deal__r.CO_Header__r.Customer__r.Type__c == 'Individual') {
                this.Phone = dealtemRec.Deal__r.CO_Header__r.Customer__r.Formatted_Home_Number__c;
                this.Email = dealtemRec.Deal__r.CO_Header__r.Customer__r.Email__c;
            } else if(dealtemRec.Deal__r.CO_Header__r.Customer__r.Type__c == 'Business') {
                this.Phone = dealtemRec.Deal__r.CO_Header__r.Customer__r.Formatted_Work_Number__c;
                this.Email = dealtemRec.Deal__r.CO_Header__r.Customer__r.Work_Email__c;
            }
            this.Mobile = dealtemRec.Deal__r.CO_Header__r.Customer__r.Formatted_Mobile_Number__c;
            this.Other_Email = dealtemRec.Deal__r.CO_Header__r.Customer__r.Other_Email__c;
            
            this.Unit_Data_01 = String.isNotBlank(dealtemRec.Customer_Owned_Unit__r.Unit_Data_01__c) ? dealtemRec.Customer_Owned_Unit__r.Unit_Data_01__c : '';
            this.Unit_Data_02 = String.isNotBlank(dealtemRec.Customer_Owned_Unit__r.Unit_Data_02__c) ? dealtemRec.Customer_Owned_Unit__r.Unit_Data_02__c : '';
            this.Unit_Data_03 = String.isNotBlank(dealtemRec.Customer_Owned_Unit__r.Unit_Data_03__c) ? dealtemRec.Customer_Owned_Unit__r.Unit_Data_03__c : '';
            this.Unit_Data_04 = String.isNotBlank(dealtemRec.Customer_Owned_Unit__r.Unit_Data_04__c) ? dealtemRec.Customer_Owned_Unit__r.Unit_Data_04__c : '';
            this.Unit_Data_05 = String.isNotBlank(dealtemRec.Customer_Owned_Unit__r.Unit_Data_05__c) ? dealtemRec.Customer_Owned_Unit__r.Unit_Data_05__c : '';
            this.Unit_Data_06 = String.isNotBlank(dealtemRec.Customer_Owned_Unit__r.Unit_Data_06__c) ? dealtemRec.Customer_Owned_Unit__r.Unit_Data_06__c : '';
            this.Unit_Data_07 = String.isNotBlank(dealtemRec.Customer_Owned_Unit__r.Unit_Data_07__c) ? dealtemRec.Customer_Owned_Unit__r.Unit_Data_07__c : '';
            this.Unit_Data_08 = String.isNotBlank(dealtemRec.Customer_Owned_Unit__r.Unit_Data_08__c) ? dealtemRec.Customer_Owned_Unit__r.Unit_Data_08__c : '';
            this.Unit_Data_09 = String.isNotBlank(dealtemRec.Customer_Owned_Unit__r.Unit_Data_09__c) ? dealtemRec.Customer_Owned_Unit__r.Unit_Data_09__c : '';
            this.Unit_Data_10 = String.isNotBlank(dealtemRec.Customer_Owned_Unit__r.Unit_Data_10__c) ? dealtemRec.Customer_Owned_Unit__r.Unit_Data_10__c : '';
            this.Unit_Data_11 = String.isNotBlank(dealtemRec.Customer_Owned_Unit__r.Unit_Data_11__c) ? dealtemRec.Customer_Owned_Unit__r.Unit_Data_11__c : '';
            this.Unit_Data_12 = String.isNotBlank(dealtemRec.Customer_Owned_Unit__r.Unit_Data_12__c) ? dealtemRec.Customer_Owned_Unit__r.Unit_Data_12__c : '';
            this.Unit_Data_13 = String.isNotBlank(dealtemRec.Customer_Owned_Unit__r.Unit_Data_13__c) ? dealtemRec.Customer_Owned_Unit__r.Unit_Data_13__c : '';
            this.Unit_Data_14 = String.isNotBlank(dealtemRec.Customer_Owned_Unit__r.Unit_Data_14__c) ? dealtemRec.Customer_Owned_Unit__r.Unit_Data_14__c : '';
            this.Unit_Data_15 = String.isNotBlank(dealtemRec.Customer_Owned_Unit__r.Unit_Data_15__c) ? dealtemRec.Customer_Owned_Unit__r.Unit_Data_15__c : '';
    	}
    }
    public class CustomerUnit {
        
        public Integer Type {get; private set;}
        public String Id {get; private set;}
        public String Unit_ID {get; private set;}
        public String Customer {get; private set;}
        public String Phone_Number {get; private set;}
        public Decimal Year {get; private set;}
        public String Make {get; private set;}
        public String Model {get; private set;}
        public String SubModel {get; private set;}
        public Decimal Mileage {get; private set;}
        public String Status {get; private set;}
        public String Modified {get; private set;}
        
        public String VIN {get; private set;}
        public String Plate_Number {get; private set;}
        public String Reg_Expiry {get; private set;}
        public String Key_Number {get; private set;}
        public String Engine_Number {get; private set;}
        public String Other_Number {get; private set;}
        public String Ext_Colour {get; private set;}
        public String Int_Colour {get; private set;}
        public String Tags {get; private set;}
        public String Account_Type {get; private set;}
        public String Compliance_Date {get; private set;}
        public String Year_Of_1st_Rego {get; private set;}
        public String Registration_Serial {get; private set;}
        public String Manufactured_Date {get; private set;}
        public String Unit_Data_01 {get; private set;}
        public String Unit_Data_02 {get; private set;}
        public String Unit_Data_03 {get; private set;}
        public String Unit_Data_04 {get; private set;}
        public String Unit_Data_05 {get; private set;}
        public String Unit_Data_06 {get; private set;}
        public String Unit_Data_07 {get; private set;}
        public String Unit_Data_08 {get; private set;}
        public String Unit_Data_09 {get; private set;}
        public String Unit_Data_10 {get; private set;}
        public String Unit_Data_11 {get; private set;}
        public String Unit_Data_12 {get; private set;}
        public String Unit_Data_13 {get; private set;}
        public String Unit_Data_14 {get; private set;}
        public String Unit_Data_15 {get; private set;}
        
        public CustomerUnit(Customer_Owned_Unit__c customerUnitRec) {
            this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Customer Unit');
            this.Id = customerUnitRec.Id;
            this.Unit_ID = customerUnitRec.Unit_Number__c;
            this.Customer = (customerUnitRec.Account__r.Name != null) ? customerUnitRec.Account__r.Name : '';
            if(customerUnitRec.Account__r.Preferred_Phone__c != null) {
                this.Phone_Number = customerUnitRec.Account__r.Formatted_Preferred_Phone__c;
            } else if(customerUnitRec.Account__r.Home_Number__c != null) {
                this.Phone_Number = customerUnitRec.Account__r.Formatted_Home_number__c;
            } else if(customerUnitRec.Account__r.Mobile__c != null) {
                this.Phone_Number = customerUnitRec.Account__r.Formatted_Mobile_Number__c;
            }
            
            this.Account_Type = (customerUnitRec.Account__c != null && customerUnitRec.Account__r.Account_Type__c != null) 
                                ? customerUnitRec.Account__r.Account_Type__r.Name : '';
            this.Year = customerUnitRec.Year__c;
            this.Year = customerUnitRec.Year__c;
            this.Make = (customerUnitRec.Unit_Make__c != null) ? customerUnitRec.Unit_Make__r.Name : '';
            this.Model = (customerUnitRec.Unit_Model__c != null) ? customerUnitRec.Unit_Model__r.Name__c : '';
            this.SubModel = (customerUnitRec.Sub_Model__c != null) ? customerUnitRec.Sub_Model__r.Sub_Model_Name__c : '';
            this.Mileage = customerUnitRec.Mileage_Value__c;
            this.Status = customerUnitRec.Status__c;
            this.Modified = BPUtility.getLastModifiedDateStr(customerUnitRec);
            
            this.VIN = (customerUnitRec.VIN_Number_Formula__c == null) ? '' : customerUnitRec.VIN_Number_Formula__c;
            this.Plate_Number = customerUnitRec.Plate__c;
            if(customerUnitRec.Reg_Expiry_Date__c != null){
                this.Reg_Expiry =  BPUtility.getFormatedDateTime(datetime.newInstance(customerUnitRec.Reg_Expiry_Date__c.year(), customerUnitRec.Reg_Expiry_Date__c.month(),customerUnitRec.Reg_Expiry_Date__c.day()));
            }
            this.Key_Number = customerUnitRec.Key_No__c;
            this.Engine_Number = customerUnitRec.Engine_Serial_No__c;
            this.Other_Number = customerUnitRec.Other_Serial_No__c;
            this.Ext_Colour = customerUnitRec.Colour__c;
            this.Int_Colour = customerUnitRec.Interior_Colour__c;
            
            String tagsNameStr1 = '';
            if(String.isNotBlank(customerUnitRec.Assigned_Tag_1__c) && customerUnitRec.Assigned_Tag_1__c.length() > 1) {
                tagsNameStr1 = customerUnitRec.Assigned_Tag_1__c.substring(1, (customerUnitRec.Assigned_Tag_1__c).length() - 1);
        }
            if(String.isNotBlank(customerUnitRec.Assigned_Tag_2__c) && customerUnitRec.Assigned_Tag_2__c.length() > 1) {
                tagsNameStr1 += (String.isNotBlank(tagsNameStr1)) ? (';' + customerUnitRec.Assigned_Tag_2__c.substring(1, (customerUnitRec.Assigned_Tag_2__c).length() - 1)) : 
                                                                    (customerUnitRec.Assigned_Tag_2__c.substring(1, (customerUnitRec.Assigned_Tag_2__c).length() - 1));
    }
    
            this.Tags = tagsNameStr1.replace(';', ',');
			this.Compliance_Date = customerUnitRec.Compliance_Date__c;
			this.Year_Of_1st_Rego = customerUnitRec.Year_Of_1st_Rego__c; 
			this.Registration_Serial = customerUnitRec.Registration_Serial__c;
			if(customerUnitRec.Manufactured_Date__c != null){
                this.Manufactured_Date =  BPUtility.getFormatedDateTime(datetime.newInstance(customerUnitRec.Manufactured_Date__c.year(), customerUnitRec.Manufactured_Date__c.month(),customerUnitRec.Manufactured_Date__c.day()));
            }           
            
            this.Unit_Data_01 = String.isNotBlank(customerUnitRec.Unit_Data_01__c) ? customerUnitRec.Unit_Data_01__c : '';
            this.Unit_Data_02 = String.isNotBlank(customerUnitRec.Unit_Data_02__c) ? customerUnitRec.Unit_Data_02__c : '';
            this.Unit_Data_03 = String.isNotBlank(customerUnitRec.Unit_Data_03__c) ? customerUnitRec.Unit_Data_03__c : '';
            this.Unit_Data_04 = String.isNotBlank(customerUnitRec.Unit_Data_04__c) ? customerUnitRec.Unit_Data_04__c : '';
            this.Unit_Data_05 = String.isNotBlank(customerUnitRec.Unit_Data_05__c) ? customerUnitRec.Unit_Data_05__c : '';
            this.Unit_Data_06 = String.isNotBlank(customerUnitRec.Unit_Data_06__c) ? customerUnitRec.Unit_Data_06__c : '';
            this.Unit_Data_07 = String.isNotBlank(customerUnitRec.Unit_Data_07__c) ? customerUnitRec.Unit_Data_07__c : '';
            this.Unit_Data_08 = String.isNotBlank(customerUnitRec.Unit_Data_08__c) ? customerUnitRec.Unit_Data_08__c : '';
            this.Unit_Data_09 = String.isNotBlank(customerUnitRec.Unit_Data_09__c) ? customerUnitRec.Unit_Data_09__c : '';
            this.Unit_Data_10 = String.isNotBlank(customerUnitRec.Unit_Data_10__c) ? customerUnitRec.Unit_Data_10__c : '';
            this.Unit_Data_11 = String.isNotBlank(customerUnitRec.Unit_Data_11__c) ? customerUnitRec.Unit_Data_11__c : '';
            this.Unit_Data_12 = String.isNotBlank(customerUnitRec.Unit_Data_12__c) ? customerUnitRec.Unit_Data_12__c : '';
            this.Unit_Data_13 = String.isNotBlank(customerUnitRec.Unit_Data_13__c) ? customerUnitRec.Unit_Data_13__c : '';
            this.Unit_Data_14 = String.isNotBlank(customerUnitRec.Unit_Data_14__c) ? customerUnitRec.Unit_Data_14__c : '';
            this.Unit_Data_15 = String.isNotBlank(customerUnitRec.Unit_Data_15__c) ? customerUnitRec.Unit_Data_15__c : '';
        }
    }
    
    /**
     * Name: VendorOrdering
     * Description: Sets the value of the VendorOrdering
    **/
    public class VendorOrdering {
        
        public String Id {get; private set;}
        public String Id_Number {get; private set;}
        public Integer Type {get; private set;}
        public String Vendor {get; private set;}
        public string VendorId {get; private set;}
        public Decimal Total {get; private set;}
        public String Status {get; private set;}
        public String Owner {get; private set;}
        public String OwnerId {get; private set;}
        public String Modified {get; private set;}
        public String Created {get; private set;}
        
        public VendorOrdering(Sobject sobjRec) {
            this.Id = String.valueOf(sobjRec.get('Id'));
            String objectName = ((Id)sobjRec.get('Id')).getSObjectType().getDescribe().getName();
            
            // Checks for the  Object and assigns the value accordingly for object type
            this.Status = (sobjRec.get(Constants.NAMESPACE +'Status__c') != null) ? String.valueOf(sobjRec.get(Constants.NAMESPACE +'Status__c')) : null;
            if(objectName == Constants.NAMESPACE + 'Return_VO_Header__c' || objectName == Constants.NAMESPACE + 'Return_CR_Header__c') {
                this.Owner = String.valueOf((sobjRec.getSobject('Owner')).get('Name'));
            } else {
            this.Owner = (sobjRec.getSobject(Constants.NAMESPACE +'Owner__r') != null && sobjRec.getSobject(Constants.NAMESPACE +'Owner__r').get('Name') != null) ? String.valueOf(sobjRec.getSobject(Constants.NAMESPACE +'Owner__r').get('Name')) : null;
            }
            this.Vendor = (sobjRec.getSobject(Constants.NAMESPACE +'Vendor__r') != null && sobjRec.getSobject(Constants.NAMESPACE +'Vendor__r').get('Name') != null) ? String.valueOf(sobjRec.getSobject(Constants.NAMESPACE +'Vendor__r').get('Name')) : null;
            this.Total = 0;
            
            if(objectName == Constants.NAMESPACE +'Vendor_Order_Header__c') {
                this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Vendor Orders');
                this.Id_Number = (sobjRec.get('Name') != null) ? String.valueOf(sobjRec.get('Name')) : null;
                this.Total = (sobjRec.get('Total__c') != null) ? Decimal.valueOf(String.valueOf(sobjRec.get('Total__c'))) : null;
            } else if(objectName == Constants.NAMESPACE +'Return_VO_Header__c') {
                this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Vendor Returns');
                this.Id_Number = (sobjRec.get('Name') != null) ? String.valueOf(sobjRec.get('Name')) : null;
                this.Total = (sobjRec.get('Total__c') != null) ? Decimal.valueOf(String.valueOf(sobjRec.get('Total__c'))) : null;
            } else if(objectName == Constants.NAMESPACE +'Return_CR_Header__c') {
                this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Vendor Credit');
                this.Id_Number = (sobjRec.get('Name') != null) ? String.valueOf(sobjRec.get('Name')) : null;
                this.Total = (sobjRec.get('Total_With_Tax__c') != null) ? Decimal.valueOf(String.valueOf(sobjRec.get('Total_With_Tax__c'))) : null;
            } else if(objectName == Constants.NAMESPACE +'Vendor_Receiving_Header__c') {
                this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Vendor Receivings');
                this.Id_Number = (sobjRec.get('Receipt_Number__c') != null) ? String.valueOf(sobjRec.get(Constants.NAMESPACE +'Receipt_Number__c')) : null;
                this.Total = (sobjRec.get('Receiving_Total__c') != null) ? Decimal.valueOf(String.valueOf(sobjRec.get('Receiving_Total__c'))) : null;
            } else if(objectName == Constants.NAMESPACE +'Vendor_Invoicing_Header__c') {
                this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Vendor Invoices');
                this.Id_Number = (sobjRec.get('Vendor_Invoice_Number__c') != null) ? String.valueOf(sobjRec.get(Constants.NAMESPACE +'Vendor_Invoice_Number__c')) : null;
                this.Total = (sobjRec.get('Total_With_Tax__c') != null) ? Decimal.valueOf(String.valueOf(sobjRec.get('Total_With_Tax__c'))) : null;
            } 
             
            this.Created =  BPUtility.getFormatedDateTime(DateTime.valueOf(String.valueOf(sobjRec.get('CreatedDate'))));
            this.Modified = BPUtility.getLastModifiedDateStr(sobjRec);
        }
     
    }
    /**
     * Name: Part Movement
     * Description: Sets the value of the Part FIFO
    **/ 
    public class PartMovement {
        public String Id;
        public String Name;
        public Integer Type;
        public String Part_Number;
        public String Description;
        public Decimal Opening_Value;
        public Decimal Opening_Qty;
        public Decimal Purchased_Qty;
        public Decimal Sales_Qty;
        public Decimal Adjusted_Qty;
        public Decimal Closing_Qty;
        public Decimal Closing_Value;
        public Decimal Total_Sales;
        public Decimal Purchased_Cost;
        public Decimal Cost_of_Sales;
        public Decimal Adjusted_Cost;
        public String Last_Sold;
        public String Last_Stocked;
        public Decimal Reorder_At;
        public Decimal Reorder_To;
        public String Location;
        public String Vendor;
        public String Part_Type;
        public String Category;
        public String Status;
        public Decimal Qty_Available;
        
        public PartMovement(){}
        public PartMovement(Part__c partRec) {
            this.Id = partRec.Id;
            this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Parts');
            this.Vendor = partRec.Vendor__r.Name;
            this.Category = partRec.Category__r.Name;
            this.Part_Type = partRec.Part_Type__c;
            this.Location = partRec.Location__c;
            this.Status = partRec.Status__c;
            this.Last_Sold = partRec.Last_Sold__c!= null ? BPUtility.getFormatedDateTime(DateTime.valueOf(String.valueOf(partRec.Last_Sold__c))) : '';
            this.Last_Stocked = partRec.Last_Stocked__c != null ? BPUtility.getFormatedDateTime(DateTime.valueOf(String.valueOf(partRec.Last_Stocked__c))) : '';
            this.Reorder_At = partRec.Auto_reorder_Min__c;
            this.Reorder_To = partRec.Auto_reorder_Max__c;
            this.Part_Number = partRec.Part_Number__c;
            this.Description = partRec.Description__c;
            this.Qty_Available = partRec.AvailableParts__c;
        }
    }
    
    public class TaxReporting {
        public String Id {get; private set;}
        public Integer Type{get; private set;}
        public String Transaction_Type {get; private set;}
        public String Document_Number {get; private set;}
        public String Customer_Vendor {get; private set;}
        public String Transaction_Date {get; private set;}
        public String Tax_Name {get; private set;}
        public Decimal Taxable_Amount {get; private set;}
        public Decimal Tax_Amount {get; private set;}
        public Decimal Non_Taxable_Amount {get; private set;}
        public String Contents {get; private set;}
        
        public TaxReporting(CO_Invoice_Header__c coInvoiceRec, String taxName, Decimal taxableAmount, Decimal taxAmount, Decimal nonTaxableAmount, String contents) {
            this.Id = coInvoiceRec.CO_Header__c;
            this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Customer Invoices');
            this.Transaction_Type = 'Customer Invoice';
            this.Transaction_Date = (coInvoiceRec.Invoice_Date__c != null) ? BPUtility.getFormatedDateTime(coInvoiceRec.Invoice_Date__c) : null;
            
            this.Document_Number = coInvoiceRec.Invoice_Number__c;
            this.Customer_Vendor = coInvoiceRec.CO_Header__r.Customer_Name__c;
            setValues(taxName, taxableAmount, taxAmount, nonTaxableAmount);
            this.Contents = contents;
        }
        
        public TaxReporting(Vendor_Invoicing_Header__c voInvoiceRec, String taxName, Decimal taxableAmount, Decimal taxAmount, Decimal nonTaxableAmount, String contents) {
            this.Id = voInvoiceRec.Id;
            this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Vendor Invoices');
            this.Transaction_Type = 'Vendor Invoice';
            this.Document_Number = voInvoiceRec.Vendor_Invoice_Number__c;
            this.Transaction_Date = voInvoiceRec.get(Constants.NAMESPACE +'Invoice_Date__c') != null ? 
                                BPUtility.getFormatedDateTime(DateTime.valueOf(String.valueOf(voInvoiceRec.get('Invoice_Date__c')))) : '';
            this.Customer_Vendor = voInvoiceRec.Vendor__r.Name;
            setValues(taxName, taxableAmount, taxAmount, nonTaxableAmount);
            this.Contents = contents;
        }

        public TaxReporting(Unit_Price_Cost__c upcRec, Sales_Tax_Item__c stiRec, String taxName) {
            this.Id = upcRec.Customer_Owned_Unit__c;
            this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Inventory Unit');
            this.Transaction_Type = 'Unit Adjustment';
            if(upcRec.Vendor__c != null) {
                this.Document_Number = upcRec.Vendor_Reference_Number__c;
                this.Customer_Vendor = upcRec.Vendor__r.Name;
            } else if(upcRec.Customer__c != null) {
                this.Document_Number = upcRec.Customer_Reference_Number__c;
                this.Customer_Vendor = upcRec.Customer__r.Name;
            }
            this.Transaction_Date = (upcRec.Adjustment_Date__c != null) ? BPUtility.getFormatedDateTime(upcRec.Adjustment_Date__c) : null;
            Decimal cost = upcRec.Total_Cost__c != null ? upcRec.Total_Cost__c : 0;
            if(stiRec != null) {
                Decimal rate = stiRec.Rate__c != null ? stiRec.Rate__c : 0;
                setValues(stiRec.Name__c, cost, (cost * rate/100), 0);
            } else {
                setValues(taxName, 0, 0, cost);
            }
            this.Contents = 'Unit adjustment';
        }

        public TaxReporting(Return_CR_Header__c returnCreditRec, Sales_Tax_Item__c stiRec, String taxName) {
            this.Id = returnCreditRec.Id;
            this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Vendor Credit');
            this.Transaction_Type = 'Vendor Credit';
            if(returnCreditRec.Credited_Date__c != null){
                this.Transaction_Date =  BPUtility.getFormatedDateTime(datetime.newInstance(returnCreditRec.Credited_Date__c.year(), returnCreditRec.Credited_Date__c.month(), returnCreditRec.Credited_Date__c.day()));
            }
            
            this.Document_Number = returnCreditRec.Credit_Memo__c;
            this.Customer_Vendor = returnCreditRec.Vendor__r.Name;

            returnCreditRec.Item_Total__c = (returnCreditRec.Item_Total__c != null ? returnCreditRec.Item_Total__c : 0);
            returnCreditRec.Other_Charges_Total__c = (returnCreditRec.Other_Charges_Total__c != null ? returnCreditRec.Other_Charges_Total__c : 0);
            Decimal nonTaxableOtherCharges = 0;
            for(Other_Charges__c otherCharge : returnCreditRec.Other_Charges__r) {
                if(!otherCharge.Is_Taxable__c) nonTaxableOtherCharges += (otherCharge.Cost__c != null ? otherCharge.Cost__c : 0); 
            }
            Decimal taxableOtherCharges = returnCreditRec.Other_Charges_Total__c - nonTaxableOtherCharges;
            Decimal totalTaxableAmount = returnCreditRec.Item_Total__c + taxableOtherCharges;

            if(stiRec != null) {
                Decimal rate = stiRec.Rate__c != null ? stiRec.Rate__c : 0;
                setValues(stiRec.Name__c, totalTaxableAmount, (totalTaxableAmount * rate/100), nonTaxableOtherCharges);
            } else {
                setValues(taxName, 0, 0, (totalTaxableAmount + nonTaxableOtherCharges));
            }
            this.Contents = 'Parts return';
        }

        public TaxReporting(Customer_Owned_Unit__c unitRec, Sales_Tax_Item__c stiRec, String taxName) {
            this.Id = unitRec.Referenced_Unit__c;
            this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Order Unit');
            this.Transaction_Type = 'Unit Invoice';
            this.Transaction_Date = (unitRec.Date_Stocked_In__c != null) ? BPUtility.getFormatedDateTime(unitRec.Date_Stocked_In__c) : null;
            this.Document_Number = unitRec.Referenced_Unit__r.Invoice_Number__c;
            this.Customer_Vendor = unitRec.Referenced_Unit__r.Vendor__r.Name;
            Decimal taxableCost = unitRec.Referenced_Unit__r.Taxable_Cost__c != null ? unitRec.Referenced_Unit__r.Taxable_Cost__c : 0;
            Decimal totalCost = unitRec.Referenced_Unit__r.Total_Cost__c != null ? unitRec.Referenced_Unit__r.Total_Cost__c : 0;

            if(stiRec != null) {
                Decimal rate = stiRec.Rate__c != null ? stiRec.Rate__c : 0;
                setValues(stiRec.Name__c, taxableCost, (taxableCost * rate/100), (totalCost - taxableCost));
            } else {
                setValues(taxName, 0, 0, totalCost);
            }
            this.Contents = 'Unit purchase';
        }

        private void setValues(String taxName, Decimal taxableAmount, Decimal taxAmount, Decimal nonTaxableAmount) {
            this.Tax_Name = taxName;
            this.Taxable_Amount = taxableAmount != null ? taxableAmount.setScale(2, RoundingMode.HALF_UP) : 0;
            this.Tax_Amount = taxAmount != null ? taxAmount.setScale(2, RoundingMode.HALF_UP) : 0;
            this.Non_Taxable_Amount = nonTaxableAmount != null ? nonTaxableAmount.setScale(2, RoundingMode.HALF_UP) : 0;
        }
    }
    /**
     * Name: AnyObject
     * Description: Sets the Value of Generic type
    **/
    public class AnyObject {
        
        public String Id {get; private set;}
        public Integer Type {get; private set;}
        public String Key {get; private set;}
        public String Summary {get; private set;}
        public String Status {get; private set;}
        public String Owner {get; private set;}
        public String OwnerId {get; private set;}
        public String Modified {get; private set;}
        public String Created {get; private set;}
        
        public AnyObject(Sobject sobjRec) {
            this.Id = String.valueOf(sobjRec.get('Id'));
            String objectName = ((Id)sobjRec.get('Id')).getSObjectType().getDescribe().getName();
            
            this.Modified =  BPUtility.getFormatedDateTime(DateTime.valueOf(String.valueOf(sobjRec.get('LastModifiedDate'))));
            this.Created =  BPUtility.getFormatedDateTime(DateTime.valueOf(String.valueOf(sobjRec.get('CreatedDate'))));
            
            // Checks for the Object and assigns the value accordingly for that object
            if(objectName == 'Account') {
                if(Boolean.valueOf(String.valueOf(sobjRec.get(Constants.NAMESPACE +'Is_Customer__c')))) {
                    this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Customers');
                    
                } else if(Boolean.valueOf(String.valueOf(sobjRec.get(Constants.NAMESPACE +'Is_Vendor__c')))) {
                    this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Vendors');
                }
                
                this.Key = (sobjRec.get('Name') != null) ? String.valueOf(sobjRec.get('Name')) : null;
                this.Status = String.valueOf(sobjRec.get(Constants.NAMESPACE +'Status__c'));
                
            } else if(objectName == Constants.NAMESPACE + 'Part__c') {
                this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Parts');
                this.Key = (sobjRec.get(Constants.NAMESPACE +'Part_Number__c') != null) ? String.valueOf(sobjRec.get(Constants.NAMESPACE +'Part_Number__c')) : null;
                this.Status = (sobjRec.get(Constants.NAMESPACE +'Status__c') != null) ? String.valueOf(sobjRec.get(Constants.NAMESPACE +'Status__c')) : null;
                this.Summary = (sobjRec.get(Constants.NAMESPACE +'Description__c') != null) ? String.valueOf(sobjRec.get(Constants.NAMESPACE +'Description__c')) : null;
                
            } else if(objectName == Constants.NAMESPACE + 'Product__c') {
                this.Id = sobjRec.get(Constants.NAMESPACE + 'Vendor__c') != null ? String.valueOf(sobjRec.get(Constants.NAMESPACE + 'Vendor__c')) : null;
                String productType = (sobjRec.get(Constants.NAMESPACE +'Type__c') != null) ? String.valueOf(sobjRec.get(Constants.NAMESPACE +'Type__c')) : '';
                if(productType == Constants.SUBLET) {
                    this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Sublets');
                } else if(productType == Constants.FINANCING_PRODUCT) {
                    this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Financing Product');
                } else if(productType == Constants.DEAL_PRODUCT) {
                    this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Deal Product');
                } else if(productType == Constants.WARRANTY_PLAN) {
                    this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Warranty Plan');
                }
                this.Key = (sobjRec.get(Constants.NAMESPACE +'Code__c') != null) ? String.valueOf(sobjRec.get(Constants.NAMESPACE +'Code__c')) : null;
                this.Status = (sobjRec.get(Constants.NAMESPACE +'Status__c') != null) ? String.valueOf(sobjRec.get(Constants.NAMESPACE +'Status__c')) : null;
                this.Summary = (sobjRec.get(Constants.NAMESPACE +'Description__c') != null) ? String.valueOf(sobjRec.get(Constants.NAMESPACE +'Description__c')) : null;
                
            } else if(objectName == Constants.NAMESPACE + 'Labour_Code__c') {
                this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Labor Codes');
                this.Key = (sobjRec.get(Constants.NAMESPACE +'Description__c') != null) ? String.valueOf(sobjRec.get(Constants.NAMESPACE +'Description__c')) : null;
                this.Summary = (sobjRec.get(Constants.NAMESPACE +'Description__c') != null) ? String.valueOf(sobjRec.get(Constants.NAMESPACE +'Description__c')) : null;
                this.Status = (sobjRec.get(Constants.NAMESPACE +'Status__c') != null) ? String.valueOf(sobjRec.get(Constants.NAMESPACE +'Status__c')) : null;
            
            } else if(objectName == Constants.NAMESPACE + 'Kit_Header__c') {
                this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Kits');
                this.Key = (sobjRec.get(Constants.NAMESPACE +'Code__c') != null) ? String.valueOf(sobjRec.get(Constants.NAMESPACE +'Code__c')) : null;
                this.Summary = (sobjRec.get(Constants.NAMESPACE +'Description__c') != null) ? String.valueOf(sobjRec.get(Constants.NAMESPACE +'Description__c')) : null;
                this.Status = (sobjRec.get(Constants.NAMESPACE +'Status__c') != null) ? String.valueOf(sobjRec.get(Constants.NAMESPACE +'Status__c')) : null;
            
            } else if(objectName == Constants.NAMESPACE + 'Fee__c') {
                this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Fees');
                this.Key = (sobjRec.get(Constants.NAMESPACE +'Fee_Unique_Name__c') != null) ? String.valueOf(sobjRec.get(Constants.NAMESPACE +'Fee_Unique_Name__c')) : null;
                this.Summary = (sobjRec.get(Constants.NAMESPACE +'Description__c') != null) ? String.valueOf(sobjRec.get(Constants.NAMESPACE +'Description__c')) : null;
                this.Status = (sobjRec.get(Constants.NAMESPACE +'Status__c') != null) ? String.valueOf(sobjRec.get(Constants.NAMESPACE +'Status__c')) : null;
                
            } else if(objectName == 'User') {
                this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Users');
                this.Key = (sobjRec.get('Name') != null) ? String.valueOf(sobjRec.get('Name')) : null;
                this.Status = (sobjRec.get('IsActive') != null) ? String.valueOf(sobjRec.get('IsActive')) : null;
                this.Status = (this.Status.toLowerCase() == 'true') ? 'Active' : 'Inactive';
                this.Summary = (sobjRec.get('Email') != null) ? String.valueOf(sobjRec.get('Email')) : null;
                this.Created = (sobjRec.get(Constants.NAMESPACE + 'CreatedDate__c') != null) ? getFormattedDate(String.valueOf(sobjRec.get(Constants.NAMESPACE + 'CreatedDate__c'))) : null;
                this.Modified = (sobjRec.get(Constants.NAMESPACE + 'LastModifiedDate__c') != null) ? getFormattedDate(String.valueOf(sobjRec.get(Constants.NAMESPACE + 'LastModifiedDate__c'))) : null;
            
            } else if(objectName == Constants.NAMESPACE + 'CO_Header__c') {
                this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Customer Orders');
                this.Key = (sobjRec.get('Name') != null) ? String.valueOf(sobjRec.get('Name')) : null;
                this.Status = (sobjRec.get(Constants.NAMESPACE +'Status__c') != null) ? String.valueOf(sobjRec.get(Constants.NAMESPACE +'Status__c')) : null;
                
            } else if(objectName == Constants.NAMESPACE + 'CO_Invoice_Header__c') {
                this.Id = sobjRec.get(Constants.NAMESPACE + 'CO_Header__c') != null ? String.valueOf(sobjRec.get(Constants.NAMESPACE + 'CO_Header__c')) : null;
                this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Customer Invoices');
                this.Key = (sobjRec.get('Invoice_Number__c') != null) ? String.valueOf(sobjRec.get('Invoice_Number__c')) : null;
                this.Status = (sobjRec.get(Constants.NAMESPACE +'Status__c') != null) ? String.valueOf(sobjRec.get(Constants.NAMESPACE +'Status__c')) : null;
            
            } else if(objectName == Constants.NAMESPACE + 'CO_Invoice_Payment__c' || objectName == Constants.NAMESPACE + 'CO_Deposit__c') {
                this.Id = ((sobjRec.getSobject(Constants.NAMESPACE +'CO_Invoice_Header__r') != null) ? 
                                    String.valueOf(sobjRec.getSobject(Constants.NAMESPACE +'CO_Invoice_Header__r').get('CO_Header__c')) : '');
                this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Customer Payments');
                this.Key = (sobjRec.get('Name') != null) ? String.valueOf(sobjRec.get('Name')) : null;
                this.Status = 'Active';
                if(objectName == Constants.NAMESPACE + 'CO_Deposit__c') {
                    this.Id = sobjRec.get(Constants.NAMESPACE + 'CO_Header__c') != null ? String.valueOf(sobjRec.get(Constants.NAMESPACE + 'CO_Header__c')) : null;
                }
            } else if(objectName == Constants.NAMESPACE + 'Payment_on_Account__c') {
                this.Id = (sobjRec.get('Customer__c') != null) ? String.valueOf(sobjRec.get('Customer__c')) : null;
            	this.Status = '';
                this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Customer Payments');
                this.Key = (sobjRec.get('Name') != null) ? String.valueOf(sobjRec.get('Name')) : null;
                
            } else if(objectName == Constants.NAMESPACE + 'Vendor_Order_Header__c') {
                this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Vendor Orders');
                this.Key = (sobjRec.get('Name') != null) ? String.valueOf(sobjRec.get('Name')) : null;
                this.Status = (sobjRec.get(Constants.NAMESPACE +'Status__c') != null) ? String.valueOf(sobjRec.get(Constants.NAMESPACE +'Status__c')) : null;
                
            }  else if(objectName == Constants.NAMESPACE + 'Return_VO_Header__c') {
                this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Vendor Returns');
                this.Key = (sobjRec.get('Name') != null) ? String.valueOf(sobjRec.get('Name')) : null;
                this.Status = (sobjRec.get(Constants.NAMESPACE +'Status__c') != null) ? String.valueOf(sobjRec.get(Constants.NAMESPACE +'Status__c')) : null;
                
            } else if(objectName == Constants.NAMESPACE + 'Vendor_Receiving_Header__c') {
                this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Vendor Receivings');
                this.Key = (sobjRec.get('Name') != null) ? String.valueOf(sobjRec.get('Name')) : null;
                this.Status = (sobjRec.get(Constants.NAMESPACE +'Status__c') != null) ? String.valueOf(sobjRec.get(Constants.NAMESPACE +'Status__c')) : null;
                
            } else if(objectName == Constants.NAMESPACE + 'Vendor_Invoicing_Header__c') {
                this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Vendor Invoices');
                this.Key = (sobjRec.get('Vendor_Invoice_Number__c') != null) ? String.valueOf(sobjRec.get('Vendor_Invoice_Number__c')) : null;
                this.Status = (sobjRec.get(Constants.NAMESPACE +'Status__c') != null ) ? String.valueOf(sobjRec.get(Constants.NAMESPACE +'Status__c')) : null;
                
            } else if(objectName == Constants.NAMESPACE + 'Category__c') {
                this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Item Categories');
                this.Key = (sobjRec.get(Constants.NAMESPACE +'Unique_Category__c') != null) ? String.valueOf(sobjRec.get(Constants.NAMESPACE +'Unique_Category__c')) : null;
                this.Status = (sobjRec.get(Constants.NAMESPACE +'Status__c') != null) ? String.valueOf(sobjRec.get(Constants.NAMESPACE +'Status__c')) : null;
                this.Summary = (sobjRec.get(Constants.NAMESPACE +'Description__c') != null) ? String.valueOf(sobjRec.get(Constants.NAMESPACE +'Description__c')) : null;
                
            } else if(objectName == Constants.NAMESPACE + 'Price_Level__c') {
                this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Price Levels');
                this.Key = (sobjRec.get(Constants.NAMESPACE +'Name__c') != null) ? String.valueOf(sobjRec.get(Constants.NAMESPACE +'Name__c')) : null;
                this.Status = (sobjRec.get(Constants.NAMESPACE +'Status__c') != null) ? String.valueOf(sobjRec.get(Constants.NAMESPACE +'Status__c')) : null;
                this.Summary = (sobjRec.get(Constants.NAMESPACE +'Description__c') != null) ? String.valueOf(sobjRec.get(Constants.NAMESPACE +'Description__c')) : null;
                
            } else if(objectName == Constants.NAMESPACE + 'Sales_Tax__c') {
                this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Sales Taxes');
                this.Key = (sobjRec.get('Name') != null) ? String.valueOf(sobjRec.get(Constants.NAMESPACE +'Name__c')) : null;
                this.Status = (sobjRec.get(Constants.NAMESPACE +'Status__c') != null) ? String.valueOf(sobjRec.get(Constants.NAMESPACE +'Status__c')) : null;
                this.Summary = (sobjRec.get(Constants.NAMESPACE +'Forms_Label__c') != null) ? String.valueOf(sobjRec.get(Constants.NAMESPACE +'Forms_Label__c')) : null;
            
            } else if(objectName == Constants.NAMESPACE + 'Customer_Owned_Unit__c') {
                if(sobjRec.get(Constants.NAMESPACE +'Unit_Type__c') != null && String.valueOf(sobjRec.get(Constants.NAMESPACE +'Unit_Type__c')) != 'COU') {
                    this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Inventory Unit');
                } else if(sobjRec.get(Constants.NAMESPACE +'Unit_Type__c') != null && String.valueOf(sobjRec.get(Constants.NAMESPACE +'Unit_Type__c')) == 'COU'){
                    this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Customer Unit');
                    String makeName = (sobjRec.get(Constants.NAMESPACE +'Make_Name__c') != null) ? String.valueOf(sobjRec.get(Constants.NAMESPACE +'Make_Name__c')) : '';
                    String modelName = (sobjRec.get(Constants.NAMESPACE +'Model_Name__c') != null) ? String.valueOf(sobjRec.get(Constants.NAMESPACE +'Model_Name__c')) : '';
                    String submodelName = (sobjRec.getSobject(Constants.NAMESPACE + 'Sub_Model__r') != null && sobjRec.getSobject(Constants.NAMESPACE + 'Sub_Model__r').get('Sub_Model_Name__c') != null) ? 
                                            String.valueOf(sobjRec.getSobject(Constants.NAMESPACE +'Sub_Model__r').get('Sub_Model_Name__c')) : '';
                    this.Summary = makeName + ' ' + modelName + ' ' + submodelName;
                }
                this.Key = (sobjRec.get(Constants.NAMESPACE +'Unit_Number__c') != null) ? String.valueOf(sobjRec.get(Constants.NAMESPACE +'Unit_Number__c')) : null;
                this.Status = (sobjRec.get(Constants.NAMESPACE +'Status__c') != null) ? String.valueOf(sobjRec.get(Constants.NAMESPACE +'Status__c')) : null;
                //this.Summary = (sobjRec.get(Constants.NAMESPACE +'Forms_Label__c') != null) ? String.valueOf(sobjRec.get(Constants.NAMESPACE +'Forms_Label__c')) : null;
            
            } else if(objectName == Constants.NAMESPACE + 'Vendor_Order_Line_Item__c') {
                this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Parts Needed');
                this.Key = (sobjRec.get(Constants.NAMESPACE+'Needed_For__c') != null) ? String.valueOf(sobjRec.get(Constants.NAMESPACE + 'Needed_For__c')) : null;
                this.Status = (sobjRec.get(Constants.NAMESPACE +'Status__c') != null) ? String.valueOf(sobjRec.get(Constants.NAMESPACE +'Status__c')) : null;
                //this.Summary = (sobjRec.get(Constants.NAMESPACE +'Forms_Label__c') != null) ? String.valueOf(sobjRec.get(Constants.NAMESPACE +'Forms_Label__c')) : null;
                
                if(sobjRec.get(Constants.NAMESPACE +'Is_required_For_Customer__c') != null && Boolean.valueOf(String.valueOf(sobjRec.get(Constants.NAMESPACE +'Is_required_For_Customer__c'))) 
                    || (sobjRec.get(Constants.NAMESPACE +'Is_Service__c') != null && Boolean.valueOf(String.valueOf(sobjRec.get(Constants.NAMESPACE +'Is_Service__c'))))) {
                
                    this.Id = (sobjRec.get(Constants.NAMESPACE +'CO_Header__c') != null) ? String.valueOf(sobjRec.get(Constants.NAMESPACE +'CO_Header__c')) : null;
                } else {
                    this.Id = (sobjRec.get(Constants.NAMESPACE +'Part__c') != null) ? String.valueOf(sobjRec.get(Constants.NAMESPACE +'Part__c')) : null;
                }
                
            }else if(objectName == Constants.NAMESPACE + 'Deal__c') {
                this.Id = sobjRec.getSobject(Constants.NAMESPACE + 'CO_Header__r') != null ? String.valueOf(sobjRec.get(Constants.NAMESPACE + 'CO_Header__c')) : null;
                this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Unit Deals');
                this.Key = (sobjRec.getSobject(Constants.NAMESPACE + 'CO_Header__r') != null && sobjRec.getSobject(Constants.NAMESPACE + 'CO_Header__r').get('Name') != null) ? String.valueOf(sobjRec.getSobject(Constants.NAMESPACE +'CO_Header__r').get('Name')) : null;
                this.Status = (sobjRec.get(Constants.NAMESPACE +'Status__c') != null) ? String.valueOf(sobjRec.get(Constants.NAMESPACE +'Status__c')) : null;
                if(sobjRec.get(Constants.NAMESPACE +'Type__c') != null){
					if(sobjRec.getSobject(Constants.NAMESPACE +'CO_Header__r').getSobject(Constants.NAMESPACE +'Customer__r') != null && 
			                sobjRec.getSobject(Constants.NAMESPACE +'CO_Header__r').getSobject(Constants.NAMESPACE +'Customer__r').get('Name') != null){
						this.Summary = String.valueOf(sobjRec.get(Constants.NAMESPACE +'Type__c')) + ' ' + String.valueOf(sobjRec.getSobject(Constants.NAMESPACE +'CO_Header__r').getSobject(Constants.NAMESPACE +'Customer__r').get('Name')); 							
					} else {
							this.Summary = String.valueOf(sobjRec.get(Constants.NAMESPACE +'Type__c'));
					}
                
				} else {
					if((sobjRec.getSobject(Constants.NAMESPACE +'CO_Header__r').getSobject(Constants.NAMESPACE +'Customer__r') != null && 
				                sobjRec.getSobject(Constants.NAMESPACE +'CO_Header__r').getSobject(Constants.NAMESPACE +'Customer__r').get('Name') != null)){
						this.Summary = String.valueOf(sobjRec.getSobject(Constants.NAMESPACE +'CO_Header__r').getSobject(Constants.NAMESPACE +'Customer__r').get('Name')); 							
					} else {
						this.Summary = null;
					}
				}			
            }else if(objectName == Constants.NAMESPACE + 'Service_Order_Header__c') {
                this.Id = sobjRec.getSobject(Constants.NAMESPACE + 'CO_Header__r') != null ? String.valueOf(sobjRec.get(Constants.NAMESPACE + 'CO_Header__c')) : null;
                this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Service Jobs');
                this.Key = (sobjRec.getSobject(Constants.NAMESPACE + 'CO_Header__r') != null && sobjRec.getSobject(Constants.NAMESPACE + 'CO_Header__r').get('Name') != null) ? String.valueOf(sobjRec.getSobject(Constants.NAMESPACE +'CO_Header__r').get('Name')) : null;
                this.Status = (sobjRec.get(Constants.NAMESPACE +'SO_Status__c') != null) ? String.valueOf(sobjRec.get(Constants.NAMESPACE +'SO_Status__c')) : null;
                //this.Summary = (sobjRec.get(Constants.NAMESPACE +'Forms_Label__c') != null) ? String.valueOf(sobjRec.get(Constants.NAMESPACE +'Forms_Label__c')) : null;
                if(sobjRec.get(Constants.NAMESPACE + 'SO_Type__c') != null && sobjRec.get(Constants.NAMESPACE + 'SO_Type__c') == Constants.INTERNAL_SERVICE) {
                    this.Summary = Constants.UNIT_INVENTORY;
                } else {
                    this.Summary = (sobjRec.get(Constants.NAMESPACE + 'Name__c') != null) ? sobjRec.get(Constants.NAMESPACE + 'Name__c') + '': '';
                    if((sobjRec.get(Constants.NAMESPACE + 'Name__c') != null) && (sobjRec.getSobject(Constants.NAMESPACE +'CO_Header__r') != null &&  
                            sobjRec.getSobject(Constants.NAMESPACE +'CO_Header__r').getSobject(Constants.NAMESPACE +'Customer__r') != null && 
                            sobjRec.getSobject(Constants.NAMESPACE +'CO_Header__r').getSobject(Constants.NAMESPACE +'Customer__r').get('Name') != null)) {
                        this.Summary += ' - ';
                    }
                    this.Summary += (sobjRec.getSobject(Constants.NAMESPACE +'CO_Header__r') != null &&  
                                    sobjRec.getSobject(Constants.NAMESPACE +'CO_Header__r').getSobject(Constants.NAMESPACE +'Customer__r') != null && 
                                    sobjRec.getSobject(Constants.NAMESPACE +'CO_Header__r').getSobject(Constants.NAMESPACE +'Customer__r').get('Name') != null) ? 
                                            String.valueOf(sobjRec.getSobject(Constants.NAMESPACE +'CO_Header__r').getSobject(Constants.NAMESPACE +'Customer__r').get('Name')) : 
                                            '';
                }
            }
            
            String ownerFieldNameValue;
            String ownerFieldIdValue;
            //system.assert(false, objectName + '  ' + HomeSearchUtil.obejctNameToMapOfSortLabelToAPIName);
            
            String ownerFieldName = HomeSearchUtil.obejctNameToMapOfSortLabelToAPIName.get(objectName).get('Owner');
            List<String> ownerFieldsMap = ownerFieldName.split('\\.');
            
            if( ownerFieldName.contains('CreatedBy') ){
                if(ownerFieldsMap.size() == 1) {
                    ownerFieldNameValue = (String) sobjRec.get(ownerFieldsMap[0]);
                    ownerFieldIdValue = (String) sobjRec.get(ownerFieldsMap[0]);
                } else if(ownerFieldsMap.size() == 2 && sobjRec.getSObject(ownerFieldsMap[0]) != null) {
                    ownerFieldNameValue = (String) sobjRec.getSObject(ownerFieldsMap[0]).get(ownerFieldsMap[1]);
                    ownerFieldIdValue = (String) sobjRec.getSObject(ownerFieldsMap[0]).get('Id');
                }
            } else if( ownerFieldName.contains('Owner') == false ){
                ownerFieldNameValue = String.valueOf(sobjRec.get(ownerFieldName));
                ownerFieldIdValue = String.valueOf(sobjRec.get(ownerFieldName));
            } else if(ownerFieldsMap.size() == 1) {
                ownerFieldNameValue = (String) sobjRec.get(ownerFieldsMap[0]);
                ownerFieldIdValue = (String) sobjRec.get(ownerFieldsMap[0]);
            } else if(ownerFieldsMap.size() == 2) {
                if(sobjRec.getSObject(ownerFieldsMap[0]) != null) {
                    ownerFieldNameValue = (String) sobjRec.getSObject(ownerFieldsMap[0]).get(ownerFieldsMap[1]);
                    ownerFieldIdValue = (String) sobjRec.getSObject(ownerFieldsMap[0]).get('Id');
                }
            } else if(ownerFieldsMap.size() == 3){
                if(sobjRec.getSObject(ownerFieldsMap[0]) != null && sobjRec.getSObject(ownerFieldsMap[0]).getSObject(ownerFieldsMap[1]) != null) {
                    ownerFieldNameValue = (String) sobjRec.getSObject(ownerFieldsMap[0]).getSObject(ownerFieldsMap[1]).get(ownerFieldsMap[2]);
                    ownerFieldIdValue = (String) sobjRec.getSObject(ownerFieldsMap[0]).getSObject(ownerFieldsMap[1]).get('Id');
                }
            } else if(ownerFieldsMap.size() == 4){
                if(sobjRec.getSObject(ownerFieldsMap[0]) != null && sobjRec.getSObject(ownerFieldsMap[0]).getSObject(ownerFieldsMap[1]) != null && sobjRec.getSObject(ownerFieldsMap[0]).getSObject(ownerFieldsMap[1]).getSObject(ownerFieldsMap[2]) != null) {
                    ownerFieldNameValue = (String) sobjRec.getSObject(ownerFieldsMap[0]).getSObject(ownerFieldsMap[1]).getSObject(ownerFieldsMap[2]).get(ownerFieldsMap[3]);
                    ownerFieldIdValue = (String) sobjRec.getSObject(ownerFieldsMap[0]).getSObject(ownerFieldsMap[1]).getSObject(ownerFieldsMap[2]).get('Id');
                }
            }
            this.Owner = ownerFieldNameValue;
            this.OwnerId = ownerFieldIdValue;
            /* 
            if(HomeSearchUtil.objectToOwnerObjectFieldName.containsKey(objectName) && HomeSearchUtil.objectToOwnerObjectFieldName.get(objectName).contains('__c')) {
                String parentObjectFieldName = HomeSearchUtil.objectToOwnerObjectFieldName.get(objectName).split('\\.')[0];
                this.Owner = String.valueOf(sobjRec.getSobject(parentObjectFieldName).getSobject('Owner__r').get('Name'));
                this.OwnerId = String.valueOf(sobjRec.getSobject(parentObjectFieldName).getSobject('Owner__r').get('Id'));
            } else if(HomeSearchUtil.objectToOwnerObjectFieldName.containsKey(objectName)) {
                String parentObjectFieldName = HomeSearchUtil.objectToOwnerObjectFieldName.get(objectName);
                this.Owner = String.valueOf(sobjRec.getSobject(parentObjectFieldName).getSobject('Owner').get('Name'));
                this.OwnerId = String.valueOf(sobjRec.getSobject(parentObjectFieldName).getSobject('Owner').get('Id'));
            } else if(HomeSearchUtil.searchableObjectToFieldsMap.get(objectName).contains('Owner.Name')) {
                this.Owner = (sobjRec.getSobject('Owner') != null && sobjRec.getSobject('Owner').get('Name') != null) ? String.valueOf(sobjRec.getSobject('Owner').get('Name')) : null;
                this.OwnerId = (sobjRec.getSobject('Owner') != null) ? String.valueOf(sobjRec.getSobject('Owner').get('Id')) : null;
            }
            */
        }
        
        public AnyObject(Sobject sobjRec, String searchName) {
        	
            this.Id = String.valueOf(sobjRec.get('Id'));
            String objectName = ((Id)sobjRec.get('Id')).getSObjectType().getDescribe().getName();
            this.Modified =  BPUtility.getFormatedDateTime(DateTime.valueOf(String.valueOf(sobjRec.get('LastModifiedDate'))));
            this.Created =  BPUtility.getFormatedDateTime(DateTime.valueOf(String.valueOf(sobjRec.get('CreatedDate'))));
            // Checks for the Object and assigns the value accordingly for that object
            if(objectName == Constants.NAMESPACE + 'CO_Header__c') {
        		this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Parts Order');
        		this.Status = (sobjRec.get(Constants.NAMESPACE +'Merchandise_Status__c') != null) ? String.valueOf(sobjRec.get(Constants.NAMESPACE +'Merchandise_Status__c')) : 'Active';
        		this.Summary = 'Parts & accessories';
        		if(sobjRec.getSobject(Constants.NAMESPACE +'Customer__r') == null) {
                    if(sobjRec.get(Constants.NAMESPACE +'CO_Type__c') == Constants.CASH_SALE) {
                        this.Summary += ' - ' + Constants.CASH_SALE.toUpperCase();
                    } else if(sobjRec.get(Constants.NAMESPACE +'CO_Type__c') == Constants.INTERNAL_SERVICE) {
                        this.Summary += ' - ' + Constants.UNIT_INVENTORY.toUpperCase();
                    }
                } else {
                    this.Summary  += (sobjRec.getSobject(Constants.NAMESPACE +'Customer__r') != null &&
                    	 sobjRec.getSobject(Constants.NAMESPACE +'Customer__r').get('Name') != null ) ? 
                    	 ' - ' + String.valueOf(sobjRec.getSobject(Constants.NAMESPACE +'Customer__r').get('Name')) : null;
                }
                this.Key = (sobjRec.get('Name') != null) ? String.valueOf(sobjRec.get('Name')) : null;
            } 
            
            String ownerFieldName = HomeSearchUtil.obejctNameToMapOfSortLabelToAPIName.get(objectName).get('Owner');
            List<String> ownerFieldsMap = ownerFieldName.split('\\.');
            
            this.Owner = (String) sobjRec.getSObject(ownerFieldsMap[0]).get(ownerFieldsMap[1]);
            this.OwnerId = (String) sobjRec.getSObject(ownerFieldsMap[0]).get('Id'); 
        }
    }
    
    /**
     * Name: getDateTimeFromString
     * Desc: Get Date Time From String 
     * @param:  (1) dtStr - String - string contain date and time
     * @return: DateTime - date time Object 
    **/
    public static String getFormattedDate(String dtStr) {
        String formattedDateTime;
        if(String.isNotBlank(dtStr)) {
            Date dt = Date.valueOf(dtStr);
            formattedDateTime = BPUtility.getFormatedDateTime(DateTime.newInstance(dt.year(), dt.month(), dt.day()));
        }
        return formattedDateTime;
    } 

    public class VOItems {
        public String Id;
        public String CustomerOrderId;
        public String PartId;
        public Integer Type;
        public String Vendor;
        public String Item_Description;
        public String VO_Number;
        public Decimal Quantity;
        public Decimal Total_Cost;
        public String Ordered;
        public String Expected;
        public String Modified;
        public String Needed_For;
        public String Customer;
        
        public VOItems(Vendor_Order_Line_Item__c voliRec) {
            if(voliRec.Part__c != null) {
                this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('VO Items Parts');
            } else if (voliRec.Sublet__c != null) {
                this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('VO Items Sublets');
            }
            this.Item_Description = voliRec.Item_Description__c;
            this.Id = voliRec.Vendor_Order_Header__r.Id;
            this.Vendor = voliRec.Vendor_Order_Header__r.Vendor__c != null ? voliRec.Vendor_Order_Header__r.Vendor__r.Name : '';
            this.VO_Number = voliRec.Vendor_Order_Header__r.Name;
            this.Quantity = voliRec.Qty_Needed__c != null ? voliRec.Qty_Needed__c : 0;
            this.Total_Cost = voliRec.Total_Cost__c != null ? voliRec.Total_Cost__c : 0;
            this.Ordered = (voliRec.Vendor_Order_Header__r.Ordered_Date__c != null) ? BPUtility.getFormatedDateTime(voliRec.Vendor_Order_Header__r.Ordered_Date__c) : null;
            this.Expected = (voliRec.Vendor_Order_Header__r.Expected_Date_Formula__c != null) ? BPUtility.getFormatedDateTime(voliRec.Vendor_Order_Header__r.Expected_Date_Formula__c) : null;
            this.Modified = BPUtility.getLastModifiedDateStr(voliRec);
            if(voliRec.Is_required_For_Customer__c && !voliRec.Is_Service__c) {
                this.Needed_For = 'Part sale';
                this.CustomerOrderId = voliRec.CO_Header__c != null ? voliRec.CO_Header__r.Id : null;
            } else if(!voliRec.Is_required_For_Customer__c && voliRec.Is_Service__c) {
                this.Needed_For = 'Service';
                this.CustomerOrderId = voliRec.CO_Header__c != null ? voliRec.CO_Header__r.Id : null;
            } else {
                this.Needed_For = 'Stock';
                this.PartId = voliRec.Part__c != null ? voliRec.Part__r.Id : null;
            }
            this.Customer = voliRec.Customer__c;
        }
    }

    public class SubletItems {
        public String CustomerOrderId;
        public String Order_Number;
        public String Customer;
        public Integer Type;
        public String Job;
        public String Job_Status;
        public String Job_Type;
        public String Item_Description;
        public String Sublet_Status;
        public Decimal Total_Price;
        public Decimal Total_Cost;
        public String Expected;
        public String Modified;
        public String Vendor;
        public String VO_Number;
        public String VR_Number;
        public String VI_Number;
        public String VI_Invoice;
        public Decimal Sublet_Accrual;
        
        public SubletItems(Vendor_Order_Line_Item__c voliRec) {
            
            this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Sublet Items');
            this.CustomerOrderId = voliRec.Service_Order_Line_Item__c != null ?  voliRec.Service_Order_Line_Item__r.CO_Header_Id__c : '';
            this.Order_Number = voliRec.CO_Header__c != null ? voliRec.CO_Header__r.Name : '';
            this.Customer = voliRec.Customer__c;
            this.Job = voliRec.Service_Order_Line_Item__r.Service_Order_Header__r.Name__c;
            this.Job_Status = voliRec.Service_Order_Line_Item__r.Service_Order_Header__r.SO_Status__c;
            this.Job_Type = voliRec.Service_Order_Line_Item__r.Service_Order_Header__r.Job_Type__c;
            this.Item_Description = voliRec.Service_Order_Line_Item__r.Item_Desc__c;
            this.Sublet_Status = this.Job_Status == 'Invoiced' ? this.Job_Status : voliRec.Service_Order_Line_Item__r.Status__c;
            this.Total_Cost = voliRec.Total_Cost__c != null ? voliRec.Total_Cost__c : 0;
            if(voliRec.Sublet__c != null) {
                this.Total_Cost = voliRec.Sublet_Calculated_Total_Cost__c;
                this.Sublet_Accrual = voliRec.Sublet_Accrual__c;
            }
            this.Total_Price = voliRec.Service_Order_Line_Item__r.Total_Price_With_Tax__c != null ? voliRec.Service_Order_Line_Item__r.Total_Price_With_Tax__c : 0;
            this.Expected = (voliRec.Vendor_Order_Header__c != null && voliRec.Vendor_Order_Header__r.Expected_Date_Formula__c != null) ? BPUtility.getFormatedDateTime(voliRec.Vendor_Order_Header__r.Expected_Date_Formula__c) : null;
            this.Modified = BPUtility.getLastModifiedDateStr(voliRec);
            this.Vendor = (voliRec.Sublet__c != null && voliRec.Sublet__r.Vendor__c != null) ? voliRec.Sublet__r.Vendor__r.Name : '';
            this.VO_Number = voliRec.Vendor_Order_Header__c != null ? voliRec.Vendor_Order_Header__r.Name : '';
            this.VR_Number = voliRec.Vendor_Receiving_Group__c != null ? voliRec.Vendor_Receiving_Group__r.Vendor_Receiving_Header__r.Name : '';
            this.VI_Number = '';
            this.VI_Invoice = '';
            
        }
    }

    public class ClaimJobs {
        public String Id;
        public String Order_Number;
        public String Customer;
        public Integer Type;
        public String Job;
        public String Job_Status;
        public String Unit_Description;
        public String Item_Description;
        public String Provider;
        public String Claim_Status;
        public Decimal Job_Total;
        public Decimal Deductible;
        public Decimal Claim_Total;
        public String Claim_Number;
        public String Deductible_Invoice;
        public String Claim_Invoice;
        public Decimal Claim_Clearing;
        public Decimal Variance;
        public Decimal Parts;
        public Decimal Labor;
        public Decimal Sublet;
        public Decimal Fees;
        public String Opened;
        public String Modified;
        public String SOId;
        
        public ClaimJobs(Service_Order_Header__c soRec) {
            
            this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Claim Jobs');
            this.Id = soRec.CO_Header__r.Id;
            this.Order_Number = soRec.CO_Header__r.Name;
            this.Customer = soRec.CO_Header__r.Customer_Name__c;
            this.Job = soRec.Name__c;
            this.Job_Status = soRec.SO_Status__c;
            this.Unit_Description = soRec.Customer_Owned_Unit__c != null ? soRec.Customer_Owned_Unit__r.Formatted_Name__c : '';
            this.Provider = soRec.Provider__c != null ? soRec.Provider__r.Name : '';
            this.Claim_Status = soRec.Claim_Status__c != null ? soRec.Claim_Status__c : '';
            this.Job_Total = soRec.Total_With_Tax__c;
            this.Deductible = soRec.Deductible_SO_Payment__c != null ? soRec.Deductible_SO_Payment__r.Total_With_Tax__c: 0;
            this.Claim_Total = soRec.Claimed_Total__c;
            this.Variance = 0;
            if(soRec.Claim__c != null) {
                this.Claim_Number = String.isNotBlank(soRec.Claim__r.Provider_Claim_Number__c) ? soRec.Claim__r.Provider_Claim_Number__c : '';
                this.Claim_Invoice = soRec.Claim_Invoice_Number__c != null ? soRec.Claim_Invoice_Number__c : '';
                this.Variance = soRec.Claim__r.Total_Variance__c != null ? soRec.Claim__r.Total_Variance__c : 0; 
            }
            this.Deductible_Invoice = soRec.Deductible_Invoice_Number__c != null ? soRec.Deductible_Invoice_Number__c : '';
            this.Claim_Clearing = soRec.Claim_Clearing__c;
            this.Parts = soRec.Pre_Tax_Parts_Total__c;
            this.Labor = soRec.Pre_Tax_Labor_Total__c;
            this.Sublet = soRec.Pre_Tax_Sublet_Total__c;
            this.Fees = soRec.Pre_Tax_Total_Fee_With_Shop_Supplies__c;
            this.Opened = (soRec.CreatedDate != null) ? BPUtility.getFormatedDateTime(soRec.CreatedDate) : null;
            this.Modified = BPUtility.getLastModifiedDateStr(soRec);
            this.SOId = soRec.Id;
        }
    }

    public class UnitRegister {
        public Integer Type;
        public String Id;
        public String Stock_Number;
        public String VIN_SN;
        public String Unit_Description;
        public String Plate_Number;
        public String Date_Stocked_In;
        public String How_Acquired;
        public String Reference_Number;
        public String Acquired_From;
        public String Status;
        public String Date_Stocked_Out;
        
        public String Sale_Number;
        public String Sold_To;
        public String Engine_Number;
        public String Acquired_From_Address;
        public String Sold_To_Address;
        public Decimal Acquisition_Cost;
        public Decimal Additional_Costs;
        public Decimal Total_Cost;
        public Decimal Sold_Price;
        public Decimal Profit;
        
        public UnitRegister(Customer_Owned_Unit__c customerUnitRec) {
            this.Type = HomeSearchUtil.displayObjectNameToTypeNumber.get('Customer Unit');
            this.Id = customerUnitRec.Id;
            this.Stock_Number = customerUnitRec.Unit_Number__c;
            this.VIN_SN = customerUnitRec.VIN_Number_Formula__c;
            this.Unit_Description = customerUnitRec.Formatted_Name__c;
            this.Plate_Number = String.isNotBlank(customerUnitRec.Plate__c) ? customerUnitRec.Plate__c : '';
            this.How_Acquired = String.isNotBlank(customerUnitRec.How_Acquired__c) ? customerUnitRec.How_Acquired__c : '';
            this.Reference_Number = String.isNotBlank(customerUnitRec.Reference_Number__c) ? customerUnitRec.Reference_Number__c : '';
            this.Acquired_From = customerUnitRec.Acquired_From__c != null ? customerUnitRec.Acquired_From__r.Name : 'Unknown';
            this.Status = String.isNotBlank(customerUnitRec.Status__c) ? customerUnitRec.Status__c : '';
            if(customerUnitRec.Date_Stocked_In__c != null){
                this.Date_Stocked_In =  BPUtility.getFormatedDateTime(datetime.newInstance(customerUnitRec.Date_Stocked_In__c.year(), customerUnitRec.Date_Stocked_In__c.month(),customerUnitRec.Date_Stocked_In__c.day()));
            }
            if(customerUnitRec.Date_Stocked_Out__c != null){
                this.Date_Stocked_Out =  BPUtility.getFormatedDateTime(datetime.newInstance(customerUnitRec.Date_Stocked_Out__c.year(), customerUnitRec.Date_Stocked_Out__c.month(),customerUnitRec.Date_Stocked_Out__c.day()));
            }
            
            this.Sale_Number = String.isNotBlank(customerUnitRec.Sale_Number__c) ? customerUnitRec.Sale_Number__c : '';
            this.Sold_To = customerUnitRec.Sold_To__c != null ? customerUnitRec.Sold_To__r.Name : '';
            this.Engine_Number = String.isNotBlank(customerUnitRec.Engine_Serial_No__c) ? customerUnitRec.Engine_Serial_No__c : '';
            this.Acquired_From_Address = '';
            if(customerUnitRec.Acquired_From__c != null) {
                String billingStreet = (customerUnitRec.Acquired_From__r.BillingStreet == null ) ? '' : customerUnitRec.Acquired_From__r.BillingStreet;
                List<String> bsList = billingStreet.split('\n');
                this.Acquired_From_Address = (bsList.size() > 0) ? bsList[0].replaceAll('\r', ' ') : '';
                this.Acquired_From_Address += (bsList.size() > 1) ? ' ' + bsList[1].replaceAll('\r', ' ') : '';
                this.Acquired_From_Address += customerUnitRec.Acquired_From__r.BillingCity != null ? ', ' + customerUnitRec.Acquired_From__r.BillingCity : '';
                this.Acquired_From_Address += customerUnitRec.Acquired_From__r.Billing_County_Parish__c != null ? ', ' + customerUnitRec.Acquired_From__r.Billing_County_Parish__c : '';
                this.Acquired_From_Address += customerUnitRec.Acquired_From__r.BillingState != null ? ', ' + customerUnitRec.Acquired_From__r.BillingState : '';
                this.Acquired_From_Address += customerUnitRec.Acquired_From__r.BillingPostalCode != null ? ', ' + customerUnitRec.Acquired_From__r.BillingPostalCode : '';
            }
            this.Sold_To_Address = '';
            if(customerUnitRec.Sold_To__c != null) {
                String billingStreet = (customerUnitRec.Sold_To__r.BillingStreet == null ) ? '' : customerUnitRec.Sold_To__r.BillingStreet;
                List<String> bsList = billingStreet.split('\n');
                this.Sold_To_Address = (bsList.size() > 0) ? bsList[0].replaceAll('\r', ' ') : '';
                this.Sold_To_Address += (bsList.size() > 1) ? ' ' + bsList[1].replaceAll('\r', ' ') : '';
                this.Sold_To_Address += customerUnitRec.Sold_To__r.BillingCity != null ? ', ' + customerUnitRec.Sold_To__r.BillingCity : '';
                this.Sold_To_Address += customerUnitRec.Sold_To__r.Billing_County_Parish__c != null ? ', ' + customerUnitRec.Sold_To__r.Billing_County_Parish__c : '';
                this.Sold_To_Address += customerUnitRec.Sold_To__r.BillingState != null ? ', ' + customerUnitRec.Sold_To__r.BillingState : '';
                this.Sold_To_Address += customerUnitRec.Sold_To__r.BillingPostalCode != null ? ', ' + customerUnitRec.Sold_To__r.BillingPostalCode : '';
            }
            this.Acquisition_Cost = customerUnitRec.Acquisition_Cost__c != null ? customerUnitRec.Acquisition_Cost__c : 0;
            this.Additional_Costs = customerUnitRec.Additional_Costs__c != null ? customerUnitRec.Additional_Costs__c : 0;
            this.Total_Cost = this.Acquisition_Cost + this.Additional_Costs;
            this.Sold_Price = customerUnitRec.Sold_Price__c;
            this.Profit = customerUnitRec.Profit__c;
        }
    }
}