/** 
* Author: Richa Mittal
* Since: Feb 03, 2021
* Name: ShopifyOrderService 
* Description: Apex class which contains Shopify order related methods.
**/
public without sharing class ShopifyOrderService {
    
    public static String createCustomer(ShopifyOrderWrapper shopifyOrder) {
        if(shopifyOrder != null && shopifyOrder.customer != null && shopifyOrder.customer.shopifyId != null) {
            return updateCustomerInBP(shopifyOrder.customer);
        }
        return null;
    }
    
    public static void insertCOLIs(String coId, ShopifyOrderWrapper shopifyOrder) {
        List<Sobject> itemsInsertList = COService.addLinkedFee(coId, null, 'Merchandise');
        if(itemsInsertList == null) {
            itemsInsertList = new List<Sobject>();
        }
        String comment = '';
    	if(shopifyOrder != null && shopifyOrder.lineItems != null) {
    		Map<String, Part__c> shopifyIdToPartRecMap = getShopifyIdToPartRecMap(shopifyOrder.lineItems);
    		
    		for(ShopifyOrderWrapper.ShopifyOrderLineItem lineItemObj: shopifyOrder.lineItems) {
    			String partId = (shopifyIdToPartRecMap.containsKey(lineItemObj.shopifyId) && shopifyIdToPartRecMap.get(lineItemObj.shopifyId) != null) ? 
    							shopifyIdToPartRecMap.get(lineItemObj.shopifyId).Id : null;
    			if(partId != null) {
    				itemsInsertList.add(setCOLIFields(coId, lineItemObj, partId, shopifyIdToPartRecMap.get(lineItemObj.shopifyId).Non_Inventory_Part__c, shopifyIdToPartRecMap.get(lineItemObj.shopifyId).AvailableParts__c));
    			} else {
    				CO_Line_Item__c coliRec = setCOLIFields(coId, lineItemObj, null, false, null);
    				comment += createCommentStr(lineItemObj);
    				if(coliRec != null) {
    					itemsInsertList.add(coliRec);
    				}
    			}
    		}
        }
        itemsInsertList.addAll((List<SObject>)addAdditionalFees(coId, shopifyOrder));

        if(itemsInsertList.size() > 0) {
            DMLUtility.insertSobjectList('CO_Line_Item__c', itemsInsertList);

			updatePricesFromShopify(itemsInsertList);
            if(comment.length() > 0) {
                comment = comment.substring(0, comment.length()-1);
                COService.addInternalCommentToCO(coId, comment);
            }
        }
	}
	
	private static List<CO_Line_Item__c> addAdditionalFees(String coId, ShopifyOrderWrapper shopifyOrder) {
        List<CO_Line_Item__c> coliList = new List<CO_Line_Item__c>();
        if(shopifyOrder != null && ((shopifyOrder.discount != null && shopifyOrder.discount != 0) || (shopifyOrder.shippingCharge != null && shopifyOrder.shippingCharge != 0))) {
            Configurations__c config = Configurations__c.getOrgDefaults();
            Set<String> bpFeeIdSet = new Set<String>{config.Shopify_Discount_Fee_Id__c, config.Shopify_Shipping_Fee_Id__c};
            bpFeeIdSet.remove(null);
            if(bpFeeIdSet.size() > 0) {
                for(Fee__c feeRec : [Select Id from Fee__c where Id IN: bpFeeIdSet]) {
                    if(shopifyOrder.discount != null && shopifyOrder.discount != 0 && feeRec.Id == config.Shopify_Discount_Fee_Id__c) {
                        coliList.add(setCOLIFields(coId, -1, shopifyOrder.discount, feeRec.Id));
                    }
                    if(shopifyOrder.shippingCharge != null && shopifyOrder.shippingCharge != 0 && feeRec.Id == config.Shopify_Shipping_Fee_Id__c) {
                        coliList.add(setCOLIFields(coId, 1, shopifyOrder.shippingCharge, feeRec.Id));
                    }
                }
            }
        }
        return coliList;
    }

    private static CO_Line_Item__c setCOLIFields(String coId, Decimal qty, Decimal price, String feeId) {
        CO_Line_Item__c coliRec = new CO_Line_Item__c(Fee__c = feeId);
        coliRec.CO_Header__c = coId;
        coliRec.Qty__c = coliRec.Qty_Committed__c = qty;
        coliRec.Price__c = coliRec.Actual_Retail_Price__c = price;
        if(GeneralConfiguration.getTaxIncludingPricing()) {
    		coliRec.Price_When_Tax_Included__c = coliRec.Price__c;
    	}
        return coliRec;
    }
    	
    public static String createCO(String customerId, String shopifyId) {
        String customerIdEncoded = BPUtility.getEncodedString(customerId);
        String sellingGroupEncoded = BPUtility.getEncodedString('Part Sale');
        if(String.isBlank(customerId)) {
            sellingGroupEncoded = BPUtility.getEncodedString('Cash Sale');
        }
        String coHeaderId = BPUtility.getDecodedString(BPGlobalHeaderCtrl.createNewCO(customerIdEncoded, sellingGroupEncoded, true));
        COSectionDetailService.createCOSection(coHeaderId, COSectionDetailService.MERCHANDISE);
        
        if(String.isNotBlank(coHeaderId)) {
            CO_Header__c coHeaderRec = new CO_Header__c(Id = coHeaderId);
            coHeaderRec.Shopify_ID__c = shopifyId;
            String shopifyTransactionTypeId = Configurations__c.getOrgDefaults().Shopify_TT_Id__c;
            if(String.isNotBlank(shopifyTransactionTypeId)) {
                coHeaderRec.Transaction_Type__c = shopifyTransactionTypeId;
            }
            DMLUtility.updateSobjectList('CO_Header__c', coHeaderRec);
        }
        return coHeaderId;
    }
    
    public static String addDeposit(String coHeaderId, ShopifyOrderWrapper shopifyOrder) {
        Decimal amount = (shopifyOrder.total != null ? shopifyOrder.total : 0);
        if(amount == 0) {
            return null;
        }
        String depositDate = (shopifyOrder.updatedAt != null ? shopifyOrder.updatedAt : null);
        
        CO_Deposit__c coDepositRec = new CO_Deposit__c(Amount__c = amount);
        String shopifyPaymentMethodId = Configurations__c.getOrgDefaults().Shopify_Payment_Method_Id__c;
        List<Payment_Method__c> paymentMethodList = [SELECT Name FROM Payment_Method__c WHERE Id =: shopifyPaymentMethodId];
        coDepositRec.Payment_Method__c = (paymentMethodList.size() > 0) ? paymentMethodList[0].Name : 'Cash';
        
        List<Cash_Drawer__c> cashDrawerList = [SELECT Id FROM Cash_Drawer__c WHERE Active__c = true Order by CreatedDate ASC limit 1];
        if(cashDrawerList.size() > 0) {
            coDepositRec.Cash_Drawer__c = cashDrawerList[0].Id;
        }
        
        coDepositRec.CO_Header__c = coHeaderId;
        if(String.isNotBlank(depositDate)) {
            try {
                DateTime depositDateTime = DateTime.parse(depositDate);
                coDepositRec.Payment_Date__c = Date.newInstance(depositDateTime.year(), depositDateTime.month(), depositDateTime.day());
            } catch(Exception e) {
                coDepositRec.Payment_Date__c = date.today();
            }
        } else {
            coDepositRec.Payment_Date__c = date.today();
        }
        DMLUtility.insertSobjectList('CO_Deposit__c', coDepositRec);
        return coDepositRec.Id;
    }
    
    public static void addInternalComment(String coHeaderId, ShopifyOrderWrapper shopifyOrder) {
        String comment = 'Shopify order: ' + shopifyOrder.orderNumber + ' Total: $' + shopifyOrder.total + ' ';
        for(ShopifyOrderWrapper.ShopifyOrderTaxLine taxLine : shopifyOrder.taxLines) {
            comment += (taxLine.title + ' $' + taxLine.tax + ' ');
        }
        if(shopifyOrder.customer != null && shopifyOrder.customer.note != null) {
            comment += ' Notes: ' + shopifyOrder.customer.note;
        }
        COService.addInternalCommentToCO(coHeaderId, comment);
    }
    
    private static String updateCustomerInBP(ShopifyOrderWrapper.ShopifyCustomer shopifyCustomer) {
        List<Account> customerList = getBPCustomerByShopifyId(shopifyCustomer.shopifyId);
        if(customerList.size() == 0) { customerList.add(new Account()); }
        if(String.isBlank(customerList[0].Id) || isCustomerUpdateRequired(shopifyCustomer, customerList[0])) {
            customerList[0] = setCustomerFields(shopifyCustomer, customerList[0]);
            DMLUtility.upsertSobjectList('Account', customerList);
        }
        return customerList[0].Id;
    }
    
    private static List<Account> getBPCustomerByShopifyId(String shopifyId) {
        if(!AccessControl.ifObjectFieldIsAccessible('Account')) {throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE);}
        List<Account> customerList = [SELECT Id, FirstName__c, LastName__c, Company_Name__c, Home_Number__c, Email__c, Type__c, 
                                        BillingStreet, BillingCity, BillingState, BillingCountry, BillingPostalCode , QB_Updated_Fields__c
                                        FROM Account WHERE Is_Customer__c = true AND Shopify_ID__c =: shopifyId 
                                        AND Active__c = true order By CreatedDate ASC];
        return customerList;                           
    }
    
    private static Account setCustomerFields(ShopifyOrderWrapper.ShopifyCustomer shopifyCustomer, Account customerRec) {
        if(String.isBlank(shopifyCustomer.firstName) && String.isBlank(shopifyCustomer.lastName)) {
            customerRec.Name = String.isNotBlank(shopifyCustomer.company) ? shopifyCustomer.company : (String.isNotBlank(shopifyCustomer.email) ? shopifyCustomer.email : shopifyCustomer.phone);
            customerRec.Type__c = 'Business';
            customerRec.Work_Number__c = getPhoneNumberWithoutCode(shopifyCustomer.phone);
            customerRec.Work_Email__c = shopifyCustomer.email;
        } else {
            customerRec.FirstName__c = shopifyCustomer.firstName;
            customerRec.LastName__c = shopifyCustomer.lastName;
            customerRec.Name = (customerRec.FirstName__c != null ? customerRec.FirstName__c + ' ' : '') + 
                                        (customerRec.LastName__c != null ? customerRec.LastName__c : '');
            customerRec.Type__c = 'Individual';
            customerRec.Home_Number__c = getPhoneNumberWithoutCode(shopifyCustomer.phone);
            customerRec.Email__c = shopifyCustomer.email;
        }
        
        customerRec.Company_Name__c = shopifyCustomer.company != null ? shopifyCustomer.company : '';
        customerRec.BillingStreet = (shopifyCustomer.address1 != null ? shopifyCustomer.address1 : '') + '\n' + 
                                    (shopifyCustomer.address2 != null ? shopifyCustomer.address2 : '');
        customerRec.BillingCity = shopifyCustomer.city;
        customerRec.BillingState = shopifyCustomer.province;
        customerRec.BillingCountry = shopifyCustomer.country;
        customerRec.BillingPostalCode = shopifyCustomer.postalZIP;
        customerRec.Shopify_ID__c = shopifyCustomer.shopifyId;
        customerRec.Active__c = true;
        customerRec.Is_Customer__c = true;
        customerRec.Is_Vendor__c = false;
        customerRec.SA_same_as_BA__c = true;
        
        if(!AccessControl.ifObjectFieldIsAccessible('Account_Type__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<Account_Type__c> accTypeList = [SELECT Id FROM Account_Type__c WHERE Applies_To__c = 'Customers' 
                                                AND Active__c = true AND Default__c = true limit 1];
        if(accTypeList.size() > 0) {
            customerRec.Account_Type__c = accTypeList[0].Id;
        }
        
        customerRec = setCustomerAccountingFields(customerRec);
        return customerRec;
    }
    
    private static Account setCustomerAccountingFields(Account customerRec) {
    	String customerUpdatedFields = 'FirstName__c,LastName__c,Company_Name__c,BillingStreet,BillingCity,BillingState,BillingCountry,BillingPostalCode,' + 
    									'Email__c,Home_Number__c,Work_Number__c,Work_Email__c,';
    	if(QBUtil.isQBEnabled()) {
            customerRec.availForQBSync__c = true;
            customerRec.QB_Updated_Fields__c = (String.isNotBlank(customerRec.QB_Updated_Fields__c) ? customerRec.QB_Updated_Fields__c : '') + customerUpdatedFields;
        } else if(General_Configurations__c.getOrgDefaults().Enable_Xero_Accounting__c) {
            customerRec.Available_For_Xero_Customer_Sync__c = true;
            customerRec.QB_Updated_Fields__c = (String.isNotBlank(customerRec.QB_Updated_Fields__c) ? customerRec.QB_Updated_Fields__c : '') + customerUpdatedFields;
        }
        return customerRec;
    }
    
    private static Boolean isCustomerUpdateRequired(ShopifyOrderWrapper.ShopifyCustomer shopifyCustomer, Account customerRec) {
        List<String> bsList = ((customerRec.BillingStreet != null ) ? customerRec.BillingStreet : '').split('\n');
        String billingStreet1 = (bsList.size() > 0) ? bsList[0] : '';
        String billingStreet2 = (bsList.size() > 1) ? bsList[1] : '';
        return isFieldValueChanged(shopifyCustomer.company, customerRec.Company_Name__c) || 
        	isFieldValueChanged(shopifyCustomer.address1, billingStreet1) || 
            isFieldValueChanged(shopifyCustomer.address2, billingStreet2) || 
            isFieldValueChanged(shopifyCustomer.city, customerRec.BillingCity) || 
            isFieldValueChanged(shopifyCustomer.province, customerRec.BillingState) || 
            isFieldValueChanged(shopifyCustomer.country, customerRec.BillingCountry) || 
            isFieldValueChanged(shopifyCustomer.postalZIP, customerRec.BillingPostalCode) || 
            (customerRec.Type__c == 'Individual' && ((isFieldValueChanged(shopifyCustomer.firstName, customerRec.FirstName__c) || 
            isFieldValueChanged(shopifyCustomer.lastName, customerRec.LastName__c) || 
            isFieldValueChanged(shopifyCustomer.email, customerRec.Email__c) || 
            isFieldValueChanged(getPhoneNumberWithoutCode(shopifyCustomer.phone), customerRec.Home_Number__c))) || 
            (customerRec.Type__c == 'Business' && (isFieldValueChanged(getPhoneNumberWithoutCode(shopifyCustomer.phone), customerRec.Work_Number__c) || 
            isFieldValueChanged(getPhoneNumberWithoutCode(shopifyCustomer.phone), customerRec.Work_Email__c))));
    }
    
    private static Boolean isFieldValueChanged(String shopifyFieldValue, String bpFieldValue) {
        return (String.isNotBlank(shopifyFieldValue) || String.isNotBlank(bpFieldValue)) && (shopifyFieldValue != bpFieldValue);
    }
    
    private static String getPhoneNumberWithoutCode(String formattedPhoneNumber) {
        return ((formattedPhoneNumber != null && formattedPhoneNumber.startsWith('+1')) ? formattedPhoneNumber.replace('+1', '') : '');
    }
    
    private static Map<String, Part__c> getShopifyIdToPartRecMap(List<ShopifyOrderWrapper.ShopifyOrderLineItem> lineItems) {
    	Map<String, Part__c> shopifyIdToPartRecMap = new Map<String, Part__c>();
    	Map<String, String> productShopifyIdToShopifyIdMap = new Map<String, String>();
    	Map<String, String> partUniqueIdToShopifyIdMap = new Map<String, String>();
    	
    	for(ShopifyOrderWrapper.ShopifyOrderLineItem lineItemObj: lineItems) {
    		if(String.isNotBlank(lineItemObj.shopifyId)) {
    			shopifyIdToPartRecMap.put(lineItemObj.shopifyId, null);
    			if(String.isNotBlank(lineItemObj.productShopifyId)) {
    				productShopifyIdToShopifyIdMap.put(lineItemObj.productShopifyId, lineItemObj.shopifyId);
    			}
	    		if(String.isNotBlank(lineItemObj.productNumber) && String.isNotBlank(lineItemObj.vendorCode)) {
    				partUniqueIdToShopifyIdMap.put((lineItemObj.productNumber + lineItemObj.vendorCode), lineItemObj.shopifyId);
    			}
    		}
    	}
    	
    	if(shopifyIdToPartRecMap.size() > 0) {
    		List<Part__c> partList = [SELECT Non_Inventory_Part__c, Shopify_Product__r.Unique_Id__c, Part_ID__c, AvailableParts__c FROM Part__c 
    		                             WHERE Shopify_Product__r.Unique_Id__c IN :productShopifyIdToShopifyIdMap.keySet()
    									       OR Part_ID__c IN :partUniqueIdToShopifyIdMap.keySet()];
	    	for(Part__c partRec: partList) {
	    		if(productShopifyIdToShopifyIdMap.containsKey(partRec.Shopify_Product__r.Unique_Id__c)) {
	    			shopifyIdToPartRecMap.put(productShopifyIdToShopifyIdMap.get(partRec.Shopify_Product__r.Unique_Id__c), partRec);
	    		} else if(partRec.Part_ID__c != null && productShopifyIdToShopifyIdMap.containsKey(partRec.Part_ID__c)) {
		    		shopifyIdToPartRecMap.put(partUniqueIdToShopifyIdMap.get(partRec.Part_ID__c), partRec);
	    		}
	    	}
    	}
    	return shopifyIdToPartRecMap;
    }
    
    private static CO_Line_Item__c setCOLIFields(String coHeaderId, ShopifyOrderWrapper.ShopifyOrderLineItem lineItemObj, String partId, Boolean isNonInvPart, Decimal bpPartQty) {
    	CO_Line_Item__c coliRec = new CO_Line_Item__c();
    	coliRec.CO_Header__c = coHeaderId;
        coliRec.Qty__c = lineItemObj.quantity;
        coliRec.Price__c = ((lineItemObj.total != null ? lineItemObj.total : 0)/lineItemObj.quantity).setScale(2, RoundingMode.HALF_UP);
        coliRec.Actual_Retail_Price__c = lineItemObj.price;
        
    	if(partId != null) {
        	bpPartQty = bpPartQty != null ? bpPartQty : 0;
            coliRec.Qty_Committed__c = (coliRec.Qty__c != null && coliRec.Qty__c > 0 && coliRec.Qty__c  > bpPartQty) ? bpPartQty : coliRec.Qty__c;
    		coliRec.Part__c = partId;
    		if(isNonInvPart != null && isNonInvPart) {
            	coliRec.Status__c = 'In Stock';
    		}
    		
    		List<CO_Header__c> coList= [SELECT Merchandise_Commit_Order_controls__c FROM CO_Header__c WHERE Id = :coHeaderId];
    		coliRec.Merchandise_Commit_Order_controls__c = coList.size() > 0 ? coList[0].Merchandise_Commit_Order_controls__c : null;
    	} else {
        	coliRec.Qty_Committed__c = coliRec.Qty__c;
    		String shopifyFeeId = Configurations__c.getOrgDefaults().Shopify_Fee_Id__c;
	    	if(String.isBlank(shopifyFeeId)) {
	    		return null;
	    	}
	        List<Fee__c> feeList = SOQLUtil.getFeeByFieldName(new Map<String, String>{'Id' => shopifyFeeId});
	        if(feeList.size() == 0) {
	            return null;
	        }
	        coliRec.Fee__c = feeList[0].Id;
	        coliRec.Item_Description__c = lineItemObj.productNumber + ' ' + lineItemObj.vendorCode;
    	}
    	
    	coliRec.Price__c = ((lineItemObj.total != null ? lineItemObj.total : 0)/lineItemObj.quantity).setScale(2, RoundingMode.HALF_UP);
    	if(GeneralConfiguration.getTaxIncludingPricing()) {
    		coliRec.Price_When_Tax_Included__c = coliRec.Price__c;
    	}
            
        return coliRec;
    }
    
    private static void updatePricesFromShopify(List<CO_Line_Item__c> coliList) {
    	for(CO_Line_Item__c coliRec: coliList) {
    		if(GeneralConfiguration.getTaxIncludingPricing()) {
	    		Decimal price = coliRec.Price_When_Tax_Included__c;
	    		if(String.isNotBlank(coliRec.Id)) {
	    			List<CO_Line_Item__c> coLineItemList = [Select Tax__c FROM CO_Line_Item__c WHERE Id = :coliRec.Id];
	            	if(coLineItemList.size() > 0) {
	            		coLineItemList[0].Tax__c = coLineItemList[0].Tax__c != null ? coLineItemList[0].Tax__c : 0;
	            	    coliRec.Price__c = (price / (1 + (coLineItemList[0].Tax__c / 100))).setScale(2, RoundingMode.HALF_UP);
	            	}
	    		}
	    	}
    	}
    	COLineItemTriggerHelper.isTotalCalculated = false;
    	COLineItemTriggerHelper.isCalculateSalesTax = false;
        DMLUtility.updateSobjectList('CO_Line_Item__c', coliList);
    }
    
    private static String createCommentStr(ShopifyOrderWrapper.ShopifyOrderLineItem lineItemObj) {
    	return 'Shopify item not found: ' + lineItemObj.productShopifyid + ' ' + lineItemObj.productNumber + ' ' + lineItemObj.vendorCode + ';';
    }
}