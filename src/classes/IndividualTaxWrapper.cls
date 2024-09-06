public without sharing class IndividualTaxWrapper {
    public String Id;
    public String SalesTaxItemName;
    public Decimal TaxRate;
    public Decimal EnhancedTaxAmount;
    
    public IndividualTaxWrapper(Individual_Tax__c individualTaxRec) {
        this.Id = individualTaxRec.Id;
        this.SalesTaxItemName = individualTaxRec.Sales_Tax_Item__r.Name__c;
        this.TaxRate = individualTaxRec.Tax_Rate__c;
        this.EnhancedTaxAmount = individualTaxRec.Enhanced_Tax_Amount__c != null ? individualTaxRec.Enhanced_Tax_Amount__c : 0.00;
    }
}