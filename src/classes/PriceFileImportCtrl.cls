/**
* Author: Tarun Khandelwal
* Since: Dec 23, 2016
* Name: PriceFileImportCtrl
* Description: Apex class which contains all remoted methods related to Price File Import Page.
**/
global without sharing class PriceFileImportCtrl {
    
    global PriceFileImportCtrl (NewHomePageCtrl controller){}
    public PriceFileImportCtrl() {}
    
    public static Boolean isAllPricesPerItem = false;
    public static Boolean isAllCostsPerItem = false;
    public static Boolean isOverridePartPkgSetting = false;
    
    @RemoteAction
    global static String getSearchResults(String JSONString) {
        return CustomerOrderCtrl.getSearchResults(JSONString);
    }
    
    @RemoteAction
    global static String importPriceFile(String vendorId, String recordJSON) {
      
        vendorId = BPUtility.getDecodedString(vendorId);
        recordJSON = BPUtility.getDecodedString(recordJSON);
        decimal sucessCount = 0;
        decimal errorCount = 0;
        decimal newRecords =  0;
       
        List<FieldMapping> recordList = (List<FieldMapping>) System.JSON.deserialize(recordJSON, List<FieldMapping>.class);
        String defaultCategoryId = getDefaultCategoryForVendor(vendorId);
        Set<String> partNumberSet = new Set<String>();
        Set<String> duplicateSet = new Set<String>();
        for(FieldMapping record : recordList) {
            partNumberSet.add(record.PartNumber);
        } 
        if(AccessControl.ifObjectFieldIsAccessible('Part__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<Part__c> existingPartList = [select Id, Part_Number__c from Part__c where Part_Number__c IN: partNumberSet and Vendor__c =:vendorId];
        List<Account> vendorList = [SELECT Id, Is_Calculate_Part_Retail_Price__c, Retail_Base_Value__c, Retail_Rate__c, Retail_Rounding__c, Retail_Round_To__c FROM Account WHERE Id =:vendorId];
        Map<String, String> partNumberToPartIdMap = new Map<String, String>();
        for(Part__c partRec : existingPartList) {
            partNumberToPartIdMap.put(partRec.Part_Number__c, partRec.Id);
        }
        
        String defaultPartTaxId = Configurations__c.getOrgDefaults().Default_Tax_on_Part__c;
        if(String.isBlank(defaultPartTaxId)){
            if(AccessControl.ifObjectFieldIsAccessible('Sales_Tax__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
            List<Sales_Tax__c> defaultSalesTaxList = [select Id from Sales_Tax__c where Default__c = true];
            if(defaultSalesTaxList.size() > 0) {
                defaultPartTaxId = defaultSalesTaxList[0].Id;
            }
        }
        
        List<Part__c> partRecordListToUpsert = new List<Part__c>();
        for(FieldMapping record : recordList) {
            try{
                Part__c partRec = new Part__c();
                partRec.Part_Number__c =record.PartNumber;
                partRec.Description__c = record.Description;
                
                // Start: Superseded Parts Fields: Added By Pooja  16 Oct 2017 
                partRec.Replaced_By_Part__c = record.ReplacedByPart; 
                partRec.Replaces_Part__c = record.ReplacesPart; 
                // End: Superseded Parts Fields: Added By Pooja  16 Oct 2017 
                partRec.MSRP__c = String.isNotBlank(record.MSRP) ? decimal.valueof(record.MSRP) : 0;
                //partRec.Retail_Price__c = decimal.valueof(record.Retail);
                if(String.isNotBlank(record.EnviroFee)) {
                	partRec.Enviro_Fee__c = String.isNotBlank(record.EnviroFee) ? decimal.valueof(record.EnviroFee) : 0;
                }
                if(String.isNotBlank(record.Location)) {
                    partRec.Assigned_Location_1__c = record.Location;
                }

                partRec.SKU_Number__c = record.SKU;  
                partRec.Mfg_Part__c = record.MfgPart;  

				isAllPricesPerItem = (record.AllPricesArePerItem != null && record.AllPricesArePerItem) ? true : false;
				isAllCostsPerItem = (record.AllCostsArePerItem != null && record.AllCostsArePerItem) ? true : false;
                isOverridePartPkgSetting = (record.OverridePartPkgSetting != null && record.OverridePartPkgSetting) ? true : false;
				
                if(String.isBlank(record.PackageQty) || decimal.valueof(record.PackageQty) < 1) {
                    record.PackageQty = '1';
                }
                
                if(record.PackageQty != null && record.PackageQty.length() <= 16 && decimal.valueof(record.PackageQty) > 1){
                    partRec.Packaged_Part__c = true; 
                    partRec.Package_Unit__c = 'PKG'; 
                    partRec.Package_Qty__c = (decimal.valueof(record.PackageQty)).round().intValue();
                    partRec.Retail_Price__c = String.isNotBlank(record.Retail) ? decimal.valueof(record.Retail) : 0; 
                    partRec.Last_Cost__c = String.isNotBlank(record.ItemCost) ? decimal.valueof(record.ItemCost) : 0; 
                    partRec.MSRP__c = partRec.MSRP__c;
                	partRec.Package_Cost__c = partRec.Last_Cost__c * partRec.Package_Qty__c;
                   
                    if(!isAllCostsPerItem) 	{
                        partRec.Package_Cost__c = String.isNotBlank(record.ItemCost) ? decimal.valueof(record.ItemCost) : 0; 
                    	partRec.Last_Cost__c = partRec.Package_Cost__c/partRec.Package_Qty__c;
                    }
                    
                }else	{
                	partRec.Packaged_Part__c = false; 
                    partRec.Package_Unit__c = ''; 
                    partRec.Package_Qty__c = 1;  
                    partRec.Package_Cost__c = 0;
                    partRec.Retail_Price__c = String.isNotBlank(record.Retail) ? decimal.valueof(record.Retail) : 0;
                    partRec.Last_Cost__c = String.isNotBlank(record.ItemCost) ? decimal.valueof(record.ItemCost) : 0;
                }
                
                //partRec.Last_Cost__c = decimal.valueof(record.ItemCost); // Ticket#2370: Commented By Pooja 27 Jun 2017
                partRec.Vendor__c = vendorId;
                if(partNumberToPartIdMap.containsKey(record.PartNumber)) {
                    if(!duplicateSet.contains(record.PartNumber)){
                        partRec.Id = partNumberToPartIdMap.get(record.PartNumber);
                        duplicateSet.add(record.PartNumber);
                    }
                }else{
                	partRec.Category__c = defaultCategoryId;
                    partRec.Applicable_Tax__c = defaultPartTaxId;
                    partRec.Taxable__c = true;
                }
                
                if(vendorList[0].Is_Calculate_Part_Retail_Price__c){
                	ViewPartCtrl.calculatePartRetailPriceOnUpsert(partRec, vendorList[0]);  
                }
                
                partRecordListToUpsert.add(partRec);
            }catch(exception ex){
                errorCount++;
            }
        }
                
        updatePartPricesAndCosts(partRecordListToUpsert);
                
        if(AccessControl.ifObjectFieldIsUpdateable('Part__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
        if(AccessControl.ifObjectFieldIsCreateable('Part__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_CREATEABLE); }
        Database.UpsertResult [] cr  = Database.upsert(partRecordListToUpsert ,false);
        
        Set<Id> ImportedPartIdSet = new Set<Id>();//(new Map<Id,SObject>(partRecordListToUpsert)).keySet();
        for(Database.UpsertResult Result : cr){
             if (result.isSuccess()) {
                    if(result.isCreated()){
                        newRecords++;
                    }
                    sucesscount++;
                    ImportedPartIdSet.add(result.Id);
             }else{
                errorcount++;   
             }
        }
        String SuccessCounter = String.valueOf(sucesscount);
        String ErrorCounter = String.valueOf(errorcount);
        String newRecordsCounter = String.valueOf(newRecords);
        return BPUtility.getEncodedString(System.JSON.serialize( new UploadResult(SuccessCounter,ErrorCounter,newRecordsCounter, ImportedPartIdSet)));
    }
    
    
    private static void updatePartPricesAndCosts(List<Part__c> partListToUpdate) {
    	Map<String, Part__c> partIdToRecMap = new Map<String, Part__c>([Select Id,Assigned_Location_1__c,Assigned_Location_2__c,Packaged_Part__c, Package_Cost__c,  Package_Qty__c, Retail_Price__c, MSRP__c, Last_Cost__c  from Part__c where Id IN: partListToUpdate]);
    	Set<String> locationNameInsertSet = new Set<String>();
        for(Part__c partRec : partListToUpdate) {
            List<String> existingAssignedLocationsList = new List<String>();
    		if(partRec.Id != null && partIdToRecMap.containsKey(partRec.Id)) {
                existingAssignedLocationsList = LocationManagementService.getLocationsList(partIdToRecMap.get(partRec.Id));

               	if(!isOverridePartPkgSetting) { 
                    partRec = setPartValues(partRec, partIdToRecMap.get(partRec.Id));
                }
                if(String.isNotBlank(partRec.Replaced_By_Part__c)) {
                    if(partRec.Package_Cost__c == 0 && partRec.Packaged_Part__c) {
                        partRec.Package_Cost__c = partIdToRecMap.get(partRec.Id).Package_Cost__c;
                    } else if(partRec.Last_Cost__c == 0 && !partRec.Packaged_Part__c) {
                        partRec.Last_Cost__c = partIdToRecMap.get(partRec.Id).Last_Cost__c;
                    }
                    if(partRec.Retail_Price__c == 0) {
                        partRec.Retail_Price__c = partIdToRecMap.get(partRec.Id).Retail_Price__c;
                    }
                    if(partRec.MSRP__c == 0) {
                        partRec.MSRP__c = partIdToRecMap.get(partRec.Id).MSRP__c;
                    }
                } 
    		}
            if(String.isNotBlank(partRec.Assigned_Location_1__c)) {
                for(String newLocation : partRec.Assigned_Location_1__c.split(',')) {
                    if(String.isNotBlank(newLocation)) {
                        newLocation = newLocation.trim();
                        if(newLocation.length() <= 20) {
                            Boolean isNewLocation = true;
	                        for(String existingLocation : existingAssignedLocationsList) {
	                            if(String.isNotBlank(existingLocation) && newLocation.equalsIgnoreCase(existingLocation.trim())) {
	                                isNewLocation = false;
	                            }
	                        }
	                        if(isNewLocation) {
	                            existingAssignedLocationsList.add(newLocation);
	                            locationNameInsertSet.add(newLocation);
	                        }
                        }
                    }
                }
                List<String> locationStrListForFields = TagUtil.convertTagListIntoTagString(existingAssignedLocationsList);
                if(locationStrListForFields.size() == 2) {
                    partRec.Assigned_Location_1__c = locationStrListForFields[0];
                    partRec.Assigned_Location_2__c = locationStrListForFields[1];
                }
            }
        }
        LocationManagementService.createNewLocations(locationNameInsertSet);
    }
    
    private static Part__c setPartValues(Part__c newPartRec, Part__c oldPartRec) {
    	if(oldPartRec.Packaged_Part__c && !newPartRec.Packaged_Part__c) {
			
			newPartRec.MSRP__c = (newPartRec.MSRP__c / oldPartRec.Package_Qty__c).setScale(2, RoundingMode.HALF_UP);
			newPartRec.Retail_Price__c = (newPartRec.Retail_Price__c / oldPartRec.Package_Qty__c).setScale(2, RoundingMode.HALF_UP);
			newPartRec.Package_Cost__c = newPartRec.Last_Cost__c.setScale(2, RoundingMode.HALF_UP);
			newPartRec.Packaged_Part__c = oldPartRec.Packaged_Part__c;
			newPartRec.Package_Qty__c = oldPartRec.Package_Qty__c;
			
		} else if(!oldPartRec.Packaged_Part__c && newPartRec.Packaged_Part__c) {
			
			if(PriceFileImportCtrl.isAllPricesPerItem) {
				newPartRec.MSRP__c = (newPartRec.MSRP__c * newPartRec.Package_Qty__c).setScale(2, RoundingMode.HALF_UP);
				newPartRec.Retail_Price__c = (newPartRec.Retail_Price__c * newPartRec.Package_Qty__c).setScale(2, RoundingMode.HALF_UP);
			} else {
				newPartRec.MSRP__c = newPartRec.MSRP__c.setScale(2, RoundingMode.HALF_UP);
				newPartRec.Retail_Price__c = newPartRec.Retail_Price__c.setScale(2, RoundingMode.HALF_UP);
			}
			
			newPartRec.Last_Cost__c = newPartRec.Package_Cost__c.setScale(2, RoundingMode.HALF_UP);
			newPartRec.Package_Cost__c = 0;
			newPartRec.Packaged_Part__c = oldPartRec.Packaged_Part__c;
			newPartRec.Package_Qty__c = oldPartRec.Package_Qty__c;
				
		} else if(newPartRec.Packaged_Part__c && oldPartRec.Packaged_Part__c && newPartRec.Package_Qty__c != oldPartRec.Package_Qty__c) {
				
			if(PriceFileImportCtrl.isAllPricesPerItem) {
				newPartRec.MSRP__c = ((newPartRec.MSRP__c * newPartRec.Package_Qty__c) / oldPartRec.Package_Qty__c).setScale(2, RoundingMode.HALF_UP);
				newPartRec.Retail_Price__c = ((newPartRec.Retail_Price__c * newPartRec.Package_Qty__c) / oldPartRec.Package_Qty__c).setScale(2, RoundingMode.HALF_UP);
			} else {
				newPartRec.MSRP__c = (newPartRec.MSRP__c / oldPartRec.Package_Qty__c).setScale(2, RoundingMode.HALF_UP);
				newPartRec.Retail_Price__c = (newPartRec.Retail_Price__c / oldPartRec.Package_Qty__c).setScale(2, RoundingMode.HALF_UP);
			}
			
			if(PriceFileImportCtrl.isAllCostsPerItem) {
				newPartRec.Package_Cost__c = (newPartRec.Last_Cost__c * newPartRec.Package_Qty__c).setScale(2, RoundingMode.HALF_UP);
			} else {
				newPartRec.Package_Cost__c = newPartRec.Package_Cost__c.setScale(2, RoundingMode.HALF_UP);
				newPartRec.Last_Cost__c = (newPartRec.Package_Cost__c / oldPartRec.Package_Qty__c).setScale(2, RoundingMode.HALF_UP);
			}
			
			newPartRec.Package_Qty__c = oldPartRec.Package_Qty__c;
		}
        
		
		return newPartRec;
    }
    
    @RemoteAction
    global static void importSupersessionPart(String ImportedPartIdList) {
    	ImportedPartIdList = BPUtility.getDecodedString(ImportedPartIdList);
    	List<String> ImportedPartIds = (List<String>)System.JSON.deserialize(ImportedPartIdList, List<String>.class);
		ImportSupersessionPart_Batch batchObj = new ImportSupersessionPart_Batch(ImportedPartIds, 200);
    }
    
    @RemoteAction
    global static void createActivityHistory(String vendorId) {
      	vendorId = BPUtility.getDecodedString(vendorId);
      	// Create Activity History in case of Insert.
      	if(!Test.isRunningTest()) {
      		ActivityHistory.createActivityHistory('Price File Import', 'Vendor', vendorId, 'Vendor', vendorId, null);
      	}
    }

    @RemoteAction
    global static String getVendorDetails(String vendorId) {
        vendorId = BPUtility.getDecodedString(vendorId);
        List<Account> vendorList = [SELECT Id, Name, Vendor_Code__c, Part_Category_Default__c, Part_Category_Default__r.name, Is_Calculate_Part_Retail_Price__c, Retail_Base_Value__c, Retail_Rate__c, Retail_Rounding__c, Retail_Round_To__c FROM Account WHERE Is_Vendor__c = true AND Id =:vendorId];
        List<VendorDetails> vendorDetailList = new List<VendorDetails>();
        for(Account vendorRec : vendorList){
            vendorDetailList.add( new VendorDetails(vendorRec));
        } 
        return BPUtility.getEncodedString(System.JSON.serialize(vendorDetailList));
    }

    private static String getDefaultCategoryForVendor(String vendorId) {
        String defaultCategoryId;
        
        if(AccessControl.ifObjectFieldIsAccessible('Category__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectFieldIsAccessible('Account') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        
        List<Category__c> categoryList = new List<Category__c>();
        if(String.isBlank(vendorId)) {
            categoryList = [select Id, Name from Category__c WHERE default__c = true and Type__c = 'Part'];
            if(categoryList.size() > 0) {
                defaultCategoryId = categoryList[0].Id;
            }
        } else {
            List<Account> vendorList = [select Id, Part_Category_Default__c from Account where Id = :vendorId AND Is_Vendor__c = true];
            if(vendorList.size() > 0 && vendorList[0].Part_Category_Default__c != null) {
                defaultCategoryId = vendorList[0].Part_Category_Default__c;
            } else {
                categoryList = [select Id, Name from Category__c WHERE default__c = true and Type__c = 'Part'];
                if(categoryList.size() > 0) {
                    defaultCategoryId = categoryList[0].Id;
                }
            }
        } 
        return defaultCategoryId;
    }
    
    public class FieldMapping {
        
        public String PartNumber;
        public String Description;
        public String MSRP;
        public String Retail;
        public String EnviroFee;
        public String ItemCost;

        public String Location;
        
        // Start: Ticket#2370: Added By Pooja 27 Jun 2017
        public String SKU;
        public String MfgPart;
        public String PackageQty;
        // End: Ticket#2370: Added By Pooja 27 Jun 2017
       
        //Start: Superseded Parts Fields: Added By Pooja  16 Oct 2017 
        public String ReplacedByPart;
        public String ReplacesPart; 
        //End: Superseded Parts Fields: Added By Pooja  16 Oct 2017 
        
        // Start: Package Part Flag: Added By Pooja  16 Oct 2017 
        public Boolean AllPricesArePerItem;
        public Boolean AllCostsArePerItem;
        public Boolean OverridePartPkgSetting;

        // End: Package Part Flag: Added By Pooja  16 Oct 2017
        
        public FieldMapping() {
            
        }
    }
    public class UploadResult{
        public String SucessCount;
        public String ErrorCount;
        public string NewRecords;
        public Set<Id> ImportedPartIdSet;
        public UploadResult( String sucessCount,String errorCount,String newRecords, Set<Id> ImportedPartIdSet) {
            this.SucessCount = sucessCount;
            this.ErrorCount = errorCount;
            this.newRecords = newRecords;
            this.ImportedPartIdSet = ImportedPartIdSet;
        }
    }

    public class VendorDetails {
        public String Title;
        public String Id;
        public Boolean IsCalculatePartRetailPriceFlag;
        public String RetailBaseValue; 
        public Decimal RetailRate;
        public Boolean RetailRounding;
        public Decimal RetailRoundTo;
        public VendorDetails(Account vendorRecord) {
            this.Title = vendorRecord.Name;
            this.Id = vendorRecord.Id;
            this.IsCalculatePartRetailPriceFlag = vendorRecord.Is_Calculate_Part_Retail_Price__c;
	        this.RetailBaseValue = (vendorRecord.Retail_Base_Value__c!= null) ? String.valueOf(vendorRecord.Retail_Base_Value__c) : 'MSRP';
	        this.RetailRate = (vendorRecord.Retail_Rate__c != null) ? vendorRecord.Retail_Rate__c : 0;
	        this.RetailRounding = vendorRecord.Retail_Rounding__c;
	        this.RetailRoundTo = (vendorRecord.Retail_Round_To__c != null) ? vendorRecord.Retail_Round_To__c : 0;
        }
    }
}