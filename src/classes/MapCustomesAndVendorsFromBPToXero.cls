/** 
* Author: Richa Mittal
* Since: Feb 22, 2021
* Name: MapCustomesAndVendorsFromBPToXero 
* Description: Batch class for fetching contacts from xero and map to BP customer/vendor if exists and set accounting Id
**/
global without sharing class MapCustomesAndVendorsFromBPToXero implements Database.Batchable<Integer>, Database.AllowsCallouts, Database.Stateful {
    
    public Integer APICounter = 1;
    public Boolean recordFound = false;
    public IFW_IntegrationConfig__c ifwRec;
    
    global MapCustomesAndVendorsFromBPToXero() {
    
    }
    
    global MapCustomesAndVendorsFromBPToXero(Integer APICounter) {
        this.APICounter = APICounter;
    }
    
    global Iterable<Integer> start(Database.BatchableContext bc) {
        return new List<Integer>{APICounter};
    }
    
    global void execute(Database.batchableContext bc, List<Integer> apiCountList) {
    	if(ifwRec == null) {
    		List<IFW_IntegrationConfig__c> ifwConfigRec = [SELECT Id, Access_Token__c, Auth_Scheme__c, Bearer_Token__c, Certificate_Name__c, Certifcate_Password__c, Consumer_Key__c, 
											                  Consumer_Secret__c, Accounting_Enabled__c, Integration_Name__c, Grant_Type__c, Password__c, Username__c, Refresh_Token__c, Timeout__c, 
											                  Token_Expiry__c, Token_Type__c, Integration_Type__c, Client_Id__c, Client_Secret__c, Company_Id__c, 
	    													(Select IFW_IntegrationConfig__c, Endpoint_URL__c, HTTP_Method__c, Timeout__c FROM IFW_IntegrationConfigItems__r WHERE 
	    														HTTP_Method__c = 'GET' AND Entity_Name__c = 'Contacts') 
	    													FROM IFW_IntegrationConfig__c WHERE Integration_Name__c = 'Xero' AND Accounting_Enabled__c = true];
			
			if(ifwConfigRec.size() > 0 && ifwConfigRec[0].IFW_IntegrationConfigItems__r.size() > 0) {
				ifwRec = ifwConfigRec[0];
			}
    	}
    	if(ifwRec == null) {
    		new LogService().createErrorLog('MapCustomesAndVendorsFromBPToXero', 'execute()', 'Xero config not defined', '', null, 
                                          null, LogService.XERO);
            return;
    	}
        
        XeroResponseWrapper responseWrapper = getContactsFromXero(APICounter);
        if(responseWrapper != null && responseWrapper.Contacts != null && responseWrapper.Contacts.size() > 0) {
        	recordFound = true;
        	updateXeroAccIdInBP(responseWrapper);
        }
    }
    
    global void finish(Database.batchableContext bc) {
        APICounter++;
        if(recordFound) {
            Database.executeBatch(new MapCustomesAndVendorsFromBPToXero(APICounter));
        }
    }
    
    private XeroResponseWrapper getContactsFromXero(Integer APICounter) {
    	XeroResponseWrapper responseWrapper;
        Map<String, String> urlParamMap = new Map<String, String>{'page' => String.valueOf(APICounter)};
        HttpResponse response = BaseIntegration.performCallout(ifwRec, ifwRec.IFW_IntegrationConfigItems__r[0], null, new List<CustomHttpHeaderWrapper>(), urlParamMap);
        
        update ifwRec;
        
        if(response.getStatusCode() == 200 || response.getStatusCode() == 201) {
            responseWrapper = (XeroResponseWrapper)System.JSON.deserialize(response.getBody(), XeroResponseWrapper.class);
        } else {
        	new LogService().createErrorLog('MapCustomesAndVendorsFromBPToXero', 'getContactsFromXero()', response.getBody(), response.getStatusCode(), null, 
                                      null, LogService.XERO);
        }
        return responseWrapper;
    }
    
    private void updateXeroAccIdInBP(XeroResponseWrapper responseWrapper) {
    	Map<String, XeroContactDTO> contactNameToXeroContactRecMap = new Map<String, XeroContactDTO>();
        for(XeroContactDTO xeroContactRec : responseWrapper.Contacts) {
            contactNameToXeroContactRecMap.put((xeroContactRec.Name).toLowerCase(), xeroContactRec);
        }
        
        if(contactNameToXeroContactRecMap.size() > 0) {
        	List<Account> accList = [SELECT Id, Name, Email__c, Other_Email__c, Work_Email__c, Is_Customer__c, Is_Vendor__c, Is_Foreign_Vendor__c, Country__r.Currency_Code__c FROM Account 
        								WHERE ((Is_Customer__c = true AND Xero_Customer_Accounting_Id__c = null) OR 
        								(Is_Vendor__c = true AND Xero_Vendor_Accounting_Id__c = null)) AND (Name IN :contactNameToXeroContactRecMap.keySet())];
        	
        	Map<String, List<Account>> fullNameToListOfCustomers = new Map<String, List<Account>>();
        	Map<String, List<Account>> fullNameToListOfVendors = new Map<String, List<Account>>();
        	for(Account accRec: accList) {
        		String accName = (accRec.Name).toLowerCase();
        		if(accRec.Is_Customer__c) {
        			if(!fullNameToListOfCustomers.containsKey(accName)) {
        				fullNameToListOfCustomers.put(accName, new List<Account>());
        			}
        			fullNameToListOfCustomers.get(accName).add(accRec);
        		} else if(accRec.Is_Vendor__c) {
        			if(!fullNameToListOfVendors.containsKey(accName)) {
        				fullNameToListOfVendors.put(accName, new List<Account>());
        			}
        			fullNameToListOfVendors.get(accName).add(accRec);
        		}
        	}
        	
        	List<Account> accListToUpdate = new List<Account>();
    		accListToUpdate.addAll(mapContactFromXero('Customer', fullNameToListOfCustomers, contactNameToXeroContactRecMap));
    		accListToUpdate.addAll(mapContactFromXero('Vendor', fullNameToListOfVendors, contactNameToXeroContactRecMap));
    		if(accListToUpdate.size() > 0) {
				CustomerTriggerHelper.isForceStopTrigger = true;
	    		update accListToUpdate;
				CustomerTriggerHelper.isForceStopTrigger = false;
	    	}
        }
    }
    
    private List<Account> mapContactFromXero(String accType, Map<String, List<Account>> nameToListOfAccRecs, Map<String, XeroContactDTO> contactNameToXeroContactRecMap) {
    	List<Account> accListToUpdate = new List<Account>();
		String homeCurr = AccountingUtil.getHomeCurrency();
    	for(String name: nameToListOfAccRecs.keySet()) {
    		if(contactNameToXeroContactRecMap.containsKey(name)) {
    			XeroContactDTO xeroContactRec = contactNameToXeroContactRecMap.get(name);
    			if((accType == 'Customer' && (xeroContactRec.IsCustomer || !xeroContactRec.IsSupplier)) 
    				|| (accType == 'Vendor' && (xeroContactRec.IsSupplier || !xeroContactRec.IsCustomer))) {
    				if(nameToListOfAccRecs.get(name).size() == 1) {
    					if(accType == 'Customer') {
    						accListToUpdate.add(new Account(Id = nameToListOfAccRecs.get(name)[0].Id, Xero_Customer_Accounting_Id__c = xeroContactRec.ContactID));
    					} else if(accType == 'Vendor') {
							setMatchedVendorAccIdInBP(nameToListOfAccRecs.get(name)[0], xeroContactRec, accListToUpdate);
    					}
						contactNameToXeroContactRecMap.remove(name);
	    			} else {
	    				List<Account> matchedAccList = new List<Account>();
	    				for(Account accRec: nameToListOfAccRecs.get(name)) {
	    					Set<String> emailStrSet = new Set<String>();
        					if(accType == 'Customer' && String.isNotBlank(nameToListOfAccRecs.get(name)[0].Email__c)) {
        						emailStrSet.add(nameToListOfAccRecs.get(name)[0].Email__c);	
        					}
        					if(String.isNotBlank(nameToListOfAccRecs.get(name)[0].Other_Email__c)) {
        						emailStrSet.add(nameToListOfAccRecs.get(name)[0].Other_Email__c);	
        					}
        					if(String.isNotBlank(nameToListOfAccRecs.get(name)[0].Work_Email__c)) {
        						emailStrSet.add(nameToListOfAccRecs.get(name)[0].Work_Email__c);	
        					}
        					
        					if(String.isBlank(xeroContactRec.EmailAddress) && emailStrSet.size() == 0) {
        						matchedAccList.add(accRec);
        					} else if(String.isNotBlank(xeroContactRec.EmailAddress) && emailStrSet.contains(xeroContactRec.EmailAddress)) {
        						matchedAccList.add(accRec);
        					}
	    				}
	    				if(matchedAccList.size() == 1) {
	    					if(accType == 'Customer') {
	    						accListToUpdate.add(new Account(Id = matchedAccList[0].Id, Xero_Customer_Accounting_Id__c = xeroContactRec.ContactID));
	    					} else if(accType == 'Vendor') {
								setMatchedVendorAccIdInBP(matchedAccList[0], xeroContactRec, accListToUpdate);
	    					}
							contactNameToXeroContactRecMap.remove(name);
	    				}
    				}
    			}
    		}
    	}
    	return accListToUpdate;
    }

	private void setMatchedVendorAccIdInBP(Account matchedAcc, XeroContactDTO xeroContactRec, List<Account> accListToUpdate) {
		String homeCurr = AccountingUtil.getHomeCurrency();
		Account accRecToUpdate;
		if(String.isBlank(homeCurr)) {
			accRecToUpdate = new Account(Id = matchedAcc.Id, Xero_Vendor_Accounting_Id__c = xeroContactRec.ContactID);
		} else {
			if((String.isBlank(xeroContactRec.DefaultCurrency) || (homeCurr == xeroContactRec.DefaultCurrency)) && 
				!matchedAcc.Is_Foreign_Vendor__c) {
				accRecToUpdate = new Account(Id = matchedAcc.Id, Xero_Vendor_Accounting_Id__c = xeroContactRec.ContactID);
			} else if(String.isNotBlank(xeroContactRec.DefaultCurrency) && matchedAcc.Is_Foreign_Vendor__c && 
						matchedAcc.Country__r.Currency_Code__c == xeroContactRec.DefaultCurrency) {
				accRecToUpdate = new Account(Id = matchedAcc.Id, Xero_Vendor_Accounting_Id__c = xeroContactRec.ContactID);
			}
		}
		if(accRecToUpdate != null) accListToUpdate.add(accRecToUpdate);
	}
    
    public class XeroResponseWrapper {
        public List<XeroContactDTO>  Contacts;
    }
    
    public class XeroContactDTO {
        public String Name;
	    public String ContactID;
	    public String EmailAddress;
	    public Boolean IsCustomer;
	    public Boolean IsSupplier;
		public String DefaultCurrency;

    }
}