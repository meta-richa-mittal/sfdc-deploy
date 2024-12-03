/**
 * Author: Manoj Sharma
 * Since: April 02, 2020
 * Name: AutomatedPriceFileCtrl
 * Description: AutomatedPriceFileCtrl class.
**/
global without sharing class AutomatedPriceFileCtrl {

    global AutomatedPriceFileCtrl (NewHomePageCtrl controller){}
    public AutomatedPriceFileCtrl() {}

    @RemoteAction
    global static String getAllSubscribedPriceFile() {
        try {
    		return BPUtility.getEncodedString(System.JSON.serialize(AutomatedPriceFileService.getVendorMasterList(), true));
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }

    @RemoteAction
    global static String getVendorMasterDetailsById(String vendorMasterId) {
        vendorMasterId = BPUtility.getDecodedString(vendorMasterId);
        try {
    		return BPUtility.getEncodedString(System.JSON.serialize(AutomatedPriceFileService.getVendorMasterDetailsById(vendorMasterId), true));
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }

    @RemoteAction
    global static String getPriceFileMappingByVendorMasterId(String vendorMasterId) {
        vendorMasterId = BPUtility.getDecodedString(vendorMasterId);
        try {
    		return BPUtility.getEncodedString(System.JSON.serialize(AutomatedPriceFileService.getPriceFileMappingByVendorMasterId(vendorMasterId), true));
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }

    @RemoteAction
    global static String savePriceFileMapping(String recordJSON) {
        recordJSON = BPUtility.getDecodedString(recordJSON);
        try {
    		return BPUtility.getEncodedString(AutomatedPriceFileService.saveAutomatedPriceFileMapping(recordJSON));
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }

    @RemoteAction
    global static String getPartCategories(String vendorMasterId) {
        vendorMasterId = BPUtility.getDecodedString(vendorMasterId);
        try {
    		return BPUtility.getEncodedString(System.JSON.serialize(AutomatedPriceFileService.getPartCategories(vendorMasterId)));
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }

    @RemoteAction
    global static String skipUpdateForVendorMaster(String vendorMasterId) {
        vendorMasterId = BPUtility.getDecodedString(vendorMasterId);
        try {
    		return BPUtility.getEncodedString(System.JSON.serialize(AutomatedPriceFileService.skipUpdateForVendorMaster(vendorMasterId)));
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    @RemoteAction
    global static String importFile(String mappingJSON, String records) {
        mappingJSON = BPUtility.getDecodedString(mappingJSON);
        records = BPUtility.getDecodedString(records);
        try {
            return BPUtility.getEncodedString(System.JSON.serialize(AutomatedPriceFileImportService.importFile(mappingJSON, records)));
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }

    @RemoteAction
    global static String getPriceFileLocationAndConfig(String vendorMasterId, String partnerVendorMasterName) {
        vendorMasterId = BPUtility.getDecodedString(vendorMasterId);
        partnerVendorMasterName = BPUtility.getDecodedString(partnerVendorMasterName);
        try {
            return BPUtility.getEncodedString(System.JSON.serialize(AutomatedPriceFileService.getPriceFileLocationFromPartnerOrg(new Set<String>{partnerVendorMasterName}, vendorMasterId), true));
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    @RemoteAction
    global static String getLastErrorLogNumber() {
        try {
            return BPUtility.getEncodedString(System.JSON.serialize(AutomatedPriceFileImportService.getLastErrorLogNumber(), true));
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }

    @RemoteAction
    global static String updateVMSImportFlagPartnerOrg(String vendorMasterId, String partnerVendorMasterName) {
        vendorMasterId = BPUtility.getDecodedString(vendorMasterId);
        partnerVendorMasterName = BPUtility.getDecodedString(partnerVendorMasterName);
        try {
            return BPUtility.getEncodedString(System.JSON.serialize(AutomatedPriceFileService.updateVendorMasterSubscriberPartnerOrg(new Set<String>{partnerVendorMasterName}, vendorMasterId)));
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    @RemoteAction
    global static void createActivityHistory(String vendorId) {
        PriceFileImportCtrl.createActivityHistory(vendorId);
    }
    
    @RemoteAction
    global static void importSupersessionPart(String importedPartIdList) {
        PriceFileImportCtrl.importSupersessionPart(importedPartIdList);
    }
    
    @RemoteAction
    global static void createFileReadErrorLog(String errorJson) {
        errorJson = BPUtility.getDecodedString(errorJson);
        try {
            AutomatedPriceFileService.createFileReadErrorLog(errorJson);
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }

    @RemoteAction
    global static String getLastImportResults(String vmId) {
        return BPUtility.getEncodedString(System.JSON.serialize(AutomatedPriceFileService.getLastImportResults(BPUtility.getDecodedString(vmId))));
    }

    @RemoteAction
    global static String getAPFRecordProcessingCount() {
        try {
            return BPUtility.getEncodedString(GeneralConfiguration.getConfigurationByName(GeneralConfiguration.APF_RECORD_PROCESSING_COUNT));
        } catch(Exception e) {
            return null;
        }
    }

    @RemoteAction
    global static void queueAPFImport(String vmId) {
        AutomatedPriceFileService.queueAPFImport(BPUtility.getDecodedString(vmId));
    }
}