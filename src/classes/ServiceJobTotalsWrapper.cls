public without sharing class ServiceJobTotalsWrapper {
    
    public SOHeaderWrapper.SOHeader SOHeaderInfo;
	public SOHeaderWrapper.SOReview SOReviewInfo;
    public List<SOHeaderWrapper.SOGrid> SOGridItems;
    public Decimal Total_Part;
    public Decimal Total_Laobur;
    public Decimal Total_Sublet;
    public Decimal Total_Other;
    public Decimal Total_ShopSupplies;
    public Decimal Total;
    public Decimal SalesTax;		
    public Decimal Deductible;
    public Decimal FinalTotal;
    public List<IndividualTax> SalesTaxList;
    public Boolean IsTaxIncludingPricing;

    public ServiceJobTotalsWrapper(Service_Order_Header__c soHeaderRec, List<Service_Order_Kit_Header__c> soKitHeaderList, Map<String, Decimal> salesTaxNameToTaxValue) {
        this.SOGridItems = new List<SOHeaderWrapper.SOGrid>();
        this.SOHeaderInfo = new SOHeaderWrapper.SOHeader(soHeaderRec);
        this.SOReviewInfo = new SOHeaderWrapper.SOReview(soHeaderRec);
        this.Total_Part = 0;
        this.Total_Laobur = 0;
        this.Total_Sublet = 0;
        this.Total_Other = 0;
        this.Total_ShopSupplies = 0;
        this.Total = 0;
        this.SalesTax = 0;		
        this.SalesTaxList = new List<IndividualTax>();		
        this.IsTaxIncludingPricing = GeneralConfiguration.getTaxIncludingPricing();
        Set<Id> soliIdSet = new Set<Id>();
        
        for(Service_Order_Kit_Header__c soKHRec : soKitHeaderList) {
            this.SOGridItems.add(new SOHeaderWrapper.SOGrid(soKHRec, soKHRec.Service_Order_Line_Items__r, true));
            for(Service_Order_Line_Item__c soliRec : sokhRec.Service_Order_Line_Items__r) {
                soliIdSet.add(soliRec.Id);
            }
        }
        for(Service_Order_Line_Item__c soliRec : soHeaderRec.Service_Order_Line_Items__r) {
            if(!soliIdSet.contains(soliRec.Id)) {
                this.SOGridItems.add(new SOHeaderWrapper.SOGrid(new Service_Order_Kit_Header__c(), new List<Service_Order_Line_Item__c>{soliRec}, false));
            }
        } 
        
        this.Total_Part = (soHeaderRec.Total_Parts__c != null) ? soHeaderRec.Total_Parts__c.setScale(2, RoundingMode.HALF_UP) : 0;
        this.Total_Other = (soHeaderRec.Total_Fees__c != null) ? soHeaderRec.Total_Fees__c.setScale(2, RoundingMode.HALF_UP) : 0;
        this.Total_Laobur = (soHeaderRec.Total_Labor__c != null) ? soHeaderRec.Total_Labor__c.setScale(2, RoundingMode.HALF_UP) : 0;
        this.Total_Sublet = (soHeaderRec.Total_Sublet__c != null) ? soHeaderRec.Total_Sublet__c.setScale(2, RoundingMode.HALF_UP) : 0;
        this.Total_ShopSupplies = (soHeaderRec.Total_Shop_Supplies__c != null) ? soHeaderRec.Total_Shop_Supplies__c.setScale(2, RoundingMode.HALF_UP) : 0;
        
        this.Total = this.Total_Part + this.Total_Laobur + this.Total_Sublet + this.Total_Other + this.Total_ShopSupplies;
        
        this.Deductible = 0;
        for(SO_Payment_Role__c deductibleRec : soHeaderRec.SO_Payment_Roles__r) {
            if(deductibleRec.RecordType.DeveloperName == 'Deductible') {
                this.Deductible += deductibleRec.Total_Amount__c;
            }
        }	
        
        for(String taxName : salesTaxNameToTaxValue.keySet()){
            this.SalesTaxList.add(new IndividualTax(TaxEngine.getAutoDistTaxLabelFromIndTax(taxName), salesTaxNameToTaxValue.get(taxName)));
            this.SalesTax += salesTaxNameToTaxValue.get(taxName);
        }
        
        this.FinalTotal = this.Total - this.Deductible;
        if(!isTaxIncludingPricing) {
            this.FinalTotal += this.SalesTax;
        }
    }

    public class IndividualTax {		
    	public String TaxName;		
    	public Decimal TaxValue;		
    			
    	public IndividualTax(String taxName, Decimal taxValue) {		
    		this.TaxName = taxName;		
    		this.TaxValue = (taxValue != null) ? taxValue.setScale(2, RoundingMode.HALF_UP) : 0;		
    	}		
    }
}