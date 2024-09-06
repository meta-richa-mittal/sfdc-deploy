/** 
* Author: Nidhi Sharma
* Since: August 16, 2021
* Name: ReopenUtil 
* Description: Apex class which contains Reopening utility fields.
**/
public without sharing class ReopenUtil {
    
    public static final String INVOICE_TYPE_DEAL = 'Deal';
    public static final String INVOICE_TYPE_CUSTOMER = 'Customer';
    public static final String INVOICE_TYPE_CASH_SALE = 'Cash Sale';
    public static final String INVOICE_TYPE_UNIT_INVENTORY = 'Internal Job on Stock Unit';
    public static final String INVOICE_TYPE_DEAL_MERCH = 'Deal Merch';
    public static final String INVOICE_TYPE_DEAL_SERVICE = 'Deal Service';
    public static final String INVOICE_TYPE_OTHER = 'Other';
    
    public static final String INVOICE_CAN_BE_REMOVED_FROM_ACCOUNTING = 'The accounting entries will be reviewed to ensure that they can be removed from the accounting application';
    public static final String SOLD_UNIT_CAN_BE_PUT_BACK_INTO_STOCK = 'The units sold will be reviewed to ensure there are no new customer service jobs or deals attached to them';
    public static final String TRADE_INS_CAN_BE_ASSIGNED_BACK_TO_THE_CUSTOMER = 'Any traded in units stocked in when the deal was finalized will be reviewed to ensure there are no internal jobs or deals tied to them';
    public static final String UNIT_IS_STILL_OWNED_BY_THE_SAME_CUSTOMER = 'Units for any service jobs will be reviewed to ensure that they are still owned by the same customer';
    public static final String UNIT_IS_STILL_IN_INVENTORY = 'Units will be reviewed to ensure that they are still in inventory';
    public static final String RETURNED_OVERSOLD_PARTS_CAN_BE_REMOVED_FROM_INVENTORY = 'Any returned parts have not been resold and any oversold parts have not already been resolved';
    public static final String DEDUCTIBLE_NOT_ALREADY_CLAIMED = 'Any invoiced deductible has not already been claimed from the third-party';
    
    public static final String SOLD_AND_TRADE_IN_WILL_RETURNED = 'Any units sold or traded in will be returned to their previous owner.';
    public static final String SERVICE_JOB_RESET_TO_COMPLETE = 'Any service jobs on the invoice will be reset to a Completed status.';
    public static final String PART_WILL_RETURN_AND_RECOMMITTED = 'Any parts on the invoice will be returned to stock and re-committed.';
    public static final String RETURNED_OVERSOLD_PART_WILL_REMOVED = 'Any returned or oversold parts on the invoice will be removed from stock.';
    
    public static Map<String, List<String>> invoiceTypeToConditionTextsMap = new Map<String, List<String>>{
    	INVOICE_TYPE_DEAL => new List<String>{
    					INVOICE_CAN_BE_REMOVED_FROM_ACCOUNTING, 
    					SOLD_UNIT_CAN_BE_PUT_BACK_INTO_STOCK,
    					TRADE_INS_CAN_BE_ASSIGNED_BACK_TO_THE_CUSTOMER
    					},
    	INVOICE_TYPE_CASH_SALE => new List<String>{
    					INVOICE_CAN_BE_REMOVED_FROM_ACCOUNTING, 
    					RETURNED_OVERSOLD_PARTS_CAN_BE_REMOVED_FROM_INVENTORY
						},
		INVOICE_TYPE_UNIT_INVENTORY => new List<String>{
    					INVOICE_CAN_BE_REMOVED_FROM_ACCOUNTING, 
    					UNIT_IS_STILL_IN_INVENTORY,
    					RETURNED_OVERSOLD_PARTS_CAN_BE_REMOVED_FROM_INVENTORY
						},
		INVOICE_TYPE_DEAL_MERCH => new List<String>{
            			INVOICE_CAN_BE_REMOVED_FROM_ACCOUNTING,
    					RETURNED_OVERSOLD_PARTS_CAN_BE_REMOVED_FROM_INVENTORY
						},
		INVOICE_TYPE_DEAL_SERVICE => new List<String>{
            			INVOICE_CAN_BE_REMOVED_FROM_ACCOUNTING,
    					RETURNED_OVERSOLD_PARTS_CAN_BE_REMOVED_FROM_INVENTORY
						},
		INVOICE_TYPE_CUSTOMER => new List<String>{
    					INVOICE_CAN_BE_REMOVED_FROM_ACCOUNTING, 
    					UNIT_IS_STILL_OWNED_BY_THE_SAME_CUSTOMER,
    					RETURNED_OVERSOLD_PARTS_CAN_BE_REMOVED_FROM_INVENTORY,
    					DEDUCTIBLE_NOT_ALREADY_CLAIMED
						},
		INVOICE_TYPE_OTHER => new List<String>{
    					INVOICE_CAN_BE_REMOVED_FROM_ACCOUNTING, 
    					UNIT_IS_STILL_OWNED_BY_THE_SAME_CUSTOMER,
    					RETURNED_OVERSOLD_PARTS_CAN_BE_REMOVED_FROM_INVENTORY
						}									
    };
    
    public static Map<String, List<String>> invoiceTypeToReopenMessageList = new Map<String, List<String>>{
    	INVOICE_TYPE_DEAL => new List<String>{
    					SOLD_AND_TRADE_IN_WILL_RETURNED
    					},
    	INVOICE_TYPE_CASH_SALE => new List<String>{
    					PART_WILL_RETURN_AND_RECOMMITTED, 
    					RETURNED_OVERSOLD_PARTS_CAN_BE_REMOVED_FROM_INVENTORY
						},
		INVOICE_TYPE_UNIT_INVENTORY => new List<String>{
    					SERVICE_JOB_RESET_TO_COMPLETE, 
    					PART_WILL_RETURN_AND_RECOMMITTED,
    					RETURNED_OVERSOLD_PART_WILL_REMOVED
						},
		INVOICE_TYPE_DEAL_MERCH => new List<String>{
    					PART_WILL_RETURN_AND_RECOMMITTED,
    					RETURNED_OVERSOLD_PART_WILL_REMOVED
						},
		INVOICE_TYPE_DEAL_SERVICE => new List<String>{
						SERVICE_JOB_RESET_TO_COMPLETE,
    					PART_WILL_RETURN_AND_RECOMMITTED,
    					RETURNED_OVERSOLD_PART_WILL_REMOVED
						},				
		INVOICE_TYPE_CUSTOMER => new List<String>{
    					SERVICE_JOB_RESET_TO_COMPLETE,
    					PART_WILL_RETURN_AND_RECOMMITTED,
    					RETURNED_OVERSOLD_PART_WILL_REMOVED
						},
		INVOICE_TYPE_OTHER => new List<String>{
    					SERVICE_JOB_RESET_TO_COMPLETE, 
    					PART_WILL_RETURN_AND_RECOMMITTED,
    					RETURNED_OVERSOLD_PART_WILL_REMOVED
						}									
    };
    
}