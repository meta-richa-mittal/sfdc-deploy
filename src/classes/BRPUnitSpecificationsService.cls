public without sharing class BRPUnitSpecificationsService {

    public static String getUnitSpecification(String vin) {
        String jsonString;
        if(String.isNotBlank(vin) && vin.length() <= 18) {
            Map<String, String> endPointExchangeParam = new Map<String, String> {'{{serial_no}}' => vin};
            HttpResponse response = BRPUtility.syncToBRP('GetUnitSpecification', null, 'GET', new Map<String, String>(), endPointExchangeParam);
            if(response.getStatusCode() == 200) {
                UnitSpecificationResWrapper unitSpecs = (UnitSpecificationResWrapper) System.JSON.deserialize(response.getBody(), UnitSpecificationResWrapper.class);
                BRPVehicleResponseWrapper.Vehicle vehicleObj = new BRPVehicleResponseWrapper.Vehicle(unitSpecs);
                vehicleObj.BRPUnitSpecifications = unitSpecs;
                jsonString = system.JSON.serialize(vehicleObj);
            } else {
                jsonString = system.JSON.serialize(new ResponseWrapper(400, 'No such vehicle found'));
            } 
        } else {
            jsonString = system.JSON.serialize(new ResponseWrapper(400, 'No such vehicle found'));
        }
        return  jsonString;
    }

    public class UnitSpecificationResWrapper {
        public Integer model_year;
        public String model_number;
        public String model_name;
        public String manufacturer_name;
        public Integer no_of_cylinders;
        public String serial_no;
        public String model_code;
        public List<String> brands;
        public String product_line;
        public String product_type;
        public String color_code_description;
        public Integer max_no_of_passengers;
        public String engine_code;
        public String engine_code_description;
        public Decimal engine_power; 
        public Decimal engine_displacement; 
        public String weight_unit;
        public String inventory_type;
        public List<String> status;
        public String last_change_date;
        public Decimal net_weight;
    }

    public static BRPArticleResponseWrapper getArticleByArticleNo(String articleNo) {
        BRPArticleResponseWrapper responseObj = new BRPArticleResponseWrapper();
        if(String.isNotBlank(articleNo) && articleNo.length() <= 18) {
            Map<String, String> endPointExchangeParam = new Map<String, String> {'{{article_number}}' => articleNo};
            HttpResponse response = BRPUtility.syncToBRP(BRPUtility.GET_ARTICLE, null, 'GET', new Map<String, String>(), endPointExchangeParam);
            if(response.getStatusCode() == 200) {
                responseObj.successResponse = BRPArticleResponseWrapper.parseArticleResponse((BRPArticleResponseWrapper.SuccessWrapperV4) System.JSON.deserialize(response.getBody(), BRPArticleResponseWrapper.SuccessWrapperV4.class));
            } else {
                parseErrorForArticleApi(responseObj, response);
            } 
        } else {
            throw new BlackPurlException('Article number can\'t be empty or greater than 18.');
        }
        return responseObj;
    }

    private static void parseErrorForArticleApi(BRPArticleResponseWrapper responseObj, HttpResponse response) {
        handleErrorForArticleApi(responseObj, response);
    }

    private static void handleErrorForArticleApi(BRPArticleResponseWrapper responseObj, HttpResponse response) {
        BRPArticleResponseWrapper.ErrorWrapper errorObj = new BRPArticleResponseWrapper.ErrorWrapper();
        responseObj.ErrorResponse = new BRPArticleResponseWrapper.FailureWrapper();
        responseObj.ErrorResponse.errors = new List<BRPArticleResponseWrapper.ErrorWrapper>();

        errorObj.title = BRPErrorHandler.getMessageFromErrorPayload(response).title;
        
        responseObj.ErrorResponse.errors.add(errorObj);
    }
    
    public static BRPCampaignResponseWrapper getCampaignsByVIN(String vin) {
        BRPCampaignResponseWrapper responseObj = new BRPCampaignResponseWrapper();
        if(String.isNotBlank(vin) && vin.length() <= 18) {
            Map<String, String> endPointExchangeParam = new Map<String, String> {'{{serial_number}}' => vin};
            HttpResponse response = BRPUtility.syncToBRP(BRPUtility.GET_CAMPAIGNS, null, 'GET', new Map<String, String>(), endPointExchangeParam);
            if(response.getStatusCode() == 200) {
                responseObj.SuccessResponse = BRPCampaignResponseWrapper.parseCampaignsResponse((BRPCampaignResponseWrapper.SuccessWrapperV4) System.JSON.deserialize(response.getBody(), BRPCampaignResponseWrapper.SuccessWrapperV4.class));
            } else {
                parseErrorForCamaignApi(responseObj, response);
            } 
            responseObj.ButtonName = getButtonNameByBRPResponse(responseObj);
        } else {
            throw new BlackPurlException('Vin number can\'t be empty or greater than 18.');
        }
        return responseObj;
    }

    private static void parseErrorForCamaignApi(BRPCampaignResponseWrapper responseObj, HttpResponse response) {
        handleErrorForCamaignApi(responseObj, response);
    }

    private static void handleErrorForCamaignApi(BRPCampaignResponseWrapper responseObj, HttpResponse response) {
        BRPCampaignResponseWrapper.ErrorWrapper errorObj = new BRPCampaignResponseWrapper.ErrorWrapper();
        responseObj.ErrorResponse = new BRPCampaignResponseWrapper.FailureWrapper();
        responseObj.ErrorResponse.errors = new List<BRPCampaignResponseWrapper.ErrorWrapper>();

        BRPErrorHandler.ErrorMessageWrapper errorMessageObj = BRPErrorHandler.getMessageFromErrorPayload(response);
        errorObj.title = errorMessageObj.title;
        errorObj.code = errorMessageObj.code;

        responseObj.ErrorResponse.errors.add(errorObj);
    }

    private static String getButtonNameByBRPResponse(BRPCampaignResponseWrapper responseObj) {
        String buttonName;
        if(responseObj.successResponse != null) {
            for(BRPCampaignResponseWrapper.Campaign campaignObj : responseObj.successResponse.campaigns) {
                if(campaignObj.articles != null && campaignObj.articles.size() > 0 && buttonName != 'BRP Safety') {
                    buttonName = 'BRP articles';
                }
                if(campaignObj.type_descr == 'Safety' && !campaignObj.is_claimed) {
                    buttonName = 'BRP Safety';
                    break;
                }
            }
            if(String.isBlank(buttonName)) {
                buttonName = 'No BRP articles';
            }
        } else if (responseObj.errorResponse != null) {
            if(responseObj.errorResponse.errors.size() > 0 && responseObj.errorResponse.errors[0].code == 'not_found') {
                if(responseObj.errorResponse.errors[0].title.contains('does not have any campaigns')) {
                    buttonName = 'No BRP campaigns';
                } else {
                    buttonName = 'Invalid BRP VIN';
                }
            } else {
                buttonName = 'BRP: Not found';
            }
        }
        return buttonName;
    }
}