/** 
* Author: Nidhi Sharma
* Since: June 7, 2021 
* Name: TagService 
* Description: Apex class which contains all service methods related to Tag.
**/
public without sharing class TagService {
    
    public static Boolean containsRequiredTagIgnoreCase(String assignedTagStr, String exemptFeeTagLabel) {
        Boolean isRequiredTagExistOnFee = false;
        Set<String> assingedTagStrSet = new Set<String>();
        if(String.isNotBlank(assignedTagStr) && String.isNotBlank(exemptFeeTagLabel)){ 
        	exemptFeeTagLabel = exemptFeeTagLabel.toUpperCase();
            assingedTagStrSet.addAll(assignedTagStr.toUpperCase().split(';'));
            if(assingedTagStrSet.contains(exemptFeeTagLabel)) {
                isRequiredTagExistOnFee = true;
            }
        }
        return isRequiredTagExistOnFee;
    }

    public static List<Tag__c> getFilteredTagList(List<FilterJSON> filerObjList) {
    	String query = 'SELECT Id, ' + String.join(TagWrapper.getTagFieldList(), ', ') + ' FROM Tag__c ' + SOQLUtility.getWhereClauseWithANDCondition(filerObjList, true);
        query += ' ORDER BY Name__c ASC LIMIT ' + SOQLUtil.getAvailableQueryRowsLimit();
    	return SOQLUtility.getQueryResults('Tag__c', query);
    }
    
    public static List<TagWrapper> getTagObjList(List<Tag__c> tagList) {
    	List<TagWrapper> tagWrapperList = new List<TagWrapper>();
    	for(Tag__c tagRec : tagList){
    		tagWrapperList.add(new TagWrapper(tagRec)); 
    	}
    	return tagWrapperList;
    }
}