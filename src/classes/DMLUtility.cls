/** 
* Author: Nidhi Sharma
* Since: June 11, 2021 
* Name: DMLUtility 
* Description: Apex class which contains dml operations and FLS check.
**/
public without sharing class DMLUtility {
    
    public static final String NOT_ACCESSIBLE = ' is not accessible.';
    public static final String NOT_CREATABLE = ' is not creatable.';
    public static final String NOT_UPDATABLE = ' is not updatable.';
    public static final String NOT_DELETABLE = ' is not deletable.';
	public static final Integer UPDATE_RECORD_MAX_RETRY = 4; //Max number of retry in case of unable to lock row
    
    //Insert
    public static List<SObject> insertSobjectList(String objectAPIName, SObject sobjectInsertRec) {
    	return insertSobjectList(objectAPIName, new List<SObject>{sobjectInsertRec}, true);
	}
	
	public static List<SObject> insertSobjectList(String objectAPIName, List<SObject> sobjectInsertList) {
		return insertSobjectList(objectAPIName, sobjectInsertList, true);
	}
	
	public static List<SObject> insertSobjectList(String objectAPIName, List<SObject> sobjectInsertList, Boolean allOrNone) {
		objectAPIName = objectAPIName.trim();
		if(sobjectInsertList.size() > 0) {
            if(!AccessControl.ifObjectFieldIsCreateable(objectAPIName)){throw new BlackPurlException(objectAPIName + NOT_CREATABLE);}
    		Database.insert(sobjectInsertList, allOrNone);
		}
		return sobjectInsertList;
	}

	public static List<Database.SaveResult> insertSobjectListAndGetResult(String objectAPIName, List<SObject> sobjectInsertList, Boolean allOrNone) {
		objectAPIName = objectAPIName.trim();
		if(sobjectInsertList.size() > 0) {
            if(!AccessControl.ifObjectFieldIsCreateable(objectAPIName)){throw new BlackPurlException(objectAPIName + NOT_CREATABLE);}
			return Database.insert(sobjectInsertList, allOrNone);
		}
		return new List<Database.SaveResult>();
	}
	
	//Update
	public static List<SObject> updateSobjectList(String objectAPIName, SObject sobjectUpdateRec) {
    	return updateSobjectList(objectAPIName, new List<SObject>{sobjectUpdateRec}, true);
	}
	
	public static List<SObject> updateSobjectList(String objectAPIName, List<SObject> sobjectUpdateList) {
		return updateSobjectList(objectAPIName, sobjectUpdateList, true);
	}
	
	public static List<SObject> updateSobjectList(String objectAPIName, List<SObject> sobjectUpdateList, Boolean allOrNone) {
    	objectAPIName = objectAPIName.trim();
		if(sobjectUpdateList.size() > 0) {
            if(!AccessControl.ifObjectFieldIsUpdateable(objectAPIName)){throw new BlackPurlException(objectAPIName + NOT_UPDATABLE); }
        	Database.update(sobjectUpdateList, allOrNone);
		}
		return sobjectUpdateList;
	}

	public static void updateSobjectListWithRetry(List<SObject> sobjectUpdateList) {
		if(sobjectUpdateList != null && sobjectUpdateList.size() > 0) {
			String objectAPIName = String.valueOf(sObjectUpdateList[0].getSObjectType());
            if(!AccessControl.ifObjectFieldIsUpdateable(objectAPIName)){throw new BlackPurlException(objectAPIName + NOT_UPDATABLE); }
        	updateWithRetry(sobjectUpdateList, 0);
		}
	}

	private static void updateWithRetry(List<SObject> sobjectUpdateList, Integer retryCount) {
    	try {
            Database.update(sobjectUpdateList, true);
        } catch (Exception e) {
            if(e.getMessage().contains('UNABLE_TO_LOCK_ROW') && retryCount < UPDATE_RECORD_MAX_RETRY) {
                BPUtility.setTimeout(2);
                updateWithRetry(sobjectUpdateList, ++retryCount);
            } else {
                throw new BlackPurlException(e);
            }
        }
	}
	
	//Upsert
	public static List<SObject> upsertSobjectList(String objectAPIName, SObject sobjectUpsertRec) {
    	return upsertSobjectList(objectAPIName, new List<SObject>{sobjectUpsertRec}, true);
	}
	
	public static List<SObject> upsertSobjectList(String objectAPIName, List<SObject> sobjectUpsertList) {
		return upsertSobjectList(objectAPIName, sobjectUpsertList, true);
	}
	
	public static List<SObject> upsertSobjectList(String objectAPIName, List<SObject> sobjectUpsertList, Boolean allOrNone) {
    	objectAPIName = objectAPIName.trim();
		if(sobjectUpsertList.size() > 0) {
            if(!AccessControl.ifObjectFieldIsCreateable(objectAPIName)) { throw new BlackPurlException(objectAPIName + NOT_CREATABLE); }
            if(!AccessControl.ifObjectFieldIsUpdateable(objectAPIName)) { throw new BlackPurlException(objectAPIName + NOT_UPDATABLE); }
        	Database.upsert(sobjectUpsertList, allOrNone);
		}
		return sobjectUpsertList;
	}
	
    public static List<Database.UpsertResult> upsertSobjectListAndGetResult(String objectAPIName, List<SObject> sobjectUpsertList, Boolean allOrNone) {
        objectAPIName = objectAPIName.trim();
		if(sobjectUpsertList.size() > 0) {
            if(!AccessControl.ifObjectFieldIsCreateable(objectAPIName)) { throw new BlackPurlException(objectAPIName + NOT_CREATABLE); }
            if(!AccessControl.ifObjectFieldIsUpdateable(objectAPIName)) { throw new BlackPurlException(objectAPIName + NOT_UPDATABLE); }
            return Database.upsert(sobjectUpsertList, allOrNone);
        }
        return new List<Database.UpsertResult>();
    }
    
	//Delete
	public static void deleteSobjectList(String objectAPIName, SObject sobjectDeleteRec) {
    	deleteSobjectList(objectAPIName, new List<SObject>{sobjectDeleteRec}, true);
	}
	
	public static void deleteSobjectList(String objectAPIName, List<SObject> sobjectDeleteList) {
		deleteSobjectList(objectAPIName, sobjectDeleteList, true);
	}
	
	public static void deleteSobjectList(String objectAPIName, List<SObject> sobjectDeleteList, Boolean allOrNone) {
		objectAPIName = objectAPIName.trim();
    	if(sobjectDeleteList.size() > 0) {
            if(!AccessControl.ifObjectIsDeletable(objectAPIName)){throw new BlackPurlException(objectAPIName + NOT_DELETABLE);}
            Database.delete(sobjectDeleteList, allOrNone);
		}
	}
}