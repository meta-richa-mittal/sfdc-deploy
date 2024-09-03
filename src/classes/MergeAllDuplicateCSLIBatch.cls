/**
 * Author: Balveer Choudhary
 * Since: Aug 08, 2022
 * Name: MergeAllDuplicateCSLIBatch
 * Description: Batch for Merge All Count Session Line Item which are having duplicacy issue
**/
global without sharing class MergeAllDuplicateCSLIBatch implements Database.Batchable<sobject> {

    // Count session record id
    public String countSessinId;
    //Constants.DUPLICATE_PART
    public String DUPLICATE_PART = Constants.DUPLICATE_PART;

    global MergeAllDuplicateCSLIBatch(String countSessionRecId) {
        this.countSessinId = countSessionRecId;
    }

    global Database.QueryLocator start(Database.BatchableContext bc){
        // get duplicate count session line items
        String strQuery = 'SELECT Id, Part__c, Assigned_Location_1__c, Assigned_Location_2__c, Counted_Qty__c'
                        + ' FROM Count_Session_Line_Item__c WHERE Issue_Indicator__c =: DUPLICATE_PART AND Count_Session__c =: countSessinId';        
        return Database.getQueryLocator(strQuery); 
    }
    
    global void execute(Database.batchableContext bc, List<Count_Session_Line_Item__c> duplicateCSLIRecList) {
        // create set of part Id from duplicate CSLI Rec
        Set<String> partIdSet = new Set<String>();
		for(Count_Session_Line_Item__c duplicateCSLIRec : duplicateCSLIRecList) {
			partIdSet.add(duplicateCSLIRec.Part__c);
		}
        // get CSLI records for duplicate parts
		List<Count_Session_Line_Item__c> csliList = [SELECT Id, Part__c, Counted_Qty__c, Assigned_Location_1__c, 
														Assigned_Location_2__c FROM Count_Session_Line_Item__c WHERE Part__c IN: partIdSet AND 
														Issue_Indicator__c = null AND Count_Session__c =: countSessinId];

        // map of part id to counted CSLI Rec
		Map<String, Count_Session_Line_Item__c> partIdToCSLIRecMap = new Map<String, Count_Session_Line_Item__c>();
		for(Count_Session_Line_Item__c csli : csliList) {
			partIdToCSLIRecMap.put(csli.Part__c, csli);
		}

        //loop having logic of adding qty and location
        Decimal duplicateCounteQty;
		for(Count_Session_Line_Item__c duplicateCSLIRec: duplicateCSLIRecList) {
			if(partIdToCSLIRecMap.containsKey(duplicateCSLIRec.Part__c)) {
				Count_Session_Line_Item__c csliRec = partIdToCSLIRecMap.get(duplicateCSLIRec.Part__c);
                //adding qty
                duplicateCounteQty = duplicateCSLIRec.Counted_Qty__c != null ? duplicateCSLIRec.Counted_Qty__c : 0;
                csliRec.Counted_Qty__c = csliRec.Counted_Qty__c != null ? (csliRec.Counted_Qty__c + duplicateCounteQty) : duplicateCounteQty;
				//adding location
				addingLocation(duplicateCSLIRec, csliRec);
			}
		}

        // updating  count session line items
		DMLUtility.updateSobjectList('Count_Session_Line_Item__c', partIdToCSLIRecMap.values());
		
		// deleting duplicate count session line items
		DMLUtility.deleteSobjectList('Count_Session_Line_Item__c', duplicateCSLIRecList);
    }
    
    global void finish(Database.batchableContext bc) {}

    public Count_Session_Line_Item__c addingLocation(Count_Session_Line_Item__c duplicateCSLIRec, Count_Session_Line_Item__c csliRec){
        // Check if duplicate rec having locations or not
        if(duplicateCSLIRec.Assigned_Location_1__c != null) {
            List<String> locationsList = new List<String>();

            locationsList.addAll( duplicateCSLIRec.Assigned_Location_1__c.replaceAll(';;', ';').split(';'));
            if(duplicateCSLIRec.Assigned_Location_2__c != null){
                locationsList.addAll(duplicateCSLIRec.Assigned_Location_2__c.replaceAll(';;', ';').split(';'));
            }

			if(csliRec.Assigned_Location_1__c != null){
				locationsList.addAll(csliRec.Assigned_Location_1__c.replaceAll(';;', ';').split(';'));
				if(csliRec.Assigned_Location_2__c != null){
					locationsList.addAll(csliRec.Assigned_Location_2__c.replaceAll(';;', ';').split(';'));
				}
			}

            //removing duplicate locations
			Set<String> locationSetLower = new Set<String>();
			Set<String> locationSet = new Set<String>();

			for(String location: locationsList){
				if(location != null && location != '' && !locationSetLower.contains(location.toLowerCase())){
					locationSet.add(location);
					locationSetLower.add(location.toLowerCase());
				}
			}	

			//converting list of locations to string
			List<String> locationStrListForFields = TagUtil.convertTagListIntoTagString(new List<String>(locationSet));
			
            if(locationStrListForFields.size() == 2) {
				csliRec.Assigned_Location_1__c = locationStrListForFields[0];
				csliRec.Assigned_Location_2__c = locationStrListForFields[1];
			}
		}
		return csliRec;
	}
}