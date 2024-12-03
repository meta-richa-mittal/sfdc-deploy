public without sharing class BRPPartInventoryService {

    public Static String getPartInventory(String partId, Integer qty) {
        String responseStr, reponseBody;
        List<Part__c> partList = [SELECT Part_Number__c, Description__c FROM Part__c WHERE Id =: partId];
        if(!partList.isEmpty()) {
            try {
                Map<String, String> endPointPathParamMap = new Map<String, String>{ '{{product_code}}' =>  partList[0].Part_Number__c};
                Map<String, String> parametersMap = getAPIParamMap(qty);
                HttpResponse response = BRPUtility.syncToBRP(BRPUtility.PART_INVENTORY, null, 'GET', parametersMap, endPointPathParamMap);
                reponseBody = response.getBody();

                if(response.getStatusCode() == 200) {
                    BRPPartLocatorWrapper partLocatorObj = new BRPPartLocatorWrapper();
                    PartInventoryWrappper apiResObj = (PartInventoryWrappper) System.JSON.deserialize(reponseBody, PartInventoryWrappper.class);
                    partLocatorObj = parseResponse(apiResObj, partList[0]);
                    if(partLocatorObj == null) {
                        partLocatorObj = populateDefaultField(partLocatorObj, partList[0]);
                    }
                    responseStr = system.JSON.serialize(partLocatorObj);
                } else {
                    responseStr = system.JSON.serialize(new ResponseWrapper(400, parseErrorResonse(response)));
                }
            } catch (Exception e) {
                throw new BlackPurlException(BRPUtility.BRP_ERROR_STRING + BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()) + ' :: ' + reponseBody);
            }
        } else {
            responseStr = system.JSON.serialize(new ResponseWrapper(400, 'Invalid part number'));
        }
        return responseStr;
    }

    private static String parseErrorResonse(HttpResponse response) {
        return getErrorMessage(response);
    }

    private static String getErrorMessage(HttpResponse response) {
        String errorResponseStr = response.getBody().toString();
        String errorStr = 'Some Error occured When fetching the details from BRP.';
        if(response.getStatusCode() == 400 && errorResponseStr.contains('Invalid Product')) {
            errorStr = 'This part number does not exist';
        }else if(errorResponseStr.contains('Discontinued')) {
            errorStr = 'Product code has been discontinued.';
        } else if(errorResponseStr.contains('Not Authorized')) {
            errorStr = 'Not a valid part for your authorized product lines.';
        } else if(errorResponseStr.contains('request validation failed')) {
            errorStr = 'Part request validation failed.';
        } else if(errorResponseStr.contains('not found')) {
            errorStr = 'Dealer Number not found.';
        } else if(errorResponseStr.contains('Invalid Product')) {
            errorStr = 'Material number does not exist.';
        }  else if(errorResponseStr.contains('access_token')) {
            errorStr = 'Access token expired.';
        } 
        return errorStr;
    }

    private static Map<String, String> getAPIParamMap(Integer qty) {
        qty = (qty == null || qty < 0) ? 1 : qty;
        return new Map<String, String>{'qty' => String.valueOf(qty)};
    }

    private static BRPPartLocatorWrapper populateDefaultField(BRPPartLocatorWrapper partLocatorObj, Part__c partRec) {
        partLocatorObj.PartNumber = partRec.Part_Number__c;
        partLocatorObj.PartDescription = partRec.Description__c;
        return partLocatorObj;
    }
    
    private static BRPPartLocatorWrapper parseResponse(PartInventoryWrappper apiResObj, Part__c partRec) {
        BRPPartLocatorWrapper partLocatorObj = new BRPPartLocatorWrapper(partRec.Part_Number__c, partRec.Description__c);
        if(apiResObj != null && apiResObj.located_lines != null && apiResObj.located_lines.size() > 0) {
            partLocatorObj.AllSupplierList = new List<BRPPartLocatorWrapper.PartInfoFromDealer>();
            for(LocatedLineWrapper supplier : apiResObj.located_lines) {
                BRPPartLocatorWrapper.PartInfoFromDealer supplierObj = new BRPPartLocatorWrapper.PartInfoFromDealer();
                supplierObj.AvailableQty = String.valueOf(supplier.determined_qty);
                supplierObj.DealerName = supplier.plant.name;
                supplierObj.DealerAddress = supplier.plant.city + ', ' + supplier.plant.state + ' ' + supplier.plant.country;
                partLocatorObj.AllSupplierList.add(supplierObj);
            }
        }
        return partLocatorObj;
    }

    public class PartInventoryWrappper {
        public List<LocatedLineWrapper> located_lines;
    }

    public class LocatedLineWrapper {
        public Integer determined_qty;
        public AddressWrapper plant;
    }

    public class AddressWrapper {
        public String name;
        public String city;
        public String state;
        public String country;
    }

}