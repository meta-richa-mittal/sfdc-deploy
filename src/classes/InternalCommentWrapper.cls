/**
 * Author: Pooja Kahndelwal
 * Since: Aug 29, 2018
 * Name: InternalCommentWrapper
 * Description: Used to convert Internal Comment object's serialize and deserialize operations
**/
public without sharing class InternalCommentWrapper {
	public String Id;
	public String CoHeaderId;
	public String Comment;
	public String CreatedById;
	public String CreatedByName;
	public String CreatedDate;
	public String CreatedTime; 
	public String LastModifiedDate;
	public String LastModifiedTime;
	public Boolean isEdited;
	public Boolean IsReadOnly;
	public Boolean IsNonEditable;
	public Boolean IsNonDeletable;
	
	public InternalCommentWrapper() {}
	
	public InternalCommentWrapper(Internal_Comment__c internalComment) {
		DateTime lastModifDate = BPUtility.getLastModifiedDate(internalComment);
		this.Id = internalComment.Id;
		this.CoHeaderId = internalComment.CO_Header__c;
		this.Comment = internalComment.Comment__c;
		this.CreatedById = internalComment.CreatedBy.Id;
		this.CreatedByName = internalComment.CreatedBy.Name; 
		this.CreatedDate = (internalComment.CreatedDate != null) ? BPUtility.getFormatedDateTime(datetime.newInstance(internalComment.CreatedDate.year(), 
																		internalComment.CreatedDate.month(), internalComment.CreatedDate.day())) : null;
		this.LastModifiedDate = (lastModifDate != null) ? BPUtility.getFormatedDateTime(datetime.newInstance(lastModifDate.year(), 
																		lastModifDate.month(), lastModifDate.day())) : null;
		this.CreatedTime = (internalComment.CreatedDate != null) ? internalComment.CreatedDate.format('h:mma') : null;	
		this.LastModifiedTime = (lastModifDate != null) ? lastModifDate.format('h:mma') : null;		
		this.isEdited = (internalComment.CreatedDate == lastModifDate) ? false : true; 													
		this.IsReadOnly = ((internalComment.CO_Header__c != null && internalComment.CO_Header__r.Closed_Date_Time__c != null && internalComment.CreatedDate < internalComment.CO_Header__r.Closed_Date_Time__c) || (internalComment.Is_Non_Editable__c && internalComment.Is_Non_Deletable__c));										
	}
	
	public static List<String> getInternalCommentFieldsList() {
	   return new List<String>{ 'Id',
	   							'CO_Header__c',
	   							'Comment__c',
	   							'CreatedBy.Id',
	   							'CreatedBy.Name',
	   							'CreatedDate',
	   							'Last_Modified_Date__c',
								'LastModifiedDate',
	   							'CO_Header__r.Closed_Date_Time__c',
								'Is_Non_Deletable__c',
								'Is_Non_Editable__c'
	   						};
   	}
}