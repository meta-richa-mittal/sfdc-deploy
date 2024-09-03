/**
 * Author: Manoj Sharma
 * Since: Aug 01, 2023
 * Name: InvoiceDetailReportService
 * Description: service class which have methods related to invoice detail report.
 * 
**/
public without sharing class InvoiceDetailReportService {
    public static Set<Id> getSpecificDateRangeInvoiceIds(String filterJSON) {
        HomeSearchFilterWrapper filterWrapperObj = (HomeSearchFilterWrapper) System.JSON.deserialize(filterJSON, HomeSearchFilterWrapper.class);
    	Set<Id> invoiceIdSet = new Set<Id>();
        if(filterWrapperObj.Customer_Invoice_Detail_Invoice_Date != null && String.isNotBlank(filterWrapperObj.Customer_Invoice_Detail_Invoice_Date.SelectedOption)) {
            List<HomeSearchFilterInterface.FieldFilter> filterList = HomeSearchFilterInterface.getDateFilter(filterWrapperObj.Customer_Invoice_Detail_Invoice_Date, 'Invoice_Date__c', true, true);
            if(!filterList.isEmpty()) {
                String query = ' Select Id From CO_Invoice_Header__c ';
                query += HomeSearchReportInterface.getWhereClause('Invoice_Date__c', filterList, null);
                invoiceIdSet = (new Map<Id, CO_Invoice_Header__c>((List<CO_Invoice_Header__c>)Database.query(query))).keySet();
            }
        }
        return invoiceIdSet;
    }
}