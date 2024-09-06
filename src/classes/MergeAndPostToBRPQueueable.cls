/** 
* Author: Manoj Sharma
* Since: June 20, 2020 
* Name: MergeAndPostToBRPQueueable 
* Description: Apex Queueable class to send request to heroku.
**/
public class MergeAndPostToBRPQueueable implements Queueable, Database.AllowsCallouts {
    public String exportType;
    public Set<String> attachmentIdList;
    public static String methodType = 'ProcessPartsInventory';
    DateTime dateTimeValue;
    Boolean isRetryFilePosting;

    public MergeAndPostToBRPQueueable(String exportType, Set<String> attIdList, DateTime dateTimeValue) {
        this.exportType = exportType;
        this.attachmentIdList = attIdList;
        this.dateTimeValue = dateTimeValue;
        this.isRetryFilePosting = false;
    }

    public MergeAndPostToBRPQueueable(String exportType, Set<String> attIdList, DateTime dateTimeValue, Boolean retryFilePosting) {
        this.exportType = exportType;
        this.attachmentIdList = attIdList;
        this.dateTimeValue = dateTimeValue;
        this.isRetryFilePosting = retryFilePosting;
    }
    
    public void execute(QueueableContext context) {
        sendFileToBRP(this.exportType, this.attachmentIdList, this.dateTimeValue, this.isRetryFilePosting);
    }

    public static void sendFileToBRP(String exportType, Set<String> attachmentIdList, DateTime dateTimeValue, Boolean isRetryFilePosting) {
    	if(!AccessControl.ifObjectFieldIsAccessible('IFW_IntegrationConfig__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<IFW_IntegrationConfig__c> configList = [SELECT Username__c, Password__c FROM IFW_IntegrationConfig__c 
        		WHERE Accounting_Enabled__c = true AND Integration_Name__c = 'BRP'];
        if(configList.size() == 0) {
        	throw new BlackpurlException('No active config found for BRP');
        } else if(String.isBlank(configList[0].Username__c) || String.isBlank(configList[0].Password__c)) {
        	throw new BlackpurlException('Blank Username or Password');
        }
        
        String brpFileDetailJSON = BPUtility.getEncodedString(System.JSON.serialize(new BRPFileDetailWrapper(exportType, attachmentIdList, 
        	dateTimeValue, configList[0].Username__c, configList[0].Password__c, isRetryFilePosting)));
        System.debug(brpFileDetailJSON);
        String endpoint = BRPUtility.getEndpoint();
        if(String.isBlank(endpoint)){
            endpoint = 'https://blackpurl-brp-4e0f474014af.herokuapp.com/BRPPartInventoryAPI/PostFileToBRP';
        } 
        endpoint += '/' + brpFileDetailJSON;
                
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('GET');
        req.setTimeout(120000);
        req.setHeader('Content-Type', 'application/json');
        if(!Test.isRunningTest()) {
            HttpResponse res = h.send(req);
            if(res.getStatusCode() != 200 && res.getStatusCode() != 201) {
                new BRPLogService().createLog('Parts Inventory', (BPUtility.getEncodedString(brpFileDetailJSON)), null, null, String.valueof(res.getStatusCode()), 
                                                res.getBody(), 'Error', 'MergeAndPostToBRPQueueable', 'sendFileToBRP', null);
            }
        }
    }
    
    public class BRPFileDetailWrapper {
        public String FileName;
        public String Orgname;
        public String Endpoint;
        public String Username;
        public String Password;
        public String CreationDateTime;
        public String BODId;
        public String DealerId;
        public Set<String> AttachmentIdList;
        public String Namespace;
        public String SFUsername;
        public String SFPassword;
        public String ExportType;
        public String DateTimeValue;
        public Boolean IsRetryFilePosting;
        public String SalesforceBaseUrl;
        public String SessionId;
        
        public BRPFileDetailWrapper(String exportType, Set<String> attachmentIdList, DateTime dateTimeValue, String username, String password, Boolean isRetryFilePosting) {
            IFW_IntegrationConfigItem__c brpIFWConfigItem = BRPUtility.getIFWConfigItem('BRPPartInventory', 'POST', 'BRP');
            this.Orgname = BRPUtility.getOrgName();
            if(brpIFWConfigItem != null) {
                this.Endpoint = brpIFWConfigItem.endpoint_URL__c;
            }
            this.Namespace = (GeneralConfiguration.getPackageNamespace() == null) ? '' : GeneralConfiguration.getPackageNamespace();
            this.AttachmentIdList = attachmentIdList;
            this.Username = username;
            this.Password = password;
            this.DealerId = BRPUtility.getDealerId();
            this.CreationDateTime = DateTime.now().format('yyyy-MM-dd\'T\'HH:mm:ssXXX', 'America/New_York');
            this.BODId = GuidUtil.generateGuid();
            this.FileName = BRPUtility.getFileNameByFileType(BRPPartInventoryBatch.FILE_TYPE, dateTimeValue) + '.xml';
            this.SFUsername = BPUtility.getDecodedString(BPConfigurationsService.getSFUsername());
            this.SFPassword = BPUtility.getDecodedString(BPConfigurationsService.getSFPassword());
            this.SessionId = UserInfo.getSessionId();
            this.SalesforceBaseUrl = URL.getSalesforceBaseUrl().toExternalForm();
            this.exportType = exportType;
            this.DateTimeValue = dateTimeValue != null ? dateTimeValue.format(): Datetime.now().format();
            this.IsRetryFilePosting = isRetryFilePosting;
        }
    }
}