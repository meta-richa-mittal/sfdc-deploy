/** 
* Author: Richa Mittal
* Since: Dec 12, 2019
* Name: HondaServiceDataBatch 
* Description: Batch class to send information about invoiced service jobs to honda server.
**/
global without sharing class HondaServiceDataBatch implements Database.Batchable<sobject>, Database.Stateful, Database.AllowsCallouts, Schedulable {
	global List<Service_Order_Header__c> soHeaderListToUpdate;
	
    global Database.QueryLocator start(Database.BatchableContext bc) {
    	soHeaderListToUpdate = new List<Service_Order_Header__c>();
        String strQuery = 'SELECT Invoice_Number__r.Invoice_Number__c, Customer_Owned_Unit__r.VIN_Number_Formula__c, Customer_Owned_Unit__r.Engine_Serial_No__c, Job_Type__c, ' + 
        					'Odometer_on_Departure__c, Invoice_Number__r.Invoice_Date__c, Hrs_Billed__c, Total_Parts__c, Transaction_Type__r.Type__c FROM Service_Order_Header__c ' + 
                            'WHERE Invoice_Number__c != null AND Invoice_Number__r.Invoice_Status__c = \'Closed\' AND Is_Uploaded_to_Honda__c = false Order By Name ASC';
        return Database.getQueryLocator(strQuery);
    }
    
    global void execute(Database.batchableContext bc, List<Service_Order_Header__c> soHeaderList) {
        if(HondaUtility.isHondaIntegrationEnabled()) {
            HondaServiceData serviceDataObj = new HondaServiceData(soHeaderList);
            HttpResponse response = HondaUtility.doCallout('Honda Service Data', System.JSON.serialize(new Map<String, List<HondaServiceData>>{'Dealers' => new List<HondaServiceData>{serviceDataObj}}, true));
            handleResponse(response, soHeaderList, soHeaderListToUpdate);
        }
    }
    
    global void finish(Database.batchableContext bc) {
    	updateSOHeaders(soHeaderListToUpdate);
    }
    
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new HondaServiceDataBatch());
    }
    
    private static void updateSOHeaders(List<Service_Order_Header__c> soHeaderListToUpdate) {
    	if(AccessControl.ifObjectFieldIsUpdateable('Service_Order_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
    	if(soHeaderListToUpdate != null && soHeaderListToUpdate.size() > 0) {
    		update soHeaderListToUpdate;
    	}
    }
    
    private static void handleResponse(HttpResponse response, List<Service_Order_Header__c> soHeaderList, List<Service_Order_Header__c> soHeaderListToUpdate) {
    	system.debug('response' + '\n' + response.getStatusCode() + '\n' + response.getBody());
    	if(response.getStatusCode() == 200 && response.getBody() == '"Create repair order successfully."') {
    		for(Service_Order_Header__c soHeaderRec: soHeaderList) {
    			soHeaderRec.Is_Uploaded_to_Honda__c = true;
    			soHeaderListToUpdate.add(soHeaderRec);
    		}
    	}
    }
}