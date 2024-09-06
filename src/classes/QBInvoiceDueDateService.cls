public without sharing class QBInvoiceDueDateService {
    
    public static Date getVendorInvoiceDueDate(Date invoiceDate, String vendorAccountingId, IFW_IntegrationConfig__c integrationConfigRec, List<QB_Term__c> qbTermsList) {
        Date dueDate = invoiceDate;
        String termQBId = getVendorPaymentTerm(vendorAccountingId, integrationConfigRec);
        if(String.isBlank(termQBId)) {
            termQBId = getQBPreferenceDefaultPaymentTerm(integrationConfigRec);
        }
        if(String.isNotBlank(termQBId)) {
            dueDate = getDueDate(invoiceDate, termQBId, integrationConfigRec, qbTermsList);
        }
        return dueDate;
    }
    
    public static String getVendorPaymentTerm(String vendorAccountingId, IFW_IntegrationConfig__c integrationConfigRec) {
        if(String.isBlank(vendorAccountingId)) throw new BlackpurlException('Vendor is not synced to ' + QBUtil.QUICKBOOKS_ONLINE + '.');
        
        QBResponseWrapper resObj = QBCalloutManager.getDataByQBId('vendor', vendorAccountingId, integrationConfigRec);
        if(resObj != null && resObj.Vendor != null && resObj.Vendor.TermRef != null) {
            return resObj.Vendor.TermRef.value;
        }
        return null;
    }

    public static String getQBPreferenceDefaultPaymentTerm(IFW_IntegrationConfig__c integrationConfigRec) {
        QBResponseWrapper resObj = QBCalloutManager.getDataByQBId(QBUtil.PREFERENCES, null, integrationConfigRec);
        if(resObj != null && resObj.Preferences != null && resObj.Preferences.VendorAndPurchasesPrefs != null && 
            resObj.Preferences.VendorAndPurchasesPrefs.DefaultTerms != null) {
            return resObj.Preferences.VendorAndPurchasesPrefs.DefaultTerms.value;
        }
        return null;
    }

    public static Date getCustomerInvoiceDueDate(Date invoiceDate, String customerAccountingId, IFW_IntegrationConfig__c integrationConfigRec, List<QB_Term__c> qbTermsList) {
        Date dueDate = invoiceDate;
        String termQBId = getCustomerPaymentTerm(customerAccountingId, integrationConfigRec);
        if(String.isBlank(termQBId)) {
            termQBId = getQBPreferenceDefaultSalesPaymentTerm(integrationConfigRec);
        }
        if(String.isNotBlank(termQBId)) {
            dueDate = getDueDate(invoiceDate, termQBId, integrationConfigRec, qbTermsList);
        }
        return dueDate;
    }
    
    public static String getCustomerPaymentTerm(String customerAccountingId, IFW_IntegrationConfig__c integrationConfigRec) {
        if(String.isBlank(customerAccountingId)) throw new BlackpurlException('Customer is not synced to ' + QBUtil.QUICKBOOKS_ONLINE + '.');
        
        QBResponseWrapper resObj = QBCalloutManager.getDataByQBId('customer', customerAccountingId, integrationConfigRec);
        if(resObj != null && resObj.Customer != null && resObj.Customer.SalesTermRef != null) {
            return resObj.Customer.SalesTermRef.value;
        }
        return null;
    }

    public static String getQBPreferenceDefaultSalesPaymentTerm(IFW_IntegrationConfig__c integrationConfigRec) {
        QBResponseWrapper resObj = QBCalloutManager.getDataByQBId(QBUtil.PREFERENCES, null, integrationConfigRec);
        if(resObj != null && resObj.Preferences != null && resObj.Preferences.SalesFormsPrefs != null && 
            resObj.Preferences.SalesFormsPrefs.DefaultTerms != null) {
            return resObj.Preferences.SalesFormsPrefs.DefaultTerms.value;
        }
        return null;
    }
    
    public static Date getDueDate(Date invoiceDate, String termQBId, IFW_IntegrationConfig__c integrationConfigRec, List<QB_Term__c> qbTermsListInsert) {
        Date dueDate = invoiceDate;
        try {
	        List<QB_Term__c> qbTermList = [SELECT Day_of_Month_Due__c, Due_Days__c, Due_Next_Month_Days__c, Type__c FROM QB_Term__c 
	                                           WHERE Accounting_Id__c =: termQBId];
            if(qbTermList.isEmpty()) {
                if(qbTermsListInsert.isEmpty()) {
                    qbTermsListInsert.addAll(QBTermService.pullTerms(integrationConfigRec));
                }
                for(QB_Term__c qbTermRec : qbTermsListInsert) {
                    if(qbTermRec.Accounting_Id__c == termQBId) {
                        qbTermList.add(qbTermRec);
                        break;
                    }
                }
            }
	        if(qbTermList.size() > 0) {
	            QB_Term__c qbTermRec = qbTermList[0];
	            if(qbTermRec.Type__c == 'STANDARD' && qbTermRec.Due_Days__c != null) {
		            dueDate = invoiceDate.addDays(Integer.valueOf(qbTermRec.Due_Days__c));
		        } else if(qbTermRec.Type__c == 'DATE_DRIVEN') {
		            Integer invoiceDateMonth = invoiceDate.month();
		            Integer invoiceDateDay = invoiceDate.day();
		            Integer dayOfMonthDue = (qbTermRec.Day_of_Month_Due__c != null) ? Integer.valueOf(qbTermRec.Day_of_Month_Due__c) : null;
		            Integer dueNextMonthDays = (qbTermRec.Due_Next_Month_Days__c != null) ? Integer.valueOf(qbTermRec.Due_Next_Month_Days__c) : null;
		            
		            if(dayOfMonthDue != null && invoiceDateDay > dayOfMonthDue) {
		                dueDate = invoiceDate.toStartOfMonth().addMonths(1).addDays(dayOfMonthDue - 1);
		            } else if(dueNextMonthDays != null && dayOfMonthDue != null && invoiceDateDay + dueNextMonthDays <= dayOfMonthDue) {
		                dueDate = invoiceDate.addDays(dayOfMonthDue - invoiceDateDay);
		            } else if(dayOfMonthDue != null) {
		                dueDate = invoiceDate.toStartOfMonth().addMonths(1).addDays(dayOfMonthDue - 1);
		            }
		        }
	        }
        } catch(Exception e) {
        }
        return dueDate;
    }
}