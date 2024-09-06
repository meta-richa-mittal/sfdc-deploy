/**
 * Author: Balveer Choudhary
 * Since: Nov 22, 2023
 * Name: SOMJobScheduler
 * Description: Scheduler class for SOM file posting
**/
global without sharing class SOMJobScheduler implements Schedulable {

    public static final String PART_INVENTORY = 'INV';
    public static final String PART_SALES = 'PSI';
    public static final String PARTS_ON_ORDER = 'POO';
    private Boolean onlySendAllDataInPsiFile;

    global SOMJobScheduler() {
        this.onlySendAllDataInPsiFile = false;
    }

    global SOMJobScheduler(Boolean onlySendAllDataInPsiFile) {
        this.onlySendAllDataInPsiFile = onlySendAllDataInPsiFile;
    }

    global void execute(SchedulableContext sc) {   
        doFilePost(this.onlySendAllDataInPsiFile);
    }
    
    @future (callout=true)
    public static void doFilePost(Boolean onlySendAllDataInPsiFile) {
        try {
            Datetime dateTimeValue = DateTime.now();
            SOM_Configuration__c somConfig = getSOMConfig();
            String orgCode = somConfig.Org_Code__c;
            String filePath = somConfig.Upload_Directory__c; 
            SOMService.doFilePost(getFileNameByFileType(PART_INVENTORY, dateTimeValue, orgCode), 
                                    getFileNameByFileType(PART_SALES, dateTimeValue, orgCode), 
                                    getFileNameByFileType(PARTS_ON_ORDER, dateTimeValue, orgCode),
                                    onlySendAllDataInPsiFile,
                                    orgCode,
                                    filePath, 
                                    onlySendAllDataInPsiFile);
        } catch(Exception e) {
            new LogService().createErrorLog('SOMJobScheduler', 'doFilePost()', e.getMessage(), null, e.getStackTraceString(), null, LogService.SOM, true, 'Error');
        }
    }

    private static String getFileNameByFileType(String fileType, Datetime dateTimeValue, String orgCode) {
        String fileName = fileType + '_';
        fileName += orgCode + '_';
        fileName += (dateTimeValue != null ? dateTimeValue.format('yyyyMMdd') : Datetime.now().format('yyyyMMdd'));
        return fileName;
    }

    private static SOM_Configuration__c getSOMConfig() {
        return SOM_Configuration__c.getOrgDefaults();
    }
}