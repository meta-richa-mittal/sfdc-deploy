/**
 * Author: Richa Mittal
 * Since: August 26, 2020
 * Name: GenericExportBatch
 * Description: Batch class to generate any export file
**/
global without sharing class GenericExportBatch implements Database.Batchable<sObject>, Database.Stateful, Schedulable, Database.AllowsCallouts {
    
    public String fileData;
    public String exportType;
    public Integer executeNumber = 0;
    public GE_File_Config__c fileConfigRec;
    private Integer batchNumber;
    public Integer partIndex;
    private DateTime dateTimeValue;
    private Boolean hasPartLineItemPresent = false;
    
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new GenericExportBatch(exportType));
    }
    
    global GenericExportBatch(String exportType) {
        this.exportType = exportType;
    }
    
    global GenericExportBatch(String exportType, Integer batchNumber, Integer partIndex, Date dateValue) {
        this.exportType = exportType;
        this.batchNumber = batchNumber;
        this.partIndex = partIndex;
        this.dateTimeValue = DateTime.newInstance(dateValue.year(), dateValue.month(), dateValue.day());
    }
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
    	try {
    		fileConfigRec = GenericExportUtil.getGenericFileConfig(exportType);
	        if(fileConfigRec == null) {throw new BlackPurlException('GE File Config is not defined'); }
	        
	        fileData = '';
	        String query = 'SELECT ';
	        
	        Set<String> fieldsToQuerySet = new Set<String>();
	        for(GE_File_Detail__c fileDetailRec: fileConfigRec.GE_File_Details__r) {
	            if(String.isBlank(fileDetailRec.Other_Object_API_Name__c) && String.isNotBlank(fileDetailRec.Field_API_Name__c)) {
	            	for(String referencedFieldAPIName: fileDetailRec.Field_API_Name__c.split('\\/')) {
    					if(String.isNotBlank(referencedFieldAPIName)) {
    						fieldsToQuerySet.add(referencedFieldAPIName);
    					}
	            	}
	            }
	        }
	        
	        query += String.join(new List<String>(fieldsToQuerySet), ',');
	        query += ' FROM ' + fileConfigRec.Object_API_Name__c;
	        
	        if(String.isNotBlank(fileConfigRec.Where_Clause__c)) {
	        	query += ' WHERE ' + fileConfigRec.Where_Clause__c;
	        }
	        
	        if(this.exportType == 'INTEXT.CSV') {
	        	query = getIntextFileWhereClause(query);
	        }
	        
	        if(String.isNotBlank(fileConfigRec.Order_By_Clause__c)) {
	        	query += ' ORDER BY ' + fileConfigRec.Order_By_Clause__c;
	        }
	        query += ' LIMIT ';
	        
	        if(this.exportType == 'INTEXT.CSV') {
	        	query += IntextPartInventoryScript.Max_LIMIT;
	        } else {
	        	query += SOQLUtil.getAvailableQueryRowsLimit();
	        }
	        
	        return Database.getQueryLocator(query);
    	} catch(Exception e) {
            new LogService().createErrorLog('GenericExportBatch', 'start()', e.getMessage(), 
                                                LogService.NOT_APPLICABLE, e.getStackTraceString(), exportType, (exportType == 'INTEXT.CSV' ? LogService.INTEXT : LogService.GENERIC_EXPORT), true);
        }
        return Database.getQueryLocator([Select Id FROM Account LIMIT 0]); // added just for the purpose of return Database.getQueryLocator for try catch handling
    }
    
    global void execute(Database.batchableContext bc, List<sObject> recordList) {
        try {
            executeNumber++;
            String imageQuery = GenericExportUtil.createQueryToFetchImages(fileConfigRec, recordList);
            Map<Id, sObject> recIdToImageRecordsMap = String.isNotBlank(imageQuery) ? new Map<Id, sObject>(Database.query(imageQuery)) : new Map<Id, sObject>();
            
            String currentIterationData = GenericExportService.createFileData(fileConfigRec, recordList, recIdToImageRecordsMap);
            if(this.exportType == 'INTEXT.CSV') {
            	GenericExportUtil.updatePartRecords(recordList, 0);
            	this.hasPartLineItemPresent = true;
            }
            fileData += currentIterationData;
            currentIterationData = null;
            System.debug('fileData---->'+fileData);
        } catch(Exception e) {
            new LogService().createErrorLog('GenericExportBatch', 'execute() number ' + executeNumber, e.getMessage(), 
                                                LogService.NOT_APPLICABLE, e.getStackTraceString(), exportType, (exportType == 'INTEXT.CSV' ? LogService.INTEXT : LogService.GENERIC_EXPORT), true);
        }
    }
    
    global void finish(Database.batchableContext bc) {
    	try {
    		if(fileConfigRec != null) {
    			if(this.exportType != 'INTEXT.CSV') {
    				processSingleAttachmentFile();
    			} else {
    				processMultiAttachmentFile();
    			}
    		}
    	} catch(Exception e) {
            new LogService().createErrorLog('GenericExportBatch', 'finish()', e.getMessage(), 
                                                LogService.NOT_APPLICABLE, e.getStackTraceString(), exportType, (exportType == 'INTEXT.CSV' ? LogService.INTEXT : LogService.GENERIC_EXPORT), true);
        }
    }
    
    private String getIntextFileWhereClause(String query) {
    	if(query.containsIgnoreCase('where')) {
    		query += ' AND';
    	} else {
    		query += ' WHERE';
    	}
    	query += ' Is_Included_In_Intext_Inventory__c = false AND Intext_Part_Index__c  = '+ this.partIndex;
    	return query;
    }
    
    private void processSingleAttachmentFile() {
    	String header = GenericExportService.getHeaders(fileConfigRec);
		header = String.isNotBlank(header) ? header + GenericExportUtil.newLineSeparator : '';
		String attId = GenericExportService.createAttachment((header + fileData), fileConfigRec);
        if(fileConfigRec.Send_to_FTP__c) {
        	System.enqueueJob(new FilePostToFTPQueueable(exportType, attId));
        }
    }
    
    private void processMultiAttachmentFile() {
    	if(String.isNotBlank(fileData)) {
    		String attId = GenericExportService.createAttachment(fileData, GenericExportUtil.fileNameToFilePrefixMap.get(this.exportType), fileConfigRec, this.batchNumber, this.dateTimeValue);
    	}
		if(this.hasPartLineItemPresent) {
            Database.executeBatch(new GenericExportBatch(this.exportType, (this.batchNumber + 1), this.partIndex, 
            						Date.newInstance(this.dateTimeValue.year(), this.dateTimeValue.month(), this.dateTimeValue.day())), 500);
        } else {
        	if(fileConfigRec.Send_to_FTP__c) {
        		List<Part__c> totalBatchPart = [SELECT Id FROM Part__c WHERE Publish_In_Feeds__c = true AND Intext_Part_Index__c =: partIndex LIMIT 1];
	            if(totalBatchPart.size() > 0) {
	                String attachmentName = GenericExportUtil.getAttachmentName(GenericExportUtil.fileNameToFilePrefixMap.get(this.exportType), this.dateTimeValue) + '%';
	                Map<String, Attachment> intextAttachedFileMap = new Map<String, Attachment>([SELECT Id FROM Attachment WHERE ParentId =: GenericExportService.getParentId() AND Name LIKE :attachmentName]);
	                if(intextAttachedFileMap.size() > 0) {
                    	String scheduledJobName = 'Post ' + exportType + ' To FTP Scheduler';
                        if(isFileGenerationComplete(intextAttachedFileMap.keySet().size(), this.dateTimeValue, this.exportType) && !isFilePostToFTPScheduled(scheduledJobName)) {
                            scheduleFilePostToFTP(scheduledJobName, String.join(new List<String>(intextAttachedFileMap.keySet()), ','));
	                        Date todaysDate = Date.newInstance(this.dateTimeValue.year(), this.dateTimeValue.month(), this.dateTimeValue.day());
	                        IntextPartInventoryScheduler.runNextJobAt5PM(todaysDate.addDays(1));
                            Database.executeBatch(new IntextDuplicatePartsEmailAlertBatch(this.exportType, this.fileConfigRec, todaysDate), 500);
	                    }
	                }
	            }
        	}
    	}
    }
    
    private static Boolean isFileGenerationComplete(Integer actualTotalAttachments, Datetime dateTimeValue, string exportType) {
    	
    	Integer expectedTotalAttachments = getExpectedNumberOfAttchments(exportType);
        
        if(actualTotalAttachments == expectedTotalAttachments) {
        	return true;
        } else if(actualTotalAttachments > expectedTotalAttachments) {
            new LogService().createErrorLog('GenericExportBatch', 'isFileGenerationComplete()', 'Intext Part Inventory File creation failed as more files created than expected', 400, null, null, (exportType == 'INTEXT.CSV' ? LogService.INTEXT : LogService.GENERIC_EXPORT), true);
    		Date todaysDate = Date.newInstance(dateTimeValue.year(), dateTimeValue.month(), dateTimeValue.day());
            IntextPartInventoryScheduler.runNextJobAt5PM(todaysDate.addDays(1));
        }
        return false;
    }
    
    private static Integer getExpectedNumberOfAttchments(String exportType) {
        return (getNumberOfAttchByIndex(1, exportType) + getNumberOfAttchByIndex(2, exportType) + getNumberOfAttchByIndex(3, exportType) + getNumberOfAttchByIndex(4, exportType) + getNumberOfAttchByIndex(5, exportType));
    }
    
    public static Integer getNumberOfAttchByIndex(Integer indexValue, String exportType) {
        Integer totalPartsWithSpecifiedIndex = 0;
		GE_File_Config__c fileConfigRec = GenericExportUtil.getGenericFileConfig(exportType);
		String query = 'Select Count(Id) totalParts from Part__c where Intext_Part_Index__c = ' + indexValue;
		if(String.isNotBlank(fileConfigRec.Where_Clause__c)) {
			query += ' AND ' + fileConfigRec.Where_Clause__c;
		} else {
			query += ' AND Publish_In_Feeds__c = true AND Is_Duplicate__c = false' ;
		}
        List<AggregateResult> aggList =  Database.query(query);
        if(aggList.size() > 0) {
            totalPartsWithSpecifiedIndex = (Integer) aggList[0].get('totalParts');
        }
          
        Integer totalAttchWithSpecifiedIndex = totalPartsWithSpecifiedIndex/IntextPartInventoryScript.Max_LIMIT;
        if(Math.mod(totalPartsWithSpecifiedIndex, IntextPartInventoryScript.Max_LIMIT) != null && math.mod(totalPartsWithSpecifiedIndex, IntextPartInventoryScript.Max_LIMIT) > 0) {
            totalAttchWithSpecifiedIndex += 1;
        }
        return totalAttchWithSpecifiedIndex;
    }
    
    private Boolean isFilePostToFTPScheduled(String scheduledJobName) {
    	List<CronTrigger> existingSheduledJobs = [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name = :scheduledJobName AND NextFireTime != null];
        return (existingSheduledJobs.size() > 0) ? true : false;
    }
    
    private void scheduleFilePostToFTP(String scheduledJobName, String attachmentIdsString) {
    	List<CronTrigger> existingSheduledJobs = [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name = :scheduledJobName];
        if(existingSheduledJobs.size() > 0) {
            system.abortJob(existingSheduledJobs[0].Id);
        }

        // schedule 5 mins after the current time
        DateTime currentDateTime = (system.now()).addMinutes(5);
        String strSchedule = String.valueOf(currentDateTime.second()) + ' ' + String.valueOf(currentDateTime.minute()) + ' ' + String.valueOf(currentDateTime.hour()) + 
                                ' ' + String.valueOf(currentDateTime.day()) + ' ' + String.valueOf(currentDateTime.month()) + ' ?' + ' ' + String.valueOf(currentDateTime.year());
        system.schedule(scheduledJobName, strSchedule, new FilePostToFTPScheduler(exportType, attachmentIdsString));
    }
}