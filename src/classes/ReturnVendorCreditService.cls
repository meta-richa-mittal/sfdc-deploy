public without sharing class ReturnVendorCreditService {
    
    public static Integer getActiveReturnCRCountByVendorId(String vendorId) {
    	String query = 'SELECT Count(Id) RCRCount FROM Return_CR_Header__c WHERE Vendor__c = \''+ BPUtility.escapeSingleQuotes(vendorId) + '\' AND Status__c = \'In Progress\'';
    	List<AggregateResult> aggList = SOQLUtility.getQueryResults('Return_CR_Header__c', query);
    	return (aggList.size() > 0) ? (Integer)aggList[0].get('RCRCount') : 0;
    }

    public static GlobalSearchResultsWrapper getActiveReturnCreditsByVendorId(GlobalSearchResultsWrapper.COOpenOrderFilterJSON filterObj) {
        String query = 'SELECT Name, Vendor__r.Name, Credit_Memo__c, LastModifiedDate, Total_With_Tax__c, Status__c FROM Return_CR_Header__c WHERE Vendor__c = \'' + BPUtility.escapeSingleQuotes(filterObj.VendorId) + 
            			'\' AND Status__c = \'In Progress\' ORDER BY Name Desc ' + 
            			SOQLUtility.getLimitClause(filterObj.StartIndex, filterObj.RecordCount);

        if(AccessControl.ifObjectFieldIsAccessible('Return_CR_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        List<Return_CR_Header__c> rcrHeaderList = Database.query(query);
        return new GlobalSearchResultsWrapper(rcrHeaderList.size(), rcrHeaderList);
    }

    public static String addVendor(String vendorId, String returnCRId) {
        Return_CR_Header__c returnCRRec = new Return_CR_Header__c(Vendor__c = vendorId, Status__c = 'In Progress', Credited_Date__c = System.today());
        if(String.isNotBlank(returnCRId)) {
            returnCRRec.Id = returnCRId;
        }
        DMLUtility.upsertSobjectList('Return_CR_Header__c', returnCRRec);
        return returnCRRec.Id;
    }

    public static Object getReturnCreditDetails(String returnCRId) {
        List<Return_CR_Header__c> returnCRRecList = getReturnCRHeaderDetail(returnCRId);
        if(returnCRRecList.isEmpty()) throw new BlackpurlException('Invalid Return Credit Memo.');
        return new ReturnCRHeaderWrapper(returnCRRecList[0]);
    }

    private static String getRVOSelectAllValue(List<ReturnVOHeaderWrapper> rvoObjList) {
        Integer selectedCount = 0, unSelectedCount = 0, disableCount = 0, partialCount = 0;
        for(ReturnVOHeaderWrapper rvoObj: rvoObjList) {
            if(rvoObj.RCRSelectedValue == 'All') {
                selectedCount++;
            } else if(rvoObj.RCRSelectedValue == 'None') {
                unSelectedCount++;
            } else if(rvoObj.RCRSelectedValue == 'Disable') {
                disableCount++;
            } else if(rvoObj.RCRSelectedValue == 'Partial') {
                partialCount++;
            }
        }
        return (selectedCount == rvoObjList.size() ? 'All' : 
                (disableCount == rvoObjList.size() ? 'Disable' : 
                ((selectedCount > 0 || partialCount > 0) ? 'Partial' : 'None')));
    }

    private static List<Return_CR_Header__c> getReturnCRHeaderDetail(String returnCRId) {
        String query = 'SELECT ' + String.join(ReturnCRHeaderWrapper.getReturnCRFieldList(), ', ') + ' FROM Return_CR_Header__c WHERE Id = :returnCRId';
        if(AccessControl.ifObjectFieldIsAccessible('Return_CR_Header__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        return Database.query(query);
    }

    public static String saveReturnCreditDetails(Map<String, Object> rcrJsonMap) {
		String vendorId = rcrJsonMap.get('VendorId') != null ? (String)rcrJsonMap.get('VendorId') : null;
		String rcrId = rcrJsonMap.get('Id') != null ? (String)rcrJsonMap.get('Id') : null;
		if(rcrJsonMap.containsKey('CreditMemoNumber') && rcrJsonMap.get('CreditMemoNumber') != null) {
			String newCreditMemoNumber = (String)rcrJsonMap.get('CreditMemoNumber');
			List<Return_CR_Header__c> rcrRecList = [Select Credit_Memo__c from Return_CR_Header__c where Id = :rcrId];
			if(!rcrRecList.isEmpty()) {
                if(rcrRecList[0].Credit_Memo__c != newCreditMemoNumber) {
					List<Return_CR_Header__c> rcrList = [Select Credit_Memo__c from Return_CR_Header__c where (Id != :rcrId AND 
															Vendor__c =: vendorId AND Credit_Memo__c =: newCreditMemoNumber) Limit 1];
					if(!rcrList.isEmpty()) {
						throw new BlackpurlException('This Credit Memo number already exists. Please use a different number.');
					}
				}
			}
		}

    	Return_CR_Header__c returnCRHObjToUpdate = new Return_CR_Header__c(Id = rcrId);
		for(String objKey: rcrWrapperKeyToAPINameMap.keySet()) {
			if(rcrJsonMap.containsKey(objKey)) {
				String value = rcrJsonMap.get(objKey) != null ? (String)rcrJsonMap.get(objKey) : null;
				if(objKey == 'CreditedDate' && rcrJsonMap.get(objKey) != null) {
					returnCRHObjToUpdate.put(rcrWrapperKeyToAPINameMap.get(objKey), DateTimeUtility.parseDate(value));
				} else {
					returnCRHObjToUpdate.put(rcrWrapperKeyToAPINameMap.get(objKey), value);
				}
			}
		}
    	DMLUtility.updateSobjectList('Return_CR_Header__c', returnCRHObjToUpdate);
    	
    	return 'Success';
    }

    public static Map<String, Object> getRVOListToCredit(String returnCRId, String vendorId, PaginationSorting pageSortAttrs) {
        List<Return_VO_Header__c> rvoList = [SELECT Name, RMA__c, Status__c, Reason__c, 
                                                (SELECT Return_CR_Line_Item__r.Return_CR_Header__c FROM Return_VO_Line_Items__r) 
                                                FROM Return_VO_Header__c WHERE Vendor__c =: vendorId AND Status__c IN ('Approved', 'Partially Credited') 
                                                order by Name ASC LIMIT :SOQLUtil.getAvailableQueryRowsLimit()];
        
        List<ReturnVOHeaderWrapper> rvoObjList = new List<ReturnVOHeaderWrapper>();
        for(Return_VO_Header__c rvoRec: rvoList) {
            rvoObjList.add(new ReturnVOHeaderWrapper(rvoRec, returnCRId));
        }

        if(pageSortAttrs == null) { // return all RVO list
            return new Map<String, Object>{
                                            'TotalRVOCount' => rvoObjList.size(),
                                            'RVOList' => rvoObjList,
                                            'SelectedValue' => getRVOSelectAllValue(rvoObjList)
                                        };
        }
        if(pageSortAttrs.CurrentPage == null || pageSortAttrs.CurrentPage == 0) pageSortAttrs.CurrentPage = 1;
        if(pageSortAttrs.pageSize == null || pageSortAttrs.pageSize == 0) pageSortAttrs.pageSize = (Integer)General_Configurations__c.getOrgDefaults().Related_List_Page_Size__c;
        
        Integer toIndex = pageSortAttrs.currentPage * pageSortAttrs.pageSize;
        Integer fromIndex = toIndex - pageSortAttrs.pageSize;
        return new Map<String, Object>{
                                          'TotalRVOCount' => rvoObjList.size(),
                                          'RVOList' => getPaginatedRecords(rvoObjList, fromIndex, toIndex),
                                          'SelectedValue' => getRVOSelectAllValue(rvoObjList)
                                        };
    }

    public static Object getRVODetailsById(String returnCRId, String rvoId) {
        List<Return_VO_Header__c> rvoList = [SELECT Name, RMA__c, Status__c, Reason__c, 
                                                (SELECT Return_CR_Line_Item__r.Return_CR_Header__c FROM Return_VO_Line_Items__r) 
                                                FROM Return_VO_Header__c WHERE Id =: rvoId];
        
        if(rvoList.isEmpty()) return null;
        return new ReturnVOHeaderWrapper(rvoList[0], returnCRId);
    }

    public static Map<String, Object> getRVOLIListToCredit(String returnCRId, String rvoId, Integer fromIndex, Integer toIndex) {
        List<Return_VO_Line_Item__c> rvoliList = [SELECT Name, Item_Desc__c, Return_Qty__c, Return_CR_Line_Item__r.Return_CR_Header__c FROM Return_VO_Line_Item__c WHERE Return_VO_Header__c =: rvoId 
                                                    order by Name ASC LIMIT :SOQLUtil.getAvailableQueryRowsLimit()]; //  AND (Return_CR_Line_Item__c = null OR Return_CR_Line_Item__r.Return_CR_Header__c = :returnCRId) 
        
        List<ReturnVOHeaderWrapper.ReturnVoLineItemWrapper> rvoliObjList = new List<ReturnVOHeaderWrapper.ReturnVoLineItemWrapper>();
        for(Return_VO_Line_Item__c rvoRec: rvoliList) {
            rvoliObjList.add(new ReturnVOHeaderWrapper.ReturnVoLineItemWrapper(rvoRec, returnCRId));
        }
        return new Map<String, Object>{
                                          'TotalRVOLICount' => rvoliObjList.size(),
                                          'ReturnVOLIList' => getPaginatedRecords(rvoliObjList, fromIndex, toIndex)
                                        };
    }

    public static Boolean validateRVOLineItemsToCredit(String returnCRId, String recordId) {
        String objectName = String.valueOf(Id.valueOf(recordId).getSobjectType());
        String query = '';
        if(objectName == Constants.NAMESPACE + 'Return_VO_Line_Item__c') {
            List<Return_VO_Line_Item__c> rvoLIList = [SELECT Id FROM Return_VO_Line_Item__c WHERE 
                                                        Return_CR_Line_Item__c != null AND Return_CR_Line_Item__r.Return_CR_Header__c != :returnCRId 
                                                        AND Id = :recordId];
            return (rvoLIList.isEmpty());
        } else if(objectName == Constants.NAMESPACE + 'Return_VO_Header__c') {
            List<Return_VO_Header__c> rvoList = [SELECT Id FROM Return_VO_Header__c WHERE Status__c = 'Credited' AND Id = :recordId];
            return (rvoList.isEmpty());
        }
        return false;
    }

    public static void createReturnCRLineItems(String returnCRId, String recordId) {
        String objectName = String.valueOf(Id.valueOf(recordId).getSobjectType());
        String query = 'SELECT Item__c, Description__c, Part__c, Return_Qty__c, Item_Cost__c FROM Return_VO_Line_Item__c WHERE Return_CR_Line_Item__c = null AND ';
        if(objectName == Constants.NAMESPACE + 'Return_VO_Line_Item__c') {
            query += 'Id = :recordId';
        } else if(objectName == Constants.NAMESPACE + 'Return_VO_Header__c') {
            query += 'Return_VO_Header__c = :recordId';
        } else if(objectName == 'Account') {
            query += 'Return_VO_Header__r.Vendor__c = :recordId AND Return_VO_Header__r.Status__c IN (\'Approved\', \'Partially Credited\')';
        }
        
        Map<String, Return_CR_Line_Item__c> rvoliIdToRCRLIRecMap = new Map<String, Return_CR_Line_Item__c>();
        for(Return_VO_Line_Item__c rvoLIRec: Database.query(query)) {
            Return_CR_Line_Item__c rcrLIRec = new Return_CR_Line_Item__c(Return_CR_Header__c = returnCRId, Item__c = rvoLIRec.Item__c, 
                                                    Description__c = rvoLIRec.Description__c, Part__c = rvoLIRec.Part__c, 
                                                    Return_Qty__c = rvoLIRec.Return_Qty__c, Return_Cost__c = rvoLIRec.Item_Cost__c, 
                                                    Credit_Cost__c = rvoLIRec.Item_Cost__c);
                
            rvoliIdToRCRLIRecMap.put(rvoLIRec.Id, rcrLIRec);
        }
        DMLUtility.insertSobjectList('Return_CR_Line_Item__c', rvoliIdToRCRLIRecMap.values());

        List<Return_VO_Line_Item__c> rvoliListToUpdate = new List<Return_VO_Line_Item__c>();
        for(String rvoliId: rvoliIdToRCRLIRecMap.keySet()) {
            rvoliListToUpdate.add(new Return_VO_Line_Item__c(Id = rvoliId, Return_CR_Line_Item__c = rvoliIdToRCRLIRecMap.get(rvoliId).Id));
        }
        DMLUtility.updateSobjectList('Return_VO_Line_Item__c', rvoliListToUpdate);
    }

    public static void removeReturnCRLineItems(String returnCRId, String recordId) {
        List<Return_CR_Line_Item__c> rcrLIToDeleteList = new List<Return_CR_Line_Item__c>();

        String objectName = String.valueOf(Id.valueOf(recordId).getSobjectType());
        if(objectName == Constants.NAMESPACE + 'Return_VO_Header__c') {
            List<Return_VO_Line_Item__c> rvoliList = [SELECT Return_CR_Line_Item__c FROM Return_VO_Line_Item__c 
                                                        WHERE Return_VO_Header__c = :recordId AND Return_CR_Line_Item__c != null AND 
                                                        Return_CR_Line_Item__r.Return_CR_Header__c = :returnCRId];
            for(Return_VO_Line_Item__c rvoliRec: rvoliList) {
                rcrLIToDeleteList.add(new Return_CR_Line_Item__c(Id = rvoliRec.Return_CR_Line_Item__c));
            }
        } else if(objectName == Constants.NAMESPACE + 'Return_CR_Line_Item__c') {
            rcrLIToDeleteList.add(new Return_CR_Line_Item__c(Id = recordId));
        } else if(objectName == Constants.NAMESPACE + 'Return_CR_Header__c') {
            rcrLIToDeleteList.addAll([SELECT Id FROM Return_CR_Line_Item__c WHERE Return_CR_Header__c = :recordId]);
        }

        DMLUtility.deleteSobjectList('Return_CR_Line_Item__c', rcrLIToDeleteList);
    }

    public static Map<String, Object> getItemsList(String returnCRId, PaginationSorting pageSortAttrs) {
        List<Return_CR_Line_Item__c> rcrLIList = getRCRLIList(returnCRId, pageSortAttrs);
        
        List<ReturnCRHeaderWrapper.ReturnCRLineItemWrapper> rcrliObjList = new List<ReturnCRHeaderWrapper.ReturnCRLineItemWrapper>();
        for(Return_CR_Line_Item__c rcrRec: rcrLIList) {
            rcrliObjList.add(new ReturnCRHeaderWrapper.ReturnCRLineItemWrapper(rcrRec));
        }

        if(pageSortAttrs.CurrentPage == null || pageSortAttrs.CurrentPage == 0) pageSortAttrs.CurrentPage = 1;
        if(pageSortAttrs.pageSize == null || pageSortAttrs.pageSize == 0) pageSortAttrs.pageSize = (Integer)General_Configurations__c.getInstance().Related_List_Page_Size__c;
        
        Integer toIndex = pageSortAttrs.currentPage * pageSortAttrs.pageSize;
        Integer fromIndex = toIndex - pageSortAttrs.pageSize;
        return new Map<String, Object>{
                                            'TotalRCRLICount' => rcrliObjList.size(),
                                            'ReturnCRLIList' => getPaginatedRecords(rcrliObjList, fromIndex, toIndex)
                                        };
    }

    public static void updateRCRLineItemData(ReturnCRHeaderWrapper.ReturnCRLineItemWrapper itemObj) {
        Return_CR_Line_Item__c rcrLIRec = new Return_CR_Line_Item__c(Id = itemObj.Id, Credit_Cost__c = itemObj.CreditCost);
        DMLUtility.updateSobjectList('Return_CR_Line_Item__c', rcrLIRec);
    }

    public static String saveOtherCharge(String rcrId, VendorInvoicingCtrl.OtherChargesWrapper otherChargeObj) {
        if(String.isBlank(otherChargeObj.Fee)) throw new BlackpurlException('Invalid fee');
        
        if(AccessControl.ifObjectIsAccessible('Fee__c') == false ) {throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE);}
        List<Fee__c> feeList = [select Code__c, Description__c, Price__c from Fee__c WHERE Id =: otherChargeObj.Fee AND Type__c = 'Purchasing' AND Active__c = true];
        if(feeList.isEmpty()) throw new BlackpurlException('Invalid fee');
        
        Other_Charges__c otherChargeRec = new Other_Charges__c(Fee__c = otherChargeObj.Fee, Id = otherChargeObj.Id);
        otherChargeRec.Cost__c = otherChargeObj.Cost != null ? otherChargeObj.Cost : feeList[0].Price__c;
        otherChargeRec.Item_Code__c = String.isNotBlank(otherChargeObj.Code) ? otherChargeObj.Code : feeList[0].Code__c;
        otherChargeRec.Item_Description__c = String.isNotBlank(otherChargeObj.Description) ? otherChargeObj.Description : feeList[0].Description__c;
        otherChargeRec.Notes__c = otherChargeObj.Notes;
        otherChargeRec.Return_CR_Header__c = rcrId;
        DMLUtility.upsertSobjectList('Other_Charges__c', otherChargeRec);
        return 'Success';
    }

    public static void deleteOtherCharge(String otherChargeId) {
        DMLUtility.deleteSobjectList('Other_Charges__c', new Other_Charges__c(Id = otherChargeId));
    }

    public static Object getOtherChargesList(String rcrId) {
        List<VendorInvoicingCtrl.OtherChargesWrapper> otherChargesList = new List<VendorInvoicingCtrl.OtherChargesWrapper>();
        for(Other_Charges__c otherChargeRec: (List<Other_Charges__c>)SOQLUtil.getOtherChargesByFieldName(new Map<String, String>{'Return_CR_Header__c' => rcrId})) {
            VendorInvoicingCtrl.OtherChargesWrapper OtherChargesObj = new VendorInvoicingCtrl.OtherChargesWrapper(otherChargeRec);
            otherChargesList.add(OtherChargesObj);
        }
        return otherChargesList;
    }

    public static void processVendorCredit(String returnCRId) {
        List<Return_CR_Header__c> rcrList = [SELECT Status__c FROM Return_CR_Header__c WHERE Id  = :returnCRId];
        if(!rcrList.isEmpty() && rcrList[0].Status__c == 'Credited') {
            throw new BlackpurlException('This Return Credit Memo has already been credited.');
        }
        Return_CR_Header__c rcrHeaderObjToUpdate = new Return_CR_Header__c(Id = returnCRId, Status__c = 'Credited');
    	for(Return_CR_Header__c rcrRec: [SELECT Vendor__r.Country__r.Conversion_Rate_With_Markup__c FROM Return_CR_Header__c WHERE Id =: returnCRId AND Vendor__r.Is_Foreign_Vendor__c = true AND Vendor__r.Country__r.Conversion_Rate_With_Markup__c != null]) {
			rcrHeaderObjToUpdate.FX_Conversion_Rate__c = rcrRec.Vendor__r.Country__r.Conversion_Rate_With_Markup__c;
		}
        DMLUtility.updateSobjectList('Return_CR_Header__c', rcrHeaderObjToUpdate);

        List<String> rvoHeaderIdToUpdateList = new List<String>();
        for(Return_CR_Line_Item__c rcrLIRec: [SELECT Id, (SELECT Return_VO_Header__c FROM Return_VO_Line_Items__r LIMIT 1) FROM Return_CR_Line_Item__c WHERE Return_CR_Header__c = :returnCRId]) {
            if(!rcrLIRec.Return_VO_Line_Items__r.isEmpty()) {
                if(rcrLIRec.Return_VO_Line_Items__r[0].Return_VO_Header__c != null) {
                    rvoHeaderIdToUpdateList.add(rcrLIRec.Return_VO_Line_Items__r[0].Return_VO_Header__c);
                }
            }
        }

        Map<String, Set<String>> rvoHeaderIdToLICreditStatusSetMap = new Map<String, Set<String>>();
        for(Return_VO_Line_Item__c rcrRec: [SELECT Credit_Status__c, Return_VO_Header__c FROM Return_VO_Line_Item__c WHERE Return_VO_Header__c IN :rvoHeaderIdToUpdateList]) {
			if(!rvoHeaderIdToLICreditStatusSetMap.containsKey(rcrRec.Return_VO_Header__c)) {
                rvoHeaderIdToLICreditStatusSetMap.put(rcrRec.Return_VO_Header__c, new Set<String>());
            }
            rvoHeaderIdToLICreditStatusSetMap.get(rcrRec.Return_VO_Header__c).add(rcrRec.Credit_Status__c);
		}

        List<Return_VO_Header__c> rvoHeaderToUpdateList = new List<Return_VO_Header__c>();
        for(String rvoHeaderId: rvoHeaderIdToLICreditStatusSetMap.keySet()) {
            Return_VO_Header__c rvoHeaderRec = new Return_VO_Header__c(Id = rvoHeaderId);
            if(rvoHeaderIdToLICreditStatusSetMap.get(rvoHeaderId).contains('Credited')) {
                if(rvoHeaderIdToLICreditStatusSetMap.get(rvoHeaderId).size() == 1) {
                    rvoHeaderRec.Status__c = 'Credited';
                } else if(rvoHeaderIdToLICreditStatusSetMap.get(rvoHeaderId).size() > 1) {
                    rvoHeaderRec.Status__c = 'Partially Credited';
                }
            }
            rvoHeaderToUpdateList.add(rvoHeaderRec);
        }
        DMLUtility.updateSobjectList('Return_VO_Header__c', rvoHeaderToUpdateList);
    }

    private static List<Return_VO_Line_Item__c> getRVOLineItemsToCredit(String returnCRId, List<String> listToProcess) {
        if(listToProcess.isEmpty()) return null;

        String objectName = String.valueOf(Id.valueOf(listToProcess[0]).getSobjectType());
        String query = 'SELECT Id FROM Return_VO_Line_Item__c WHERE Return_CR_Line_Item__c != null AND Return_CR_Line_Item__r.Return_CR_Header__c != :returnCRId AND ';
        if(objectName == Constants.NAMESPACE + 'Return_VO_Line_Item__c') {
            query += 'Id IN :listToProcess';
        } else if(objectName == Constants.NAMESPACE + 'Return_VO_Header__c') {
            query += 'Return_VO_Header__c IN :listToProcess';
        }
        return Database.query(query);
    }

    private static List<Object> getPaginatedRecords(List<Object> recordsList, Integer fromIndex, integer toIndex) {
        List<Object> paginatedRecords = new List<Object>();
        for(Integer i = (fromIndex); i < toIndex; i++) {
            if(recordsList.size() > i){
                paginatedRecords.add(recordsList.get(i));
            }
        }
        return paginatedRecords;
    }

    private static List<Return_CR_Line_Item__c> getRCRLIList(String returnCRId, PaginationSorting pageSortAttrs) {
        String query = 'Select Name, Item_Desc__c, Return_Cost__c, Credit_Cost__c, Return_Qty__c, Part__c, Return_CR_Header__c, ' + 
                        '(SELECT Return_VO_Header__r.Name, Return_VO_Header__r.RMA__c FROM Return_VO_Line_Items__r LIMIT 1) ' + 
                        'FROM Return_CR_Line_Item__c WHERE Return_CR_Header__c = :returnCRId';
        // Order by clause
        query += ' ORDER BY ';
        if(pageSortAttrs != null) {
            for(PaginationSorting.SortAttrs sortAttr: pageSortAttrs.Sorting) {
                query += BPUtility.escapeSingleQuotes(sortAttr.FieldName) + ' ' + BPUtility.escapeSingleQuotes(sortAttr.SortDirection) + ', ';
            }
            query = query.substring(0, query.length()-2);
        } else {
            query += ' LastModifiedDate DESC';
        }
        query += ' LIMIT ' + SOQLUtil.getAvailableQueryRowsLimit();
        if(!AccessControl.ifObjectFieldIsAccessible('Return_CR_Line_Item__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        return Database.query(query);
    }

    public static String deleteReturnVendorCredit(String returnCRId){    
    	List<Return_CR_Header__c> returnCreditList = [Select Id, Status__c, (Select Id FROM Return_CR_Line_Items__r LIMIT 1), (Select Id FROM Other_Charges__r LIMIT 1) FROM Return_CR_Header__c WHERE Id =: returnCRId]; 
    	String response = 'Error';
    	if(!returnCreditList.isEmpty()) {
    		if(returnCreditList[0].Status__c == 'In Progress' && returnCreditList[0].Return_CR_Line_Items__r.isEmpty() && returnCreditList[0].Other_Charges__r.isEmpty()) {
    			DMLUtility.deleteSobjectList('Return_CR_Header__c', returnCreditList);
    			response = 'Success';
    		}
    	}
    	return response;
    }

    private static Map<String, String> rcrWrapperKeyToAPINameMap = new Map<String, String>{
                                                                                            'CreditedDate' => 'Credited_Date__c',
                                                                                            'CreditMemoNumber' => 'Credit_Memo__c'
                                                                                        };
}