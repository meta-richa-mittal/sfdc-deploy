public without sharing class BRPDealerPartLocatorService {
    
    public Static String getPartsLocator(String partId, Integer qty, String searchType) {
        String responseStr, reponseBody;
        List<Part__c> partList = [SELECT Part_Number__c, Description__c FROM Part__c WHERE Id =: partId];
        if(!partList.isEmpty()) {
            try {
                Map<String, String> endPointPathParamMap = new Map<String, String>{ '{{product_code}}' =>  partList[0].Part_Number__c};
                Map<String, String> parametersMap = getAPIParamMap(qty, searchType);
                HttpResponse response = BRPUtility.syncToBRP(BRPUtility.DEALER_PART_LOCATOR, null, 'GET', parametersMap, endPointPathParamMap);
                reponseBody = response.getBody();

                if(response.getStatusCode() == 200) {
                    BRPPartLocatorWrapper partLocatorObj = new BRPPartLocatorWrapper();
                    BRPDealerPartLocatorWrappper apiResObj = (BRPDealerPartLocatorWrappper) System.JSON.deserialize(response.getBody(), BRPDealerPartLocatorWrappper.class);
                    partLocatorObj = parseResponse(apiResObj, searchType, partList[0]);
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
        BRPUtility.insertBRPLog(BRPUtility.DEALER_PART_LOCATOR, null, response, 'BRPDealerPartLocatorService');
        return getErrorMessage(response);
    }

    private static String getErrorMessage(HttpResponse response) {
        String errorResponseStr = response.getBody().toString();
        String errorStr = 'Some Error occurred When fetching the details from BRP.';
        if(errorResponseStr.contains('Discontinued')) {
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

    private static Map<String, String> getAPIParamMap(Integer qty, String searchType) {
        qty = (qty == null || qty < 0) ? 1 : qty;
        String radius = BRPUtility.getDealerRadius();
        if(searchType == 'Dealer') {
            radius = '8000';
        }
        String unitCode = BRPUtility.getDealerRadiusMeasure();
        unitCode = (unitCode == 'mile' ? 'mi' : unitCode);

        return new Map<String, String>{'dealer_no' => BRPUtility.getDealerId(),
                                        'req_qty' => String.valueOf(qty),
                                        'radius' => radius,
                                        'unit' => unitCode
                                    };
    }

    private static BRPPartLocatorWrapper populateDefaultField(BRPPartLocatorWrapper partLocatorObj, Part__c partRec) {
        partLocatorObj.PartNumber = partRec.Part_Number__c;
        partLocatorObj.PartDescription = partRec.Description__c;
        return partLocatorObj;
    }

    private static BRPPartLocatorWrapper parseResponse(BRPDealerPartLocatorWrappper apiResObj, String searchType, Part__c partRec) {
        BRPPartLocatorWrapper partLocatorObj = new BRPPartLocatorWrapper(partRec.Part_Number__c, partRec.Description__c);
        if(apiResObj != null && apiResObj.dealers != null && apiResObj.dealers.size() > 0) {
            if(searchType == 'Dealer Radius') {
                partLocatorObj.DealerNearList = new List<BRPPartLocatorWrapper.PartInfoFromDealer>();
            } else {
                partLocatorObj.AllDealerList = new List<BRPPartLocatorWrapper.PartInfoFromDealer>();
            }
            for(PartLocatorWrapper dealer : apiResObj.dealers) {
                BRPPartLocatorWrapper.PartInfoFromDealer dealerObj = new BRPPartLocatorWrapper.PartInfoFromDealer();
                dealerObj.AvailableQty = String.valueOf(apiResObj.req_qty);
                dealerObj.DealerName = dealer.dealer_name;
                dealerObj.DealerAddress = dealer.address.street + ', ' + dealer.address.city + ' ' + dealer.address.state + ' ' + dealer.address.country + ' ' + dealer.address.postal_code;
                dealerObj.Distance = getFormattedDistance(dealer.distance);
                dealerObj.DealerPhoneNumber = dealer.phone_no;
                if(searchType == 'Dealer Radius') {
                    partLocatorObj.DealerNearList.add(dealerObj);
                } else {
                    partLocatorObj.AllDealerList.add(dealerObj);
                }
            }
        }
        return partLocatorObj;
    }

    private static String getFormattedDistance(Decimal distance) {
        return distance + ' ' + BRPUtility.getDealerRadiusMeasure() + ' away';
    }

    public class BRPDealerPartLocatorWrappper{
        public String req_product_code;
        public Integer req_qty;
        public List<PartLocatorWrapper> dealers;
    }

    public class PartLocatorWrapper{
        public String dealer_no;
        public String dealer_name;
        public BRPAddressWrapper address;
        public String language;
        public String time_zone;
        public String phone_no;
        public Decimal distance;
    }

    public class BRPAddressWrapper{
        public String street;
        public String city;
        public String state;
        public String country;
        public String postal_code;
    }
}