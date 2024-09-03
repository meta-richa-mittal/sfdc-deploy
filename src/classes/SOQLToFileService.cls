public without sharing class SOQLToFileService {

    public static void doFilePost(String exportType) {
        GE_File_Config__c fileConfigRec = GenericExportUtil.getGenericFileConfig(exportType);  
        FTP_Config__c ftpConfigRec = GenericExportUtil.getFTPConfigRec(exportType);
        Boolean isSFTP = ftpConfigRec.SFTP_Server__c;

        Map<String, List<String>> otherObjAPINameToFieldAPINameListMap = new Map<String, List<String>>();
        Set<String> fileDetailIdSet = new Set<String>();
        for(GE_File_Detail__c fileDetailRec: fileConfigRec.GE_File_Details__r) {
            if(String.isNotBlank(fileDetailRec.Other_Object_API_Name__c) && String.isNotBlank(fileDetailRec.Field_API_Name__c)) {
            	if(!otherObjAPINameToFieldAPINameListMap.containsKey(fileDetailRec.Other_Object_API_Name__c)) {
            		otherObjAPINameToFieldAPINameListMap.put(fileDetailRec.Other_Object_API_Name__c, new List<String>());
            	}
            	otherObjAPINameToFieldAPINameListMap.get(fileDetailRec.Other_Object_API_Name__c).add(fileDetailRec.Field_API_Name__c);
            }
            fileDetailIdSet.add(fileDetailRec.Id);
        }

        Map<String, List<GE_File_Column_Override_Info__c>> fileDetailToColOverrideInfoListMap = GenericExportUtil.getFileDetailToColOverrideInfoListMap(fileDetailIdSet);
        SOQLToFileWrapper SOQLToFileObj = new SOQLToFileWrapper(exportType, fileConfigRec, ftpConfigRec, fileDetailToColOverrideInfoListMap, otherObjAPINameToFieldAPINameListMap); 
        UniversalApiWrapper reqWrapper = new UniversalApiWrapper(SOQLToFileObj, isSFTP);
        HTTPResponse response = UniversalAPIService.doCallout(JSON.serialize(reqWrapper.SOQLToFileReqData, true));
        handleResponse(response, exportType);
    }

    public static void handleResponse(HTTPResponse response, String exportType) {
        if(response.getStatusCode() == 200) {
            UniversalAPIWrapper.UniversalApiResWrapper SOQLToFileApiResObj = (UniversalAPIWrapper.UniversalApiResWrapper) JSON.deserialize(response.getBody(), UniversalAPIWrapper.UniversalApiResWrapper.class);
            if(SOQLToFileApiResObj != null && SOQLToFileApiResObj.data != null && SOQLToFileApiResObj.data.asyncJobCreate != null && SOQLToFileApiResObj.data.asyncJobCreate.id != null) {
                List<GE_File_Config__c> geFileList = [SELECT id FROM GE_File_Config__c WHERE File_Name__c = :exportType LIMIT 1];
                if(!geFileList.isEmpty()) {
                    geFileList[0].JobRequestId__c = SOQLToFileApiResObj.data.asyncJobCreate.id;
                    DMLUtility.upsertSobjectList('GE_File_Config__c', geFileList);
                }
            } else {
                new LogService().createErrorLog('SOQLToFileService' , 'doFilePost()', response.getStatus() +' '+ response.getBody(), String.valueOf(response.getStatusCode()), null, null, LogService.FTP, true, 'Error');
            }
        } else {
            new LogService().createErrorLog('SOQLToFileService' , 'doFilePost()', response.getStatus() +' '+ response.getBody(), String.valueOf(response.getStatusCode()), null, null, LogService.FTP, true, 'Error');
        }
    }
}