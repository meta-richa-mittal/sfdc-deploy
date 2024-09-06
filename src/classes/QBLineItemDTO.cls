/**
 * Author: Manoj Sharma
 * Since: Aug 20, 2022
 * Name: QBLineItemDTO
 * Description: Apex class to create line item for the QB request.
**/
public without sharing class QBLineItemDTO {
    public String Description;
    public Decimal Amount;
    public String DetailType;
    public SaleItemLineDetailWrapper SalesItemLineDetail;
    public AccountBasedExpenseLineDetailWrapper AccountBasedExpenseLineDetail;

    public QBLineItemDTO(CO_Line_Item__c coliRec, AccountingCustomerInvoice customerInvoiceRecord) {
        String itemCategoryAccountingId, itemCategoryName, taxCodeAccountingId;
        if(coliRec.Part__c != null) {
            itemCategoryAccountingId = (coliRec.CO_Header__r.Transaction_Type__r.Part_Category__c != null && !String.isBlank(coliRec.CO_Header__r.Transaction_Type__r.Part_Category__r.AccountingId__c)) ? coliRec.CO_Header__r.Transaction_Type__r.Part_Category__r.AccountingId__c : coliRec.Part__r.Category__r.AccountingId__c;
            itemCategoryName = (coliRec.CO_Header__r.Transaction_Type__r.Part_Category__c != null && !String.isBlank(coliRec.CO_Header__r.Transaction_Type__r.Part_Category__r.Name)) ? coliRec.CO_Header__r.Transaction_Type__r.Part_Category__r.Name : coliRec.Part__r.Category__r.Name;
        } else if(coliRec.Fee__c != null) {
            itemCategoryAccountingId = coliRec.Fee__r.Category__r.AccountingId__c;
            itemCategoryName = coliRec.Fee__r.Category__r.Name;
        }
        
        Decimal price = 0;
        if(customerInvoiceRecord.EntityIdToTotalSalesTaxValueMap.containsKey(coliRec.Id)) {
            price = ((coliRec.Price_When_Tax_Included__c != null ? coliRec.Price_When_Tax_Included__c : 0) - (customerInvoiceRecord.EntityIdToTotalSalesTaxValueMap.get(coLIRec.Id))).setScale(2, RoundingMode.HALF_UP);
        } else {
            price = (coliRec.Price__c != null ? coliRec.Price__c : 0).setScale(2, RoundingMode.HALF_UP);
        }
        this.Amount = ((coliRec.Qty__c != null ? coliRec.Qty__c : 0) * price).setScale(2, RoundingMode.HALF_UP);
        if(customerInvoiceRecord.SyncingObjectType == IntegrationUtility.REFUND_RECEIPT || customerInvoiceRecord.SyncingObjectType == IntegrationUtility.CREDIT_MEMO) {
            this.Amount *= -1;
        }
        this.DetailType = 'SalesItemLineDetail';    
        this.Description = (coliRec.Item_Code__c != null) ? coliRec.Item_Code__c + '-' : '';
        this.Description += (coliRec.Item_Description__c != null) ? coliRec.Item_Description__c : '';
        
        taxCodeAccountingId = coliRec.Applicable_Tax__c != null ? coliRec.Applicable_Tax__r.Accounting_Id__c : QBUtil.nonTaxableCodeAccId;

        if(coliRec.Applicable_Tax__c != null) {
            customerInvoiceRecord.applicableSalesTaxIdSet.add(coliRec.Applicable_Tax__c);
        } else {
            customerInvoiceRecord.isNonTaxableLIExists = true;
        }
        this.SalesItemLineDetail = new SaleItemLineDetailWrapper(customerInvoiceRecord.SyncingObjectType, price, coliRec.Qty__c, itemCategoryAccountingId, itemCategoryName, taxCodeAccountingId);  
    }
    
    public QBLineItemDTO(Service_Order_Header__c soHeaderRec, Service_Order_Line_Item__c soliRec, AccountingCustomerInvoice customerInvoiceRecord) {
        String itemCategoryAccountingId, itemCategoryName, taxCodeAccountingId;
        if(soLIRec.Part__c != null) {
            itemCategoryAccountingId = !String.isBlank(soHeaderRec.Transaction_Type__r.Part_Category__r.AccountingId__c) ? soHeaderRec.Transaction_Type__r.Part_Category__r.AccountingId__c : soLIRec.Part__r.Category__r.AccountingId__c;
            itemCategoryName = !String.isBlank(soHeaderRec.Transaction_Type__r.Part_Category__r.Name) ? soHeaderRec.Transaction_Type__r.Part_Category__r.Name : soLIRec.Part__r.Category__r.Name;
        } else if(soLIRec.Fee__c != null) {
            itemCategoryAccountingId = soLIRec.Fee__r.Category__r.AccountingId__c;
            itemCategoryName = soLIRec.Fee__r.Category__r.Name;
        } else if(soLIRec.Labour_Code__c != null) {
            itemCategoryAccountingId = !String.isBlank(soHeaderRec.Transaction_Type__r.Labour_Category__r.AccountingId__c) ? soHeaderRec.Transaction_Type__r.Labour_Category__r.AccountingId__c : soLIRec.Labour_Code__r.Category__r.AccountingId__c;
            itemCategoryName = !String.isBlank(soHeaderRec.Transaction_Type__r.Labour_Category__r.Name) ? soHeaderRec.Transaction_Type__r.Labour_Category__r.Name : soLIRec.Labour_Code__r.Category__r.Name;
        } else if(soLIRec.Sublet__c != null) {
            itemCategoryAccountingId = soLIRec.Sublet__r.Category__r.AccountingId__c;
            itemCategoryName = soLIRec.Sublet__r.Category__r.Name;
        }
        Decimal qty = (soLIRec.Qty_Needed__c != null ? soLIRec.Qty_Needed__c : 0);
        if(customerInvoiceRecord.EntityIdToTotalSalesTaxValueMap.containsKey(soLIRec.Id)) {
            Decimal totalPriceWithTax = ((soLIRec.Price_When_Tax_Included__c != null ? soLIRec.Price_When_Tax_Included__c : 0)*qty).setScale(2, RoundingMode.HALF_UP);
            Decimal totalTax = ((customerInvoiceRecord.EntityIdToTotalSalesTaxValueMap.get(soLIRec.Id))*qty).setScale(2, RoundingMode.HALF_UP);
            this.Amount = (totalPriceWithTax - totalTax).setScale(2, RoundingMode.HALF_UP);
        } else {
            this.Amount = (soLIRec.Kit_Price__c != null ? ((soLIRec.Kit_Price__c.setScale(2, RoundingMode.HALF_UP))*qty).setScale(2, RoundingMode.HALF_UP) : 0);
        }
        this.DetailType = 'SalesItemLineDetail';    
        this.Description = (soLIRec.Item_Code__c != null) ? soLIRec.Item_Code__c : '';
        this.Description += (soLIRec.Item_Description__c != null) ? ' - ' + soLIRec.Item_Description__c : '';
        taxCodeAccountingId = soLIRec.Applicable_Tax__c != null ? soLIRec.Applicable_Tax__r.Accounting_Id__c : QBUtil.nonTaxableCodeAccId;
        if(soLIRec.Applicable_Tax__c != null) {
            customerInvoiceRecord.applicableSalesTaxIdSet.add(soLIRec.Applicable_Tax__c);
        } else {
            customerInvoiceRecord.isNonTaxableLIExists = true;
        }

        this.SalesItemLineDetail = new SaleItemLineDetailWrapper(customerInvoiceRecord.SyncingObjectType, this.Amount, 1, itemCategoryAccountingId, itemCategoryName, taxCodeAccountingId);  
        if(customerInvoiceRecord.SyncingObjectType == IntegrationUtility.REFUND_RECEIPT || customerInvoiceRecord.SyncingObjectType == IntegrationUtility.CREDIT_MEMO) {
            this.Amount *= -1;
        }
    }
   
    public QBLineItemDTO(Deal_Item__c dealItemRec, Deal_Unit_Price_Cost__c dealUnitPriceandCost, AccountingCustomerInvoice customerInvoiceRecord, Map<String, Category__c> categoryTypeToRecMap) {
        String itemCategoryAccountingId, itemCategoryName, taxCodeAccountingId;
        this.Description = dealUnitPriceandCost.Type__c == 'Base' ? QBUtil.getDealUnitName(dealItemRec) : dealUnitPriceandCost.Item_Description__c;
        this.DetailType = 'SalesItemLineDetail';    
        itemCategoryAccountingId = dealItemRec.Customer_Owned_Unit__r.Category__r.AccountingId__c != null ? dealItemRec.Customer_Owned_Unit__r.Category__r.AccountingId__c : categoryTypeToRecMap.get('Unit').AccountingId__c;
        itemCategoryName = dealItemRec.Customer_Owned_Unit__r.Category__r.Name != null ? dealItemRec.Customer_Owned_Unit__r.Category__r.Name : categoryTypeToRecMap.get('Unit').Name;
        taxCodeAccountingId = dealUnitPriceandCost.Applicable_Tax__c != null ? dealUnitPriceandCost.Applicable_Tax__r.Accounting_Id__c : QBUtil.nonTaxableCodeAccId;

        Decimal price = 0;
        if(customerInvoiceRecord.EntityIdToTotalSalesTaxValueMap.containsKey(dealUnitPriceandCost.Id)) {
            price = (dealUnitPriceandCost.Price_When_Tax_Included__c != null ? dealUnitPriceandCost.Price_When_Tax_Included__c : 0) - (customerInvoiceRecord.EntityIdToTotalSalesTaxValueMap.get(dealUnitPriceandCost.Id));
        } else {
            price = (dealUnitPriceandCost.Price__c != null ? dealUnitPriceandCost.Price__c : 0);
        }
        price = price.setScale(2, RoundingMode.HALF_UP);
        this.Amount = ((dealUnitPriceandCost.Qty__c != null ? dealUnitPriceandCost.Qty__c : 0) * price).setScale(2, RoundingMode.HALF_UP);
        if(customerInvoiceRecord.SyncingObjectType == IntegrationUtility.REFUND_RECEIPT || customerInvoiceRecord.SyncingObjectType == IntegrationUtility.CREDIT_MEMO) {
            this.Amount *= -1;
        }
        if(dealUnitPriceandCost.Applicable_Tax__c != null) {
            customerInvoiceRecord.applicableSalesTaxIdSet.add(dealUnitPriceandCost.Applicable_Tax__c);
        } else {
            customerInvoiceRecord.isNonTaxableLIExists = true;
        }
        this.SalesItemLineDetail = new SaleItemLineDetailWrapper(customerInvoiceRecord.SyncingObjectType, price, dealUnitPriceandCost.Qty__c, itemCategoryAccountingId, itemCategoryName, taxCodeAccountingId);  
    }
    
    public QBLineItemDTO(Deal_Item__c dealItemRec, Option_Fee__c optionAndFee, AccountingCustomerInvoice customerInvoiceRecord, Map<String, Category__c> categoryTypeToRecMap) {
        String itemCategoryAccountingId, itemCategoryName, taxCodeAccountingId;
        if(optionAndFee.Part__c != null) {
            itemCategoryAccountingId = dealItemRec.Customer_Owned_Unit__r.Category__r.AccountingId__c != null ? dealItemRec.Customer_Owned_Unit__r.Category__r.AccountingId__c : categoryTypeToRecMap.get('Unit').AccountingId__c;
            itemCategoryName = dealItemRec.Customer_Owned_Unit__r.Category__r.Name != null ? dealItemRec.Customer_Owned_Unit__r.Category__r.Name : categoryTypeToRecMap.get('Unit').Name;
        } else if(optionAndFee.Fee__c != null) {
            if(optionAndFee.CO_Line_Item__c != null || optionAndFee.Service_Order_Line_Item__c != null) {
                itemCategoryAccountingId = dealItemRec.Customer_Owned_Unit__r.Category__r.AccountingId__c != null ? dealItemRec.Customer_Owned_Unit__r.Category__r.AccountingId__c : categoryTypeToRecMap.get('Unit').AccountingId__c;
                itemCategoryName = dealItemRec.Customer_Owned_Unit__r.Category__r.Name != null ? dealItemRec.Customer_Owned_Unit__r.Category__r.Name : categoryTypeToRecMap.get('Unit').Name;
            } else {
                itemCategoryAccountingId = optionAndFee.Fee__r.Category__r.AccountingId__c;
                itemCategoryName = optionAndFee.Fee__r.Category__r.Name;
            }
        } else if(optionAndFee.Labour_Code__c != null) {
            itemCategoryAccountingId = dealItemRec.Customer_Owned_Unit__r.Category__r.AccountingId__c != null ? dealItemRec.Customer_Owned_Unit__r.Category__r.AccountingId__c : categoryTypeToRecMap.get('Unit').AccountingId__c;
            itemCategoryName = dealItemRec.Customer_Owned_Unit__r.Category__r.Name != null ? dealItemRec.Customer_Owned_Unit__r.Category__r.Name : categoryTypeToRecMap.get('Unit').Name;
        } else if(optionAndFee.Product__c != null) {
            if(optionAndFee.Product__r.Type__c == Constants.SUBLET) {
            itemCategoryAccountingId = dealItemRec.Customer_Owned_Unit__r.Category__r.AccountingId__c != null ? dealItemRec.Customer_Owned_Unit__r.Category__r.AccountingId__c : categoryTypeToRecMap.get('Unit').AccountingId__c;
              itemCategoryName = dealItemRec.Customer_Owned_Unit__r.Category__r.Name != null ? dealItemRec.Customer_Owned_Unit__r.Category__r.Name : categoryTypeToRecMap.get('Unit').Name;
            } else {
                itemCategoryAccountingId = optionAndFee.Product__r.Category__r.AccountingId__c != null ? optionAndFee.Product__r.Category__r.AccountingId__c : categoryTypeToRecMap.get('Unit').AccountingId__c;
                itemCategoryName = optionAndFee.Product__r.Category__r.Name != null ? optionAndFee.Product__r.Category__r.Name : categoryTypeToRecMap.get('Unit').Name;
            }
        }
        taxCodeAccountingId = optionAndFee.Applicable_Tax__c != null ? optionAndFee.Applicable_Tax__r.Accounting_Id__c : QBUtil.nonTaxableCodeAccId;
        Decimal price = 0;
        optionAndFee.Qty__c = (optionAndFee.Qty__c != null ? (optionAndFee.Qty__c).setScale(2, RoundingMode.HALF_UP) : 0);
        if(customerInvoiceRecord.EntityIdToTotalSalesTaxValueMap.containsKey(optionAndFee.Id)) {
            price = (optionAndFee.Price_When_Tax_Included__c != null ? optionAndFee.Price_When_Tax_Included__c : 0) - (customerInvoiceRecord.EntityIdToTotalSalesTaxValueMap.get(optionAndFee.Id));
        } else {
            price = (optionAndFee.Price__c != null ? optionAndFee.Price__c : 0);
        }
        price = price.setScale(2, RoundingMode.HALF_UP);
        this.Amount = ((optionAndFee.Qty__c != null ? optionAndFee.Qty__c : 0) * price).setScale(2, RoundingMode.HALF_UP);
        this.Description =  (optionAndFee.Item_Code__c != null) ? optionAndFee.Item_Code__c : '';
        this.Description +=  ((optionAndFee.Item_Description__c != null) ? ' - ' + optionAndFee.Item_Description__c   : '') + ';';
        this.DetailType = 'SalesItemLineDetail';    
        if(customerInvoiceRecord.SyncingObjectType == IntegrationUtility.REFUND_RECEIPT || customerInvoiceRecord.SyncingObjectType == IntegrationUtility.CREDIT_MEMO) {
            this.Amount *= -1;
        }
        if(optionAndFee.Applicable_Tax__c != null) {
            customerInvoiceRecord.applicableSalesTaxIdSet.add(optionAndFee.Applicable_Tax__c);
        } else {
            customerInvoiceRecord.isNonTaxableLIExists = true;
        }
        this.SalesItemLineDetail = new SaleItemLineDetailWrapper(customerInvoiceRecord.SyncingObjectType, price, optionAndFee.Qty__c, itemCategoryAccountingId, itemCategoryName, taxCodeAccountingId);     
    }
    
    public QBLineItemDTO(Deal_Item__c dealItemRec, AccountingCustomerInvoice customerInvoiceRecord, String recordType) {
        if(recordType == 'Trade In') {
            setTradeInQBData(dealItemRec, customerInvoiceRecord);
        } else if(recordType == 'Lien Payout') {
            setLienPayoutQBData(dealItemRec, customerInvoiceRecord);
        } else if(recordType == 'Stamp Duty') {
            setStampDutyQBData(dealItemRec, customerInvoiceRecord);
        }
    }

    public QBLineItemDTO(F_I_Product__c FIProduct, AccountingCustomerInvoice customerInvoiceRecord, Map<String, Category__c> categoryTypeToRecMap) {
        String itemCategoryAccountingId, itemCategoryName, taxCodeAccountingId;
        itemCategoryAccountingId = FIProduct.Vendor_Product__r.Category__r.AccountingId__c != null ? FIProduct.Vendor_Product__r.Category__r.AccountingId__c : categoryTypeToRecMap.get('Unit').AccountingId__c;
        itemCategoryName = FIProduct.Vendor_Product__r.Category__r.Name != null ? FIProduct.Vendor_Product__r.Category__r.Name : categoryTypeToRecMap.get('Unit').Name;
        taxCodeAccountingId = FIProduct.Applicable_Tax__c != null ? FIProduct.Applicable_Tax__r.Accounting_Id__c : QBUtil.nonTaxableCodeAccId;

        this.Description = 'Financing: ' + FIProduct.Item_Description__c;
        this.DetailType = 'SalesItemLineDetail';    

        if(customerInvoiceRecord.EntityIdToTotalSalesTaxValueMap.containsKey(FIProduct.Id)) {
            this.Amount = ((FIProduct.Price_When_Tax_Included__c != null ? FIProduct.Price_When_Tax_Included__c : 0) - (customerInvoiceRecord.EntityIdToTotalSalesTaxValueMap.get(FIProduct.Id))).setScale(2, RoundingMode.HALF_UP);
        } else {
            this.Amount = (FIProduct.Price__c != null ? FIProduct.Price__c : 0).setScale(2, RoundingMode.HALF_UP);
        }
        if(FIProduct.Applicable_Tax__c != null) {
            customerInvoiceRecord.applicableSalesTaxIdSet.add(FIProduct.Applicable_Tax__c);
        } else {
            customerInvoiceRecord.isNonTaxableLIExists = true;
        }
        this.SalesItemLineDetail = new SaleItemLineDetailWrapper(customerInvoiceRecord.SyncingObjectType, this.Amount, 1, itemCategoryAccountingId, itemCategoryName, taxCodeAccountingId);  
        if(customerInvoiceRecord.SyncingObjectType == IntegrationUtility.REFUND_RECEIPT || customerInvoiceRecord.SyncingObjectType == IntegrationUtility.CREDIT_MEMO) {
            this.Amount *= -1;
        }
    }

    public QBLineItemDTO(String syncingObjectType, String description, Decimal amount, Decimal unitPrice, Decimal qty, String itemCategoryAccountingId, String itemCategoryName, String taxCodeAccountingId) {
        this.Description = description;
        this.Amount = amount;
        if(syncingObjectType == IntegrationUtility.REFUND_RECEIPT || syncingObjectType == IntegrationUtility.CREDIT_MEMO) {
            this.Amount *= -1;
        }
        this.DetailType = 'SalesItemLineDetail';   
        this.SalesItemLineDetail = new SaleItemLineDetailWrapper(syncingObjectType, unitPrice, qty, itemCategoryAccountingId, itemCategoryName, taxCodeAccountingId);  
    }

    public QBLineItemDTO(AccountingUnitPriceAndCost adjstmentRec) {
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

    public QBLineItemDTO(AccountingUnit consUnitRecord) {
        this.Description = 'Consignment payout:' + (String.isNotBlank(consUnitRecord.VIN) ? (' ' + consUnitRecord.VIN) : '');
        this.Amount = consUnitRecord.AgreedPayout;
        this.DetailType = 'SalesItemLineDetail';
        this.SalesItemLineDetail = new SaleItemLineDetailWrapper(consUnitRecord);   
    }

    public QBLineItemDTO(AccountingVendorReturn.ReturnCRLineItemWrapper RCRLIRec, AccountingVendorReturn.AccountRefWrapper AccountRef, String taxCodeAccountingId) { 
        this.Description = RCRLIRec.ItemDescription + ' ' + RCRLIRec.ReturnQty + '@$' + RCRLIRec.ItemCost;
        this.Amount = RCRLIRec.ReturnQty * RCRLIRec.ItemCost;
        this.DetailType = 'AccountBasedExpenseLineDetail';
        this.AccountBasedExpenseLineDetail = new AccountBasedExpenseLineDetailWrapper(AccountRef, taxCodeAccountingId); 
    }

    public QBLineItemDTO(AccountingUnitPriceAndCost.TaxDetail taxDetail) {
        this.Description = taxDetail.Name; 
        this.Amount = taxDetail.TaxAmount;
        if(this.Amount < 0) {
            this.Amount *= -1;
        }
        this.DetailType = 'SalesItemLineDetail';        
        this.SalesItemLineDetail = new SaleItemLineDetailWrapper(taxDetail);   
    }

    public QBLineItemDTO(AccountingCustomerInvoice.TaxDetail taxDetail) {
        this.Description = taxDetail.Name; 
        this.Amount = taxDetail.TaxAmount;
        this.DetailType = 'SalesItemLineDetail';        
        this.SalesItemLineDetail = new SaleItemLineDetailWrapper(taxDetail);   
    }

    public QBLineItemDTO(CO_Invoice_Payment__c coInvPaymentRec, String categoryAccId) {
        this.Description = QBBaseInvoiceDTO.getPrivateNoteString(coInvPaymentRec, coInvPaymentRec.AR_Credit_Number__c) + coInvPaymentRec.CO_Invoice_Header__r.CO_Header__r.Name;
        this.Amount = coInvPaymentRec.Amount__c != null ? coInvPaymentRec.Amount__c : 0;
        this.DetailType = 'SalesItemLineDetail';        
        this.SalesItemLineDetail = new SaleItemLineDetailWrapper(coInvPaymentRec, categoryAccId);   
    }

    public QBLineItemDTO(CO_Deposit__c coDepositRec, String categoryAccId) {
        this.Description = QBBaseInvoiceDTO.getPrivateNoteString(coDepositRec, coDepositRec.AR_Credit_Number__c) + coDepositRec.CO_Header__r.Name;
        this.Amount = coDepositRec.Amount__c != null ? coDepositRec.Amount__c : 0;
        this.DetailType = 'SalesItemLineDetail';        
        this.SalesItemLineDetail = new SaleItemLineDetailWrapper(coDepositRec, categoryAccId);   
    }

    public QBLineItemDTO(String Description, Decimal Amount, AccountingVendorReturn.AccountRefWrapper AccountRef, String taxCodeAccountingId) {
        this.Description = Description;
        this.Amount = Amount;
        this.DetailType = 'AccountBasedExpenseLineDetail';
        this.AccountBasedExpenseLineDetail = new AccountBasedExpenseLineDetailWrapper(AccountRef, taxCodeAccountingId);   
    }
     
     public QBLineItemDTO(String Description, Decimal Amount, String CategoryAccountRef, String taxCodeAccountingId) {
        this.Description = Description; 
        this.Amount = Amount;
        this.DetailType = 'AccountBasedExpenseLineDetail';
        this.AccountBasedExpenseLineDetail = new AccountBasedExpenseLineDetailWrapper(CategoryAccountRef, taxCodeAccountingId);   
    }
     
    public QBLineItemDTO(String Description, Decimal Amount, String CategoryAccountRef) {
        this.Description = Description; 
        this.Amount = Amount;
        this.DetailType = 'AccountBasedExpenseLineDetail';
        this.AccountBasedExpenseLineDetail = new AccountBasedExpenseLineDetailWrapper(CategoryAccountRef);   
    }

    private void setTradeInQBData(Deal_Item__c dealItemRec, AccountingCustomerInvoice customerInvoiceRecord) {
        Map<String, Category__c> categoryTypeToRecMap = getCategoryTypeToRecMap();
        String itemCategoryAccountingId, itemCategoryName, taxCodeAccountingId;
        this.Description = 'Trade-in: ';
        this.Description += String.isNotBlank(QBUtil.getDealUnitName(dealItemRec)) ? '-' : '';
        this.Description += QBUtil.getDealUnitName(dealItemRec);
        this.Amount = dealItemRec.Pre_Tax_Agreed_Value__c != null ? dealItemRec.Pre_Tax_Agreed_Value__c.setScale(2, RoundingMode.HALF_UP) * -1 : 0;
        
        itemCategoryAccountingId = AccountingUtil.getSystemDefaultCategory('Stocked Trade').size() > 0 ? AccountingUtil.getSystemDefaultCategory('Stocked Trade')[0].AccountingId__c  : '';
        itemCategoryName = AccountingUtil.getSystemDefaultCategory('Stocked Trade').size() > 0 ? AccountingUtil.getSystemDefaultCategory('Stocked Trade')[0].Name : '';

        if(dealItemRec.Applicable_Tax__c != null) {
            taxCodeAccountingId = dealItemRec.Applicable_Tax__r.Accounting_Id__c;
            customerInvoiceRecord.applicableSalesTaxIdSet.add(dealItemRec.Applicable_Tax__c);
        } else {
            taxCodeAccountingId = QBUtil.nonTaxableCodeAccId;
            customerInvoiceRecord.isNonTaxableLIExists = true;
        }
        this.DetailType = 'SalesItemLineDetail';    
        this.SalesItemLineDetail = new SaleItemLineDetailWrapper(customerInvoiceRecord.SyncingObjectType, this.Amount, 1, itemCategoryAccountingId, itemCategoryName, taxCodeAccountingId);     
        if(customerInvoiceRecord.SyncingObjectType == IntegrationUtility.REFUND_RECEIPT || customerInvoiceRecord.SyncingObjectType == IntegrationUtility.CREDIT_MEMO) {
            this.Amount *= -1;
        }
    }

    private void setLienPayoutQBData(Deal_Item__c dealItemRec, AccountingCustomerInvoice customerInvoiceRecord) {
        Map<String, Category__c> categoryTypeToRecMap = getCategoryTypeToRecMap();
        String itemCategoryAccountingId, itemCategoryName, taxCodeAccountingId;
        this.Description = 'Lien payout:' + (!String.isBlank(dealItemRec.Customer_Owned_Unit__r.VIN_Number__c) ? (' ' + dealItemRec.Customer_Owned_Unit__r.VIN_Number__c) : '') 
                           +  (!String.isBlank(dealItemRec.Finance_Company__r.Name) ? (' ' + dealItemRec.Finance_Company__r.Name) : '');
        this.Amount = (dealItemRec.Lien_Payout__c != null) ? dealItemRec.Lien_Payout__c.setScale(2, RoundingMode.HALF_UP) : 0;
        this.DetailType = 'SalesItemLineDetail';    
        itemCategoryAccountingId = categoryTypeToRecMap.get('Lien Payout').AccountingId__c;
        itemCategoryName = categoryTypeToRecMap.get('Lien Payout').Name;
        taxCodeAccountingId = QBUtil.nonTaxableCodeAccId;
        customerInvoiceRecord.isNonTaxableLIExists = true;
        this.SalesItemLineDetail = new SaleItemLineDetailWrapper(customerInvoiceRecord.SyncingObjectType, this.Amount, 1, itemCategoryAccountingId, itemCategoryName, taxCodeAccountingId);    
        if(customerInvoiceRecord.SyncingObjectType == IntegrationUtility.REFUND_RECEIPT || customerInvoiceRecord.SyncingObjectType == IntegrationUtility.CREDIT_MEMO) {
            this.Amount *= -1;
        } 
    }
    
    private void setStampDutyQBData(Deal_Item__c dealItemRec, AccountingCustomerInvoice customerInvoiceRecord) {
        String itemCategoryAccountingId, itemCategoryName, taxCodeAccountingId;
        this.Description =  'Stamp Duty';
        this.Amount = (dealItemRec.Stamp_Duty_Total__c != null) ? dealItemRec.Stamp_Duty_Total__c.setScale(2, RoundingMode.HALF_UP) : 0;
        this.DetailType = 'SalesItemLineDetail';    
        
        List<Category__c> stampDutyCategory = AccountingUtil.getSystemDefaultCategory('Stamp Duty');
        if(stampDutyCategory.size() > 0) {
            itemCategoryAccountingId = stampDutyCategory[0].AccountingId__c;
            itemCategoryName = stampDutyCategory[0].Name;
        }
        taxCodeAccountingId = QBUtil.nonTaxableCodeAccId;
        customerInvoiceRecord.isNonTaxableLIExists = true;
        this.SalesItemLineDetail = new SaleItemLineDetailWrapper(customerInvoiceRecord.SyncingObjectType, this.Amount, 1, itemCategoryAccountingId, itemCategoryName, taxCodeAccountingId);     
        if(customerInvoiceRecord.SyncingObjectType == IntegrationUtility.REFUND_RECEIPT || customerInvoiceRecord.SyncingObjectType == IntegrationUtility.CREDIT_MEMO) {
            this.Amount *= -1;
        }
    }

    public static Map<String, Category__c> getCategoryTypeToRecMap() {
        Set<String> defaultCategoryTypeSet = new Set<String>{'Unit', 'Trade-in', 'Stocked Trade', 'Tax', 'Lien Payout'};
        Map<String, Category__c> categoryTypeToRecMap = new Map<String, Category__c>();
        List<Category__c> systemDefaultCategoryList = [SELECT AccountingId__c, Name, Type__c FROM Category__c WHERE Type__c IN :defaultCategoryTypeSet AND Default__c = true AND Active__c = true];
        for(Category__c categoryRec: systemDefaultCategoryList) {
            categoryTypeToRecMap.put(categoryRec.Type__c, categoryRec);
        }
        return categoryTypeToRecMap;
    }


    public class SaleItemLineDetailWrapper {
        public Decimal UnitPrice;
        public Decimal Qty;
        public QBInnerEntityWrapper ItemRef;
        public QBInnerEntityWrapper TaxCodeRef;

        public SaleItemLineDetailWrapper(String syncingObjectType, Decimal unitPrice, Decimal qty, String itemCategoryAccountingId, String itemCategoryName, String taxCodeAccountingId) {
            this.UnitPrice = unitPrice;
            this.Qty = qty;
            if(syncingObjectType == IntegrationUtility.REFUND_RECEIPT || syncingObjectType == IntegrationUtility.CREDIT_MEMO) {
                this.Qty *= -1;
            }
            if(itemCategoryAccountingId != null){
                this.ItemRef = new QBInnerEntityWrapper(itemCategoryAccountingId, itemCategoryName);
            }
            if(QBUtil.isQBTaxCodesEnabled) {
                this.TaxCodeRef = new QBInnerEntityWrapper(taxCodeAccountingId, '');
            }
        }

        public SaleItemLineDetailWrapper(AccountingUnitPriceAndCost adjstmentRec) {
            this.UnitPrice = adjstmentRec.TotalCost;
            if(this.UnitPrice < 0) {
                this.UnitPrice *= -1;
            }
        	this.Qty = 1;
            if(adjstmentRec.CategoryAccId != null) {
                this.ItemRef = new QBInnerEntityWrapper(adjstmentRec.CategoryAccId, null);
            }
            if(QBUtil.isQBTaxCodesEnabled) {
                String taxCodeAccountingId = adjstmentRec.ApplicableTaxAccId != null ? adjstmentRec.ApplicableTaxAccId : QBUtil.nonTaxableCodeAccId;
                this.TaxCodeRef = new QBInnerEntityWrapper(taxCodeAccountingId, '');
            }
        }

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

        public SaleItemLineDetailWrapper(AccountingUnitPriceAndCost.TaxDetail taxDetail) {
            if(taxDetail.AccountingId != null) {
                this.ItemRef = new QBInnerEntityWrapper(taxDetail.AccountingId, null);
            }
        }

        public SaleItemLineDetailWrapper(AccountingCustomerInvoice.TaxDetail taxDetail) {
            if(taxDetail.AccountingId != null) {
                this.ItemRef = new QBInnerEntityWrapper(taxDetail.AccountingId, taxDetail.CategoryName);
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

    public class AccountBasedExpenseLineDetailWrapper{
        public QBInnerEntityWrapper AccountRef;
        public QBInnerEntityWrapper TaxCodeRef;
        
        public AccountBasedExpenseLineDetailWrapper(AccountingVendorReturn.AccountRefWrapper AccountRef, String taxCodeAccountingId)	{
            this.AccountRef = new QBInnerEntityWrapper(AccountRef.AccountingId); 
        	if(QBUtil.isQBTaxCodesEnabled) {
            	this.TaxCodeRef = new QBInnerEntityWrapper(taxCodeAccountingId, '');
            }
        }
        
        public AccountBasedExpenseLineDetailWrapper(String CategoryAccountRef, String taxCodeAccountingId)	{
            this.AccountRef = new QBInnerEntityWrapper(CategoryAccountRef); 
            if(QBUtil.isQBTaxCodesEnabled) {
            	this.TaxCodeRef = new QBInnerEntityWrapper(taxCodeAccountingId, '');
            }
        }
        
        public AccountBasedExpenseLineDetailWrapper(String CategoryAccountRef)	{
            this.AccountRef = new QBInnerEntityWrapper(CategoryAccountRef); 
        }
    }
}