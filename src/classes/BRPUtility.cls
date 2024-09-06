public without sharing class BRPUtility {
    
    public static String contentType = 'application/xml';
    public static String nameSpace = 'http://www.starstandard.org/STAR/5';
    public static String prefix = 'star';
    public static String release = '5.10.4';
    public static String languageCode = 'en-US';
    public static String BRP = 'BRP';
    public static String BRP_OAUTH2 = 'BRP OAuth2.0';
    public static String BRP_DMS_OAUTH2 = 'BRP DMS OAuth2.0';
    public static String BRP_DEALER_AUTH = 'BRP Dealer Auth';
    public static String BRP_2 = 'BRP 2.0';
    public static String CurrencyCode {get{return BRP_Settings__c.getOrgDefaults().Currency_Code__c;} private set;}
    public static String careOfFieldDelimiter = '¤';
    public static DateTime partMasterEffectiveDate {get{return BRP_Settings__c.getOrgDefaults().Parts_Master_Successful_Imported_Date__c;} private set;}
    public static String OAUTH2_REDIRECT_URI = 'https://login.salesforce.com/apex/' + Constants.NAMESPACE + 'BRPOAuthCallback';
    public static String STATUS_BO_AVAILABLE = 'Backorder Available';
    public static String BRP_ERROR_STRING = 'BRP Error:';
    public static Integer SchedulerTimeInterval = 0;
    public final static Integer MAX_RETRY_COUNT = 3;
    public final static String DEALER_PART_LOCATOR = 'Dealer Part Locator';
    public final static String PART_INVENTORY = 'Part Inventory';
    public final static String GET_DEALER = 'GetDealer';
    public final static String GET_ARTICLE = 'GetArticle';
    public final static String GET_CAMPAIGNS = 'GetCampaigns';
    public final static String GET_UNIT_SPECIFICATION = 'GetUnitSpecification';
    public final static String VALIDATE_PARTS_ORDER = 'Validate Parts Order';
    public final static String CREATE_PARTS_ORDER = 'Create Parts Order';
    public final static String GET_PARTS_ORDER = 'Get Parts Order';
    public static List<String> brp2ApiList = new List<String> {'DSP Info', 'Dealer Inventory', DEALER_PART_LOCATOR, 'Parts', 'Part', GET_DEALER, GET_UNIT_SPECIFICATION, PART_INVENTORY, GET_ARTICLE, GET_CAMPAIGNS, VALIDATE_PARTS_ORDER, CREATE_PARTS_ORDER, GET_PARTS_ORDER};
    public static List<String> brp2DealerHeaderList = new List<String> {'Dealer Inventory', GET_UNIT_SPECIFICATION, PART_INVENTORY, GET_ARTICLE, GET_CAMPAIGNS};
    public static String API_VERSION_V2 = 'v2';
    public static String API_VERSION_V4 = 'v4';

    public static String generateBodId() {
        return GuidUtil.generateGuid();
    }
    
    public static String creationDateTimeString() {
        return DateTime.now().formatGMT('yyyy-MM-dd\'T\'HH:mm:ss-04:00');
    }
    
    public static String getFormattedDateTime(DateTime dateTimeToFormat) {
        return dateTimeToFormat.format('yyyy-MM-dd\'T\'HH:mm:ssXXX');
    }
    
    public static Boolean isBRPEnabled() {
    	if(!AccessControl.ifObjectFieldIsAccessible('IFW_IntegrationConfig__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<IFW_IntegrationConfig__c> configList = [SELECT Integration_Name__c FROM IFW_IntegrationConfig__c WHERE Accounting_Enabled__c = true AND Integration_Name__c = 'BRP'];
        return configList.size() > 0 ? true : false;
    }
    
    public static IFW_IntegrationConfig__c getBRPIFWConfig() {
    	if(!AccessControl.ifObjectFieldIsAccessible('IFW_IntegrationConfig__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<IFW_IntegrationConfig__c> configList = [SELECT Id, timeout__c, Integration_Name__c, Auth_Scheme__c, Username__c, Password__c, Access_Token__c FROM IFW_IntegrationConfig__c WHERE Accounting_Enabled__c = true AND Integration_Name__c = 'BRP'];
        return configList.size() > 0 ? configList[0] : null;
    }

    public static IFW_IntegrationConfig__c getBRPIFWConfigForAuth2() {
    	if(!AccessControl.ifObjectFieldIsAccessible('IFW_IntegrationConfig__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<IFW_IntegrationConfig__c> configList = [SELECT Id, timeout__c, Integration_Name__c, Auth_Scheme__c, Username__c, Password__c, Access_Token__c FROM IFW_IntegrationConfig__c WHERE Accounting_Enabled__c = true AND Integration_Name__c = 'BRP OAuth2.0' AND Auth_Scheme__c = 'OAuth2.0'];
        return configList.size() > 0 ? configList[0] : null;
    }

    public static IFW_IntegrationConfig__c getBRPDMSIFWConfigForAuth2() {
    	if(!AccessControl.ifObjectFieldIsAccessible('IFW_IntegrationConfig__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<IFW_IntegrationConfig__c> configList = [SELECT Id, timeout__c, Integration_Name__c, Auth_Scheme__c, Username__c, Password__c, Access_Token__c, Client_Id__c, Client_Secret__c, Refresh_Token__c, (SELECT Id, Timeout__c, endpoint_URL__c, Http_Method__c from IFW_IntegrationConfigItems__r 
        WHERE Entity_Name__c = 'Token' AND HTTP_Method__c = 'POST') FROM IFW_IntegrationConfig__c WHERE Accounting_Enabled__c = true AND Integration_Name__c =: BRP_DMS_OAUTH2 AND Auth_Scheme__c = 'OAuth2.0'];
        return configList.size() > 0 ? configList[0] : null;
    }
    
    public static IFW_IntegrationConfig__c getBRP2IfwConfig() {
    	if(!AccessControl.ifObjectFieldIsAccessible('IFW_IntegrationConfig__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<IFW_IntegrationConfig__c> configList = 
        	[SELECT timeout__c, Integration_Name__c, Auth_Scheme__c, Username__c, Password__c, Access_Token__c, Client_Id__c, Client_Secret__c, Refresh_Token__c, 
        		(SELECT Id, Timeout__c, endpoint_URL__c, Http_Method__c FROM IFW_IntegrationConfigItems__r WHERE Entity_Name__c = 'Token' AND HTTP_Method__c = 'POST') 
			FROM IFW_IntegrationConfig__c WHERE Accounting_Enabled__c = true AND Integration_Name__c =: BRP_2 AND Auth_Scheme__c = 'OAuth2.0'];
    	return (configList.size() > 0 ? configList[0] : null);
    }

    public static IFW_IntegrationConfig__c getIFWConfigForOAuth2WithConfigItem(String entityName, String methodType) {
    	if(!AccessControl.ifObjectFieldIsAccessible('IFW_IntegrationConfig__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<IFW_IntegrationConfig__c> configList = [SELECT Id, timeout__c, Access_Token__c, Refresh_Token__c, Client_Id__c, Client_Secret__c, 
        												Integration_Name__c, Auth_Scheme__c, 
        												(SELECT Id, Timeout__c, endpoint_URL__c, Http_Method__c from IFW_IntegrationConfigItems__r 
        												WHERE Entity_Name__c =: entityName AND HTTP_Method__c =: methodType)
        												FROM IFW_IntegrationConfig__c WHERE Accounting_Enabled__c = true AND 
        												Integration_Name__c =: BRP_OAUTH2];
        
        if(configList.size() == 0) throw new BlackPurlException('BRP OAuth 2.0 config is not defined');
        if(configList[0].IFW_IntegrationConfigItems__r.size() == 0) throw new BlackPurlException('BRP OAuth 2.0 config item for ' + entityName + ' is not defined');
        if(String.isBlank(configList[0].Client_Id__c) || String.isBlank(configList[0].Client_Secret__c)) 
        	throw new BlackPurlException('Client Id OR Secret is not defined for BRP OAuth 2.0 config');
        
        return configList[0];
    }
    
    public static IFW_IntegrationConfig__c getIFWConfigForDealerAuthWithConfigItem(String entityName, String methodType) {
    	if(!AccessControl.ifObjectFieldIsAccessible('IFW_IntegrationConfig__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<IFW_IntegrationConfig__c> configList = [SELECT Id, timeout__c, Access_Token__c, Refresh_Token__c, Client_Id__c, Client_Secret__c, 
        												Integration_Name__c, Auth_Scheme__c, 
        												(SELECT Id, Timeout__c, endpoint_URL__c, Http_Method__c from IFW_IntegrationConfigItems__r 
        												WHERE Entity_Name__c =: entityName AND HTTP_Method__c =: methodType)
        												FROM IFW_IntegrationConfig__c WHERE Accounting_Enabled__c = true AND 
        												Integration_Name__c =: BRP_DEALER_AUTH];
        
        if(configList.size() == 0) throw new BlackPurlException('BRP Dealer Auth config is not defined');
        if(configList[0].IFW_IntegrationConfigItems__r.size() == 0) throw new BlackPurlException('BRP Dealer Auth config item for ' + entityName + ' is not defined');
        if(String.isBlank(configList[0].Client_Id__c) || String.isBlank(configList[0].Client_Secret__c)) 
        	throw new BlackPurlException('Client Id OR Secret is not defined for BRP Dealer Auth config');
        
        return configList[0];
    }
    
    public static Id getIFWConfigItemByEntityName(String entityName, String methodType, String integrationName) {
        if(AccessControl.ifObjectIsAccessible('IFW_IntegrationConfigItem__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); } 
        List<IFW_IntegrationConfigItem__c> configItemList = 
                [SELECT Id from IFW_IntegrationConfigItem__c WHERE Entity_Name__c =: entityName AND HTTP_Method__c =: methodType
                    AND IFW_IntegrationConfig__r.Integration_Name__c =: integrationName];
        Id returnId;
        if(configItemList.size() > 0) {
            returnId = configItemList[0].Id;
        }
        return returnId;
    }
    
    public static IFW_IntegrationConfigItem__c getIFWConfigItem(String entityName, String methodType, String integrationName) {
        if(AccessControl.ifObjectIsAccessible('IFW_IntegrationConfigItem__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); } 
        List<IFW_IntegrationConfigItem__c> configItemList = 
                [SELECT Id, Timeout__c, endpoint_URL__c, Entity_Name__c, Http_Method__c, IFW_IntegrationConfig__c from IFW_IntegrationConfigItem__c WHERE Entity_Name__c =: entityName AND HTTP_Method__c =: methodType
                    AND IFW_IntegrationConfig__r.Integration_Name__c =: integrationName];
        return configItemList.size() > 0 ? configItemList[0] : null;
    }
    
    public static Id getIdByURL(String URL, String method) {
        if(AccessControl.ifObjectIsAccessible('IFW_IntegrationConfigItem__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); } 
        List<IFW_IntegrationConfigItem__c> configItemList = [SELECT Id from IFW_IntegrationConfigItem__c 
                                                                WHERE Endpoint_URL__c =: URL and HTTP_Method__c =: method];
        Id returnId;
        if(configItemList.size() > 0) {
            returnId = configItemList[0].Id;
        }
        return returnId;
    }
    
    public static CustomHttpHeaderWrapper buildCustomHttpHeader(String key, String value) {
        return new CustomHttpHeaderWrapper(key, value);
    }
    
    public static String getFormattedDealerId() {
        String dealerId = getDealerId();
        if(dealerId != null && dealerId.length() < 10) {
            dealerId = dealerId.leftPad(10, '0');
        }
        return dealerId;
    }

    public static String getDealerId() {
        return BRP_Settings__c.getOrgDefaults().Dealer_Id__c;
    }
    
    public static String getEndpoint() {
        return BRP_Settings__c.getOrgDefaults().Endpoint__c;
    }
    
    public static String getDealerRadius() {
        return (BRP_Settings__c.getOrgDefaults().Radius__c != null) ? String.valueOf(BRP_Settings__c.getOrgDefaults().Radius__c) : null;
    }
    
    public static String getDealerRadiusMeasure() {
        return BRP_Settings__c.getOrgDefaults().Radius_Measure__c;
    }

    public static String getAPIVersion() {
        return BRP_Settings__c.getOrgDefaults().API_Version__c;
    }
    
    public static Set<String> getAllBRPVendorsIdSet() {
        List<BRP_Vendors_List__c> brpVendorList =  BRP_Vendors_List__c.getAll().values();
        Set<String> brpVendorIdSet = new Set<String>();
        for(BRP_Vendors_List__c brpVendorRec : brpVendorList) {
            if(brpVendorRec.Type__c == 'Vendor' && brpVendorRec.Is_Active_Vendor__c) {
                brpVendorIdSet.add(brpVendorRec.Name);
            }
        }
        return brpVendorIdSet;
    }

    public static String getBRPVendorIdForPartsMaster() {
        List<BRP_Vendors_List__c> brpVendorList =  BRP_Vendors_List__c.getAll().values();
        String brpVendorId;
        for(BRP_Vendors_List__c brpVendorRec : brpVendorList) {
            if(brpVendorRec.Type__c == 'Vendor' && brpVendorRec.Is_Active_Vendor__c && brpVendorRec.Is_Used_For_Parts_Master__c) {
                brpVendorId = brpVendorRec.Name;
                break;
            }
        }
        return brpVendorId;
    }

    public static Boolean isPartOrderingVendor(String vendorId) {
        BRP_Vendors_List__c brpVendor = BRP_Vendors_List__c.getValues(vendorId);
        return (brpVendor != null && brpVendor.Type__c == 'Vendor' && brpVendor.Is_Active_Vendor__c && brpVendor.Is_Used_For_Parts_Ordering__c && brpVendor.Is_Used_For_Parts_Master__c);
    }

    public static Set<String> getAllBRPUnitMakeIdSet() {
        List<BRP_Vendors_List__c> brpUnitMakeList =  BRP_Vendors_List__c.getAll().values();
        Set<String> brpUnitMakeIdSet = new Set<String>();
        for(BRP_Vendors_List__c brpUnitMakeRec : brpUnitMakeList) {
            if(brpUnitMakeRec.Type__c == 'Unit Make' && brpUnitMakeRec.Is_Active_Vendor__c) {
                brpUnitMakeIdSet.add(brpUnitMakeRec.Name);
            }
        }
        return brpUnitMakeIdSet;
    }

    public static String getOrgName() {
        return BRP_Settings__c.getOrgDefaults().Org_Name__c;
    }

    public static String getCronExpression() {
        return BRP_Settings__c.getOrgDefaults().Part_Inventory_Cron_Expression__c != null ? BRP_Settings__c.getOrgDefaults().Part_Inventory_Cron_Expression__c : ScheduleJobService.jobNameToCronExpMap.get(ScheduleJobService.BRP_PART_INVENTORY_SCHEDULER);
    }
    
    public static dom.XmlNode createRequestHeaderNode(DOM.Document doc, String methodType) {
        dom.XmlNode root = doc.createRootElement(methodType, nameSpace, prefix);
        root.setAttribute('releaseID', release);
        root.setAttribute('languageCode', languageCode);
        root.setNamespace('star', nameSpace);
        
        createApplicationAreaNode(root, methodType);
        return root;
    }
    
    private static void createApplicationAreaNode(dom.XmlNode root, String methodType) {
        dom.XmlNode applicationArea = addChildElement(root, 'ApplicationArea');
        dom.XmlNode sender = addChildElement(applicationArea, 'Sender');
        
        addChildElementWithValue(sender, 'ReferenceID', GuidUtil.generateGuid());
        if(methodType == 'ProcessPartsOrder' || methodType == 'GetPartsOrder') {
        	addChildElementWithValue(sender, 'AuthorizationID', '00dd59a2-df7c-4d17-b37a-9d0827b1b9db'); // for the purpose of test cases
        } else {
        	addChildElementWithValue(sender, 'AuthorizationID', '1234');
        }
        addChildElementWithValue(sender, 'CreatorNameCode', 'Blackpurl');
        addChildElementWithValue(sender, 'SenderNameCode', 'BP');
        addChildElementWithValue(sender, 'DealerNumberID', getDealerId());

        if(methodType == 'ProcessPartsOrder' || methodType == 'GetPartsOrder') {
        	List<IFW_IntegrationConfig__c> ifwList = IFW_SOQLUtil.getIntegrationConfig(new Map<String, Object>{'Integration_Name__c' => BRP_OAUTH2});
        	if(ifwList.size() > 0) {
        		addChildElementWithValue(sender, 'Password', ifwList[0].Access_Token__c);
        	}
        }
        addChildElementWithValue(sender, 'SystemVersion', '12');
        addChildElementWithValue(sender, 'ServiceID', methodType);
        if(methodType == 'ProcessRepairOrder' && BRPRepairOrderService.repairOrderCreationDate != null) {
        	addChildElementWithValue(applicationArea, 'CreationDateTime', BRPRepairOrderService.repairOrderCreationDate.format('yyyy-MM-dd\'T\'HH:mm:ssXXX'));
        } else if(methodType == 'ProcessPartsOrder' || methodType == 'GetPartsOrder') {
        	addChildElementWithValue(applicationArea, 'CreationDateTime', system.now().formatGMT('yyyy-MM-dd\'T\'HH:mm:ss') + 'Z');
        } else {
        	addChildElementWithValue(applicationArea, 'CreationDateTime', system.now().format('yyyy-MM-dd\'T\'HH:mm:ssXXX'));
        }
        addChildElementWithValue(applicationArea, 'BODID', GuidUtil.generateGuid());
        
        dom.XmlNode destination = addChildElement(applicationArea, 'Destination');
        addChildElementWithValue(destination, 'DestinationNameCode', 'BD');
    }
    
    public static void addChildElementWithValue(dom.XmlNode parentNode, String childNodeName, String nodeValue) {
        nodeValue = (nodeValue == null ? '' : nodeValue);
        parentNode.addChildElement(childNodeName, nameSpace, null).addTextNode(nodeValue);
    }
    
    public static void addChildElementWithAttribute(dom.XmlNode parentNode, String childNodeName, String nodeValue, String attributeName, String attributeValue) {
        nodeValue = (nodeValue == null ? '' : nodeValue);
        dom.XmlNode childNode = parentNode.addChildElement(childNodeName, nameSpace, prefix);
        childNode.setAttribute(attributeName, attributeValue);
        childNode.addTextNode(nodeValue);
    }
    
    public static dom.XmlNode addAttributeElementWithoutValue(dom.XmlNode parentNode, String childNodeName, String attributeName, String attributeValue) {
        dom.XmlNode childNode = parentNode.addChildElement(childNodeName, nameSpace, prefix);
        childNode.setAttribute(attributeName, attributeValue);
        return childNode;
    }
    
    public static dom.XmlNode addChildElement(dom.XmlNode parentNode, String childNodeName) {
        return parentNode.addChildElement(childNodeName, nameSpace, prefix);
    }

    public static void addChildElementWithPrefix(dom.XmlNode parentNode, String childNodeName, String nameSpace, String prefixName, String attributeName, String attributeValue, String nodeValue) {
        dom.XmlNode childNode = parentNode.addChildElement(childNodeName, nameSpace, prefixName);
		childNode.setAttribute(attributeName, attributeValue);
        if(!String.isBlank(nodeValue)) {
            childNode.addTextNode(nodeValue);
        }
    }
    
    public static BRPResponseWrapper parseXMLResponse(String xmlString) {
    	return (BRPResponseWrapper)new XMLSerializer().deSerialize(xmlString, BRPResponseWrapper.class);
    }
    
    public static BRPResponseWrapper parseXMLResponse(String xmlString, Set<String> deSerializeNodesAsArray) {
    	return (BRPResponseWrapper)new XMLSerializer().deSerialize(xmlString, BRPResponseWrapper.class, deSerializeNodesAsArray);
    }
    
    public static String getUpdatedResBodyIfMultipleErrors(String responseBody) {
    	String resJsonStr = new XMLSerializer().XMLToJSON(responseBody);
		if(resJsonStr.contains('ConfirmBOD') && resJsonStr.contains('"ErrorProcessMessage":[')) {
			responseBody = responseBody.replace('ErrorProcessMessage', 'ErrorProcessMessageList');
		}
		return responseBody;
    }
    
    public static BRP_Log__c handleResponse(String entityName, String requestParamStr, HttpResponse res) {
    	String ackNodeName = syncEntityNameToAckNodeNameMap.get(entityName) != null ? syncEntityNameToAckNodeNameMap.get(entityName) : '';
    	BRPLogService brpLogServiceObj = new BRPLogService();
    	brpLogServiceObj.entityName = entityName;
    	brpLogServiceObj.requestParams = requestParamStr;
    	brpLogServiceObj.responseCode = res.getStatusCode() != null ? String.valueOf(res.getStatusCode()) : null;
    	String responseBody = res.getBody();
    	
    	if(String.isNotBlank(ackNodeName) && (responseBody.contains(ackNodeName) || responseBody.contains('ConfirmBOD'))) {
    		responseBody = getUpdatedResBodyIfMultipleErrors(responseBody);
			BRPResponseWrapper responseObj = BRPUtility.parseXMLResponse(responseBody);
	        if(responseObj.ConfirmBOD != null) {
	        	// BRP failure
	        	brpLogServiceObj.logType = 'Error';
        		handleErrorResponse(responseObj.ConfirmBOD, brpLogServiceObj);
        	} else {
        		// BRP success
        		brpLogServiceObj.logType = 'Info';
        		if(ackNodeName == 'AcknowledgePartsInventory') {
		        	handleSuccessResponse(responseObj.AcknowledgePartsInventory, brpLogServiceObj);
		        } else if(ackNodeName == 'AcknowledgePartsInvoice') {
		        	handleSuccessResponse(responseObj.AcknowledgePartsInvoice, brpLogServiceObj);
	        	} else if(ackNodeName == 'AcknowledgeRepairOrder') {
		        	handleSuccessResponse(responseObj.AcknowledgeRepairOrder, brpLogServiceObj);
	        	} else if(ackNodeName == 'AcknowledgeRetailDeliveryReporting') {
		        	handleSuccessResponse(responseObj.AcknowledgeRetailDeliveryReporting, brpLogServiceObj);
	        	} else if(ackNodeName == 'AcknowledgePartsOrder') {
		        	//handleSuccessResponse(responseObj.AcknowledgePartsOrder, brpLogServiceObj);
	        	}
        	}
    	} else if((entityName == 'DSP Info' || entityName == 'DMSInfo' || entityName == 'Parts Inventory') && (res.getStatusCode() == 200 || res.getStatusCode() == 201)) {
    		brpLogServiceObj.logType = 'Info';
    		brpLogServiceObj.errorMessages = responseBody;
    	} else {
    		brpLogServiceObj.logType = 'Error';
    		brpLogServiceObj.errorMessages = responseBody;
    	}
    	return brpLogServiceObj.sampleLog();
    }
    
    private static void handleSuccessResponse(BRPResponseWrapper.AcknowledgeWrapper acknowledgePartsInventory, BRPLogService brpLogServiceObj) {
    	String requestBODId = '';
    	String responseBODId = '';
    	if(acknowledgePartsInventory != null && acknowledgePartsInventory.ApplicationArea != null) {
    		responseBODId = acknowledgePartsInventory.ApplicationArea.BODID;
    		if(acknowledgePartsInventory.ApplicationArea.Sender != null) {
    			requestBODId = acknowledgePartsInventory.ApplicationArea.Sender.ReferenceID;
    		}
    	}
    	brpLogServiceObj.requestBODId = requestBODId;
    	brpLogServiceObj.responseBODId = responseBODId;
    }
    
    private static void handleErrorResponse(BRPResponseWrapper.ConfirmBODWrapper confirmBOD, BRPLogService brpLogServiceObj) {
    	String requestBODId = '';
    	String responseBODId = '';
    	String errorMsgs = '';
    	if(confirmBOD != null) {
    		if(confirmBOD.ApplicationArea != null) {
	    		responseBODId = confirmBOD.ApplicationArea.BODID;
	    		if(confirmBOD.ApplicationArea.Sender != null) {
	    			requestBODId = confirmBOD.ApplicationArea.Sender.ReferenceID;
	    		}
	    	}
	    	if(confirmBOD.ConfirmBODDataArea != null && confirmBOD.ConfirmBODDataArea.BOD != null 
	    				&& confirmBOD.ConfirmBODDataArea.BOD.BODFailureMessage != null) {
				if(confirmBOD.ConfirmBODDataArea.BOD.BODFailureMessage.ErrorProcessMessage != null) {
					errorMsgs = System.JSON.serialize(confirmBOD.ConfirmBODDataArea.BOD.BODFailureMessage.ErrorProcessMessage);
				} else if(confirmBOD.ConfirmBODDataArea.BOD.BODFailureMessage.ErrorProcessMessageList != null) {
					errorMsgs = System.JSON.serialize(confirmBOD.ConfirmBODDataArea.BOD.BODFailureMessage.ErrorProcessMessageList);
				}
	    	}
    	}
    	brpLogServiceObj.requestBODId = requestBODId;
    	brpLogServiceObj.responseBODId = responseBODId;
    	brpLogServiceObj.errorMessages = errorMsgs;
    }
    
    public static List<String> BRPPriceFieldsList = new List<String>{'Sold', 'Suggested Retail Price', 'Cost'};

    public static String getFileNameByFileType(String fileType, DateTime dateTimeValue) {
        String fileName = '';
        if(String.isNotBlank(fileType)) {
            fileName = fileType + '_';
        }
        fileName += getDealerId() + '_';
        fileName += (dateTimeValue != null ? dateTimeValue.format('yyyyMMdd') : Datetime.now().format('yyyyMMdd'));

        return fileName;
    }
    
    public static Map<String, String> syncEntityNameToSyncFlagAPINameMap = new Map<String, String>{
    																			'Parts Invoice'	=>	'Available_For_BRP_Parts_Invoice_Sync__c',
    																			'Repair Order'	=>	'Available_For_BRP_Repair_Order_Sync__c',
    																			'Retail Delivery Reporting'	=>	'Available_For_BRP_RDR_Sync__c'
    };
    
    public static Map<String, Type> syncEntityNameToBatchName = new Map<String, Type>{
    																			'Parts Invoice'	=>	BRPPartsInvoiceBatch.class,
    																			'Repair Order'	=>	BRPRepairOrderBatch.class,
    																			'Retail Delivery Reporting'	=>	BRPRetailDeliveryReportingBatch.class
    };
    
    public static Map<String, String> syncEntityNameToAckNodeNameMap = new Map<String, String>{
    																			'Parts Inventory'	=>	'AcknowledgePartsInventory',
    																			'Parts Invoice'	=>	'AcknowledgePartsInvoice',
                                                                                'Repair Order'	=>	'AcknowledgeRepairOrder',
                                                                                'Retail Delivery Reporting'	=>	'AcknowledgeRetailDeliveryReporting'
    };
    
    public static void createCustomerNodeForNonCustomerCO(dom.XmlNode parentNode, String nodeValue, String coType) {
    	dom.XmlNode customerNode = BRPUtility.addChildElement(parentNode, nodeValue);
    	dom.XmlNode specifiedPerson = BRPUtility.addChildElement(customerNode, 'SpecifiedPerson');
		addChildElementWithValue(specifiedPerson, 'FamilyName', coType);
    }
    
    public static void createCustomerNode(dom.XmlNode parentNode, String nodeValue, Account customerRec) {
    	if(customerRec != null) {
    		dom.XmlNode customerNode = BRPUtility.addChildElement(parentNode, nodeValue);
	    	if(String.isNotBlank(customerRec.Type__c) && customerRec.Type__c == 'Business') {
	    		dom.XmlNode specifiedOrgNode = BRPUtility.addChildElement(customerNode, 'SpecifiedOrganization');
	    		BRPUtility.addChildElementWithValue(specifiedOrgNode, 'CompanyName', customerRec.Name);
	    		
	    		dom.XmlNode primaryContactNode = BRPUtility.addChildElement(specifiedOrgNode, 'PrimaryContact');
	    		if(customerRec.Peoples__r.size() > 0) {
	    			BRPUtility.addChildElementWithValue(primaryContactNode, 'TypeCode', customerRec.Peoples__r[0].Relationship__c); 
	    		} else {
	    			addChildElementWithValue(primaryContactNode, 'TypeCode', 'Company Contact'); 
	    		}
	    		createSpecifiedPersonNode(primaryContactNode, (customerRec.Peoples__r.size() > 0 ? customerRec.Peoples__r[0].Parent_Customer2__r : customerRec));
	    	} else {
	    		createSpecifiedPersonNode(customerNode, customerRec);
	    	}
    	}
    }
    
    public static void createSpecifiedPersonNode(dom.XmlNode parentNode, Account customerRec) {
    	if(customerRec != null) { 
    		dom.XmlNode specifiedPerson = addChildElement(parentNode, 'SpecifiedPerson');
	    	if(String.isNotBlank(customerRec.Type__c) && customerRec.Type__c == 'Business') {
				addChildElementWithValue(specifiedPerson, 'FamilyName', customerRec.Name);
	    	} else {
	    		addChildElementWithValue(specifiedPerson, 'GivenName', customerRec.FirstName__c);
				addChildElementWithValue(specifiedPerson, 'FamilyName', customerRec.LastName__c);
	    	}
			
			createTelephoneCommunicationNode(specifiedPerson, customerRec);
			createURICommunicationNode(specifiedPerson, customerRec);
			
			dom.XmlNode postalAddress = addChildElement(specifiedPerson, 'PostalAddress');
			String billingStreet = (customerRec.BillingStreet == null ) ? '' : customerRec.BillingStreet;
			if(String.isNotBlank(billingStreet)) {
				List<String> bsList = billingStreet.split('\n');
				addChildElementWithValue(postalAddress, 'LineOne', (bsList.size() > 0) ? bsList[0] : '');
			}
			addChildElementWithValue(postalAddress, 'CityName', customerRec.BillingCity);
			
			createCountryIdElement(postalAddress, customerRec.BillingCountry);
			addChildElementWithValue(postalAddress, 'Postcode', customerRec.BillingPostalCode);
			if(String.isNotBlank(customerRec.BillingState)) {
				addChildElementWithValue(postalAddress, 'StateOrProvinceCountrySub-DivisionID', 
											customerRec.BillingState.length() > 6 ? customerRec.BillingState.subString(0, 6) : customerRec.BillingState);
			}
    	}
    }
    
    public static void createTelephoneCommunicationNode(dom.XmlNode specifiedPersonNode, Account customerRec) {
    	Set<String> phoneNumbetSet = new Set<String>();
    	if(String.isNotBlank(customerRec.Type__c) && customerRec.Type__c == 'Business') {
    		phoneNumbetSet.add(customerRec.Work_Number__c);
    	} else {
    		phoneNumbetSet.add(customerRec.Home_Number__c);
    	}
    	phoneNumbetSet.add(customerRec.Mobile__c);
    	phoneNumbetSet.remove(null);
    	for(String phnNumber : phoneNumbetSet) {
            String localNumber = phnNumber.contains('(') ? phnNumber.substring(5, phnNumber.length()) : phnNumber.substring(3, phnNumber.length());
            String areaCode = phnNumber.contains('(') ? phnNumber.substring(1, 4) : phnNumber.substring(0, 3);
	    	dom.XmlNode telephoneCommunication = addChildElement(specifiedPersonNode, 'TelephoneCommunication');
			addChildElementWithValue(telephoneCommunication, 'ChannelCode', 'telephone');
            addChildElementWithValue(telephoneCommunication, 'LocalNumber', localNumber);
            addChildElementWithValue(telephoneCommunication, 'AreaNumberCode', areaCode);
    	}
    }
    
    public static void createURICommunicationNode(dom.XmlNode specifiedEntity, Account customerRec) {
    	Set<String> emailSet = new Set<String>();
    	if(String.isNotBlank(customerRec.Type__c) && customerRec.Type__c == 'Business') {
    		emailSet.add(customerRec.Work_Email__c);
    	} else {
    		emailSet.add(customerRec.Email__c);
    	}
    	emailSet.add(customerRec.Other_Email__c);
    	emailSet.remove(null);
    	for(String email : emailSet) {
    		dom.XmlNode uriCommunication = addChildElement(specifiedEntity, 'URlCommunication');
			addChildElementWithValue(uriCommunication, 'URIID', email);
			addChildElementWithValue(uriCommunication, 'ChannelCode', 'email');
    	}
    }
    public static void initiateBatch(Set<Id> idSet, String syncEntityName, Integer retryAttemptNumber) {
    	BRPBaseSyncingBatch batchObj = (BRPBaseSyncingBatch)syncEntityNameToBatchName.get(syncEntityName).newInstance(); 
        if(retryAttemptNumber != null) batchObj.retryRequestNumber = retryAttemptNumber;
        batchObj.setIdSet(idSet);
        batchObj.setSyncEntityName(syncEntityName);
        Database.executeBatch(batchObj, 10);
    }
    
    public static void createTaxNode(dom.XmlNode parentNode, List<Individual_Tax__c> individualTaxList) {
        Map<String, Decimal> salesTaxItemFormLabelToTaxRateMap = new Map<String, Decimal>();
        Map<String, Decimal> salesTaxItemFormLabelToTaxableAmountMap = new Map<String, Decimal>();
        for(Individual_Tax__c indTaxRec: individualTaxList) {
    		if(!salesTaxItemFormLabelToTaxRateMap.containsKey(indTaxRec.Sales_Tax_Item__r.Name__c)) {
    			salesTaxItemFormLabelToTaxRateMap.put(indTaxRec.Sales_Tax_Item__r.Name__c, indTaxRec.Tax_Rate__c);
    		}
    		if(!salesTaxItemFormLabelToTaxableAmountMap.containsKey(indTaxRec.Sales_Tax_Item__r.Name__c)) {
    			salesTaxItemFormLabelToTaxableAmountMap.put(indTaxRec.Sales_Tax_Item__r.Name__c, 0);
    		}
    		if(indTaxRec.Taxable_Amount__c != null) {
	    		salesTaxItemFormLabelToTaxableAmountMap.put(indTaxRec.Sales_Tax_Item__r.Name__c, 
	    				salesTaxItemFormLabelToTaxableAmountMap.get(indTaxRec.Sales_Tax_Item__r.Name__c) + indTaxRec.Taxable_Amount__c);
    		}
    	}
        
        for(String salesTaxItemName: salesTaxItemFormLabelToTaxRateMap.keySet()) {
        	dom.XmlNode taxNode = addChildElement(parentNode, 'Tax');
        	addChildElementWithValue(taxNode, 'TaxTypeCode', 'Total');
        	
        	Decimal taxRate = salesTaxItemFormLabelToTaxRateMap.get(salesTaxItemName) != null ? salesTaxItemFormLabelToTaxRateMap.get(salesTaxItemName) : 0.00;
        	
        	Decimal taxableAmount = salesTaxItemFormLabelToTaxableAmountMap.get(salesTaxItemName);
        	Decimal taxAmount = (taxableAmount * taxRate / 100).setScale(2, RoundingMode.HALF_UP);
        	
        	addChildElementWithAttribute(taxNode, 'TaxAmount', String.valueOf(taxAmount), 'currencyID', CurrencyCode);
	        addChildElementWithValue(taxNode, 'TaxRatePercent', String.valueOf((taxRate / 100).setScale(8)));
	        addChildElementWithAttribute(taxNode, 'TotalTaxableAmount', String.valueOf(taxableAmount), 'currencyID', CurrencyCode);
        }
    }
    
    public static void createPricingNode(dom.XmlNode parentNode, String priceCode, String priceDescription, Decimal amount) {
    	dom.XmlNode priceNode = addChildElement(parentNode, 'Price');
    	addChildElementWithValue(priceNode, 'PriceCode', priceCode);
    	amount = amount != null ? amount : 0;
    	addChildElementWithAttribute(priceNode, 'ChargeAmount', String.valueOf(amount), 'currencyID', CurrencyCode);
    	if(String.isNotBlank(priceDescription)) {
    		addChildElementWithValue(priceNode, 'PriceDescription', priceDescription);
    	}
    }
    
    public static List<CustomHttpHeaderWrapper> getHeaderList() {
        List<CustomHttpHeaderWrapper> headerList = new List<CustomHttpHeaderWrapper>();
        headerList.add(BRPUtility.buildCustomHttpHeader('Content-Type', BRPUtility.contentType));
        headerList.add(BRPUtility.buildCustomHttpHeader('Accept-Language', 'en-US'));
        headerList.add(BRPUtility.buildCustomHttpHeader('Connection', 'Keep-Alive'));
        headerList.add(BRPUtility.buildCustomHttpHeader('Accept-Charset', 'UTF-8'));
        headerList.add(BRPUtility.buildCustomHttpHeader('Accept', BRPUtility.contentType));
        headerList.add(BRPUtility.buildCustomHttpHeader('Accept-Encoding', 'gzip'));
        return headerList;
    }
    
    public static HttpResponse syncToBRP(String syncActionName, String requestBody) {
    	return syncToBRP(syncActionName, requestBody, 'POST');
    }

    public static HttpResponse syncToBRP(String syncActionName, String requestBody, String methodType) {
        return syncToBRP(syncActionName, requestBody, methodType, New Map<String, String>(), New Map<String, String>());
    }   


    public static HttpResponse syncToBRP(String syncActionName, String requestBody, String methodType, Map<String, String> parameters, Map<String, String> endPointPathParamMap) {
        List<CustomHttpHeaderWrapper> headerList = new List<CustomHttpHeaderWrapper>{};
        String authenticationType;
        IFW_IntegrationConfig__c configRec;

        if(brp2ApiList.contains(syncActionName)) {
            authenticationType = BRPUtility.BRP_2;
            configRec = getBRP2IfwConfig();
            headerList = getBRP2HeaderList(syncActionName);
        } else if(syncActionName == 'DMSInfo') {
            authenticationType = BRPUtility.BRP_DMS_OAUTH2;
            headerList = new List<CustomHttpHeaderWrapper>{};
            configRec = getBRPDMSIFWConfigForAuth2();
        } else {
        	authenticationType = BRPUtility.BRP;
        	configRec = getBRPIFWConfig();
        	headerList = getHeaderList();
        }
        String oldAccessToken = configRec.Access_Token__c;
        IFW_IntegrationConfigItem__c configItemRec = getIFWConfigItem(syncActionName, methodType, authenticationType);
        if(configItemRec == null) throw new BlackPurlException('IFW Config item is not defined.');
        updateParmInEndPoint(configItemRec, endPointPathParamMap);
        HttpResponse response = BaseIntegration.performCallout(configRec, configItemRec, requestBody, headerList, parameters);
        if(oldAccessToken != configRec.Access_Token__c) {
        	update configRec;
        }
        if(BaseIntegration.webServiceLogs != null) DMLUtility.insertSobjectList('WebService_Log__c', BaseIntegration.webServiceLogs);
        return response;
    }

    public static void updateParmInEndPoint(IFW_IntegrationConfigItem__c configItemRec,Map<String, String> endPointPathParamMap) {
        if(configItemRec != null && endPointPathParamMap != null && endPointPathParamMap.size() > 0) {
            for(String key : endPointPathParamMap.keySet()) {
                if(configItemRec.Endpoint_URL__c.contains(key)) {
                    configItemRec.Endpoint_URL__c = configItemRec.Endpoint_URL__c.replace(key, endPointPathParamMap.get(key));
                }
            }
        }
    }

    public static List<CustomHttpHeaderWrapper> getBRP2HeaderList(String syncActionName) {
        List<CustomHttpHeaderWrapper> headerList = new List<CustomHttpHeaderWrapper>();
        if(brp2DealerHeaderList.contains(syncActionName)) {
            headerList.add(BRPUtility.buildCustomHttpHeader('Dealer-Number', BRP_Settings__c.getOrgDefaults().Dealer_Id__c));
        }
        if(syncActionName == GET_CAMPAIGNS || syncActionName == GET_ARTICLE) {
            headerList.add(BRPUtility.buildCustomHttpHeader('x-brp-host', (Constants.NAMESPACE).equalsIgnoreCase('BlackPurlCore__') ? 'cloud-api.brp.com' : 'qa1-cloud-api.brp.com'));
        }
        return headerList;
    }

    public static void insertBRPLog(String entityName, String requestBody, HttpResponse response, String apexClassName) {
        BRP_log__c brpLog = BRPUtility.handleResponse(entityName, requestBody, response);
        brpLog.Apex_Class__c = apexClassName;
        DMLUtility.insertSobjectList('BRP_log__c', new List<BRP_log__c>{brpLog});
    }

    public static String getBRPFileStorageId() {
        if(!AccessControl.ifObjectFieldIsAccessible('File_Storage__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<File_Storage__c> fileStorageList = [SELECT Id FROM File_Storage__c WHERE Name__c = 'BRP' LIMIT 1];
        
        File_Storage__c fileStorageRec = new File_Storage__c();
        if(fileStorageList.size() > 0) {
            fileStorageRec = fileStorageList[0];
        } else {
            fileStorageRec.Name__c = 'BRP';
            DMLUtility.insertSobjectList('File_Storage__c', fileStorageRec);
        }
        return fileStorageRec.Id;
    }
    
    public static void createCountryIdElement(dom.XmlNode parentNode, String countryName) {
    	if(String.isNotBlank(countryName)) {
			if(countryName == 'Canada') {
				BRPUtility.addChildElementWithValue(parentNode, 'CountryID', 'CA');
			} else if(countryName == 'USA') {
				BRPUtility.addChildElementWithValue(parentNode, 'CountryID', 'US');
			}
    	}
    }
    
    public static String getBRPOauth2AccessToken() {
    	for(IFW_IntegrationConfig__c ifwRec : IFW_SOQLUtil.getIntegrationConfig(new Map<String, Object>{'Integration_Name__c' => BRP_OAUTH2})) {
    		return ifwRec.Access_Token__c;
    	}
    	return null;
    }
    
    public static Map<String, Account> getCustomerIdToRecMap(List<CO_Invoice_Header__c> coInvList) {
    	Set<String> customerIdSet = new Set<String>();
		for(CO_Invoice_Header__c coInvRec: coInvList) {
			customerIdSet.add(coInvRec.CO_Header__r.Customer__c);
	    }
	    customerIdSet.remove(null);
      
      	String query = 'SELECT ';
        for(String fieldName : objectToFieldMap.get('CustomerWithFirstContact')) {
            fieldName = BPUtility.escapeSingleQuotes(fieldName);
            query += fieldName + ', ';
        }
        query = query.substring(0, query.length() - 2);
        query += ' FROM Account WHERE Id IN: customerIdSet';
        
        return new Map<String, Account>((List<Account>)Database.query(query));
    }
    
    public static BRP_Dealers__c getBRPDealerDetail() {
    	List<BRP_Dealers__c> brpDealerList = [select Care_Of__c, Address_ID__c from BRP_Dealers__c where Party_ID__c =: getDealerId()];
    	return brpDealerList.size() > 0 ? brpDealerList[0] : null;
    }
    
    public static Boolean isPartsMasterVendor(String vendorId) {
    	return (BRPUtility.isBRPEnabled() && isPartOrderingVendor(vendorId));
    }
    
    public static String prependZerosToString(String str, Integer maxNumberOfCharsInStr) {
    	while(str.length() < maxNumberOfCharsInStr) {
    		str = '0' + str;
    	}
    	return str;
    }
	
    public static void checkForRetryLogic(Exception e, SObject syncObj, Integer retryRequestNumber, Map<String, List<SObject>> failedRecordsMap) {
        Map<String, Integration_Error_Handling_Config__mdt> errorTypeToRetryConfigListMap = AccountingUtil.getRetryConfigsByIntegration(BRP);
        String errorKeywordWhileSyncing;
        for(String errorType : errorTypeToRetryConfigListMap.keySet()) {
            if(e.getMessage() != null && e.getMessage().containsIgnoreCase(errorType)) {
                errorKeywordWhileSyncing = errorType;
                break;
            }
        }
        if(String.isNotBlank(errorKeywordWhileSyncing) && retryRequestNumber <= BRPUtility.MAX_RETRY_COUNT) {
            writeToFailedRecordsMap(errorKeywordWhileSyncing, syncObj, failedRecordsMap);
        }
    }

	private static void writeToFailedRecordsMap(String key, SObject failedObject, Map<String, List<SObject>> failedRecordsMap) {
        if(!failedRecordsMap.containsKey(key)) {
            failedRecordsMap.put(key, new List<SObject>());
        }
        failedRecordsMap.get(key).add(failedObject);
    }

    public static Map<String, String> currencyCodeToCountryCodeMap = new Map<String, String>{
    	'CAD'	=>	'CA',
    	'USD'	=>	'US'
    };

    public static Map<String, String> brpPOStatusTextToBRPStatusMap = new Map<String, String>{
    	'your order is in the process of delivery'	=>	'In process',
    	'your order has been shipped'	=>	'Shipped',
    	'some item have a status to pay attention'	=>	'Review',
    	'your order has been cancelled'	=>	'Cancelled'
    };

    private static Map<String, Set<String>> objectToFieldMap = new Map<String, Set<String>>{
        'CustomerWithFirstContact'       => new Set<String>{ 
        									'Id',
                                            'Name',
                                            'Type__c',
											'FirstName__c',
											'LastName__c',
											'Home_Number__c',
											'Work_Number__c',
											'Mobile__c',
											'Email__c',
											'Work_Email__c',
											'Other_Email__c',
											'BillingCity',
											'BillingStreet',
											'BillingState',
											'BillingCountry',
											'BillingPostalCode',
                                            '(SELECT Id, Relationship__c, ' +
                                            'Parent_Customer2__r.Name, ' +
                                            'Parent_Customer2__r.Type__c, ' +
											'Parent_Customer2__r.FirstName__c, ' +
											'Parent_Customer2__r.LastName__c, ' +
											'Parent_Customer2__r.Home_Number__c, ' +
											'Parent_Customer2__r.Mobile__c, ' +
											'Parent_Customer2__r.Work_Number__c, ' +
											'Parent_Customer2__r.Email__c, ' +
											'Parent_Customer2__r.Work_Email__c, ' +
											'Parent_Customer2__r.Other_Email__c, ' +
											'Parent_Customer2__r.BillingCity, ' +
											'Parent_Customer2__r.BillingStreet, ' +
											'Parent_Customer2__r.BillingState, ' +
											'Parent_Customer2__r.BillingCountry, ' +
											'Parent_Customer2__r.BillingPostalCode FROM Peoples__r ORDER BY Name ASC LIMIT 1) '
                                        }
    };

    public static Map<String, Map<String, String>> entityNameToFieldNameToValueMapForBasicIFW = new Map<String, Map<String, String>>{
        'GetDealer' => new Map<String, String>{
            Constants.NAMESPACE + 'HTTP_Method__c' => 'POST',
            Constants.NAMESPACE + 'Endpoint_URL__c' => 'https://qa-api.brp.com/facade/star/services/DealerLocator/Get',
            Constants.NAMESPACE + 'Entity_Name__c' => 'GetDealer'
        },
        'GetPartLocator' => new Map<String, String>{
            Constants.NAMESPACE + 'HTTP_Method__c' => 'POST',
            Constants.NAMESPACE + 'Endpoint_URL__c' => 'https://qa-api.brp.com/facade/star/services/PartsLocator/Get',
            Constants.NAMESPACE + 'Entity_Name__c' => 'GetPartLocator'
        },
        'GetVehicleSpecification' => new Map<String, String>{
            Constants.NAMESPACE + 'HTTP_Method__c' => 'GET',
            Constants.NAMESPACE + 'Endpoint_URL__c' => 'https://qa-api.brp.com/facade/star/services/VehicleSpecifications',
            Constants.NAMESPACE + 'Entity_Name__c' => 'GetVehicleSpecification'
        },
        'BRPPartInventory' => new Map<String, String>{
            Constants.NAMESPACE + 'HTTP_Method__c' => 'POST',
            Constants.NAMESPACE + 'Endpoint_URL__c' => 'https://qa-api.brp.com/facade/star/services/PartsInventory/Process',
            Constants.NAMESPACE + 'Entity_Name__c' => 'BRPPartInventory'
        },
        'BRPPartsInvoice' => new Map<String, String>{
            Constants.NAMESPACE + 'HTTP_Method__c' => 'POST',
            Constants.NAMESPACE + 'Endpoint_URL__c' => 'https://qa-api.brp.com/facade/star/services/PartsInvoice/Process',
            Constants.NAMESPACE + 'Entity_Name__c' => 'BRPPartsInvoice'
        },
        'BRPRepairOrder' => new Map<String, String>{
            Constants.NAMESPACE + 'HTTP_Method__c' => 'POST',
            Constants.NAMESPACE + 'Endpoint_URL__c' => 'https://qa-api.brp.com/facade/star/services/RepairOrder/Process',
            Constants.NAMESPACE + 'Entity_Name__c' => 'BRPRepairOrder'
        },
        'BRPRetailDeliveryReporting' => new Map<String, String>{
            Constants.NAMESPACE + 'HTTP_Method__c' => 'POST',
            Constants.NAMESPACE + 'Endpoint_URL__c' => 'https://qa-api.brp.com/facade/star/services/RetailDeliveryReporting/Process',
            Constants.NAMESPACE + 'Entity_Name__c' => 'BRPRetailDeliveryReporting'
        },
        'GetPartsMaster' => new Map<String, String>{
            Constants.NAMESPACE + 'HTTP_Method__c' => 'POST',
            Constants.NAMESPACE + 'Endpoint_URL__c' => 'https://qa-api.brp.com/facade/star/services/PartsMaster/Get',
            Constants.NAMESPACE + 'Entity_Name__c' => 'GetPartsMaster'
        },
        'BRPPartsOrder' => new Map<String, String>{
            Constants.NAMESPACE + 'HTTP_Method__c' => 'POST',
            Constants.NAMESPACE + 'Endpoint_URL__c' => 'https://qa-api.brp.com/facade/star/services/PartsOrder/Process',
            Constants.NAMESPACE + 'Entity_Name__c' => 'BRPPartsOrder'
        },
        'BRPRetrievePartsOrder' => new Map<String, String>{
            Constants.NAMESPACE + 'HTTP_Method__c' => 'GET',
            Constants.NAMESPACE + 'Endpoint_URL__c' => 'https://qa-api.brp.com/facade/star/services/PartsOrder/Get',
            Constants.NAMESPACE + 'Entity_Name__c' => 'BRPRetrievePartsOrder'
        },
        'GetArticle' => new Map<String, String>{
            Constants.NAMESPACE + 'HTTP_Method__c' => 'GET',
            Constants.NAMESPACE + 'Endpoint_URL__c' => 'https://ms-brp-proxy-qa-kdumhzx3qq-uc.a.run.app/dealer_connect_program/service_history/v1/article/{article-no}',
            Constants.NAMESPACE + 'Entity_Name__c' => 'GetArticle'
        },
        'GetCampaigns' => new Map<String, String>{
            Constants.NAMESPACE + 'HTTP_Method__c' => 'GET',
            Constants.NAMESPACE + 'Endpoint_URL__c' => 'https://ms-brp-proxy-qa-kdumhzx3qq-uc.a.run.app/dealer_connect_program/service_history/v1/vin/{vin}/campaigns',
            Constants.NAMESPACE + 'Entity_Name__c' => 'GetCampaigns'
        }
    };

    public static Map<String, Map<String, String>> entityNameToFieldNameToValueMapForOAUth2POIFW = new Map<String, Map<String, String>>{
        'Authorize' => new Map<String, String>{
            Constants.NAMESPACE + 'HTTP_Method__c' => 'GET',
            Constants.NAMESPACE + 'Endpoint_URL__c' => 'https://qa-cloud-api.brp.com/dealer_accnt_mgmt/v1/authentication/oauth2/authorize',
            Constants.NAMESPACE + 'Entity_Name__c' => 'Authorize'
        },
        'Token' => new Map<String, String>{
            Constants.NAMESPACE + 'HTTP_Method__c' => 'POST',
            Constants.NAMESPACE + 'Endpoint_URL__c' => 'https://qa-cloud-api.brp.com/dealer_accnt_mgmt/v1/authentication/oauth2/token',
            Constants.NAMESPACE + 'Entity_Name__c' => 'Token'
        }
    };

    public static Map<String, Map<String, String>> entityNameToFieldNameToValueMapForDealerAuth = new Map<String, Map<String, String>>{
        'Authorize' => new Map<String, String>{
            Constants.NAMESPACE + 'HTTP_Method__c' => 'GET',
            Constants.NAMESPACE + 'Endpoint_URL__c' => 'https://qa-cloud-api.brp.com/dcp/authentication/dealer/authorize',
            Constants.NAMESPACE + 'Entity_Name__c' => 'Authorize'
        },
        'Token' => new Map<String, String>{
            Constants.NAMESPACE + 'HTTP_Method__c' => 'POST',
            Constants.NAMESPACE + 'Endpoint_URL__c' => 'https://qa-cloud-api.brp.com/dcp/authentication/dealer/token',
            Constants.NAMESPACE + 'Entity_Name__c' => 'Token'
        }
    };

    public static Map<String, Map<String, String>> entityNameToFieldNameToValueMapForOAUth2IFW = new Map<String, Map<String, String>>{
        'DSP Info' => new Map<String, String>{
            Constants.NAMESPACE + 'HTTP_Method__c' => 'POST',
            Constants.NAMESPACE + 'Endpoint_URL__c' => 'https://qa-cloud-api.brp.com/dcp/v4/dsp/dealers',
            Constants.NAMESPACE + 'Entity_Name__c' => 'DSP Info'
        },
        'Dealer Inventory' => new Map<String, String>{
            Constants.NAMESPACE + 'HTTP_Method__c' => 'POST',
            Constants.NAMESPACE + 'Endpoint_URL__c' => 'https://qa-cloud-api.brp.com/dcp/v4/parts/dealer-inventory',
            Constants.NAMESPACE + 'Entity_Name__c' => 'Dealer Inventory'
        },
        'Dealer Part Locator' => new Map<String, String>{
            Constants.NAMESPACE + 'HTTP_Method__c' => 'GET',
            Constants.NAMESPACE + 'Endpoint_URL__c' => 'https://qa-cloud-api.brp.com/dcp/v4/part/{{product_code}}/dealer-inventory',
            Constants.NAMESPACE + 'Entity_Name__c' => 'Dealer Part Locator'
        },
        'Token' => new Map<String, String>{
            Constants.NAMESPACE + 'HTTP_Method__c' => 'POST',
            Constants.NAMESPACE + 'Endpoint_URL__c' => 'https://qa-cloud-api.brp.com/dcp/authentication/app/token',
            Constants.NAMESPACE + 'Entity_Name__c' => 'Token'
        },
        'Part' => new Map<String, String>{
            Constants.NAMESPACE + 'HTTP_Method__c' => 'GET',
            Constants.NAMESPACE + 'Endpoint_URL__c' => 'https://qa-cloud-api.brp.com/dcp/v4/part/{{product_code}}',
            Constants.NAMESPACE + 'Entity_Name__c' => 'Part'
        },
        'Parts' => new Map<String, String>{
            Constants.NAMESPACE + 'HTTP_Method__c' => 'GET',
            Constants.NAMESPACE + 'Endpoint_URL__c' => 'https://qa-cloud-api.brp.com/dcp/v4/parts',
            Constants.NAMESPACE + 'Entity_Name__c' => 'Parts'
        },'GetDealer' => new Map<String, String>{
            Constants.NAMESPACE + 'HTTP_Method__c' => 'GET',
            Constants.NAMESPACE + 'Endpoint_URL__c' => 'https://qa-cloud-api.brp.com/dcp/v4/dealer/{{dealer_no}}',
            Constants.NAMESPACE + 'Entity_Name__c' => 'GetDealer'
        },'GetUnitSpecification' => new Map<String, String>{
            Constants.NAMESPACE + 'HTTP_Method__c' => 'GET',
            Constants.NAMESPACE + 'Endpoint_URL__c' => 'https://qa-cloud-api.brp.com/dcp/v4/unit/{{serial_no}}/specifications',
            Constants.NAMESPACE + 'Entity_Name__c' => 'GetUnitSpecification'
        },'Part Inventory' => new Map<String, String>{
            Constants.NAMESPACE + 'HTTP_Method__c' => 'GET',
            Constants.NAMESPACE + 'Endpoint_URL__c' => 'https://qa-cloud-api.brp.com/dcp/v4/part/{{product_code}}/inventory',
            Constants.NAMESPACE + 'Entity_Name__c' => 'Part Inventory'
        },'GetArticle' => new Map<String, String>{
            Constants.NAMESPACE + 'HTTP_Method__c' => 'GET',
            Constants.NAMESPACE + 'Endpoint_URL__c' => 'https://ms-brp-proxy-5niqfavtya-uc.a.run.app/dcp/v4/article/{{article_number}}',
            Constants.NAMESPACE + 'Entity_Name__c' => 'GetArticle'
        },'GetCampaigns' => new Map<String, String>{
            Constants.NAMESPACE + 'HTTP_Method__c' => 'GET',
            Constants.NAMESPACE + 'Endpoint_URL__c' => 'https://ms-brp-proxy-5niqfavtya-uc.a.run.app/dcp/v4/unit/{{serial_number}}/campaigns',
            Constants.NAMESPACE + 'Entity_Name__c' => 'GetCampaigns'
        }
    };
}