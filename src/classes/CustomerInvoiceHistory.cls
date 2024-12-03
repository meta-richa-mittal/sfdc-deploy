public without sharing class CustomerInvoiceHistory {
    
    public List<CusomterInvoiceWrapper> InvoiceHistoryList;
    public Integer TotalInvoice;
	public Decimal InvoicesTotalAmount;
    
    public CustomerInvoiceHistory(List<CO_Invoice_Header__c> invoiceList, Integer totalInvoice) {
        Map<String, String> dealIdToUnitDescMap = getDealIdToUnitDescMap(invoiceList);
        this.InvoiceHistoryList = new List<CusomterInvoiceWrapper>();
        for(CO_Invoice_Header__c invoiceRec : invoiceList) {
            InvoiceHistoryList.add(new CusomterInvoiceWrapper(invoiceRec, dealIdToUnitDescMap));
        }
        this.TotalInvoice = totalInvoice;
    }
    
    public static Map<String, String> getDealIdToUnitDescMap(List<CO_Invoice_Header__c> invoiceList) {
        Set<Id> dealIdSet = new Set<Id>();
        for(CO_Invoice_Header__c invoiceRec : invoiceList) {
            for(CO_Invoice_Item__c invoiceItemRec : invoiceRec.CO_Invoice_Items__r) {
                if(invoiceItemRec.Deal__c != null) {
                    dealIdSet.add(invoiceItemRec.Deal__c);
                }
            }
        }
        dealIdSet.remove(null);
        
        List<Deal_Item__c> dealItemList = [SELECT Customer_Owned_Unit__r.Formatted_Name__c, Deal__c FROM Deal_Item__c WHERE Deal__c IN: dealIdSet
        									AND Type__c = 'Unit'];
        Map<String, String> dealIdToUnitDescMap = new Map<String, String>();
        for(Deal_Item__c dealItemRec : dealItemList) {
            if(!dealIdToUnitDescMap.containsKey(dealItemRec.Deal__c)) {
                dealIdToUnitDescMap.put(dealItemRec.Deal__c, dealItemRec.Customer_Owned_Unit__r.Formatted_Name__c);
            } else {
                dealIdToUnitDescMap.put(dealItemRec.Deal__c, dealIdToUnitDescMap.get(dealItemRec.Deal__c) + ';' + dealItemRec.Customer_Owned_Unit__r.Formatted_Name__c);
            }
        }
        return dealIdToUnitDescMap;
    }
    
    
    public class CusomterInvoiceWrapper {
	    public String COHeaderId;
	    public String InvoiceNumber;
	    public String InvoiceDate;
	    public Decimal InvoiceTotal;
	    public String InvoiceType;
	    public String Description;
		public String COInvoiceHeaderId;
        public Boolean HasCustomerPayServiceJob;
        public Boolean HasLineItemFromMerchSection;

	    public CusomterInvoiceWrapper(CO_Invoice_Header__c invoiceRec, Map<String, String> dealIdToUnitDescMap) {
	        this.COHeaderId = invoiceRec.CO_Header__c;
	        this.InvoiceNumber = invoiceRec.Invoice_Number__c;
	        this.InvoiceDate = BPUtility.getFormatedDateTime(invoiceRec.Invoice_Date__c);
	        this.InvoiceTotal = invoiceRec.Total__c;
			this.COInvoiceHeaderId = invoiceRec.Id;
            this.HasLineItemFromMerchSection = false;
            this.HasCustomerPayServiceJob = false;
	        
	        Map<String, Integer> invoiceTypeToCountMap = new Map<String, Integer>();
	        for(CO_Invoice_Item__c invoiceItemRec : invoiceRec.CO_Invoice_Items__r) {
	            String entityType;
	            if(invoiceItemRec.Deal__c != null) {
	                entityType = 'Deal';
	            } else if(invoiceItemRec.SO_Payment_Role__c != null && invoiceItemRec.SO_Payment_Role__r.RecordType.DeveloperName == 'Deductible') {
	                entityType = 'Deductible';
	            } else if(invoiceItemRec.Service_Order_Header__c != null) {
	                entityType = 'Service';
	            } else if(invoiceItemRec.CO_Line_Item__c != null || invoiceItemRec.CO_Kit_Header__c != null) {
	                entityType = 'Parts';
	            }
	            if(entityType != null) {
	                if(!invoiceTypeToCountMap.containsKey(entityType)) {
	                    invoiceTypeToCountMap.put(entityType, 0);
	                }
	                invoiceTypeToCountMap.put(entityType, invoiceTypeToCountMap.get(entityType) + 1);
	            }

				if(!this.HasLineItemFromMerchSection && invoiceItemRec.CO_Line_Item__c != null && invoiceItemRec.CO_Line_Item__r.Deal__c == null) {
                    this.HasLineItemFromMerchSection = true;
                    break;
                } else if(!this.HasCustomerPayServiceJob && invoiceItemRec.Service_Order_Header__c != null && invoiceRec.Checkout_Type__c == Constants.CHECKOUT_TYPE_CUSTOMER) {
                    this.HasCustomerPayServiceJob = true;
                }
	        }
	        if(invoiceTypeToCountMap.size() > 1) {
	            this.InvoiceType = 'Multiple';
	        } else if(invoiceTypeToCountMap.size() == 1) {
	            for(String entityType : invoiceTypeToCountMap.keySet()) {
	                this.InvoiceType = entityType;
	            }
	        }
	        
	        if(this.InvoiceType == 'Multiple') {
	            this.Description = 'View invoice for details';
	        } else if(this.InvoiceType == 'Deal') {
                for(CO_Invoice_Item__c invoiceItemRec : invoiceRec.CO_Invoice_Items__r) {
                    if(dealIdToUnitDescMap.containsKey(invoiceItemRec.Deal__c)) {
                        this.Description = dealIdToUnitDescMap.get(invoiceItemRec.Deal__c);
                        break;
                    }
                }
            } else if(this.InvoiceType == 'Deductible') {
	            this.Description = 'Claim deductible';
	        } else if(this.InvoiceType == 'Service') {
	            List<String> concernList = new List<String>();
	            for(CO_Invoice_Item__c invoiceItemRec : invoiceRec.CO_Invoice_Items__r) {
	                if(invoiceItemRec.Service_Order_Header__r.SO_Concern__c != null) {
	                    concernList.addAll(invoiceItemRec.Service_Order_Header__r.SO_Concern__c.split('\n'));
	                }
	                this.Description = String.join(concernList, ', ');
	            }
	        } else if(this.InvoiceType == 'Parts') {
	            List<String> codeList = new List<String>();
	            for(CO_Invoice_Item__c invoiceItemRec : invoiceRec.CO_Invoice_Items__r) {
	                if(invoiceItemRec.CO_Line_Item__c != null && invoiceItemRec.CO_Line_Item__r.Part__c != null) {
	                    codeList.add(invoiceItemRec.CO_Line_Item__r.Part__r.Part_Number__c);
	                } else if(invoiceItemRec.CO_Line_Item__c != null && invoiceItemRec.CO_Line_Item__r.Fee__c != null) {
	                    codeList.add(invoiceItemRec.CO_Line_Item__r.Fee__r.Code__c);
	                } else if(invoiceItemRec.CO_Kit_Header__c != null && invoiceItemRec.CO_Kit_Header__r.Kit_Header__r.Code__c != null) {
                        codeList.add(invoiceItemRec.CO_Kit_Header__r.Kit_Header__r.Code__c);
                    } 
	                this.Description = String.join(codeList, ', '); 
	            }
	        }
	    }
    }
}