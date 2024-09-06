global without sharing class PopulateCassonsPartDetailsBatch implements Database.Batchable<sobject>, Database.AllowsCallouts, Schedulable{
    public Set<String> cassonsVendorsIdSet;
    public Map<String, CassonsHerokuService.CassonsPartWrapper> cassonsPartNumberToPartRecMap;
    public Integer startIndex;
    List<CassonsHerokuService.CassonsPartWrapper> cassonsPartList;


    global PopulateCassonsPartDetailsBatch(Integer startIndex, List<CassonsHerokuService.CassonsPartWrapper> cassonsPartList, Boolean isBatch){
        this.startIndex = startIndex;
        this.cassonsPartList = cassonsPartList;
        if(isBatch){
            this.cassonsPartNumberToPartRecMap = new Map<String, CassonsHerokuService.CassonsPartWrapper>();
            if(cassonsPartList != null) {
                for(CassonsHerokuService.CassonsPartWrapper partRec : cassonsPartList) {
                    if(String.isNotBlank(partRec.PartNo)) {
                        this.cassonsPartNumberToPartRecMap.put(((partRec.PartNo).trim()).toLowercase(), partRec);
                    }
                }
            }
            this.cassonsVendorsIdSet = CassonsUtility.getAllCassonsVendorsIdSet();
        }
    }
    global Database.QueryLocator start(Database.BatchableContext bc) {
        Set<String> partNumberSet = cassonsPartNumberToPartRecMap.keySet();
        String strQuery = 'SELECT Part_Number__c, Cassons_Description__c, Cassons_SOH__c, Cassons_ID__c FROM Part__c WHERE Vendor__c IN :cassonsVendorsIdSet AND Part_Number__c IN : partNumberSet ORDER BY Name ASC';
        return Database.getQueryLocator(strQuery); 
    }
      
    global void execute(Database.batchableContext bc, List<Part__c> partList) {
        System.debug('this.cassonsPartNumberToPartRecMap  ' + this.cassonsPartNumberToPartRecMap);

        String soh;
        for(Part__c partRec : partList){
            if(this.cassonsPartNumberToPartRecMap.containsKey((partRec.Part_Number__c).toLowercase())) {
                partRec.Cassons_Description__c = (this.cassonsPartNumberToPartRecMap.get((partRec.Part_Number__c).toLowercase())).Description;
                partRec.Cassons_ID__c = (this.cassonsPartNumberToPartRecMap.get((partRec.Part_Number__c).toLowercase())).PartNo;
                soh = (this.cassonsPartNumberToPartRecMap.get((partRec.Part_Number__c).toLowercase())).SOH;
                partRec.Cassons_SOH__c = Decimal.valueOf(String.IsNotBlank(soh) ? soh: '0');
            }
        }
        PartTriggerHelper.isForceStopTrigger = true;
        update partList;
        PartTriggerHelper.isForceStopTrigger = false;

    }
      
    global void finish(Database.batchableContext bc) {
        Integer partsPerRequest = CassonsUtility.getPartsPerRequest();
        if(this.cassonsPartList.size() >= partsPerRequest) {
            BPUtility.abortAlreadyScheduleJobs('Fetch Cassons Part Details');
            String cronExp = BPUtility.getCronExpForGivenTime(10);
            system.schedule('Fetch Cassons Part Details', cronExp, new FetchCassonsPartsScheduler(this.startIndex + partsPerRequest));
        } 
    }

    global void execute(SchedulableContext sc) {
        PopulateCassonsPartDetailsBatch b = new PopulateCassonsPartDetailsBatch(this.startIndex, this.cassonsPartList, true); 
        database.executebatch(b);
    }
}