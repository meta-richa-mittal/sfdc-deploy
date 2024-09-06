/** 
* Author: Tarun Khandelwal
* Since: Nov 27, 2019 
* Name: BRPGetDealersBatch 
* Description: Batch Apex class to get all BRP Dealers using Pagination
**/
global without sharing class BRPGetDealersBatch implements Database.Batchable<String>, Database.Stateful, Database.AllowsCallouts {
    
    private Integer pageNumber;
    private Integer numberOfDealersReturned;
    
    global BRPGetDealersBatch() {
        this.pageNumber = 1;
        this.numberOfDealersReturned = 0;
    }
    
    global BRPGetDealersBatch(Integer pageNumber, Integer numberOfDealersReturned) {
        this.pageNumber = (pageNumber != null) ? pageNumber : 1;
        this.numberOfDealersReturned = (numberOfDealersReturned != null) ? numberOfDealersReturned : 0;
    }
     
    global Iterable<String> start(Database.BatchableContext bc) {
        return new List<String>{'1'};
    }
    
    global void execute(Database.batchableContext bc, List<String> iterableList) {
        numberOfDealersReturned = BRPDealerIntegration.getDealers(pageNumber);
    }
    
    global void finish(Database.batchableContext bc) {
        if(numberOfDealersReturned > 0) {
            pageNumber++;
            Database.executeBatch(new BRPGetDealersBatch(pageNumber, numberOfDealersReturned));
        }
    }
}