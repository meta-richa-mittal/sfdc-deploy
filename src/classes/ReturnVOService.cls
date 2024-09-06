/** 
 * Author: Richa Mittal
 * Since: Nov 08, 2023
 * Name: ReturnVOService 
 * Description: service class which contains all methods related to Return VO Ctrl.
**/
public without sharing class ReturnVOService {
    
    public static String getActiveRVOCountByVendorId(String vendorId) {
    	String query = 'SELECT Count(Id) RVOCount FROM Return_VO_Header__c WHERE Vendor__c = \''+ BPUtility.escapeSingleQuotes(vendorId) + '\' AND Status__c = \'In Progress\'';
    	List<AggregateResult> aggList = SOQLUtility.getQueryResults('Return_VO_Header__c', query);
    	return String.valueOf((aggList.size() > 0) ? (Integer) aggList[0].get('RVOCount') : 0);
    }

    public static GlobalSearchResultsWrapper getActiveReturnVendorOrdersByVendorId(String filterJson) {
        GlobalSearchResultsWrapper.COOpenOrderFilterJSON filterObj = (GlobalSearchResultsWrapper.COOpenOrderFilterJSON) System.JSON.deserialize(filterJson, 
                                                                        GlobalSearchResultsWrapper.COOpenOrderFilterJSON.class);
        
        String query = 'SELECT Name, Vendor__r.Name, Reason__c, Return_Total__c, LastModifiedDate, RMA__c, Status__c FROM Return_VO_Header__c WHERE Vendor__c = \'' + BPUtility.escapeSingleQuotes(filterObj.VendorId) + 
            			'\' AND Status__c = \'In Progress\' ORDER BY Name Desc ' + 
            			SOQLUtility.getLimitClause(filterObj.StartIndex, filterObj.RecordCount);

        if(AccessControl.ifObjectFieldIsAccessible('Return_VO_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<Return_VO_Header__c> rvoHeaderList = Database.query(query);
        return new GlobalSearchResultsWrapper(rvoHeaderList.size(), rvoHeaderList);
    }

    public static List<ReturnVOHeaderWrapper.ReturnCreditHistoryWrapper> getCreditHistory(String rvoId) {
        Set<String> rcrIdList = new Set<String>();
        for(Return_VO_Line_Item__c rvoliRec: [SELECT Return_CR_Line_Item__r.Return_CR_Header__c FROM Return_VO_Line_Item__c WHERE Return_VO_Header__c = :rvoId]) {
            rcrIdList.add(rvoliRec.Return_CR_Line_Item__r.Return_CR_Header__c);
        }
        List<ReturnVOHeaderWrapper.ReturnCreditHistoryWrapper> historyObjList = new List<ReturnVOHeaderWrapper.ReturnCreditHistoryWrapper>();
        List<Return_CR_Header__c> rcrHeaderList = [SELECT Status__c, Credited_Date__c, Credit_Memo__c, Owner.Name, Item_Total__c, Name, 
                                                    Other_Charges_Total__c, (SELECT Id FROM Return_CR_Line_Items__r) FROM Return_CR_Header__c 
                                                    WHERE Id IN :rcrIdList];

        for(Return_CR_Header__c rcrRec: rcrHeaderList) {
            historyObjList.add(new ReturnVOHeaderWrapper.ReturnCreditHistoryWrapper(rcrRec));
        }
        return historyObjList;
    }

    public static Map<String, String> rvoWrapperKeyToAPINameMap = new Map<String, String>{
                                                                                          'ReturnedDate' => 'Returned_Date__c',
                                                                                          'Reason' => 'Reason__c',
                                                                                          'TrackingNumber' => 'Tracking_Number__c',
                                                                                          'RMANumber' => 'RMA__c',
                                                                                          'Notes' => 'Notes__c'
                                                                                        };
}