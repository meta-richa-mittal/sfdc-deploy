public without sharing class HondaServiceData extends HondaBaseWrapper {
	public List<JobCardWrapper> JobCard;
	
	public HondaServiceData(List<Service_Order_Header__c> soHeaderList) {
		this.JobCard = new List<JobCardWrapper>();
		for(Service_Order_Header__c soHeaderRec: soHeaderList) {
			this.JobCard.add(new JobCardWrapper(soHeaderRec));
		}
	}
    
    public class JobCardWrapper {
    	public String JobCardNumber;
    	public String VIN;
    	//public String EngineFrameNumber;
    	public List<JobCardDetailsWrapper> Details;
    	
    	public JobCardWrapper(Service_Order_Header__c soHeaderRec) {
    		this.JobCardNumber = soHeaderRec.Invoice_Number__r.Invoice_Number__c;
    		this.VIN = soHeaderRec.Customer_Owned_Unit__r.VIN_Number_Formula__c;
    		//this.EngineFrameNumber = soHeaderRec.Customer_Owned_Unit__r.VIN_Number_Formula__c;
    		
    		this.Details = new List<JobCardDetailsWrapper>();
    		for(String detailType: jobCardDetailsTypeList) {
    			this.Details.add(new JobCardDetailsWrapper(soHeaderRec, detailType));
    		}
    	}
    }
    
    public class JobCardDetailsWrapper {
    	public String Type;
    	public String Odometer;
    	public String ROCheckoutDate;
    	public String ROLabour;
    	public String ROPartsSaleValue;
    	public String ROOilChemicalValue;
    	
    	public JobCardDetailsWrapper(Service_Order_Header__c soHeaderRec, String detailType) {
    		String jobCardDetailType = '';
    		if(soHeaderRec.Transaction_Type__r.Type__c == 'Internal' || soHeaderRec.Transaction_Type__r.Type__c == 'Stock Unit' ||
    			soHeaderRec.Transaction_Type__r.Type__c == 'Deal Service') {
    				jobCardDetailType = 'internal';
    		} else if(soHeaderRec.Transaction_Type__r.Type__c == 'Third-Party') {
    			jobCardDetailType = 'warranty';
    		} else if(soHeaderRec.Transaction_Type__r.Type__c == 'Customer') {
    			jobCardDetailType = 'customer';
    		}
    		
    		this.Type = detailType;
    		this.ROCheckoutDate = soHeaderRec.Invoice_Number__r.Invoice_Date__c.format('dd/MM/yyyy');
    		this.ROOilChemicalValue = '0';
    		
    		if(jobCardDetailType == detailType) {
				this.Odometer = String.valueOf(soHeaderRec.Odometer_on_Departure__c);
	    		this.ROLabour = String.valueOf(soHeaderRec.Hrs_Billed__c);
	    		this.ROPartsSaleValue = String.valueOf(soHeaderRec.Total_Parts__c);
			} else {
				this.Odometer = '0';
	    		this.ROLabour = '0';
	    		this.ROPartsSaleValue = '0';
			}
    	}
    }
    
    private static List<String> jobCardDetailsTypeList = new List<String>{'customer', 'internal', 'warranty'};
}