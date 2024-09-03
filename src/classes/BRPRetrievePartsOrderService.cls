/**
 * Author: Manoj Sharma
 * Since: july 03, 2021
 * Name: BRPRetrievePartsOrderService
 * Description: Service class for BRP GetPartsOrder xml creation
**/
public without sharing class BRPRetrievePartsOrderService {
    public static String methodType = 'GetPartsOrder';
	public static String orderActionCode = 'Validate';
	public static String nameSpace = 'http://www.openapplications.org/oagis/9';
	public static String vendorOrderNumber;
	public static BRPPOFilterWrapper filterObj = new BRPPOFilterWrapper();
	public static String PaginationRecReferenceId;

	public static String getPartsOrderByFilter(String filterJson, String paginationReferenceId) {
		PaginationRecReferenceId = paginationReferenceId;
		if(String.isNotBlank(filterJson)) {
			filterObj = (BRPPOFilterWrapper) System.JSON.deserialize(filterJson, BRPPOFilterWrapper.class);
			setDateFilterFields(filterObj);
		}
		List<BRPPartOrderHeaderWrapper> brpPartsOrderList = new List<BRPPartOrderHeaderWrapper>();
		vendorOrderNumber = null;
		HttpResponse response = getPartsOrderRequest();
		BRPShowPartOrderResponseWrapper responseObj;
		String recordSetReferenceId;
		if(response.getStatusCode() == 200 || response.getStatusCode() == 201) {
			recordSetReferenceId = getRecordSetReferenceId(response);
			responseObj = (BRPShowPartOrderResponseWrapper)new XMLSerializer().deSerialize(response.getBody(), BRPShowPartOrderResponseWrapper.class, new Set<String>{'PartsOrder', 'AcknowledgementStatus', 'Expression'});
		} else {
			throw new BlackPurlException(BRPUtility.BRP_ERROR_STRING + response.getStatusCode() + '::' + response.getBody());
		}
		if(responseObj != null) {
			List<BRPShowPartOrderResponseWrapper.PartsOrder> partsOrderList = new List<BRPShowPartOrderResponseWrapper.PartsOrder>();
			if(responseObj.ShowPartsOrder != null && responseObj.ShowPartsOrder.ShowPartsOrderDataArea != null && responseObj.ShowPartsOrder.ShowPartsOrderDataArea.PartsOrder != null) {
				partsOrderList = responseObj.ShowPartsOrder.ShowPartsOrderDataArea.PartsOrder;
			}
			String voNumber;

			for(BRPShowPartOrderResponseWrapper.PartsOrder partOrderobj : partsOrderList) {
				voNumber = '';
				for(BRPShowPartOrderResponseWrapper.DocumentIdentification docObj :partOrderobj.PartsOrderHeader.DocumentReferenceIdentificationGroup.DocumentIdentification) {
					if(docObj.AgencyRoleCode.equalsIgnoreCase('Customer Purchase Order Number')) {
						voNumber = docObj.DocumentID;
						break;
					}
				}
				if(String.isNotBlank(voNumber)) {
					brpPartsOrderList.add(new BRPPartOrderHeaderWrapper(voNumber, partOrderobj.PartsOrderHeader.RequestedShipDate, partOrderobj.PartsOrderHeader.AcknowledgementStatus[0].StatusText, partOrderobj.PartsOrderHeader.AcknowledgementStatus[0].StatusTypeCode));
				}
			}
		}
		return System.JSON.serialize(new BRPPartOrderWrapper(recordSetReferenceId, brpPartsOrderList));
	}

	public static String getPartOrderBRPStatus(String voNumber) {
		try {
			vendorOrderNumber = voNumber;
			HttpResponse response = getPartsOrderRequest();
			BRPShowPartOrderResponseWrapper responseObj;
			if(response.getStatusCode() == 200) {
				responseObj = (BRPShowPartOrderResponseWrapper)new XMLSerializer().deSerialize(response.getBody(), BRPShowPartOrderResponseWrapper.class, new Set<String>{'PartsOrder', 'AcknowledgementStatus'});
			}
			if( responseObj != null && responseObj.ShowPartsOrder.ShowPartsOrderDataArea.PartsOrder.size() > 0) {
				string brpStatusText = responseObj.ShowPartsOrder.ShowPartsOrderDataArea.PartsOrder[0].PartsOrderHeader.AcknowledgementStatus[0].StatusText;
				return string.isNotBlank(brpStatusText) && BRPUtility.brpPOStatusTextToBRPStatusMap.containsKey(brpStatusText.toLowerCase())? BRPUtility.brpPOStatusTextToBRPStatusMap.get(brpStatusText.toLowerCase()): brpStatusText;
			} 
		} catch(Exception e) {
			return '';
    	}
		return '';
	}

	public static String getPartOrderLineItems(String voNumber) {
		vendorOrderNumber = voNumber;
		HttpResponse response = getPartsOrderRequest();
		BRPShowPartOrderLinesResponseWrapper responseObj;
		if(response.getStatusCode() == 200) {
			responseObj = (BRPShowPartOrderLinesResponseWrapper)new XMLSerializer().deSerialize(response.getBody(), BRPShowPartOrderLinesResponseWrapper.class, new Set<String>{'PartsOrderLine', 'PartsOrder', 'ItemIdentification', 'AcknowledgementStatus'});
		}
		List<BRPPartOrderLineItemsWrapper> brpPartsOrderLineItemsList = new List<BRPPartOrderLineItemsWrapper>();
		if(responseObj != null) {
			for(BRPShowPartOrderLinesResponseWrapper.PartsOrderLine partOrderLineItemobj : responseObj.ShowPartsOrder.ShowPartsOrderDataArea.PartsOrder[0].PartsOrderLine) {
				if(partOrderLineItemobj != null) {
					brpPartsOrderLineItemsList.add(new BRPPartOrderLineItemsWrapper(partOrderLineItemobj.ItemIdentificationGroup.ItemIdentification[0].ItemID, partOrderLineItemobj.AcknowledgementStatus[0].StatusText, partOrderLineItemobj.AcknowledgementStatus[0].StatusTypeCode));
				}
			}
		}
		return brpPartsOrderLineItemsList.size() > 0 ? System.JSON.serialize(brpPartsOrderLineItemsList) : '';
	}

	public static HttpResponse getPartsOrderRequest() {
		String requestBody = createRequestBody();
		System.debug('requestBody    ::::  ' + requestBody);
		HttpResponse response = BRPUtility.syncToBRP('BRPRetrievePartsOrder', requestBody, 'GET');
		createLog(requestBody, response);
		return response;
	}
	
	private static void createLog(String requestBody, HttpResponse res) {
    	BRPLogService brpLogServiceObj = new BRPLogService();
    	brpLogServiceObj.entityName = 'BRPRetrievePartsOrder';
    	brpLogServiceObj.requestParams = requestBody;
    	brpLogServiceObj.responseCode = String.valueOf(res.getStatusCode());
    	brpLogServiceObj.logType = 'Info';
    	brpLogServiceObj.apexClass = 'BRPRetrievePartsOrderService';
    	brpLogServiceObj.errorMessages = res.getBody();
    	brpLogServiceObj.createLog();
    }
	
	public static String createRequestBody() {
		BRPUtility.release = '5.11.4';
		return createXMLPayload();
	}
	
	private static String createXMLPayload() {
    	DOM.Document doc = new DOM.Document();
    	dom.XmlNode root = BRPUtility.createRequestHeaderNode(doc, methodType);
    	createGetPartsOrderDataAreaNode(root);
        return doc.toXmlString();
    }
    
    private static void createGetPartsOrderDataAreaNode(dom.XmlNode root) {
    	dom.XmlNode getPartsOrderDataArea = BRPUtility.addChildElement(root, 'GetPartsOrderDataArea');
		dom.XmlNode partsOrderNode = BRPUtility.addChildElement(getPartsOrderDataArea, 'PartsOrder');
        createPartsOrderHeaderNode(partsOrderNode);

		dom.XmlNode getNode = BRPUtility.addChildElement(getPartsOrderDataArea, 'Get');
		if(String.isNotBlank(PaginationRecReferenceId)) {
			getNode.setAttribute('recordSetReferenceId', PaginationRecReferenceId);
		}
		if(String.isNotBlank(vendorOrderNumber)) {
			dom.XmlNode expressionNode = getNode.addChildElement('Expression', nameSpace, 'oagis');
			expressionNode.addTextNode(vendorOrderNumber);
			expressionNode.setAttribute('expressionLanguage', 'PurchaseOrderNumber');
		} else {
			dom.XmlNode expressionNode = getNode.addChildElement('Expression', nameSpace, 'oagis');
			expressionNode.addTextNode(filterObj.DateSubmitted.Value1);
			expressionNode.setAttribute('expressionLanguage', 'PartsOrderStartDate');

			dom.XmlNode expressionNode3 = getNode.addChildElement('Expression', nameSpace, 'oagis');
			expressionNode3.addTextNode(filterObj.DateSubmitted.Value2);
			expressionNode3.setAttribute('expressionLanguage', 'PartsOrderEndDate');
	
			if(String.isNotBlank(filterObj.OrderType) && filterObj.OrderType != 'Any') {
				dom.XmlNode expressionNode4 = getNode.addChildElement('Expression', nameSpace, 'oagis');
				expressionNode4.addTextNode(filterObj.OrderType);
				expressionNode4.setAttribute('expressionLanguage', 'OrderType');
			}

			filterObj.OrderStatus = String.isNotBlank(filterObj.OrderStatus) ? filterObj.OrderStatus : '0';
			dom.XmlNode expressionNode2 = getNode.addChildElement('Expression', nameSpace, 'oagis');
			expressionNode2.addTextNode(filterObj.OrderStatus);
			expressionNode2.setAttribute('expressionLanguage', 'Status');
		}
    }
    
    private static void createPartsOrderHeaderNode(dom.XmlNode partsOrderNode) {
    	dom.XmlNode partsOrderHeaderNode = BRPUtility.addChildElement(partsOrderNode, 'PartsOrderHeader');
    	dom.XmlNode documentIdentificationGroupNode = BRPUtility.addChildElement(partsOrderHeaderNode, 'DocumentIdentificationGroup');
        dom.XmlNode documentIdentificationNode = BRPUtility.addChildElement(documentIdentificationGroupNode, 'DocumentIdentification');

        BRPUtility.addChildElementWithValue(documentIdentificationNode, 'DocumentID', MethodType);
        BRPUtility.addChildElementWithValue(documentIdentificationNode, 'AgencyRoleCode', 'Dealer');
    }

	private static void setDateFilterFields(BRPPOFilterWrapper filterObj) {
    	if(filterObj.DateSubmitted.SelectedOption == '0') {
			filterObj.DateSubmitted.Value1 = ((system.now()).addYears(-1)).formatGMT('yyyy-MM-dd');
			filterObj.DateSubmitted.Value2 = system.now().formatGMT('yyyy-MM-dd');
		} else if(filterObj.DateSubmitted.SelectedOption == '1') {
			filterObj.DateSubmitted.Value1 = system.now().formatGMT('yyyy-MM-dd');
			filterObj.DateSubmitted.Value2 = system.now().formatGMT('yyyy-MM-dd');
		} else if(filterObj.DateSubmitted.SelectedOption == '2') {
			filterObj.DateSubmitted.Value1 = ((system.now()).addDays(-1)).formatGMT('yyyy-MM-dd');
			filterObj.DateSubmitted.Value2 = ((system.now()).addDays(-1)).formatGMT('yyyy-MM-dd');
		} else if(filterObj.DateSubmitted.SelectedOption == '3') {
			filterObj.DateSubmitted.Value1 = ((system.now()).addDays(-7)).formatGMT('yyyy-MM-dd');
			filterObj.DateSubmitted.Value2 = system.now().formatGMT('yyyy-MM-dd');
		} else if(filterObj.DateSubmitted.SelectedOption == '4') {
			filterObj.DateSubmitted.Value1 = ((system.now()).addDays(-30)).formatGMT('yyyy-MM-dd');
			filterObj.DateSubmitted.Value2 = system.now().formatGMT('yyyy-MM-dd');
		} else if(filterObj.DateSubmitted.SelectedOption == '5') {
			filterObj.DateSubmitted.Value1 = getFormattedDate(filterObj.DateSubmitted.Value1);
			filterObj.DateSubmitted.Value2 = getFormattedDate(filterObj.DateSubmitted.Value2);
		}
    }
    
	private static string getFormattedDate(String dateStr) {
		List<String> dateStringList = dateStr.split('/');
    	String userLocale = UserInfo.getLocale();
		String formatOfDate;
    	if(!Constants.localeToDateTimeFmtMap.containsKey(userLocale)){
    		formatOfDate = Constants.localeToDateTimeFmtMap.get('en_US');
    	} else {
			formatOfDate = Constants.localeToDateTimeFmtMap.get(userLocale);
		}
		if(formatOfDate == 'MM/dd/yyyy') {
			return (DateTime.newInstanceGMT(Integer.valueOf(dateStringList[2]), Integer.valueOf(dateStringList[0]), Integer.valueOf(dateStringList[1]))).formatGMT('yyyy-MM-dd');
		} else {
			return (DateTime.newInstanceGMT(Integer.valueOf(dateStringList[2]), Integer.valueOf(dateStringList[1]), Integer.valueOf(dateStringList[0]))).formatGMT('yyyy-MM-dd');
		}
    }

	private static string getFormattedDateBasedOnUserLocale(String dateStr) {
		List<String> dateStringList = dateStr.split('-');
    	String userLocale = UserInfo.getLocale();
		String formatOfDate;
    	if(!Constants.localeToDateTimeFmtMap.containsKey(userLocale)){
    		formatOfDate = Constants.localeToDateTimeFmtMap.get('en_US');
    	} else {
			formatOfDate = Constants.localeToDateTimeFmtMap.get(userLocale);
		}
		return (DateTime.newInstanceGMT(Integer.valueOf(dateStringList[0]), Integer.valueOf(dateStringList[1]), Integer.valueOf(dateStringList[2]))).formatGMT(formatOfDate);
    }

	private static String getRecordSetReferenceId(HttpResponse res) {
    	XmlStreamReader reader = res.getXmlStreamReader();
    	while(reader.hasNext()) {
		    if (reader.getEventType() == XmlTag.START_ELEMENT && 
		       reader.getLocalName() == 'Expression') {
		        return reader.getAttributeValue('', 'recordSetReferenceId');
		    }
		    reader.next();
		}
    	return '';
    }

	public class BRPPOFilterWrapper {
		public String OrderType;
		public String OrderStatus;
		public HomeSearchFilterWrapper.BetweenFilter DateSubmitted;

		public BRPPOFilterWrapper() {
			this.OrderType = 'STK';
			this.OrderStatus = '0';
			this.DateSubmitted = new HomeSearchFilterWrapper.BetweenFilter();
		}

		public BRPPOFilterWrapper(String orderType, String orderStatus, HomeSearchFilterWrapper.BetweenFilter dateSubmitted) {
			this.OrderType = orderType;
			this.OrderStatus = orderStatus;
			this.DateSubmitted = dateSubmitted;
		}
	}

	public class BRPPartOrderWrapper {
		public String PaginationReferenceId;
		public List<BRPPartOrderHeaderWrapper> PartsOrderList;

		public BRPPartOrderWrapper(){}

		public BRPPartOrderWrapper(String paginationReferenceId, List<BRPPartOrderHeaderWrapper> partsOrderList) {
			this.PaginationReferenceId = paginationReferenceId;
			this.PartsOrderList = partsOrderList;
		}
	}
	public class BRPPartOrderHeaderWrapper {
		public String OrderNumber;
		public String OrderedDate;
		public String BRPStatus;
		public String BRPStatusCode;

		public BRPPartOrderHeaderWrapper(){}
		
		public BRPPartOrderHeaderWrapper(String orderNumber, String orderedDate, String brpStatus, String brpStatusCode) {
			this.OrderNumber = orderNumber;
			this.OrderedDate = String.IsNotBlank(orderedDate) ? getFormattedDateBasedOnUserLocale(orderedDate) : orderedDate;
			this.BRPStatus = brpStatus;
			this.BRPStatusCode = brpStatusCode;
		}
	}

	public class BRPPartOrderLineItemsWrapper {
		public String PartNumber;
		public String BRPStatus;
		public String BRPStatusCode;

		public BRPPartOrderLineItemsWrapper(String partNumber, String brpStatus, String brpStatusCode) {
			this.PartNumber = partNumber;
			this.BRPStatus = brpStatus;
			this.BRPStatusCode = brpStatusCode;
		}
	}
}