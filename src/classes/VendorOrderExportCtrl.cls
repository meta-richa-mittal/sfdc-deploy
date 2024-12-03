global without sharing class VendorOrderExportCtrl {
	public String fileContent {get; private set;}
	public String contentType {get; private set;}
	private final String GENERIC = 'Generic (.csv)';
	private final String PARTS_CANADA = 'Parts Canada (.csv)';
	private final String HDNET_AUSTRALIA = 'HDnet Australia';
	private final String BOSSWEB = 'BossWeb';
	private final String KTM = 'KTM';
    private String voNumber;
	private String vendorName;
	private final String HONDA_EBIZ = 'Honda eBiz';
	public final String YAMAHA_AUSTRALIA = 'Yamaha Australia';
	private final String MONZA_AUSTRALIA = 'Monza/Fox Australia';
	private final String YAMAHA_CANADA = 'Yamaha Canada';
	private final String AMERICAN_HONDA = 'American Honda';
	private final String TURN_14 = 'Turn 14 (TRDOS)';
	private String hondaDealerNumber;
	private String hondaEbizOrderType;
	private String voHeaderId;
	private String exportType;
	private String freightCarrier;
	
    public VendorOrderExportCtrl() {
		String paramStr = BPUtility.getDecodedString(ApexPages.currentPage().getParameters().get('params'));
		if(String.isBlank(paramStr)) return;
		VOExportParams paramsObj = (VOExportParams)System.JSON.deserialize(paramStr, VOExportParams.class);
		voHeaderId = paramsObj.VOHeaderId;
    	exportType = paramsObj.ExportType;
    	hondaDealerNumber = paramsObj.HondaDealerNumber;
		hondaEbizOrderType = paramsObj.OrderType;
		freightCarrier = paramsObj.FreightCarrier;

		if(exportTypeToContentTypeMap.containsKey(exportType)) {
			exportFileWithPredefinedFormats();
		} else {
			exportFile(paramsObj.ExportFormatId);
		}
    }

    private Map<String, String> exportTypeToContentTypeMap = new Map<String, String>{
    																					GENERIC => 'text/csv#Vendor Order.csv',
    																					PARTS_CANADA => 'text/csv#Vendor Order.csv',
																						HDNET_AUSTRALIA => null,
																						BOSSWEB => 'text/plain/#Vendor Order.txt;charset=UTF-8',
																						KTM => 'text/plain/#Vendor Order.txt',
																						HONDA_EBIZ => 'text/plain/#HNVENDOR.DAT',
																						YAMAHA_CANADA => 'text/plain/#YDC.txt',
																						MONZA_AUSTRALIA => null,
																						YAMAHA_AUSTRALIA => null,
																						AMERICAN_HONDA => 'text/plain/#PORD.txt',
																						TURN_14 => null
    																				};

    private void exportFileWithPredefinedFormats() {
		if(AccessControl.ifObjectFieldIsAccessible('Vendor_Order_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
    	if(AccessControl.ifObjectFieldIsAccessible('Vendor_Order_Line_Item_Group__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }

    	List<Vendor_Order_Header__c> voHeaderlist = [SELECT Name, Vendor__r.Name, Vendor__r.AccountNumber, Vendor__r.Status__c, Ordered_Date__c, Notes__c, Purchase_Order_Type__r.Code__c, Expected_Date_Formula__c, CreatedDate, (SELECT Part__r.Part_Number__c, Part__r.Description__c,
    		Need__c, Part__r.Package_Unit__c, Part__r.Packaged_Part__c, Part__r.Package_Qty__c, Part__r.Location__c, Cost__c, Per_Unit_Cost__c, Is_Order_As_Individual_Item__c, 
    		Part__r.Assigned_Location_1__c FROM Vendor_Order_Line_Item_Groups__r where Part__c != null Order By Part__r.Part_Number__c), Status__c
    		FROM Vendor_Order_Header__c WHERE Id =: voHeaderId ORDER BY LastModifiedDate Desc];
		
		system.debug('Export Type: '+exportType);

    	fileContent = '';
    	if(voHeaderlist.size() > 0) {
			voNumber = voHeaderlist[0].Name;
			vendorName = voHeaderlist[0].Vendor__r.Name;

    		if(exportType == GENERIC) {
	    		generateGenericExportFile(voHeaderlist[0].Vendor_Order_Line_Item_Groups__r);
	    	} else if(exportType == PARTS_CANADA) {
	    		generatePartsCanadaExportFile(voHeaderlist[0].Vendor_Order_Line_Item_Groups__r);
	    	} else if(exportType == HDNET_AUSTRALIA) {
	    		generateHDnetAustraliaExportFile(voHeaderlist[0]);
		    } else if(exportType == BOSSWEB) {
	    		generateBosswebExportFile(voHeaderlist[0].Vendor_Order_Line_Item_Groups__r, voHeaderList);
	    	}  else if(exportType == KTM) {
	    	    generateKTMExportFile(voHeaderlist[0].Vendor_Order_Line_Item_Groups__r);
	    	} else if(exportType == HONDA_EBIZ) {
	    		generateHondaEBizExportFile(voHeaderlist[0].Vendor_Order_Line_Item_Groups__r, voHeaderList[0]);
	    	} else if(exportType == MONZA_AUSTRALIA) {
				generateMonzaAustraliaExportFile(voHeaderlist[0].Vendor_Order_Line_Item_Groups__r);
	    	} else if(exportType == YAMAHA_AUSTRALIA) {
				generateYamahaAustraliaExportFile(voHeaderlist[0].Vendor_Order_Line_Item_Groups__r, voHeaderList[0]);
	    	} else if(exportType == YAMAHA_CANADA) {
				generateYamahaCanadaExportFile(voHeaderlist[0].Vendor_Order_Line_Item_Groups__r, voHeaderList[0]);
	    	} else if(exportType == AMERICAN_HONDA) {
				generateAmericanHondaExportFile(voHeaderlist[0].Vendor_Order_Line_Item_Groups__r, voHeaderList[0]);
	    	} else if(exportType == TURN_14) {
				generateTurn14ExportFile(voHeaderlist[0].Vendor_Order_Line_Item_Groups__r, voHeaderList[0]);
	    	}
		}
		contentType = exportTypeToContentTypeMap.get(exportType);
	}

	private void exportFile(String exportFormatId) {
		if(String.isBlank(exportFormatId)) throw new BlackPurlException('Invalid VO export format Id');
		GE_File_Config__c fileConfigRec = GenericExportService.getExportRecById(exportFormatId);
		if(fileConfigRec == null) throw new BlackPurlException('Invalid VO export format Id');
		if(voHeaderId == null) throw new BlackPurlException('Invalid VO header Id');
		fileConfigRec.Where_Clause__c = 'Vendor_Order_Header__c = \'' + voHeaderId + '\'';
		String query = GenericExportUtil.createQueryForDataToExport(fileConfigRec, null, null);
		fileContent = GenericExportService.getHeaders(fileConfigRec);
		fileContent = String.isNotBlank(fileContent) ? (fileContent + GenericExportUtil.newLineSeparator) : '';
		fileContent += GenericExportService.createFileData(fileConfigRec, 
										SOQLUtility.getQueryResults(fileConfigRec.Object_API_Name__c, query), null, null, new GenericExportBatch(''));
		contentType = (GenericExportUtil.fileTypeToContentTypeMap.containsKey(fileConfigRec.File_Content_Type__c) ? 
						GenericExportUtil.fileTypeToContentTypeMap.get(fileConfigRec.File_Content_Type__c) : 'text/plain');
		contentType += '#Vendor Order.'; 
		contentType += fileConfigRec.File_Content_Type__c == null ? 'txt' : fileConfigRec.File_Content_Type__c;
		system.debug('contentType: ' + contentType);
	}

    private void generateGenericExportFile(List<Vendor_Order_Line_Item_Group__c> voliGroupList) {
    	fileContent += 'Part#,Description,Qty Ordered,Unit Measure,Cost\n';
    	for(Vendor_Order_Line_Item_Group__c voliGroupRec : voliGroupList) {
    		Decimal qtyOrdered = calculatePackagedQty(voliGroupRec.Need__c, voliGroupRec.Part__r, voliGroupRec.Is_Order_As_Individual_Item__c);
			Decimal cost = (voliGroupRec.Cost__c != null) ? voliGroupRec.Cost__c.setScale(2, RoundingMode.HALF_UP) : 0;
			if(voliGroupRec.Part__r.Packaged_Part__c && !voliGroupRec.Is_Order_As_Individual_Item__c) {
				if(voliGroupRec.Part__r.Package_Qty__c == null) {
					voliGroupRec.Part__r.Package_Qty__c = 1;
				}
				cost = (cost * voliGroupRec.Part__r.Package_Qty__c).setScale(2, RoundingMode.HALF_UP);
			}
			if(voliGroupRec.Per_Unit_Cost__c != null) {
				cost = voliGroupRec.Per_Unit_Cost__c.setScale(2, RoundingMode.HALF_UP);
			}
    		fileContent += ((voliGroupRec.Part__r.Part_Number__c != null) ? voliGroupRec.Part__r.Part_Number__c.escapeCsv() : '') + ',';
    		fileContent += ((voliGroupRec.Part__r.Description__c != null) ? voliGroupRec.Part__r.Description__c.escapeCsv() : '') + ',';
    		fileContent += String.valueOf(qtyOrdered) + ',';
    		if(voliGroupRec.Is_Order_As_Individual_Item__c) {
    			fileContent += 'EA' + ',';
    		} else if(String.isNotBlank(voliGroupRec.Part__r.Package_Unit__c)) {
    			fileContent += voliGroupRec.Part__r.Package_Unit__c + ',';
    		} else if(voliGroupRec.Part__r.Packaged_Part__c) {
    			fileContent += 'PKG' + ',';
    		} else {
    			fileContent += 'EA' + ',';
    		}
    		fileContent += String.valueOf(cost) + '\n';
    	}
    }

	private void generatePartsCanadaExportFile(List<Vendor_Order_Line_Item_Group__c> voliGroupList) {
    	fileContent += 'Part#,Qty Ordered\n';
    	for(Vendor_Order_Line_Item_Group__c voliGroupRec : voliGroupList) {
	    	Decimal qtyOrdered = calculatePackagedQty(voliGroupRec.Need__c, voliGroupRec.Part__r, voliGroupRec.Is_Order_As_Individual_Item__c);
			fileContent += ((voliGroupRec.Part__r.Part_Number__c != null) ? voliGroupRec.Part__r.Part_Number__c.escapeCsv() : '') + ',';
			fileContent += String.valueOf(qtyOrdered) + '\n';
    	}
    }
	
	private void generateKTMExportFile(List<Vendor_Order_Line_Item_Group__c> voliGroupList) {
        for(Vendor_Order_Line_Item_Group__c voliGroupRec : voliGroupList) {
            Decimal qtyOrdered = calculatePackagedQty(voliGroupRec.Need__c, voliGroupRec.Part__r, voliGroupRec.Is_Order_As_Individual_Item__c);
            fileContent += ((voliGroupRec.Part__r.Part_Number__c != null) ? voliGroupRec.Part__r.Part_Number__c.escapeCsv() : '') + ';';
            fileContent += String.valueOf(qtyOrdered) + '\n';
        }
        exportTypeToContentTypeMap.put(KTM, 'text/plain/#' + voNumber + '.txt');
    }

	private void generateBosswebExportFile(List<Vendor_Order_Line_Item_Group__c> voliGroupList, List<Vendor_Order_Header__c> voHeaderlist) {
		Vendor_Order_Header__c voHeader = voHeaderlist[0];
		system.debug('voHeader: '+voHeader.name);
		contentType= 'text/plain/#'+voHeader.name+'.txt';
		String tabStr = '\t';
		String lfStr = '\n';

		//fileContent += 'Required Quantity'+tabStr+'Part No'+lfStr;
		fileContent = '';

    	for(Vendor_Order_Line_Item_Group__c voliGroupRec : voliGroupList) {
	    	Integer qtyOrdered = Integer.valueOf(calculatePackagedQty(voliGroupRec.Need__c, voliGroupRec.Part__r, voliGroupRec.Is_Order_As_Individual_Item__c));
			fileContent += String.valueOf(qtyOrdered) + tabStr;
			fileContent += voliGroupRec.Part__r.Part_Number__c +lfStr;
    	}
		fileContent = BPUtility.getDecodedString(BPUtility.getEncodedString(fileContent.trim()));  // Removed leading, trailing, and repeating white space and new line characters.
    }
        
    private void generateAmericanHondaExportFile(List<Vendor_Order_Line_Item_Group__c> voliGroupList, Vendor_Order_Header__c voHeader) {
		fileContent = '';
		fileContent += createInterfaceHeaderRec();
		fileContent += createTransactionHeaderRec(voHeader.Name);
		fileContent += createOrderTransactionDetailsRec(voliGroupList);
		fileContent += createTransactionIntefaceTrailerRec();
    }

    private void generateHondaEBizExportFile(List<Vendor_Order_Line_Item_Group__c> voliGroupList, Vendor_Order_Header__c voHeader) {
		fileContent = '';
		fileContent += createTransferHeaderRec();
		fileContent += createOrderHeaderRec(voHeader.Name);
		fileContent += createOrderDetailsRec(voliGroupList);
		fileContent += createOrderTrailerRec(voHeader.Name);
		fileContent += createTransferTrailerRec();
    }
    
	private void generateMonzaAustraliaExportFile(List<Vendor_Order_Line_Item_Group__c> voliGroupList) {
    	fileContent += 'ItemNumber,Name,Description,OrderQty,Price\n';
    	for(Vendor_Order_Line_Item_Group__c voliGroupRec : voliGroupList) {
    		Decimal cost = (voliGroupRec.Cost__c != null) ? voliGroupRec.Cost__c.setScale(2, RoundingMode.HALF_UP) : 0;
    		
    		fileContent += ((voliGroupRec.Part__r.Part_Number__c != null) ? voliGroupRec.Part__r.Part_Number__c.escapeCsv() : '') + ',';
			fileContent += ((voliGroupRec.Part__r.Description__c != null) ? voliGroupRec.Part__r.Description__c.escapeCsv() : '') + ',';
			fileContent += ((voliGroupRec.Part__r.Description__c != null) ? voliGroupRec.Part__r.Description__c.escapeCsv() : '') + ',';
			fileContent += ((voliGroupRec.Need__c != null) ? (String.valueOf(voliGroupRec.Need__c).escapeCsv()) : '0') + ',';		
    		fileContent += (String.valueOf(cost)).escapeCsv() + '\n';
		}
		voNumber = voNumber.remove('-');
		exportTypeToContentTypeMap.put(MONZA_AUSTRALIA, 'text/csv#'+vendorName +'_'+ voNumber+'.csv');
    }
    
	private void generateTurn14ExportFile(List<Vendor_Order_Line_Item_Group__c> voliGroupList, Vendor_Order_Header__c voHeader) {
		fileContent = '';
		fileContent += 'H' + voHeader.Name + '\n';
		fileContent += 'F' + freightCarrier + '\n';
		fileContent += createTurn14DetailsRec(voliGroupList);
		fileContent += 'D999999999';
		exportTypeToContentTypeMap.put(TURN_14, 'text/csv#'+ voHeader.Name +'.txt');
    }

	private String createTurn14DetailsRec(List<Vendor_Order_Line_Item_Group__c> voliGroupList) {
    	String recStr = '';
    	for(Integer i=0; i < voliGroupList.size(); i++) {
    		String partNumber = String.isNotBlank(voliGroupList[i].Part__r.Part_Number__c) ? voliGroupList[i].Part__r.Part_Number__c : '';
    		Integer qtyOrdered = (calculatePackagedQty(voliGroupList[i].Need__c, voliGroupList[i].Part__r, voliGroupList[i].Is_Order_As_Individual_Item__c)).intValue();
			if(qtyOrdered < 1) qtyOrdered = 1;
			if(qtyOrdered >= 1000) qtyOrdered = 999;
			String qtyOrderedStr = String.valueOf(qtyOrdered).leftPad(3, '0');
    		recStr += 'D' + qtyOrderedStr + partNumber + '\n';
		}    	
    	return recStr;
    }
    
    
    private String createTransferHeaderRec() {
    	String DCSSoftwareName = 'HONDAEBIZ';
    	String dealerNumber = hondaDealerNumber; //HondaUtility.getDealerNumber();
    	dealerNumber = String.isNotBlank(dealerNumber) ? dealerNumber : '';
    	
    	String recStr = '$$';
    	recStr += addSpaces(3);
    	recStr += dealerNumber + addSpaces(6 - dealerNumber.length());
    	recStr += '01';
    	recStr += 'P';
    	recStr += 'HC';
    	recStr += DCSSoftwareName + addSpaces(12 - DCSSoftwareName.length());
    	recStr += '12345';
    	recStr += addSpaces(27);
    	
    	return recStr;
    }
    
	private String createInterfaceHeaderRec() {
    	String dealerNumber = hondaDealerNumber;
    	dealerNumber = String.isNotBlank(dealerNumber) ? dealerNumber : '';
    	String specialChar = '›››››'; //Since ASCII value 155 is not supported in Salesforce we are using this special character directly.
    	String recStr = specialChar;
    	recStr += dealerNumber + addSpaces(6 - dealerNumber.length());
    	recStr += addSpaces(2);
    	recStr += 'P';
    	recStr += addSpaces(46);
    	return recStr;
    }
    
    private String getOrderRef(String voNumber) {
    	String orderRef = hondaEbizOrderType;
    	orderRef += getOrderDateRef(voNumber);
    	
    	return orderRef;
    }

	private String getOrderDateRef(String voNumber) {
    	String orderRef = String.isNotBlank(voNumber) ? voNumber.subString(voNumber.length()-3, voNumber.length()) : addSpaces(3);
    	orderRef += system.now().format('MMdd');
    	
    	return orderRef;
    }
    
    private String createTransactionHeaderRec(String voNumber) {
    	String recStr = 'PORD';
		recStr += 'P';
    	recStr += getOrderDateRef(voNumber);
    	recStr += addSpaces(22);
    	recStr += 'Y';
		recStr += '3';
    	recStr += '3';
		recStr += 'Y';
		recStr += 'N';
    	recStr += addSpaces(1);
    	recStr += String.isNotBlank(voNumber) ? voNumber + addSpaces(15 - voNumber.length()) : addSpaces(15);
    	recStr += addSpaces(5);
    	
    	return recStr;
    }

    private String createOrderHeaderRec(String voNumber) {
    	String recStr = 'PORD';
    	recStr += getOrderRef(voNumber);
    	recStr += addSpaces(25);
    	recStr += '0';
    	recStr += addSpaces(2);
    	recStr += addSpaces(14);
    	recStr += addSpaces(6);
    	
    	return recStr;
    }
    
    private String createOrderDetailsRec(List<Vendor_Order_Line_Item_Group__c> voliGroupList) {
    	String recStr = '';
    	for(Integer i=0; i < voliGroupList.size(); i++) {
    		String partNumber = String.isNotBlank(voliGroupList[i].Part__r.Part_Number__c) ? voliGroupList[i].Part__r.Part_Number__c : '';
    		partNumber = (partNumber.length() > 15 ? partNumber.subString(0, 15) : partNumber);
    		
    		String qtyOrderedStr = String.valueOf(calculatePackagedQty(voliGroupList[i].Need__c, voliGroupList[i].Part__r, voliGroupList[i].Is_Order_As_Individual_Item__c));
    		qtyOrderedStr = createFormattedStringForQtyOrdered(qtyOrderedStr);
    		qtyOrderedStr = (qtyOrderedStr.split('\\.'))[0];
    		qtyOrderedStr = qtyOrderedStr.length() > 4 ? qtyOrderedStr.subString(0, 4) : qtyOrderedStr;
    		
    		recStr += partNumber + addSpaces(15 - partNumber.length());
    		recStr += addSpaces(3);
    		recStr += addSpecifiedChar(4 - qtyOrderedStr.length(), '0') + qtyOrderedStr;
    		recStr += addSpaces(8);
    	}

    	if(Math.mod(voliGroupList.size(), 2) != null && math.mod(voliGroupList.size(), 2) > 0) {
    		recStr += createExtraOrderDetailRecord(1);
    	} else {
    		recStr += createExtraOrderDetailRecord(2);
    	}

    	return recStr;
    }
    
    private String createOrderTransactionDetailsRec(List<Vendor_Order_Line_Item_Group__c> voliGroupList) {
    	String recStr = '';
    	for(Integer i=0; i < voliGroupList.size(); i++) {
    		String partNumber = String.isNotBlank(voliGroupList[i].Part__r.Part_Number__c) ? voliGroupList[i].Part__r.Part_Number__c : '';
    		partNumber = (partNumber.length() > 17 ? partNumber.subString(0, 17) : partNumber);
    		
    		String qtyOrderedStr = String.valueOf(calculatePackagedQty(voliGroupList[i].Need__c, voliGroupList[i].Part__r, voliGroupList[i].Is_Order_As_Individual_Item__c));
    		qtyOrderedStr = createFormattedStringForQtyOrdered(qtyOrderedStr);
    		qtyOrderedStr = (qtyOrderedStr.split('\\.'))[0];
    		qtyOrderedStr = qtyOrderedStr.length() > 4 ? qtyOrderedStr.subString(0, 4) : qtyOrderedStr;
    		
    		recStr += partNumber + addSpaces(17 - partNumber.length());
    		recStr += addSpaces(1);
    		recStr += addSpecifiedChar(4 - qtyOrderedStr.length(), '0') + qtyOrderedStr;
			if(String.isNotBlank(voliGroupList[i].Part__r.Assigned_Location_1__c)) {
				String location = (voliGroupList[i].Part__r.Assigned_Location_1__c.replaceAll(';', ' ')).trim();
				recStr += location.length() > 6 ? location.subString(0, 6) : location; 
				recStr += addSpaces(6 - location.length());
			} else {
				recStr += addSpaces(6);
			}
    		recStr += addSpaces(2);
    	}

    	if(Math.mod(voliGroupList.size(), 2) != null && math.mod(voliGroupList.size(), 2) > 0) {
    		recStr += createAmericanHondaExtraOrderDetailRecord(1);
    	} else {
    		recStr += createAmericanHondaExtraOrderDetailRecord(2);
    	}

    	return recStr;
    }

	private String createAmericanHondaExtraOrderDetailRecord(Integer numOfExtraOrderDetailRec) {
    	String recStr = '';
    	for(Integer i=0; i < numOfExtraOrderDetailRec; i++) {
			recStr += 'END' + addSpaces(27);
    	}
    	
    	return recStr;
    }
    
    private String createExtraOrderDetailRecord(Integer numOfExtraOrderDetailRec) {
    	String recStr = '';
    	for(Integer i=0; i < numOfExtraOrderDetailRec; i++) {
    		recStr += 'END' + addSpaces(12);
    		recStr += addSpaces(3);
    		recStr += addSpaces(4);
    		recStr += addSpaces(8);
    	}
    	
    	return recStr;
    }
    
    private String createOrderTrailerRec(String voNumber) {
    	String recStr = 'END';
    	recStr += addSpaces(1);
    	recStr += getOrderRef(voNumber);
    	recStr += addSpaces(48);
    	
    	return recStr;
    }
    
    private String createTransactionIntefaceTrailerRec() {
    	String recStr = 'END ';
    	recStr += addSpaces(56);
		recStr += '››END';
		recStr += addSpaces(55);
    	return recStr;
    }

    private String createTransferTrailerRec() {
    	String dealerNumber = hondaDealerNumber; //HondaUtility.getDealerNumber();
    	dealerNumber = String.isNotBlank(dealerNumber) ? dealerNumber : '';
    	
    	String recStr = '$$END';
    	recStr += dealerNumber + addSpaces(6 - dealerNumber.length());
    	recStr += addSpaces(49);
    	
    	return recStr;
    }
    
    private String addSpaces(Integer numOfSpaces) {
    	return addSpecifiedChar(numOfSpaces, ' ');
    }
    
    private String addSpecifiedChar(Integer numOfChar, String value) {
    	String charStr = '';
    	for(Integer i = 0; i < numOfChar; i++) {
    		charStr += value != null ? value : ' ';
    	}
    	return charStr;
    }

    private void generateHDnetAustraliaExportFile(Vendor_Order_Header__c voHeader) {
    	String mailBoxId = HDnet_Australia_Config__c.getOrgDefaults().Dealer_Mailbox_Id__c;
		String shipTo = HDnet_Australia_Config__c.getOrgDefaults().Ship_To__c;
    	String dealerRefHeader = voHeader.Name != null ? voHeader.Name : '';
    	String currentFormattedDate = DateTime.now().format('YYYYMMdd');
		String notes = (voHeader.Notes__c != null) ? voHeader.Notes__c : '';
		String orderType = HDnet_Australia_Config__c.getOrgDefaults().Order_Type__c;
    	if(String.isNotBlank(voHeader.Purchase_Order_Type__r.Code__c)) {
    		if(voHeader.Purchase_Order_Type__r.Code__c.containsIgnoreCase('STANDARD')) {
    			orderType = 'SO';
    		} else if(voHeader.Purchase_Order_Type__r.Code__c.containsIgnoreCase('PREMIUM')) {
    			orderType = 'UU';
    		} else if(voHeader.Purchase_Order_Type__r.Code__c.containsIgnoreCase('LINKED')) {
    			orderType = 'SM';
    		}  else if(voHeader.Purchase_Order_Type__r.Code__c.containsIgnoreCase('DOWN VEHICLE')) {
    			orderType = 'SU';
    		}
    	}
		
		String headerNode = '<header>';
		headerNode += '<poReference>' + dealerRefHeader + '</poReference>';
		headerNode += '<dealerNumber>' + mailBoxId + '</dealerNumber>';
		headerNode += '<requestedDate>' + currentFormattedDate + '</requestedDate>';
		headerNode += '<time></time>';
		headerNode += '<orderType>' + orderType + '</orderType>';
		headerNode += '<shipping-method></shipping-method>';
		headerNode += '<shipToDealerNumber>' + shipTo + '</shipToDealerNumber>';
		headerNode += '<vinNumber></vinNumber>';
		headerNode += '<notes>'+notes+'</notes>';
		headerNode += '</header>';

		String lineItemsNode = '';
		for(Vendor_Order_Line_Item_Group__c voliGroupRec : voHeader.Vendor_Order_Line_Item_Groups__r) {
	    	String partNumber = voliGroupRec.Part__r.Part_Number__c != null ? voliGroupRec.Part__r.Part_Number__c : '';
			String qtyWholeNumber = voliGroupRec.Need__c != null ? String.valueOf(voliGroupRec.Need__c.intValue()) : '0';

			lineItemsNode += '<lineItem>';
			lineItemsNode += '<partNumber>' + partNumber + '</partNumber>';
			lineItemsNode += '<quantity>' + qtyWholeNumber + '</quantity>';
			lineItemsNode += '<linkedOrder></linkedOrder>';
			lineItemsNode += '<notes></notes>';
			lineItemsNode += '</lineItem>';
		}

        fileContent = (headerNode + lineItemsNode);
		exportTypeToContentTypeMap.put(HDNET_AUSTRALIA, 'text/plain/#'+dealerRefHeader+'.txt');
    }

    String newLineStr = '\r\n';
	private void generateYamahaAustraliaExportFile(List<Vendor_Order_Line_Item_Group__c> voliGroupList, Vendor_Order_Header__c voHeader) {
        String dealerCode = Yamaha_Australia_Config__c.getOrgDefaults().Dealer_Code__c;
        
        String header = generateHeaderForYamaha(voHeader);
        String orderDetail = generateOrderDetailForYamaha(voHeader, voliGroupList);
        String trailer = generateTrailerForYamaha(voHeader, voliGroupList);
        fileContent += header + newLineStr + orderDetail + trailer;
        
        String companyNumber;
        String locale = GeneralConfiguration.getCompanyLocale();
        if (locale == 'Australia') {
            companyNumber = '001';
        } else if(locale == 'New Zealand') {
            companyNumber = '010';
        }
        exportTypeToContentTypeMap.put(YAMAHA_AUSTRALIA, 'text/plain/#' + 'O' + dealerCode + '1' + '.' + companyNumber);
	}
    
    private String generateHeaderForYamaha(Vendor_Order_Header__c voHeader) {
        String salesPersonCode = Yamaha_Australia_Config__c.getOrgDefaults().Sales_Person_Code__c;
        String userId = Yamaha_Australia_Config__c.getOrgDefaults().User_ID__c;
        String dealerCode = Yamaha_Australia_Config__c.getOrgDefaults().Dealer_Code__c;
        
        String header = getCommonDataForYamaha(voHeader, dealerCode, '1');
        
        String creationDate = '';
        if(voHeader.Ordered_Date__c == null && (voHeader.Status__c == 'Open' || voHeader.Status__c == 'Locked')) {
            creationDate = voHeader.CreatedDate.format('YYYYMMdd');
        } else {
            creationDate = Datetime.newInstance(voHeader.Ordered_Date__c.year(), voHeader.Ordered_Date__c.month(), voHeader.Ordered_Date__c.day()).format('YYYYMMdd');
        }
        header += creationDate;
        
        String orderType = voHeader.Purchase_Order_Type__r.Code__c != null ? voHeader.Purchase_Order_Type__r.Code__c.SubString(0, 1) : ' '; 
        header += orderType;
        
        userId += createStringToAppend(' ', 10, userId.length());
        header += userId;
        header += addSpaces(10); // Spare
        
        String dueDate = '';
        if(voHeader.Expected_Date_Formula__c != null) {
            dueDate = datetime.newInstance(voHeader.Expected_Date_Formula__c.year(), voHeader.Expected_Date_Formula__c.month(),voHeader.Expected_Date_Formula__c.day()).format('YYYYMMdd');
        }
        dueDate += createStringToAppend(' ', 8, dueDate.length());
        header += dueDate;
        
        header += addSpaces(25); // Transport Company
        header += addSpaces(25); // Transport Instructions
        header += 'N'; // Back Order Flag
        
        salesPersonCode += createStringToAppend(' ', 3, salesPersonCode.length());
        header += salesPersonCode;
        header += addSpaces(53); // Spare
        return header; 
    }
    
    private String generateOrderDetailForYamaha(Vendor_Order_Header__c voHeader, List<Vendor_Order_Line_Item_Group__c> voliGroupList) {
        String dealerCode = Yamaha_Australia_Config__c.getOrgDefaults().Dealer_Code__c;
        String orderDetail = '';
        for(Vendor_Order_Line_Item_Group__c voliGroupRec : voHeader.Vendor_Order_Line_Item_Groups__r) {
            orderDetail += getCommonDataForYamaha(voHeader, dealerCode, '2');
        
            String partNumber = voliGroupRec.Part__r.Part_Number__c != null ? voliGroupRec.Part__r.Part_Number__c : '';
            if(partNumber.length() > 20) {
                partNumber = partNumber.subString(0, 20);
            } else {
                partNumber += createStringToAppend(' ', 20, partNumber.length());
            }
            orderDetail += partNumber; 

            Decimal qtyOrdered = calculatePackagedQty(voliGroupRec.Need__c, voliGroupRec.Part__r, voliGroupRec.Is_Order_As_Individual_Item__c);
            String qtyOrderedStr = String.valueOf(qtyOrdered);
            qtyOrderedStr = createFormattedStringForQtyOrdered(qtyOrderedStr);
            qtyOrderedStr = createStringToAppend('0', 7, qtyOrderedStr.length()) + qtyOrderedStr;
            orderDetail += qtyOrderedStr; 
            
            orderDetail += addSpaces(9); // Location
            
            String orderType = voHeader.Purchase_Order_Type__r.Code__c != null ? voHeader.Purchase_Order_Type__r.Code__c.SubString(0, 1) : ' '; 
            orderDetail += orderType;
            orderDetail += 'N'; //Back Order Flag
            
            String message = (voHeader.Notes__c != null) ? voHeader.Notes__c : '';
            if(message != null && message.length() > 50) {
                message = message.subString(0, 50);
            } else {
                message += createStringToAppend(' ', 50, message.length());
            }
            orderDetail += message;
            orderDetail += addSpaces(36);
            orderDetail += newLineStr;
        }
        return orderDetail;
    }
    
    private String generateTrailerForYamaha(Vendor_Order_Header__c voHeader, List<Vendor_Order_Line_Item_Group__c> voliGroupList) {
        String salesPersonCode = Yamaha_Australia_Config__c.getOrgDefaults().Sales_Person_Code__c;
        String userId = Yamaha_Australia_Config__c.getOrgDefaults().User_ID__c;
        String dealerCode = Yamaha_Australia_Config__c.getOrgDefaults().Dealer_Code__c;
        
        String trailer = getCommonDataForYamaha(voHeader, dealerCode, '9');
        
        String totalLines = String.valueOf(voliGroupList.size());
        trailer += addSpecifiedChar(5 - totalLines.length(), '0') + totalLines;
        
        Decimal qtyOrdered = 0;
        for(Vendor_Order_Line_Item_Group__c voliGroupRec : voliGroupList) {
            qtyOrdered += calculatePackagedQty(voliGroupRec.Need__c, voliGroupRec.Part__r, voliGroupRec.Is_Order_As_Individual_Item__c);
        }
        String qtyOrderedStr = createFormattedStringForQtyOrdered(String.valueOf(qtyOrdered));
        trailer += addSpecifiedChar(9 - qtyOrderedStr.length(), '0') + qtyOrderedStr;
        
        trailer += addSpaces(110);
        return trailer;
    }
    
    private String getCommonDataForYamaha(Vendor_Order_Header__c voHeader, String dealerCode, String recordType) {
        String startingContent = recordType;
        startingContent += dealerCode;
        startingContent += addSpaces(4);
        
        String voNumber = voHeader.Name;
        voNumber += createStringToAppend(' ', 15, voNumber.length());
        startingContent += voNumber;
        return startingContent;
    }
    
    private void generateYamahaCanadaExportFile(List<Vendor_Order_Line_Item_Group__c> voliGroupList, Vendor_Order_Header__c voHeader) {
        fileContent = '';
    	for(Vendor_Order_Line_Item_Group__c voliGroupRec : voliGroupList) {
	    	Decimal qtyOrdered = calculatePackagedQty(voliGroupRec.Need__c, voliGroupRec.Part__r, voliGroupRec.Is_Order_As_Individual_Item__c);
			fileContent += ((voliGroupRec.Part__r.Part_Number__c != null) ? voliGroupRec.Part__r.Part_Number__c.escapeCsv() : '') + ',';
			fileContent += qtyOrdered.format() + '\n';
    	}
	}
	
    private String createStringToAppend(String chracterToAdd, Integer maxLength, Integer currentLength) {
    	String str = '';
    	if(currentLength < maxLength) {
    		Integer noOfChars = maxLength - currentLength;
    		if(noOfChars > 0) {
    			for(Integer i=0; i<noOfChars; i++) {
					str += chracterToAdd;
				}
    		}
    	}
		return str;
    }

    private String createFormattedStringForQtyOrdered(String qtyOrdered) {
    	List<String> splittedString = qtyOrdered.split('\\.');
    	if(splittedString.size() == 2) {
    		List<String> splittedSubString = splittedString[1].split('');
    		if(splittedSubString.size() > 0) {
    			for(Integer i=splittedSubString.size()-1; i>=0; i--) {
    				String strToAppend = '';
    				if(Integer.valueOf(splittedSubString[i]) == 0) {
    					strToAppend = splittedString[1].subString(0, i);
    				} else {
    					break;
    				}
    				qtyOrdered = splittedString[0] + (strToAppend.length() > 0 ? ('.' + strToAppend) : strToAppend);
    			}
    		}
    	}
		return qtyOrdered;
    }

    private Decimal calculatePackagedQty(Decimal need, Part__c partRec, Boolean isOrderAsIndividualItem) {
    	Decimal qtyOrdered = need != null ? need : 0;
    	if(partRec.Packaged_Part__c && !isOrderAsIndividualItem) {
        	if(partRec.Package_Qty__c == null) {
        		partRec.Package_Qty__c = 1;
        	}
            qtyOrdered = qtyOrdered / partRec.Package_Qty__c;
        }
        return qtyOrdered;
    }

	public class VOExportParams {
		public String VOHeaderId;
		public String ExportType;
		public String ExportFormatId;
		public String HondaDealerNumber;
		public String OrderType;
		public String FreightCarrier;
	}
}