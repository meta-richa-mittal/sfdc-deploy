/**
 * Author: Nidhi Sharma
 * Since: April 22, 2021
 * Name: COARestrictionConfigTriggerHelper
 * Description: Trigger helper class
**/
public without sharing class COARestrictionConfigTriggerHelper {
    
    public static void afterInsert() {
    	AccountingUtil.validateChartOnAccounts();
    }
    
    public static void afterUpdate() {
    	AccountingUtil.validateChartOnAccounts();
    }
    
    public static void afterDelete() {
    	AccountingUtil.validateChartOnAccounts();
    }
    
    public static void afterUndelete() {
    	AccountingUtil.validateChartOnAccounts();
    }
}