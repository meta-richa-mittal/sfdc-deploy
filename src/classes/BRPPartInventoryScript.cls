/** 
* Author: Manoj Sharma
* Since: June 20, 2020 
* Name: BRPPartInventoryScript 
* Description: Apex class to run batch class based on part index.
**/
public without sharing class BRPPartInventoryScript {
    public static Integer Max_LIMIT = 5000;
   
    public static void run(Date fileDate) {
    	Set<String> brpVendorsIdSet = BRPUtility.getAllBRPVendorsIdSet();
        Integer fileNumber = 1;
        //Integer minutesFromNow = 1;
        //String jobName = 'Part Inventory Batch Index ';
        Database.executeBatch(new BRPPartInventoryBatch(fileDate, 1, fileNumber), 500);
        fileNumber += BRPPartInventoryBatch.getNumberOfAttchByIndex(1, brpVendorsIdSet);
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
    
    public static Integer getNumberOfFilesPerIndex(Integer numberOfRecPerBatch) {
        Integer numberOfFilesPerIndex = numberOfRecPerBatch / Max_LIMIT;
        if(Math.mod(numberOfRecPerBatch, Max_LIMIT) != null && math.mod(numberOfRecPerBatch, Max_LIMIT) > 0) {
            numberOfFilesPerIndex += 1;
        }
        return numberOfFilesPerIndex;
    }        
}