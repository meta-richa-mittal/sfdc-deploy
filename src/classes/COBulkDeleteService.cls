/**
 * Author: Nidhi Sharma
 * Since: March 05, 2024
 * Name: BPScriptManager
 * Description: Apex class for all scripts executed after package installation
**/
public without sharing class COBulkDeleteService {
    
    private static COBulkDeleteWrapper coBulkDeleteObj;

    public static void deleteBulkCOItems(String coItemsJson) {
        if(coItemsJson != null) {
            coBulkDeleteObj = (COBulkDeleteWrapper) JSON.deserialize(coItemsJson, COBulkDeleteWrapper.class);
            if(String.isNotBlank(coBulkDeleteObj.COHeaderId)) {
                //Merch Section
                if(coBulkDeleteObj.MerchSection != null) {
                    deleteMerchSectionItems(coBulkDeleteObj.MerchSection, coBulkDeleteObj.COHeaderId);
                }
                //Service Sections
                if(coBulkDeleteObj.ServiceSections != null) {
                    for(COBulkDeleteWrapper.SectionWrapper serviceSection : coBulkDeleteObj.ServiceSections) {
                        deleteServiceSectionItems(serviceSection, coBulkDeleteObj.COHeaderId);
                    }
                }
                //Deal Section
                if(coBulkDeleteObj.DealSection != null && String.isNotBlank(coBulkDeleteObj.DealSection.SectionId)) {
                    deleteDealSectionItems(coBulkDeleteObj.DealSection);
                }
                
                if(coBulkDeleteObj.IsDeleteOrder != null && coBulkDeleteObj.IsDeleteOrder) {
                    COService.deleteCustomerOrder(BPUtility.getEncodedString(coBulkDeleteObj.COHeaderId));
                } else {
                    COSectionDetailService.setSectionStatus(new Set<Id>{coBulkDeleteObj.COHeaderId}, null);
                    COService.validateAndCloseCO(coBulkDeleteObj.COHeaderId);
                }
            }
        }
    }

    private static void deleteMerchSectionItems(COBulkDeleteWrapper.SectionWrapper sectionJson, Id coId) {
        if(sectionJson.IsDeleteSection || (sectionJson.LineItemIds != null && !sectionJson.LineItemIds.isEmpty())) {
            List<Id> lineItemIdsToDelete = sectionJson.LineItemIds;
            String query = 'Select Invoice_Number__c FROM CO_Line_Item__c WHERE CO_Header__c =: coId AND Is_In_Merch_Section__c = true AND CO_Kit_Header__c = null AND Deal__c = null';
            if(!sectionJson.IsDeleteSection) query += ' AND Id IN :lineItemIdsToDelete';
            List<CO_Line_Item__c> coliList = Database.query(query);

            query = 'Select Id, (Select Id, Invoice_Number__c from CO_Line_Items__r) FROM CO_Kit_Header__c WHERE CO_Header__c =: coId AND Deal__c = null';
            if(!sectionJson.IsDeleteSection) query += ' AND Id IN :lineItemIdsToDelete';
            List<CO_Kit_Header__c> cokhList = Database.query(query);

            for(CO_Kit_Header__c cokh : cokhList) {
                coliList.addAll(cokh.CO_Line_Items__r);
            }

            validateMerchLIDelete(coliList);

            DMLUtility.deleteSobjectList('CO_Line_Item__c', coliList);
            DMLUtility.deleteSobjectList('CO_Kit_Header__c', cokhList);
        }
        CO_Header__c coRec;
        if(sectionJson.IsDeleteSection != null && sectionJson.IsDeleteSection) {
            coRec = new CO_Header__c(Id = coId, Merchandise_Notes_For_Customer__c = null, Hide_Merchandise_Section__c = true);
        } else if(sectionJson.IsDeleteNotes != null && sectionJson.IsDeleteNotes) {
            coRec = new CO_Header__c(Id = coId, Merchandise_Notes_For_Customer__c = null);
        }
        if(coRec != null) {
            COTriggerHelper.isForceStopTrigger = true;
            DMLUtility.updateSobjectList('CO_Header__c', coRec);
            COTriggerHelper.isForceStopTrigger = false;
        }
    }

    private static void validateMerchLIDelete(List<CO_Line_Item__c> coliList) {
        for(CO_Line_Item__c coli : coliList) {
            if(coli.Invoice_Number__c != null) {
                throw new BlackPurlException('Cannot delete an invoiced items.');
            }
        }
    }

    private static void deleteServiceSectionItems(COBulkDeleteWrapper.SectionWrapper sectionJson, Id coId) {
        if(String.isNotBlank(sectionJson.SectionId)) {
            Id soId = sectionJson.SectionId;
            Service_Order_Header__c soRec = [Select Id, SO_Status__c, Invoice_Number__c FROM Service_Order_Header__c WHERE Id =: sectionJson.SectionId];
            if(String.isNotBlank(soRec.Invoice_Number__c) || soRec.SO_Status__c.equalsIgnoreCase(ServiceJobUtil.INVOICED)) {
                throw new BlackPurlException('Service job is already invoiced.');
            }
            List<Service_Order_Line_Item__c> soliList;
            if(sectionJson.IsDeleteSection || (sectionJson.LineItemIds != null && !sectionJson.LineItemIds.isEmpty())) {
                List<Id> lineItemIdsToDelete = sectionJson.LineItemIds;
                String query = 'Select Service_Order_Header__r.SO_Status__c, Service_Order_Header__r.Invoice_Number__c, Labour_Code__c, ' +
                'Is_Calculate_Supplies__c, Part__c, Sublet__c, (Select Id from Vendor_Order_Line_Items__r where Sublet__c != null AND ' +
                'Vendor_Order_Line_Item_Group__c != null AND Vendor_Order_Header__r.Status__c != \'Open\' AND ' +
                'Vendor_Order_Header__r.Status__c != \'Locked\') FROM Service_Order_Line_Item__c WHERE Service_Order_Header__r.Deal__c = null ' +
                'AND Service_Order_Kit_Header__c = null AND Service_Order_Header__c =: soId';
                if(!sectionJson.IsDeleteSection) query += ' AND Id IN :lineItemIdsToDelete';
                soliList = Database.query(query);

                query = 'Select Service_Order_Header__r.SO_Status__c, Service_Order_Header__r.Invoice_Number__c, ' +
                '(Select Service_Order_Header__c, Is_Calculate_Supplies__c, Labour_Code__c, Part__c, Sublet__c FROM Service_Order_Line_Items__r) '+
                'FROM Service_Order_Kit_Header__c WHERE Service_Order_Header__r.Deal__c = null AND Service_Order_Header__c =: soId';
                if(!sectionJson.IsDeleteSection) query += ' AND Id IN :lineItemIdsToDelete';
                List<Service_Order_Kit_Header__c> sokhList = Database.query(query);
                
                for(Service_Order_Kit_Header__c sokh : sokhList) {
                    soliList.addAll(sokh.Service_Order_Line_Items__r);
                }

                validateServiceLIDelete(soliList);

                DMLUtility.deleteSobjectList('Service_Order_Line_Item__c', soliList);
                DMLUtility.deleteSobjectList('Service_Order_Kit_Header__c', sokhList);
                
                performPostDeleteServiceActions(soliList);

            }
            if((sectionJson.IsDeleteSection != null && sectionJson.IsDeleteSection) || (sectionJson.IsDeleteDocuments != null && sectionJson.IsDeleteDocuments)) {
                delete [Select Id FROM CO_Form__c WHERE Service_Order_Header__c =: soId];
            }
            if((sectionJson.IsDeleteSection != null && sectionJson.IsDeleteSection) || (sectionJson.IsDeleteTechnicianTimes != null && sectionJson.IsDeleteTechnicianTimes)) {
                List<Hours_Logged__c> hrsLoggedList = [Select Id, End_Date_Time__c, Available_For_QB_Sync__c, Available_For_Xero_Sync__c FROM Hours_Logged__c WHERE Service_Order_Header__c =: soId AND Is_Removed__c = false];
                List<Hours_Logged__c> hrsLoggedListToDelete = new List<Hours_Logged__c>();
                List<Hours_Logged__c> hrsLoggedListToUpdate = new List<Hours_Logged__c>();
                for(Hours_Logged__c hrsLogged : hrsLoggedList) {
                    if(hrsLogged.End_Date_Time__c != null) {
                        if(hrsLogged.Available_For_QB_Sync__c || hrsLogged.Available_For_Xero_Sync__c) {
                            throw new BlackPurlException(Constants.HOURS_LOGGED_NOT_EDITABLE);
                        }
                        hrsLogged.Is_Removed__c = true;
                        hrsLoggedListToUpdate.add(hrsLogged);
                    } else {
                        hrsLoggedListToDelete.add(hrsLogged);
                    }
                }
                delete hrsLoggedListToDelete;
                update hrsLoggedListToUpdate;
            }
            if(sectionJson.IsDeleteSection != null && sectionJson.IsDeleteSection) {
                delete new Service_Order_Header__c(Id = soId);
            } else if(sectionJson.IsDeleteNotes != null && sectionJson.IsDeleteNotes) {
                SOTriggerHelper.isForceStopTrigger = true;
                update new Service_Order_Header__c(Id = soId, SO_Notes_For_Customer__c = null);
                SOTriggerHelper.isForceStopTrigger = false;
            }
        }
    }

    private static void validateServiceLIDelete(List<Service_Order_Line_Item__c> soliList) {
        if(soliList != null) {
            for(Service_Order_Line_Item__c soli : soliList) {
                if(soli.Sublet__c != null && !soli.Vendor_Order_Line_Items__r.isEmpty()) {
                    throw new BlackpurlException('Can not remove sublet that is already ordered.');
                }
            }
        }
    }

    private static void performPostDeleteServiceActions(List<Service_Order_Line_Item__c> soliList) {
        Boolean calculateShopSupplies = false;
        String soId;
        for(Service_Order_Line_Item__c soli : soliList) {
            if(soli.Labour_Code__c != null && soli.Is_Calculate_Supplies__c) {
                soId = soli.Service_Order_Header__c;
                break;
            }
        }
        if(String.isNotBlank(soId)) ShopSuppliesService.shopSuppliesCalculation(soId);
    }

    private static void deleteDealSectionItems(COBulkDeleteWrapper.SectionWrapper sectionJson) {
        if(String.isNotBlank(sectionJson.SectionId)) {
            Id dealId = sectionJson.SectionId;
            Deal__c dealRec = [Select Id, Status__c, Invoice_Number__c FROM Deal__c WHERE Id =: sectionJson.SectionId];
            if(dealRec.Status__c.equalsIgnoreCase('Invoiced') || String.isNotBlank(dealRec.Invoice_Number__c)) {
                throw new BlackPurlException('Deal is already invoiced.');
            }
            if(sectionJson.IsDeleteSection || (sectionJson.LineItemIds != null && !sectionJson.LineItemIds.isEmpty())) {
                List<Id> lineItemIdsToDelete = sectionJson.LineItemIds;
                String query = 'Select Status__c, Deal__r.Invoice_Number__c FROM Option_Fee__c WHERE Deal__c =: dealId AND Deal_Kit_Header__c = null';
                if(!sectionJson.IsDeleteSection) query += ' AND Id IN :lineItemIdsToDelete';
                List<Option_Fee__c> ofList = Database.query(query);

                query = 'Select Id, (Select Id FROM Options_Fees__r) FROM Deal_Kit_Header__c WHERE Deal_Item__r.Deal__c =: dealId';
                if(!sectionJson.IsDeleteSection) query += ' AND Id IN :lineItemIdsToDelete';
                List<Deal_Kit_Header__c> dealkhList = Database.query(query);

                for(Deal_Kit_Header__c dealkh : dealkhList) {
                    ofList.addAll(dealkh.Options_Fees__r);
                }
                DMLUtility.deleteSobjectList('Option_Fee__c', ofList);
                DMLUtility.deleteSobjectList('Deal_Kit_Header__c', dealkhList);
            }

            deleteDealFinanceSection(sectionJson.DealFinanceSection);
            deleteDealUnitsAndTradeIns(sectionJson.UnitIds, sectionJson.TradeInIds);

            if((sectionJson.IsDeleteSection != null && sectionJson.IsDeleteSection) || (sectionJson.IsDeleteDocuments != null && sectionJson.IsDeleteDocuments)) {
                delete [Select Id FROM CO_Form__c WHERE Deal__c =: dealId];
            }
            if(sectionJson.IsDeleteSection != null && sectionJson.IsDeleteSection) {
                delete dealRec;
            } else {
                dealRec = DealService.updateStatusForDeal(dealId, false);
                if(sectionJson.IsDeleteNotes != null && sectionJson.IsDeleteNotes) {
                    dealRec.Notes_For_Customer__c = null;
                }
                DealTriggerHelper.isForceStopTrigger = true;
                DMLUtility.updateSobjectList('Deal__c', dealRec);
                DealTriggerHelper.isForceStopTrigger = false;
            }
        }
    }

    private static void deleteDealUnitsAndTradeIns(List<Id> dealUnitIds, List<Id> tradeInIds) {
        if(dealUnitIds != null && !dealUnitIds.isEmpty()) {
            delete [Select Id FROM Deal_Unit_Price_Cost__c WHERE Deal_Item__c IN: dealUnitIds];
        }
        List<Id> dealItemIdsToDelete = new List<Id>();
        if(dealUnitIds != null) dealItemIdsToDelete.addAll(dealUnitIds);
        if(tradeInIds != null) dealItemIdsToDelete.addAll(tradeInIds);
        if(!dealItemIdsToDelete.isEmpty()) {
            List<SObject> orduDeleteList = new List<SObject>();
            List<Customer_Owned_Unit__c> unitUpdateList = new List<Customer_Owned_Unit__c>();
            List<Deal_Item__c> dealItemList = [Select Id, Type__c, Customer_Owned_Unit__r.Status__c, Customer_Owned_Unit__r.Unit_Type__c FROM Deal_Item__c WHERE Id IN: dealItemIdsToDelete];
            for(Deal_Item__c dealItemRec : dealItemList) {
                if(dealItemRec.Type__c.equalsIgnoreCase(Constants.DEAL_ITEM_TYPE_UNIT)) {
                    if(dealItemRec.Customer_Owned_Unit__r.Status__c == 'Reserved' && dealItemRec.Customer_Owned_Unit__r.Unit_Type__c == 'STOCK') {
                        unitUpdateList.add(new Customer_Owned_Unit__c (Id = dealItemRec.Customer_Owned_Unit__c, Status__c = 'Available'));
                    } else if(dealItemRec.Customer_Owned_Unit__r.Status__c == 'Reserved' && dealItemRec.Customer_Owned_Unit__r.Unit_Type__c == 'COU') {
                        unitUpdateList.add(new Customer_Owned_Unit__c (Id = dealItemRec.Customer_Owned_Unit__c, Status__c = 'Active'));
                    } else if(dealItemRec.Customer_Owned_Unit__r.Unit_Type__c == 'ORDU') {
                        if(dealItemRec.Customer_Owned_Unit__r.Status__c == Constants.ON_ORDER_STATUS) {
                            unitUpdateList.add(new Customer_Owned_Unit__c (Id = dealItemRec.Customer_Owned_Unit__c, Is_Ordered_Unit_Added_To_Deal__c = false));
                        } else if ((dealItemRec.Customer_Owned_Unit__r.Status__c.equalsIgnoreCase(Constants.TEMP_ORDERD_UNIT_STATUS) || dealItemRec.Customer_Owned_Unit__r.Status__c.equalsIgnoreCase(Constants.REQ_ORDERD_UNIT_STATUS))) {
                            orduDeleteList.add(new Customer_Owned_Unit__c (Id = dealItemRec.Customer_Owned_Unit__c));      
                        }
                        unitUpdateList.add(new Customer_Owned_Unit__c (Id = dealItemRec.Customer_Owned_Unit__c, Status__c = 'Active'));
                    }
                }
            }
            if(!orduDeleteList.isEmpty()) {
                delete [Select Id FROM Unit_Price_Cost__c WHERE Customer_Owned_Unit__c IN: orduDeleteList];
                DMLUtility.deleteSobjectList('Customer_Owned_Unit__c', orduDeleteList);
            }
            DMLUtility.updateSobjectList('Customer_Owned_Unit__c', unitUpdateList);
            DMLUtility.deleteSobjectList('Deal_Item__c', dealItemList);
        }
    }

    private static void deleteDealFinanceSection(COBulkDeleteWrapper.SectionWrapper sectionJson) {
        if(String.isNotBlank(sectionJson.SectionId)) {
            Id dfId = sectionJson.SectionId;
            if(sectionJson.IsDeleteSection || (sectionJson.LineItemIds != null && !sectionJson.LineItemIds.isEmpty())) {
                List<Id> lineItemIdsToDelete = sectionJson.LineItemIds;
                String query = 'Select Deal_Finance__r.Status__c FROM F_I_Product__c WHERE Deal_Finance__c =: dfId';
                if(!sectionJson.IsDeleteSection) query += ' AND Id IN :lineItemIdsToDelete';
                DMLUtility.deleteSobjectList('F_I_Product__c', Database.query(query));
            }
            if((sectionJson.IsDeleteSection != null && sectionJson.IsDeleteSection) || (sectionJson.IsDeleteDocuments != null && sectionJson.IsDeleteDocuments)) {
                delete [Select Id FROM CO_Form__c WHERE Deal_Finance__c =: dfId];
            }
            if(sectionJson.IsDeleteSection) {
                delete new Deal_Finance__c(Id = dfId);
            }
        }
    }

}