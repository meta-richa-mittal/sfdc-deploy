/**
 * Author: Nidhi Sharma
 * Since: May 12, 2021
 * Name: VendorOrderReceivingSOQLUtil
 * Description: SOQL Apex class to handle queries related to Vendor Order Receiving Page.
**/
public without sharing class VendorOrderReceivingSOQLUtil {
    
    public static List<Vendor_Order_Line_Item_Group__c> getVROutstandingItemsByFilters(String vorId, String searchStr) {
        String query = 'SELECT ' + String.join(VendorOrderLineItemGroup.fieldsList(), ','); 
        // Child query for VOLI
        query += ', (SELECT ' + String.join(VendorOrderLineItem.fieldsList(), ',') + ' FROM Vendor_Order_Line_Items__r Where Vendor_Receiving_Group__c = null LIMIT 1) ';

        query += ' FROM Vendor_Order_Line_Item_Group__c WHERE Vendor_Order_Header__c IN (SELECT Vendor_Order_Header__c FROM In_Progress_VR__c ' + 
        			'WHERE Vendor_Receiving_Header__r.Status__c = \'In Progress\' AND Vendor_Receiving_Header__c =: vorId)';
            
        if(String.isNotBlank(searchStr)) {
        	searchStr = BPUtility.escapeSingleQuotes(searchStr);
            query += ' AND (Part__r.Part_Number__c LIKE \'%' + searchStr + '%\' OR Sublet__r.Code__c LIKE \'%' + searchStr + '%\')';
        }
        
        if(AccessControl.ifObjectFieldIsAccessible('Vendor_Order_Line_Item_Group__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectIsAccessible('In_Progress_VR__c') == false ){throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE);}
        List<Vendor_Order_Line_Item_Group__c> voLineItemGroups = Database.query(query);
        return voLineItemGroups;
    }
    
    public static List<Sobject> getVRItemsByFilters(String vrId, String searchStr) {
        String query = 'SELECT ' + String.join(VORGroup.fieldsList(), ','); 
        // Child queries
        query += ', (SELECT ' + String.join(VendorOrderLineItem.fieldsList(), ',') + ' FROM Vendor_Order_Line_Items__r)';
        query += ', (SELECT ' + String.join(VendorOrderLineItem.stockExcessFieldsList(), ',') + ' FROM Vendor_Receiving_Stock_Excesses__r)';
        
        query += ' FROM Vendor_Receiving_Group__c WHERE Vendor_Receiving_Header__c = \'' + BPUtility.escapeSingleQuotes(vrId) + '\'';
        
        if(String.isNotBlank(searchStr)) {
            query += ' AND (Part__r.Part_Number__c LIKE \'%' + BPUtility.escapeSingleQuotes(searchStr) + '%\' OR Sublet__r.Code__c LIKE \'%' + BPUtility.escapeSingleQuotes(searchStr) + '%\')';
        }
        query += ' ORDER BY CreatedDate DESC';
        if(AccessControl.ifObjectFieldIsAccessible('Vendor_Order_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectFieldIsAccessible('Vendor_Receiving_Stock_Excess__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectFieldIsAccessible('Vendor_Receiving_Group__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        
        List<Vendor_Receiving_Group__c> vorGroups = Database.query(query);
        return vorGroups;
    }
}