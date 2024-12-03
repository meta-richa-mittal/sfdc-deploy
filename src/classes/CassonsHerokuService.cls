global without sharing class CassonsHerokuService {

    public static HttpResponse sendRequestToHeroku(String herokuEndPoint){
        if(String.isNotBlank(herokuEndPoint)) {
            String endpoint = herokuEndPoint;
            Http h = new Http();
            HttpRequest req = new HttpRequest();
            req.setEndpoint(endpoint);
            req.setMethod('GET');
            req.setTimeout(120000);
            req.setHeader('Content-Type', 'application/json');
            if(!Test.isRunningTest()) {
                HttpResponse res = h.send(req);
                return res;
            }
        } else {
            new LogService().createErrorLog('CassonsHerokuService', 'sendRequestToHeroku()', 'No heroku end point set', 404, null, 
                                            herokuEndPoint, LogService.CASSONS, true);
        }
        return null;
    }
    @future(callout=true)
    public static void fetchPartsFromHeroku(Integer startIndex) {
        String orgId = UserInfo.getOrganizationId();
        Integer partsPerRequest = CassonsUtility.getPartsPerRequest();
        String cassonsWrapperJson = BPUtility.getEncodedString(System.JSON.serialize(new PartResponseWrapper(orgId, partsPerRequest, startIndex)));
        String herokuEndPoint = CassonsUtility.getHerokuEndPoint();
        herokuEndPoint = herokuEndPoint + '/CassonsAPI/getCassonsParts/' + cassonsWrapperJson;
        HttpResponse res = sendRequestToHeroku(herokuEndPoint);
        if(res != null){
            if(res.getStatusCode() != 200 && res.getStatusCode() != 201 && res.getStatusCode() != 503) {
                new LogService().createErrorLog('CassonsHerokuService', 'fetchPartsFromHeroku()', res.getBody(), String.valueOf(res.getStatusCode()), null, 
                                                String.valueOf(startIndex), LogService.CASSONS, true, 'Info');
            } else {
                PartResponseWrapper responseObj = (PartResponseWrapper) System.JSON.deserialize(BPUtility.getDecodedString(res.getBody()), PartResponseWrapper.class);
                if(responseObj.FileGenerated) {
                    schedulePopulateCassonsPartDetailsBatch(startIndex, responseObj.CassonsPartList, 10);
                } else {
                    BPUtility.abortAlreadyScheduleJobs('Fetch Cassons Part Details');
                    String cronExp = BPUtility.getCronExpForGivenTime(120);
                    system.schedule('Fetch Cassons Part Details', cronExp, new FetchCassonsPartsScheduler(startIndex));
                }
            }
        }
    }

    public static void schedulePopulateCassonsPartDetailsBatch(Integer startIndex, List<CassonsPartWrapper> cassonsPartList, Integer timeInterval){
        try{
            BPUtility.abortAlreadyScheduleJobs('Populate Cassons Part Details');
            String cronExp = BPUtility.getCronExpForGivenTime(timeInterval);
            system.schedule('Populate Cassons Part Details', cronExp, new PopulateCassonsPartDetailsBatch(startIndex, cassonsPartList, false));
        } catch(Exception e){
            schedulePopulateCassonsPartDetailsBatch(startIndex, cassonsPartList, 300);
        }   
    }

    @future(callout=true)
    public static void sendPartInventoryRequest() {
        String cassonsWrapperJson = BPUtility.getEncodedString(System.JSON.serialize(new CassonsWrapper()));
        String herokuEndPoint = CassonsUtility.getHerokuEndPoint();
        herokuEndPoint = herokuEndPoint + '/CassonsAPI/fetchPartsFromCasson/' + cassonsWrapperJson;
        HttpResponse res = sendRequestToHeroku(herokuEndPoint);
        if(res != null){
            if(res.getStatusCode() != 200 && res.getStatusCode() != 201 && res.getStatusCode() != 503) {
                new LogService().createErrorLog('CassonsHerokuService', 'sendPartInventoryRequest()', res.getBody(), String.valueOf(res.getStatusCode()), null, 
                                                    null, LogService.CASSONS, true, 'Info');
            } else {
                BPUtility.abortAlreadyScheduleJobs('Fetch Cassons Part Details');
                String cronExp = BPUtility.getCronExpForGivenTime(300);
                system.schedule('Fetch Cassons Part Details', cronExp, new FetchCassonsPartsScheduler(1));
            }
        }
    } 
    public class CassonsWrapper {
       
        public String OrgId;
        public String CassonsRequestURI;
        public String Port;
        public Integer ConnectionTimeout;
        public String ProxyIPAddress;

        public CassonsWrapper(){
           this.OrgId = UserInfo.getOrganizationId();
           this.CassonsRequestURI = CASSONS_Configuration__c.getOrgDefaults().Cassons_Request_URI__c + CASSONS_Configuration__c.getOrgDefaults().API_Key__c + '&format=json';
           this.Port = CASSONS_Configuration__c.getOrgDefaults().Port__c	;
           this.ConnectionTimeout = CASSONS_Configuration__c.getOrgDefaults().Connection_Timeout__c != null ? (Integer)CASSONS_Configuration__c.getOrgDefaults().Connection_Timeout__c: 300;
           this.ProxyIPAddress = CASSONS_Configuration__c.getOrgDefaults().Proxy_IP_Address__c;
        }
    }

    global class PartResponseWrapper {
        public String OrgId;
        public Boolean FileGenerated;
        public List<CassonsPartWrapper> CassonsPartList;
        public Integer PartsPerRequest;
        public Integer StartIndex;

        public PartResponseWrapper(String orgId, Integer partsPerRequest, Integer startIndex) {
            this.OrgId = orgId;
            this.PartsPerRequest = partsPerRequest;
            this.StartIndex = startIndex != null ? startIndex : 1;
        }
    }

    global class CassonsPartWrapper {
        public String PartNo;
        public String Description;
        public String SOH;
    }
}