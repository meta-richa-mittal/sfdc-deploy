/**
 * Author: Richa Mittal
 * Name: SetLastModifiedOnHistoricalDataBatch1
**/
global without sharing class SetLastModifiedOnHistoricalDataBatch1 implements Database.Batchable<String>, Database.Stateful {

    private static final Integer DML_LIMIT_COUNT = 10000;

    public List<String> objectToProcessList;
    public Set<String> objectWithErrorSet;
    private Post_Install_Log__c errorLog;
    global SetLastModifiedOnHistoricalDataBatch1() {
        objectToProcessList = new List<String>();
        objectWithErrorSet = new Set<String>();
    }
    
    global Iterable<String> start(Database.BatchableContext bc) {
        Set<String> objectNameSet = getAllCustomObjects();
        objectNameSet.addAll(new Set<String>{'Account', 'Contact'});
        for(String objName: objNamesToExcludeList) {
            if(objectNameSet.contains(Constants.NAMESPACE + objName)) {
                objectNameSet.remove(Constants.NAMESPACE + objName);
            }
        }
        try {
            String errorString = String.join(objectToProcessList, ',');
            errorString = (errorString.length() > 5000) ? errorString.subString(0, 5000) : errorString;
            errorLog = PostInstallScriptUtil.upsertLog(null, 'SetLastModifiedOnHistoricalDataBatch1', LogService.NOT_APPLICABLE, errorString, 'Pending', LogService.NOT_APPLICABLE, true);
        } catch(Exception e) {
            // added to catch error in case of log insertion failure
        }
        return objectNameSet;
    }
    
    global void execute(Database.BatchableContext bc, List<String> objectsList) {
        if(!objectsList.isEmpty()) { // batch will be executed with 1
            try {
                List<SObject> sObjList = Database.query('SELECT Id FROM ' + objectsList[0] + ' WHERE Last_Modified_By__c = null OR Last_Modified_Date__c = null LIMIT ' + DML_LIMIT_COUNT);
                if(sObjList.size() == DML_LIMIT_COUNT) {
                    objectToProcessList.add(objectsList[0]);
                } else {
                    BPTriggerHandler.isExecuteTrigger = false;
                    DMLUtility.updateSobjectList(objectsList[0], sObjList, false);
                    BPTriggerHandler.isExecuteTrigger = true;
                }
            } catch(Exception e) {
                objectWithErrorSet.add(objectsList[0] + ' - ' + e.getMessage());
            }
        }
    }
    
    global void finish(Database.BatchableContext bc) {
        try {
            if(!objectWithErrorSet.isEmpty()) {
                String errorString = 'Error in processing following objects: ' + String.join(objectWithErrorSet, ',');
                errorString = (errorString.length() > 5000) ? errorString.subString(0, 5000) : errorString;
                if(errorLog == null) {
                    errorLog = PostInstallScriptUtil.upsertLog(null, 'SetLastModifiedOnHistoricalDataBatch1', LogService.NOT_APPLICABLE, errorString, 'Errored', 'finish()', false);
                } else {
                    errorLog.Status__c = 'Errored';
                    errorLog.Stack_Trace__c = errorString;
                }
            } else if(errorLog != null) {
                errorLog.Status__c = 'Completed';
            }
            executeBatch2ForLargeData(objectToProcessList);
        } catch(Exception e) {
            String errorString = String.join(objectToProcessList, ',') + ' - ' + e.getMessage();
            errorString = (errorString.length() > 5000) ? errorString.subString(0, 5000) : errorString;
            if(errorLog == null) {
                errorLog = PostInstallScriptUtil.upsertLog(null, 'SetLastModifiedOnHistoricalDataBatch1', LogService.NOT_APPLICABLE, errorString, 'Errored', 'finish()', false);
            } else {
                errorLog.Status__c = 'Errored';
                errorLog.Stack_Trace__c = errorString;
            }
        }
        DMLUtility.upsertSobjectList('Post_Install_Log__c', errorLog);
    }

    private static Set<String> objNamesToExcludeList = new Set<String>{
        'Accounting_Data_Migration__c', 'App_Log__c', 'Applicable_Taxes__c', 'AutoNumberHolder__c', 'Coli_Fifo_Line_Item_Junction__c', 'Customer_Page_Size__c', 
        'CustomerApproval__c', 'File_Storage__c', 'GL_Account__c', 'Integration__c', 'Logged_In_Device__c', 'Message_Read_By__c', 'Notes__c', 'Part_Tax__c', 
        'People__c', 'Provider__c', 'QB_Tax_Rate__c', 'QB_TaxCode__c', 'Recent_Customer__c', 'Recent_Part__c', 'Recent_Vendor__c', 'Reporting__c', 
        'Service_Job_To_Customer_Approval__c', 'Stock_Count__c', 'Summary_Log__c', 'Suppress_CO_Item__c', 'Timezone__c', 'Widget__c', 'Widget_User_Junction__c', 
        'Return_CR_Header__c', 'Return_CR_Line_Item__c', 'SOM_Integration__c', 'Vendor_Receiving_Line_Item__c', 'VO_Locked_Line_Item__c', 'Option_Fee_Kit_header__c', 
        'Accounting_Default_Accounts__c', 'Accounting_Settings__c', 'Australian_Market__c', 'BP_Configurations__c', 'BRP_Settings__c', 'BRP_Vendors_List__c', 
        'CASSONS_Configuration__c', 'CASSONS_Vendor_List__c', 'Configuration_List__c', 'Configurations__c', 'DP360_Configuration__c', 
        'Email_Configuration__c', 'FTP_Config__c', 'General_Configurations__c', 'HDnet_Australia_Config__c', 'Honda_Configuration__c', 
        'QuickBooks_Configurations__c', 'LMA_Config__c', 'Part_Aging_Period__c', 'Partsmart_To_BP_Vendor_Code_Mapping__c', 'Payment_Method__c', 'Reporting__c', 
        'SearchConfigurations__c', 'Service_Job_Status__c', 'SFTP_Server__c', 'Shop_Settings__c', 'Shop_Supplies__c', 'Shopify_Configuration__c', 'SMS_Configuration__c', 
        'SOM_Configuration__c', 'TestClassesNames__c', 'Trigger_Soft_Disable__c', 'Unit_Data_Field_Config__c', 'Vendor_Availability_Mapping__c', 'Yamaha_Australia_Config__c'
    };

    private static Set<String> getAllCustomObjects() {
        // Get a map of all objects in the org.
        Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();

        // Initialize a Set to hold the names of custom objects.
        Set<String> customObjects = new Set<String>();

        // Iterate over the map.
        for (String objectName : globalDescribe.keySet()) {
            // If the object name ends with '__c', it's a custom object.
            if(objectName.endsWith('__c')) {
                customObjects.add(String.valueOf(globalDescribe.get(objectName)));
            }
        }
        return customObjects;
    }

    public static void executeBatch2ForLargeData(List<String> objectToProcessList) {
        List<List<String>> objectList = new List<List<String>>(); // This list will contain 5 items
        Integer Max_Size = 5;
        for(Integer i=0; i<Max_Size; i++) {
            objectList.add(new List<String>());
        }

        if(!objectToProcessList.isEmpty()) {
            Integer q = objectToProcessList.size()/Max_Size;
            Integer r = Math.mod(objectToProcessList.size(), Max_Size);
            
            Integer counter = 0;
            for(Integer i=0; i<objectToProcessList.size(); i++) {
                if(q > 0) {
                    for(Integer j=0; j<Max_Size; j++) {
                        objectList[j].add(objectToProcessList[i]);
                    }
                    q--;
                    counter++;
                } 
                if(q == 0) break;
            }

            for(Integer i=counter; i<objectToProcessList.size(); i++) {
                if(r != 0) {
                    objectList[r-1].add(objectToProcessList[i]);
                    r--;
                }
            }
        }
        for(Integer i=0; i<objectList.size(); i++) {
            if(objectList[i] != null && !objectList[i].isEmpty()) {
                Database.executeBatch(new SetLastModifiedOnHistoricalDataBatch2(objectList[i]), 2000);
            }
        }
    }
}