/**
 * Author: Richa Mittal
 * Since: March 16, 2022
 * Name: BPScriptManager
 * Description: Apex class for all scripts executed after package installation
**/
global without sharing class BPScriptManager implements Callable {
    
    global static void createCustomerDepositsSpecialCategory() {
        if(AccessControl.ifObjectFieldIsAccessible('Category__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<Category__c> defaultCategoryList = [SELECT Id, Type__c FROM Category__c WHERE Default__c = true AND Active__c = true AND Type__c = 'Customer Deposits'];
        
        if(defaultCategoryList.size() == 0) {
            DMLUtility.insertSobjectList('Category__c', new Category__c(Name = 'Customer Deposits Default', Description__c = 'Customer Deposits Default',
                                    Type__c = 'Customer Deposits', Default__c = true, Active__c = true, 
                                                                        Income_GL__c = Accounting_Default_Accounts__c.getOrgDefaults().Customer_Deposits__c));
        }
    }

    global static void executePopulatePartTypeFieldOnPartV2Batch() {
        Database.executeBatch(new PopulatePartTypeFieldOnPartV2Batch());
    }
    
	global static void enableHomePageDashboardPermissionForAllGroup() {
        setSpecifiedPermissionForAllGroup(new Map<String, String>{'Homepage_Dashboards__c' => 'Primary'}, true);
    }

    global static void disableAccSettingExportPermissionForAllGroup() {
        setSpecifiedPermissionForAllGroup(new Map<String, String>{'Accounting_settings_export__c' => 'None'}, false);
    }

    global static void enableReportAndWorkshopDashboardPermissionForAllGroup() {
        setSpecifiedPermissionForAllGroup(new Map<String, String>{'Reports__c' => 'Primary', 'Workshop_Dashboard__c' => 'Primary'}, true);
    }

    // isNewPermission - this flag is used to enable newly added permissions and used to avoid the permission overwirting.  
    global static void setSpecifiedPermissionForAllGroup(Map<String, String> permissionNameToValueMap, Boolean isNewPermission) {
    	String query = 'SELECT Id FROM User_Group__c ';
        Boolean isWhereClause = false;
    	if(permissionNameToValueMap != null && isNewPermission) {
	    	for(String permissionName : permissionNameToValueMap.keySet()) {
                if(isWhereClause) {
                    query += ' AND ' + permissionName + ' = null ';
                } else {
                    query += ' Where ' + permissionName + ' = null ';
                    isWhereClause = true;
                }
	    	}
    	}
    	List<User_Group__c> userGroupList = Database.query(query);
        if(userGroupList.size() > 0) {
            for(User_Group__c userGroupRec : userGroupList) {
                for(String permissionName : permissionNameToValueMap.keySet()) {
                    userGroupRec.put(permissionName, permissionNameToValueMap.get(permissionName));
                }
            }
            update userGroupList;
        }
    }
    
    global static void populateCashDrawerOnCashRoundingPayments() {
        List<CO_Invoice_Payment__c> paymentList = SOQLUtility.getQueryResults('CO_Invoice_Payment__c', 'Select Id, Cash_Rounding_Payment__r.Cash_Drawer__c FROM CO_Invoice_Payment__c WHERE Payment_Method__c = \'Cash Rounding\' AND Cash_Drawer__c = null AND Cash_Rounding_Payment__r.Cash_Drawer__c != null');
        for(CO_Invoice_Payment__c paymentRec : paymentList) {
            paymentRec.Cash_Drawer__c = paymentRec.Cash_Rounding_Payment__r.Cash_Drawer__c;
        }
        DMLUtility.updateSObjectList('CO_Invoice_Payment__c', paymentList);
    }

    /**
     * Callable::call() implementation, calling static function
     * It is best to keep the naming consistent with the original method signature, no error checking is made for simplicity:
     * call() expects an object to be returned, null is returned for void function, other types can be used as needed:
     */
    public Object call(String action, Map<String, Object> args) {
        switch on action {
            when 'createCustomerDepositsSpecialCategory()' {
                createCustomerDepositsSpecialCategory();
                return null;
            }
            when 'executePopulatePartTypeFieldOnPartV2Batch()' {
                executePopulatePartTypeFieldOnPartV2Batch();
                return null;
            }
            when 'disableAccSettingExportPermissionForAllGroup()' {
                disableAccSettingExportPermissionForAllGroup();
                return null;
            }
			when 'enableHomePageDashboardPermissionForAllGroup()' {
                enableHomePageDashboardPermissionForAllGroup();
                return null;
            }
            when 'enableReportAndWorkshopDashboardPermissionForAllGroup()' {
                enableReportAndWorkshopDashboardPermissionForAllGroup();
                return null;
            }
            when 'populateCashDrawerOnCashRoundingPayments()' {
                populateCashDrawerOnCashRoundingPayments();
                return null;
            }

            when else {
                throw new BlackPurlException('Method not implemented');
            }
        }
    }
}