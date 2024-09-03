public without sharing class QBJournalEntryDTO {
    public String SFId;
    public String Id;
    public String SyncToken;
    public String DocNumber;
    public Date TxnDate;
    public List<LineWrapper> Line;
    public String PrivateNote; 
    public QBInnerEntityWrapper CurrencyRef;
    public Decimal ExchangeRate = 1;


    public class AccountRefWrapper{
        public String value;
        
        public AccountRefWrapper(AccountingVendorReturn.AccountRefWrapper AccountRef) {
            this.value = AccountRef.AccountingId;
        }
        
        public AccountRefWrapper(String CategoryAccountRef) {
            this.value = CategoryAccountRef;
        }
     }

    public class VendorRefWrapper{
        public String value;
        public String name;
        
        public VendorRefWrapper(String value, String name) {
            this.value = value;
            this.name = name;
        }
    }



    public class LineWrapper {
		public String Description;
        public Decimal Amount;
        public String DetailType;
        public JournalEntryLineDetailWrapper JournalEntryLineDetail;
		
		public LineWrapper(String description, Decimal amount, String accountRef, String postingType, String entityRef) {
            this.Description = description ; 
            this.Amount = Amount.setScale(2, RoundingMode.HALF_UP);
            this.DetailType = 'JournalEntryLineDetail';   
            this.JournalEntryLineDetail = new JournalEntryLineDetailWrapper(accountRef, postingType, entityRef);   
        }

        public LineWrapper(String description, Decimal Amount, String AccountRef, String postingType) {
            this.Description = description;
            this.Amount = Amount.setScale(2, RoundingMode.HALF_UP);
            if(this.Amount < 0) {
            	this.Amount *= -1;
	}
            this.DetailType = 'JournalEntryLineDetail';   
            this.JournalEntryLineDetail = new JournalEntryLineDetailWrapper(AccountRef, postingType, null); 
        }

        public LineWrapper(AccountingFIFOBucket FIFOBucketRecord, String AccountRef, String postingType, String EntityRef) {
            FIFOBucketRecord.Cost = FIFOBucketRecord.Cost != null ? FIFOBucketRecord.Cost.setScale(2, RoundingMode.HALF_UP) : 0;
            String description = FIFOBucketRecord.PartNumber + ' - increased by '+ FIFOBucketRecord.QtyIn + '@$' + FIFOBucketRecord.Cost;
            if(FIFOBucketRecord.Reference == 'Pre Sold Cost Adjustment') {
                FIFOBucketRecord.Total = (FIFOBucketRecord.Cost * ((FIFOBucketRecord.QtyIn != null ? FIFOBucketRecord.QtyIn : 0)));
            }
            if(FIFOBucketRecord.SourceName == LogService.REOPEN_INVOICE) {
                description = 'Pre-sold cost adjustment reversal';
                FIFOBucketRecord.Total = (FIFOBucketRecord.Cost * ((FIFOBucketRecord.QtyIn != null ? FIFOBucketRecord.QtyIn : 0)));
            }
            this.Description = description;
            if(FIFOBucketRecord.Total < 0) {
                this.Amount = FIFOBucketRecord.Total * -1;
            } else {
                this.Amount = FIFOBucketRecord.Total;
            }
            this.Amount = this.Amount.setScale(2, RoundingMode.HALF_UP);
            this.DetailType = 'JournalEntryLineDetail';   
            this.JournalEntryLineDetail = new JournalEntryLineDetailWrapper(AccountRef, postingType, EntityRef);   
        }
         
        public LineWrapper(AccountingFIFOBucketActivityLineItem FIFOBucketActivityLineItemRecord, String AccountRef, String postingType, String EntityRef) {
            FIFOBucketActivityLineItemRecord.Cost = FIFOBucketActivityLineItemRecord.Cost != null ? FIFOBucketActivityLineItemRecord.Cost.setScale(2, RoundingMode.HALF_UP) : 0;
            this.Amount = FIFOBucketActivityLineItemRecord.Cost * FIFOBucketActivityLineItemRecord.QtyOut; /////////
        
            String description = FIFOBucketActivityLineItemRecord.PartNumber + ' - reduced by '+ FIFOBucketActivityLineItemRecord.QtyOut + '@$' + FIFOBucketActivityLineItemRecord.Cost;
            if(FIFOBucketActivityLineItemRecord.FIFOSource == 'Oversold'){
                description = FIFOBucketActivityLineItemRecord.PartNumber + ' - resolved oversold of '+ (FIFOBucketActivityLineItemRecord.QtyOut*-1) + '@$' + FIFOBucketActivityLineItemRecord.Cost;
            }
            if(FIFOBucketActivityLineItemRecord.Reference == 'Vendor Return'){
                description = FIFOBucketActivityLineItemRecord.PartNumber + ' - Returned '+ FIFOBucketActivityLineItemRecord.QtyOut + '@$' + FIFOBucketActivityLineItemRecord.Cost;
            } else if(FIFOBucketActivityLineItemRecord.COGS_GL == AccountRef && FIFOBucketActivityLineItemRecord.Reference == 'Pre Sold Cost Adjustment On Existing FIFO') {
                description = FIFOBucketActivityLineItemRecord.PartNumber + ' - reduced by '+ FIFOBucketActivityLineItemRecord.BucketQtyOut + '@$' + FIFOBucketActivityLineItemRecord.BucketCost;
                this.Amount = FIFOBucketActivityLineItemRecord.BucketCost * FIFOBucketActivityLineItemRecord.BucketQtyOut; 
            } else if((FIFOBucketActivityLineItemRecord.Inventory_GL == AccountRef || AccountingUtil.getChartofAccount('Inventory Adjustments') == AccountRef) && FIFOBucketActivityLineItemRecord.Reference == 'Pre Sold Cost Adjustment On Existing FIFO') {
                if(postingType == 'Credit') {
                    description = FIFOBucketActivityLineItemRecord.PartNumber + ' - reduced by '+ FIFOBucketActivityLineItemRecord.BucketQtyRemaining + '@$' + FIFOBucketActivityLineItemRecord.BucketCost;
                    this.Amount = FIFOBucketActivityLineItemRecord.BucketCost * FIFOBucketActivityLineItemRecord.BucketQtyRemaining; 
                } else {
                    description = FIFOBucketActivityLineItemRecord.PartNumber + ' - reduced by '+ FIFOBucketActivityLineItemRecord.BucketQtyIn + '@$' + FIFOBucketActivityLineItemRecord.BucketCost;
                    this.Amount = FIFOBucketActivityLineItemRecord.BucketCost * FIFOBucketActivityLineItemRecord.BucketQtyIn; 
            }
            } else if(FIFOBucketActivityLineItemRecord.Reference == 'Pre Sold Cost Adjustment On New FIFO') {
                description = FIFOBucketActivityLineItemRecord.PartNumber + ' - reduced by '+ FIFOBucketActivityLineItemRecord.BucketQtyOut + '@$' + FIFOBucketActivityLineItemRecord.BucketCost;
                this.Amount = FIFOBucketActivityLineItemRecord.BucketCost * FIFOBucketActivityLineItemRecord.BucketQtyOut; 
            } 
            this.Description = description;
            if(this.Amount < 0) {
                this.Amount = this.Amount * -1;
                this.Amount = this.Amount.setScale(2, RoundingMode.HALF_UP);
            }
            this.DetailType = 'JournalEntryLineDetail';   
            this.JournalEntryLineDetail = new JournalEntryLineDetailWrapper(AccountRef, postingType, EntityRef);   
        }

        public LineWrapper(String description, Decimal Amount, Decimal UnitQtyAmount, COInvoiceJournalEntryService.QuickBooksCustomerInvoiceItemsHelper COInvoiceJournalEntryRecord, String AccountRef, String postingType, Boolean DealUnitLineForDealMerchOrService, Boolean isInternalServiceTax) {
            UnitQtyAmount = UnitQtyAmount != null ? UnitQtyAmount.setScale(3, RoundingMode.HALF_UP) : 0;
            COInvoiceJournalEntryRecord.Qty = COInvoiceJournalEntryRecord.Qty != null ? COInvoiceJournalEntryRecord.Qty.setScale(2, RoundingMode.HALF_UP) : 0;
            if(isInternalServiceTax) {
                this.Description = COInvoiceJournalEntryRecord.Description;
            } else if(DealUnitLineForDealMerchOrService) {
                this.Description = COInvoiceJournalEntryRecord.DealUnitDescription;
            } else if(COInvoiceJournalEntryRecord.IsLaborWithTechnicianHoursCostingEnabled) {
                this.Description = description + COInvoiceJournalEntryRecord.Description;
            } else {
                this.Description = description + COInvoiceJournalEntryRecord.Description + ' ' + COInvoiceJournalEntryRecord.Qty + '@' + UnitQtyAmount; /////////
            }
            this.Amount = Amount.setScale(2, RoundingMode.HALF_UP);
            if(this.Amount < 0) {
                this.Amount *= -1;
            }
            this.DetailType = 'JournalEntryLineDetail';   
            this.JournalEntryLineDetail = new JournalEntryLineDetailWrapper(AccountRef, postingType, COInvoiceJournalEntryRecord.SubletVendorAccId);   
                
        }
	}
    

    public class JournalEntryLineDetailWrapper{
        public String PostingType;
        public QBInnerEntityWrapper AccountRef;
        public EntityWrapper Entity;
        
        public JournalEntryLineDetailWrapper(String accountRef, String postingType, String entityRef) {
            this.PostingType = postingType; 
            this.AccountRef = new QBInnerEntityWrapper(accountRef, null);
            if(String.isNotBlank(entityRef)) {
            this.Entity = new EntityWrapper(entityRef);
        	}
    	}
    }

    public class EntityWrapper {
        public QBInnerEntityWrapper EntityRef;

        public EntityWrapper(String entityRef) {
            this.EntityRef = new QBInnerEntityWrapper(entityRef, null);
        }
    }

    public QBJournalEntryDTO(AccountingCODeposit coDepositRec) {
        this.SFId = coDepositRec.Id;
        this.Id = coDepositRec.JournalEntryAccountingId;
        this.SyncToken = coDepositRec.JournalEntrySyncToken;
        this.DocNumber = coDepositRec.DepositName; 
        this.TxnDate = coDepositRec.PaymentDate;
        String memo = AccountingUtil.getDepositMemo(coDepositRec);
        String lineItemDesc = AccountingUtil.getDepositLineItemDesc(coDepositRec);
        this.PrivateNote = memo;
        QBInnerEntityWrapper currRef = QBUtil.getCurrencyRef();
        if(currRef != null) this.CurrencyRef = currRef;

        this.Line = new List<LineWrapper>();
        String undepFundsAccId = AccountingUtil.getPaymentUndepositedFundAccId(coDepositRec.PaymentMethod);
        String customerDepAccId = AccountingUtil.getChartofAccount('Customer Deposits');
        String storeCreditAccrualAccId = AccountingUtil.getChartofAccount('Store Credit Accrual');
        String paymentSurchargeAccId = AccountingUtil.getChartofAccount('Payment Method Surcharges');
        String cashRecClearingAccId = AccountingUtil.getChartofAccount('Cash Rec Clearing');
        String newUndepFundsAccId = AccountingUtil.getChartofAccount('Undeposited Funds');
        String giftCardLiabilityAccId = AccountingUtil.getChartofAccount('Gift Card liability');
        if(AccountingUtil.isNewPaymentAccountingApplicable(coDepositRec.PaymentDate)){
            if(coDepositRec.Amount > 0) {
                if(coDepositRec.PaymentMethod == 'Direct Deposit' || coDepositRec.PaymentMethod == 'Financing') {
                    this.Line.add(new LineWrapper(lineItemDesc, coDepositRec.Amount, customerDepAccId, 'Credit', coDepositRec.customer.AccountingId));
                    this.Line.add(new LineWrapper(lineItemDesc, coDepositRec.Amount, newUndepFundsAccId, 'Debit', coDepositRec.customer.AccountingId));
                } else if(coDepositRec.PaymentMethod == 'Store Credit') {
                    this.Line.add(new LineWrapper(lineItemDesc, coDepositRec.Amount, customerDepAccId, 'Credit', coDepositRec.customer.AccountingId));
                    this.Line.add(new LineWrapper(lineItemDesc, coDepositRec.Amount, storeCreditAccrualAccId, 'Debit', coDepositRec.customer.AccountingId));    
                } else if(coDepositRec.PaymentMethod == 'Payment Surcharge') {
                    this.Line.add(new LineWrapper(lineItemDesc, coDepositRec.Amount, customerDepAccId, 'Credit', coDepositRec.customer.AccountingId));
                    this.Line.add(new LineWrapper(lineItemDesc, coDepositRec.Amount, paymentSurchargeAccId, 'Debit', coDepositRec.customer.AccountingId));
                } else if(coDepositRec.PaymentMethod == 'Giftcard' || coDepositRec.PaymentMethod == 'Gift Card') {
                    this.Line.add(new LineWrapper(lineItemDesc, coDepositRec.Amount, customerDepAccId, 'Credit', coDepositRec.customer.AccountingId));
                    this.Line.add(new LineWrapper(lineItemDesc, coDepositRec.Amount, giftCardLiabilityAccId, 'Debit', coDepositRec.customer.AccountingId));
                } else {
                    this.Line.add(new LineWrapper(lineItemDesc, coDepositRec.Amount, customerDepAccId, 'Credit', coDepositRec.customer.AccountingId));
                    this.Line.add(new LineWrapper(lineItemDesc, coDepositRec.Amount, cashRecClearingAccId, 'Debit', coDepositRec.customer.AccountingId));
                }
            } else {
                if(coDepositRec.PaymentMethod == 'Direct Deposit' || coDepositRec.PaymentMethod == 'Financing') {
                    this.Line.add(new LineWrapper(lineItemDesc, coDepositRec.Amount * -1, customerDepAccId, 'Debit', coDepositRec.customer.AccountingId));
                    this.Line.add(new LineWrapper(lineItemDesc, coDepositRec.Amount * -1, newUndepFundsAccId, 'Credit', coDepositRec.customer.AccountingId));
                } else if(coDepositRec.PaymentMethod == 'Store Credit') {
                    this.Line.add(new LineWrapper(lineItemDesc, coDepositRec.Amount * -1, customerDepAccId, 'Debit', coDepositRec.customer.AccountingId));
                    this.Line.add(new LineWrapper(lineItemDesc, coDepositRec.Amount * -1, storeCreditAccrualAccId, 'Credit', coDepositRec.customer.AccountingId));    
                } else if(coDepositRec.PaymentMethod == 'Payment Surcharge') {
                    this.Line.add(new LineWrapper(lineItemDesc, coDepositRec.Amount * -1, customerDepAccId, 'Debit', coDepositRec.customer.AccountingId));
                    this.Line.add(new LineWrapper(lineItemDesc, coDepositRec.Amount * -1, paymentSurchargeAccId, 'Credit', coDepositRec.customer.AccountingId));
                } else if(coDepositRec.PaymentMethod == 'Giftcard' || coDepositRec.PaymentMethod == 'Gift Card') {
                    this.Line.add(new LineWrapper(lineItemDesc, coDepositRec.Amount * -1, customerDepAccId, 'Debit', coDepositRec.customer.AccountingId));
                    this.Line.add(new LineWrapper(lineItemDesc, coDepositRec.Amount * -1, giftCardLiabilityAccId, 'Credit', coDepositRec.customer.AccountingId));
                } else {
                    this.Line.add(new LineWrapper(lineItemDesc, coDepositRec.Amount * -1, customerDepAccId, 'Debit', coDepositRec.customer.AccountingId));
                    this.Line.add(new LineWrapper(lineItemDesc, coDepositRec.Amount * -1, cashRecClearingAccId, 'Credit', coDepositRec.customer.AccountingId));
                }
            }
        } else {
            if(coDepositRec.Amount > 0) {
                String debitAccId = coDepositRec.PaymentMethod == 'Store Credit' ? storeCreditAccrualAccId : 
                                    (coDepositRec.PaymentMethod == 'Payment Surcharge' ? paymentSurchargeAccId : undepFundsAccId);
                this.Line.add(new LineWrapper(lineItemDesc, coDepositRec.Amount, customerDepAccId, 'Credit', coDepositRec.customer.AccountingId));
                this.Line.add(new LineWrapper(lineItemDesc, coDepositRec.Amount, debitAccId, 'Debit', coDepositRec.customer.AccountingId));
            } else {
                String creditAccId = coDepositRec.PaymentMethod == 'Store Credit' ? storeCreditAccrualAccId : 
                                    (coDepositRec.PaymentMethod == 'Payment Surcharge' ? paymentSurchargeAccId : undepFundsAccId);
                this.Line.add(new LineWrapper(lineItemDesc, coDepositRec.Amount * -1, customerDepAccId, 'Debit', coDepositRec.customer.AccountingId));
                this.Line.add(new LineWrapper(lineItemDesc, coDepositRec.Amount * -1, creditAccId, 'Credit', coDepositRec.customer.AccountingId));
            }
        }
    }

    public QBJournalEntryDTO(AccountingCOInvoicePayment COInvoicePaymentRecord) {
        this.SFId = COInvoicePaymentRecord.Id;
        String customerName = '';
        if(String.isNotBlank(COInvoicePaymentRecord.customer.Name)){
            customerName = COInvoicePaymentRecord.customer.Name;
        } else if(COInvoicePaymentRecord.COType == Constants.CASH_SALE) {
            customerName = Constants.CASH_SALE;
        } else if(COInvoicePaymentRecord.COType == Constants.INTERNAL_SERVICE) {
            customerName = Constants.INTERNAL_SERVICE;
        }
        
        String docNumber = COInvoicePaymentRecord.COInvoicePaymentNumber;
        String coNumber = COInvoicePaymentRecord.CustomerOrderNumber;
        String paymentMethod = COInvoicePaymentRecord.PaymentMethod;
        String entityType = 'Payment';

        this.Id = COInvoicePaymentRecord.JournalEntryAccountingId;
        this.SyncToken = COInvoicePaymentRecord.JournalEntrySyncToken;
        this.DocNumber = COInvoicePaymentRecord.COInvoicePaymentNumber; 
        this.TxnDate = COInvoicePaymentRecord.PaymentDate;
        this.PrivateNote = docNumber + ';' + customerName + ';' + coNumber + ';' + paymentMethod + ';' + entityType;
        String lineItemDesc = paymentMethod + ';' + entityType + ';' + docNumber + ';' + customerName + ';' + coNumber;
        QBInnerEntityWrapper currRef = QBUtil.getCurrencyRef();
        if(currRef != null) this.CurrencyRef = currRef;

        this.Line = new List<LineWrapper>();
        String undepFundsAccId = AccountingUtil.getPaymentUndepositedFundAccId(COInvoicePaymentRecord.PaymentMethod);
        String customerDepAccId = AccountingUtil.getChartofAccount('Customer Deposits');
        String cashRoundingAccId = AccountingUtil.getChartofAccount('Cash Rounding');
        String storeCreditAccrualAccId = AccountingUtil.getChartofAccount('Store Credit Accrual');
        String paymentSurchargeAccId = AccountingUtil.getChartofAccount('Payment Method Surcharges');
        String cashRecClearingAccId = AccountingUtil.getChartofAccount('Cash Rec Clearing');
        String checkoutClearingAccId = AccountingUtil.getChartofAccount('Checkout Clearing');
        String newUndepFundsAccId = AccountingUtil.getChartofAccount('Undeposited Funds');
        String giftCardLiabilityAccId = AccountingUtil.getChartofAccount('Gift Card liability');
        if(AccountingUtil.isNewPaymentAccountingApplicable(COInvoicePaymentRecord.PaymentDate)){
            if(COInvoicePaymentRecord.Amount > 0) {
                if(COInvoicePaymentRecord.PaymentMethod == 'Cash Rounding') {
                    this.Line.add(new LineWrapper(lineItemDesc, COInvoicePaymentRecord.Amount, cashRoundingAccId, 'Debit', COInvoicePaymentRecord.customer.AccountingId)); 
                    this.Line.add(new LineWrapper(lineItemDesc, COInvoicePaymentRecord.Amount, checkoutClearingAccId, 'Credit', COInvoicePaymentRecord.customer.AccountingId)); 
                } else if(COInvoicePaymentRecord.PaymentMethod == 'Payment Surcharge') {
                    this.Line.add(new LineWrapper(lineItemDesc, COInvoicePaymentRecord.Amount, paymentSurchargeAccId, 'Debit', COInvoicePaymentRecord.customer.AccountingId)); 
                    this.Line.add(new LineWrapper(lineItemDesc, COInvoicePaymentRecord.Amount, checkoutClearingAccId, 'Credit', COInvoicePaymentRecord.customer.AccountingId));
                } else if(COInvoicePaymentRecord.PaymentMethod == 'Direct Deposit') {
                    this.Line.add(new LineWrapper(lineItemDesc, COInvoicePaymentRecord.Amount, newUndepFundsAccId, 'Debit', COInvoicePaymentRecord.customer.AccountingId)); 
                    this.Line.add(new LineWrapper(lineItemDesc, COInvoicePaymentRecord.Amount, checkoutClearingAccId, 'Credit', COInvoicePaymentRecord.customer.AccountingId));
                } else if(COInvoicePaymentRecord.PaymentMethod == 'Gift Card' || COInvoicePaymentRecord.PaymentMethod == 'Giftcard') {
                    this.Line.add(new LineWrapper(lineItemDesc, COInvoicePaymentRecord.Amount, giftCardLiabilityAccId, 'Debit', COInvoicePaymentRecord.customer.AccountingId));
                    this.Line.add(new LineWrapper(lineItemDesc, COInvoicePaymentRecord.Amount, checkoutClearingAccId, 'Credit', COInvoicePaymentRecord.customer.AccountingId));
                } else if(COInvoicePaymentRecord.PaymentMethod == 'Store Credit') {
                    this.Line.add(new LineWrapper(lineItemDesc, COInvoicePaymentRecord.Amount, storeCreditAccrualAccId, 'Debit', COInvoicePaymentRecord.customer.AccountingId)); 
                    this.Line.add(new LineWrapper(lineItemDesc, COInvoicePaymentRecord.Amount, checkoutClearingAccId, 'Credit', COInvoicePaymentRecord.customer.AccountingId)); 
                } else if(COInvoicePaymentRecord.PaymentMethod == 'Use Deposit' || COInvoicePaymentRecord.PaymentMethod == AccountingUtil.USE_DEAL_DEPOSIT) {
                    this.Line.add(new LineWrapper(lineItemDesc, COInvoicePaymentRecord.Amount, customerDepAccId, 'Debit', COInvoicePaymentRecord.customer.AccountingId)); 
                    this.Line.add(new LineWrapper(lineItemDesc, COInvoicePaymentRecord.Amount, checkoutClearingAccId, 'Credit', COInvoicePaymentRecord.customer.AccountingId)); 
                } else{
                    this.Line.add(new LineWrapper(lineItemDesc, COInvoicePaymentRecord.Amount, cashRecClearingAccId, 'Debit', COInvoicePaymentRecord.customer.AccountingId)); 
                    this.Line.add(new LineWrapper(lineItemDesc, COInvoicePaymentRecord.Amount, checkoutClearingAccId, 'Credit', COInvoicePaymentRecord.customer.AccountingId)); 
                }
            } else {
                if(COInvoicePaymentRecord.PaymentMethod == 'Cash Rounding') {
                    this.Line.add(new LineWrapper(lineItemDesc, COInvoicePaymentRecord.Amount * -1, cashRoundingAccId, 'Credit', COInvoicePaymentRecord.customer.AccountingId)); 
                    this.Line.add(new LineWrapper(lineItemDesc, COInvoicePaymentRecord.Amount * -1, checkoutClearingAccId, 'Debit', COInvoicePaymentRecord.customer.AccountingId));
                } else if(COInvoicePaymentRecord.PaymentMethod == 'Payment Surcharge') {
                    this.Line.add(new LineWrapper(lineItemDesc, COInvoicePaymentRecord.Amount * -1, paymentSurchargeAccId, 'Credit', COInvoicePaymentRecord.customer.AccountingId)); 
                    this.Line.add(new LineWrapper(lineItemDesc, COInvoicePaymentRecord.Amount * -1, checkoutClearingAccId, 'Debit', COInvoicePaymentRecord.customer.AccountingId)); 
                } else if(COInvoicePaymentRecord.PaymentMethod == 'Direct Deposit') {
                    this.Line.add(new LineWrapper(lineItemDesc, COInvoicePaymentRecord.Amount * -1, newUndepFundsAccId, 'Credit', COInvoicePaymentRecord.customer.AccountingId)); 
                    this.Line.add(new LineWrapper(lineItemDesc, COInvoicePaymentRecord.Amount * -1, checkoutClearingAccId, 'Debit', COInvoicePaymentRecord.customer.AccountingId)); 
                } else if(COInvoicePaymentRecord.PaymentMethod == 'Gift Card' || COInvoicePaymentRecord.PaymentMethod == 'Giftcard') {
                    this.Line.add(new LineWrapper(lineItemDesc, COInvoicePaymentRecord.Amount * -1, giftCardLiabilityAccId, 'Credit', COInvoicePaymentRecord.customer.AccountingId)); 
                    this.Line.add(new LineWrapper(lineItemDesc, COInvoicePaymentRecord.Amount * -1, checkoutClearingAccId, 'Debit', COInvoicePaymentRecord.customer.AccountingId)); 
                } else if(COInvoicePaymentRecord.PaymentMethod == 'Store Credit') {
                    this.Line.add(new LineWrapper(lineItemDesc, COInvoicePaymentRecord.Amount * -1, storeCreditAccrualAccId, 'Credit', COInvoicePaymentRecord.customer.AccountingId));
                    this.Line.add(new LineWrapper(lineItemDesc, COInvoicePaymentRecord.Amount * -1, checkoutClearingAccId, 'Debit', COInvoicePaymentRecord.customer.AccountingId)); 
                } else if(COInvoicePaymentRecord.PaymentMethod == 'Use Deposit' || COInvoicePaymentRecord.PaymentMethod == AccountingUtil.USE_DEAL_DEPOSIT) {
                    this.Line.add(new LineWrapper(lineItemDesc, COInvoicePaymentRecord.Amount * -1, customerDepAccId, 'Credit', COInvoicePaymentRecord.customer.AccountingId)); 
                    this.Line.add(new LineWrapper(lineItemDesc, COInvoicePaymentRecord.Amount * -1, checkoutClearingAccId, 'Debit', COInvoicePaymentRecord.customer.AccountingId)); 
                } else {
                    this.Line.add(new LineWrapper(lineItemDesc, COInvoicePaymentRecord.Amount * -1, cashRecClearingAccId, 'Credit', COInvoicePaymentRecord.customer.AccountingId));
                    this.Line.add(new LineWrapper(lineItemDesc, COInvoicePaymentRecord.Amount * -1, checkoutClearingAccId, 'Debit', COInvoicePaymentRecord.customer.AccountingId)); 
                }
            }
        } else {
            if(COInvoicePaymentRecord.Amount > 0) {
                if(COInvoicePaymentRecord.PaymentMethod == 'Cash Rounding') {
                    this.Line.add(new LineWrapper(lineItemDesc, COInvoicePaymentRecord.Amount, cashRoundingAccId, 'Debit', COInvoicePaymentRecord.customer.AccountingId)); //Cash Rounding
                    this.Line.add(new LineWrapper(lineItemDesc, COInvoicePaymentRecord.Amount, customerDepAccId, 'Credit', COInvoicePaymentRecord.customer.AccountingId)); //Undeposited Funds
                } else if(COInvoicePaymentRecord.PaymentMethod == 'Store Credit') {
                    this.Line.add(new LineWrapper(lineItemDesc, COInvoicePaymentRecord.Amount, customerDepAccId, 'Credit', COInvoicePaymentRecord.customer.AccountingId)); //Customer Deposits
                    this.Line.add(new LineWrapper(lineItemDesc, COInvoicePaymentRecord.Amount, storeCreditAccrualAccId, 'Debit', COInvoicePaymentRecord.customer.AccountingId)); //Store Credit Accrual
                } else if(COInvoicePaymentRecord.PaymentMethod == 'Payment Surcharge') {
                    this.Line.add(new LineWrapper(lineItemDesc, COInvoicePaymentRecord.Amount, paymentSurchargeAccId, 'Debit', COInvoicePaymentRecord.customer.AccountingId)); // Payment Surcharge
                    this.Line.add(new LineWrapper(lineItemDesc, COInvoicePaymentRecord.Amount, customerDepAccId, 'Credit', COInvoicePaymentRecord.customer.AccountingId)); // Undeposited Funds
                } else{
                    this.Line.add(new LineWrapper(lineItemDesc, COInvoicePaymentRecord.Amount, undepFundsAccId, 'Debit', COInvoicePaymentRecord.customer.AccountingId)); //Undeposited Funds
                    this.Line.add(new LineWrapper(lineItemDesc, COInvoicePaymentRecord.Amount, customerDepAccId, 'Credit', COInvoicePaymentRecord.customer.AccountingId)); //Customer Deposits	
                }
            } else {
                if(COInvoicePaymentRecord.PaymentMethod == 'Cash Rounding') {
                    this.Line.add(new LineWrapper(lineItemDesc, COInvoicePaymentRecord.Amount * -1, cashRoundingAccId, 'Credit', COInvoicePaymentRecord.customer.AccountingId)); //Customer Deposits
                    this.Line.add(new LineWrapper(lineItemDesc, COInvoicePaymentRecord.Amount * -1, customerDepAccId, 'Debit', COInvoicePaymentRecord.customer.AccountingId)); //Undeposited Funds
                } else if(COInvoicePaymentRecord.PaymentMethod == 'Store Credit') {
                    this.Line.add(new LineWrapper(lineItemDesc, COInvoicePaymentRecord.Amount * -1, customerDepAccId, 'Debit', COInvoicePaymentRecord.customer.AccountingId)); //Customer Deposits
                    this.Line.add(new LineWrapper(lineItemDesc, COInvoicePaymentRecord.Amount * -1, storeCreditAccrualAccId, 'Credit', COInvoicePaymentRecord.customer.AccountingId)); //Store Credit Accrual
                } else if(COInvoicePaymentRecord.PaymentMethod == 'Payment Surcharge') {
                    this.Line.add(new LineWrapper(lineItemDesc, COInvoicePaymentRecord.Amount * -1, paymentSurchargeAccId, 'Credit', COInvoicePaymentRecord.customer.AccountingId)); // Payment Surcharge
                    this.Line.add(new LineWrapper(lineItemDesc, COInvoicePaymentRecord.Amount * -1, customerDepAccId, 'Debit', COInvoicePaymentRecord.customer.AccountingId)); // Undeposited Funds
                } else {
                    this.Line.add(new LineWrapper(lineItemDesc, COInvoicePaymentRecord.Amount * -1, undepFundsAccId, 'Credit', COInvoicePaymentRecord.customer.AccountingId)); //Undeposited Funds
                    this.Line.add(new LineWrapper(lineItemDesc, COInvoicePaymentRecord.Amount * -1, customerDepAccId, 'Debit', COInvoicePaymentRecord.customer.AccountingId)); //Customer Deposits
                }
            }
        }
    }
    
    public QBJournalEntryDTO(AccountingStoreCredit StoreCreditRecord){
        this.SFId = StoreCreditRecord.Id;
        String description = '';
        String memo = StoreCreditRecord.customer.Name + ';' +
                                StoreCreditRecord.StoreCreditReference + ';StoreCredit';

        this.Id = StoreCreditRecord.JournalEntryAccountingId;
        this.SyncToken = StoreCreditRecord.JournalEntrySyncToken; 
        this.DocNumber = StoreCreditRecord.StoreCreditName; 
        this.TxnDate = StoreCreditRecord.CreatedDate;
        this.PrivateNote = memo;
        QBInnerEntityWrapper currRef = QBUtil.getCurrencyRef();
        if(currRef != null) this.CurrencyRef = currRef;

        this.Line = new List<LineWrapper>();
        String storeCreditAccrualAccId = AccountingUtil.getChartofAccount('Store Credit Accrual');
        String storeCreditExpenseAccId = AccountingUtil.getChartofAccount('Store Credit Expense');
        if(StoreCreditRecord.Amount > 0) {
            this.Line.add(new LineWrapper(memo, StoreCreditRecord.Amount, storeCreditAccrualAccId, 'Credit', StoreCreditRecord.customer.AccountingId)); //Customer Deposits
            this.Line.add(new LineWrapper(memo, StoreCreditRecord.Amount, storeCreditExpenseAccId, 'Debit', StoreCreditRecord.customer.AccountingId)); //Undeposited Funds
        } else {
            this.Line.add(new LineWrapper(memo, StoreCreditRecord.Amount * -1, storeCreditAccrualAccId, 'Debit', StoreCreditRecord.customer.AccountingId)); //Customer Deposits
            this.Line.add(new LineWrapper(memo, StoreCreditRecord.Amount * -1, storeCreditExpenseAccId, 'Credit', StoreCreditRecord.customer.AccountingId)); //Undeposited Funds
            
        }
    }

    public QBJournalEntryDTO(AccountingCountSession countSessionRecord) {
        this.SFId = countSessionRecord.Id;
        this.Id = countSessionRecord.QBAccountingId;	
        this.SyncToken = countSessionRecord.AccountingSyncToken;
        
        this.DocNumber = countSessionRecord.CountSessionNumber;
        this.TxnDate = countSessionRecord.CountDate;
        this.PrivateNote = countSessionRecord.CountSessionNumber +';' + countSessionRecord.Name +';' + 'Part Count';
        QBInnerEntityWrapper currRef = QBUtil.getCurrencyRef();
        if(currRef != null) this.CurrencyRef = currRef;
        
        this.Line = new List<LineWrapper>();
        String entityRef = null;
        
        for(AccountingCountSession.AccountingCountSessionLineItem countSessionLineItemRec : countSessionRecord.CountSessionLineItemList) {
            if(countSessionLineItemRec.TotalCostAdjustment != null && countSessionLineItemRec.TotalCostAdjustment != 0) {
                if(countSessionLineItemRec.TotalCostAdjustment > 0) {
                    this.Line.add(new LineWrapper(this.PrivateNote, countSessionLineItemRec.TotalCostAdjustment.setScale(2, RoundingMode.HALF_UP), countSessionLineItemRec.PartCategoryInventoryGL, 'Debit', entityRef));
                } else {
                    this.Line.add(new LineWrapper(this.PrivateNote, countSessionLineItemRec.TotalCostAdjustment.setScale(2, RoundingMode.HALF_UP) * -1, countSessionLineItemRec.PartCategoryInventoryGL, 'Credit', entityRef));
                }
            }
        }
        if(countSessionRecord.TotalCostAdjustment > 0) {
            this.Line.add(new LineWrapper(this.PrivateNote, countSessionRecord.TotalCostAdjustment.setScale(2, RoundingMode.HALF_UP), countSessionRecord.AdjustmentCategoryIncomeGL, 'Credit', entityRef));
        } else {
            this.Line.add(new LineWrapper(this.PrivateNote, countSessionRecord.TotalCostAdjustment.setScale(2, RoundingMode.HALF_UP) * -1, countSessionRecord.AdjustmentCategoryIncomeGL, 'Debit', entityRef));
        }
    }

    public QBJournalEntryDTO(AccountingCashReconciliation cashReconRecord) {
        this.SFId = cashReconRecord.Id;
        this.Id = cashReconRecord.AccountingId;	
        this.SyncToken = cashReconRecord.SyncToken;
        
        this.DocNumber = cashReconRecord.CashReconName;
        this.TxnDate = cashReconRecord.ReconciliationDate;
        this.PrivateNote = String.ValueOf(cashReconRecord.ReconciliationDate) +';' + 'Cash reconciliation' +';' + cashReconRecord.OptionalNote;
        this.PrivateNote = this.PrivateNote.length() > 1000 ? this.PrivateNote.substring(0, 1000) : this.PrivateNote;
        QBInnerEntityWrapper currRef = QBUtil.getCurrencyRef();
        if(currRef != null) this.CurrencyRef = currRef;
        
        this.Line = new List<LineWrapper>();
        String entityRef = null;
        String lineItemDesc;
        for(AccountingCashReconciliation.CashReconciliationPaymentWrapper reconPaymentRec : cashReconRecord.ReconPaymentList) {
            if(reconPaymentRec.ActualAmount != null && reconPaymentRec.ActualAmount != 0) {
                lineItemDesc = String.ValueOf(cashReconRecord.ReconciliationDate) + ' - '+ reconPaymentRec.PaymentName + ' - ' + reconPaymentRec.CashDrawerName;
                if(reconPaymentRec.ActualAmount > 0) {
                    this.Line.add(new LineWrapper(lineItemDesc, reconPaymentRec.ActualAmount.setScale(2, RoundingMode.HALF_UP), AccountingUtil.getChartofAccount('Undeposited Funds'), 'Debit', entityRef));
                } else {
                    this.Line.add(new LineWrapper(lineItemDesc, reconPaymentRec.ActualAmount.setScale(2, RoundingMode.HALF_UP) * -1, AccountingUtil.getChartofAccount('Undeposited Funds'), 'Credit', entityRef));
                }
            }
        }
        if(cashReconRecord.TotalProcessedAmount != 0) {
            if(cashReconRecord.TotalProcessedAmount > 0) {
                this.Line.add(new LineWrapper(String.ValueOf(cashReconRecord.ReconciliationDate) + ' - Cash reconciliation', cashReconRecord.TotalProcessedAmount.setScale(2, RoundingMode.HALF_UP), AccountingUtil.getChartofAccount('Cash Rec Clearing'), 'Credit', entityRef));
            } else {
                this.Line.add(new LineWrapper(String.ValueOf(cashReconRecord.ReconciliationDate) + ' - Cash reconciliation', cashReconRecord.TotalProcessedAmount.setScale(2, RoundingMode.HALF_UP) * -1, AccountingUtil.getChartofAccount('Cash Rec Clearing'), 'Debit', entityRef));
            }
        }

        if(cashReconRecord.TotalVariance != 0) {
            if(cashReconRecord.TotalVariance > 0) {
                this.Line.add(new LineWrapper(String.ValueOf(cashReconRecord.ReconciliationDate) + ' - Cash reconciliation', cashReconRecord.TotalVariance.setScale(2, RoundingMode.HALF_UP), AccountingUtil.getChartofAccount('Cash over/short'), 'Credit', entityRef));
            } else {
                this.Line.add(new LineWrapper(String.ValueOf(cashReconRecord.ReconciliationDate) + ' - Cash reconciliation', cashReconRecord.TotalVariance.setScale(2, RoundingMode.HALF_UP) * -1, AccountingUtil.getChartofAccount('Cash over/short'), 'Debit', entityRef));
            }
        }
        
    }

    public QBJournalEntryDTO(AccountingVendorReceiving VORRecord) {
        this.SFId = VORRecord.Id;
        this.Id = VORRecord.AccountingVORHeaderRec.JournalEntryAccountingId;
        this.SyncToken = VORRecord.AccountingVORHeaderRec.JournalEntrySyncToken;
        this.DocNumber = VORRecord.AccountingVORHeaderRec.VORName; 
        this.TxnDate = VORRecord.AccountingVORHeaderRec.FinalizedDate;
        QBInnerEntityWrapper currRef = QBUtil.getCurrencyRef();
        if(currRef != null) this.CurrencyRef = currRef;

        this.Line = new List<LineWrapper>();
        
        String baseDesc = VORRecord.AccountingVORHeaderRec.VORName + ';' + VORRecord.AccountingVORHeaderRec.VendorName + ';' +
                                VORRecord.AccountingVORHeaderRec.PackagingSlipNumber;
        String descriptionForCompleteVR = baseDesc + ';Total Receiving';
        String memo = baseDesc + ';Inventory receiving';
        this.PrivateNote = memo;
        List<String> newmy = new List<String>();
        
        for(AccountingVendorReceiving.AccountingVRGroupByGL VORGroupByGLRec : VORRecord.AccountingVRGroupByGLList) {
            String description = baseDesc + ';Inventory received';
            if(VORGroupByGLRec.Total > 0) {
                this.Line.add(new LineWrapper(description, VORGroupByGLRec.Total, VORGroupByGLRec.Inventory_GL, 'Debit', VORRecord.EntityRef.AccountingId)); //null
            } else{
                this.Line.add(new LineWrapper(description, VORGroupByGLRec.Total * -1, VORGroupByGLRec.Inventory_GL, 'Credit', VORRecord.EntityRef.AccountingId)); //null
            }
        }
        String APInvAccrualAccId = AccountingUtil.getChartofAccount('A/P Inventory Accrual');
        if(VORRecord.AccountingVORHeaderRec.ReceivingTotal > 0) {
           this.Line.add(new LineWrapper(descriptionForCompleteVR, VORRecord.AccountingVORHeaderRec.ReceivingTotal, APInvAccrualAccId, 'Credit', VORRecord.EntityRef.AccountingId)); 
        } else {
            this.Line.add(new LineWrapper(descriptionForCompleteVR, VORRecord.AccountingVORHeaderRec.ReceivingTotal * -1, APInvAccrualAccId, 'Debit', VORRecord.EntityRef.AccountingId));
        }
    }

    public QBJournalEntryDTO(AccountingFIFOBucket FIFOBucketRecord) {
        this.SFId = FIFOBucketRecord.Id;
        String memo = FIFOBucketRecord.PartNumber + ';' +
                                FIFOBucketRecord.SourceName;
        this.Id = FIFOBucketRecord.AccountingId;
        this.SyncToken = FIFOBucketRecord.SyncToken;
        this.DocNumber = FIFOBucketRecord.UniqueId; // FIFOBucketRecord.Name
        this.TxnDate = FIFOBucketRecord.CreatedDate;
        this.PrivateNote = memo;
        QBInnerEntityWrapper currRef = QBUtil.getCurrencyRef();
        if(currRef != null) this.CurrencyRef = currRef;

        this.Line = new List<LineWrapper>();
        if(FIFOBucketRecord.SourceName == LogService.REOPEN_INVOICE) {
            this.PrivateNote = FIFOBucketRecord.Reference + ';Pre-sold cost adjustment reversal';
            this.DocNumber = FIFOBucketRecord.Reference;
            if(FIFOBucketRecord.Cost > 0) {
                this.Line.add(new LineWrapper(FIFOBucketRecord, FIFOBucketRecord.COGS_GL, 'Credit', null));
                this.Line.add(new LineWrapper(FIFOBucketRecord, FIFOBucketRecord.Inventory_GL, 'Debit', null));
            } else {
                this.Line.add(new LineWrapper(FIFOBucketRecord, FIFOBucketRecord.Inventory_GL, 'Credit', null));
                this.Line.add(new LineWrapper(FIFOBucketRecord, FIFOBucketRecord.COGS_GL, 'Debit', null));
            }
        } else {
            String invAdjustmentsAccId = AccountingUtil.getChartofAccount('Inventory Adjustments');
            this.Line.add(new LineWrapper(FIFOBucketRecord, invAdjustmentsAccId, 'Credit', null));
            this.Line.add(new LineWrapper(FIFOBucketRecord, FIFOBucketRecord.Inventory_GL, 'Debit', null));
        }
    }

    public QBJournalEntryDTO(AccountingFIFOBucketActivityLineItem FIFOBucketActivityLineItemRecord) {
        this.SFId = FIFOBucketActivityLineItemRecord.Id;
        String memo = FIFOBucketActivityLineItemRecord.PartNumber + ';' +
                                (FIFOBucketActivityLineItemRecord.Reference.containsIgnoreCase('Pre Sold Cost Adjustment') ? 'Cost Adjustment' : FIFOBucketActivityLineItemRecord.Reference);
        if(FIFOBucketActivityLineItemRecord.Reference == 'Vendor Return'){
            memo += ';'+FIFOBucketActivityLineItemRecord.RMANumber;
        }
        this.Id = FIFOBucketActivityLineItemRecord.AccountingId;
        this.SyncToken = FIFOBucketActivityLineItemRecord.SyncToken;
        this.DocNumber = FIFOBucketActivityLineItemRecord.UniqueId; // FIFOBucketActivityLineItemRecord.Name
        this.TxnDate = FIFOBucketActivityLineItemRecord.CreatedDate;
        this.PrivateNote = memo;
        QBInnerEntityWrapper currRef = QBUtil.getCurrencyRef();
        if(currRef != null) this.CurrencyRef = currRef;
    
        this.Line = new List<LineWrapper>();
        String invAdjustmentsAccId = AccountingUtil.getChartofAccount('Inventory Adjustments');
        String APInvAccrualAccId = AccountingUtil.getChartofAccount('A/P Inventory Accrual');
        AccountingFIFOBucketActivityLineItem.EntityRefWrapper FIFOBucketActivityLineItemEntityRefRec;
        if(FIFOBucketActivityLineItemRecord.FIFOSource == 'Oversold') {
            this.Line.add(new LineWrapper(FIFOBucketActivityLineItemRecord, invAdjustmentsAccId, 'Credit', FIFOBucketActivityLineItemRecord.EntityRef.AccountingId));
            this.Line.add(new LineWrapper(FIFOBucketActivityLineItemRecord, FIFOBucketActivityLineItemRecord.Inventory_GL, 'Debit', null));
        } else if(FIFOBucketActivityLineItemRecord.Reference == 'Vendor Return') {
            this.Line.add(new LineWrapper(FIFOBucketActivityLineItemRecord, APInvAccrualAccId, 'Debit', FIFOBucketActivityLineItemRecord.EntityRef.AccountingId));
            this.Line.add(new LineWrapper(FIFOBucketActivityLineItemRecord, FIFOBucketActivityLineItemRecord.Inventory_GL, 'Credit', null));
        }  else if(FIFOBucketActivityLineItemRecord.Reference == 'Pre Sold Cost Adjustment On Existing FIFO') {
            this.Line.add(new LineWrapper(FIFOBucketActivityLineItemRecord, FIFOBucketActivityLineItemRecord.Inventory_GL, 'Credit', null));
            this.Line.add(new LineWrapper(FIFOBucketActivityLineItemRecord, FIFOBucketActivityLineItemRecord.COGS_GL, 'Credit', null));
            this.Line.add(new LineWrapper(FIFOBucketActivityLineItemRecord, invAdjustmentsAccId, 'Debit', FIFOBucketActivityLineItemRecord.EntityRef.AccountingId));
        } else if(FIFOBucketActivityLineItemRecord.Reference == 'Pre Sold Cost Adjustment On New FIFO') {
            this.Line.add(new LineWrapper(FIFOBucketActivityLineItemRecord, FIFOBucketActivityLineItemRecord.Inventory_GL, 'Credit', null));
            this.Line.add(new LineWrapper(FIFOBucketActivityLineItemRecord, FIFOBucketActivityLineItemRecord.COGS_GL, 'Debit', null));
        } else {
            this.Line.add(new LineWrapper(FIFOBucketActivityLineItemRecord, invAdjustmentsAccId, 'Debit', FIFOBucketActivityLineItemRecord.EntityRef.AccountingId));
            this.Line.add(new LineWrapper(FIFOBucketActivityLineItemRecord, FIFOBucketActivityLineItemRecord.Inventory_GL, 'Credit', null));
        }
    }

    public QBJournalEntryDTO(AccountingHoursLogged hoursLoggedRecord) {
        this.SFId = hoursLoggedRecord.Id;
        
        this.DocNumber = hoursLoggedRecord.Name;
        this.TxnDate = date.newinstance(hoursLoggedRecord.EndDate.year(), hoursLoggedRecord.EndDate.month(), hoursLoggedRecord.EndDate.day());
        this.PrivateNote = AccountingUtil.getHoursLoggedJENarration(hoursLoggedRecord);
        QBInnerEntityWrapper currRef = QBUtil.getCurrencyRef();
        if(currRef != null) this.CurrencyRef = currRef;
        
        String addJournalLineItemDesc = AccountingUtil.getHoursLoggedJELineItemDesc(hoursLoggedRecord, true);
        String removeJournalLineItemDesc = AccountingUtil.getHoursLoggedJELineItemDesc(hoursLoggedRecord, false);
        
        this.Line = new List<LineWrapper>();
        String wIPLaborInventoryGLAccId = AccountingUtil.getChartofAccount('WIP Labor Inventory');
        String wIPLaborExpenseGLAccId = AccountingUtil.getChartofAccount('WIP Labor Expense');
        String entityRef = null;
        
        if(hoursLoggedRecord.OldTotalCost != null || hoursLoggedRecord.IsRemoved) {
            Decimal cost = hoursLoggedRecord.IsRemoved ? hoursLoggedRecord.TotalCost : hoursLoggedRecord.OldTotalCost;
            if(cost > 0) {
                this.Line.add(new LineWrapper(removeJournalLineItemDesc, cost, wIPLaborExpenseGLAccId, 'Debit', entityRef));
                this.Line.add(new LineWrapper(removeJournalLineItemDesc, cost, wIPLaborInventoryGLAccId, 'Credit', entityRef));
            } else if(cost < 0) {
                this.Line.add(new LineWrapper(removeJournalLineItemDesc, cost * -1, wIPLaborInventoryGLAccId, 'Credit', entityRef));
                this.Line.add(new LineWrapper(removeJournalLineItemDesc, cost * -1, wIPLaborExpenseGLAccId, 'Debit', entityRef));
            }
        }
        if(!hoursLoggedRecord.IsRemoved && hoursLoggedRecord.TotalCost != 0) {
            if(hoursLoggedRecord.TotalCost > 0) {
                this.Line.add(new LineWrapper(addJournalLineItemDesc, hoursLoggedRecord.TotalCost, wIPLaborInventoryGLAccId, 'Debit', entityRef));
                this.Line.add(new LineWrapper(addJournalLineItemDesc, hoursLoggedRecord.TotalCost, wIPLaborExpenseGLAccId, 'Credit', entityRef));
            } else {
                this.Line.add(new LineWrapper(addJournalLineItemDesc, hoursLoggedRecord.TotalCost * -1, wIPLaborExpenseGLAccId, 'Credit', entityRef));
                this.Line.add(new LineWrapper(addJournalLineItemDesc, hoursLoggedRecord.TotalCost * -1, wIPLaborInventoryGLAccId, 'Debit', entityRef));
            }
        }
    }

    public QBJournalEntryDTO(AccountingUnit unitRec, String entityType) {
        this.SFId = unitRec.Id;
        if(entityType == IntegrationUtility.STOCK_UNIT_CATEGORY) {
            // Category change should create separate JE rather the override existing one
            //this.SyncToken = unitRec.SyncTokenForCategory; // We send GET req to fetch data from QB if it is from scrip/retry handler or syncToken != null
            unitRec.StockNumber = unitRec.StockNumber != null ? unitRec.StockNumber : '';
            String memo = unitRec.StockNumber + ';Category changed';
            String description = unitRec.StockNumber + ' - Category changed from ' + unitRec.OldCategoryName + ' to ' + unitRec.NewCategoryName;
            this.DocNumber = unitRec.StockNumber.length() > 21 ? unitRec.StockNumber.substring(0, 21) : unitRec.StockNumber;
            this.TxnDate = unitRec.ModifiedDate;
            this.PrivateNote = memo;
            this.Line = new List<LineWrapper>();
            String entityRef = null;
            if(unitRec.TotalInventoryValuation > 0) {
                this.Line.add(new LineWrapper(description, unitRec.TotalInventoryValuation, unitRec.OldCategoryInventoryGL, 'Credit', entityRef));
                this.Line.add(new LineWrapper(description, unitRec.TotalInventoryValuation, unitRec.NewCategoryInventoryGL, 'Debit', entityRef));
            } else {
                this.Line.add(new LineWrapper(description, unitRec.TotalInventoryValuation * -1, unitRec.OldCategoryInventoryGL, 'Debit', entityRef));
                this.Line.add(new LineWrapper(description, unitRec.TotalInventoryValuation * -1, unitRec.NewCategoryInventoryGL, 'Credit', entityRef));
            }
        } else if(entityType == IntegrationUtility.UNIT_INVOICE_JE) {
            //Unit Invoice JE
            this.SyncToken = unitRec.SyncTokenForUnitInvoiceJE;
            String purchaseTaxLiabilityCategory = '';
            String notionalInputTaxCat = '';
            if(String.isNotBlank(GeneralConfiguration.getTradeTaxPendingSaleCategory()) || String.isNotBlank(GeneralConfiguration.getPurchaseTaxLiabilityCategory())) {
                Set<String> categoryIdSet = new Set<String>{GeneralConfiguration.getTradeTaxPendingSaleCategory(), 
                                                            GeneralConfiguration.getPurchaseTaxLiabilityCategory()};
                categoryIdSet.remove(null);
                
                Map<String, Category__c> categoryIdToRecMap = new Map<String, Category__c>([Select Id, Income_GL__c from Category__c where Id IN: categoryIdSet]);
                purchaseTaxLiabilityCategory = categoryIdToRecMap.containsKey(GeneralConfiguration.getPurchaseTaxLiabilityCategory()) ? 
                        categoryIdToRecMap.get(GeneralConfiguration.getPurchaseTaxLiabilityCategory()).Income_GL__c : '';
                        
                notionalInputTaxCat = categoryIdToRecMap.containsKey(GeneralConfiguration.getTradeTaxPendingSaleCategory()) ? 
                                categoryIdToRecMap.get(GeneralConfiguration.getTradeTaxPendingSaleCategory()).Income_GL__c : '';
            }
            
            unitRec.StockNumber = unitRec.StockNumber != null ? unitRec.StockNumber : '';
            String memo = unitRec.ItemDesc + ';Purchase Tax Credit';
            this.DocNumber = unitRec.InvoiceNumber.length() > 21 ? unitRec.InvoiceNumber.substring(0, 21) : unitRec.InvoiceNumber;
            this.TxnDate = unitRec.CreatedDate;
            this.PrivateNote = memo;
            this.Line = new List<LineWrapper>();
            String entityRef = null;
            if(unitRec.PurchaseTaxCredit > 0) {
                this.Line.add(new LineWrapper(memo, unitRec.PurchaseTaxCredit, purchaseTaxLiabilityCategory, 'Credit', entityRef));
                this.Line.add(new LineWrapper(memo, unitRec.PurchaseTaxCredit, notionalInputTaxCat, 'Debit', entityRef));
            } else {
                this.Line.add(new LineWrapper(memo, unitRec.PurchaseTaxCredit * -1, purchaseTaxLiabilityCategory, 'Debit', entityRef));
                this.Line.add(new LineWrapper(memo, unitRec.PurchaseTaxCredit * -1, notionalInputTaxCat, 'Credit', entityRef));
            }
        } else if(entityType == IntegrationUtility.UNIT_NITC_JE) {
            setUnitNITCJEData(unitRec);
        }
        QBInnerEntityWrapper currRef = QBUtil.getCurrencyRef();
        if(currRef != null) this.CurrencyRef = currRef;
    }
    
    private void setUnitNITCJEData(AccountingUnit unitRec) {
        this.Id = unitRec.QBUnitNITCJEAccountingId;
        this.SyncToken = unitRec.SyncTokenForUnitNITCJE;
        this.DocNumber = (unitRec.StockNumber != null ? unitRec.StockNumber : '') + ' NITC';
        this.DocNumber = this.DocNumber.length() > 21 ? this.DocNumber.substring(0, 21) : this.DocNumber;
        this.TxnDate = unitRec.NITCDateClaimed;
        
        String memo = unitRec.VIN + ';NITC Claimed;Manually';
        this.PrivateNote = memo;
        
        this.Line = new List<LineWrapper>();
        String entityRef = null;
        String taxCategoryIncomeGL = '';
        Decimal amount = 0;
        Map<String, Category__c> tradeInTaxCategoryIdToRecMap = AccountingUtil.getTradeInTaxCategoryMap();
        String tradeTaxPendingSaleCategory = tradeInTaxCategoryIdToRecMap.containsKey(GeneralConfiguration.getTradeTaxPendingSaleCategory()) ? tradeInTaxCategoryIdToRecMap.get(GeneralConfiguration.getTradeTaxPendingSaleCategory()).Income_GL__c : '';
        
        if(unitRec.SalesTaxCredit != null && unitRec.SalesTaxCredit != 0) {
            amount = unitRec.SalesTaxCredit.setScale(2, RoundingMode.HALF_UP) * -1;
            taxCategoryIncomeGL = tradeInTaxCategoryIdToRecMap.containsKey(GeneralConfiguration.getTradeTaxLiabilityCategory()) ? tradeInTaxCategoryIdToRecMap.get(GeneralConfiguration.getTradeTaxLiabilityCategory()).Income_GL__c : '';
            
        } else if(unitRec.PurchaseTaxCredit != null && unitRec.PurchaseTaxCredit != 0) {
            amount = unitRec.PurchaseTaxCredit.setScale(2, RoundingMode.HALF_UP) * -1;
            taxCategoryIncomeGL = tradeInTaxCategoryIdToRecMap.containsKey(GeneralConfiguration.getPurchaseTaxLiabilityCategory()) ? tradeInTaxCategoryIdToRecMap.get(GeneralConfiguration.getPurchaseTaxLiabilityCategory()).Income_GL__c : '';
        }
        
        if(amount > 0) {
            this.Line.add(new LineWrapper(memo, amount, taxCategoryIncomeGL, 'Credit', entityRef));
            this.Line.add(new LineWrapper(memo, amount, tradeTaxPendingSaleCategory, 'Debit', entityRef));
        } else {
            this.Line.add(new LineWrapper(memo, amount * -1, taxCategoryIncomeGL, 'Debit', entityRef));
            this.Line.add(new LineWrapper(memo, amount * -1, tradeTaxPendingSaleCategory, 'Credit', entityRef));
        }
    }

    public QBJournalEntryDTO(AccountingPart partRec) {
        this.SFId = partRec.Id;
        this.SyncToken = partRec.SyncTokenCategory;
        partRec.PartNumber = partRec.PartNumber != null ? partRec.PartNumber : '';
        String memo = partRec.PartNumber + ';Category changed';
        String description = partRec.PartNumber + ' - Category changed from ' + partRec.OldCategoryName + ' to ' + partRec.NewCategoryName;
        this.DocNumber = partRec.PartNumber.length() > 21 ? partRec.PartNumber.substring(0, 21) : partRec.PartNumber;
        this.TxnDate = partRec.ModifiedDate;
        this.PrivateNote = memo;
        QBInnerEntityWrapper currRef = QBUtil.getCurrencyRef();
        if(currRef != null) this.CurrencyRef = currRef;

        this.Line = new List<LineWrapper>();
        String entityRef = null;
        if(partRec.TotalInventoryValuation > 0) {
            this.Line.add(new LineWrapper(description, partRec.TotalInventoryValuation, partRec.OldCategoryInventoryGL, 'Credit', entityRef));
            this.Line.add(new LineWrapper(description, partRec.TotalInventoryValuation, partRec.NewCategoryInventoryGL, 'Debit', entityRef));
        } else {
            this.Line.add(new LineWrapper(description, partRec.TotalInventoryValuation * -1, partRec.OldCategoryInventoryGL, 'Debit', entityRef));
            this.Line.add(new LineWrapper(description, partRec.TotalInventoryValuation * -1, partRec.NewCategoryInventoryGL, 'Credit', entityRef));
        }
    }
    
    public QBJournalEntryDTO(AccountingVendorInvoice vendorInvoiceRecord) {
        this.SFId = vendorInvoiceRecord.Id;
        this.Id = vendorInvoiceRecord.AccountingVIHeaderRec.QBVarinaceJEAccountingId;
        this.SyncToken = vendorInvoiceRecord.AccountingVIHeaderRec.SyncTokenForVarinaceJE;
        this.DocNumber = vendorInvoiceRecord.AccountingVIHeaderRec.InvoiceNumber;
        this.TxnDate = (vendorInvoiceRecord.AccountingVIHeaderRec.InvoiceDate != null) ? vendorInvoiceRecord.AccountingVIHeaderRec.InvoiceDate :
                        vendorInvoiceRecord.AccountingVIHeaderRec.CreatedDate;
        this.PrivateNote = vendorInvoiceRecord.AccountingVIHeaderRec.VIHeaderNumber + ';' + vendorInvoiceRecord.AccountingVIHeaderRec.InvoiceNumber + ';' +
                            vendorInvoiceRecord.AccountingVIHeaderRec.VendorName + ';' + 'Cost variances';
        QBInnerEntityWrapper currRef = QBUtil.getCurrencyRef();
        if(currRef != null) this.CurrencyRef = currRef;
        
        this.Line = new List<LineWrapper>();
        String entityRef = null;
        String VRNumberFoDesc = vendorInvoiceRecord.VRNumberSet.size() == 1 ? new List<String>(vendorInvoiceRecord.VRNumberSet)[0] + ';' : '';
        String description = vendorInvoiceRecord.AccountingVIHeaderRec.VIHeaderNumber + ';' + vendorInvoiceRecord.AccountingVIHeaderRec.VendorName + ';' +
        vendorInvoiceRecord.AccountingVIHeaderRec.InvoiceNumber + ';';
        
        for(AccountingVendorInvoice.AccountingVIGroupByGLAndType accVIGRec: vendorInvoiceRecord.AccountingVIGroupByGLAndTypeList) {
            if(accVIGRec.Type == AccountingVendorInvoice.INVENTORY_RECEIVED) continue;
            String lineType = accVIGRec.Total > 0 ? 'Debit' : 'Credit';
            accVIGRec.Total = accVIGRec.Total < 0 ? accVIGRec.Total * -1 : accVIGRec.Total;
            this.Line.add(new LineWrapper((VRNumberFoDesc + description + accVIGRec.Type), accVIGRec.Total, accVIGRec.GLNumber, lineType, entityRef));
        }
    }

    public QBJournalEntryDTO(AccountingVendorReturn vendorReturn) {
        this.SFId = vendorReturn.Id;
        this.Id = vendorReturn.QBVarianceJEAccountingId;	
        this.SyncToken = vendorReturn.SyncTokenForVarianceJE;
        this.DocNumber = vendorReturn.CreditMemoNumber;
        this.TxnDate = vendorReturn.CreditedDate;
        this.PrivateNote = vendorReturn.RTNNumber + ';' + vendorReturn.CreditMemoNumber + ';' + vendorReturn.VendorName + ';' + 'Cost variances';
                
        QBInnerEntityWrapper currRef = QBUtil.getCurrencyRef();
        if(currRef != null) this.CurrencyRef = currRef;
        String entityRef = null;
        this.Line = new List<LineWrapper>();
        for(AccountingVendorReturn.ReturnCRLineItemWrapper returnCRLI: vendorReturn.ReturnCRLIList) {
            if(returnCRLI.Variance != null && returnCRLI.Variance != 0) {
                if(returnCRLI.Variance > 0) {
                    this.Line.add(new LineWrapper((returnCRLI.ItemDescription + ';Return Cost Variance'), returnCRLI.Variance, AccountingUtil.getChartofAccount('A/P Inventory Accrual'), 'Credit', entityRef));
                    this.Line.add(new LineWrapper((returnCRLI.ItemDescription + ';Return Inventory Adjustment'), returnCRLI.Variance, AccountingUtil.getChartofAccount('Inventory Adjustments'), 'Debit', entityRef));
                } else {
                    this.Line.add(new LineWrapper((returnCRLI.ItemDescription + ';Return Cost Variance'), returnCRLI.Variance * -1, AccountingUtil.getChartofAccount('A/P Inventory Accrual'), 'Debit', entityRef));
                    this.Line.add(new LineWrapper((returnCRLI.ItemDescription + ';Return Inventory Adjustment'), returnCRLI.Variance * -1, AccountingUtil.getChartofAccount('Inventory Adjustments'), 'Credit', entityRef));
                }
            }
        }
    }

    public QBJournalEntryDTO(AccountingDealItem dealItemRec) {
        this.SFId = dealItemRec.Id;
        this.SyncToken = dealItemRec.SyncToken;
        this.PrivateNote = dealItemRec.COHeaderNumber + ';' + 'Stocked Trade In;'+dealItemRec.StockedUnitStockNumber+';'+ dealItemRec.StockedUnitVin; 
        String description = 'Trade In;'+ dealItemRec.StockedUnitStockNumber+';'+ dealItemRec.StockedUnitVin;
        this.DocNumber = dealItemRec.COHeaderNumber.length() > 21 ? dealItemRec.COHeaderNumber.substring(0, 21) : dealItemRec.COHeaderNumber;
        this.TxnDate = dealItemRec.StockedInDate;
        QBInnerEntityWrapper currRef = QBUtil.getCurrencyRef();
        if(currRef != null) this.CurrencyRef = currRef;

        this.Line = new List<LineWrapper>();
        String entityRef = null;
        if(AccessControl.ifObjectFieldIsAccessible('Category__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<Category__c> defaultStockedTradeCategoryList = [SELECT Income_GL__c FROM Category__c WHERE Type__c = 'Stocked Trade' AND Default__c = true AND Active__c = true];
        String stockedTradeIncomeGL = defaultStockedTradeCategoryList.size() > 0 ? defaultStockedTradeCategoryList[0].Income_GL__c : '';
        if(dealItemRec.ActualCashValue > 0) {
            this.Line.add(new LineWrapper(description, dealItemRec.ActualCashValue, dealItemRec.InventoryGL, 'Debit', entityRef));
            this.Line.add(new LineWrapper(description, dealItemRec.ActualCashValue, stockedTradeIncomeGL, 'Credit', entityRef));
        } else {
            this.Line.add(new LineWrapper(description, dealItemRec.ActualCashValue * -1, dealItemRec.InventoryGL, 'Credit', entityRef));
            this.Line.add(new LineWrapper(description, dealItemRec.ActualCashValue * -1, stockedTradeIncomeGL, 'Debit', entityRef));
        }
    }

    public QBJournalEntryDTO(AccountingPaymentOnAccount paymentOnAccountRecord) {
        this.SFId = paymentOnAccountRecord.Id;
        this.Id = paymentOnAccountRecord.QBAccountingId;	
        this.SyncToken = paymentOnAccountRecord.AccountingSyncToken;
        this.DocNumber = paymentOnAccountRecord.Name;
        this.TxnDate = paymentOnAccountRecord.PaymentDate;
        this.PrivateNote = paymentOnAccountRecord.Name + ';' + paymentOnAccountRecord.Customer.Name + ';' + paymentOnAccountRecord.PaymentMethod + ';Payment on Account';
        QBInnerEntityWrapper currRef = QBUtil.getCurrencyRef();
        if(currRef != null) this.CurrencyRef = currRef;
        this.Line = new List<LineWrapper>();
        String customerDepositsGLAccId = AccountingUtil.getChartofAccount('Customer Deposits');
        String undepFundsGLAccId = AccountingUtil.getPaymentUndepositedFundAccId(paymentOnAccountRecord.PaymentMethod);
        String paymentSurchargeGLAccId = AccountingUtil.getChartofAccount('Payment Method Surcharges');
        String cashRecClearingGLAccId = AccountingUtil.getChartofAccount('Cash Rec Clearing');
        String newUndepFundsAccId = AccountingUtil.getChartofAccount('Undeposited Funds');
        String giftCardLiabilityAccId = AccountingUtil.getChartofAccount('Gift Card liability');
        String checkoutClearingAccId = AccountingUtil.getChartofAccount('Checkout Clearing');
        String entityRef = null;
            
        if(AccountingUtil.isNewPaymentAccountingApplicable(paymentOnAccountRecord.PaymentDate)){
            if(paymentOnAccountRecord.TotalAmount > 0) {
                    if(paymentOnAccountRecord.PaymentMethod == 'Payment Surcharge') {
                        this.Line.add(new LineWrapper(this.PrivateNote, paymentOnAccountRecord.TotalAmount, paymentSurchargeGLAccId, 'Debit', entityRef));
                        this.Line.add(new LineWrapper(this.PrivateNote, paymentOnAccountRecord.TotalAmount, checkoutClearingAccId, 'Credit', entityRef));    
                    } else if(paymentOnAccountRecord.PaymentMethod == 'Direct Deposit') {
                        this.Line.add(new LineWrapper(this.PrivateNote, paymentOnAccountRecord.TotalAmount, newUndepFundsAccId, 'Debit', entityRef));
                        this.Line.add(new LineWrapper(this.PrivateNote, paymentOnAccountRecord.TotalAmount, checkoutClearingAccId, 'Credit', entityRef));    
                    } else if(paymentOnAccountRecord.PaymentMethod == 'GiftCard' || paymentOnAccountRecord.PaymentMethod == 'Gift Card') {
                        this.Line.add(new LineWrapper(this.PrivateNote, paymentOnAccountRecord.TotalAmount, giftCardLiabilityAccId, 'Debit', entityRef));
                        this.Line.add(new LineWrapper(this.PrivateNote, paymentOnAccountRecord.TotalAmount, checkoutClearingAccId, 'Credit', entityRef));    
                    } else {
                        this.Line.add(new LineWrapper(this.PrivateNote, paymentOnAccountRecord.TotalAmount, cashRecClearingGLAccId, 'Debit', entityRef));
                        this.Line.add(new LineWrapper(this.PrivateNote, paymentOnAccountRecord.TotalAmount, checkoutClearingAccId, 'Credit', entityRef));    
                    }
                } else {
                    if(paymentOnAccountRecord.PaymentMethod == 'Payment Surcharge') {
                        this.Line.add(new LineWrapper(this.PrivateNote, paymentOnAccountRecord.TotalAmount * -1, paymentSurchargeGLAccId, 'Credit', entityRef));
                        this.Line.add(new LineWrapper(this.PrivateNote, paymentOnAccountRecord.TotalAmount * -1, checkoutClearingAccId, 'Debit', entityRef));    
                    } else if(paymentOnAccountRecord.PaymentMethod == 'Direct Deposit') {
                        this.Line.add(new LineWrapper(this.PrivateNote, paymentOnAccountRecord.TotalAmount * -1, newUndepFundsAccId, 'Credit', entityRef));
                        this.Line.add(new LineWrapper(this.PrivateNote, paymentOnAccountRecord.TotalAmount * -1, checkoutClearingAccId, 'Debit', entityRef));    
                    } else if(paymentOnAccountRecord.PaymentMethod == 'GiftCard' || paymentOnAccountRecord.PaymentMethod == 'Gift Card') {
                        this.Line.add(new LineWrapper(this.PrivateNote, paymentOnAccountRecord.TotalAmount * -1, giftCardLiabilityAccId, 'Credit', entityRef));
                        this.Line.add(new LineWrapper(this.PrivateNote, paymentOnAccountRecord.TotalAmount * -1, checkoutClearingAccId, 'Debit', entityRef));    
                    } else {
                        this.Line.add(new LineWrapper(this.PrivateNote, paymentOnAccountRecord.TotalAmount * -1, cashRecClearingGLAccId, 'Credit', entityRef));
                        this.Line.add(new LineWrapper(this.PrivateNote, paymentOnAccountRecord.TotalAmount * -1, checkoutClearingAccId, 'Debit', entityRef));    
                    }
                }   
        } else {
            if(paymentOnAccountRecord.TotalAmount > 0) {
                if(paymentOnAccountRecord.PaymentMethod == 'Payment Surcharge'){
                    this.Line.add(new LineWrapper(this.PrivateNote, paymentOnAccountRecord.TotalAmount, paymentSurchargeGLAccId, 'Debit', entityRef));
                    this.Line.add(new LineWrapper(this.PrivateNote, paymentOnAccountRecord.TotalAmount, customerDepositsGLAccId, 'Credit', entityRef));
                } else {
                    this.Line.add(new LineWrapper(this.PrivateNote, paymentOnAccountRecord.TotalAmount, undepFundsGLAccId, 'Debit', entityRef));
                    this.Line.add(new LineWrapper(this.PrivateNote, paymentOnAccountRecord.TotalAmount, customerDepositsGLAccId, 'Credit', entityRef));    
                }
            } else {
                if(paymentOnAccountRecord.PaymentMethod == 'Payment Surcharge'){
                    this.Line.add(new LineWrapper(this.PrivateNote, paymentOnAccountRecord.TotalAmount  * -1, paymentSurchargeGLAccId, 'Credit', entityRef));
                    this.Line.add(new LineWrapper(this.PrivateNote, paymentOnAccountRecord.TotalAmount  * -1, customerDepositsGLAccId, 'Debit', entityRef));    
                } else{
                    this.Line.add(new LineWrapper(this.PrivateNote, paymentOnAccountRecord.TotalAmount  * -1, undepFundsGLAccId, 'Credit', entityRef));
                    this.Line.add(new LineWrapper(this.PrivateNote, paymentOnAccountRecord.TotalAmount  * -1, customerDepositsGLAccId, 'Debit', entityRef));    
                }
            }
        }
    }
    
    public QBJournalEntryDTO(AccountingUnitPriceAndCost adjstmentRec){
        this.SFId = adjstmentRec.Id;
        this.Id = adjstmentRec.JournalEntryAccountingId;
        this.SyncToken = adjstmentRec.JournalEntrySyncToken;
        String memo = '';
        memo += adjstmentRec.RefrenceNumber != null ? adjstmentRec.RefrenceNumber + ';' : '';
        memo += 'Unit Cost Adjustment;';
        memo += adjstmentRec.ItemDescription != null ? adjstmentRec.ItemDescription + ';' : '';
        memo += adjstmentRec.UnitId != null ? adjstmentRec.UnitId + ';' : '';
        memo += adjstmentRec.StockNumber != null ? adjstmentRec.StockNumber + ';' : '';
        memo += adjstmentRec.VIN != null ? adjstmentRec.VIN : '';

        this.DocNumber = adjstmentRec.RefrenceNumber;
        this.TxnDate = adjstmentRec.AdjustmentDate;
        this.PrivateNote = memo;
        QBInnerEntityWrapper currRef = QBUtil.getCurrencyRef();
        if(currRef != null) this.CurrencyRef = currRef;

        Map<String, Category__c> categoryTypeToDefaultRecMap = AccountingUtil.getTypeToDefaultCategoryMap(new List<String>{'Unit', 'Adjustment'});

        String inventoryGLNumber;
        if(adjstmentRec.UnitStatus == 'Available' || adjstmentRec.UnitStatus == 'Reserved') {
            inventoryGLNumber = adjstmentRec.Unit_Inventory_GL != null ? adjstmentRec.Unit_Inventory_GL : (categoryTypeToDefaultRecMap.containsKey('Unit') ? categoryTypeToDefaultRecMap.get('Unit').Inventory_GL__c : null);
        } else {
            inventoryGLNumber = adjstmentRec.Unit_COGS_GL != null ? adjstmentRec.Unit_COGS_GL : (categoryTypeToDefaultRecMap.containsKey('Unit') ? categoryTypeToDefaultRecMap.get('Unit').COGS_GL__c : null);
        }

            String incomeGLNumber = adjstmentRec.Unit_Adjustment_Income_GL != null ? adjstmentRec.Unit_Adjustment_Income_GL : (categoryTypeToDefaultRecMap.containsKey('Adjustment') ? categoryTypeToDefaultRecMap.get('Adjustment').Income_GL__c : null); 

        AccountingUnitPriceAndCost.EntityRefWrapper entity; // null entity
        this.Line = new List<LineWrapper>();
        if(adjstmentRec.TotalCost > 0) {
            this.Line.add(new LineWrapper(memo, adjstmentRec.TotalCost, incomeGLNumber, 'Credit', null));
            this.Line.add(new LineWrapper(memo, adjstmentRec.TotalCost, inventoryGLNumber, 'Debit', null));
        } else {
            this.Line.add(new LineWrapper(memo, adjstmentRec.TotalCost * -1, incomeGLNumber, 'Debit', null));
            this.Line.add(new LineWrapper(memo, adjstmentRec.TotalCost * -1, inventoryGLNumber, 'Credit', null));
        }
    }

    public QBJournalEntryDTO(AccountingCustomerInvoice customerInvoiceRecord) {
        this.SFId = customerInvoiceRecord.Id;
        String description = '';
        this.PrivateNote = (customerInvoiceRecord.AccountingCOInvoiceHeaderRec.Customer != null) ? 
                   (customerInvoiceRecord.AccountingCOInvoiceHeaderRec.Customer.Name + ';' + customerInvoiceRecord.AccountingCOInvoiceHeaderRec.COHeaderNumber + ';Costing') : '';
        description += (String.isNotBlank(this.PrivateNote) ? this.PrivateNote + ';' : '');
        this.Id = customerInvoiceRecord.AccountingCOInvoiceHeaderRec.JournalEntryAccountingId;
        this.SyncToken = customerInvoiceRecord.AccountingCOInvoiceHeaderRec.JournalEntrySyncToken;
        this.DocNumber = customerInvoiceRecord.AccountingCOInvoiceHeaderRec.COInvoiceHeaderNumber; 
        this.TxnDate =  DateTimeUtility.getDateFromFormattedDateStr(customerInvoiceRecord.AccountingCOInvoiceHeaderRec.ClosedInvoiceDate);
        QBInnerEntityWrapper currRef = QBUtil.getCurrencyRef();
        if(currRef != null) this.CurrencyRef = currRef;

        this.Line = new List<LineWrapper>();
        
        for(COInvoiceJournalEntryService.QuickBooksCustomerInvoiceItemsHelper coInvoiceItemRec : COInvoiceJournalEntryService.getAllAccountingCOInvoiceItemsRecs(customerInvoiceRecord)) {
            Decimal CostAmount = 0;
            if(coInvoiceItemRec.EntityType == 'Part' && coInvoiceItemRec.TotalCost != null && coInvoiceItemRec.TotalCost != 0) {
                CostAmount = coInvoiceItemRec.TotalCost.setScale(2, RoundingMode.HALF_UP);
            } else {
                CostAmount = (coInvoiceItemRec.Qty != null ? (coInvoiceItemRec.Qty).setScale(2, RoundingMode.HALF_UP) : 0) * (coInvoiceItemRec.UnitCost).setScale(2, RoundingMode.HALF_UP);
            }
            Decimal PriceAmount = (coInvoiceItemRec.Qty != null ? (coInvoiceItemRec.Qty).setScale(2, RoundingMode.HALF_UP) : 0) * (coInvoiceItemRec.UnitPrice).setScale(2, RoundingMode.HALF_UP);
            if(coInvoiceItemRec.IsInternalServiceTax) {
                PriceAmount = coInvoiceItemRec.UnitPrice;
            }
            
            if(coInvoiceItemRec.isNITCEntry != null && coInvoiceItemRec.isNITCEntry) {
                if(coInvoiceItemRec.UnitCost != null && coInvoiceItemRec.UnitCost != 0) {
                    if(String.isNotBlank(coInvoiceItemRec.PostingType) && coInvoiceItemRec.PostingType == 'Credit') {
                        this.Line.add(new LineWrapper(coInvoiceItemRec.Description, CostAmount, coInvoiceItemRec.Inventory_GL, 'Credit'));
                    } else {
                        this.Line.add(new LineWrapper(coInvoiceItemRec.Description, CostAmount, coInvoiceItemRec.COGS_GL, 'Debit'));
                    }
                }
            } else if(coInvoiceItemRec.IsBillToInternalClaimLI) {
                if(CostAmount != 0) {  
                    String accountRef = (coInvoiceItemRec.PostingType == 'Credit') ? coInvoiceItemRec.Income_GL : coInvoiceItemRec.Income_GL; //debit variance desposition category
                    this.Line.add(new LineWrapper(coInvoiceItemRec.Description, CostAmount, accountRef, coInvoiceItemRec.PostingType));
                }
            } else if(coInvoiceItemRec.EntryName != null && coInvoiceItemRec.EntryName == Constants.DEAL_ITEM_TYPE_TRADE_IN) {
                this.Line.add(new LineWrapper(coInvoiceItemRec.Description, CostAmount, coInvoiceItemRec.GLAccount, coInvoiceItemRec.PostingType));
            } else if(!coInvoiceItemRec.IsDealMerchOrService && !coInvoiceItemRec.IsInternalService) {
                if(CostAmount != 0) { // Added for JE is not created for 0 cost 10 aug 2017
                    if(CostAmount > 0) {
                        this.Line.add(new LineWrapper(description, CostAmount, coInvoiceItemRec.UnitCost, coInvoiceItemRec, coInvoiceItemRec.Inventory_GL, 'Credit', false, false)); //Debit Changed by richa 19/01/2017
                        this.Line.add(new LineWrapper(description, CostAmount, coInvoiceItemRec.UnitCost, coInvoiceItemRec, coInvoiceItemRec.COGS_GL, 'Debit', false, false)); //Credit Changed by richa 19/01/2017
                    } else {
                        this.Line.add(new LineWrapper(description, CostAmount, coInvoiceItemRec.UnitCost, coInvoiceItemRec, coInvoiceItemRec.Inventory_GL, 'Debit', false, false));
                        this.Line.add(new LineWrapper(description, CostAmount, coInvoiceItemRec.UnitCost, coInvoiceItemRec, coInvoiceItemRec.COGS_GL, 'Credit', false, false));
                    }
                }
            } else if(coInvoiceItemRec.IsDealMerchOrService) {
                String dealDesc = '';
                if(coInvoiceItemRec.Qty > 0) {
                    if(CostAmount != 0 && coInvoiceItemRec.EntityType != 'Fee') {
                        this.Line.add(new LineWrapper(dealDesc, CostAmount, coInvoiceItemRec.UnitCost, coInvoiceItemRec, coInvoiceItemRec.COGS_GL, 'Debit', false, false));
                        this.Line.add(new LineWrapper(dealDesc, CostAmount, coInvoiceItemRec.UnitCost, coInvoiceItemRec, coInvoiceItemRec.Inventory_GL, 'Credit', false, false));
                    }
                    
                    if(PriceAmount != 0) {
                        this.Line.add(new LineWrapper(dealDesc, PriceAmount, coInvoiceItemRec.UnitPrice, coInvoiceItemRec, coInvoiceItemRec.Income_GL, 'Credit', false, false));
                        this.Line.add(new LineWrapper(dealDesc, PriceAmount, coInvoiceItemRec.UnitPrice, coInvoiceItemRec, coInvoiceItemRec.DealUnit_Inventory_GL, 'Debit', true, false));
                    }
                } else {
                    if(CostAmount != 0 && coInvoiceItemRec.EntityType != 'Fee') {
                        this.Line.add(new LineWrapper(dealDesc, CostAmount, coInvoiceItemRec.UnitCost, coInvoiceItemRec, coInvoiceItemRec.COGS_GL, 'Credit', false, false));
                        this.Line.add(new LineWrapper(dealDesc, CostAmount, coInvoiceItemRec.UnitCost, coInvoiceItemRec, coInvoiceItemRec.Inventory_GL, 'Debit', false, false));
                    }
                    
                    if(PriceAmount != 0) {
                        this.Line.add(new LineWrapper(dealDesc, PriceAmount, coInvoiceItemRec.UnitPrice, coInvoiceItemRec, coInvoiceItemRec.Income_GL, 'Debit', false, false));
                        this.Line.add(new LineWrapper(dealDesc, PriceAmount, coInvoiceItemRec.UnitPrice, coInvoiceItemRec, coInvoiceItemRec.DealUnit_Inventory_GL, 'Credit', true, false));
                    }
                }
            } else if(coInvoiceItemRec.IsInternalService) {
                String internalServiceDesc = '';
                if(coInvoiceItemRec.IsInternalServiceTax && PriceAmount != 0) {
                    if(PriceAmount > 0) {
                        this.Line.add(new LineWrapper(internalServiceDesc, coInvoiceItemRec.UnitPrice, coInvoiceItemRec.UnitPrice, coInvoiceItemRec, coInvoiceItemRec.Income_GL, 'Credit', false, true));
                        this.Line.add(new LineWrapper(internalServiceDesc, PriceAmount, coInvoiceItemRec.UnitPrice, coInvoiceItemRec, coInvoiceItemRec.DealUnit_Inventory_GL, 'Debit', true, false));
                    } else {
                        this.Line.add(new LineWrapper(internalServiceDesc, PriceAmount, coInvoiceItemRec.UnitPrice, coInvoiceItemRec, coInvoiceItemRec.Income_GL, 'Debit', false, true));
                        this.Line.add(new LineWrapper(internalServiceDesc, PriceAmount, coInvoiceItemRec.UnitPrice, coInvoiceItemRec, coInvoiceItemRec.DealUnit_Inventory_GL, 'Credit', true, false));
                    }
                    
                } else {
                    if(coInvoiceItemRec.Qty > 0) {
                        if(CostAmount != 0 && String.isNotBlank(coInvoiceItemRec.COGS_GL)) {
                            this.Line.add(new LineWrapper(internalServiceDesc, CostAmount, coInvoiceItemRec.UnitCost, coInvoiceItemRec, coInvoiceItemRec.COGS_GL, 'Debit', false, false));
                            this.Line.add(new LineWrapper(internalServiceDesc, CostAmount, coInvoiceItemRec.UnitCost, coInvoiceItemRec, coInvoiceItemRec.Inventory_GL, 'Credit', false, false));
                        }
                        
                        if(PriceAmount != 0) {
                            this.Line.add(new LineWrapper(internalServiceDesc, PriceAmount, coInvoiceItemRec.UnitPrice, coInvoiceItemRec, coInvoiceItemRec.Income_GL, 'Credit', false, false));
                            this.Line.add(new LineWrapper(internalServiceDesc, PriceAmount, coInvoiceItemRec.UnitPrice, coInvoiceItemRec, coInvoiceItemRec.DealUnit_Inventory_GL, 'Debit', true, false));
                        }
                    } else {
                        if(CostAmount != 0 && String.isNotBlank(coInvoiceItemRec.COGS_GL)) {
                            this.Line.add(new LineWrapper(internalServiceDesc, CostAmount, coInvoiceItemRec.UnitCost, coInvoiceItemRec, coInvoiceItemRec.COGS_GL, 'Credit', false, false));
                            this.Line.add(new LineWrapper(internalServiceDesc, CostAmount, coInvoiceItemRec.UnitCost, coInvoiceItemRec, coInvoiceItemRec.Inventory_GL, 'Debit', false, false));
                        }
                        
                        if(PriceAmount != 0) {
                            this.Line.add(new LineWrapper(internalServiceDesc, PriceAmount, coInvoiceItemRec.UnitPrice, coInvoiceItemRec, coInvoiceItemRec.Income_GL, 'Debit', false, false));
                            this.Line.add(new LineWrapper(internalServiceDesc, PriceAmount, coInvoiceItemRec.UnitPrice, coInvoiceItemRec, coInvoiceItemRec.DealUnit_Inventory_GL, 'Credit', true, false));
                        }
                    }
                }
            }
        }
    }
}