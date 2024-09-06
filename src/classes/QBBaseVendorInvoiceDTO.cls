public without sharing abstract class QBBaseVendorInvoiceDTO {
    public String Id;
    public String SyncToken;
    public String DocNumber;  
    public Date TxnDate;
    public List<LineWrapper> Line;
    public VendorRefWrapper VendorRef;
    public AccountRefWrapper APAccountRef;
    public QBTxnTaxDetailWrapper TxnTaxDetail;
    public Decimal TotalAmt;
    public Decimal Balance;
    public String GlobalTaxCalculation;
    public String PrivateNote;
    
    public QBBaseVendorInvoiceDTO() {}

    public QBBaseVendorInvoiceDTO(AccountingUnitPriceAndCost adjstmentRec) {
    	this.Id = adjstmentRec.JournalEntryAccountingId;
        this.SyncToken = adjstmentRec.JournalEntrySyncToken;
        
        this.DocNumber = adjstmentRec.VendorReferenceNumber; 
		if(String.isNotBlank(adjstmentRec.VendorReferenceNumber) && adjstmentRec.VendorReferenceNumber.length() > 21) {
			this.DocNumber = adjstmentRec.VendorReferenceNumber.substring(0, 21);
		}
        this.TxnDate = adjstmentRec.AdjustmentDate;
        this.Line = new List<LineWrapper>{new LineWrapper(adjstmentRec)};
        this.VendorRef = new VendorRefWrapper(adjstmentRec.VendorAccountingId);

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
    
    public QBBaseVendorInvoiceDTO(AccountingVendorInvoice vendorInvoiceRecord) {
        this.Id = vendorInvoiceRecord.AccountingVIHeaderRec.AccountingId;
        this.SyncToken = vendorInvoiceRecord.AccountingVIHeaderRec.SyncToken;
        this.DocNumber = vendorInvoiceRecord.AccountingVIHeaderRec.InvoiceNumber; 
        this.TxnDate = (vendorInvoiceRecord.AccountingVIHeaderRec.InvoiceDate != null) ? vendorInvoiceRecord.AccountingVIHeaderRec.InvoiceDate :
                                vendorInvoiceRecord.AccountingVIHeaderRec.CreatedDate;
        this.Line = new List<LineWrapper>();
            
        String description = vendorInvoiceRecord.AccountingVIHeaderRec.VIHeaderNumber + ';' + vendorInvoiceRecord.AccountingVIHeaderRec.VendorName + ';' +
	    						vendorInvoiceRecord.AccountingVIHeaderRec.InvoiceNumber + ';';
	    String VRNumberFoDesc = vendorInvoiceRecord.VRNumberSet.size() == 1 ? new List<String>(vendorInvoiceRecord.VRNumberSet)[0] + ';' : '';
	    for(AccountingVendorInvoice.AccountingVIGroupByGLAndType accVIGRec: vendorInvoiceRecord.AccountingVIGroupByGLAndTypeList) {
	    	if(QBUtil.isQBTaxCodesEnabled) {
                this.Line.add(new LineWrapper((VRNumberFoDesc + description + accVIGRec.Type), accVIGRec.Total, accVIGRec.GLNumber, accVIGRec.TaxCodeAccId));
            } else {
                this.Line.add(new LineWrapper((VRNumberFoDesc + description + accVIGRec.Type), accVIGRec.Total, accVIGRec.GLNumber));
            }
        }
        
        Decimal totalTaxAmount = vendorInvoiceRecord.AccountingVIHeaderRec.TotalPartSubtotal != null ? vendorInvoiceRecord.AccountingVIHeaderRec.TotalPartSubtotal : 0;
        if(QBUtil.isQBTaxCodesEnabled) {
            for(AccountingVendorInvoice.OtherChargesWrapper otherChargesRec : vendorInvoiceRecord.AccountingOtherChargesList) {
                if(otherChargesRec.IsTaxable) {
                   totalTaxAmount += otherChargesRec.Cost != null ? otherChargesRec.Cost : 0;
                   this.Line.add(new LineWrapper(description + 'Other Charge - ' + otherChargesRec.ItemDesc, otherChargesRec.Cost, otherChargesRec.CategoyRef, vendorInvoiceRecord.AppliedQBTaxCode)); 
                } else {
                    VendorInvoiceService.isSyncRecordContainsNonTaxableItem = true;
                    this.Line.add(new LineWrapper(description + 'Other Charge - ' + otherChargesRec.ItemDesc, otherChargesRec.Cost, otherChargesRec.CategoyRef, QBUtil.nonTaxableCodeAccId));
                }
                
            }
        } else {
            for(AccountingVendorInvoice.OtherChargesWrapper otherChargesRec : vendorInvoiceRecord.AccountingOtherChargesList) {
            	if(otherChargesRec.IsTaxable) {
            		totalTaxAmount += otherChargesRec.Cost != null ? otherChargesRec.Cost : 0; // Required while sending taxes as line items below
            	}
                this.Line.add(new LineWrapper(description + 'Other Charge - ' + otherChargesRec.ItemDesc, otherChargesRec.Cost, otherChargesRec.CategoyRef));
            }
        }
        this.VendorRef = new VendorRefWrapper(vendorInvoiceRecord.vendor);
        this.TotalAmt = this.Balance = vendorInvoiceRecord.AccountingVIHeaderRec.TotalAmt;
        AccountingVendorInvoice.AccountingPurchaseTax purchaseTax;
        if(QBUtil.isQBTaxCodesEnabled) {
            this.GlobalTaxCalculation = QBUtil.TAX_EXCLUDED;
            Decimal totalTax = ((totalTaxAmount * vendorInvoiceRecord.AppliedTaxRate)/100).setScale(2, RoundingMode.HALF_UP);
            List<AccountingVendorInvoice.TaxRateComponent> taxComponentList = new List<AccountingVendorInvoice.TaxRateComponent>();
            if(vendorInvoiceRecord.AccountingPurchaseTaxList.size() > 0) {
                for(Integer i = 0; i < vendorInvoiceRecord.AccountingPurchaseTaxList.size(); i++) {
                    purchaseTax = vendorInvoiceRecord.AccountingPurchaseTaxList[i];
                    Decimal taxAmount = ((purchaseTax.SalesTaxRate * totalTaxAmount / 100).setScale(2, RoundingMode.HALF_UP));
                    Decimal taxableAmount = totalTaxAmount;
                    Decimal taxPercent = purchaseTax.SalesTaxRate;
                    String purchaseTaxRateAcctId = purchaseTax.QBTaxCodeRef;
                    taxComponentList.add(new AccountingVendorInvoice.TaxRateComponent(taxAmount, taxableAmount, purchaseTaxRateAcctId, taxPercent));
                }
            } else if(vendorInvoiceRecord.AppliedTaxRate == 0 && String.isNotBlank(vendorInvoiceRecord.AppliedQBTaxCode)) {
                if(AccessControl.ifObjectFieldIsAccessible('QB_TaxCode__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
                List<QB_TaxCode__c> taxCodeList = [SELECT Applicable_QB_Tax_Rates__c FROM QB_TaxCode__c WHERE Accounting_Id__c = :vendorInvoiceRecord.AppliedQBTaxCode AND Tax_Applicable_On__c =: QBUtil.PURCHASE];
                if(taxCodeList.size() > 0  && String.isNotBlank(taxCodeList[0].Applicable_QB_Tax_Rates__c)) {
                    List<String> taxRateAccIdList = taxCodeList[0].Applicable_QB_Tax_Rates__c.split(';');
                    for(String taxRateAccId : taxRateAccIdList) {
                        taxComponentList.add(new AccountingVendorInvoice.TaxRateComponent(0, 0, taxRateAccId, 0));
                    }
                }
            }
            if(VendorInvoiceService.isSyncRecordContainsNonTaxableItem) {
                Map<String, List<String>> nonTaxCodeToRatesMap = QBUtil.getNonTaxableTaxCodeWithRates(QBUtil.PURCHASE);
                if(nonTaxCodeToRatesMap.containsKey(QBUtil.nonTaxableCodeAccId)) {
                    for(String acctId : nonTaxCodeToRatesMap.get(QBUtil.nonTaxableCodeAccId)) {
                        taxComponentList.add(new AccountingVendorInvoice.TaxRateComponent(0, 0, acctId, 0));
                    }
                }
            }
            this.TxnTaxDetail = new QBTxnTaxDetailWrapper(totalTax, taxComponentList);  
        } else {
            Decimal taxValue = 0;
            String categoryRef = '';
            this.GlobalTaxCalculation = QBUtil.TAX_NOT_APPLICABLE;
            if(vendorInvoiceRecord.AccountingPurchaseTaxList.size() > 0) {
                for(Integer i = 0; i < vendorInvoiceRecord.AccountingPurchaseTaxList.size(); i++) {
                    purchaseTax = vendorInvoiceRecord.AccountingPurchaseTaxList[i];
                    Decimal taxAmount = ((purchaseTax.SalesTaxRate * totalTaxAmount / 100).setScale(2, RoundingMode.HALF_UP));
                    categoryRef = purchaseTax.CategoyRef != null ? purchaseTax.CategoyRef : AccountingUtil.getChartofAccount('Sales Tax');
                    this.Line.add(new LineWrapper('Purchase Tax - ' + purchaseTax.SalesTaxName, taxAmount, categoryRef));
                }
            }
        }
        this.PrivateNote = String.join(new List<String>(vendorInvoiceRecord.VRNumberSet), ';') + ';' + description + 'Vendor invoice';
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
	    	this.AccountBasedExpenseLineDetail = new AccountBasedExpenseLineDetailWrapper(inventoryGLNumber,adjstmentRec.ApplicableTaxAccId);
        }
      
        public LineWrapper(AccountingVendorInvoice.AccountingVIGroup VIGroupRec, AccountingVendorInvoice.AccountRefWrapper AccountRef) {
            this.Description = VIGroupRec.ItemDesc + ' ' + VIGroupRec.InvoiceTotalQty + '@$' + VIGroupRec.InvoiceCost;
            this.Amount = (VIGroupRec.InvoiceTotalQty * (VIGroupRec.InvoiceCost * (1 - (VIGroupRec.Discount / 100 ))).setScale(2, RoundingMode.HALF_UP));
            if(VendorInvoiceService.syncingObjectType == QBUtil.VENDOR_CREDIT) {
            	this.Amount *= -1;
            }
            this.DetailType = 'AccountBasedExpenseLineDetail';    
            this.AccountBasedExpenseLineDetail = new AccountBasedExpenseLineDetailWrapper(AccountRef);   
        }
        
        public LineWrapper(String Description, Decimal Amount, AccountingVendorInvoice.AccountRefWrapper AccountRef) {
            this.Description = Description;
            this.Amount = Amount;
            if(VendorInvoiceService.syncingObjectType == QBUtil.VENDOR_CREDIT) {
            	this.Amount *= -1;
            }
            this.DetailType = 'AccountBasedExpenseLineDetail';
            this.AccountBasedExpenseLineDetail = new AccountBasedExpenseLineDetailWrapper(AccountRef);   
        }
         public LineWrapper(AccountingVendorInvoice.AccountingVIGroup VIGroupRec, AccountingVendorInvoice.AccountRefWrapper AccountRef, String taxCodeRefAccountingId) {
            this.Description = VIGroupRec.ItemDesc + ' ' + VIGroupRec.InvoiceTotalQty + '@$' + VIGroupRec.InvoiceCost;
            this.Amount = (VIGroupRec.InvoiceTotalQty * (VIGroupRec.InvoiceCost * (1 - (VIGroupRec.Discount / 100 ))).setScale(2, RoundingMode.HALF_UP));
            if(VendorInvoiceService.syncingObjectType == QBUtil.VENDOR_CREDIT) {
            	this.Amount *= -1;
            }
            this.DetailType = 'AccountBasedExpenseLineDetail';    
            this.AccountBasedExpenseLineDetail = new AccountBasedExpenseLineDetailWrapper(AccountRef, taxCodeRefAccountingId);   
        }
        
        public LineWrapper(String Description, Decimal Amount, AccountingVendorInvoice.AccountRefWrapper AccountRef, String taxCodeRefAccountingId) {
            this.Description = Description;
            this.Amount = Amount;
            if(VendorInvoiceService.syncingObjectType == QBUtil.VENDOR_CREDIT) {
            	this.Amount *= -1;
            }
            this.DetailType = 'AccountBasedExpenseLineDetail';
            this.AccountBasedExpenseLineDetail = new AccountBasedExpenseLineDetailWrapper(AccountRef, taxCodeRefAccountingId);   
        }
         public LineWrapper(String Description, Decimal Amount, String CategoryAccountRef) {
            this.Description = Description; 
            this.Amount = Amount;
            if(VendorInvoiceService.syncingObjectType == QBUtil.VENDOR_CREDIT) {
            	this.Amount *= -1;
            }
            this.DetailType = 'AccountBasedExpenseLineDetail';
            this.AccountBasedExpenseLineDetail = new AccountBasedExpenseLineDetailWrapper(CategoryAccountRef);   
        }
        public LineWrapper(String Description, Decimal Amount, String CategoryAccountRef, String taxCodeRefAccountingId) {
            this.Description = Description; 
            this.Amount = Amount;
            if(VendorInvoiceService.syncingObjectType == QBUtil.VENDOR_CREDIT) {
            	this.Amount *= -1;
            }
            this.DetailType = 'AccountBasedExpenseLineDetail';
            this.AccountBasedExpenseLineDetail = new AccountBasedExpenseLineDetailWrapper(CategoryAccountRef, taxCodeRefAccountingId);   
        }

        public LineWrapper(AccountingUnitPriceAndCost.TaxDetail taxDetail, String CategoryAccId) {
            this.Description = taxDetail.Name; 
            this.Amount = taxDetail.TaxAmount;
            this.DetailType = 'AccountBasedExpenseLineDetail';        
            this.AccountBasedExpenseLineDetail = new AccountBasedExpenseLineDetailWrapper(taxDetail, CategoryAccId);   
        }
    }

    public class AccountBasedExpenseLineDetailWrapper {
        public AccountRefWrapper AccountRef;
        public QBInternalEntity TaxCodeRef; //change Wrapper to replace by intrnal entity 
        public AccountBasedExpenseLineDetailWrapper(AccountingVendorInvoice.AccountRefWrapper AccountRef) {
            this.AccountRef = new AccountRefWrapper(AccountRef); 
        }
        public AccountBasedExpenseLineDetailWrapper(AccountingVendorInvoice.AccountRefWrapper AccountRef, String taxCodeRefAccountingId) {
            this.AccountRef = new AccountRefWrapper(AccountRef); 
            this.TaxCodeRef =  String.isNotBlank(taxCodeRefAccountingId) ? new QBInternalEntity(taxCodeRefAccountingId) : null;
        }
        public AccountBasedExpenseLineDetailWrapper(String CategoryAccountRef)  {
            this.AccountRef = new AccountRefWrapper(CategoryAccountRef); 
        }
        public AccountBasedExpenseLineDetailWrapper(String CategoryAccountRef, String taxCodeRefAccountingId)  {
            this.AccountRef = new AccountRefWrapper(CategoryAccountRef);
            if(QBUtil.isQBTaxCodesEnabled) {
                this.TaxCodeRef =  String.isNotBlank(taxCodeRefAccountingId) ? new QBInternalEntity(taxCodeRefAccountingId) : null; 
            }
        }
        public AccountBasedExpenseLineDetailWrapper(AccountingUnitPriceAndCost.TaxDetail taxDetail, String categoryAccId) {
            this.AccountRef = new AccountRefWrapper(categoryAccId);
            if(QBUtil.isQBTaxCodesEnabled && taxDetail.AccountingId != null) {
                this.TaxCodeRef = new QBInternalEntity(taxDetail.AccountingId);
            }
        }
    }
     
    public class AccountRefWrapper {
        public String value;
        public AccountRefWrapper(AccountingVendorInvoice.AccountRefWrapper AccountRef) {
            this.value = AccountRef.AccountingId;
        }
        public AccountRefWrapper(String CategoryAccountRef) {
            this.value = CategoryAccountRef;
        }
        public AccountRefWrapper(AccountingUnitPriceAndCost.TaxDetail taxRef) {
            this.value = taxRef.AccountingId;
        }
    }

    public class VendorRefWrapper {
        public String value;
        public String name;
        public VendorRefWrapper(AccountingVendorInvoice.VendorWrapper VendorRef) {
            this.value = VendorRef.AccountingId;
            this.name = VendorRef.Name;
        }
        public VendorRefWrapper(String acctId) {
            this.value = acctId;
        }
     }

     public class QBInternalEntity {
        public String value;
        public QBInternalEntity(String acctId) {
            this.value = acctId;
        }
     }
}