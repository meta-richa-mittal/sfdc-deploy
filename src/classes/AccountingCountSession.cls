/**
 * Author: Nidhi Sharma
 * Since: Sept 11, 2019
 * Name: AccountingCountSession
 * Description: 
**/
public without sharing class AccountingCountSession {
 	
 	public String Id;
    public String CountSessionNumber;
    public String Name;
    public Date CountDate;
    public Decimal TotalCostAdjustment;
    public String AdjustmentCategoryIncomeGL;
    
	public String XeroAccountingId;
	public String QBAccountingId;
	public String AccountingSyncToken;
	public List<AccountingCountSessionLineItem> CountSessionLineItemList;
	
 	public AccountingCountSession(Count_Session__c countSessionRec, List<Count_Session_Line_Item__c> countSessionLineItemRecList) {
 		this.Id = countSessionRec.Id;
 		this.CountSessionNumber = countSessionRec.Name;
 		this.Name = countSessionRec.Name__c;
 		this.CountDate = DateTimeUtility.getDateFromFormattedDateStr(DateTimeUtility.getFormttedDateFromDateTime(countSessionRec.Count_Date_Time__c, 'dd/MM/yyyy'));
 		this.TotalCostAdjustment = countSessionRec.Net_Adjustment_After_Finalize__c != null ? 
	    										countSessionRec.Net_Adjustment_After_Finalize__c.setScale(2, RoundingMode.HALF_UP) : 0;
	    										
 		this.AdjustmentCategoryIncomeGL = countSessionRec.Adjustment_Category__r.Income_GL__c;
 		
 		this.XeroAccountingId = countSessionRec.Xero_Accounting_Id__c;
 		this.QBAccountingId = countSessionRec.QB_Accounting_Id__c;
 		this.AccountingSyncToken = countSessionRec.Accounting_Sync_Token__c;
 		
		this.CountSessionLineItemList = new List<AccountingCountSessionLineItem>();
		Map<String, AccountingCountSessionLineItem> partCategoryToAccCountSessionLIMap = new Map<String, AccountingCountSessionLineItem>(); 
 		for(Count_Session_Line_Item__c countSessionLineItemRec : countSessionLineItemRecList) {
			if(!partCategoryToAccCountSessionLIMap.containsKey(countSessionLineItemRec.Part_Category__c)) {
				partCategoryToAccCountSessionLIMap.put(countSessionLineItemRec.Part_Category__c, new AccountingCountSessionLineItem(countSessionLineItemRec));
			} else {
				if(countSessionLineItemRec.Total_Cost_Adjustment__c != null) {
					partCategoryToAccCountSessionLIMap.get(countSessionLineItemRec.Part_Category__c).TotalCostAdjustment += countSessionLineItemRec.Total_Cost_Adjustment__c.setScale(2, RoundingMode.HALF_UP);
				}
			}
		}
		this.CountSessionLineItemList = partCategoryToAccCountSessionLIMap.values();
		 
 	}
 	
 	public class AccountingCountSessionLineItem {
	    public Decimal Variance;
	    public Decimal TotalCostAdjustment;
	    public String PartCategoryInventoryGL;
		
		public AccountingCountSessionLineItem(Count_Session_Line_Item__c countSessionLineItemRec) {
	    	this.Variance = countSessionLineItemRec.Variance__c;
	    	this.TotalCostAdjustment = countSessionLineItemRec.Total_Cost_Adjustment__c != null ? 
	    										countSessionLineItemRec.Total_Cost_Adjustment__c.setScale(2, RoundingMode.HALF_UP) : 0;
	    	this.PartCategoryInventoryGL = countSessionLineItemRec.Part_Category__r.Inventory_GL__c;
	 	}
 	}
 	
	public static List<String> getCountSessionfieldsList(){
        return new List<String>{ 'Id',
                            'Name',
                            'Name__c',
                            'Count_Date_Time__c',
                            'Finalized_Date__c',
                            'Finalized_By__r.Name',
                            'Net_Adjustment_After_Finalize__c',
                            'Xero_Accounting_Id__c',
                            'QB_Accounting_Id__c',
                            'Accounting_Sync_Token__c',
                            'Adjustment_Category__r.Income_GL__c'
                       };
    }
    
    public static List<String> getCountSessionLineItemfieldsList(){
        return new List<String>{ 'Variance__c',
        					'Count_Session__c',
                            'Part_Category__r.Inventory_GL__c',
							'Total_Cost_Adjustment__c',
							'Part_Category__c'
                       };
    }
       
}