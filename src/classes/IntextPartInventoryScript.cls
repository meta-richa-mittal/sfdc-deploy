/** 
* Author: Richa Mittal
* Since: Dec 07, 2020 
* Name: IntextPartInventoryScript 
* Description: Apex class to run batch class based on intext part index.
**/
public without sharing class IntextPartInventoryScript {
    public static Integer Max_LIMIT = 40000;
   
    public static void run(Date fileDate) {
    	String exportType = 'INTEXT.CSV';
    	Integer fileNumber = 1;
 		Database.executeBatch(new GenericExportBatch(exportType, fileNumber, 1, fileDate), 500);
 		fileNumber += GenericExportBatch.getNumberOfAttchByIndex(1, exportType);
 		
 		Integer noOfAttchForIndex2 = GenericExportBatch.getNumberOfAttchByIndex(2, exportType);
 		if(noOfAttchForIndex2 != 0) {
 			Database.executeBatch(new GenericExportBatch(exportType, fileNumber, 2, fileDate), 500);
 			fileNumber += noOfAttchForIndex2;
 		}
 		
 		Integer noOfAttchForIndex3 = GenericExportBatch.getNumberOfAttchByIndex(3, exportType);
 		if(noOfAttchForIndex3 != 0) {
 			Database.executeBatch(new GenericExportBatch(exportType, fileNumber, 3, fileDate), 500);
 			fileNumber += noOfAttchForIndex3;
 		}
 		
 		Integer noOfAttchForIndex4 = GenericExportBatch.getNumberOfAttchByIndex(4, exportType);
 		if(noOfAttchForIndex4 != 0) {
	 		Database.executeBatch(new GenericExportBatch(exportType, fileNumber, 4, fileDate), 500);
	 		fileNumber += noOfAttchForIndex4;
 		}
 		
 		Integer noOfAttchForIndex5 = GenericExportBatch.getNumberOfAttchByIndex(5, exportType);
 		if(noOfAttchForIndex5 != 0) {
 			Database.executeBatch(new GenericExportBatch(exportType, fileNumber, 5, fileDate), 500);
 			//fileNumber += noOfAttchForIndex5;
 		}
 		
 		/*Integer noOfAttchForIndex6 = GenericExportBatch.getNumberOfAttchByIndex(6, exportType);
 		if(noOfAttchForIndex6 != 0) {
 			Database.executeBatch(new GenericExportBatch(exportType, fileNumber, 6, fileDate), 500);
 		}*/
    	
        /*
        System.scheduleBatch(new BRPPartInventoryBatch(fileDate, 2, fileNumber), jobName +'2', minutesFromNow, 500);
        fileNumber += BRPPartInventoryBatch.getNumberOfAttchByIndex(2, brpVendorsIdSet);
        System.scheduleBatch(new BRPPartInventoryBatch(fileDate, 3, fileNumber), jobName +'3', 2 * minutesFromNow, 500);
        fileNumber += BRPPartInventoryBatch.getNumberOfAttchByIndex(3, brpVendorsIdSet);
        System.scheduleBatch(new BRPPartInventoryBatch(fileDate, 4, fileNumber), jobName +'4', 3 * minutesFromNow, 500);
        fileNumber += BRPPartInventoryBatch.getNumberOfAttchByIndex(4, brpVendorsIdSet);
        System.scheduleBatch(new BRPPartInventoryBatch(fileDate, 5, fileNumber), jobName +'5', 4 * minutesFromNow, 500);
        */
    }
    
    /*public static Integer getNumberOfFilesPerIndex(Integer numberOfRecPerBatch) {
        Integer numberOfFilesPerIndex = numberOfRecPerBatch / Max_LIMIT;
        if(Math.mod(numberOfRecPerBatch, Max_LIMIT) != null && math.mod(numberOfRecPerBatch, Max_LIMIT) > 0) {
            numberOfFilesPerIndex += 1;
        }
        return numberOfFilesPerIndex;
    }*/       
}