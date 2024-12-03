/** 
* Author: Nidhi Sharma
* Since: June 14, 2021 
* Name: PartService 
* Description: Apex class which contains reusable methods for Part entity.
**/
public without sharing class PartService {
	
	public static Integer limitRecord = 50;
	
    public static List<Part__c> getAllParts(PartFilterWrapper filterObj) {
    	String query = 'SELECT ' + String.join(PartWrapper.fieldsList(), ',') + ' FROM Part__c ' + getWhereClauseByFilterStr(filterObj);
    	query += ' ORDER BY Part_Number__c ASC '; 
    	if(filterObj.StartIndex != null && filterObj.RecordCount != null) {
    		query += SOQLUtility.getLimitClause(filterObj.StartIndex, filterObj.RecordCount);
    	} else {
    		query += 'LIMIT ' + limitRecord;
    	}
    	List<SObject> sobjList = SOQLUtility.getQueryResults('Part__c', query);
    	
    	if(filterObj.StartIndex != null && filterObj.StartIndex > 2000 && filterObj.RecordCount != null) {
    		sobjList = SOQLUtility.getLimitRecordsBasedOnRecordCount(sobjList, filterObj.StartIndex);
    	}
    	return sobjList;
    }
    
    public static List<PartWrapper> getPartObjList(List<Part__c> partList) {
    	List<PartWrapper> wrapperList = new List<PartWrapper>();
        for(Part__c partRec : partList) {
            wrapperList.add(new PartWrapper(partRec));
        }
        return wrapperList;
    }
    
    private static String getWhereClauseByFilterStr(PartFilterWrapper filterObj) {
    	List<String> filterStrList = new List<String>{'Active__c = true'};
    	
    	if(filterObj != null) {
    		//Vendor
	    	if(filterObj.VendorList != null && !filterObj.VendorList.isEmpty()) {
	    		filterStrList.add('Vendor__c IN ' + SOQLUtility.convertListToStringForWhereClause(filterObj.VendorList));
	    	}
	    	//Tag
	    	String tagFilterStr = HomeSearchReportInterface.getAssignedTagClause('Parts', filterObj.TagList, 'Tag');
	    	if(String.isNotBlank(tagFilterStr)) {
    			filterStrList.add(tagFilterStr);
	    	}
	    	//Category
	    	if(filterObj.CategoryList != null && !filterObj.CategoryList.isEmpty()) {
	    		filterStrList.add('Category__c IN ' + SOQLUtility.convertListToStringForWhereClause(filterObj.CategoryList));
	    	}
	    	//Part Number OR description
	    	if(String.isNotBlank(filterObj.PartItemDesc) && String.isNotBlank(filterObj.PartItemDesc.trim())) {
	    		filterStrList.add('(Part_Number__c LIKE \'' + BPUtility.escapeSingleQuotes(filterObj.PartItemDesc.trim()) + '%\' OR Description__c LIKE \'%' + BPUtility.escapeSingleQuotes(filterObj.PartItemDesc.trim()) + '%\')');
	    	}
	    	//From created date
	    	if(String.isNotBlank(filterObj.StartDateCreated)) {
	    		DateTime createdDateTimeStart = HomeSearchFilterInterface.getDateFromString(filterObj.StartDateCreated);
	    		filterStrList.add('CreatedDate >= ' + createdDateTimeStart.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\''));
	    	}
	    	//To created date
	    	if(String.isNotBlank(filterObj.EndDateCreated)) {
	    		DateTime createdDateTimeEnd = HomeSearchFilterInterface.getDateFromString(filterObj.EndDateCreated);
	    		filterStrList.add('CreatedDate < ' + createdDateTimeEnd.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\''));
	    	}
	    	//Any Hardcoded where clause
            if(String.isNotBlank(filterObj.HardCodedWhereClause)) {
                filterStrList.add(filterObj.HardCodedWhereClause);
            }
    	}
    	return !filterStrList.isEmpty() ? ' WHERE ' + String.join(filterStrList, ' AND ') : '';
    }

	public static void updatePartQtyCommitted(Set<Id> partIdSet) {
        List<Part__c> partListWithChild = [SELECT Qty_Committed__c,
                                            (SELECT Qty_Committed__c, Oversold_Qty__c FROM CO_Line_Items__r WHERE Closed_CO_Invoice_link__c = null AND 
                                                Invoice_Number__c = null AND CO_Header__r.Order_Status__c != 'Quote'),
                                            (SELECT Return_Qty__c FROM Return_VO_Line_Items__r WHERE Return_VO_Header__r.Status__c NOT IN('Approved','Credited'))
                                            FROM Part__c WHERE Id In :partIdSet];
        List<Part__c> partListToUpdate = new List<Part__c>();
        for(Part__c partRec: partListWithChild) {
            partRec.Qty_Committed__c = partRec.Qty_Committed__c != null ? partRec.Qty_Committed__c : 0;
            Decimal qtyCommittedNew = 0;
            for(CO_Line_Item__c coli: partRec.CO_Line_Items__r) {
                qtyCommittedNew += ((coli.Qty_Committed__c != null ? coli.Qty_Committed__c : 0) - (coli.Oversold_Qty__c != null ? coli.Oversold_Qty__c : 0));
            }

            for(Return_VO_Line_Item__c rvoli: partRec.Return_VO_Line_Items__r) {
                if(rvoli.Return_Qty__c != null) {
                    qtyCommittedNew += rvoli.Return_Qty__c;
                }
            }
            if(qtyCommittedNew != partRec.Qty_Committed__c) {
                partRec.Qty_Committed__c = qtyCommittedNew;
                partListToUpdate.add(partRec);
            }
        }
		if(!partListToUpdate.isEmpty()) {
        	DMLUtility.updateSobjectList('Part__c', partListToUpdate);
		}
    }

	public static void updatePartOnOrderQty(Set<Id> partIdSet) {
    	if(partIdSet != null && partIdSet.size() > 0) {
	    	List<Part__c> partList = [SELECT Id, (SELECT Qty_Needed__c FROM Vendor_Order_Line_Items__r WHERE Is_Received__c = false AND Vendor_Order_Header__c != null AND Is_required_For_Customer__c = false AND Is_Service__c = false) FROM Part__c WHERE Id IN: partIdSet];
            for(Part__c partRec : partList) {
				partRec.Qty_On_Order__c = 0;
                for(Vendor_Order_Line_Item__c voli : partRec.Vendor_Order_Line_Items__r) {
                    partRec.Qty_On_Order__c += (voli.Qty_Needed__c != null ? voli.Qty_Needed__c : 0);
                }
            } 
			DMLUtility.updateSobjectList('Part__c', partList);
    	}
    }
}