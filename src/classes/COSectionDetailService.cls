public without sharing class COSectionDetailService {
    
    public static final String MERCHANDISE = 'Merchandise';
    public static final String DEAL_MERCHANDISE  = 'Deal Merchandise';
    public static final String SERVICE = 'Service';
    
    public static final String SO_STATUS_NONE = 'None';
    public static final String SO_STATUS_NEED_TO_ORDER = 'Need to order';
    public static final String SO_STATUS_ORDER_SUBMITTED = 'Order submitted';
    public static final String SO_STATUS_ALL_IN_STOCK = 'All in-stock';
    public static final String SO_STATUS_FULFILLED = 'Fulfilled';
    
    @future
    public static void createCOSection_future(String coHeaderId, String sectionType) {
        createCOSection(coHeaderId, sectionType);
    }
    
    @future
    public static void checkAndCreateCOSection_future(String coHeaderId, String sectionType) {
        List<CO_Header__c> coHeaderList = [SELECT Id, (SELECT Id FROM CO_Section_Details__r WHERE Section_Type__c =: sectionType)
                                                FROM CO_Header__c WHERE Id =: coHeaderId];
        
        if(coHeaderList.size() > 0 && coHeaderList[0].CO_Section_Details__r.size() == 0) {
            createCOSection(coHeaderId, sectionType);
        }
    }
    
    public static void createCOSection(String coHeaderId, String sectionType) {
        CO_Section_Detail__c coSectionDetailRec = setCOSectionValue(coHeaderId, sectionType);
        DMLUtility.insertSobjectList('CO_Section_Detail__c', coSectionDetailRec);
    }
    
    public static CO_Section_Detail__c setCOSectionValue(String coHeaderId, String sectionType) {
        CO_Section_Detail__c coSectionDetailRec = new CO_Section_Detail__c();
        coSectionDetailRec.CO_Header__c = coHeaderId;
        coSectionDetailRec.Section_Type__c = sectionType;
        coSectionDetailRec.Special_Order_Status__c = 'None';
        return coSectionDetailRec;
    }
    
    @future
    public static void checkAndDeleteCOSection_future(String coHeaderId, String sectionType) {
        if(sectionType == DEAL_MERCHANDISE) {
            List<CO_Line_Item__c> dealCOliList = [SELECT Id FROM CO_Line_Item__c WHERE CO_Header__c =: coHeaderId AND Deal__c != null 
                                                      AND Service_Order_Line_Item__c = null];
            if(dealCOliList.size() == 0) {
                deleteCOSection(coHeaderId, sectionType);
            }
        }
    }
    
    @future
    public static void deleteCOSection_future(String coHeaderId, String sectionType) {
        deleteCOSection(coHeaderId, sectionType);
    }
    
    public static void deleteCOSection(String coHeaderId, String sectionType) {
        List<CO_Header__c> coHeaderList = [SELECT Id, (SELECT Id FROM CO_Section_Details__r WHERE Section_Type__c =: sectionType limit 1)
                                                FROM CO_Header__c WHERE Id =: coHeaderId];
                                                
        if(coHeaderList.size() > 0 && coHeaderList[0].CO_Section_Details__r.size() > 0) {
            delete coHeaderList[0].CO_Section_Details__r;
        }
    }
    
    
    
    @future 
    public static void setSectionStatus_future(Set<Id> coHeaderIdSet) {
        setSectionStatus(coHeaderIdSet, null);
    }
    
    @future 
    public static void setSectionStatus_future(Set<Id> coHeaderIdSet, String sectionType) {
        setSectionStatus(coHeaderIdSet, sectionType);
    }
    
    public static void setSectionStatus(Set<Id> coHeaderIdSet, String sectionType) {
        List<CO_Header__c> coHeaderList = 
            [SELECT Id, (SELECT Section_Type__c, Special_Order_Status__c FROM CO_Section_Details__r),
                    (SELECT Invoice_Number__c FROM Service_Order_Headers__r),
                    (SELECT Special_Order_Belongs_To__c, Special_Order_Status__c FROM Vendor_Order_Line_Items__r Order BY Special_Order_Belongs_To__c ASC) 
                 FROM CO_Header__c WHERE Id IN: coHeaderIdSet];
        
        if(String.isBlank(sectionType)) {
            setSOStatusForMerchandise(coHeaderList);
            setSOStatusForServiceJobs(coHeaderList);
        } else if(sectionType == MERCHANDISE || sectionType == DEAL_MERCHANDISE) {
            setSOStatusForMerchandise(coHeaderList);
        } else {
            setSOStatusForServiceJobs(coHeaderList);
        }
    }
    
    public static void setSOStatusForMerchandise(List<CO_Header__c> coHeaderList) {
        
        Map<String, List<CO_Line_Item__c>> coHeaderIdToMerchListMap = new Map<String, List<CO_Line_Item__c>>();
        Map<String, List<CO_Line_Item__c>> coHeaderIdToDealMerchListMap = new Map<String, List<CO_Line_Item__c>>();
        for(CO_Header__c coHeader : coHeaderList) {
            coHeaderIdToMerchListMap.put(coHeader.Id, new List<CO_Line_Item__c>());
            coHeaderIdToDealMerchListMap.put(coHeader.Id, new List<CO_Line_Item__c>());
        }
        
        List<CO_Line_Item__c> coliList = 
            [SELECT CO_Header__c, Service_Order_Line_Item__c, Deal__c, Service_Order_Line_Item__r.Deal__c, Invoice_Number__c,
                    (SELECT Special_Order_Belongs_To__c, Special_Order_Status__c FROM Vendor_Order_Line_Items__r WHERE Is_Received__c = false) 
                FROM CO_Line_Item__c WHERE Part__c != null AND CO_Header__c IN: coHeaderList];
        
        for(CO_Line_Item__c coliRec : coliList) {
            if(coliRec.Deal__c == null && coliRec.Service_Order_Line_Item__c == null) {
                coHeaderIdToMerchListMap.get(coliRec.CO_Header__c).add(coliRec);
            } else if(coliRec.Deal__c != null && coliRec.Service_Order_Line_Item__c == null){
                coHeaderIdToDealMerchListMap.get(coliRec.CO_Header__c).add(coliRec);
            }
        }
        
        List<CO_Section_Detail__c> coSectionDetailList = new List<CO_Section_Detail__c>();
        for(CO_Header__c coHeader : coHeaderList) {
            Map<String, Id> sectionTypeToSectionIdMap = new Map<String, Id>();
            Map<String, String> sectionNameToSOStatusMap = new Map<String, String>();
            
            for(CO_Section_Detail__c sectionDetail : coHeader.CO_Section_Details__r) {
                sectionTypeToSectionIdMap.put(sectionDetail.Section_Type__c, sectionDetail.Id);
                sectionNameToSOStatusMap.put(sectionDetail.Section_Type__c, 'None');
            }
            sectionNameToSOStatusMap.put(MERCHANDISE, getSOStatusForMerchSection(coHeaderIdToMerchListMap.get(coHeader.Id)));
            sectionNameToSOStatusMap.put(DEAL_MERCHANDISE, getSOStatusForMerchSection(coHeaderIdToDealMerchListMap.get(coHeader.Id)));
            
            for(String sectionName : sectionNameToSOStatusMap.keySet()) {
                if(sectionTypeToSectionIdMap.containsKey(sectionName)) {
                    CO_Section_Detail__c sectionDetailRec = new CO_Section_Detail__c(Id = sectionTypeToSectionIdMap.get(sectionName));
                    sectionDetailRec.Special_Order_Status__c = sectionNameToSOStatusMap.get(sectionName);
                    coSectionDetailList.add(sectionDetailRec);
                }
            }
        }
        if(coSectionDetailList.size() > 0) {
            DMLUtility.updateSobjectList('CO_Section_Detail__c', coSectionDetailList);
        }
    }
    
    public static void setSOStatusForServiceJobs(List<CO_Header__c> coHeaderList) {
        
        List<Service_Order_Header__c> soHeaderList = 
            [SELECT Id, (SELECT Id, Service_Order_Header__r.Invoice_Number__c FROM Service_Order_Line_Items__r 
                            WHERE Part__c != null OR Sublet__c != null)
                   FROM Service_Order_Header__c WHERE CO_Header__c IN: coHeaderList];
        
        Map<Id, List<Service_Order_Line_Item__c>> soHeaderIdToSOLIListMap = new Map<Id, List<Service_Order_Line_Item__c>>();
        for(Service_Order_Header__c soHeader : soHeaderList) {
            soHeaderIdToSOLIListMap.put(soHeader.Id, soHeader.Service_Order_Line_Items__r);
        }
        
        
        List<Vendor_Order_Line_Item__c> voliList = 
            [SELECT Related_SOLI__c, Special_Order_Belongs_To__c, Special_Order_Status__c FROM Vendor_Order_Line_Item__c WHERE CO_Header__c IN: coHeaderList 
                    AND Related_SOLI__c != null AND Is_Received__c = false];
        
        Map<String, Map<Id, List<Vendor_Order_Line_Item__c>>> soHeaderToSoliIdToVOLIListMap = new Map<String, Map<Id, List<Vendor_Order_Line_Item__c>>>();
        for(Vendor_Order_Line_Item__c voli : voliList) {
            if(!soHeaderToSoliIdToVOLIListMap.containsKey(voli.Special_Order_Belongs_To__c)) {
                soHeaderToSoliIdToVOLIListMap.put(voli.Special_Order_Belongs_To__c, new Map<Id, List<Vendor_Order_Line_Item__c>>());
            }
            Map<Id, List<Vendor_Order_Line_Item__c>> soliIdToVOLIListMap = soHeaderToSoliIdToVOLIListMap.get(voli.Special_Order_Belongs_To__c);
            if(!soliIdToVOLIListMap.containsKey(voli.Related_SOLI__c)) {
                soliIdToVOLIListMap.put(voli.Related_SOLI__c, new List<Vendor_Order_Line_Item__c>());
            }
            soliIdToVOLIListMap.get(voli.Related_SOLI__c).add(voli);
        }
        
        List<Service_Order_Header__c> serviceJobList = new List<Service_Order_Header__c>();
        Set<String> soHeaderIdSet = new Set<String>();
        for(CO_Header__c coHeader : coHeaderList) {
            Map<String, String> sectionNameToSOStatusMap = new Map<String, String>();
            
            for(Service_Order_Header__c serviceJob : coHeader.Service_Order_Headers__r) {
                soHeaderIdSet.add(serviceJob.Id);
                
                String soId = (String.valueOf(serviceJob.Id)).subString(0, 15);
                if(soHeaderToSoliIdToVOLIListMap.containsKey(soId)) {
                    sectionNameToSOStatusMap.put(serviceJob.Id, 
                        getSOStatusForServiceSection(soHeaderIdToSOLIListMap.get(serviceJob.Id), soHeaderToSoliIdToVOLIListMap.get(soId)));
                } else {
                    sectionNameToSOStatusMap.put(serviceJob.Id, 
                        getSOStatusForServiceSection(soHeaderIdToSOLIListMap.get(serviceJob.Id), new Map<Id, List<Vendor_Order_Line_Item__c>>()));
                }
            }
            
            for(String sectionName : sectionNameToSOStatusMap.keySet()) {
                if(soHeaderIdSet.contains(sectionName)) {
                    Service_Order_Header__c soHeader = new Service_Order_Header__c(Id = sectionName);
                    soHeader.Special_Order_Status__c = sectionNameToSOStatusMap.get(sectionName);
                    serviceJobList.add(soHeader);
                }
            }
        }
        if(serviceJobList.size() > 0) {
            DMLUtility.updateSobjectList('Service_Order_Header__c', serviceJobList);
        }
    }
        
    public static String getSOStatusForServiceSection(List<Service_Order_Line_Item__c> soliList, 
                                                        Map<Id, List<Vendor_Order_Line_Item__c>> soliIdToVOLIListMap) {
        String soStatus;
        if(soliList.size() == 0) {
            soStatus = SO_STATUS_NONE;
        } else if(soliList[0].Service_Order_Header__r.Invoice_Number__c != null) {
            soStatus = SO_STATUS_FULFILLED;
        } else {
            Boolean isAllInStock = true;
            for(Service_Order_Line_Item__c soli : soliList) {
                if(soliIdToVOLIListMap.containsKey(soli.Id) && soliIdToVOLIListMap.get(soli.Id).size() > 0) {
                    isAllInStock = false;
                    break;
                }
            }
            if(isAllInStock) {
                soStatus = SO_STATUS_ALL_IN_STOCK;
            } else {
                for(Service_Order_Line_Item__c soli : soliList) {
                    if(soliIdToVOLIListMap.containsKey(soli.Id)) {
                        for(Vendor_Order_Line_Item__c voli : soliIdToVOLIListMap.get(soli.Id)) {
	                        if(voli.Special_Order_Status__c == SO_STATUS_NEED_TO_ORDER) {
	                            soStatus = SO_STATUS_NEED_TO_ORDER;
	                            break;
	                        } else if(voli.Special_Order_Status__c == SO_STATUS_ORDER_SUBMITTED) {
	                            soStatus = SO_STATUS_ORDER_SUBMITTED;
	                        } else if(voli.Special_Order_Status__c == 'In Stock' && soStatus != SO_STATUS_ORDER_SUBMITTED) {
	                            soStatus = SO_STATUS_ALL_IN_STOCK;
	                        }
	                    }
                    }
                    if(soStatus == SO_STATUS_NEED_TO_ORDER) {
                        break;
                    }
                }
            }
        }
        return soStatus;
    }
    
    
    public static String getSOStatusForMerchSection(List<CO_Line_Item__c> merchList) {
        String soStatus;
        if(merchList.size() == 0) {
            soStatus = SO_STATUS_NONE;
        } else {
            Boolean isAllFullfilled = true;
            for(CO_Line_Item__c coli : merchList) {
                if(coli.Invoice_Number__c == null) {
                    isAllFullfilled = false;
                    break;
                }
            }
            if(isAllFullfilled) {
                soStatus = SO_STATUS_FULFILLED;
            } else {
                Boolean isAllInStock = true;
                for(CO_Line_Item__c coli : merchList) {
	                if(coli.Vendor_Order_Line_Items__r.size() > 0) {
	                    isAllInStock = false;
	                    break;
	                }
	            }
	            if(isAllInStock) {
	                soStatus = SO_STATUS_ALL_IN_STOCK;
	            } else {
	                for(CO_Line_Item__c coli : merchList) {
	                    for(Vendor_Order_Line_Item__c voli : coli.Vendor_Order_Line_Items__r) {
	                        if(voli.Special_Order_Status__c == SO_STATUS_NEED_TO_ORDER) {
	                            soStatus = SO_STATUS_NEED_TO_ORDER;
	                            break;
	                        } else if(voli.Special_Order_Status__c == SO_STATUS_ORDER_SUBMITTED) {
	                            soStatus = SO_STATUS_ORDER_SUBMITTED;
	                        } else if(voli.Special_Order_Status__c == 'In Stock' && soStatus != SO_STATUS_ORDER_SUBMITTED) {
	                            soStatus = SO_STATUS_ALL_IN_STOCK;
	                        }
	                    }
	                    if(soStatus == SO_STATUS_NEED_TO_ORDER) {
	                        break;
	                    }
	                }
	            }
            }
        }
        return soStatus;
    }
}