public without sharing abstract class XeroBaseInvoiceDTO {
    public String SFId;
    public String Type;
    public XeroContactDTO Contact;
    public String InvDate;
    public String DueDate;
    public String Status;
    public String Url;
    public String LineAmountTypes;
    public String InvoiceID;
    public List<XeroLineItemDTO> LineItems; 
    public Decimal Total;
    public String DateString;
    public String DueDateString;
    public List<XeroInvoicePaymentDTO> Payments;
    public String CurrencyCode;
    public Decimal CurrencyRate;
    
    public XeroBaseInvoiceDTO() { 
    	this.Status = 'AUTHORISED';
    }
    
    public XeroBaseInvoiceDTO(AccountingCustomerInvoice customerInvoiceRecord) {
    	this.InvoiceID = customerInvoiceRecord.AccountingCOInvoiceHeaderRec.XeroAccountingId;
    	this.SFId = customerInvoiceRecord.AccountingCOInvoiceHeaderRec.COInvoiceHeaderId;
        this.InvDate = DateTimeUtility.getFormttedDateFromDateTime(customerInvoiceRecord.AccountingCOInvoiceHeaderRec.COInvoiceDate, 'yyyy-MM-dd');
    	if(customerInvoiceRecord.AccountingCOInvoiceHeaderRec.InvoiceTotal < 0) {
    		this.Type = 'ACCRECCREDIT';
            this.DueDate = DateTimeUtility.getFormttedDateFromDateTime(customerInvoiceRecord.AccountingCOInvoiceHeaderRec.COInvoiceDate, 'yyyy-MM-dd');
    	} else {
    		this.Type = 'ACCREC';
            if(customerInvoiceRecord.AccountingCOInvoiceHeaderRec.DueDate != null) {
                this.DueDate = DateTimeUtility.getFormttedDateFromDateTime(DateTime.newInstance(customerInvoiceRecord.AccountingCOInvoiceHeaderRec.DueDate.year(), 
                                customerInvoiceRecord.AccountingCOInvoiceHeaderRec.DueDate.month(), customerInvoiceRecord.AccountingCOInvoiceHeaderRec.DueDate.day()), 'yyyy-MM-dd');
            }
    	}
    	this.LineItems = new List<XeroLineItemDTO>();
    	this.Contact = new XeroContactDTO(customerInvoiceRecord.AccountingCOInvoiceHeaderRec.XeroCustomerAccountingId);
    	this.Status = 'AUTHORISED';
    	this.Url = AccountingUtil.getURL(customerInvoiceRecord.AccountingCOInvoiceHeaderRec.COHeaderId, 'CustomerOrder_V2');
    	
    	for(Object lineItemRec : AccountingCustomerInvoiceService.setAllInvoiceItemRec(customerInvoiceRecord)) {
    		this.LineItems.add( (XeroLineItemDTO) lineItemRec);
    	}
    	if(QBUtil.isQBTaxCodesEnabled) {
            if(GeneralConfiguration.getTaxIncludingPricing()) {
	    		this.LineAmountTypes = 'Inclusive'; 
	    	} else {
	    		this.LineAmountTypes = 'Exclusive';
	    	}
        } else {
            this.LineAmountTypes = 'NoTax';
            // Adding Taxes as line item of Invoice
            for(AccountingCustomerInvoice.TaxDetail taxRec : customerInvoiceRecord.taxDetails) {
                if(taxRec.TaxAmount != null && taxRec.TaxAmount != 0) {
                	XeroLineItemDTO xeroLineItemRec = new XeroLineItemDTO(taxRec);
                	
                	// If invoice total is negative that multiply amount by -1 as CreditNote is created
                	if(customerInvoiceRecord.AccountingCOInvoiceHeaderRec.InvoiceTotal < 0) {
                		xeroLineItemRec.UnitAmount *= -1;
                	}
                    this.LineItems.add(xeroLineItemRec);
                }
            }
        }
    }
    
    
    public XeroBaseInvoiceDTO(AccountingVendorInvoice voInvoice) {
    	this.InvoiceID = voInvoice.AccountingVIHeaderRec.XeroAccountingId;
        this.SFId = voInvoice.AccountingVIHeaderRec.VIHeaderId;
        this.Status = 'AUTHORISED';
        if(voInvoice.AccountingVIHeaderRec.IsForeignVendor) {
            this.CurrencyCode = voInvoice.AccountingVIHeaderRec.CurrencyCode;
            this.CurrencyRate = voInvoice.AccountingVIHeaderRec.BackwardFXConversionRate != null && voInvoice.AccountingVIHeaderRec.BackwardFXConversionRate != 0 ? voInvoice.AccountingVIHeaderRec.BackwardFXConversionRate : 1;
        }
        this.InvDate = DateTimeUtility.getFormttedDateFromDateTime(voInvoice.AccountingVIHeaderRec.InvoicedDateTime, 'yyyy-MM-dd');
        if (voInvoice.AccountingVIHeaderRec.TotalWithTax != null && voInvoice.AccountingVIHeaderRec.TotalWithTax < 0 ){
            this.Type = 'ACCPAYCREDIT';
            this.DueDate = this.InvDate;
        } else  {
            this.Type = 'ACCPAY';
            this.DueDate = DateTimeUtility.getFormttedDateFromDateTime(DateTime.newInstance(voInvoice.AccountingVIHeaderRec.DueDate.year(), 
        	voInvoice.AccountingVIHeaderRec.DueDate.month(), voInvoice.AccountingVIHeaderRec.DueDate.day()), 'yyyy-MM-dd');
        }
        //this.Contact = new Map<String, String>{'ContactID' => voInvoice.vendor.XeroVendorAccountingId};
        this.Contact = new XeroContactDTO(voInvoice.vendor.XeroVendorAccountingId);
        this.Url = AccountingUtil.getURL(voInvoice.AccountingVIHeaderRec.VIHeaderId, 'VendorOrderInvoicing');
        this.LineItems = XeroVendorInvoiceUtility.setAllInvoiceItemRec(voInvoice);
        if(QBUtil.isQBTaxCodesEnabled) {
        	this.LineAmountTypes = 'Exclusive';
        } else {
        	this.LineAmountTypes = 'NoTax';
        	Decimal totalTaxAmount = voInvoice.AccountingVIHeaderRec.TotalPartSubtotal != null ? voInvoice.AccountingVIHeaderRec.TotalPartSubtotal : 0;
        	for(AccountingVendorInvoice.OtherChargesWrapper otherChargesRec : voInvoice.AccountingOtherChargesList) {
            	if(otherChargesRec.IsTaxable) {
            		totalTaxAmount += otherChargesRec.Cost != null ? otherChargesRec.Cost : 0; // Required while sending taxes as line items below
            	}
            }
        	// Adding Taxes as line item of Invoice
            if(!voInvoice.AccountingPurchaseTaxList.isEmpty()) {
                Decimal taxValue = 0;
                for(Integer i = 0; i < voInvoice.AccountingPurchaseTaxList.size(); i++) {
                    AccountingVendorInvoice.AccountingPurchaseTax purchaseTaxRec = voInvoice.AccountingPurchaseTaxList[i];
                    if(i == (voInvoice.AccountingPurchaseTaxList.size() - 1)) {
                        purchaseTaxRec.TaxAmount = voInvoice.AccountingVIHeaderRec.TotalTax - taxValue;
                    } else {
                        purchaseTaxRec.TaxAmount = ((purchaseTaxRec.SalesTaxRate * totalTaxAmount / 100).setScale(2));
                        taxValue += purchaseTaxRec.TaxAmount;
                    }
                    if(purchaseTaxRec.TaxAmount != null && purchaseTaxRec.TaxAmount != 0) {
                        this.LineItems.add(new XeroLineItemDTO(purchaseTaxRec));
                    }
                }
            }
        }

        if (voInvoice.AccountingVIHeaderRec.TotalWithTax != null && voInvoice.AccountingVIHeaderRec.TotalWithTax < 0 ){
            this.Type = 'ACCPAYCREDIT';
            this.DueDate = this.InvDate;
            for(XeroLineItemDTO xeroLineItemRec : LineItems) {
                if (xeroLineItemRec.UnitAmount !=null) {
                    xeroLineItemRec.UnitAmount *= -1;
                }
            }
        } else  {
            this.Type = 'ACCPAY';
            this.DueDate = DateTimeUtility.getFormttedDateFromDateTime(DateTime.newInstance(voInvoice.AccountingVIHeaderRec.DueDate.year(), 
        	voInvoice.AccountingVIHeaderRec.DueDate.month(), voInvoice.AccountingVIHeaderRec.DueDate.day()), 'yyyy-MM-dd');
        }
    }
    
     public XeroBaseInvoiceDTO(AccountingVendorReturn vendorReturn) {
     	this.InvoiceID = vendorReturn.XeroAccountingId;
        this.SFId = vendorReturn.Id;
        if(vendorReturn.Total != null && vendorReturn.Total < 0) {
                this.Type = 'ACCPAY';
                this.DueDate = vendorReturn.DueDate != null ? String.valueOf(vendorReturn.DueDate) : null;
            } else {
                this.Type = 'ACCPAYCREDIT';
                this.DueDate = String.ValueOf(vendorReturn.CreditedDate);
            }
        this.Status = 'AUTHORISED';
        this.Contact = new XeroContactDTO(vendorReturn.XeroVendorAccountingId);
        this.InvDate = String.ValueOf(vendorReturn.CreditedDate);
        
        this.Url = AccountingUtil.getURL(vendorReturn.Id, 'ReturnVO');
        this.LineItems = XeroVendorInvoiceUtility.setAllInvoiceItemRec(vendorReturn);
        if(vendorReturn.IsForeignVendor) {
            this.CurrencyCode = vendorReturn.CurrencyCode;
            this.CurrencyRate = vendorReturn.FXConversionRate != null && vendorReturn.FXConversionRate != 0 ? vendorReturn.FXConversionRate : 1;
        }
        if(QBUtil.isQBTaxCodesEnabled) {
        	this.LineAmountTypes = 'Exclusive';
        } else {
        	this.LineAmountTypes = 'NoTax';
            Decimal totalTaxableAmount = vendorReturn.ItemTotal != null ? vendorReturn.ItemTotal : 0;
        	for(AccountingVendorInvoice.OtherChargesWrapper otherChargesRec : vendorReturn.AccountingOtherChargesList) {
            	if(otherChargesRec.IsTaxable) {
            		totalTaxableAmount += otherChargesRec.Cost != null ? otherChargesRec.Cost : 0; // Required while sending taxes as line items below
            	}
            }
        	// Adding Taxes as line item of Invoice
        	for(AccountingVendorReturn.AccountingPurchaseTax purchaseTaxRec : vendorReturn.AccountingPurchaseTaxList) {
                purchaseTaxRec.TaxAmount = ((purchaseTaxRec.SalesTaxRate * totalTaxableAmount / 100).setScale(2, RoundingMode.HALF_UP));
                if(purchaseTaxRec.TaxAmount != null && purchaseTaxRec.TaxAmount != 0) {
                    if(vendorReturn.Total < 0) {
                        purchaseTaxRec.TaxAmount *= -1;
                    }
                    this.LineItems.add(new XeroLineItemDTO(purchaseTaxRec));
                }
            }
        }
    }
    
    public XeroBaseInvoiceDTO(AccountingUnit unitRec) {
    	setUnitInvoiceDetails(unitRec, false);
    }
    
    public XeroBaseInvoiceDTO(AccountingUnit unitRec, Boolean isConsignment) {
    	setUnitInvoiceDetails(unitRec, isConsignment);
    }
    
    private void setUnitInvoiceDetails(AccountingUnit unitRec, Boolean isConsignment) {
    	this.SFId = unitRec.Id;
        this.Status = 'AUTHORISED';
        this.Url = AccountingUtil.getURL(unitRec.Id, 'ViewUnit');
        this.LineItems = XeroVendorInvoiceUtility.setAllInvoiceItemRec(unitRec, isConsignment);
        if(QBUtil.isQBTaxCodesEnabled) {
        	this.LineAmountTypes = GeneralConfiguration.getTaxIncludingPricing() ? 'Inclusive': 'Exclusive';
        } else {
        	this.LineAmountTypes = 'NoTax';
        }
        if(isConsignment) {
        	this.Type = 'ACCRECCREDIT';
	        this.Contact = new XeroContactDTO(unitRec.XeroCustomerAccId);
	        this.InvDate = DateTimeUtility.getFormttedDateFromDateTime(DateTimeUtility.getDateTimeFromDate(unitRec.UnitInvoiceDate), 'yyyy-MM-dd');
	        this.DueDate = DateTimeUtility.getFormttedDateFromDateTime(DateTimeUtility.getDateTimeFromDate(unitRec.UnitInvoiceDate), 'yyyy-MM-dd');
	        
    	} else {
	        this.InvoiceID = unitRec.XeroAccountingId;
	        this.SFId = unitRec.Id;
            if(unitRec.IsForeignVendor) {
                this.CurrencyCode = unitRec.CurrencyCode;
                this.CurrencyRate = unitRec.FXConversionRate != null && unitRec.FXConversionRate != 0 ? unitRec.FXConversionRate : 1;
            }
	        this.Type = 'ACCPAY';
	        this.Contact = new XeroContactDTO(unitRec.XeroVendorAccountingId);
	        this.InvDate = DateTimeUtility.getFormttedDateFromDateTime(DateTimeUtility.getDateTimeFromDate(unitRec.CreatedDate), 'yyyy-MM-dd');
	        this.DueDate = DateTimeUtility.getFormttedDateFromDateTime(DateTimeUtility.getDateTimeFromDate(unitRec.DueDate), 'yyyy-MM-dd');
	        
	        if(!QBUtil.isQBTaxCodesEnabled) {
	        	// Adding Taxes as line item of Invoice
	        	if(unitRec.AccountingPurchaseTaxList.size() > 0) {
	        		Decimal taxValue = 0;
		            AccountingUnit.AccountingPurchaseTax purchaseTax;
			        for(Integer i = 0; i < unitRec.AccountingPurchaseTaxList.size() - 1; i++) {
		                purchaseTax = unitRec.AccountingPurchaseTaxList[i];
		                purchaseTax.TaxAmount = (purchaseTax.SalesTaxRate * unitRec.TotalCost/100);
		                taxValue += purchaseTax.TaxAmount;
		                if(purchaseTax.TaxAmount != null && purchaseTax.TaxAmount != 0) {
		                	this.LineItems.add(new XeroLineItemDTO(purchaseTax));
		                }
		            }
		            purchaseTax = unitRec.AccountingPurchaseTaxList[unitRec.AccountingPurchaseTaxList.size() - 1];
		            purchaseTax.TaxAmount = unitRec.TotalPurchaseTax - taxValue;
		            if(purchaseTax.TaxAmount != null && purchaseTax.TaxAmount != 0) {
		            	this.LineItems.add(new XeroLineItemDTO(purchaseTax));
		            }
	        	}
	        }
    	}
    }
    
    public XeroBaseInvoiceDTO(AccountingUnitPriceAndCost unitPriceAndCostRecord) {
    	this.InvoiceID = unitPriceAndCostRecord.XeroAccountingId;
        this.SFId = unitPriceAndCostRecord.Id;
        if(unitPriceAndCostRecord.VendorId != null) {
            if(unitPriceAndCostRecord.TotalCost != null && unitPriceAndCostRecord.TotalCost < 0) {
                this.Type = 'ACCPAYCREDIT';
            } else {
                this.Type = 'ACCPAY';
            }
            this.Contact = new XeroContactDTO(unitPriceAndCostRecord.VendorAccountingId);
            if(unitPriceAndCostRecord.IsForeignVendor != null && unitPriceAndCostRecord.IsForeignVendor) {
                this.CurrencyCode = unitPriceAndCostRecord.CurrencyCode;
                this.CurrencyRate = unitPriceAndCostRecord.FXConversionRate != null && unitPriceAndCostRecord.FXConversionRate != 0 ? unitPriceAndCostRecord.FXConversionRate : 1;
            }
        } else if(unitPriceAndCostRecord.CustomerId != null) {
            if(unitPriceAndCostRecord.TotalCost != null && unitPriceAndCostRecord.TotalCost < 0) {
                this.Type = 'ACCREC';
            } else {
                this.Type = 'ACCRECCREDIT';
            }
            this.Contact = new XeroContactDTO(unitPriceAndCostRecord.CustomerAccountingId);
            
        }
        this.Status = 'AUTHORISED';
        this.LineAmountTypes = 'Exclusive';
        
        
        this.InvDate = String.valueOf(unitPriceAndCostRecord.AdjustmentDate);
        this.DueDate = unitPriceAndCostRecord.DueDate != null ? String.valueOf(unitPriceAndCostRecord.DueDate) : null;
		
        this.Url = AccountingUtil.getURL(unitPriceAndCostRecord.CustomerOwnedUnitID, 'ViewUnit');
        this.LineItems = XeroVendorInvoiceUtility.setAllInvoiceItemRec(unitPriceAndCostRecord);

        if(QBUtil.isQBTaxCodesEnabled) {
            this.LineAmountTypes = 'Exclusive';
        } else {
            this.LineAmountTypes = 'NoTax';
            for(AccountingUnitPriceAndCost.TaxDetail taxRec : unitPriceAndCostRecord.taxDetailList) {
                if(taxRec.TaxAmount != null && taxRec.TaxAmount != 0) {
                	XeroLineItemDTO xeroLineItemRec = new XeroLineItemDTO(taxRec);
                    this.LineItems.add(xeroLineItemRec);
                }
            }
        }    
    }

    public XeroBaseInvoiceDTO(CO_Invoice_Payment__c coInvPaymentRec) {
    	this.SFId = coInvPaymentRec.Id;
    	this.Type = 'ACCREC';
    	this.Contact = new XeroContactDTO(coInvPaymentRec.CO_Invoice_Header__r.CO_Header__r.Customer__r.Xero_Customer_Accounting_Id__c);
    	this.Status = 'AUTHORISED';
    	this.Url = AccountingUtil.getURL(coInvPaymentRec.CO_Invoice_Header__r.CO_Header__c, 'CustomerOrder_V2');
    	
    	this.InvDate = DateTimeUtility.getFormttedDateFromDateTime(DateTimeUtility.getDateTimeFromDate(coInvPaymentRec.Payment_Date__c), 'yyyy-MM-dd');
    	this.DueDate = DateTimeUtility.getFormttedDateFromDateTime(DateTimeUtility.getDateTimeFromDate(coInvPaymentRec.Payment_Date__c), 'yyyy-MM-dd');
        this.LineItems = new List<XeroLineItemDTO>();
    	this.LineItems.add( new XeroLineItemDTO(coInvPaymentRec));
        this.LineAmountTypes = 'NoTax';
    }
}