/**
 * Author: Richa Mittal
 * Since: March 09, 2022
 * Name: PostInstallService
 * Description: Service class for running post install scripts
**/
public without sharing class PostInstallService {

    private static PostInstallService instance;
    private Version currentVersion;
    private Version previousVersion;
    private Map<String, Post_Install_Log__c> scriptNameToLogRecMap = new Map<String, Post_Install_Log__c>();

    private PostInstallService() {}

    public static PostInstallService getInstance(InstallContext context) {
        if(instance == null) {
            instance = new PostInstallService();
            instance.currentVersion = System.requestVersion();
            instance.previousVersion = context.previousVersion();
        }
        return instance;
    }

    // Added for test class and dev testing
    public static PostInstallService getInstance() {
        if(instance == null) {
            instance = new PostInstallService();
            instance.currentVersion = new Version(2, 30);
            instance.previousVersion = new Version(2, 25);
        }
        return instance;
    }
    

    /**
     * this is start method which will be called from post install script
     */
    public void startService() {
        if (!PostInstallScriptUtil.isChanged(previousVersion, currentVersion)) {
            return; // Same Version - somehow....
        } else if (!PostInstallScriptUtil.isUpgrade(previousVersion, currentVersion)) {
            return; // Currently in BP we only upgrade package
        }

        Set<String> versionNumberSet = getVersionNumberSet();

        List<Post_Install_Script_Config__mdt> configList = [SELECT Scripts_To_Run__c, Script_Type__c, SF_Package_Version__c FROM Post_Install_Script_Config__mdt 
                                                            WHERE SF_Package_Version__c IN :versionNumberSet];
        if(configList.size() == 0 && !Test.isRunningTest()) return;
        if(Test.isRunningTest()) configList = PostInstallScriptUtil.getScriptToExecuteListTest();

        List<Post_Install_Log__c> logListToUpdate = new List<Post_Install_Log__c>();
        Map<String, String> scriptNameToTypeMap = new Map<String, String>();
        for(Post_Install_Script_Config__mdt configRec: configList) {
            if(String.isNotBlank(configRec.Scripts_To_Run__c) && versionNumberSet.contains(configRec.SF_Package_Version__c)) {
                List<String> scriptList = configRec.Scripts_To_Run__c.split(',');
                for(String scriptName: scriptList) {
                    scriptName = scriptName.trim();
                    if(String.isNotBlank(scriptName)) {
                        scriptNameToLogRecMap.put(scriptName, PostInstallScriptUtil.upsertLog(null, scriptName, null, null, 'Pending', null, 
                                configRec.SF_Package_Version__c, (currentVersion.major() + '.' + currentVersion.minor()), false));
                        scriptNameToTypeMap.put(scriptName, configRec.Script_Type__c);
                    }
                }
            }
        }

        if(scriptNameToLogRecMap.size() > 0) DMLUtility.insertSobjectList('Post_Install_Log__c', scriptNameToLogRecMap.values());
        executeScript(scriptNameToTypeMap, logListToUpdate);
        finishService(logListToUpdate);
    }

    private Set<String> getVersionNumberSet() {
        Set<String> versionNumberSet = new Set<String>();
        Integer majorVersion = previousVersion.major();
        Integer minorVersion = previousVersion.minor() + 1;
        while(currentVersion.major() >= majorVersion) {
            if(currentVersion.major() == majorVersion) {
                while(currentVersion.minor() >= minorVersion) {
                    versionNumberSet.add(majorVersion + '.' + minorVersion);
                    minorVersion++;
                }
            } else if(currentVersion.major() > majorVersion) {
                while(PostInstallScriptUtil.PACKAGE_VERSION_MAX_NUMBER >= minorVersion) {
                    versionNumberSet.add(majorVersion + '.' + minorVersion);
                    minorVersion++;
                }
                minorVersion = PostInstallScriptUtil.PACKAGE_VERSION_MIN_NUMBER;
            }
            majorVersion++;
        }
        return versionNumberSet;
    }

    private void executeScript(Map<String, String> scriptNameToTypeMap, List<Post_Install_Log__c> logListToUpdate) {
        for(String scriptName: scriptNameToTypeMap.keySet()) {
            try {
                Object obj = PostInstallScriptUtil.executeScript(scriptName, PostInstallScriptUtil.SCRIPT_CLASS_NAME);
                if(scriptNameToTypeMap.get(scriptName) != 'Batch') {
                    logListToUpdate.add(PostInstallScriptUtil.upsertLog(scriptNameToLogRecMap.get(scriptName), scriptName, null, null, 'Completed', null, false));
                }
            } catch(Exception e) {
                logListToUpdate.add(PostInstallScriptUtil.upsertLog(scriptNameToLogRecMap.get(scriptName), scriptName, e.getMessage(), e.getStackTraceString(), 'Errored', null, false));
            }
        }
    }

    /**
     * this method will be called after all the sync scripts are executed
     */
    private void finishService(List<Post_Install_Log__c> logListToUpdate) {
        DMLUtility.updateSobjectList('Post_Install_Log__c', logListToUpdate);
    }
}