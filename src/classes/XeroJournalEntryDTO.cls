public without sharing class XeroJournalEntryDTO {
	public String SFId;
	public String ManualJournalID;
	public String JournalDate;
	public String Status = 'POSTED';
	public String Narration;
	public String LineAmountTypes;
	public String Url;
	public List<JournalLines> JournalLines;
	public Decimal Quantity;

	public class JournalLines {
		public Decimal LineAmount;
		public String AccountCode;
		public String Description;
		public String TaxType;
		public Decimal TaxAmount;
		
		public JournalLines(Decimal LineAmount, String AccountCode, String Description) {
			this.LineAmount = LineAmount;
			this.AccountCode = AccountCode;
			this.Description = Description;
		}
		
		public JournalLines(Decimal LineAmount, String AccountCode, String Description, String TaxType, Decimal TaxAmount) {
			this.LineAmount = LineAmount;
			this.AccountCode = AccountCode;
			this.Description = Description;
			this.TaxType = TaxType;
			this.TaxAmount = TaxAmount;
		}
	}
	
	public XeroJournalEntryDTO(AccountingFIFOBucket accountingFIFOBucketRec) {
		this.SFId = accountingFIFOBucketRec.Id;
		this.JournalLines =  new List<JournalLines>();
		this.ManualJournalID = accountingFIFOBucketRec.XeroAccountingId;
		this.JournalDate = String.ValueOf(accountingFIFOBucketRec.CreatedDate);
		this.Status = 'POSTED';
		this.Narration = accountingFIFOBucketRec.UniqueId + ';' + accountingFIFOBucketRec.PartNumber + ';'
							+ (accountingFIFOBucketRec.Reference.containsIgnoreCase('Pre Sold Cost Adjustment') ? 'Cost Adjustment' : accountingFIFOBucketRec.Reference) + ';' 
							+ accountingFIFOBucketRec.Name;
		this.Url = AccountingUtil.getURL(accountingFIFOBucketRec.PartId, 'ViewPart');
		
		Decimal cost = accountingFIFOBucketRec.Cost != null ? accountingFIFOBucketRec.Cost.setScale(2, RoundingMode.HALF_UP) : 0;
		String description = accountingFIFOBucketRec.PartNumber + ' - increased by '+ accountingFIFOBucketRec.QtyIn + '@$' + cost;
		Decimal totalCost = (cost * (accountingFIFOBucketRec.QtyIn != null ? accountingFIFOBucketRec.QtyIn : 0));
		
		if(accountingFIFOBucketRec.SourceName == LogService.REOPEN_INVOICE) {
			description = 'Pre-sold cost adjustment reversal';
			this.Narration = accountingFIFOBucketRec.Reference + ';' + description;
			this.JournalLines.add(new JournalLines(totalCost, accountingFIFOBucketRec.Inventory_GL,  description));
			this.JournalLines.add(new JournalLines(totalCost * -1, accountingFIFOBucketRec.COGS_GL,  description));
		} else {
			this.JournalLines.add(new JournalLines(totalCost, accountingFIFOBucketRec.Inventory_GL,  description));
			this.JournalLines.add(new JournalLines(totalCost * -1, AccountingUtil.getChartofAccount('Inventory Adjustments'),  description));
		}
	}
	
	public XeroJournalEntryDTO(AccountingFIFOBucketActivityLineItem accountingFIFOBucketActivityLineItemRec) {
		this.SFId = accountingFIFOBucketActivityLineItemRec.Id;
		this.JournalLines =  new List<JournalLines>();
		this.ManualJournalID = accountingFIFOBucketActivityLineItemRec.XeroAccountingId;
		this.JournalDate = String.ValueOf(accountingFIFOBucketActivityLineItemRec.CreatedDate);
		this.Status = 'POSTED';
		accountingFIFOBucketActivityLineItemRec.QtyOut = accountingFIFOBucketActivityLineItemRec.QtyOut != null ? accountingFIFOBucketActivityLineItemRec.QtyOut.setScale(2, RoundingMode.HALF_UP) : accountingFIFOBucketActivityLineItemRec.QtyOut;
		Decimal cost = accountingFIFOBucketActivityLineItemRec.Cost != null  ? accountingFIFOBucketActivityLineItemRec.Cost.setScale(2, RoundingMode.HALF_UP) : 0;
        Decimal totalCost = (cost * accountingFIFOBucketActivityLineItemRec.QtyOut).setScale(2, RoundingMode.HALF_UP);
		String description = '';
		if(String.isNotBlank(accountingFIFOBucketActivityLineItemRec.ReturnVOHeaderId)) {
		    this.Narration = accountingFIFOBucketActivityLineItemRec.UniqueId+';'
		      +accountingFIFOBucketActivityLineItemRec.VendorName+';'
		      +'Vendor Return;'+accountingFIFOBucketActivityLineItemRec.RMANumber;
		    this.Url = AccountingUtil.getURL(accountingFIFOBucketActivityLineItemRec.ReturnVOHeaderId, 'ReturnVO');
		    description = accountingFIFOBucketActivityLineItemRec.PartDesc + ';Returned ' + accountingFIFOBucketActivityLineItemRec.QtyOut + '@$' + cost;
		    this.JournalLines.add(new JournalLines(totalCost * -1,  accountingFIFOBucketActivityLineItemRec.Inventory_GL,  description));
            this.JournalLines.add(new JournalLines(totalCost, AccountingUtil.getChartofAccount('A/P Inventory Accrual'),  description));
		} else if(accountingFIFOBucketActivityLineItemRec.Reference == 'Pre Sold Cost Adjustment On Existing FIFO') {
			this.Narration = accountingFIFOBucketActivityLineItemRec.UniqueId + ';' + accountingFIFOBucketActivityLineItemRec.PartNumber + ';' + 'Cost Adjustment';
	        this.Url = AccountingUtil.getURL(accountingFIFOBucketActivityLineItemRec.PartId, 'ViewPart');
	        description = accountingFIFOBucketActivityLineItemRec.PartNumber + ' - decreased by ' + accountingFIFOBucketActivityLineItemRec.BucketQtyRemaining + '@$' + accountingFIFOBucketActivityLineItemRec.BucketCost;
			totalCost = (accountingFIFOBucketActivityLineItemRec.BucketCost * accountingFIFOBucketActivityLineItemRec.BucketQtyRemaining).setScale(2, RoundingMode.HALF_UP);
			if(totalCost != 0) {
				this.JournalLines.add(new JournalLines(totalCost * -1,  accountingFIFOBucketActivityLineItemRec.Inventory_GL,  description));
			}
			description = accountingFIFOBucketActivityLineItemRec.PartNumber + ' - decreased by ' + accountingFIFOBucketActivityLineItemRec.BucketQtyOut + '@$' + accountingFIFOBucketActivityLineItemRec.BucketCost;
			totalCost = (accountingFIFOBucketActivityLineItemRec.BucketCost * accountingFIFOBucketActivityLineItemRec.BucketQtyOut).setScale(2, RoundingMode.HALF_UP);
			if(totalCost != 0) {
				this.JournalLines.add(new JournalLines(totalCost * -1, accountingFIFOBucketActivityLineItemRec.COGS_GL, description));
			}
			description = accountingFIFOBucketActivityLineItemRec.PartNumber + ' - decreased by ' + accountingFIFOBucketActivityLineItemRec.BucketQtyIn + '@$' + accountingFIFOBucketActivityLineItemRec.BucketCost;
			totalCost = (accountingFIFOBucketActivityLineItemRec.BucketCost * accountingFIFOBucketActivityLineItemRec.BucketQtyIn).setScale(2, RoundingMode.HALF_UP);
			if(totalCost != 0) {
				this.JournalLines.add(new JournalLines(totalCost, AccountingUtil.getChartofAccount('Inventory Adjustments'), description));
			}
		} else if(accountingFIFOBucketActivityLineItemRec.Reference == 'Pre Sold Cost Adjustment On New FIFO') {
			totalCost = (accountingFIFOBucketActivityLineItemRec.BucketCost * accountingFIFOBucketActivityLineItemRec.BucketQtyOut).setScale(2, RoundingMode.HALF_UP);
			this.Narration = accountingFIFOBucketActivityLineItemRec.UniqueId + ';' + accountingFIFOBucketActivityLineItemRec.PartNumber + ';' + 'Cost Adjustment';
	        this.Url = AccountingUtil.getURL(accountingFIFOBucketActivityLineItemRec.PartId, 'ViewPart');
	        description = accountingFIFOBucketActivityLineItemRec.PartNumber + ' - decreased by ' + accountingFIFOBucketActivityLineItemRec.BucketQtyOut + '@$' + accountingFIFOBucketActivityLineItemRec.BucketCost;
			this.JournalLines.add(new JournalLines(totalCost * -1,  accountingFIFOBucketActivityLineItemRec.Inventory_GL,  description));
	        this.JournalLines.add(new JournalLines(totalCost, accountingFIFOBucketActivityLineItemRec.COGS_GL, description));
		} else {
		    this.Narration = accountingFIFOBucketActivityLineItemRec.UniqueId + ';' + accountingFIFOBucketActivityLineItemRec.PartNumber + ';' + accountingFIFOBucketActivityLineItemRec.Reference;
	        this.Url = AccountingUtil.getURL(accountingFIFOBucketActivityLineItemRec.PartId, 'ViewPart');
	        description = accountingFIFOBucketActivityLineItemRec.PartNumber + ' - decreased by ' + accountingFIFOBucketActivityLineItemRec.QtyOut + '@$' + cost;
	        this.JournalLines.add(new JournalLines(totalCost * -1,  accountingFIFOBucketActivityLineItemRec.Inventory_GL,  description));
	        this.JournalLines.add(new JournalLines(totalCost, AccountingUtil.getChartofAccount('Inventory Adjustments'),  description));
		}
		this.Narration += (';' +  accountingFIFOBucketActivityLineItemRec.Name);
	}
	
	public XeroJournalEntryDTO(AccountingDealItem accountingDealItemRec) {
        this.SFId = accountingDealItemRec.Id;
        this.JournalLines =  new List<JournalLines>();
        this.ManualJournalID = accountingDealItemRec.XeroAccountingId;
        this.JournalDate = String.ValueOf(accountingDealItemRec.StockedInDate);
        this.Status = 'POSTED';
        this.Narration = accountingDealItemRec.COHeaderNumber + ';' + 'Stocked Trade In;'+accountingDealItemRec.StockedUnitStockNumber+';'+ accountingDealItemRec.StockedUnitVin; 
        this.Url = AccountingUtil.getURL(accountingDealItemRec.COHeaderId, 'CustomerOrder_V2');
        
        String description = 'Trade In;'+ accountingDealItemRec.StockedUnitStockNumber+';'+ accountingDealItemRec.StockedUnitVin;
        Decimal totalCost = accountingDealItemRec.ActualCashValue != null ? accountingDealItemRec.ActualCashValue.setScale(2, RoundingMode.HALF_UP) : 0;
        List<Category__c> stockTradeClearingCategoryList = AccountingUtil.getSystemDefaultCategory('Stocked Trade');
        String stockedTradeIncomeGL = stockTradeClearingCategoryList.size() > 0 ? stockTradeClearingCategoryList[0].Income_GL__c : '';
        this.JournalLines.add(new JournalLines(totalCost, accountingDealItemRec.InventoryGL,  description));
        this.JournalLines.add(new JournalLines(totalCost * -1, stockedTradeIncomeGL,  description));
    }
	
	public XeroJournalEntryDTO(AccountingCOInvoicePayment accountingCOInvoicePaymentRec) {
        this.SFId = accountingCOInvoicePaymentRec.Id;
        this.JournalLines =  new List<JournalLines>();
        this.ManualJournalID = accountingCOInvoicePaymentRec.XeroAccountingId;
        this.JournalDate = String.ValueOf(accountingCOInvoicePaymentRec.PaymentDate);
        this.Status = 'POSTED';
        if(String.isNotBlank(accountingCOInvoicePaymentRec.customer.Name)){
            accountingCOInvoicePaymentRec.customer.Name = accountingCOInvoicePaymentRec.customer.Name;
        } else if(accountingCOInvoicePaymentRec.COType == Constants.CASH_SALE) {
            accountingCOInvoicePaymentRec.customer.Name = Constants.CASH_SALE;
        } else if(accountingCOInvoicePaymentRec.COType == Constants.INTERNAL_SERVICE) {
            accountingCOInvoicePaymentRec.customer.Name = Constants.INTERNAL_SERVICE;
        }
		
		String customerName = accountingCOInvoicePaymentRec.customer.Name;
		String docNumber = accountingCOInvoicePaymentRec.COInvoicePaymentNumber;
        String coNumber = accountingCOInvoicePaymentRec.CustomerOrderNumber;
        String paymentMethod = accountingCOInvoicePaymentRec.PaymentMethod;
        String entityType = 'Payment';
        if(accountingCOInvoicePaymentRec.IsReverse && String.isNotBlank(accountingCOInvoicePaymentRec.ReverseLink)) {
			entityType = 'Payment Reversal';
        } else if(accountingCOInvoicePaymentRec.IsReverse) {
			entityType = 'Refund';
        } else {
			entityType = 'Payment'; 
        }
		this.Narration = docNumber + ';' + customerName + ';' + coNumber + ';' + paymentMethod + ';' + entityType;
		String lineItemDesc = paymentMethod + ';' + entityType + ';' + docNumber + ';' + customerName + ';' + coNumber;
        this.Url = AccountingUtil.getURL(accountingCOInvoicePaymentRec.CustomerOrderId, 'CustomerOrder_V2');
        if(AccountingUtil.isNewPaymentAccountingApplicable(accountingCOInvoicePaymentRec.PaymentDate)){
			if(accountingCOInvoicePaymentRec.PaymentMethod == 'Cash Rounding') {
				this.JournalLines.add(new JournalLines(accountingCOInvoicePaymentRec.Amount,  AccountingUtil.getChartofAccount('Cash Rounding'),  lineItemDesc));
            } else if(accountingCOInvoicePaymentRec.PaymentMethod == 'Payment Surcharge') {
				this.JournalLines.add(new JournalLines(accountingCOInvoicePaymentRec.Amount,  AccountingUtil.getChartofAccount('Payment Method Surcharges'),  lineItemDesc));
            } else if(accountingCOInvoicePaymentRec.PaymentMethod == 'Direct Deposit') {
				this.JournalLines.add(new JournalLines(accountingCOInvoicePaymentRec.Amount,  AccountingUtil.getChartofAccount('Undeposited Funds'),  lineItemDesc));
            } else if(accountingCOInvoicePaymentRec.PaymentMethod == 'Gift Card' || accountingCOInvoicePaymentRec.PaymentMethod == 'Giftcard') {
				this.JournalLines.add(new JournalLines(accountingCOInvoicePaymentRec.Amount,  AccountingUtil.getChartofAccount('Gift Card liability'),  lineItemDesc));
            } else if(accountingCOInvoicePaymentRec.PaymentMethod == 'Store Credit') {
				this.JournalLines.add(new JournalLines(accountingCOInvoicePaymentRec.Amount,  AccountingUtil.getChartofAccount('Store Credit Accrual'),  lineItemDesc));
            } else if(accountingCOInvoicePaymentRec.PaymentMethod == 'Use Deposit' || accountingCOInvoicePaymentRec.PaymentMethod == AccountingUtil.USE_DEAL_DEPOSIT) {
				this.JournalLines.add(new JournalLines(accountingCOInvoicePaymentRec.Amount,  AccountingUtil.getChartofAccount('Customer Deposits'),  lineItemDesc));
            } else {
				this.JournalLines.add(new JournalLines(accountingCOInvoicePaymentRec.Amount,  AccountingUtil.getChartofAccount('Cash Rec Clearing'),  lineItemDesc));
            }
			this.JournalLines.add(new JournalLines((accountingCOInvoicePaymentRec.Amount * -1),  AccountingUtil.getChartofAccount('Checkout Clearing'),  lineItemDesc));
		} else{
			if(accountingCOInvoicePaymentRec.PaymentMethod == 'Store Credit') {
				this.JournalLines.add(new JournalLines(accountingCOInvoicePaymentRec.Amount,  AccountingUtil.getChartofAccount('Store Credit Accrual'),  lineItemDesc));
			} else if(accountingCOInvoicePaymentRec.PaymentMethod == 'Cash Rounding') {
				this.JournalLines.add(new JournalLines(accountingCOInvoicePaymentRec.Amount,  AccountingUtil.getChartofAccount('Cash Rounding'),  lineItemDesc));
			} else if(accountingCOInvoicePaymentRec.PaymentMethod == 'Payment Surcharge') {
				this.JournalLines.add(new JournalLines(accountingCOInvoicePaymentRec.Amount,  AccountingUtil.getChartofAccount('Payment Method Surcharges'),  lineItemDesc));
			} else {
				this.JournalLines.add(new JournalLines(accountingCOInvoicePaymentRec.Amount,  AccountingUtil.getPaymentUndepositedFundAccId(accountingCOInvoicePaymentRec.PaymentMethod),  lineItemDesc));
			}
			this.JournalLines.add(new JournalLines((accountingCOInvoicePaymentRec.Amount * -1),  AccountingUtil.getChartofAccount('Customer Deposits'),  lineItemDesc));
		}
        
    }
    
	public XeroJournalEntryDTO(AccountingPart partRec) {
		this.SFId = partRec.Id;
		//Category change should create separate JE rather the override existing one
		//this.ManualJournalID = partRec.XeroAccountingId;
		this.JournalLines =  new List<JournalLines>();
		String memo = partRec.PartNumber + ';Category changed';
        String description = partRec.PartNumber + ' - Category changed from ' + partRec.OldCategoryName + ' to ' + partRec.NewCategoryName;
		this.JournalDate = String.ValueOf(partRec.ModifiedDate);
		this.Status = 'POSTED';
		this.Narration = memo;
		this.Url = AccountingUtil.getURL(partRec.Id, 'ViewPart');
		this.JournalLines.add(new JournalLines(partRec.TotalInventoryValuation, partRec.NewCategoryInventoryGL,  description));
		this.JournalLines.add(new JournalLines(partRec.TotalInventoryValuation * -1, partRec.OldCategoryInventoryGL, description));
	}
	
	public XeroJournalEntryDTO(AccountingUnit unitRec, String entityType) {
        this.SFId = unitRec.Id;
        this.JournalLines =  new List<JournalLines>();
        this.Status = 'POSTED';
        this.Url = AccountingUtil.getURL(unitRec.Id, 'ViewUnit');
        
        if(entityType == IntegrationUtility.STOCK_UNIT_CATEGORY) {		
        	//Category change should create separate JE rather the override existing one
        	//this.ManualJournalID = unitRec.XeroJEAccountingId;
	        String memo = unitRec.UnitId+';' + unitRec.StockNumber+';'+ unitRec.VIN + ';Category changed';
	        String description = memo +' from ' + unitRec.OldCategoryName + ' to ' + unitRec.NewCategoryName;
	        this.JournalDate = String.ValueOf(unitRec.ModifiedDate);
	        this.Narration = memo;
	        this.JournalLines.add(new JournalLines(unitRec.TotalInventoryValuation * -1, unitRec.OldCategoryInventoryGL, description));
	        this.JournalLines.add(new JournalLines(unitRec.TotalInventoryValuation, unitRec.NewCategoryInventoryGL,  description));
	        
        } else if(entityType == IntegrationUtility.UNIT_INVOICE_JE) {			//Invoice JE
        	this.ManualJournalID = unitRec.XeroAccountingIdUnitInvoiceJE;
        	String description = '';
        	/**
			if(unitRec.StockNumber != null) {
				description += unitRec.StockNumber + ';';
			}
	        if(unitRec.VIN != null){
	            description += unitRec.VIN + ';';
	        }
	        if(unitRec.MakeName != null){
	            description += unitRec.MakeName + ' ';
	        } 
	        if(unitRec.ModelName != null){
	            description += unitRec.ModelName + ' ';
	        } 
	        if(unitRec.SubModelName != null){
	            description += unitRec.SubModelName;
	        }  
	        
	        description += ';Purchase Tax Credit';**/
            description += (unitRec.VIN != null) ? unitRec.VIN + ';' : '';
	        description += 'NITC Withheld;Unit purchase;';
            description += (unitRec.Vendor != null && unitRec.Vendor.Name != null) ? unitRec.Vendor.Name + ';' : '';
            description += (unitRec.InvoiceNumber != null) ? unitRec.InvoiceNumber : '';
	        
        	this.Narration = description;
        	this.LineAmountTypes = 'Exclusive';
        	
        	this.JournalDate = DateTimeUtility.getFormttedDateFromDateTime(DateTimeUtility.getDateTimeFromDate(unitRec.CreatedDate), 'yyyy-MM-dd');
        	Decimal amount = unitRec.PurchaseTaxCredit.setScale(2, RoundingMode.HALF_UP);
        	
        	String purchaseTaxLiabilityCategory = '';
        	String notionalInputTaxCat = '';
			if(GeneralConfiguration.getTradeTaxPendingSaleCategory() != null || GeneralConfiguration.getPurchaseTaxLiabilityCategory() != null) {
				Set<String> categoryIdSet = new Set<String>();
				if(GeneralConfiguration.getTradeTaxPendingSaleCategory() != null) {
					categoryIdSet.add(GeneralConfiguration.getTradeTaxPendingSaleCategory());
				}
				if(GeneralConfiguration.getPurchaseTaxLiabilityCategory() != null) {
					categoryIdSet.add(GeneralConfiguration.getPurchaseTaxLiabilityCategory());
				}
				Map<String, Category__c> categoryIdToRecMap = new Map<String, Category__c>([Select Id, Income_GL__c from Category__c where Id IN: categoryIdSet]);
				if(categoryIdToRecMap.size() > 0) {
					purchaseTaxLiabilityCategory = categoryIdToRecMap.containsKey(GeneralConfiguration.getPurchaseTaxLiabilityCategory()) ? 
							categoryIdToRecMap.get(GeneralConfiguration.getPurchaseTaxLiabilityCategory()).Income_GL__c : '';
							
					notionalInputTaxCat = categoryIdToRecMap.containsKey(GeneralConfiguration.getTradeTaxPendingSaleCategory()) ? 
									categoryIdToRecMap.get(GeneralConfiguration.getTradeTaxPendingSaleCategory()).Income_GL__c : '';
				}
			}
			
			String nitcWithHeldTaxCode = QuickBooks_Configurations__c.getOrgDefaults().NITC_WithHeld_Tax_Code__c;
	        this.JournalLines.add(new JournalLines(amount, notionalInputTaxCat, description));
	        this.JournalLines.add(new JournalLines(amount * -1, purchaseTaxLiabilityCategory, description, nitcWithHeldTaxCode, 0));
        } else if(entityType == IntegrationUtility.UNIT_NITC_JE) {
        	setUnitNITCJEData(unitRec);
        }
    }
    
    private void setUnitNITCJEData(AccountingUnit unitRec) {
    	this.ManualJournalID = unitRec.XeroUnitNITCJEAccountingId;
        String description = unitRec.VIN + ';NITC Claimed;Manually';
        this.JournalDate = DateTimeUtility.getFormttedDateFromDateTime(DateTimeUtility.getDateTimeFromDate(unitRec.NITCDateClaimed), 'yyyy-MM-dd');
        this.Narration = description;
        this.LineAmountTypes = 'Exclusive';
        Map<String, Category__c> tradeInTaxCategoryIdToRecMap = AccountingUtil.getTradeInTaxCategoryMap();
        String tradeTaxPendingSaleCategory = tradeInTaxCategoryIdToRecMap.containsKey(GeneralConfiguration.getTradeTaxPendingSaleCategory()) ? tradeInTaxCategoryIdToRecMap.get(GeneralConfiguration.getTradeTaxPendingSaleCategory()).Income_GL__c : '';
        String taxCategoryIncomeGL = '';
        Decimal amount = 0;
        String nitcClaimedTaxCode = QuickBooks_Configurations__c.getOrgDefaults().NITC_Claimed_Tax_Code__c;
        
        if(unitRec.SalesTaxCredit != null && unitRec.SalesTaxCredit != 0) {
        	amount = (unitRec.SalesTaxCredit.setScale(2, RoundingMode.HALF_UP) * -1);
        	taxCategoryIncomeGL = tradeInTaxCategoryIdToRecMap.containsKey(GeneralConfiguration.getTradeTaxLiabilityCategory()) ? tradeInTaxCategoryIdToRecMap.get(GeneralConfiguration.getTradeTaxLiabilityCategory()).Income_GL__c : '';
        	
        } else if(unitRec.PurchaseTaxCredit != null && unitRec.PurchaseTaxCredit != 0) {
        	amount = unitRec.PurchaseTaxCredit.setScale(2, RoundingMode.HALF_UP) * -1;
        	taxCategoryIncomeGL = tradeInTaxCategoryIdToRecMap.containsKey(GeneralConfiguration.getPurchaseTaxLiabilityCategory()) ? tradeInTaxCategoryIdToRecMap.get(GeneralConfiguration.getPurchaseTaxLiabilityCategory()).Income_GL__c : '';
        }
        
        if(amount != 0) {
        	this.JournalLines.add(new JournalLines(amount.setScale(2, RoundingMode.HALF_UP), tradeTaxPendingSaleCategory, description, 
	        							QBUtil.nonTaxableCodeAccId, 0));
	        this.JournalLines.add(new JournalLines(amount.setScale(2, RoundingMode.HALF_UP) * -1, taxCategoryIncomeGL, description, 
	        							nitcClaimedTaxCode, 0));
        }
    }
	
	public XeroJournalEntryDTO(AccountingCODeposit coDepositRec) {
		this.SFId = coDepositRec.CODepositId;
		this.ManualJournalID = coDepositRec.XeroAccountingId;
		this.JournalLines =  new List<JournalLines>();
		String memo = AccountingUtil.getDepositMemo(coDepositRec);
		String lineItemDesc = AccountingUtil.getDepositLineItemDesc(coDepositRec);
		this.JournalDate = String.ValueOf(coDepositRec.PaymentDate);
		this.Status = 'POSTED';
		this.Narration = memo;
		
		this.Url = AccountingUtil.getURL(coDepositRec.COHeaderId, 'CustomerOrder_V2');

		if(AccountingUtil.isNewPaymentAccountingApplicable(coDepositRec.PaymentDate)) {
			if(coDepositRec.PaymentMethod == 'Direct Deposit' || coDepositRec.PaymentMethod == 'Financing') {
				this.JournalLines.add(new JournalLines(coDepositRec.Amount, AccountingUtil.getChartofAccount('Undeposited Funds'),  lineItemDesc));
			} else if(coDepositRec.PaymentMethod == 'Store Credit') {
				this.JournalLines.add(new JournalLines(coDepositRec.Amount, AccountingUtil.getChartofAccount('Store Credit Accrual'),  lineItemDesc));
			} else if(coDepositRec.PaymentMethod == 'Payment Surcharge') {
				this.JournalLines.add(new JournalLines(coDepositRec.Amount, AccountingUtil.getChartofAccount('Payment Method Surcharges'),  lineItemDesc));
			} else if(coDepositRec.PaymentMethod == 'Giftcard' || coDepositRec.PaymentMethod == 'Gift Card') {
				this.JournalLines.add(new JournalLines(coDepositRec.Amount, AccountingUtil.getChartofAccount('Gift Card liability'),  lineItemDesc));
			} else {
				this.JournalLines.add(new JournalLines(coDepositRec.Amount, AccountingUtil.getChartofAccount('Cash Rec Clearing'),  lineItemDesc));
			}
			this.JournalLines.add(new JournalLines(coDepositRec.Amount * -1, AccountingUtil.getChartofAccount('Customer Deposits'), lineItemDesc));
		} else {
			if(coDepositRec.PaymentMethod == 'Store Credit') {
				this.JournalLines.add(new JournalLines(coDepositRec.Amount, AccountingUtil.getChartofAccount('Store Credit Accrual'),  lineItemDesc));
			} else if(coDepositRec.PaymentMethod == 'Payment Surcharge') {
				this.JournalLines.add(new JournalLines(coDepositRec.Amount, AccountingUtil.getChartofAccount('Payment Method Surcharges'),  lineItemDesc));
			} else {
				this.JournalLines.add(new JournalLines(coDepositRec.Amount, AccountingUtil.getPaymentUndepositedFundAccId(coDepositRec.PaymentMethod),  lineItemDesc));
			}
			this.JournalLines.add(new JournalLines(coDepositRec.Amount * -1, AccountingUtil.getChartofAccount('Customer Deposits'), lineItemDesc));
		}
	}
	
	public XeroJournalEntryDTO(AccountingStoreCredit storeCreditRec) {
		this.SFId = storeCreditRec.StoreCreditId;
		this.ManualJournalID = storeCreditRec.XeroAccountingId;
		this.JournalLines =  new List<JournalLines>();
		String memo = '';
		if(storeCreditRec.StoreCreditName != null) {
			memo += storeCreditRec.StoreCreditName + ';';
		}
        if(storeCreditRec.customer.Name != null){
            memo += storeCreditRec.customer.Name + ';';
        } 
       if(storeCreditRec.Amount > 0) {
        	memo += 'Store Credit Increase'+ ';';
        }else {
        	memo += 'Store Credit Decrease'+ ';';
        } 
        if(storeCreditRec.StoreCreditReference != null){
            memo += storeCreditRec.StoreCreditReference ;
        } 
		this.JournalDate = String.ValueOf(storeCreditRec.CreatedDate);
		this.Status = 'POSTED';
		this.Narration = memo;
		
		this.Url = AccountingUtil.getURL(storeCreditRec.customer.customerId, 'ViewCustomer');
        this.JournalLines.add(new JournalLines(storeCreditRec.Amount, AccountingUtil.getChartofAccount('Store Credit Expense'),  memo));
        this.JournalLines.add(new JournalLines(storeCreditRec.Amount * -1, AccountingUtil.getChartofAccount('Store Credit Accrual'),  memo));
	}
	
    public XeroJournalEntryDTO(AccountingHoursLogged hoursLoggedObj) {
        this.SFId = hoursLoggedObj.Id;
        this.Status = 'POSTED';
        
        this.Narration = AccountingUtil.getHoursLoggedJENarration(hoursLoggedObj);
        this.JournalDate = hoursLoggedObj.TxnDate;
        this.Url = AccountingUtil.getURL(hoursLoggedObj.COHeaderId, 'CustomerOrder_V2');
        
        String addJournalLineItemDesc = AccountingUtil.getHoursLoggedJELineItemDesc(hoursLoggedObj, true);
        String removeJournalLineItemDesc = AccountingUtil.getHoursLoggedJELineItemDesc(hoursLoggedObj, false);
        this.JournalLines = new List<JournalLines>();
        
        if(hoursLoggedObj.OldTotalCost != null || hoursLoggedObj.IsRemoved) {
        	Decimal cost = hoursLoggedObj.IsRemoved ? hoursLoggedObj.TotalCost : hoursLoggedObj.OldTotalCost;
            if(cost != 0) {
            	this.JournalLines.add(new JournalLines(cost * -1, AccountingUtil.getChartOfAccount('WIP Labor Inventory'), removeJournalLineItemDesc));
            	this.JournalLines.add(new JournalLines(cost, AccountingUtil.getChartOfAccount('WIP Labor Expense'), removeJournalLineItemDesc));
            }
        }
        if(!hoursLoggedObj.IsRemoved && hoursLoggedObj.TotalCost != 0) {
            this.JournalLines.add(new JournalLines(hoursLoggedObj.TotalCost, AccountingUtil.getChartOfAccount('WIP Labor Inventory'), addJournalLineItemDesc));
            this.JournalLines.add(new JournalLines(hoursLoggedObj.TotalCost * -1, AccountingUtil.getChartOfAccount('WIP Labor Expense'), addJournalLineItemDesc));
        }
    }
    
	public XeroJournalEntryDTO(AccountingUnitPriceAndCost unitPriceAndCostRec) {
		this.SFId = unitPriceAndCostRec.Id;
		this.ManualJournalID = unitPriceAndCostRec.XeroAccountingId;
		this.JournalLines =  new List<JournalLines>();
		String memo = '';
		memo += unitPriceAndCostRec.RefrenceNumber != null ? unitPriceAndCostRec.RefrenceNumber + ';' : '';
    	memo += 'Unit Cost Adjustment;';
    	memo += unitPriceAndCostRec.ItemDescription != null ? unitPriceAndCostRec.ItemDescription + ';' : '';
    	memo += unitPriceAndCostRec.UnitId != null ? unitPriceAndCostRec.UnitId + ';' : '';
    	memo += unitPriceAndCostRec.StockNumber != null ? unitPriceAndCostRec.StockNumber + ';' : '';
    	memo += unitPriceAndCostRec.VIN != null ? unitPriceAndCostRec.VIN : '';
		
		this.JournalDate = String.ValueOf(unitPriceAndCostRec.AdjustmentDate);
		this.Status = 'POSTED';
		this.Narration = memo;
		
		this.Url = AccountingUtil.getURL(unitPriceAndCostRec.CustomerOwnedUnitId, 'ViewUnit');
		Decimal totalCost = unitPriceAndCostRec.TotalCost != null ? unitPriceAndCostRec.TotalCost.setScale(2, RoundingMode.HALF_UP) : 0;
        
        Map<String, Category__c> categoryTypeToDefaultRecMap = AccountingUtil.getTypeToDefaultCategoryMap(new List<String>{'Unit', 'Adjustment'});
        
	    String inventoryGLNumber;
	    if(unitPriceAndCostRec.UnitStatus == 'Available' || unitPriceAndCostRec.UnitStatus == 'Reserved') {
            inventoryGLNumber = unitPriceAndCostRec.Unit_Inventory_GL != null ? unitPriceAndCostRec.Unit_Inventory_GL : (categoryTypeToDefaultRecMap.containsKey('Unit') ? categoryTypeToDefaultRecMap.get('Unit').Inventory_GL__c : null);
	    } else {
            inventoryGLNumber = unitPriceAndCostRec.Unit_COGS_GL != null ? unitPriceAndCostRec.Unit_COGS_GL : (categoryTypeToDefaultRecMap.containsKey('Unit') ? categoryTypeToDefaultRecMap.get('Unit').COGS_GL__c : null);
	    }
        
       	String incomeGLNumber = unitPriceAndCostRec.Unit_Adjustment_Income_GL != null ? unitPriceAndCostRec.Unit_Adjustment_Income_GL : (categoryTypeToDefaultRecMap.containsKey('Adjustment') ? categoryTypeToDefaultRecMap.get('Adjustment').Income_GL__c : null); 
        
        this.JournalLines.add(new JournalLines(totalCost, inventoryGLNumber ,  memo));
        this.JournalLines.add(new JournalLines(totalCost * -1, incomeGLNumber, memo));
	}
	
	public XeroJournalEntryDTO(AccountingVendorReceiving vendorReceivingRec) {
		this.JournalLines =  new List<JournalLines>();
		this.SFId = vendorReceivingRec.AccountingVORHeaderRec.VORId;
		this.ManualJournalID = vendorReceivingRec.AccountingVORHeaderRec.XeroAccountingId;
		this.JournalDate = String.ValueOf(vendorReceivingRec.AccountingVORHeaderRec.FinalizedDate);
		this.Status = 'POSTED';
		
		String baseDesc = vendorReceivingRec.AccountingVORHeaderRec.VORName + ';' + vendorReceivingRec.AccountingVORHeaderRec.VendorName + ';' +
                                    vendorReceivingRec.AccountingVORHeaderRec.PackagingSlipNumber;
        String memo = baseDesc + ';Inventory receiving';
		this.Narration = memo;
		this.Url = AccountingUtil.getURL(vendorReceivingRec.AccountingVORHeaderRec.VORId, 'VendorOrderReceiving');
        for(AccountingVendorReceiving.AccountingVRGroupByGL VORGroupByGLRec : vendorReceivingRec.AccountingVRGroupByGLList) {
            String description = baseDesc +  + ';Inventory received';
            this.JournalLines.add(new JournalLines(VORGroupByGLRec.Total, VORGroupByGLRec.Inventory_GL,  description));
        }
        
        String descriptionForCompleteVR = baseDesc+ ';Total receiving'; 
        this.JournalLines.add(new JournalLines(vendorReceivingRec.AccountingVORHeaderRec.ReceivingTotal * -1, AccountingUtil.getChartofAccount('A/P Inventory Accrual'), descriptionForCompleteVR));
	}
	
	public XeroJournalEntryDTO(AccountingPaymentOnAccount paymentOnAccountRecord) {
		this.JournalLines =  new List<JournalLines>();
		this.SFId = paymentOnAccountRecord.Id;
		this.ManualJournalID = paymentOnAccountRecord.XeroAccountingId;
		this.JournalDate = String.ValueOf(paymentOnAccountRecord.PaymentDate);
		this.Status = 'POSTED';
		String description = paymentOnAccountRecord.Name + ';' + paymentOnAccountRecord.Customer.Name + ';' + 
											paymentOnAccountRecord.PaymentMethod + ';Payment on Account';
		
		this.Narration = description;
		
		this.Url = AccountingUtil.getURL(paymentOnAccountRecord.Customer.Id, 'ViewCustomer');
		if(AccountingUtil.isNewPaymentAccountingApplicable(paymentOnAccountRecord.PaymentDate)){
            if(paymentOnAccountRecord.PaymentMethod == 'Payment Surcharge') {
				this.JournalLines.add(new JournalLines(paymentOnAccountRecord.TotalAmount, AccountingUtil.getChartofAccount('Payment Method Surcharges'), description));
			} else if(paymentOnAccountRecord.PaymentMethod == 'Direct Deposit') {
				this.JournalLines.add(new JournalLines(paymentOnAccountRecord.TotalAmount, AccountingUtil.getChartofAccount('Undeposited Funds'), description));
			} else if(paymentOnAccountRecord.PaymentMethod == 'GiftCard' || paymentOnAccountRecord.PaymentMethod == 'Gift Card') {
				this.JournalLines.add(new JournalLines(paymentOnAccountRecord.TotalAmount, AccountingUtil.getChartofAccount('Gift Card liability'), description));
			} else {
				this.JournalLines.add(new JournalLines(paymentOnAccountRecord.TotalAmount, AccountingUtil.getChartofAccount('Cash Rec Clearing'), description));
			}
			this.JournalLines.add(new JournalLines(paymentOnAccountRecord.TotalAmount * -1, AccountingUtil.getChartofAccount('Checkout Clearing'), description));
		} else{
			if(paymentOnAccountRecord.PaymentMethod != 'Payment Surcharge') {
				this.JournalLines.add(new JournalLines(paymentOnAccountRecord.TotalAmount, AccountingUtil.getPaymentUndepositedFundAccId(paymentOnAccountRecord.PaymentMethod), description));
			} else {
				this.JournalLines.add(new JournalLines(paymentOnAccountRecord.TotalAmount, AccountingUtil.getChartofAccount('Payment Method Surcharges'), description));
			}
			this.JournalLines.add(new JournalLines(paymentOnAccountRecord.TotalAmount * -1, AccountingUtil.getChartofAccount('Customer Deposits'), description));
		}
	}
	
	public XeroJournalEntryDTO(AccountingCustomerInvoice accCOInvoiceRec) {
		this.JournalLines =  new List<JournalLines>();
		this.SFId = accCOInvoiceRec.AccountingCOInvoiceHeaderRec.COInvoiceHeaderId;
		this.ManualJournalID = accCOInvoiceRec.AccountingCOInvoiceHeaderRec.XeroCOInvoiceJEAccountingId;
		this.Status = 'POSTED';
		this.Quantity = 1;
		this.Url = AccountingUtil.getURL(accCOInvoiceRec.AccountingCOInvoiceHeaderRec.COHeaderId, 'CustomerOrder_V2');
		
		this.Narration = accCOInvoiceRec.AccountingCOInvoiceHeaderRec.COInvoiceHeaderNumber +';' + accCOInvoiceRec.AccountingCOInvoiceHeaderRec.FormattedCustomerName +';' + accCOInvoiceRec.AccountingCOInvoiceHeaderRec.COHeaderNumber;
		if(accCOInvoiceRec.AccountingCOInvoiceHeaderRec.CheckoutType == 'Third-Party') {
			this.Narration += ';Claim Invoice COGS';
		} else if(accCOInvoiceRec.AccountingCOInvoiceHeaderRec.CheckoutType == 'Deal') {
			this.Narration += setNarrationForDealMerchAndService(accCOInvoiceRec);
		}else if(accCOInvoiceRec.AccountingCOInvoiceItemsRecs[0].ServiceJobType == 'Stock Unit') {
			this.Narration = accCOInvoiceRec.AccountingCOInvoiceHeaderRec.COInvoiceHeaderNumber +';' + 'UNIT INVENTORY;' + accCOInvoiceRec.AccountingCOInvoiceHeaderRec.COHeaderNumber + ';'
								+ 'Internal Service;';
			for(AccountingCustomerInvoice.AccountingCOInvoiceItem coInvItem : accCOInvoiceRec.AccountingCOInvoiceItemsRecs) {
				this.Narration += coInvItem.SkuNumber;
			}				
		} else if(accCOInvoiceRec.AccountingCOInvoiceItemsRecs[0].ServiceJobType == 'Internal') {
			this.Narration = accCOInvoiceRec.AccountingCOInvoiceHeaderRec.COInvoiceHeaderNumber +';' + accCOInvoiceRec.AccountingCOInvoiceHeaderRec.FormattedCustomerName +';' +
							 accCOInvoiceRec.AccountingCOInvoiceHeaderRec.COHeaderNumber + ';';
			for(AccountingCustomerInvoice.AccountingCOInvoiceItem coInvItem : accCOInvoiceRec.AccountingCOInvoiceItemsRecs) {
				this.Narration += coInvItem.ServiceJobName;
				this.Narration += ';' + coInvItem.VinNumber;
			}				
		} else {
			this.Narration += ';Invoice COGS';
		}
		this.JournalDate =  DateTimeUtility.getFormttedDateFromDateTime(accCOInvoiceRec.AccountingCOInvoiceHeaderRec.COInvoiceDate, 'yyyy-MM-dd');
		for(Object lineItemRec : AccountingCustomerInvoiceService.setAllInvoiceItemRec((AccountingCustomerInvoice) accCOInvoiceRec, IntegrationUtility.CO_INVOICE_JE)) {
			JournalLines journalLinesRec = (JournalLines) lineItemRec;
			if(journalLinesRec.LineAmount != 0) {
				this.JournalLines.add(journalLinesRec);
			}
		}
		if(AccountingCustomerInvoiceService.IsSetLineAmountTypesToExclusive) {
			this.LineAmountTypes = 'Exclusive';
			AccountingCustomerInvoiceService.IsSetLineAmountTypesToExclusive = false;
		}
	}
	
	public XeroJournalEntryDTO(AccountingCountSession countSessionObj) {
		
		this.JournalLines =  new List<JournalLines>();
		this.SFId = countSessionObj.Id;
		this.ManualJournalID = countSessionObj.XeroAccountingId;
		this.Status = 'POSTED';
		this.Quantity = 1;
		this.Url = AccountingUtil.getURL(countSessionObj.XeroAccountingId, 'CountSession');
		
		this.Narration = countSessionObj.CountSessionNumber +';' + countSessionObj.Name +';' + 'Part Count';
		this.JournalDate =  String.ValueOf((countSessionObj.CountDate));
		
		for(AccountingCountSession.AccountingCountSessionLineItem countSessionLineItemRec : countSessionObj.CountSessionLineItemList) {
			if(countSessionLineItemRec.TotalCostAdjustment != null && countSessionLineItemRec.TotalCostAdjustment != 0) {
				this.JournalLines.add(new JournalLines(countSessionLineItemRec.TotalCostAdjustment.setScale(2, RoundingMode.HALF_UP), countSessionLineItemRec.PartCategoryInventoryGL, this.Narration));
			}
		}
		
		this.JournalLines.add(new JournalLines((countSessionObj.TotalCostAdjustment.setScale(2, RoundingMode.HALF_UP) * -1), countSessionObj.AdjustmentCategoryIncomeGL, this.Narration));
	}

	public XeroJournalEntryDTO(AccountingCashReconciliation cashReconRecord) {
		
		this.JournalLines =  new List<JournalLines>();
		this.SFId = cashReconRecord.Id;
		this.ManualJournalID = cashReconRecord.AccountingId;
		this.Status = 'POSTED';
		this.Quantity = 1;
		
		this.Narration = String.ValueOf(cashReconRecord.ReconciliationDate) +';' + 'Cash reconciliation' +';' + cashReconRecord.OptionalNote;
		this.Narration = this.Narration.length() > 1000 ? this.Narration.substring(0, 1000) : this.Narration;
		this.JournalDate =  String.ValueOf((cashReconRecord.ReconciliationDate));
		
		String lineItemDesc;
        for(AccountingCashReconciliation.CashReconciliationPaymentWrapper reconPaymentRec : cashReconRecord.ReconPaymentList) {
            if(reconPaymentRec.ActualAmount != null && reconPaymentRec.ActualAmount != 0) {
                lineItemDesc = String.ValueOf(cashReconRecord.ReconciliationDate) + ' - '+ reconPaymentRec.PaymentName + ' - ' + reconPaymentRec.CashDrawerName;
				this.JournalLines.add(new JournalLines(reconPaymentRec.ActualAmount.setScale(2, RoundingMode.HALF_UP),AccountingUtil.getChartofAccount('Undeposited Funds'), lineItemDesc));
            }
        }
        if(cashReconRecord.TotalProcessedAmount != 0) {
			this.JournalLines.add(new JournalLines((cashReconRecord.TotalProcessedAmount.setScale(2, RoundingMode.HALF_UP) * -1), AccountingUtil.getChartofAccount('Cash Rec Clearing'), String.ValueOf(cashReconRecord.ReconciliationDate) + ' - Cash reconciliation'));
        }

        if(cashReconRecord.TotalVariance != 0) {
			this.JournalLines.add(new JournalLines((cashReconRecord.TotalVariance.setScale(2, RoundingMode.HALF_UP) * -1), AccountingUtil.getChartofAccount('Cash over/short'), String.ValueOf(cashReconRecord.ReconciliationDate) + ' - Cash reconciliation'));
        }
	}
	
	public XeroJournalEntryDTO(AccountingVendorReturn vendorReturn) {
		
		this.JournalLines =  new List<JournalLines>();
		this.SFId = vendorReturn.Id;
		this.ManualJournalID = vendorReturn.XeroVarianceJEAccountingId;
		this.Status = 'POSTED';
		this.Quantity = 1;
		this.Url = AccountingUtil.getURL(vendorReturn.Id, 'ReturnVO');
		
		this.Narration = vendorReturn.RTNNumber + ';' + vendorReturn.CreditMemoNumber + ';' +
					vendorReturn.VendorName + ';' + 'Cost variances';
		this.JournalDate =  DateTimeUtility.getFormttedDateFromDateTime(vendorReturn.CreditedDateTime, 'yyyy-MM-dd');
		
	    for(AccountingVendorReturn.ReturnCRLineItemWrapper returnCRLI: vendorReturn.ReturnCRLIList) {
			if(returnCRLI.Variance != null && returnCRLI.Variance != 0) {
            	this.JournalLines.add(new JournalLines(returnCRLI.Variance * -1, AccountingUtil.getChartofAccount('A/P Inventory Accrual'), (returnCRLI.ItemDescription + ';Return Cost Variance')));
				this.JournalLines.add(new JournalLines(returnCRLI.Variance, AccountingUtil.getChartofAccount('Inventory Adjustments'), (returnCRLI.ItemDescription + ';Return Inventory Adjustment')));
			}
        }
	}

	public XeroJournalEntryDTO(AccountingVendorInvoice vendorInvoiceRecord) {
		
		this.JournalLines =  new List<JournalLines>();
		this.SFId = vendorInvoiceRecord.Id;
		this.ManualJournalID = vendorInvoiceRecord.AccountingVIHeaderRec.XeroVarinaceJEAccountingId;
		this.Status = 'POSTED';
		this.Quantity = 1;
		this.Url = AccountingUtil.getURL(vendorInvoiceRecord.Id, 'VendorOrderInvoicing');
		
		this.Narration = vendorInvoiceRecord.AccountingVIHeaderRec.VIHeaderNumber + ';' + vendorInvoiceRecord.AccountingVIHeaderRec.InvoiceNumber + ';' +
							vendorInvoiceRecord.AccountingVIHeaderRec.VendorName + ';' + 'Cost variances';
		this.JournalDate =  DateTimeUtility.getFormttedDateFromDateTime(vendorInvoiceRecord.AccountingVIHeaderRec.InvoicedDateTime, 'yyyy-MM-dd');
		
		String description = vendorInvoiceRecord.AccountingVIHeaderRec.VIHeaderNumber + ';' + vendorInvoiceRecord.AccountingVIHeaderRec.VendorName + ';' +
	    						vendorInvoiceRecord.AccountingVIHeaderRec.InvoiceNumber + ';';
	    String VRNumberFoDesc = vendorInvoiceRecord.VRNumberSet.size() == 1 ? new List<String>(vendorInvoiceRecord.VRNumberSet)[0] + ';' : '';
	    for(AccountingVendorInvoice.AccountingVIGroupByGLAndType accVIGRec: vendorInvoiceRecord.AccountingVIGroupByGLAndTypeList) {
            if(accVIGRec.Type == AccountingVendorInvoice.INVENTORY_RECEIVED) continue;
			if(accVIGRec.Total != null && accVIGRec.Total != 0) {
				this.JournalLines.add(new JournalLines(accVIGRec.Total, accVIGRec.GLNumber, (VRNumberFoDesc + description + accVIGRec.Type)));
			}
        }
	}
	
	private String setNarrationForDealMerchAndService(AccountingCustomerInvoice accCOInvoiceRec) {
		String soHeaderId = accCOInvoiceRec.AccountingCOInvoiceItemsRecs.size() > 0 ? accCOInvoiceRec.AccountingCOInvoiceItemsRecs[0].SOHeaderId : '';
		Set<String> skuNumberSet = new Set<String>();
		for(AccountingCustomerInvoice.AccountingCOInvoiceItem coInvItem : accCOInvoiceRec.AccountingCOInvoiceItemsRecs) {
			skuNumberSet.add(coInvItem.SkuNumber);
		}
		skuNumberSet.remove(null);
		if(String.isBlank(soHeaderId)) {
			if(skuNumberSet.size() > 1) {
				return ';Deal Merchandise;Multiple Units';
			} else if(skuNumberSet.size() == 1) {
				return ';Deal Merchandise;' + (new List<String>(skuNumberSet))[0];
			}
		} else {
			return ';Deal Service;' + accCOInvoiceRec.AccountingCOInvoiceItemsRecs[0].SKUNumberonDealService;
		}
		
		return '';
	}
	
}