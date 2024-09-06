/**
 * Author: Pooja Kahndelwal
 * Since: Jan 31, 2019
 * Name: NotesService
 * Description: Service Class used to perform CRUD operations on Generic Notes Object-Used to store concerns/notes for BP records 
**/
public without sharing class NotesService {
    
    /**
    * Name: upsertNotesRecord
    * Desc: Method to Create/Update Notes record
    * @param: concern - String - cocerns/notes to be saved
    * @param: notesId - Id - Notes Record Id
    * @return: Id - Notes Record Id
    **/
   	public static Id upsertNotesRecord(String concern, Id notesId) {
    	Notes__c notes = new Notes__c(Description__c = concern, Id = notesId);
        DMLUtility.upsertSobjectList('Notes__c', notes);
    	if(notes != null) {
    		return notes.Id;
    	} 
    	return '';
    }
    
    /**
    * Name: deleteNotesRecords
    * Desc: Method to Delete Notes record
    * @param: notesIdSet - Set<Id> - Deletable Notes records' Id set
    * @return: 
    **/
    public static void deleteNotesRecords(Set<Id> notesIdSet) {
    	if(AccessControl.ifObjectFieldIsAccessible('Notes__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
    	List<Notes__c> notesRecordList = new List<Notes__c>();
    	for(Id notesId : notesIdSet) {
    		notesRecordList.add(new Notes__c(Id = notesId));
    	}
   		if(AccessControl.ifObjectIsDeletable('Notes__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
   		delete notesRecordList;
    }
    
    /**
    * Name: populateNotesLookup
    * Desc: Method to Create/Update Notes record and then Populate Notes Id (Event_Concern__c field) (Notes Lookup) on Event record - while Save Events
    * @param: eventRec - Event - Event record
    * @param: concern - String - Appointment cocerns to be saved
    * @return: Event - eventRec - Event record
    **/
    public static Event populateNotesLookup(Event eventRec, String concern) {
    	String notesId = upsertNotesRecord(concern, null); 
    	if(String.isNotBlank(notesId)) {
    		eventRec.Event_Concern__c = notesId;
    	}
    	return eventRec;
    }
    
    /**
    * Name: populateConcernsOnSO
    * Desc: Method to Populate concern field on SO record from corresponding Event's 'Notes' record - while Save SO
    * @param: soRec - Service_Order_Header__c - SO Record
    * @param: notesId - String - Notes Record Id
    * @return:
    **/
    public static void populateConcernsOnSO(Service_Order_Header__c soRec, String notesId) {
   		if(AccessControl.ifObjectFieldIsAccessible('Notes__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
    	List<Notes__c> notesList = [SELECT Id, Description__c FROM Notes__c WHERE Id =: notesId];
        soRec.SO_Concern__c = '';
        for(Notes__c notesRec : notesList) {
        	soRec.SO_Concern__c += (notesRec.Description__c != null) ? notesRec.Description__c : '';
        }
   	}	
   	
   	/**
    * Name: populateNotesOnAppointment
    * Desc: Method to Populate concern field on AppointmentWrapper Json('Event' Rec) from corresponding 'Notes' record - while get Events  
    * @param: appointmentObj - AppointmentWrapper - Appointment Json
    * @param: notesId - String - Notes Record Id
    * @return:
    **/
   	public static void populateNotesOnAppointment(AppointmentWrapper appointmentObj, String notesId) {
   		if(AccessControl.ifObjectFieldIsAccessible('Notes__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
    	List<Notes__c> notesList = [SELECT Id, Description__c FROM Notes__c WHERE Id =: notesId];
        for(Notes__c notesRec : notesList) {
        	if(String.isNotBlank(notesRec.Description__c)) {
                appointmentObj.Concern.addAll(notesRec.Description__c.split('\n'));
            }
        }
   	}
       
    public static void saveNotes(String notesJsonString) {
        
        NotesWrapper notesWrapper = (NotesWrapper) System.JSON.deserialize(notesJsonString, NotesWrapper.class);
        String sObjectName;
        if (String.isNotBlank(notesWrapper.Id)) {
            sObjectName= (Id.valueOf(notesWrapper.Id)).getSObjectType().getDescribe().getName();
        }
        if (String.isNotBlank(sObjectName))  {
            if (sObjectName == 'Account') {
                if(AccessControl.ifObjectFieldIsUpdateable('Account') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); } 
                Account accountRec = new Account(Id = notesWrapper.Id);
                accountRec.Notes__c = notesWrapper.Notes;
                DMLUtility.updateSobjectList('Account', accountRec);
            } else if (sObjectName == CONSTANTS.NAMESPACE + 'Customer_Owned_Unit__c') {
                if(AccessControl.ifObjectFieldIsUpdateable('Customer_Owned_Unit__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); } 
                Customer_Owned_Unit__c customerOwnedUnitRec = new Customer_Owned_Unit__c(Id = notesWrapper.Id);
                customerOwnedUnitRec.Notes__c = notesWrapper.Notes;
                DMLUtility.updateSobjectList('Customer_Owned_Unit__c', customerOwnedUnitRec);
            } else if (sObjectName == CONSTANTS.NAMESPACE + 'Deal_Item__c') {
                if(AccessControl.ifObjectFieldIsUpdateable('Deal_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); } 
                Deal_Item__c dealItemRec = new Deal_Item__c(Id = notesWrapper.Id);
                dealItemRec.Notes__c = notesWrapper.Notes;
                DMLUtility.updateSobjectList('Deal_Item__c', dealItemRec);
            }
        }     
     }
    
    public class NotesWrapper {
        public String Id;
        public String Notes;

        public NotesWrapper(String Id,String notes){
            this.Id = Id;
            this.Notes = notes;
        }
    }
}