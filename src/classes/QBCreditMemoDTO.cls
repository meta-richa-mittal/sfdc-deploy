public without sharing class QBCreditMemoDTO {
    public String Id;
    public String SyncToken;
    public String DocNumber;  
    public Date TxnDate;
    public List<LineWrapper> Line;
    public QBInnerEntityWrapper CustomerRef;
    public Decimal TotalAmt;
    public String PrintStatus;
    public String GlobalTaxCalculation;
    public Decimal Balance;
    public String PrivateNote;
    public QBTxnTaxDetailWrapper TxnTaxDetail;

    public QBCreditMemoDTO(AccountingUnitPriceAndCost adjstmentRec) {
        this.Id = adjstmentRec.JournalEntryAccountingId;
        this.SyncToken = adjstmentRec.JournalEntrySyncToken;
        
        this.DocNumber = adjstmentRec.CustomerReferenceNumber; 
		if(String.isNotBlank(adjstmentRec.CustomerReferenceNumber) && adjstmentRec.CustomerReferenceNumber.length() > 21) {
			this.DocNumber = adjstmentRec.CustomerReferenceNumber.substring(0, 21);
		}
        this.TxnDate = adjstmentRec.AdjustmentDate;
        this.Line = new List<LineWrapper>();
        this.Line.add(new LineWrapper(adjstmentRec));
        this.CustomerRef = new QBInnerEntityWrapper(adjstmentRec.CustomerAccountingId, null);

        if(adjstmentRec.ApplicableTaxId != null) {
            
            Boolean isTaxIncludingPricing = GeneralConfiguration.getTaxIncludingPricing();
            if(QBUtil.isQBTaxCodesEnabled) {
                //if(isTaxIncludingPricing) {
                   //this.GlobalTaxCalculation = 'TaxInclusive';
               // } else {
                    this.GlobalTaxCalculation = 'TaxExcluded';
                ///}
                
               this.TxnTaxDetail = new QBTxnTaxDetailWrapper(adjstmentRec.TaxAmount, adjstmentRec.taxDetailList, adjstmentRec.ApplicableTaxId, false);

            } else {
                this.GlobalTaxCalculation = QBUtil.TAX_NOT_APPLICABLE;
                for(AccountingUnitPriceAndCost.TaxDetail taxRec : adjstmentRec.taxDetailList) {
                    this.Line.add(new LineWrapper(taxRec));
                }           
            }
        }
    }
    
    public QBCreditMemoDTO(AccountingUnit consUnitRecord) {
        this.Id = consUnitRecord.QBConsAccountingId;
        this.SyncToken = consUnitRecord.SyncTokenForCons;
        this.DocNumber = consUnitRecord.InvoiceNumber.replace('INV', 'CONS'); 
        String invoiceDate = DateTimeUtility.getFormttedDateFromDateTime(consUnitRecord.UnitInvoiceDate, 'dd/MM/yyyy');
        this.TxnDate = DateTimeUtility.getDateFromFormattedDateStr(invoiceDate);
        this.Line = new List<LineWrapper>();
        this.Line.add(new LineWrapper(consUnitRecord));
        this.TotalAmt = this.Balance = consUnitRecord.AgreedPayout;
        this.GlobalTaxCalculation = QBUtil.TAX_NOT_APPLICABLE;
        this.CustomerRef = new QBInnerEntityWrapper(consUnitRecord.QBCustomerAccId, null);
        this.PrintStatus = 'PrintComplete';
        this.PrivateNote = 'Consignment payout:' + (String.isNotBlank(consUnitRecord.VIN) ? (' ' + consUnitRecord.VIN) : '');
    }
    
    public class LineWrapper {
        public String Description;
        public Decimal Amount;
        public String DetailType;
        public SaleItemLineDetailWrapper SalesItemLineDetail;

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
	    	this.DetailType = 'SalesItemLineDetail';
            this.SalesItemLineDetail = new SaleItemLineDetailWrapper(adjstmentRec);

        }
        
        public LineWrapper(AccountingUnit consUnitRecord) {
            this.Description = 'Consignment payout:' + (String.isNotBlank(consUnitRecord.VIN) ? (' ' + consUnitRecord.VIN) : '');
            this.Amount = consUnitRecord.AgreedPayout;
            this.DetailType = 'SalesItemLineDetail';
            this.SalesItemLineDetail = new SaleItemLineDetailWrapper(consUnitRecord);   
        }

        public LineWrapper(AccountingUnitPriceAndCost.TaxDetail taxDetail) {
            this.Description = taxDetail.Name; 
            this.Amount = taxDetail.TaxAmount;
            this.DetailType = 'SalesItemLineDetail';        
            this.SalesItemLineDetail = new SaleItemLineDetailWrapper(taxDetail);   
        }
    }

    public class SaleItemLineDetailWrapper {
    	public Decimal UnitPrice;
        public Decimal Qty;
        public QBInnerEntityWrapper ItemRef;
        public QBInnerEntityWrapper TaxCodeRef;

        public SaleItemLineDetailWrapper(AccountingUnit consUnitRecord)  {
        	this.UnitPrice = consUnitRecord.AgreedPayout;
        	this.Qty = 1;
        	
        	List<Category__c> consignmentCategory = [select AccountingId__c from Category__c
		            									where Type__c = :Constants.CATEGORY_TYPE_CONSIGNMENT_CLEARING 
		            									AND Active__c = true AND Default__c = true]; 
	    	if(consignmentCategory.size() > 0 && String.isNotBlank(consignmentCategory[0].AccountingId__c)) {
	    		this.ItemRef = new QBInnerEntityWrapper(consignmentCategory[0].AccountingId__c, null);
	    	}
            
        }

        public SaleItemLineDetailWrapper(AccountingUnitPriceAndCost adjstmentRec) {
            this.UnitPrice = adjstmentRec.TotalCost;
        	this.Qty = 1;
            if(adjstmentRec.CategoryAccId != null) {
                this.ItemRef = new QBInnerEntityWrapper(adjstmentRec.CategoryAccId, null);
            }
            if(QBUtil.isQBTaxCodesEnabled) {
                String taxCodeAccountingId = adjstmentRec.ApplicableTaxAccId != null ? adjstmentRec.ApplicableTaxAccId : QBUtil.nonTaxableCodeAccId;
                this.TaxCodeRef = new QBInnerEntityWrapper(taxCodeAccountingId, '');
            }
        }

        public SaleItemLineDetailWrapper(AccountingUnitPriceAndCost.TaxDetail taxDetail) {
            if(taxDetail.AccountingId != null) {
                this.ItemRef = new QBInnerEntityWrapper(taxDetail.AccountingId, null);
            }
        }
    }

    
}