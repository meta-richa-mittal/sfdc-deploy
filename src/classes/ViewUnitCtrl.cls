/**
 * Author: Nidhi Sharma
 * Since: August 03, 2016
 * Name: ViewUnitCtrl
 * Description: Controller class to handle methods for View Unit page
**/

global without sharing class ViewUnitCtrl {
    
    public static Decimal MAX_HEAP_SIZE = 5000000;
    global ViewUnitCtrl (NewHomePageCtrl controller){}
    public ViewUnitCtrl() {}
    
    /**
     * Name: getUnitDetails
     * Desc: To get unit Record JSON String
     * @param:  (1) unitId - String - Unit Object record id
     * @return: String - Unit JSON String.
    **/
    @remoteAction 
    global static String getUnitDetails(String unitId) {
        unitId = BPUtility.getDecodedString(unitId);
        if(String.isBlank(unitId)){
            return BPUtility.getEncodedString('{}');
        }
        List<Customer_Owned_Unit__c> unitList = SOQLUtil.getUnitByFieldName(new Map<String, String>{'Id' => unitId});
        if(unitList.size() == 0) {
            return BPUtility.getEncodedString('{}');
        }
        List<Customer_Owned_Unit__c> similarUnits = getSimilarUnits(unitList[0].VIN_Number__c);
        List<Sales_Tax__c> salesTaxList = SOQLUtil.getSalesTax(new List<Id>());
        List<Service_Order_Header__c> soList = SOQLUtil.getUnitServiceOrdersByUnitId(new Set<Id>{unitId});
        List<Unit_Price_Cost__c> unitAdjustmentList = getUnitAdjustmentList(unitId);
        
        UnitWrapper unitWrapperObj = new UnitWrapper(unitList[0], similarUnits, salesTaxList, soList, unitAdjustmentList);
        return BPUtility.getEncodedString(System.JSON.serialize(unitWrapperObj));
    }
    
    public static List<Customer_Owned_Unit__c> getSimilarUnits(String vinNumber) {
        List<Customer_Owned_Unit__c> similarUnits = new List<Customer_Owned_Unit__c>(); 
        if(String.isNotBlank(vinNumber)) {
            similarUnits = SOQLUtil.getUnitByFieldName(new Map<String, String>{'VIN_Number__c' => vinNumber});
        }
        return similarUnits;
    }
    
    public static List<Unit_Price_Cost__c> getUnitAdjustmentList(String unitId) {
        String query = 'SELECT ' + String.join(UnitWrapper.fieldsListForUnitPriceAndCostTracking(), ',') + ' FROM Unit_Price_Cost__c' + 
                        ' WHERE Customer_Owned_Unit__c =: unitId ORDER BY Type__c ASC, CreatedDate ASC';
        return Database.query(query);                      
    }
    
   /**
    * Name: saveNotesForUnit
    * Desc: Method Which saves notes for unit in Database 
    * @param:   (1) unitId - String - Unit record Id
    *           (2) notes - String - Notes of Unit record
    * @return: 
    **/
    @RemoteAction
    global static void saveNotesForUnit(String unitId, String notes) {
        
        unitId = BPUtility.getDecodedString(unitId);
        notes = BPUtility.getDecodedString(notes);
        if(AccessControl.ifObjectFieldIsUpdateable('Customer_Owned_Unit__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
        
        Customer_Owned_Unit__c couRec = new Customer_Owned_Unit__c(); 
        if(unitId != null){ 
            couRec.Id = unitId;
            couRec.Notes__c = notes;
            update couRec;
        }
    }
    
    /**
    * Name: saveUnit
    * Desc: Method Which saves unit in Database 
    * @param:   (1) unitId - String - Unit record Id
    *           (2) jSONString - String - JSON String of Unit record
    * @return: String - JSON String of CO Header Detail Record
    **/
    @RemoteAction
    global static String saveUnit(String jSONString) {
        
        jSONString = BPUtility.getDecodedString(jSONString);
        if(AccessControl.ifObjectFieldIsUpdateable('Customer_Owned_Unit__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
        if(AccessControl.ifObjectFieldIsCreateable('Customer_Owned_Unit__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_CREATEABLE); }
        UnitWrapper unitObj = (UnitWrapper) System.JSON.deserialize(jSONString, UnitWrapper.class);
        Customer_Owned_Unit__c couRec = setUnitFields(unitObj.UnitInfo); 
        if(unitObj.UnitInfo.Id != null){ 
            couRec.Id = unitObj.UnitInfo.Id;
        }
        upsert couRec;
        return getUnitDetails(BPUtility.getEncodedString(unitObj.UnitInfo.Id));
    }
    
    @RemoteAction
    global static String getCustomerInfo(String customerId) {
        return CustomerOrderCtrl.getRecordById(customerId);
    }
    
    /**
    * Name: savePriceAndCost
    * Desc: Method Which saves unit price and cost in Database 
    * @param:   (1) jSONString - String - Unit price and cost string
    * @return: String - json result string
    **/
    @RemoteAction
    global static String savePriceAndCost(String unitId, String jSONString) {
        unitId = BPUtility.getDecodedString(unitId);
        jSONString = BPUtility.getDecodedString(jSONString);
        if(!AccessControl.ifObjectFieldIsUpdateable('Unit_Price_Cost__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
        
        UnitWrapper.PriceAndCostTrackingWrapper unitPriceAndCostObj = (UnitWrapper.PriceAndCostTrackingWrapper) System.JSON.deserialize(jSONString, UnitWrapper.PriceAndCostTrackingWrapper.class);
        Unit_Price_Cost__c unitPriceAndCostRec = setUnitPriceAndCostFields(unitPriceAndCostObj); 
        if(String.isNotBlank(unitPriceAndCostObj.Id)) {
            if(!AccessControl.ifObjectFieldIsUpdateable('Unit_Price_Cost__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
            update unitPriceAndCostRec;
        } else {
            if(!AccessControl.ifObjectFieldIsCreateable('Unit_Price_Cost__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_CREATEABLE); }
            insert unitPriceAndCostRec;
        }
        List<Customer_Owned_Unit__c> unitList = SOQLUtil.getUnitByFieldName(new Map<String, String>{'Id' => unitId});
        List<Unit_Price_Cost__c> unitAdjustmentList = getUnitAdjustmentList(unitId);
        
        UnitWrapper unitWrapperObj = new UnitWrapper(unitList[0], new List<Customer_Owned_Unit__c>(), new List<Sales_Tax__c>(), new List<Service_Order_Header__c>(), unitAdjustmentList);
        return BPUtility.getEncodedString(System.JSON.serialize(unitWrapperObj.PriceAndCostTrackingWrapperList));
    }

    /**
     * Name: removeCOURecord
     * Desc: Remove Record with given Id
     * @param: (1) customerId - String - Id of Customer 
     * @return: String - JSON string of Customer info. 
    **/
    @RemoteAction
    global static String removePriceAndCost(String unitId, String recordId) {
        unitId = BPUtility.getDecodedString(unitId);
        recordId = BPUtility.getDecodedString(recordId);
        
        List<Sobject> sobjectListToDel = SOQLUtil.getReocrdByGivenId(recordId);
        if(sobjectListToDel.size() > 0) {
            if(AccessControl.ifObjectIsDeletable(sobjectListToDel[0]) == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
            delete sobjectListToDel[0];
        }
        return getUnitDetails(BPUtility.getEncodedString(unitId));
    }
    
    /**
    * Name: uploadImage
    * Desc: Method to upload image
    * @param: (1) filename - String - File Name
    *         (2) fileData - String - File to be uploaded
    *         (3) recordId - String - Parent Id of attachment
    *         (4) description - String - Description of attachment
    * @return: void
    **/
    @RemoteAction
    global static String uploadImage(String filename, String fileData, String recordId) {
        try {
            filename = BPUtility.getDecodedString(filename);
            fileData = BPUtility.getDecodedString(fileData);
            if(Limits.getHeapSize() > MAX_HEAP_SIZE) {
                return BPUtility.getEncodedString(System.JSON.serialize(new ResponseWrapper('error', 'File size is large')));
            }
            recordId = BPUtility.getDecodedString(recordId);
            
            if(fileData == null) {
                return BPUtility.getEncodedString(System.JSON.serialize(new ResponseWrapper('error', 'Invalid file data')));
            }
            String base64 = fileData.substring(fileData.indexOf(',') + 1);
            Blob actualdata = EncodingUtil.base64Decode(base64);
            if(AccessControl.ifObjectFieldIsAccessible('Document__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
            List<Document__c> existingImageList = [SELECT id FROM Document__c where Unit__c = :recordId];
            Document__c newDoc = new Document__c();
            newDoc.Is_Primary__c = existingImageList.size() == 0 ? true : false;
            newDoc.Unit__c = recordId;
            if(AccessControl.ifObjectFieldIsCreateable('Document__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_CREATEABLE); }
            insert newDoc;
            Attachment att = new Attachment(ParentId = newDoc.Id, Body = actualdata);
            att.Name = filename;
            if(AccessControl.ifObjectFieldIsCreateable('Attachment') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_CREATEABLE); }
            insert(att);
            if(GeneralConfiguration.isImagePublicURLCreationEnabled()) {
            	createPublicDocumentForImage_future(newDoc.Id, actualdata, filename);
            }
            return getDocumentsList(BPUtility.getEncodedString(recordId));
        } catch(Exception e){
            return BPUtility.getEncodedString(System.JSON.serialize(new ResponseWrapper('error', 'File size is large')));
        }
        return BPUtility.getEncodedString('');
    }
    
    @future
    private static void createPublicDocumentForImage_future(String docId, Blob imageBody, String fileName) {
    	String folderId = getFolderIdForDocuments();
		if(folderId != null) {
    		Document docToInsert = createPublicDocumentForImage(imageBody, fileName, folderId);
    		insert docToInsert;
    		
    		// update public URL in custom document created
			update new Document__c(Id = docId, Public_Image_URL__c = URL.getSalesforceBaseUrl().toExternalForm() + '/servlet/servlet.ImageServer?id=' + docToInsert.Id + '&oid=' + UserInfo.getOrganizationId());
		}
    }
    
    public static Document createPublicDocumentForImage(Blob imageBody, String fileName, String folderId) {
    	Document documentObj = new Document();
		documentObj.Body = imageBody;
		documentObj.Name = fileName;
		documentObj.IsPublic = true;
		documentObj.FolderId = folderId;
		return documentObj;
    }
    
    public static String getFolderIdForDocuments() {
    	List<Folder> folderList = [SELECT Id FROM Folder WHERE DeveloperName = 'Unit_Images'];
		if(folderList.size() == 0) {
			folderList = [SELECT Id FROM Folder LIMIT 1];
		}
		if(folderList.size() > 0) {
			return folderList[0].Id;
		}
		return null;
    }
    
    /**
    * Name: getDocumentsList
    * Desc: Method to get all images of  unit
    * @param: (1) unitId - String - unit id
    * @return: void
    **/
    @remoteAction
    global static String getDocumentsList(String unitId) {
        unitId = BPUtility.getDecodedString(unitId);
        if(AccessControl.ifObjectFieldIsAccessible('Document__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectFieldIsAccessible('Attachment') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<Document__c> docList = [select Id, Is_Primary__c, 
                                        (select Id, Name from Attachments) from Document__c where Unit__c = :unitId order By CreatedDate ASC];
        if(docList.size() == 0) {
            return BPUtility.getEncodedString('[]');
        }
        
        List<UnitWrapper.Documents> imageList = new List<UnitWrapper.Documents>();
        for(Document__c doc : docList) {
            imageList.add(new UnitWrapper.Documents(doc));
        }
        return BPUtility.getEncodedString(System.JSON.serialize(imageList));
    }
    
    /**
    * Name: pinImage
    * Desc: Method to set primary image for unit
    * @param: (1) docId - String - document id
              (2) IsPrimary - Boolean - whether to set image primary
              (3) unitId - String - unit id
    * @return: void
    **/
    @remoteAction
    global static String pinImage(String docId, Boolean IsPrimary, String unitId) {
        docId = BPUtility.getDecodedString(docId);
        unitId = BPUtility.getDecodedString(unitId);
        if(String.isNotBlank(docId)) {
            List<Document__c> docList = [select Id, Is_Primary__c from Document__c where Unit__c = :unitId and Is_Primary__c = true];
            for(Document__c doc: docList) {
                doc.Is_Primary__c = false;
            }
            if(AccessControl.ifObjectFieldIsUpdateable('Document__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
            Document__c docToUpdate = new Document__c();
            docToUpdate.Id = docId;
            docToUpdate.Is_Primary__c = IsPrimary;
            docList.add(docToUpdate);
            update docList;
        }
        
        return BPUtility.getEncodedString('Success');
    }
    
    /**
    * Name: deleteImage
    * Desc: Method to delete the image and set the next in order image to be the primary image if deleted image is primary
    * @param: (1) docId - String - document id to delete
              (2) unitId - String - unit id
    * @return: String
    **/
    @remoteAction
    global static String deleteImage(String docId, String unitId) {
        docId = BPUtility.getDecodedString(docId);
        unitId = BPUtility.getDecodedString(unitId);
        Boolean setPrimary = false;
        if(String.isNotBlank(docId)) {
            if(AccessControl.ifObjectFieldIsAccessible('Document__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
            if(AccessControl.ifObjectFieldIsAccessible('Attachment') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
            List<Document__c> docList = [select id, Is_Primary__c from Document__c where id =: docId];
            if(docList.size() > 0) {
                if(docList[0].Is_Primary__c) {
                    setPrimary = true;
                }
                if(AccessControl.ifObjectIsDeletable('Document__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
                if(AccessControl.ifObjectIsDeletable('Attachment') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
                delete docList;
            }
            
        }
        if(setPrimary) {
            List<Document__c> docList = [select Id, Is_Primary__c from Document__c where Unit__c = :unitId Order By CreatedDate ASC];
            if(docList.size() > 0) {
                docList[0].Is_Primary__c = true;
                update docList;
            }
        }
        
        return getDocumentsList(BPUtility.getEncodedString(unitId));
    }
    
    @remoteAction
    global static String getMakeModelSubmodelList() {
        try {
    	   return BPUtility.getEncodedString(MakeModelSubModelService.getMakeModelSubmodelList());
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    public static Customer_Owned_Unit__c setUnitFields(UnitWrapper.UnitInfoWrapper unitInfoObj) {
        
        Customer_Owned_Unit__c couRec = new Customer_Owned_Unit__c();

        couRec.Applicable_Tax__c = unitInfoObj.ApplicableTax;
        couRec.Automatic__c = (unitInfoObj.IsAutomatic != null) ? unitInfoObj.IsAutomatic : false;
        couRec.Account__c = unitInfoObj.Customer;
        couRec.Cylinders__c = unitInfoObj.Cylinders;
        couRec.Colour__c = unitInfoObj.ExteriorColour;
        couRec.Category__c = unitInfoObj.Category;
        couRec.Date_Stocked_In__c = String.isNotBlank(unitInfoObj.DateIn) ? Date.parse(unitInfoObj.DateIn) : null; 
        couRec.Date_Stocked_Out__c = String.isNotBlank(unitInfoObj.DateOut) ? Date.parse(unitInfoObj.DateOut) : null;
        couRec.Displacement__c = unitInfoObj.Displacement;
        couRec.Engine_Serial_No__c = unitInfoObj.EngineSerialNo;
        couRec.Gears__c = unitInfoObj.Gears;
        couRec.Interior_Colour__c = unitInfoObj.InteriorColour;
        couRec.Key_No__c = unitInfoObj.KeyNo;
        couRec.Location__c = unitInfoObj.Location;
        couRec.Manufactured_Date__c = String.isNotBlank(unitInfoObj.ManufacturedDate) ? Date.parse(unitInfoObj.ManufacturedDate) : null;
        couRec.Reg_Expiry_Date__c = String.isNotBlank(unitInfoObj.RegExpiryDate) ? Date.parse(unitInfoObj.RegExpiryDate) : null;
        couRec.Mileage_Value__c = unitInfoObj.Mileage;
        couRec.Mileage_Type__c = unitInfoObj.MileageType;
        couRec.Notes__c = unitInfoObj.Notes;
        couRec.New_Unit__c = (unitInfoObj.IsNewUnit != null) ? unitInfoObj.IsNewUnit : false;
        if(unitInfoObj.UnitType == 'STOCK') {
        	couRec.Publish_in_feeds__c = (unitInfoObj.IsPublishInFeeds != null) ? unitInfoObj.IsPublishInFeeds : true;
        }
        couRec.Other_Serial_No__c = unitInfoObj.OtherSerialNo;
        couRec.Plate__c = unitInfoObj.Plate;
        couRec.Status__c = unitInfoObj.Status;
        couRec.Sub_Model__c = unitInfoObj.SubModel;
        couRec.Taxable__c = (unitInfoObj.IsTaxable != null) ? unitInfoObj.IsTaxable : false;
        couRec.Unit_Id__c = unitInfoObj.UnitId;
        couRec.Unit_Make__c = unitInfoObj.Make;
        couRec.Unit_Model__c = unitInfoObj.Model;
        couRec.Unit_Type__c = unitInfoObj.UnitType;
        couRec.VIN_Number__c = unitInfoObj.VIN;
        couRec.Year__c = unitInfoObj.Year;
        couRec.Vendor__c = unitInfoObj.VendorId;
        couRec.Stock_Id__c = unitInfoObj.StockNumber;
        couRec.Compliance_Date__c = unitInfoObj.ComplianceDate;
        couRec.Registration_Serial__c = unitInfoObj.RegistrationSerial;
        couRec.Year_Of_1st_Rego__c = unitInfoObj.YearOf1stRego;
        if(unitInfoObj.IsSyncToDP360 != null && unitInfoObj.IsSyncToDP360 && DP360Service.isDP360Enabled()) {
            couRec.Available_For_DP360_Sync__c = unitInfoObj.IsSyncToDP360;
        }
        
        couRec = setUnitDataFields(couRec, unitInfoObj);
        if(unitInfoObj.UnitType == 'ORDU') {
    		couRec.Is_Accrue_Purchase_Tax_Until_Unit_Sold__c = unitInfoObj.IsAccruePurchaseTaxUntilThisUnitIsSold != null ? 
						unitInfoObj.IsAccruePurchaseTaxUntilThisUnitIsSold : GeneralConfiguration.isEnableTaxAccrualOnOrderUnits();
        }
        
        return couRec;
    }
    
    public static Customer_Owned_Unit__c setUnitDataFields(Customer_Owned_Unit__c couRec, UnitWrapper.UnitInfoWrapper unitInfoObj) {
    	couRec.Unit_Data_01__c = unitInfoObj.UnitData01;
        couRec.Unit_Data_02__c = unitInfoObj.UnitData02;
        couRec.Unit_Data_03__c = unitInfoObj.UnitData03;
        couRec.Unit_Data_04__c = unitInfoObj.UnitData04;
        couRec.Unit_Data_05__c = unitInfoObj.UnitData05;
        couRec.Unit_Data_06__c = unitInfoObj.UnitData06;
        couRec.Unit_Data_07__c = unitInfoObj.UnitData07;
        couRec.Unit_Data_08__c = unitInfoObj.UnitData08;
        couRec.Unit_Data_09__c = unitInfoObj.UnitData09;
        couRec.Unit_Data_10__c = unitInfoObj.UnitData10;
        couRec.Unit_Data_11__c = unitInfoObj.UnitData11;
        couRec.Unit_Data_12__c = unitInfoObj.UnitData12;
        couRec.Unit_Data_13__c = unitInfoObj.UnitData13;
        couRec.Unit_Data_14__c = unitInfoObj.UnitData14;
        couRec.Unit_Data_15__c = unitInfoObj.UnitData15;
        
        return couRec;
    }
    
    @RemoteAction 
    global static String getUnitDataFieldsConfig() {
    	return BPUtility.getEncodedString(System.JSON.serialize(GeneralConfiguration.getUnitDataFieldsConfig()));
    }
    
    private static Unit_Price_Cost__c setUnitPriceAndCostFields(UnitWrapper.PriceAndCostTrackingWrapper unitPriceAndCostObj) {
        
        Unit_Price_Cost__c unitPriceAndCostRec = new Unit_Price_Cost__c();

        unitPriceAndCostRec.Id = unitPriceAndCostObj.Id;
        unitPriceAndCostRec.Type__c = unitPriceAndCostObj.Type;
        unitPriceAndCostRec.Ref_No__c = unitPriceAndCostObj.RefNo;
        unitPriceAndCostRec.Item_Description__c = unitPriceAndCostObj.ItemDescription;
        unitPriceAndCostRec.Qty__c = unitPriceAndCostObj.Quantity;
        unitPriceAndCostRec.Price__c = unitPriceAndCostObj.Price;
        if(unitPriceAndCostRec.Type__c == 'Factory' || unitPriceAndCostRec.Type__c == 'Base') {
            unitPriceAndCostRec.Price__c = unitPriceAndCostObj.TotalPrice;
        }
        unitPriceAndCostRec.Total_Price__c = unitPriceAndCostObj.TotalPrice; 
        unitPriceAndCostRec.Total_Cost__c = unitPriceAndCostObj.TotalCost;
        unitPriceAndCostRec.Customer_Owned_Unit__c= unitPriceAndCostObj.UnitId;
        
        unitPriceAndCostRec.Adjustment_Date__c = String.isNotBlank(unitPriceAndCostObj.AdjustmentDate) ? HomeSearchFilterInterface.getDateFromString(unitPriceAndCostObj.AdjustmentDate) : null;
        unitPriceAndCostRec.Category__c = (String.isNotBlank(unitPriceAndCostObj.CategoryId) ? unitPriceAndCostObj.CategoryId : null);
        if(String.isNotBlank(unitPriceAndCostObj.VendorId)) {
        	unitPriceAndCostRec.Vendor__c = (String.isNotBlank(unitPriceAndCostObj.VendorId) ? unitPriceAndCostObj.VendorId	 : null);
        	unitPriceAndCostRec.Vendor_Reference_Number__c = unitPriceAndCostObj.VendorReferenceNumber;
        }
        if(String.isNotBlank(unitPriceAndCostObj.CustomerId)) {
        	unitPriceAndCostRec.Customer__c = unitPriceAndCostObj.CustomerId;
        	unitPriceAndCostRec.Customer_Reference_Number__c = unitPriceAndCostObj.CustomerReferenceNumber;
        }
        unitPriceAndCostRec.Applicable_Tax__c = unitPriceAndCostObj.ApplicableTaxID;
        return unitPriceAndCostRec;
    }
    
	@RemoteAction
    global static String getAdjustmentCategories() {
    	List<CategoryService.CategoryWrapper> categoryList = CategoryService.getFilteredCategoryWrapperList(new Map<String, String>{'Type__c' => Constants.CATEGORY_TYPE_ADJUSTMENT});
    	return BPUtility.getEncodedString(System.JSON.serialize(categoryList));
    }
	
    global static String validateVendorReferenceNumber(String recId, String vendorRefNum) {return '';}
    
	@RemoteAction
    global static String validateCustomerReferenceNumber(String recId, String customerId, String customerRefNum) {
    	recId = BPUtility.getDecodedString(recId);
    	customerId = BPUtility.getDecodedString(customerId);
    	customerRefNum = BPUtility.getDecodedString(customerRefNum);
    	
    	if(String.isBlank(customerId)) {
    		throw new BlackPurlException('Customer id is blank');
    	}
    	if(String.isBlank(customerRefNum)) {
    		throw new BlackPurlException('Customer reference number is blank');
    	}
    	List<Unit_Price_Cost__c> upcRecWithDuplicateRefNum = [Select Id from Unit_Price_Cost__c where Customer_Reference_Number__c =: customerRefNum 
    							AND Customer__c =: customerId AND Id != :recId LIMIT 1];
    	if(upcRecWithDuplicateRefNum.size() > 0) {
    		return BPUtility.getEncodedString('Error : Duplicate customer reference number');
    	}
    	return BPUtility.getEncodedString('Success');
    }
    
	@RemoteAction
    global static String validateVendorReferenceNumber(String recId, String vendorId, String vendorRefNum) {
    	recId = BPUtility.getDecodedString(recId);
    	vendorId = BPUtility.getDecodedString(vendorId);
    	vendorRefNum = BPUtility.getDecodedString(vendorRefNum);
    	
    	if(String.isBlank(vendorId)) {
    		throw new BlackPurlException('Vendor id is blank');
    	}
    	if(String.isBlank(vendorRefNum)) {
    		throw new BlackPurlException('Vendor reference number is blank');
    	}
    	List<Unit_Price_Cost__c> upcRecWithDuplicateRefNum = [Select Id from Unit_Price_Cost__c where Vendor_Reference_Number__c =: vendorRefNum 
    							AND Vendor__c =: vendorId AND Id != :recId LIMIT 1];
    	if(upcRecWithDuplicateRefNum.size() > 0) {
    		return BPUtility.getEncodedString('Error : Duplicate vendor reference number');
    	}
    	return BPUtility.getEncodedString('Success');
    }
	
    @RemoteAction
    global static String getVendorList() {
    	List<Account> vendorList = [SELECT Id, Name, Purchase_Tax__c, Purchase_Tax__r.Name__c FROM Account WHERE Is_Vendor__c = true AND Active__c = true ORDER BY Name ASC];
        List<Vendor> vendorObjList = new List<Vendor>();
    	for(Account vendorRec : vendorList) {
    		vendorObjList.add(new Vendor(vendorRec.Id, vendorRec.Name, vendorRec.Purchase_Tax__c, vendorRec.Purchase_Tax__r.Name__c));
    	}
    	return BPUtility.getEncodedString(System.JSON.serialize(vendorObjList, true));
    }
	
	@RemoteAction
    global static String getCustomerList() {
    	List<Customer> customerList = Customer_Service.getCustomerList();
    	return BPUtility.getEncodedString(System.JSON.serialize(customerList, true));
    }
	
	@RemoteAction
    global static String transferUnitOwnership(String unitId, String customerId) {
    	unitId = BPUtility.getDecodedString(unitId);
    	customerId = BPUtility.getDecodedString(customerId);
    	
    	if(String.isBlank(unitId)) {
    		throw new BlackPurlException('Unit Id is blank');
    	} else if(String.isBlank(customerId)) {
    		throw new BlackPurlException('Customer Id is blank');
    	}
    	
    	updateUnitStatus(unitId, 'Transferred');
    	String newUnitId = createDuplicateUnitWithUpdatedOwner(unitId, customerId);
    	return BPUtility.getEncodedString(newUnitId);
    }
    
    @RemoteAction
    global static String validateCustomerRefNumberInQB(String jSONString) {
    	if(QBUtil.isQBEnabled()) {
    		jSONString = BPUtility.getDecodedString(jSONString);
	        UnitWrapper.PriceAndCostTrackingWrapper unitPriceAndCostObj = (UnitWrapper.PriceAndCostTrackingWrapper) System.JSON.deserialize(jSONString, UnitWrapper.PriceAndCostTrackingWrapper.class);
	        return BPUtility.getEncodedString(validateCustRefNumInQB(unitPriceAndCostObj));
    	}
    	return BPUtility.getEncodedString('Success');
    }
    
    @RemoteAction
    global static String validateVendorRefNumberInQB(String jSONString) {
    	if(QBUtil.isQBEnabled()) {
    		jSONString = BPUtility.getDecodedString(jSONString);
	        UnitWrapper.PriceAndCostTrackingWrapper unitPriceAndCostObj = (UnitWrapper.PriceAndCostTrackingWrapper) System.JSON.deserialize(jSONString, UnitWrapper.PriceAndCostTrackingWrapper.class);
	        return BPUtility.getEncodedString(validateRefNumberInQB(unitPriceAndCostObj));
    	}
    	return BPUtility.getEncodedString('Success');
    }

    @RemoteAction
    global static String validateVendorRefNumberInXero(String jSONString) {
    	BaseIntegrationService integrationRec = IntegrationServiceFactory.getIntegrationServiceInstance('Accounting');
	   	if(integrationRec != null && integrationRec.integrationName == 'Xero') {
	   		jSONString = BPUtility.getDecodedString(jSONString);
	        UnitWrapper.PriceAndCostTrackingWrapper unitPriceAndCostObj = (UnitWrapper.PriceAndCostTrackingWrapper) System.JSON.deserialize(jSONString, UnitWrapper.PriceAndCostTrackingWrapper.class);
	        return BPUtility.getEncodedString(validateRefNumberInXero(unitPriceAndCostObj));
    	}
    	return BPUtility.getEncodedString('Success');
    }
    
    @RemoteAction
    global static String validateCustomerRefNumberInXero(String jSONString) {
    	BaseIntegrationService integrationRec = IntegrationServiceFactory.getIntegrationServiceInstance('Accounting');
	   	if(integrationRec != null && integrationRec.integrationName == 'Xero') {
	   		jSONString = BPUtility.getDecodedString(jSONString);
	        UnitWrapper.PriceAndCostTrackingWrapper unitPriceAndCostObj = (UnitWrapper.PriceAndCostTrackingWrapper) System.JSON.deserialize(jSONString, UnitWrapper.PriceAndCostTrackingWrapper.class);
	        return BPUtility.getEncodedString(validateCustRefNumInXero(unitPriceAndCostObj));
    	}
    	return BPUtility.getEncodedString('Success');
    }
    
    @RemoteAction
    global static String processManuallyClaimNITC(String unitId) {
    	unitId = BPUtility.getDecodedString(unitId);
    	update new Customer_Owned_Unit__c(Id = unitId, NITC_Claimed_Manually__c = true, NITC_Date_Claimed__c = system.today());
    	return BPUtility.getEncodedString('Success');
    }
    
    public static void updateUnitStatus(String unitId, String status) {
    	update new Customer_Owned_Unit__c(Id = unitId, Status__c = status);
    }
    
    public static String createDuplicateUnitWithUpdatedOwner(String unitId, String customerId) {
    	List<Customer_Owned_Unit__c> couList = new List<Customer_Owned_Unit__c>();
        String query = 'Select ';
        for(String fieldName : CustomerOwnedUnit.fieldsList()) {
            query += fieldName + ', ';
        }
        query = query.substring(0, query.length() - 2);
        query += ' from Customer_Owned_Unit__c where Id =:unitId';
        
        couList = Database.query(query);
        if(couList.size() == 0) {
            return null;
        }
        Customer_Owned_Unit__c couToInsert = couList[0].clone(false, false, false, false);
        
        couToInsert.put('Id',null);
        couToInsert.put('Unit_Type__c', 'COU');
        couToInsert.put('Unit_Id__c', null);
        couToInsert.put('Status__c', 'Active');
        couToInsert.put('Status__c', 'Active');
        couToInsert.put('Account__c', customerId);
        
        insert couToInsert;
        return couToInsert.Id;
    }
    
    private static String validateCustRefNumInQB(UnitWrapper.PriceAndCostTrackingWrapper unitPriceAndCostObj) {
    	if(String.isNotBlank(unitPriceAndCostObj.CustomerId)) {
            Account CustomerRec = [SELECT AccountingId__c FROM Account WHERE Id = :unitPriceAndCostObj.CustomerId];
			if(String.isNotBlank(CustomerRec.AccountingId__c)) {
				
                List<String> filterConditions = new List<String>{'DocNumber =\'' + unitPriceAndCostObj.CustomerReferenceNumber + '\'', 
													'customerref =\'' + CustomerRec.AccountingId__c + '\''};                                                        
				String entityName = '';
				if(unitPriceAndCostObj.TotalCost > 0) {
		            entityName = 'CreditMemo';
		        } else {
		        	entityName = 'Invoice';
		        }
		        try {
		        	QuickBookQueryService.ResponseQuickBooks qbResponse = QuickBookQueryService.getRecordsByFilter(entityName, filterConditions);
                    if(QuickBookQueryService.refreshToken !=  null) {
				        QBUtil.saveRefreshToken(QuickBookQueryService.refreshToken, QuickBookQueryService.refreshTokenExpiresIn);
			        }
					if(qbResponse == null) {
						return 'There is some error validating customer reference number from ' + QBUtil.QUICKBOOKS_ONLINE + '. Please try after some time.';
					} else {
						if((qbResponse.Invoice != null && qbResponse.Invoice.size() > 0) || (qbResponse.CreditMemo != null && qbResponse.CreditMemo.size() > 0)) {
				            return 'Duplicate';
				        }
				        return 'Success';
					}
		        } catch(Exception e) {
					if(e.getMessage().contains('invalid_grant')) {
						return 'Please check your connection to ' + QBUtil.QUICKBOOKS_ONLINE + '.';
					}
				}
			} else {
				return 'Customer is not synced to ' + QBUtil.QUICKBOOKS_ONLINE + ' for validating customer reference number';
			}
        }
        return '';
    }

    private static String validateCustRefNumInXero(UnitWrapper.PriceAndCostTrackingWrapper unitPriceAndCostObj) {
    	if(String.isNotBlank(unitPriceAndCostObj.CustomerId)) {
            Account CustomerRec = [SELECT Xero_Customer_Accounting_Id__c FROM Account WHERE Id = :unitPriceAndCostObj.CustomerId];
			if(String.isNotBlank(CustomerRec.Xero_Customer_Accounting_Id__c)) {
				List<IFW_IntegrationConfig__c> integrationConfigList = BaseIntegration.getParentByName('Xero');
				if(integrationConfigList.size() > 0) {
					String entityName = '';
					if(unitPriceAndCostObj.TotalCost > 0) {
			            entityName = 'Credit Note';
			        } else {
			        	entityName = 'Invoice';
			        }
					
					String whereClause = 'Contact.ContactID == Guid("' + CustomerRec.Xero_Customer_Accounting_Id__c + '")';
					whereClause += '&&' + (entityName == 'Invoice' ? 'InvoiceNumber' : 'CreditNoteNumber') + ' == "' + unitPriceAndCostObj.CustomerReferenceNumber + '"';
					XeroResponseWrapper responseWrapper = XeroService.getDataFromXero(entityName, whereClause, integrationConfigList[0]);
					if(responseWrapper == null) return 'Error validating customer reference number from Xero';
                    if((responseWrapper.Invoices != null && responseWrapper.Invoices.size() > 0) || (responseWrapper.CreditNotes != null && responseWrapper.CreditNotes.size() > 0)) {
                        return 'Duplicate';
                    } else {
                        return 'Success'; 
                    }
				}
				update integrationConfigList;
			} else {
				return 'Customer is not synced to Xero for validating customer reference number';
			}
        }
        return '';
    }
    
    private static String validateRefNumberInQB(UnitWrapper.PriceAndCostTrackingWrapper unitPriceAndCostObj) {
    	if(String.isNotBlank(unitPriceAndCostObj.VendorId)) {
            Account vendorRec = [SELECT Vendor_AccountingId__c FROM Account WHERE Id = :unitPriceAndCostObj.VendorId];
			if(String.isNotBlank(vendorRec.Vendor_AccountingId__c)) {
				List<String> filterConditions = new List<String>{'DocNumber =\'' + unitPriceAndCostObj.VendorReferenceNumber + '\'', 
													'VendorRef =\'' + vendorRec.Vendor_AccountingId__c + '\''};
				
				String entityName = '';
				if(unitPriceAndCostObj.TotalCost > 0) {
		            entityName = 'Bill';
		        } else {
		        	entityName = 'vendorcredit';
		        }
		        try {
		        	QuickBookQueryService.ResponseQuickBooks qbResponse = QuickBookQueryService.getRecordsByFilter(entityName, filterConditions);
                    if(QuickBookQueryService.refreshToken !=  null) {
				        QBUtil.saveRefreshToken(QuickBookQueryService.refreshToken, QuickBookQueryService.refreshTokenExpiresIn);
			        }
					if(qbResponse == null) {
						return 'There is some error validating vendor reference number from ' + QBUtil.QUICKBOOKS_ONLINE + '. Please try after some time.';
					} else {
						if((qbResponse.Bill != null && qbResponse.Bill.size() > 0) || (qbResponse.VendorCredit != null && qbResponse.VendorCredit.size() > 0)) {
				            return 'Duplicate';
				        }
				        return 'Success';
					}
		        } catch(Exception e) {
					if(e.getMessage().contains('invalid_grant')) {
						return 'Please check your connection to ' + QBUtil.QUICKBOOKS_ONLINE + '.';
					}
				}
			} else {
				return 'Vendor is not synced to ' + QBUtil.QUICKBOOKS_ONLINE + ' for validating vendor reference number';
			}
        }
        return '';
    }
    
    private static String validateRefNumberInXero(UnitWrapper.PriceAndCostTrackingWrapper unitPriceAndCostObj) {
    	if(String.isNotBlank(unitPriceAndCostObj.VendorId)) {
            Account vendorRec = [SELECT Xero_Vendor_Accounting_Id__c FROM Account WHERE Id = :unitPriceAndCostObj.VendorId];
			if(String.isNotBlank(vendorRec.Xero_Vendor_Accounting_Id__c)) {
				List<IFW_IntegrationConfig__c> integrationConfigList = BaseIntegration.getParentByName('Xero');
				if(integrationConfigList.size() > 0) {
					String entityName = '';
					if(unitPriceAndCostObj.TotalCost > 0) {
			            entityName = 'Invoice';
			        } else {
			        	entityName = 'Credit Note';
			        }
					
					String whereClause = 'Contact.ContactID == Guid("' + vendorRec.Xero_Vendor_Accounting_Id__c + '")';
					whereClause += '&&' + (entityName == 'Invoice' ? 'InvoiceNumber' : 'CreditNoteNumber') + ' == "' + unitPriceAndCostObj.VendorReferenceNumber + '"';
					XeroResponseWrapper responseWrapper = XeroService.getDataFromXero(entityName, whereClause, integrationConfigList[0]);
					if(responseWrapper == null) return 'Error validating vendor reference number from Xero';
                    if((responseWrapper.Invoices != null && responseWrapper.Invoices.size() > 0) || (responseWrapper.CreditNotes != null && responseWrapper.CreditNotes.size() > 0)) {
                        return 'Duplicate';
                    } else {
                        return 'Success'; 
                    }
				}
				update integrationConfigList;
			} else {
				return 'Vendor is not synced to Xero for validating vendor reference number';
			}
        }
        return '';
    }
}