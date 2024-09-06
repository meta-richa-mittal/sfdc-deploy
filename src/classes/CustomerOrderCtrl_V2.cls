/** 
* Author: Hitesh Gupta
* Since: Nov 14, 2017 
* Name: CustomerOrderCtrl_V2 
* Description: Apex class which contains all remoted methods related to Customer Order V2 Page.
**/
global class CustomerOrderCtrl_V2 {
    global CustomerOrderCtrl_V2(NewHomePageCtrl controller){} 
    public CustomerOrderCtrl_V2() {}
    
    @RemoteAction
    global static String getSearchResults(String JSONString) {
        return CustomerOrderCtrl.getSearchResults(JSONString); 
    }
     
    @RemoteAction 
    global static String getCOHeaderDetailsByGridName(String coHeaderId, String gridName){
        coHeaderId = BPUtility.getDecodedString(coHeaderId);
        gridName = BPUtility.getDecodedString(gridName);
        try{
            return COService.getCOHeaderDetailsByGridName(coHeaderId, gridName);
        }catch(Exception e){
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    @RemoteAction
    global static String addCustomer(String coHeaderId, String customerId){
        return BPUtility.getEncodedString(Customer_Service.addCustomerToCO(BPUtility.getDecodedString(coHeaderId), BPUtility.getDecodedString(customerId)));
    }
    
    /**
    * Name: getSOMasterData
    * Desc: Method to get json String related to SO Master Data
    * @param:  (1) coHeaderId - String - Id of CO Header Record
    * @return: String - JSON String of SO Header Detail Record
    **/
    @RemoteAction
    global static String getSOMasterData(String coHeaderId) {
        coHeaderId = BPUtility.getDecodedString(coHeaderId);
        try {
            ServiceOrderWrapper.SOMasterData masterDataObj = ServiceJobService.getServiceJobMasterdata(coHeaderId); 
            return BPUtility.getEncodedString(System.JSON.serialize(masterDataObj, true));  
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    @RemoteAction 
    global static String getSOHeaderDetails(String recordId, String gridName){
        recordId = BPUtility.getDecodedString(recordId);
        gridName = BPUtility.getDecodedString(gridName);
        try{
            List<ServiceOrderWrapper.SOWrapper> soWrapperList = ServiceJobService.getServiceJobDetails(recordId, gridName);
            return BPUtility.getEncodedString(System.JSON.serialize(soWrapperList, true));
        }catch(Exception e){
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
        return BPUtility.getEncodedString('');
    }
    
    /**
    * Name: createSOHeader
    * Desc: Method to create SO Header
    * @param:  (1) coHeaderId - String - Id of CO Header Record
    * @return: String - JSON String of SO Header Record
    **/
    @RemoteAction
    global static String createSOHeader(String coHeaderId) {
        coHeaderId = BPUtility.getDecodedString(coHeaderId);
        try{
            ServiceJobService.createServiceJob(coHeaderId);
            return getSOHeaderDetails(BPUtility.getEncodedString(coHeaderId), BPUtility.getEncodedString('soHeader,Grid Items'));
        }catch(Exception e){
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
        return BPUtility.getEncodedString('');
    }
    
    @RemoteAction
    global static String updateSOLineItems(String lineItemJSON, String soHeaderId) {
        lineItemJSON = BPUtility.getDecodedString(lineItemJSON);
        soHeaderId = BPUtility.getDecodedString(soHeaderId);
        try{
        String response = ServiceJobService.updateSOLIRec(lineItemJSON, soHeaderId);
            if(response != null) {
                return response;
            }
            return getSOHeaderDetails(BPUtility.getEncodedString(soHeaderId), null);
        }catch(Exception e){
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
        return BPUtility.getEncodedString('');
    }
    
    @RemoteAction
    global static String updateSOKHLineItems(String lineItemJSON, String soHeaderId) {
        lineItemJSON = BPUtility.getDecodedString(lineItemJSON);
        soHeaderId = BPUtility.getDecodedString(soHeaderId);
        Boolean isTaxIncludingPricing = GeneralConfiguration.getTaxIncludingPricing();
        try{
            if(AccessControl.ifObjectFieldIsUpdateable('Service_Order_Kit_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
            if(AccessControl.ifObjectFieldIsAccessible('Service_Order_Kit_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
            
            SOHeaderWrapper.SOKitHeader sokhObj = (SOHeaderWrapper.SOKitHeader) System.JSON.deserialize(lineItemJSON, SOHeaderWrapper.SOKitHeader.class);
    
            if(sokhObj.Id != null) {
                Service_Order_Kit_Header__c soKH = [SELECT Id, Service_Order_Header__c, Fixed_Price__c FROM Service_Order_Kit_Header__c WHERE Id =: sokhObj.Id];
                
                if(soKH.Fixed_Price__c.SetScale(3) != sokhObj.FixedPrice) {
                    SO_KLI_Recalculation.Errorhandler error = SO_KLI_Recalculation.updateSOKitHeader(sokhObj); //SO_KLI_Recalculation.updateSOKitHeader(sokhObj);
                    ShopSuppliesService.shopSuppliesCalculation(soKH.Service_Order_Header__c);
                }
            }
            return getSOHeaderDetails(BPUtility.getEncodedString(soHeaderId), null);
        }catch(Exception e){
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
        return BPUtility.getEncodedString('');
    }
    
    @RemoteAction
    global static String addDeductibleAmount(String deductibleJson) {
        deductibleJson = BPUtility.getDecodedString(deductibleJson);
        SOHeaderWrapper.Deductible soPaymentWrapperObj = (SOHeaderWrapper.Deductible)System.JSON.deserialize(deductibleJson, SOHeaderWrapper.Deductible.class);
        
        String soPaymentRoleRecId = ServiceJobService.saveDeductibleAmount(soPaymentWrapperObj);
        List<SOPaymentWrapper> soPaymentRoleObjList;
        if(soPaymentRoleRecId == null) {
            SOPaymentWrapper newSOPaymentWrapper = new SOPaymentWrapper( new SO_Payment_Role__c(Total_Amount__c = 0.0));
            soPaymentRoleObjList = new List<SOPaymentWrapper>{newSOPaymentWrapper};
        } else {
            soPaymentRoleObjList = ServiceJobService.getSoPaymentRoleById(soPaymentRoleRecId, null);
        }
        return BPUtility.getEncodedString(System.JSON.serialize(soPaymentRoleObjList[0], true));
    }
    
    @RemoteAction
    global static String addLineItems(String lineItemId, String soHeaderId) {
        lineItemId = BPUtility.getDecodedString(lineItemId);
        soHeaderId = BPUtility.getDecodedString(soHeaderId);
        try{
            CustomerOrderCtrl.addServiceJobLineItems(lineItemId, soHeaderId, null, null);
            return getSOHeaderDetails(BPUtility.getEncodedString(soHeaderId), BPUtility.getEncodedString('soHeader,Grid Items'));
        }catch(Exception e){
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
        return BPUtility.getEncodedString('');
    }
    
    /**
    * Name: removeLineItems
    * Desc: Method to remove Line Items in Items Grid.
    * @param:   (1) lineItemId - String - id of line item
                (2) coHeaderId - String - id of coHeader
                (3) soHeaderId - String - id of Service Order Header
    *         
    * @return: String - Wrapper JSON String of all Lookup fields of Customer
    **/
    @RemoteAction
    global static String removeLineItems(String lineItemId, String soHeaderId) {
        lineItemId = BPUtility.getDecodedString(lineItemId);
        soHeaderId = BPUtility.getDecodedString(soHeaderId);
        try{
            if(AccessControl.ifObjectFieldIsAccessible('Service_Order_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
            if(AccessControl.ifObjectFieldIsAccessible('Service_Order_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
            if(AccessControl.ifObjectFieldIsUpdateable('Service_Order_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
            

            String objectName = (Id.valueOf(lineItemId)).getSObjectType().getDescribe().getName();
            if(objectName == CONSTANTS.NAMESPACE + 'Service_Order_Line_Item__c') {
                CustomerOrderCtrl.removeSOLineItem(lineItemId);
            } else if(objectName == CONSTANTS.NAMESPACE + 'Service_Order_Kit_Header__c') {
                CustomerOrderCtrl.removeSOKHItems(lineItemId);
                ShopSuppliesService.shopSuppliesCalculation(soHeaderId);
            }
            soHeaderId = BPUtility.escapeSingleQuotes(soHeaderId);
            List<Service_Order_Header__c> soHeaderList = [select Deal__c, Status__c, (select Id from Service_Order_Line_Items__r) from Service_Order_Header__c where Id =: soHeaderId];
            if(soHeaderList.size() > 0 && soHeaderList[0].Service_Order_Line_Items__r != null && soHeaderList[0].Service_Order_Line_Items__r.size() == 0 && Constants.SOStatusToPriorityMap.get(soHeaderList[0].Status__c) < 2) {
                soHeaderList[0].Status__c = 'Ready';
                update soHeaderList[0];
            }
            
            if(String.isNotBlank(soHeaderList[0].Deal__c)) {
                if(soHeaderList[0].Service_Order_Line_Items__r.size() == 0) {
                    if(AccessControl.ifObjectIsDeletable('Service_Order_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
                    delete soHeaderList[0];
                    return BPUtility.getEncodedString('[]');
                }
            }
            
            return getSOHeaderDetails(BPUtility.getEncodedString(soHeaderId), BPUtility.getEncodedString('soHeader,Grid Items'));
        }catch(Exception e){
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
        return BPUtility.getEncodedString('');
    }
       
    /**
    * Name: saveSOHeaderInfo
    * Desc: Method to save SO header Info
    * @param: (1)coHeaderId - String - CO Header record Id
    *         (2) jSONString - String - JSON String of SO Header Info
    * @return: String - JSON String of Current SO Info Data
    **/
    @RemoteAction
    global static String saveSOHeaderInfo(String coHeaderId, String jSONString) {
        coHeaderId = BPUtility.getDecodedString(coHeaderId);
        jSONString = BPUtility.getDecodedString(jSONString);
        try {
            ServiceOrderWrapper.SOInfo soHeaderObj = (ServiceOrderWrapper.SOInfo) System.JSON.deserialize(jSONString, ServiceOrderWrapper.SOInfo.class);
            Service_Order_Header__c soHeaderRec = new Service_Order_Header__c();
            soHeaderRec.Id = soHeaderObj.Id;
            soHeaderRec.Name__c = soHeaderObj.Name;
            soHeaderRec.Customer_Owned_Unit__c = soHeaderObj.UnitId;
            soHeaderRec.Transaction_Type__c = soHeaderObj.TransactionTypeId;
            
            soHeaderRec.SO_Concern__c = convertListIntoStringForSOFields(soHeaderObj.ManualConcern);
            soHeaderRec.SO_Correction__c = convertListIntoStringForSOFields(soHeaderObj.ManualCorrection);
            soHeaderRec.SO_Cause__c = convertListIntoStringForSOFields(soHeaderObj.ManualCause);
            soHeaderRec.Odometer_on_Arrival__c = soHeaderObj.OdometerIn;
            soHeaderRec.Odometer_on_Departure__c = soHeaderObj.OdometerOut;
            soHeaderRec.Work_Status__c = soHeaderObj.WorkStatus;
            soHeaderRec.Provider__c = soHeaderObj.ProviderId;
            soHeaderRec.Claim_Status__c = soHeaderObj.ClaimStatus;
            soHeaderRec.Category__c = (soHeaderObj.TransactionType == 'Internal' || soHeaderObj.TransactionType == 'Stock Unit') ? soHeaderObj.CategoryId : null;
            
            /*if(soHeaderObj.NotesForCustomer.size() == 0) {
                soHeaderRec.SO_Notes_For_Customer__c = null;
            }
            String notesCustomer = '';
            for(String notesStr : soHeaderObj.NotesForCustomer) {
                notesStr = (notesStr.contains('\n')) ? notesStr.replaceAll('\n', '') : notesStr;
                soHeaderRec.SO_Notes_For_Customer__c = (soHeaderRec.SO_Notes_For_Customer__c == null ? '' : soHeaderRec.SO_Notes_For_Customer__c);
                notesCustomer += notesStr + '\n';
            }*/
            soHeaderRec.SO_Notes_For_Customer__c = convertListIntoStringForSOFields(soHeaderObj.NotesForCustomer);
            //soHeaderRec.SO_Notes_For_Customer__c = String.isNotBlank(soHeaderObj.NotesForCustomer) ? soHeaderObj.NotesForCustomer : null;
            
            // Logic to delete Invoice Item and SO Payment role - If Job type is changed from "Third Party" to "any other"
            if(soHeaderObj.TransactionType != 'Third-Party' && !soHeaderObj.TransactionTypeLabel.equalsIgnoreCase('Quote Third-Party')) {
                List<Service_Order_Header__c> soHeaderList = [Select Id, (Select Id from CO_Invoice_Items__r where SO_Payment_Role__c != null), 
                    (Select Id from SO_Payment_Roles__r) from Service_Order_Header__c where Id =: soHeaderObj.Id];
                if(soHeaderList.size() > 0) {
                    List<SObject> sObjectListToDelete = new List<SObject>((List<SObject>)soHeaderList[0].CO_Invoice_Items__r);
                    sObjectListToDelete.addAll((List<SObject>)soHeaderList[0].SO_Payment_Roles__r);
                    
                    if(!AccessControl.ifObjectIsDeletable('CO_Invoice_Item__c')){throw new BlackPurlException('CO_Invoice_Item__c' + DMLUtility.NOT_DELETABLE);}
                    if(!AccessControl.ifObjectIsDeletable('SO_Payment_Role__c')){throw new BlackPurlException('SO_Payment_Role__c' + DMLUtility.NOT_DELETABLE);}
                    delete sObjectListToDelete;
                }
            }
                       
            if(soHeaderRec.Id != null) {
                DMLUtility.updateSobjectList('Service_Order_Header__c', soHeaderRec);
            }
            
            List<Service_Order_Header__c> soHeaderRecList = SOQLUtil.getSODetailsByFieldName(new Map<String, String>{'Id' => soHeaderObj.Id});
            if(soHeaderRecList.size() == 0) {
                return BPUtility.getEncodedString('{}');
            }
            
            return BPUtility.getEncodedString(System.JSON.serialize(new ServiceOrderWrapper.SOInfo(soHeaderRecList[0])));
        }catch(Exception e){
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
        return BPUtility.getEncodedString('');
    }
    
    @RemoteAction
    global static String saveUnitArrivalInfo(String jSONString) {
        jSONString = BPUtility.getDecodedString(jSONString);
        try {
            CustomerOrderCtrl.saveUnitArrivalInfo(jSONString);  
        } catch(Exception e){
            throw new BlackPurlException(e.getMessage());
        }
        return BPUtility.getEncodedString('Success');
    }
    
    private static String convertListIntoStringForSOFields(List<ServiceOrderWrapper.ServiceNotes> serviceNotesList) {
        String returnStr = '';
        if(serviceNotesList.size() == 0) { 
            returnStr = null;
        }
        for(ServiceOrderWrapper.ServiceNotes serviceNote : serviceNotesList) {
            serviceNote.Value = (serviceNote.Value.contains('\n')) ? serviceNote.Value.replaceAll('\n', '') : serviceNote.Value;
            if(serviceNote.IsDecline) {
                serviceNote.Value = ServiceJobService.SERVICE_DECLINE_SEPARATOR + serviceNote.Value;
            }
            returnStr += (serviceNote.Value != null) ? (serviceNote.Value + '\n') : '';
        }
        return returnStr;
    }
    
   /**
    * Name: uploadAttachment
    * Desc: Method to upload attchments
    * @param: (1) filename - String - File Name
    *         (2) fileData - String - File to be uploaded
    *         (3) recordId - String - Parent Id of attachment
    *         (4) description - String - Description of attachment
    * @return: void
    **/
    @RemoteAction
    global static String uploadAttachment(String filename, String fileData, String recordId, String description) {
        filename = BPUtility.getDecodedString(filename);
        fileData = BPUtility.getDecodedString(fileData);
        recordId = BPUtility.getDecodedString(recordId);
        description = BPUtility.getDecodedString(description);
        
        String user = UserInfo.getUserId();
        if(fileData == null) {
            return BPUtility.getEncodedString(String.valueOf('Invalid file data.'));
        }
        String base64 = fileData.substring(fileData.indexOf(',') + 1);
        Blob actualdata = EncodingUtil.base64Decode(base64);
        if(actualdata.size() <= 0) {
            return BPUtility.getEncodedString(String.valueOf('File size cannot be greater then 10 MB.'));
        }
        
        Attachment att = new Attachment(ParentId = recordId, Body = actualdata);
        att.Name = filename;
        att.Description = description;
        DMLUtility.insertSobjectList('Attachment', att);
        
        return getAttachmentListByParentId(BPUtility.getEncodedString(recordId));
    }
    
    /**
    * Name: removeAttachment
    * Desc: Method to remove attachment
    * @param: (1) attachmentId - String - Id of attachment line item
    *         (2) soHeaderId - String - SO Header Id
    * @return: void
    **/
    @remoteAction
    global static String removeAttachment(String attachmentId, String soHeaderId) {
        attachmentId = BPUtility.getDecodedString(attachmentId);
        soHeaderId = BPUtility.getDecodedString(soHeaderId);
        if(AccessControl.ifObjectFieldIsAccessible('Attachment') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        attachmentId = BPUtility.escapeSingleQuotes(attachmentId);
        List<Attachment> attList = [select Id from Attachment where Id = : attachmentId];
        if(attList.size() > 0) {
            if(AccessControl.ifObjectIsDeletable('Attachment') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
            delete attList;
        }
        return getAttachmentListByParentId(BPUtility.getEncodedString(soHeaderId));
    }
    
    /**
    * Name: getAttachmentListByParentId
    * Desc: Method to get Attachment List from Parent Id(Service Order Header Id)
    * @param: (1) parentId - String - SO Header Id
    * @return: void
    **/
    @remoteAction
    global static String getAttachmentListByParentId(String parentId) {
        parentId = BPUtility.getDecodedString(parentId);
        if(AccessControl.ifObjectFieldIsAccessible('Attachment') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<Attachment> attList = [select Description, Name, CreatedDate from Attachment where ParentId = : parentId Order By CreatedDate ASC];
        if(attList.size() == 0) {
            return BPUtility.getEncodedString('[]');
        }
        
        List<ServiceOrderWrapper.Attachments> attachList = new List<ServiceOrderWrapper.Attachments>();
        for(Attachment att : attList) {
            attachList.add(new ServiceOrderWrapper.Attachments(att));
        }
        return BPUtility.getEncodedString(System.JSON.serialize(attachList));
    }
    
    @RemoteAction
    global static String addAttachment(String formJson, String fileData) {
        formJson = BPUtility.getDecodedString(formJson);
        fileData = BPUtility.getDecodedString(fileData);
        if(Limits.getHeapSize() > AttachmentService.MAX_HEAP_SIZE) {
            return BPUtility.getEncodedString(System.JSON.serialize(new ResponseWrapper('error', 'File size is large')));
        }
        if(fileData == null) {
            return BPUtility.getEncodedString(System.JSON.serialize(new ResponseWrapper('error', 'Invalid file data')));
        }
        try {
            AttachmentService.uploadAttachment(formJson, fileData);
            return BPUtility.getEncodedString(System.JSON.serialize(new ResponseWrapper('success', 'success')));
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    @remoteAction
    global static String getAttachmentList(String parentId) {
        parentId = BPUtility.getDecodedString(parentId);
        try {
            Map<Id, List<AttachmentWrapper>> parentIdToAttachmentListMap = AttachmentService.getAttachmentListByParentId(parentId);
            return BPUtility.getEncodedString(system.JSON.serialize(parentIdToAttachmentListMap, true));
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    @remoteAction
    global static String deleteAttachment(String attachmentId) {
        attachmentId = BPUtility.getDecodedString(attachmentId);
        try {
            AttachmentService.deleteAttachment(attachmentId);
            return BPUtility.getEncodedString(System.JSON.serialize(new ResponseWrapper('success', 'success')));
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    /**
     * Name: saveCOInvoicePayment
     * Desc: Method to save CO Invoice Payment in database
     * @param:  (1) jsonString - String - jsonString of all CO Invoice Payments Records
     * @return: String - JSON String of all CO Invoice Payments
    **/ 
    @RemoteAction
    global static String saveCOInvoicePayment(String jsonString){
        return null;
    }
    
    /**
     * Name: getCOInvoicePaymentsByCOInvoiceHedaerId
     * Desc: Method to get All CO Invoice Payments from CO Header Id
     * @param:  (1) COInvoiceHeaderId - String - CO Invoice Header Id
     * @return: String - JSON String of all CO Invoice Payments
     **/
    @RemoteAction
    global static String getCOInvoicePaymentsByCOInvoiceHedaerId(String coInvoiceHeaderId){
        coInvoiceHeaderId = BPUtility.getDecodedString(coInvoiceHeaderId);
        try {
            List<CO_Invoice_Payment__c> coInvoicePayments = SOQLUtil.getCOInvoicePaymentsByCOInvoiceHeaderId(coInvoiceHeaderId);
            List<COInvoicePayment> coInvoicePaymentList = new List<COInvoicePayment>();
            coInvoicePayments = COHeaderWrapper.sortCOPayment(coInvoicePayments);
            for(CO_Invoice_Payment__c coInvoicePaymentRec : coInvoicePayments) {
                coInvoicePaymentList.add(new COInvoicePayment(coInvoicePaymentRec));
            }
            return BPUtility.getEncodedString(System.JSON.serialize(coInvoicePaymentList));
        }catch(Exception e){
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
        return BPUtility.getEncodedString('');
    }
    
    /**
     * Name: updateCOInvoiceItem
     * Desc: Method to update CO Invoice Item 
     * @param:  (1) jsonString - String - jSONString of CO Invoice Items
     *          (2) coHeaderId - String - Co Header Id
     * @return: String - JSON String of all CO Invoice Item List
    **/
    @RemoteAction
    global static String updateCOInvoiceItem(String jsonString, String coHeaderId){
        jsonString = BPUtility.getDecodedString(jsonString);
        coHeaderId = BPUtility.getDecodedString(coHeaderId);
        
        try {
            List<COInvoiceItem_V2> coInvoiceItemObjList = (List<COInvoiceItem_V2>) System.JSON.deserialize(jsonString, List<COInvoiceItem_V2>.class);
            List<CO_Invoice_Item__c> coInvoiceItemListToUpdate = new List<CO_Invoice_Item__c>();

            for(COInvoiceItem_V2 coIIObj : coInvoiceItemObjList) {
                CO_Invoice_Item__c coInvoiceItemRec = new CO_Invoice_Item__c(Id = coIIObj.COInvoiceItemId);
                coInvoiceItemRec.IsActive__c = (coIIObj.IsActive != null) ? coIIObj.IsActive : false;
                coInvoiceItemListToUpdate.add(coInvoiceItemRec);
            }

            if(coInvoiceItemListToUpdate.size() > 0) {
                DMLUtility.updateSobjectList('CO_Invoice_Item__c', coInvoiceItemListToUpdate);
            }
            return BPUtility.getEncodedString(System.JSON.serialize(COInvoiceItemService.getCOCheckoutInfo(coHeaderId), true));
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }  
    }
    
    @RemoteAction
    global static String getCOInvoiceItemList(String coHeaderId) { 
        coHeaderId = BPUtility.getDecodedString(coHeaderId); 
        try {
            return BPUtility.getEncodedString(System.JSON.serialize(COInvoiceItemService.getCOCheckoutInfo(coHeaderId), true));
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString())); 
        }  
    }
    
    @RemoteAction
    global static String getSalesTaxDetailsForDeal(String dealId) {
        dealId = BPUtility.getDecodedString(dealId);
        return BPUtility.getEncodedString(DealService.getSalesTaxForDeal(dealId));
    }
    
    @RemoteAction
    global static String addPayment(String jsonString, String coHeaderId){
        jsonString = BPUtility.getDecodedString(jsonString);
        coHeaderId = BPUtility.getDecodedString(coHeaderId);
        try{
            List<COInvoicePayment> coInvoicePaymentsObjList = COInvoicePayment.parse(jsonString);
            String response = COService.addPayment(coInvoicePaymentsObjList, coHeaderId);
            if(coInvoicePaymentsObjList[0].PaymentMethod.equalsIgnoreCase(PreferredPaymentService.PREFERRED_PAYMENTS) && response != null) {
                try {
                    ResponseWrapper responseObj = (ResponseWrapper) System.JSON.deserialize(response, ResponseWrapper.class);
                    if(responseObj.responseStatus.equalsIgnoreCase('Error')) {
                        return BPUtility.getEncodedString(response);
                    }
                } catch(Exception exp) {}
            } else if(String.isNotBlank(response) && coInvoicePaymentsObjList.size() > 0 && coInvoicePaymentsObjList[0].PaymentMethod == Constants.AR_CREDIT) {
                return response;
            }
            return getCOInvoiceItemList(BPUtility.getEncodedString(coHeaderId));
        }catch(Exception e){
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
        return BPUtility.getEncodedString('');
    }
    
    @remoteAction
    global static void changeStatus(String soHeaderId, String newStatus, String statusType) {
        soHeaderId = BPUtility.getDecodedString(soHeaderId);
        newStatus = BPUtility.getDecodedString(newStatus);
        statusType = BPUtility.getDecodedString(statusType);
        if(String.isNotBlank(soHeaderId)) {
            Service_Order_Header__c soHeader = new Service_Order_Header__c(Id = soHeaderId);
            if(statusType.equalsIgnoreCase('work')) {
                if(String.isNotBlank(newStatus)) {
                    soHeader.Work_Status__c = newStatus;
                }
            } else {
                soHeader.Claim_Status__c = newStatus;
            }
            DMLUtility.updateSobjectList('Service_Order_Header__c', soHeader);
        } 
    }
    
    @RemoteAction
    global static String closedInvoiceAction(String coInvoiceItemsJsonString, String coHeaderId, String currentCheckoutType) {
        String coInvoiceItemJSONStr = BPUtility.getDecodedString(coInvoiceItemsJsonString);
        List<COInvoiceItem_V2> coInvoiceItemObjList = (List<COInvoiceItem_V2>) System.JSON.deserialize(coInvoiceItemJSONStr, List<COInvoiceItem_V2>.class);
        String coInvoiceHeaderId;
        String  invoiceDateString;
        String trackingNumber;
        if(coInvoiceItemObjList.size() > 0) {
            coInvoiceHeaderId = coInvoiceItemObjList[0].COInvoiceHeaderId;
            invoiceDateString = coInvoiceItemObjList[0].InvoiceDate;
            trackingNumber = coInvoiceItemObjList[0].TrackingNumber;
        }
        Boolean isShowDiscount = false;
        List<String> recIdList = new List<String>();
        for(COInvoiceItem_V2 invRec : coInvoiceItemObjList) {
            if(invRec.IsActive) {
                if(invRec.IsDisplayDiscountAmount != null && invRec.IsDisplayDiscountAmount) {
                    isShowDiscount = invRec.IsDisplayDiscountAmount;
                }
                recIdList.add(invRec.ItemId);
            }
        }
        
        List<COInvoiceItem> coInvItemObjList = COInvoiceItemService.updateInvoiceItems(recIdList, BPUtility.getDecodedString(coHeaderId), true, isShowDiscount);
        coInvoiceItemObjList = null;
        recIdList = null;
        
        List<CO_Invoice_Header__c> coInvHeaderList = [Select Id, 
            (Select isActive__c, CO_Line_Item__c, CO_Line_Item__r.Qty__c, CO_Line_Item__r.Qty_Committed__c, 
            CO_Invoice_Header__r.CO_Header__r.Total_Deposit__c from CO_Invoice_Items__r 
            where isActive__c = false OR (CO_Line_Item__c != null AND CO_Line_Item__r.Part__c != null AND
            CO_Line_Item__r.Part__r.Non_Inventory_Part__c = false))
        FROM CO_Invoice_Header__c where Id =: coInvoiceHeaderId AND Status__c != 'Closed'];

        if(coInvHeaderList.size() == 0) throw new BlackpurlException(COInvoiceItemService.INVOICE_ALREADY_CLOSED);
        List<CO_Invoice_Item__c> coInvoiceItemList = coInvHeaderList[0].CO_Invoice_Items__r;
        
        List<Deal__c> dealList = [Select Id, Status__c, (Select Id from CO_Invoice_Items__r) from Deal__c where CO_Header__c =: BPUtility.getDecodedString(coHeaderId)];
        
        if(coInvItemObjList != null && coInvItemObjList.size() > 0) {
            coInvItemObjList[0].TrackingNumber = trackingNumber;
        }

        Decimal totalDepositOnCO = 0;
        if(!coInvoiceItemList.isEmpty()) {
            totalDepositOnCO = coInvoiceItemList[0].CO_Invoice_Header__r.CO_Header__r.Total_Deposit__c;
        } else {
            List<CO_Header__c> coHeaderList = [Select Id, Total_Deposit__c from CO_Header__c where Id =: BPUtility.getDecodedString(coHeaderId)];
            totalDepositOnCO = coHeaderList[0].Total_Deposit__c;
        }
        
        if(totalDepositOnCO > 0 
            || (dealList.size() > 0 && dealList[0].CO_Invoice_Items__r.size() == 0 && dealList[0].Status__c != 'Invoiced')) {
            CustomerOrderCtrl.closeInvoice(BPUtility.getEncodedString(System.JSON.serialize(coInvItemObjList)), coHeaderId, currentCheckoutType, invoiceDateString);
            return '';
        } else {
            for(CO_Invoice_Item__c invItemRec : coInvoiceItemList) {
                if(!invItemRec.isActive__c || (invItemRec.CO_Line_Item__c != null && invItemRec.CO_Line_Item__r.Qty__c > 0 && 
                    (invItemRec.CO_Line_Item__r.Qty__c != invItemRec.CO_Line_Item__r.Qty_Committed__c))) {
                    CustomerOrderCtrl.closeInvoice(BPUtility.getEncodedString(System.JSON.serialize(coInvItemObjList)), coHeaderId, currentCheckoutType, invoiceDateString);
                    return '';
                }
            }
        }
        
        CustomerOrderCtrl.closeOrder(BPUtility.getEncodedString(System.JSON.serialize(coInvItemObjList)), coHeaderId, currentCheckoutType, invoiceDateString);
        return '';
    }
    
    /**
    * Name: saveCOLineItem
    * Desc: Method Which saves CO Line Items in Database 
    * @param:   (1) coHeaderId - String - CO Header record Id
    *           (2) jSONString - String - JSON String of CO Line Items
    * @return: String - JSON String of CO Header Detail Record
    **/
    private static String saveCOLineItem_Updated(String coHeaderId, String jSONString, String feeId) {
        String a = ' ' + DateTime.now();
        Boolean isTaxIncludingPricing = GeneralConfiguration.getTaxIncludingPricing();
        Boolean isAddLinkedFee = false;
        Boolean isCashSalesCreated = false;
        //try{
            if(String.isBlank(coHeaderId)) {
                isCashSalesCreated = true;
                coHeaderId = BPUtility.getDecodedString(BPGlobalHeaderCtrl.createCustomerOrder());  
                isAddLinkedFee = true;
            }
                
            if(String.isNotBlank(feeId)) {
                insertFeeInMerchGrid(feeId, coHeaderId, isAddLinkedFee, 1);
            } else {
                if(AccessControl.ifObjectFieldIsAccessible('CO_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
                
                List<COLIWrapper> coLineItemObjList = (List<COLIWrapper>) System.JSON.deserialize(jSONString, List<COLIWrapper>.class);
                List<CO_Line_Item__c> coLineItemListToUpdate = new List<CO_Line_Item__c>();
                Decimal previousQty;
                String commitOrderControlSettingValue;
                if(coLineItemObjList.size() > 0 && coLineItemObjList[0].CoLineItemId == null && String.isBlank(coLineItemObjList[0].DealId)) {
                    List<CO_Header__c> coHeaderList = [Select Id, CO_Type__c, Merchandise_Commit_Order_controls__c, Hide_Merchandise_Section__c, 
                            (Select Id from CO_Line_Items__r where Is_In_Merch_Section__c = true LIMIT 1) from CO_Header__c where Id =: coHeaderId];
                    
                    commitOrderControlSettingValue = coHeaderList[0].Merchandise_Commit_Order_controls__c;
                    if(coHeaderList.size() > 0 && coHeaderList[0].CO_Line_Items__r.size() == 0) {
                        if(!GeneralConfiguration.isLoadNewCustomerOrder() || isAddLinkedFee) {
                            List<SObject> sObjectListToInsert = COService.addLinkedFee(coHeaderId, null, 'Merchandise');
                            if(sObjectListToInsert != null && sObjectListToInsert.size() > 0) {
                                coLineItemListToUpdate.addAll((List<CO_Line_Item__c>) sObjectListToInsert);
                            }
                            
                            // Add CO Section Detail record for Merchandise section when first record is added in Merchandise section.
                            COSectionDetailService.createCOSection(coHeaderId, COSectionDetailService.MERCHANDISE);
                        }
                    }
                }
                
                // get environment fee data for part
                Set<String> partIdSet = new Set<String>();
                for(COLIWrapper coLineItemObj : coLineItemObjList) {
                    if(String.isNotBlank(coLineItemObj.PartId)) {
                        partIdSet.add(coLineItemObj.PartId);
                    }
                }
                Map<String, Part__c> partIdToPartRecMap = COService.getPartIdToPartRecMap(partIdSet);
                
                for(COLIWrapper coLineItemObj : coLineItemObjList) {
                    
                    CO_Line_Item__c coLineItemRec = new CO_Line_Item__c(CO_Header__c = coHeaderId, Deal__c = coLineItemObj.DealId);
                    coLineItemRec.Qty__c = coLineItemObj.Qty ;
                    coLineItemObj.Tax = (coLineItemObj.Tax == null) ? 0 : coLineItemObj.Tax;
                    coLineItemObj.Price = (coLineItemObj.Price == null) ? 0 : coLineItemObj.Price;
                    coLineItemRec.Special_Order__c = (coLineItemObj.isSpecialOrder == null) ? false : coLineItemObj.isSpecialOrder;
                    
                    if(isTaxIncludingPricing && String.isBlank(coLineItemObj.DealId)) {
                        coLineItemRec.Price_When_Tax_Included__c = coLineItemObj.Price;
                        coLineItemRec.Price__c = (coLineItemObj.Price / (1 + (coLineItemObj.Tax / 100))).setScale(2, RoundingMode.HALF_UP);
                    } else {
                        coLineItemRec.Price__c = coLineItemObj.Price;
                    }
                      
                    if(coLineItemObj.CoLineItemId != null) {
                        coLineItemRec.Id = coLineItemObj.CoLineItemId;
                        if(isTaxIncludingPricing && String.isNotBlank(coLineItemObj.DealId)) {
                            coLineItemRec.Price_When_Tax_Included__c = coLineItemObj.Price;
                        }
                        //Analysis : Query only for deal section
                        if(String.isNotBlank(coLineItemObj.DealId)) {
                            List<CO_Line_Item__c> coliList = [select Qty__c from CO_Line_Item__c where Id = :coLineItemObj.CoLineItemId];
                            if(coliList.size() > 0) {
                                previousQty = coliList[0].Qty__c;
                            }
                        }
                    }                
                    
                    if(String.isNotBlank(coLineItemObj.FeeId)) {
                        coLineItemRec.Fee__c =  coLineItemObj.FeeId;
                        coLineItemRec.Item_Description__c = coLineItemObj.ItemDescription;
                        coLineItemRec.Qty_Committed__c = coLineItemObj.Qty;
                    } if(String.isNotBlank(coLineItemObj.PartId)) {
                        coLineItemRec.Part__c = coLineItemObj.PartId;
                        if(coLineItemObj.IsNonInventoryPart != null && coLineItemObj.IsNonInventoryPart) {
                            coLineItemRec.Status__c = 'In Stock';
                            coLineItemRec.Qty_Committed__c = coLineItemObj.Qty;
                        } else if(coLineItemObj.QtyCommitted != null && coLineItemObj.Qty > 0) {
                           coLineItemRec.Qty_Committed__c = (coLineItemObj.QtyCommitted > coLineItemObj.Qty) ? coLineItemObj.Qty : coLineItemObj.QtyCommitted;    
                        }
                    }
                    
                    coLineItemListToUpdate.add(coLineItemRec);
                    
                    // Create one Extra line for Env Fee
                    if(coLineItemObj.CoLineItemId == null && coLineItemObj.PartId != null && String.isBlank(coLineItemObj.DealId)) {
                        coLineItemRec.Merchandise_Commit_Order_controls__c = commitOrderControlSettingValue;

                        CO_Line_Item__c envFeeLineItemRec = COService.createEnvFeeLineItem(partIdToPartRecMap.get(coLineItemObj.PartId), coHeaderId);
                        if(envFeeLineItemRec.Fee__c != null) {
                            coLineItemListToUpdate.add(envFeeLineItemRec);
                        }
                    }
                }
                if(coLineItemListToUpdate.size() > 0) {
                    DMLUtility.upsertSobjectList('CO_Line_Item__c', coLineItemListToUpdate);
                    
                    if(String.isNotBlank(coLineItemListToUpdate[0].Deal__c)) {
                        String dealId = coLineItemListToUpdate[0].Deal__c;
                        Set<String> coliIdSet = new Set<String>();
                        for(CO_Line_Item__c coliRec : coLineItemListToUpdate) {
                            coliIdSet.add(coliRec.Id);
                        }
                        if(String.isNotBlank(coLineItemObjList[0].CoLineItemId)) {
                            if(previousQty != coLineItemListToUpdate[0].Qty__c) {
                                CustomerOrderCtrl.createDealUnresolvedFulfillment(new List<String>(coliIdSet), dealId, Constants.UNRESOLVED_FULFILLMENT_TYPE_UPDATED);
                            }
                        } else {
                            CustomerOrderCtrl.createDealUnresolvedFulfillment(new List<String>(coliIdSet), dealId, Constants.UNRESOLVED_FULFILLMENT_TYPE_ADDED);
                        }
                        return getDealDetails(BPUtility.getEncodedString(dealId), BPUtility.getEncodedString('dealUnresolvedFulfillmentAndDealFulfillment'));
                    }
                }
            }
            if(isCashSalesCreated) {
                List<CO_Line_Item__c> coLineItemList = [Select Price__c, Price_When_Tax_Included__c, Tax__c FROM CO_Line_Item__c WHERE CO_Header__c =: coHeaderId AND Part__c != null];
                Decimal price, taxRate;
                String coLineItemId;
                if(coLineItemList.size() > 0) {
                    coLineItemId = coLineItemList[0].Id;
                    price = (isTaxIncludingPricing ? coLineItemList[0].Price_When_Tax_Included__c : coLineItemList[0].Price__c);
                    price = (price != null ? price.setScale(2, RoundingMode.HALF_UP) : 0);
                    taxRate = coLineItemList[0].Tax__c;
                }
                return BPUtility.getEncodedString('{"COHeaderId" : "' + coHeaderId + '", "COLineItemId" : "' + coLineItemId + '", "Tax" : ' + taxRate + ', "Price" : ' + price + '}');
            } else {
                return getCOHeaderDetailsByGridName(BPUtility.getEncodedString(coHeaderId), BPUtility.getEncodedString('coHeader,coLineItem'));
            }
        /*}catch(Exception e){

            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
        return BPUtility.getEncodedString('');*/
    }
    
    @RemoteAction
    global static String saveCOLineItem(String coHeaderId, String jSONString, String feeId) {
        coHeaderId = BPUtility.getDecodedString(coHeaderId);
        jSONString = BPUtility.getDecodedString(jSONString);
        feeId = BPUtility.getDecodedString(feeId);
        return saveCOLineItem_Updated(coHeaderId, jSONString, feeId);
        /*
        Boolean isTaxIncludingPricing = GeneralConfiguration.getTaxIncludingPricing();
        Boolean isAddLinkedFee = false;
        try{
            if(String.isBlank(coHeaderId)) {
                coHeaderId = BPUtility.getDecodedString(BPGlobalHeaderCtrl.createCustomerOrder());  
                isAddLinkedFee = true;
            }
                
            if(String.isNotBlank(feeId)) {
                insertFeeInMerchGrid(feeId, coHeaderId, isAddLinkedFee, 1);
            } else {
                if(AccessControl.ifObjectFieldIsCreateable('CO_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_CREATEABLE); }
                if(AccessControl.ifObjectFieldIsUpdateable('CO_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
                if(AccessControl.ifObjectFieldIsAccessible('CO_Line_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
                
                List<COLIWrapper> coLineItemObjList = (List<COLIWrapper>) System.JSON.deserialize(jSONString, List<COLIWrapper>.class);
                List<CO_Line_Item__c> coLineItemListToUpdate = new List<CO_Line_Item__c>();
                Decimal previousQty;
                if(coLineItemObjList.size() > 0 && coLineItemObjList[0].CoLineItemId == null && String.isBlank(coLineItemObjList[0].DealId)) {
                    List<CO_Header__c> coHeaderList = [Select Id, CO_Type__c, Hide_Merchandise_Section__c, (Select Id from CO_Line_Items__r where Is_In_Merch_Section__c = true)
                                                 from CO_Header__c where Id =: coHeaderId];
                    
                    if(coHeaderList.size() > 0 && coHeaderList[0].CO_Line_Items__r.size() == 0
                        && (!GeneralConfiguration.isLoadNewCustomerOrder() || isAddLinkedFee)) {
                        List<SObject> sObjectListToInsert = COService.addLinkedFee(coHeaderId, null, 'Merchandise');
                        if(sObjectListToInsert != null && sObjectListToInsert.size() > 0) {
                            coLineItemListToUpdate.addAll((List<CO_Line_Item__c>) sObjectListToInsert);
                        }
                    }
                }
                
                for(COLIWrapper coLineItemObj : coLineItemObjList) {
                    CO_Line_Item__c coLineItemRec = new CO_Line_Item__c();
                    coLineItemRec.Deal__c = coLineItemObj.DealId;
                    coLineItemRec.Qty__c = coLineItemObj.Qty ;
                    coLineItemObj.Tax = (coLineItemObj.Tax == null) ? 0 : coLineItemObj.Tax;
                    coLineItemObj.Price = (coLineItemObj.Price == null) ? 0 : coLineItemObj.Price;
                    if(isTaxIncludingPricing && String.isBlank(coLineItemObj.DealId)) {
                        coLineItemRec.Price_When_Tax_Included__c = coLineItemObj.Price;
                        coLineItemRec.Price__c = (coLineItemObj.Price / (1 + (coLineItemObj.Tax / 100))).setScale(2, RoundingMode.HALF_UP);
                    } else {
                        coLineItemRec.Price__c = coLineItemObj.Price;
                    }
                    coLineItemRec.CO_Header__c = coHeaderId;
                    coLineItemRec.Part__c = (coLineItemObj.PartId != '') ? coLineItemObj.PartId : null;
                    coLineItemRec.Fee__c = (coLineItemObj.FeeId != '') ? coLineItemObj.FeeId : null;
                      
                    if(coLineItemObj.PartId != null && coLineItemObj.IsNonInventoryPart != null && coLineItemObj.IsNonInventoryPart) {
                        coLineItemRec.Status__c = 'In Stock';
                    }
                    if(coLineItemRec.Fee__c != null) {
                        coLineItemRec.Item_Description__c = coLineItemObj.ItemDescription;
                    }
                    if(coLineItemObj.isSpecialOrder == null) {
                        coLineItemRec.Special_Order__c = false; // Special Order Flag
                    } else {
                        coLineItemRec.Special_Order__c = coLineItemObj.isSpecialOrder; // Special Order Flag
                    }
                    if(coLineItemObj.CoLineItemId != null) {
                        coLineItemRec.Id = coLineItemObj.CoLineItemId;
                        if(isTaxIncludingPricing && String.isNotBlank(coLineItemObj.DealId)) {
                            coLineItemRec.Price_When_Tax_Included__c = coLineItemObj.Price;
                        }
                        List<CO_Line_Item__c> coliList = [select Qty__c from CO_Line_Item__c where Id = :coLineItemObj.CoLineItemId];
                        if(coliList.size() > 0) {
                            previousQty = coliList[0].Qty__c;
                        }
                    }                
                    if(coLineItemObj.QtyCommitted != null && coLineItemObj.Qty > 0) {
                        if( coLineItemObj.QtyCommitted  > coLineItemObj.Qty) {
                            coLineItemRec.Qty_Committed__c = coLineItemObj.Qty;
                        } else {
                            coLineItemRec.Qty_Committed__c = coLineItemObj.QtyCommitted;    
                        }
                    }
                    if(coLineItemRec.Fee__c != null) {
                        coLineItemRec.Qty_Committed__c = coLineItemObj.Qty;
                    }
                    
                    if(coLineItemObj.PartId != null && coLineItemObj.IsNonInventoryPart != null && coLineItemObj.IsNonInventoryPart) {
                        coLineItemRec.Qty_Committed__c = coLineItemObj.Qty;
                    }
                    
                    coLineItemListToUpdate.add(coLineItemRec);
                    
                    // Create one Extra line for Env Fee
                    if(coLineItemObj.CoLineItemId == null && coLineItemObj.PartId != null && String.isBlank(coLineItemObj.DealId)) {
                        CO_Line_Item__c envFeeLineItemRec = COService.createEnvFeeLineItem(coLineItemObj.PartId, coHeaderId);
                        if(envFeeLineItemRec.Fee__c != null) {
                            coLineItemListToUpdate.add(envFeeLineItemRec);
                        }
                    }
                }
                
                if(coLineItemListToUpdate.size() > 0) {
                    upsert coLineItemListToUpdate;
                    
                    String dealId = coLineItemListToUpdate[0].Deal__c;
                    Set<String> coliIdSet = new Set<String>();
                    for(CO_Line_Item__c coliRec : coLineItemListToUpdate) {
                        coliIdSet.add(coliRec.Id);
                    }
                    if(String.isNotBlank(coLineItemObjList[0].CoLineItemId)) {
                        if(previousQty != coLineItemListToUpdate[0].Qty__c) {
                            CustomerOrderCtrl.createDealUnresolvedFulfillment(new List<String>(coliIdSet), dealId, Constants.UNRESOLVED_FULFILLMENT_TYPE_UPDATED);
                        }
                    } else {
                        CustomerOrderCtrl.createDealUnresolvedFulfillment(new List<String>(coliIdSet), dealId, Constants.UNRESOLVED_FULFILLMENT_TYPE_ADDED);
                    }
                    
                    if(String.isNotBlank(dealId)) {
                        return getDealDetails(BPUtility.getEncodedString(dealId), BPUtility.getEncodedString('dealUnresolvedFulfillmentAndDealFulfillment'));
                    }
                    
                }
            }
            return getCOHeaderDetailsByGridName(BPUtility.getEncodedString(coHeaderId), BPUtility.getEncodedString('coHeader,coLineItem'));
        }catch(Exception e){

            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
        return BPUtility.getEncodedString('');*/
    }
    
    public static void insertFeeInMerchGrid(String lineItemId, String coHeaderId, Boolean isAddLinkedFee, Decimal qty) {
        try{
            List<Fee__c> feeList = SOQLUtil.getFeeByFieldName(new Map<String, String>{'Id' => lineItemId});
            if(feeList.size() == 0) {
                return;
            }
            
            List<CO_Line_Item__c> coliListToInsert = new List<CO_Line_Item__c>();
            List<CO_Line_Item__c> coliList = [Select Id from CO_Line_Item__c where Is_In_Merch_Section__c = true AND CO_Header__c =: coHeaderId];
            if(coliList.size() == 0) {
                if(!GeneralConfiguration.isLoadNewCustomerOrder() || isAddLinkedFee) {
                    List<SObject> sObjectListToInsert = COService.addLinkedFee(coHeaderId, null, 'Merchandise');
                    if(sObjectListToInsert != null && sObjectListToInsert.size() > 0) {
                        coliListToInsert.addAll((List<CO_Line_Item__c>) sObjectListToInsert);
                    }
                    
                    // Add CO Section Detail record for Merchandise section when first record is added in Merchandise section.
                    COSectionDetailService.createCOSection(coHeaderId, COSectionDetailService.MERCHANDISE);
                }
            }

            CO_Line_Item__c coliRec = new CO_Line_Item__c();
            coliRec.CO_Header__c = coHeaderId;
            coliRec.Fee__c = feeList[0].Id;
            coliRec.Qty__c = (qty != null) ? qty : 1;
            coliRec.Qty_Committed__c = coliRec.Qty__c;
            coliRec.Price__c = (feeList[0].Price__c != null) ? feeList[0].Price__c : 0;
            coliRec.Retail__c = coliRec.Price__c;
            coliListToInsert.add(coliRec);
            DMLUtility.insertSobjectList('CO_Line_Item__c', coliListToInsert);
            
            //return getCOHeaderDetailsByGridName(BPUtility.getEncodedString(coHeaderId), BPUtility.getEncodedString('coHeader,coLineItem,closedCOInvoiceHeader'));
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
        return;
    }
    
    @RemoteAction
    global static String deleteCOLineItem(String lineItemId, String coHeaderId){
        lineItemId = BPUtility.getDecodedString(lineItemId);
        coHeaderId = BPUtility.getDecodedString(coHeaderId);
        try{
            String objectName = (Id.valueOf(lineItemId)).getSObjectType().getDescribe().getName();
            String dealId;
            if(objectName == CONSTANTS.NAMESPACE + 'CO_Line_Item__c') {
                dealId = MerchandiseService.deleteCOLI(lineItemId);
            } else if(objectName == CONSTANTS.NAMESPACE + 'CO_Kit_Header__c') {
                dealId = MerchandiseService.removeCOKHItems(lineItemId);
            } 
            if(String.isNotBlank(dealId)) {
                return getDealDetails(BPUtility.getEncodedString(dealId), BPUtility.getEncodedString('dealUnresolvedFulfillmentAndDealFulfillment'));
            }
            return getCOHeaderDetailsByGridName(BPUtility.getEncodedString(coHeaderId), BPUtility.getEncodedString('coHeader,coLineItem'));
        }catch(Exception e){
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
        return BPUtility.getEncodedString('');
    }
    
    @RemoteAction 
    global static String getTechnicianList() {
        return CustomerOrderCtrl.getTechnicianList();
    }
    
    @RemoteAction
    global static String saveHoursLogged(String hoursLoggedJSONString, String coHeaderId) {
        hoursLoggedJSONString = BPUtility.getDecodedString(hoursLoggedJSONString);
        coHeaderId = BPUtility.getDecodedString(coHeaderId);
        
        try {
            String reponse = CustomerOrderCtrl.saveHoursLoggedRec(hoursLoggedJSONString, coHeaderId);
            if(reponse.contains('[]') || reponse.contains('HasError')) {
                return BPUtility.getEncodedString(reponse);
            }
            return BPUtility.getEncodedString(System.JSON.serialize(ServiceJobService.getHoursLogged(reponse), true));
        }catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
        return BPUtility.getEncodedString('[]');
    }
    
    @RemoteAction
    global static String deleteHoursLogged(String soHeaderId, String hrsLoggedRecTd) {
        soHeaderId = BPUtility.getDecodedString(soHeaderId);
        hrsLoggedRecTd = BPUtility.getDecodedString(hrsLoggedRecTd);
        try {
            List<Hours_Logged__c> hrsLoggedList = [Select Id, End_Date_Time__c, Available_For_QB_Sync__c, Available_For_Xero_Sync__c from Hours_Logged__c where Id =: hrsLoggedRecTd];
            if(hrsLoggedList.size() > 0 && hrsLoggedList[0].End_Date_Time__c != null && soHeaderId != null) {
                if(AccessControl.ifObjectFieldIsUpdateable('Hours_Logged__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
                if(hrsLoggedList[0].Available_For_QB_Sync__c || hrsLoggedList[0].Available_For_Xero_Sync__c) {
                    throw new BlackPurlException(Constants.HOURS_LOGGED_NOT_EDITABLE);
                }     
                update new Hours_Logged__c(Id = hrsLoggedRecTd, Is_Removed__c = true);
            } else {
                if(AccessControl.ifObjectIsDeletable('Hours_Logged__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
                delete new Hours_Logged__c(Id = hrsLoggedRecTd);
            }
            ServiceJobService.updateLabourCostingOnSOLIBasedOnTechHoursCosting(new Set<String>{soHeaderId});
            
            return BPUtility.getEncodedString(System.JSON.serialize(ServiceJobService.getHoursLogged(soHeaderId), true));
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
        return BPUtility.getEncodedString('[]');
    }
    
    @remoteAction
    global static String submitClaimRecords(String soHeaderId) {
        return CustomerOrderCtrl.submitClaimRecords(soHeaderId);
    }
    
    @RemoteAction
    global static String getWizardInfo(String soHeaderId, String wizardName) {
        return CustomerOrderCtrl.getWizardInfo(soHeaderId, wizardName);
    } 
    
    @RemoteAction
    global static String saveClaimResponse(String soHeaderId,String ClaimWizardJson,String StepNumber){
        return CustomerOrderCtrl.saveClaimResponse(soHeaderId, ClaimWizardJson, StepNumber);
    }
    
    @RemoteAction
    global static String getProviderInfo(String vendorId) {
        return CustomerOrderCtrl.getProviderInfo(vendorId);
    }
    
    @RemoteAction
    global static String getServiceWorksheetPrintDetail(String coHeaderId) {
        return CustomerOrderCtrl.getServiceWorksheetPrintDetail(coHeaderId);
    }
    
    @RemoteAction
    global static void saveWorkseetSelectionJson(String coHeaderId, String jsonString) { 
        CustomerOrderCtrl.saveWorkseetSelectionJson(coHeaderId, jsonString);
    }
    
    @RemoteAction
    global static String getServiceJobTotals(String soHeaderId) {
        soHeaderId = BPUtility.getDecodedString(soHeaderId);
        List<Service_Order_Header__c> soHeaderRecList = SOQLUtil.getSODetailsByFieldName(new Map<String, String>{'Id' => soHeaderId});
        if(soHeaderRecList.size() > 0) {
            List<Individual_Tax__c> individualItemsList = [select CO_Line_Item__c, Tax_Rate__c, Form_Label__c, 
                                                                Enhanced_Tax_Amount__c, Sales_Tax_Item__r.Name__c, 
                                                                Taxable_Amount__c, Tax_Amount__c,
                                                                Applicable_Tax__c, List_Tax_items_on_forms__c
                                                                    from Individual_Tax__c where Service_Order_Line_Item__r.Service_Order_Header__c = :soHeaderId];
            Map<String, Decimal> salesTaxNameToTaxValue = TaxCalculation.getTaxAmountWithFormLabel(individualItemsList);
            
            SOHeaderPrintPreviewCtrl.PrintingInfo printingInfoObj = new SOHeaderPrintPreviewCtrl.PrintingInfo(new List<Account>(), new List<Customer_Owned_Unit__c>(), new List<CO_Header__c>(), soHeaderRecList[0], 
                                new List<Service_Order_Kit_Header__c>(), new List<Individual_Tax__c>(), new List<Price_Level__c>(),
                                salesTaxNameToTaxValue);
                                                            
            return BPUtility.getEncodedString(System.JSON.serialize(printingInfoObj, true)); 
        }
        return '';
    }
    
    /**
    * Name: saveCustomerApproval
    * Desc: Save CustomerApproval Information to CustomerApproval__c
    * @param:  (1) coHeaderId - String - Id of CO Header Record
    * @param:  (2) Json Data to save
    * @return: Updated JSON data of Customer Approvals
    **/
    @RemoteAction
    public static String saveCustomerApproval(String soHeaderId, String JSONString) {
        if(AccessControl.ifObjectFieldIsAccessible('CustomerApproval__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        if(AccessControl.ifObjectFieldIsCreateable('CustomerApproval__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_CREATEABLE); }
        if(AccessControl.ifObjectFieldIsUpdateable('CustomerApproval__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_UPDATEABLE); }
        if(AccessControl.ifObjectIsDeletable('CustomerApproval__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
        
        soHeaderId = BPUtility.escapeSingleQuotes(BPUtility.getDecodedString(soHeaderId));
        JSONString = BPUtility.getDecodedString(JSONString);
        List<CustomerApproval> custApprovalObjList = (List<CustomerApproval>)System.JSON.deserialize(JSONString, List<CustomerApproval>.class);
        
        return COService.saveCustomerApproval(soHeaderId, (List<CustomerApproval>) System.JSON.deserialize(JSONString, List<CustomerApproval>.class));
    }

    /**
    * Name: splitSOKHItem
    * Desc: Method to split service order kit header 
    * @param:   (1)lineItemId - String - id of line item
                (2) coHeaderId - String - id of coHeader
    * @return: String - Wrapper JSON String of all Lookup fields of Customer
    **/
    @RemoteAction
    global static String splitSOKHItem(String lineItemId, String soHeaderId) {
        lineItemId = BPUtility.getDecodedString(lineItemId);
        soHeaderId = BPUtility.getDecodedString(soHeaderId);
        try{
            ServiceJobService.splitSOKHItem(lineItemId);
            return getSOHeaderDetails(BPUtility.getEncodedString(soHeaderId), BPUtility.getEncodedString('soHeader,Grid Items'));
        }catch(Exception e){
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
        return BPUtility.getEncodedString('');
    }
    
     /**
    * Name: splitSOKHItem
    * Desc: Method to split service order kit header 
    * @param:   (1)lineItemId - String - id of line item
                (2) coHeaderId - String - id of coHeader
    * @return: String - Wrapper JSON String of all Lookup fields of Customer
    **/
    @RemoteAction
    global static String createMerchSection(String coHeaderId) {
        coHeaderId = BPUtility.getDecodedString(coHeaderId);
        try{
            COService.createMerchSectionIfNotExist(coHeaderId);
            return getCOHeaderDetailsByGridName(BPUtility.getEncodedString(coHeaderId), BPUtility.getEncodedString('coHeader,coLineItem'));
        }catch(Exception e){
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
        return BPUtility.getEncodedString('');
    }
        
    @RemoteAction
    global static String createNewCustomerOrder(String customerId, String sellingGroup) {
        //String coHeaderId = BPGlobalHeaderCtrl.createNewCustomerOrder(customerId, sellingGroup);
        /**if(sellingGroup != 'Part Sale' && sellingGroup != 'Cash Sale') {
            CustomerOrderCtrl.removeMerchandiseSection(coHeaderId, true);
        }*/
        /**if(BPUtility.getDecodedString(sellingGroup) != 'Part Sale' && BPUtility.getDecodedString(sellingGroup) != 'Cash Sale') {
            CustomerOrderCtrl.removeMerchandiseSection(coHeaderId, true);
        }
        return COService.getCOHeaderDetailsByGridName(BPUtility.getDecodedString(coHeaderId), 'Customer Info');*/
        return '';
    }
    
    @RemoteAction
    global static String createCustomerOrder(String customerId, String sellingGroup, Boolean isPreventMerchSectionCreation) {
        sellingGroup = BPUtility.getDecodedString(sellingGroup);
        if(String.isNotBlank(sellingGroup) && (sellingGroup.equalsIgnoreCase('Service Order') || sellingGroup.equalsIgnoreCase('Unit Deal'))) {
            String coHeaderId = COService.createCO(BPUtility.getDecodedString(customerId), sellingGroup, isPreventMerchSectionCreation);
            return BPUtility.getEncodedString(System.JSON.serialize(COService.getCOBasicInfo(coHeaderId, sellingGroup), true));
        } else {
            String coHeaderId = BPGlobalHeaderCtrl.createNewCO(customerId, BPUtility.getEncodedString(sellingGroup), isPreventMerchSectionCreation);
            if((sellingGroup != 'Part Sale' && sellingGroup != 'Cash Sale') 
                || (sellingGroup == 'Part Sale' && isPreventMerchSectionCreation)) {
                CustomerOrderCtrl.removeMerchandiseSection(coHeaderId, true);
            }
            return coHeaderId;
        }
    }
    
    @RemoteAction
    global static String getDealDetails(String objectId, String gridName) {
        return CustomerOrderCtrl.getDealDetails(objectId, gridName);
    }
    
    @RemoteAction
    global static String createDeal(String coHeaderId) {
        return CustomerOrderCtrl.createDeal(coHeaderId);
    }
    
    @RemoteAction
    global static String saveDealInfoDetails(String coHeaderId, String dealId, String json) {
        return CustomerOrderCtrl.saveDealInfoDetails(coHeaderId, dealId, json);
    }
    
    @RemoteAction
    global static String saveTemporaryUnit(String dealId, String jSONString) {
        return CustomerOrderCtrl.saveTemporaryUnit(dealId, jSONString);
    }
    
    @RemoteAction
    global static String updateDealStatus(String dealId, String dealStatus) {
        return CustomerOrderCtrl.updateDealStatus(dealId, dealStatus);
    }
    
    @RemoteAction
    global static String addUnitToDeal(String dealItemId, String unitId, String dealId) {
        return CustomerOrderCtrl.addUnitToDeal(dealItemId, unitId, dealId);
    }
    
    @RemoteAction
    global static String updateDealUnitCostPrice(String dealUnitCostPriceItemjson, String dealId, String dealItemId) {
        return CustomerOrderCtrl.updateDealUnitCostPrice(dealUnitCostPriceItemjson, dealId, dealItemId);
    }
    
    @RemoteAction
    global static String toggleRideawayPricingEnabled(String dealItemId, Decimal totalEnforceRideawayPrice, Boolean IsRideawayPricingEnabled) {
        return CustomerOrderCtrl.toggleRideawayPricingEnabled(dealItemId, totalEnforceRideawayPrice, IsRideawayPricingEnabled);
    }
    
    @RemoteAction
    global static String updateRideawayPricing(String dealItemId, String unitJsonString) {
        return CustomerOrderCtrl.updateRideawayPricing(dealItemId, unitJsonString);
    }
    
    @RemoteAction
    global static String updateStampDuty(String dealItemId, String stampDutyTotal) {
        return CustomerOrderCtrl.updateStampDuty(dealItemId, stampDutyTotal);
    }
    
    @RemoteAction
    global static String updateStampDutyWhenRideawayPricingEnabled(String dealItemId, String stampDutyTotal) {
        dealItemId = BPUtility.getDecodedString(dealItemId);
        stampDutyTotal = BPUtility.getDecodedString(stampDutyTotal);
        try {
            return DealService.updateStampDutyWhenRideawayPricingEnabled(dealItemId, stampDutyTotal);
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    } 
    
    @RemoteAction
    global static String removeUnitFromDeal(String dealId, String dealItemId) { 
        dealItemId = BPUtility.getDecodedString(dealItemId); 
        dealId = BPUtility.getDecodedString(dealId);    

        if(String.isNotBlank(dealItemId)) {
            List<Deal_Item__c> dealItemList = [Select Deal__r.CO_Header__c, Customer_Owned_Unit__c, Deal__r.Status__c, Type__c, Customer_Owned_Unit__r.Status__c, Deal__r.Deal_Section_Trade_Only__c, Customer_Owned_Unit__r.Unit_Type__c From Deal_Item__c where Id =: dealItemId];
            if(dealItemList.size() > 0 && dealItemList[0].Deal__r.Status__c != 'Invoiced') {
                if(dealItemList[0].Customer_Owned_Unit__r.Status__c == Constants.ON_ORDER_STATUS) {
                    List<Customer_Owned_Unit__c> orduList = [Select Id, Is_Ordered_Unit_Added_To_Deal__c from Customer_Owned_Unit__c where Id =: dealItemList[0].Customer_Owned_Unit__c];
                    if(orduList.size() > 0) {
                        orduList[0].Is_Ordered_Unit_Added_To_Deal__c = false;
                        DMLUtility.updateSobjectList('Customer_Owned_Unit__c', orduList);                    
                    }
                }
                String couId = dealItemList[0].Customer_Owned_Unit__c;
                String coHeaderId = dealItemList[0].Deal__r.CO_Header__c;
                
                if(dealItemList[0].Type__c == Constants.DEAL_ITEM_TYPE_UNIT && String.isNotBlank(couId) && dealItemList[0].Customer_Owned_Unit__r.Status__c =='Reserved') {
                    update new Customer_Owned_Unit__c(Id = dealItemList[0].Customer_Owned_Unit__c, Status__c = DealService.getUnitStatusByUnitAnddealItemId(dealItemList[0].Customer_Owned_Unit__c, dealItemList[0].Id, dealItemList[0].Customer_Owned_Unit__r.Unit_Type__c));
                }
                
                if(AccessControl.ifObjectIsDeletable('Deal_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
                delete new Deal_Item__c(Id = dealItemId);
                
                CustomerOrderCtrl.updateStatusForDeal(dealId);
                
                List<Deal_Item__c> newDealItemList = [Select Id, Deal__r.Deal_Section_Trade_Only__c, Deal__r.Type__c From Deal_Item__c where Deal__c =: dealId];
                if(!GeneralConfiguration.getTaxIncludingPricing() && newDealItemList.size() > 0 &&
                                        islimitDealItemSalesTax(newDealItemList[0].Deal__r.Deal_Section_Trade_Only__c)) {
                    DealService.limitDealItemSalesTax(dealId);
                }
                
                if(dealItemList[0].Type__c == Constants.DEAL_ITEM_TYPE_UNIT && String.isBlank(couId) && newDealItemList.size() > 0 &&
                                        newDealItemList[0].Deal__r.Deal_Section_Trade_Only__c && newDealItemList[0].Deal__r.Type__c == 'Financed') {
                    List<Deal_Finance__c> dealFinanceList = [Select Id from Deal_Finance__c where Deal__c =: dealId];
                    if(dealFinanceList.size() > 0) {
                        DealService.removeDealFinancing(dealId, String.valueOf(dealFinanceList[0].Id));
                    }
                }
            }
        }
        return getDealDetails(BPUtility.getEncodedString(dealId), null);
    }
    
    public static Boolean islimitDealItemSalesTax(Boolean isDealTradeOnly) {
        if(!isDealTradeOnly && GeneralConfiguration.isTradeTaxCreditCanNotExceedUnitTax()) {
            return true;
        }
        return false;
    }
    
    @RemoteAction
    global static String saveOptionFeesLineItem(String dealId, String dealItemId, String jSONString) {
        return CustomerOrderCtrl.saveOptionFeesLineItem(dealId, dealItemId, jSONString);
    }
    
    @RemoteAction
    global static String getDealItemDetails(String dealItemId) {
        dealItemId = BPUtility.getDecodedString(dealItemId);
        return CustomerOrderCtrl.getDealItemDetails(dealItemId);
    }
    
    @RemoteAction
    global static String removeOptionFeesLineItem(String dealItemId, String lineItemId) {
        return CustomerOrderCtrl.removeOptionFeesLineItem(dealItemId, lineItemId);
    }
       
    @RemoteAction
    global static String updateTradeIn(String dealId, String jsonString) {
        return CustomerOrderCtrl.updateTradeIn(dealId, jsonString);
    }
    
    @RemoteAction
    global static String createDealMerchAndServiceSetion(String dealId, String coHeaderId) {
        return CustomerOrderCtrl.createDealMerchAndServiceSetion(dealId, coHeaderId);
    }
    
    @RemoteAction
    global static String createDealMerchSection(String dealItemIdSetJson, String coHeaderId) {
        dealItemIdSetJson = BPUtility.getDecodedString(dealItemIdSetJson);
        coHeaderId = BPUtility.getDecodedString(coHeaderId);
        return DealService.createDealMerchSection(dealItemIdSetJson, coHeaderId);
    }
    
    @RemoteAction
    global static String createDealServiceSection(String dealItemIdSetJson, String coHeaderId) {
        dealItemIdSetJson = BPUtility.getDecodedString(dealItemIdSetJson);
        coHeaderId = BPUtility.getDecodedString(coHeaderId);
        return BPUtility.getEncodedString(DealService.createDealServiceSection(dealItemIdSetJson, coHeaderId));
    }
    
    @RemoteAction
    global static String setStatusForCommitAndInstallAction(String dealId, String coHeaderId) {
        dealId = BPUtility.getDecodedString(dealId);
        coHeaderId = BPUtility.getDecodedString(coHeaderId);
        return BPUtility.getEncodedString(DealService.setStatusForCommitAndInstallAction(dealId, coHeaderId));
    }
    
    @RemoteAction
    global static String moveDealMerchAndServiceLineItems(String optionFeeRecId, String coHeaderId) {
        return CustomerOrderCtrl.moveDealMerchAndServiceLineItems(optionFeeRecId, coHeaderId);
    }
    
    @RemoteAction
    global static String resolveFulfillment(String dealId, String unresolvedFulfillmentObjJSON, String chargeMethod, String selectedUnitId) {
        return CustomerOrderCtrl.resolveFulfillment(dealId, unresolvedFulfillmentObjJSON, chargeMethod, selectedUnitId);
    }    
    
   @RemoteAction
    global static String updateDealFinanceDetails(String dealId, String dealFinanceJSON) {
        dealId = BPUtility.getDecodedString(dealId);
        dealFinanceJSON = BPUtility.getDecodedString(dealFinanceJSON);
        DealService.updateDealFinanceDetails(dealId, dealFinanceJSON);
        return getDealDetails(BPUtility.getEncodedString(dealId), BPUtility.getEncodedString('dealFinanceSection'));
    }
    
    @RemoteAction
    global static String removeFAndIProductLineItem(String dealId, String fAndIProductId) {
        return CustomerOrderCtrl.removeFAndIProductLineItem(dealId, fAndIProductId);
    }
    
    @RemoteAction
    global static String saveDealFAndIProduct(String dealId, String dealFAndIProductJSON) {
        return CustomerOrderCtrl.saveDealFAndIProduct(dealId, dealFAndIProductJSON);
    }
    
    @RemoteAction
    global static String updateDealFinanceStatus(String coHeaderId, String dealId, String dealFinanceObjJson, String financeStatus) {
        coHeaderId = BPUtility.getDecodedString(coHeaderId);
        dealId = BPUtility.getDecodedString(dealId);
        dealFinanceObjJson = BPUtility.getDecodedString(dealFinanceObjJson);
        financeStatus = BPUtility.getDecodedString(financeStatus);
        DealWrapper.DealFinanceWrapper dealFinanceObj = (DealWrapper.DealFinanceWrapper) System.JSON.deserialize(dealFinanceObjJson, DealWrapper.DealFinanceWrapper.class);
        
        if(String.isBlank(dealFinanceObj.Id)) {
            return BPUtility.getEncodedString('{}'); 
        }  
        DealService.updateFinanceStatus(coHeaderId, dealId, dealFinanceObj, financeStatus);
        return BPUtility.getEncodedString('Success');
    }
    
    @RemoteAction
    global static String recalculationOfDealKHLineItems(String dealKHJSON, String dealKHLineItemJSON) {
        return CustomerOrderCtrl.recalculationOfDealKHLineItems(dealKHJSON, dealKHLineItemJSON);
    }    
    
    @remoteAction
    global static String insertOptionAndFeeLineItems(String partId, String coHeaderId, String dealId, String dealItemId, String jSONString, Boolean isSuppress, Boolean isDuplicateCheck) {
        return CustomerOrderCtrl.insertOptionAndFeeLineItems(partId, coHeaderId, dealId, dealItemId, jSONString, isSuppress, isDuplicateCheck);
    }  
        
    @remoteAction
    global static String getDealFinanceMasterData() {
        return CustomerOrderCtrl.getDealFinanceMasterData();
    }
    
    @remoteAction
    global static String finalizeInvoice(String recordIdsJson, String coHeaderId) {
        COInvoiceItemService.finalizeCOInvoice(recordIdsJson, coHeaderId);
        return 'Success';
    }
    
    @RemoteAction
    global static String saveCODeposit(String jsonString){
        return CustomerOrderCtrl.saveCODeposit(jsonString);
    }
    
    @remoteAction
    global static String removeDealFinancing(String dealIdStr, String dealFinanceIdStr) {
        String dealId = BPUtility.getDecodedString(dealIdStr); 
        String dealFinanceId = BPUtility.getDecodedString(dealFinanceIdStr);
        DealService.removeDealFinancing(dealId, dealFinanceId);
        return CustomerOrderCtrl.getDealDetails(BPUtility.getEncodedString(dealId), BPUtility.getEncodedString('dealInfo'));
    }
    
    /**
    * Name: getSpecialOrders
    * Desc: Load list of all Special orders created for a CustomerOrder
    * @param:  (1) coHeaderId - String - Id of CO Header Record
    * @return: JSON data having list of Special orders
    **/
    @RemoteAction
    public static String getSpecialOrders(String coHeaderId) {
        coHeaderId = BPUtility.escapeSingleQuotes(BPUtility.getDecodedString(coHeaderId));
        
        List<COHeaderWrapper.SpecialOrder> specialOrderResponseList = new List<COHeaderWrapper.SpecialOrder>();
        List<Vendor_Order_Line_Item__c> specialOrderList = SOQLUtil.getSpecialOrderByCOHeaderId(coHeaderId);
        
        List<String> vendorIdList = new List<String>();
        for(Vendor_Order_Line_Item__c specialOrderObj : specialOrderList) {
            if(specialOrderObj.Part__c != null) {
                vendorIdList.add(specialOrderObj.Part__r.Vendor__c);
            } else if(specialOrderObj.Sublet__c != null) {
                vendorIdList.add(specialOrderObj.Sublet__r.Vendor__c);
            }
        }
        Map<String, Integer> vendorIdToDefaultLeadTimeMap = getVendorLeadTimeMap(vendorIdList);
        for(Vendor_Order_Line_Item__c specialOrderObj : specialOrderList) {
            Integer leadTime = 0;
            if(specialOrderObj.Part__c != null) {
                leadTime = vendorIdToDefaultLeadTimeMap.get(specialOrderObj.Part__r.Vendor__c);
            } else if(specialOrderObj.Sublet__c != null) {
                leadTime = vendorIdToDefaultLeadTimeMap.get(specialOrderObj.Sublet__r.Vendor__c);
            }
            specialOrderResponseList.add(new COHeaderWrapper.SpecialOrder(specialOrderObj, leadTime));
        }
        return BPUtility.getEncodedString(System.JSON.serialize(specialOrderResponseList, true));
    }
    
    public static Map<String, Integer> getVendorLeadTimeMap(List<String> vendorIdList) {
        Map<String, Integer> vendorIdToDefaultLeadTimeMap = new Map<String, Integer>();
        List<PO_Type__c> poTypeList = [SELECT Vendor__c, Lead_Time__c FROM PO_Type__c WHERE IsDefault__c = true AND Vendor__c IN :vendorIdList];
        
        for(PO_Type__c poTypeRec: poTypeList) {
            if(!vendorIdToDefaultLeadTimeMap.containsKey(poTypeRec.Vendor__c)) {
                vendorIdToDefaultLeadTimeMap.put(poTypeRec.Vendor__c, Integer.valueOf(poTypeRec.Lead_Time__c != null ? poTypeRec.Lead_Time__c : 0));
            }
        }
        return vendorIdToDefaultLeadTimeMap;
    }
    
    @RemoteAction
    global static String refreshCOPricingAndTax(String coHeaderId, String customerId){
        coHeaderId = BPUtility.getDecodedString(coHeaderId);
        customerId = BPUtility.getDecodedString(customerId);
        CO_Header__c coHeaderRec = new CO_Header__c(Id = coHeaderId, Customer__c = customerId);
        COTriggerHelper.isRecalculateCOPLAndTax = true;
        CustomerOrderCtrl.updateCOPricingAndTax(new List<CO_Header__c> {coHeaderRec}, customerId, true);
        return 'Success';
    }
    
    public static Boolean isRefreshCOKit = false;
    @RemoteAction 
    global static String refreshCOPricingAndTaxOnKit(String coHeaderId, String customerId){
        coHeaderId = BPUtility.getDecodedString(coHeaderId);
        customerId = BPUtility.getDecodedString(customerId);
        isRefreshCOKit = true;
        COService.updateCOPricingAndTaxOnKit(coHeaderId, customerId);
        return COService.getCOHeaderDetailsByGridName(coHeaderId, 'coHeader,coLineItem,closedCOInvoiceHeader');
    }
    
    @RemoteAction
    global static String refreshSOPricingAndTax(String soHeaderId){
        soHeaderId = BPUtility.getDecodedString(soHeaderId);
        ServiceJobService.refreshSOPricingAndTax(new List<String> {soHeaderId});
        return 'Success';
    }
    
    @RemoteAction 
    global static void setCOStatusAsQuote(String coHeaderId){
        CustomerOrderCtrl.setCOStatusAsQuote(coHeaderId);
    }
    
    /**
    * Name: deleteServiceOrder
    * Desc: Method to delete Service Job
    * @param:  (1) coHeaderId - String - Id of CO Header Record
    * (2) soHeaderId - String - Id of SO Header Record
    **/
    @RemoteAction
    global static String deleteServiceOrder(String coHeaderId, String soHeaderId) {
        coHeaderId = BPUtility.getDecodedString(coHeaderId);
        soHeaderId = BPUtility.getDecodedString(soHeaderId);
        String coHeaderStatus = '';
        try{
            if(AccessControl.ifObjectFieldIsAccessible('Service_Order_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
            if(AccessControl.ifObjectIsDeletable('CO_Invoice_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
            if(AccessControl.ifObjectIsDeletable('Service_Order_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
            
            List<Service_Order_Header__c> soHeaderRecList = new List<Service_Order_Header__c>();
            soHeaderRecList = SOQLUtil.getSODetailsByFieldName(new Map<String, String>{'Id' => soHeaderId});
            
            Boolean isClockedEntry = false;
            // Check for invoiced deductible
            if(soHeaderRecList.size() > 0) {
                for(SO_Payment_Role__c soPaymentRoleRec : soHeaderRecList[0].SO_Payment_Roles__r) {
                    if(soPaymentRoleRec.RecordType.DeveloperName == 'Deductible' && soPaymentRoleRec.Status__c == 'Invoiced') {
                        return BPUtility.getEncodedString(System.JSON.serialize(new ResponseWrapper('error', 'Can\'t delete service job since deductible is already invoiced.')));
                    }
                }
                
                for(Hours_Logged__c hoursLoggedRec: soHeaderRecList[0].Hours_Logged__r) {
                    if(hoursLoggedRec.Start_Date_Time__c != null) {
                        isClockedEntry = true;
                        break;
                    }
                }
                
                if(!isClockedEntry) {
                    delete soHeaderRecList[0].Hours_Logged__r;
                }
            }
            
            if(soHeaderRecList != null && soHeaderRecList.size() > 0 && soHeaderRecList[0].Work_Status__c!= 'Complete' && 
                soHeaderRecList[0].Status__c!= 'Reviewed' && !isClockedEntry &&
                soHeaderRecList[0].Service_Order_Line_Items__r.size() == 0) {
                List<CO_Header__c> coHeader = SOQLUtil.getCOHeaderDetails(coHeaderId);
                if(coHeader[0].Status__c == 'Open' || coHeader[0].Status__c == 'Quote') {
                    soHeaderId = BPUtility.escapeSingleQuotes(soHeaderId);
                    if(AccessControl.ifObjectFieldIsAccessible('CO_Invoice_Item__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
                    List<CO_Invoice_Item__c> coInvoiceItems = [Select Id From CO_Invoice_Item__c where Service_Order_Header__c =:soHeaderId];
                    if(coInvoiceItems.size() > 0 ){
                        delete coInvoiceItems;
                    }
                    delete soHeaderRecList;
                    coHeaderStatus = COService.validateAndCloseCO(coHeaderId);
                } else {
                    return BPUtility.getEncodedString(System.JSON.serialize(new ResponseWrapper('error', 'Please check status of customer order')));
                }
            }
            else {
                return BPUtility.getEncodedString(System.JSON.serialize(new ResponseWrapper('error', 'To remove, the job must be active and not contain any line items')));
            }
        } catch(Exception e){
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
        return (BPUtility.getEncodedString(coHeaderStatus));
    }
    
    /**
    * Name: removeMerchandiseSection 
    * Desc: Wrapper Method over OLD CO to set flag to delete emplty merchandise section on Customer Order Page
    * @param:  (1) coHeaderId - String - Id of CO Header Record
    **/
    @RemoteAction  
    global static void removeMerchandiseSection(String coHeaderId, Boolean flag) {
        CustomerOrderCtrl.removeMerchandiseSection(coHeaderId, flag);
    }
    
    /**
    * Name: removeDeal
    * Desc: Wrapper Method over OLD CO to delete a deal from Customer Order
    * @param:  (1) dealId - String - Id of Deal
    **/
    @RemoteAction  
    global static String removeDeal(String dealId) {
        return CustomerOrderCtrl.removeDeal(dealId);
    }
    
    @RemoteAction
    global static String moveLineItem(String sectionFrom, String sectionTo, String idToMove, String coHeaderId) {
        COService.moveLineItem(sectionFrom, sectionTo, idToMove, coHeaderId);
        return getCOHeaderDetailsByGridName(coHeaderId, BPUtility.getEncodedString(null));
    }
    
    /**
    * Name: getAlternatePartsList 
    * Desc: Wrapper Method over OLD CO to get all related/alternative parts
    * @param:  (1) partId - String - Id of Part
    **/
    @RemoteAction
    global static String getAlternatePartsList(String partId) {
        return CustomerOrderCtrl.getAlternatePartsList(partId);
    }
    
    /**
    * Name: addServiceOrderLineItems 
    * Desc: Wrapper Method over OLD CO to add Service Order line items
    * @param:  (1) partIds - String
    * @param:  (2) soHeaderId - String
    **/
    @RemoteAction
    global static String addServiceOrderLineItems(String partIdsString, String soHeaderId) {
        partIdsString = BPUtility.getDecodedString(partIdsString);
        soHeaderId = BPUtility.getDecodedString(soHeaderId);
        try{
            String coHeaderId = COService.addRelatedPartInSO(partIdsString, soHeaderId);
            return getSOHeaderDetails(BPUtility.getEncodedString(soHeaderId), BPUtility.getEncodedString('soHeader,Grid Items'));
        }catch(Exception e){
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
        return BPUtility.getEncodedString('');
        return CustomerOrderCtrl.addServiceOrderLineItems(partIdsString, soHeaderId);
    }
    
    @remoteAction
    global static String insertCOLineItems(String partId, String coHeaderId, String jSONString, Boolean isSuppress, Boolean isDuplicateCheck, String soHeaderId, String customerId) {
        partId = BPUtility.getDecodedString(partId);
        
        String resultStr = '{}';
        
        if(isSuppress || String.isBlank(partId)) {
            if(isSuppress) {
                CustomerOrderCtrl.insertSuppressLineItem(BPUtility.getDecodedString(coHeaderId), partId);
            }
            if(String.isNotBlank(BPUtility.getDecodedString(soHeaderId)) && BPUtility.getDecodedString(soHeaderId) != 'null') {
                resultStr = addLineItems(BPUtility.getEncodedString(partId), soHeaderId);
            } else { 
                resultStr = saveCOLineItem(coHeaderId, jSONString, BPUtility.getEncodedString(null));
            }
        } else if(String.isNotBlank(partId)) {
            coHeaderId = BPUtility.getDecodedString(coHeaderId);
            if(isDuplicateCheck && !CustomerOrderCtrl.isSuppressLineItemOnCO(coHeaderId, partId) && CustomerOrderCtrl.isDuplicatePartOnCO(coHeaderId, partId)) {
                resultStr = BPUtility.getEncodedString('{"DuplicatePart" : true}');
            } else { 
                if(String.isNotBlank(BPUtility.getDecodedString(soHeaderId)) && BPUtility.getDecodedString(soHeaderId) != 'null') {
                    resultStr = addLineItems(BPUtility.getEncodedString(partId), soHeaderId);
                } else {
                    resultStr = saveCOLineItem(BPUtility.getEncodedString(coHeaderId), jSONString, BPUtility.getEncodedString(null));
                }
            }
        }
        return resultStr;
    }
    
    @RemoteAction
    global static String getActiveSKUServiceJobByUnitId(String unitId) {
        unitId = BPUtility.getDecodedString(unitId);
        try{
            List<DeduplicationWrapper> soDeduplicationWrapperList = ServiceJobService.getActiveSKUServiceJobByUnitId(unitId);
            return BPUtility.getEncodedString(System.JSON.serialize(soDeduplicationWrapperList));
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
        
        return '';
    }
    
    @remoteAction 
    global static String showHistoryOnSuppressPopup(String partId, String coHeaderId) {
        return CustomerOrderCtrl.showHistoryOnSuppressPopup(partId, coHeaderId);
    }
    
    @RemoteAction
    global static String activateQuoteCO(String coHeaderId){
        return CustomerOrderCtrl.activateQuoteCO(coHeaderId);
    }
    
    @RemoteAction
    global static String getActiveCustomerOrdersById(String customerId) {
        return BPGlobalHeaderCtrl.getActiveCustomerOrdersById(customerId);
    }
    
    @RemoteAction
    global static String getActiveCOCountByCustomerId(String customerId) {
        return BPUtility.getEncodedString(COService.getActiveCOCountByCustomerId(BPUtility.getDecodedString(customerId)));
    }
    
    /**
    * Name: deleteCustomerOrder 
    * Desc: Wrapper Method over OLD CO to delete Customer Order
    * @param: coHeaderId
    **/
    @RemoteAction
    global static String deleteCustomerOrder(String coHeaderId){
        return CustomerOrderCtrl.deleteCustomerOrder(coHeaderId);
    }
        
    @RemoteAction
    global static void addServiceJobForJobScheduling(String eventJson) {
        JobSchedulingCtrl.addServiceJobForJobScheduling(eventJson);
    }
    
    @RemoteAction
    global static String syncDealWithDP360(String dealId) {
        dealId = BPUtility.getDecodedString(dealId);
        //DP360IntegrationCtrl.saveLeadFromDP360();  
        String response = DP360IntegrationCtrl.upsertLead(new List<String> {dealId});
        if(response != 'Success') {
            return 'Some error occured. Please try again later';
        }
        return CustomerOrderCtrl.getDealDetails(BPUtility.getEncodedString(dealId), BPUtility.getEncodedString('dealInfo'));
    }
    
    @RemoteAction
    global static String getLeadUrlByLeadId(String leadId) {
        leadId = BPUtility.getDecodedString(leadId);
        return DP360IntegrationCtrl.getLeadUrlByLeadId(leadId);
    }
    
    @RemoteAction
    global static String getServiceJobCategories(String categoryType) {
        categoryType = BPUtility.getDecodedString(categoryType);
        try{
            Map<String, String> searchFields = new Map<String, String>{'Type__c' => categoryType};
            return BPUtility.getEncodedString(System.JSON.serialize(ServiceJobService.getServiceJobCategories(searchFields)));
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    @RemoteAction
    global static String closeCustomerOrder(String coHeaderId) {
        return BPUtility.getEncodedString(COService.validateAndCloseCO(BPUtility.getDecodedString(coHeaderId)));
    }
    
    @RemoteAction
    global static String calculateShopSupplies(String soId) {
        ShopSuppliesService.shopSuppliesCalculation(BPUtility.getDecodedString(soId));
        return 'Success';
    }
    
    @RemoteAction
    global static String insertKitHeaderInMerchGrid(String lineItemId, String coHeaderId) {
        lineItemId = BPUtility.getDecodedString(lineItemId);
        coHeaderId = BPUtility.getDecodedString(coHeaderId);
        try{
            coHeaderId = MerchandiseService.insertMerchKit(lineItemId, coHeaderId);
            return getCOHeaderDetailsByGridName(BPUtility.getEncodedString(coHeaderId), BPUtility.getEncodedString('coHeader,coLineItem'));
        }catch(Exception e){
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
        return BPUtility.getEncodedString('');
    }
    
    @RemoteAction
    global static String splitCOKHItem(String lineItemId, String coHeaderId) {
        MerchandiseService.splitCOKHItem(BPUtility.getDecodedString(lineItemId), BPUtility.getDecodedString(coHeaderId));
        return getCOHeaderDetailsByGridName(coHeaderId, BPUtility.getEncodedString('coHeader,coLineItem'));
    }
    
    @RemoteAction
    global static String updateCOKHLineItemsRecalculation(String cokhJSON, String coHeaderId, String cokliJson) {
        cokhJSON = BPUtility.getDecodedString(cokhJSON);
        coHeaderId = BPUtility.getDecodedString(coHeaderId);
        cokliJson = BPUtility.getDecodedString(cokliJson);
        try{
            String dealId = MerchandiseService.updateCOKHLineItemsRecalculation(cokhJSON, coHeaderId, cokliJson);
            if(String.isNotBlank(dealId)) {
                return getDealDetails(BPUtility.getEncodedString(dealId), BPUtility.getEncodedString('dealUnresolvedFulfillmentAndDealFulfillment'));
            }        
            return getCOHeaderDetailsByGridName(BPUtility.getEncodedString(coHeaderId), BPUtility.getEncodedString('coHeader,coLineItem'));
        }catch(Exception e){
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
        return BPUtility.getEncodedString('');
    }
    
    @remoteAction
    global static String insertKitHeaderInDealMerchGrid(String kitHeaderId, String dealId, String coHeaderId) {
        kitHeaderId = BPUtility.getDecodedString(kitHeaderId);
        dealId = BPUtility.getDecodedString(dealId);
        coHeaderId = BPUtility.getDecodedString(coHeaderId);
        Savepoint sp = Database.setSavepoint();
        try{
            MerchandiseService.insertKitHeaderInDealMerchGrid(kitHeaderId, dealId, coHeaderId);
            return getDealDetails(BPUtility.getEncodedString(dealId), BPUtility.getEncodedString('dealUnresolvedFulfillmentAndDealFulfillment'));
        }catch(Exception e){
            Database.rollback(sp);
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
        return BPUtility.getEncodedString('');
    }
    
    @remoteAction
    global static String recalculateMerchKit(String coKitId, String coHeaderId) {
        coKitId = BPUtility.getDecodedString(coKitId);
        coHeaderId = BPUtility.getDecodedString(coHeaderId);
        Savepoint sp = Database.setSavepoint();
        try{
            //COKH_Recalcualtion.CoKitInsert(coKitId, coHeaderId);
            COKH_Recalcualtion.calculatePriceForCOKitInsertion(coKitId, coHeaderId);
            return 'Success';
        }catch(Exception e){
            Database.rollback(sp);
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
        return BPUtility.getEncodedString('');
    }
    
    @remoteAction
    global static String recalculateServiceKit(String customerId, String coHeaderId, String sokhId, String soHeaderId) {
        customerId = BPUtility.getDecodedString(customerId);
        coHeaderId = BPUtility.getDecodedString(coHeaderId);
        sokhId = BPUtility.getDecodedString(sokhId);
        soHeaderId = BPUtility.getDecodedString(soHeaderId);
        Savepoint sp = Database.setSavepoint();
        try{
            //SO_KLI_Recalculation.SOPriceCalcultaionByPriceLevelForSOKitHeaders(customerId, coHeaderId, new List<Id>{soKHId}, soHeaderId);
            SO_KLI_Recalculation.soKitPriceCalculation(new Set<Id>{soKHId}, new Set<Id>{soHeaderId}, coHeaderId);
            return 'Success';
        }catch(Exception e){
            Database.rollback(sp);
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
        return BPUtility.getEncodedString('');
    }
    
    @remoteAction
    global static String getActiveInvHeaderId(String coHeaderId) {
        coHeaderId = BPUtility.getDecodedString(coHeaderId);
        try{
            String invHeaderId = COInvoiceItemService.getActiveInvHeaderId(coHeaderId);
            return BPUtility.getEncodedString(invHeaderId);
        }catch(Exception e){
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
        return BPUtility.getEncodedString('');
    }
    
    @remoteAction
    global static String getPrimaryUnitImage(String recordId) { // recortId : deal Id or CO header Id
        recordId = BPUtility.getDecodedString(recordId);
        try {
            List<Id> unitIdList = COService.getUnitIdList(recordId); // recId dealItem Id or SO Header Id
            Map<Id, UnitWrapper.Documents> unitIdIdToUnitImageMap = new Map<Id, UnitWrapper.Documents>();
            for(Id unitId: unitIdList) {
                List<UnitWrapper.Documents> imageList = COService.getUnitImages(unitId, true);
                if(imageList.size() > 0) {
                    unitIdIdToUnitImageMap.put(unitId, imageList[0]);
                } else {
                    unitIdIdToUnitImageMap.put(unitId, null);
                }
            }
            return BPUtility.getEncodedString(System.JSON.serialize(unitIdIdToUnitImageMap));
        } catch(Exception e){
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
        return BPUtility.getEncodedString('');
    }
    
    @remoteAction
    global static String getUnitImagesByUnitId(String unitId) {
        unitId = BPUtility.getDecodedString(unitId);
        try {
            List<UnitWrapper.Documents> imageList = COService.getUnitImages(unitId, false);
            return BPUtility.getEncodedString(System.JSON.serialize(imageList));
        } catch(Exception e){
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
        return BPUtility.getEncodedString('');
    }

    @remoteAction
    global static String addPartsSmartItems(String partsInfoJson, String sectionName, String sectionId) {
        return null;
    }

    @remoteAction
    global static String addPartsSmartItems_Updated(String partsInfoJson, String sectionName, String sectionId, String partImportFormat) {
        partsInfoJson = BPUtility.getDecodedString(partsInfoJson);
        sectionName = BPUtility.getDecodedString(sectionName);
        sectionId = BPUtility.getDecodedString(sectionId);
        partImportFormat = BPUtility.getDecodedString(partImportFormat);
        try {
            Map<String, List<COService.SearchPartDetailWrapper>> partNotInSystemList = COService.addPartsSmartItems(partsInfoJson, sectionName, sectionId, partImportFormat);
            return BPUtility.getEncodedString(System.JSON.serialize(partNotInSystemList));
        } catch(Exception e){ 
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
        return BPUtility.getEncodedString('');
    }
    
    @remoteAction
    global static String getCustomerApprovalData(String coHeaderId) {
        coHeaderId = BPUtility.getDecodedString(coHeaderId);
        try { 
            Map<String, List<CustomerApproval>> soIdToCustomerApprovalListMap = ServiceJobService.getCustomerApprovalList(coHeaderId);
            return BPUtility.getEncodedString(System.JSON.serialize(soIdToCustomerApprovalListMap));
        } catch(Exception e){
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
        return BPUtility.getEncodedString('');
    }
        
    @remoteAction
    global static String getOutOfStockPartsInKit(String kitHeaderId) { 
        kitHeaderId = BPUtility.getDecodedString(kitHeaderId);
        try {
            List<ViewKitCtrl.KitHeaderLineItem> khliList = MerchandiseService.getOutOfStockPartsInKit(kitHeaderId);
            return BPUtility.getEncodedString(System.JSON.serialize(khliList));
        } catch(Exception e){
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
        return BPUtility.getEncodedString('');
    }
    
    @remoteAction
    global static String oversoldKit(String coHeaderId, String kitHeaderJSON) {
        coHeaderId = BPUtility.getDecodedString(coHeaderId);
        kitHeaderJSON = BPUtility.getDecodedString(kitHeaderJSON);
        try {
            MerchandiseService.oversoldKit(kitHeaderJSON);
            return getCOHeaderDetailsByGridName(BPUtility.getEncodedString(coHeaderId), BPUtility.getEncodedString('coHeader,coLineItem'));
        } catch(Exception e){
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
        return BPUtility.getEncodedString('');
    }
    
    @remoteAction
    global static String getActiveFormsBySectionId(String sectionId) {
        sectionId = BPUtility.getDecodedString(sectionId);
        try {
            List<FormRepositoryWrapper> activeFormsList = COFormService.getActiveFormsBySectionId(sectionId);
            return BPUtility.getEncodedString(system.JSON.serialize(activeFormsList, true));
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    @remoteAction
    global static String getCOFormsBySectionId(String sectionId) {
        sectionId = BPUtility.getDecodedString(sectionId);
        try {
            Map<Id, List<COFormWrapper>> sectionIdToCOFormListMap = COFormService.getCOFormsBySectionId(sectionId);
            return BPUtility.getEncodedString(system.JSON.serialize(sectionIdToCOFormListMap, true));
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    @remoteAction
    global static String addFormsToSection(String coHeaderId, String sectionId, String formJson) {
        coHeaderId = BPUtility.getDecodedString(coHeaderId);
        sectionId = BPUtility.getDecodedString(sectionId);
        formJson = BPUtility.getDecodedString(formJson);
        try {
            COFormService.addFormsToSection(coHeaderId, sectionId, formJson);
            return BPUtility.getEncodedString(system.JSON.serialize('Success'));
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    @RemoteAction
    global static String deleteCOForm(String coFormId) {
        coFormId = BPUtility.getDecodedString(coFormId);
        try {
            COFormService.deleteCOForm(coFormId);
            return BPUtility.getEncodedString('Success');
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    @RemoteAction
    global static String insertDefaultCOForms(String coHeaderId, String sectionId) {
        coHeaderId = BPUtility.getDecodedString(coHeaderId);
        sectionId = BPUtility.getDecodedString(sectionId);
        try {
            COFormService.insertDefaultCOForms(coHeaderId, sectionId);
            return BPUtility.getEncodedString('Success');
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    @RemoteAction
    global static String getActiveFormsCount() {
        try {
            return BPUtility.getEncodedString(system.JSON.serialize(COFormService.getActiveFormsCount(), true));
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    @RemoteAction
    global static String saveInternalComment(String internalCommentJSON) {
        internalCommentJSON = BPUtility.getDecodedString(internalCommentJSON);
        try {
            InternalCommentService.saveInternalCommentOnCO(internalCommentJSON);
            return BPUtility.getEncodedString('Success');
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    @RemoteAction
    global static String getInternalCommentList(String coHeaderId) {
        coHeaderId = BPUtility.getDecodedString(coHeaderId);
        try {
            return BPUtility.getEncodedString(system.JSON.serialize(InternalCommentService.getInternalCommentListByCOId(coHeaderId), true));
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    @remoteAction
    global static String deleteInternalComment(String internalCommentId) {
        internalCommentId = BPUtility.getDecodedString(internalCommentId);
        try {
            InternalCommentService.deleteInternalCommentFromCO(internalCommentId);
            return BPUtility.getEncodedString(System.JSON.serialize(new ResponseWrapper('success', 'success')));
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }

    @remoteAction
    global static String stockInCOU(String tradeInId, String unitId) {
        tradeInId = BPUtility.getDecodedString(tradeInId);
        unitId = BPUtility.getDecodedString(unitId);
        try {
            DealService.stockInCOU(tradeInId, unitId);
            return BPUtility.getEncodedString(System.JSON.serialize(new ResponseWrapper('success', 'success')));
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    @RemoteAction
    global static String getCOProfitability(String coId) {
        coId = BPUtility.getDecodedString(coId);
        try {
            return BPUtility.getEncodedString(system.JSON.serialize(COService.getCOProfitability(coId), true));
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    @RemoteAction
    global static String getBussinessProfileData() { 
        try {
            return BPUtility.getEncodedString(system.JSON.serialize(COService.getBussinessProfileData(), true));
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    @RemoteAction
    global static String getSalesPersonList() { 
        try {
            return UserSettingCtrl.getAllClockingStaff();
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    @RemoteAction
    global static String getApplicableTaxList() {
        try {
            return BPUtility.getEncodedString(TaxUtility.getApplicableList());
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    @RemoteAction
    global static String saveDealItemTaxInfo(String dealItemTaxInfoJSON) {
        dealItemTaxInfoJSON = BPUtility.getDecodedString(dealItemTaxInfoJSON);
        try {
            DealService.saveDealItemTaxInfo(dealItemTaxInfoJSON);
            return BPUtility.getEncodedString(system.JSON.serialize(new ResponseWrapper(200, 'Success')));
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    /**
    * Get Attachment body
    */
    @RemoteAction
    global static String getAttachmentBodyByParentIdAndName(String parentId, String fileName) {
        try {
            return BPUtility.getEncodedString(system.JSON.serialize(AttachmentService.getAttachmentBodyByParentIdAndName(BPUtility.getDecodedString(parentId), BPUtility.getDecodedString(fileName))));
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    @remoteAction
    global static String getAppointmentsBySectionId(String sectionId) {
        sectionId = BPUtility.getDecodedString(sectionId);
        try {
            Map<Id, AppointmentWrapper> sectionIdToAppointmentListMap = COAppointmentService.getAppointmentsBySectionId(sectionId);
            return BPUtility.getEncodedString(system.JSON.serialize(sectionIdToAppointmentListMap, true));
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    @remoteAction
    global static String updateAppointmentsBySectionId(String sectionId) {
        sectionId = BPUtility.getDecodedString(sectionId);
        try {
            COAppointmentService.updateAppointmentsBySectionId(sectionId);
            return BPUtility.getEncodedString('Success');
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    @remoteAction
    global static String getActiveCOUList(String customerId) {
        customerId = BPUtility.getDecodedString(customerId);
        try {
            List<ServiceOrderWrapper.Unit> couList = ServiceJobService.getActiveCOUList(customerId); 
            return BPUtility.getEncodedString(system.JSON.serialize(couList, true));
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    @remoteAction
    global static Boolean checkForRefreshLinkOnDealUnitPriceCost(String dealItemId, String unitId) {
        dealItemId = BPUtility.getDecodedString(dealItemId);
        unitId = BPUtility.getDecodedString(unitId);
        try {
            return DealService.checkForRefreshLinkOnDealUnitPriceCost(dealItemId, unitId); 
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    @RemoteAction
    global static void refreshDealUnitPriceCost(String dealItemId, String unitId) {
        dealItemId = BPUtility.getDecodedString(dealItemId);
        unitId = BPUtility.getDecodedString(unitId);
        try {
            DealService.refreshDealUnitPriceCost(dealItemId, unitId); 
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
     @RemoteAction 
    global static String getCoBuyer(String customerId) {
        customerId = BPUtility.getDecodedString(customerId);
        try {
            String query = 'Select ';
            for(String fieldName : DealWrapper.getCoBuyerFields()) {
                query += BPUtility.escapeSingleQuotes(fieldName) + ', ';
            }
            query = query.substring(0, query.length()-2);
            query += ' from Account where Id = \'' + BPUtility.escapeSingleQuotes(customerId) +'\'';
            List<Account> coBuyerInfoList= Database.query(query);
            return BPUtility.getEncodedString(system.JSON.serialize(new DealWrapper.CoBuyerWrapper(coBuyerInfoList[0])));
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
        return '';
    }
    
    @RemoteAction
    global static String getActiveCashDrawerList() {
        try {
            List<CashDrawerWrapper> cashDrawerObjList = CashDrawerService.getActiveCashDrawerList();
            return BPUtility.getEncodedString(system.JSON.serialize(cashDrawerObjList, true));
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    @RemoteAction
    global static String getDeviceInfoByDeviceUUID(String UUID) {
        UUID = BPUtility.getDecodedString(UUID);
        try {
            LoggedInDeviceWrapper loggedInDeviceObj = LoggedInDeviceService.getDeviceInfoByDeviceUUID(UUID);
            String loggedInDeviceObjStr = (loggedInDeviceObj != null) ? system.JSON.serialize(loggedInDeviceObj) : null;
            return BPUtility.getEncodedString(loggedInDeviceObjStr);
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
        return null;
    }
    
    @RemoteAction
    global static String saveDeviceInfo(String loggedInDeviceJson) {
        loggedInDeviceJson = BPUtility.getDecodedString(loggedInDeviceJson);
        try {
            LoggedInDeviceService.saveDeviceInfo(loggedInDeviceJson);
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
        return 'Success';
    }
    
    @RemoteAction
    global static String getBrandingLocationList() {
        try {
            List<BrandingLocationWrapper> brandingLocationObjList = BrandingLocationService.getBrandingLocationList();
            return BPUtility.getEncodedString(system.JSON.serialize(brandingLocationObjList, true));
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    @RemoteAction
    global static String getActivePaymentMethodList() {
        try {
            List<PaymentMethodWrapper> paymentMethodObjList = AccountSettingService.getActivePaymentMethodNameList();
            return BPUtility.getEncodedString(system.JSON.serialize(paymentMethodObjList, true));
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    @RemoteAction
    global static String getDealItemInternalServiceStatus(String dealId) {
        dealId = BPUtility.getDecodedString(dealId);
        return BPUtility.getEncodedString(system.JSON.serialize(DealService.getDealItemInternalServiceStatus(dealId), true));
    }
    
    @RemoteAction
    global static String refreshSOLIPricingAndTax(String coHeaderId, String soHeaderId) {
        coHeaderId = BPUtility.getDecodedString(coHeaderId);
        soHeaderId = BPUtility.getDecodedString(soHeaderId);
        ServiceJobService.refreshSOLIPricingAndTax(coHeaderId, soHeaderId);
        return 'Success';
    }
    
    @RemoteAction
    global static String finalizeClaimResponse(String soHeaderId, String ClaimWizardJson) {
        soHeaderId = BPUtility.getDecodedString(soHeaderId);
        ClaimWizardJson = BPUtility.getDecodedString(ClaimWizardJson);
        CustomerOrderCtrl.updateVariance(soHeaderId, ClaimWizardJson, true);
        CustomerOrderCtrl.changeStatus(BPUtility.getEncodedString(soHeaderId), BPUtility.getEncodedString('Approved'), BPUtility.getEncodedString('claim'));
        return 'Success';
    }
    
    @RemoteAction
    global static String saveVarianceLI(String varianceLIJson) {
        varianceLIJson = BPUtility.getDecodedString(varianceLIJson);
        ClaimWizard.ClaimLineItem varianceLIObj = (ClaimWizard.ClaimLineItem)System.JSON.deserialize(varianceLIJson, ClaimWizard.ClaimLineItem.class);
        Claim_Line_Item__c VarianceLIRec = new Claim_Line_Item__c(Id = varianceLIObj.Id, Category__c = varianceLIObj.Category);
        update VarianceLIRec;
        return 'Success';
    }
    
    @RemoteAction
    global static String getShopSuppliesConfiguration() {
        return BPUtility.getEncodedString(system.JSON.serialize(GeneralConfiguration.getShopSuppliesCalculationMethod()));
    }
    
    @RemoteAction
    global static String getIndividualTaxesForSO(String soHeaderId) {
        soHeaderId = BPUtility.getDecodedString(soHeaderId);
        Map<Id, Service_Order_Line_Item__c> soliIdToRecMap = new Map<Id, Service_Order_Line_Item__c>([SELECT Id, (SELECT Id, Tax_Rate__c, Enhanced_Tax_Amount__c, Sales_Tax_Item__r.Name__c FROM Individual_Taxes__r) FROM Service_Order_Line_Item__c WHERE Service_Order_Header__c = :soHeaderId]);
        Map<Id, List<IndividualTaxWrapper>> soliIdToIndividualTaxListMap = new Map<Id, List<IndividualTaxWrapper>>();
        for(Id soliId: soliIdToRecMap.keySet()) {
            for(Individual_Tax__c individualTaxRec: soliIdToRecMap.get(soliId).Individual_Taxes__r) {
                if(!soliIdToIndividualTaxListMap.containsKey(soliId)) {
                    soliIdToIndividualTaxListMap.put(soliId, new List<IndividualTaxWrapper>());
                }
                soliIdToIndividualTaxListMap.get(soliId).add(new IndividualTaxWrapper(individualTaxRec));
            }
        }
        return BPUtility.getEncodedString(system.JSON.serialize(soliIdToIndividualTaxListMap));
    }
    
    @RemoteAction
    global static String saveCOHeaderInfo(String coHeaderJson) {
        coHeaderJson = BPUtility.getDecodedString(coHeaderJson);
        try {
            return MerchandiseService.updatePartsAndAccessoriesSetting(coHeaderJson);
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
        return 'Success';
    }
    
    @RemoteAction 
    global static String getPartsLocator(String partId, Integer quantity, String searchType) {
        try {
            partId = BPUtility.getDecodedString(partId);
            searchType = BPUtility.getDecodedString(searchType);
            return BPUtility.getEncodedString(BRPPartsIntegration.getPartsLocator(partId, quantity, searchType));
            } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
        return 'success';
    }
    
    @RemoteAction
    global static String validatePaymentDate(String paymentDate) {
        try {
            paymentDate = BPUtility.getDecodedString(paymentDate);
            return BPUtility.getEncodedString(system.JSON.serialize(COApexValidation.validatePaymentDate(paymentDate)));
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
        return 'Success';
    }
    
    @RemoteAction
    global static String validateInvoiceDate(String invoiceId, String coHeaderId, String selectedInvoiceDate) {
        return null;
    }
    
    @RemoteAction
    global static String validateInvoiceDateOnCheckout(String invoiceDateValidateJSONString) {
        try {
            invoiceDateValidateJSONString = BPUtility.getDecodedString(invoiceDateValidateJSONString);
            return BPUtility.getEncodedString(system.JSON.serialize(COApexValidation.validateInvoiceDate(invoiceDateValidateJSONString)));
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
        return 'success';
    }
    
    @RemoteAction
    global static String updateShopSupplies(String soHeaderId, String oldJobType, String newJobType) {
        try {
            soHeaderId = BPUtility.getDecodedString(soHeaderId);
            oldJobType = BPUtility.getDecodedString(oldJobType);
            newJobType = BPUtility.getDecodedString(newJobType);
            if(oldJobType != newJobType) {
                if(newJobType == 'Internal') {
                    //delete Shop Supplies
                    ShopSuppliesService.removeShopSupplies(soHeaderId);
                } else if(oldJobType == 'Internal') {
                    //recalculate Shop Supplies
                    ShopSuppliesService.addShopSuppliesToSO(soHeaderId);
                }
            }
            return 'success';
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
        return 'success';
    }

    @RemoteAction 
    global static String getBusinessName() {
        try {
            List<Business_Profile__c> businessProfileList = SOQLUtil.getBusinessProfileData(new List<Id>());
            if(businessProfileList.size() > 0) {
                return BPUtility.getEncodedString(businessProfileList[0].Business_Name__c);
            }
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
        return '';
    }
    
    @RemoteAction 
    public static String getUnitCategoryList() {
        try {
            return BPUtility.getEncodedString(system.JSON.serialize(CategoryService.getFilteredCategoryWrapperList(new Map<String, String>{'Type__c' => 'Unit'})));
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
        return '';
    }
    
    @RemoteAction
    public static String saveCustomerPONumber(String coHeaderId, String customerPONumber) {
        try {
            coHeaderId = BPUtility.getDecodedString(coHeaderId);
            customerPONumber = BPUtility.getDecodedString(customerPONumber);
            update new CO_Header__c(Id = coHeaderId, Customer_PO_Number__c = customerPONumber);
            return 'success';
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
        return 'success';
    }
    
    @RemoteAction 
    public static String getBillOfSaleFormData(String dealId) {
        try {
            dealId = BPUtility.getDecodedString(dealId);
            return BPUtility.getEncodedString(DealService.getBillOfSaleFormData(dealId));
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
        return '';
    }

    @RemoteAction
    global static String getPartPickListCOLIList(String coHeaderId) { 
        coHeaderId = BPUtility.getDecodedString(coHeaderId); 
        try {
            return BPUtility.getEncodedString(System.JSON.serialize(PartPickListService.getPartPickListCOLIList(coHeaderId), true));
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString())); 
        }  
    }

    @RemoteAction
    global static String savePartPickListCOLI(String recordJSON) { 
        COService.savePartPickListCOLI(BPUtility.getDecodedString(recordJSON));
        return BPUtility.getEncodedString('Success');
    }

    @RemoteAction
    global static String assignOrUnassignTechnician(String soHeaderId, String technicianId) { 
        soHeaderId = BPUtility.getDecodedString(soHeaderId);
        technicianId = BPUtility.getDecodedString(technicianId);
        try {
            return BPUtility.getEncodedString(TechnicianService.assignOrUnassignTechnician(soHeaderId, technicianId));
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString())); 
        } 
    }
    
    @RemoteAction
    global static String getAssignedTechnicianList(String soHeaderId) { 
        soHeaderId = BPUtility.getDecodedString(soHeaderId);
        try {
            return BPUtility.getEncodedString(System.JSON.serialize(TechnicianService.getAssignedTechnicianList(soHeaderId, null)));
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString())); 
        } 
    }
    
    @RemoteAction
    global static String clockONTechnician(String soHeaderId, String technicianId) { 
        soHeaderId = BPUtility.getDecodedString(soHeaderId);
        technicianId = BPUtility.getDecodedString(technicianId);
        try {
            TechnicianService.clockONTechnician(Constants.NAMESPACE + 'Service_Order_Header__c', soHeaderId, technicianId);
            return BPUtility.getEncodedString('Success');
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString())); 
        } 
    }
    
    @RemoteAction
    global static String clockOFFTechnician(String soHeaderId, String technicianId) { 
        soHeaderId = BPUtility.getDecodedString(soHeaderId);
        technicianId = BPUtility.getDecodedString(technicianId);
        try {
            return BPUtility.getEncodedString(TechnicianService.clockOFFTechnicianWithNotes(Constants.NAMESPACE + 'Service_Order_Header__c', soHeaderId, technicianId, null));
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString())); 
        } 
    }
    
    @RemoteAction
    global static String getHoursLogged(String soHeaderId) { 
        soHeaderId = BPUtility.getDecodedString(soHeaderId);
        try {
            return BPUtility.getEncodedString(System.JSON.serialize(ServiceJobService.getHoursLogged(soHeaderId), true));
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString())); 
        } 
    }

    @RemoteAction
    global static String getTransactionTypeLabelList() { 
        try {
            List<Transaction_Type__c> ttList = [SELECT Id, Code_Label__c, Default__c FROM Transaction_Type__c WHERE Type__c = 'Part Sale' AND Active__c = true Order by Code_Label__c ASC];
            List<MerchandiseService.TransactionTypeLabelWrapper> ttLabelWrapperList = new List<MerchandiseService.TransactionTypeLabelWrapper>();
            for(Transaction_Type__c ttRec : ttList) {
                ttLabelWrapperList.add(new MerchandiseService.TransactionTypeLabelWrapper(ttRec));
            }
            return BPUtility.getEncodedString(System.JSON.serialize(ttLabelWrapperList, true));
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString())); 
        } 
    }

    @RemoteAction
    global static String saveNotes(String jSONString) {
        jSONString = BPUtility.getDecodedString(jSONString);
        try {
            NotesService.saveNotes(jSONString);  
        } catch(Exception e){
            throw new BlackPurlException(e.getMessage());
        }
        return BPUtility.getEncodedString('Success');
    }
    
    @RemoteAction
    global static String validateDealReOpening(String dealId) {
        dealId = BPUtility.getDecodedString(dealId);
        try {
            return BPUtility.getEncodedString(System.JSON.serialize(ReopenDealService.validateDealReOpening(dealId)));
        } catch(Exception e) {
            /* exception is not thrown as this transaction has QB/Xero callout 
                which may change refresh token and if not saved may cause invalid grant issue */
            ReopenDealService.ReOpenDealValidationWrapper reopenValidationWrapperObj = new ReopenDealService.ReOpenDealValidationWrapper();
            reopenValidationWrapperObj.AccEntriesCanBeRemoved = null;
            reopenValidationWrapperObj.CanSoldUnitsBeReversed = null;
            reopenValidationWrapperObj.CanTradedInUnitsBeReversed = null;
            reopenValidationWrapperObj.ErrroMsg = e.getMessage();
            return BPUtility.getEncodedString(System.JSON.serialize(reopenValidationWrapperObj, true));
        }
    }

    @RemoteAction
    global static String validateInvoiceReOpening(String invoiceID) {
        invoiceID = BPUtility.getDecodedString(invoiceID);
        try {
            return BPUtility.getEncodedString(System.JSON.serialize(new ReopenCOService().validateInvoiceReopening(invoiceID)));
        } catch(Exception e) {
            ReopenCOValidationWrapper reopenValidationWrapperObj = new ReopenCOValidationWrapper();
            reopenValidationWrapperObj.ErrorMsg = e.getMessage();
            return BPUtility.getEncodedString(System.JSON.serialize(reopenValidationWrapperObj, true));
        }
    }
    
    @RemoteAction
    global static String reOpenDeal(String dealId) { 
        dealId = BPUtility.getDecodedString(dealId);
        try {
            return BPUtility.getEncodedString(System.JSON.serialize(ReopenDealService.reOpenDeal(dealId), true));
        } catch(Exception e) {
            /* exception is not thrown as this transaction has QB/Xero callout 
                which may change refresh token and if not saved may cause invalid grant issue */
            new LogService().createErrorLog('CustomerOrderCtrl_V2', 'reOpenDeal()', e.getMessage(), null, e.getStackTraceString(), 
                                            dealId, LogService.REOPEN_DEAL, true, 'Info');
            return 'error';
        }
    }

    @RemoteAction
    global static String reOpenInvoice(String invoiceId) { 
        invoiceId = BPUtility.getDecodedString(invoiceId);
        try { 
            return BPUtility.getEncodedString(System.JSON.serialize(new ReopenCOService().reOpenInvoice(invoiceId), true));
        } catch(Exception e) {
            new LogService().createErrorLog('CustomerOrderCtrl_V2', 'reOpenInvoice()', e.getMessage(), null, e.getStackTraceString(), 
            invoiceId, LogService.REOPEN_INVOICE, true, 'Info');
            return 'error';
        } 
    }

    @RemoteAction
    global static String getFormJson(String coId) {
        return BPUtility.getEncodedString(System.JSON.serialize(COFormService.getFormJson(BPUtility.getDecodedString(coId)), true));
    }

    // DP360 related methods
    @RemoteAction
    global static String getOpenLeadsFromDP360() { 
        try {
            return BPUtility.getEncodedString(DP360LeadService.getAllOpenLeads());
        } catch(Exception e) {
            throw new BlackPurlException(e.getMessage());
        }
    }

    @RemoteAction
    global static String createCustomerFromDP360(String leadId) {
        leadId = BPUtility.getDecodedString(leadId);
        try {
            String customerInfoJSONString = DP360LeadService.getCustomerInfoByLeadId(leadId);
            return BPUtility.getEncodedString(AddCustomerCtrl_V2.saveCustomer(BPUtility.getEncodedString(customerInfoJSONString)));
        } catch(Exception e) {
            throw new BlackPurlException(e.getMessage());
        }
    }
    
    @RemoteAction
    global static String createDealFromDP360(String leadId, String customerId) {
        leadId = BPUtility.getDecodedString(leadId);
        customerId = BPUtility.getDecodedString(customerId);
        try {
            return BPUtility.getEncodedString(DP360LeadService.createDealFromLead(leadId, customerId));
        } catch(Exception e) {
            throw new BlackPurlException(e.getMessage());
        }
    }
    
    @RemoteAction
    global static String updateDP360DealSalePrice(String updateUnitPriceJson) {
        return BPUtility.getEncodedString(DP360LeadService.updateDP360DealSalePrice(BPUtility.getDecodedString(updateUnitPriceJson)));
    }
    
    @RemoteAction
    global static String getTextHistory(String customerId, String coHeaderId) {
        return BPUtility.getEncodedString(System.JSON.serialize(MessageHistoryService.getTextHistory(BPUtility.getDecodedString(customerId), BPUtility.getDecodedString(coHeaderId)), true));
    }

    @RemoteAction
    global static String verifyTechnicianPin(String technicianId, String technicianPin) {
        technicianId = BPUtility.getDecodedString(technicianId);
        technicianPin = BPUtility.getDecodedString(technicianPin);
        return TechnicianService.verifyTechnicianPin(technicianId, technicianPin);
    }

    @RemoteAction 
    global static String getCassonsInventoryByCassonsId(String partId) {
        try {
            return BPUtility.getEncodedString(CassonsService.getCassonsInventoryByPartId(BPUtility.getDecodedString(partId)));
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    @RemoteAction
    global static String getPriceAndCostOptionsListForTempUnit(String dealItemId) {
        return BPUtility.getEncodedString(system.JSON.serialize(DealService.getPriceAndCostOptionsListForTempUnit(BPUtility.getDecodedString(dealItemId)), true));
    }
    
    @remoteAction
    global static String savePriceAndCostOptionForTempUnit(String dealItemId, String jsonString) {
        return BPUtility.getEncodedString(DealService.savePriceAndCostOptionForTempUnit(BPUtility.getDecodedString(dealItemId), 
                                            BPUtility.getDecodedString(jsonString)));
    }
    
    @remoteAction
    global static String deletePriceAndCostOptionForTempUnit(String dupcId) {
        return BPUtility.getEncodedString(DealService.deletePriceAndCostOptionForTempUnit(BPUtility.getDecodedString(dupcId)));
    }
    
    @remoteAction
    global static String getDefaultFactoryOptionsByDealItemId(String dealItemId, String makeId, String modelId, String subModelId) {
        return BPUtility.getEncodedString(UnitPricingService.getDefaultFactoryOptionsByRecId(BPUtility.getDecodedString(dealItemId), 
                                                BPUtility.getDecodedString(makeId), BPUtility.getDecodedString(modelId), BPUtility.getDecodedString(subModelId)));
    }
    
    @RemoteAction
    global static String getSupercededPartsByCOId(String coHeaderId) {
        coHeaderId = BPUtility.getDecodedString(coHeaderId);
        Set<String> partIdSet = COService.getCustomerOrderPartIds(new Set<String>{coHeaderId});
        
        Map<String, SupersededPartService.PartModal> response = SupersededPartService.getSupersededParts(partIdSet);
        return BPUtility.getEncodedString(System.JSON.serialize(response));
    }

    @RemoteAction
    global static String getUnappliedCreditsFromAccounting(String customerId) {
        return Customer_Service.getARPaymentsByCustomerAccId(BPUtility.getDecodedString(customerId), false);
    }

    @RemoteAction
    global static String processARCRDepositToAccounting(String coDepositId) {
        return BPUtility.getEncodedString(COPaymentService.processARCRDepositToAccounting(BPUtility.getDecodedString(coDepositId)));
    }

    @RemoteAction
    global static String processARCRPaymentToAccounting(String coInvPaymentId) {
        return BPUtility.getEncodedString(COPaymentService.processARCRPaymentToAccounting(BPUtility.getDecodedString(coInvPaymentId)));
    }

    @RemoteAction
    global static String getCODepositByCOHeaderId(String coHeaderId) {
        return CustomerOrderCtrl.getCODepositByCOHeaderId(coHeaderId);
    }

    @RemoteAction
    global static String saveDealNotes(String dealId, String notesJson) {
        List<String> notesList = (List<String>) System.JSON.deserialize(BPUtility.getDecodedString(notesJson), List<String>.class);
        return BPUtility.getEncodedString(DealService.saveDealNotes(BPUtility.getDecodedString(dealId), notesList));
    }

    @RemoteAction
    global static String validateChangeCustomerAction(String coHeaderId, Boolean isCustomerDeletedFromCO) {
        return BPUtility.getEncodedString(Customer_Service.validateChangeCustomerAction(BPUtility.getDecodedString(coHeaderId), isCustomerDeletedFromCO));
    }

    @RemoteAction
    global static Boolean updateOptionFeeStatusAndDealStatus(String coHeaderId) {
        return CustomerOrderCtrl.updateOptionFeeStatusAndDealStatus(BPUtility.getDecodedString(coHeaderId));
    }

    @RemoteAction
    global static String getAllActivePaymentTerminals() {
        return BPUtility.getEncodedString(System.JSON.serialize(PreferredPaymentService.getAllActivePaymentTerminals()));
    }

    //This method is deprecated
    global static String authorizeAndCapturePayment(String paymentIntegrationJson, String paymentJson, String coHeaderId) {return'';}

    //This method is deprecated
    @RemoteAction
    global static String authorizeAndCaptureDeposit(String paymentIntegrationJson, String depositJson) {
        return BPUtility.getDecodedString('');
    }

    @RemoteAction
    global static String getRefundMaxCreditAmount() {
        return BPUtility.getEncodedString(System.JSON.serialize(new Map<String, Decimal> {'RefundMaxCreditAmount' => PreferredPaymentService.getRefundMaxCreditAmount()}));
    }
}