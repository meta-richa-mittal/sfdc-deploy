/**
 * Author: Tarun Khandelwal
 * Since: May 23, 2024
 * Name: BRPDealerPartsInventoryBatchScheduler
 * Description: Scheduler class for send BRP parts from Blackpurl to BRP system
 *              This class is using version v4 of BRP APIs
**/
global without sharing class BRPDealerPartsInventoryBatchScheduler implements Database.Batchable<sobject>, Database.AllowsCallouts, Database.Stateful, Schedulable {

    global BRPDealerPartsInventoryBatchScheduler() {}

    global Database.QueryLocator start(Database.BatchableContext bc) {
        Set<String> brpVendorsIdSet = BRPUtility.getAllBRPVendorsIdSet();
        String query = 'SELECT Id, Name, Part_Number__c, Qty_In_Stock__c, Auto_reorder_Min__c, AvailableParts__c, Auto_reorder_Max__c, Last_Counted__c FROM Part__c WHERE Vendor__c IN: brpVendorsIdSet ' +
                            ' AND (LastModifiedDate = LAST_N_Days:365 OR (LastModifiedDate < LAST_N_Days:365 AND Qty_In_Stock__c > 0)) Order By Vendor__c, Name ASC';
        return Database.getQueryLocator(query);
    }

    global void execute(Database.batchableContext bc, List<Part__c> partList) {
        List<PartWrapper> partObjList = new List<PartWrapper>();
        for(Part__c partRec : partList) {
            partObjList.add(new PartWrapper(partRec));
        }
        sendDealerInventoryToBRP(partObjList);
    }

    public void sendDealerInventoryToBRP(List<PartWrapper> partObjList) {
        String requestBodyJson = JSON.serialize(new DealerInventoryWrapper(partObjList), true);
        HttpResponse response = BRPUtility.syncToBRP('Dealer Inventory', requestBodyJson);
        if(response.getStatusCode() != 200) {
            BRPUtility.insertBRPLog('Dealer Parts Inventory', requestBodyJson, response, 'BRPDealerPartsInventoryBatchScheduler');
        }
    }

    global void finish(Database.batchableContext bc) {
    }

    global static void runAt11PM() {
        String jobName = 'BRP Part Inventory Scheduler v4';
        List<CronTrigger> existingSheduledJobs = [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name =: jobName];
        if(existingSheduledJobs.size() > 0) {
            system.abortJob(existingSheduledJobs[0].Id);
        }
        system.schedule(jobName, BRPUtility.getCronExpression(), new BRPDealerPartsInventoryBatchScheduler());
    }

    global void execute(SchedulableContext sc) {
    	Database.executeBatch(new BRPDealerPartsInventoryBatchScheduler(), 2000);
	}

    public class DealerInventoryWrapper {
        private String dealer_no;
        private Datetime inventory_date;
        private List<PartWrapper> parts_inventory;

        public DealerInventoryWrapper(List<PartWrapper> partObjList) {
            this.dealer_no = BRPUtility.getFormattedDealerId();
            this.inventory_date = System.Today();
            this.parts_inventory = partObjList;
        }
    }

    public class PartWrapper {
        private String product_code;
        private Integer qty_on_hand;
        private Integer qty_dealer_stocking;
        private Integer qty_available;
        private Integer qty_min_stocking_level;
        private Integer qty_max_stocking_level;
        private Integer qty_best_stocking_level;
        private Date last_physical_inventory_date;

        public PartWrapper(Part__c partRec) {
            this.product_code = String.valueOf(partRec.Part_Number__c).length() <= 18 ? String.valueOf(partRec.Part_Number__c) : String.valueOf(partRec.Part_Number__c).substring(0, 18);
            this.qty_on_hand = (partRec.Qty_In_Stock__c != null ? Integer.valueOf(partRec.Qty_In_Stock__c) : 0);
            this.qty_available = partRec.AvailableParts__c != null ? Integer.valueOf(partRec.AvailableParts__c) : 0;
            this.qty_min_stocking_level = partRec.Auto_reorder_Min__c != null ? Integer.valueOf(partRec.Auto_reorder_Min__c) : 0;
            this.qty_max_stocking_level = partRec.Auto_reorder_Max__c != null ? Integer.valueOf(partRec.Auto_reorder_Max__c) : 0;
            this.qty_best_stocking_level = this.qty_max_stocking_level;
            if(partRec.Last_Counted__c != null) {
                this.last_physical_inventory_date = Date.newInstance(partRec.Last_Counted__c.year(), partRec.Last_Counted__c.month(), partRec.Last_Counted__c.day());
            }
        }
    }
}