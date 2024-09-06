@RestResource(urlMapping = '/YamahaPartUpdate/*')
global without sharing class YamahaPartUpdateRestAPI {
     
    @HttpPost
    global static ResponseWrapper doPost() {
        String body;
        try {
            body = RestContext.request.requestBody.toString();
	        List<YamahaPartWrapper> partObjList = (List<YamahaPartWrapper>) System.JSON.deserialize(body, List<YamahaPartWrapper>.class);
            
            if(partObjList.size() > 0 && partObjList[0].partNumber != 'Aw0YFC9n3fgXlIVpKyzbGh_mGVOOg2-DuMIBWdXVmCXnfZzF') {
                return new ResponseWrapper(500, 'Private Key not matched');
            }
            partObjList.remove(0);
            
            Set<String> partNumberSet = new Set<String>();
	        Map<String, Decimal> partNumberToQtyMap = new Map<String, Decimal>();
	        for(YamahaPartWrapper partObj : partObjList) {
	            partNumberSet.add(partObj.partNumber);
	            partNumberToQtyMap.put(partObj.partNumber, partObj.qty);
	        }

            List<Part__c> partList = getPartList(partNumberSet);
	        for(Part__c partRec : partList) {
	            if(partNumberToQtyMap.containsKey(partRec.Part_Number__c)) {
	                partRec.Cassons_SOH__c = partNumberToQtyMap.get(partRec.Part_Number__c);
	            }
	        }
	        PartTriggerHelper.isForceStopTrigger = true;
            DMLUtility.updateSobjectListWithRetry(partList);
            PartTriggerHelper.isForceStopTrigger = false;
            return new ResponseWrapper(200, 'Parts updated successfully');
            
        } catch(Exception e) {
            new LogService().createErrorLog('YamahaPartUpdateRestAPI', 'doPost()', e.getMessage(), null, e.getStackTraceString(), body, 'Yamaha', true, 'error');
            return new ResponseWrapper(500, e.getMessage());
        }
    }
    
    public static List<Part__c> getPartList(Set<String> partNumberSet) {
        String vendorCode = BP_Configurations__c.getOrgDefaults().Yamaha_Vendor_Code__c;
        return [SELECT Cassons_SOH__c, Part_Number__c FROM Part__c WHERE Part_Number__c IN: partNumberSet AND Vendor_Code__c =: vendorCode 
                        limit: SOQLUtility.getAvailableQueryRowsLimit()];
    }

    private class YamahaPartWrapper {
        public String partNumber;
        public Decimal qty;
    }
    
    global class ResponseWrapper {
	    public String response;
	    public Integer responseCode;
	    
	    public ResponseWrapper(Integer responseCode, String response) {
	        this.responseCode = responseCode;
	        this.response = response;
	    }
    }
}