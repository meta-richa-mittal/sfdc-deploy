public without sharing class AutomatedPriceFileErrorLogExportCtrl {
    
    public String fileContent {get; private set;}
    
    public AutomatedPriceFileErrorLogExportCtrl() {
        String lastNumber = ApexPages.currentPage().getParameters().get('lastNumber');
        String priceFileMappingId = ApexPages.currentPage().getParameters().get('mappingId');
        
        String query = 'SELECT Error_Field_Name__c, Error_Messages__c, Part_Number__c FROM Price_File_Error_Log__c ' + 
                        ' WHERE Vendor__c != null AND CreatedById = \'' + UserInfo.getUserId() + '\'';
        
        if(String.isNotBlank(lastNumber)) {
            query += ' AND Name >: lastNumber';
        }
        if(String.isNotBlank(priceFileMappingId)) {
            query += ' AND Price_File_Mapping__c =: priceFileMappingId';
        }
        query += ' ORDER BY CreatedDate ASC';
        
        if(!AccessControl.ifObjectFieldIsAccessible('Price_File_Error_Log__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        setExportFileData(Database.query(query));
    }
    
    private void setExportFileData(List<Price_File_Error_Log__c> errorLogList) {
        fileContent = 'Part#,Field Name,Error Message\n';
        for(Price_File_Error_Log__c errorLogRec : errorLogList) {
            fileContent += (errorLogRec.Part_Number__c != null ? errorLogRec.Part_Number__c.escapeCsv() : '') + ',';
            fileContent += (errorLogRec.Error_Field_Name__c != null ? errorLogRec.Error_Field_Name__c.escapeCsv() : '') + ',';
            fileContent += (errorLogRec.Error_Messages__c != null ? errorLogRec.Error_Messages__c.escapeCsv() : '') + '\n';
        }
    }
}