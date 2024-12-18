/**
 * Author: Tarun Khandelwal
 * Since: Dec 5, 2015
 * Name: ViewFeeCtrl
 * Description: Apex class to handle JSON related oprations of View Fee
**/
global without sharing class ViewFeeCtrl {
    
    
	public Decimal Related_List_Page_Size { get{return GeneralConfiguration.getRelatedListPageSize();} private set;}

	global ViewFeeCtrl (NewHomePageCtrl controller){}
    public ViewFeeCtrl() {}
	
    /** 
     * Name: getDefaultFeeData  
     * Desc: Get default data for new Fee records
     * @param:  (1)
     * @return: String - Fee JSON String.
    **/
    @remoteAction
    global static String getDefaultFeeData() {
        try{
            List<Category__c> defaultFeeCategories = SOQLUtil.getDefaultCategoryRecords(new Map<String, String>{'Type__c' => 'Fee', 'Status__c' => 'Active'});
            if(defaultFeeCategories.size() > 0) {
                Category__c defaultCategory = defaultFeeCategories[0];
                
                Fee newFee = new Fee();  
                newFee.CategoryId = defaultCategory.Id;
                newFee.CategoryName = defaultCategory.Name;
                return BPUtility.getEncodedString(System.JSON.serialize(newFee));
            }
        }
        catch(Exception e){
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
        
        return BPUtility.getEncodedString('{}');
    }
    
    /**
     * Name: getApplicableTaxList
     * Desc: To get Labour Details on Edit Labour Pop Up window
     * @param: 
     * @return: String - JSON string of Part info. 
    **/
    @RemoteAction
    global static String getApplicableTaxList() {
        String defaultLaborTaxId = Configurations__c.getOrgDefaults().Default_Tax_on_Fee__c;
        String taxWrapperJSON = TaxUtility.getApplicableList(defaultLaborTaxId);
        TaxUtility.Tax taxObj = (TaxUtility.Tax) System.JSON.deserialize(taxWrapperJSON, TaxUtility.Tax.class);
        
        List<String> costMethodPicklistValues = getCostMethodPicklistValue();
        List<String> TypePicklistValues = getTypePicklistValue();
        FeeMasterDataWrapper masterDataObj = new FeeMasterDataWrapper(taxObj,costMethodPicklistValues,TypePicklistValues );
        
        return BPUtility.getEncodedString(system.JSON.serialize(masterDataObj));
    }
    
    //Added by Nikhil 10/07/17
	/**
     * Name: getCostMethodPicklistValue
     * Desc: Method to get all pickList Values of Cost_Method__c on Fee Object.
     * @param:  
     * @return: List<String> - Cost_Method__c values list
    **/
	public static List<String> getCostMethodPicklistValue() {
		List<String> options = new List<String>();
   		Schema.DescribeFieldResult fieldResult = Fee__c.Cost_Method__c.getDescribe();
   		List<Schema.PicklistEntry> pickListAllEntries = fieldResult.getPicklistValues();
   			for( Schema.PicklistEntry val: pickListAllEntries)
  		 	{
      			options.add(val.getValue());
   			}        
   		
   		return options;
	}
    public static List<String> getTypePicklistValue() {
		List<String> options = new List<String>();
   		Schema.DescribeFieldResult fieldResult = Fee__c.Type__c.getDescribe();
   		List<Schema.PicklistEntry> pickListAllEntries = fieldResult.getPicklistValues();
   			for( Schema.PicklistEntry val: pickListAllEntries)
  		 	{
      			options.add(val.getValue());
   			}        
   		
   		return options;
	}
    /**
     * Name: getFeeDetails
     * Desc: To get Fee Record JSON String
     * @param:  (1) feeId - String - Kit Header Record Id
     *          (2) gridName - String - Name of Grid which JSON grid is needed. If null, all JSON is returned  
     * @return: String - Fee JSON String.
    **/
    @remoteAction
    global static String getFeeDetails(String feeId, String gridName, String activeOrderPageSortAttrsJSON) {
        
        try{
        	feeId = BPUtility.getDecodedString(feeId);
        	gridName = BPUtility.getDecodedString(gridName);
        	activeOrderPageSortAttrsJSON = BPUtility.getDecodedString(activeOrderPageSortAttrsJSON);
        	
            List<Fee__c> feeList = SOQLUtil.getFeeByFieldName(new Map<String, String>{'Id' => feeId});
            List<Service_Order_Line_Item__c> soliList = new List<Service_Order_Line_Item__c>();
            List<Linked_Fee__c> linkedFeeList = new List<Linked_Fee__c>(); // Added By Ayushi - 08/29/2017
            PaginationSorting activeOrderPageSortAttrs = PaginationSorting.parsePageAttrs(activeOrderPageSortAttrsJSON);
            
            if(gridName == null || gridName.toLowerCase() == 'activeorder') {
                soliList = SOQLUtil.getActiveOrders(feeId);
            }
            
            /* START: Added By Ayushi - 08/29/2017 */
            if(gridName == null || gridName.toLowerCase() == 'linkedFee') {
                linkedFeeList = SOQLUtil.getLinkedFeeList(new Map<String, String>{'Fee__c' => feeId});
            }
            /* End: Added By Ayushi - 08/29/2017 */
            if(feeList.size() == 0) {
                return BPUtility.getEncodedString('{}');
            }
            
            List<Fee__c> feeWithCOLIList = SOQLUtil.getFeeDetailsForFeeId(FeeId, null);
			List<CO_Line_Item__c> coliList = new List<CO_Line_Item__c>();
			for (Fee__c feeRecord : feeWithCOLIList) {
				if(feeRecord.CO_Line_Items__r != null) {
					coliList.addAll(feeRecord.CO_Line_Items__r);
				}
			}
            FeeWrapper feeWrapperObj = new FeeWrapper(feeList[0], soliList, coliList, linkedFeeList, activeOrderPageSortAttrs);
            //getActiveOrdersListByFeeId(feeId, activeOrderPageSortAttrsJSON, feeWrapperObj);
            
            return BPUtility.getEncodedString(System.JSON.serialize(feeWrapperObj));
        }
        catch(Exception e){
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    /**
     * Name: getSimilarFees
     * Desc: To get similar Kit Header Records
     * @param: 
     * @return: String - get Main JSON data.
    **/
    @remoteAction
    global static String getSimilarFees(String jsonString) {
        try{
        	jsonString = BPUtility.getDecodedString(jsonString);
        	
            Fee feeObj = Fee.parse(jsonString);
            Fee__c feeFilterValue = (Fee__c)setFeeFields(feeObj);
            List<Fee__c> feeRecords = SOQLUtil.getOtherSimilarFees(feeFilterValue);
            List<FeeSuggestion> feeSuggestionList = new List<FeeSuggestion>();
            //system.assert(false, kitHeaders);
            
            for(Fee__c feeRec : feeRecords) {
                if(feeRec.Code__c == feeFilterValue.Code__c) {
                    feeSuggestionList.add(new FeeSuggestion(feeRec, 1));
                } else if(feeRec.Description__c == feeFilterValue.Description__c) {  
                    feeSuggestionList.add(new FeeSuggestion(feeRec, 2));
                } else {
                    feeSuggestionList.add(new FeeSuggestion(feeRec, 3));
                }
            } 
            
            feeSuggestionList.sort();
            Integer listSizeLimit = 15;
            if(feeSuggestionList.size() > listSizeLimit) {
                List<FeeSuggestion> feeSuggestionLimitedList = new List<FeeSuggestion>();
                for(Integer i = 0 ; i < listSizeLimit ; i++) {
                    feeSuggestionLimitedList.add(feeSuggestionList[i]);
                }
                feeSuggestionList = new List<FeeSuggestion>();
                feeSuggestionList.addAll(feeSuggestionLimitedList);
            }
            return BPUtility.getEncodedString(System.JSON.serialize(feeSuggestionList));
        }
        catch(Exception e){
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    /**
     * Name: saveFee
     * Desc: To save Fee Record
     * @param: 
     * @return: String - get Main JSON data.
    **/
    @remoteAction
    global static String saveFee(String jsonString, String activeOrderPageSortAttrsJSON) {
    	jsonString = BPUtility.getDecodedString(jsonString);
    	activeOrderPageSortAttrsJSON = BPUtility.getDecodedString(activeOrderPageSortAttrsJSON);
    	
        Fee feeObj = Fee.parse(jsonString);
        Fee__c feeToUpsert = (Fee__c)setFeeFields(feeObj);
        if(AccessControl.ifObjectFieldIsCreateable('Fee__c') == false ){throw new BlackPurlException(Constants.OBJIECT_NOT_CREATEABLE);}
       	if(AccessControl.ifObjectIsUpdateable('Fee__c') == false ){throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE);}
	    Savepoint sp = Database.setSavepoint();
        try{
            upsert feeToUpsert;
            return getFeeDetails(BPUtility.getEncodedString(feeToUpsert.Id), BPUtility.getEncodedString('Info'), BPUtility.getEncodedString(activeOrderPageSortAttrsJSON));
        }
        catch(Exception e){
            Database.rollback(sp);
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    /**
     * Name: setFeeFields
     * Desc: Method to set fields of Customer Object
     * @param:  (1) kitHeaderObj - KitHeader - Kit Header Obj
     * @return:  Sobject - Sobject with populated values of Kit Header object
    **/
    private static Sobject setFeeFields(Fee feeObj){
        Fee__c feeRec = new Fee__c();
        feeRec.Type__c = feeObj.Type;
        feeRec.Code__c = feeObj.Code;
        feeRec.Description__c = feeObj.Description;
        feeRec.Price__c = feeObj.Price;
        feeRec.Category__c = feeObj.CategoryId;
        feeRec.Taxable__c = feeObj.IsTaxable;
        feeRec.Active__c = feeObj.IsActive;
        feeRec.Cost_Method__c = feeObj.CostMethod; //Added by Nikhil 11/07/17
        feeRec.Cost_Rate__c = feeObj.CostRate; //Added by Nikhil 11/07/17
        feeRec.Is_Include_In_Profit_Calculation__c = feeObj.IsIncludeInProfitCalculation;
        if(feeObj.IsTaxable) {
        	feeRec.Applicable_Tax__c = feeObj.ApplicableTaxId;
        } else {
        	feeRec.Applicable_Tax__c = null;
        }
        if(feeObj.Id != null) {
            feeRec.Id = feeObj.Id;
        }
        if(feeObj.AssignedTags != null && feeObj.AssignedTags.size() > 0) {
	        List<String> tagStrListForFields = TagUtil.convertTagListIntoTagString(feeObj.AssignedTags);
	        if(tagStrListForFields.size() == 2) {
	            feeRec.Assigned_Tag_1__c = tagStrListForFields[0];
	            feeRec.Assigned_Tag_2__c = tagStrListForFields[1];
	        }
	    } else {
	        feeRec.Assigned_Tag_1__c = feeRec.Assigned_Tag_2__c = '';
	    }
        return feeRec;
    }
    
    @RemoteAction
    global static String getActiveTagList() {
        return BPUtility.getEncodedString(System.JSON.serialize(TagManagementCtrl.getActiveTagList()));
    }
    
    public static String getActiveFeeList(String typeOfFee) {
    	String defaultId;
    	if(typeOfFee == 'Env Fee') {
    		defaultId = Configurations__c.getOrgDefaults().Default_Environmental_Fee__c;
    	}
    	List<Fee__c> feeList = SOQLUtil.getFeeByFieldName(new Map<String, String>());
    	List<ActiveFee> activeFeeList = new List<ActiveFee>();
    	for(Fee__c feeRec : feeList) {
    		if(feeRec.Active__c && (typeOfFee == 'Env Fee' || typeOfFee == 'Linked Fee' || typeOfFee == 'Shop Supplies') && feeRec.Type__c != 'Purchasing') {
    			activeFeeList.add(new ActiveFee(feeRec, (feeRec.Id == defaultId)));
    		}
            else if(feeRec.Active__c && typeOfFee != 'Env Fee' && typeOfFee != 'Linked Fee' && typeOfFee != 'Shop Supplies'){
                activeFeeList.add(new ActiveFee(feeRec, (feeRec.Id == defaultId)));    
            }
    	}
    	return system.JSON.serialize(activeFeeList);
    }
    
    public class ActiveFee {
    	public String Id;
    	public String Code;
    	public String Description;
    	public String ItemDesc;
    	public Decimal Price;
    	public Boolean IsDefault;
        public String Type;
    	
    	public ActiveFee(Fee__c feeRec, Boolean isDefaultFee) {
    		this.Id = feeRec.Id;
    		this.Code = feeRec.Code__c;
    		this.Description = feeRec.Description__c;
    		this.Price = feeRec.Price__c;
    		this.IsDefault = isDefaultFee;
    		this.ItemDesc = feeRec.Code__c + ' - ' + feeRec.Description__c;
            this.Type = feeRec.Type__c;
    	}
    }
    
    public static List<ViewFeeCtrl.ActiveOrder> getPaginatedRecords(List<ViewFeeCtrl.ActiveOrder> allrecords, Integer currentPage, integer pageSize) {
        try{
            List<ViewFeeCtrl.ActiveOrder> objRecords = new List<ViewFeeCtrl.ActiveOrder>();
            if(currentPage == null || currentPage == 0){
                currentPage = 1;
            }
            if(pageSize == null || pageSize == 0){
                pageSize = (Integer) General_Configurations__c.getInstance().Related_List_Page_Size__c;
            }
            
            for(Integer i = (currentPage * pageSize - pageSize); i < (currentPage * pageSize); i++){
                if(allrecords.size() > i){
                    objRecords.add(allrecords.get(i));
                }
            }
            return objRecords;
        }
        catch(Exception e){
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    
    
    public class FeeWrapper {
        
        public Fee FeeRec;
        public List<ViewFeeCtrl.ActiveOrder> ActiveOrderList;
        public List<LinkedFeeWrapper> LinkedFeeList; // Added By Ayushi - 08/29/2017
        public Integer TotalActiveOrder;
        public Integer TotalLinkedFee;
    	    
        public FeeWrapper(	Fee__c feeRec, 
        					List<Service_Order_Line_Item__c> soliList, 
        					List<CO_Line_Item__c> coliList,
        					List<Linked_Fee__c> linkedFeeList, // Added By Ayushi - 08/29/2017
        					PaginationSorting activeOrderPageSortAttrs
        				) {
            this.FeeRec = new Fee(feeRec);
            this.ActiveOrderList = new List<ViewFeeCtrl.ActiveOrder>();
            this.LinkedFeeList = new List<LinkedFeeWrapper>(); // Added By Ayushi - 08/29/2017
            Set<Id> coHeaderIdSet = new Set<Id>();
            for(Service_Order_Line_Item__c soliRec : soliList) {
                if(soliRec.Service_Order_Header__c == null || soliRec.Service_Order_Header__r.CO_Header__c == null) {
                    continue;
                }
                
                if(!coHeaderIdSet.contains(soliRec.Service_Order_Header__r.CO_Header__c) && soliRec.Service_Order_Header__r.CO_Header__r.Order_status__c == 'Open') {
                    this.ActiveOrderList.add(new ViewFeeCtrl.ActiveOrder(soliRec));
                    coHeaderIdSet.add(soliRec.Service_Order_Header__r.CO_Header__c);
                }
            }
            for(CO_Line_Item__c coli : coliList) {
                if(!coHeaderIdSet.contains(coli.CO_Header__c) && coli.CO_Header__r.Order_status__c == 'Open') {
                    this.ActiveOrderList.add(new ViewFeeCtrl.ActiveOrder(coli));
                    coHeaderIdSet.add(coli.CO_Header__c);
                }
            }
            
            /* START: Added By Ayushi - 08/29/2017 */
            for(Linked_Fee__c linkedFeeRec : linkedFeeList) {
                    this.LinkedFeeList.add(new LinkedFeeWrapper(linkedFeeRec));
            }
            /* END: Added By Ayushi - 08/29/2017 */
            
            this.TotalActiveOrder = this.ActiveOrderList.size();
            this.TotalLinkedFee = this.LinkedFeeList.size(); // Added By Ayushi - 08/29/2017
            this.ActiveOrderList = getPaginatedRecords(this.ActiveOrderList, activeOrderPageSortAttrs.CurrentPage, activeOrderPageSortAttrs.PageSize);
        }
    }
    
    public class ActiveOrder {
        
        public String COHeaderNumber;
        public String COHeaderId;
        public String CustomerName;
        public String OwnerName;  
        public String Status;
        
        public ActiveOrder(Service_Order_Line_Item__c soliRec) {
            this.COHeaderNumber = soliRec.Service_Order_Header__r.CO_Header__r.Name;
            this.COHeaderId = soliRec.Service_Order_Header__r.CO_Header__c;
            //this.CustomerName = (soliRec.Service_Order_Header__r.CO_Header__r.Customer__c != null) ? soliRec.Service_Order_Header__r.CO_Header__r.Customer__r.Name : null;
            this.CustomerName = soliRec.Service_Order_Header__r.CO_Header__r.Customer_Name__c;
            this.OwnerName = (soliRec.Service_Order_Header__r.CO_Header__r.Owner__c != null) ? soliRec.Service_Order_Header__r.CO_Header__r.Owner__r.Name : null;
            this.Status = soliRec.Service_Order_Header__r.CO_Header__r.Order_status__c;
        }
        
        public ActiveOrder(CO_Line_Item__c coli) {
            this.COHeaderNumber = coli.CO_Header__r.Name;
            this.COHeaderId = coli.CO_Header__c;
            //this.CustomerName = (coli.CO_Header__r.Customer__c != null) ? coli.CO_Header__r.Customer__r.Name : null;
            this.CustomerName = coli.CO_Header__r.Customer_Name__c;
            this.OwnerName = (coli.CO_Header__r.Owner__c != null) ? coli.CO_Header__r.Owner__r.Name : null;
            this.Status = coli.CO_Header__r.Order_status__c;
        }
    }
  
    //Added by Nikhil 10/07/17    
  /**
	* Name: FeeMasterDataWrapper
	* Description: Apex class Service Order Master Data
	**/
    
    public class FeeMasterDataWrapper {
    	public list<String> TypePicklistValues;
    	public list<String> CostPicklistValues;
    	public TaxUtility.Tax taxObj;
    	
    	public FeeMasterDataWrapper(TaxUtility.Tax taxObj, List<String> costMethodPicklistValues, List<String> typePicklistValues){
    		this.taxObj = taxObj;
    		this.CostPicklistValues = costMethodPicklistValues;
            this.TypePicklistValues = typePicklistValues;
    	}
    }
}