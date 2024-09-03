public without sharing class UniversalAPIWrapper {
    
    public kenectApiWrapper data;
    public SOMApiWrapper SOMReqData;
    public SOQLToFileApiWrapper SOQLToFileReqData;
    public YamahaAusApiWrapper yamahaAusReqData;
    public ApfImportApiWrapper apfImportReqData;

    public UniversalAPIWrapper(kenectApiReqWrapper reqWrapper) {
        data = new kenectApiWrapper();
        data.query = 'mutation ($payload: BlackpurlMessage!) { kenectPushMessageToKenect(payload: $payload){ customerId smsBody email phone smsDirection messageUUID customerOrderId customerInvoiceId}}';
        data.variables = new kenectVariableWrapper();
        data.variables.payload = reqWrapper;
    }

    public UniversalAPIWrapper(SOMApiReqWrapper reqWrapper) {
        SOMReqData = new SOMApiWrapper();
        SOMReqData.query = 'mutation AsyncJob($variables: JSON!, $webhookURL: String) {\tasyncJobCreate( request: { query: \"mutation ($payload: SomCreatePayload!) { somCreateJob(payload: $payload) {invFileName psiFileName pooFileName includeAllSubmittedClaimItems invStatus psiStatus pooStatus}}\" variables: $variables } webhookURL: $webhookURL\t) { id webhookURL createdDate status\t}}';
        SOMReqData.variables = new SOMAPIVariableWrapper();
        SOMReqData.variables.variables = new SOMVariableWrapper();
        SOMReqData.variables.webhookURL = UniversalAPIUtility.webhookURL;
        SOMReqData.variables.variables.payload = reqWrapper;
    }

    public UniversalAPIWrapper(YamahaAusApiReqWrapper reqWrapper) {
        yamahaAusReqData = new YamahaAusApiWrapper();
        yamahaAusReqData.query = 'mutation AsyncJob($variables: JSON!) {\tasyncJobCreate( request: { query: \"mutation ($payload: YamahaAustraliaUpdateVendorPartsAvailabilityInput!) { yamahaAustraliaUpdateVendorPartsAvailability(payload: $payload) }\" variables: $variables } \t) { id createdDate status\t}}';
        yamahaAusReqData.variables = new YamahaAusAPIVariableWrapper();
        yamahaAusReqData.variables.variables = new YamahaAusVariableWrapper();
        yamahaAusReqData.variables.webhookURL = UniversalAPIUtility.webhookURL;
        yamahaAusReqData.variables.variables.payload = reqWrapper;
    }
    
    public UniversalAPIWrapper(ApfImportApiReqWrapper reqWrapper) {
        apfImportReqData = new ApfImportApiWrapper();
        apfImportReqData.query = 'mutation AsyncJob($variables: JSON!, $webhookURL: String) {\tasyncJobCreate( request: { query: \"mutation ($payload: MsVendorsSyncApiImportPriceFilePayload!) { MsVendorsSyncApiImportPriceFile(payload: $payload) { vendorMasterId requestId createdParts updatedParts failedParts }} \" variables: $variables } webhookURL: $webhookURL\t) { id webhookURL createdDate status\t}}';
        apfImportReqData.variables = new ApfImportAPIVariableWrapper();
        apfImportReqData.variables.variables = new ApfImportVariableWrapper();
        apfImportReqData.variables.webhookURL = UniversalAPIUtility.webhookURL;
        apfImportReqData.variables.variables.payload = reqWrapper;
    }

    public UniversalAPIWrapper(SOQLToFileWrapper reqWrapper, Boolean isSFTP) {
        SOQLToFileReqData = new SOQLToFileApiWrapper();
        SOQLToFileReqData.query = isSFTP ? 'mutation AsyncJob($variables: JSON!, $webhookURL: String) {asyncJobCreate( request: { query: \"query ($options: SoqlToSftpOptions!) {soqlToSftp(options: $options) { status }} \" variables: $variables } webhookURL: $webhookURL) { id webhookURL createdDate status}}'
                                    : 'mutation AsyncJob($variables: JSON!, $webhookURL: String) {asyncJobCreate( request: { query: \"query ($options: SoqlToFtpOptions!) {soqlToFtp(options: $options) { status}} \", variables: $variables} webhookURL: $webhookURL) { id webhookURL createdDate status}}';
        SOQLToFileReqData.variables = new SOQLToFileAPIVariableWrapper();
        SOQLToFileReqData.variables.variables = new SOQLToFileVariableWrapper();
        SOQLToFileReqData.variables.webhookURL = UniversalAPIUtility.webhookURL;
        SOQLToFileReqData.variables.variables.options = reqWrapper;
    }

    public class kenectApiWrapper {
        public kenectVariableWrapper variables;
        public String query;
    }

    public class SOMApiWrapper {
        public SOMAPIVariableWrapper variables;
        public String query;
    }
    public class SOQLToFileApiWrapper {
        public SOQLToFileAPIVariableWrapper variables;
        public String query;
    }
    public class kenectVariableWrapper {
        public kenectApiReqWrapper payload;
    }
    public class SOMAPIVariableWrapper {
        public SOMVariableWrapper variables;
        public String webhookURL;
    }

    // Yamaha AUS API related classes
    public class YamahaAusApiWrapper {
        public YamahaAusAPIVariableWrapper variables;
        public String query;
    }
    public class YamahaAusAPIVariableWrapper {
        public YamahaAusVariableWrapper variables;
        public String webhookURL;
    }
    public class YamahaAusVariableWrapper {
        public YamahaAusApiReqWrapper payload;
    }
    public class YamahaAusApiReqWrapper {
        public String username;
        public String password;

        public YamahaAusApiReqWrapper(String username, String password) {
            this.username = username;
            this.password = password;
        }
    }
    
    public class SOQLToFileAPIVariableWrapper {
        public SOQLToFileVariableWrapper variables;
        public String webhookURL;
    }

    public class SOQLToFileVariableWrapper {
        public SOQLToFileWrapper options;
    }

    public class SOMVariableWrapper {
        public SOMApiReqWrapper payload;
    }


    public class JWTTokenWrapper {
        public String requestedUser;
        public String instanceUrl;
        public String name;
        public String namespace;

        public JWTTokenWrapper() {
            this.requestedUser = UserInfo.getUserName();
            this.instanceUrl = URL.getOrgDomainUrl().toExternalForm();
            this.name = 'Kenect';
            this.namespace = GeneralConfiguration.getPackageNamespace();
            if(this.namespace == null) {
                this.namespace = '';
            }
        }
    }

    public class kenectApiReqWrapper {
        public String customerId;
        public String smsBody;
        public String email;
        public String phone;
        public String smsDirection;
        public String messageUUID;
        public String customerOrderId;
        public String customerInvoiceId;
        public Integer locationId;

        public kenectApiReqWrapper(Message_History__c messageRec) {
            this.customerId = messageRec.Sent_To__c;
            this.smsBody = messageRec.SMS_Body__c;
            this.phone = messageRec.Phone__c;
            this.smsDirection = messageRec.SMS_Direction__c;
            this.customerOrderId = messageRec.CO_Header__c;
            this.email = '';
            this.messageUUID = '';
            this.customerInvoiceId = null;
        }
    }

    public class ApfImportApiWrapper {
        public ApfImportAPIVariableWrapper variables;
        public String query;
    }
    public class ApfImportAPIVariableWrapper {
        public ApfImportVariableWrapper variables;
        public String webhookURL;
    }
    public class ApfImportVariableWrapper {
        public ApfImportApiReqWrapper payload;
    }
    public class ApfImportApiReqWrapper {
        public String accessKeyId;
        public String secretAccessKey;
        public String priceFileBucketName;
        public String region;
        public String filePath;
        public String vendorMasterId;
        public String requestId;
        public String orgId;
        public Integer chunkSize;

        public ApfImportApiReqWrapper(Vendor_Master__c vmRec, VendorMasterWrapper vendorMasterObj) {
            this.vendorMasterId = vmRec.Id;
            this.requestId = vmRec.Summary_Logs__r[0].Id;
            this.accessKeyId = vendorMasterObj.accessKeyId;
            this.secretAccessKey = vendorMasterObj.secretAccessKey;
            this.priceFileBucketName = vendorMasterObj.priceFileBucketName;
            this.region = vendorMasterObj.region;
            this.filePath = vendorMasterObj.priceFileLocation.substringAfter(APFImportScheduler.fileFolder);
            this.orgId = UserInfo.getOrganizationId();
            try {
                String chunkSizeStr = GeneralConfiguration.getConfigurationByName(GeneralConfiguration.APF_RECORD_PROCESSING_COUNT);
                this.chunkSize = String.isNotBlank(chunkSizeStr) ? Integer.valueOf(chunkSizeStr) : 2000;
            } catch(Exception e) {
                this.chunkSize = 2000;
            }
        }
    }

    public class SOMApiReqWrapper {
        public String invFileName;
        public String psiFileName;
        public String pooFileName;
        public Boolean includeAllSubmittedClaimItems;
        public String orgCode;
        public String filepath;
        public Boolean onlySendAllDataInPsiFile;
        public String timezone;
        public String dateRangeFilterForPSI;

        public SOMApiReqWrapper(String invFileName, String psiFileName, String pooFileName, Boolean includeAllSubmittedClaimItems,
                                String orgCode, String filepath, Boolean onlySendAllDataInPsiFile) {
            this.invFileName = invFileName;
            this.psiFileName = psiFileName;
            this.pooFileName = pooFileName;
            this.includeAllSubmittedClaimItems = includeAllSubmittedClaimItems;
            this.orgCode = orgCode;
            this.filepath = filePath;
            this.onlySendAllDataInPsiFile = onlySendAllDataInPsiFile;
            this.timezone = UserInfo.getTimeZone().getID();
        }
    }

    public class kenectApiResWrapper {
        public List<kenectApiErrorResWrapper> errors;
        public kenectApiSuccessResWrapper data;
    }

    public class kenectApiSuccessResWrapper {
        public kenectApiReqWrapper kenectPushMessageToKenect;
    }

    public class kenectApiErrorResWrapper {
        public String message;
    }


    public class UniversalApiResWrapper {
        public UniversalApiSuccessResWrapper data;
        public List<UniversalApiErrorResWrapper> errors;
    }
    public class UniversalApiSuccessResWrapper {
        public UniversalApiResResultWrapper asyncJobCreate;
    }
    public class UniversalApiResResultWrapper {
        public String id;
        public String webhookURL;
        public String createdDate;
        public String status;
    }
    public class UniversalApiErrorResWrapper {
        public String message;
    }
}