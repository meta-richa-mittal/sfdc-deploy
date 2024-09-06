public without sharing class SOMPartInventoryBatchManager {
    
    public static Integer Max_LIMIT = 40000;
    
    public static void run(Date fileDate) {
        
        Integer fileNumber = 1;
        Database.executeBatch(new SOMPartInventoryBatch(fileNumber, 1, fileDate), 500);
        fileNumber += SOMPartInventoryBatch.getNumberOfAttchByIndex(1);
        
        Integer noOfAttchForIndex2 = SOMPartInventoryBatch.getNumberOfAttchByIndex(2);
        if(noOfAttchForIndex2 != 0) {
            Database.executeBatch(new SOMPartInventoryBatch(fileNumber, 2, fileDate), 500);
            fileNumber += noOfAttchForIndex2;
        }
        
        Integer noOfAttchForIndex3 = SOMPartInventoryBatch.getNumberOfAttchByIndex(3);
        if(noOfAttchForIndex3 != 0) {
            Database.executeBatch(new SOMPartInventoryBatch(fileNumber, 3, fileDate), 500);
            fileNumber += noOfAttchForIndex3;
        }
        
        Integer noOfAttchForIndex4 = SOMPartInventoryBatch.getNumberOfAttchByIndex(4);
        if(noOfAttchForIndex4 != 0) {
            Database.executeBatch(new SOMPartInventoryBatch(fileNumber, 4, fileDate), 500);
            fileNumber += noOfAttchForIndex4;
        }
        
        Integer noOfAttchForIndex5 = SOMPartInventoryBatch.getNumberOfAttchByIndex(5);
        if(noOfAttchForIndex5 != 0) {
            Database.executeBatch(new SOMPartInventoryBatch(fileNumber, 5, fileDate), 500);
        }
    }
    
    public static Integer getNumberOfFilesPerIndex(Integer numberOfRecPerBatch) {
        Integer numberOfFilesPerIndex = numberOfRecPerBatch / Max_LIMIT;
        if(Math.mod(numberOfRecPerBatch, Max_LIMIT) != null && math.mod(numberOfRecPerBatch, Max_LIMIT) > 0) {
            numberOfFilesPerIndex += 1;
        }
        return numberOfFilesPerIndex;
    }
}