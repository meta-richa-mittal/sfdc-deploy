public without sharing abstract class QBBaseVendorInvoiceDTO {
    public String SFId;
    public String Id;
    public String SyncToken;
    public String DocNumber;  
    public Date TxnDate;
    public List<LineWrapper> Line;
    public QBInnerEntityWrapper VendorRef;
    public QBInnerEntityWrapper APAccountRef;
    public QBTxnTaxDetailWrapper TxnTaxDetail;
    public Decimal TotalAmt;
    public Decimal Balance;
    public String GlobalTaxCalculation;
    public String PrivateNote;
    public QBInnerEntityWrapper CurrencyRef;
    public Decimal ExchangeRate = 1;
    public static String syncingObjectType = '';
    public static Boolean isSyncRecordContainsNonTaxableItem = false;
    private static Boolean isReverseAmount = false;

    public QBBaseVendorInvoiceDTO() {}

    public QBBaseVendorInvoiceDTO(AccountingUnitPriceAndCost adjstmentRec) {
        this.SFId = adjstmentRec.Id;
    	this.Id = adjstmentRec.JournalEntryAccountingId;
        this.SyncToken = adjstmentRec.JournalEntrySyncToken;
        
        this.DocNumber = adjstmentRec.VendorReferenceNumber; 
		if(String.isNotBlank(adjstmentRec.VendorReferenceNumber) && adjstmentRec.VendorReferenceNumber.length() > 21) {
			this.DocNumber = adjstmentRec.VendorReferenceNumber.substring(0, 21);
		}
        this.TxnDate = adjstmentRec.AdjustmentDate;

        this.Line = new List<LineWrapper>{new LineWrapper(adjstmentRec)};
        this.VendorRef = new QBInnerEntityWrapper(adjstmentRec.VendorAccountingId, null);

        if(AccountingUtil.isMultiCurrencyEnabled()) {
            this.CurrencyRef = new QBInnerEntityWrapper(adjstmentRec.CurrencyCode, null);
            this.ExchangeRate = adjstmentRec.FXConversionRate;
        }
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
        this.SFId = vendorInvoiceRecord.Id;
        this.Id = vendorInvoiceRecord.AccountingVIHeaderRec.AccountingId;
        this.SyncToken = vendorInvoiceRecord.AccountingVIHeaderRec.SyncToken;
        this.DocNumber = vendorInvoiceRecord.AccountingVIHeaderRec.InvoiceNumber; 
        this.TxnDate = (vendorInvoiceRecord.AccountingVIHeaderRec.InvoiceDate != null) ? vendorInvoiceRecord.AccountingVIHeaderRec.InvoiceDate :
                                vendorInvoiceRecord.AccountingVIHeaderRec.CreatedDate;
        if(AccountingUtil.isMultiCurrencyEnabled()) {
            this.CurrencyRef = new QBInnerEntityWrapper(vendorInvoiceRecord.AccountingVIHeaderRec.CurrencyCode, null);
            this.ExchangeRate = vendorInvoiceRecord.AccountingVIHeaderRec.FXConversionRate;
        }
        this.TotalAmt = this.Balance = vendorInvoiceRecord.AccountingVIHeaderRec.TotalWithTax;
        if(vendorInvoiceRecord.AccountingVIHeaderRec.TotalWithTax < 0) {
            syncingObjectType = QBUtil.VENDOR_CREDIT;
            this.TotalAmt *= -1;
            this.Balance *= -1;
        }
        this.Line = new List<LineWrapper>();
            
        String description = vendorInvoiceRecord.AccountingVIHeaderRec.VIHeaderNumber + ';' + vendorInvoiceRecord.AccountingVIHeaderRec.VendorName + ';' +
	    						vendorInvoiceRecord.AccountingVIHeaderRec.InvoiceNumber + ';';
	    String VRNumberFoDesc = vendorInvoiceRecord.VRNumberSet.size() == 1 ? new List<String>(vendorInvoiceRecord.VRNumberSet)[0] + ';' : '';
	    for(AccountingVendorInvoice.AccountingVIGroupByGLAndType accVIGRec: vendorInvoiceRecord.AccountingVIGroupByGLAndTypeList) {
            if(accVIGRec.Type != AccountingVendorInvoice.INVENTORY_RECEIVED) continue; // added to exclude the variance lines as we now post JE for that QBVIVarianceJEService
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
                    isSyncRecordContainsNonTaxableItem = true;
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
        this.VendorRef = new QBInnerEntityWrapper(vendorInvoiceRecord.vendor.AccountingId, vendorInvoiceRecord.vendor.Name);
        AccountingVendorInvoice.AccountingPurchaseTax purchaseTax;
        vendorInvoiceRecord.AppliedTaxRate = vendorInvoiceRecord.AppliedTaxRate != null ? vendorInvoiceRecord.AppliedTaxRate : 0;
        if(QBUtil.isQBTaxCodesEnabled) {
            this.GlobalTaxCalculation = QBUtil.TAX_EXCLUDED;
            Decimal totalTaxOnCost = 0;
            List<AccountingVendorInvoice.TaxRateComponent> taxComponentList = new List<AccountingVendorInvoice.TaxRateComponent>();
            if(vendorInvoiceRecord.AccountingPurchaseTaxList.size() > 0) {
                for(Integer i = 0; i < vendorInvoiceRecord.AccountingPurchaseTaxList.size(); i++) {
                    purchaseTax = vendorInvoiceRecord.AccountingPurchaseTaxList[i];
                    Decimal taxAmount = ((purchaseTax.SalesTaxRate * (vendorInvoiceRecord.AccountingVIHeaderRec.TotalPartSubtotal != null ? vendorInvoiceRecord.AccountingVIHeaderRec.TotalPartSubtotal : 0) / 100).setScale(2, RoundingMode.HALF_UP));
                    for(AccountingVendorInvoice.OtherChargesWrapper otherChargesRec : vendorInvoiceRecord.AccountingOtherChargesList) {
                        if(otherChargesRec.IsTaxable) {
                            taxAmount += ((purchaseTax.SalesTaxRate * otherChargesRec.Cost / 100).setScale(2, RoundingMode.HALF_UP)); // Required while sending taxes as line items below
                        }
                    }
                    totalTaxOnCost += taxAmount;
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
            if(GeneralConfiguration.getTaxIncludingPricing() && (vendorInvoiceRecord.AccountingVIHeaderRec.TotalTax - totalTaxOnCost) != 0 && taxComponentList.size() > 0) {
                taxComponentList[taxComponentList.size() - 1].TaxAmount += vendorInvoiceRecord.AccountingVIHeaderRec.TotalTax - totalTaxOnCost;
            }
            if(isSyncRecordContainsNonTaxableItem) {
                Map<String, List<String>> nonTaxCodeToRatesMap = QBUtil.getNonTaxableTaxCodeWithRates(QBUtil.PURCHASE);
                if(nonTaxCodeToRatesMap.containsKey(QBUtil.nonTaxableCodeAccId)) {
                    for(String acctId : nonTaxCodeToRatesMap.get(QBUtil.nonTaxableCodeAccId)) {
                        taxComponentList.add(new AccountingVendorInvoice.TaxRateComponent(0, 0, acctId, 0));
                    }
                }
            }
            this.TxnTaxDetail = new QBTxnTaxDetailWrapper(vendorInvoiceRecord.AccountingVIHeaderRec.TotalTax, taxComponentList);  
        } else {
            Decimal taxValue = 0;
            String categoryRef = '';
            this.GlobalTaxCalculation = QBUtil.TAX_NOT_APPLICABLE;
            if(vendorInvoiceRecord.AccountingPurchaseTaxList.size() > 0) {
                for(Integer i = 0; i < vendorInvoiceRecord.AccountingPurchaseTaxList.size(); i++) {
                    purchaseTax = vendorInvoiceRecord.AccountingPurchaseTaxList[i];
                    Decimal taxAmount = 0;
                    for(AccountingVendorInvoice.OtherChargesWrapper otherChargesRec : vendorInvoiceRecord.AccountingOtherChargesList) {
                        if(otherChargesRec.IsTaxable) {
                            taxAmount += ((purchaseTax.SalesTaxRate * otherChargesRec.Cost / 100).setScale(2, RoundingMode.HALF_UP)); // Required while sending taxes as line items below
                        }
                    }
                    categoryRef = purchaseTax.CategoyRef != null ? purchaseTax.CategoyRef : AccountingUtil.getChartofAccount('Sales Tax');
                    if(i == vendorInvoiceRecord.AccountingPurchaseTaxList.size() - 1) {
                        this.Line.add(new LineWrapper('Purchase Tax - ' + purchaseTax.SalesTaxName, (vendorInvoiceRecord.AccountingVIHeaderRec.TotalTax - taxValue), categoryRef));
                    } else {
                        this.Line.add(new LineWrapper('Purchase Tax - ' + purchaseTax.SalesTaxName, taxAmount, categoryRef));
                        taxValue += taxAmount;
                    }
                }
            }
        }
        this.PrivateNote = String.join(new List<String>(vendorInvoiceRecord.VRNumberSet), ';') + ';' + description + 'Vendor invoice';
    }
    
    public QBBaseVendorInvoiceDTO(AccountingVendorReturn returnCRHeaderRecord) {
        this.SFId = returnCRHeaderRecord.Id;
        this.Id = returnCRHeaderRecord.AccountingId;
        this.SyncToken = returnCRHeaderRecord.SyncToken;
        this.DocNumber = returnCRHeaderRecord.Name; 
        this.TxnDate = returnCRHeaderRecord.CreditedDate;
        if(AccountingUtil.isMultiCurrencyEnabled()) {
            this.CurrencyRef = new QBInnerEntityWrapper(returnCRHeaderRecord.CurrencyCode, null);
            this.ExchangeRate = returnCRHeaderRecord.FXConversionRate;
        }
        this.TotalAmt = this.Balance = returnCRHeaderRecord.Total;
        if(returnCRHeaderRecord.Total < 0) {
            isReverseAmount = true;
            this.TotalAmt *= -1;
            this.Balance *= -1;
        }
        this.Line = new List<LineWrapper>();

        Map<Id, List<AccountingFIFOBucket>> partIdToFIFOBucketMap = new Map<Id, List<AccountingFIFOBucket>>();
        Decimal Variance = 0;
        for(AccountingVendorReturn.ReturnCRLineItemWrapper RCRLIRec: returnCRHeaderRecord.ReturnCRLIList) {
            this.Line.add(new LineWrapper(RCRLIRec, returnCRHeaderRecord.AccountRef1, 
                                            returnCRHeaderRecord.TaxCodeAccountingId));
        }

        Decimal totalTaxableAmount = returnCRHeaderRecord.ItemTotal != null ? returnCRHeaderRecord.ItemTotal : 0;
        if(QBUtil.isQBTaxCodesEnabled) {
            for(AccountingVendorInvoice.OtherChargesWrapper otherChargesRec: returnCRHeaderRecord.AccountingOtherChargesList) {
                otherChargesRec.Cost = otherChargesRec.Cost != null ? otherChargesRec.Cost : 0;
                if(otherChargesRec.IsTaxable) {
                    totalTaxableAmount += otherChargesRec.Cost;
                    this.Line.add(new LineWrapper('Other Charge - ' + otherChargesRec.ItemDesc, otherChargesRec.Cost, otherChargesRec.CategoyRef, returnCRHeaderRecord.TaxCodeAccountingId)); 
                } else {
                    isSyncRecordContainsNonTaxableItem = true;
                    this.Line.add(new LineWrapper('Other Charge - ' + otherChargesRec.ItemDesc, otherChargesRec.Cost, otherChargesRec.CategoyRef, QBUtil.nonTaxableCodeAccId));
                }
                
            }
        } else {
            for(AccountingVendorInvoice.OtherChargesWrapper otherChargesRec: returnCRHeaderRecord.AccountingOtherChargesList) {
            	otherChargesRec.Cost = otherChargesRec.Cost != null ? otherChargesRec.Cost : 0;
                if(otherChargesRec.IsTaxable) {
            		totalTaxableAmount += otherChargesRec.Cost; // Required while sending taxes as line items below
            	}
                this.Line.add(new LineWrapper('Other Charge - ' + otherChargesRec.ItemDesc, otherChargesRec.Cost, otherChargesRec.CategoyRef));
            }
        }

        this.VendorRef = new QBInnerEntityWrapper(returnCRHeaderRecord.VendorAccountingId, returnCRHeaderRecord.VendorName);
        Decimal TotalTaxAmount = returnCRHeaderRecord.Tax != null ? returnCRHeaderRecord.Tax : 0;
        Decimal taxValue = 0;
        String categoryRef = '';
        AccountingVendorReturn.AccountingPurchaseTax purchaseTax;
        
        if(QBUtil.isQBTaxCodesEnabled) {
            this.GlobalTaxCalculation = QBUtil.TAX_EXCLUDED;
            
            List<AccountingVendorReturn.TaxRateComponent> taxComponentList = new List<AccountingVendorReturn.TaxRateComponent>();
            for(Integer i=0 ; i<returnCRHeaderRecord.AccountingPurchaseTaxList.size(); i++) {
                purchaseTax = returnCRHeaderRecord.AccountingPurchaseTaxList[i];
                Decimal taxAmount = (purchaseTax.SalesTaxRate*totalTaxableAmount/100);  
                Decimal taxableAmount = totalTaxableAmount;
                String purchaseTaxRateAcctId = purchaseTax.SalesTaxItemAccountingId;
                Decimal taxPercent = purchaseTax.SalesTaxRate;
                taxComponentList.add(new AccountingVendorReturn.TaxRateComponent(taxAmount, taxableAmount, purchaseTaxRateAcctId, taxPercent));
            }
            
            if(returnCRHeaderRecord.AccountingPurchaseTaxList.size() == 0 && String.isNotBlank(returnCRHeaderRecord.TaxCodeAccountingId)) {
                List<QB_TaxCode__c> taxCodeList = [SELECT Applicable_QB_Tax_Rates__c FROM QB_TaxCode__c WHERE Accounting_Id__c = :returnCRHeaderRecord.TaxCodeAccountingId AND Tax_Applicable_On__c =: QBUtil.PURCHASE];
                if(taxCodeList.size() > 0 && String.isNotBlank(taxCodeList[0].Applicable_QB_Tax_Rates__c)) {
                     List<String> taxRateAccIdList = taxCodeList[0].Applicable_QB_Tax_Rates__c.split(';');
                     for(String taxRateAccId : taxRateAccIdList) {
                        taxComponentList.add(new AccountingVendorReturn.TaxRateComponent(0, 0, taxRateAccId, 0));
                    }
                }
            }
        
            if(isSyncRecordContainsNonTaxableItem) {
                Map<String, List<String>> nonTaxCodeToRatesMap = QBUtil.getNonTaxableTaxCodeWithRates(QBUtil.PURCHASE);
                if(nonTaxCodeToRatesMap.containsKey(QBUtil.nonTaxableCodeAccId)) {
                    for(String acctId : nonTaxCodeToRatesMap.get(QBUtil.nonTaxableCodeAccId)) {
                        taxComponentList.add(new AccountingVendorReturn.TaxRateComponent(0, 0, acctId, 0));
                    }
                }
            }
            this.TxnTaxDetail = new QBTxnTaxDetailWrapper(returnCRHeaderRecord.Tax, taxComponentList);
        } else {
            this.GlobalTaxCalculation = QBUtil.TAX_NOT_APPLICABLE;
            if(returnCRHeaderRecord.AccountingPurchaseTaxList.size() > 0) {
                for(Integer i=0 ;i<returnCRHeaderRecord.AccountingPurchaseTaxList.size() - 1; i++) {
                    purchaseTax = returnCRHeaderRecord.AccountingPurchaseTaxList[i];
                    Decimal taxAmount = (purchaseTax.SalesTaxRate*this.TotalAmt/100); //.setScale(2, RoundingMode.HALF_UP)
                    taxValue += taxAmount;
                    categoryRef = purchaseTax.CategoyRef != null ? purchaseTax.CategoyRef : AccountingUtil.getChartofAccount('Sales Tax');
                    this.Line.add(new LineWrapper('Purchase Tax - ' + purchaseTax.SalesTaxName, taxAmount, categoryRef));
                }
                purchaseTax = returnCRHeaderRecord.AccountingPurchaseTaxList[returnCRHeaderRecord.AccountingPurchaseTaxList.size() - 1];
                categoryRef = purchaseTax.CategoyRef != null ? purchaseTax.CategoyRef : AccountingUtil.getChartofAccount('Sales Tax');
                this.Line.add(new LineWrapper('Purchase Tax - ' + purchaseTax.SalesTaxName, (TotalTaxAmount - taxValue), categoryRef));
            }
        }
    }

    public QBBaseVendorInvoiceDTO(AccountingUnit couRecord) {
        this.SFId = couRecord.Id;
        this.Id = couRecord.AccountingId;
        this.SyncToken = couRecord.SyncToken;
        this.DocNumber = couRecord.InvoiceNumber;
        this.TxnDate = couRecord.CreatedDate;
        this.PrivateNote = couRecord.ItemDesc;
        if(AccountingUtil.isMultiCurrencyEnabled()) {
            this.CurrencyRef = new QBInnerEntityWrapper(couRecord.CurrencyCode, null);
            this.ExchangeRate = couRecord.FXConversionRate;
        }
        
        this.Line = new List<LineWrapper>();
        List<Category__c> defaultCategory = [select Name, Inventory_GL__c  from Category__c
                                                where Type__c = 'Unit' AND Active__c = true AND Default__c = true]; 
        
        String inventoryGLValue = couRecord.Inventory_GL != null ? couRecord.Inventory_GL : defaultCategory[0].Inventory_GL__c;
        
        if(QBUtil.isQBTaxCodesEnabled) {
            this.Line.add(new LineWrapper(couRecord, inventoryGLValue, couRecord.AppliedQBTaxCode));
        } else {
            this.Line.add(new LineWrapper(couRecord, inventoryGLValue));
        }
            
        this.VendorRef = new QBInnerEntityWrapper(couRecord.Vendor.AccountingId, couRecord.Vendor.Name);
        this.TotalAmt = couRecord.TotalCost;
        this.Balance = couRecord.TotalCost;
        
        AccountingUnit.AccountingPurchaseTax purchaseTax;
        if(QBUtil.isQBTaxCodesEnabled) {
            this.GlobalTaxCalculation = GeneralConfiguration.getTaxIncludingPricing() ? QBUtil.TAX_INCLUSIVE: QBUtil.TAX_EXCLUDED;
            Decimal totalTax = couRecord.TotalPurchaseTax;
            Decimal totalTaxOnCost = 0;
            List<AccountingUnit.TaxRateComponent> taxComponentList = new List<AccountingUnit.TaxRateComponent>();
            if(couRecord.AccountingPurchaseTaxList != null && couRecord.AccountingPurchaseTaxList.size() > 0) {
                for(Integer i=0 ;i<couRecord.AccountingPurchaseTaxList.size(); i++) {
                    purchaseTax = couRecord.AccountingPurchaseTaxList[i];
                    Decimal taxAmount = (purchaseTax.SalesTaxRate * this.TotalAmt/100).setScale(2, RoundingMode.HALF_UP);
                    totalTaxOnCost += taxAmount;
                    Decimal taxableAmount = this.TotalAmt;
                    Decimal taxPercent = purchaseTax.SalesTaxRate;
                    String purchaseTaxRateAcctId = purchaseTax.QBTaxCodeRef;
                    taxComponentList.add(new AccountingUnit.TaxRateComponent(taxAmount, taxableAmount, purchaseTaxRateAcctId, taxPercent));
                }
            } else if(couRecord.AppliedTaxRate == 0 && couRecord.AccountingPurchaseTaxList.size() == 0) {
                if(AccessControl.ifObjectFieldIsAccessible('QB_TaxCode__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
                List<QB_TaxCode__c> taxCodeList = [SELECT Applicable_QB_Tax_Rates__c FROM QB_TaxCode__c WHERE Accounting_Id__c = :couRecord.AppliedQBTaxCode AND Tax_Applicable_On__c =: QBUtil.PURCHASE];
                if(taxCodeList.size() > 0  && String.isNotBlank(taxCodeList[0].Applicable_QB_Tax_Rates__c)) {
                    List<String> taxRateAccIdList = taxCodeList[0].Applicable_QB_Tax_Rates__c.split(';');
                    for(String taxRateAccId : taxRateAccIdList) {
                        taxComponentList.add(new AccountingUnit.TaxRateComponent(0, 0, taxRateAccId, 0));
                    }
                }
            }
            if(GeneralConfiguration.getTaxIncludingPricing() && (totalTax - totalTaxOnCost) != 0 && taxComponentList.size() > 0) {
                taxComponentList[taxComponentList.size() - 1].TaxAmount += totalTax - totalTaxOnCost;
            }
            this.TxnTaxDetail = new QBTxnTaxDetailWrapper(totalTax, taxComponentList);
        } else if(couRecord.AccountingPurchaseTaxList.size() > 0) {
            Decimal TotalTaxAmount = couRecord.TotalPurchaseTax;
            Decimal taxValue = 0;
            String categoryRef = '';
            for(Integer i=0 ;i<couRecord.AccountingPurchaseTaxList.size() - 1; i++) {
                purchaseTax = couRecord.AccountingPurchaseTaxList[i];
                Decimal taxAmount = (purchaseTax.SalesTaxRate * this.TotalAmt/100); //.setScale(2, RoundingMode.HALF_UP)
                taxValue += taxAmount;
                categoryRef = purchaseTax.CategoyRef != null ? purchaseTax.CategoyRef : AccountingUtil.getChartofAccount('Sales Tax');
                this.Line.add(new LineWrapper('Purchase Tax - ' + purchaseTax.SalesTaxName, taxAmount, categoryRef));
            }
            purchaseTax = couRecord.AccountingPurchaseTaxList[couRecord.AccountingPurchaseTaxList.size() - 1];
            categoryRef = purchaseTax.CategoyRef != null ? purchaseTax.CategoyRef : AccountingUtil.getChartofAccount('Sales Tax');
            this.Line.add(new LineWrapper('Purchase Tax - ' + purchaseTax.SalesTaxName, (TotalTaxAmount - taxValue), categoryRef));
        }
    }

    public QBBaseVendorInvoiceDTO(AccountingLienPayout dealItemRecord) {
        this.SFId = dealItemRecord.Id;
        this.Id = dealItemRecord.AccountingId;
        this.SyncToken = dealItemRecord.SyncToken;
        this.DocNumber = dealItemRecord.InvoiceNumber;
        this.TxnDate = dealItemRecord.InvoiceDate;
        QBInnerEntityWrapper currRef = QBUtil.getCurrencyRef();
        if(currRef != null) this.CurrencyRef = currRef;
        
        this.Line = new List<LineWrapper>();
        String itemDesc = 'Lien payout:' + (!String.isBlank(dealItemRecord.UnitVinNumber) ? (' ' + dealItemRecord.UnitVinNumber) : '') 
                                +  (!String.isBlank(dealItemRecord.FinanceCompany.Name) ? (' ' + dealItemRecord.FinanceCompany.Name) : '');
        this.Line.add(new LineWrapper(itemDesc, dealItemRecord.LienPayout, dealItemRecord.CategoyIncomeGLAccountRef));
        
        this.VendorRef = new QBInnerEntityWrapper(dealItemRecord.FinanceCompany.AccountingId, dealItemRecord.FinanceCompany.Name);
        this.TotalAmt = this.Balance = dealItemRecord.LienPayout;
        this.GlobalTaxCalculation = QBUtil.TAX_NOT_APPLICABLE;
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
      
        public LineWrapper(AccountingVendorInvoice.AccountingVIGroup VIGroupRec, AccountingVendorInvoice.AccountRefWrapper AccountRef) {
            this.Description = VIGroupRec.ItemDesc + ' ' + VIGroupRec.InvoiceTotalQty + '@$' + VIGroupRec.InvoiceCost;
            this.Amount = (VIGroupRec.InvoiceTotalQty * (VIGroupRec.InvoiceCost * (1 - (VIGroupRec.Discount / 100 ))).setScale(2, RoundingMode.HALF_UP));
            if(syncingObjectType == QBUtil.VENDOR_CREDIT) {
            	this.Amount *= -1;
            }
            this.DetailType = 'AccountBasedExpenseLineDetail';    
            this.AccountBasedExpenseLineDetail = new AccountBasedExpenseLineDetailWrapper(AccountRef.AccountingId, null);   
        }
        
        public LineWrapper(String Description, Decimal Amount, AccountingVendorInvoice.AccountRefWrapper AccountRef) {
            this.Description = Description;
            this.Amount = Amount;
            if(syncingObjectType == QBUtil.VENDOR_CREDIT) {
            	this.Amount *= -1;
            }
            this.DetailType = 'AccountBasedExpenseLineDetail';
            this.AccountBasedExpenseLineDetail = new AccountBasedExpenseLineDetailWrapper(AccountRef.AccountingId, null);   
        }
         public LineWrapper(AccountingVendorInvoice.AccountingVIGroup VIGroupRec, AccountingVendorInvoice.AccountRefWrapper AccountRef, String taxCodeRefAccountingId) {
            this.Description = VIGroupRec.ItemDesc + ' ' + VIGroupRec.InvoiceTotalQty + '@$' + VIGroupRec.InvoiceCost;
            this.Amount = (VIGroupRec.InvoiceTotalQty * (VIGroupRec.InvoiceCost * (1 - (VIGroupRec.Discount / 100 ))).setScale(2, RoundingMode.HALF_UP));
            if(syncingObjectType == QBUtil.VENDOR_CREDIT) {
            	this.Amount *= -1;
            }
            this.DetailType = 'AccountBasedExpenseLineDetail';    
            this.AccountBasedExpenseLineDetail = new AccountBasedExpenseLineDetailWrapper(AccountRef.AccountingId, taxCodeRefAccountingId);   
        }

        public LineWrapper(AccountingUnit couRec, String CategoryAccountRef) {
            this.Description = couRec.ItemDesc;
            this.Amount = (couRec.TotalCost != null) ? couRec.TotalCost : 0;
            this.DetailType = 'AccountBasedExpenseLineDetail';   
            this.AccountBasedExpenseLineDetail = new AccountBasedExpenseLineDetailWrapper(CategoryAccountRef);   
        }
        
        public LineWrapper(AccountingUnit couRec, String CategoryAccountRef, String taxCodeRefId) {
            this.Description = couRec.ItemDesc;
            this.Amount = (couRec.TotalCost != null) ? couRec.TotalCost : 0;
            this.DetailType = 'AccountBasedExpenseLineDetail';   
            this.AccountBasedExpenseLineDetail = new AccountBasedExpenseLineDetailWrapper(CategoryAccountRef, taxCodeRefId);   
        }
        
        public LineWrapper(String Description, Decimal Amount, AccountingVendorInvoice.AccountRefWrapper AccountRef, String taxCodeRefAccountingId) {
            this.Description = Description;
            this.Amount = Amount;
            if(syncingObjectType == QBUtil.VENDOR_CREDIT) {
            	this.Amount *= -1;
            }
            this.DetailType = 'AccountBasedExpenseLineDetail';
            this.AccountBasedExpenseLineDetail = new AccountBasedExpenseLineDetailWrapper(AccountRef.AccountingId, taxCodeRefAccountingId);   
        }
         public LineWrapper(String Description, Decimal Amount, String CategoryAccountRef) {
            this.Description = Description; 
            this.Amount = Amount;
            if(syncingObjectType == QBUtil.VENDOR_CREDIT || isReverseAmount) {
            	this.Amount *= -1;
            }
            this.DetailType = 'AccountBasedExpenseLineDetail';
            this.AccountBasedExpenseLineDetail = new AccountBasedExpenseLineDetailWrapper(CategoryAccountRef, null);   
        }
        public LineWrapper(String Description, Decimal Amount, String CategoryAccountRef, String taxCodeRefAccountingId) {
            this.Description = Description; 
            this.Amount = Amount;
            if(syncingObjectType == QBUtil.VENDOR_CREDIT || isReverseAmount) {
            	this.Amount *= -1;
            }
            this.DetailType = 'AccountBasedExpenseLineDetail';
            this.AccountBasedExpenseLineDetail = new AccountBasedExpenseLineDetailWrapper(CategoryAccountRef, taxCodeRefAccountingId);   
        }

        public LineWrapper(AccountingUnitPriceAndCost.TaxDetail taxDetail, String CategoryAccId) {
            this.Description = taxDetail.Name; 
            this.Amount = taxDetail.TaxAmount;
            if(this.Amount < 0) {
                this.Amount *= -1;
            }
            this.DetailType = 'AccountBasedExpenseLineDetail';        
            this.AccountBasedExpenseLineDetail = new AccountBasedExpenseLineDetailWrapper(CategoryAccId, taxDetail.AccountingId);   
        }

        public LineWrapper(AccountingVendorReturn.ReturnCRLineItemWrapper RCRLIRec, AccountingVendorReturn.AccountRefWrapper AccountRef, String taxCodeAccountingId) { 
            this.Description = RCRLIRec.ItemDescription + ' ' + RCRLIRec.ReturnQty + '@$' + RCRLIRec.ItemCost;
            this.Amount = RCRLIRec.ReturnQty * RCRLIRec.ItemCost;
            if(isReverseAmount) {
            	this.Amount *= -1;
            }
            this.DetailType = 'AccountBasedExpenseLineDetail';    
			this.AccountBasedExpenseLineDetail = new AccountBasedExpenseLineDetailWrapper(AccountRef, taxCodeAccountingId);   
		}
        
        public LineWrapper(String Description, Decimal Amount, AccountingVendorReturn.AccountRefWrapper AccountRef, String taxCodeAccountingId) {
            this.Description = Description;
            this.Amount = Amount;
            if(isReverseAmount) {
            	this.Amount *= -1;
            }
            this.DetailType = 'AccountBasedExpenseLineDetail';
            this.AccountBasedExpenseLineDetail = new AccountBasedExpenseLineDetailWrapper(AccountRef, taxCodeAccountingId);   
        }
         
        //  public LineWrapper(String Description, Decimal Amount, String CategoryAccountRef, String taxCodeAccountingId) {
        //     this.Description = Description; 
        //     this.Amount = Amount;
        //     this.DetailType = 'AccountBasedExpenseLineDetail';
        //     this.AccountBasedExpenseLineDetail = new AccountBasedExpenseLineDetailWrapper(CategoryAccountRef, taxCodeAccountingId);   
        // }
         
        // public LineWrapper(String Description, Decimal Amount, String CategoryAccountRef) {
        //     this.Description = Description; 
        //     this.Amount = Amount;
        //     this.DetailType = 'AccountBasedExpenseLineDetail';
        //     this.AccountBasedExpenseLineDetail = new AccountBasedExpenseLineDetailWrapper(CategoryAccountRef);   
        // }
    }

    public class AccountBasedExpenseLineDetailWrapper {
        public QBInnerEntityWrapper AccountRef;
        public QBInnerEntityWrapper TaxCodeRef;
        public AccountBasedExpenseLineDetailWrapper(String CategoryAccountRef, String taxCodeRefAccountingId)  {
            this.AccountRef = new QBInnerEntityWrapper(CategoryAccountRef, null);
            if(QBUtil.isQBTaxCodesEnabled) {
                this.TaxCodeRef =  String.isNotBlank(taxCodeRefAccountingId) ? new QBInnerEntityWrapper(taxCodeRefAccountingId, null) : null; 
            }
        }
        public AccountBasedExpenseLineDetailWrapper(AccountingVendorReturn.AccountRefWrapper AccountRef, String taxCodeAccountingId)	{
            this.AccountRef = new QBInnerEntityWrapper(AccountRef); 
        	if(QBUtil.isQBTaxCodesEnabled) {
            	this.TaxCodeRef = new QBInnerEntityWrapper(taxCodeAccountingId, '');
            }
        }
        
        public AccountBasedExpenseLineDetailWrapper(String CategoryAccountRef)	{
            this.AccountRef = new QBInnerEntityWrapper(CategoryAccountRef); 
        }
    }
}