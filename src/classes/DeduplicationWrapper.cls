public without sharing class DeduplicationWrapper {
	
	public String AdditionalInfo1;
    public String JobType;
    public Decimal Total;
    public String Concern;
    public String COHeaderId;
    public String CONumber;
    public String LastModifiedDate;
    
    public DeduplicationWrapper(Service_Order_Header__c soHeaderRec) {
        this.AdditionalInfo1 = soHeaderRec.Customer_Owned_Unit__r.Stock_Id__c;
        this.CONumber = soHeaderRec.CO_Header__r.Name;
        
        this.JobType = (soHeaderRec.Transaction_Type__r.Code_Label__c != null) ? soHeaderRec.Transaction_Type__r.Code_Label__c : '';
        this.Total = (soHeaderRec.Total__c != null) ? soHeaderRec.Total__c.setScale(2, RoundingMode.HALF_UP) : 0.00;
        this.Concern = (soHeaderRec.SO_Concern__c != null) ? String.join(soHeaderRec.SO_Concern__c.split('\n'), ',') : '';
        
        this.COHeaderId = soHeaderRec.CO_Header__c;
        this.LastModifiedDate = soHeaderRec.LastModifiedDate.format('MMMM d,  yyyy');
    }
    
    public static List<String> getServiceJobFieldsList() {
            return new List<String>{ 'Id',
                            'Name__c',
                            'Transaction_Type__r.Code_Label__c',
                            'Total__c',
                            'SO_Concern__c',
                            'Customer_Owned_Unit__r.Stock_Id__c',
                            'CO_Header__c',
                            'CO_Header__r.Name',
                            'LastModifiedDate'
                    };
    }
}