/**
 * Author: Nidhi Sharma
 * Since: August 28, 2019
 * Name: CountSessionLineItemWrapper
 * Description: 
**/
public without sharing class CountSessionLineItemWrapper {
    
    public Integer TotalRecords;
    public Integer TotalPages;
    public Integer CurrentPage;
    public Integer PageSize;
    public Decimal TotalAdjustment;
    public Decimal TotalCountedParts;
    public Decimal TotalUncountedParts;
    public Decimal TotalAdjustedParts;
    public Decimal TotalIssuesToResolve;
    public Decimal TotalCountedCost;
    public Decimal TotalUncountedCost;
	public Decimal TotalDuplicateCountIssues;

    public List<CountSessionLineItem> CountSessionLineItems;
    
    public CountSessionLineItemWrapper(Count_Session__c countSessionRec, Integer pageSize) {
    	this.TotalRecords = 0;
    	this.CurrentPage = 0;
        this.PageSize = pageSize;
        this.TotalPages = 0;
		this.TotalDuplicateCountIssues = 0;
		this.CountSessionLineItems = new List<CountSessionLineItem>();
		
    	if(countSessionRec.Status__c.equalsIgnoreCase('Closed')) {
    		this.TotalAdjustment = countSessionRec.Net_Adjustment_After_Finalize__c.setScale(2, RoundingMode.HALF_UP);
    	} else {
    		this.TotalAdjustment = countSessionRec.Total_Adjusted_Cost__c.setScale(2, RoundingMode.HALF_UP);
    	}
        	
    	this.TotalCountedParts = countSessionRec.Total_Counted_Parts__c;
		this.TotalUncountedParts = countSessionRec.Total_Uncounted_Parts__c;
		this.TotalAdjustedParts = countSessionRec.Total_Adjusted_Parts__c;
		this.TotalIssuesToResolve = countSessionRec.Total_Issues_To_Resolve__c;
		
		this.TotalCountedCost = countSessionRec.Total_Counted_Cost__c.setScale(2, RoundingMode.HALF_UP);
		this.TotalUncountedCost = countSessionRec.Total_Uncounted_Cost__c.setScale(2, RoundingMode.HALF_UP);
    	
    }
    
    public CountSessionLineItemWrapper(List<Count_Session_Line_Item__c> countSessionLineItemRecList) {
    	if(countSessionLineItemRecList != null && countSessionLineItemRecList.size() > 0) {
    		if(countSessionLineItemRecList[0].Count_Session__r.Status__c.equalsIgnoreCase('Closed')) {
        		this.TotalAdjustment = countSessionLineItemRecList[0].Count_Session__r.Net_Adjustment_After_Finalize__c.setScale(2, RoundingMode.HALF_UP);
        	} else {
        		this.TotalAdjustment = countSessionLineItemRecList[0].Count_Session__r.Total_Adjusted_Cost__c.setScale(2, RoundingMode.HALF_UP);
        	}
    	}

    	this.CountSessionLineItems = new List<CountSessionLineItem>();
    	for(Count_Session_Line_Item__c countSessionLIRec : countSessionLineItemRecList) {
    		this.CountSessionLineItems.add(new CountSessionLineItemWrapper.CountSessionLineItem(countSessionLIRec));
    	}
    }

    public CountSessionLineItemWrapper(Integer totalRecords, PartCountService.PageInfoWrapper pageInfoObj, List<Count_Session_Line_Item__c> countSessionLineItemRecList, Integer totalDuplicateCountIssues) {
    	this.TotalRecords = totalRecords;
		this.TotalDuplicateCountIssues = totalDuplicateCountIssues;

    	this.CurrentPage = (pageInfoObj.CurrentPage != null && pageInfoObj.CurrentPage > 0) ? pageInfoObj.CurrentPage : 1;
        this.PageSize = pageInfoObj.PageSize;
        
        this.TotalPages = (totalRecords != null && totalRecords != 0) ? (totalRecords / pageInfoObj.PageSize) : 0;
        if(Math.mod(totalRecords, pageInfoObj.PageSize) != null && math.mod(totalRecords, pageInfoObj.PageSize) > 0 ) {
        	this.TotalPages += 1;
        }

        if(countSessionLineItemRecList != null && countSessionLineItemRecList.size() > 0) {
        	if(countSessionLineItemRecList[0].Count_Session__r.Status__c.equalsIgnoreCase('Closed')) {
        		this.TotalAdjustment = countSessionLineItemRecList[0].Count_Session__r.Net_Adjustment_After_Finalize__c.setScale(2, RoundingMode.HALF_UP);
        	} else {
        		this.TotalAdjustment = countSessionLineItemRecList[0].Count_Session__r.Total_Adjusted_Cost__c.setScale(2, RoundingMode.HALF_UP);
        	}
        	this.TotalCountedParts = countSessionLineItemRecList[0].Count_Session__r.Total_Counted_Parts__c;
			this.TotalUncountedParts = countSessionLineItemRecList[0].Count_Session__r.Total_Uncounted_Parts__c;
			this.TotalAdjustedParts = countSessionLineItemRecList[0].Count_Session__r.Total_Adjusted_Parts__c;
			this.TotalIssuesToResolve = countSessionLineItemRecList[0].Count_Session__r.Total_Issues_To_Resolve__c;
			this.TotalCountedCost = countSessionLineItemRecList[0].Count_Session__r.Total_Counted_Cost__c.setScale(2, RoundingMode.HALF_UP);
			this.TotalUncountedCost = countSessionLineItemRecList[0].Count_Session__r.Total_Uncounted_Cost__c.setScale(2, RoundingMode.HALF_UP);
        }
        
    	this.CountSessionLineItems = new List<CountSessionLineItem>();
    	for(Count_Session_Line_Item__c countSessionLIRec : countSessionLineItemRecList) {
    		this.CountSessionLineItems.add(new CountSessionLineItemWrapper.CountSessionLineItem(countSessionLIRec));
    	}
    }
    
    public class CountSessionLineItem {
    	public String Id;
    	public String CountSessionId;
    	public String PartNumber;
	    public String Description;
	    public String VendorName;
	    public String Locations;
	    public Decimal QtyAvailable;
	    public Decimal CountedQty;
	    public Decimal Variance;
	    public Decimal Cost;
	    public Decimal NetAdjustment;
	    public Boolean IsSelectedPart;
	    public Boolean IsAlreadyCounted;
	    public String PartId;
		public String Issue;
		public String IssueDescription;
		public Decimal TotalVariance;
	    public Decimal TotalCost;
		public String Name;

		public CountSessionLineItem(){}
	    
	    public CountSessionLineItem(Count_Session_Line_Item__c countSessionLineItemRec) {
	    	this.Id = countSessionLineItemRec.Id;
	    	this.PartId = countSessionLineItemRec.Part__c;
	    	this.CountSessionId = countSessionLineItemRec.Count_Session__c;
	    	
	    	this.PartNumber = countSessionLineItemRec.Part_Number_Formula__c;
	    	
	    	if(countSessionLineItemRec.Part__c != null) {
		    	this.Description = countSessionLineItemRec.Part__r.Description__c;
		    	this.VendorName = countSessionLineItemRec.Part__r.Vendor__r.Name;
	    	}
	    	
	    	this.QtyAvailable = countSessionLineItemRec.Qty_Available__c != null ? countSessionLineItemRec.Qty_Available__c : 0;
	    	List<String> locationList = (LocationManagementService.getLocationsList(countSessionLineItemRec));
	    	this.Locations = ((locationList != null && locationList.size() > 0) ? String.join(locationList, ',') : '');
	    	this.CountedQty = countSessionLineItemRec.Counted_Qty__c != null ? countSessionLineItemRec.Counted_Qty__c : 0;
	    	this.Variance = countSessionLineItemRec.Variance__c;
	    	this.Cost = (countSessionLineItemRec.Cost__c != null) ? countSessionLineItemRec.Cost__c.setScale(2, RoundingMode.HALF_UP) : 0;
	    	if(countSessionLineItemRec.Count_Session__r.Status__c != null && countSessionLineItemRec.Count_Session__r.Status__c.equalsIgnoreCase('Closed')) {
        		this.NetAdjustment = countSessionLineItemRec.Total_Cost_Adjustment__c != null ? 
        						countSessionLineItemRec.Total_Cost_Adjustment__c.setScale(2, RoundingMode.HALF_UP) : 0;
        	} else {
        		this.NetAdjustment = countSessionLineItemRec.Net_Adjustment__c != null ? 
        						countSessionLineItemRec.Net_Adjustment__c.setScale(2, RoundingMode.HALF_UP) : 0;
        	}
	    	this.IsSelectedPart = countSessionLineItemRec.Is_Selected_Part__c;
	    	this.IsAlreadyCounted = countSessionLineItemRec.Is_Counted__c;
			this.Issue = countSessionLineItemRec.Issue_Indicator__c;
			if(this.Issue != null && PartCountService.issueIndicatorToIssueDescriptionMap.containsKey(this.Issue)) {
				this.IssueDescription = PartCountService.issueIndicatorToIssueDescriptionMap.get(this.Issue);
			} else {
				this.IssueDescription = '';
			}
			this.TotalVariance = this.Variance * this.Cost;
			this.TotalCost = this.QtyAvailable * this.Cost;
			this.Name = countSessionLineItemRec.Name;
	    }
	    
	    public CountSessionLineItem(Part__c partRec) {
	    	this.PartId = partRec.Id;
	    	this.PartNumber = partRec.Part_Number__c;
	    	this.Description = partRec.Description__c;
	    	this.VendorName = partRec.Vendor__r.Name;
	    	this.Cost = (partRec.Average_Cost__c != null && partRec.Average_Cost__c != 0) ? partRec.Average_Cost__c : partRec.Last_Cost__c;
	    	this.QtyAvailable = partRec.AvailableParts__c;
	    	List<String> locationList = (LocationManagementService.getLocationsList(partRec));
	    	this.Locations = ((locationList != null && locationList.size() > 0) ? String.join(locationList, ',') : '');
	    	this.CountedQty = 0;
	    	this.IsSelectedPart = false;
	    	this.IsAlreadyCounted = false;
	    }
    }
	
	public class CountSessionImportFileWrapper { 
		public Boolean MergeDuplicateParts;
		public List<CountSessionLineItem> CountSessionLineItems;

	}
    
    public static List<String> fieldsList() {
    	return new List<String>{'Id',
    							'Part__c',
    							'Part_Number_Formula__c',
    							'Part__r.Description__c',
    							'Part__r.Part_Number__c',
    							'Part__r.Vendor__r.Name',
    							'Qty_Available__c',
    							'Assigned_Location_1__c',
    							'Assigned_Location_2__c',
    							'Counted_Qty__c',
    							'Variance__c',
    							'Cost__c',
    							'Net_Adjustment__c',
    							'Is_Selected_Part__c',
    							'Is_Counted__c',
    							'Count_Session__c',
    							'Count_Session__r.Status__c',
    							'Count_Session__r.Total_Counted_Parts__c',
    							'Count_Session__r.Total_Uncounted_Parts__c',
    							'Count_Session__r.Total_Adjusted_Parts__c',
    							'Count_Session__r.Total_Issues_To_Resolve__c',
	                            'Count_Session__r.Total_Counted_Cost__c',
	                            'Count_Session__r.Total_Uncounted_Cost__c',
	                            'Count_Session__r.Total_Adjusted_Cost__c',
	                            'Count_Session__r.Net_Adjustment_After_Finalize__c',
	                            'Issue_Indicator__c',
								'Total_Cost_Adjustment__c', 
								'Name'
    						};
    }
    
}