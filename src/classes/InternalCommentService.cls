/**
 * Author: Pooja Kahndelwal
 * Since: Aug 29, 2018
 * Name: InternalCommentService
 * Description: Service Class used to perform CRUD operations on Internal Comment Object
**/
public without sharing class InternalCommentService {
    
   	public static List<Internal_Comment__c> saveInternalComment(List<InternalCommentWrapper> internalCommentObjList) {
		Internal_Comment__c internalCommentRec;
		List<Internal_Comment__c> internalCommentList = new List<Internal_Comment__c>();
        
		for(InternalCommentWrapper internalCommentObj: internalCommentObjList) {
			internalCommentRec = new Internal_Comment__c();
			internalCommentRec.CO_Header__c = internalCommentObj.CoHeaderId;
			internalCommentRec.Comment__c = internalCommentObj.Comment;
			internalCommentRec.Is_Non_Editable__c = internalCommentObj.IsNonEditable != null ? internalCommentObj.IsNonEditable : false;
			internalCommentRec.Is_Non_Deletable__c = internalCommentObj.IsNonDeletable != null ? internalCommentObj.IsNonEditable : false;
			internalCommentRec.Id = internalCommentObj.Id;
			internalCommentList.add(internalCommentRec);
		}
		return internalCommentList;
   	}
   	
   	public static void saveInternalCommentOnCO(String internalCommentJSON) {
   		InternalCommentWrapper internalCommentObj = (InternalCommentWrapper) System.JSON.deserialize(internalCommentJSON, InternalCommentWrapper.class);
		List<Internal_Comment__c> internalCommentList = saveInternalComment(new List<InternalCommentWrapper>{internalCommentObj});
		DMLUtility.upsertSobjectList('Internal_Comment__c', internalCommentList);

		if(!String.isBlank(internalCommentObj.CoHeaderId)) {
        	List<CO_Header__c> coHeaderList = saveLastNoteOnCO(new Set<String>{internalCommentObj.CoHeaderId});
			if(!AccessControl.ifObjectFieldIsUpdateable('CO_Header__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
			DMLUtility.updateSobjectList('CO_Header__c', coHeaderList);
        }
   	}
   	
   	private static List<CO_Header__c> saveLastNoteOnCO(Set<String> coHeaderIdSet) {
		if(!AccessControl.ifObjectFieldIsAccessible('Internal_Comment__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
		List<Internal_Comment__c> internalCommentList = [SELECT CreatedDate, Comment__c, CO_Header__r.Last_Comment__c, CO_Header__r.Id FROM Internal_Comment__c WHERE CO_Header__c IN :coHeaderIdSet ORDER by CreatedDate DESC LIMIT 1];
		Map<String, String> coHeaderIdToLastNoteMap = new Map<String, String>();
		
		String lastNote;
		for(Internal_Comment__c internalComment : internalCommentList) {
			String createdDate = (internalComment.CreatedDate != null) ? BPUtility.getFormatedDateTime(datetime.newInstance(internalComment.CreatedDate.year(), 
																		internalComment.CreatedDate.month(), internalComment.CreatedDate.day())) : null;
			lastNote = (createdDate != null) ? (createdDate + (!String.isBlank(internalComment.Comment__c) ? ('-' + internalComment.Comment__c) : '')) : (!String.isBlank(internalComment.Comment__c) ? internalComment.Comment__c : '');
			lastNote = (lastNote.length() > 255) ? lastNote.substring(0, 254) : lastNote;
			
			if(internalComment.CO_Header__r.Last_Comment__c == lastNote){
				coHeaderIdSet.remove(internalComment.CO_Header__r.Id);
				continue;
			}
			coHeaderIdToLastNoteMap.put(internalComment.CO_Header__r.Id, lastNote);
		}

		List<CO_Header__c> coHeaderListToUpdate = new List<CO_Header__c>();
		for(String coHeaderId : coHeaderIdSet) {
			lastNote = (coHeaderIdToLastNoteMap.get(coHeaderId) != null ? coHeaderIdToLastNoteMap.get(coHeaderId): '');
			coHeaderListToUpdate.add(new CO_Header__c(Id = coHeaderId, Last_Comment__c = lastNote));
		}
		return coHeaderListToUpdate;
    }
     
   	public static List<InternalCommentWrapper> getInternalCommentListByCOId(String coHeaderId) {
   		String query;   
        query = 'SELECT '; 
        for(String fieldsName : InternalCommentWrapper.getInternalCommentFieldsList()){
        	fieldsName = BPUtility.escapeSingleQuotes(fieldsName);
            query += fieldsName + ', ';
        }
        query = query.substring(0, query.length()-2);
        query += ' FROM ' + Constants.NAMESPACE + 'Internal_Comment__c';
        query += ' WHERE CO_Header__c =: coHeaderId';
        query += ' ORDER by CreatedDate DESC';
        query += ' LIMIT ' + SOQLUtil.getAvailableQueryRowsLimit();
        if(AccessControl.ifObjectFieldIsAccessible('Internal_Comment__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<Internal_Comment__c> internalCommentList  = Database.query(query);
        List<InternalCommentWrapper> internalCommentRecList = new List<InternalCommentWrapper>();
        for(Internal_Comment__c internalCommentRec: internalCommentList) {
        	internalCommentRecList.add(new InternalCommentWrapper(internalCommentRec));
        }
        return internalCommentRecList;
   	}
   	
   	public static void deleteInternalComment(String internalCommentId) { 
   		if(AccessControl.ifObjectIsDeletable('Internal_Comment__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
    	delete new Internal_Comment__c(Id = internalCommentId);
   	}
   	
   	public static void deleteInternalCommentFromCO(String internalCommentId) {
   		if(AccessControl.ifObjectFieldIsAccessible('Internal_Comment__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
   		List<Internal_Comment__c> internalCommentList = [SELECT CO_Header__c FROM Internal_Comment__c WHERE Id =: internalCommentId];
   		String coHeaderId = internalCommentList[0].CO_Header__c;
   		deleteInternalComment(internalCommentId);
   		if(!String.isBlank(coHeaderId)) {
        	saveLastNoteOnCO(new Set<String>{coHeaderId});
        }
   	}
   	
   	public static void deleteInternalCommentsFromCO(String coHeaderId) {
   		if(AccessControl.ifObjectFieldIsAccessible('Internal_Comment__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
   		List<Internal_Comment__c> internalCommentList = [SELECT Id FROM Internal_Comment__c WHERE CO_Header__c =: coHeaderId];
   		if(AccessControl.ifObjectIsDeletable('Internal_Comment__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
   		delete internalCommentList;
   	}

	public static void saveInternalCommentOnCOInBulk(String internalCommentJSON) {
		List<InternalCommentWrapper> internalCommentObjList = (List<InternalCommentWrapper>) System.JSON.deserialize(internalCommentJSON, List<InternalCommentWrapper>.class);
		List<Internal_Comment__c> internalCommentList = saveInternalComment(internalCommentObjList);
		DMLUtility.upsertSobjectList('Internal_Comment__c', internalCommentList);

		Set<String> coHeaderIdSet = new Set<String>();
		for(InternalCommentWrapper internalCommentObj: internalCommentObjList) {
			coHeaderIdSet.add(internalCommentObj.CoHeaderId);
		}
		List<CO_Header__c> coHeaderList = saveLastNoteOnCO(coHeaderIdSet);
		if(!AccessControl.ifObjectFieldIsUpdateable('CO_Header__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
		DMLUtility.updateSobjectList('CO_Header__c', coHeaderList);
   	}

	public static void createInternalCommentsForMoveLineItem(String ItemType, String ItemDescription, String sourceSection, String destinationSection, String sourceCOId, String destinationCOId, String sourceCOName) {
		List<InternalCommentWrapper> internalCommentWrapperList = new List<InternalCommentWrapper>();
		InternalCommentWrapper internalComment1 = new InternalCommentWrapper();
		internalComment1.CoHeaderId = sourceCOId;
		internalComment1.Comment = ItemType + ' '+ ItemDescription +' moved from ' + sourceSection +' to ';
		internalComment1.IsNonEditable = true;
		internalComment1.IsNonDeletable = true;
		if(String.isNotBlank(sourceCOId) && String.isNotBlank(destinationCOId) && destinationCOId != sourceCOId) {
			InternalCommentWrapper internalComment2 = new InternalCommentWrapper();
			internalComment2.CoHeaderId = destinationCOId;
			internalComment2.Comment = ItemType + ' '+ ItemDescription + ' moved from ' + '<a href="#/CustomerOrder_V2?Id=' + sourceCOId + '" target="_blank">' + sourceCOName + '</a> ' + sourceSection +' to ' + destinationSection;
			internalComment2.IsNonEditable = true;
			internalComment2.IsNonDeletable = true;
			internalCommentWrapperList.add(internalComment2);
            List<CO_Header__c> destinationCO = [Select Name From CO_Header__c Where Id =: destinationCOId];
			internalComment1.Comment +=  '<a href="#/CustomerOrder_V2?Id=' + destinationCOId + '" target="_blank">' + destinationCO[0].Name + '</a> ';
		}
		internalComment1.Comment +=  destinationSection;
		internalCommentWrapperList.add(internalComment1);
		InternalCommentService.saveInternalCommentOnCOInBulk(System.JSON.serialize(internalCommentWrapperList));
	}

	public static void addInternalCommentForBulkDiscount(String coId, Decimal oldDiscountPct, Decimal newDiscountPct, String sectionName, String entityName) {
        Internal_Comment__c internalComment = new Internal_Comment__c();
        internalComment.CO_Header__c = coId;
        internalComment.Is_Non_Editable__c = true;
        internalComment.Is_Non_Deletable__c = true;
        if(oldDiscountPct == null) {
            oldDiscountPct = 0;
        }
        if(oldDiscountPct == 0 && newDiscountPct != 0) {
            internalComment.Comment__c = newDiscountPct.setScale(2, RoundingMode.HALF_UP) + '% bulk discount applied to ' + sectionName + ' ' + entityName;
        } else if (oldDiscountPct != 0 && newDiscountPct == 0) {
            internalComment.Comment__c = oldDiscountPct.setScale(2, RoundingMode.HALF_UP) + '% bulk discount was removed from ' + sectionName + ' ' + entityName;
        } else if (oldDiscountPct != 0 && newDiscountPct != 0) {
            internalComment.Comment__c = 'Bulk discount on ' + sectionName + ' '+ entityName + ' changed from ' + oldDiscountPct.setScale(2, RoundingMode.HALF_UP) + '% to ' + newDiscountPct.setScale(2, RoundingMode.HALF_UP) + '%';
        }

		DMLUtility.insertSobjectList('Internal_Comment__c', internalComment);
    }
}