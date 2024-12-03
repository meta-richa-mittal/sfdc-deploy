/** 
* Author: Manoj Sharma
* Since: June 20, 2020 
* Name: BRPPartInventoryBatch 
* Description: Apex batch class to create xml file for part inventory and send them to heroku.
**/
global without sharing class BRPPartInventoryBatch implements Database.Batchable<sobject>, Database.AllowsCallouts, Database.Stateful {
    private String fileData = '';   
    private Integer MAX_LIMIT = 5000;
    private Integer batchNumber;
    private Boolean hasPartLineItemPresent = false;
    private DateTime dateTimeValue;
    public static String newLineSeparator = '\r\n'; 
    public static String contentType = 'text/csv';
    public static String csvFileExtension = '.csv';
    public static String FILE_TYPE = 'PI';
    public Set<String> brpVendorsIdSet;
    public static String attParentId;
    public static String entityName = 'SendPartInventory';
    public Integer partIndex;

    global BRPPartInventoryBatch(Date dateValue, Integer partIndex) {
        this.batchNumber = 1;
        this.partIndex = partIndex;
        this.dateTimeValue = DateTime.newInstance(dateValue.year(), dateValue.month(), dateValue.day());
    }
    
    global BRPPartInventoryBatch(Date dateValue, Integer partIndex, Integer batchNumber) {
        this.batchNumber = batchNumber;
        this.partIndex = partIndex;
        this.dateTimeValue = DateTime.newInstance(dateValue.year(), dateValue.month(), dateValue.day());
    }

    global Database.QueryLocator start(Database.BatchableContext bc){
        brpVendorsIdSet = BRPUtility.getAllBRPVendorsIdSet();
        String strQuery = 'SELECT Id, Name, Part_Number__c, Qty_In_Stock__c, Qty_On_Order__c, Auto_reorder_Min__c, MSRP__c, AvailableParts__c, Last_Sold__c, ' +
        'Auto_reorder_Max__c, Last_Stocked__c, Last_Counted__c, Is_Included_In_BRP_Inventory__c FROM Part__c where Is_Included_In_BRP_Inventory__c = false';
        strQuery += ' AND Vendor__c IN : brpVendorsIdSet AND BRP_Part_Index__c = '+ partIndex + ' AND (Last_Sold__c = LAST_N_Days:730 OR ((Last_Sold__c = null OR Last_Sold__c <= LAST_N_Days:730) AND Qty_In_Stock__c > 0))'; 
        strQuery += ' Order By Name ASC LIMIT ' + MAX_LIMIT ;
        return Database.getQueryLocator(strQuery); 
    }
    
    global void execute(Database.batchableContext bc, List<Part__c> partList) {
        setFileData(partList);
        this.hasPartLineItemPresent = true;
    }
    
    public void setFileData(List<Part__c> partList) {

        DOM.Document body = new DOM.Document();
        String prefix = 'star';
        String nameSpace = 'http://www.starstandard.org/STAR/5';
        DOM.XmlNode root = body.createRootElement('PartsInventoryHeader', nameSpace, prefix);
        root.setNamespace('star',nameSpace);
        
        for(Part__c partRec : partList) {

            dom.XmlNode partsInventoryLine = root.addChildElement('PartsInventoryLine', nameSpace, prefix);
            dom.XmlNode quantityOnHand = partsInventoryLine.addChildElement('QuantityOnHand', nameSpace, prefix).addTextNode(String.valueOf(partRec.Qty_In_Stock__c));
            dom.XmlNode quantityOnOrder = partsInventoryLine.addChildElement('QuantityOnOrder', nameSpace, prefix).addTextNode(String.valueOf((partRec.Qty_On_Order__c != null ? partRec.Qty_On_Order__c : 0)));
            dom.XmlNode quantityReOrderPoint = partsInventoryLine.addChildElement('QuantityReOrderPoint', nameSpace, prefix).addTextNode(String.valueOf((partRec.Auto_reorder_Min__c != null ? partRec.Auto_reorder_Min__c : 0)));
            dom.XmlNode unitPriceAmount = partsInventoryLine.addChildElement('UnitPriceAmount', nameSpace, prefix);
            unitPriceAmount.setAttribute('currencyID', BRPUtility.CurrencyCode);
            unitPriceAmount.addTextNode(String.valueOf(partRec.MSRP__c));
            dom.XmlNode quantityAvailable = partsInventoryLine.addChildElement('QuantityAvailable', nameSpace, prefix).addTextNode(String.valueOf(partRec.AvailableParts__c));
            if(partRec.Last_Sold__c != null) {
                dom.XmlNode lastSoldDate = partsInventoryLine.addChildElement('LastSoldDate', nameSpace, prefix).addTextNode(DateTimeUtility.getFormttedDateFromDateTime(partRec.Last_Sold__c, 'yyyy-MM-dd'));
            }
            dom.XmlNode quantityUserMin = partsInventoryLine.addChildElement('QuantityUserMin', nameSpace, prefix).addTextNode(String.valueOf((partRec.Auto_reorder_Min__c != null ? partRec.Auto_reorder_Min__c : 0)));
            dom.XmlNode quantityUserMax = partsInventoryLine.addChildElement('QuantityUserMax', nameSpace, prefix).addTextNode(String.valueOf((partRec.Auto_reorder_Max__c != null ? partRec.Auto_reorder_Max__c : 0)));
            dom.XmlNode quantityBestStockingLevel = partsInventoryLine.addChildElement('QuantityBestStockingLevel', nameSpace, prefix).addTextNode(String.valueOf((partRec.Auto_reorder_Max__c != null ? partRec.Auto_reorder_Max__c : 0)));
            dom.XmlNode partsProductItem = partsInventoryLine.addChildElement('PartsProductItem', nameSpace, prefix);
            dom.XmlNode itemIdentificationGroup = partsProductItem.addChildElement('ItemIdentificationGroup', nameSpace, prefix);
            dom.XmlNode itemIdentification = itemIdentificationGroup.addChildElement('ItemIdentification', nameSpace, prefix);
            dom.XmlNode itemID = itemIdentification.addChildElement('ItemID', nameSpace, prefix).addTextNode(String.valueOf(partRec.Part_Number__c));
            dom.XmlNode uomCode = partsProductItem.addChildElement('UOMCode', nameSpace, prefix).addTextNode('ea');
            if(partRec.Last_Stocked__c != null){
                dom.XmlNode lastReceiptDate = partsInventoryLine.addChildElement('LastReceiptDate', nameSpace, prefix).addTextNode(DateTimeUtility.getFormttedDateFromDateTime(partRec.Last_Stocked__c, 'yyyy-MM-dd'));
            }
            if(partRec.Last_Counted__c !=  null){
                dom.XmlNode lastPhysicalInventoryDate = partsInventoryLine.addChildElement('LastPhysicalInventoryDate', nameSpace, prefix).addTextNode(DateTimeUtility.getFormttedDateFromDateTime(partRec.Last_Counted__c, 'yyyy-MM-dd'));
            }
            partRec.Is_Included_In_BRP_Inventory__c = true;
        }
        fileData += (body.toXmlString()).replace('<?xml version="1.0" encoding="UTF-8"?><star:PartsInventoryHeader xmlns:star="http://www.starstandard.org/STAR/5">', '').replace('</star:PartsInventoryHeader>', '');
        PartTriggerHelper.isForceStopTrigger = true;
        update partList;
        PartTriggerHelper.isForceStopTrigger = false;
    }
    
    global void finish(Database.batchableContext bc) {
        attParentId = BRPUtility.getBRPFileStorageId();
        
        if(String.isNotBlank(fileData)) {
            handleFinish(fileData,this.batchNumber, this.dateTimeValue);
        }
        if(this.hasPartLineItemPresent) {
            Database.executeBatch(new BRPPartInventoryBatch(Date.newInstance(this.dateTimeValue.year(), this.dateTimeValue.month(), this.dateTimeValue.day()), this.partIndex,
            	this.batchNumber + 1), 500);
        } else {
            String attachmentName = BRPUtility.getFileNameByFileType(FILE_TYPE, this.dateTimeValue) + '%';
            Map<String, Attachment> brpAttachedFileMap = new Map<String, Attachment>([SELECT Id FROM Attachment WHERE ParentId =: attParentId AND Name LIKE :attachmentName]);
            if(isFileGenerationComplete(brpAttachedFileMap.keySet().size(), this.dateTimeValue, brpVendorsIdSet)) {
                if(brpAttachedFileMap.size() > 0) {
                    System.enqueueJob(new MergeAndPostToBRPQueueable(entityName, brpAttachedFileMap.keySet(), this.dateTimeValue));
                }
                Date todaysDate = Date.newInstance(this.dateTimeValue.year(), this.dateTimeValue.month(), this.dateTimeValue.day());
                BRPPartInventoryScheduler.runNextJobAt10PM(todaysDate.addDays(1));
            }
        }
    }

    public static Boolean isFileGenerationComplete(Integer actualTotalAttachments, Datetime dateTimeValue, Set<String> brpVendorsIdSet) {
    	
    	Integer expectedTotalAttachments = getExpectedNumberOfAttchments(brpVendorsIdSet);
        
        if(actualTotalAttachments == expectedTotalAttachments) {
        	return true;
        } else if(actualTotalAttachments > expectedTotalAttachments) {
            new BRPLogService().createLog('Parts Inventory', null, null, null, '400', 'BRP Part Inventory File creation failed as more files created than expected', 'Error', 'BRPPartInventoryBatch', 'isFileGenerationComplete', null);
    		Date todaysDate = Date.newInstance(dateTimeValue.year(), dateTimeValue.month(), dateTimeValue.day());
            BRPPartInventoryScheduler.runNextJobAt10PM(todaysDate.addDays(1));
        }
        return false;
    }

    public static Integer getExpectedNumberOfAttchments(Set<String> brpVendorsIdSet) {
    	Integer totalAttchWithIndex1 = getNumberOfAttchByIndex(1, brpVendorsIdSet);
    	Integer totalAttchWithIndex2 = getNumberOfAttchByIndex(2, brpVendorsIdSet);
    	Integer totalAttchWithIndex3 = getNumberOfAttchByIndex(3, brpVendorsIdSet);
    	Integer totalAttchWithIndex4 = getNumberOfAttchByIndex(4, brpVendorsIdSet);
    	Integer totalAttchWithIndex5 = getNumberOfAttchByIndex(5, brpVendorsIdSet);
    	
        return (totalAttchWithIndex1 + totalAttchWithIndex2 + totalAttchWithIndex3 + totalAttchWithIndex4 + totalAttchWithIndex5);
    }
    
    public static void handleFinish(String fileContent, Integer batchNumber, DateTime dateOfFileData) {
        Attachment attch = createAttachment(fileContent, batchNumber, dateOfFileData);
        insertAttachment(new List<Attachment>{attch});
    }

    public static Attachment createAttachment(String fileContent, Integer batchNumber, DateTime dateOfFileData) {
        Attachment attachment = new Attachment();
        attachment.ParentId = attParentId; 
        attachment.ContentType = contentType;
        
        dateOfFileData = dateOfFileData != null ? dateOfFileData : system.now();
        String batchNumberInTwoDigits = '';
        if(batchNumber != null) {
        	batchNumberInTwoDigits = '_' + ((batchNumber > 9) ? String.valueOf(batchNumber) : ('0' + batchNumber));
        }
        attachment.Name = BRPUtility.getFileNameByFileType(FILE_TYPE, dateOfFileData)+ batchNumberInTwoDigits + csvFileExtension;
        attachment.Body = Blob.valueOf(fileContent);
        return attachment;
    }

    private static void insertAttachment(List<Attachment> attachmentList) {
        DMLUtility.insertSobjectList('Attachment', attachmentList);
    }

    public static Integer getNumberOfAttchByIndex(Integer indexValue, Set<String> brpVendorIdSet) {
        Integer totalPartsWithSpecifiedIndex = 0;
        List<AggregateResult> aggList = [Select Count(Id) totalParts from Part__c where BRP_Part_Index__c =: indexValue AND (Last_Sold__c = LAST_N_Days:730 OR ((Last_Sold__c = null OR Last_Sold__c <= LAST_N_Days:730) AND Qty_In_Stock__c > 0)) AND Vendor__c IN :brpVendorIdSet];
        if(aggList.size() > 0) {
            totalPartsWithSpecifiedIndex = (Integer) aggList[0].get('totalParts');
        }
          
        Integer totalAttchWithSpecifiedIndex = totalPartsWithSpecifiedIndex/BRPPartInventoryScript.Max_LIMIT;
        if(Math.mod(totalPartsWithSpecifiedIndex, BRPPartInventoryScript.Max_LIMIT) != null && math.mod(totalPartsWithSpecifiedIndex, BRPPartInventoryScript.Max_LIMIT) > 0) {
            totalAttchWithSpecifiedIndex += 1;
        }
        return totalAttchWithSpecifiedIndex;
    }
}