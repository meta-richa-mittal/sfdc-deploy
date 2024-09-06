public without sharing class QBVendorPurchaseDTO {
    public String Id;
    public String SyncToken;
    public String DocNumber;  
    public Date TxnDate;
    public List<LineWrapper> Line;
    public QBInternalEntityWrapper VendorRef;
    public QBTxnTaxDetailWrapper TxnTaxDetail;
    public String GlobalTaxCalculation;
    
    public QBVendorPurchaseDTO(AccountingUnitPriceAndCost adjstmentRec) {
    	this.Id = adjstmentRec.JournalEntryAccountingId;
        this.SyncToken = adjstmentRec.JournalEntrySyncToken;
        
        this.DocNumber = adjstmentRec.VendorReferenceNumber; 
		if(String.isNotBlank(adjstmentRec.VendorReferenceNumber) && adjstmentRec.VendorReferenceNumber.length() > 21) {
			this.DocNumber = adjstmentRec.VendorReferenceNumber.substring(0, 21);
		}
        this.TxnDate = adjstmentRec.AdjustmentDate;
        this.Line = new List<LineWrapper>{new LineWrapper(adjstmentRec)};
        this.VendorRef = new QBInternalEntityWrapper(adjstmentRec.VendorAccountingId);

        if(adjstmentRec.ApplicableTaxId != null) {
            if(QBUtil.isQBTaxCodesEnabled) {
                this.GlobalTaxCalculation = QBUtil.TAX_EXCLUDED;
                this.TxnTaxDetail = new QBTxnTaxDetailWrapper(adjstmentRec.TaxAmount, adjstmentRec.taxDetailList); 
            } else {
                this.GlobalTaxCalculation = QBUtil.TAX_NOT_APPLICABLE;
                for(AccountingUnitPriceAndCost.TaxDetail taxRec : adjstmentRec.taxDetailList) {
                    this.Line.add(new LineWrapper(taxRec, adjstmentRec.TaxCategoryIncomeGL));
                }       
            }
        }
    }
    
    public class LineWrapper {
        public String Description;
        public Decimal Amount;
        public String DetailType;
        public AccountBasedExpenseLineDetailWrapper AccountBasedExpenseLineDetail;
        
        public LineWrapper(AccountingUnitPriceAndCost adjstmentRec) {
        	this.Description = '';
	    	this.Description += adjstmentRec.RefrenceNumber != null ? adjstmentRec.RefrenceNumber + ';' : '';
	    	this.Description += 'Unit Cost Adjustment;';
	    	this.Description += adjstmentRec.ItemDescription != null ? adjstmentRec.ItemDescription + ';' : '';
	    	this.Description += adjstmentRec.UnitId != null ? adjstmentRec.UnitId + ';' : '';
	    	this.Description += adjstmentRec.StockNumber != null ? adjstmentRec.StockNumber + ';' : '';
	    	this.Description += adjstmentRec.VIN != null ? adjstmentRec.VIN : '';
	    	
	    	this.Amount = adjstmentRec.TotalCost;
	    	if(this.Amount < 0) {
	    		this.Amount *= -1;
	    	}
	    	this.DetailType = 'AccountBasedExpenseLineDetail';
	    	String inventoryGLNumber;
            if(adjstmentRec.UnitStatus == 'Available' || adjstmentRec.UnitStatus == 'Reserved') {
                inventoryGLNumber = adjstmentRec.Unit_Inventory_GL;
            } else {
                inventoryGLNumber = adjstmentRec.Unit_COGS_GL;
            }
	    	this.AccountBasedExpenseLineDetail = new AccountBasedExpenseLineDetailWrapper(inventoryGLNumber, adjstmentRec.ApplicableTaxAccId);
        }

        public LineWrapper(AccountingUnitPriceAndCost.TaxDetail taxDetail, String categoryAccId) {
            this.Description = taxDetail.Name; 
            this.Amount = taxDetail.TaxAmount;
            if(this.Amount < 0) {
                this.Amount *= -1;
            }
            this.DetailType = 'AccountBasedExpenseLineDetail';        
            this.AccountBasedExpenseLineDetail = new AccountBasedExpenseLineDetailWrapper(taxDetail, categoryAccId);   
        }
    }
    
    public class AccountBasedExpenseLineDetailWrapper {
        public QBInternalEntityWrapper AccountRef;
        public QBInternalEntityWrapper TaxCodeRef; 
        
        public AccountBasedExpenseLineDetailWrapper(String accountRef, String taxCodeRefAccountingId)  {
             this.AccountRef = new QBInternalEntityWrapper(accountRef);
             if(QBUtil.isQBTaxCodesEnabled) {
                this.TaxCodeRef =  String.isNotBlank(taxCodeRefAccountingId) ? new QBInternalEntityWrapper(taxCodeRefAccountingId) : null; 
            }
        }

        public AccountBasedExpenseLineDetailWrapper(AccountingUnitPriceAndCost.TaxDetail taxDetail, String categoryAccId) {
            this.AccountRef = new QBInternalEntityWrapper(categoryAccId);
            if(QBUtil.isQBTaxCodesEnabled && taxDetail.AccountingId != null) {
              this.TaxCodeRef = new QBInternalEntityWrapper(taxDetail.AccountingId);
            }
        }
    }

     public class QBInternalEntityWrapper {
        public String value;
        public QBInternalEntityWrapper(String acctId) {
            this.value = acctId;
        }
     }
}