public without sharing class MerchandiseService {
    
    public static String deleteCOLI(String coLineItemId) {
    	try{
    		String dealId;
	    	if(AccessControl.ifObjectFieldIsAccessible('CO_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
	        
	        coLineItemId = BPUtility.escapeSingleQuotes(coLineItemId);
	        List<CO_Line_Item__c> coLineItemToDelete = [select CO_Header__c, Closed_CO_Invoice_link__c, Deal__c from CO_Line_Item__c where Id = :coLineItemId];
	        String coHeaderId = coLineItemToDelete.size() > 0 ? coLineItemToDelete[0].CO_Header__c : '';
	        if(coLineItemToDelete.size() > 0 && String.isBlank(coLineItemToDelete[0].Closed_CO_Invoice_link__c)) {
	            dealId = coLineItemToDelete[0].Deal__c;
	            DealService.createDealUnresolvedFulfillment(new List<String>{coLineItemToDelete[0].Id}, dealId, Constants.UNRESOLVED_FULFILLMENT_TYPE_REMOVED);
	            if(AccessControl.ifObjectIsDeletable('CO_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
	            delete coLineItemToDelete;
	            
	            COService.validateAndCloseCO(coHeaderId);
	            if(dealId != null && !Test.isRunningTest()) {
	                COSectionDetailService.checkAndDeleteCOSection_future(coHeaderId, COSectionDetailService.DEAL_MERCHANDISE);
	            } else {
                    COSectionDetailService.setSectionStatus(new Set<Id>{coHeaderId}, COSectionDetailService.MERCHANDISE);
                }
	        }
	        
	        return dealId;
       	}catch(Exception e){
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }

    public static String insertMerchKit(String jsonStr, String coHeaderId) {
        if(AccessControl.ifObjectFieldIsAccessible('CO_Kit_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
            if(AccessControl.ifObjectFieldIsAccessible('CO_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
            if(AccessControl.ifObjectFieldIsUpdateable('CO_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
            
            Boolean isAddLinkedFee = false;
            CustomerOrderWrapper.LineItemWrapper jsonObj = (CustomerOrderWrapper.LineItemWrapper) System.JSON.deserialize(jsonStr, CustomerOrderWrapper.LineItemWrapper.class);            
            if(String.isBlank(coHeaderId)) {
                coHeaderId = BPUtility.getDecodedString(BPGlobalHeaderCtrl.createCustomerOrder()); 
                isAddLinkedFee = true; 
            }

            if(isAddLinkedFee) {
                List<SObject> sObjectListToInsert = COService.addLinkedFee(coHeaderId, null, 'Merchandise');
                DMLUtility.insertSobjectList('CO_Line_Item__c', sObjectListToInsert);
                
                // Add CO Section Detail record for Merchandise section when first record is added in Merchandise section.
                COSectionDetailService.createCOSection(coHeaderId, COSectionDetailService.MERCHANDISE);
            }

            List<Kit_Header__c> kitHeaderList = SOQLUtil.getKitHeaderRec(new Map<String, String>{ 'Id' => jsonObj.EntityId });
            if(kitHeaderList.size() == 0 || kitHeaderList[0].Service_Kit__c) {
                return coHeaderId;
            }
            
            CO_Kit_Header__c cokhRec = new CO_Kit_Header__c();
            cokhRec.CO_Header__c = coHeaderId;
            cokhRec.Kit_Header__c = kitHeaderList[0].Id;
            cokhRec.Price__c = kitHeaderList[0].Fixed_Price__c;
            cokhRec.Actual_Kit_Price__c = kitHeaderList[0].Fixed_Price__c;
            cokhRec.Can_Split__c = kitHeaderList[0].Can_Split__c;
            cokhRec.Fixed_Price_Flag__c = kitHeaderList[0].Fixed_Price_Flag__c;
            cokhRec.Service_Kit__c = kitHeaderList[0].Service_Kit__c;
            cokhRec.UUID__c = jsonObj.UUID;
            
            DMLUtility.insertSobjectList('CO_Kit_Header__c', cokhRec);
            COLineItemTriggerHelper.isTotalCalculated = true;
            insertAllKitLineItemsInMerchGrid(jsonObj.EntityId, coHeaderId, cokhRec.Id, null);            
            COLineItemTriggerHelper.isTotalCalculated = false;
            
        //COKH_Recalcualtion.CoKitInsert(cokhRec.Id, coHeaderId) ;
        COKH_Recalcualtion.calculatePriceForCOKitInsertion(cokhRec.Id, coHeaderId);
            updateMerchSectionToDisplay(coHeaderId, false);
            return (!COLineItemTriggerHelper.isMoveLineItem ? coHeaderId : cokhRec.Id);
    }
    
    /**
    * Name: insertAllKitLineItemsInMerchGrid
    * Desc: Method to insert all line item in merch Grid
    * @param:   (1) lineItemId - String - id of line item
                (2) coHeaderId - String - id of coHeader 
                (3) cokhRecId - String - id of co kit header 
    * @return: void 
    **/
    public static void insertAllKitLineItemsInMerchGrid(String lineItemId, String coHeaderId, String cokhRecId, String dealId) {
        List<Kit_Header_Line_Item__c> khLineItemList = SOQLUtil.getKHLineItemRec(new Map<String, String>{ 'Kit_Header__c' => lineItemId });
        if(khLineItemList.size() == 0) {
            return;
        }
        List<CO_Header__c> coHeaderList = String.isBlank(dealId) ? [Select Merchandise_Commit_Order_controls__c FROM CO_Header__c WHERE Id =: coHeaderId] : new List<CO_Header__c>();
        List<CO_Line_Item__c> coliListToInsert = new List<CO_Line_Item__c>();
        Boolean isNonInventoryPartAvailable = false;
        for(Kit_Header_Line_Item__c khliRec : khLineItemList) {
            CO_Line_Item__c coliRec = new CO_Line_Item__c(Kit_Header_Line_Item__c = khliRec.Id);
            
            coliRec.CO_Header__c = coHeaderId;
            coliRec.CO_Kit_Header__c = cokhRecId;
            coliRec.Deal__c = dealId;
            if(String.isBlank(dealId) && khliRec.Part__c != null && !coHeaderList.isEmpty()) {
                coliRec.Merchandise_Commit_Order_controls__c = coHeaderList[0].Merchandise_Commit_Order_controls__c;
            }
            if(khliRec.Part__c != null) {
                coliRec.Part__c = khliRec.Part__c;
                coliRec.Actual_Retail_Price__c = khliRec.Part__r.Retail_Price__c;
                if(khliRec.Part__r.Non_Inventory_Part__c) {
                    isNonInventoryPartAvailable = true;
                }
            } else if(khliRec.Fee__c != null) { // Removed else if comment by Pooja 21 Nov. 2016 (Issue# '$' icon is not displayed for Fee in Kit in CO Merchandise section)
                coliRec.Fee__c = khliRec.Fee__c;
            }
            coliRec.Fixed_Price__c = khliRec.Fixed_Price__c;
            coliRec.Price_When_Tax_Included__c = coliRec.Price__c = coliRec.Actual_Kit_Price__c = khliRec.Kit_Price__c;
            coliRec.Qty__c = khliRec.Qty_Needed__c;
            coliRec.Item_Code__c = khliRec.Item_Code__c;
            coliRec.Item_Description__c = khliRec.Item_Description__c;
            coliListToInsert.add(coliRec);
        }
        if(coliListToInsert.size() > 0) {
            DMLUtility.insertSobjectList('CO_Line_Item__c', coliListToInsert);
            if(isNonInventoryPartAvailable) {
                COSectionDetailService.setSectionStatus_future(new Set<Id>{coHeaderId}, COSectionDetailService.MERCHANDISE);
            }
        }
    }
    
    
    /**
    * Name: removeCOKHItems
    * Desc: Method to remove kit header items
    * @param:   (1) lineItemId - String - id of line item
    * @return: void
    **/
    public static String removeCOKHItems(String lineItemId) {
        if(AccessControl.ifObjectFieldIsAccessible('CO_Kit_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectFieldIsAccessible('CO_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectIsDeletable('CO_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
        if(AccessControl.ifObjectIsDeletable('CO_Kit_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
        
        lineItemId = BPUtility.escapeSingleQuotes(lineItemId);
        List<CO_Kit_Header__c> cokhList = [select Id, Deal__c, CO_Header__c, (Select Id from CO_Line_Items__r) from CO_Kit_Header__c where Id =: lineItemId];
        String coHeaderId = cokhList.size() > 0 ? cokhList[0].CO_Header__c : '';
        String dealId;
        if(cokhList.size() > 0) {
            dealId = cokhList[0].Deal__c;
        }
        List<CO_Line_Item__c> coliListToDelete = new List<CO_Line_Item__c>();
        for(CO_Kit_Header__c cokhRec : cokhList) {
            if(cokhRec.CO_Line_Items__r != null && cokhRec.CO_Line_Items__r.size() > 0) {
                coliListToDelete.addAll(cokhRec.CO_Line_Items__r);
            }
        }
        
        DealService.createDealUnresolvedFulfillment(new List<String>{cokhList[0].Id}, dealId, Constants.UNRESOLVED_FULFILLMENT_TYPE_REMOVED);
        
        if(coliListToDelete.size() > 0) {
            delete coliListToDelete;
        }
        if(cokhList.size() > 0) {
            delete cokhList;
            if(dealId != null) {
                COSectionDetailService.checkAndDeleteCOSection_future(coHeaderId, COSectionDetailService.DEAL_MERCHANDISE);
            } else {
                COSectionDetailService.setSectionStatus(new Set<Id>{coHeaderId}, COSectionDetailService.MERCHANDISE);
            }
            COService.validateAndCloseCO(coHeaderId);
        }
        
        return dealId;
    }
    
    
    public static void splitCOKHItem(String lineItemId, String coHeaderId) {
    	lineItemId = BPUtility.escapeSingleQuotes(lineItemId);
        
        if(AccessControl.ifObjectFieldIsAccessible('CO_Kit_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectFieldIsAccessible('CO_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectIsDeletable('CO_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
        if(AccessControl.ifObjectIsDeletable('CO_Kit_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
        List<CO_Kit_Header__c> cokhList = [select Id,
                                            (select Merchandise_Commit_Order_controls__c, CO_Header__c, Qty__c, Part__c, Part__r.Non_Inventory_Part__c, Fee__c from CO_Line_items__r)     
                                            from CO_Kit_Header__c where Id =: lineItemId];
        
        List<CO_Line_Item__c> coLineItemListToInsert = new List<CO_Line_Item__c>();
        List<CO_Line_Item__c> coLineItemListToDelete = new List<CO_Line_Item__c>();
        
        for(CO_Kit_Header__c cokhRec : cokhList) {
            for(CO_Line_Item__c coliRec : cokhRec.CO_Line_items__r) {
                CO_Line_Item__c newCOLIRec = new CO_Line_Item__c();
                newCOLIRec.CO_Header__c = coliRec.CO_Header__c;
                newCOLIRec.Qty__c = coliRec.Qty__c;
                newCOLIRec.Part__c = coliRec.Part__c;
                newCOLIRec.Fee__c = coliRec.Fee__c;
                newCOLIRec.Merchandise_Commit_Order_controls__c = coliRec.Merchandise_Commit_Order_controls__c;
                if(coliRec.Fee__c != null || coliRec.Part__r.Non_Inventory_Part__c){
                    newCOLIRec.Qty_Committed__c = coliRec.Qty__c;
                }
                coLineItemListToInsert.add(newCOLIRec);
                coLineItemListToDelete.add(coliRec);
            }
        }

        DMLUtility.deleteSobjectList('CO_Line_Item__c', coLineItemListToDelete);
        DMLUtility.deleteSobjectList('CO_Kit_Header__c', cokhList);
        DMLUtility.insertSobjectList('CO_Line_Item__c', coLineItemListToInsert);
	}
	
    public static String updateCOKHLineItemsRecalculation(String cokhJSON, String coHeaderId, String cokliJson) {
        if(AccessControl.ifObjectFieldIsAccessible('CO_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        COHeaderWrapper.COKitHeader cokhObj = (COHeaderWrapper.COKitHeader) System.JSON.deserialize(cokhJSON, COHeaderWrapper.COKitHeader.class);            
        if(cokliJson != 'null') {    
			COLineItem  coli = (COLineItem) System.JSON.deserialize(cokliJson, COLineItem.class);
            if(String.isNotBlank(coli.FeeId)) {
                CO_Line_Item__c  coliToUpdate  = [select Id, Item_Description__c from CO_Line_Item__c where Id =:coli.CoLineItemId ];
                if(coliToUpdate.Item_Description__c != coli.ItemDescription){
                    coliToUpdate.Item_Description__c = coli.ItemDescription;
                    DMLUtility.updateSobjectList('CO_Line_Item__c', coliToUpdate);
                }                       
            }
            if(!coli.IsFixedPrice && (String.isNotBlank(coli.PartId) || String.isNotBlank(coli.FeeId))) {
                String Result = COKH_Recalcualtion.UpdateKitLineItem(cokhObj, coli, coHeaderId);
                SO_KLI_Recalculation.Errorhandler error = (Result != 'Success') ? new SO_KLI_Recalculation.Errorhandler('300',Result) : new SO_KLI_Recalculation.Errorhandler('200','Saved Successfully');
            }
        } else {    
            if(!cokhObj.IsFixedPrice){
                String Result = COKH_Recalcualtion.UpdateKitHeader(cokhObj);                                
                SO_KLI_Recalculation.Errorhandler error = (Result != 'Success') ? new SO_KLI_Recalculation.Errorhandler('300',Result) : new SO_KLI_Recalculation.Errorhandler('200','Saved Successfully');
            }  
        }
        
        return cokhObj.DealId;           
    }
    
    public static void insertKitHeaderInDealMerchGrid(String jsonStr, String dealId, String coHeaderId) {
    	CustomerOrderWrapper.LineItemWrapper jsonObj = (CustomerOrderWrapper.LineItemWrapper) System.JSON.deserialize(jsonStr, CustomerOrderWrapper.LineItemWrapper.class);            
        List<Kit_Header__c> kitHeaderList = SOQLUtil.getKitHeaderRec(new Map<String, String>{ 'Id' => jsonObj.EntityId });
        if(kitHeaderList.size() == 0 || kitHeaderList[0].Service_Kit__c) {
            return;
        }
        
        CO_Kit_Header__c cokhRec = new CO_Kit_Header__c();
        cokhRec.CO_Header__c = coHeaderId;
        cokhRec.Kit_Header__c = kitHeaderList[0].Id;
        cokhRec.Price__c = kitHeaderList[0].Fixed_Price__c;
        cokhRec.Actual_Kit_Price__c = kitHeaderList[0].Fixed_Price__c;
        cokhRec.Can_Split__c = kitHeaderList[0].Can_Split__c;
        cokhRec.Fixed_Price_Flag__c = kitHeaderList[0].Fixed_Price_Flag__c;
        cokhRec.Service_Kit__c = kitHeaderList[0].Service_Kit__c;
        cokhRec.Deal__c = dealId;
        cokhRec.UUID__c = jsonObj.UUID;
        DMLUtility.insertSobjectList('CO_Kit_Header__c', cokhRec);
        MerchandiseService.insertAllKitLineItemsInMerchGrid(jsonObj.EntityId, coHeaderId, cokhRec.Id, dealId);
        
        //COKH_Recalcualtion.CoKitInsert(cokhRec.Id, coHeaderId);
        COKH_Recalcualtion.calculatePriceForCOKitInsertion(cokhRec.Id, coHeaderId);
        DealService.createDealUnresolvedFulfillment(new List<String>{cokhRec.Id}, dealId, Constants.UNRESOLVED_FULFILLMENT_TYPE_ADDED);            
    }
    
    public static List<ViewKitCtrl.KitHeaderLineItem> getOutOfStockPartsInKit(String kitHeaderId) {
		List<ViewKitCtrl.KitHeaderLineItem> khliObjList = new List<ViewKitCtrl.KitHeaderLineItem>();
		List<Kit_Header_Line_Item__c> khliRecList = SOQLUtil.getKHLineItemRec(new Map<String, String>{'Kit_Header__c' => kitHeaderId});
		for(Kit_Header_Line_Item__c khliRec : khliRecList) {
			if(khliRec.Part__r.AvailableParts__c < khliRec.Qty_Needed__c && !khliRec.Part__r.Non_Inventory_Part__c) {
				khliObjList.add(new ViewKitCtrl.KitHeaderLineItem(khliRec));
			}
		}
		return khliObjList;
    }
    
    public static void oversoldKit(String kitHeaderJSON) {
		COHeaderWrapper.COKitHeader cokhObj = (COHeaderWrapper.COKitHeader) System.JSON.deserialize(kitHeaderJSON, COHeaderWrapper.COKitHeader.class);
		List<CO_Line_Item__c> coliListToUpdate = new List<CO_Line_Item__c>();
		for(COLineItem coliObj : cokhObj.COLIList) {
			coliListToUpdate.add(new CO_Line_Item__c(Id = coliObj.CoLineItemId, Qty_Committed__c = coliObj.Qty));
		}
        update coliListToUpdate;
    }
    
    public static Map<String, ProfitabilityWrapper.SectionProfitabilityWrapper> getMerchAndDealMerchProfitability(String coId) {
    	Map<String, ProfitabilityWrapper.SectionProfitabilityWrapper> sectionTypeToProfitabilityWrapperMap = 
    		new Map<String, ProfitabilityWrapper.SectionProfitabilityWrapper>();
    	
    	List<CO_Line_Item__c> coliList = [SELECT Item_ID__c, Closed_CO_Invoice_link__c, Part__r.Average_Cost__c, Part__r.Last_Cost__c, Part__c, Fee__c, Part__r.Part_Type__c, Qty__c, Price__c, Deal__c, Price_When_Tax_Included__c, 
        	Fee_Cost__c, Adjusted_Cost_Coli__c, Fee__r.Is_Include_In_Profit_Calculation__c, Fee__r.Cost_Method__c, Fee__r.Cost_Rate__c FROM CO_Line_Item__c WHERE Service_Order_Line_Item__c = null AND CO_Header__c =: coId];
       
        Boolean IsTaxIncludingPricing = GeneralConfiguration.getTaxIncludingPricing();
        Decimal partTotal = 0;      
       	if(coliList.size() > 0) {
       		Decimal totalCOPartSales, totalCOMerchSales, totalDealPartSales, totalDealMerchSales, totalCOFeeSales, totalDealFeeSales;
	       	Decimal totalCOPartCost, totalCOMerchCost, totalDealPartCost, totalDealMerchCost, totalCOFeeCost, totalDealFeeCost = 0;
	       	totalCOPartCost = totalCOMerchCost = totalDealPartCost = totalDealMerchCost = totalCOFeeCost = totalDealFeeCost = 0;
	       	
			for(CO_Line_Item__c coli : coliList) {
	        	coli.Price__c = (coli.Price__c != null) ? coli.Price__c : 0;
	           	coli.Qty__c = (coli.Qty__c != null) ? coli.Qty__c : 0;
	           	if(coli.Part__c != null) {
	           		Decimal partAvgCost = coli.Part__r.Average_Cost__c != null && coli.Part__r.Average_Cost__c != 0 ? 
                						coli.Part__r.Average_Cost__c : (coli.Part__r.Last_Cost__c != null ? coli.Part__r.Last_Cost__c : 0);
                						
	           		if(String.isNotBlank(coli.Part__r.Part_Type__c) && coli.Part__r.Part_Type__c == 'Merchandise') {
	           			if(String.isNotBlank(coli.Deal__c)) {
	           				totalDealMerchSales = (totalDealMerchSales != null) ? totalDealMerchSales : 0;
							totalDealMerchSales += (coli.Qty__c * coli.Price__c).setScale(2, RoundingMode.HALF_UP);
		               		totalDealMerchCost += (coli.Closed_CO_Invoice_link__c != null ? (coli.Adjusted_Cost_Coli__c != null ? coli.Adjusted_Cost_Coli__c : 0) :
		               			(partAvgCost != null ? (partAvgCost * coli.Qty__c) : 0));
		               	} else {
		               		totalCOMerchSales = (totalCOMerchSales != null) ? totalCOMerchSales : 0;
		               		totalCOMerchSales += (coli.Qty__c * coli.Price__c).setScale(2, RoundingMode.HALF_UP);
		               		totalCOMerchCost += (coli.Closed_CO_Invoice_link__c != null ? (coli.Adjusted_Cost_Coli__c != null ? coli.Adjusted_Cost_Coli__c : 0) :
		               			(partAvgCost != null ? (partAvgCost * coli.Qty__c) : 0));
		               	}
	           		} else {
		               	if(String.isNotBlank(coli.Deal__c)) {
		               		totalDealPartSales = (totalDealPartSales != null) ? totalDealPartSales : 0;
							totalDealPartSales += (coli.Qty__c * coli.Price__c).setScale(2, RoundingMode.HALF_UP);
		               		totalDealPartCost += (coli.Closed_CO_Invoice_link__c != null ? (coli.Adjusted_Cost_Coli__c != null ? coli.Adjusted_Cost_Coli__c : 0) :
		               			(partAvgCost != null ? (partAvgCost * coli.Qty__c) : 0));              		
		               	} else {
		               		totalCOPartSales = (totalCOPartSales != null) ? totalCOPartSales : 0;
		               		totalCOPartSales += (coli.Qty__c * coli.Price__c).setScale(2, RoundingMode.HALF_UP);
		               		totalCOPartCost += (coli.Closed_CO_Invoice_link__c != null ? (coli.Adjusted_Cost_Coli__c != null ? coli.Adjusted_Cost_Coli__c : 0) :
		               			(partAvgCost != null ? (partAvgCost * coli.Qty__c) : 0));
		               	}
	           		}
	    		} else if(coli.Fee__c != null && coli.Fee__r.Is_Include_In_Profit_Calculation__c) {
	           		if(String.isNotBlank(coli.Deal__c)) {
	           			totalDealFeeSales = (totalDealFeeSales != null) ? totalDealFeeSales : 0;
	               		totalDealFeeSales += (coli.Qty__c * coli.Price__c).setScale(2, RoundingMode.HALF_UP);
	               		if(coli.Fee__r.Cost_Method__c == 'Fixed Cost' && coli.Fee__r.Cost_Rate__c != null && coli.Qty__c != null) {
	                		totalDealFeeCost += (coli.Closed_CO_Invoice_link__c != null ? (coli.Fee_Cost__c != null ? coli.Fee_Cost__c : 0) 
	                								: (coli.Qty__c * coli.Fee__r.Cost_Rate__c));  
	                	} else if(coli.Fee__r.Cost_Method__c == 'Percent Retail' && coli.Fee__r.Cost_Rate__c != null && coli.Qty__c != null) {
	                    	totalDealFeeCost += (coli.Closed_CO_Invoice_link__c != null ? (coli.Fee_Cost__c != null ? coli.Fee_Cost__c : 0) 
	                								: (coli.Qty__c * ((coli.Price__c * coli.Fee__r.Cost_Rate__c) /100))); 
	                	} 
	               	} else {
	               		totalCOFeeSales = (totalCOFeeSales != null) ? totalCOFeeSales : 0;
	               		totalCOFeeSales += (coli.Qty__c * coli.Price__c).setScale(2, RoundingMode.HALF_UP);
						if(coli.Fee__r.Cost_Method__c == 'Fixed Cost' && coli.Fee__r.Cost_Rate__c != null && coli.Qty__c != null) {
		                    totalCOFeeCost += (coli.Closed_CO_Invoice_link__c != null ? (coli.Fee_Cost__c != null ? coli.Fee_Cost__c : 0) 
	                								: (coli.Qty__c * coli.Fee__r.Cost_Rate__c)); 
		                } else if(coli.Fee__r.Cost_Method__c == 'Percent Retail' && coli.Fee__r.Cost_Rate__c != null && coli.Qty__c != null) {
		                    totalCOFeeCost += (coli.Closed_CO_Invoice_link__c != null ? (coli.Fee_Cost__c != null ? coli.Fee_Cost__c : 0) 
	                								: (coli.Qty__c * ((coli.Price__c * coli.Fee__r.Cost_Rate__c) /100))); 
	                	}
	               	}
	       		}
			}
            
			List<ProfitabilityWrapper.ProductProfitabilityWrapper> merchProductProfitabilityObjList = new List<ProfitabilityWrapper.ProductProfitabilityWrapper>(); 
			List<ProfitabilityWrapper.ProductProfitabilityWrapper> dealMerchProductProfitabilityObjList = new List<ProfitabilityWrapper.ProductProfitabilityWrapper>();
			
            //Merchandise
			if(totalCOPartSales != null) {
				merchProductProfitabilityObjList.add(new ProfitabilityWrapper.ProductProfitabilityWrapper('Parts', totalCOPartSales, totalCOPartCost));
			}
			if(totalCOMerchSales != null) { 
				merchProductProfitabilityObjList.add(new ProfitabilityWrapper.ProductProfitabilityWrapper('Merchandise', totalCOMerchSales, totalCOMerchCost));
			}
			if(totalCOFeeSales != null) {
				merchProductProfitabilityObjList.add(new ProfitabilityWrapper.ProductProfitabilityWrapper('Fees', totalCOFeeSales, totalCOFeeCost));
			}
			
			//Deal Merchandise
			if(totalDealPartSales != null) {
				dealMerchProductProfitabilityObjList.add(new ProfitabilityWrapper.ProductProfitabilityWrapper('Parts', totalDealPartSales, totalDealPartCost));
			}
			if(totalDealMerchSales != null) {
				dealMerchProductProfitabilityObjList.add(new ProfitabilityWrapper.ProductProfitabilityWrapper('Merchandise', totalDealMerchSales, totalDealMerchCost));
			}
       		if(totalDealFeeSales != null) {
				dealMerchProductProfitabilityObjList.add(new ProfitabilityWrapper.ProductProfitabilityWrapper('Fees', totalDealFeeSales, totalDealFeeCost));
			}
       		if(merchProductProfitabilityObjList.size() > 0) {
       			sectionTypeToProfitabilityWrapperMap.put('Parts & Accessories', new ProfitabilityWrapper.SectionProfitabilityWrapper('Parts & Accessories', merchProductProfitabilityObjList));
			}
			if(dealMerchProductProfitabilityObjList.size() > 0) {
				sectionTypeToProfitabilityWrapperMap.put('Deal Merchandise', new ProfitabilityWrapper.SectionProfitabilityWrapper('Deal Merchandise', dealMerchProductProfitabilityObjList));
			}
       	}
       	return sectionTypeToProfitabilityWrapperMap;
    }
    
     public static void populateMerchIndividualsCostTotalsAfterFinalize(String coInvoiceId) {
    	List<CO_Line_Item__c> coliList = [SELECT Fee__c, Qty__c, Price__c, Deal__c, Fee__r.Is_Include_In_Profit_Calculation__c, Fee__r.Cost_Method__c, 
    										Fee__r.Cost_Rate__c FROM CO_Line_Item__c WHERE Service_Order_Line_Item__c = null AND Invoice_Number__c =: coInvoiceId];
       
       	if(coliList.size() > 0) {
        	for(CO_Line_Item__c coli : coliList) {
	        	coli.Price__c = (coli.Price__c != null) ? coli.Price__c : 0;
	           	coli.Qty__c = (coli.Qty__c != null) ? coli.Qty__c : 0;
	           	if(coli.Fee__c != null && coli.Fee__r.Is_Include_In_Profit_Calculation__c) {
                	if(coli.Fee__r.Cost_Method__c == 'Fixed Cost' && coli.Fee__r.Cost_Rate__c != null && coli.Qty__c != null) {
                		coli.Fee_Cost__c = (coli.Qty__c * coli.Fee__r.Cost_Rate__c).setScale(2, RoundingMode.HALF_UP);
                	} else if(coli.Fee__r.Cost_Method__c == 'Percent Retail' && coli.Fee__r.Cost_Rate__c != null && coli.Qty__c != null) {
                    	coli.Fee_Cost__c = (coli.Qty__c * ((coli.Price__c * coli.Fee__r.Cost_Rate__c) /100)).setScale(2, RoundingMode.HALF_UP);
                	}
	       		} 
			}
			update coliList;
       	}
    }

    public static List<ServiceOrderWrapper.ServiceNotes> saveNotesForCustomerForPartsSale(String coHeaderId, String notesJson) {
        if(String.isBlank(coHeaderId)) throw new BlackPurlException('Invalid Customer Order Id');
        List<ServiceOrderWrapper.ServiceNotes> notesList = (List<ServiceOrderWrapper.ServiceNotes>)system.JSON.deserialize(notesJson, List<ServiceOrderWrapper.ServiceNotes>.class);
        CO_Header__c coHeaderToUpdate = new CO_Header__c(Id = coHeaderId, Merchandise_Notes_For_Customer__c = CustomerOrderCtrl_V2.convertListIntoStringForSOFields(notesList));
        COTriggerHelper.isForceStopTrigger = true;
        update coHeaderToUpdate;
        COTriggerHelper.isForceStopTrigger = false;
        return (coHeaderToUpdate.Merchandise_Notes_For_Customer__c != null) ?  ServiceJobService.getServiceNotesList(coHeaderToUpdate.Merchandise_Notes_For_Customer__c.split('\n')) : new List<ServiceOrderWrapper.ServiceNotes>();
    }
    
    public static String updatePartsAndAccessoriesSetting(String coHeaderJson) {
    	CustomerOrderWrapper.COHeader coHeaderObj = (CustomerOrderWrapper.COHeader) system.JSON.deserialize(coHeaderJson, CustomerOrderWrapper.COHeader.class);
    	if(String.isBlank(coHeaderObj.COHeaderId)) {
    		return 'Error: Customer order id is blank';
     	}
    	List<CO_Header__c> coHeaderRecList = [Select Id, Merchandise_Commit_Order_controls__c, (Select Id from CO_Line_Items__r 
    										where Is_In_Merch_Section__c = true AND Closed_CO_Invoice_link__c = null) 
    										from CO_Header__c where Id =: coHeaderObj.COHeaderId];
    	if(coHeaderRecList.size() > 0 ) {
    		CO_Header__c coHeaderRec = new CO_Header__c(Id = coHeaderObj.COHeaderId, Merchandise_Commit_Order_controls__c = coHeaderObj.MerchandiseCommitOrdercontrols, 
    										Transaction_Type__c = coHeaderObj.MerchandiseTransactionTypeId, Merchandise_Transaction_Type__c = (coHeaderObj.MerchandiseTransactionTypeLabel == 'Layaway' || coHeaderObj.MerchandiseTransactionTypeLabel == 'Layby') ? coHeaderObj.MerchandiseTransactionTypeLabel : 'Part Sale');
    		if(AccessControl.ifObjectFieldIsUpdateable('CO_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }								
    		update coHeaderRec;
    		
    		if(coHeaderRecList[0].Merchandise_Commit_Order_controls__c != coHeaderObj.MerchandiseCommitOrdercontrols && coHeaderRecList[0].CO_Line_Items__r.size() > 0) {
    			if(AccessControl.ifObjectFieldIsUpdateable('CO_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }	
    			for(CO_Line_Item__c coliRec : coHeaderRecList[0].CO_Line_Items__r) {
    				coliRec.Merchandise_Commit_Order_controls__c = coHeaderObj.MerchandiseCommitOrdercontrols;
    			}
    			update coHeaderRecList[0].CO_Line_Items__r;
    		}
    	} else {
    		return 'Error: Customer order does not exists';
    	}
    	return 'Success';
    }

    public Static String getMerchandiseSalesTaxAmount(String coHeaderId) {
        List<PrintCustomerOrderInvoiceCtrl.TaxDetail> taxDetails;
        if(!GeneralConfiguration.getTaxIncludingPricing()) {
            List<Individual_Tax__c> individualTaxList = [SELECT Deal__c, Taxable_Amount_for_Section_Header__c, CO_Line_Item__c, Tax_Rate__c, 
                                                            Form_Label__c, Sales_Tax_Item_Name__c, Sales_Tax_Item__r.Name__c, Tax_Amount__c, Tax_Amount_To_Invoice__c, 
                                                            Enhanced_Tax_Amount__c, Taxable_Amount__c, Taxable_Amount_To_Invoice__c, 
                                                            Sales_Tax_Item__r.Is_Automated__c,
                                                            Applicable_Tax__c, List_Tax_items_on_forms__c, SO_Payment_Role__c, Sales_Tax_Item__r.Forms_Label__c  
                                                            FROM Individual_Tax__c WHERE CO_Line_Item__c != null AND 
                                                            CO_Line_Item__r.CO_Header__c =: coHeaderId AND 
                                                            CO_Line_Item__r.Is_In_Merch_Section__c = true];

            Map<String, Decimal> salesTaxNameToTaxValue = TaxCalculation.getTaxAmountWithIndividualFormLabel(individualTaxList, true);
            taxDetails = TaxEngine.setTaxDetails(salesTaxNameToTaxValue);
        }
        return System.JSON.serialize(taxDetails);
    }
    
    public static ResponseWrapper saveMerchTaxInfo(COService.COSectionTaxDetailWrapper sectionTaxDetailObj) {
        ResponseWrapper resObj = new ResponseWrapper('success', 'Customer taxes populated successfully');
        if(sectionTaxDetailObj != null) {
            CO_Header__c coHeaderRec = new CO_Header__c(Id = sectionTaxDetailObj.COHeaderId);
            if(sectionTaxDetailObj.IsOverrideTax != null) {
                coHeaderRec.Is_Override_Merch_Tax__c = sectionTaxDetailObj.IsOverrideTax;
                if(coHeaderRec.Is_Override_Merch_Tax__c) {
                    coHeaderRec.Merch_Applicable_Tax__c = sectionTaxDetailObj.ApplicableTaxId;
                } else {
                    coHeaderRec.Merch_Applicable_Tax__c = null;
                }
                coHeaderRec.Override_Merch_Tax_Applicable_On__c = String.isNotBlank(sectionTaxDetailObj.OverrideTaxApplicableOn) ? sectionTaxDetailObj.OverrideTaxApplicableOn : null;
            }
            List<CO_Header__c> coHeaderList = [Select Id, Customer__c, Customer__r.BillingState, Is_Tax_Based_On_Customer_Address__c, Is_Override_Merch_Tax__c, Merch_Applicable_Tax__c, Override_Merch_Tax_Applicable_On__c, 
            (Select Id FROM Tax_Exemptions__r WHERE Type__c =: TaxUtility.AUTOMATED_CUSTOMER LIMIT 1) FROM CO_Header__c Where Id =: coHeaderRec.Id];
            Set<String> entitiesToRecalculatePriceSet = new Set<String>();

            if(!coHeaderList.isEmpty() && GeneralConfiguration.getConfigurations().Automatic_Tax_Rates__c && sectionTaxDetailObj.IsTaxBasedOnCustomerAddress != null 
                && coHeaderList[0].Is_Tax_Based_On_Customer_Address__c != sectionTaxDetailObj.IsTaxBasedOnCustomerAddress && sectionTaxDetailObj.IsTaxBasedOnCustomerAddress
                && coHeaderList[0].Customer__c != null) {
                List<State__c> stateList = [SELECT Id FROM State__c WHERE (Name__c =: coHeaderList[0].Customer__r.BillingState OR Short_Code__c =: coHeaderList[0].Customer__r.BillingState) AND Auto_Tax_Calc__c = true];
                if(stateList.isEmpty()) {
                    throw new BlackPurlException(DealService.CUSTOMER_ADDR_AUTO_TAX_CALC_ERROR);
                }
            }

			for(CO_Header__c oldCORec : coHeaderList) {
				if(GeneralConfiguration.getConfigurations().Automatic_Tax_Rates__c && sectionTaxDetailObj.IsTaxBasedOnCustomerAddress != null && oldCORec.Is_Tax_Based_On_Customer_Address__c != sectionTaxDetailObj.IsTaxBasedOnCustomerAddress) {
                    coHeaderRec.Is_Tax_Based_On_Customer_Address__c = sectionTaxDetailObj.IsTaxBasedOnCustomerAddress;
                    if(coHeaderRec.Is_Tax_Based_On_Customer_Address__c && oldCORec.Tax_Exemptions__r.isEmpty()) {
                        resObj = Customer_Service.populateCustomerTaxesOnCO(oldCORec.Id, oldCORec.Customer__c, true);
                        if(resObj != null && resObj.responseStatus.equalsIgnoreCase('error')) {
                            return resObj;
                        }
                    }
                    entitiesToRecalculatePriceSet.add(DealUtil.UNIT_TAX_APPLICABLE_ON_PARTS);
                    entitiesToRecalculatePriceSet.add(DealUtil.UNIT_TAX_APPLICABLE_ON_FEES);
                } else if((coHeaderRec.Is_Override_Merch_Tax__c && oldCORec.Merch_Applicable_Tax__c != coHeaderRec.Merch_Applicable_Tax__c) || 
                oldCORec.Is_Override_Merch_Tax__c != coHeaderRec.Is_Override_Merch_Tax__c) {
                    if(String.isNotBlank(oldCORec.Override_Merch_Tax_Applicable_On__c)) {
                        entitiesToRecalculatePriceSet.addAll(oldCORec.Override_Merch_Tax_Applicable_On__c.split(DealUtil.delimitor));
                    }
                    if(String.isNotBlank(coHeaderRec.Override_Merch_Tax_Applicable_On__c)) {
                        entitiesToRecalculatePriceSet.addAll(coHeaderRec.Override_Merch_Tax_Applicable_On__c.split(DealUtil.delimitor));
                    }
                } else if(oldCORec.Override_Merch_Tax_Applicable_On__c != coHeaderRec.Override_Merch_Tax_Applicable_On__c) {
                    if(String.isNotBlank(oldCORec.Override_Merch_Tax_Applicable_On__c)) {
                        entitiesToRecalculatePriceSet.addAll(oldCORec.Override_Merch_Tax_Applicable_On__c.split(DealUtil.delimitor));
                    }
                    if(String.isNotBlank(coHeaderRec.Override_Merch_Tax_Applicable_On__c)) {
                        for(String entityName : coHeaderRec.Override_Merch_Tax_Applicable_On__c.split(DealUtil.delimitor)) {
                            if(String.isNotBlank(oldCORec.Override_Merch_Tax_Applicable_On__c) && oldCORec.Override_Merch_Tax_Applicable_On__c.contains(entityName)) {
                                entitiesToRecalculatePriceSet.remove(entityName);
                            } else {
                                entitiesToRecalculatePriceSet.add(entityName);
                            }
                        }
                    }
                }
			}
			COTriggerHelper.isForceStopTrigger = true;
            DMLUtility.updateSobjectList('CO_Header__c', coHeaderRec);
            COTriggerHelper.isForceStopTrigger = false;

            if(!entitiesToRecalculatePriceSet.isEmpty()) {
				List<CO_Line_Item__c> coliList = getCOLIToRecalculatePrices(coHeaderRec.Id, entitiesToRecalculatePriceSet);

                system.debug('coliList:: ' +coliList.size());
                if(!coliList.isEmpty()) {
                    COLineItemTriggerHelper.isTotalCalculated = false;
                    COTriggerHelper.calculateSalesTax(coliList);
                }
			}
		}
        return resObj;
	}

	private static List<CO_Line_Item__c> getCOLIToRecalculatePrices(Id coId, Set<String> entitiesToRecalculatePriceSet) {
		List<CO_Line_Item__c> coliList = new List<CO_Line_Item__c>();
		if(String.isNotBlank(coId) && entitiesToRecalculatePriceSet != null && !entitiesToRecalculatePriceSet.isEmpty()) {
			String query = 'SELECT Id, Qty__c, Price__c, Applicable_Tax__c, Deal__c, Service_Order_Line_Item__r.Service_Order_Header__c, '+
			'Part__r.Taxable__c, Part__r.Applicable_Tax__c, Fee__r.Taxable__c, Fee__r.Applicable_Tax__c, CO_Header__r.Is_Tax_Based_On_Customer_Address__c, '+
			'CO_Header__r.Is_Override_Merch_Tax__c, CO_Header__r.Override_Merch_Tax_Applicable_On__c, CO_Header__r.Merch_Applicable_Tax__c, ' +
			'Service_Order_Line_Item__c, CO_Header__c, CO_Header__r.CO_Type__c, CO_Header__r.Customer__c from CO_Line_Item__c ' +
            'WHERE CO_Header__c =: coId AND Is_In_Merch_Section__c = true AND (';
			if(entitiesToRecalculatePriceSet.contains(DealUtil.UNIT_TAX_APPLICABLE_ON_PARTS)) query += ' Part__c != null OR';
			if(entitiesToRecalculatePriceSet.contains(DealUtil.UNIT_TAX_APPLICABLE_ON_FEES)) query += ' Fee__c != null OR';
		
			query = (query.substringBeforeLast(' OR') + ')');
			coliList = Database.query(query);
		}
		return coliList;
	}

    /* Methods moved from CustomerOrderCtrl */

    /**
    * Name: removeMerchandiseSection 
    * Desc: Method to set flag to delete emplty merchandise section on Customer Order Page
    * @param:  (1) coHeaderId - String - Id of CO Header Record
    * @return: String - JSON String of CO Header Detail Record
    **/
    public static void removeMerchandiseSection(String coHeaderId, Boolean flag){
        coHeaderId = BPUtility.getDecodedString(coHeaderId);
        if(coHeaderId != null) {
            updateMerchSectionToDisplay(coHeaderId, flag);
            COService.removeAllCOSalespersonBySectionId(coHeaderId);
            // Remove CO Section detail record for Merchandise section 
            COSectionDetailService.deleteCOSection_future(coHeaderId, COSectionDetailService.MERCHANDISE);
        }
    }

    public static void updateMerchSectionToDisplay(String coHeaderId, Boolean flag) {
        CO_Header__c coHeaderRec = new CO_Header__c(Id = coHeaderId, Hide_Merchandise_Section__c = flag);
        if(flag != null && flag) {
            coHeaderRec.Salesperson_Names__c = null;
            coHeaderRec.Is_Tax_Based_On_Customer_Address__c = false;
        }
        COTriggerHelper.isTriggerExecute = true;
        DMLUtility.updateSobjectList('CO_Header__c', coHeaderRec);
    }

    public static void saveMerchBulkDiscountPercent(String coHeaderId, Boolean isPartDiscount, Decimal discountPct) {
        if(String.isBlank(coHeaderId)) throw new BlackPurlException('Invalid Customer Order Id');
        List<CO_Header__c> coHeaderList = [Select Id, Parts_Bulk_Discount_Percent__c, Fees_Bulk_Discount_Percent__c From CO_Header__c Where Id =: coHeaderId];
        if(!coHeaderList.isEmpty()) {
            if(isPartDiscount) {
                InternalCommentService.addInternalCommentForBulkDiscount(coHeaderId, coHeaderList[0].Parts_Bulk_Discount_Percent__c, discountPct, 'P&A', 'Parts');
                coHeaderList[0].Parts_Bulk_Discount_Percent__c = discountPct;
            } else {
                InternalCommentService.addInternalCommentForBulkDiscount(coHeaderId, coHeaderList[0].Fees_Bulk_Discount_Percent__c, discountPct, 'P&A', 'Fees');
                coHeaderList[0].Fees_Bulk_Discount_Percent__c = discountPct;
            }
            COTriggerHelper.isForceStopTrigger = true;
            DMLUtility.updateSobjectList('CO_Header__c', coHeaderList);
            COTriggerHelper.isForceStopTrigger = false;
            applyBulkDiscount(coHeaderId, isPartDiscount);
        }
    }
    public static Boolean isApplyBulkDiscount = false;
    private static void applyBulkDiscount(String coHeaderId, Boolean isPartDiscount) {
        String query = 'SELECT Calculated_Customer_Price__c, Price__c, Price_When_Tax_Included__c, Tax__c, Bulk_Discount_Percent__c, CO_Kit_Header__c, Fixed_Price__c, CO_Kit_Header__r.Fixed_Price_Flag__c from CO_Line_Item__c where '+
        'Invoice_Number__c = null AND CO_Header__c =: coHeaderId AND Service_Order_Line_Item__c = null ';
        if(isPartDiscount) {
            query += ' AND Part__c != null ';
        } else {
            query += ' AND Fee__c != null';
        }
        boolean hasKit = false;
        List<CO_Line_Item__c> coliListToUpdate = new List<CO_Line_Item__c>();
        for(CO_Line_Item__c coliRec : (List<CO_Line_Item__c>) Database.query(query)) {
            if(coliRec.CO_Kit_Header__c != null) {
                if(!coliRec.CO_Kit_Header__r.Fixed_Price_Flag__c && !coliRec.Fixed_Price__c) hasKit = true;
                continue;
            }            
            if(GeneralConfiguration.getTaxIncludingPricing()) {
                coliRec.Price_When_Tax_Included__c = (coliRec.Calculated_Customer_Price__c * (1 - (coliRec.Bulk_Discount_Percent__c /100))).setScale(2, RoundingMode.HALF_UP);
                if( coliRec.Tax__c != 0) {
                    coliRec.Price__c = (coliRec.Price_When_Tax_Included__c / (1 + (coliRec.Tax__c / 100))).setScale(2, RoundingMode.HALF_UP);
                } else {
                    coliRec.Price__c = coliRec.Price_When_Tax_Included__c;
                }
            } else {
                coliRec.Price__c = (coliRec.Calculated_Customer_Price__c * (1 - (coliRec.Bulk_Discount_Percent__c /100))).setScale(2, RoundingMode.HALF_UP);
            }
            coliListToUpdate.add(coliRec);
        }
        COLineItemTriggerHelper.isTotalCalculated = hasKit;
        DMLUtility.updateSobjectList('CO_Line_Item__c', coliListToUpdate);

        if(hasKit) {
            isApplyBulkDiscount = true;
            CustomerOrderCtrl_V2.isRefreshCOKit = true;
            COTriggerHelper.isResetPricing = false;
            COKH_Recalcualtion.COKitPriceCalculation(null, coHeaderId);
            isApplyBulkDiscount = false;
            CustomerOrderCtrl_V2.isRefreshCOKit = false;
            COTriggerHelper.isResetPricing = true;
            TaxCalculation.populateOrderTotal(coHeaderId, true);
        }
    }

    /* Methods moved from CustomerOrderCtrl */

    public class TransactionTypeLabelWrapper {
		public String Id;
		public String CodeLabel;
		public Boolean IsDefault;

		public TransactionTypeLabelWrapper(Transaction_Type__c ttRec){
			this.Id = ttRec.Id;
			this.CodeLabel = ttRec.Code_Label__c;
			this.IsDefault = ttRec.Default__c;
		}
	}
}