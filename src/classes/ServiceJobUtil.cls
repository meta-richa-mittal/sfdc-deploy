/**
 * Author: Nidhi Sharma
 * Since: Nov. 30, 2022
 * Name: ServiceJobUtil
 * Description: utility class which holds service job related attributes/methods 
**/
public with sharing class ServiceJobUtil {
    
    public static final String ESTIMATE = 'Estimate';
    public static final String NEW_JOB = 'New job';
    public static final String TRIAGE_REQUIRED = 'Triage required';
    public static final String TRIAGE_DONE = 'Triage done';
    public static final String CUSTOMER_TO_OK = 'Customer to ok';
    public static final String CUSTOMER_APPROVED = 'Customer approved';
    public static final String READY_TO_START = 'Ready to start';
    public static final String IN_PROGRESS = 'In progress';
    public static final String WAIT_FOR_PARTS = 'Wait for parts';
    public static final String PART_MGR_REVIEW = 'PartMgr review';
    public static final String SERV_MGR_REVIEW = 'ServMgr review';
    public static final String JOB_COMPLETE = 'Job complete';
    public static final String READY_TO_INVOICE = 'Ready to invoice';
    public static final String INVOICED = 'Invoiced';
    public static final String COMPLETED = 'Completed';
    private static Map<String, SO_Status__c> soStatusToRecMap = new Map<String, SO_Status__c>();
    public static final Set<String> invoiceableStatusSet = new Set<String>{JOB_COMPLETE, READY_TO_INVOICE};

    public static Map<String, List<String>> jobStatusGroupToExcludedValueMap = new Map<String, List<String>> {
        'Open' => new List<String>{ESTIMATE, INVOICED},
        'Active' => new List<String>{ESTIMATE, NEW_JOB, JOB_COMPLETE, READY_TO_INVOICE, INVOICED},
        'All open jobs' => new List<String>{ESTIMATE, INVOICED}
    };
    
    public static List<String> getActiveSOStatusList() {
        if(soStatusToRecMap == null || soStatusToRecMap.isEmpty()) populateSOStatusMap();
        List<String> activeSOStatusList = new List<String>();
        for(SO_Status__c soStatusRec : soStatusToRecMap.values()) {
            if(soStatusRec.Is_Active__c) activeSOStatusList.add(soStatusRec.Name__c);
        }
        return activeSOStatusList;
    }

    public static List<ServiceJobStatusWrapper> getActiveSOStatusRecList() {
        if(soStatusToRecMap == null || soStatusToRecMap.isEmpty()) populateSOStatusMap();
        List<ServiceJobStatusWrapper> activeSOStatusRecList = new List<ServiceJobStatusWrapper>();
        for(SO_Status__c soStatusRec : soStatusToRecMap.values()) {
            if(soStatusRec.Is_Active__c) activeSOStatusRecList.add(new ServiceJobStatusWrapper(soStatusRec));
        }
        return activeSOStatusRecList;
    }

    public static List<String> getAllSOStatusList() {
        if(soStatusToRecMap == null || soStatusToRecMap.isEmpty()) populateSOStatusMap();
        List<String> allSOStatusList = new List<String>();
        for(SO_Status__c soStatusRec : soStatusToRecMap.values()) {
            allSOStatusList.add(soStatusRec.Name__c);
        }
        return allSOStatusList;
    }

    public static SO_Status__c getSOStatusConfigByName(String status) {
        if(String.isNotBlank(status)) {
            if(soStatusToRecMap == null || soStatusToRecMap.isEmpty()) populateSOStatusMap();
            if(soStatusToRecMap.get(status) != null) return soStatusToRecMap.get(status);
        }
        return new SO_Status__c();
    }

    private static void populateSOStatusMap() {
        if(AccessControl.ifObjectFieldIsAccessible('SO_Status__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        for(SO_Status__c soStatusRec : [Select Id, Name__c, Short_Name__c, Order_No__c, Is_Active__c, Is_Required__c, Text_Color__c, Background_Color__c, Default_Clock_ON_Status__c FROM SO_Status__c WHERE Name__c != null ORDER BY Order_No__c]) {
            soStatusToRecMap.put(soStatusRec.Name__c, soStatusRec);
        }
	}
    
    public static Boolean isJobComplete(String workStatus) {
        return String.isNotBlank(workStatus) && invoiceableStatusSet.contains(workStatus);
    }

    public static Boolean isReadyToCheckout(String workStatus) {
        return String.isNotBlank(workStatus) && workStatus == READY_TO_INVOICE || 
        (!GeneralConfiguration.getConfigurations().Is_Ready_To_Invoice_Required_To_Finalize__c && workStatus == JOB_COMPLETE);
    }
    
    public static Id getApplicableTaxOnSOLI(Service_Order_Line_Item__c soliRec) {
        Id applicableTaxId;
        if(soliRec != null && isEntityTaxable(soliRec)) {
            String entityName = getEntityName(soliRec);
            if(!GeneralConfiguration.getConfigurations().Tax_Included_Pricing__c && soliRec.Service_Order_Header__c != null && 
            soliRec.Service_Order_Header__r.Deal__c == null && 
            soliRec.Service_Order_Header__r.Transaction_Type__c != null && 
            soliRec.Service_Order_Header__r.Transaction_Type__r.Type__c != null && 
            soliRec.Service_Order_Header__r.Transaction_Type__r.Type__c.equalsIgnoreCase('Customer') && 
            soliRec.Service_Order_Header__r.Is_Override_Tax__c && 
            soliRec.Service_Order_Header__r.Override_Tax_Applicable_On__c != null && 
            entityName != null && soliRec.Service_Order_Header__r.Override_Tax_Applicable_On__c.contains(entityName)) {
                applicableTaxId = soliRec.Service_Order_Header__r.Applicable_Tax__c;
            } else {
                if(soliRec.Service_Order_Header__r.Job_Type__c == 'Internal') {
                    applicableTaxId = GeneralConfiguration.getConfigurations().Default_Sales_Tax_on_Internal_Service__c;
                }
                if(String.isBlank(applicableTaxId)) {
                    applicableTaxId = getApplicableTaxOnEntity(soliRec);
                }
            }
        }
        return applicableTaxId;
	}

	public static Id getApplicableTaxOnEntity(Service_Order_Line_Item__c soliRec) {
		Id applicableTaxId;
        if(soliRec.Part__c != null && soliRec.Part__r.Taxable__c) {
            applicableTaxId = soliRec.Part__r.Applicable_Tax__c;
        } else if(soliRec.Fee__c != null && soliRec.Fee__r.Taxable__c) {
            applicableTaxId = soliRec.Fee__r.Applicable_Tax__c;
        } else if(soliRec.Labour_Code__c != null && soliRec.Labour_Code__r.Taxable__c) {
            applicableTaxId = soliRec.Labour_Code__r.Applicable_Tax__c;
        } else if(soliRec.Sublet__c != null && soliRec.Sublet__r.Taxable__c) {
            applicableTaxId = soliRec.Sublet__r.Applicable_Tax__c;
        }
		return applicableTaxId;
	}

    private static Boolean isEntityTaxable(Service_Order_Line_Item__c soliRec) {
        return ((soliRec.Part__c != null && soliRec.Part__r.Taxable__c) || 
            (soliRec.Fee__c != null && soliRec.Fee__r.Taxable__c) || 
            (soliRec.Labour_Code__c != null && soliRec.Labour_Code__r.Taxable__c) || 
            (soliRec.Sublet__c != null && soliRec.Sublet__r.Taxable__c));
    }

	private static String getEntityName(Service_Order_Line_Item__c soliRec) {
		if(soliRec != null) {
			if(soliRec.Part__c != null) return DealUtil.UNIT_TAX_APPLICABLE_ON_PARTS;
            if(soliRec.Fee__c != null) return DealUtil.UNIT_TAX_APPLICABLE_ON_FEES;
			if(soliRec.Labour_Code__c != null) return DealUtil.UNIT_TAX_APPLICABLE_ON_LABOR;
			if(soliRec.Sublet__c != null) return DealUtil.UNIT_TAX_APPLICABLE_ON_SUBLET;
		}
		return null;
	}
}