/**
 * Author: Richa Mittal
 * Since: Dec 15, 2017
 * Name: AccountingUnitPriceAndCost
 * Description: Apex class to handle JSON related oprations of unit price and cost for Accounting.
**/
public without sharing class AccountingUnitPriceAndCost {
    
    public String Id;
    public String RefrenceNumber;
    public String UnitId;
    public String StockNumber;
    public String UnitStatus;
    
    public String VendorId;
    public String VendorAccountingId;
    public String VendorReferenceNumber;

    public String CustomerId;
    public String CustomerAccountingId;
    public String CustomerReferenceNumber;
    
    public String Type;
    public String Unit_Inventory_GL;
    public String Unit_COGS_GL;
    public String Unit_Adjustment_Income_GL;
    public Decimal TotalCost;
    public Decimal Qty;
    public Date CreatedDate;
    public Date AdjustmentDate;
    public Date DueDate;
    
    public EntityRefWrapper EntityRef;
	public String JournalEntryAccountingId;
    public String JournalEntrySyncToken;
    public String JournalEntryAccountingResponse;
    
    public String XeroAccountingId;
    public String ItemDescription;
    public String CustomerOwnedUnitId;
   	public String VIN;

    public String ApplicableTaxId; 
    public String CategoryAccId;  
    public Decimal TaxAmount;
    public List<TaxDetail> taxDetailList;
    public String ApplicableTaxAccId;
    public String TaxCategoryIncomeGL;

    
    // Constructor
    public AccountingUnitPriceAndCost(Unit_Price_Cost__c adjstmentRec) {
    	this.Id = adjstmentRec.Id;
        this.RefrenceNumber = adjstmentRec.Ref_No__c;
        this.UnitId = adjstmentRec.Customer_Owned_Unit__r.Unit_Id__c;
        this.StockNumber = adjstmentRec.Customer_Owned_Unit__r.Stock_Id__c;
        this.UnitStatus = adjstmentRec.Customer_Owned_Unit__r.Status__c;
        this.Type = adjstmentRec.Type__c;
        this.Unit_Inventory_GL = adjstmentRec.Customer_Owned_Unit__r.Category__r.Inventory_GL__c;
        this.Unit_COGS_GL = adjstmentRec.Customer_Owned_Unit__r.Category__r.COGS_GL__c;
        this.Unit_Adjustment_Income_GL = adjstmentRec.Category__r.Income_GL__c;
        this.TotalCost = adjstmentRec.Total_Cost__c;
        this.Qty = adjstmentRec.Qty__c;
        this.CreatedDate = adjstmentRec.CreatedDate.Date();
		this.AdjustmentDate = (adjstmentRec.Adjustment_Date__c != null) ? 
											Date.newInstance(adjstmentRec.Adjustment_Date__c.year(), adjstmentRec.Adjustment_Date__c.month(), adjstmentRec.Adjustment_Date__c.day()) : this.CreatedDate;
        if(String.isNotBlank(adjstmentRec.Vendor__c)) {
        	this.VendorId = adjstmentRec.Vendor__c;
        	this.VendorAccountingId = (adjstmentRec.Vendor__r.Vendor_AccountingId__c != null ? adjstmentRec.Vendor__r.Vendor_AccountingId__c : 
        				adjstmentRec.Vendor__r.Xero_Vendor_Accounting_Id__c);
        	this.VendorReferenceNumber = adjstmentRec.Vendor_Reference_Number__c;        
        }

        if(String.isNotBlank(adjstmentRec.Customer__c)) {
        	this.CustomerId = adjstmentRec.Customer__c;
        	this.CustomerAccountingId = (adjstmentRec.Customer__r.AccountingId__c != null ? adjstmentRec.Customer__r.AccountingId__c : 
        				adjstmentRec.Customer__r.Xero_Customer_Accounting_Id__c);
        	this.CustomerReferenceNumber = adjstmentRec.Customer_Reference_Number__c;        
        }
        
        this.EntityRef = new EntityRefWrapper(adjstmentRec.Customer_Owned_Unit__r.Referenced_Unit__r.Vendor__r.Vendor_AccountingId__c, adjstmentRec.Customer_Owned_Unit__r.Referenced_Unit__r.Vendor__r.Name);
        this.JournalEntryAccountingId = adjstmentRec.AccountingId__c;
        this.JournalEntrySyncToken = adjstmentRec.SyncToken__c;
        this.JournalEntryAccountingResponse = adjstmentRec.AccountingResponse__c;
        this.XeroAccountingId = adjstmentRec.Xero_Accounting_Id__c ;
        this.ItemDescription = adjstmentRec.Item_Description__c;
        this.CustomerOwnedUnitID = adjstmentRec.Customer_Owned_Unit__r.Id;
        this.VIN = adjstmentRec.Customer_Owned_Unit__r.VIN_Number__c;

        this.ApplicableTaxId = adjstmentRec.Applicable_Tax__c;
        this.CategoryAccId = adjstmentRec.Category__r.AccountingId__c;
        this.TaxAmount = adjstmentRec.Tax_Amount__c;

        this.taxDetailList =  getSalesTaxItemList(this.ApplicableTaxId);
        this.ApplicableTaxAccId = adjstmentRec.Applicable_Tax__r.Accounting_Id__c;
    }     


    private List<TaxDetail> getSalesTaxItemList(String applicableTaxId) {
        List<TaxDetail> taxDetails = new List<TaxDetail>();
        Decimal taxAmount;
        List<Applicable_Taxes__c> applicableTaxList = [Select id, Sales_Tax_Item__c from Applicable_Taxes__c where Sales_Tax__c = :applicableTaxId];
        set<Id> salesTaxitemIds = new set<Id>();
        for(Applicable_Taxes__c tax : applicableTaxList) {
            salesTaxitemIds.add(tax.Sales_Tax_Item__c);
        }
        List<Sales_Tax_Item__c> salesTaxItemList = [select Id, Name__c, Rate__c, AccountingId__c, Category__r.AccountingId__c, Category__r.Name,
             Category__r.Income_GL__c from Sales_Tax_Item__c where Active__c = true And Id In :salesTaxitemIds];

        for(Sales_Tax_Item__c STI : salesTaxItemList) {
            if(STI.Rate__c !=  null) {
                taxAmount = STI.Rate__c * this.TotalCost / 100;
            } else {
                taxAmount = 0;
            }
            if(QBUtil.isQBTaxCodesEnabled) {
                taxDetails.add(new TaxDetail(STI.Id, STI.Name__c, taxAmount, this.TotalCost, STI.AccountingId__c));
            } else {
                String accountingId;
            	if(QBUtil.isQBEnabled()) {
            		accountingId = STI.Category__r.AccountingId__c;
            	} else {
            		accountingId = STI.Category__r.Income_GL__c;
            	}
                taxDetails.add(new TaxDetail(STI.Id, STI.Name__c, taxAmount, this.TotalCost, accountingId));
            }
            this.TaxCategoryIncomeGL = STI.Category__r.Income_GL__c;                            
        }    
        return taxDetails;
    }
    
  
    /**
     * Name: fieldsList
     * Desc: Method Which contains all the field list to be quried
     * @param:  
     * @return: List<String> - Fields List
    **/
    public static List<String> fieldsList(){
        List<String> UnitPriceAndCOstFields = new List<String>{ 'Id',
                            'Name',
                            'Vendor__c', 
                            'Vendor_Reference_Number__c',
                            'Vendor__r.Vendor_AccountingId__c',
                            'Vendor__r.Xero_Vendor_Accounting_Id__c',
                            'Customer_Owned_Unit__r.Unit_Id__c',
                            'Customer_Owned_Unit__r.Category__r.Inventory_GL__c',
                            'Customer_Owned_Unit__r.Category__r.COGS_GL__c',
                            'Category__r.Income_GL__c',
                            'Customer_Owned_Unit__r.Stock_Id__c',
                            'Customer_Owned_Unit__r.Status__c',
            				'Type__c',
                            'Cost__c',
                            'Total_Cost__c',
                            'CreatedDate',
                            'Adjustment_Date__c',
                            'Ref_No__c',
                            'Qty__c',
                            'Customer_Owned_Unit__r.Referenced_Unit__r.Vendor__c',
                            'Customer_Owned_Unit__r.Referenced_Unit__r.Vendor__r.Vendor_AccountingId__c',
                            'Customer_Owned_Unit__r.Referenced_Unit__r.Vendor__r.Name',
                            'AccountingResponse__c',
                            'AccountingId__c',
                            'SyncToken__c',
                            'Xero_Accounting_Id__c',
                            'Item_Description__c',
                            'Customer_Owned_Unit__r.Id',
                            'Customer_Owned_Unit__r.VIN_Number__c',
                            'Customer__c',
                            'Customer_Reference_Number__c',
                            'Customer__r.AccountingId__c',
                            'Customer__r.Xero_Customer_Accounting_Id__c',
                            'Applicable_Tax__c',
                            'Category__r.AccountingId__c',
                            'Tax_Amount__c',
                            'Applicable_Tax__r.Accounting_Id__c'
                           };
        return UnitPriceAndCOstFields;
    }
    
    public class EntityRefWrapper{
        public String AccountingId;
        public String Name;
        
        public EntityRefWrapper(String AccountingId, String Name) {
            this.AccountingId = AccountingId;
            this.Name = Name;
        }
    }

    public class TaxDetail {
        public String Id;
        public String Name;
        public Decimal TaxAmount;
        public Decimal TaxableAmount;
        public String AccountingId;
    
        public TaxDetail(String id, String name, Decimal taxAmount, Decimal taxableAmount, String accountingId) {
            this.Id = id;
            this.Name = name;
            this.TaxAmount = (taxAmount != null) ? taxAmount : 0;
            this.TaxableAmount = taxableAmount;
            this.AccountingId = accountingId;
        }
    }
    
}