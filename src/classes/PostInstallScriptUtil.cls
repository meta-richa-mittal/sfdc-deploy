/** 
* Author: Richa Mittal
* Since: March 14, 2022
* Name: PostInstallScriptUtil 
* Description: Util class which contains post install script related variables and methods.
**/
public without sharing class PostInstallScriptUtil {

    public static final String SCRIPT_CLASS_NAME = 'BPScriptManager';
    public static final Integer PACKAGE_VERSION_MAX_NUMBER = 999;
    public static final Integer PACKAGE_VERSION_MIN_NUMBER = 0;

    public static boolean isUpgrade(Version previousVersion, Version newVersion) {
        return newVersion.compareTo(previousVersion) > 0;
    }
  
    public static boolean isChanged(Version previousVersion, Version newVersion) {
        return previousVersion.compareTo(newVersion) != 0;
    }

    public static Object getClassInstance(String className) {
        Type classType = Type.forName(className);
        if(classType == null) return null;
        return classType.newInstance();
    }

    public static Object executeScript(String methodName, String className) {
        Callable c = (Callable) PostInstallScriptUtil.getClassInstance(className);
        return c.call(methodName, new Map<String, Object>());
    }

    public static Post_Install_Log__c upsertLog(Post_Install_Log__c logRec, String scriptName, String error, String stackTrace, String status, String methodName, Boolean isUpsert) {
        if(logRec == null) {
            logRec = new Post_Install_Log__c();
        }
        logRec.Script_Name__c = scriptName;
        logRec.Error_Message__c = error; 
        logRec.Stack_Trace__c = stackTrace; 
        logRec.Status__c = status;
        logRec.Method_Name__c = methodName;
        if(isUpsert) upsert logRec;
        return logRec;
    }

    public static Post_Install_Log__c upsertLog(Post_Install_Log__c logRec, String scriptName, String error, String stackTrace, String status, String methodName, String scriptIncludedFor, String scriptRunFor, Boolean isUpsert) {
        logRec = upsertLog(logRec, scriptName, error, stackTrace, status, methodName, false);
        if(String.isNotBlank(scriptIncludedFor)) logRec.Script_Included_For_Package__c = scriptIncludedFor;
        if(String.isNotBlank(scriptRunFor))logRec.Script_Run_For_Package__c = scriptRunFor;
        if(isUpsert) upsert logRec;
        return logRec;
    }

    /* Used for creating instance of metadata required in test class as we can not create metadata using apex. */
    public static List<Post_Install_Script_Config__mdt> getScriptToExecuteListTest() {
        Post_Install_Script_Config__mdt config = new Post_Install_Script_Config__mdt();
        config.DeveloperName = 'Test Script';
        config.Label = 'Test Script';
        config.Scripts_To_Run__c = 'createCustomerDepositsSpecialCategory(), ';
        config.Script_Type__c = 'Synchronous';
        config.SF_Package_Version__c = '2.30';

        Post_Install_Script_Config__mdt configBatch = new Post_Install_Script_Config__mdt();
        configBatch.DeveloperName = 'Test Script Batch';
        configBatch.Label = 'Test Script Batch';
        configBatch.Scripts_To_Run__c = 'executePopulatePartTypeFieldOnPartV2Batch(), ';
        configBatch.Script_Type__c = 'Batch';
        configBatch.SF_Package_Version__c = '2.26';
        return new List<Post_Install_Script_Config__mdt>{config, configBatch};
    }
}