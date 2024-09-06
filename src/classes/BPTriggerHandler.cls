public without sharing class BPTriggerHandler {

    public static Boolean isExecuteTrigger = true;
    public static final String BP_PROFILE_ID_KEY = 'Blackpurl Profile SFId';

    public static void onBeforeUpdate() {
        setLastModifiedByUserDetails();
    }

    private static void setLastModifiedByUserDetails() {
        for(sObject newRecord: Trigger.new) {
            sObject oldRecord = Trigger.isUpdate ? Trigger.oldMap.get(newRecord.Id) : null;
            if(!isExecuteTrigger) { // considering this will be false from script SetLastModifiedOnHistoricalDataBatch
                if(oldRecord != null) {
                    if(newRecord.get('Last_Modified_By__c') == null) {
                        newRecord.put('Last_Modified_By__c', oldRecord.get('LastModifiedById'));
                    }
                    if(newRecord.get('Last_Modified_Date__c') == null) {
                        newRecord.put('Last_Modified_Date__c', oldRecord.get('LastModifiedDate'));
                    }
                }
            } else if(isBlackpurlUser()) {
                if(oldRecord == null || (UserInfo.getUserId() != oldRecord.get('Last_Modified_By__c'))) {
                    newRecord.put('Last_Modified_By__c', UserInfo.getUserId());
                }
                newRecord.put('Last_Modified_Date__c', System.now());
            }
        }
    }

    // User with Blackpurl profile are Blackpurl users
    private static Boolean isBlackpurlUser() {
        String bpProfileId = getBlackpurlProfileId();
        return UserInfo.getProfileId() == bpProfileId;
    }

    public static String getBlackpurlProfileId() {
        String bpProfileId = GeneralConfiguration.getConfigurationByName(BPTriggerHandler.BP_PROFILE_ID_KEY);
        if(String.isBlank(bpProfileId)) {
            List<Profile> profileList = [SELECT Id FROM Profile WHERE Name = 'Blackpurl'];
            if(!profileList.isEmpty()) {
                bpProfileId = profileList[0].Id;
            }
            if(String.isBlank(bpProfileId)) {
                throw new BlackPurlException('Blackpurl profile does not exist.');
            }

            insert new Configuration_List__c(
                Name = BPTriggerHandler.BP_PROFILE_ID_KEY,
                Value__c = bpProfileId
            );
        }
        return bpProfileId;
    }
}