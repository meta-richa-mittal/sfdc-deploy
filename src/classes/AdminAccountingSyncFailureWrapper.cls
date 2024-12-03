/**
 * Author: Richa Mittal
 * Since: March 29, 2024
 * Name: AdminAccountingSyncFailureWrapper
**/
public without sharing class AdminAccountingSyncFailureWrapper {

    public String ErrorLogsURL;
    public String WebServiceLogsURL;
    public List<SyncFailureWrapper> SyncFailureList;

    public AdminAccountingSyncFailureWrapper() {
        this.SyncFailureList = new List<SyncFailureWrapper>();
    }

    public class SyncFailureWrapper {
        public String EntityName;
        public String FailureCount;
        public String FailureListViewURL;
        public String ScriptToExecute;

        public SyncFailureWrapper(String entityName, String failureCount, String failureListViewURL, String scriptToExecute) {
            this.EntityName = entityName;
            this.FailureCount = failureCount;
            this.FailureListViewURL = failureListViewURL;
            this.ScriptToExecute = scriptToExecute;
            
        }
    }
}