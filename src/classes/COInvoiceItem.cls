/**
 * Author: Tarun Khandelwal
 * Since: April 30, 2015
 * Name: COInvoiceItem
 * Description: Apex class to handle JSON related oprations of CO Invoice Header object.
**/
public without sharing class COInvoiceItem {
    
    // CO Line Item Key ( Part Name + Part_Id)
    public String Item {get; set;}
    
    /* START: Added By Tarun - #170 - 09/23/2016 */
    public String ItemCode {get; set;}
    public String ItemDescription {get; set;}
    
    // CO Line Item Qty Committed 
    public Decimal Qty {get; set;} 
        
    // CO Line Item Id
    public String COLineItemId {get; set;}
    
    // CO Line Item Price
    public Decimal Price {get; set;}
    
    //CO Line Item Total
    public Decimal Total {get; set;} 
    
    // CO Invoice Header Id
    public String COInvoiceHeaderId {get; set;}
    
    // CO Invoice Item Id
    public String COInvoiceItemId {get; set;}
    
    // Active
    public Boolean IsActive {get; set;}
    
    // CO Invoice Item Number
    public String COInvoiceItemNumber {get; set;}
    
    // Tax
    public Decimal TaxAmount {get; set;}
    
    //Qty Required
    public Decimal QtyRequired {get; set;}
    
    // Retail Price
    public Decimal RetailPrice {get; set;}
    
    // Saving
    public Decimal Saving {get; set;}
    public Boolean IsNonInventoryPart {get; set;}
    public String COType;
    // Id
    public Boolean IsInvoiceable;
    public String SOStatus;
    public Boolean IsFinalizable;
    
    public String CheckoutType;
    public String ItemType;
    public Boolean isTaxIncludingPricing;
    public String DealId;
    public String DealFinanceId;
    public Decimal DiscountAmount;
    public Boolean IsDisplayDiscountAmount;
    public String TrackingNumber;
      
    // Constructor
    public COInvoiceItem(CO_Invoice_Item__c  coInvoiceItemRec) { 
    	this.TaxAmount = 0;
    	this.IsInvoiceable = false;
    	this.Total = 0;
    	this.DiscountAmount = 0;
    	this.IsDisplayDiscountAmount = false;
    	this.isTaxIncludingPricing = GeneralConfiguration.getTaxIncludingPricing();
    	this.COType = coInvoiceItemRec.CO_Invoice_Header__r.CO_Header__r.CO_Type__c;
    	if(coInvoiceItemRec.CO_Line_Item__c != null) {
    		
    		/* START: Added By Tarun - #170 - 09/23/2016 */
    		this.ItemCode = (coInvoiceItemRec.CO_Line_Item__r.Item_Code__c != null) ? coInvoiceItemRec.CO_Line_Item__r.Item_Code__c : '';
	    	this.ItemDescription = (coInvoiceItemRec.CO_Line_Item__r.Item_Description__c != null) ? coInvoiceItemRec.CO_Line_Item__r.Item_Description__c : '';
	    	this.Item = this.ItemCode + ' - ' + this.ItemDescription;
    		coInvoiceItemRec.CO_Line_Item__r.Qty__c = (coInvoiceItemRec.CO_Line_Item__r.Qty__c != null) ? coInvoiceItemRec.CO_Line_Item__r.Qty__c : 0;
	    	//this.Item = coInvoiceItemRec.CO_Line_Item__r.Part__r.Part_Number__c + ' - ' + coInvoiceItemRec.CO_Line_Item__r.Part__r.Description__c;
	    	if((coInvoiceItemRec.CO_Line_Item__r.Part__c != null && (coInvoiceItemRec.CO_Line_Item__r.Part__r.Non_Inventory_Part__c != null) && coInvoiceItemRec.CO_Line_Item__r.Part__r.Non_Inventory_Part__c) 
	    			|| (coInvoiceItemRec.CO_Line_Item__r.Fee__c != null && coInvoiceItemRec.CO_Line_Item__r.Is_Environmental_Fee__c)) {
	    		this.Qty = coInvoiceItemRec.CO_Line_Item__r.Qty__c;
	    	} else {
	    		this.Qty = coInvoiceItemRec.CO_Line_Item__r.Qty_Committed__c;
	    	}
	    	this.COLineItemId = coInvoiceItemRec.CO_Line_Item__c;
	        this.Price = (coInvoiceItemRec.CO_Line_Item__r.Price__c != null) ? coInvoiceItemRec.CO_Line_Item__r.Price__c.setScale(2, RoundingMode.HALF_UP) : 0.00;
	        if(coInvoiceItemRec.CO_Line_Item__r.Price__c == null) {		
	            this.Price = 0;		
	        } else {		
	            if(!isTaxIncludingPricing) {		
	            	this.Price = coInvoiceItemRec.CO_Line_Item__r.Price__c.setScale(2, RoundingMode.HALF_UP);
	            	if(coInvoiceItemRec.CO_Line_Item__r.Tax__c == null) {
	            		coInvoiceItemRec.CO_Line_Item__r.Tax__c = 0;
	            	} 
	            	this.TaxAmount = ((this.Qty) * (this.Price) * (coInvoiceItemRec.CO_Line_Item__r.Tax__c / 100)).setScale(2, RoundingMode.HALF_UP);		
	            } else {		
	            	if(coInvoiceItemRec.CO_Line_Item__r.Tax__c == null) {
	            		coInvoiceItemRec.CO_Line_Item__r.Tax__c = 0;
	            	}
	            	this.Price = (coInvoiceItemRec.CO_Line_Item__r.Price_When_Tax_Included__c != null) ? coInvoiceItemRec.CO_Line_Item__r.Price_When_Tax_Included__c.setScale(2, RoundingMode.HALF_UP) : 
	            								(coInvoiceItemRec.CO_Line_Item__r.Price__c * (1 + coInvoiceItemRec.CO_Line_Item__r.Tax__c /100)).setScale(2, RoundingMode.HALF_UP);	
	            	this.TaxAmount = ((this.Qty) * (coInvoiceItemRec.CO_Line_Item__r.Price__c) * (coInvoiceItemRec.CO_Line_Item__r.Tax__c / 100)).setScale(2, RoundingMode.HALF_UP);	
	            }		
	        }
	        if(coInvoiceItemRec.CO_Line_Item__r.Tax__c == null) {
	        	coInvoiceItemRec.CO_Line_Item__r.Tax__c = 0;
	        }
	        
	        this.Total = ((this.Qty) * (this.Price)).setScale(2, RoundingMode.HALF_UP);
	        this.isActive = coInvoiceItemRec.isActive__c;
	        this.COInvoiceItemNumber = coInvoiceItemRec.Name;
	        
	        this.QtyRequired = coInvoiceItemRec.CO_Line_Item__r.Qty__c;
	        this.RetailPrice = (coInvoiceItemRec.CO_Line_Item__r.Retail__c != null) ? coInvoiceItemRec.CO_Line_Item__r.Retail__c.setScale(2, RoundingMode.HALF_UP) : 0.00;
	        if(coInvoiceItemRec.CO_Line_Item__r.Retail__c == null) {
	        	coInvoiceItemRec.CO_Line_Item__r.Retail__c = 0.00;
	        } 
	        if(coInvoiceItemRec.CO_Line_Item__r.Price__c == null) {
	        	coInvoiceItemRec.CO_Line_Item__r.Price__c = 0.00;
	        }
	        
	        this.Saving = (this.QtyRequired) * (coInvoiceItemRec.CO_Line_Item__r.Retail__c - coInvoiceItemRec.CO_Line_Item__r.Price__c);
	        
	        if(coInvoiceItemRec.CO_Line_Item__r.Qty_Committed__c > 0 || (coInvoiceItemRec.CO_Line_Item__r.Fee__c != null && coInvoiceItemRec.CO_Line_Item__r.Is_Environmental_Fee__c)) {
	        	this.IsInvoiceable = true;
	        } else {
	        	this.IsInvoiceable = false;
	        }
	        
	        if(coInvoiceItemRec.CO_Line_Item__r.Qty__c == coInvoiceItemRec.CO_Line_Item__r.Qty_Committed__c && coInvoiceItemRec.isActive__c){
	       		this.IsFinalizable = true;
	        } else {
	        	this.IsFinalizable = false;
	        }
	        
	        if(coInvoiceItemRec.CO_Line_Item__r.Qty__c < 0) {
	        	this.Qty = coInvoiceItemRec.CO_Line_Item__r.Qty__c;
	        	this.Total = ((this.Qty) * (this.Price)).setScale(2, RoundingMode.HALF_UP);
	        	this.TaxAmount = ((this.Qty) * (this.Price) * (coInvoiceItemRec.CO_Line_Item__r.Tax__c / 100)).setScale(2, RoundingMode.HALF_UP);
	        	this.IsFinalizable = true;
	        	this.IsInvoiceable = true;
	        }
	        if(String.isNotBlank(coInvoiceItemRec.CO_Line_Item__r.Deal__c)) {
				this.CheckoutType = Constants.CHECKOUT_TYPE_DEAL;
	    		this.TaxAmount = 0;
	    		this.Price = ((coInvoiceItemRec.CO_Line_Item__r.Price__c != null) ? coInvoiceItemRec.CO_Line_Item__r.Price__c : 0).setScale(2, RoundingMode.HALF_UP);
	    		this.Total = ((this.Qty) * (this.Price)).setScale(2, RoundingMode.HALF_UP);
	    		//system.assert(false,coInvoiceItemRec.CO_Line_Item__r.Price__c);
	    		
			} else {
	       		this.CheckoutType = Constants.CHECKOUT_TYPE_CUSTOMER;
			}
            
	        if(coInvoiceItemRec.CO_Line_Item__r.Part__c != null) {
	        	this.ItemType = Constants.PART_INVOICE_ITEM_TYPE;
	        	if(coInvoiceItemRec.CO_Line_Item__r.Part__r.Non_Inventory_Part__c) {
	        		this.IsFinalizable = true;
	        		this.IsInvoiceable = true;
	        		this.Qty = coInvoiceItemRec.CO_Line_Item__r.Qty__c;
	        		this.Total = ((this.Qty) * (this.Price)).setScale(2, RoundingMode.HALF_UP);
	        	}
	        	this.IsNonInventoryPart = coInvoiceItemRec.CO_Line_Item__r.Part__r.Non_Inventory_Part__c;
	        	
	        	if(coInvoiceItemRec.CO_Line_Item__r.Actual_Retail_Price__c == null) {
		        	coInvoiceItemRec.CO_Line_Item__r.Actual_Retail_Price__c = 0.00;
		        }
	        	if(coInvoiceItemRec.CO_Line_Item__r.Qty__c > 0) {
		        	this.DiscountAmount = (coInvoiceItemRec.CO_Line_Item__r.Actual_Retail_Price__c - coInvoiceItemRec.CO_Line_Item__r.Price__c) * coInvoiceItemRec.CO_Line_Item__r.Qty__c;
		        	if(isTaxIncludingPricing && coInvoiceItemRec.CO_Line_Item__r.Tax_Amount__c != null) {
		        		//this.DiscountAmount = this.DiscountAmount - coInvoiceItemRec.CO_Line_Item__r.Tax_Amount__c;
		        	}
		        }
	        	this.IsDisplayDiscountAmount = (this.DiscountAmount > 0) ? true : false;
	        } else if(coInvoiceItemRec.CO_Line_Item__r.Fee__c != null) {
	        	this.ItemType = Constants.FEE_INVOICE_ITEM_TYPE;
	        }
	        
	        
    	} else if(coInvoiceItemRec.Service_Order_Header__c != null) {
    		this.DiscountAmount = (coInvoiceItemRec.Service_Order_Header__r.Total_Discount__c != null) ? (coInvoiceItemRec.Service_Order_Header__r.Total_Discount__c).setScale(2, RoundingMode.HALF_UP) : 0;
        	this.IsDisplayDiscountAmount = (this.DiscountAmount > 0) ? true : false;
    		
    		if(coInvoiceItemRec.SO_Payment_Role__c != null && coInvoiceItemRec.Service_Order_Header__r.Transaction_Type__r.Type__c == 'Third-Party'){    			
    			populateSOPaymentRoleFields(coInvoiceItemRec);    			
    		}else if(coInvoiceItemRec.SO_Payment_Role__c == null && coInvoiceItemRec.Service_Order_Header__r.Transaction_Type__r.Type__c == 'Third-Party' ){
    			populateSOThirdParty(coInvoiceItemRec);	
    		} else {
    			if(coInvoiceItemRec.Service_Order_Header__r.Transaction_Type__r.Type__c == 'Internal' || coInvoiceItemRec.Service_Order_Header__r.Transaction_Type__r.Type__c == 'Stock Unit') {
    				if(coInvoiceItemRec.Service_Order_Header__r.SO_Type__c == 'Internal Service') {
    					this.Item = coInvoiceItemRec.Service_Order_Header__r.Name__c + ' - INTERNAL '; 
    					//this.Item = coInvoiceItemRec.Service_Order_Header__r.Name__c + ' - INTERNAL - ' + coInvoiceItemRec.Service_Order_Header__r.Category__r.Name;
    				} else {
    					this.Item = coInvoiceItemRec.Service_Order_Header__r.Name__c + ' - INTERNAL - ' + coInvoiceItemRec.Service_Order_Header__r.Category__r.Name;
    				}
    				this.CheckoutType = Constants.CHECKOUT_TYPE_INTERNAL;
    			} else {
	    			this.Item = coInvoiceItemRec.Service_Order_Header__r.Name__c;
	    			if(String.isNotBlank(coInvoiceItemRec.Service_Order_Header__r.Deal__c)) {
                          this.CheckoutType = Constants.CHECKOUT_TYPE_DEAL;
                      } else {
                      this.CheckoutType = Constants.CHECKOUT_TYPE_CUSTOMER;
                  }
    			}
	    		this.isActive = coInvoiceItemRec.isActive__c;
	    		this.Total = coInvoiceItemRec.Service_Order_Header__r.Total__c;		
	    		this.TaxAmount = (coInvoiceItemRec.Service_Order_Header__r.Tax_Amount__c != null) ? coInvoiceItemRec.Service_Order_Header__r.Tax_Amount__c.setScale(2, RoundingMode.HALF_UP) : 0.00;
	    		if(String.isNotBlank(coInvoiceItemRec.Service_Order_Header__r.Deal__c)) {
	    			this.TaxAmount = 0;
	    		}
	    		/*if(isTaxIncludingPricing) {		
	    			if(this.Total == null) {		
	    				this.Total = 0;		
	    			}		
	    			if(this.TaxAmount == null) {		
	    				this.TaxAmount = 0;		
	    			}		
	    			this.Total = this.Total + this.TaxAmount;		
	    		}*/		
	    		this.Price = this.Total;
	    		if(ServiceJobUtil.isReadyToCheckout(coInvoiceItemRec.Service_Order_Header__r.SO_Status__c)) {
	    			this.IsInvoiceable = coInvoiceItemRec.Is_Invoiceable__c;
	    			this.isActive  = this.IsInvoiceable;
	    			
	    		} else {
	    			this.isActive = false;
	    		}
	    		this.SOStatus = coInvoiceItemRec.Service_Order_Header__r.Status__c;
	    		
	    		if(coInvoiceItemRec.isActive__c &&  coInvoiceItemRec.Is_Invoiceable__c && (coInvoiceItemRec.Service_Order_Header__r.Status__c == 'Complete'|| coInvoiceItemRec.Service_Order_Header__r.Status__c == 'Reviewed')){
			 		this.IsFinalizable = true;
	    		} else {
					this.IsFinalizable = false;
	    		}
	    		this.ItemType = Constants.WORK_SERVICE_ORDER_INVOICE_ITEM_TYPE;
    		}
    		
    	} else if(coInvoiceItemRec.CO_Kit_Header__c != null){
    		if(coInvoiceItemRec.CO_Kit_Header__r.Kit_Header__c != null) {
    			this.Item = coInvoiceItemRec.CO_Kit_Header__r.Kit_Header__r.Kit_Unique_Name__c;
    		}
    		this.isActive = coInvoiceItemRec.isActive__c;
    		this.IsInvoiceable = coInvoiceItemRec.Is_Invoiceable__c;
    		if(!isTaxIncludingPricing) {
    			this.Total = (coInvoiceItemRec.CO_Kit_Header__r.Price__c != null) ? coInvoiceItemRec.CO_Kit_Header__r.Price__c.setScale(2, RoundingMode.HALF_UP) : 0.00;
    			this.TaxAmount = (coInvoiceItemRec.CO_Kit_Header__r.Tax_Amount__c != null) ? coInvoiceItemRec.CO_Kit_Header__r.Tax_Amount__c.setScale(2, RoundingMode.HALF_UP) : 0.00;
    		}else{
				this.TaxAmount = (coInvoiceItemRec.CO_Kit_Header__r.Tax_Amount__c != null) ? coInvoiceItemRec.CO_Kit_Header__r.Tax_Amount__c.setScale(2, RoundingMode.HALF_UP) : 0.00;
				this.Total = ((coInvoiceItemRec.CO_Kit_Header__r.Price__c != null) ? coInvoiceItemRec.CO_Kit_Header__r.Price__c.setScale(2, RoundingMode.HALF_UP) : 0.00); // + ((coInvoiceItemRec.CO_Kit_Header__r.Tax_Amount__c != null) ? coInvoiceItemRec.CO_Kit_Header__r.Tax_Amount__c.setScale(2, RoundingMode.HALF_UP) : 0.00);
    		}
    		if(coInvoiceItemRec.isActive__c && coInvoiceItemRec.Is_Invoiceable__c ){
    		 	this.IsFinalizable = true;
    		} else {  
    			this.IsFinalizable = false;
    		}
    		if(String.isNotBlank(coInvoiceItemRec.CO_Kit_Header__r.Deal__c)) {
				this.CheckoutType = Constants.CHECKOUT_TYPE_DEAL;
			} else {
    		this.CheckoutType = Constants.CHECKOUT_TYPE_CUSTOMER;
			}
    		this.ItemType = Constants.KIT_INVOICE_ITEM_TYPE;
        	this.DiscountAmount = (coInvoiceItemRec.CO_Kit_Header__r.Total_Discount__c != null) ? (coInvoiceItemRec.CO_Kit_Header__r.Total_Discount__c).setScale(2, RoundingMode.HALF_UP) : 0;
        	this.IsDisplayDiscountAmount = (this.DiscountAmount > 0) ? true : false;
        } else if(coInvoiceItemRec.Deal__c != null) {
        	         
            if(coInvoiceItemRec.Deal__r.Type__c == Constants.CASH_DEAL) {
                this.CheckoutType = Constants.CHECKOUT_TYPE_CUSTOMER;
            } else if(coInvoiceItemRec.Deal__r.Type__c == Constants.FINANCED) {
                this.CheckoutType = Constants.CHECKOUT_TYPE_THIRD_PARTY;
            }
            this.IsInvoiceable = coInvoiceItemRec.Is_Invoiceable__c;
            this.IsActive = coInvoiceItemRec.isActive__c;
            if(coInvoiceItemRec.isActive__c && coInvoiceItemRec.Is_Invoiceable__c ){
    		 	this.IsFinalizable = true;
    		} else {  
    			this.IsFinalizable = false;
    		}
            //this.Total = ((coInvoiceItemRec.Deal__r.Total__c) - coInvoiceItemRec.Deal__r.Total_Deposit_And_Payment__c)).setScale(2, RoundingMode.HALF_UP);
            if(coInvoiceItemRec.Deal_Finance__c != null) {
            	this.DealFinanceId = coInvoiceItemRec.Deal_Finance__c;
            	//this.CheckoutType = Constants.CHECKOUT_TYPE_THIRD_PARTY;
            	this.ItemCode = 'Financing - ' + coInvoiceItemRec.Deal_Finance__r.Finance_Company__r.Name;
	            this.ItemDescription = (coInvoiceItemRec.Deal_Finance__r.Status__c != null ? coInvoiceItemRec.Deal_Finance__r.Status__c : '');
	            this.Item = this.ItemCode + ' - ' + this.ItemDescription;
	            
	            this.Total = ((coInvoiceItemRec.Deal__r.Deal_Total__c != null ? coInvoiceItemRec.Deal__r.Deal_Total__c : 0) + (coInvoiceItemRec.Deal_Finance__r.F_I_Total__c != null ? coInvoiceItemRec.Deal_Finance__r.F_I_Total__c : 0)
	            					 - (coInvoiceItemRec.Deal_Finance__r.Down_Payment__c != null ? coInvoiceItemRec.Deal_Finance__r.Down_Payment__c : 0)).setScale(2, RoundingMode.HALF_UP);
            	this.TaxAmount = ((coInvoiceItemRec.Deal__r.Deal_Tax_Total__c != null ? coInvoiceItemRec.Deal__r.Deal_Tax_Total__c : 0) + (coInvoiceItemRec.Deal_Finance__r.F_I_Product_Tax_Total__c != null ? coInvoiceItemRec.Deal_Finance__r.F_I_Product_Tax_Total__c : 0)).setScale(2, RoundingMode.HALF_UP);
            } else {
            	//this.TaxAmount = (coInvoiceItemRec.Deal__r.Deal_Tax_Total__c != null ? coInvoiceItemRec.Deal__r.Deal_Tax_Total__c : 0).setScale(2, RoundingMode.HALF_UP);
            	
            	this.Total = ((coInvoiceItemRec.Deal__r.Deal_Total__c != null ? coInvoiceItemRec.Deal__r.Deal_Total__c : 0)).setScale(2, RoundingMode.HALF_UP);
            	
	            this.ItemCode = 'Deal';
	            this.ItemDescription = (coInvoiceItemRec.Deal__r.Status__c != null ? coInvoiceItemRec.Deal__r.Status__c : '');
	            this.Item = this.ItemCode + ' - ' + this.ItemDescription; 
    		}
    		if(isTaxIncludingPricing) {
            	//this.Total += this.TaxAmount;
        	}
        	this.Price = this.Total;
    	}
    	this.DealId = coInvoiceItemRec.Deal__c;
    	this.COInvoiceHeaderId = coInvoiceItemRec.CO_Invoice_Header__c;
    	this.COInvoiceItemId = coInvoiceItemRec.Id;
    }
     
     
    public void populateSOPaymentRoleFields(CO_Invoice_Item__c  coInvoiceItemRec) {
    	if(coInvoiceItemRec.SO_Payment_Role__r.RecordType.DeveloperName == 'Deductible') {
    		if(coInvoiceItemRec.SO_Payment_Role__r.Total_Amount__c > 0) {
    			if(coInvoiceItemRec.SO_Payment_Role__r.Deductible_Status__c == 'Owing') {
    				this.Item = coInvoiceItemRec.SO_Payment_Role__r.Service_Order_Header__r.Name__c + ' - CLAIM - Deductible Adjustment';
    			} else {
    				this.Item = coInvoiceItemRec.SO_Payment_Role__r.Service_Order_Header__r.Name__c + ' - CLAIM - Deductible';
    			} 
    			this.isActive = coInvoiceItemRec.isActive__c;
	    		this.Total = (coInvoiceItemRec.SO_Payment_Role__r.Total_Amount__c != null) ? coInvoiceItemRec.SO_Payment_Role__r.Total_Amount__c.setScale(2, RoundingMode.HALF_UP) : 0.00;
	    		this.IsInvoiceable = coInvoiceItemRec.Is_Invoiceable__c;
	    		this.CheckoutType = Constants.CHECKOUT_TYPE_CUSTOMER;
    		}
    	}
    	
    	if(coInvoiceItemRec.SO_Payment_Role__r.RecordType.DeveloperName == 'Third_Party') {
    		if(coInvoiceItemRec.SO_Payment_Role__r.Claim__c != null) {
				this.Item = coInvoiceItemRec.SO_Payment_Role__r.Service_Order_Header__r.Name__c + ' - CLAIM - ' + coInvoiceItemRec.Service_Order_Header__r.Claim_Status__c + ' - ' + coInvoiceItemRec.Service_Order_Header__r.Provider__r.Name;
    			this.isActive = coInvoiceItemRec.isActive__c;
	    		this.Total = (coInvoiceItemRec.SO_Payment_Role__r.Total_Amount__c != null) ? coInvoiceItemRec.SO_Payment_Role__r.Total_Amount__c.setScale(2, RoundingMode.HALF_UP) : 0.00;
	    		if(ServiceJobUtil.isReadyToCheckout(coInvoiceItemRec.SO_Payment_Role__r.Service_Order_Header__r.SO_Status__c)) {
	    			this.IsInvoiceable = coInvoiceItemRec.Is_Invoiceable__c;
	    		} else {
	    			this.IsInvoiceable = false;
	    		}
	    		this.CheckoutType = Constants.CHECKOUT_TYPE_THIRD_PARTY;
    		}
    		
    	}
    	
    	if(coInvoiceItemRec.SO_Payment_Role__r.RecordType.DeveloperName == 'Internal') {
    		if(coInvoiceItemRec.Service_Order_Header__r != null) {
				this.Item = coInvoiceItemRec.Service_Order_Header__r.Name__c + ' - CLAIM VARIANCE ' + ((coInvoiceItemRec.SO_Payment_Role__r.Category__c != null) ? (' - ' + coInvoiceItemRec.SO_Payment_Role__r.Category__r.Name) : '');
    			this.isActive = coInvoiceItemRec.isActive__c;
	    		this.Total = (coInvoiceItemRec.SO_Payment_Role__r.Total_Amount__c != null) ? coInvoiceItemRec.SO_Payment_Role__r.Total_Amount__c.setScale(2, RoundingMode.HALF_UP) : 0.00;
	    		if(ServiceJobUtil.isReadyToCheckout(coInvoiceItemRec.SO_Payment_Role__r.Service_Order_Header__r.SO_Status__c) && coInvoiceItemRec.SO_Payment_Role__r.Claim__r.Claim_Disposition__c != 'Denied') {
	    			this.IsInvoiceable = coInvoiceItemRec.Is_Invoiceable__c;
	    		} else {
	    			this.IsInvoiceable = false;
	    		}
	    		if(coInvoiceItemRec.Service_Order_Header__r.Transaction_Type__r.Type__c == 'Third-Party') {
	    			this.CheckoutType = Constants.CHECKOUT_TYPE_THIRD_PARTY;
	    		} else {
	    			this.CheckoutType = Constants.CHECKOUT_TYPE_INTERNAL;
	    		}
    		}
    	}
    	
    	if(coInvoiceItemRec.SO_Payment_Role__r.RecordType.DeveloperName == 'Customer') {
    		if(coInvoiceItemRec.Service_Order_Header__r != null) {
				this.Item = coInvoiceItemRec.Service_Order_Header__r.Name__c + ' - CLAIM VARIANCE -  [item/desc from the claim]';
    			this.isActive = coInvoiceItemRec.isActive__c;
    			this.Qty = coInvoiceItemRec.SO_Payment_Role__r.Qty__c;
	    		this.Total = (coInvoiceItemRec.SO_Payment_Role__r.Total_Amount__c != null) ? coInvoiceItemRec.SO_Payment_Role__r.Total_Amount__c.setScale(2, RoundingMode.HALF_UP) : 0.00;
	    		if(ServiceJobUtil.isReadyToCheckout(coInvoiceItemRec.SO_Payment_Role__r.Service_Order_Header__r.SO_Status__c) && coInvoiceItemRec.SO_Payment_Role__r.Claim__r.Claim_Disposition__c != 'Denied') {
	    			this.IsInvoiceable = coInvoiceItemRec.Is_Invoiceable__c;
	    		} else {
	    			this.IsInvoiceable = false;
	    		}
	    		this.CheckoutType = Constants.CHECKOUT_TYPE_CUSTOMER;
    		}
    	}
    	if(this.IsInvoiceable && this.isActive) {
    		this.IsFinalizable = true;
    	} else {
    		this.IsFinalizable = false;
    	}
    	
    	this.TaxAmount = (coInvoiceItemRec.SO_Payment_Role__r.Tax_Amount__c == null) ? 0 : coInvoiceItemRec.SO_Payment_Role__r.Tax_Amount__c;
    	if(this.isTaxIncludingPricing) {
    		if(this.Total == null) {
				this.Total = 0;
			}
    		this.Total = this.Total + this.TaxAmount; 
    	}
    	//this.IsFinalizable = false; 
    	//system.assert(false,this.IsFinalizable);
    	this.ItemType = Constants.CLAIM_SERVICE_ORDER_INVOICE_ITEM_TYPE;
    }
    
   public void populateSOThirdParty(CO_Invoice_Item__c  coInvoiceItemRec) {
		this.Item = coInvoiceItemRec.Service_Order_Header__r.Name__c + ' - CLAIM - ' + ((coInvoiceItemRec.Service_Order_Header__r.Claim_Status__c !=null) ? coInvoiceItemRec.Service_Order_Header__r.Claim_Status__c : 'Unsubmitted ') + ((coInvoiceItemRec.Service_Order_Header__r.Provider__r.Name !=null ) ? ' - ' + coInvoiceItemRec.Service_Order_Header__r.Provider__r.Name : '');
		this.isActive = false;
		this.TaxAmount = (coInvoiceItemRec.Service_Order_Header__r.Tax_Amount__c != null) ? coInvoiceItemRec.Service_Order_Header__r.Tax_Amount__c.setScale(2, RoundingMode.HALF_UP) : 0.00;
		this.Total = (coInvoiceItemRec.Service_Order_Header__r.Total__c != null) ? coInvoiceItemRec.Service_Order_Header__r.Total__c : 0;		
		if(isTaxIncludingPricing) {		
			if(this.Total == null) {		
				this.Total = 0;		
			}		
			if(this.TaxAmount == null) {		
				this.TaxAmount = 0;		
			}		
			this.Total = this.Total + this.TaxAmount;		
		}
		this.Price = this.Total;		
		this.IsInvoiceable = false;
		this.CheckoutType = Constants.CHECKOUT_TYPE_THIRD_PARTY;
		this.ItemType = Constants.CLAIM_SERVICE_ORDER_INVOICE_ITEM_TYPE;
	}
     
    /**
     * Name: parse
     * Desc: Method to Parse JSON String to class instance
     * @param:  (1) JSONString - String - JSON String 
     * @return: COLineItem - Class Object
    **/
    public static COInvoiceItem parse(String json) {
        return (COInvoiceItem) System.JSON.deserialize(json, COInvoiceItem.class);
    }
    
    /**
     * Name: fieldsList
     * Desc: Method Which contains all the field list to be quried
     * @param:  
     * @return: List<String> - Fields List
    **/
    public static List<String> fieldsList(){
        List<String> coInvoiceItemFields = new List<String>{ 'Id',
	                                                        'Name', 
	                                                        'Qty__c',
	                                                        'CO_Invoice_Header__c',
	                                                        'CO_Line_Item__c',
	                                                        'isActive__c',
	                                                        'Is_Invoiceable__c',
	                                                        'CreatedDate',
	                                                        
	                                                        'CO_Line_Item__r.Part__c',
	                                                        'CO_Line_Item__r.Part__r.Name',
	                                                        'CO_Line_Item__r.Part__r.Non_Inventory_Part__c',
	                                                        'CO_Line_Item__r.Part__r.Part_Number__c',
	                                                        'CO_Line_Item__r.Part__r.Description__c',
	                                                        'CO_Line_Item__r.Item_ID__c',
	                                                        'CO_Line_Item__r.Item_Code__c',
	                                                        'CO_Line_Item__r.Item_Description__c',
	                                                        'CO_Line_Item__r.Qty_Committed__c',
	                                                        'CO_Line_Item__r.Price__c',
	                                                        'CO_Line_Item__r.Price_When_Tax_Included__c',
	                                                        'CO_Line_Item__r.Retail__c',
	                                                        'CO_Line_Item__r.Actual_Retail_Price__c',
	                                                        'CO_Line_Item__r.Tax__c',
	                                                        'CO_Line_Item__r.Qty__c',
	                                                        'CO_Line_Item__r.Fee__c',
	                                                        'CO_Line_Item__r.Deal__c',
	                                                        'CO_Line_Item__r.Tax_Amount__c',
	                                                        'CO_Line_Item__r.Is_Environmental_Fee__c',
	                                                        'CO_Invoice_Header__r.CO_Header__r.CO_Type__c',
                                                            'Deal__c',
                                                            'Deal__r.Type__c',
                                                            'Deal__r.Deal_Total__c',
                                                            'Deal__r.Status__c',
                                                            'Deal__r.Total_Deposit_And_Payment__c',
                                                            'Deal__r.Deal_Tax_Total__c',
                                                            'Deal__r.F_I_Total__c',
                                                            'Deal__r.F_I_Tax_Total__c',
                                                            
                                                            'Deal_Finance__c',
                                                            'Deal_Finance__r.Finance_Company__r.Name',
                                                            'Deal_Finance__r.Status__c',
                                                            'Deal_Finance__r.F_I_Total__c',
                                                            'Deal_Finance__r.Down_Payment__c',  
                                                            'Deal_Finance__r.F_I_Product_Tax_Total__c',
                                                            
	                                                        'Service_Order_Header__c',
	                                                        'Service_Order_Header__r.SO_Type__c',
	                                                        'Service_Order_Header__r.Name__c',
	                                                        'Service_Order_Header__r.Total__c',
	                                                        'Service_Order_Header__r.Tax_Amount__c',
	                                                        'Service_Order_Header__r.Status__c',
	                                                        'Service_Order_Header__r.SO_Status__c',
	                                                        'Service_Order_Header__r.Claim_Status__c',
	                                                        'Service_Order_Header__r.Transaction_Type__r.Type__c',
	                                                        'Service_Order_Header__r.Provider__r.Name',
	                                                        'Service_Order_Header__r.Category__r.Name',
	                                                        'Service_Order_Header__r.Deal__c',
	                                                        'Service_Order_Header__r.Total_Discount__c',
	                                                        
	                                                        'CO_Kit_Header__r.Kit_Header__r.Kit_Unique_Name__c',
	                                                        'CO_Kit_Header__r.Price__c',
	                                                        'CO_Kit_Header__r.Tax_Amount__c',
	                                                        'CO_Kit_Header__r.Deal__c',
	                                                        'CO_Kit_Header__r.Total_Discount__c',
	                                                        'SO_Payment_Role__c',
															'SO_Payment_Role__r.RecordType.DeveloperName',
															'SO_Payment_Role__r.Total_Amount__c',
															'SO_Payment_Role__r.Tax_Amount__c',
															'SO_Payment_Role__r.Deductible_Status__c',
															'SO_Payment_Role__r.Service_Order_Header__r.Name__c',
															'SO_Payment_Role__r.Service_Order_Header__r.SO_Status__c',
															'SO_Payment_Role__r.Claim__c',
															'SO_Payment_Role__r.Claim__r.Claim_Disposition__c',
															'SO_Payment_Role__r.Qty__c',
															'SO_Payment_Role__r.Category__c',
															'SO_Payment_Role__r.Category__r.Name'
	                                               		 };
        return coInvoiceItemFields;
    }
}