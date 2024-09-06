public without sharing abstract class QBBaseInvoiceDTO {
    public String SFId;
    public String Id;
    public String SyncToken;
    public String DocNumber;  
    public Date TxnDate;
    public List<QBLineItemDTO> Line;
    public QBInnerEntityWrapper CustomerRef;
    public String GlobalTaxCalculation;
    public QBTxnTaxDetailWrapper TxnTaxDetail;
    public String PrivateNote;
    public QBInnerEntityWrapper CurrencyRef;
    public Decimal ExchangeRate = 1;
    public Decimal TotalAmt;
    public Decimal Balance;
    public String PrintStatus;
    public String PaymentRefNum;
    public QBInnerEntityWrapper DepositToAccountRef;
    public String DueDate;
    public String RemainingCredit;
    public List<QBLinkedTxn> LinkedTxn;
    public Boolean sparse;

    public QBBaseInvoiceDTO(AccountingCustomerInvoice customerInvoiceRecord) {
        this.SFId = customerInvoiceRecord.AccountingCOInvoiceHeaderRec.COInvoiceHeaderId;
        this.Id = customerInvoiceRecord.AccountingCOInvoiceHeaderRec.AccountingId;
        this.SyncToken = customerInvoiceRecord.AccountingCOInvoiceHeaderRec.SyncToken;
        this.DocNumber = customerInvoiceRecord.AccountingCOInvoiceHeaderRec.COInvoiceHeaderNumber; 
        this.TxnDate = DateTimeUtility.getDateFromFormattedDateStr(customerInvoiceRecord.AccountingCOInvoiceHeaderRec.ClosedInvoiceDate);
        QBInnerEntityWrapper currRef = QBUtil.getCurrencyRef();
        if(currRef != null) this.CurrencyRef = currRef;

    	this.Line = new List<QBLineItemDTO>();
        for(Object lineItemRec : AccountingCustomerInvoiceService.setAllInvoiceItemRec(customerInvoiceRecord)) {
    		this.Line.add((QBLineItemDTO) lineItemRec);
    	}
        this.TotalAmt = customerInvoiceRecord.AccountingCOInvoiceHeaderRec.InvoiceTotal;
        if((customerInvoiceRecord.SyncingObjectType == IntegrationUtility.REFUND_RECEIPT || customerInvoiceRecord.SyncingObjectType == IntegrationUtility.CREDIT_MEMO) && this.TotalAmt < 0) {
            this.TotalAmt *= -1;
            customerInvoiceRecord.AccountingCOInvoiceHeaderRec.TotalSalesTax *= -1;
            for(AccountingCustomerInvoice.TaxDetail taxDetailRec : customerInvoiceRecord.taxDetails) {
                taxDetailRec.TaxAmount *= -1;
                taxDetailRec.TaxableAmount *= -1;
            }
        }
        
        if(QBUtil.isQBTaxCodesEnabled) {
            if(customerInvoiceRecord.isTaxIncludingPricing) {
                this.GlobalTaxCalculation = 'TaxInclusive';
            } else {
                this.GlobalTaxCalculation = 'TaxExcluded';
            }
            this.TxnTaxDetail = new QBTxnTaxDetailWrapper(customerInvoiceRecord.AccountingCOInvoiceHeaderRec.TotalSalesTax,
                                                    customerInvoiceRecord.taxDetails, customerInvoiceRecord.applicableSalesTaxIdSet, customerInvoiceRecord.isNonTaxableLIExists);
        } else {
            this.GlobalTaxCalculation = QBUtil.TAX_NOT_APPLICABLE;
            // Adding Taxes as line item of Invoice - #4158
            for(AccountingCustomerInvoice.TaxDetail taxRec : customerInvoiceRecord.taxDetails) {
                if(taxRec.TaxAmount != null && taxRec.TaxAmount != 0) {
                    this.Line.add(new QBLineItemDTO(taxRec));
                }
            }
        }
        
        this.CustomerRef = new QBInnerEntityWrapper(customerInvoiceRecord.AccountingCOInvoiceHeaderRec.customer.AccountingId, customerInvoiceRecord.AccountingCOInvoiceHeaderRec.customer.Name);
        this.PrintStatus = 'PrintComplete';
        this.Balance = customerInvoiceRecord.AccountingCOInvoiceHeaderRec.InvoiceTotal;
        
        if(customerInvoiceRecord.AccountingCOInvoiceHeaderRec.ClaimNumber != null) {
            this.PrivateNote = customerInvoiceRecord.AccountingCOInvoiceHeaderRec.CustomerName + ';' + customerInvoiceRecord.AccountingCOInvoiceHeaderRec.ClaimNumber;
        }
        if(customerInvoiceRecord.SyncingObjectType == IntegrationUtility.REFUND_RECEIPT || customerInvoiceRecord.SyncingObjectType == IntegrationUtility.SALES_RECEIPT){
            this.PaymentRefNum = 'To Print';
            this.DepositToAccountRef = new QBInnerEntityWrapper(AccountingUtil.getChartofAccount(AccountingUtil.isNewPaymentAccountingApplicable(customerInvoiceRecord.AccountingCOInvoiceHeaderRec.COInvoiceDate.date()) ? 'Checkout Clearing' :'Customer Deposits'));
        }
    }

    public QBBaseInvoiceDTO(AccountingUnitPriceAndCost adjstmentRec) {
        this.SFId = adjstmentRec.Id;
        this.Id = adjstmentRec.JournalEntryAccountingId;
        this.SyncToken = adjstmentRec.JournalEntrySyncToken;
        
        this.DocNumber = adjstmentRec.CustomerReferenceNumber; 
        if(String.isNotBlank(adjstmentRec.CustomerReferenceNumber) && adjstmentRec.CustomerReferenceNumber.length() > 21) {
            this.DocNumber = adjstmentRec.CustomerReferenceNumber.substring(0, 21);
        }
        this.TxnDate = adjstmentRec.AdjustmentDate;
        QBInnerEntityWrapper currRef = QBUtil.getCurrencyRef();
        if(currRef != null) this.CurrencyRef = currRef;

        this.Line = new List<QBLineItemDTO>();
        this.Line.add(new QBLineItemDTO(adjstmentRec));
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
                    this.Line.add(new QBLineItemDTO(taxRec));
                }         
            }
        }   
    }
    
    public QBBaseInvoiceDTO(SObject arcrTxnRec, String categoryAccId) {
        String objName = String.valueOf(arcrTxnRec.getSObjectType());
        if(objName == Constants.NAMESPACE + 'CO_Deposit__c') {
            setARCRDepositData((CO_Deposit__c)arcrTxnRec, categoryAccId);
        } else if(objName == Constants.NAMESPACE + 'CO_Invoice_Payment__c') {
            setARCRPaymentData((CO_Invoice_Payment__c)arcrTxnRec, categoryAccId);
        }
    }

    public QBBaseInvoiceDTO(AccountingUnit consUnitRecord) {
        this.SFId = consUnitRecord.Id;
        this.Id = consUnitRecord.QBConsAccountingId;
        this.SyncToken = consUnitRecord.SyncTokenForCons;
        this.DocNumber = consUnitRecord.InvoiceNumber.replace('INV', 'CONS'); 
        String invoiceDate = DateTimeUtility.getFormttedDateFromDateTime(consUnitRecord.UnitInvoiceDate, 'dd/MM/yyyy');
        this.TxnDate = DateTimeUtility.getDateFromFormattedDateStr(invoiceDate);
        QBInnerEntityWrapper currRef = QBUtil.getCurrencyRef();
        if(currRef != null) this.CurrencyRef = currRef;
        
        this.Line = new List<QBLineItemDTO>();
        this.Line.add(new QBLineItemDTO(consUnitRecord));
        this.TotalAmt = this.Balance = consUnitRecord.AgreedPayout;
        this.GlobalTaxCalculation = QBUtil.TAX_NOT_APPLICABLE;
        this.CustomerRef = new QBInnerEntityWrapper(consUnitRecord.QBCustomerAccId, null);
        this.PrintStatus = 'PrintComplete';
        this.PrivateNote = 'Consignment payout:' + (String.isNotBlank(consUnitRecord.VIN) ? (' ' + consUnitRecord.VIN) : '');
    }

    public QBBaseInvoiceDTO(AccountingVendorReturn returnCRHeaderRecord) {
        this.Id = returnCRHeaderRecord.AccountingId;
        this.SyncToken = returnCRHeaderRecord.SyncToken;
        this.DocNumber = returnCRHeaderRecord.Name; 
        this.TxnDate = returnCRHeaderRecord.CreditedDate;
        QBInnerEntityWrapper currRef = QBUtil.getCurrencyRef();
        if(currRef != null) this.CurrencyRef = currRef;
        
        this.Line = new List<QBLineItemDTO>();

        Map<Id, List<AccountingFIFOBucket>> partIdToFIFOBucketMap = new Map<Id, List<AccountingFIFOBucket>>();
        Decimal Variance = 0;
        String description = '';
        Boolean isNonTaxableItemAvailble = false;
        for(AccountingVendorReturn.ReturnCRLineItemWrapper RCRLIRec : returnCRHeaderRecord.ReturnCRLIList) {
            this.Line.add(new QBLineItemDTO(RCRLIRec, returnCRHeaderRecord.AccountRef1, 
                                            returnCRHeaderRecord.TaxCodeAccountingId));

            Variance = ((RCRLIRec.ReturnQty * RCRLIRec.ItemCost) - RCRLIRec.InventoryCost);
            description = ''; 
            description += RCRLIRec.ItemDescription;
            if(Variance != 0) {
                isNonTaxableItemAvailble = true;
                String invAdjustmentsAccId = AccountingUtil.getChartofAccount('Inventory Adjustments');
                this.Line.add(new QBLineItemDTO((description + ' Receiving Adjustment'), Variance, invAdjustmentsAccId, QBUtil.nonTaxableCodeAccId)); // Changed account returnCRHeaderRecord.AccountRef1 => invAdjustmentsAccId #3313
                this.Line.add(new QBLineItemDTO((description + ' Inventory Adjustment'), (Variance * -1), returnCRHeaderRecord.AccountRef1, QBUtil.nonTaxableCodeAccId)); // RVOLIRec.Inventory_GL  // Changed account invAdjustmentsAccId => returnCRHeaderRecord.AccountRef1 #3313
            } 
        }
        // this.VendorRef = new VendorRefWrapper(returnCRHeaderRecord.VendorAccountingId, returnCRHeaderRecord.VendorName);
        this.TotalAmt = returnCRHeaderRecord.Total;
        this.Balance = returnCRHeaderRecord.Total; 

        Decimal TotalTaxAmount = returnCRHeaderRecord.Tax;
        Decimal taxValue = 0;
        String categoryRef = '';
        AccountingVendorReturn.AccountingPurchaseTax purchaseTax;
        
        if(QBUtil.isQBTaxCodesEnabled) {
            this.GlobalTaxCalculation = QBUtil.TAX_EXCLUDED;
            
            List<AccountingVendorReturn.TaxRateComponent> taxComponentList = new List<AccountingVendorReturn.TaxRateComponent>();
            for(Integer i=0 ; i<returnCRHeaderRecord.AccountingPurchaseTaxList.size(); i++) {
                purchaseTax = returnCRHeaderRecord.AccountingPurchaseTaxList[i];
                Decimal taxAmount = (purchaseTax.SalesTaxRate*returnCRHeaderRecord.ItemTotal/100);  
                Decimal taxableAmount = returnCRHeaderRecord.ItemTotal;
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
            
            Map<String, List<String>> nonTaxableTaxCodeToTaxRatesMap = QBUtil.getNonTaxableTaxCodeWithRates(QBUtil.PURCHASE);
            if(isNonTaxableItemAvailble && nonTaxableTaxCodeToTaxRatesMap.containsKey(QBUtil.nonTaxableCodeAccId)) {
                for(String taxRateAccId : nonTaxableTaxCodeToTaxRatesMap.get(QBUtil.nonTaxableCodeAccId)) {
                    taxComponentList.add(new AccountingVendorReturn.TaxRateComponent(0, 0, taxRateAccId, 0));
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
                    this.Line.add(new QBLineItemDTO('Purchase Tax - ' + purchaseTax.SalesTaxName, taxAmount, categoryRef));
                }
                purchaseTax = returnCRHeaderRecord.AccountingPurchaseTaxList[returnCRHeaderRecord.AccountingPurchaseTaxList.size() - 1];
                categoryRef = purchaseTax.CategoyRef != null ? purchaseTax.CategoyRef : AccountingUtil.getChartofAccount('Sales Tax');
                this.Line.add(new QBLineItemDTO('Purchase Tax - ' + purchaseTax.SalesTaxName, (TotalTaxAmount - taxValue), categoryRef));
            }
        }
    }

    public QBBaseInvoiceDTO(String id, String syncToken, String docNumber) {
        this.Id = id;
        this.SyncToken = syncToken;
        this.DocNumber = docNumber; 
        this.sparse = true;
    }

    private void setARCRDepositData(CO_Deposit__c depositRec, String categoryAccId) {
        String arCreditNumber = getARCreditNumber(depositRec);
        this.DocNumber = arCreditNumber + '_USED';
        if(this.DocNumber.length() > 21) {
            this.DocNumber = this.DocNumber.substring(0, 21);
            if(this.DocNumber == arCreditNumber) throw new BlackPurlException(QBUtil.AR_CREDIT_TOO_LONG_ERR_MSG);
        }

        this.TxnDate = depositRec.Payment_Date__c;
        this.Line = new List<QBLineItemDTO>();
        this.Line.add(new QBLineItemDTO(depositRec, categoryAccId));
        this.GlobalTaxCalculation = QBUtil.TAX_NOT_APPLICABLE;
        this.CustomerRef = new QBInnerEntityWrapper(depositRec.CO_Header__r.Customer__r.AccountingId__c, null);
        this.PrivateNote = getPrivateNoteString(depositRec, depositRec.AR_Credit_Number__c) + depositRec.CO_Header__r.Name;
        QBInnerEntityWrapper currRef = QBUtil.getCurrencyRef();
        if(currRef != null) this.CurrencyRef = currRef;
    }

    private void setARCRPaymentData(CO_Invoice_Payment__c coInvPaymentRec, String categoryAccId) {
        String arCreditNumber = getARCreditNumber(coInvPaymentRec);
        this.DocNumber = arCreditNumber + '_USED';
        if(this.DocNumber.length() > 21) {
            this.DocNumber = this.DocNumber.substring(0, 21);
            if(this.DocNumber == arCreditNumber) throw new BlackPurlException(QBUtil.AR_CREDIT_TOO_LONG_ERR_MSG);
        }

        this.TxnDate = coInvPaymentRec.Payment_Date__c;
        this.Line = new List<QBLineItemDTO>();
        this.Line.add(new QBLineItemDTO(coInvPaymentRec, categoryAccId));
        this.GlobalTaxCalculation = QBUtil.TAX_NOT_APPLICABLE;
        this.CustomerRef = new QBInnerEntityWrapper(coInvPaymentRec.CO_Invoice_Header__r.CO_Header__r.Customer__r.AccountingId__c, null);
        this.PrivateNote = getPrivateNoteString(coInvPaymentRec, coInvPaymentRec.AR_Credit_Number__c) + coInvPaymentRec.CO_Invoice_Header__r.CO_Header__r.Name;
        QBInnerEntityWrapper currRef = QBUtil.getCurrencyRef();
        if(currRef != null) this.CurrencyRef = currRef;
    }

    private static string getARCreditNumber(SObject arcrTxnRec) {
        String arCreditNumber = '';
        if(arcrTxnRec.get(Constants.NAMESPACE + 'Unapplied_Payment_Type__c') == COPaymentService.AR_PAYMENT) {
            arCreditNumber = String.valueOf(arcrTxnRec.get('Name'));
        } else if(arcrTxnRec.get(Constants.NAMESPACE + 'AR_Credit_Number__c') != null) {
            arCreditNumber = String.valueOf(arcrTxnRec.get(Constants.NAMESPACE + 'AR_Credit_Number__c'));
        }
        return arCreditNumber;
    } 

    public static string getPrivateNoteString(SObject arcrTxnRec, String arCreditNumber) {
        if(String.isBlank(arCreditNumber)) {
            arCreditNumber = '';
        }
        String privateNote = '';
        String objName = String.valueOf(arcrTxnRec.getSObjectType());
        if(objName == Constants.NAMESPACE + 'CO_Deposit__c') {
            if(String.valueOf(arcrTxnRec.get(Constants.NAMESPACE + 'Unapplied_Payment_Type__c')) == COPaymentService.AR_PAYMENT) {
                privateNote = 'AR payment ' + arCreditNumber + ' used as deposit on ';
            } else {
                privateNote = 'AR credit ' + arCreditNumber + ' used as deposit on ';
            }
        } else if(objName == Constants.NAMESPACE + 'CO_Invoice_Payment__c') {
            if(String.valueOf(arcrTxnRec.get(Constants.NAMESPACE + 'Unapplied_Payment_Type__c')) == COPaymentService.AR_PAYMENT) {
                privateNote = 'AR payment ' + arCreditNumber + ' used on ';
            } else {
                privateNote = 'AR credit ' + arCreditNumber + ' used as payment on ';
            }
        }
        return privateNote;
    } 

    public class QBLinkedTxn {
        public String TxnId;
        public String TxnType;
    }
}