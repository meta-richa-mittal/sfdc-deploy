/**
* Author: Nidhi Sharma
* Since: Nov 1, 2019
* Name: SOMPartInventoryBatch
* Description:
**/
global without sharing class SOMPartInventoryBatch implements Database.Batchable<sobject>, Database.AllowsCallouts, Database.Stateful {

    private String fileData = '';           
    private Integer totalRecords = 0;
    private Integer MAX_LIMIT = SOMPartInventoryBatchManager.Max_LIMIT;
    private Integer batchNumber;
    private Boolean hasPartLineItemPresent = false;
    private DateTime dateTimeValue;
    public static String fileSeparator = '|';
    public static String newLineSeparator = '\r\n'; 
    public static final String PART_INVENTORY_SNAPSHOT = 'Part inventory snapshot';
    public static final String PART_SALES_TRANSACTIONS = 'Part sales transactions';
    public static final String PARTS_ON_ORDER = 'Parts on order';
    public static String contentType = 'text/csv';
    public static String csvFileExtension = '.csv';
    public String orgCode = getOrgCode();
    public Integer partIndex;
    
    // Deprecated - Not in used
    global SOMPartInventoryBatch() {
        this.batchNumber = 1;
        this.dateTimeValue = Date.newInstance(system.today().year(), system.today().month(), system.today().day());
    }
    
    // Deprecated - Not in used
    global SOMPartInventoryBatch(Integer batchNumber) {
        this.batchNumber = batchNumber;
        this.dateTimeValue = Date.newInstance(system.today().year(), system.today().month(), system.today().day());
    }
    
    // Deprecated - Not in used
    global SOMPartInventoryBatch(Date dateValue) {
        this.batchNumber = 1;
        this.dateTimeValue = dateValue;
    }
    
    // Deprecated - Not in used
    global SOMPartInventoryBatch(Integer batchNumber, Date dateValue) {
        this.batchNumber = batchNumber;
        this.dateTimeValue = dateValue;
    }
    
    global SOMPartInventoryBatch(Date dateValue, Integer partIndex) {
        this.batchNumber = 1;
        this.partIndex = partIndex;
        this.dateTimeValue = DateTime.newInstance(dateValue.year(), dateValue.month(), dateValue.day());
    }
    
    global SOMPartInventoryBatch(Integer batchNumber, Integer partIndex, Date dateValue) {
        this.batchNumber = batchNumber;
        this.partIndex = partIndex;
        this.dateTimeValue = DateTime.newInstance(dateValue.year(), dateValue.month(), dateValue.day());
    }
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        String strQuery = 'SELECT Name, Part_Number__c, Vendor_Code__c, Category__r.Name, AvailableParts__c, Last_Cost__c, Average_Cost__c, Qty_Committed__c, ' +
                        'Packaged_Part__c, Package_Qty__c, Part_Type__c, Active__c, Non_Inventory_Part__c, Replaced_By_Part__c, Retail_Price__c, ' +
                        'Is_Superseded__c, Superseded_To__c, Superseded_To__r.Part_Number__c, CreatedDate, Assigned_Tag_1__c, Assigned_Tag_2__c ' +
                        'FROM Part__c where Is_Included_In_SOM__c = false AND Part_Index__c = ' + partIndex;
        strQuery += (this.dateTimeValue != null ? ' AND CreatedDate < ' + (this.dateTimeValue.addDays(1)).formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'') : '');
        strQuery += ' Order By Name ASC LIMIT ' + MAX_LIMIT ;
        return Database.getQueryLocator(strQuery); 
    }
    
    global void execute(Database.batchableContext bc, List<Part__c> partList) {
        setFileData(partList);
        this.hasPartLineItemPresent = true;
    }
    
    public static String getOrgCode() {
        return SOM_Configuration__c.getOrgDefaults().Org_Code__c;
    }
    
    private void setFileData(List<Part__c> partList) {
        for(Part__c partRec : partList) {
            fileData += orgCode + fileSeparator;
            fileData += partRec.Part_Number__c + fileSeparator;
            fileData += partRec.Vendor_Code__c + fileSeparator;
            fileData += partRec.Category__r.Name + fileSeparator;
            fileData += partRec.AvailableParts__c + fileSeparator;
            fileData += (partRec.Last_Cost__c != null ? partRec.Last_Cost__c.setScale(2, RoundingMode.HALF_UP) : 0) + fileSeparator;
            fileData += (partRec.Average_Cost__c != null ? partRec.Average_Cost__c.setScale(2, RoundingMode.HALF_UP) : 0) + fileSeparator;
            fileData += (partRec.Retail_Price__c != null ? partRec.Retail_Price__c.setScale(2, RoundingMode.HALF_UP) : 0) + fileSeparator;
            fileData += (partRec.Packaged_Part__c ? '1' : '0') + fileSeparator;
            fileData += (partRec.Packaged_Part__c ? String.valueOf(partRec.Package_Qty__c) : ' ') + fileSeparator;
            fileData += ' ' + fileSeparator;     //ServiceQty
            
            fileData += (partRec.Part_Type__c != null && partRec.Part_Type__c == 'Merchandise' ? '1' : '0') + fileSeparator;
            fileData += ' ' + fileSeparator;     //Style
            fileData += getObsoleteValue(partRec) + fileSeparator;     //ObsoleteStatus
            fileData += (partRec.Active__c ? '0' : '1') + fileSeparator;     //Inactive
            fileData += (partRec.Non_Inventory_Part__c ? '1' : '0') + fileSeparator;     //NonStock
            
            if(partRec.Is_Superseded__c) {
                fileData += '1' + fileSeparator;        //Superseded
                fileData += partRec.Superseded_To__r.Part_Number__c + fileSeparator;        //SupersededTo
            } else {
                fileData += '0' + fileSeparator;     //Superseded
                fileData += ' ' + fileSeparator;     //SupersededTo
            }
            
            fileData += ' ' + fileSeparator;     //Seasonal
            fileData += (partRec.Qty_Committed__c != null ? partRec.Qty_Committed__c : 0) + fileSeparator;     //SeasonStartMonth
            fileData += ' ' + fileSeparator;     //SeasonStartDay
            fileData += ' ' + fileSeparator;     //SeasonEndMonth
            fileData += ' ' + fileSeparator;     //SeasonEndDay
            fileData += partRec.CreatedDate.format('yyyy-MM-dd');       //CreatedOn
            fileData += newLineSeparator;
            
            partRec.Is_Included_In_SOM__c = true;
        }
        SOMUtility.updatePartRecords(partList);
    }
    
    public static String getObsoleteValue(Part__c partRec) {
        if(partRec != null && (TagService.containsRequiredTagIgnoreCase(partRec.Assigned_Tag_1__c, 'Obsolete') || 
                          TagService.containsRequiredTagIgnoreCase(partRec.Assigned_Tag_2__c, 'Obsolete'))) {
          	return 'O';
    	} else if(partRec != null && (TagService.containsRequiredTagIgnoreCase(partRec.Assigned_Tag_1__c, 'use out') || 
                                TagService.containsRequiredTagIgnoreCase(partRec.Assigned_Tag_2__c, 'use out') || 
                                TagService.containsRequiredTagIgnoreCase(partRec.Assigned_Tag_1__c, 'pending obsolete') || 
                                TagService.containsRequiredTagIgnoreCase(partRec.Assigned_Tag_2__c, 'pending obsolete'))) {
            return 'U';
        }
    	return '';
    }
    
    global void finish(Database.batchableContext bc) {
        if(String.isNotBlank(fileData)) {
            handleFinish(PART_INVENTORY_SNAPSHOT, fileData, totalRecords, this.batchNumber, this.dateTimeValue);
        }
        
        if(this.hasPartLineItemPresent) {
            Database.executeBatch(new SOMPartInventoryBatch(this.batchNumber + 1, this.partIndex,
                    Date.newInstance(this.dateTimeValue.year(), this.dateTimeValue.month(), this.dateTimeValue.day())), 500);
        } else {
            String fileName = getFileNameByFileType(PART_INVENTORY_SNAPSHOT, this.dateTimeValue);
            updateFileNameInCustomSetting(fileName);
            
            if(isFileGenerationComplete(fileName, this.dateTimeValue)) {
                BPScriptUtility.enableTrigger('PartTrigger');
                scheduleFilePostToFTP();
                Date todaysDate = Date.newInstance(this.dateTimeValue.year(), this.dateTimeValue.month(), this.dateTimeValue.day());
                SOMScheduler.runNextJobAt10PM(todaysDate.addDays(1));
            }
        }
    }
    
    private void scheduleFilePostToFTP() {
        String scheduledJobName = 'Post SOMPartInventory Scheduler';
        List<CronTrigger> existingSheduledJobs = [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name =: scheduledJobName];
        if(existingSheduledJobs.size() > 0) {
            system.abortJob(existingSheduledJobs[0].Id);
        }

        // schedule 5 mins after the current time
        DateTime currentDateTime = (system.now()).addMinutes(5);
        String strSchedule = String.valueOf(currentDateTime.second()) + ' ' + String.valueOf(currentDateTime.minute()) + ' ' + String.valueOf(currentDateTime.hour()) + 
                                ' ' + String.valueOf(currentDateTime.day()) + ' ' + String.valueOf(currentDateTime.month()) + ' ?' + ' ' + String.valueOf(currentDateTime.year());
        system.schedule(scheduledJobName, strSchedule, new MergeAndPostToSOMScheduler());
    }
    
    public static Integer getNumberOfAttchByIndex(Integer indexValue) {
        Integer totalPartsWithSpecifiedIndex = 0;
        List<AggregateResult> aggList = [Select Count(Id) totalParts from Part__c where Part_Index__c =: indexValue];
        if(aggList.size() > 0) {
            totalPartsWithSpecifiedIndex = (Integer) aggList[0].get('totalParts');
        }
        
        Integer totalAttchWithSpecifiedIndex = totalPartsWithSpecifiedIndex/SOMPartInventoryBatchManager.Max_LIMIT;
        if(Math.mod(totalPartsWithSpecifiedIndex, SOMPartInventoryBatchManager.Max_LIMIT) != null 
                        && math.mod(totalPartsWithSpecifiedIndex, SOMPartInventoryBatchManager.Max_LIMIT) > 0) {
            totalAttchWithSpecifiedIndex += 1;
        }
        return totalAttchWithSpecifiedIndex;
    }
    
    public static Integer getExpectedNumberOfAttchments() {
        Integer totalAttchWithIndex1 = getNumberOfAttchByIndex(1);
        Integer totalAttchWithIndex2 = getNumberOfAttchByIndex(2);
        Integer totalAttchWithIndex3 = getNumberOfAttchByIndex(3);
        Integer totalAttchWithIndex4 = getNumberOfAttchByIndex(4);
        Integer totalAttchWithIndex5 = getNumberOfAttchByIndex(5);
        
        return (totalAttchWithIndex1 + totalAttchWithIndex2 + totalAttchWithIndex3 + totalAttchWithIndex4 + totalAttchWithIndex5);
    }
    
    public static Boolean isFileGenerationComplete(String fileName, Datetime dateTimeValue) {
        
        Integer expectedTotalAttachments = getExpectedNumberOfAttchments();
        
        Integer actualTotalAttachments = 0;
        List<AggregateResult> attachmentAggList = [Select Count(Id) actualTotalAttachments from Attachment where Name Like :(fileName + '%')];
        if(attachmentAggList.size() > 0) {
            actualTotalAttachments = (Integer) attachmentAggList[0].get('actualTotalAttachments');
        }
        
        if(actualTotalAttachments == expectedTotalAttachments) {
            return true;
        } else if(actualTotalAttachments > expectedTotalAttachments) {
            BPScriptUtility.enableTrigger('PartTrigger');
            insert new Log__c(Integration_Type__c = 'SOM', Error_Code__c = null, Log_Info__c = 'SOM Part inventory file creation failed due to number of files exceeded than expected.',
                        Apex_Class__c = 'SOMPartInventoryBatch', Type__c = 'Error', Method_Params__c = 'File name ' + fileName);
            sendErrorMail();
            Date todaysDate = Date.newInstance(dateTimeValue.year(), dateTimeValue.month(), dateTimeValue.day());
            SOMScheduler.runNextJobAt10PM(todaysDate.addDays(1));
        }
        
        return false;
    }
    
    private static void sendErrorMail() {
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        message.ToAddresses = new List<String>{'blackpurl@metacube.com'};
        message.Subject = UserInfo.getOrganizationName() + ' - SOM Part Inventory File creation failed as more files created than expected';
        message.PlainTextBody = 'Hi,\n\n'+ 
                                'SOM Part inventory file creation failed due to number of files exceeded than expected. \n\n' +
                                'Thank You\nTeam Blackpurl';
        
        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{message});
    }
    
    private static void updateFileNameInCustomSetting(String fileName) {
        BP_Configurations__c bpConfig = BP_Configurations__c.getOrgDefaults();
        bpConfig.SOM_Part_Inventory_File_Name__c = fileName;
        DMLUtility.upsertSobjectList('BP_Configurations__c', bpConfig);
    }
    
    public static void sendFinishMail() {
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        message.ToAddresses = new List<String>{'blackpurl@metacube.com'};
        message.Subject = UserInfo.getOrganizationName() + ' - SOM Part Inventory File export completed';
        message.PlainTextBody = 'Hi,\n\n'+ 
                                'SOM Part Inventory File export completed. Please run your java program to merge file.\n\n' +
                                'Thank You\nTeam Blackpurl';
        
        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{message});
    }
    
    public static void handleFinish(String fileType, String fileContent, Integer totalRecords, Integer batchNumber, DateTime dateOfFileData) {
        Attachment attch = createAttachment(fileType, fileContent, totalRecords, batchNumber, dateOfFileData);
        insertAttachment(new List<Attachment>{attch}, fileType);
    }
    
    private static Map<String, List<String>> fileTypeToFieldLabelListMap = new Map<String, List<String>> {
                    PART_INVENTORY_SNAPSHOT => new List<String>{'OrgCode','PartNumber','VendorCode','PartGroupID','QtyAvailable','Cost','AvgCost','Price','IsPackage',
                                                            'PackageUnit','ServiceQty','IsGM','Style','ObsoleteStatus','Inactive','NonStock','Superseded','SupersededTo',
                                                            'Seasonal','SeasonStartMonth','SeasonStartDay','SeasonEndMonth','SeasonEndDay','CreatedOn'},
                                                            
                    PART_SALES_TRANSACTIONS => new List<String>{'OrgCode','InvoiceID','CustomerID','PartNumber','VendorCode','Qty','Price','Cost','ExceptionalSale',
                                                            'IsSpecialOrder','CustomerCity','CustomerState','CustomerCountry','SoldBy','SoldOn'},
                                                            
                    PARTS_ON_ORDER => new List<String>{'OrgCode', 'PONumber', 'VendorCode', 'PartNumber', 'QtyOrderedNotReceived', 
                                                            'IsSpecialOrder', 'ExceptionalOrder', 'SubmittedOn'}
    };
    
    public static String getHeaderByFileType(String fileType) {
        String header = '';
        if(fileTypeToFieldLabelListMap.containsKey(fileType)) {
            header = String.join(fileTypeToFieldLabelListMap.get(fileType), fileSeparator);
        }
        return header;
    }
    
    public static Attachment createAttachment(String fileType, String fileContent, Integer totalLines, Integer batchNumber, DateTime dateOfFileData) {
        Attachment attachment = new Attachment();
        
        if(batchNumber == null || batchNumber == 1) {
            fileContent = getHeaderByFileType(fileType) + newLineSeparator + fileContent;
        }
        attachment.ParentId = getSOMAttachmentParentId(); 
        attachment.ContentType = contentType;
        attachment.Description = fileType;
        
        dateOfFileData = dateOfFileData != null ? dateOfFileData : system.now();
        String batchNumberInTwoDigits = '';
        if(batchNumber != null) {
            batchNumberInTwoDigits = '_' + ((batchNumber > 9) ? String.valueOf(batchNumber) : ('0' + batchNumber));
        }
        attachment.Name = getFileNameByFileType(fileType, dateOfFileData) + batchNumberInTwoDigits + csvFileExtension;
        attachment.Body = Blob.valueOf(fileContent);
        return attachment;
    }
    
    private static Map<String, String> fileTypeToFileNameInitialsMap = new Map<String, String> {PART_INVENTORY_SNAPSHOT => 'INV',
                                                                                                PART_SALES_TRANSACTIONS => 'PSI',
                                                                                                PARTS_ON_ORDER => 'POO'};
    
    public static String getFileNameByFileType(String fileType, DateTime dateTimeValue) {
        String fileName = '';
        if(fileTypeToFileNameInitialsMap.containsKey(fileType)) {
            fileName = fileTypeToFileNameInitialsMap.get(fileType) + '_';
        }
        fileName += getOrgCode() + '_';
        fileName += (dateTimeValue != null ? dateTimeValue.format('yyyyMMdd') : Datetime.now().format('yyyyMMdd'));
        
        return fileName;
    }
    
    public static String getSOMAttachmentParentId() {
        List<SOM_Integration__c> SOMIntegrationList = [SELECT Id FROM SOM_Integration__c LIMIT 1];
        
        SOM_Integration__c SOMIntegrationRec = new SOM_Integration__c();
        if(SOMIntegrationList.size() > 0) {
            SOMIntegrationRec = SOMIntegrationList[0];
        } else {
            insert SOMIntegrationRec;
        }
        return SOMIntegrationRec.Id;
    }
    
    private static void insertAttachment(List<Attachment> attachmentRecList, String fileType) {
        DMLUtility.insertSobjectList('Attachment', attachmentRecList);
    }
}