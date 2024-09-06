/** 
* Author: Manoj Sharma
* Since: Nov 10, 2021 
* Name: CustomerOrderUtil 
* Description: Apex class which contains utility methods related to Customer Order.
**/
public without sharing class CustomerOrderUtil {
    public static Final String CHANGE_CUSTOMER_ERROR_INVOICE_GENERATED = 'An invoice has been generated from the CO.';
	public static Final String CHANGE_CUSTOMER_ERROR_AR_CREDIT_PAYMENT = 'AR credit payments have been made.';
	public static Final String CHANGE_CUSTOMER_ERROR_AR_CREDIT_DEPOSIT = 'AR credit deposits have been made.';
    public static Final String CHANGE_CUSTOMER_ERROR_STORE_CREDIT_PAYMENT = 'Active store credit payments have been made. You must reverse the credit payment before changing the customer.';
    public static Final String CHANGE_CUSTOMER_ERROR_STORE_CREDIT_DEPOSIT = 'Active store credit deposits have been made. You must reverse the credit deposit before changing the customer.';
    public static Final String CHANGE_CUSTOMER_ERROR_COMPLETED_SERVICE_JOB = 'CO contains a service job that has a Completed status.';
	public static Final String CHANGE_CUSTOMER_ERROR_SERVICE_JOB = 'CO contains Service Jobs.';
	public static Final String CHANGE_CUSTOMER_ERROR_APPROVED_DEAL = 'CO contains a deal that has an Approved status.';
	public static Final String CHANGE_CUSTOMER_ERROR_DEAL = 'CO contains Deal.';
	public static Final String CHANGE_CUSTOMER_ERROR_STOCKED_IN_TRADE_IN = 'Deal contains a trade-in which has already been stocked in.';
    public static Final String CHANGE_CUSTOMER_ERROR_SPECIAL_ORDER = 'CO contains special order lines in the Merch section.';
}
