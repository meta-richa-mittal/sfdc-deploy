public without sharing class ExportStockUnitUtil {
    
    public static String fileSeparatorComma = ',';
    public static String fileSeparatorPipe = '|';
    public static String newLineSeparator = '\r\n';
    public static String MOTORLOT_EXPORT = 'Motorlot';
    public static String RV_TRADER_EXPORT = 'RV Trader';
    public static String RVT_EXPORT = 'RVT';
    public static String GENERIC_EXPORT = 'Generic';
    
    public static Map<String, String> motorlotFieldNameToAPIFieldNameMap = new Map<String, String> {
        'Engine' => 'Unit_Data_02__c',
        'Body Type' => 'Unit_Data_01__c',
        'Transmission' => 'Unit_Data_03__c',
        'Fuel' => 'Unit_Data_04__c',
        'Doors' => 'Unit_Data_08__c',
        'Featured' => 'Unit_Data_11__c',
        'Fuel Economy City' => 'Unit_Data_05__c',
        'Fuel Economy Highway' => 'Unit_Data_06__c',
        'Standard Features' => 'Unit_Data_09__c',
        'Optional Features' => 'Unit_Data_10__c'
    };
    
    public static Map<String, String> rvTraderFieldNameToAPIFieldNameMap = new Map<String, String> {
        'Length' => 'Unit_Data_07__c',
        'Body type' => 'Unit_Data_01__c',
        'Fuel type' => 'Unit_Data_04__c'
    };
    
    public static Map<String, String> rvtFieldNameToAPIFieldNameMap = new Map<String, String> {
        'category' => 'Unit_Data_01__c',
        'Length' => 'Unit_Data_07__c',
        'Fuel type' => 'Unit_Data_04__c',
        'Features' => 'Unit_Data_09__c',
        'Transmission' => 'Unit_Data_03__c'
    };
    
    public static Map<String, String> exportTypeToContentTypeMap = new Map<String, String>{
        MOTORLOT_EXPORT => 'text/csv',
        RV_TRADER_EXPORT => 'text/csv',
        RVT_EXPORT => 'text/csv',
        GENERIC_EXPORT => 'text/csv'
    };
    
    public static String getHeaders(String exportType) {
        List<String> headerList = new List<String>();
        if(exportType == MOTORLOT_EXPORT) {
            headerList = new List<String>{'VIN', 'Stock Number', 'Engine', 'Make', 'Model', 'Year', 'Body Type', 'Odometer', 'Transmission', 'Exterior Color', 
                                            'Interior Color', 'Fuel', 'Doors', 'Description', 'Featured', 'Price', 'Fuel Economy City', 
                                            'Fuel Economy Highway', 'Standard Features', 'Optional Features', 'Images', 'trim_level', 'price_text', 'external_url'};
        } else if(exportType == RV_TRADER_EXPORT) {
            headerList = new List<String>{'Dealer ID', 'Stock Number', 'Length', 'Body type', 'Make', 'Model', 'Year', 'Price to export', 'Vehicle Condition', 'Description', 
                                            'Dealer Name', 'Dealer Phone', 'City', 'State', 'Zip code', 'Mileage', 'Fuel type', 'Exterior color', 'Vin',
                                            'Public Url'};
            for(Integer i = 1; i <= 50; i++) {
                headerList.add('Image_url_' + i);
            }
        } else if(exportType == RVT_EXPORT) {
            headerList = new List<String>{'Dealer_id', 'UniqueId', 'category', 'Newused', 'Year', 'brand', 'Model', 'Length', 'Price', 'Fuel type', 
                                            'Description', 'Features', 'Exterior color', 'Mileage', 'Transmission', 'Vin', 'Post_date', 'Last updated', 'Photos'};
        } else if(exportType == GENERIC_EXPORT) { 
           headerList = new List<String>{'Year', 'Make', 'Model', 'Retail Price','Mileage'};          
        }
        return String.join(headerList, (exportType == RVT_EXPORT ? fileSeparatorPipe : fileSeparatorComma));
    }
    
    public static String genericTypeExport(List<Customer_Owned_Unit__c> stockUnitList, Map<Id, Customer_Owned_Unit__c> stockUnitsMap) {
        String fileData = '';
        for(Customer_Owned_Unit__c stockUnit : stockUnitList) {
            fileData += (stockUnit.Year__c != null ? String.valueOf(stockUnit.Year__c.intValue()) : '').escapeCsv() + fileSeparatorComma;
            fileData += (stockUnit.Unit_Make__r.Name != null ? stockUnit.Unit_Make__r.Name : '').escapeCsv() + fileSeparatorComma;
            fileData += (stockUnit.Unit_Model__r.Name__c != null ? stockUnit.Unit_Model__r.Name__c : '').escapeCsv() + fileSeparatorComma;
            fileData += (stockUnit.Total_Price__c != null ? String.valueOf(stockUnit.Total_Price__c.intValue()) : '').escapeCsv() + fileSeparatorComma;
            fileData += (stockUnit.Mileage_Value__c != null ? stockUnit.Mileage_Value__c + ' ' + stockUnit.Mileage_Type__c : '').escapeCsv() + fileSeparatorComma;
            fileData += newLineSeparator;
        }
        return fileData;
    }
    public static String motorlotTypeExport(List<Customer_Owned_Unit__c> stockUnitList, Map<Id, Customer_Owned_Unit__c> stockUnitsMap) {
        String fileData = '';
        for(Customer_Owned_Unit__c stockUnit : stockUnitList) {
            fileData += (stockUnit.VIN_Number__c != null ? stockUnit.VIN_Number__c : '').escapeCsv() + fileSeparatorComma;
            fileData += (stockUnit.Stock_Id__c != null ? stockUnit.Stock_Id__c : '').escapeCsv() + fileSeparatorComma;
            fileData += (stockUnit.get(motorlotFieldNameToAPIFieldNameMap.get('Engine')) != null ? 
                            String.valueOf(stockUnit.get(motorlotFieldNameToAPIFieldNameMap.get('Engine'))) : '').escapeCsv() + fileSeparatorComma;
            
            fileData += (stockUnit.Unit_Make__r.Name != null ? stockUnit.Unit_Make__r.Name : '').escapeCsv() + fileSeparatorComma;
            fileData += (stockUnit.Unit_Model__r.Name__c != null ? stockUnit.Unit_Model__r.Name__c : '').escapeCsv() + fileSeparatorComma;
            fileData += (stockUnit.Year__c != null ? String.valueOf(stockUnit.Year__c.intValue()) : '').escapeCsv() + fileSeparatorComma;
            
            fileData += (stockUnit.get(motorlotFieldNameToAPIFieldNameMap.get('Body Type')) != null ? 
                            String.valueOf(stockUnit.get(motorlotFieldNameToAPIFieldNameMap.get('Body Type'))) : '').escapeCsv() + fileSeparatorComma;
            fileData += (stockUnit.Mileage_Value__c != null ? String.valueOf(stockUnit.Mileage_Value__c.intValue()) : '').escapeCsv() + fileSeparatorComma;
            fileData += (stockUnit.get(motorlotFieldNameToAPIFieldNameMap.get('Transmission')) != null ? 
                            String.valueOf(stockUnit.get(motorlotFieldNameToAPIFieldNameMap.get('Transmission'))) : '').escapeCsv() + fileSeparatorComma;
            
            
            fileData += (stockUnit.Colour__c != null ? stockUnit.Colour__c : '').escapeCsv() + fileSeparatorComma;
            fileData += (stockUnit.Interior_Colour__c != null ? stockUnit.Interior_Colour__c : '').escapeCsv() + fileSeparatorComma;
            fileData += (stockUnit.get(motorlotFieldNameToAPIFieldNameMap.get('Fuel')) != null ? 
                            String.valueOf(stockUnit.get(motorlotFieldNameToAPIFieldNameMap.get('Fuel'))) : '').escapeCsv() + fileSeparatorComma;
            
            fileData += (stockUnit.get(motorlotFieldNameToAPIFieldNameMap.get('Doors')) != null ? 
                            String.valueOf(stockUnit.get(motorlotFieldNameToAPIFieldNameMap.get('Doors'))) : '').escapeCsv() + fileSeparatorComma;
            fileData += (stockUnit.Notes__c != null ? stockUnit.Notes__c : '').escapeCsv() + fileSeparatorComma;
            fileData += (stockUnit.get(motorlotFieldNameToAPIFieldNameMap.get('Featured')) != null ? 
                            String.valueOf(stockUnit.get(motorlotFieldNameToAPIFieldNameMap.get('Featured'))) : '').escapeCsv() + fileSeparatorComma;
            
            
            fileData += (stockUnit.Total_Price__c != null ? String.valueOf(stockUnit.Total_Price__c.intValue()) : '').escapeCsv() + fileSeparatorComma;
            fileData += (stockUnit.get(motorlotFieldNameToAPIFieldNameMap.get('Fuel Economy City')) != null ? 
                            String.valueOf(stockUnit.get(motorlotFieldNameToAPIFieldNameMap.get('Fuel Economy City'))) : '').escapeCsv() + fileSeparatorComma;
            fileData += (stockUnit.get(motorlotFieldNameToAPIFieldNameMap.get('Fuel Economy Highway')) != null ? 
                            String.valueOf(stockUnit.get(motorlotFieldNameToAPIFieldNameMap.get('Fuel Economy Highway'))) : '').escapeCsv() + fileSeparatorComma;
            
            fileData += (stockUnit.get(motorlotFieldNameToAPIFieldNameMap.get('Standard Features')) != null ? 
                            String.valueOf(stockUnit.get(motorlotFieldNameToAPIFieldNameMap.get('Standard Features'))) : '').escapeCsv() + fileSeparatorComma;
            fileData += (stockUnit.get(motorlotFieldNameToAPIFieldNameMap.get('Optional Features')) != null ? 
                            String.valueOf(stockUnit.get(motorlotFieldNameToAPIFieldNameMap.get('Optional Features'))) : '').escapeCsv() + fileSeparatorComma;
            
            // Image
            if(stockUnitsMap.containsKey(stockUnit.Id)) {
                List<String> imageUrls = new List<String>();
                for(Document__c document : stockUnitsMap.get(stockUnit.Id).Documents__r) {
                    if(String.isNotBlank(document.Public_Image_URL__c)) {
                        imageUrls.add(document.Public_Image_URL__c);
                    }
                }
                fileData += (String.join(imageUrls, fileSeparatorPipe) + fileSeparatorComma);
            }
            
            fileData += (stockUnit.Sub_Model__r.Sub_Model_Name__c != null ? stockUnit.Sub_Model__r.Sub_Model_Name__c : '').escapeCsv() + fileSeparatorComma;
            fileData += (stockUnit.Total_Price__c != null ? String.valueOf(stockUnit.Total_Price__c.intValue()) : '').escapeCsv() + fileSeparatorComma;
            fileData += fileSeparatorComma;  //external_url
            
            fileData += newLineSeparator;
        }
        return fileData;
    }
    
    public static String rvTraderTypeExport(List<Customer_Owned_Unit__c> stockUnitList, Map<Id, Customer_Owned_Unit__c> stockUnitsMap) {
        String fileData = '';
        List<Business_Profile__c> businessProfileList = SOQLUtil.getBusinessProfileData(new List<Id>());
        Business_Profile__c businessProfile = new Business_Profile__c();
        if(businessProfileList.size() > 0) {
            businessProfile = businessProfileList[0];
        }
        for(Customer_Owned_Unit__c stockUnit : stockUnitList) {
            fileData += 'steamrvllc' + fileSeparatorComma;
            fileData += (stockUnit.Stock_Id__c != null ? stockUnit.Stock_Id__c : '').escapeCsv() + fileSeparatorComma;
            fileData += (stockUnit.get(rvTraderFieldNameToAPIFieldNameMap.get('Length')) != null ? 
                            String.valueOf(stockUnit.get(rvTraderFieldNameToAPIFieldNameMap.get('Length'))) : '').escapeCsv() + fileSeparatorComma;
            
            fileData += (stockUnit.get(rvTraderFieldNameToAPIFieldNameMap.get('Body type')) != null ? 
                            String.valueOf(stockUnit.get(rvTraderFieldNameToAPIFieldNameMap.get('Body type'))) : '').escapeCsv() + fileSeparatorComma;
            fileData += (stockUnit.Unit_Make__r.Name != null ? stockUnit.Unit_Make__r.Name : '').escapeCsv() + fileSeparatorComma;
            fileData += (stockUnit.Unit_Model__r.Name__c != null ? stockUnit.Unit_Model__r.Name__c : '').escapeCsv() + fileSeparatorComma;
            fileData += (stockUnit.Year__c != null ? String.valueOf(stockUnit.Year__c.intValue()) : '').escapeCsv() + fileSeparatorComma;
            
            fileData += (stockUnit.Total_Price__c != null ? String.valueOf(stockUnit.Total_Price__c.intValue()) : '').escapeCsv() + fileSeparatorComma;
            fileData += (stockUnit.New_Unit__c ? 'New' : 'Used').escapeCsv() + fileSeparatorComma;
            fileData += (stockUnit.Notes__c != null ? stockUnit.Notes__c : '').escapeCsv() + fileSeparatorComma;
            
            // Address
            fileData += (businessProfile.Business_Name__c != null ? businessProfile.Business_Name__c : '').escapeCsv() + fileSeparatorComma;
            fileData += (businessProfile.Business_Phone__c != null ? businessProfile.Business_Phone__c : '').escapeCsv() + fileSeparatorComma;
            fileData += (businessProfile.Business_City__c != null ? businessProfile.Business_City__c : '').escapeCsv() + fileSeparatorComma;
            fileData += (businessProfile.Business_State__c != null ? businessProfile.Business_State__r.Display_Name__c : '').escapeCsv() + fileSeparatorComma;
            fileData += (businessProfile.Business_Postal_Code__c != null ? businessProfile.Business_Postal_Code__c : '').escapeCsv() + fileSeparatorComma;
            
            fileData += (stockUnit.Mileage_Value__c != null ? stockUnit.Mileage_Value__c.intValue() + ' ' : '').escapeCsv() + fileSeparatorComma;
            fileData += (stockUnit.get(rvTraderFieldNameToAPIFieldNameMap.get('Fuel type')) != null ? 
                            String.valueOf(stockUnit.get(rvTraderFieldNameToAPIFieldNameMap.get('Fuel type'))) : '').escapeCsv() + fileSeparatorComma;
            fileData += (stockUnit.Colour__c != null ? stockUnit.Colour__c : '').escapeCsv() + fileSeparatorComma;
            
            fileData += (stockUnit.VIN_Number__c != null ? stockUnit.VIN_Number__c : '').escapeCsv() + fileSeparatorComma;
            fileData += 'https://www.streamrv.com/inventory' + fileSeparatorComma;
            
            // Image
            if(stockUnitsMap.containsKey(stockUnit.Id)) {
                for(Document__c document : stockUnitsMap.get(stockUnit.Id).Documents__r) {
                    fileData += (document.Public_Image_URL__c != null ? (document.Public_Image_URL__c) : '').escapeCsv() + fileSeparatorComma;
                }
            }
            fileData += newLineSeparator;
        }
        return fileData;
    }
    
    public static String rvtTypeExport(List<Customer_Owned_Unit__c> stockUnitList, Map<Id, Customer_Owned_Unit__c> stockUnitsMap) {
        String fileData = '';
        for(Customer_Owned_Unit__c stockUnit : stockUnitList) {
            fileData += 'steamrvllc' + fileSeparatorPipe;
            fileData += (stockUnit.Stock_Id__c != null ? stockUnit.Stock_Id__c : '').escapeCsv() + fileSeparatorPipe;
            fileData += (stockUnit.get(rvtFieldNameToAPIFieldNameMap.get('category')) != null ?
                            String.valueOf(stockUnit.get(rvtFieldNameToAPIFieldNameMap.get('category'))) : '').escapeCsv() + fileSeparatorPipe;
            
            fileData += (stockUnit.New_Unit__c ? '1' : '0').escapeCsv() + fileSeparatorPipe;
            fileData += (stockUnit.Year__c != null ? String.valueOf(stockUnit.Year__c.intValue()) : '').escapeCsv() + fileSeparatorPipe;
            fileData += (stockUnit.Unit_Make__r.Name != null ? stockUnit.Unit_Make__r.Name : '').escapeCsv() + fileSeparatorPipe;
            
            fileData += (stockUnit.Unit_Model__r.Name__c != null ? stockUnit.Unit_Model__r.Name__c : '').escapeCsv() + fileSeparatorPipe;
            fileData += (stockUnit.get(rvtFieldNameToAPIFieldNameMap.get('Length')) != null ? 
                            String.valueOf(stockUnit.get(rvtFieldNameToAPIFieldNameMap.get('Length'))) : '').escapeCsv() + fileSeparatorPipe;
            fileData += (stockUnit.Total_Price__c != null ? String.valueOf(stockUnit.Total_Price__c.intValue()) : '').escapeCsv() + fileSeparatorPipe;
            
            fileData += (stockUnit.get(rvtFieldNameToAPIFieldNameMap.get('Fuel type')) != null ? 
                            String.valueOf(stockUnit.get(rvtFieldNameToAPIFieldNameMap.get('Fuel type'))) : '').escapeCsv() + fileSeparatorPipe;
            fileData += (stockUnit.Notes__c != null ? stockUnit.Notes__c : '').escapeCsv() + fileSeparatorPipe;
            fileData += (stockUnit.get(rvtFieldNameToAPIFieldNameMap.get('Features')) != null ? 
                            String.valueOf(stockUnit.get(rvtFieldNameToAPIFieldNameMap.get('Features'))) : '').escapeCsv() + fileSeparatorPipe;
            
            fileData += (stockUnit.Colour__c != null ? stockUnit.Colour__c : '').escapeCsv() + fileSeparatorPipe;
            fileData += (stockUnit.Mileage_Value__c != null ? stockUnit.Mileage_Value__c + ' ' : '').escapeCsv() + fileSeparatorPipe;
            fileData += (stockUnit.get(rvtFieldNameToAPIFieldNameMap.get('Transmission')) != null ? 
                            String.valueOf(stockUnit.get(rvtFieldNameToAPIFieldNameMap.get('Transmission'))) : '').escapeCsv() + fileSeparatorPipe;
            
            
            fileData += (stockUnit.VIN_Number__c != null ? stockUnit.VIN_Number__c : '').escapeCsv() + fileSeparatorPipe;
            fileData += (stockUnit.Date_Stocked_In__c != null ? stockUnit.Date_Stocked_In__c.format() : '').escapeCsv() + fileSeparatorPipe;
            fileData += (stockUnit.LastModifiedDate != null ? stockUnit.LastModifiedDate.format('MM/dd/yyyy') : '').escapeCsv() + fileSeparatorPipe;
            
            // Image
            if(stockUnitsMap.containsKey(stockUnit.Id)) {
                List<String> imageUrls = new List<String>();
                for(Document__c document : stockUnitsMap.get(stockUnit.Id).Documents__r) {
                    if(String.isNotBlank(document.Public_Image_URL__c)) {
                        imageUrls.add(document.Public_Image_URL__c);
                    }
                }
                fileData += (String.join(imageUrls, fileSeparatorComma) + fileSeparatorPipe);
            }
            fileData += newLineSeparator;
        }
        return fileData;
    }
    
    
    public static String createAttachment(String fileContent, String exportType) {
        Attachment attachment = new Attachment();
        attachment.ParentId = getParentId(); 
        attachment.Name = getFileName(exportType);
        attachment.ContentType = exportTypeToContentTypeMap.get(exportType);
        attachment.Body = Blob.valueOf(fileContent);
        DMLUtility.insertSobjectList('Attachment', attachment);
        return attachment.Id;
    }
    
    public static String getParentId() {
        if(!AccessControl.ifObjectFieldIsAccessible('File_Storage__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<File_Storage__c> fileStorageList = [SELECT Id FROM File_Storage__c WHERE Name__c = 'FTP' LIMIT 1];
        
        File_Storage__c fileStorageRec = new File_Storage__c();
        if(fileStorageList.size() > 0) {
            fileStorageRec = fileStorageList[0];
        } else {
            fileStorageRec.Name__c = 'FTP';
            DMLUtility.insertSobjectList('File_Storage__c', fileStorageRec);
        }
        return fileStorageRec.Id;
    }
    
    public static String getFileName(String exportType) {
        String fileName;
        if(exportType == MOTORLOT_EXPORT) {
            fileName = 'motorlot.csv';
        } else if(exportType == RV_TRADER_EXPORT) {
            fileName = 'RV Trader.csv';
        } else if(exportType == RVT_EXPORT) {
            fileName = 'rvdatafeed.txt';
        } else {
            fileName = 'generic.csv';
        }
        return fileName;
    }
    
    public static void sendFileToFTP(String exportType, String attachmentId) {
        String ftpDetailJSON = BPUtility.getEncodedString(System.JSON.serialize(new FTPWrapper(exportType, attachmentId)));
        String endpoint = 'https://blackpurl-som.herokuapp.com/FTPAPI/fetchAndPostFileToFTP/' + ftpDetailJSON;
        
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('GET');
        req.setTimeout(120000);
        req.setHeader('Content-Type', 'application/json');
        if(!Test.isRunningTest()) {
        	HttpResponse res = h.send(req);
	        if(res.getStatusCode() != 200 && res.getStatusCode() != 201) {
	            new LogService().createErrorLog('GenerateExportFileForStockUnitsBatch', 'sendFileToFTP()', res.getBody(), 
	                                                res.getStatusCode(), null, null, null, true);
	        }
        }
    }
    
    public class FTPWrapper {
        public String FtpURL;
        public String Username;
        public String Password;
        public String OrgName;
        public String Namespace;
        public String AttachmentId;
        
        public FTPWrapper(String exportType, String attachmentId) {
            if(!AccessControl.ifObjectFieldIsAccessible('FTP_Config__c')) {throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
            List<FTP_Config__c> ftpConfigs = [SELECT FTP_URL__c, FTP_Username__c, FTP_Password__c, Org_Name__c FROM FTP_Config__c 
                                                WHERE Name =: exportType];
            if(ftpConfigs.size() > 0) {
                this.FtpURL = ftpConfigs[0].FTP_URL__c;
	            this.Username = ftpConfigs[0].FTP_Username__c;
	            this.Password = ftpConfigs[0].FTP_Password__c;
	            this.OrgName = ftpConfigs[0].Org_Name__c;
            }
            this.Namespace = (GeneralConfiguration.getPackageNamespace() == null) ? '' : GeneralConfiguration.getPackageNamespace();
            this.AttachmentId = attachmentId;
        }
    }
}