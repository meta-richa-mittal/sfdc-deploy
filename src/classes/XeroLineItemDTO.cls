public without sharing class XeroLineItemDTO {
	public String Description;
	public Decimal Quantity;
	public Decimal UnitAmount;
	public String AccountCode;
	public String TaxType;
	public Decimal TaxAmount;
	
	public XeroLineItemDTO(CO_Line_Item__c coliRec, AccountingCustomerInvoice customerInvoiceRecord) {
		this.Quantity = 1;
		if(coliRec.Part__c != null) {
			this.AccountCode = (coliRec.CO_Header__r.Transaction_Type__c != null && coliRec.CO_Header__r.Transaction_Type__r.Part_Category__c != null && coliRec.CO_Header__r.Transaction_Type__r.Part_Category__r.Income_GL__c != null) 
									? coliRec.CO_Header__r.Transaction_Type__r.Part_Category__r.Income_GL__c : coliRec.Part__r.Category__r.Income_GL__c;
		} else if(coliRec.Fee__c != null) {
			this.AccountCode = coliRec.Fee__r.Category__r.Income_GL__c;
		}
		
		Decimal price = 0;
		Decimal invoiceTotal = customerInvoiceRecord.AccountingCOInvoiceHeaderRec.InvoiceTotal;
		if(GeneralConfiguration.getTaxIncludingPricing()) {
			price = (coliRec.Price_When_Tax_Included__c != null ? coliRec.Price_When_Tax_Included__c : 0).setScale(2, RoundingMode.HALF_UP);
			this.TaxAmount = ((coliRec.Qty__c != null ? coliRec.Qty__c : 0) * (customerInvoiceRecord.EntityIdToTotalSalesTaxValueMap.get(coliRec.Id) != null ? customerInvoiceRecord.EntityIdToTotalSalesTaxValueMap.get(coliRec.Id) : 0)).setScale(2, RoundingMode.HALF_UP);
		} else {
			price = (coliRec.Price__c != null ? coliRec.Price__c : 0).setScale(2, RoundingMode.HALF_UP);
			this.TaxAmount = (coliRec.Tax_Amount__c != null ? coliRec.Tax_Amount__c : 0).setScale(2, RoundingMode.HALF_UP);
		}
		coliRec.Qty__c = coliRec.Qty__c != null ? (coliRec.Qty__c).setScale(2, RoundingMode.HALF_UP) : 0 ;
		this.UnitAmount = ((coliRec.Qty__c != null ? coliRec.Qty__c : 0) * price).setScale(2, RoundingMode.HALF_UP);
		 
		this.Description = (coliRec.Item_Code__c != null) ? coliRec.Item_Code__c + '-' : '';
		this.Description += (coliRec.Item_Description__c != null) ? coliRec.Item_Description__c : '';
		this.Description += ';' + (coliRec.Qty__c != null ? (invoiceTotal < 0 ? coliRec.Qty__c*-1 : coliRec.Qty__c) : 0) + ' @ ';
		this.Description += ' ' + price;
		
		this.TaxType = coliRec.Applicable_Tax__c != null ? coliRec.Applicable_Tax__r.Accounting_Id__c : QBUtil.nonTaxableCodeAccId;
		
		if(invoiceTotal < 0) {
			this.UnitAmount *= -1;	
			this.TaxAmount *= -1;
		}
		
		if(!QBUtil.isQBTaxCodesEnabled) {
			resetTaxValueWhenTaxCodeSettingIsOff();
		}
	}
	
	public XeroLineItemDTO(Service_Order_Line_Item__c soliRec, AccountingCustomerInvoice customerInvoiceRecord) {
		this.Quantity = 1;
		Decimal price = 0;
		Decimal invoiceTotal = customerInvoiceRecord.AccountingCOInvoiceHeaderRec.InvoiceTotal;
		if(soLIRec.Part__c != null) {
			if(String.isNotBlank(soLIRec.Service_Order_Header__r.Transaction_Type__r.Part_Category__r.Income_GL__c)) {
				this.AccountCode = soLIRec.Service_Order_Header__r.Transaction_Type__r.Part_Category__r.Income_GL__c;
			} else {
				this.AccountCode = soLIRec.Part__r.Category__r.Income_GL__c;
			}
		} else if(soLIRec.Fee__c != null) {
			this.AccountCode = soLIRec.Fee__r.Category__r.Income_GL__c;
		} else if(soLIRec.Labour_Code__c != null) {
			if(String.isNotBlank(soLIRec.Service_Order_Header__r.Transaction_Type__r.Labour_Category__r.Income_GL__c)) {
					this.AccountCode = soLIRec.Service_Order_Header__r.Transaction_Type__r.Labour_Category__r.Income_GL__c;
				} else {
					this.AccountCode = soLIRec.Labour_Code__r.Category__r.Income_GL__c;
				}
		} else if(soLIRec.Sublet__c != null) {
			this.AccountCode = soLIRec.Sublet__r.Category__r.Income_GL__c;     
		}
		
		if(GeneralConfiguration.getTaxIncludingPricing()) {
			price = (soLIRec.Price_When_Tax_Included__c != null ? soLIRec.Price_When_Tax_Included__c : 0).setScale(2, RoundingMode.HALF_UP);
			this.TaxAmount = ((soLIRec.Qty_Needed__c != null ? soLIRec.Qty_Needed__c : 0) * (customerInvoiceRecord.EntityIdToTotalSalesTaxValueMap.get(soLIRec.Id) != null ? customerInvoiceRecord.EntityIdToTotalSalesTaxValueMap.get(soLIRec.Id) : 0)).setScale(2, RoundingMode.HALF_UP);
		} else {
			price = (soLIRec.Kit_Price__c != null ? soLIRec.Kit_Price__c.setScale(2, RoundingMode.HALF_UP) : 0);
			this.TaxAmount = (soLIRec.Tax_Amount__c != null ? soLIRec.Tax_Amount__c : 0).setScale(2, RoundingMode.HALF_UP);
		}
		this.UnitAmount = ((soLIRec.Qty_Needed__c != null ? soLIRec.Qty_Needed__c : 0) * price).setScale(2, RoundingMode.HALF_UP);
		soLIRec.Qty_Needed__c = soLIRec.Qty_Needed__c != null ? (soLIRec.Qty_Needed__c).setScale(2, RoundingMode.HALF_UP) : 0;
		this.Description = (soLIRec.Item_Code__c != null) ? soLIRec.Item_Code__c : '';
		this.Description += (soLIRec.Item_Description__c != null) ? ' - ' + soLIRec.Item_Description__c : '';
		this.Description += ';' + (soLIRec.Qty_Needed__c != null ? (invoiceTotal < 0 ? soLIRec.Qty_Needed__c*-1 : soLIRec.Qty_Needed__c) : 0) + ' @ ';
		this.Description += ' ' + price;
		
		this.TaxType = soLIRec.Applicable_Tax__c != null ? soLIRec.Applicable_Tax__r.Accounting_Id__c : QBUtil.nonTaxableCodeAccId;
		if(invoiceTotal < 0) {
			this.UnitAmount *= -1;	
			this.TaxAmount *= -1;
		}
		
		if(!QBUtil.isQBTaxCodesEnabled) {
			resetTaxValueWhenTaxCodeSettingIsOff();
		}
	}
	
	public XeroLineItemDTO(Deal_Item__c dealItemRec, Deal_Unit_Price_Cost__c dealUnitPriceandCost, AccountingCustomerInvoice customerInvoiceRecord) {
		this.Description = 'Unit: ';
		this.Description += dealItemRec.Customer_Owned_Unit__r.Stock_Id__c != null ? dealItemRec.Customer_Owned_Unit__r.Stock_Id__c + ';' : '';
		if(dealUnitPriceandCost.Type__c == 'Base') {
			this.Description += dealItemRec.Customer_Owned_Unit__r.Year__c != null ? dealItemRec.Customer_Owned_Unit__r.Year__c + ' ' : '';
			this.Description += dealItemRec.Customer_Owned_Unit__r.Unit_Make__r.Name != null ? ' ' + dealItemRec.Customer_Owned_Unit__r.Unit_Make__r.Name : '';
			this.Description += dealItemRec.Customer_Owned_Unit__r.Unit_Model__r.Name__c != null ? ' ' + dealItemRec.Customer_Owned_Unit__r.Unit_Model__r.Name__c : '';
			this.Description += dealItemRec.Customer_Owned_Unit__r.Sub_Model__r.Sub_Model_Name__c != null ? ' ' + dealItemRec.Customer_Owned_Unit__r.Sub_Model__r.Sub_Model_Name__c : '';
			this.Description += dealItemRec.Customer_Owned_Unit__r.VIN_Number__c != null ? ';' + dealItemRec.Customer_Owned_Unit__r.VIN_Number__c : '';
		} else {
			this.Description += dealUnitPriceandCost.Item_Description__c;
		}
		this.Quantity = 1;
		Decimal price = 0;
		this.AccountCode = dealItemRec.Customer_Owned_Unit__r.Category__r.Income_GL__c;
		if(GeneralConfiguration.getTaxIncludingPricing()) {
			price = (dealUnitPriceandCost.Price_When_Tax_Included__c != null ? dealUnitPriceandCost.Price_When_Tax_Included__c.setScale(2, RoundingMode.HALF_UP) : 0);
			this.TaxAmount = ((dealUnitPriceandCost.Qty__c != null ? dealUnitPriceandCost.Qty__c : 0) * (customerInvoiceRecord.EntityIdToTotalSalesTaxValueMap.get(dealUnitPriceandCost.Id) != null ? customerInvoiceRecord.EntityIdToTotalSalesTaxValueMap.get(dealUnitPriceandCost.Id) : 0)).setScale(2, RoundingMode.HALF_UP);
		} else {
			price = (dealUnitPriceandCost.Price__c != null ? dealUnitPriceandCost.Price__c.setScale(2, RoundingMode.HALF_UP) : 0);
			this.TaxAmount = (dealUnitPriceandCost.Tax_Amount__c != null ? dealUnitPriceandCost.Tax_Amount__c : 0).setScale(2, RoundingMode.HALF_UP);
		}
		this.UnitAmount = ((dealUnitPriceandCost.Qty__c != null ? dealUnitPriceandCost.Qty__c : 0) * price).setScale(2, RoundingMode.HALF_UP);
		if(customerInvoiceRecord.AccountingCOInvoiceHeaderRec.InvoiceTotal < 0) {
			this.UnitAmount *= -1;
			this.TaxAmount *= -1;
		}
		this.TaxType = dealItemRec.Applicable_Tax__c != null ? dealItemRec.Applicable_Tax__r.Accounting_Id__c : QBUtil.nonTaxableCodeAccId;
		
		if(!QBUtil.isQBTaxCodesEnabled) {
			resetTaxValueWhenTaxCodeSettingIsOff();
		}
	}
	
	public XeroLineItemDTO(Deal_Item__c dealItemRec, Option_Fee__c optionAndFee, AccountingCustomerInvoice customerInvoiceRecord) {
		Decimal price = 0;
		optionAndFee.Qty__c = (optionAndFee.Qty__c != null ? (optionAndFee.Qty__c).setScale(2, RoundingMode.HALF_UP) : 0);
		if(GeneralConfiguration.getTaxIncludingPricing()) {
			price = (optionAndFee.Price_When_Tax_Included__c != null ? optionAndFee.Price_When_Tax_Included__c : 0).setScale(2, RoundingMode.HALF_UP);
			this.TaxAmount = (optionAndFee.Qty__c * (customerInvoiceRecord.EntityIdToTotalSalesTaxValueMap.get(optionAndFee.Id) != null ? customerInvoiceRecord.EntityIdToTotalSalesTaxValueMap.get(optionAndFee.Id) : 0)).setScale(2, RoundingMode.HALF_UP);
		} else {
			price = (optionAndFee.Price__c != null ? optionAndFee.Price__c : 0).setScale(2, RoundingMode.HALF_UP);
			this.TaxAmount = (optionAndFee.Qty__c * (price *  (optionAndFee.Sales_Tax_Percentage__c != null ? optionAndFee.Sales_Tax_Percentage__c : 0))/100).setScale(2, RoundingMode.HALF_UP);
		}
		this.Description = 'Option: ';
		this.Description +=  (optionAndFee.Deal_Item__r.Customer_Owned_Unit__r.Stock_Id__c != null ? optionAndFee.Deal_Item__r.Customer_Owned_Unit__r.Stock_Id__c + ';' : '');
		this.Description +=  (optionAndFee.Item_Code__c != null) ? optionAndFee.Item_Code__c : '';
		this.Description +=  ((optionAndFee.Item_Description__c != null) ? ' - ' + optionAndFee.Item_Description__c   : '') + ';';
		this.Description +=  optionAndFee.Qty__c + ' @ ' + price;
		
		this.Quantity = 1;
		this.UnitAmount = (optionAndFee.Qty__c * price).setScale(2, RoundingMode.HALF_UP);
		
		
		if(optionAndFee.Part__c != null || optionAndFee.Labour_Code__c != null || (optionAndFee.Product__c != null && optionAndFee.Product__r.Type__c == Constants.SUBLET)) {
			this.AccountCode = dealItemRec.Customer_Owned_Unit__r.Category__r.Income_GL__c;
		} else if(optionAndFee.Fee__c != null) {
			this.AccountCode = optionAndFee.Fee__r.Category__r.Income_GL__c;
		} else if(optionAndFee.Product__c != null) {
			this.AccountCode = optionAndFee.Product__r.Category__r.Income_GL__c;
		}
		
		
		this.TaxType = optionAndFee.Applicable_Tax__c != null ? optionAndFee.Applicable_Tax__r.Accounting_Id__c : QBUtil.nonTaxableCodeAccId;
		
		if(customerInvoiceRecord.AccountingCOInvoiceHeaderRec.InvoiceTotal < 0) {
			this.UnitAmount *= -1;
			this.TaxAmount *= -1;
		}
		
		if(!QBUtil.isQBTaxCodesEnabled) {
			resetTaxValueWhenTaxCodeSettingIsOff();
		}
	}
	
	public XeroLineItemDTO(Deal_Item__c dealItemRec, AccountingCustomerInvoice customerInvoiceRecord, String recordType) {
		if(recordType == 'Trade In') {
			setTradeInXeroData(dealItemRec, customerInvoiceRecord);
		} else if(recordType == 'Lien Payout') {
			setLienPayoutXeroData(dealItemRec, customerInvoiceRecord);
		} else if(recordType == 'Stamp Duty') {
			setStampDutyXeroData(dealItemRec, customerInvoiceRecord);
		}
		if(!QBUtil.isQBTaxCodesEnabled) {
			resetTaxValueWhenTaxCodeSettingIsOff();
		}
	}
	
	// Deal Item taxes
	public XeroLineItemDTO(Deal_Item__c dealItemRec, AccountingCustomerInvoice customerInvoiceRecord, Map<String, Category__c> tradeInTaxCategoryIdToRecMap, String recordType, Boolean isCreditLine) {
		String taxCategoryIncomeGL;
		Decimal taxAmount = 0;
		if(recordType == 'Stocked Trade In Tax') {
			taxAmount = (dealItemRec.Tax_Amount__c != null) ? dealItemRec.Tax_Amount__c.setScale(2, RoundingMode.HALF_UP) : 0;
			taxCategoryIncomeGL = tradeInTaxCategoryIdToRecMap.containsKey(GeneralConfiguration.getTradeTaxPendingSaleCategory()) ? tradeInTaxCategoryIdToRecMap.get(GeneralConfiguration.getTradeTaxPendingSaleCategory()).Income_GL__c : '';
			if(isCreditLine) {
				setDealItemSalesTaxXeroData('Stocked Trade In Tax', taxAmount, AccountingUtil.getSystemDefaultCategory('Tax').size() > 0 ? AccountingUtil.getSystemDefaultCategory('Tax')[0].Income_GL__c : '');
			} else {
				setDealItemSalesTaxXeroData('Stocked Trade In Tax', taxAmount * -1, taxCategoryIncomeGL);
			}
		}  else if(recordType == 'Unit Sales Tax Credit') {
			if(dealItemRec.Customer_Owned_Unit__r.Sales_Tax_Credit__c != null && dealItemRec.Customer_Owned_Unit__r.Sales_Tax_Credit__c != 0) {
				taxAmount = (dealItemRec.Customer_Owned_Unit__r.Sales_Tax_Credit__c != null) ? dealItemRec.Customer_Owned_Unit__r.Sales_Tax_Credit__c.setScale(2, RoundingMode.HALF_UP) : 0;
				if(isCreditLine) {
					taxCategoryIncomeGL = tradeInTaxCategoryIdToRecMap.containsKey(GeneralConfiguration.getTradeTaxPendingSaleCategory()) ? tradeInTaxCategoryIdToRecMap.get(GeneralConfiguration.getTradeTaxPendingSaleCategory()).Income_GL__c : '';
					setDealItemSalesTaxXeroData('Unit Sales Tax Credit', taxAmount, taxCategoryIncomeGL);
				} else {
					taxCategoryIncomeGL = tradeInTaxCategoryIdToRecMap.containsKey(GeneralConfiguration.getTradeTaxLiabilityCategory()) ? tradeInTaxCategoryIdToRecMap.get(GeneralConfiguration.getTradeTaxLiabilityCategory()).Income_GL__c : '';
					setDealItemSalesTaxXeroData('Unit Selling Price VS Trade-In Value', taxAmount * -1, taxCategoryIncomeGL);
				}
			} else if(dealItemRec.Customer_Owned_Unit__r.Purchase_Tax_Credit__c != null && dealItemRec.Customer_Owned_Unit__r.Purchase_Tax_Credit__c != 0) {
				taxAmount = (dealItemRec.Customer_Owned_Unit__r.Purchase_Tax_Credit__c != null) ? dealItemRec.Customer_Owned_Unit__r.Purchase_Tax_Credit__c.setScale(2, RoundingMode.HALF_UP) : 0;
				if(isCreditLine) {
					taxCategoryIncomeGL = tradeInTaxCategoryIdToRecMap.containsKey(GeneralConfiguration.getTradeTaxPendingSaleCategory()) ? tradeInTaxCategoryIdToRecMap.get(GeneralConfiguration.getTradeTaxPendingSaleCategory()).Income_GL__c : '';
					setDealItemSalesTaxXeroData('Unit Puchase Tax Credit', taxAmount, taxCategoryIncomeGL);
				} else {
					taxCategoryIncomeGL = tradeInTaxCategoryIdToRecMap.containsKey(GeneralConfiguration.getPurchaseTaxLiabilityCategory()) ? tradeInTaxCategoryIdToRecMap.get(GeneralConfiguration.getPurchaseTaxLiabilityCategory()).Income_GL__c : '';
					setDealItemSalesTaxXeroData('Unit Selling Price VS Purchase Value', taxAmount * -1, taxCategoryIncomeGL);
				}
			}
		} else if(recordType == 'Unit Sales Tax') {
			taxAmount = (customerInvoiceRecord.unitIdToTaxAmountMap.containskey(dealItemRec.Id) ? customerInvoiceRecord.unitIdToTaxAmountMap.get(dealItemRec.Id) : 0) * -1;
			taxCategoryIncomeGL = tradeInTaxCategoryIdToRecMap.containsKey(GeneralConfiguration.getTradeTaxLiabilityCategory()) ? tradeInTaxCategoryIdToRecMap.get(GeneralConfiguration.getTradeTaxLiabilityCategory()).Income_GL__c : '';
			setDealItemSalesTaxXeroData('Unit Selling Price VS Trade-In Value', taxAmount, taxCategoryIncomeGL);
		} else if(recordType == 'Diff Of Unit Sales Tax Credit And Unit Sales Tax') {
			taxAmount = ((!customerInvoiceRecord.unitIdToTaxAmountMap.containskey(dealItemRec.Id)) ? dealItemRec.Customer_Owned_Unit__r.Sales_Tax_Credit__c :
														(dealItemRec.Customer_Owned_Unit__r.Sales_Tax_Credit__c - customerInvoiceRecord.unitIdToTaxAmountMap.get(dealItemRec.Id))) * -1;
			taxCategoryIncomeGL = tradeInTaxCategoryIdToRecMap.containsKey(GeneralConfiguration.getTradeTaxExpenseCategory()) ? tradeInTaxCategoryIdToRecMap.get(GeneralConfiguration.getTradeTaxExpenseCategory()).Income_GL__c : '';
			setDealItemSalesTaxXeroData('Unit Selling Price VS Trade-In Value', taxAmount, taxCategoryIncomeGL);
		}
		
		if(!QBUtil.isQBTaxCodesEnabled) {
			resetTaxValueWhenTaxCodeSettingIsOff();
		}
	}
	
	// Deductible
	public XeroLineItemDTO(String description, Decimal unitAmount, String deductibleGL) {
		this.Description = description;
		this.Quantity = 1;
		this.UnitAmount = unitAmount;
		this.TaxAmount = 0;
		this.TaxType = QBUtil.nonTaxableCodeAccId;
		this.AccountCode = deductibleGL;
		if(!QBUtil.isQBTaxCodesEnabled) {
			resetTaxValueWhenTaxCodeSettingIsOff();
		}
	}
	
	 public XeroLineItemDTO(AccountingVendorInvoice.AccountingVIGroup viGroup, String appliedTaxAccountingId, Decimal appliedTaxRate) {
		 String description = viGroup.ItemDesc;
		 this.UnitAmount = (viGroup.InvoiceCost*((100.00 - viGroup.Discount)/ 100)).setScale(2, RoundingMode.HALF_UP);
		 this.Description =  description + ';' + viGroup.InvoiceTotalQty +'@$'+ this.UnitAmount;
		 this.Quantity = viGroup.InvoiceTotalQty;
		 this.AccountCode = AccountingUtil.getChartofAccount('A/P Inventory Accrual');
		 this.TaxType = appliedTaxAccountingId;
		 if(!QBUtil.isQBTaxCodesEnabled) {
			resetTaxValueWhenTaxCodeSettingIsOff();
		}
	 }
	 
	 public XeroLineItemDTO(String description, Decimal quantity, Decimal unitAmount, String accountCode, String appliedTaxAccountingId) {
		 this.Description =  description;
		 this.Quantity = quantity != null ? quantity.setScale(2, RoundingMode.HALF_UP) : quantity;
		 this.UnitAmount = unitAmount.setScale(2, RoundingMode.HALF_UP);
		 this.AccountCode = accountCode;
		 this.TaxType = appliedTaxAccountingId;
		 if(!QBUtil.isQBTaxCodesEnabled) {
			resetTaxValueWhenTaxCodeSettingIsOff();
		}
	 }
	 
	 public XeroLineItemDTO(String description, Decimal quantity, Decimal unitAmount, String accountCode, String appliedTaxAccountingId, Decimal taxAmount) {
		this(description, quantity, unitAmount, accountCode, appliedTaxAccountingId);
		this.TaxAmount = (taxAmount == null) ? 0 : taxAmount.setScale(2, RoundingMode.HALF_UP);
		if(unitAmount < 0 && this.TaxAmount > 0){
			this.TaxAmount *= -1; 
		}
		if(!QBUtil.isQBTaxCodesEnabled) {
			resetTaxValueWhenTaxCodeSettingIsOff();
		}
	 }
	 
	 public XeroLineItemDTO(AccountingVendorReturn.ReturnCRLineItemWrapper returnCRLI, String appliedTaxAccountingId) {
		returnCRLI.ReturnQty = returnCRLI.ReturnQty != null ? returnCRLI.ReturnQty.setScale(2, RoundingMode.HALF_UP) : returnCRLI.ReturnQty;
		String description = returnCRLI.ItemDescription;
		this.Description =  description + ';Returned ' + returnCRLI.ReturnQty +'@$'+ returnCRLI.ItemCost;
		this.Quantity = returnCRLI.ReturnQty;
		this.UnitAmount = returnCRLI.ItemCost.setScale(2, RoundingMode.HALF_UP);
		this.AccountCode = AccountingUtil.getChartofAccount('A/P Inventory Accrual');
		this.TaxType = appliedTaxAccountingId;
		if(!QBUtil.isQBTaxCodesEnabled) {
		   resetTaxValueWhenTaxCodeSettingIsOff();
	   }
	 }
	 
	 public XeroLineItemDTO(AccountingLienPayout accountingLienPayoutRec) {
		this.Description = 'Lien payout: ' + accountingLienPayoutRec.SkuId + ';' + (String.isNotBlank(accountingLienPayoutRec.SkuYear) ? accountingLienPayoutRec.SkuYear + ' ' : '') 
			+ accountingLienPayoutRec.SkuMake + accountingLienPayoutRec.SkuModel + ';' +
		 (accountingLienPayoutRec.SkuSubModel != null ? accountingLienPayoutRec.SkuSubModel + ';'  : '')  + (accountingLienPayoutRec.SkuVINNumber != null ? accountingLienPayoutRec.SkuVINNumber + ';' :'') 
		 + accountingLienPayoutRec.CustomerName;
		this.Quantity = 1;
		this.UnitAmount = accountingLienPayoutRec.LienPayout.setScale(2, RoundingMode.HALF_UP);
		this.TaxAmount = 0;
		this.TaxType = QBUtil.nonTaxablePurchaseCodeAccId;
		this.AccountCode = accountingLienPayoutRec.CategoyIncomeGLAccountRef;
		if(!QBUtil.isQBTaxCodesEnabled) {
			resetTaxValueWhenTaxCodeSettingIsOff();
		}
	}
	
	public XeroLineItemDTO(F_I_Product__c FIProduct, AccountingCustomerInvoice customerInvoiceRecord) {
		this.Description = 'Financing: ' + FIProduct.Item_Description__c;
		this.AccountCode = FIProduct.Vendor_Product__r.Category__r.Income_GL__c;
		this.Quantity = 1;
		Decimal price = 0;
		
		if(GeneralConfiguration.getTaxIncludingPricing()) {
			this.UnitAmount = (FIProduct.Price_When_Tax_Included__c != null ? FIProduct.Price_When_Tax_Included__c : 0).setScale(2, RoundingMode.HALF_UP);
				this.TaxAmount = ((customerInvoiceRecord.EntityIdToTotalSalesTaxValueMap.get(FIProduct.Id) != null ? customerInvoiceRecord.EntityIdToTotalSalesTaxValueMap.get(FIProduct.Id) : 0)).setScale(2, RoundingMode.HALF_UP);
			
		} else {
			this.UnitAmount = (FIProduct.Price__c != null ? FIProduct.Price__c : 0).setScale(2, RoundingMode.HALF_UP);
			this.TaxAmount = ((FIProduct.Price__c != null ? FIProduct.Price__c : 0) *  (FIProduct.Sales_Tax_Percentage__c != null ? FIProduct.Sales_Tax_Percentage__c : 0) / 100).setScale(2, RoundingMode.HALF_UP);
		}
		this.TaxType = FIProduct.Applicable_Tax__c != null ? FIProduct.Applicable_Tax__r.Accounting_Id__c : QBUtil.nonTaxableCodeAccId;
		if(customerInvoiceRecord.AccountingCOInvoiceHeaderRec.InvoiceTotal < 0) {
			this.UnitAmount *= -1;
			this.TaxAmount *= -1;
		}
		if(!QBUtil.isQBTaxCodesEnabled) {
			resetTaxValueWhenTaxCodeSettingIsOff();
		}
	}
	
	public XeroLineItemDTO(AccountingUnit unitRec, Boolean isConsignment){
		String memo = '';
		if(isConsignment) {
			memo += 'Consignment payout:' + (String.isNotBlank(unitRec.VIN) ? + unitRec.VIN : '');
			List<Category__c> consignmentCategory = [select Name, Income_GL__c from Category__c
													where Type__c =: AccountingIntegrationSettingsCtrl.CONSIGNMENT_CLEARING AND Active__c = true AND Default__c = true]; 
			this.AccountCode = consignmentCategory[0].Income_GL__c;
			this.UnitAmount = unitRec.AgreedPayout; 
		
		} else {
			if(unitRec.StockNumber != null) {
				memo += unitRec.StockNumber + ';';
			}
			if(unitRec.VIN != null){
				memo += unitRec.VIN + ';';
			}
			if(unitRec.MakeName != null){
				memo += unitRec.MakeName + ' ';
			} 
			if(unitRec.ModelName != null){
				memo += unitRec.ModelName + ' ';
			} 
			if(unitRec.SubModelName != null){
				memo += unitRec.SubModelName;
			}
			if(unitRec.Inventory_GL != null) {
				this.AccountCode = unitRec.Inventory_GL;
			} else {
				List<Category__c> defaultCategory = [select Name, Inventory_GL__c  from Category__c
													where Type__c = 'Unit' AND Active__c = true AND Default__c = true]; 
				this.AccountCode = defaultCategory[0].Inventory_GL__c;
			}
			this.UnitAmount = (QBUtil.isQBTaxCodesEnabled && GeneralConfiguration.getTaxIncludingPricing()) ? unitRec.TotalCostWithTax.setScale(2, RoundingMode.HALF_UP): unitRec.TotalCost.setScale(2, RoundingMode.HALF_UP); 
		
		}
		this.Description = memo;
		this.Quantity = 1;
		
		this.TaxType = unitRec.AppliedQBTaxCode;
		if(!(QBUtil.isQBTaxCodesEnabled && GeneralConfiguration.getTaxIncludingPricing())) {
			this.TaxAmount = unitRec.TotalPurchaseTax;
		} 
		if(!QBUtil.isQBTaxCodesEnabled) {
			resetTaxValueWhenTaxCodeSettingIsOff();
		}
	}
	
	public XeroLineItemDTO(AccountingCustomerInvoice.TaxDetail taxRec) {
		this.Description = taxRec.Name;
		this.Quantity = 1;
		this.UnitAmount = taxRec.TaxAmount.setScale(2, RoundingMode.HALF_UP);
		this.AccountCode = taxRec.AccountingId;
		this.TaxType = 'NONE';
		this.TaxAmount = 0;
	}

	public XeroLineItemDTO(AccountingUnitPriceAndCost.TaxDetail taxRec) {
		this.Description = taxRec.Name;
		this.Quantity = 1;
		this.UnitAmount = taxRec.TaxAmount.setScale(2, RoundingMode.HALF_UP);
		if(this.UnitAmount < 0) {
			this.UnitAmount *= -1;
		}
		this.AccountCode = taxRec.AccountingId;
		this.TaxType = 'NONE';
		this.TaxAmount = 0;
	}
	
	public XeroLineItemDTO(AccountingVendorInvoice.AccountingPurchaseTax purchaseTaxRec) {
		this.Description = 'Purchase Tax - ' + purchaseTaxRec.SalesTaxName;
		this.Quantity = 1;
		this.UnitAmount = purchaseTaxRec.TaxAmount.setScale(2, RoundingMode.HALF_UP);
		this.AccountCode = purchaseTaxRec.CategoyRef;
		this.TaxType = 'NONE';
		this.TaxAmount = 0;
	}
	
	public XeroLineItemDTO(AccountingVendorReturn.AccountingPurchaseTax purchaseTaxRec) {
		this.Description = 'Purchase Tax - ' + purchaseTaxRec.SalesTaxName;
		this.Quantity = 1;
		this.UnitAmount = purchaseTaxRec.TaxAmount.setScale(2, RoundingMode.HALF_UP);
		this.AccountCode = purchaseTaxRec.CategoyRef;
		this.TaxType = 'NONE';
		this.TaxAmount = 0;
		}
	
	public XeroLineItemDTO(AccountingUnit.AccountingPurchaseTax purchaseTaxRec) {
		this.Description = 'Purchase Tax - ' + purchaseTaxRec.SalesTaxName;
		this.Quantity = 1;
		this.UnitAmount = purchaseTaxRec.TaxAmount.setScale(2, RoundingMode.HALF_UP);
		this.AccountCode = purchaseTaxRec.CategoyRef;
		this.TaxType = 'NONE';
		this.TaxAmount = 0;
	}
	
	public XeroLineItemDTO(CO_Invoice_Payment__c coInvPaymentRec) {
		this.Description = 'AR credit ' + (coInvPaymentRec.AR_Credit_Number__c != null ? coInvPaymentRec.AR_Credit_Number__c : '') + ' used as payment on ' + coInvPaymentRec.CO_Invoice_Header__r.CO_Header__r.Name;
		this.Quantity = 1;
		this.UnitAmount = coInvPaymentRec.Amount__c != null ? coInvPaymentRec.Amount__c : 0;
		this.AccountCode = Accountingutil.getChartofAccount(AccountingUtil.isNewPaymentAccountingApplicable(coInvPaymentRec.Payment_Date__c) ? 'Checkout Clearing' :'Customer Deposits');
		this.TaxType = 'NONE';
		this.TaxAmount = 0;
	}
	
	private void setTradeInXeroData(Deal_Item__c dealItemRec, AccountingCustomerInvoice customerInvoiceRecord) {
		this.Quantity = 1;
		this.Description = 'Trade-in: ';
		this.Description += dealItemRec.Stocked_In_Unit__r.Stock_Id__c != null ? dealItemRec.Stocked_In_Unit__r.Stock_Id__c + ';' : '';
		this.Description += dealItemRec.Customer_Owned_Unit__r.Year__c != null ? dealItemRec.Customer_Owned_Unit__r.Year__c + ' ' : '';
		this.Description += dealItemRec.Customer_Owned_Unit__r.Unit_Make__r.Name != null ? ' ' + dealItemRec.Customer_Owned_Unit__r.Unit_Make__r.Name : '';
		this.Description += dealItemRec.Customer_Owned_Unit__r.Unit_Model__r.Name__c != null ? ' ' + dealItemRec.Customer_Owned_Unit__r.Unit_Model__r.Name__c : '';
		this.Description += dealItemRec.Customer_Owned_Unit__r.Sub_Model__r.Sub_Model_Name__c != null ? ' ' + dealItemRec.Customer_Owned_Unit__r.Sub_Model__r.Sub_Model_Name__c : '';
		this.Description += dealItemRec.Customer_Owned_Unit__r.VIN_Number__c != null ? ';' + dealItemRec.Customer_Owned_Unit__r.VIN_Number__c : '';
		/*if(dealItemRec.Is_Stocked_In__c) {
			this.AccountCode = AccountingUtil.getSystemDefaultCategory('Stocked Trade');
		} else {
			this.AccountCode = AccountingUtil.getSystemDefaultCategory('Trade-in');
		}*/
		this.AccountCode = AccountingUtil.getSystemDefaultCategory('Stocked Trade').size() > 0 ? AccountingUtil.getSystemDefaultCategory('Stocked Trade')[0].Income_GL__c : '';
		this.UnitAmount = (dealItemRec.Agreed_Value__c != null) ? dealItemRec.Agreed_Value__c.setScale(2, RoundingMode.HALF_UP)*-1 : 0;
		if(GeneralConfiguration.getTaxIncludingPricing()) {
			this.TaxAmount = ((this.UnitAmount - (this.UnitAmount / (1 + dealItemRec.Default_Unit_Sales_Tax_Percentage__c/100))).setScale(2, RoundingMode.HALF_UP));
		} else {
			this.TaxAmount = (((this.UnitAmount * dealItemRec.Default_Unit_Sales_Tax_Percentage__c)/100).setScale(2, RoundingMode.HALF_UP));
		}
		this.TaxType = dealItemRec.Applicable_Tax__c != null ? dealItemRec.Applicable_Tax__r.Accounting_Id__c : QBUtil.nonTaxableCodeAccId;
	}
	
	private void setLienPayoutXeroData(Deal_Item__c dealItemRec, AccountingCustomerInvoice customerInvoiceRecord) {
		this.Quantity = 1;
		this.Description = 'Lien payout: ';
		this.Description += dealItemRec.Stocked_In_Unit__r.Stock_Id__c != null ? dealItemRec.Stocked_In_Unit__r.Stock_Id__c + ';' : '';
		this.Description += dealItemRec.Customer_Owned_Unit__r.Year__c != null ? dealItemRec.Customer_Owned_Unit__r.Year__c + ' ' : '';
		this.Description += dealItemRec.Customer_Owned_Unit__r.Unit_Make__r.Name != null ? ' ' + dealItemRec.Customer_Owned_Unit__r.Unit_Make__r.Name : '';
		this.Description += dealItemRec.Customer_Owned_Unit__r.Unit_Model__r.Name__c != null ? ' ' + dealItemRec.Customer_Owned_Unit__r.Unit_Model__r.Name__c : '';
		this.Description += dealItemRec.Customer_Owned_Unit__r.Sub_Model__r.Sub_Model_Name__c != null ? ' ' + dealItemRec.Customer_Owned_Unit__r.Sub_Model__r.Sub_Model_Name__c : '';
		this.Description += dealItemRec.Customer_Owned_Unit__r.VIN_Number__c != null ? ';' + dealItemRec.Customer_Owned_Unit__r.VIN_Number__c : '';
		this.Description += dealItemRec.Finance_Company__r.Name != null ? ';' + dealItemRec.Finance_Company__r.Name : '';
		this.AccountCode = AccountingUtil.getSystemDefaultCategory('Lien Payout').size() > 0 ? AccountingUtil.getSystemDefaultCategory('Lien Payout')[0].Income_GL__c : '';
		this.UnitAmount = (dealItemRec.Lien_Payout__c != null) ? dealItemRec.Lien_Payout__c.setScale(2, RoundingMode.HALF_UP) : 0;
		this.TaxAmount = 0;
		if(customerInvoiceRecord.AccountingCOInvoiceHeaderRec.InvoiceTotal < 0) {
			this.UnitAmount *= -1;
		}
		this.TaxType = QBUtil.nonTaxableCodeAccId;
	}
	
	private void setStampDutyXeroData(Deal_Item__c dealItemRec, AccountingCustomerInvoice customerInvoiceRecord) {
		this.Description =  'Stamp Duty';
		this.Quantity = 1;
		this.UnitAmount = (dealItemRec.Stamp_Duty_Total__c != null) ? dealItemRec.Stamp_Duty_Total__c.setScale(2, RoundingMode.HALF_UP) : 0;
		if(customerInvoiceRecord.AccountingCOInvoiceHeaderRec.InvoiceTotal < 0) {
			this.UnitAmount *= -1;
		}
		this.TaxAmount = 0;
		this.AccountCode = AccountingUtil.getSystemDefaultCategory('Stamp Duty').size() > 0 ? AccountingUtil.getSystemDefaultCategory('Stamp Duty')[0].Income_GL__c : '';
		this.TaxType = QBUtil.nonTaxableCodeAccId;
	}
	
	private void setDealItemSalesTaxXeroData(String description, Decimal unitAmount, String accountCode) {
		this.Description = description;
		this.Quantity = 1;
		this.UnitAmount = unitAmount;
		this.TaxAmount = 0;
		this.AccountCode = accountCode != null ? accountCode : '';
		this.TaxType = QBUtil.nonTaxableCodeAccId;
	}
	
	private void resetTaxValueWhenTaxCodeSettingIsOff() {
		this.TaxType = 'NONE';
		this.TaxAmount = 0;
	}
}