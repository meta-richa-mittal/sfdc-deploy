public without sharing class COMoveLineItemService {
    
    public static void moveLineItem(String idToMove, String destinationId) {
        destinationId = BPUtility.getDecodedString(destinationId);
        idToMove = BPUtility.getDecodedString(idToMove);
        String idToMoveAPIName = Id.valueOf(idToMove).getSObjectType().getDescribe().getName();
        String destinationIdAPIName = Id.valueOf(destinationId).getSObjectType().getDescribe().getName();
        if(idToMoveAPIName == CONSTANTS.NAMESPACE + 'CO_Line_Item__c') { 
            moveCOLineItem(idToMove, destinationId);
        } else if(idToMoveAPIName == CONSTANTS.NAMESPACE + 'Service_Order_Line_Item__c') { 
            moveSOLineItem(idToMove, destinationId);
        } else if(idToMoveAPIName == CONSTANTS.NAMESPACE + 'CO_Kit_Header__c' ) {
            MoveFromCokhSokh(idToMove, destinationId);
        } else if (idToMoveAPIName == CONSTANTS.NAMESPACE + 'Service_Order_Kit_Header__c') {
            MoveFromSokhCOKH(idToMove, destinationId, '');
        }
    }

    private static String moveCOLineItem(String coliToMove,String destinationId) {
        String destinationIdAPIName = Id.valueOf(destinationId).getSObjectType().getDescribe().getName();

        coliToMove = BPUtility.escapeSingleQuotes(coliToMove);
        destinationId = BPUtility.escapeSingleQuotes(destinationId);
        List<CO_Line_Item__c>  coliListToMove = [Select Id,CO_Header__c, Merchandise_Commit_Order_controls__c, CO_Header__r.Name,Actual_Kit_Price__c,Fixed_Price__c,CO_Fixed_KitLineItem__c,Price__c, Fee__c, Price_When_Tax_Included__c, Deal__c, CO_Header__r.Fees_Bulk_Discount_Percent__c,
                                                    Part__r.Retail_Price__c,Qty_Committed__c,Qty__c,Qty_To_Order__c,Part__c, Tax__c,Item_Code__c,Item_Description__c, Is_Environmental_Fee__c, Is_Linked_Fee__c, CO_Header__r.Parts_Bulk_Discount_Percent__c,
                                                    Status__c, Vendor_Order_Header__c, VO_Number__c, VO_Status__c, Expected_Delivery_Date__c, Pulled__c, Item_ID__c, Service_Order_Line_Item__c, CO_Kit_Header__c, CO_Header__r.Customer__c, CO_Header__r.Customer__r.Price_Level__c,
                                                    (Select Id, Vendor_Order_Line_Item_Group__c, Is_Received__c From Vendor_Order_Line_Items__r), 
                                                    (Select Id, CO_Invoice_Header__c, isActive__c From CO_Invoice_Items__r) 
                                                    FROM CO_Line_Item__c WHERE Id =:coliToMove AND (Fee__c != null OR Part__c != null) AND CO_Kit_Header__c = null];
        if(coliListToMove.isEmpty()){return '';}
        String ItemType = coliListToMove[0].Part__c != null ? 'Part' : 'Fee'; 
        String sourceSection = 'Parts & accessories'; 
        String destinationSection,  destinationCOId; 
        String sourceCOName = coliListToMove[0].CO_Header__r.Name; 
        String currentCOId = coliListToMove[0].CO_Header__c;                                                        
        COLineItemTriggerHelper.isMoveLineItem = true;
        if(destinationIdAPIName == CONSTANTS.NAMESPACE + 'CO_Header__c'){
            COService.createMerchSectionIfNotExist(destinationId); 
            destinationCOId = destinationId;
            destinationSection = 'Parts & accessories';
            List<CO_Header__c> coListToMove = [Select Fees_Bulk_Discount_Percent__c, Parts_Bulk_Discount_Percent__c, Customer__c, Customer__r.Price_Level__c, Merchandise_Commit_Order_controls__c FROM CO_Header__c WHERE Id =: destinationId];

            Boolean isCommitControlsUpdated = coliListToMove[0].Merchandise_Commit_Order_controls__c != coListToMove[0].Merchandise_Commit_Order_controls__c;
            COLineItemTriggerHelper.isMoveLineItem = !isCommitControlsUpdated;
            
            CO_Line_Item__c colirec = new CO_Line_Item__c();
            colirec.CO_Header__c = Id.valueOf(destinationId);
            colirec.Part__c = coliListToMove[0].Part__c;
            colirec.Fee__c = coliListToMove[0].Fee__c;
            colirec.Price__c = coliListToMove[0].Part__r.Retail_Price__c;
            colirec.Qty__c =  coliListToMove[0].Qty__c;
            colirec.Item_Code__c = coliListToMove[0].Item_Code__c;
            colirec.Item_Description__c = coliListToMove[0].Item_Description__c;
            colirec.Merchandise_Commit_Order_controls__c = coListToMove[0].Merchandise_Commit_Order_controls__c;
            DMLUtility.deleteSobjectList('CO_Line_Item__c', coliListToMove);
            DMLUtility.insertSobjectList('CO_Line_Item__c', colirec);
            if((coListToMove[0].Fees_Bulk_Discount_Percent__c == coliListToMove[0].CO_Header__r.Fees_Bulk_Discount_Percent__c && colirec.Fee__c != null) || (coListToMove[0].Parts_Bulk_Discount_Percent__c == coliListToMove[0].CO_Header__r.Parts_Bulk_Discount_Percent__c && colirec.Part__c != null)) {
                colirec.Price_When_Tax_Included__c = coliListToMove[0].Price_When_Tax_Included__c;
                colirec.Price__c = coliListToMove[0].Price__c;
                COLineItemTriggerHelper.isTriggerExecute = false;
                DMLUtility.upsertSobjectList('CO_Line_Item__c', colirec); 
                COTriggerHelper.salesTaxCalculation(null, null, new List<CO_Line_Item__c>{colirec});
            } else {
                TaxCalculation.populateOrderTotal(destinationId, true);
            }
            COSectionDetailService.setSectionStatus(new Set<Id>{currentCOId, destinationId}, COSectionDetailService.MERCHANDISE);
            if(!isCommitControlsUpdated) updateVOLIANDCOLIOnMoveFromColiToSoli(colirec, null, coliListToMove);
        } else if(destinationIdAPIName == CONSTANTS.NAMESPACE + 'Service_Order_Header__c' ){
            List<Service_Order_Header__c> serviceOrderHeaderRecList =  [Select Id, Name__c,CO_Header__c, Commit_Order_Controls__c, Fees_Bulk_Discount_Percent__c, Parts_Bulk_Discount_Percent__c,(Select Id, CO_Invoice_Header__c, isActive__c From CO_Invoice_Items__r),
                                                                                         (Select Qty_To_Order__c From Service_Order_Line_Items__r), Transaction_Type__c, Transaction_Type__r.Type__c 
                                                                                         from Service_Order_Header__c
                                                                                         where  Id =: destinationId];
            Boolean isCommitControlsUpdated = coliListToMove[0].Merchandise_Commit_Order_controls__c != serviceOrderHeaderRecList[0].Commit_Order_Controls__c;
            COLineItemTriggerHelper.isMoveLineItem = !isCommitControlsUpdated;
            Service_Order_Line_Item__c solirec = new Service_Order_Line_Item__c();
            destinationCOId = serviceOrderHeaderRecList[0].CO_Header__c;
            solirec.Part__c = coliListToMove[0].Part__c;
            solirec.Fee__c = coliListToMove[0].Fee__c;
            solirec.Kit_Price__c = coliListToMove[0].Part__r.Retail_Price__c;
            solirec.Qty_Needed__c =  coliListToMove[0].Qty__c;
            solirec.Service_Order_Header__c = Id.valueOf(destinationId);
            solirec.Item_Code__c = coliListToMove[0].Item_Code__c;
            solirec.Item_Description__c = coliListToMove[0].Item_Description__c;
            solirec.Commit_Order_Controls__c = serviceOrderHeaderRecList[0].Commit_Order_Controls__c;
            DMLUtility.deleteSobjectList('CO_Line_Item__c', coliListToMove);
            DMLUtility.insertSobjectList('Service_Order_Line_Item__c', solirec);
            List<CO_Line_Item__c> newlyInsertedCOLIList = updateVOLIANDCOLIOnMoveFromColiToSoli(null, solirec, coliListToMove);
            if(((serviceOrderHeaderRecList[0].Transaction_Type__c != null && serviceOrderHeaderRecList[0].Transaction_Type__r.Type__c == 'Customer') && ((serviceOrderHeaderRecList[0].Fees_Bulk_Discount_Percent__c == coliListToMove[0].CO_Header__r.Fees_Bulk_Discount_Percent__c && solirec.Fee__c != null) || (serviceOrderHeaderRecList[0].Parts_Bulk_Discount_Percent__c == coliListToMove[0].CO_Header__r.Parts_Bulk_Discount_Percent__c && solirec.Part__c != null))) || (serviceOrderHeaderRecList[0].Fees_Bulk_Discount_Percent__c == coliListToMove[0].CO_Header__r.Fees_Bulk_Discount_Percent__c && solirec.Fee__c != null)) {
                solirec.Price_When_Tax_Included__c = coliListToMove[0].Price_When_Tax_Included__c;
                solirec.Kit_Price__c = coliListToMove[0].Price__c;
                ServiceOrderLineItemTriggerHelper.isTriggerExecuted = false;
                DMLUtility.upsertSobjectList('Service_Order_Line_Item__c', solirec); 
                COTriggerHelper.salesTaxCalculation(null, null, newlyInsertedCOLIList);
            } 
            destinationSection = serviceOrderHeaderRecList[0].Name__c;
            if(destinationCOId != currentCOId) {
                COSectionDetailService.setSectionStatus(new Set<Id>{destinationCOId}, COSectionDetailService.SERVICE);
            }        
        }
        InternalCommentService.createInternalCommentsForMoveLineItem(ItemType, coliListToMove[0].Item_ID__c, sourceSection, destinationSection, currentCOId, destinationCOId, sourceCOName);
        COService.validateAndCloseCO(currentCOId);
        COLineItemTriggerHelper.isMoveLineItem = false;
        return 'Sucess';
    }

    public static String moveSOLineItem(String soliToMove, String destinationId) {
        String destinationIdAPIName = Id.valueOf(destinationId).getSObjectType().getDescribe().getName();
        soliToMove = BPUtility.escapeSingleQuotes(soliToMove);
        destinationId = BPUtility.escapeSingleQuotes(destinationId);
        Boolean IsTaxIncludingPricing = GeneralConfiguration.getTaxIncludingPricing();

         List<Service_Order_Line_Item__c> soliItemToMovelist = [SELECT Actual_Kit_Price__c, Service_Order_Header__c, Commit_Order_Controls__c, CO_Line_Item__c, Service_Order_Header__r.CO_Header__r.Name,
                                                                Status__c, Vendor_Order_Header__c, VO_Number__c, Kit_Price__c, Service_Order_Header__r.Name__c, Service_Order_Header__r.Fees_Bulk_Discount_Percent__c,
                                                                VO_Status__c, Expected_Delivery_Date__c, Price_When_Tax_Included__c, Qty_Committed__c, Item_Desc__c, Service_Order_Header__r.Labor_Bulk_Discount_Percent__c,
                                                                CO_Line_Item__r.Status__c, CO_Line_Item__r.Vendor_Order_Header__c, CO_Line_Item__r.VO_Number__c, Service_Order_Header__r.Parts_Bulk_Discount_Percent__c,
                                                                CO_Line_Item__r.VO_Status__c, CO_Line_Item__r.Expected_Delivery_Date__c, CO_Line_Item__r.Pulled__c, Service_Order_Header__r.Sublet_Bulk_Discount_Percent__c,
                                                                Service_Order_Header__r.CO_Header__c, Item_Code__c, Item_Description__c, Qty_Needed__c, Part__c, Labour_Code__c,
                                                                Part__r.Retail_price__c, Part__r.Non_Inventory_Part__c, Part__r.Applicable_Tax__r.Rate__c, Sublet__c, Fee__c, Service_Order_Header__r.Provider__c, 
                                                                Part__r.Part_Number__c, Part__r.Description__c, Service_Order_Header__r.Transaction_Type__c, Service_Order_Header__r.Transaction_Type__r.Type__c,
                                                                Service_Order_Header__r.CO_Header__r.Merchandise_Commit_Order_controls__c, 
                                                                (SELECT Id from Vendor_Order_Line_Items__r WHERE Sublet__c != null AND Is_Received__c = true) 
                                                                FROM Service_Order_Line_Item__c WHERE Id =: soliToMove];
        if(soliItemToMovelist.isEmpty()){return '';}
        String currentCOId = soliItemToMovelist[0].Service_Order_Header__r.CO_Header__c; 
        String sourceSection = soliItemToMovelist[0].Service_Order_Header__r.Name__c; 
        String destinationSection, ItemType, destinationCOId; 
        String sourceCOName = soliItemToMovelist[0].Service_Order_Header__r.CO_Header__r.Name; 
        COLineItemTriggerHelper.isMoveLineItem = true; 
        ServiceOrderLineItemTriggerHelper.isMoveLineItem = true;                                                              
        if(destinationIdAPIName == CONSTANTS.NAMESPACE + 'CO_Header__c'){
            COService.createMerchSectionIfNotExist(destinationId);   

            //Commit Controls
            String destinationCommitControls = CONSTANTS.COMMIT_AND_ORDER;
                for(CO_Header__c coHeader : [Select Merchandise_Commit_Order_controls__c From CO_Header__c where Id =: destinationId]) {
                    destinationCommitControls = coHeader.Merchandise_Commit_Order_controls__c;
                }
            Boolean isCommitControlsUpdated = destinationCommitControls != soliItemToMovelist[0].Commit_Order_Controls__c;  
            
            destinationCOId = destinationId;
            destinationSection = 'Parts & accessories';  
            List<CO_Header__c> coListToMove = [Select Fees_Bulk_Discount_Percent__c, Parts_Bulk_Discount_Percent__c, Customer__c, Customer__r.Price_Level__c FROM CO_Header__c WHERE Id =: destinationId];
            ItemType = soliItemToMovelist[0].Part__c != null ? 'Part' : 'Fee';                                                                          
            CO_Line_Item__c coLineItemRec = new CO_Line_Item__c(CO_Header__c = destinationId);
            coLineItemRec.Qty__c = soliItemToMovelist[0].Qty_Needed__c ;
            coLineItemRec.Pulled__c = soliItemToMovelist[0].CO_Line_Item__r.Pulled__c;
            coLineItemRec.Part__c = soliItemToMovelist[0].Part__c;
            coLineItemRec.Fee__c = soliItemToMovelist[0].Fee__c;
            coLineItemRec.Item_Code__c = soliItemToMovelist[0].Item_Code__c;
            coLineItemRec.Item_Description__c = soliItemToMovelist[0].Item_Description__c;
            coLineItemRec.Merchandise_Commit_Order_controls__c = destinationCommitControls;
            
            List<Vendor_Order_Line_Item__c> voliRecListToUpdate = new List<Vendor_Order_Line_Item__c>();
            if(String.isNotBlank(soliItemToMovelist[0].Part__c) && String.isNotBlank(soliItemToMovelist[0].CO_Line_Item__c)) {
                voliRecListToUpdate = [Select Id, Vendor_Order_Line_Item_Group__c, Is_Received__c From Vendor_Order_Line_Item__c WHERE CO_Line_Item__c =: soliItemToMovelist[0].CO_Line_Item__c];
            }
            COLineItemTriggerHelper.isMoveLineItem = !isCommitControlsUpdated;
            DMLUtility.insertSobjectList('CO_Line_Item__c', coLineItemRec);
            if(!isCommitControlsUpdated && voliRecListToUpdate.size() > 0 && String.isNotBlank(soliItemToMovelist[0].Part__c)) {
                updateVOLIANDCOLIOnPartMoveFromSoliTOColi(voliRecListToUpdate, new List<CO_Line_Item__c>{coLineItemRec}, soliItemToMovelist);
            }
            DMLUtility.deleteSobjectList('Service_Order_Line_Item__c', soliItemToMovelist);
            if(((soliItemToMovelist[0].Service_Order_Header__r.Transaction_Type__c != null && soliItemToMovelist[0].Service_Order_Header__r.Transaction_Type__r.Type__c == 'Customer') && ((coListToMove[0].Fees_Bulk_Discount_Percent__c == soliItemToMovelist[0].Service_Order_Header__r.Fees_Bulk_Discount_Percent__c && coLineItemRec.Fee__c != null) || (coListToMove[0].Parts_Bulk_Discount_Percent__c == soliItemToMovelist[0].Service_Order_Header__r.Parts_Bulk_Discount_Percent__c && coLineItemRec.Part__c != null))) || (coListToMove[0].Fees_Bulk_Discount_Percent__c == soliItemToMovelist[0].Service_Order_Header__r.Fees_Bulk_Discount_Percent__c && coLineItemRec.Fee__c != null)) {
                coLineItemRec.Price_When_Tax_Included__c =soliItemToMovelist[0].Price_When_Tax_Included__c;
                coLineItemRec.Price__c = soliItemToMovelist[0].Kit_Price__c;
                COLineItemTriggerHelper.isVOLIRecToChange = false;
                DMLUtility.updateSobjectList('CO_Line_Item__c', coLineItemRec);
                COLineItemTriggerHelper.isVOLIRecToChange = true;
            } 
            TaxCalculation.populateOrderTotal(destinationId, true);
            COLineItemTriggerHelper.isMoveLineItem = true;
            COSectionDetailService.setSectionStatus(new Set<Id>{currentCOId, destinationId}, null);
        } else if(destinationIdAPIName == CONSTANTS.NAMESPACE + 'Service_Order_Header__c' ){
            List<Service_Order_Line_Item__c> soliListCommittedOnServer = new List<Service_Order_Line_Item__c>(); 
            String sectionFromHeaderId = soliItemToMovelist[0].Service_Order_Header__c;
            List<Vendor_Order_Line_Item__c> voliRecListToUpdate = new List<Vendor_Order_Line_Item__c>();
            String query = 'Select Id, Vendor_Order_Line_Item_Group__c, Is_Received__c, CO_Line_Item__c From Vendor_Order_Line_Item__c';
            
            if(String.isNotBlank(soliItemToMovelist[0].Part__c) && String.isNotBlank(soliItemToMovelist[0].CO_Line_Item__c)) {
                query += ' WHERE CO_Line_Item__c = \'' + soliItemToMovelist[0].CO_Line_Item__c + '\'';
                voliRecListToUpdate = DataBase.query(query);
            } else if(String.isNotBlank(soliItemToMovelist[0].Sublet__c) && String.isNotBlank(soliItemToMovelist[0].Id)) {
                query += ' WHERE Service_Order_Line_Item__c = \'' + soliItemToMovelist[0].Id + '\'';
                voliRecListToUpdate = DataBase.query(query);
            }
            List<Service_Order_Header__c> serviceOrderListToMove = [SELECT Id, CO_Header__c, Commit_Order_Controls__c, Name__c, Transaction_Type__c, Transaction_Type__r.Type__c, Provider__c, Fees_Bulk_Discount_Percent__c, Labor_Bulk_Discount_Percent__c, Parts_Bulk_Discount_Percent__c, Sublet_Bulk_Discount_Percent__c FROM Service_Order_Header__c WHERE Id =: destinationId];
            Boolean isCommitControlsUpdated = serviceOrderListToMove[0].Commit_Order_Controls__c != soliItemToMovelist[0].Commit_Order_Controls__c; 
            COLineItemTriggerHelper.isMoveLineItem = ServiceOrderLineItemTriggerHelper.isMoveLineItem = !isCommitControlsUpdated; 
            DMLUtility.deleteSobjectList('Service_Order_Line_Item__c', soliItemToMovelist);
            if(String.isNotBlank(soliItemToMovelist[0].Part__c)) {
                soliListCommittedOnServer = ServiceJobService.insertPartInGrid(soliItemToMovelist[0].Part__c, destinationId, soliItemToMovelist[0].Qty_Needed__c, null);
            } else if(String.isNotBlank(soliItemToMovelist[0].Labour_Code__c)) {
                soliListCommittedOnServer.add(ServiceJobService.insertLabourInGrid(soliItemToMovelist[0].Labour_Code__c, destinationId, soliItemToMovelist[0].Qty_Needed__c, null, soliItemToMovelist[0].Item_Description__c, null));
            } else if(String.isNotBlank(soliItemToMovelist[0].Fee__c)) {
                soliListCommittedOnServer.add(ServiceJobService.insertFeeInGrid(soliItemToMovelist[0].Fee__c, destinationId, false, new Part__c(), soliItemToMovelist[0].Qty_Needed__c, null));
            } else if(String.isNotBlank(soliItemToMovelist[0].Sublet__c)) {
                soliListCommittedOnServer.add(ServiceJobService.insertProductInGrid(soliItemToMovelist[0].Sublet__c, destinationId, soliItemToMovelist[0].Qty_Needed__c, null));
            } 

            if(!soliListCommittedOnServer.isEmpty()) {
                soliListCommittedOnServer[0].Item_Description__c = soliItemToMovelist[0].Item_Description__c;
                soliListCommittedOnServer[0].Item_Code__c = soliItemToMovelist[0].Item_Code__c;
            }          
            if(serviceOrderListToMove.size() > 0 && serviceOrderListToMove[0].Transaction_Type__c != null && soliItemToMovelist[0].Service_Order_Header__r.Transaction_Type__c != null && 
                serviceOrderListToMove[0].Transaction_Type__r.Type__c == soliItemToMovelist[0].Service_Order_Header__r.Transaction_Type__r.Type__c && serviceOrderListToMove[0].Provider__c == soliItemToMovelist[0].Service_Order_Header__r.Provider__c && 
                (serviceOrderListToMove[0].Transaction_Type__r.Type__c != 'Customer' || (serviceOrderListToMove[0].Transaction_Type__r.Type__c == 'Customer' && ((serviceOrderListToMove[0].Fees_Bulk_Discount_Percent__c == soliItemToMovelist[0].Service_Order_Header__r.Fees_Bulk_Discount_Percent__c && soliItemToMovelist[0].Fee__c != null) || (serviceOrderListToMove[0].Parts_Bulk_Discount_Percent__c == soliItemToMovelist[0].Service_Order_Header__r.Parts_Bulk_Discount_Percent__c && soliItemToMovelist[0].Part__c != null)
                || (serviceOrderListToMove[0].Sublet_Bulk_Discount_Percent__c == soliItemToMovelist[0].Service_Order_Header__r.Sublet_Bulk_Discount_Percent__c && soliItemToMovelist[0].Sublet__c != null) || (serviceOrderListToMove[0].Labor_Bulk_Discount_Percent__c == soliItemToMovelist[0].Service_Order_Header__r.Labor_Bulk_Discount_Percent__c && soliItemToMovelist[0].Labour_Code__c != null))))) {
                    soliListCommittedOnServer[0].Kit_Price__c = soliItemToMovelist[0].Kit_Price__c;
                    soliListCommittedOnServer[0].Price_When_Tax_Included__c = soliItemToMovelist[0].Price_When_Tax_Included__c;
                    ServiceOrderLineItemTriggerHelper.isTriggerExecuted = false;
                    DMLUtility.upsertSobjectList('Service_Order_Line_Item__c', soliListCommittedOnServer);
            } else if((serviceOrderListToMove[0].Fees_Bulk_Discount_Percent__c == soliItemToMovelist[0].Service_Order_Header__r.Fees_Bulk_Discount_Percent__c && soliItemToMovelist[0].Fee__c != null) || (serviceOrderListToMove[0].Sublet_Bulk_Discount_Percent__c == soliItemToMovelist[0].Service_Order_Header__r.Sublet_Bulk_Discount_Percent__c && soliItemToMovelist[0].Sublet__c != null)) {
                soliListCommittedOnServer[0].Kit_Price__c = soliItemToMovelist[0].Kit_Price__c;
                soliListCommittedOnServer[0].Price_When_Tax_Included__c = soliItemToMovelist[0].Price_When_Tax_Included__c;
                ServiceOrderLineItemTriggerHelper.isTriggerExecuted = false;
                DMLUtility.upsertSobjectList('Service_Order_Line_Item__c', soliListCommittedOnServer);
            } else {
                ServiceOrderLineItemTriggerHelper.shouldTriggerRunStop = true;
                DMLUtility.upsertSobjectList('Service_Order_Line_Item__c', soliListCommittedOnServer);
                ServiceOrderLineItemTriggerHelper.shouldTriggerRunStop = false;
                                
            } 
            destinationCOId = serviceOrderListToMove[0].CO_Header__c;
            ItemType = soliItemToMovelist[0].Part__c != null ? 'Part' : (soliItemToMovelist[0].Fee__c != null ? 'Fee' : (soliItemToMovelist[0].Sublet__c != null ? 'Sublet' : 'Labor'));                                                                          

            destinationSection = serviceOrderListToMove[0].Name__c;
            if(voliRecListToUpdate.size() > 0 && !isCommitControlsUpdated) {
                if(String.isNotBlank(soliItemToMovelist[0].Part__c)) {
                    List<CO_Line_Item__c>  newlyInsertedCOLIList = [Select Id, Service_Order_Line_Item__c, CO_Header__c From CO_Line_Item__c 
                                                                    WHERE Service_Order_Line_Item__c IN: soliListCommittedOnServer AND Part__c != null];
                    updateVOLIANDCOLIOnPartMoveFromSoliTOColi(voliRecListToUpdate, newlyInsertedCOLIList, soliItemToMovelist);
                } else if(String.isNotBlank(soliItemToMovelist[0].Sublet__c)) {
                    updateVOLIANDCOLIOnSubletMoveFromSoliTOColi(voliRecListToUpdate, soliListCommittedOnServer[0].Id, soliItemToMovelist);
                }
            }
            if(destinationCOId != currentCOId) {
                COSectionDetailService.setSectionStatus(new Set<Id>{destinationCOId}, COSectionDetailService.SERVICE);
            }  
        }
        InternalCommentService.createInternalCommentsForMoveLineItem(ItemType, soliItemToMovelist[0].Item_Desc__c, sourceSection, destinationSection, currentCOId, destinationCOId, sourceCOName);
        ServiceOrderLineItemTriggerHelper.isMoveLineItem = false;                                                              
        COLineItemTriggerHelper.isMoveLineItem = false;
        return 'Sucess';
    }

    // function to move kit item
    private static String MoveFromCokhSokh(String kitIdToMove,String sectionToMove){
        Savepoint sp = Database.setSavepoint();
        kitIdToMove = BPUtility.escapeSingleQuotes(kitIdToMove);
        String destinationIdAPIName = Id.valueOf(sectionToMove).getSObjectType().getDescribe().getName();
        
        list<CO_Kit_Header__c> coKitHeaderToMovelist =new  list<CO_Kit_Header__c>([select Id,Tax_amount__c,Actual_Kit_Price__c,Can_Split__c,CO_Fixed_KitHeader__c,Kit_Header__r.Code__c, Kit_Header__r.Kit_Unique_Name__c,
                                                                                  Kit_Header__r.Description__c,CO_Header__c, CO_Header__r.Name,CO_Header__r.Customer__c,Fixed_Price_Flag__c,Kit_Header__c,Price__c,Service_Kit__c,
                                                                                  (select Id,Actual_Kit_Price__c,Fixed_Price__c,CO_Fixed_KitLineItem__c,Price__c,Item_Code__c, Fee__c, Price_When_Tax_Included__c,
                                                                                  Item_Description__c,Qty_Committed__c,Qty__c,Qty_To_Order__c,Part__c, Tax__c, Is_Environmental_Fee__c, Is_Linked_Fee__c,
                                                                                  Kit_Header_Line_Item__c, Status__c, Vendor_Order_Header__c, VO_Number__c, VO_Status__c, Expected_Delivery_Date__c   
                                                                                  from CO_Line_Items__r ), CO_Header__r.Merchandise_Commit_Order_controls__c, CO_Header__r.Fees_Bulk_Discount_Percent__c, CO_Header__r.Parts_Bulk_Discount_Percent__c,
                                                                                  (Select Id, CO_Invoice_Header__c, isActive__c From CO_Invoice_Items__r)                       
                                                                                  from CO_Kit_Header__c where Id =: kitIdToMove]);
        
        List<Vendor_Order_Line_Item__c> voliRecListToUpdate = new List<Vendor_Order_Line_Item__c>();
        if(String.isNotBlank(coKitHeaderToMovelist[0].Id)) {
            voliRecListToUpdate = [Select Id, Vendor_Order_Line_Item_Group__c, Is_Received__c, CO_Line_Item__r.Kit_Header_Line_Item__c From Vendor_Order_Line_Item__c WHERE CO_Line_Item__r.CO_Kit_Header__c =: coKitHeaderToMovelist[0].Id];
        }
        String sourceSection = 'Parts & accessories'; 
        String destinationSection,  destinationCOId; 
        String sourceCOName = coKitHeaderToMovelist[0].CO_Header__r.Name; 
        String currentCOId = coKitHeaderToMovelist[0].CO_Header__c;     
        COLineItemTriggerHelper.isMoveLineItem = true;
        if(destinationIdAPIName == CONSTANTS.NAMESPACE + 'CO_Header__c'){
            COService.createMerchSectionIfNotExist(sectionToMove); 
            destinationSection = 'Parts & accessories'; 
            destinationCOId = sectionToMove;
            List<CO_Header__c> destinationCOList = [Select Fees_Bulk_Discount_Percent__c, Parts_Bulk_Discount_Percent__c, Merchandise_Commit_Order_controls__c FROM CO_Header__c WHERE Id =: destinationCOId];

            //Commit Controls
            String sourceCommitControls = coKitHeaderToMovelist[0].CO_Header__r.Merchandise_Commit_Order_controls__c;
            String destinationCommitControls = destinationCOList[0].Merchandise_Commit_Order_controls__c;
            Boolean isCommitControlsUpdated = destinationCommitControls != sourceCommitControls;
            if(isCommitControlsUpdated) COLineItemTriggerHelper.isMoveLineItem = false;
            MerchandiseService.removeCOKHItems(coKitHeaderToMovelist[0].Id);
            Id cokhId = MerchandiseService.insertMerchKit(System.JSON.serialize(new CustomerOrderWrapper.LineItemWrapper(coKitHeaderToMovelist[0].Kit_Header__c, null)), sectionToMove);
            List<CO_Kit_Header__c> newlyInsertedCOKitList = new List<CO_Kit_Header__c>();

            if((destinationCOList[0].Fees_Bulk_Discount_Percent__c == coKitHeaderToMovelist[0].CO_Header__r.Fees_Bulk_Discount_Percent__c) || (destinationCOList[0].Parts_Bulk_Discount_Percent__c == coKitHeaderToMovelist[0].CO_Header__r.Parts_Bulk_Discount_Percent__c)) {
                newlyInsertedCOKitList = COKH_Recalcualtion.getCOKitRecList(new Set<Id>{cokhId}, destinationCOId).values();

                List<CO_Line_Item__c> coliListToUpdate = new List<CO_Line_Item__c>();
                Map<String, CO_Line_Item__c> kitLiIdToColiMap = new Map<String, CO_Line_Item__c>();

                for(CO_Kit_Header__c kitRec : coKitHeaderToMovelist) {
                    for(CO_Line_Item__c coliRec : kitRec.CO_Line_Items__r) {
                        kitLiIdToColiMap.put(coliRec.Kit_Header_Line_Item__c, coliRec);
                    }
                } 

                for(CO_Kit_Header__c kitRec : newlyInsertedCOKitList) {
                    for(CO_Line_Item__c coliRec : kitRec.CO_Line_Items__r) {
                        coliRec.Merchandise_Commit_Order_controls__c = destinationCommitControls;
                        if(kitLiIdToColiMap.containsKey(coliRec.Kit_Header_Line_Item__c) && ((destinationCOList[0].Parts_Bulk_Discount_Percent__c == coKitHeaderToMovelist[0].CO_Header__r.Parts_Bulk_Discount_Percent__c && coliRec.Part__c != null) || (destinationCOList[0].Fees_Bulk_Discount_Percent__c == coKitHeaderToMovelist[0].CO_Header__r.Fees_Bulk_Discount_Percent__c && coliRec.Fee__c != null))) {
                            colirec.Price_When_Tax_Included__c = kitLiIdToColiMap.get(coliRec.Kit_Header_Line_Item__c).Price_When_Tax_Included__c;
                            colirec.Price__c = kitLiIdToColiMap.get(coliRec.Kit_Header_Line_Item__c).Price__c;
                            coliListToUpdate.add(colirec);
                        }    
                    }
                    
                } 
                if(!coliListToUpdate.isEmpty()) {
                    COLineItemTriggerHelper.isTriggerExecute = false;
                    DMLUtility.updateSobjectList('CO_Line_Item__c', coliListToUpdate);   
                    newlyInsertedCOKitList = COKH_Recalcualtion.applySalesTax(newlyInsertedCOKitList, destinationCOId);
                    DMLUtility.updateSobjectList('CO_Kit_Header__c', newlyInsertedCOKitList);   
                    TaxCalculation.populateOrderTotal(destinationCOId, true);
                }
            } 
            if(!isCommitControlsUpdated && voliRecListToUpdate.size() > 0) {
                if(newlyInsertedCOKitList.isEmpty()) newlyInsertedCOKitList = COKH_Recalcualtion.getCOKitRecList(new Set<Id>{cokhId}, destinationCOId).values();
                updateVOLIANDCOLIOnMoveFromCokhSokh(null, newlyInsertedCOKitList, voliRecListToUpdate);
            }
            if(destinationCOId != currentCOId) {
                COSectionDetailService.setSectionStatus(new Set<Id>{destinationCOId}, COSectionDetailService.MERCHANDISE);
            }
        } else if(destinationIdAPIName == CONSTANTS.NAMESPACE + 'Service_Order_Header__c') {
            List<Service_Order_Header__c> serviceOrderHeaderList = [Select Commit_Order_Controls__c, Fees_Bulk_Discount_Percent__c, Parts_Bulk_Discount_Percent__c, CO_Header__c, Name__c, Transaction_Type__c, Transaction_Type__r.Type__c from Service_Order_Header__c where Id =: sectionToMove];
            destinationSection = serviceOrderHeaderList[0].Name__c; 
            destinationCOId = serviceOrderHeaderList[0].CO_Header__c;

            String sourceCommitControls = coKitHeaderToMovelist[0].CO_Header__r.Merchandise_Commit_Order_controls__c;
            Boolean isCommitControlsUpdated = sourceCommitControls != serviceOrderHeaderList[0].Commit_Order_Controls__c;
            COLineItemTriggerHelper.isMoveLineItem = !isCommitControlsUpdated;
            MerchandiseService.removeCOKHItems(coKitHeaderToMovelist[0].Id);
            Id soKHId = ServiceJobService.insertKitHeaderInGrid(coKitHeaderToMovelist[0].Kit_Header__c, sectionToMove, null);
            
            if(voliRecListToUpdate.size() > 0 && !isCommitControlsUpdated) {
                updateVOLIANDCOLIOnMoveFromCokhSokh(soKHId, coKitHeaderToMovelist, voliRecListToUpdate);
            }
            
            SO_KLI_Recalculation.soKitPriceCalculation(new Set<Id>{soKHId}, new Set<Id>{sectionToMove}, null);
            if(ServiceJobService.hasLabor) {
                ShopSuppliesService.shopSuppliesCalculation(sectionToMove);
            }

            if((serviceOrderHeaderList[0].Transaction_Type__c != null && serviceOrderHeaderList[0].Transaction_Type__r.Type__c == 'Customer') && ((serviceOrderHeaderList[0].Fees_Bulk_Discount_Percent__c == coKitHeaderToMovelist[0].CO_Header__r.Fees_Bulk_Discount_Percent__c) || (serviceOrderHeaderList[0].Parts_Bulk_Discount_Percent__c == coKitHeaderToMovelist[0].CO_Header__r.Parts_Bulk_Discount_Percent__c))) {
                List<Service_Order_Kit_Header__c> newlyInsertedSOKitList = SO_KLI_Recalculation.getSOKitRecList(new Set<Id>{soKHId}, null, null);

                List<Service_Order_Line_Item__c> soliListToUpdate = new List<Service_Order_Line_Item__c>();
                Map<String, CO_Line_Item__c> kitLiIdToColiMap = new Map<String, CO_Line_Item__c>();
                
                for(CO_Kit_Header__c kitRec : coKitHeaderToMovelist) {
                    for(CO_Line_Item__c coliRec : kitRec.CO_Line_Items__r) {
                        kitLiIdToColiMap.put(coliRec.Kit_Header_Line_Item__c, coliRec);
                    }
                } 

                for(Service_Order_Kit_Header__c kitRec : newlyInsertedSOKitList) {
                    for(Service_Order_Line_Item__c soliRec : kitRec.Service_Order_Line_Items__r) {
                        if(kitLiIdToColiMap.containsKey(soliRec.Kit_Header_Line_Item__c) && ((serviceOrderHeaderList[0].Parts_Bulk_Discount_Percent__c == coKitHeaderToMovelist[0].CO_Header__r.Parts_Bulk_Discount_Percent__c && soliRec.Part__c != null) || (serviceOrderHeaderList[0].Fees_Bulk_Discount_Percent__c == coKitHeaderToMovelist[0].CO_Header__r.Fees_Bulk_Discount_Percent__c && soliRec.Fee__c != null))) {
                            soliRec.Price_When_Tax_Included__c = kitLiIdToColiMap.get(soliRec.Kit_Header_Line_Item__c).Price_When_Tax_Included__c;
                            soliRec.Kit_Price__c = kitLiIdToColiMap.get(soliRec.Kit_Header_Line_Item__c).Price__c;
                            soliListToUpdate.add(soliRec);
                        }    
                    }
                    
                } 
                if(!soliListToUpdate.isEmpty()) {
                    COLineItemTriggerHelper.isTriggerExecute = false;
                    DMLUtility.updateSobjectList('Service_Order_Line_Item__c', soliListToUpdate);  
                    newlyInsertedSOKitList = SO_KLI_Recalculation.applySalesTax(newlyInsertedSOKitList, new Set<Id>{sectionToMove}, null);
                    DMLUtility.updateSobjectList('Service_Order_Kit_Header__c', newlyInsertedSOKitList);   
                }           
            } 
            if(destinationCOId != currentCOId) {
                COSectionDetailService.setSectionStatus(new Set<Id>{destinationCOId}, COSectionDetailService.SERVICE);
            }
        }
        COLineItemTriggerHelper.isMoveLineItem = false;
        InternalCommentService.createInternalCommentsForMoveLineItem('Kit', coKitHeaderToMovelist[0].Kit_Header__r.Kit_Unique_Name__c, sourceSection, destinationSection, currentCOId, destinationCOId, sourceCOName);
        COService.validateAndCloseCO(currentCOId);
        return null;
    }

    private static String MoveFromSokhCOKH(String kitIdToMove,String sectionToMove,String CoheaderId) {
        Savepoint sp = Database.setSavepoint();
        String destinationIdAPIName = Id.valueOf(sectionToMove).getSObjectType().getDescribe().getName();
        
        kitIdToMove = BPUtility.escapeSingleQuotes(kitIdToMove);
        list<Service_Order_Kit_Header__c> serviceOrderKitHeaderListToMove = SO_KLI_Recalculation.getSOKitRecList(new Set<Id>{kitIdToMove}, null, null);
        boolean IsTaxIncludingPricing = GeneralConfiguration.getTaxIncludingPricing(); 
        String currentCOId = serviceOrderKitHeaderListToMove[0].Service_Order_Header__r.CO_Header__c; 
        String sourceSection = serviceOrderKitHeaderListToMove[0].Service_Order_Header__r.Name__c; 
        String destinationSection, destinationCOId; 
        String sourceCOName = serviceOrderKitHeaderListToMove[0].Service_Order_Header__r.CO_Header__r.Name;                                                                                                        
        if(destinationIdAPIName == CONSTANTS.NAMESPACE + 'Service_Order_Header__c') {
            List<Service_Order_Header__c> serviceOrderListToMove = [SELECT Id, Fees_Bulk_Discount_Percent__c, Commit_Order_Controls__c, Labor_Bulk_Discount_Percent__c, Parts_Bulk_Discount_Percent__c, CO_Header__c, Name__c, Transaction_Type__c, Transaction_Type__r.Type__c, Provider__c FROM Service_Order_Header__c WHERE Id =: sectionToMove];
            destinationCOId = serviceOrderListToMove[0].CO_Header__c;
            destinationSection = serviceOrderListToMove[0].Name__c;
            Boolean isCommitControlsUpdated = serviceOrderListToMove[0].Commit_Order_Controls__c != serviceOrderKitHeaderListToMove[0].Service_Order_Header__r.Commit_Order_Controls__c; 
            COLineItemTriggerHelper.isMoveLineItem = !isCommitControlsUpdated;
            List<Vendor_Order_Line_Item__c> voliRecListToUpdate = new List<Vendor_Order_Line_Item__c>();
            if(String.isNotBlank(serviceOrderKitHeaderListToMove[0].Id)) {
                voliRecListToUpdate = [Select Id, CO_Line_Item__r.Service_Order_Line_Item__r.Kit_Header_Line_Item__c From Vendor_Order_Line_Item__c 
                                                                        WHERE CO_Line_Item__r.Service_Order_Line_Item__r.Service_Order_Kit_Header__c =: serviceOrderKitHeaderListToMove[0].Id];
            }
            ServiceJobService.removeSOKHItems(serviceOrderKitHeaderListToMove[0].Id);
            Id soKHId = ServiceJobService.insertKitHeaderInGrid(serviceOrderKitHeaderListToMove[0].Kit_Header__c, sectionToMove, null);
            COLineItemTriggerHelper.isMoveLineItem = false;
            
            SO_KLI_Recalculation.soKitPriceCalculation(new Set<Id>{soKHId}, new Set<Id>(), serviceOrderListToMove[0].CO_header__c);
            
            if(voliRecListToUpdate.size() > 0 && !isCommitControlsUpdated) {
                updateVOLIANDCOLIOnMoveFromSokhCOKH(new Map<String, Id>{'Service_Order_Line_Item__r.Service_Order_Kit_Header__c' => soKHId}, serviceOrderKitHeaderListToMove, voliRecListToUpdate);
            }

            if(serviceOrderListToMove.size() > 0 && serviceOrderListToMove[0].Transaction_Type__c != null && serviceOrderKitHeaderListToMove[0].Service_Order_Header__r.Transaction_Type__c != null && 
                serviceOrderListToMove[0].Transaction_Type__r.Type__c == serviceOrderKitHeaderListToMove[0].Service_Order_Header__r.Transaction_Type__r.Type__c && serviceOrderListToMove[0].Provider__c == serviceOrderKitHeaderListToMove[0].Service_Order_Header__r.Provider__c && 
                (serviceOrderListToMove[0].Transaction_Type__r.Type__c != 'Customer' || (serviceOrderListToMove[0].Transaction_Type__r.Type__c == 'Customer' && ((serviceOrderListToMove[0].Fees_Bulk_Discount_Percent__c == serviceOrderKitHeaderListToMove[0].Service_Order_Header__r.Fees_Bulk_Discount_Percent__c) || (serviceOrderListToMove[0].Parts_Bulk_Discount_Percent__c == serviceOrderKitHeaderListToMove[0].Service_Order_Header__r.Parts_Bulk_Discount_Percent__c)
                || (serviceOrderListToMove[0].Labor_Bulk_Discount_Percent__c == serviceOrderKitHeaderListToMove[0].Service_Order_Header__r.Labor_Bulk_Discount_Percent__c))))) {
                
                List<Service_Order_Kit_Header__c> newlyInsertedSOKitList = SO_KLI_Recalculation.getSOKitRecList(new Set<Id>{soKHId}, null, null);

                List<Service_Order_Line_Item__c> soliListToUpdate = new List<Service_Order_Line_Item__c>();
                Map<String, Service_Order_Line_Item__c> kitLiIdToSoliMap = new Map<String, Service_Order_Line_Item__c>();
                
                for(Service_Order_Kit_Header__c kitRec : serviceOrderKitHeaderListToMove) {
                    for(Service_Order_Line_Item__c soliRec : kitRec.Service_Order_Line_Items__r) {
                        kitLiIdToSoliMap.put(soliRec.Kit_Header_Line_Item__c, soliRec);
                    }
                } 

                for(Service_Order_Kit_Header__c kitRec : newlyInsertedSOKitList) {
                    for(Service_Order_Line_Item__c soliRec : kitRec.Service_Order_Line_Items__r) {
                        if(kitLiIdToSoliMap.containsKey(soliRec.Kit_Header_Line_Item__c) && ((serviceOrderListToMove[0].Parts_Bulk_Discount_Percent__c == serviceOrderKitHeaderListToMove[0].Service_Order_Header__r.Parts_Bulk_Discount_Percent__c && soliRec.Part__c != null) || (serviceOrderListToMove[0].Fees_Bulk_Discount_Percent__c == serviceOrderKitHeaderListToMove[0].Service_Order_Header__r.Fees_Bulk_Discount_Percent__c && soliRec.Fee__c != null)  || (serviceOrderListToMove[0].Labor_Bulk_Discount_Percent__c == serviceOrderKitHeaderListToMove[0].Service_Order_Header__r.Labor_Bulk_Discount_Percent__c && soliRec.Labour_Code__c != null))) {
                            soliRec.Price_When_Tax_Included__c = kitLiIdToSoliMap.get(soliRec.Kit_Header_Line_Item__c).Price_When_Tax_Included__c;
                            soliRec.Kit_Price__c = kitLiIdToSoliMap.get(soliRec.Kit_Header_Line_Item__c).Kit_Price__c;
                            soliListToUpdate.add(soliRec);
                        }    
                    }
                    
                } 
                if(!soliListToUpdate.isEmpty()) {
                    COLineItemTriggerHelper.isTriggerExecute = false;
                    DMLUtility.updateSobjectList('Service_Order_Line_Item__c', soliListToUpdate);  
                    newlyInsertedSOKitList = SO_KLI_Recalculation.applySalesTax(newlyInsertedSOKitList, new Set<Id>{sectionToMove}, null);
                    DMLUtility.updateSobjectList('Service_Order_Kit_Header__c', newlyInsertedSOKitList);   
                }  
            }
            if(destinationCOId != currentCOId) {
                COSectionDetailService.setSectionStatus(new Set<Id>{destinationCOId}, COSectionDetailService.SERVICE);
            }
            
        } else if(destinationIdAPIName == CONSTANTS.NAMESPACE + 'CO_Header__c'){
            destinationCOId = sectionToMove;
            destinationSection = 'Parts & accessories';  
            List<CO_Header__c> destinationCOList = [Select Fees_Bulk_Discount_Percent__c, Parts_Bulk_Discount_Percent__c, Merchandise_Commit_Order_controls__c, Customer__c, Customer__r.Price_Level__c FROM CO_Header__c WHERE Id =: destinationCOId];

            List<Vendor_Order_Line_Item__c> voliRecListToUpdate = new List<Vendor_Order_Line_Item__c>();
            if(String.isNotBlank(serviceOrderKitHeaderListToMove[0].Id)) {
                voliRecListToUpdate = [Select Id, CO_Line_Item__r.Service_Order_Line_Item__r.Kit_Header_Line_Item__c From Vendor_Order_Line_Item__c 
                                                                        WHERE CO_Line_Item__r.Service_Order_Line_Item__r.Service_Order_Kit_Header__c =: serviceOrderKitHeaderListToMove[0].Id];
            }
            COLineItemTriggerHelper.isMoveLineItem = true;
            Boolean isCommitControlsUpdated = false;
            String destinationCommitControls = Constants.COMMIT_AND_ORDER;
                    for(CO_Header__c coHeader : destinationCOList) {
                        destinationCommitControls = coHeader.Merchandise_Commit_Order_controls__c;
                    }
            isCommitControlsUpdated = destinationCommitControls != serviceOrderKitHeaderListToMove[0].Service_Order_Header__r.Commit_Order_Controls__c; 
            COLineItemTriggerHelper.isMoveLineItem = !isCommitControlsUpdated;
            Id cokhId = MerchandiseService.insertMerchKit(System.JSON.serialize(new CustomerOrderWrapper.LineItemWrapper(serviceOrderKitHeaderListToMove[0].Kit_Header__c, null)), sectionToMove);
            ServiceJobService.removeSOKHItems(serviceOrderKitHeaderListToMove[0].Id);
            COLineItemTriggerHelper.isMoveLineItem = false;
            
            if(!isCommitControlsUpdated && voliRecListToUpdate.size() > 0) {
                updateVOLIANDCOLIOnMoveFromSokhCOKH(new Map<String, Id>{'CO_Kit_Header__c' => cokhId}, serviceOrderKitHeaderListToMove, voliRecListToUpdate);
            }

            if((serviceOrderKitHeaderListToMove[0].Service_Order_Header__r.Transaction_Type__c != null && serviceOrderKitHeaderListToMove[0].Service_Order_Header__r.Transaction_Type__r.Type__c == 'Customer') && ((destinationCOList[0].Fees_Bulk_Discount_Percent__c == serviceOrderKitHeaderListToMove[0].Service_Order_Header__r.Fees_Bulk_Discount_Percent__c) || (destinationCOList[0].Parts_Bulk_Discount_Percent__c == serviceOrderKitHeaderListToMove[0].Service_Order_Header__r.Parts_Bulk_Discount_Percent__c))) {
                List<CO_Kit_Header__c> newlyInsertedCOKitList = COKH_Recalcualtion.getCOKitRecList(new Set<Id>{cokhId}, destinationCOId).values();

                List<CO_Line_Item__c> coliListToUpdate = new List<CO_Line_Item__c>();
                Map<String, Service_Order_Line_Item__c> kitLiIdToSoliMap = new Map<String, Service_Order_Line_Item__c>();

                for(Service_Order_Kit_Header__c kitRec : serviceOrderKitHeaderListToMove) {
                    for(Service_Order_Line_Item__c soliRec : kitRec.Service_Order_Line_Items__r) {
                        kitLiIdToSoliMap.put(soliRec.Kit_Header_Line_Item__c, soliRec);
                    }
                } 

                for(CO_Kit_Header__c kitRec : newlyInsertedCOKitList) {
                    for(CO_Line_Item__c coliRec : kitRec.CO_Line_Items__r) {
                        if(kitLiIdToSoliMap.containsKey(coliRec.Kit_Header_Line_Item__c) && ((destinationCOList[0].Parts_Bulk_Discount_Percent__c == serviceOrderKitHeaderListToMove[0].Service_Order_Header__r.Parts_Bulk_Discount_Percent__c && coliRec.Part__c != null) || (destinationCOList[0].Fees_Bulk_Discount_Percent__c == serviceOrderKitHeaderListToMove[0].Service_Order_Header__r.Fees_Bulk_Discount_Percent__c && coliRec.Fee__c != null))) {
                            colirec.Price_When_Tax_Included__c = kitLiIdToSoliMap.get(coliRec.Kit_Header_Line_Item__c).Price_When_Tax_Included__c;
                            colirec.Price__c = kitLiIdToSoliMap.get(coliRec.Kit_Header_Line_Item__c).Kit_Price__c;
                            coliListToUpdate.add(colirec);
                        }    
                    }
                    
                } 
                if(!coliListToUpdate.isEmpty()) {
                    COLineItemTriggerHelper.isTriggerExecute = false;
                    DMLUtility.updateSobjectList('CO_Line_Item__c', coliListToUpdate);   
                    newlyInsertedCOKitList = COKH_Recalcualtion.applySalesTax(newlyInsertedCOKitList, destinationCOId);
                    DMLUtility.updateSobjectList('CO_Kit_Header__c', newlyInsertedCOKitList);   
                    TaxCalculation.populateOrderTotal(destinationCOId, true);
                }            
            }
            if(destinationCOId != currentCOId) {
                COSectionDetailService.setSectionStatus(new Set<Id>{destinationCOId}, COSectionDetailService.MERCHANDISE);
            }
        }   
        InternalCommentService.createInternalCommentsForMoveLineItem('Kit', serviceOrderKitHeaderListToMove[0].Kit_Unique_Name__c, sourceSection, destinationSection, currentCOId, destinationCOId, sourceCOName);
        return null;                                                                                                        
                     
    }

    private static List<CO_Line_Item__c> updateVOLIANDCOLIOnMoveFromColiToSoli(CO_Line_Item__c newCOLIRec, Service_Order_Line_Item__c solirec, List<CO_Line_Item__c> coliListToMove) {	            
	    List<CO_Line_Item__c>  newlyInsertedCOLIList = new List<CO_Line_Item__c>();
            String query = 'Select Id, Service_Order_Line_Item__c, CO_Header__c From CO_Line_Item__c ';
            if(solirec != null) {
                String soliId = solirec.Id;
                query += ' WHERE Service_Order_Line_Item__c =: soliId ';
            } else if(newCOLIRec != null) {
                String coliId = newCOLIRec.Id;
                query += ' WHERE Id =: coliId ';
            }
        newlyInsertedCOLIList = Database.query(query);
        if(coliListToMove[0].Vendor_Order_Line_Items__r != null && coliListToMove[0].Vendor_Order_Line_Items__r.size() > 0 && ((newCOLIRec != null && coliListToMove[0].Merchandise_Commit_Order_controls__c == newCOLIRec.Merchandise_Commit_Order_controls__c) || (solirec != null && coliListToMove[0].Merchandise_Commit_Order_controls__c == solirec.Commit_Order_Controls__c))) {
	    	List<Vendor_Order_Line_Item__c> voliRecListToUpdate = new List<Vendor_Order_Line_Item__c>();
	        voliRecListToUpdate.addAll(coliListToMove[0].Vendor_Order_Line_Items__r);
	        
	        for(Vendor_Order_Line_Item__c voliRec : voliRecListToUpdate) {
	    		voliRec.CO_Line_Item__c = newlyInsertedCOLIList[0].Id;
                voliRec.CO_Header__c = newlyInsertedCOLIList[0].CO_Header__c;
	        	if(newlyInsertedCOLIList[0].Service_Order_Line_Item__c != null){
	                voliRec.Is_Service__c = true;
	                voliRec.Is_required_For_Customer__c = false;
	            } else {
	                voliRec.Is_required_For_Customer__c = true;
	                voliRec.Is_Service__c = false;
	            }
	        }
            DMLUtility.upsertSobjectList('Vendor_Order_Line_Item__c', voliRecListToUpdate);
            if(solirec != null) {
	        newlyInsertedCOLIList[0].Status__c = coliListToMove[0].Status__c;
	        newlyInsertedCOLIList[0].Vendor_Order_Header__c = coliListToMove[0].Vendor_Order_Header__c;
	        newlyInsertedCOLIList[0].VO_Number__c = coliListToMove[0].VO_Number__c;
	        newlyInsertedCOLIList[0].VO_Status__c = coliListToMove[0].VO_Status__c;
			newlyInsertedCOLIList[0].Expected_Delivery_Date__c = coliListToMove[0].Expected_Delivery_Date__c;
		newlyInsertedCOLIList[0].Pulled__c = coliListToMove[0].Pulled__c;
        COLineItemTriggerHelper.isForceStopTrigger = true;
        DMLUtility.upsertSobjectList('CO_Line_Item__c', newlyInsertedCOLIList);
        COLineItemTriggerHelper.isForceStopTrigger = false;																
    }
	    }														
        return newlyInsertedCOLIList;														
    }
    															
    private static void updateVOLIANDCOLIOnMoveFromCokhSokh(Id soKHId, List<CO_Kit_Header__c> coKitHeaderToMovelist, List<Vendor_Order_Line_Item__c> voliRecListToUpdate) {
        List<CO_Line_Item__c>  newlyInsertedCOLIList;
        if(soKHId != null) {
           newlyInsertedCOLIList = [Select Id, CO_Header__c, Service_Order_Line_Item__c, Kit_Header_Line_Item__c From CO_Line_Item__c WHERE Service_Order_Line_Item__r.Service_Order_Kit_Header__c =: soKHId];
        } else {
            newlyInsertedCOLIList = [Select Id, CO_Header__c, Service_Order_Line_Item__c, Kit_Header_Line_Item__c From CO_Line_Item__c WHERE CO_Kit_Header__c IN : coKitHeaderToMovelist];
        }
        List<CO_Line_Item__c>  newlyInsertedCOLIListToUpdate = new List<CO_Line_Item__c>();
        
        Map<Id, CO_Line_Item__c> khliIdToNewlyInsertedCOLIRecMap = new Map<Id, CO_Line_Item__c>();
        for(CO_Line_Item__c coliRec : newlyInsertedCOLIList) {
        	khliIdToNewlyInsertedCOLIRecMap.put(coliRec.Kit_Header_Line_Item__c, coliRec);
        }
        
        Map<Id, CO_Line_Item__c> khliIdToCOLIRecToMoveMap = new Map<Id, CO_Line_Item__c>();
        for(CO_Line_Item__c coliRec : coKitHeaderToMovelist[0].CO_Line_Items__r) {
        	khliIdToCOLIRecToMoveMap.put(coliRec.Kit_Header_Line_Item__c, coliRec);
        }
        
        for(Vendor_Order_Line_Item__c voliRec : voliRecListToUpdate) {
        	if(khliIdToNewlyInsertedCOLIRecMap.containsKey(voliRec.CO_Line_Item__r.Kit_Header_Line_Item__c)) {
        		voliRec.CO_Line_Item__c = khliIdToNewlyInsertedCOLIRecMap.get(voliRec.CO_Line_Item__r.Kit_Header_Line_Item__c).Id;
                voliRec.CO_Header__c = khliIdToNewlyInsertedCOLIRecMap.get(voliRec.CO_Line_Item__r.Kit_Header_Line_Item__c).CO_Header__c;
        		if(khliIdToNewlyInsertedCOLIRecMap.get(voliRec.CO_Line_Item__r.Kit_Header_Line_Item__c).Service_Order_Line_Item__c != null){
                    voliRec.Is_Service__c = true;
                    voliRec.Is_required_For_Customer__c = false;
                } else {
                    voliRec.Is_required_For_Customer__c = true;
                    voliRec.Is_Service__c = false;
                }
                
        		CO_Line_Item__c newlyInsertedCOLIToUpdate = new CO_Line_Item__c();
                newlyInsertedCOLIToUpdate.Id = khliIdToNewlyInsertedCOLIRecMap.get(voliRec.CO_Line_Item__r.Kit_Header_Line_Item__c).Id;
                
                if(khliIdToCOLIRecToMoveMap.containsKey(voliRec.CO_Line_Item__r.Kit_Header_Line_Item__c)) {
                	newlyInsertedCOLIToUpdate.Status__c = khliIdToCOLIRecToMoveMap.get(voliRec.CO_Line_Item__r.Kit_Header_Line_Item__c).Status__c;
		            newlyInsertedCOLIToUpdate.Vendor_Order_Header__c = khliIdToCOLIRecToMoveMap.get(voliRec.CO_Line_Item__r.Kit_Header_Line_Item__c).Vendor_Order_Header__c;
		            newlyInsertedCOLIToUpdate.VO_Number__c = khliIdToCOLIRecToMoveMap.get(voliRec.CO_Line_Item__r.Kit_Header_Line_Item__c).VO_Number__c;
		            newlyInsertedCOLIToUpdate.VO_Status__c = khliIdToCOLIRecToMoveMap.get(voliRec.CO_Line_Item__r.Kit_Header_Line_Item__c).VO_Status__c;
					newlyInsertedCOLIToUpdate.Expected_Delivery_Date__c = khliIdToCOLIRecToMoveMap.get(voliRec.CO_Line_Item__r.Kit_Header_Line_Item__c).Expected_Delivery_Date__c;
                }
                newlyInsertedCOLIListToUpdate.add(newlyInsertedCOLIToUpdate);
        	}
        }
        
        DMLUtility.upsertSobjectList('Vendor_Order_Line_Item__c', voliRecListToUpdate);
        DMLUtility.upsertSobjectList('CO_Line_Item__c', newlyInsertedCOLIListToUpdate);
    }			
    												
    private static void updateVOLIANDCOLIOnPartMoveFromSoliTOColi(List<Vendor_Order_Line_Item__c> voliRecListToUpdate, List<CO_Line_Item__c> coliToUpsert, 
    															List<Service_Order_Line_Item__c> soliItemToMovelist) {
    	for(Vendor_Order_Line_Item__c voliRec : voliRecListToUpdate) {
    		voliRec.CO_Line_Item__c = coliToUpsert[0].Id;
            voliRec.CO_Header__c = coliToUpsert[0].CO_Header__c;
        	if(coliToUpsert[0].Service_Order_Line_Item__c != null){
                voliRec.Is_Service__c = true;
                voliRec.Is_required_For_Customer__c = false;
            } else {
                voliRec.Is_required_For_Customer__c = true;
                voliRec.Is_Service__c = false;
            }
    	}
    	
    	coliToUpsert[0].Status__c = soliItemToMovelist[0].CO_Line_Item__r.Status__c;
    	coliToUpsert[0].Vendor_Order_Header__c = soliItemToMovelist[0].CO_Line_Item__r.Vendor_Order_Header__c;
    	coliToUpsert[0].VO_Number__c = soliItemToMovelist[0].CO_Line_Item__r.VO_Number__c;
    	coliToUpsert[0].VO_Status__c =  soliItemToMovelist[0].CO_Line_Item__r.VO_Status__c;
    	coliToUpsert[0].Expected_Delivery_Date__c = soliItemToMovelist[0].CO_Line_Item__r.Expected_Delivery_Date__c;
    	
        DMLUtility.upsertSobjectList('Vendor_Order_Line_Item__c', voliRecListToUpdate);
        COLineItemTriggerHelper.isForceStopTrigger = true;
        DMLUtility.upsertSobjectList('CO_Line_Item__c', coliToUpsert);
        COLineItemTriggerHelper.isForceStopTrigger = false;
    }
    
    private static void updateVOLIANDCOLIOnSubletMoveFromSoliTOColi(List<Vendor_Order_Line_Item__c> voliRecListToUpdate, String soliId, List<Service_Order_Line_Item__c> soliItemToMovelist) {
    	
    	List<Service_Order_Line_Item__c>  newlyInsertedSOLIList = [Select Id, Service_Order_Header__r.CO_Header__c From Service_Order_Line_Item__c WHERE Id =: soliId];
    	
    	for(Vendor_Order_Line_Item__c voliRec : voliRecListToUpdate) {
    		voliRec.Service_Order_Line_Item__c = newlyInsertedSOLIList[0].Id;
            voliRec.CO_Header__c = newlyInsertedSOLIList[0].Service_Order_Header__r.CO_Header__c;
            voliRec.Is_Service__c = true;
            voliRec.Is_required_For_Customer__c = false;
    	}
    	
    	newlyInsertedSOLIList[0].Status__c = soliItemToMovelist[0].Status__c;
    	newlyInsertedSOLIList[0].Vendor_Order_Header__c = soliItemToMovelist[0].Vendor_Order_Header__c;
    	newlyInsertedSOLIList[0].VO_Number__c = soliItemToMovelist[0].VO_Number__c;
    	newlyInsertedSOLIList[0].VO_Status__c =  soliItemToMovelist[0].VO_Status__c;
    	newlyInsertedSOLIList[0].Expected_Delivery_Date__c = soliItemToMovelist[0].Expected_Delivery_Date__c;
    	
        DMLUtility.upsertSobjectList('Vendor_Order_Line_Item__c', voliRecListToUpdate);
        DMLUtility.upsertSobjectList('Service_Order_Line_Item__c', newlyInsertedSOLIList);
    }
    
    private static void updateVOLIANDCOLIOnMoveFromSokhCOKH(Map<String, Id> fieldNameToFieldValueMap, List<Service_Order_Kit_Header__c> serviceOrderKitHeaderListToMove, 
    															List<Vendor_Order_Line_Item__c> voliRecListToUpdate) {
       	String query = 'Select Id, CO_Header__c, Service_Order_Line_Item__c, Kit_Header_Line_Item__c From CO_Line_Item__c ';
       	for(String fieldName : fieldNameToFieldValueMap.keySet()) {
            fieldName = BPUtility.escapeSingleQuotes(fieldName);
            if(fieldNameToFieldValueMap.get(fieldName) == null) {
                query += 'WHERE '+ fieldName + ' = ' + fieldNameToFieldValueMap.get(fieldName);
            } else {
            	query += 'WHERE '+ fieldName + ' = \'' + BPUtility.escapeSingleQuotes(fieldNameToFieldValueMap.get(fieldName)) + '\'';
            }
        }
            
        //List<CO_Line_Item__c>  newlyInsertedCOLIList = [Select Id, Service_Order_Line_Item__c, Kit_Header_Line_Item__c From CO_Line_Item__c WHERE CO_Kit_Header__c =: cokhId];
        //List<CO_Line_Item__c>  newlyInsertedCOLIList = [Select Id, Service_Order_Line_Item__c, Kit_Header_Line_Item__c From CO_Line_Item__c WHERE Service_Order_Line_Item__r.Service_Order_Kit_Header__c =: soKHId];
        
        List<CO_Line_Item__c>  newlyInsertedCOLIList = Database.query(query);
        
        List<CO_Line_Item__c>  newlyInsertedCOLIListToUpdate = new List<CO_Line_Item__c>();
        
        Map<Id, CO_Line_Item__c> khliIdToNewlyInsertedCOLIRecMap = new Map<Id, CO_Line_Item__c>();
        for(CO_Line_Item__c coliRec : newlyInsertedCOLIList) {
        	khliIdToNewlyInsertedCOLIRecMap.put(coliRec.Kit_Header_Line_Item__c, coliRec);
        }
        
        Map<Id, Service_Order_Line_Item__c> khliIdToSOLIRecToMoveMap = new Map<Id, Service_Order_Line_Item__c>();
        for(Service_Order_Line_Item__c soliRec : serviceOrderKitHeaderListToMove[0].Service_Order_Line_Items__r) {
        	khliIdToSOLIRecToMoveMap.put(soliRec.Kit_Header_Line_Item__c, soliRec);
        }
        
        for(Vendor_Order_Line_Item__c voliRec : voliRecListToUpdate) {
        	voliRec.CO_Line_Item__c = khliIdToNewlyInsertedCOLIRecMap.containsKey(voliRec.CO_Line_Item__r.Service_Order_Line_Item__r.Kit_Header_Line_Item__c) ? 
        								khliIdToNewlyInsertedCOLIRecMap.get(voliRec.CO_Line_Item__r.Service_Order_Line_Item__r.Kit_Header_Line_Item__c).Id : null;
            voliRec.CO_Header__c = newlyInsertedCOLIList.isEmpty() ? null : newlyInsertedCOLIList[0].CO_Header__c;
        	if(khliIdToNewlyInsertedCOLIRecMap.containsKey(voliRec.CO_Line_Item__r.Service_Order_Line_Item__r.Kit_Header_Line_Item__c)) {
        		if(khliIdToNewlyInsertedCOLIRecMap.get(voliRec.CO_Line_Item__r.Service_Order_Line_Item__r.Kit_Header_Line_Item__c).Service_Order_Line_Item__c != null){
                    voliRec.Is_Service__c = true;
                    voliRec.Is_required_For_Customer__c = false;
                } else {
                    voliRec.Is_required_For_Customer__c = true;
                    voliRec.Is_Service__c = false;
                }
                
        		CO_Line_Item__c newlyInsertedCOLIToUpdate = new CO_Line_Item__c();
                newlyInsertedCOLIToUpdate.Id = khliIdToNewlyInsertedCOLIRecMap.get(voliRec.CO_Line_Item__r.Service_Order_Line_Item__r.Kit_Header_Line_Item__c).Id;
                
                if(khliIdToSOLIRecToMoveMap.containsKey(voliRec.CO_Line_Item__r.Service_Order_Line_Item__r.Kit_Header_Line_Item__c) 
                	&& khliIdToSOLIRecToMoveMap.get(voliRec.CO_Line_Item__r.Service_Order_Line_Item__r.Kit_Header_Line_Item__c).CO_Line_Item__c != null) {
                	newlyInsertedCOLIToUpdate.Status__c = khliIdToSOLIRecToMoveMap.get(voliRec.CO_Line_Item__r.Service_Order_Line_Item__r.Kit_Header_Line_Item__c).CO_Line_Item__r.Status__c;
		            newlyInsertedCOLIToUpdate.Vendor_Order_Header__c = khliIdToSOLIRecToMoveMap.get(voliRec.CO_Line_Item__r.Service_Order_Line_Item__r.Kit_Header_Line_Item__c).CO_Line_Item__r.Vendor_Order_Header__c;
		            newlyInsertedCOLIToUpdate.VO_Number__c = khliIdToSOLIRecToMoveMap.get(voliRec.CO_Line_Item__r.Service_Order_Line_Item__r.Kit_Header_Line_Item__c).CO_Line_Item__r.VO_Number__c;
		            newlyInsertedCOLIToUpdate.VO_Status__c = khliIdToSOLIRecToMoveMap.get(voliRec.CO_Line_Item__r.Service_Order_Line_Item__r.Kit_Header_Line_Item__c).CO_Line_Item__r.VO_Status__c;
					newlyInsertedCOLIToUpdate.Expected_Delivery_Date__c = khliIdToSOLIRecToMoveMap.get(voliRec.CO_Line_Item__r.Service_Order_Line_Item__r.Kit_Header_Line_Item__c).CO_Line_Item__r.Expected_Delivery_Date__c;
                }
                newlyInsertedCOLIListToUpdate.add(newlyInsertedCOLIToUpdate);
        	}
        }
        DMLUtility.upsertSobjectList('Vendor_Order_Line_Item__c', voliRecListToUpdate);
        COLineItemTriggerHelper.isForceStopTrigger = true;
        DMLUtility.upsertSobjectList('CO_Line_Item__c', newlyInsertedCOLIListToUpdate);
        COLineItemTriggerHelper.isForceStopTrigger = false;
    }
    
}