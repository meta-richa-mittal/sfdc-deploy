/**
 * Author: Nidhi Sharma
 * Since: Sept 16, 2024
 * Name: MergeCustomerService
**/
public without sharing class MergeCustomerService {
    
    public static Map<String, Integer> getCustomerRelatedRecordsSummary(String customerId) {
        Map<String, Integer> sobjNameToRecCountMap = new Map<String, Integer>();
        if(String.isNotBlank(customerId)) {
            Map<String, List<String>> childObjectToAccountFieldNameMap = getChildObjectToAccountFieldNameMap();
            for(String childObjectName : childObjectToAccountFieldNameMap.keySet()) {
                if(!childObjectToAccountFieldNameMap.get(childObjectName).isEmpty()) {
                    Schema.SObjectType sobjectType = Schema.getGlobalDescribe().get(childObjectName);
                    String pluralLabel = sobjectType.getDescribe().getLabelPlural();

                    List<String> whereClauses = new List<String>();
                    for(String fieldName : childObjectToAccountFieldNameMap.get(childObjectName)) {
                        whereClauses.add(fieldName + ' = \'' + customerId + '\'');
                    }
                    String query = 'Select COUNT() FROM ' + childObjectName + ' WHERE ' + String.join(whereClauses, ' OR ');
                    sobjNameToRecCountMap.put(pluralLabel, Database.countQuery(query));
                }
            }
        }
        return sobjNameToRecCountMap;
    }

    public static void mergeCustomers(String mergeCustJson) {
        if(String.isNotBlank(mergeCustJson)) {
            MergeCustomerWrapper mergeObj = (MergeCustomerWrapper) System.JSON.deserialize(mergeCustJson, MergeCustomerWrapper.class);
            if(mergeObj.KeepCustomerId != null && mergeObj.MergeCustomerId != null && mergeObj.KeepCustomerId != mergeObj.MergeCustomerId) {
                
                Map<String, List<String>> childObjectToAccountFieldNameMap = getChildObjectToAccountFieldNameMap();
                List<Sobject> sobjRecListToUpdate = new List<Sobject>();

                Set<String> childRecordsObjectNamesSet = new Set<String>(); 
                for(String childObjectName : childObjectToAccountFieldNameMap.keySet()) {
                    if(!childObjectToAccountFieldNameMap.get(childObjectName).isEmpty()) {
                        List<String> whereClauses = new List<String>();
                        for(String fieldName : childObjectToAccountFieldNameMap.get(childObjectName)) {
                            whereClauses.add(fieldName + ' = \'' + mergeObj.MergeCustomerId + '\'');
                        }
                        String query = 'Select ' + String.join(childObjectToAccountFieldNameMap.get(childObjectName), ', ') + ' FROM ' + childObjectName + ' WHERE ' + String.join(whereClauses, ' OR ');
                        for(SObject sobjRec : Database.query(query)) {
                            for(String fieldName : childObjectToAccountFieldNameMap.get(childObjectName)) {
                                if(sobjRec.get(fieldName) != null && String.valueOf(sobjRec.get(fieldName)) == mergeObj.MergeCustomerId) {
                                    sobjRec.put(fieldName, mergeObj.KeepCustomerId);
                                }
                            }
                            sobjRecListToUpdate.add(sobjRec);
                            childRecordsObjectNamesSet.add(childObjectName);
                        }
                        if(Math.Mod(childRecordsObjectNamesSet.size(), 10) == 0) {
                            updateChildRecords(sobjRecListToUpdate);
                        }
                    }
                }
                updateChildRecords(sobjRecListToUpdate);
                CustomerTriggerHelper.isBypassValidation = true;
                DMLUtility.updateSObjectList('Account', new Account(Id = mergeObj.MergeCustomerId, Active__c = false));
                CustomerTriggerHelper.isBypassValidation = false;
            }
        }
    }

    private static void updateChildRecords(List<Sobject> sobjRecListToUpdate) {
        if(!sobjRecListToUpdate.isEmpty()) {
            COTriggerHelper.isForceStopTrigger = CustomerOwnedUnitTriggerHelper.isForceStopTrigger = PaymentOnAccountTriggerHelper.isForceStopTrigger = true;
            update sobjRecListToUpdate;
            sobjRecListToUpdate = new List<Sobject>();
            COTriggerHelper.isForceStopTrigger = CustomerOwnedUnitTriggerHelper.isForceStopTrigger = PaymentOnAccountTriggerHelper.isForceStopTrigger = false;
        }
    }

    private static Map<String, List<String>> getChildObjectToAccountFieldNameMap() {
        Map<String, List<String>> childObjectToAccountFieldNameMap = new Map<String, List<String>>();

        Schema.DescribeSObjectResult accountDescribe = Account.SObjectType.getDescribe();
        List<Schema.ChildRelationship> childRelationships = accountDescribe.getChildRelationships();

        for(Schema.ChildRelationship childRel : childRelationships) {
            String childObjectName = childRel.getChildSObject().toString();
            String fieldName = childRel.getField().getDescribe().getName();

            String childObjectNameWithoutNamespace = childObjectName.substringAfter(Constants.Namespace).toUpperCase();
            String fieldNameWithoutNamespace = fieldName.substringAfter(Constants.Namespace).toUpperCase();

            if(excludedObjectToFieldsMap.containsKey(childObjectNameWithoutNamespace) &&
            (excludedObjectToFieldsMap.get(childObjectNameWithoutNamespace).isEmpty() || excludedObjectToFieldsMap.get(childObjectNameWithoutNamespace).contains(fieldNameWithoutNamespace))) {
                continue;
            } else if(childObjectName.contains('__c') || childObjectName.equalsIgnoreCase('Contact')) {
                if(!childObjectToAccountFieldNameMap.containsKey(childObjectName)) {
                    childObjectToAccountFieldNameMap.put(childObjectName, new List<String>());
                }
                childObjectToAccountFieldNameMap.get(childObjectName).add(fieldName);
            }
        }
        return childObjectToAccountFieldNameMap;
    }

    public static CustomerWrapper getCustomerDetailsById(String accountId) {
        for(Account accRec : [Select Id, Name, Customer_Number__c, Is_Customer__c, Is_Vendor__c,
        Preferred_Email__c, Email__c, Other_Email__c, Work_Email__c,
        Preferred_Phone__c, Home_Number__c, Mobile__c, Work_Number__c, Formatted_Preferred_Phone__c,Formatted_Home_number__c,Formatted_Mobile_Number__c,Formatted_Work_Number__c,
        BillingStreet,BillingCity,BillingState,BillingCountry,BillingPostalCode FROM Account WHERE Id =: accountId LIMIT 1]) {
            return new CustomerWrapper(accRec);
        }
        return new CustomerWrapper(null);
    }

    public class CustomerWrapper {
        public Id Id;
        public String Email;
        public String CustomerName;
        public String CustomerNumber;
        public String Phone;
        public String BillingAddress;

        public CustomerWrapper(Account accRec) {
            if(accRec != null) {
                this.Id = accRec.Id;
                this.CustomerName = accRec.Name;
                this.CustomerNumber = accRec.Customer_Number__c;
                if(accRec.Preferred_Email__c == null) {
                    if(accRec.Email__c != null) {
                        this.Email = accRec.Email__c;
                    } else if(accRec.Work_Email__c != null) {
                        this.Email = accRec.Work_Email__c;
                    } else if(accRec.Other_Email__c != null) {
                        this.Email = accRec.Other_Email__c;
                    }
                } else {
                    this.Email = accRec.Preferred_Email__c;
                }
                if(accRec.Preferred_Phone__c == null) {
                    if(accRec.Home_Number__c != null) {
                        this.Phone = accRec.Formatted_Home_number__c;
                    } else if(accRec.Mobile__c != null) {
                        this.Phone = accRec.Formatted_Mobile_Number__c;
                    } else if(accRec.Work_Number__c != null) {
                        this.Phone = accRec.Formatted_Work_Number__c;
                    }
                } else {
                    this.Phone = accRec.Formatted_Preferred_Phone__c;
                }
                List<String> bsList = ((accRec.BillingStreet == null ) ? '' : accRec.BillingStreet).split('\n');
                String billingStreet1 = (bsList.size() > 0) ? bsList[0] : '';
                String billingStreet2 = (bsList.size() > 1) ? bsList[1] : '';

                List<String> addressPartList = new List<String>();
                if(String.isNotBlank(billingStreet1)) addressPartList.add(billingStreet1);
                if(String.isNotBlank(billingStreet2)) addressPartList.add(billingStreet2);
                if(String.isNotBlank(accRec.BillingCity)) addressPartList.add(accRec.BillingCity);
                if(String.isNotBlank(accRec.BillingState)) addressPartList.add(accRec.BillingState);
                if(String.isNotBlank(accRec.BillingCountry)) addressPartList.add(accRec.BillingCountry);
                if(String.isNotBlank(accRec.BillingPostalCode)) addressPartList.add(accRec.BillingPostalCode);
                this.BillingAddress = String.join(addressPartList, ', ');
            }
        }
    }

    public class MergeCustomerWrapper {
        public Id KeepCustomerId;
        public Id MergeCustomerId;
    }

    private static Map<String, Set<String>> excludedObjectToFieldsMap = new Map<String, Set<String>>{
        'ESCALATOR__C' => new Set<String>(),
        'PO_TYPE__C' => new Set<String>(),
        'DEAL_ITEM__C' => new Set<String>(),
        'GE_FILE_CONFIG__C' => new Set<String>(),
        'PART__C' => new Set<String>(),
        'PRICE_FILE_ERROR_LOG__C' => new Set<String>(),
        'PRODUCT__C' => new Set<String>(),
        'RETURN_CR_HEADER__C' => new Set<String>(),
        'RETURN_VO_HEADER__C' => new Set<String>(),
        'SERVICE_ORDER_HEADER__C' => new Set<String>(),
        'TAX_EXEMPTION__C' => new Set<String>(),
        'TRANSACTION_TYPE__C' => new Set<String>(),
        'UNIT_PRICE_COST__C' => new Set<String>{'VENDOR__C'},
        'CUSTOMER_OWNED_UNIT__C' => new Set<String>{'VENDOR__C'},
        'DEAL_FINANCE__C' => new Set<String>(),
        'UNIT_PRICE_COST__C' => new Set<String>{'VENDOR__C'},
        'VENDOR_INVOICING_HEADER__C' => new Set<String>(),
        'VENDOR_MASTER__C' => new Set<String>(),
        'VENDOR_ORDER_HEADER__C' => new Set<String>(),
        'VENDOR_RECEIVING_HEADER__C' => new Set<String>()
    };
}