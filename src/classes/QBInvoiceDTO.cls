public class QBInvoiceDTO {
    
    public String Id;
    public String SyncToken;
    public String DocNumber;  
    public Date TxnDate;
    public List<LineWrapper> Line;
    public QBInnerEntityWrapper CustomerRef;
    public String GlobalTaxCalculation;
    public QBTxnTaxDetailWrapper TxnTaxDetail;
    public String PrivateNote;
  
    public QBInvoiceDTO(AccountingUnitPriceAndCost adjstmentRec) {
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
                   // this.GlobalTaxCalculation = 'TaxInclusive';
               // } else {
                    this.GlobalTaxCalculation = 'TaxExcluded';
                //}
                
                this.TxnTaxDetail = new QBTxnTaxDetailWrapper(adjstmentRec.TaxAmount, adjstmentRec.taxDetailList, adjstmentRec.ApplicableTaxId, false);

            } else {
                this.GlobalTaxCalculation = QBUtil.TAX_NOT_APPLICABLE;
                for(AccountingUnitPriceAndCost.TaxDetail taxRec : adjstmentRec.taxDetailList) {
                    this.Line.add(new LineWrapper(taxRec));
                }         
            }
        }   
    }
    
    public QBInvoiceDTO(SObject arcrTxnRec, String categoryAccId) {
        String objName = String.valueOf(arcrTxnRec.getSObjectType());
        if(objName == Constants.NAMESPACE + 'CO_Deposit__c') {
            setARCRDepositData((CO_Deposit__c)arcrTxnRec, categoryAccId);
        } else if(objName == Constants.NAMESPACE + 'CO_Invoice_Payment__c') {
            setARCRPaymentData((CO_Invoice_Payment__c)arcrTxnRec, categoryAccId);
        }
    }

    private void setARCRDepositData(CO_Deposit__c depositRec, String categoryAccId) {
        String arCreditNumber = getARCreditNumber(depositRec);
        this.DocNumber = arCreditNumber + '_USED';
        this.TxnDate = depositRec.Payment_Date__c;
        this.Line = new List<LineWrapper>();
        this.Line.add(new LineWrapper(depositRec, categoryAccId));
        this.GlobalTaxCalculation = QBUtil.TAX_NOT_APPLICABLE;
        this.CustomerRef = new QBInnerEntityWrapper(depositRec.CO_Header__r.Customer__r.AccountingId__c, null);
        this.PrivateNote = getPrivateNoteString(depositRec, depositRec.AR_Credit_Number__c) + depositRec.CO_Header__r.Name;
    }

    private void setARCRPaymentData(CO_Invoice_Payment__c coInvPaymentRec, String categoryAccId) {
        String arCreditNumber = getARCreditNumber(coInvPaymentRec);
        this.DocNumber = arCreditNumber + '_USED';
        this.TxnDate = coInvPaymentRec.Payment_Date__c;
        this.Line = new List<LineWrapper>();
        this.Line.add(new LineWrapper(coInvPaymentRec, categoryAccId));
        this.GlobalTaxCalculation = QBUtil.TAX_NOT_APPLICABLE;
        this.CustomerRef = new QBInnerEntityWrapper(coInvPaymentRec.CO_Invoice_Header__r.CO_Header__r.Customer__r.AccountingId__c, null);
        this.PrivateNote = getPrivateNoteString(coInvPaymentRec, coInvPaymentRec.AR_Credit_Number__c) + coInvPaymentRec.CO_Invoice_Header__r.CO_Header__r.Name;

    }

    private static string getARCreditNumber(SObject arcrTxnRec) {
        String arCreditNumber = '';
        if(arcrTxnRec.get(Constants.NAMESPACE + 'Unapplied_Payment_Type__c') == COInvoicePaymentService.AR_PAYMENT) {
            arCreditNumber = String.valueOf(arcrTxnRec.get('Name'));
        } else if(arcrTxnRec.get(Constants.NAMESPACE + 'AR_Credit_Number__c') != null) {
            arCreditNumber = String.valueOf(arcrTxnRec.get(Constants.NAMESPACE + 'AR_Credit_Number__c'));
        }
        return arCreditNumber;
    } 

    private static string getPrivateNoteString(SObject arcrTxnRec, String arCreditNumber) {
        if(String.isBlank(arCreditNumber)) {
            arCreditNumber = '';
        }
        String privateNote = '';
        String objName = String.valueOf(arcrTxnRec.getSObjectType());
        if(objName == Constants.NAMESPACE + 'CO_Deposit__c') {
            if(String.valueOf(arcrTxnRec.get(Constants.NAMESPACE + 'Unapplied_Payment_Type__c')) == COInvoicePaymentService.AR_PAYMENT) {
                privateNote = 'AR payment ' + arCreditNumber + ' used as deposit on ';
            } else {
                privateNote = 'AR credit ' + arCreditNumber + ' used as deposit on ';
            }
        } else if(objName == Constants.NAMESPACE + 'CO_Invoice_Payment__c') {
            if(String.valueOf(arcrTxnRec.get(Constants.NAMESPACE + 'Unapplied_Payment_Type__c')) == COInvoicePaymentService.AR_PAYMENT) {
                privateNote = 'AR payment ' + arCreditNumber + ' used on ';
            } else {
                privateNote = 'AR credit ' + arCreditNumber + ' used as payment on ';
            }
        }
        return privateNote;
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
            
            this.Amount = adjstmentRec.TotalCost*-1;
            this.DetailType = 'SalesItemLineDetail';
            this.SalesItemLineDetail = new SaleItemLineDetailWrapper(adjstmentRec);
        }  

        public LineWrapper(AccountingUnitPriceAndCost.TaxDetail taxDetail) {
            this.Description = taxDetail.Name; 
            this.Amount = taxDetail.TaxAmount;
            if(this.Amount < 0) {
                this.Amount *= -1;
            }
            this.DetailType = 'SalesItemLineDetail';        
            this.SalesItemLineDetail = new SaleItemLineDetailWrapper(taxDetail);   
        }

        public LineWrapper(CO_Invoice_Payment__c coInvPaymentRec, String categoryAccId) {
            this.Description = getPrivateNoteString(coInvPaymentRec, coInvPaymentRec.AR_Credit_Number__c) + coInvPaymentRec.CO_Invoice_Header__r.CO_Header__r.Name;
            this.Amount = coInvPaymentRec.Amount__c != null ? coInvPaymentRec.Amount__c : 0;
            this.DetailType = 'SalesItemLineDetail';        
            this.SalesItemLineDetail = new SaleItemLineDetailWrapper(coInvPaymentRec, categoryAccId);   
        }

        public LineWrapper(CO_Deposit__c coDepositRec, String categoryAccId) {
            this.Description = getPrivateNoteString(coDepositRec, coDepositRec.AR_Credit_Number__c) + coDepositRec.CO_Header__r.Name;
            this.Amount = coDepositRec.Amount__c != null ? coDepositRec.Amount__c : 0;
            this.DetailType = 'SalesItemLineDetail';        
            this.SalesItemLineDetail = new SaleItemLineDetailWrapper(coDepositRec, categoryAccId);   
        }
        
    }

    public class SaleItemLineDetailWrapper {
    	public Decimal UnitPrice;
        public Decimal Qty;
        public QBInnerEntityWrapper ItemRef;
        public QBInnerEntityWrapper TaxCodeRef;

        public SaleItemLineDetailWrapper(AccountingUnitPriceAndCost adjstmentRec) {
            this.UnitPrice = adjstmentRec.TotalCost*-1;
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

        public SaleItemLineDetailWrapper(CO_Invoice_Payment__c coInvPaymentRec, String categoryAccId) {
            this.UnitPrice = coInvPaymentRec.Amount__c != null ? coInvPaymentRec.Amount__c : 0;
        	this.Qty = 1;
            this.ItemRef = new QBInnerEntityWrapper(categoryAccId, null);
        }

        public SaleItemLineDetailWrapper(CO_Deposit__c coDepositRec, String categoryAccId) {
            this.UnitPrice = coDepositRec.Amount__c != null ? coDepositRec.Amount__c : 0;
        	this.Qty = 1;
            this.ItemRef = new QBInnerEntityWrapper(categoryAccId, null);
        }
    }
    
}