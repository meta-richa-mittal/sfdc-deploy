public without sharing class HomeSearchFilterService {
    public static void setObjectNamesForCustomerInvoiceDetails(Set<String> objectNameSet, HomeSearchFilterWrapper homeSerachFilterObj) {
    	objectNameSet.remove('Customer Invoice Details');
    	Set<String> salesTypeObjectsToSearch = new Set<String>();
    	Set<String> itemTypeObjectsToSearch = new Set<String>();
    	if(homeSerachFilterObj.Selected_Sale_Types != null && homeSerachFilterObj.Selected_Sale_Types.size() > 0 && homeSerachFilterObj.Selected_Sale_Types[0] != 'All') {
        	for(String saleType: homeSerachFilterObj.Selected_Sale_Types) {
        		if(HomeSearchUtil.saleTypeToSearchTypeToWhereClauseStrMap.containsKey(saleType)) {
        			Map<String, String> searchTypeToWhereClauseStrMap = HomeSearchUtil.saleTypeToSearchTypeToWhereClauseStrMap.get(saleType);
        			for(String objName: searchTypeToWhereClauseStrMap.keyset()) {
        				if(!salesTypeObjectsToSearch.contains(objName)) {
        					salesTypeObjectsToSearch.add(objName);
        				}
        			}
        		}
        	}
        } else {
        	salesTypeObjectsToSearch.addAll(HomeSearchUtil.objectsToSearchForCustomerInvoiceDetailsSearch);
        }
        
        if(homeSerachFilterObj.Selected_Item_Types != null && homeSerachFilterObj.Selected_Item_Types.size() > 0 && homeSerachFilterObj.Selected_Item_Types[0] != 'All') {
        	for(String itemType: homeSerachFilterObj.Selected_Item_Types) {
        		if(HomeSearchUtil.itemTypeToSearchTypeToWhereClauseStrMap.containsKey(itemType)) {
        			Map<String, String> searchTypeToWhereClauseStrMap = HomeSearchUtil.itemTypeToSearchTypeToWhereClauseStrMap.get(itemType);
        			for(String objName: searchTypeToWhereClauseStrMap.keyset()) {
        				if(!itemTypeObjectsToSearch.contains(objName)) {
        					itemTypeObjectsToSearch.add(objName);
        				}
        			}
        		}
        	}
        } else {
        	itemTypeObjectsToSearch.addAll(HomeSearchUtil.objectsToSearchForCustomerInvoiceDetailsSearch);
        }
        
        for(String objName: HomeSearchUtil.objectsToSearchForCustomerInvoiceDetailsSearch) {
        	if(salesTypeObjectsToSearch.contains(objName) && itemTypeObjectsToSearch.contains(objName)) {
        		objectNameSet.add(objName);
        	}
        }
    }
    
    public static void setFiltersForCustomerInvoiceDetails(String objName, List<HomeSearchFilterInterface.FieldFilter> filterJSON, HomeSearchFilterWrapper homeSerachFilterObj) {
    	String salesPersonField = '';
    	String invoiceDateField = '';
        String invoiceField = '';
    	if(objName == 'Customer Invoice Details COLI') {
    		filterJSON.add(new HomeSearchFilterInterface.FieldFilter('Service_Order_Line_Item__c', '=', 'null'));
    		filterJSON.add(new HomeSearchFilterInterface.FieldFilter('Invoice_Number__c', '!=', 'null'));
    		
            invoiceDateField = 'Invoice_Number__r.Invoice_Date__c';
            invoiceField = 'Invoice_Number__c';
            salesPersonField = 'Invoice_Number__r.Salesperson__c';
    	} else if(objName == 'Customer Invoice Details SOLI') {
    		filterJSON.add(new HomeSearchFilterInterface.FieldFilter('Service_Order_Header__r.Invoice_Number__c', '!=', 'null'));
    		
            invoiceDateField = 'Service_Order_Header__r.Invoice_Number__r.Invoice_Date__c';
            invoiceField = 'Service_Order_Header__r.Invoice_Number__c';
            salesPersonField = 'Service_Order_Header__r.Salesperson_Names__c';
    	} else if(objName == 'Customer Invoice Details Option and Fee') {
    		filterJSON.add(new HomeSearchFilterInterface.FieldFilter('Deal__r.Invoice_Number__c', '!=', 'null'));
    		
    		invoiceDateField = 'Deal__r.Invoice_Number__r.Invoice_Date__c';
            invoiceField = 'Deal__r.Invoice_Number__c';
    		salesPersonField = 'Deal__r.Salesperson_Name__c';
    	} else if(objName == 'Customer Invoice Details Deal UPC') {
    		filterJSON.add(new HomeSearchFilterInterface.FieldFilter('Deal_Item__r.Deal__r.Invoice_Number__c', '!=', 'null'));
    		
    		invoiceDateField = 'Deal_Item__r.Deal__r.Invoice_Number__r.Invoice_Date__c';
            invoiceField = 'Deal_Item__r.Deal__r.Invoice_Number__c';
    		salesPersonField = 'Deal_Item__r.Deal__r.Salesperson_Name__c';
    	} else if(objName == 'Customer Invoice Details Trade in') {
    		filterJSON.add(new HomeSearchFilterInterface.FieldFilter('Type__c', '=', '\'Trade In\''));
    		filterJSON.add(new HomeSearchFilterInterface.FieldFilter('Deal__r.Invoice_Number__c', '!=', 'null'));
    		
    		invoiceDateField = 'Deal__r.Invoice_Number__r.Invoice_Date__c';
            invoiceField = 'Deal__r.Invoice_Number__c';
    		salesPersonField = 'Deal__r.Salesperson_Name__c';
    	} else if(objName == 'Customer Invoice Details FI Product') {
    		filterJSON.add(new HomeSearchFilterInterface.FieldFilter('Deal_Finance__r.Deal__r.Invoice_Number__c', '!=', 'null'));
    		
    		invoiceDateField = 'Deal_Finance__r.Deal__r.Invoice_Number__r.Invoice_Date__c';
            invoiceField = 'Deal_Finance__r.Deal__r.Invoice_Number__c';
    		salesPersonField = 'Deal_Finance__r.Deal__r.Salesperson_Name__c';
    	} else if(objName == 'Customer Invoice Details Deal Finance') {
    		filterJSON.add(new HomeSearchFilterInterface.FieldFilter('Deal__r.Invoice_Number__c', '!=', 'null'));
    		
    		invoiceDateField = 'Deal__r.Invoice_Number__r.Invoice_Date__c';
            invoiceField = 'Deal__r.Invoice_Number__c';
    		salesPersonField = 'Deal__r.Salesperson_Name__c';
    	} else if(objName == 'Customer Invoice Details Deal') {
            filterJSON.add(new HomeSearchFilterInterface.FieldFilter('Invoice_Number__c', '!=', 'null'));
    		
    		invoiceDateField = 'Invoice_Number__r.Invoice_Date__c';
            invoiceField = 'Invoice_Number__c';
    		salesPersonField = 'Salesperson_Name__c';
        }
    	
    	if(homeSerachFilterObj.Customer_Invoice_Detail_Invoice_Date != null && String.isNotBlank(homeSerachFilterObj.Customer_Invoice_Detail_Invoice_Date.SelectedOption)) {
            List<HomeSearchFilterInterface.FieldFilter> invoiceDateFilterJSON = HomeSearchFilterInterface.getDateFilter(homeSerachFilterObj.Customer_Invoice_Detail_Invoice_Date, invoiceDateField, true, true);
            if(invoiceDateFilterJSON.size() > 0) {
                filterJSON.addAll(invoiceDateFilterJSON);
            }
        }

        if(homeSerachFilterObj.Customer_Invoice_Detail_Invoice_Ids != null && !homeSerachFilterObj.Customer_Invoice_Detail_Invoice_Ids.isEmpty()) {
            String idString = '';
            for(String idStr : homeSerachFilterObj.Customer_Invoice_Detail_Invoice_Ids) {
                idString += '\'' + idStr + '\',';
            }
            idString = idString.removeEnd(',');
            filterJSON.add(new HomeSearchFilterInterface.FieldFilter(invoiceField, 'IN', '(' + idString + ')'));
        }
        
    	if(String.isNotBlank(salesPersonField) && String.isNotBlank(homeSerachFilterObj.Customer_Invoice_Detail_Salesperson)) {
            if(homeSerachFilterObj.Customer_Invoice_Detail_Salesperson.equalsIgnoreCase('Unassigned')) {
                filterJSON.add(new HomeSearchFilterInterface.FieldFilter('(' + salesPersonField, '=', 'null OR ' + salesPersonField + ' = \'\')'));
            } else {
                filterJSON.add(new HomeSearchFilterInterface.FieldFilter(salesPersonField, 'Like', '\'%' +homeSerachFilterObj.Customer_Invoice_Detail_Salesperson + '%\''));
            }
        }
        
        if(homeSerachFilterObj.Selected_Sale_Types != null && homeSerachFilterObj.Selected_Sale_Types.size() > 0 && homeSerachFilterObj.Selected_Sale_Types[0] != 'All') {
        	String saleTypeFilterClause = '(';
        	for(String saleType: homeSerachFilterObj.Selected_Sale_Types) {
        		if(HomeSearchUtil.saleTypeToSearchTypeToWhereClauseStrMap.containsKey(saleType)) {
        			Map<String, String> searchTypeToWhereClauseStrMap = HomeSearchUtil.saleTypeToSearchTypeToWhereClauseStrMap.get(saleType);
        			if(searchTypeToWhereClauseStrMap.containsKey(objName) && String.isNotBlank(searchTypeToWhereClauseStrMap.get(objName))) {
        				saleTypeFilterClause += searchTypeToWhereClauseStrMap.get(objName);
        				saleTypeFilterClause += ' OR ';
        			}
        		}
        	}
        	if(saleTypeFilterClause.length() > 1) {
        		saleTypeFilterClause = saleTypeFilterClause.substring(0, saleTypeFilterClause.length() - 4);
        		saleTypeFilterClause += ')';
        		filterJSON.add(new HomeSearchFilterInterface.FieldFilter('', '', saleTypeFilterClause));
        	}
        }
        
        if(homeSerachFilterObj.Selected_Item_Types != null && homeSerachFilterObj.Selected_Item_Types.size() > 0 && homeSerachFilterObj.Selected_Item_Types[0] != 'All') {
        	String itemTypeFilterClause = '(';
        	for(String itemType: homeSerachFilterObj.Selected_Item_Types) {
        		if(HomeSearchUtil.itemTypeToSearchTypeToWhereClauseStrMap.containsKey(itemType)) {
        			Map<String, String> searchTypeToWhereClauseStrMapForItemType = HomeSearchUtil.itemTypeToSearchTypeToWhereClauseStrMap.get(itemType);
        			if(searchTypeToWhereClauseStrMapForItemType.containsKey(objName) && String.isNotBlank(searchTypeToWhereClauseStrMapForItemType.get(objName))) {
        				itemTypeFilterClause += searchTypeToWhereClauseStrMapForItemType.get(objName);
        				itemTypeFilterClause += ' OR ';
        			}
        		}
        	}
        	if(itemTypeFilterClause.length() > 1) {
        		itemTypeFilterClause = itemTypeFilterClause.substring(0, itemTypeFilterClause.length() - 4);
        		itemTypeFilterClause += ')';
        		filterJSON.add(new HomeSearchFilterInterface.FieldFilter('', '', itemTypeFilterClause));
        	}
        }
    }
    
    public static void serFilterLabelsForCustomerInvoiceDetails(List<HomeSearchFilterInterface.FilterLabel> filterLables, HomeSearchFilterWrapper homeSerachFilterObj) {
    	if(homeSerachFilterObj.Customer_Invoice_Detail_Invoice_Date != null && !String.isBlank(homeSerachFilterObj.Customer_Invoice_Detail_Invoice_Date.SelectedOption) && homeSerachFilterObj.Customer_Invoice_Detail_Invoice_Date.SelectedOption != '0') {
            String modifiedLabelName = HomeSearchFilterInterface.optionValueToModifiedKeyMap.containsKey(homeSerachFilterObj.Customer_Invoice_Detail_Invoice_Date.SelectedOption) ? HomeSearchFilterInterface.optionValueToModifiedKeyMap.get(homeSerachFilterObj.Customer_Invoice_Detail_Invoice_Date.SelectedOption) : homeSerachFilterObj.Customer_Invoice_Detail_Invoice_Date.SelectedOption;
            if(modifiedLabelName == '5' && !String.isBlank(homeSerachFilterObj.Customer_Invoice_Detail_Invoice_Date.Value1) && !String.isBlank(homeSerachFilterObj.Customer_Invoice_Detail_Invoice_Date.Value2)) {
                filterLables.add(new HomeSearchFilterInterface.FilterLabel('Customer_Invoice_Detail_Invoice_Date', 'Invoice Date', homeSerachFilterObj.Customer_Invoice_Detail_Invoice_Date.Value1 + ' To ' + homeSerachFilterObj.Customer_Invoice_Detail_Invoice_Date.Value2));
            } else if(modifiedLabelName != '5') {
                filterLables.add(new HomeSearchFilterInterface.FilterLabel('Customer_Invoice_Detail_Invoice_Date', 'Invoice Date', modifiedLabelName));
            }
        }
        
        if(!String.isBlank(homeSerachFilterObj.Customer_Invoice_Detail_Salesperson)) { 
            filterLables.add(new HomeSearchFilterInterface.FilterLabel('Customer_Invoice_Detail_Salesperson', 'Salesperson', homeSerachFilterObj.Customer_Invoice_Detail_Salesperson));
        }
        
        if(homeSerachFilterObj.Selected_Sale_Types != null && homeSerachFilterObj.Selected_Sale_Types.size() > 0) {
			filterLables.add(HomeSearchFilterInterface.getTagsFilterLabel('Selected_Sale_Types', 'Sale Types', homeSerachFilterObj.Selected_Sale_Types));
    	}
    	
    	if(homeSerachFilterObj.Selected_Item_Types != null && homeSerachFilterObj.Selected_Item_Types.size() > 0) {
			filterLables.add(HomeSearchFilterInterface.getTagsFilterLabel('Selected_Item_Types', 'Item Types', homeSerachFilterObj.Selected_Item_Types));
    	}
    }
	
	public static void setFilterLabelsForPartDetails(List<HomeSearchFilterInterface.FilterLabel> filterLables, HomeSearchFilterWrapper homeSerachFilterObj) {
    	if(homeSerachFilterObj.Part_SalePrice != null && !String.isBlank(homeSerachFilterObj.Part_SalePrice.SelectedOption) && homeSerachFilterObj.Part_SalePrice.SelectedOption != '0') {
            String modifiedLabelName = HomeSearchFilterInterface.optionValueToNumberValueLabelMap.containsKey(homeSerachFilterObj.Part_SalePrice.SelectedOption) ? HomeSearchFilterInterface.optionValueToNumberValueLabelMap.get(homeSerachFilterObj.Part_SalePrice.SelectedOption) : homeSerachFilterObj.Part_SalePrice.SelectedOption;
            if(modifiedLabelName == '5' && !String.isBlank(homeSerachFilterObj.Part_SalePrice.Value1) && !String.isBlank(homeSerachFilterObj.Part_SalePrice.Value2)) {
                filterLables.add(new HomeSearchFilterInterface.FilterLabel('Part_SalePrice', 'Sale Price', homeSerachFilterObj.Part_SalePrice.Value1 + ' To ' + homeSerachFilterObj.Part_SalePrice.Value2));
            } else if(modifiedLabelName != '5') {
                filterLables.add(new HomeSearchFilterInterface.FilterLabel('Part_SalePrice', 'Sale Price', modifiedLabelName + ' ' + homeSerachFilterObj.Part_SalePrice.Value1));
            }
        }
    }
    
    public static void serFilterLabelsForOrderUnit(List<HomeSearchFilterInterface.FilterLabel> filterLables, HomeSearchFilterWrapper homeSerachFilterObj) {
    	if(!String.isBlank(homeSerachFilterObj.Order_Unit_Make) && homeSerachFilterObj.Order_Unit_Make != '0') {   
            filterLables.add(new HomeSearchFilterInterface.FilterLabel('Order_Unit_Make', 'Make', homeSerachFilterObj.Order_Unit_Make));
        }
        if(!String.isBlank(homeSerachFilterObj.Order_Unit_Model) && homeSerachFilterObj.Order_Unit_Model != '0') {   
            filterLables.add(new HomeSearchFilterInterface.FilterLabel('Order_Unit_Model', 'Model', homeSerachFilterObj.Order_Unit_Model));
        }
        if(!String.isBlank(homeSerachFilterObj.Order_Unit_SubModel) && homeSerachFilterObj.Order_Unit_SubModel != '0') {   
            filterLables.add(new HomeSearchFilterInterface.FilterLabel('Order_Unit_SubModel', 'SubModel', homeSerachFilterObj.Order_Unit_SubModel));
        }
        if(!String.isBlank(homeSerachFilterObj.Order_Unit_Year) && homeSerachFilterObj.Order_Unit_Year != '0') {   
            filterLables.add(new HomeSearchFilterInterface.FilterLabel('Order_Unit_Year', 'Year', homeSerachFilterObj.Order_Unit_Year));
        }
        if(!String.isBlank(homeSerachFilterObj.Order_Unit_Unit_ID) && homeSerachFilterObj.Order_Unit_Unit_ID != '0') {   
            filterLables.add(new HomeSearchFilterInterface.FilterLabel('Order_Unit_Unit_ID', 'Unit ID', homeSerachFilterObj.Order_Unit_Unit_ID));
        }
        if(!String.isBlank(homeSerachFilterObj.Order_Unit_Category)) {   
            filterLables.add(new HomeSearchFilterInterface.FilterLabel('Order_Unit_Category', 'Category', homeSerachFilterObj.Order_Unit_Category));
        }
        if(homeSerachFilterObj.Order_Unit_Ordered != null && !String.isBlank(homeSerachFilterObj.Order_Unit_Ordered.SelectedOption) && homeSerachFilterObj.Order_Unit_Ordered.SelectedOption != '0') {
            String modifiedLabelName = HomeSearchFilterInterface.optionValueToModifiedKeyMap.containsKey(homeSerachFilterObj.Order_Unit_Ordered.SelectedOption) ? HomeSearchFilterInterface.optionValueToModifiedKeyMap.get(homeSerachFilterObj.Order_Unit_Ordered.SelectedOption) : homeSerachFilterObj.Order_Unit_Ordered.SelectedOption;
            if( modifiedLabelName == '5'  && !String.isBlank(HomeSerachFilterObj.Order_Unit_Ordered.Value1) && !String.isBlank(homeSerachFilterObj.Order_Unit_Ordered.Value2)) {
                filterLables.add(new HomeSearchFilterInterface.FilterLabel('Order_Unit_Ordered', 'Ordered', homeSerachFilterObj.Order_Unit_Ordered.Value1 + ' To ' + homeSerachFilterObj.Order_Unit_Ordered.Value2));
            } else if(modifiedLabelName != '5'){
                filterLables.add(new HomeSearchFilterInterface.FilterLabel('Order_Unit_Ordered', 'Ordered', modifiedLabelName));
            }
        }
        if(homeSerachFilterObj.Order_Unit_Expected != null && !String.isBlank(homeSerachFilterObj.Order_Unit_Expected.SelectedOption) && homeSerachFilterObj.Order_Unit_Expected.SelectedOption != '0') {
            String modifiedLabelName = HomeSearchFilterInterface.optionValueToModifiedKeyMap.containsKey(homeSerachFilterObj.Order_Unit_Expected.SelectedOption) ? HomeSearchFilterInterface.optionValueToModifiedKeyMap.get(homeSerachFilterObj.Order_Unit_Expected.SelectedOption) : homeSerachFilterObj.Order_Unit_Expected.SelectedOption;
            if( modifiedLabelName == '5'  && !String.isBlank(HomeSerachFilterObj.Order_Unit_Expected.Value1) && !String.isBlank(homeSerachFilterObj.Order_Unit_Expected.Value2)) {
                filterLables.add(new HomeSearchFilterInterface.FilterLabel('Order_Unit_Expected', 'Expected', homeSerachFilterObj.Order_Unit_Expected.Value1 + ' To ' + homeSerachFilterObj.Order_Unit_Expected.Value2));
            } else if(modifiedLabelName != '5'){
                filterLables.add(new HomeSearchFilterInterface.FilterLabel('Order_Unit_Expected', 'Expected', modifiedLabelName));
            }
        }
        if(homeSerachFilterObj.Order_Unit_Days_Out != null && !String.isBlank(homeSerachFilterObj.Order_Unit_Days_Out.SelectedOption) && homeSerachFilterObj.Order_Unit_Days_Out.SelectedOption != '0') {   
            String modifiedLabelName = HomeSearchFilterInterface.optionValueToNumberValueLabelMap.containsKey(homeSerachFilterObj.Order_Unit_Days_Out.SelectedOption) ? HomeSearchFilterInterface.optionValueToNumberValueLabelMap.get(homeSerachFilterObj.Order_Unit_Days_Out.SelectedOption) : homeSerachFilterObj.Order_Unit_Days_Out.SelectedOption;
            if( modifiedLabelName == '5'  && !String.isBlank(HomeSerachFilterObj.Order_Unit_Days_Out.Value1) && !String.isBlank(homeSerachFilterObj.Order_Unit_Days_Out.Value2)) {
               filterLables.add(new HomeSearchFilterInterface.FilterLabel('Order_Unit_Days_Out', 'Days Out', homeSerachFilterObj.Order_Unit_Days_Out.Value1 + ' To ' + homeSerachFilterObj.Order_Unit_Days_Out.Value2));
           } else {
               filterLables.add(new HomeSearchFilterInterface.FilterLabel('Order_Unit_Days_Out', 'Days Out', modifiedLabelName + ' ' + homeSerachFilterObj.Order_Unit_Days_Out.Value1));
           }
        }
        if(!String.isBlank(homeSerachFilterObj.Order_Unit_FO_Number) && homeSerachFilterObj.Order_Unit_FO_Number != '0') {   
            filterLables.add(new HomeSearchFilterInterface.FilterLabel('Order_Unit_FO_Number', 'FO Number', homeSerachFilterObj.Order_Unit_FO_Number));
        }
        if(!String.isBlank(homeSerachFilterObj.Order_Unit_Committed) && homeSerachFilterObj.Order_Unit_Committed != '0') {   
            filterLables.add(new HomeSearchFilterInterface.FilterLabel('Order_Unit_Committed', 'Committed', homeSerachFilterObj.Order_Unit_Committed));
        }
        if(homeSerachFilterObj.Order_Unit_Unit_Cost != null && !String.isBlank(homeSerachFilterObj.Order_Unit_Unit_Cost.SelectedOption) && homeSerachFilterObj.Order_Unit_Unit_Cost.SelectedOption != '0') {
            String modifiedLabelName = HomeSearchFilterInterface.optionValueToNumberValueLabelMap.containsKey(homeSerachFilterObj.Order_Unit_Unit_Cost.SelectedOption) ? HomeSearchFilterInterface.optionValueToNumberValueLabelMap.get(homeSerachFilterObj.Order_Unit_Unit_Cost.SelectedOption) : homeSerachFilterObj.Order_Unit_Unit_Cost.SelectedOption;
            if( modifiedLabelName == '5'  && !String.isBlank(HomeSerachFilterObj.Order_Unit_Unit_Cost.Value1) && !String.isBlank(homeSerachFilterObj.Order_Unit_Unit_Cost.Value2)) {
                filterLables.add(new HomeSearchFilterInterface.FilterLabel('Order_Unit_Unit_Cost', 'Unit Cost', homeSerachFilterObj.Order_Unit_Unit_Cost.Value1 + ' To ' + homeSerachFilterObj.Order_Unit_Unit_Cost.Value2));
            } else {
                filterLables.add(new HomeSearchFilterInterface.FilterLabel('Order_Unit_Unit_Cost', 'Unit Cost', modifiedLabelName + ' ' + homeSerachFilterObj.Order_Unit_Unit_Cost.Value1));
            }
        }
        if(homeSerachFilterObj.Order_Unit_Tax != null && !String.isBlank(homeSerachFilterObj.Order_Unit_Tax.SelectedOption) && homeSerachFilterObj.Order_Unit_Tax.SelectedOption != '0') {
            String modifiedLabelName = HomeSearchFilterInterface.optionValueToNumberValueLabelMap.containsKey(homeSerachFilterObj.Order_Unit_Tax.SelectedOption) ? HomeSearchFilterInterface.optionValueToNumberValueLabelMap.get(homeSerachFilterObj.Order_Unit_Tax.SelectedOption) : homeSerachFilterObj.Order_Unit_Tax.SelectedOption;
            if( modifiedLabelName == '5'  && !String.isBlank(HomeSerachFilterObj.Order_Unit_Tax.Value1) && !String.isBlank(homeSerachFilterObj.Order_Unit_Tax.Value2)) {
                filterLables.add(new HomeSearchFilterInterface.FilterLabel('Order_Unit_Tax', 'Tax', homeSerachFilterObj.Order_Unit_Tax.Value1 + ' To ' + homeSerachFilterObj.Order_Unit_Tax.Value2));
            } else {
                filterLables.add(new HomeSearchFilterInterface.FilterLabel('Order_Unit_Tax', 'Tax', modifiedLabelName + ' ' + homeSerachFilterObj.Order_Unit_Tax.Value1));
            }
        }
        if(homeSerachFilterObj.Order_Unit_Total_Cost != null && !String.isBlank(homeSerachFilterObj.Order_Unit_Total_Cost.SelectedOption) && homeSerachFilterObj.Order_Unit_Total_Cost.SelectedOption != '0') {
            String modifiedLabelName = HomeSearchFilterInterface.optionValueToNumberValueLabelMap.containsKey(homeSerachFilterObj.Order_Unit_Total_Cost.SelectedOption) ? HomeSearchFilterInterface.optionValueToNumberValueLabelMap.get(homeSerachFilterObj.Order_Unit_Total_Cost.SelectedOption) : homeSerachFilterObj.Order_Unit_Total_Cost.SelectedOption;
            if( modifiedLabelName == '5'  && !String.isBlank(HomeSerachFilterObj.Order_Unit_Total_Cost.Value1) && !String.isBlank(homeSerachFilterObj.Order_Unit_Total_Cost.Value2)) {
                filterLables.add(new HomeSearchFilterInterface.FilterLabel('Order_Unit_Total_Cost', 'Total Cost', homeSerachFilterObj.Order_Unit_Total_Cost.Value1 + ' To ' + homeSerachFilterObj.Order_Unit_Total_Cost.Value2));
            } else {
                filterLables.add(new HomeSearchFilterInterface.FilterLabel('Order_Unit_Total_Cost', 'Total Cost', modifiedLabelName + ' ' + homeSerachFilterObj.Order_Unit_Total_Cost.Value1));
            }
        }
        if(homeSerachFilterObj.Order_Unit_Retail_Price != null && !String.isBlank(homeSerachFilterObj.Order_Unit_Retail_Price.SelectedOption) && homeSerachFilterObj.Order_Unit_Retail_Price.SelectedOption != '0') {
            String modifiedLabelName = HomeSearchFilterInterface.optionValueToNumberValueLabelMap.containsKey(homeSerachFilterObj.Order_Unit_Retail_Price.SelectedOption) ? HomeSearchFilterInterface.optionValueToNumberValueLabelMap.get(homeSerachFilterObj.Order_Unit_Retail_Price.SelectedOption) : homeSerachFilterObj.Order_Unit_Retail_Price.SelectedOption;
            if( modifiedLabelName == '5'  && !String.isBlank(HomeSerachFilterObj.Order_Unit_Retail_Price.Value1) && !String.isBlank(homeSerachFilterObj.Order_Unit_Retail_Price.Value2)) {
                filterLables.add(new HomeSearchFilterInterface.FilterLabel('Order_Unit_Retail_Price', 'Retail Price', homeSerachFilterObj.Order_Unit_Retail_Price.Value1 + ' To ' + homeSerachFilterObj.Order_Unit_Retail_Price.Value2));
            } else {
                filterLables.add(new HomeSearchFilterInterface.FilterLabel('Order_Unit_Retail_Price', 'Retail Price', modifiedLabelName + ' ' + homeSerachFilterObj.Order_Unit_Retail_Price.Value1));
            }
        }
        if(!String.isBlank(homeSerachFilterObj.Order_Unit_Vendor) && homeSerachFilterObj.Order_Unit_Vendor != '0') {   
            filterLables.add(new HomeSearchFilterInterface.FilterLabel('Order_Unit_Vendor', 'Vendor', homeSerachFilterObj.Order_Unit_Vendor));
        }
        if(!String.isBlank(homeSerachFilterObj.Order_Unit_VIN) && homeSerachFilterObj.Order_Unit_VIN != '0') {   
            filterLables.add(new HomeSearchFilterInterface.FilterLabel('Order_Unit_VIN', 'VIN', homeSerachFilterObj.Order_Unit_VIN));
        }
        if(!String.isBlank(homeSerachFilterObj.Order_Unit_Stock_Number)) {   
            filterLables.add(new HomeSearchFilterInterface.FilterLabel('Order_Unit_Stock_Number', 'Stock Number', homeSerachFilterObj.Order_Unit_Stock_Number));
        }
        if(!String.isBlank(homeSerachFilterObj.Order_Unit_Ext_Color) && homeSerachFilterObj.Order_Unit_Ext_Color != '0') {   
            filterLables.add(new HomeSearchFilterInterface.FilterLabel('Order_Unit_Ext_Color', 'Ext Color', homeSerachFilterObj.Order_Unit_Ext_Color));
        }
        if(!String.isBlank(homeSerachFilterObj.Order_Unit_Int_Color) && homeSerachFilterObj.Order_Unit_Int_Color != '0') {   
            filterLables.add(new HomeSearchFilterInterface.FilterLabel('Order_Unit_Int_Color', 'Int Color', homeSerachFilterObj.Order_Unit_Int_Color));
        }
    }

	public static void setFilterLabelsForInventoryUnit(List<HomeSearchFilterInterface.FilterLabel> filterLables, HomeSearchFilterWrapper homeSerachFilterObj) {
        if(!String.isBlank(homeSerachFilterObj.Inventory_Unit_VIN)){   
            filterLables.add(new HomeSearchFilterInterface.FilterLabel('Inventory_Unit_VIN', 'VIN', homeSerachFilterObj.Inventory_Unit_VIN));
        }
        if(!String.isBlank(homeSerachFilterObj.Inventory_Unit_Unit_Type) && homeSerachFilterObj.Inventory_Unit_Unit_Type != '0') { 
            String unitType = (homeSerachFilterObj.Inventory_Unit_Unit_Type == 'ORDU') ? 'Order Unit' : 'Stock Unit';
            filterLables.add(new HomeSearchFilterInterface.FilterLabel('Inventory_Unit_Unit_Type', 'Unit Type', unitType));
        }
        if(homeSerachFilterObj.IncludeConsignments) { 
            filterLables.add(new HomeSearchFilterInterface.FilterLabel('IncludeConsignments', 'Include Consignments', 'Yes'));
        }
        if(!String.isBlank(homeSerachFilterObj.Inventory_Unit_Stock_Number)){   
            filterLables.add(new HomeSearchFilterInterface.FilterLabel('Inventory_Unit_Stock_Number', 'Stock Number', homeSerachFilterObj.Inventory_Unit_Stock_Number));
        }
        if(!String.isBlank(homeSerachFilterObj.Inventory_Unit_Year)){   
            filterLables.add(new HomeSearchFilterInterface.FilterLabel('Inventory_Unit_Year', 'Year', homeSerachFilterObj.Inventory_Unit_Year));
        }
        if(!String.isBlank(homeSerachFilterObj.Inventory_Unit_Make) && homeSerachFilterObj.Inventory_Unit_Make != '0'){   
            filterLables.add(new HomeSearchFilterInterface.FilterLabel('Inventory_Unit_Make', 'Make', homeSerachFilterObj.Inventory_Unit_Make));
        }
        if(!String.isBlank(homeSerachFilterObj.Inventory_Unit_Model) && homeSerachFilterObj.Inventory_Unit_Model != '0'){   
            filterLables.add(new HomeSearchFilterInterface.FilterLabel('Inventory_Unit_Model', 'Model', homeSerachFilterObj.Inventory_Unit_Model));
        }
        if(!String.isBlank(homeSerachFilterObj.Inventory_Unit_SubModel) && homeSerachFilterObj.Inventory_Unit_SubModel != '0'){   
            filterLables.add(new HomeSearchFilterInterface.FilterLabel('Inventory_Unit_SubModel', 'SubModel', homeSerachFilterObj.Inventory_Unit_SubModel));
        }
        if(!String.isBlank(homeSerachFilterObj.Inventory_Unit_Ext_Colour)){   
            filterLables.add(new HomeSearchFilterInterface.FilterLabel('Inventory_Unit_Ext_Colour', 'Ext Colour', homeSerachFilterObj.Inventory_Unit_Ext_Colour));
        }
        if(!String.isBlank(homeSerachFilterObj.Inventory_Unit_Vendor)){   
            filterLables.add(new HomeSearchFilterInterface.FilterLabel('Inventory_Unit_Vendor', 'Vendor', homeSerachFilterObj.Inventory_Unit_Vendor));
        }
        if(!String.isBlank(homeSerachFilterObj.Inventory_Unit_New_Unit) && homeSerachFilterObj.Inventory_Unit_New_Unit != '0'){   
            filterLables.add(new HomeSearchFilterInterface.FilterLabel('Inventory_Unit_New_Unit', 'New Unit', homeSerachFilterObj.Inventory_Unit_New_Unit));
        }
        
        if(homeSerachFilterObj.Inventory_Unit_Base_Unit_Price !=null && !String.isBlank(homeSerachFilterObj.Inventory_Unit_Base_Unit_Price.SelectedOption) && homeSerachFilterObj.Inventory_Unit_Base_Unit_Price.SelectedOption != '0') {
            String modifiedLabelName = HomeSearchFilterInterface.optionValueToNumberValueLabelMap.containsKey(homeSerachFilterObj.Inventory_Unit_Base_Unit_Price.SelectedOption) ? HomeSearchFilterInterface.optionValueToNumberValueLabelMap.get(homeSerachFilterObj.Inventory_Unit_Base_Unit_Price.SelectedOption) : homeSerachFilterObj.Inventory_Unit_Base_Unit_Price.SelectedOption;
            if( modifiedLabelName == '5'  && !String.isBlank(HomeSerachFilterObj.Inventory_Unit_Base_Unit_Price.Value1) && !String.isBlank(homeSerachFilterObj.Inventory_Unit_Base_Unit_Price.Value2)) {
                filterLables.add(new HomeSearchFilterInterface.FilterLabel('Inventory_Unit_Base_Unit_Price', 'Base Unit Price', homeSerachFilterObj.Inventory_Unit_Base_Unit_Price.Value1 + ' To ' + homeSerachFilterObj.Inventory_Unit_Base_Unit_Price.Value2));
            } else {
                filterLables.add(new HomeSearchFilterInterface.FilterLabel('Inventory_Unit_Base_Unit_Price', 'Base Unit Price', modifiedLabelName + ' ' + homeSerachFilterObj.Inventory_Unit_Base_Unit_Price.Value1));
            }
        }
        
        if(homeSerachFilterObj.Inventory_Unit_Factory_Options !=null && !String.isBlank(homeSerachFilterObj.Inventory_Unit_Factory_Options.SelectedOption) && homeSerachFilterObj.Inventory_Unit_Factory_Options.SelectedOption != '0') {
            String modifiedLabelName = HomeSearchFilterInterface.optionValueToNumberValueLabelMap.containsKey(homeSerachFilterObj.Inventory_Unit_Factory_Options.SelectedOption) ? HomeSearchFilterInterface.optionValueToNumberValueLabelMap.get(homeSerachFilterObj.Inventory_Unit_Factory_Options.SelectedOption) : homeSerachFilterObj.Inventory_Unit_Factory_Options.SelectedOption;
            if( modifiedLabelName == '5'  && !String.isBlank(HomeSerachFilterObj.Inventory_Unit_Factory_Options.Value1) && !String.isBlank(homeSerachFilterObj.Inventory_Unit_Factory_Options.Value2)) {
                filterLables.add(new HomeSearchFilterInterface.FilterLabel('Inventory_Unit_Factory_Options', 'Factory Options', homeSerachFilterObj.Inventory_Unit_Factory_Options.Value1 + ' To ' + homeSerachFilterObj.Inventory_Unit_Factory_Options.Value2));
            } else {
                filterLables.add(new HomeSearchFilterInterface.FilterLabel('Inventory_Unit_Factory_Options', 'Factory Options', modifiedLabelName + ' ' + homeSerachFilterObj.Inventory_Unit_Factory_Options.Value1));
            }
        }
        
        if(homeSerachFilterObj.Inventory_Unit_Dealer_Options !=null && !String.isBlank(homeSerachFilterObj.Inventory_Unit_Dealer_Options.SelectedOption) && homeSerachFilterObj.Inventory_Unit_Dealer_Options.SelectedOption != '0') {
            String modifiedLabelName = HomeSearchFilterInterface.optionValueToNumberValueLabelMap.containsKey(homeSerachFilterObj.Inventory_Unit_Dealer_Options.SelectedOption) ? HomeSearchFilterInterface.optionValueToNumberValueLabelMap.get(homeSerachFilterObj.Inventory_Unit_Dealer_Options.SelectedOption) : homeSerachFilterObj.Inventory_Unit_Dealer_Options.SelectedOption;
            if( modifiedLabelName == '5'  && !String.isBlank(HomeSerachFilterObj.Inventory_Unit_Dealer_Options.Value1) && !String.isBlank(homeSerachFilterObj.Inventory_Unit_Dealer_Options.Value2)) {
                filterLables.add(new HomeSearchFilterInterface.FilterLabel('Inventory_Unit_Dealer_Options', 'Dealer Options', homeSerachFilterObj.Inventory_Unit_Dealer_Options.Value1 + ' To ' + homeSerachFilterObj.Inventory_Unit_Dealer_Options.Value2));
            } else {
                filterLables.add(new HomeSearchFilterInterface.FilterLabel('Inventory_Unit_Dealer_Options', 'Dealer Options', modifiedLabelName + ' ' + homeSerachFilterObj.Inventory_Unit_Dealer_Options.Value1));
            }
        }
        if(homeSerachFilterObj.Inventory_Unit_Deal_Options_WIP != null && !String.isBlank(homeSerachFilterObj.Inventory_Unit_Deal_Options_WIP.SelectedOption) && homeSerachFilterObj.Inventory_Unit_Deal_Options_WIP.SelectedOption != '0') {
            String modifiedLabelName = HomeSearchFilterInterface.optionValueToNumberValueLabelMap.containsKey(homeSerachFilterObj.Inventory_Unit_Deal_Options_WIP.SelectedOption) ? HomeSearchFilterInterface.optionValueToNumberValueLabelMap.get(homeSerachFilterObj.Inventory_Unit_Deal_Options_WIP.SelectedOption) : homeSerachFilterObj.Inventory_Unit_Deal_Options_WIP.SelectedOption;
            if( modifiedLabelName == '5'  && !String.isBlank(HomeSerachFilterObj.Inventory_Unit_Deal_Options_WIP.Value1) && !String.isBlank(homeSerachFilterObj.Inventory_Unit_Deal_Options_WIP.Value2)) {
                filterLables.add(new HomeSearchFilterInterface.FilterLabel('Inventory_Unit_Deal_Options_WIP', 'Dealer Options WIP', homeSerachFilterObj.Inventory_Unit_Deal_Options_WIP.Value1 + ' To ' + homeSerachFilterObj.Inventory_Unit_Deal_Options_WIP.Value2));
            } else {
                filterLables.add(new HomeSearchFilterInterface.FilterLabel('Inventory_Unit_Deal_Options_WIP', 'Dealer Options WIP', modifiedLabelName + ' ' + homeSerachFilterObj.Inventory_Unit_Deal_Options_WIP.Value1));
            }
        }
        if(homeSerachFilterObj.Inventory_Unit_Base_Unit_Price !=null && !String.isBlank(homeSerachFilterObj.Inventory_Unit_Base_Unit_Price.SelectedOption) && homeSerachFilterObj.Inventory_Unit_Total_Price.SelectedOption != '0') {
            String modifiedLabelName = HomeSearchFilterInterface.optionValueToNumberValueLabelMap.containsKey(homeSerachFilterObj.Inventory_Unit_Total_Price.SelectedOption) ? HomeSearchFilterInterface.optionValueToNumberValueLabelMap.get(homeSerachFilterObj.Inventory_Unit_Total_Price.SelectedOption) : homeSerachFilterObj.Inventory_Unit_Total_Price.SelectedOption;
            if( modifiedLabelName == '5'  && !String.isBlank(HomeSerachFilterObj.Inventory_Unit_Total_Price.Value1) && !String.isBlank(homeSerachFilterObj.Inventory_Unit_Total_Price.Value2)) {
                filterLables.add(new HomeSearchFilterInterface.FilterLabel('Inventory_Unit_Total_Price', 'Total Price', homeSerachFilterObj.Inventory_Unit_Total_Price.Value1 + ' To ' + homeSerachFilterObj.Inventory_Unit_Total_Price.Value2));
            } else {
                filterLables.add(new HomeSearchFilterInterface.FilterLabel('Inventory_Unit_Total_Price', 'Total Price', modifiedLabelName + ' ' + homeSerachFilterObj.Inventory_Unit_Total_Price.Value1));
            }
        }  
        
        if(homeSerachFilterObj.Inventory_Unit_Base_Unit_Cost !=null && !String.isBlank(homeSerachFilterObj.Inventory_Unit_Base_Unit_Cost.SelectedOption) && homeSerachFilterObj.Inventory_Unit_Base_Unit_Cost.SelectedOption != '0') {
            String modifiedLabelName = HomeSearchFilterInterface.optionValueToNumberValueLabelMap.containsKey(homeSerachFilterObj.Inventory_Unit_Base_Unit_Cost.SelectedOption) ? HomeSearchFilterInterface.optionValueToNumberValueLabelMap.get(homeSerachFilterObj.Inventory_Unit_Base_Unit_Cost.SelectedOption) : homeSerachFilterObj.Inventory_Unit_Base_Unit_Cost.SelectedOption;
            if( modifiedLabelName == '5'  && !String.isBlank(HomeSerachFilterObj.Inventory_Unit_Base_Unit_Cost.Value1) && !String.isBlank(homeSerachFilterObj.Inventory_Unit_Base_Unit_Cost.Value2)) {
                filterLables.add(new HomeSearchFilterInterface.FilterLabel('Inventory_Unit_Base_Unit_Cost', 'Base Unit Cost', homeSerachFilterObj.Inventory_Unit_Base_Unit_Cost.Value1 + ' To ' + homeSerachFilterObj.Inventory_Unit_Base_Unit_Cost.Value2));
            } else {
                filterLables.add(new HomeSearchFilterInterface.FilterLabel('Inventory_Unit_Base_Unit_Cost', 'Base Unit Cost', modifiedLabelName + ' ' + homeSerachFilterObj.Inventory_Unit_Base_Unit_Cost.Value1));
            }
        }
        
        if(homeSerachFilterObj.Inventory_Unit_Factory_Option_Cost !=null && !String.isBlank(homeSerachFilterObj.Inventory_Unit_Factory_Option_Cost.SelectedOption) && homeSerachFilterObj.Inventory_Unit_Factory_Option_Cost.SelectedOption != '0') {
            String modifiedLabelName = HomeSearchFilterInterface.optionValueToNumberValueLabelMap.containsKey(homeSerachFilterObj.Inventory_Unit_Factory_Option_Cost.SelectedOption) ? HomeSearchFilterInterface.optionValueToNumberValueLabelMap.get(homeSerachFilterObj.Inventory_Unit_Factory_Option_Cost.SelectedOption) : homeSerachFilterObj.Inventory_Unit_Factory_Option_Cost.SelectedOption;
            if( modifiedLabelName == '5'  && !String.isBlank(HomeSerachFilterObj.Inventory_Unit_Factory_Option_Cost.Value1) && !String.isBlank(homeSerachFilterObj.Inventory_Unit_Factory_Option_Cost.Value2)) {
                filterLables.add(new HomeSearchFilterInterface.FilterLabel('Inventory_Unit_Factory_Option_Cost', 'Factory Option Cost', homeSerachFilterObj.Inventory_Unit_Factory_Option_Cost.Value1 + ' To ' + homeSerachFilterObj.Inventory_Unit_Factory_Option_Cost.Value2));
            } else {
                filterLables.add(new HomeSearchFilterInterface.FilterLabel('Inventory_Unit_Factory_Option_Cost', 'Factory Option Cost', modifiedLabelName + ' ' + homeSerachFilterObj.Inventory_Unit_Factory_Option_Cost.Value1));
            }
        }
        
        if(homeSerachFilterObj.Inventory_Unit_Dealer_Option_Cost !=null && !String.isBlank(homeSerachFilterObj.Inventory_Unit_Dealer_Option_Cost.SelectedOption) && homeSerachFilterObj.Inventory_Unit_Dealer_Option_Cost.SelectedOption != '0') {
            String modifiedLabelName = HomeSearchFilterInterface.optionValueToNumberValueLabelMap.containsKey(homeSerachFilterObj.Inventory_Unit_Dealer_Option_Cost.SelectedOption) ? HomeSearchFilterInterface.optionValueToNumberValueLabelMap.get(homeSerachFilterObj.Inventory_Unit_Dealer_Option_Cost.SelectedOption) : homeSerachFilterObj.Inventory_Unit_Dealer_Option_Cost.SelectedOption;
            if( modifiedLabelName == '5'  && !String.isBlank(HomeSerachFilterObj.Inventory_Unit_Dealer_Option_Cost.Value1) && !String.isBlank(homeSerachFilterObj.Inventory_Unit_Dealer_Option_Cost.Value2)) {
                filterLables.add(new HomeSearchFilterInterface.FilterLabel('Inventory_Unit_Dealer_Option_Cost', 'Dealer Option Cost', homeSerachFilterObj.Inventory_Unit_Dealer_Option_Cost.Value1 + ' To ' + homeSerachFilterObj.Inventory_Unit_Dealer_Option_Cost.Value2));
            } else {
                filterLables.add(new HomeSearchFilterInterface.FilterLabel('Inventory_Unit_Dealer_Option_Cost', 'Dealer Option Cost', modifiedLabelName + ' ' + homeSerachFilterObj.Inventory_Unit_Dealer_Option_Cost.Value1));
            }
        }  
        if(homeSerachFilterObj.Inventory_Unit_Total_Cost !=null && !String.isBlank(homeSerachFilterObj.Inventory_Unit_Total_Cost.SelectedOption) && homeSerachFilterObj.Inventory_Unit_Total_Cost.SelectedOption != '0') {
            String modifiedLabelName = HomeSearchFilterInterface.optionValueToNumberValueLabelMap.containsKey(homeSerachFilterObj.Inventory_Unit_Total_Cost.SelectedOption) ? HomeSearchFilterInterface.optionValueToNumberValueLabelMap.get(homeSerachFilterObj.Inventory_Unit_Total_Cost.SelectedOption) : homeSerachFilterObj.Inventory_Unit_Total_Cost.SelectedOption;
            if( modifiedLabelName == '5'  && !String.isBlank(HomeSerachFilterObj.Inventory_Unit_Total_Cost.Value1) && !String.isBlank(homeSerachFilterObj.Inventory_Unit_Total_Cost.Value2)) {
                filterLables.add(new HomeSearchFilterInterface.FilterLabel('Inventory_Unit_Total_Cost', 'Total Cost', homeSerachFilterObj.Inventory_Unit_Total_Cost.Value1 + ' To ' + homeSerachFilterObj.Inventory_Unit_Total_Cost.Value2));
            } else {
                filterLables.add(new HomeSearchFilterInterface.FilterLabel('Inventory_Unit_Total_Cost', 'Total Cost', modifiedLabelName + ' ' + homeSerachFilterObj.Inventory_Unit_Total_Cost.Value1));
            }
        }              
        if(!String.isBlank(homeSerachFilterObj.Inventory_Unit_Location)){   
            filterLables.add(new HomeSearchFilterInterface.FilterLabel('Inventory_Unit_Location', 'Location', homeSerachFilterObj.Inventory_Unit_Location));
        }
        if(!String.isBlank(homeSerachFilterObj.Inventory_Unit_Category)){   
            filterLables.add(new HomeSearchFilterInterface.FilterLabel('Inventory_Unit_Total_Price', 'Category', homeSerachFilterObj.Inventory_Unit_Category));
        }
        if(homeSerachFilterObj.Inventory_Unit_Stocked_In !=null && !String.isBlank(homeSerachFilterObj.Inventory_Unit_Stocked_In.SelectedOption) && homeSerachFilterObj.Inventory_Unit_Stocked_In.SelectedOption != '0') {
            String modifiedLabelName = HomeSearchFilterInterface.optionValueToModifiedKeyMap.containsKey(homeSerachFilterObj.Inventory_Unit_Stocked_In.SelectedOption) ? HomeSearchFilterInterface.optionValueToModifiedKeyMap.get(homeSerachFilterObj.Inventory_Unit_Stocked_In.SelectedOption) : homeSerachFilterObj.Inventory_Unit_Stocked_In.SelectedOption;
            if( modifiedLabelName == '5'  && !String.isBlank(HomeSerachFilterObj.Inventory_Unit_Stocked_In.Value1) && !String.isBlank(homeSerachFilterObj.Inventory_Unit_Stocked_In.Value2)) {
                filterLables.add(new HomeSearchFilterInterface.FilterLabel('Inventory_Unit_Stocked_In', 'Stocked', homeSerachFilterObj.Inventory_Unit_Stocked_In.Value1 + ' To ' + homeSerachFilterObj.Inventory_Unit_Stocked_In.Value2));
            } else if(modifiedLabelName != '5'){
                filterLables.add(new HomeSearchFilterInterface.FilterLabel('Inventory_Unit_Stocked_In', 'Stocked', modifiedLabelName));
            }
        } 
        
        if(homeSerachFilterObj.Inventory_Unit_Age != null && !String.isBlank(homeSerachFilterObj.Inventory_Unit_Age.SelectedOption) && homeSerachFilterObj.Inventory_Unit_Age.SelectedOption != '0'){   
            String modifiedLabelName = HomeSearchFilterInterface.optionValueToNumberValueLabelMap.containsKey(homeSerachFilterObj.Inventory_Unit_Age.SelectedOption) ? HomeSearchFilterInterface.optionValueToNumberValueLabelMap.get(homeSerachFilterObj.Inventory_Unit_Age.SelectedOption) : homeSerachFilterObj.Inventory_Unit_Age.SelectedOption;
            if( modifiedLabelName == '5'  && !String.isBlank(HomeSerachFilterObj.Inventory_Unit_Age.Value1) && !String.isBlank(homeSerachFilterObj.Inventory_Unit_Age.Value2)) {
               filterLables.add(new HomeSearchFilterInterface.FilterLabel('Inventory_Unit_Age', 'Age', homeSerachFilterObj.Inventory_Unit_Age.Value1 + ' To ' + homeSerachFilterObj.Inventory_Unit_Age.Value2));
           } else {
               filterLables.add(new HomeSearchFilterInterface.FilterLabel('Inventory_Unit_Age', 'Age', modifiedLabelName + ' ' + homeSerachFilterObj.Inventory_Unit_Age.Value1));
           }
        }
       
        if(!String.isBlank(homeSerachFilterObj.Inventory_Unit_Key_Number)){   
            filterLables.add(new HomeSearchFilterInterface.FilterLabel('Inventory_Unit_Key_Number', 'Key Number', homeSerachFilterObj.Inventory_Unit_Key_Number));
        }
        if(!String.isBlank(homeSerachFilterObj.Inventory_Unit_Engine_Number)){   
            filterLables.add(new HomeSearchFilterInterface.FilterLabel('Inventory_Unit_Engine_Number', 'Engine Number', homeSerachFilterObj.Inventory_Unit_Engine_Number));
        }
        if(!String.isBlank(homeSerachFilterObj.Inventory_Unit_Other_Number)){   
            filterLables.add(new HomeSearchFilterInterface.FilterLabel('Inventory_Unit_Other_Number', 'Other Number', homeSerachFilterObj.Inventory_Unit_Other_Number));
        }
        if(!String.isBlank(homeSerachFilterObj.Inventory_Unit_Int_Colour)){   
            filterLables.add(new HomeSearchFilterInterface.FilterLabel('Inventory_Unit_Int_Colour', 'Int Colour', homeSerachFilterObj.Inventory_Unit_Int_Colour));
        }
        
        if(homeSerachFilterObj.Inventory_Unit_Stocked_Out !=null && !String.isBlank(homeSerachFilterObj.Inventory_Unit_Stocked_Out.SelectedOption) && homeSerachFilterObj.Inventory_Unit_Stocked_Out.SelectedOption != '0') {
            String modifiedLabelName = HomeSearchFilterInterface.optionValueToModifiedKeyMap.containsKey(homeSerachFilterObj.Inventory_Unit_Stocked_Out.SelectedOption) ? HomeSearchFilterInterface.optionValueToModifiedKeyMap.get(homeSerachFilterObj.Inventory_Unit_Stocked_Out.SelectedOption) : homeSerachFilterObj.Inventory_Unit_Stocked_Out.SelectedOption;
            if( modifiedLabelName == '5'  && !String.isBlank(HomeSerachFilterObj.Inventory_Unit_Stocked_Out.Value1) && !String.isBlank(homeSerachFilterObj.Inventory_Unit_Stocked_Out.Value2)) {
                filterLables.add(new HomeSearchFilterInterface.FilterLabel('Inventory_Unit_Stocked_Out', 'Stocked Out', homeSerachFilterObj.Inventory_Unit_Stocked_Out.Value1 + ' To ' + homeSerachFilterObj.Inventory_Unit_Stocked_Out.Value2));
            } else if(modifiedLabelName != '5'){
                filterLables.add(new HomeSearchFilterInterface.FilterLabel('Inventory_Unit_Stocked_Out', 'Stocked Out', modifiedLabelName));
            }
        }
        
        if(!String.isBlank(homeSerachFilterObj.Inventory_Unit_Taxable) && homeSerachFilterObj.Inventory_Unit_Taxable != '0') {
            filterLables.add(new HomeSearchFilterInterface.FilterLabel('Inventory_Unit_Taxable', 'Taxable', homeSerachFilterObj.Inventory_Unit_Taxable));
        }
        if(!String.isBlank(homeSerachFilterObj.Inventory_Unit_Applicable_Tax) && homeSerachFilterObj.Inventory_Unit_Taxable != '0') {
            filterLables.add(new HomeSearchFilterInterface.FilterLabel('Inventory_Unit_Applicable_Tax', 'Applicable Tax', homeSerachFilterObj.Inventory_Unit_Applicable_Tax));
        }
        
        if(homeSerachFilterObj.Inventory_Unit_Cylinders !=null && !String.isBlank(homeSerachFilterObj.Inventory_Unit_Cylinders.SelectedOption) && homeSerachFilterObj.Inventory_Unit_Cylinders.SelectedOption != '0') {
            String modifiedLabelName = HomeSearchFilterInterface.optionValueToNumberValueLabelMap.containsKey(homeSerachFilterObj.Inventory_Unit_Cylinders.SelectedOption) ? HomeSearchFilterInterface.optionValueToNumberValueLabelMap.get(homeSerachFilterObj.Inventory_Unit_Cylinders.SelectedOption) : homeSerachFilterObj.Inventory_Unit_Cylinders.SelectedOption;
            if(modifiedLabelName == '5' && !String.isBlank(homeSerachFilterObj.Inventory_Unit_Cylinders.Value1) && !String.isBlank(homeSerachFilterObj.Inventory_Unit_Cylinders.Value2)) {
                filterLables.add(new HomeSearchFilterInterface.FilterLabel('Inventory_Unit_Cylinders', 'Cylinder', homeSerachFilterObj.Inventory_Unit_Cylinders.Value1 + ' To ' + homeSerachFilterObj.Inventory_Unit_Cylinders.Value2));
            } else if(!String.isBlank(homeSerachFilterObj.Inventory_Unit_Cylinders.Value1)){
                filterLables.add(new HomeSearchFilterInterface.FilterLabel('Inventory_Unit_Cylinders', 'Cylinder', modifiedLabelName + ' ' + homeSerachFilterObj.Inventory_Unit_Cylinders.Value1));
            }
        }
        
        if(!String.isBlank(homeSerachFilterObj.Inventory_Unit_Automatic) && homeSerachFilterObj.Inventory_Unit_Automatic != '0'){   
            filterLables.add(new HomeSearchFilterInterface.FilterLabel('Inventory_Unit_Automatic', 'Automatic', homeSerachFilterObj.Inventory_Unit_Automatic));
        }
        
        if(homeSerachFilterObj.Inventory_Unit_Manufactured_Date !=null && !String.isBlank(homeSerachFilterObj.Inventory_Unit_Manufactured_Date.SelectedOption) && homeSerachFilterObj.Inventory_Unit_Manufactured_Date.SelectedOption != '0') {
            String modifiedLabelName = HomeSearchFilterInterface.optionValueToModifiedKeyMap.containsKey(homeSerachFilterObj.Inventory_Unit_Manufactured_Date.SelectedOption) ? HomeSearchFilterInterface.optionValueToModifiedKeyMap.get(homeSerachFilterObj.Inventory_Unit_Manufactured_Date.SelectedOption) : homeSerachFilterObj.Inventory_Unit_Manufactured_Date.SelectedOption;
            if( modifiedLabelName == '5'  && !String.isBlank(HomeSerachFilterObj.Inventory_Unit_Manufactured_Date.Value1) && !String.isBlank(homeSerachFilterObj.Inventory_Unit_Manufactured_Date.Value2)) {
                filterLables.add(new HomeSearchFilterInterface.FilterLabel('Inventory_Unit_Manufactured_Date', 'Manufactured Date', homeSerachFilterObj.Inventory_Unit_Manufactured_Date.Value1 + ' To ' + homeSerachFilterObj.Inventory_Unit_Manufactured_Date.Value2));
            } else if(modifiedLabelName != '5'){
                filterLables.add(new HomeSearchFilterInterface.FilterLabel('Inventory_Unit_Manufactured_Date', 'Manufactured Date', modifiedLabelName));
            }
        }
        
        if(homeSerachFilterObj.Inventory_Unit_Mileage !=null && !String.isBlank(homeSerachFilterObj.Inventory_Unit_Mileage.SelectedOption) && homeSerachFilterObj.Inventory_Unit_Mileage.SelectedOption != '0') {
            String modifiedLabelName = HomeSearchFilterInterface.optionValueToNumberValueLabelMap.containsKey(homeSerachFilterObj.Inventory_Unit_Mileage.SelectedOption) ? HomeSearchFilterInterface.optionValueToNumberValueLabelMap.get(homeSerachFilterObj.Inventory_Unit_Mileage.SelectedOption) : homeSerachFilterObj.Inventory_Unit_Mileage.SelectedOption;
            if(modifiedLabelName == '5' && !String.isBlank(homeSerachFilterObj.Inventory_Unit_Mileage.Value1) && !String.isBlank(homeSerachFilterObj.Inventory_Unit_Mileage.Value2)) {
                filterLables.add(new HomeSearchFilterInterface.FilterLabel('Inventory_Unit_Mileage', 'Mileage', homeSerachFilterObj.Inventory_Unit_Mileage.Value1 + ' To ' + homeSerachFilterObj.Inventory_Unit_Mileage.Value2));
            } else if(!String.isBlank(homeSerachFilterObj.Inventory_Unit_Mileage.Value1)){
                filterLables.add(new HomeSearchFilterInterface.FilterLabel('Inventory_Unit_Mileage', 'Mileage', modifiedLabelName + ' ' + homeSerachFilterObj.Inventory_Unit_Mileage.Value1));
            }
        }
                       
        if(!String.isBlank(homeSerachFilterObj.Inventory_Unit_Plate_Number)){   
            filterLables.add(new HomeSearchFilterInterface.FilterLabel('Inventory_Unit_Plate_Number', 'Plate Number', homeSerachFilterObj.Inventory_Unit_Plate_Number));
        }
        
        if(homeSerachFilterObj.Inventory_Unit_Reg_Expiry !=null && !String.isBlank(homeSerachFilterObj.Inventory_Unit_Reg_Expiry.SelectedOption) && homeSerachFilterObj.Inventory_Unit_Reg_Expiry.SelectedOption != '0') {
            String modifiedLabelName = HomeSearchFilterInterface.optionValueToModifiedKeyMap.containsKey(homeSerachFilterObj.Inventory_Unit_Reg_Expiry.SelectedOption) ? HomeSearchFilterInterface.optionValueToModifiedKeyMap.get(homeSerachFilterObj.Inventory_Unit_Reg_Expiry.SelectedOption) : homeSerachFilterObj.Inventory_Unit_Reg_Expiry.SelectedOption;
            if(modifiedLabelName == '5' && !String.isBlank(homeSerachFilterObj.Inventory_Unit_Reg_Expiry.Value1) && !String.isBlank(homeSerachFilterObj.Inventory_Unit_Reg_Expiry.Value2)) {
                filterLables.add(new HomeSearchFilterInterface.FilterLabel('Inventory_Unit_Reg_Expiry', 'Reg Expiry', homeSerachFilterObj.Inventory_Unit_Reg_Expiry.Value1 + ' To ' + homeSerachFilterObj.Inventory_Unit_Reg_Expiry.Value2));
            } else if(modifiedLabelName != '5') {
                filterLables.add(new HomeSearchFilterInterface.FilterLabel('Inventory_Unit_Reg_Expiry', 'Reg Expiry', modifiedLabelName));
            }
        }
        
        if(homeSerachFilterObj.AssignedTags != null && homeSerachFilterObj.AssignedTags.size() > 0) {
            filterLables.add(HomeSearchFilterInterface.getTagsFilterLabel(homeSerachFilterObj.AssignedTags));        }
        
        if(!String.isBlank(homeSerachFilterObj.Inventory_Unit_Compliance_Date) && homeSerachFilterObj.Inventory_Unit_Compliance_Date != '0'){   
            filterLables.add(new HomeSearchFilterInterface.FilterLabel('Inventory_Unit_Compliance_Date', 'Compliance Date', homeSerachFilterObj.Inventory_Unit_Compliance_Date));
        }
        if(!String.isBlank(homeSerachFilterObj.Inventory_Unit_Year_Of_1st_Rego) && homeSerachFilterObj.Inventory_Unit_Year_Of_1st_Rego != '0'){   
            filterLables.add(new HomeSearchFilterInterface.FilterLabel('Inventory_Unit_Year_Of_1st_Rego', 'Year of 1st Rego', homeSerachFilterObj.Inventory_Unit_Year_Of_1st_Rego));
        }
        if(!String.isBlank(homeSerachFilterObj.Inventory_Unit_Registration_Serial) && homeSerachFilterObj.Inventory_Unit_Registration_Serial != '0'){   
            filterLables.add(new HomeSearchFilterInterface.FilterLabel('Inventory_Unit_Registration_Serial', 'Registration Serial#', homeSerachFilterObj.Inventory_Unit_Registration_Serial));
        }
        if(homeSerachFilterObj.Inventory_Unit_NITC_Withheld !=null && !String.isBlank(homeSerachFilterObj.Inventory_Unit_NITC_Withheld.SelectedOption) && homeSerachFilterObj.Inventory_Unit_NITC_Withheld.SelectedOption != '0') {
            String modifiedLabelName = HomeSearchFilterInterface.optionValueToNumberValueLabelMap.containsKey(homeSerachFilterObj.Inventory_Unit_NITC_Withheld.SelectedOption) ? HomeSearchFilterInterface.optionValueToNumberValueLabelMap.get(homeSerachFilterObj.Inventory_Unit_NITC_Withheld.SelectedOption) : homeSerachFilterObj.Inventory_Unit_NITC_Withheld.SelectedOption;
            if( modifiedLabelName == '5'  && !String.isBlank(HomeSerachFilterObj.Inventory_Unit_NITC_Withheld.Value1) && !String.isBlank(homeSerachFilterObj.Inventory_Unit_NITC_Withheld.Value2)) {
                filterLables.add(new HomeSearchFilterInterface.FilterLabel('Inventory_Unit_NITC_Withheld', 'NITC Withheld', homeSerachFilterObj.Inventory_Unit_NITC_Withheld.Value1 + ' To ' + homeSerachFilterObj.Inventory_Unit_NITC_Withheld.Value2));
            } else {
                filterLables.add(new HomeSearchFilterInterface.FilterLabel('Inventory_Unit_NITC_Withheld', 'NITC Withheld', modifiedLabelName + ' ' + homeSerachFilterObj.Inventory_Unit_NITC_Withheld.Value1));
            }
        } 
        if(homeSerachFilterObj.Inventory_Unit_In_Stock_As_Of != null && String.isNotBlank(homeSerachFilterObj.Inventory_Unit_In_Stock_As_Of.SelectedOption) && homeSerachFilterObj.Inventory_Unit_In_Stock_As_Of.SelectedOption != '0' && String.isNotBlank(homeSerachFilterObj.Inventory_Unit_In_Stock_As_Of.Value1)) { 
            filterLables.add(new HomeSearchFilterInterface.FilterLabel('Inventory_Unit_In_Stock_As_Of', 'In Stock As Of', homeSerachFilterObj.Inventory_Unit_In_Stock_As_Of.Value1));
        }
    }

	public static void setFilterLabelsForPublishInFeeds(List<HomeSearchFilterInterface.FilterLabel> filterLables, HomeSearchFilterWrapper homeSerachFilterObj) {
		if(!String.isBlank(homeSerachFilterObj.Part_PublishInFeeds) && homeSerachFilterObj.Part_PublishInFeeds != '0') {
            if(homeSerachFilterObj.Part_PublishInFeeds == '1') {
                filterLables.add(new HomeSearchFilterInterface.FilterLabel('Part_PublishInFeeds', 'Publish In Feeds', 'Yes'));
            } else if(homeSerachFilterObj.Part_PublishInFeeds == '2'){
                filterLables.add(new HomeSearchFilterInterface.FilterLabel('Part_PublishInFeeds', 'Publish In Feeds', 'No'));
            }
        }
	}
    
    public static void setFilterLabelsForVOItems(List<HomeSearchFilterInterface.FilterLabel> filterLables, HomeSearchFilterWrapper homeSerachFilterObj) {
    	if(homeSerachFilterObj.VO_Items_Quantity != null && String.isNotBlank(homeSerachFilterObj.VO_Items_Quantity.SelectedOption) && homeSerachFilterObj.VO_Items_Quantity.SelectedOption != '0') {
            String modifiedLabelName = HomeSearchFilterInterface.optionValueToNumberValueLabelMap.containsKey(homeSerachFilterObj.VO_Items_Quantity.SelectedOption) ? HomeSearchFilterInterface.optionValueToNumberValueLabelMap.get(homeSerachFilterObj.VO_Items_Quantity.SelectedOption) : homeSerachFilterObj.VO_Items_Quantity.SelectedOption;
            if(modifiedLabelName == '5' && String.isNotBlank(homeSerachFilterObj.VO_Items_Quantity.Value1) && String.isNotBlank(homeSerachFilterObj.VO_Items_Quantity.Value2)) {
                filterLables.add(new HomeSearchFilterInterface.FilterLabel('VO_Items_Quantity', 'Quantity', homeSerachFilterObj.VO_Items_Quantity.Value1 + ' To ' + homeSerachFilterObj.VO_Items_Quantity.Value2));
            } else if(modifiedLabelName != '5') {
                filterLables.add(new HomeSearchFilterInterface.FilterLabel('VO_Items_Quantity', 'Quantity', modifiedLabelName + ' ' + homeSerachFilterObj.VO_Items_Quantity.Value1));
            }
        }
        if(homeSerachFilterObj.VO_Items_Total_Cost != null && String.isNotBlank(homeSerachFilterObj.VO_Items_Total_Cost.SelectedOption) && homeSerachFilterObj.VO_Items_Total_Cost.SelectedOption != '0') {
            String modifiedLabelName = HomeSearchFilterInterface.optionValueToNumberValueLabelMap.containsKey(homeSerachFilterObj.VO_Items_Total_Cost.SelectedOption) ? HomeSearchFilterInterface.optionValueToNumberValueLabelMap.get(homeSerachFilterObj.VO_Items_Total_Cost.SelectedOption) : homeSerachFilterObj.VO_Items_Total_Cost.SelectedOption;
            if(modifiedLabelName == '5' && String.isNotBlank(homeSerachFilterObj.VO_Items_Total_Cost.Value1) && String.isNotBlank(homeSerachFilterObj.VO_Items_Total_Cost.Value2)) {
                filterLables.add(new HomeSearchFilterInterface.FilterLabel('VO_Items_Total_Cost', 'Total Cost', homeSerachFilterObj.VO_Items_Total_Cost.Value1 + ' To ' + homeSerachFilterObj.VO_Items_Total_Cost.Value2));
            } else if(modifiedLabelName != '5') {
                filterLables.add(new HomeSearchFilterInterface.FilterLabel('VO_Items_Total_Cost', 'Total Cost', modifiedLabelName + ' ' + homeSerachFilterObj.VO_Items_Total_Cost.Value1));
            }
        }
        if(homeSerachFilterObj.VO_Items_Ordered !=null && String.isNotBlank(homeSerachFilterObj.VO_Items_Ordered.SelectedOption) && homeSerachFilterObj.VO_Items_Ordered.SelectedOption != '0') {
            String modifiedLabelName = HomeSearchFilterInterface.optionValueToModifiedKeyMap.containsKey(homeSerachFilterObj.VO_Items_Ordered.SelectedOption) ? HomeSearchFilterInterface.optionValueToModifiedKeyMap.get(homeSerachFilterObj.VO_Items_Ordered.SelectedOption) : homeSerachFilterObj.VO_Items_Ordered.SelectedOption;
            if(modifiedLabelName == '5' && String.isNotBlank(homeSerachFilterObj.VO_Items_Ordered.Value1) && String.isNotBlank(homeSerachFilterObj.VO_Items_Ordered.Value2)) {
                filterLables.add(new HomeSearchFilterInterface.FilterLabel('VO_Items_Ordered', 'Ordered', homeSerachFilterObj.VO_Items_Ordered.Value1 + ' To ' + homeSerachFilterObj.VO_Items_Ordered.Value2));
            } else if(modifiedLabelName != '5') {
                filterLables.add(new HomeSearchFilterInterface.FilterLabel('VO_Items_Ordered', 'Ordered', modifiedLabelName));
            }
        }
        if(homeSerachFilterObj.VO_Items_Expected !=null && String.isNotBlank(homeSerachFilterObj.VO_Items_Expected.SelectedOption) && homeSerachFilterObj.VO_Items_Expected.SelectedOption != '0') {
            String modifiedLabelName = HomeSearchFilterInterface.optionValueToModifiedKeyMap.containsKey(homeSerachFilterObj.VO_Items_Expected.SelectedOption) ? HomeSearchFilterInterface.optionValueToModifiedKeyMap.get(homeSerachFilterObj.VO_Items_Expected.SelectedOption) : homeSerachFilterObj.VO_Items_Expected.SelectedOption;
            if(modifiedLabelName == '5' && String.isNotBlank(homeSerachFilterObj.VO_Items_Expected.Value1) && String.isNotBlank(homeSerachFilterObj.VO_Items_Expected.Value2)) {
                filterLables.add(new HomeSearchFilterInterface.FilterLabel('VO_Items_Expected', 'Expected', homeSerachFilterObj.VO_Items_Expected.Value1 + ' To ' + homeSerachFilterObj.VO_Items_Expected.Value2));
            } else if(modifiedLabelName != '5') {
                filterLables.add(new HomeSearchFilterInterface.FilterLabel('VO_Items_Expected', 'Expected', modifiedLabelName));
            }
        }
        if(String.isNotBlank(homeSerachFilterObj.VO_Items_Needed_For) && homeSerachFilterObj.VO_Items_Needed_For != '0'){   
            filterLables.add(new HomeSearchFilterInterface.FilterLabel('VO_Items_Needed_For', 'Needed For', homeSerachFilterObj.VO_Items_Needed_For));
        } 
        if(String.isNotBlank(homeSerachFilterObj.VO_Items_Customer)) {
            filterLables.add(new HomeSearchFilterInterface.FilterLabel('VO_Items_Customer', 'Customer', homeSerachFilterObj.VO_Items_Customer));
        }
        if(String.isNotBlank(homeSerachFilterObj.VO_Items_Vendor)) {
            filterLables.add(new HomeSearchFilterInterface.FilterLabel('VO_Items_Vendor', 'Vendor', homeSerachFilterObj.VO_Items_Vendor));
        }
        if(String.isNotBlank(homeSerachFilterObj.VO_Items_Item_Description)) {
            filterLables.add(new HomeSearchFilterInterface.FilterLabel('VO_Items_Item_Description', 'Item Description', homeSerachFilterObj.VO_Items_Item_Description));
        }
        if(String.isNotBlank(homeSerachFilterObj.VO_Items_VO_Number)) {
            filterLables.add(new HomeSearchFilterInterface.FilterLabel('VO_Items_VO_Number', 'VO Number', homeSerachFilterObj.VO_Items_VO_Number));
        }
    }


    public static void setFilterJSONForSubletItems(List<HomeSearchFilterInterface.FieldFilter> filterJSON, HomeSearchFilterWrapper homeSerachFilterObj) {
    	filterJSON.add(new HomeSearchFilterInterface.FieldFilter('Sublet__c', '!=', null));
        filterJSON.add(new HomeSearchFilterInterface.FieldFilter('Service_Order_Line_Item__c', '!=', null));
        if(String.isNotBlank(homeSerachFilterObj.Sublet_Items_Order_Number)) {
            filterJSON.add(new HomeSearchFilterInterface.FieldFilter('CO_Header__r.Name', 'Like', '\'' +homeSerachFilterObj.Sublet_Items_Order_Number + '%\''));
        }
        if(String.isNotBlank(homeSerachFilterObj.Sublet_Items_Customer)) {
            filterJSON.add(new HomeSearchFilterInterface.FieldFilter('Customer__c', 'Like', '\'%' +homeSerachFilterObj.Sublet_Items_Customer + '%\''));
        }
        if(String.isNotBlank(homeSerachFilterObj.Sublet_Items_Job_Status) && homeSerachFilterObj.Sublet_Items_Job_Status != '0') {
            if(ServiceJobUtil.jobStatusGroupToExcludedValueMap.containsKey(homeSerachFilterObj.Sublet_Items_Job_Status)) {
                String filterValues = ' (';
                for(String value : ServiceJobUtil.jobStatusGroupToExcludedValueMap.get(homeSerachFilterObj.Sublet_Items_Job_Status)) {
                    filterValues += ' \'' + value + '\',' ;
                }
                filterValues = filterValues.substring(0, filterValues.length()-1) + ' )';
                filterJSON.add(new HomeSearchFilterInterface.FieldFilter('', '', 'Service_Order_Line_Item__r.Service_Order_Header__r.SO_Status__c NOT IN ' + filterValues));
            } else if(homeSerachFilterObj.Sublet_Items_Job_Status.equalsIgnoreCase(ServiceJobUtil.COMPLETED)) {
                String filterValues = ' (';
                for(String value : ServiceJobUtil.invoiceableStatusSet) {
                    filterValues += ' \'' + value + '\',' ;
                }
                filterValues = filterValues.substring(0, filterValues.length()-1) + ' )';
                filterJSON.add(new HomeSearchFilterInterface.FieldFilter('', '', 'Service_Order_Line_Item__r.Service_Order_Header__r.SO_Status__c IN ' + filterValues));
            } else {
                filterJSON.add(new HomeSearchFilterInterface.FieldFilter('Service_Order_Line_Item__r.Service_Order_Header__r.SO_Status__c', '=', '\'' + homeSerachFilterObj.Sublet_Items_Job_Status + '\''));
            }
        }
        if(String.isNotBlank(homeSerachFilterObj.Sublet_Items_Job_Type) && homeSerachFilterObj.Sublet_Items_Job_Type != '0') {
            filterJSON.add(new HomeSearchFilterInterface.FieldFilter('Service_Order_Line_Item__r.Service_Order_Header__r.Job_Type__c', 'Like', '\'' +homeSerachFilterObj.Sublet_Items_Job_Type + '%\''));
        }
        if(String.isNotBlank(homeSerachFilterObj.Sublet_Items_Vendor)) {
            filterJSON.add(new HomeSearchFilterInterface.FieldFilter('Sublet__r.Vendor__r.Name', 'Like', '\'' +homeSerachFilterObj.Sublet_Items_Vendor + '%\''));
        }
        if(String.isNotBlank(homeSerachFilterObj.Sublet_Items_VO_Number)) {
            filterJSON.add(new HomeSearchFilterInterface.FieldFilter('Vendor_Order_Header__r.Name', 'Like', '\'%' +homeSerachFilterObj.Sublet_Items_VO_Number + '%\''));
        }
        if(String.isNotBlank(homeSerachFilterObj.Sublet_Items_VR_Number)) {
            filterJSON.add(new HomeSearchFilterInterface.FieldFilter('Vendor_Receiving_Group__r.Vendor_Receiving_Header__r.Name', 'Like', '\'%' +homeSerachFilterObj.Sublet_Items_VR_Number + '%\''));
        }
        if(String.isNotBlank(homeSerachFilterObj.Sublet_Items_VI_Number)) {
            List<Vendor_Invoicing_Group__c> vigList = [Select Vendor_Receiving_Group__c FROM Vendor_Invoicing_Group__c Where Vendor_Receiving_Group__r.Sublet__c != null AND Vendor_Invoicing_Header__r.Name Like :('%' +homeSerachFilterObj.Sublet_Items_VI_Number + '%')];
            List<String> vegList = new List<String>();
            for(Vendor_Invoicing_Group__c vigRec : vigList) {
                if(vigRec.Vendor_Receiving_Group__c != null) {
                    vegList.add(vigRec.Vendor_Receiving_Group__c);
                }
            }
            if(vegList.isEmpty()) {
                filterJSON.add(new HomeSearchFilterInterface.FieldFilter('Vendor_Receiving_Group__c', '=', null));
            } else{
                String idString = '';
                for(String idStr : vegList) {
                    idString += '\'' + idStr + '\',';
                }
                idString = idString.removeEnd(',');
                filterJSON.add(new HomeSearchFilterInterface.FieldFilter('Vendor_Receiving_Group__c', 'IN', '('+ idString +')'));
            }
            filterJSON.add(new HomeSearchFilterInterface.FieldFilter('Vendor_Receiving_Group__c', '!=', null));
        }
        if(String.isNotBlank(homeSerachFilterObj.Sublet_Items_Sublet_Status)){   
            if(homeSerachFilterObj.Sublet_Items_Sublet_Status == '0') {
                filterJSON.add(new HomeSearchFilterInterface.FieldFilter('Service_Order_Line_Item__r.Service_Order_Header__r.SO_Status__c', '!=', '\''+ServicejobUtil.INVOICED+'\''));
            } else if(homeSerachFilterObj.Sublet_Items_Sublet_Status == 'Invoiced') {
                filterJSON.add(new HomeSearchFilterInterface.FieldFilter('Service_Order_Line_Item__r.Service_Order_Header__r.SO_Status__c', '=', '\''+ServicejobUtil.INVOICED+'\''));
            } else {
                filterJSON.add(new HomeSearchFilterInterface.FieldFilter('Service_Order_Line_Item__r.Status__c', '=', '\'' +homeSerachFilterObj.Sublet_Items_Sublet_Status + '\''));
                filterJSON.add(new HomeSearchFilterInterface.FieldFilter('Service_Order_Line_Item__r.Service_Order_Header__r.SO_Status__c', '!=', '\''+ServicejobUtil.INVOICED+'\''));
            }
        }
        if(homeSerachFilterObj.Sublet_Items_Expected != null && !String.isBlank(homeSerachFilterObj.Sublet_Items_Expected.SelectedOption) && homeSerachFilterObj.VO_Items_Expected.SelectedOption != '0') {
            List<HomeSearchFilterInterface.FieldFilter> expectedFilterJSON = HomeSearchFilterInterface.getDateFilter(homeSerachFilterObj.Sublet_Items_Expected, 'Vendor_Order_Header__r.Expected_Date_Formula__c', false);
            if(expectedFilterJSON.size() > 0) {  
                filterJSON.addAll(expectedFilterJSON);
            }
        }
        if(homeSerachFilterObj.Sublet_Items_Total_Price != null && !String.isBlank(homeSerachFilterObj.Sublet_Items_Total_Price.SelectedOption) && homeSerachFilterObj.VO_Items_Quantity.SelectedOption != '0'){
            List<HomeSearchFilterInterface.FieldFilter> numericFilterList = HomeSearchFilterInterface.getNumericFilter(homeSerachFilterObj.Sublet_Items_Total_Price, 'Service_Order_Line_Item__r.Total_Price_With_Tax__c');
            if(numericFilterList.size() > 0) {
                filterJSON.addAll(numericFilterList);
            }
        }
        if(homeSerachFilterObj.Sublet_Items_Total_Cost != null && !String.isBlank(homeSerachFilterObj.Sublet_Items_Total_Cost.SelectedOption) && homeSerachFilterObj.VO_Items_Total_Cost.SelectedOption != '0'){
            List<HomeSearchFilterInterface.FieldFilter> numericFilterList = HomeSearchFilterInterface.getNumericFilter(homeSerachFilterObj.Sublet_Items_Total_Cost, 'Total_Cost__c');
            if(numericFilterList.size() > 0) {
                filterJSON.addAll(numericFilterList);
            }
        }
    }

    public static void setFilterJSONForClaimJobs(List<HomeSearchFilterInterface.FieldFilter> filterJSON, HomeSearchFilterWrapper homeSerachFilterObj) {
        filterJSON.add(new HomeSearchFilterInterface.FieldFilter('Transaction_Type__r.Type__c', '=', '\'Third-Party\''));
        if(String.isNotBlank(homeSerachFilterObj.Claim_Jobs_Provider)) {
            filterJSON.add(new HomeSearchFilterInterface.FieldFilter('Provider__r.Name', 'Like', '\'' +homeSerachFilterObj.Claim_Jobs_Provider + '%\''));
        }
        if(String.isNotBlank(homeSerachFilterObj.Claim_Jobs_Claim_Status) && homeSerachFilterObj.Claim_Jobs_Claim_Status != '0') {
            filterJSON.add(new HomeSearchFilterInterface.FieldFilter('Claim_Status__c', '=', '\'' +homeSerachFilterObj.Claim_Jobs_Claim_Status + '\''));
        }
        if(homeSerachFilterObj.Claim_Jobs_Variance != null && !String.isBlank(homeSerachFilterObj.Claim_Jobs_Variance.SelectedOption) && homeSerachFilterObj.Claim_Jobs_Variance.SelectedOption != '0'){
            List<HomeSearchFilterInterface.FieldFilter> numericFilterList = HomeSearchFilterInterface.getNumericFilter(homeSerachFilterObj.Claim_Jobs_Variance, 'Claim__r.Total_Variance__c');
            if(numericFilterList.size() > 0) {
                filterJSON.addAll(numericFilterList);
            }
        }
    }

    public static void setFilterJSONForUnitRegister(List<HomeSearchFilterInterface.FieldFilter> filterJSON, HomeSearchFilterWrapper homeSerachFilterObj) {
        if(homeSerachFilterObj.IncludeConsignments != null && homeSerachFilterObj.IncludeConsignments) {
            filterJSON.add(new HomeSearchFilterInterface.FieldFilter('((Unit_Type__c', '=', '\'STOCK\') OR (Unit_Type__c = \'COU\' AND Consignment__c = true))'));
        } else {                    
            filterJSON.add(new HomeSearchFilterInterface.FieldFilter('Unit_Type__c', '=', '\'STOCK\''));
        }
        if(!String.isBlank(homeSerachFilterObj.Unit_Register_New_Unit) && homeSerachFilterObj.Unit_Register_New_Unit != '0'){   
            filterJSON.add(new HomeSearchFilterInterface.FieldFilter('New_Unit__c', '=', ((homeSerachFilterObj.Unit_Register_New_Unit == 'Yes') ? true : false)));
        }
        if(!String.isBlank(homeSerachFilterObj.Unit_Register_Make)){   
            filterJSON.add(new HomeSearchFilterInterface.FieldFilter('Unit_Make__r.Name', 'LIKE', '\'' + BPUtility.escapeSingleQuotes(homeSerachFilterObj.Unit_Register_Make) + '%\''));
        }
        
        if(!String.isBlank(homeSerachFilterObj.Unit_Register_Model)){   
            filterJSON.add(new HomeSearchFilterInterface.FieldFilter('Unit_Model__r.Name__c', 'LIKE', '\'' + BPUtility.escapeSingleQuotes(homeSerachFilterObj.Unit_Register_Model) + '%\''));
        }
        if(!String.isBlank(homeSerachFilterObj.Unit_Register_Submodel)){   
            filterJSON.add(new HomeSearchFilterInterface.FieldFilter('Sub_Model__r.Sub_Model_Name__c', 'LIKE', '\'' + BPUtility.escapeSingleQuotes(homeSerachFilterObj.Unit_Register_Submodel) + '%\''));
        }
        if(!String.isBlank(homeSerachFilterObj.Unit_Register_Year)) {   
            filterJSON.add(new HomeSearchFilterInterface.FieldFilter('Year__c', '=',  homeSerachFilterObj.Unit_Register_Year));
        }
        if(!String.isBlank(homeSerachFilterObj.Unit_Register_How_Acquired)  && homeSerachFilterObj.Unit_Register_How_Acquired != '0') {   
            filterJSON.add(new HomeSearchFilterInterface.FieldFilter('How_Acquired__c', '=',  '\'' +homeSerachFilterObj.Unit_Register_How_Acquired + '\''));
        }
        if(homeSerachFilterObj.Unit_Register_Stocked_In !=null && !String.isBlank(homeSerachFilterObj.Unit_Register_Stocked_In.SelectedOption) && homeSerachFilterObj.Unit_Register_Stocked_In.SelectedOption != '0') {
            List<HomeSearchFilterInterface.FieldFilter> stockOutFilterJSON = HomeSearchFilterInterface.getDateFilter(homeSerachFilterObj.Unit_Register_Stocked_In, 'Date_Stocked_In__c', false);
            if(stockOutFilterJSON.size() > 0) {
                filterJSON.addAll(stockOutFilterJSON);
            }
        }
    }

    public static void setFilterLabelsForSubletItems(List<HomeSearchFilterInterface.FilterLabel> filterLables, HomeSearchFilterWrapper homeSerachFilterObj) {
    	if(homeSerachFilterObj.Sublet_Items_Total_Price != null && String.isNotBlank(homeSerachFilterObj.Sublet_Items_Total_Price.SelectedOption) && homeSerachFilterObj.Sublet_Items_Total_Price.SelectedOption != '0') {
            String modifiedLabelName = HomeSearchFilterInterface.optionValueToNumberValueLabelMap.containsKey(homeSerachFilterObj.Sublet_Items_Total_Price.SelectedOption) ? HomeSearchFilterInterface.optionValueToNumberValueLabelMap.get(homeSerachFilterObj.Sublet_Items_Total_Price.SelectedOption) : homeSerachFilterObj.Sublet_Items_Total_Price.SelectedOption;
            if(modifiedLabelName == '5' && String.isNotBlank(homeSerachFilterObj.Sublet_Items_Total_Price.Value1) && String.isNotBlank(homeSerachFilterObj.Sublet_Items_Total_Price.Value2)) {
                filterLables.add(new HomeSearchFilterInterface.FilterLabel('Sublet_Items_Total_Price', 'Total Price', homeSerachFilterObj.Sublet_Items_Total_Price.Value1 + ' To ' + homeSerachFilterObj.Sublet_Items_Total_Price.Value2));
            } else if(modifiedLabelName != '5') {
                filterLables.add(new HomeSearchFilterInterface.FilterLabel('Sublet_Items_Total_Price', 'Total Price', modifiedLabelName + ' ' + homeSerachFilterObj.Sublet_Items_Total_Price.Value1));
            }
        }
        if(homeSerachFilterObj.Sublet_Items_Total_Cost != null && String.isNotBlank(homeSerachFilterObj.Sublet_Items_Total_Cost.SelectedOption) && homeSerachFilterObj.Sublet_Items_Total_Cost.SelectedOption != '0') {
            String modifiedLabelName = HomeSearchFilterInterface.optionValueToNumberValueLabelMap.containsKey(homeSerachFilterObj.Sublet_Items_Total_Cost.SelectedOption) ? HomeSearchFilterInterface.optionValueToNumberValueLabelMap.get(homeSerachFilterObj.Sublet_Items_Total_Cost.SelectedOption) : homeSerachFilterObj.Sublet_Items_Total_Cost.SelectedOption;
            if(modifiedLabelName == '5' && String.isNotBlank(homeSerachFilterObj.Sublet_Items_Total_Cost.Value1) && String.isNotBlank(homeSerachFilterObj.Sublet_Items_Total_Cost.Value2)) {
                filterLables.add(new HomeSearchFilterInterface.FilterLabel('Sublet_Items_Total_Cost', 'Total Cost', homeSerachFilterObj.Sublet_Items_Total_Cost.Value1 + ' To ' + homeSerachFilterObj.Sublet_Items_Total_Cost.Value2));
            } else if(modifiedLabelName != '5') {
                filterLables.add(new HomeSearchFilterInterface.FilterLabel('Sublet_Items_Total_Cost', 'Total Cost', modifiedLabelName + ' ' + homeSerachFilterObj.Sublet_Items_Total_Cost.Value1));
            }
        }
        if(homeSerachFilterObj.Sublet_Items_Expected !=null && String.isNotBlank(homeSerachFilterObj.Sublet_Items_Expected.SelectedOption) && homeSerachFilterObj.Sublet_Items_Expected.SelectedOption != '0') {
            String modifiedLabelName = HomeSearchFilterInterface.optionValueToModifiedKeyMap.containsKey(homeSerachFilterObj.Sublet_Items_Expected.SelectedOption) ? HomeSearchFilterInterface.optionValueToModifiedKeyMap.get(homeSerachFilterObj.Sublet_Items_Expected.SelectedOption) : homeSerachFilterObj.Sublet_Items_Expected.SelectedOption;
            if(modifiedLabelName == '5' && String.isNotBlank(homeSerachFilterObj.Sublet_Items_Expected.Value1) && String.isNotBlank(homeSerachFilterObj.Sublet_Items_Expected.Value2)) {
                filterLables.add(new HomeSearchFilterInterface.FilterLabel('Sublet_Items_Expected', 'Expected', homeSerachFilterObj.Sublet_Items_Expected.Value1 + ' To ' + homeSerachFilterObj.Sublet_Items_Expected.Value2));
            } else if(modifiedLabelName != '5') {
                filterLables.add(new HomeSearchFilterInterface.FilterLabel('Sublet_Items_Expected', 'Expected', modifiedLabelName));
            }
        }
        if(String.isNotBlank(homeSerachFilterObj.Sublet_Items_Sublet_Status)){ 
            if(homeSerachFilterObj.Sublet_Items_Sublet_Status == '0') {
                filterLables.add(new HomeSearchFilterInterface.FilterLabel('Sublet_Items_Sublet_Status', 'Sublet Status', 'Active'));
            } else {
                filterLables.add(new HomeSearchFilterInterface.FilterLabel('Sublet_Items_Sublet_Status', 'Sublet Status', homeSerachFilterObj.Sublet_Items_Sublet_Status));
            }  
        } 
        if(String.isNotBlank(homeSerachFilterObj.Sublet_Items_Order_Number)) {
            filterLables.add(new HomeSearchFilterInterface.FilterLabel('Sublet_Items_Order_Number', 'Order Number', homeSerachFilterObj.Sublet_Items_Order_Number));
        }
        if(String.isNotBlank(homeSerachFilterObj.Sublet_Items_Customer)) {
            filterLables.add(new HomeSearchFilterInterface.FilterLabel('Sublet_Items_Customer', 'Customer', homeSerachFilterObj.Sublet_Items_Customer));
        }
        if(String.isNotBlank(homeSerachFilterObj.Sublet_Items_Job_Status) && homeSerachFilterObj.Sublet_Items_Job_Status != '0') {
            filterLables.add(new HomeSearchFilterInterface.FilterLabel('Sublet_Items_Job_Status', 'Job Status', homeSerachFilterObj.Sublet_Items_Job_Status));
        }
        if(String.isNotBlank(homeSerachFilterObj.Sublet_Items_Job_Type) && homeSerachFilterObj.Sublet_Items_Job_Type != '0') {
            filterLables.add(new HomeSearchFilterInterface.FilterLabel('Sublet_Items_Job_Type', 'Job Type', homeSerachFilterObj.Sublet_Items_Job_Type));
        }
        if(String.isNotBlank(homeSerachFilterObj.Sublet_Items_Vendor)) {
            filterLables.add(new HomeSearchFilterInterface.FilterLabel('Sublet_Items_Vendor', 'Vendor', homeSerachFilterObj.Sublet_Items_Vendor));
        }
        if(String.isNotBlank(homeSerachFilterObj.Sublet_Items_VO_Number)) {
            filterLables.add(new HomeSearchFilterInterface.FilterLabel('Sublet_Items_VO_Number', 'VO Number', homeSerachFilterObj.Sublet_Items_VO_Number));
        }
        if(String.isNotBlank(homeSerachFilterObj.Sublet_Items_VR_Number)) {
            filterLables.add(new HomeSearchFilterInterface.FilterLabel('Sublet_Items_VR_Number', 'VR Number', homeSerachFilterObj.Sublet_Items_VR_Number));
        }
        if(String.isNotBlank(homeSerachFilterObj.Sublet_Items_VI_Number)) {
            filterLables.add(new HomeSearchFilterInterface.FilterLabel('Sublet_Items_VI_Number', 'VI Number', homeSerachFilterObj.Sublet_Items_VI_Number));
        }
    }

    public static void setFilterLabelsForClaimJobs(List<HomeSearchFilterInterface.FilterLabel> filterLables, HomeSearchFilterWrapper homeSerachFilterObj) {
    	if(homeSerachFilterObj.Claim_Jobs_Variance != null && String.isNotBlank(homeSerachFilterObj.Claim_Jobs_Variance.SelectedOption) && homeSerachFilterObj.Claim_Jobs_Variance.SelectedOption != '0') {
            String modifiedLabelName = HomeSearchFilterInterface.optionValueToNumberValueLabelMap.containsKey(homeSerachFilterObj.Claim_Jobs_Variance.SelectedOption) ? HomeSearchFilterInterface.optionValueToNumberValueLabelMap.get(homeSerachFilterObj.Claim_Jobs_Variance.SelectedOption) : homeSerachFilterObj.Claim_Jobs_Variance.SelectedOption;
            if(modifiedLabelName == '5' && String.isNotBlank(homeSerachFilterObj.Claim_Jobs_Variance.Value1) && String.isNotBlank(homeSerachFilterObj.Claim_Jobs_Variance.Value2)) {
                filterLables.add(new HomeSearchFilterInterface.FilterLabel('Claim_Jobs_Variance', 'Variance', homeSerachFilterObj.Claim_Jobs_Variance.Value1 + ' To ' + homeSerachFilterObj.Claim_Jobs_Variance.Value2));
            } else if(modifiedLabelName != '5') {
                filterLables.add(new HomeSearchFilterInterface.FilterLabel('Claim_Jobs_Variance', 'Variance', modifiedLabelName + ' ' + homeSerachFilterObj.Claim_Jobs_Variance.Value1));
            }
        }
        
        if(String.isNotBlank(homeSerachFilterObj.Claim_Jobs_Claim_Status) && homeSerachFilterObj.Claim_Jobs_Claim_Status != '0'){ 
            filterLables.add(new HomeSearchFilterInterface.FilterLabel('Claim_Jobs_Claim_Status', 'Claim Status', homeSerachFilterObj.Claim_Jobs_Claim_Status));
        } 
        if(String.isNotBlank(homeSerachFilterObj.Claim_Jobs_Provider)) {
            filterLables.add(new HomeSearchFilterInterface.FilterLabel('Claim_Jobs_Provider', 'Provider', homeSerachFilterObj.Claim_Jobs_Provider));
        }
    }

    public static void setFilterLabelsForUnitRegister(List<HomeSearchFilterInterface.FilterLabel> filterLables, HomeSearchFilterWrapper homeSerachFilterObj) {
    	if(homeSerachFilterObj.IncludeConsignments) { 
            filterLables.add(new HomeSearchFilterInterface.FilterLabel('IncludeConsignments', 'Include Consignments', 'Yes'));
        }
        if(homeSerachFilterObj.Unit_Register_Stocked_In !=null && !String.isBlank(homeSerachFilterObj.Unit_Register_Stocked_In.SelectedOption) && homeSerachFilterObj.Unit_Register_Stocked_In.SelectedOption != '0') {
            String modifiedLabelName = HomeSearchFilterInterface.optionValueToModifiedKeyMap.containsKey(homeSerachFilterObj.Unit_Register_Stocked_In.SelectedOption) ? HomeSearchFilterInterface.optionValueToModifiedKeyMap.get(homeSerachFilterObj.Unit_Register_Stocked_In.SelectedOption) : homeSerachFilterObj.Unit_Register_Stocked_In.SelectedOption;
            if( modifiedLabelName == '5'  && !String.isBlank(HomeSerachFilterObj.Unit_Register_Stocked_In.Value1) && !String.isBlank(homeSerachFilterObj.Unit_Register_Stocked_In.Value2)) {
                filterLables.add(new HomeSearchFilterInterface.FilterLabel('Unit_Register_Stocked_In', 'Stocked In', homeSerachFilterObj.Unit_Register_Stocked_In.Value1 + ' To ' + homeSerachFilterObj.Unit_Register_Stocked_In.Value2));
            } else if(modifiedLabelName != '5'){
                filterLables.add(new HomeSearchFilterInterface.FilterLabel('Unit_Register_Stocked_In', 'Stocked In', modifiedLabelName));
            }
        }
        if(!String.isBlank(homeSerachFilterObj.Unit_Register_New_Unit) && homeSerachFilterObj.Unit_Register_New_Unit != '0'){   
            filterLables.add(new HomeSearchFilterInterface.FilterLabel('Unit_Register_New_Unit', 'New Unit', homeSerachFilterObj.Unit_Register_New_Unit));
        }

        if(!String.isBlank(homeSerachFilterObj.Unit_Register_Make) && homeSerachFilterObj.Unit_Register_Make != '0') {   
            filterLables.add(new HomeSearchFilterInterface.FilterLabel('Unit_Register_Make', 'Make', homeSerachFilterObj.Unit_Register_Make));
        }
        if(!String.isBlank(homeSerachFilterObj.Unit_Register_Model) && homeSerachFilterObj.Unit_Register_Model != '0') {   
            filterLables.add(new HomeSearchFilterInterface.FilterLabel('Unit_Register_Model', 'Model', homeSerachFilterObj.Unit_Register_Model));
        }
        if(!String.isBlank(homeSerachFilterObj.Unit_Register_Submodel) && homeSerachFilterObj.Unit_Register_Submodel != '0') {   
            filterLables.add(new HomeSearchFilterInterface.FilterLabel('Unit_Register_Submodel', 'SubModel', homeSerachFilterObj.Unit_Register_Submodel));
        }
        if(!String.isBlank(homeSerachFilterObj.Unit_Register_Year) && homeSerachFilterObj.Unit_Register_Year != '0') {   
            filterLables.add(new HomeSearchFilterInterface.FilterLabel('Unit_Register_Year', 'Year', homeSerachFilterObj.Unit_Register_Year));
        }
        if(!String.isBlank(homeSerachFilterObj.Unit_Register_How_Acquired) && homeSerachFilterObj.Unit_Register_How_Acquired != '0') {   
            filterLables.add(new HomeSearchFilterInterface.FilterLabel('Unit_Register_How_Acquired', 'How Acquired', homeSerachFilterObj.Unit_Register_How_Acquired));
        }
    }

    public static String scheduleReport(String scheduleReportJson) {
        ScheduleReportWrapper scheduleReportObj = (ScheduleReportWrapper) System.JSON.deserialize(scheduleReportJson, ScheduleReportWrapper.class);
        Filter__c filterRec = updateReportSchedulingData(scheduleReportObj);
        GE_File_Config__c geFileConfig = createGEFileConfigData(scheduleReportObj);
        scheduleExport(filterRec, geFileConfig);
        return '';
    }

    private static void scheduleExport(Filter__c filterRec, GE_File_Config__c geFileConfig) {
        String fileName = geFileConfig.File_Name__c;
        AccountingUtil.abortScheduleJobs(fileName);
        String scheduleStr = getCRONStrForSchedule(filterRec);
        System.schedule(fileName + ' Scheduler', scheduleStr , new GenericExportBatch(fileName));
    }

    private static String getCRONStrForSchedule(Filter__c filterRec) {
        Time scheduleTime = DateTimeUtility.getTimeFromString2(filterRec.Schedule_At__c);
        Integer second = scheduleTime.second();
        Integer minute = scheduleTime.minute();
        Integer hour = scheduleTime.hour();
        String dayOfMonth = '';
        String month = '*';
        String dayOfWeek = ''; 
        String year = '*';

        if(filterRec.Report_Frequency__c == 'Daily') {
            dayOfMonth = '*';
            dayOfWeek = '?';
        } else if(filterRec.Report_Frequency__c == 'Weekly') {
            dayOfMonth = '?';
            dayOfWeek = dayNameToNumberMap.get(filterRec.Schedule_On__c);
        } else if(filterRec.Report_Frequency__c == 'Monthly') {
            dayOfMonth = dayNameToNumberMap.get(filterRec.Schedule_On__c);
            dayOfWeek = '?';
        }
        return (second + ' ' + minute + ' ' + hour + ' ' + dayOfMonth + ' ' + month + ' ' + dayOfWeek + ' ' + year);
    }

    private static Filter__c updateReportSchedulingData(ScheduleReportWrapper scheduleReportObj) {
        Filter__c filterToScheduleRec = new Filter__c(Id = scheduleReportObj.FilterId);
        filterToScheduleRec.Report_Format__c = scheduleReportObj.ReportFormat;
        filterToScheduleRec.Email_Addresses__c = scheduleReportObj.EmailListStr;
        filterToScheduleRec.Report_Frequency__c = scheduleReportObj.Frequency;
        filterToScheduleRec.Schedule_On__c = scheduleReportObj.ScheduleOn;
        filterToScheduleRec.Schedule_At__c = scheduleReportObj.ScheduleAt;
        DMLUtility.updateSobjectList('Filter__c', filterToScheduleRec);
        return filterToScheduleRec;
    }

    private static GE_File_Config__c createGEFileConfigData(ScheduleReportWrapper scheduleReportObj) {
        Filter__c filterRec = [SELECT Field_Filter_Json__c, Field_Filter_Json_2__c, Export_GroupBy_Field__c, Sort_Json__c, Display_Hidden_Column__c, 
                                Filter_User__c, (SELECT Id FROM GE_File_Configs__r LIMIT 1) FROM Filter__c WHERE Id =: scheduleReportObj.FilterId];
        
        String fieldFilterJson = ((filterRec.Field_Filter_Json__c != null ? filterRec.Field_Filter_Json__c : '' ) + (filterRec.Field_Filter_Json_2__c  != null ? filterRec.Field_Filter_Json_2__c : ''));
        HomeSearchFilterWrapper filterWrapperObj = (HomeSearchFilterWrapper) System.JSON.deserialize(fieldFilterJson, HomeSearchFilterWrapper.class);
        PaginationSorting sortingObj = (PaginationSorting) System.JSON.deserialize(filterRec.Sort_Json__c, PaginationSorting.class);
        
        String objectNameLabel;
        if(!filterWrapperObj.Type.Objects.isEmpty()) {
            if(filterWrapperObj.Type.Objects.size() > 1) {
                throw new BlackPurlException('Multiple objects report can not be scheduled.');
            }
            objectNameLabel = new List<String>(filterWrapperObj.Type.Objects)[0];
        } else {
            throw new BlackPurlException('Some issue occurred while creating scheduling configuration - object is not defined.');
        }
        
        GenericExportWrapper genericExportObj = new GenericExportWrapper();
        if(filterRec.GE_File_Configs__r.size() > 0) {
            genericExportObj.Id = filterRec.GE_File_Configs__r[0].Id;
        }

        genericExportObj.FileName = scheduleReportObj.ReportName + '_' + filterRec.Filter_User__c;
        genericExportObj.FileType = scheduleReportObj.ReportFormat.toLowerCase();
        genericExportObj.DelimiterTextValue = scheduleReportObj.ReportFormat.equalsIgnoreCase('pdf') ? 'tab' : 'comma';
        genericExportObj.Delimiter = GenericExportUtil.fileSeparatorToFileSeparatorSymbolMap.get(genericExportObj.DelimiterTextValue);
        genericExportObj.IncludeColumnHeader = true;
        genericExportObj.ObjectAPIName = HomeSearchUtil.displayObjectNameToObjectAPINameMap.get(objectNameLabel);
        genericExportObj.FilterId = scheduleReportObj.FilterId;
        genericExportObj.GroupByFieldAPIName = getGroupByFieldAPIName(filterRec.Export_GroupBy_Field__c, objectNameLabel);
        genericExportObj.OrderByClause = getOrderByClause(sortingObj);
        genericExportObj.WhereClause = getWhereClause(filterWrapperObj, objectNameLabel);
        genericExportObj.ColumnDetailList = createDataForGEFileDetails(filterRec.Display_Hidden_Column__c, objectNameLabel);
        
        if(genericExportObj.Id != null) {
            DMLUtility.deleteSobjectList('GE_File_Detail__c', [SELECT Id FROM GE_File_Detail__c WHERE GE_File_Config__c = :genericExportObj.Id]);
        }
        return GenericExportService.upsertGenericExportFormat(genericExportObj);
    }

    private static String getGroupByFieldAPIName(String exportGroupByFieldName, String displayObjectName) {
        List<HomeSearch_Grid_Column__mdt> gridColsRecList = [SELECT Field_API_Name__c FROM HomeSearch_Grid_Column__mdt WHERE MasterLabel =: exportGroupByFieldName AND Display_Object_Name__c =: displayObjectName];
        if(!gridColsRecList.isEmpty()) {
            return gridColsRecList[0].Field_API_Name__c;
        }
        return null;
    }

    private static String getOrderByClause(PaginationSorting sortingObj) {
        String orderByStr = '';
        for(PaginationSorting.SortAttrs sortAttrObj: sortingObj.Sorting) {
            orderByStr += sortAttrObj.FieldName + ' ' + sortAttrObj.SortDirection + ', ';
        }
        orderByStr = orderByStr.substring(0, orderByStr.length()-2);
        return orderByStr;
    }

    private static String getWhereClause(HomeSearchFilterWrapper filterWrapperObj, String objectNameLabel) {
        String whereClauseStr = '';

        Map<String, List<HomeSearchFilterInterface.FieldFilter>> objNameToFilterListMap = HomeSearchFilterInterface.getFilterList(filterWrapperObj);
        if(!objNameToFilterListMap.containsKey(objectNameLabel)) {
            throw new BlackPurlException('Filters can not be found for ' + objectNameLabel + '.');
        }
        for(HomeSearchFilterInterface.FieldFilter fieldFilterObj: objNameToFilterListMap.get(objectNameLabel)) {
            whereClauseStr += fieldFilterObj.FieldName + ' ' + fieldFilterObj.Operator + ' ' + fieldFilterObj.FieldValue + ' AND ';
        }
        whereClauseStr = whereClauseStr.subString(0, whereClauseStr.length() - 5);
        return whereClauseStr;
    }

    private static List<GenericExportWrapper.ColumnDetailWrapper> createDataForGEFileDetails(String displayHiddenColJson, String displayObjectName) {
        List<String> colsToInculdeList = new List<String>();
        HomeSearchCtrl.DisplayHiddenColumnWrapper columnObj = (HomeSearchCtrl.DisplayHiddenColumnWrapper) System.JSON.deserialize(displayHiddenColJson, HomeSearchCtrl.DisplayHiddenColumnWrapper.class);
        List<GenericExportWrapper.ColumnDetailWrapper> columnList = new List<GenericExportWrapper.ColumnDetailWrapper>();
        for(HomeSearchCtrl.DisplayedColumnsWrapper colObj: columnObj.DisplayedColumns) {
            colsToInculdeList.add(colObj.Label);
        }
        List<HomeSearch_Grid_Column__mdt> gridColsRecList = [SELECT MasterLabel, Field_API_Name__c, Order_Number__c FROM HomeSearch_Grid_Column__mdt WHERE MasterLabel IN :colsToInculdeList AND Display_Object_Name__c =: displayObjectName];
        for(HomeSearch_Grid_Column__mdt colRec: gridColsRecList) {
            if(colRec.MasterLabel == 'Type') {
                continue;
            }
            GenericExportWrapper.ColumnDetailWrapper colDetailObj = new GenericExportWrapper.ColumnDetailWrapper();
            colDetailObj.ColumnLabel = colRec.MasterLabel;
            colDetailObj.OrderNumber = Integer.valueOf(colRec.Order_Number__c);
            colDetailObj.FieldAPIName = colRec.Field_API_Name__c;
            columnList.add(colDetailObj);
        }
        return columnList;
    }

    private static Map<String, String> dayNameToNumberMap = new Map<String, String>{
                                                                                        'Sunday' => '1',
                                                                                        'Monday' => '2',
                                                                                        'Tuesday' => '3',
                                                                                        'Wednesday' => '4',
                                                                                        'Thursday' => '5',
                                                                                        'Friday' => '6',
                                                                                        'Saturday' => '7',
                                                                                        '1st day' => '1',
                                                                                        'Last day' => 'L',
                                                                                        '15th day' => '15'
                                                                                    };

    public static void setFilterJSONForDealUnits(List<HomeSearchFilterInterface.FieldFilter> filterJSON, HomeSearchFilterWrapper homeSerachFilterObj) {
    	if(!String.isBlank(homeSerachFilterObj.Deal_Units_Unit_Type) && homeSerachFilterObj.Deal_Units_Unit_Type != '0') {
            filterJSON.add(new HomeSearchFilterInterface.FieldFilter('Unit_Type__c', '=', '\'' + homeSerachFilterObj.Deal_Units_Unit_Type + '\''));
        } else {
            filterJSON.add(new HomeSearchFilterInterface.FieldFilter('Unit_Type__c', '!=', '\'Trade-in\''));
        }
        
        if(!String.isBlank(homeSerachFilterObj.Deal_Units_Order_Number)){   
            filterJSON.add(new HomeSearchFilterInterface.FieldFilter('Deal__r.CO_Header__r.Name', 'LIKE', '\'' + homeSerachFilterObj.Deal_Units_Order_Number + '%\''));
        }
        if(!String.isBlank(homeSerachFilterObj.Deal_Units_Stock_Number)){   
            filterJSON.add(new HomeSearchFilterInterface.FieldFilter('', '', '((Unit_Type__c = \'Stock unit\' AND Customer_Owned_Unit__r.Stock_Id__c LIKE \'' + 
                                                    homeSerachFilterObj.Deal_Units_Stock_Number + '%\') OR ' + 
                                                    '(Unit_Type__c != \'Stock unit\' AND Customer_Owned_Unit__r.Unit_Number__c LIKE \'' + 
                                                    homeSerachFilterObj.Deal_Units_Stock_Number + '%\'))'));
        }
        if(homeSerachFilterObj.Deal_Units_Date_Sold != null && !String.isBlank(homeSerachFilterObj.Deal_Units_Date_Sold.SelectedOption)) {
            List<HomeSearchFilterInterface.FieldFilter> stockInFilterJSON = HomeSearchFilterInterface.getDateFilter(homeSerachFilterObj.Deal_Units_Date_Sold, 'Date_Sold__c', false);
            if(stockInFilterJSON.size() > 0) {
                filterJSON.addAll(stockInFilterJSON);
            }
        }
        if(!String.isBlank(homeSerachFilterObj.Deal_Units_Invoice_Number)){   
            filterJSON.add(new HomeSearchFilterInterface.FieldFilter('Deal__r.Invoice_Number__r.Invoice_Number__c', 'LIKE', '\'' + homeSerachFilterObj.Deal_Units_Invoice_Number + '%\''));
        }
        if(!String.isBlank(homeSerachFilterObj.Deal_Units_Make)){   
            filterJSON.add(new HomeSearchFilterInterface.FieldFilter('Customer_Owned_Unit__r.Make_Name__c ', 'LIKE', '\'' + BPUtility.escapeSingleQuotes(homeSerachFilterObj.Deal_Units_Make) + '%\''));
        }
        if(!String.isBlank(homeSerachFilterObj.Deal_Units_Model)){   
            filterJSON.add(new HomeSearchFilterInterface.FieldFilter('Customer_Owned_Unit__r.Model_Name__c', 'LIKE', '\'' + BPUtility.escapeSingleQuotes(homeSerachFilterObj.Deal_Units_Model) + '%\''));
        }
        if(!String.isBlank(homeSerachFilterObj.Deal_Units_Submodel)){   
            filterJSON.add(new HomeSearchFilterInterface.FieldFilter('Customer_Owned_Unit__r.Sub_Model__r.Sub_Model_Name__c', 'LIKE', '\'' + BPUtility.escapeSingleQuotes(homeSerachFilterObj.Deal_Units_Submodel) + '%\''));
        }
        if(!String.isBlank(homeSerachFilterObj.Deal_Units_Year)){   
            filterJSON.add(new HomeSearchFilterInterface.FieldFilter('Customer_Owned_Unit__r.Year__c', '=',  homeSerachFilterObj.Deal_Units_Year));
        }
        if(!String.isBlank(homeSerachFilterObj.Deal_Units_Deal_Customer)){   
            filterJSON.add(new HomeSearchFilterInterface.FieldFilter('Deal__r.CO_Header__r.Customer_Name__c', 'LIKE', '\'' + homeSerachFilterObj.Deal_Units_Deal_Customer + '%\''));
        }
        if(!String.isBlank(homeSerachFilterObj.Deal_Units_Deal_Type) && homeSerachFilterObj.Deal_Units_Deal_Type != '0'){
            String dealType;
            if(homeSerachFilterObj.Deal_Units_Deal_Type == '1') {
                dealType = Constants.CASH_DEAL;
            } else if(homeSerachFilterObj.Deal_Units_Deal_Type == '2') {
                dealType = Constants.FINANCED;
            }   
            filterJSON.add(new HomeSearchFilterInterface.FieldFilter('Deal__r.Type__c', '=', '\'' + dealType + '\''));
        }
        if(!String.isBlank(homeSerachFilterObj.Deal_Units_Salesperson)) {
            if(homeSerachFilterObj.Deal_Units_Salesperson.equalsIgnoreCase('Unassigned')) {
                filterJSON.add(new HomeSearchFilterInterface.FieldFilter('', '', '(Deal__r.Salesperson_Name__c = null OR Deal__r.Salesperson_Name__c = \'\')'));
            } else {
                filterJSON.add(new HomeSearchFilterInterface.FieldFilter('Deal__r.Salesperson_Name__c', 'Like', '\'%' + homeSerachFilterObj.Deal_Units_Salesperson + '%\''));
            }
        }
        if(homeSerachFilterObj.Deal_Units_Total_Price !=null && !String.isBlank(homeSerachFilterObj.Deal_Units_Total_Price.SelectedOption) && homeSerachFilterObj.Deal_Units_Total_Price.SelectedOption != '0'){
            List<HomeSearchFilterInterface.FieldFilter> numericFilterList = HomeSearchFilterInterface.getNumericFilter(homeSerachFilterObj.Deal_Units_Total_Price, 'Total_Price__c');
            if(numericFilterList.size() > 0) {
                filterJSON.addAll(numericFilterList);
            }
        }
        if(homeSerachFilterObj.Deal_Units_Total_Cost !=null && !String.isBlank(homeSerachFilterObj.Deal_Units_Total_Cost.SelectedOption) && homeSerachFilterObj.Deal_Units_Total_Cost.SelectedOption != '0'){
            List<HomeSearchFilterInterface.FieldFilter> numericFilterList = HomeSearchFilterInterface.getNumericFilter(homeSerachFilterObj.Deal_Units_Total_Cost, 'Total_Cost__c');
            if(numericFilterList.size() > 0) {
                filterJSON.addAll(numericFilterList);
            }
        }
        if(homeSerachFilterObj.Deal_Units_Total_Profit !=null && !String.isBlank(homeSerachFilterObj.Deal_Units_Total_Profit.SelectedOption) && homeSerachFilterObj.Deal_Units_Total_Profit.SelectedOption != '0'){
            List<HomeSearchFilterInterface.FieldFilter> numericFilterList = HomeSearchFilterInterface.getNumericFilter(homeSerachFilterObj.Deal_Units_Total_Profit, 'Total_Profit__c');
            if(numericFilterList.size() > 0) {
                filterJSON.addAll(numericFilterList);
            }
        }
        if(homeSerachFilterObj.Deal_Units_Total_Unit_Price !=null && !String.isBlank(homeSerachFilterObj.Deal_Units_Total_Unit_Price.SelectedOption) && homeSerachFilterObj.Deal_Units_Total_Unit_Price.SelectedOption != '0'){
            List<HomeSearchFilterInterface.FieldFilter> numericFilterList = HomeSearchFilterInterface.getNumericFilter(homeSerachFilterObj.Deal_Units_Total_Unit_Price, 'Total_Unit_Price__c');
            if(numericFilterList.size() > 0) {
                filterJSON.addAll(numericFilterList);
            }
        }
        if(homeSerachFilterObj.Deal_Units_Total_Unit_Cost !=null && !String.isBlank(homeSerachFilterObj.Deal_Units_Total_Unit_Cost.SelectedOption) && homeSerachFilterObj.Deal_Units_Total_Unit_Cost.SelectedOption != '0'){
            List<HomeSearchFilterInterface.FieldFilter> numericFilterList = HomeSearchFilterInterface.getNumericFilter(homeSerachFilterObj.Deal_Units_Total_Unit_Cost, 'Total_Unit_Cost__c');
            if(numericFilterList.size() > 0) {
                filterJSON.addAll(numericFilterList);
            }
        }
        if(homeSerachFilterObj.Deal_Units_Total_Unit_Profit !=null && !String.isBlank(homeSerachFilterObj.Deal_Units_Total_Unit_Profit.SelectedOption) && homeSerachFilterObj.Deal_Units_Total_Unit_Profit.SelectedOption != '0'){
            List<HomeSearchFilterInterface.FieldFilter> numericFilterList = HomeSearchFilterInterface.getNumericFilter(homeSerachFilterObj.Deal_Units_Total_Unit_Profit, 'Total_Unit_Profit__c');
            if(numericFilterList.size() > 0) {
                filterJSON.addAll(numericFilterList);
            }
        }
        if(homeSerachFilterObj.Deal_Units_Total_Unit_Option_Price !=null && !String.isBlank(homeSerachFilterObj.Deal_Units_Total_Unit_Option_Price.SelectedOption) && homeSerachFilterObj.Deal_Units_Total_Unit_Option_Price.SelectedOption != '0'){
            List<HomeSearchFilterInterface.FieldFilter> numericFilterList = HomeSearchFilterInterface.getNumericFilter(homeSerachFilterObj.Deal_Units_Total_Unit_Option_Price, 'Total_Unit_Option_Price__c');
            if(numericFilterList.size() > 0) {
                filterJSON.addAll(numericFilterList);
            }
        }
        if(homeSerachFilterObj.Deal_Units_Total_Unit_Option_Cost !=null && !String.isBlank(homeSerachFilterObj.Deal_Units_Total_Unit_Option_Cost.SelectedOption) && homeSerachFilterObj.Deal_Units_Total_Unit_Option_Cost.SelectedOption != '0'){
            List<HomeSearchFilterInterface.FieldFilter> numericFilterList = HomeSearchFilterInterface.getNumericFilter(homeSerachFilterObj.Deal_Units_Total_Unit_Option_Cost, 'Total_Unit_Option_Cost__c');
            if(numericFilterList.size() > 0) {
                filterJSON.addAll(numericFilterList);
            }
        }
        if(homeSerachFilterObj.Deal_Units_Total_Unit_Option_Profit !=null && !String.isBlank(homeSerachFilterObj.Deal_Units_Total_Unit_Option_Profit.SelectedOption) && homeSerachFilterObj.Deal_Units_Total_Unit_Option_Profit.SelectedOption != '0'){
            List<HomeSearchFilterInterface.FieldFilter> numericFilterList = HomeSearchFilterInterface.getNumericFilter(homeSerachFilterObj.Deal_Units_Total_Unit_Option_Profit, 'Total_Unit_Option_Profit__c');
            if(numericFilterList.size() > 0) {
                filterJSON.addAll(numericFilterList);
            }
        }
        if(homeSerachFilterObj.Deal_Units_Base_Price !=null && !String.isBlank(homeSerachFilterObj.Deal_Units_Base_Price.SelectedOption) && homeSerachFilterObj.Deal_Units_Base_Price.SelectedOption != '0'){
            List<HomeSearchFilterInterface.FieldFilter> numericFilterList = HomeSearchFilterInterface.getNumericFilter(homeSerachFilterObj.Deal_Units_Base_Price, 'Base_Price__c');
            if(numericFilterList.size() > 0) {
                filterJSON.addAll(numericFilterList);
            }
        }
        if(homeSerachFilterObj.Deal_Units_Factory_Options !=null && !String.isBlank(homeSerachFilterObj.Deal_Units_Factory_Options.SelectedOption) && homeSerachFilterObj.Deal_Units_Factory_Options.SelectedOption != '0'){
            List<HomeSearchFilterInterface.FieldFilter> numericFilterList = HomeSearchFilterInterface.getNumericFilter(homeSerachFilterObj.Deal_Units_Factory_Options, 'Factory_Option_Total__c');
            if(numericFilterList.size() > 0) {
                filterJSON.addAll(numericFilterList);
            }
        }
        if(homeSerachFilterObj.Deal_Units_Dealer_Installed !=null && !String.isBlank(homeSerachFilterObj.Deal_Units_Dealer_Installed.SelectedOption) && homeSerachFilterObj.Deal_Units_Dealer_Installed.SelectedOption != '0'){
            List<HomeSearchFilterInterface.FieldFilter> numericFilterList = HomeSearchFilterInterface.getNumericFilter(homeSerachFilterObj.Deal_Units_Dealer_Installed, 'Dealer_Option_Total__c');
            if(numericFilterList.size() > 0) {
                filterJSON.addAll(numericFilterList);
            }
        }
        if(homeSerachFilterObj.Deal_Units_Part_Options !=null && !String.isBlank(homeSerachFilterObj.Deal_Units_Part_Options.SelectedOption) && homeSerachFilterObj.Deal_Units_Part_Options.SelectedOption != '0'){
            List<HomeSearchFilterInterface.FieldFilter> numericFilterList = HomeSearchFilterInterface.getNumericFilter(homeSerachFilterObj.Deal_Units_Part_Options, 'Part_Total__c');
            if(numericFilterList.size() > 0) {
                filterJSON.addAll(numericFilterList);
            }
        }
        if(homeSerachFilterObj.Deal_Units_Labor_Options !=null && !String.isBlank(homeSerachFilterObj.Deal_Units_Labor_Options.SelectedOption) && homeSerachFilterObj.Deal_Units_Labor_Options.SelectedOption != '0'){
            List<HomeSearchFilterInterface.FieldFilter> numericFilterList = HomeSearchFilterInterface.getNumericFilter(homeSerachFilterObj.Deal_Units_Labor_Options, 'Labour_Total__c');
            if(numericFilterList.size() > 0) {
                filterJSON.addAll(numericFilterList);
            }
        }
        if(homeSerachFilterObj.Deal_Units_Sublet_Options !=null && !String.isBlank(homeSerachFilterObj.Deal_Units_Sublet_Options.SelectedOption) && homeSerachFilterObj.Deal_Units_Sublet_Options.SelectedOption != '0'){
            List<HomeSearchFilterInterface.FieldFilter> numericFilterList = HomeSearchFilterInterface.getNumericFilter(homeSerachFilterObj.Deal_Units_Sublet_Options, 'Sublet_Total__c');
            if(numericFilterList.size() > 0) {
                filterJSON.addAll(numericFilterList);
            }
        }
        if(homeSerachFilterObj.Deal_Units_Fee_Options !=null && !String.isBlank(homeSerachFilterObj.Deal_Units_Fee_Options.SelectedOption) && homeSerachFilterObj.Deal_Units_Fee_Options.SelectedOption != '0'){
            List<HomeSearchFilterInterface.FieldFilter> numericFilterList = HomeSearchFilterInterface.getNumericFilter(homeSerachFilterObj.Deal_Units_Fee_Options, 'Fee_Total__c');
            if(numericFilterList.size() > 0) {
                filterJSON.addAll(numericFilterList);
            }
        }
        if(homeSerachFilterObj.Deal_Units_Warranty_Options !=null && !String.isBlank(homeSerachFilterObj.Deal_Units_Warranty_Options.SelectedOption) && homeSerachFilterObj.Deal_Units_Warranty_Options.SelectedOption != '0'){
            List<HomeSearchFilterInterface.FieldFilter> numericFilterList = HomeSearchFilterInterface.getNumericFilter(homeSerachFilterObj.Deal_Units_Warranty_Options, 'Warranty_Product_Total__c');
            if(numericFilterList.size() > 0) {
                filterJSON.addAll(numericFilterList);
            }
        }
        if(homeSerachFilterObj.Deal_Units_Other_Products !=null && !String.isBlank(homeSerachFilterObj.Deal_Units_Other_Products.SelectedOption) && homeSerachFilterObj.Deal_Units_Other_Products.SelectedOption != '0'){
            List<HomeSearchFilterInterface.FieldFilter> numericFilterList = HomeSearchFilterInterface.getNumericFilter(homeSerachFilterObj.Deal_Units_Other_Products, 'Other_Product_Total__c');
            if(numericFilterList.size() > 0) {
                filterJSON.addAll(numericFilterList);
            }
        }
        if(homeSerachFilterObj.Deal_Units_Stamp_Duty !=null && !String.isBlank(homeSerachFilterObj.Deal_Units_Stamp_Duty.SelectedOption) && homeSerachFilterObj.Deal_Units_Stamp_Duty.SelectedOption != '0'){
            List<HomeSearchFilterInterface.FieldFilter> numericFilterList = HomeSearchFilterInterface.getNumericFilter(homeSerachFilterObj.Deal_Units_Stamp_Duty, 'Stamp_Duty_Total__c');
            if(numericFilterList.size() > 0) {
                filterJSON.addAll(numericFilterList);
            }
        }
        if(!String.isBlank(homeSerachFilterObj.Deal_Units_VIN)){   
            filterJSON.add(new HomeSearchFilterInterface.FieldFilter('Customer_Owned_Unit__r.VIN_Number_Formula__c', 'LIKE', '\'' + homeSerachFilterObj.Deal_Units_VIN + '%\''));
        }
         if(!String.isBlank(homeSerachFilterObj.Deal_Units_New_Unit) && homeSerachFilterObj.Deal_Units_New_Unit != '0'){   
            filterJSON.add(new HomeSearchFilterInterface.FieldFilter('Customer_Owned_Unit__r.New_Unit__c', '=', ((homeSerachFilterObj.Deal_Units_New_Unit == 'Yes') ? true : false)));
        }
        if(!String.isBlank(homeSerachFilterObj.Deal_Units_Category)){   
            filterJSON.add(new HomeSearchFilterInterface.FieldFilter('Customer_Owned_Unit__r.Category__r.Name', 'LIKE', '\'' + homeSerachFilterObj.Deal_Units_Category + '%\''));
        }
        if(homeSerachFilterObj.Deal_Units_Stocked_In != null && !String.isBlank(homeSerachFilterObj.Deal_Units_Stocked_In.SelectedOption)) {
            List<HomeSearchFilterInterface.FieldFilter> stockInFilterJSON = HomeSearchFilterInterface.getDateFilter(homeSerachFilterObj.Deal_Units_Stocked_In, 'Customer_Owned_Unit__r.Date_Stocked_In__c', false);
            if(stockInFilterJSON.size() > 0) {
                filterJSON.addAll(stockInFilterJSON);
            }
        }
        if(homeSerachFilterObj.Deal_Units_Age != null && !String.isBlank(homeSerachFilterObj.Deal_Units_Age.SelectedOption) && homeSerachFilterObj.Deal_Units_Age.SelectedOption != '0'){   
            List<HomeSearchFilterInterface.FieldFilter> numericFilterList = HomeSearchFilterInterface.getNumericFilter(homeSerachFilterObj.Deal_Units_Age, 'Customer_Owned_Unit__r.Age__c');
            if(numericFilterList.size() > 0) {
               filterJSON.addAll(numericFilterList);
            }  
        }
        if(homeSerachFilterObj.Deal_Units_Confirmed_Sale != null && !String.isBlank(homeSerachFilterObj.Deal_Units_Confirmed_Sale.SelectedOption)) {
            if(homeSerachFilterObj.Deal_Units_Confirmed_Sale.SelectedOption == '0') {
                filterJSON.add(new HomeSearchFilterInterface.FieldFilter('Deal__r.Confirmed_Sale_Date__c', '!=', null));
            } else {
                List<HomeSearchFilterInterface.FieldFilter> stockInFilterJSON = HomeSearchFilterInterface.getDateFilter(homeSerachFilterObj.Deal_Units_Confirmed_Sale, 'Deal__r.Confirmed_Sale_Date__c', false);
                if(stockInFilterJSON.size() > 0) {
                    filterJSON.addAll(stockInFilterJSON);
                }
            }
        }
        //Tags
        if(homeSerachFilterObj.Deal_Units_Mileage !=null && !String.isBlank(homeSerachFilterObj.Deal_Units_Mileage.SelectedOption) && homeSerachFilterObj.Deal_Units_Mileage.SelectedOption != '0'){
            List<HomeSearchFilterInterface.FieldFilter> numericFilterList = HomeSearchFilterInterface.getNumericFilter(homeSerachFilterObj.Deal_Units_Mileage, 'Customer_Owned_Unit__r.Mileage_Value__c');
            if(numericFilterList.size() > 0) {
                filterJSON.addAll(numericFilterList);
            }
        }     
        if(!String.isBlank(homeSerachFilterObj.Deal_Units_Mileage_Type)){   
            filterJSON.add(new HomeSearchFilterInterface.FieldFilter('Customer_Owned_Unit__r.Mileage_Type__c', 'LIKE', '\'' + homeSerachFilterObj.Deal_Units_Mileage_Type + '%\''));
        }
        if(!String.isBlank(homeSerachFilterObj.Deal_Units_Ext_Color)){   
            filterJSON.add(new HomeSearchFilterInterface.FieldFilter('Customer_Owned_Unit__r.Colour__c', 'LIKE', '\'' + homeSerachFilterObj.Deal_Units_Ext_Color + '%\''));
        }
        if(!String.isBlank(homeSerachFilterObj.Deal_Units_Int_Color)){   
            filterJSON.add(new HomeSearchFilterInterface.FieldFilter('Customer_Owned_Unit__r.Interior_Colour__c', 'LIKE', '\'' + homeSerachFilterObj.Deal_Units_VIN + '%\''));
        }
        if(homeSerachFilterObj.Include_Quotes == null || !homeSerachFilterObj.Include_Quotes) {
            filterJSON.add(new HomeSearchFilterInterface.FieldFilter('Deal__r.Status__c', '!=', '\'Quotation\''));
        }
        if(!String.isBlank(homeSerachFilterObj.Deal_Units_Compliance_Date)){   
            filterJSON.add(new HomeSearchFilterInterface.FieldFilter('Customer_Owned_Unit__r.Compliance_Date__c', 'LIKE', '\'' + homeSerachFilterObj.Deal_Units_Compliance_Date + '%\''));
        }
        if(!String.isBlank(homeSerachFilterObj.Deal_Units_Year_Of_1st_Rego)){   
            filterJSON.add(new HomeSearchFilterInterface.FieldFilter('Customer_Owned_Unit__r.Year_Of_1st_Rego__c', 'LIKE', '\'' + homeSerachFilterObj.Deal_Units_Year_Of_1st_Rego + '%\''));
        }
        if(!String.isBlank(homeSerachFilterObj.Deal_Units_Registration_Serial)){   
            filterJSON.add(new HomeSearchFilterInterface.FieldFilter('Customer_Owned_Unit__r.Registration_Serial__c', 'LIKE', '\'' + homeSerachFilterObj.Deal_Units_Registration_Serial + '%\''));
        }
        if(homeSerachFilterObj.Deal_Units_Manufactured_Date != null && !String.isBlank(homeSerachFilterObj.Deal_Units_Manufactured_Date.SelectedOption)) {
            List<HomeSearchFilterInterface.FieldFilter> stockInFilterJSON = HomeSearchFilterInterface.getDateFilter(homeSerachFilterObj.Deal_Units_Manufactured_Date, 'Customer_Owned_Unit__r.Manufactured_Date__c', false);
            if(stockInFilterJSON.size() > 0) {
                filterJSON.addAll(stockInFilterJSON);
            }
        }
        if(homeSerachFilterObj.Deal_Units_Confirmed_Sale != null && !String.isBlank(homeSerachFilterObj.Deal_Units_Confirmed_Sale.SelectedOption)) {
            if(homeSerachFilterObj.Deal_Units_Confirmed_Sale.SelectedOption == '0') {
                filterJSON.add(new HomeSearchFilterInterface.FieldFilter('Deal__r.Confirmed_Sale_Date__c', '!=', null));
            } else {
                List<HomeSearchFilterInterface.FieldFilter> stockInFilterJSON = HomeSearchFilterInterface.getDateFilter(homeSerachFilterObj.Deal_Units_Confirmed_Sale, 'Deal__r.Confirmed_Sale_Date__c', false);
                if(stockInFilterJSON.size() > 0) {
                    filterJSON.addAll(stockInFilterJSON);
                }
            }
        }
        if(!String.isBlank(homeSerachFilterObj.Deal_Units_First_Name)){   
            filterJSON.add(new HomeSearchFilterInterface.FieldFilter('Deal__r.CO_Header__r.Customer__r.FirstName__c', 'LIKE', '\'' + homeSerachFilterObj.Deal_Units_First_Name + '%\''));
        }
        if(!String.isBlank(homeSerachFilterObj.Deal_Units_Last_Name)){   
            filterJSON.add(new HomeSearchFilterInterface.FieldFilter('Deal__r.CO_Header__r.Customer__r.LastName__c', 'LIKE', '\'' + homeSerachFilterObj.Deal_Units_Last_Name + '%\''));
        }
        if(!String.isBlank(homeSerachFilterObj.Deal_Units_Address)){   
            filterJSON.add(new HomeSearchFilterInterface.FieldFilter('Deal__r.CO_Header__r.Customer__r.BillingStreet', 'LIKE', '\'' + homeSerachFilterObj.Deal_Units_Address + '%\''));
        }
        if(!String.isBlank(homeSerachFilterObj.Deal_Units_City)){   
            filterJSON.add(new HomeSearchFilterInterface.FieldFilter('Deal__r.CO_Header__r.Customer__r.BillingCity', 'LIKE', '\'' + homeSerachFilterObj.Deal_Units_City + '%\''));
        }
        if(!String.isBlank(homeSerachFilterObj.Deal_Units_State)){   
            filterJSON.add(new HomeSearchFilterInterface.FieldFilter('Deal__r.CO_Header__r.Customer__r.BillingState', 'LIKE', '\'' + homeSerachFilterObj.Deal_Units_State + '%\''));
        }
        if(!String.isBlank(homeSerachFilterObj.Deal_Units_Postal)){   
            filterJSON.add(new HomeSearchFilterInterface.FieldFilter('Deal__r.CO_Header__r.Customer__r.BillingPhone', 'LIKE', '\'' + homeSerachFilterObj.Deal_Units_Postal + '%\''));
        }
        if(!String.isBlank(homeSerachFilterObj.Deal_Units_Phone)){  
            filterJSON.add(new HomeSearchFilterInterface.FieldFilter('',  '', (' (Deal__r.CO_Header__r.Customer__r.Preferred_Phone__c Like \'%' + homeSerachFilterObj.Deal_Units_Phone + '%\''
                                                + ' OR Deal__r.CO_Header__r.Customer__r.Phone Like \'%' + homeSerachFilterObj.Deal_Units_Phone + '%\''
                                                + ' OR Deal__r.CO_Header__r.Customer__r.Home_Number__c Like \'%' + homeSerachFilterObj.Deal_Units_Phone + '%\''
                                                + ' OR Deal__r.CO_Header__r.Customer__r.Preferred_SMS__c Like \'%' + homeSerachFilterObj.Deal_Units_Phone + '%\''
                                                + ' OR Deal__r.CO_Header__r.Customer__r.Work_Number__c Like \'%' + homeSerachFilterObj.Deal_Units_Phone + '%\')') ));
        }
        if(!String.isBlank(homeSerachFilterObj.Deal_Units_Mobile)){   
            filterJSON.add(new HomeSearchFilterInterface.FieldFilter('Deal__r.CO_Header__r.Customer__r.Mobile__c', 'LIKE', '\'' + homeSerachFilterObj.Deal_Units_Mobile + '%\''));
        }
        if(!String.isBlank(homeSerachFilterObj.Deal_Units_Email)){
            filterJSON.add(new HomeSearchFilterInterface.FieldFilter('',  '', (' (Deal__r.CO_Header__r.Customer__r.Preferred_Email__c Like \'%' + homeSerachFilterObj.Deal_Units_Email + '%\''
                                                + ' OR Deal__r.CO_Header__r.Customer__r.Email__c Like \'%' + homeSerachFilterObj.Deal_Units_Email + '%\''
                                                + ' OR Deal__r.CO_Header__r.Customer__r.Work_Email__c Like \'%' + homeSerachFilterObj.Deal_Units_Email + '%\')') ));
        }
        if(!String.isBlank(homeSerachFilterObj.Deal_Units_Other_Email)){   
            filterJSON.add(new HomeSearchFilterInterface.FieldFilter('Deal__r.CO_Header__r.Customer__r.Other_Email__c', 'LIKE', '\'' + homeSerachFilterObj.Deal_Units_Other_Email + '%\''));
        }
    }

    public static void setFilterJSONForVOItems(List<HomeSearchFilterInterface.FieldFilter> filterJSON, HomeSearchFilterWrapper homeSerachFilterObj) {
        filterJSON.add(new HomeSearchFilterInterface.FieldFilter('', '', 'Line_Item_Status__c IN (\'In Receiving\', \'On Order\')'));
        filterJSON.add(new HomeSearchFilterInterface.FieldFilter('Vendor_Order_Header__c', '!=', null));
        if(String.isNotBlank(homeSerachFilterObj.VO_Items_Vendor)) {
            filterJSON.add(new HomeSearchFilterInterface.FieldFilter('Vendor_Order_Header__r.Vendor__r.Name', 'Like', '\'' +homeSerachFilterObj.VO_Items_Vendor + '%\''));
        }
        if(String.isNotBlank(homeSerachFilterObj.VO_Items_Item_Description)) {
            filterJSON.add(new HomeSearchFilterInterface.FieldFilter('Item_Description__c', 'Like', '\'%' +homeSerachFilterObj.VO_Items_Item_Description + '%\''));
        }
        if(String.isNotBlank(homeSerachFilterObj.VO_Items_VO_Number)) {
            filterJSON.add(new HomeSearchFilterInterface.FieldFilter('Vendor_Order_Header__r.Name', 'Like', '\'%' +homeSerachFilterObj.VO_Items_VO_Number + '%\''));
        }
        if(String.isNotBlank(homeSerachFilterObj.VO_Items_Customer)) {
            filterJSON.add(new HomeSearchFilterInterface.FieldFilter('Customer__c', 'Like', '\'' +homeSerachFilterObj.VO_Items_Customer + '%\''));
        }
        if(String.isNotBlank(homeSerachFilterObj.VO_Items_Needed_For) && homeSerachFilterObj.VO_Items_Needed_For != '0'){   
            if(homeSerachFilterObj.VO_Items_Needed_For == 'Part Sale') {
                filterJSON.add(new HomeSearchFilterInterface.FieldFilter('Is_required_For_Customer__c', '=', true));
                filterJSON.add(new HomeSearchFilterInterface.FieldFilter('Is_Service__c', '=', false));
            } else if(homeSerachFilterObj.VO_Items_Needed_For == 'Service') {
                filterJSON.add(new HomeSearchFilterInterface.FieldFilter('Is_required_For_Customer__c', '=', false));
                filterJSON.add(new HomeSearchFilterInterface.FieldFilter('Is_Service__c', '=', true));
            }  else if(homeSerachFilterObj.VO_Items_Needed_For == 'Stock') {
                filterJSON.add(new HomeSearchFilterInterface.FieldFilter('Is_required_For_Customer__c', '=', false));
                filterJSON.add(new HomeSearchFilterInterface.FieldFilter('Is_Service__c', '=', false));
            }
        }
        if(homeSerachFilterObj.VO_Items_Ordered != null && !String.isBlank(homeSerachFilterObj.VO_Items_Ordered.SelectedOption) && homeSerachFilterObj.VO_Items_Ordered.SelectedOption != '0') {
            List<HomeSearchFilterInterface.FieldFilter> orderedFilterJSON = HomeSearchFilterInterface.getDateFilter(homeSerachFilterObj.VO_Items_Ordered, 'Vendor_Order_Header__r.Ordered_Date__c', false);
            if(orderedFilterJSON.size() > 0) {  
                filterJSON.addAll(orderedFilterJSON);
            }
        }
        if(homeSerachFilterObj.VO_Items_Expected != null && !String.isBlank(homeSerachFilterObj.VO_Items_Expected.SelectedOption) && homeSerachFilterObj.VO_Items_Expected.SelectedOption != '0') {
            List<HomeSearchFilterInterface.FieldFilter> expectedFilterJSON = HomeSearchFilterInterface.getDateFilter(homeSerachFilterObj.VO_Items_Expected, 'Vendor_Order_Header__r.Expected_Date_Formula__c', false);
            if(expectedFilterJSON.size() > 0) {  
                filterJSON.addAll(expectedFilterJSON);
            }
        }
        if(homeSerachFilterObj.VO_Items_Quantity != null && !String.isBlank(homeSerachFilterObj.VO_Items_Quantity.SelectedOption) && homeSerachFilterObj.VO_Items_Quantity.SelectedOption != '0'){
            List<HomeSearchFilterInterface.FieldFilter> numericFilterList = HomeSearchFilterInterface.getNumericFilter(homeSerachFilterObj.VO_Items_Quantity, 'Qty_Needed__c');
            if(numericFilterList.size() > 0) {
                filterJSON.addAll(numericFilterList);
            }
        }
        if(homeSerachFilterObj.VO_Items_Total_Cost != null && !String.isBlank(homeSerachFilterObj.VO_Items_Total_Cost.SelectedOption) && homeSerachFilterObj.VO_Items_Total_Cost.SelectedOption != '0'){
            List<HomeSearchFilterInterface.FieldFilter> numericFilterList = HomeSearchFilterInterface.getNumericFilter(homeSerachFilterObj.VO_Items_Total_Cost, 'Total_Cost__c');
            if(numericFilterList.size() > 0) {
                filterJSON.addAll(numericFilterList);
            }
        }
    }

    public static void setFilterJSONForVendorReturns(List<HomeSearchFilterInterface.FieldFilter> filterJSON, HomeSearchFilterWrapper homeSerachFilterObj) {
    	if(homeSerachFilterObj.Vendor_Ordering_Total !=null && !String.isBlank(homeSerachFilterObj.Vendor_Ordering_Total.SelectedOption) && homeSerachFilterObj.Vendor_Ordering_Total.SelectedOption != '0'){
            List<HomeSearchFilterInterface.FieldFilter> numericFilterList = HomeSearchFilterInterface.getNumericFilter(homeSerachFilterObj.Vendor_Ordering_Total, 'Total__c');
            if(numericFilterList.size() > 0) {
                filterJSON.addAll(numericFilterList);
            }
        }
        if(!String.isBlank(homeSerachFilterObj.Vendor_Ordering_Vendor)){
            filterJSON.add(new HomeSearchFilterInterface.FieldFilter('Vendor__r.Name', 'Like', '\'%'+ homeSerachFilterObj.Vendor_Ordering_Vendor + '%\''));
        }
        if(homeSerachFilterObj.Vendor_Return_Credits_Pending !=null &&  !String.isBlank(homeSerachFilterObj.Vendor_Return_Credits_Pending.SelectedOption) && homeSerachFilterObj.Vendor_Return_Credits_Pending.SelectedOption != '0'){
            List<HomeSearchFilterInterface.FieldFilter> numericFilterList = HomeSearchFilterInterface.getNumericFilter(homeSerachFilterObj.Vendor_Return_Credits_Pending, 'Credits_Pending_Reporting__c');
            if(numericFilterList.size() > 0) {
                filterJSON.addAll(numericFilterList);
            }
        }
        if(!String.isBlank(homeSerachFilterObj.Vendor_Return_RMA)) {
            filterJSON.add(new HomeSearchFilterInterface.FieldFilter('RMA__c', 'LIKE', '\'' + homeSerachFilterObj.Vendor_Return_RMA + '%\''));
        }
        if(!String.isBlank(homeSerachFilterObj.Vendor_Return_Tracking)) {
            filterJSON.add(new HomeSearchFilterInterface.FieldFilter('Tracking_Number__c', 'LIKE', '\'' + homeSerachFilterObj.Vendor_Return_Tracking + '%\''));
        }
    }
    
	public static void setFilterLabelsForVendorReturns(List<HomeSearchFilterInterface.FilterLabel> filterLables, HomeSearchFilterWrapper homeSerachFilterObj) {
    	if(homeSerachFilterObj.Vendor_Ordering_Total !=null && !String.isBlank(homeSerachFilterObj.Vendor_Ordering_Total.SelectedOption) && homeSerachFilterObj.Vendor_Ordering_Total.SelectedOption != '0'){
            String modifiedLabelName = HomeSearchFilterInterface.optionValueToNumberValueLabelMap.containsKey(homeSerachFilterObj.Vendor_Ordering_Total.SelectedOption) ? HomeSearchFilterInterface.optionValueToNumberValueLabelMap.get(homeSerachFilterObj.Vendor_Ordering_Total.SelectedOption) : homeSerachFilterObj.Vendor_Ordering_Total.SelectedOption;
            if(modifiedLabelName == '5') {
                filterLables.add(new HomeSearchFilterInterface.FilterLabel('Vendor_Ordering_Total', 'Total', homeSerachFilterObj.Vendor_Ordering_Total.Value1 + ' To ' + homeSerachFilterObj.Vendor_Ordering_Total.Value2));
            } else {
                filterLables.add(new HomeSearchFilterInterface.FilterLabel('Vendor_Ordering_Total', 'Total', modifiedLabelName + ' ' + homeSerachFilterObj.Vendor_Ordering_Total.Value1));
            }
        }
                
        if(!String.isBlank(homeSerachFilterObj.Vendor_Ordering_Vendor)){
            filterLables.add(new HomeSearchFilterInterface.FilterLabel('Vendor_Ordering_Vendor', 'Vendor', homeSerachFilterObj.Vendor_Ordering_Vendor));
        }

        if(homeSerachFilterObj.Vendor_Return_Credits_Pending !=null && !String.isBlank(homeSerachFilterObj.Vendor_Return_Credits_Pending.SelectedOption) && homeSerachFilterObj.Vendor_Return_Credits_Pending.SelectedOption != '0'){
            String modifiedLabelName = HomeSearchFilterInterface.optionValueToNumberValueLabelMap.containsKey(homeSerachFilterObj.Vendor_Return_Credits_Pending.SelectedOption) ? HomeSearchFilterInterface.optionValueToNumberValueLabelMap.get(homeSerachFilterObj.Vendor_Return_Credits_Pending.SelectedOption) : homeSerachFilterObj.Vendor_Return_Credits_Pending.SelectedOption;
            if(modifiedLabelName == '5') {
                filterLables.add(new HomeSearchFilterInterface.FilterLabel('Vendor_Return_Credits_Pending', 'Credits Pending', homeSerachFilterObj.Vendor_Return_Credits_Pending.Value1 + ' To ' + homeSerachFilterObj.Vendor_Return_Credits_Pending.Value2));
            } else {
                filterLables.add(new HomeSearchFilterInterface.FilterLabel('Vendor_Return_Credits_Pending', 'Credits Pending', modifiedLabelName + ' ' + homeSerachFilterObj.Vendor_Return_Credits_Pending.Value1));
            }
        }
                
        if(!String.isBlank(homeSerachFilterObj.Vendor_Return_RMA)){
            filterLables.add(new HomeSearchFilterInterface.FilterLabel('Vendor_Return_RMA', 'RMA#', homeSerachFilterObj.Vendor_Return_RMA));
        }
                
        if(!String.isBlank(homeSerachFilterObj.Vendor_Return_Tracking)){
            filterLables.add(new HomeSearchFilterInterface.FilterLabel('Vendor_Return_Tracking', 'Tracking#', homeSerachFilterObj.Vendor_Return_Tracking));
        }
    }
}