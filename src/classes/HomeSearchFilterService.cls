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
    	if(objName == 'Customer Invoice Details COLI') {
    		filterJSON.add(new HomeSearchFilterInterface.FieldFilter('Service_Order_Line_Item__c', '=', 'null'));
    		//filterJSON.add(new HomeSearchFilterInterface.FieldFilter('Is_Unresolved_Fulfillment_Exists__c', '=', 'null'));
    		filterJSON.add(new HomeSearchFilterInterface.FieldFilter('Invoice_Number__c', '!=', 'null'));
    		
            invoiceDateField = 'Invoice_Number__r.Invoice_Date__c';
            if(!String.isBlank(homeSerachFilterObj.Customer_Invoice_Detail_Salesperson)) {
            	filterJSON.add(new HomeSearchFilterInterface.FieldFilter('',  '', '((Deal__c != null AND Deal__r.Salesperson_Name__c Like \'%' + homeSerachFilterObj.Customer_Invoice_Detail_Salesperson + '%\')'
                                                + ' OR ( Deal__c = null AND CO_Header__r.Owner__r.Name Like \'%' + homeSerachFilterObj.Customer_Invoice_Detail_Salesperson + '%\'))'));
            }
    	} else if(objName == 'Customer Invoice Details SOLI') {
    		filterJSON.add(new HomeSearchFilterInterface.FieldFilter('Service_Order_Header__r.Invoice_Number__c', '!=', 'null'));
    		
            invoiceDateField = 'Service_Order_Header__r.Invoice_Number__r.Invoice_Date__c';
            if(!String.isBlank(homeSerachFilterObj.Customer_Invoice_Detail_Salesperson)) {
            	filterJSON.add(new HomeSearchFilterInterface.FieldFilter('',  '', '((Deal__c != null AND Deal__r.Salesperson_Name__c Like \'%' + homeSerachFilterObj.Customer_Invoice_Detail_Salesperson + '%\')'
                                                + ' OR ( Deal__c = null AND Service_Order_Header__r.CO_Header__r.Owner__r.Name Like \'%' + homeSerachFilterObj.Customer_Invoice_Detail_Salesperson + '%\'))'));
            }
    	} else if(objName == 'Customer Invoice Details Option and Fee') {
    		filterJSON.add(new HomeSearchFilterInterface.FieldFilter('Deal__r.Invoice_Number__c', '!=', 'null'));
    		
    		invoiceDateField = 'Deal__r.Invoice_Number__r.Invoice_Date__c';
    		salesPersonField = 'Deal__r.Salesperson_Name__c';
    	} else if(objName == 'Customer Invoice Details Deal UPC') {
    		filterJSON.add(new HomeSearchFilterInterface.FieldFilter('Deal_Item__r.Deal__r.Invoice_Number__c', '!=', 'null'));
    		
    		invoiceDateField = 'Deal_Item__r.Deal__r.Invoice_Number__r.Invoice_Date__c';
    		salesPersonField = 'Deal_Item__r.Deal__r.Salesperson_Name__c';
    	} else if(objName == 'Customer Invoice Details Trade in') {
    		filterJSON.add(new HomeSearchFilterInterface.FieldFilter('Type__c', '=', '\'Trade In\''));
    		filterJSON.add(new HomeSearchFilterInterface.FieldFilter('Deal__r.Invoice_Number__c', '!=', 'null'));
    		
    		invoiceDateField = 'Deal__r.Invoice_Number__r.Invoice_Date__c';
    		salesPersonField = 'Deal__r.Salesperson_Name__c';
    	} else if(objName == 'Customer Invoice Details FI Product') {
    		filterJSON.add(new HomeSearchFilterInterface.FieldFilter('Deal_Finance__r.Deal__r.Invoice_Number__c', '!=', 'null'));
    		
    		invoiceDateField = 'Deal_Finance__r.Deal__r.Invoice_Number__r.Invoice_Date__c';
    		salesPersonField = 'Deal_Finance__r.Deal__r.Salesperson_Name__c';
    	}
    	
    	if(homeSerachFilterObj.Customer_Invoice_Detail_Invoice_Date != null && String.isNotBlank(homeSerachFilterObj.Customer_Invoice_Detail_Invoice_Date.SelectedOption)) {
            List<HomeSearchFilterInterface.FieldFilter> invoiceDateFilterJSON = HomeSearchFilterInterface.getDateFilter(homeSerachFilterObj.Customer_Invoice_Detail_Invoice_Date, invoiceDateField, true, true);
            if(invoiceDateFilterJSON.size() > 0) {
                filterJSON.addAll(invoiceDateFilterJSON);
            }
        }
        
    	if(!String.isBlank(salesPersonField) && !String.isBlank(homeSerachFilterObj.Customer_Invoice_Detail_Salesperson)) {
            filterJSON.add(new HomeSearchFilterInterface.FieldFilter(salesPersonField, 'Like', '\'%' +homeSerachFilterObj.Customer_Invoice_Detail_Salesperson + '%\''));
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
}