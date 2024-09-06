public with sharing class SOQLToFileWrapper {
    public String soql;
    public String host;
    public Decimal port;
    public String username;
    public String password;
    public String filepath;
    public Boolean allowUnauthorized;
    public Boolean secure;
    public Boolean includeColumnHeader;
    public Boolean includeImages;
    public String imageSoql;
    public Map<String, String> apiNameToSoql;
    public csvFormatOption csvFormatOptions;

    public SOQLToFileWrapper(String exportType, GE_File_Config__c fileConfigRec, FTP_Config__c ftpConfigRec, Map<String, List<GE_File_Column_Override_Info__c>> fileDetailToColOverrideInfoListMap, Map<String, List<String>> otherObjAPINameToFieldAPINameListMap) {
        this.soql = BPUtility.getEncodedString(BPUtility.addNamespaceToQuery(GenericExportUtil.createQueryForDataToExport(fileConfigRec, exportType, null), Constants.NAMESPACE));
        this.host = String.isNotBlank(ftpConfigRec.FTP_URL__c) ? ftpConfigRec.FTP_URL__c : '';
        this.port = ftpConfigRec.Port__c != null ? ftpConfigRec.Port__c : 0;
        this.username = ftpConfigRec.FTP_Username__c;
        this.password = ftpConfigRec.FTP_Password__c;
        String fileName = fileConfigRec.Include_Timestamp__c ? GenericExportUtil.getAttachmentNameWithTime(fileConfigRec.File_Name__c, Datetime.now()) : fileConfigRec.File_Name__c;
        String fileNameWithContantType = String.isNotBlank(fileConfigRec.File_Content_Type__c) ? (fileName).removeEnd('.' + fileConfigRec.File_Content_Type__c) + '.' + fileConfigRec.File_Content_Type__c : '';
        this.filepath = ftpConfigRec.Directory_Path__c + fileNameWithContantType;
        this.includeColumnHeader = fileConfigRec.Include_Column_Header__c;
        this.includeImages = fileConfigRec.Include_Images__c;
        if(fileConfigRec.Include_Images__c) {
            this.imageSoql = BPUtility.getEncodedString(BPUtility.addNamespaceToQuery(GenericExportUtil.createQueryToFetchImages(fileConfigRec, null), Constants.NAMESPACE));
        }

        this.apiNameToSoql = new Map<String, string>();    
        for(String objectAPIName: otherObjAPINameToFieldAPINameListMap.keySet()) {
            String query = 'SELECT ' + String.join(otherObjAPINameToFieldAPINameListMap.get(objectAPIName), ',') + ' FROM ' + objectAPIName + ' LIMIT 1';
            this.apiNameToSoql.put(objectAPIName, BPUtility.getEncodedString(BPUtility.addNamespaceToQuery(query, Constants.NAMESPACE)));
        }

        if(!ftpConfigRec.SFTP_Server__c) {
            this.allowUnauthorized = true;
            this.secure = false;
        }
        if(ftpConfigRec.FTPS_Connection__c) {
            this.secure = true;
        }
        this.csvFormatOptions = new csvFormatOption(fileConfigRec, fileDetailToColOverrideInfoListMap);        
    }

    public class csvFormatOption {
        public String delimiter;
        public String timeFormat;
        public String timeStandard;
        public Decimal timezone;
        public List<columnDetail> columnDetails;

        public csvFormatOption() {}

        public csvFormatOption(GE_File_Config__c fileConfigRec, Map<String, List<GE_File_Column_Override_Info__c>> fileDetailToColOverrideInfoListMap) {
            this.timeFormat = 'YYYY-DD-MM';
            this.timeStandard = 'UTC';
            this.timezone = Decimal.valueOf(UserInfo.getTimeZone().getDisplayName().substringBefore(')').substringAfter('(GMT').replace(':','.')); 
            this.delimiter = GenericExportUtil.fileSeparatorToFileSeparatorSymbolMap.containsKey(fileConfigRec.File_Separator__c) ? 
                                                GenericExportUtil.fileSeparatorToFileSeparatorSymbolMap.get(fileConfigRec.File_Separator__c) : 
                                                (fileConfigRec.File_Separator__c.equalsIgnoreCase('other') ? fileConfigRec.Delimiter__c : fileConfigRec.File_Separator__c);
            
            this.columnDetails = new List<columnDetail>();
            List<GE_File_Column_Override_Info__c> colOverrideInfoList;
            for(GE_File_Detail__c columnDetailRec : fileConfigRec.GE_File_Details__r) {
                colOverrideInfoList = fileDetailToColOverrideInfoListMap.containsKey(columnDetailRec.Id) ? fileDetailToColOverrideInfoListMap.get(columnDetailRec.Id) : new List<GE_File_Column_Override_Info__c>();
                this.columnDetails.add(new columnDetail(columnDetailRec, colOverrideInfoList));
            }
        }
    }

    public class columnDetail {
        public String dataType;
        public String fieldAPIName;
        public String fileColumnLabel;
        public Integer orderNumber;
        public String defaultValue;
        public String otherObjectAPIName;
        public Map<String, String> columnOverrideInfo;

        public columnDetail() {}

        public columnDetail(GE_File_Detail__c columnDetailRec, List<GE_File_Column_Override_Info__c> colOverrideInfoList) {
            this.fileColumnLabel = columnDetailRec.File_Column_Label__c;
            this.fieldAPIName = columnDetailRec.Field_API_Name__c; 
            this.orderNumber = Integer.valueOf(columnDetailRec.Order_Number__c);
            this.dataType = columnDetailRec.Data_Type__c.equalsIgnoreCase('Date/Time') ? 'DateTime' : columnDetailRec.Data_Type__c;
            this.defaultValue = columnDetailRec.Default_Value__c != null ? columnDetailRec.Default_Value__c : '';
            this.otherObjectAPIName = columnDetailRec.Other_Object_API_Name__c != null ? columnDetailRec.Other_Object_API_Name__c : '';
            this.columnOverrideInfo = new Map<String, String>();
            for(GE_File_Column_Override_Info__c columnOverrideInfoRec : colOverrideInfoList) {
                this.columnOverrideInfo.put(columnOverrideInfoRec.Actual_Column_Value__c, columnOverrideInfoRec.Override_Column_Value__c);
            }
        }
    }
}