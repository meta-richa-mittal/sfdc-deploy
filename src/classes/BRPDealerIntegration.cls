global without sharing class BRPDealerIntegration {

    public static String DealerId = BRPUtility.getDealerId();
    
    public static String getDealersList() {
        if(AccessControl.ifObjectIsAccessible('BRP_Dealers__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); } 
        List<BRP_Dealers__c> dealerList = [SELECT City__c, Company_Name__c, Country__c, Email__c, Fax__c, Line_Two__c, Party_ID__c, Person_Name__c,
                                                Postcode__c, State__c, Street__c, Telephone__c, Type_Code__c, Website__c,
                                                (SELECT Name FROM BRP_Dealer_Product_Lines__r)
                                                FROM BRP_Dealers__c WHERE Company_Name__c != null];
        
        List<BRPDealerWrapper> brpDealerWrapperObjList = new List<BRPDealerWrapper>();
        for(BRP_Dealers__c brpDealerRec : dealerList) {
        	brpDealerWrapperObjList.add(new BRPDealerWrapper(brpDealerRec));
        }
        return System.JSON.serialize(brpDealerWrapperObjList);
    }

    global static void getDealerLocator() {
        getDealers(1);
    }
    
    public static Integer getDealers(Integer pageNumber) {
        if(AccessControl.ifObjectIsCreateable('BRP_Dealers__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_CREATEABLE); } 
        List<CustomHttpHeaderWrapper> headerList = getHeaderList();
        String body = getDealerLocatorString(pageNumber);
        
        Id IFW_ItemId = BRPUtility.getIFWConfigItemByEntityName('GetDealer', 'POST', 'BRP');
        IFW_IntegrationConfigItem__c child = BaseIntegration.getChild(IFW_ItemId);
        IFW_IntegrationConfig__c parent = BaseIntegration.getParent(child.IFW_IntegrationConfig__c);
        
        HttpResponse response = new HttpResponse();
        try {
            response = BaseIntegration.performCallout(parent, child, body, headerList, new Map<String, String>(), null);
        } catch (System.Exception c) {
            System.debug('Callout error: '+ c);
        }
        return parseXML(response.getXmlStreamReader(), DealerId);
    }
    
    private static List<CustomHttpHeaderWrapper> getHeaderList() {
        List<CustomHttpHeaderWrapper> headerList = new List<CustomHttpHeaderWrapper>();
        headerList.add(BRPUtility.buildCustomHttpHeader('Content-Type', BRPUtility.contentType));
        headerList.add(BRPUtility.buildCustomHttpHeader('Accept-Language', 'en-US'));
        headerList.add(BRPUtility.buildCustomHttpHeader('Connection', 'Keep-Alive'));
        headerList.add(BRPUtility.buildCustomHttpHeader('Accept-Charset', 'UTF-8'));
        headerList.add(BRPUtility.buildCustomHttpHeader('Accept', BRPUtility.contentType));
        headerList.add(BRPUtility.buildCustomHttpHeader('Accept-Encoding', 'gzip, deflate'));
        headerList.add(BRPUtility.buildCustomHttpHeader('User-Agent', 'Apache-HttpClient/4.1.1 (java 1.5)'));
        return headerList;
    }


    public static String getDealerLocatorString(Integer pageNumber) {
        DOM.Document body = new DOM.Document();
        String prefix = 'star';
        String oagis = 'http://www.openapplications.org/oagis/9';
        String nameSpace = 'http://www.starstandard.org/STAR/5';
        String schemaLocation = 'http://www.starstandard.org/STAR/5 /STAR/Rev5.9.3/BODs/Standalone/GetDealerLocator.xsd " "';
        String release = '5.12.4';
        String languageCode = 'en-US';
        string createorNameCodeString = 'Blackpurl';
        string senderNameCodeString = 'BP';
        String destinationNameCodeString = 'BD';
        string agencyRoleCodeString = 'Operator';

        DOM.XmlNode root = body.createRootElement('GetDealerLocator', nameSpace, prefix);
        root.setAttribute('releaseID', release);
        root.setAttribute('languageCode', languageCode);
        root.setNamespace('oagis',oagis);
        root.setNamespace('star',nameSpace);

        dom.XmlNode applicationArea = root.addChildElement('ApplicationArea', nameSpace, prefix);
        dom.XmlNode sender = applicationArea.addChildElement('Sender', nameSpace, prefix);
        dom.XmlNode authorizationId = sender.addChildElement('AuthorizationID', nameSpace, prefix).addTextNode('ABC123');
        dom.XmlNode creationDateTime = applicationArea.addChildElement('CreationDateTime', nameSpace, prefix).addTextNode(BRPUtility.creationDateTimeString());
        dom.XmlNode creatorNameCode = sender.addChildElement('CreatorNameCode', nameSpace, prefix).addTextNode(createorNameCodeString);
        dom.XmlNode senderNameCode = sender.addChildElement('SenderNameCode', nameSpace, prefix).addTextNode(senderNameCodeString);
        dom.XmlNode dealerNumberID = sender.addChildElement('DealerNumberID', nameSpace, prefix).addTextNode(DealerId);
        dom.XmlNode serviceId = sender.addChildElement('ServiceID', nameSpace, prefix).addTextNode('GetDealerLocator');

        dom.XmlNode BODID = applicationArea.addChildElement('BODID', nameSpace, prefix).addTextNode(BRPUtility.generateBodId());
        dom.XmlNode destination = applicationArea.addChildElement('Destination', nameSpace, prefix);
        dom.XmlNode destinationNameCode = destination.addChildElement('DestinationNameCode', nameSpace, prefix).addTextNode(destinationNameCodeString);

        dom.XmlNode getDealerLocatorDataArea = root.addChildElement('GetDealerLocatorDataArea', nameSpace, prefix);
        dom.XmlNode get = getDealerLocatorDataArea.addChildElement('Get', nameSpace, prefix);
        get.setAttribute('recordSetReferenceId', String.valueOf(pageNumber));
        
        dom.XmlNode oagisElement = get.addChildElement('oagis:Expression', null, null);
        dom.XmlNode dealerLocator = getDealerLocatorDataArea.addChildElement('DealerLocator', nameSpace, prefix);
        dom.XmlNode dealerLocatorHeader = dealerLocator.addChildElement('DealerLocatorHeader', nameSpace, prefix);
        dom.XmlNode documentIdentificationGroup = dealerLocatorHeader.addChildElement('DocumentIdentificationGroup', nameSpace, prefix);
        dom.XmlNode documentIdentification = documentIdentificationGroup.addChildElement('DocumentIdentification', nameSpace, prefix);
        dom.XmlNode documentID = documentIdentification.addChildElement('DocumentID', nameSpace, prefix).addTextNode('GetDealerLocator');
        dom.XmlNode agencyRoleCode = documentIdentification.addChildElement('AgencyRoleCode', nameSpace, prefix).addTextNode(agencyRoleCodeString);
        return body.toXmlString();
    }

    public static Integer parseXML(XmlStreamReader reader, String dealerId) {
        if(!AccessControl.ifObjectFieldIsCreateable('BRP_Dealers__c')){throw new BlackPurlException('BRP_Dealers__c' + DMLUtility.NOT_CREATABLE);}
        if(!AccessControl.ifObjectFieldIsUpdateable('BRP_Dealers__c')) { throw new BlackPurlException('BRP_Dealers__c' + DMLUtility.NOT_UPDATABLE); }
        if(!AccessControl.ifObjectFieldIsCreateable('BRP_Dealer_Product_Line__c')){throw new BlackPurlException('BRP_Dealer_Product_Line__c' + DMLUtility.NOT_CREATABLE);}
        if(!AccessControl.ifObjectFieldIsUpdateable('BRP_Dealer_Product_Line__c')) { throw new BlackPurlException('BRP_Dealer_Product_Line__c' + DMLUtility.NOT_UPDATABLE); }
        
        //extract xml
        Integer totalNumberOfDealers = 0;
        String ChannelType;
        String StoredURI;
        boolean isSafeToGetNextXmlElement = true;
        List<BRP_Dealers__c> dealers = new List<BRP_Dealers__c>();
        BRP_Dealers__c d  = new BRP_Dealers__c();
        List<BRP_Dealer_Product_Line__c> productLines = new List<BRP_Dealer_Product_Line__c>();
        BRP_Dealer_Product_Line__c p = new BRP_Dealer_Product_Line__c();
        
        while(isSafeToGetNextXmlElement) {
            // Start at the beginning of the dealer and make sure that it is a dealer
            if (reader.getEventType() == XmlTag.END_ELEMENT && reader.getLocalName() == 'DealerLocatorDetail') {
              dealers.add(d);
              d = new BRP_Dealers__c();
            }
            
            if(reader.getEventType() == XmlTag.START_ELEMENT && reader.getLocalName() == 'NumberOfDealersToBeReturnedNumeric' && totalNumberOfDealers == 0) {
                String totalDealers = parseValues(reader);
                if(String.isNotBlank(totalDealers)) {
                    totalNumberOfDealers = Integer.valueOf(totalDealers);
                }
            }

            if (reader.getEventType() == XmlTag.START_ELEMENT) {
              switch on reader.getLocalName() {
                  when 'PartyID' { d.Party_Id__c=parseValues(reader); }
                  when 'PersonName' { d.Person_Name__c =parseValues(reader); }
                  when 'CompanyName' { d.Company_Name__c =parseValues(reader); }
                  when 'TypeCode' { d.Type_Code__c = parseValues(reader); }
                  when 'LineOne' { d.Street__c = parseValues(reader); }
                  when 'LineTwo' { d.Line_two__c = parseValues(reader); }
                  when 'CityName' { d.City__c = parseValues(reader); }
                  when 'StateOrProvinceCountrySub-DivisionID' { d.state__c = parseValues(reader); }
                  when 'Postcode' { d.Postcode__c = parseValues(reader); }
                  when 'CountryID' { d.country__c = getCountryFromCode(parseValues(reader)); }
                  when 'ChannelCode' { 
                    ChannelType = parseValues(reader); 
                    if (ChannelType == 'email') d.email__c = StoredURI;
                    else if (ChannelType == 'website') d.website__c = StoredURI;
                  }
                  when 'LocalNumber' { 
                      if (ChannelType == 'telephone') d.telephone__c = parseValues(reader);
                      else if (ChannelType == 'fax') d.fax__c = parseValues(reader);
                  }      
                  when 'AreaNumberCode' {
                      if (ChannelType == 'telephone') d.telephone__c = '('+parseValues(reader)+')' + ' ' + d.telephone__c;
                      else if (ChannelType == 'fax') d.fax__c = '('+parseValues(reader)+')' + ' ' + d.fax__c;
                  }
                  when 'URIID' { 
                    StoredURI = parseValues(reader);
                  }
                  when 'ProductsCarried' {
                    p = new BRP_Dealer_Product_Line__c();
                    p.Party_Id__c = d.Party_Id__c;
                    p.name = parseValues(reader);
                    p.Unique_Id__c = p.Party_Id__c+'-'+p.name;
                    productLines.add(p);
                    system.debug(parseValues(reader));
                  }
                  when 'AddressType' { d.Address_Type__c = parseValues(reader); }
                  when 'CareOf' { d.Care_Of__c = parseValues(reader); }
                  when 'AddressID' { d.Address_ID__c = parseValues(reader); }
                  when 'ErrorProcessMessage' { parseDealerErrors(reader, dealerId);}
              }
          }
            // Always use hasNext() before calling next() to confirm
            // that we have not reached the end of the stream
            if (reader.hasNext()) {
                reader.next();
            } else {
                isSafeToGetNextXmlElement = false;
                break;
            }
        }
        
        if(dealers.size() > 0) {
            if(!AccessControl.ifObjectFieldIsCreateable(new BRP_Dealers__c())){throw new BlackPurlException('BRP_Dealers__c' + DMLUtility.NOT_CREATABLE);}
            if(!AccessControl.ifObjectFieldIsUpdateable(new BRP_Dealers__c())) { throw new BlackPurlException('BRP_Dealers__c' + DMLUtility.NOT_UPDATABLE); }
            Database.upsert(dealers, BRP_Dealers__c.Party_Id__c, false);
        }

        Map<String, String> dealerPartyIdToSFIdMap = new Map<String, String>();
        for(BRP_Dealers__c dealer : dealers) {
            dealerPartyIdToSFIdMap.put(dealer.Party_Id__c, dealer.Id);
        }
        
        List<BRP_Dealer_Product_Line__c> productLineListToUpsert = new List<BRP_Dealer_Product_Line__c>();
        for(BRP_Dealer_Product_Line__c productLine : productLines) {
            if(dealerPartyIdToSFIdMap.containsKey(productLine.Party_Id__c)) {
                productLine.BRP_Dealer__c = dealerPartyIdToSFIdMap.get(productLine.Party_Id__c);
                productLineListToUpsert.add(productLine);
            }
        }
        if(productLineListToUpsert.size() > 0) {
            if(!AccessControl.ifObjectFieldIsCreateable(new BRP_Dealer_Product_Line__c())){throw new BlackPurlException('BRP_Dealer_Product_Line__c' + DMLUtility.NOT_CREATABLE);}
            if(!AccessControl.ifObjectFieldIsUpdateable(new BRP_Dealer_Product_Line__c())) { throw new BlackPurlException('BRP_Dealer_Product_Line__c' + DMLUtility.NOT_UPDATABLE); }
            Database.upsert(productLineListToUpsert, BRP_Dealer_Product_Line__c.Unique_Id__c, false);
        }
        return totalNumberOfDealers;
    }

    public static string  getCountryFromCode(String CountryCode) {
        switch on countryCode {
            when 'US' { return 'USA'; } 
            when 'CA' { return 'Canada'; }
            when else { return CountryCode; }
        }
    }

    public static string  getProductLineFromCode(String productLineCode) {
        switch on productLineCode {
            when '2WV' { return 'Two-wheel vehicles'; } 
            when '3WV' { return 'Three-wheel vehicles'; }
            when 'ATV' { return 'All-terrain vehicles'; } 
            when 'BT' { return 'Boat'; }
            when 'OE' { return 'Outboard Engines'; } 
            when 'PTN' { return 'Pontoon boats'; }
            when 'PWC' { return 'Personal Watercrafts'; } 
            when 'SNO' { return 'Snowmobiles'; }
            when 'SSV' { return 'Side-by-Side vehicles'; }
            when else { return productLineCode; }
        }
    }

    public static String parseValues(XmlStreamReader xls) {
        while (xls.getEventType() != XmlTag.CHARACTERS) {
            xls.next();
        }
        return xls.getText();
    }

    /*public static String HandleErrors(HttpResponse response) {
        String returnStr = '';
        if(response.getStatusCode() == 401){
            //IntegrationLog.createLog('BRPIntegration', 'getDealerLocator()', 'Unauthorized', String.valueOf(response.getStatusCode()), null, 'dealerId');
            returnStr = response.getStatusCode() + ' Unauthorized - ' + response.getBody();
        } else if(response.getStatusCode() == 400){
            //IntegrationLog.createLog('BRPIntegration', 'getDealerLocator()', 'Client Fault (Bad Request)', String.valueOf(response.getStatusCode()), null, 'dealerId');
            returnStr = response.getStatusCode() + ' Client Fault (Bad Request)'+response.getBody();
        } else if(response.getStatusCode() == 500){
            //IntegrationLog.createLog('BRPIntegration', 'getDealerLocator()', 'Server Fault', String.valueOf(response.getStatusCode()), null, 'dealerId');
            returnStr = response.getStatusCode() + ' Server Fault';
        } else {
            //IntegrationLog.createLog('BRPIntegration', 'getDealerLocator()', 'Response indicating an unknown fault', String.valueOf(response.getStatusCode()), null, 'dealerId');
            returnStr = response.getStatusCode() + ' Response indicating a unknown fault - ' + response.getBody();
        }
        return returnStr;
    }*/

    // Parse errors in Vehicle Spec Requests
    public static void parseDealerErrors(XmlStreamReader reader, String dealerCode) {
        Boolean isSafeToGetNextXmlElement = true;
        String title = '', type = '', descr = '';
        
        while(isSafeToGetNextXmlElement) {
            switch on reader.getLocalName() {
                when 'title' {
                    title = parseValues(reader);
                }
                when 'Type' {
                    type = parseValues(reader);
                }
                when 'Description' {
                    descr = parseValues(reader);
                }
            }
            
            if(reader.hasNext()) {
                reader.next();
            } else {
                isSafeToGetNextXmlElement = false;
                break;
            }
        }
    }

    // Get Dealers Details using V4 version API
    public static String getDealer(String dealerNo) {
        String responseStr;
        if(String.isNotBlank(dealerNo)) {
            if( dealerNo.length() < 10) {
                dealerNo = dealerNo.leftPad(10, '0');
            }
            Map<String, String> endPointPathParamMap = new Map<String, String> {'{{dealer_no}}' => dealerNo};
            HttpResponse response = BRPUtility.syncToBRP(BRPUtility.GET_DEALER, null, 'GET', new Map<String, String>(), endPointPathParamMap);
            if(response.getStatusCode() == 200) {
                responseStr = System.JSON.serialize(new BRPDealerWrapper((DealerWrapper) System.JSON.deserialize(response.getBody(), DealerWrapper.class)));
            } else {
                responseStr = system.JSON.serialize(new ResponseWrapper(400, handleErrorResponseV4(response)));
            } 
        } else {
            responseStr = system.JSON.serialize(new ResponseWrapper(400, 'Dealer number can\'t be blank.'));
        }
        return responseStr;
    }

    public static String handleErrorResponseV4(HttpResponse response) {
        Boolean isBRPLogNeeded = true;
        if(response.getStatusCode() == 404 && response.getBody().containsIgnoreCase('Dealer') && response.getBody().containsIgnoreCase('not found')) {
            isBRPLogNeeded = false;
        }
        if(isBRPLogNeeded) {BRPUtility.insertBRPLog(BRPUtility.GET_DEALER, null, response, 'BRPDealerIntegration');}
        return getErrorMessage(response);
    }

    public static String getErrorMessage(HttpResponse response) {
        String errorMessage = '';
        if(response.getStatusCode() == 400 || response.getStatusCode() == 401 || response.getStatusCode() == 404) {
            BRPErrorWrapper errorObj = (BRPErrorWrapper) System.JSON.deserialize(response.getBody(), BRPErrorWrapper.class);
            errorMessage = errorObj.meta.detail;
        } else {
            errorMessage = response.getBody();
        }
        return errorMessage;
    }

    public class DealerWrapper {
		public String dealer_no;
		public String dealer_name;
		public String legal_name;
		public List<String> product_lines;
		public DealerAddressWrapper address;
	}

	public class DealerAddressWrapper {
		public String street;
		public String city;
		public String state;
		public String country;
		public String postal_code;
	}
}