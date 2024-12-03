/**
 * Author: Richa Mittal
 * Since: August 12, 2016
 * Name: GlobalSearchResultsWrapper
 * Description: Class is used for the Creating Json For Search Results
**/
public without sharing class GlobalSearchResultsWrapper {
    public Integer TotalRecords;
    public List<GlobalSearchRecordWrapper> searchRecords;
    
    public GlobalSearchResultsWrapper(Integer TotalRecords, List<Sobject> searchedObjList){
        this.TotalRecords = TotalRecords;
        this.searchRecords = new List<GlobalSearchRecordWrapper>();
        for(Sobject sObj : searchedObjList) {
            this.searchRecords.add(new GlobalSearchRecordWrapper(sObj, null));
        }
    }

    public GlobalSearchResultsWrapper(Integer TotalRecords, List<Sobject> searchedObjList, Set<String> objectNameSetToSearch) {
    	this.TotalRecords = TotalRecords;
        this.searchRecords = new List<GlobalSearchRecordWrapper>();
        for(Sobject sObj : searchedObjList) {
            this.searchRecords.add(new GlobalSearchRecordWrapper(sObj, objectNameSetToSearch));
        }
    }
    
    public class GlobalSearchRecordWrapper{
        public String Id;
        public Integer Type;
        public String ObjectName; 
        public String AdditionalInfo1;
        public String AdditionalInfo2;
        public String AdditionalInfo3;
        public String AdditionalInfo4;
        public String AdditionalInfo5;
        public String AdditionalInfoLabel1;
        public String AdditionalInfoLabel2;
        public String AdditionalInfoLabel3;
        public String AdditionalInfoLabel4;
        public String AdditionalInfoLabel5;
        public String ItemName;
        public String LastModifiedDate;
        
        /**
         * Name:GlobalSearchResultsWrapper 
         * Description: Constructor
        **/
        public GlobalSearchRecordWrapper(Sobject searchedObj, Set<String> objectNameSetToSearch) {
            String objName = String.valueOf(searchedObj.getSObjectType());
            if(objName == 'Account') {
                if(objectNameSetToSearch != null) {
            		if(objectNameSetToSearch.contains('Customers')) {
            			this.Type = 1;
	                    this.ObjectName = 'Customer';
	            	} else if(objectNameSetToSearch.contains('Vendors')) {
	            		this.Type = 2;
	                    this.ObjectName = 'Vendor';
	            	}
            	} else {
            		if(((searchedObj.get(Constants.NAMESPACE +'Is_Customer__c') != null) ? String.valueOf(searchedObj.get(Constants.NAMESPACE +'Is_Customer__c')) : null) == 'true') {
	                    this.Type = 1;
	                    this.ObjectName = 'Customer';
	                } else if(((searchedObj.get(Constants.NAMESPACE +'Is_Vendor__c') != null) ? String.valueOf(searchedObj.get(Constants.NAMESPACE +'Is_Vendor__c')) : null) == 'true') {
	                    this.Type = 2;
	                    this.ObjectName = 'Vendor';
	                }
            	}
                
                this.Id = String.valueOf(searchedObj.get('Id'));
                this.ItemName = (searchedObj.get('Name') != null) ? String.valueOf(searchedObj.get('Name')) : '';
                this.AdditionalInfoLabel1 = 'Email';
                this.AdditionalInfoLabel2 = 'Phone';
                
                if(searchedObj.get(Constants.NAMESPACE +'Preferred_Email__c') != '' && searchedObj.get(Constants.NAMESPACE +'Preferred_Email__c') != null) {
                    this.AdditionalInfo1 = String.valueOf(searchedObj.get(Constants.NAMESPACE +'Preferred_Email__c'));
                } else if(searchedObj.get(Constants.NAMESPACE +'Work_Email__c') != '' && searchedObj.get(Constants.NAMESPACE +'Work_Email__c') != null) {
                    this.AdditionalInfo1 = String.valueOf(searchedObj.get(Constants.NAMESPACE +'Work_Email__c'));
                } else {
                    if(((searchedObj.get(Constants.NAMESPACE +'Is_Customer__c') != null) ? String.valueOf(searchedObj.get(Constants.NAMESPACE +'Is_Customer__c')) : null) == 'true') {
                        if(searchedObj.get(Constants.NAMESPACE +'Email__c') != '' && searchedObj.get(Constants.NAMESPACE +'Email__c') != null) {
                            this.AdditionalInfo1 = String.valueOf(searchedObj.get(Constants.NAMESPACE +'Email__c'));
                        } else if(searchedObj.get(Constants.NAMESPACE +'Other_Email__c') != '' && searchedObj.get(Constants.NAMESPACE +'Other_Email__c') != null) {
                            this.AdditionalInfo1 = String.valueOf(searchedObj.get(Constants.NAMESPACE +'Other_Email__c'));
                        }
                    } else if(((searchedObj.get(Constants.NAMESPACE +'Is_Vendor__c') != null) ? String.valueOf(searchedObj.get(Constants.NAMESPACE +'Is_Vendor__c')) : null) == 'true') {
                        if(searchedObj.get(Constants.NAMESPACE +'Other_Email__c') != '' && searchedObj.get(Constants.NAMESPACE +'Other_Email__c') != null) {
                            this.AdditionalInfo1 = String.valueOf(searchedObj.get(Constants.NAMESPACE +'Other_Email__c'));
                        }
                    }
                } 
                
                if(searchedObj.get(Constants.NAMESPACE +'Preferred_Phone__c') != '' && searchedObj.get(Constants.NAMESPACE +'Preferred_Phone__c') != null) {
                    this.AdditionalInfo2 = String.valueOf(searchedObj.get(Constants.NAMESPACE +'Formatted_Preferred_Phone__c'));
                } else if(searchedObj.get(Constants.NAMESPACE +'Work_Number__c') != '' && searchedObj.get(Constants.NAMESPACE +'Work_Number__c') != null) {
                    this.AdditionalInfo2 = String.valueOf(searchedObj.get(Constants.NAMESPACE +'Formatted_Work_Number__c'));
                } else {
                    if(((searchedObj.get(Constants.NAMESPACE +'Is_Customer__c') != null) ? String.valueOf(searchedObj.get(Constants.NAMESPACE +'Is_Customer__c')) : null) == 'true') { 
                        if(searchedObj.get(Constants.NAMESPACE +'Home_Number__c') != '' && searchedObj.get(Constants.NAMESPACE +'Home_Number__c') != null) {
                            this.AdditionalInfo2 = String.valueOf(searchedObj.get(Constants.NAMESPACE +'Formatted_Home_number__c'));
                        } else if(searchedObj.get(Constants.NAMESPACE +'Mobile__c') != '' && searchedObj.get(Constants.NAMESPACE +'Mobile__c') != null) {
                            this.AdditionalInfo2 = String.valueOf(searchedObj.get(Constants.NAMESPACE +'Formatted_Mobile_Number__c'));
                        }
                    } else if(((searchedObj.get(Constants.NAMESPACE +'Is_Vendor__c') != null) ? String.valueOf(searchedObj.get(Constants.NAMESPACE +'Is_Vendor__c')) : null) == 'true') {
                        if(searchedObj.get(Constants.NAMESPACE +'Mobile__c') != '' && searchedObj.get(Constants.NAMESPACE +'Mobile__c') != null) {
                            this.AdditionalInfo2 = String.valueOf(searchedObj.get(Constants.NAMESPACE +'Formatted_Mobile_Number__c'));
                        }
                    }
                }
                
                Account accRec = (Account) searchedObj;
                this.AdditionalInfoLabel3 = 'Mobile';
                this.AdditionalInfoLabel4 = 'BillingAddress';
                if(accRec.Formatted_Mobile_Number__c != null) {
                    this.AdditionalInfo3 = String.valueOf(accRec.Formatted_Mobile_Number__c);
                }
                List<String> bsList = ((accRec.BillingStreet == null ) ? '' : accRec.BillingStreet).split('\n');
                String billingStreet1 = (bsList.size() > 0) ? bsList[0] : '';
                String billingStreet2 = (bsList.size() > 1) ? bsList[1] : '';

                List<String> addressPartList = new List<String>();
                if(String.isNotBlank(billingStreet1)) addressPartList.add(billingStreet1);
                if(String.isNotBlank(billingStreet2)) addressPartList.add(billingStreet2);
                if(String.isNotBlank(accRec.BillingCity)) addressPartList.add(accRec.BillingCity);
                if(String.isNotBlank(accRec.BillingState)) addressPartList.add(accRec.BillingState);
                if(String.isNotBlank(accRec.BillingCountry)) addressPartList.add(accRec.BillingCountry);
                if(String.isNotBlank(accRec.BillingPostalCode)) addressPartList.add(accRec.BillingPostalCode);
                this.AdditionalInfo4 = String.join(addressPartList, ', ');
                
            } else if(objName == 'Contact') {
                this.Id = String.valueOf(searchedObj.getSObject('Account').get('Id'));
                this.ObjectName = 'Contact';
                if(Boolean.valueOf(searchedObj.getSObject('Account').get(Constants.NAMESPACE +'Is_Customer__c'))) {
                    this.Type = 1;
                    this.AdditionalInfoLabel3 = 'Customer';
                } else if(Boolean.valueOf(searchedObj.getSObject('Account').get(Constants.NAMESPACE +'Is_Vendor__c'))) {
                    this.Type = 2;
                    this.AdditionalInfoLabel3 = 'Vendor';
                }
                this.ItemName = (searchedObj.get('LastName') != null) ? String.valueOf(searchedObj.get('LastName')) : '';
	    		this.AdditionalInfoLabel1 = 'Email';
	    		this.AdditionalInfo1 = (searchedObj.get('Email') != null) ? String.valueOf(searchedObj.get('Email')) : null;
	    		this.AdditionalInfoLabel2 = 'Phone';
	    		this.AdditionalInfo2 = (searchedObj.get('Phone') != null) ? String.valueOf(searchedObj.get('Phone')) : null;
	    		this.AdditionalInfo3 = (searchedObj.getSObject('Account').get('Name') != null) ? String.valueOf(searchedObj.getSObject('Account').get('Name')) : null;
            } else if(objName == Constants.NAMESPACE + 'Part__c') {
                this.Id = String.valueOf(searchedObj.get('Id'));
                this.Type = 3;
                this.ObjectName = 'Part';
                this.ItemName = ((searchedObj.get(Constants.NAMESPACE +'Part_Number__c') != null) ? String.valueOf(searchedObj.get(Constants.NAMESPACE +'Part_Number__c')) : '') + ((searchedObj.get(Constants.NAMESPACE +'Part_Number__c') != null) && (searchedObj.get(Constants.NAMESPACE +'Description__c') != null) ? ' - ' : '') + ((searchedObj.get(Constants.NAMESPACE +'Description__c') != null) ? String.valueOf(searchedObj.get(Constants.NAMESPACE +'Description__c')) : '');
	    		this.AdditionalInfo2 = (searchedObj.get(Constants.NAMESPACE +'AvailableParts__c') != null) ? String.valueOf(searchedObj.get(Constants.NAMESPACE +'AvailableParts__c')) : null;
	    		this.AdditionalInfoLabel2 = 'available';
	    		this.AdditionalInfo1 = (searchedObj.getSObject(Constants.NAMESPACE +'Vendor__r').get('Name') != null) ? String.valueOf(searchedObj.getSObject(Constants.NAMESPACE +'Vendor__r').get('Name')) : null;
	    		this.AdditionalInfoLabel1 = 'Vendor Name';
	    		this.AdditionalInfo3 = String.join(LocationManagementService.getLocationsList((Part__c)searchedObj), ',');
	    		this.AdditionalInfoLabel3 = 'Location';
                this.AdditionalInfoLabel4 = 'RetailPrice';
                this.AdditionalInfo4 = ((searchedObj.get(Constants.NAMESPACE +'Retail_Price__c') != null) ? ((Decimal)searchedObj.get(Constants.NAMESPACE +'Retail_Price__c') < 0 ? '($'+ String.valueOf((Decimal)searchedObj.get(Constants.NAMESPACE +'Retail_Price__c') * -1) + ')' : '$'+ String.valueOf(searchedObj.get(Constants.NAMESPACE +'Retail_Price__c'))) : null);
	    		this.AdditionalInfoLabel5 = 'QtyOnOrder';
                this.AdditionalInfo5 = (searchedObj.get(Constants.NAMESPACE +'Qty_On_Order__c') != null) ? String.valueOf(searchedObj.get(Constants.NAMESPACE +'Qty_On_Order__c')) : null;
	    		
            } else if(objName == Constants.NAMESPACE + 'Kit_Header__c') {
                this.Id = String.valueOf(searchedObj.get('Id'));
                this.Type = 4;
                this.ItemName = ((searchedObj.get(Constants.NAMESPACE +'Code__c') != null) ? String.valueOf(searchedObj.get(Constants.NAMESPACE +'Code__c')) : '') + ((searchedObj.get(Constants.NAMESPACE +'Code__c') != null) && (searchedObj.get(Constants.NAMESPACE +'Description__c') != null) ? ' - ' : '') + ((searchedObj.get(Constants.NAMESPACE +'Description__c') != null) ? String.valueOf(searchedObj.get(Constants.NAMESPACE +'Description__c')) : '');
                if(((searchedObj.get(Constants.NAMESPACE +'Service_Kit__c') != null) ? String.valueOf(searchedObj.get(Constants.NAMESPACE +'Service_Kit__c')) : null) == 'true') {
                    this.AdditionalInfo1 = 'Service';
                    this.ObjectName = 'Service Kit';
                } else {
                    this.AdditionalInfo1 = 'General';
                    this.ObjectName = 'Kit';
                }
                this.AdditionalInfoLabel1 = 'Type';

                this.AdditionalInfoLabel2 = 'Price';
                this.AdditionalInfo2 = ((searchedObj.get(Constants.NAMESPACE +'Fixed_Price__c') != null) ? ((Decimal)searchedObj.get(Constants.NAMESPACE +'Fixed_Price__c') < 0 ? '($'+ String.valueOf((Decimal)searchedObj.get(Constants.NAMESPACE +'Fixed_Price__c') * -1) + ')' : '$'+ String.valueOf(searchedObj.get(Constants.NAMESPACE +'Fixed_Price__c'))) : null);
	    		
            } else if(objName == Constants.NAMESPACE + 'Fee__c') {
                this.Id = String.valueOf(searchedObj.get('Id'));
                this.Type = 5;
                this.ObjectName = 'Fee';
                this.ItemName = ((searchedObj.get(Constants.NAMESPACE +'Code__c') != null) ? String.valueOf(searchedObj.get(Constants.NAMESPACE +'Code__c')) : '') + ((searchedObj.get(Constants.NAMESPACE +'Code__c') != null) && (searchedObj.get(Constants.NAMESPACE +'Description__c') != null) ? ' - ' : '') + ((searchedObj.get(Constants.NAMESPACE +'Description__c') != null) ? String.valueOf(searchedObj.get(Constants.NAMESPACE +'Description__c')) : '');
                this.AdditionalInfo1 = ((searchedObj.get(Constants.NAMESPACE +'Price__c') != null) ? ((Decimal)searchedObj.get(Constants.NAMESPACE +'Price__c') < 0 ? '($'+ String.valueOf((Decimal)searchedObj.get(Constants.NAMESPACE +'Price__c') * -1) + ')' : '$'+ String.valueOf(searchedObj.get(Constants.NAMESPACE +'Price__c'))) : null);
                this.AdditionalInfoLabel1 = 'Price';
                this.AdditionalInfoLabel2 = 'FeeType';
                this.AdditionalInfo2 = (searchedObj.get(Constants.NAMESPACE +'Type__c') != null) ? String.valueOf(searchedObj.get(Constants.NAMESPACE +'Type__c')) : '';
	    		
            } else if(objName == Constants.NAMESPACE + 'Labour_Code__c') {
                this.Id = String.valueOf(searchedObj.get('Id'));
                this.Type = 6;
                this.ObjectName = 'Labor Code';
                this.ItemName = ((searchedObj.get(Constants.NAMESPACE +'Code__c') != null) ? String.valueOf(searchedObj.get(Constants.NAMESPACE +'Code__c')) : '') + ((searchedObj.get(Constants.NAMESPACE +'Code__c') != null) && (searchedObj.get(Constants.NAMESPACE +'Description__c') != null) ? ' - ' : '') + ((searchedObj.get(Constants.NAMESPACE +'Description__c') != null) ? String.valueOf(searchedObj.get(Constants.NAMESPACE +'Description__c')) : '');
                this.AdditionalInfo1 = (searchedObj.get(Constants.NAMESPACE +'Hours__c') != null) ? String.valueOf(searchedObj.get(Constants.NAMESPACE +'Hours__c')) : null;
                this.AdditionalInfoLabel1 = 'Hours';
                this.AdditionalInfoLabel2 = 'Rate';
                this.AdditionalInfo2 = ((searchedObj.get(Constants.NAMESPACE +'Rate__c') != null) ? ((Decimal)searchedObj.get(Constants.NAMESPACE +'Rate__c') < 0 ? '($'+ String.valueOf((Decimal)searchedObj.get(Constants.NAMESPACE +'Rate__c') * -1) + ')' : '$'+ String.valueOf(searchedObj.get(Constants.NAMESPACE +'Rate__c'))) : null);
	    		
            } else if(objName == 'User') {
                this.Id = String.valueOf(searchedObj.get('Id'));
                this.Type = 7;
                this.ObjectName = 'User';
                this.ItemName = (searchedObj.get('Name') != null) ? String.valueOf(searchedObj.get('Name')) : '';
                this.AdditionalInfo1 = (searchedObj.get('Email') != null) ? String.valueOf(searchedObj.get('Email')) : null;
                this.AdditionalInfo2 = (searchedObj.get('Phone') != null) ? String.valueOf(searchedObj.get('Phone')) : null;
                this.AdditionalInfoLabel1 = 'Email';
                this.AdditionalInfoLabel2 = 'Phone';
            } else if(objName == Constants.NAMESPACE + 'CO_Header__c') {
                this.Id = String.valueOf(searchedObj.get('Id'));
                this.Type = 8;
                this.ObjectName = 'Customer Order';
                this.ItemName = (searchedObj.get('Name') != null) ? String.valueOf(searchedObj.get('Name')) : '';
                this.AdditionalInfo1 = (searchedObj.get(Constants.NAMESPACE +'Customer_Name__c') != null) ? String.valueOf(searchedObj.get(Constants.NAMESPACE +'Customer_Name__c')) : null;
                Decimal DealTotal = (searchedObj.get(Constants.NAMESPACE + 'Deal_Header_Total__c') != null) ? (Decimal)(searchedObj.get(Constants.NAMESPACE + 'Deal_Header_Total__c')) : 0.00;
                this.AdditionalInfo2 = ((Decimal)searchedObj.get(Constants.NAMESPACE + 'NumberOfDeals__c') > 0) ? (DealTotal < 0 ? '($'+ String.valueOf(DealTotal * -1) + ')' : '$'+ String.valueOf(DealTotal)) : null;
                this.AdditionalInfoLabel2 = 'Deal';
                Decimal SOTotalWithTax = ((searchedObj.get(Constants.NAMESPACE + 'Service_Order_Subtotal__c') != null) ? (Decimal)(searchedObj.get(Constants.NAMESPACE + 'Service_Order_Subtotal__c')) : 0.00).setScale(2, RoundingMode.HALF_UP);
                
                this.AdditionalInfo3 = ((Decimal)searchedObj.get(Constants.NAMESPACE + 'TotalNumberOfSOHeader__c') > 0) ? (SOTotalWithTax < 0 ? '($'+ String.valueOf(SOTotalWithTax * -1) + ')' : '$'+ String.valueOf(SOTotalWithTax)) : null;
                this.AdditionalInfoLabel3 = 'Service';
                
                Decimal MerchTotal = (searchedObj.get(Constants.NAMESPACE + 'Merchandise_Total__c') != null) ? ((Decimal)searchedObj.get(Constants.NAMESPACE + 'Merchandise_Total__c')).setScale(2, RoundingMode.HALF_UP) : 0.00;
                this.AdditionalInfo4 = ( ((Decimal)searchedObj.get(Constants.NAMESPACE + 'TotalNumberOfCOLI__c') > 0) && 
                                          ((String.valueOf(searchedObj.get(Constants.NAMESPACE + 'Selling_Group__c')) == 'Part Sale') ||
                                          (String.valueOf(searchedObj.get(Constants.NAMESPACE + 'Selling_Group__c')) == 'Cash Sale') ||
                                            ((String.valueOf(searchedObj.get(Constants.NAMESPACE + 'Selling_Group__c')) != 'Internal Service')))) ? 
                                        (MerchTotal < 0 ? '($'+ String.valueOf(MerchTotal * -1) + ')' : '$'+ String.valueOf(MerchTotal)) : null;
                
                this.AdditionalInfoLabel4 = 'Merchandise';
                Datetime lastModifiedDt = BPUtility.getLastModifiedDate(searchedObj);
                this.LastModifiedDate = (lastModifiedDt != null) ? lastModifiedDt.format('MMMM d,  yyyy') : '';
                this.AdditionalInfo5 = (searchedObj.get(Constants.NAMESPACE + 'Order_status__c') != null) ? String.valueOf(searchedObj.get(Constants.NAMESPACE + 'Order_status__c')) : '';
                
            } else if(objName == Constants.NAMESPACE + 'CO_Invoice_Header__c') {
                this.Id = (searchedObj.getSobject(Constants.NAMESPACE +'CO_Header__r') != null && searchedObj.getSobject(Constants.NAMESPACE +'CO_Header__r').get('Id') != null) ? String.valueOf(searchedObj.getSobject(Constants.NAMESPACE +'CO_Header__r').get('Id')) : null;
                this.Type = 9;
                this.ObjectName = 'Customer Invoice';
                this.ItemName = (searchedObj.get(Constants.NAMESPACE + 'Invoice_Number__c') != null) ? String.valueOf(searchedObj.get(Constants.NAMESPACE + 'Invoice_Number__c')) : '';
                this.AdditionalInfo1 = (searchedObj.getSobject(Constants.NAMESPACE +'CO_Header__r') != null && searchedObj.getSobject(Constants.NAMESPACE +'CO_Header__r').get('Customer_Name__c') != null) ? String.valueOf(searchedObj.getSObject(Constants.NAMESPACE +'CO_Header__r').get('Customer_Name__c')) : null;
                this.AdditionalInfoLabel1 = 'Customer Name';
                this.AdditionalInfo2 = (searchedObj.get(Constants.NAMESPACE +'Total__c') != null) ? String.valueOf(searchedObj.get(Constants.NAMESPACE +'Total__c')) : '';
                this.AdditionalInfoLabel2 = 'Total';
                this.AdditionalInfoLabel3 = 'InvoiceDate';
                this.AdditionalInfo3 = (searchedObj.get(Constants.NAMESPACE +'Invoice_Date__c') != null) ? ((DateTime)searchedObj.get(Constants.NAMESPACE +'Invoice_Date__c')).format('MMMM d,  yyyy') : '';
                  
            } else if(objName == Constants.NAMESPACE + 'Vendor_Order_Header__c' || objName == Constants.NAMESPACE + 'Return_VO_Header__c') {
                this.Id = String.valueOf(searchedObj.get('Id'));
                if(objName == Constants.NAMESPACE + 'Return_VO_Header__c') {
                    this.Type = 22;
                    this.ObjectName = 'Vendor Return';
                    
                    this.AdditionalInfoLabel2 = 'Total';
                    this.AdditionalInfo2 = ((searchedObj.get(Constants.NAMESPACE +'Return_Total__c') != null) ? String.valueOf((Decimal)searchedObj.get(Constants.NAMESPACE +'Return_Total__c') * -1) : null);
                    this.AdditionalInfo5 = (searchedObj.get(Constants.NAMESPACE +'RMA__c') != null) ? String.valueOf(searchedObj.get(Constants.NAMESPACE +'RMA__c')) : '';
                    this.AdditionalInfoLabel5 = 'RMA#';
                    this.AdditionalInfoLabel3 = 'Reason';
                    this.AdditionalInfo3 = (searchedObj.get(Constants.NAMESPACE + 'Reason__c') != null) ? String.valueOf(searchedObj.get(Constants.NAMESPACE + 'Reason__c')) : null;  
                } else {
                    this.Type = 10;
                    this.ObjectName = 'Vendor Order';
                    
                    this.AdditionalInfoLabel2 = 'PO Type';
                    this.AdditionalInfo2 = (searchedObj.getSobject(Constants.NAMESPACE +'Purchase_Order_Type__r') != null && searchedObj.getSobject(Constants.NAMESPACE +'Purchase_Order_Type__r').get('Code__c') != null) ? String.valueOf(searchedObj.getSObject(Constants.NAMESPACE +'Purchase_Order_Type__r').get('Code__c')) : null;                
                    this.AdditionalInfoLabel3 = 'Total';
                    this.AdditionalInfo3 = (searchedObj.get(Constants.NAMESPACE +'Total__c') != null) ? String.valueOf(searchedObj.get(Constants.NAMESPACE +'Total__c')) : '';
                    Datetime lastModifiedDt = BPUtility.getLastModifiedDate(searchedObj);
                    this.LastModifiedDate = (lastModifiedDt != null) ? lastModifiedDt.format('MMMM d,  yyyy') : '';
                    this.AdditionalInfo5 = (searchedObj.get(Constants.NAMESPACE +'Ordered_Date__c') != null) ? ((DateTime)searchedObj.get(Constants.NAMESPACE +'Ordered_Date__c')).format('MMMM d,  yyyy') : '';
                    this.AdditionalInfoLabel5 = 'OrderedDate';
                }
                this.ItemName = (searchedObj.get('Name') != null) ? String.valueOf(searchedObj.get('Name')) : '';
                this.AdditionalInfo1 = (searchedObj.getSobject(Constants.NAMESPACE +'Vendor__r') != null && searchedObj.getSobject(Constants.NAMESPACE +'Vendor__r').get('Name') != null) ? String.valueOf(searchedObj.getSObject(Constants.NAMESPACE +'Vendor__r').get('Name')) : null;
                this.AdditionalInfoLabel1 = 'Vendor Name';
                this.AdditionalInfo4 = (searchedObj.get(Constants.NAMESPACE +'Status__c') != null) ? String.valueOf(searchedObj.get(Constants.NAMESPACE +'Status__c')) : '';
                this.AdditionalInfoLabel4 = 'Status';
                this.LastModifiedDate = (searchedObj.get('LastModifiedDate') != null) ? ((DateTime)searchedObj.get('LastModifiedDate')).format('MMMM d,  yyyy') : '';
                
            } else if(objName == Constants.NAMESPACE + 'Vendor_Receiving_Header__c') {
                this.Id = String.valueOf(searchedObj.get('Id'));
                this.Type = 11;
                this.ObjectName = 'Vendor Receiving';
                this.ItemName = (searchedObj.get('Name') != null) ? String.valueOf(searchedObj.get('Name')) : '';
                this.AdditionalInfo1 = (searchedObj.getSobject(Constants.NAMESPACE +'Vendor__r') != null && searchedObj.getSobject(Constants.NAMESPACE +'Vendor__r').get('Name') != null) ? String.valueOf(searchedObj.getSObject(Constants.NAMESPACE +'Vendor__r').get('Name')) : null;
                this.AdditionalInfoLabel1 = 'Vendor Name';
                
                this.AdditionalInfoLabel2 = 'Packaging Slip Number';
                this.AdditionalInfo2 = (searchedObj.get(Constants.NAMESPACE +'Packing_Slip_Number__c') != null) ? String.valueOf(searchedObj.get(Constants.NAMESPACE +'Packing_Slip_Number__c')) : '';
                this.AdditionalInfoLabel3 = 'Total';
                this.AdditionalInfo3 = (searchedObj.get(Constants.NAMESPACE +'Receiving_Total__c') != null) ? String.valueOf(searchedObj.get(Constants.NAMESPACE +'Receiving_Total__c')) : '';
                Datetime lastModifiedDt = BPUtility.getLastModifiedDate(searchedObj);
                this.LastModifiedDate = (lastModifiedDt != null) ? lastModifiedDt.format('MMMM d,  yyyy') : '';
                this.AdditionalInfoLabel4 = 'Status';
                this.AdditionalInfo4 = (searchedObj.get(Constants.NAMESPACE +'Status__c') != null) ? String.valueOf(searchedObj.get(Constants.NAMESPACE +'Status__c')) : '';
                
            } else if(objName == Constants.NAMESPACE + 'Vendor_Invoicing_Header__c') {
                this.Id = String.valueOf(searchedObj.get('Id'));
                this.Type = 12;
                this.ObjectName = 'Vendor Invoice';
                this.ItemName = (searchedObj.get('Name') != null) ? String.valueOf(searchedObj.get('Name')) : '';
                this.AdditionalInfo1 = (searchedObj.getSobject(Constants.NAMESPACE +'Vendor__r') != null && searchedObj.getSobject(Constants.NAMESPACE +'Vendor__r').get('Name') != null) ? String.valueOf(searchedObj.getSObject(Constants.NAMESPACE +'Vendor__r').get('Name')) : null;
                this.AdditionalInfoLabel1 = 'Vendor Name';
                this.AdditionalInfo2 = (searchedObj.get(Constants.NAMESPACE +'Total_With_Tax__c') != null) ? String.valueOf(searchedObj.get(Constants.NAMESPACE +'Total_With_Tax__c')) : '';
                this.AdditionalInfoLabel2 = 'Total';
                this.AdditionalInfo3 = (searchedObj.get(Constants.NAMESPACE +'Status__c') != null) ? String.valueOf(searchedObj.get(Constants.NAMESPACE +'Status__c')) : '';
                this.AdditionalInfoLabel3 = 'Status';
                this.AdditionalInfo4 = (searchedObj.get(Constants.NAMESPACE +'Invoice_Number__c') != null) ? String.valueOf(searchedObj.get(Constants.NAMESPACE +'Invoice_Number__c')) : '';
                this.AdditionalInfoLabel4 = 'Invoice#';
                
            } else if(objName == Constants.NAMESPACE + 'Category__c') {
                this.Id = String.valueOf(searchedObj.get('Id'));
                this.Type = 13;
                this.ObjectName = 'Item Category';
                this.ItemName = ((searchedObj.get('Name') != null) ? String.valueOf(searchedObj.get('Name')) : '') + ((searchedObj.get('Name') != null) && (searchedObj.get(Constants.NAMESPACE +'Description__c') != null) ? ' - ' : '') + ((searchedObj.get(Constants.NAMESPACE +'Description__c') != null) ? String.valueOf(searchedObj.get(Constants.NAMESPACE +'Description__c')) : '');
                this.AdditionalInfo1 = (searchedObj.get(Constants.NAMESPACE +'Type__c') != null) ? String.valueOf(searchedObj.get(Constants.NAMESPACE +'Type__c')) : null;
                this.AdditionalInfoLabel1 = 'Category Type';
                
            } else if(objName == Constants.NAMESPACE + 'Price_Level__c') {
                this.Id = String.valueOf(searchedObj.get('Id'));
                this.Type = 14;
                this.ObjectName = 'Price Level';
                this.ItemName = (searchedObj.get(Constants.NAMESPACE +'Name__c') != null) ? String.valueOf(searchedObj.get(Constants.NAMESPACE +'Name__c')) : '';
                this.AdditionalInfo1 = ((searchedObj.get(Constants.NAMESPACE +'Discount_Markup__c') != null) ? String.valueOf(searchedObj.get(Constants.NAMESPACE +'Discount_Markup__c')) : null)+ '%';
                this.AdditionalInfoLabel1 = 'Discount Markup';
                
            } else if(objName == Constants.NAMESPACE + 'Sales_Tax__c') {
                this.Id = String.valueOf(searchedObj.get('Id'));
                this.Type = 15;
                this.ObjectName = 'Sales Tax';
                this.ItemName = (searchedObj.get(Constants.NAMESPACE +'Name__c') != null) ? String.valueOf(searchedObj.get(Constants.NAMESPACE +'Name__c')) : '';
                this.AdditionalInfo1 = ((searchedObj.get(Constants.NAMESPACE +'Rate__c') != null) ? String.valueOf(searchedObj.get(Constants.NAMESPACE +'Rate__c')) : null)+ '%';
                this.AdditionalInfoLabel1 = 'Rate';
                
            } else if(objName == Constants.NAMESPACE + 'Product__c') {
                this.Id = (searchedObj.getSobject(Constants.NAMESPACE +'Vendor__r') != null && searchedObj.getSobject(Constants.NAMESPACE +'Vendor__r').get('Id') != null) ? String.valueOf(searchedObj.getSObject(Constants.NAMESPACE +'Vendor__r').get('Id')) : null;
                String productType = (searchedObj.get(Constants.NAMESPACE +'Type__c') != null) ? String.valueOf(searchedObj.get(Constants.NAMESPACE +'Type__c')) : '';
                if(productType == Constants.SUBLET) {
                    this.Type = 16;
                    this.ObjectName = Constants.SUBLET;
                } else if(productType == Constants.FINANCING_PRODUCT) {
                    this.Type = 19;
                    this.ObjectName = Constants.FINANCING_PRODUCT;
                } else if(productType == Constants.DEAL_PRODUCT) {
                    this.Type = 20;
                    this.ObjectName = Constants.DEAL_PRODUCT;
                } else if(productType == Constants.WARRANTY_PLAN) {
                    this.Type = 21;
                    this.ObjectName = Constants.WARRANTY_PLAN;
                }
                this.ItemName = ((searchedObj.get(Constants.NAMESPACE +'Code__c') != null) ? String.valueOf(searchedObj.get(Constants.NAMESPACE +'Code__c')) : '') + ((searchedObj.get(Constants.NAMESPACE +'Code__c') != null) && (searchedObj.get(Constants.NAMESPACE +'Description__c') != null) ? ' - ' : '') + ((searchedObj.get(Constants.NAMESPACE +'Description__c') != null) ? String.valueOf(searchedObj.get(Constants.NAMESPACE +'Description__c')) : '');
                this.AdditionalInfo1 = (searchedObj.getSobject(Constants.NAMESPACE +'Vendor__r') != null && searchedObj.getSobject(Constants.NAMESPACE +'Vendor__r').get('Name') != null) ? String.valueOf(searchedObj.getSObject(Constants.NAMESPACE +'Vendor__r').get('Name')) : null;
                this.AdditionalInfoLabel1 = 'Vendor Name';
                this.AdditionalInfoLabel2 = 'Price';
                this.AdditionalInfo2 = ((searchedObj.get(Constants.NAMESPACE +'Price__c') != null) ? ((Decimal)searchedObj.get(Constants.NAMESPACE +'Price__c') < 0 ? '($'+ String.valueOf((Decimal)searchedObj.get(Constants.NAMESPACE +'Price__c') * -1) + ')' : '$'+ String.valueOf(searchedObj.get(Constants.NAMESPACE +'Price__c'))) : null);
                
            } else if(objName == Constants.NAMESPACE + 'Customer_Owned_Unit__c') {
                this.Id = String.valueOf(searchedObj.get('Id'));
                
                Customer_Owned_Unit__c unit = (Customer_Owned_Unit__c)searchedObj;
                this.ItemName = unit.VIN_Number__c;
                this.AdditionalInfo1 = unit.Unit_Type__c;
                this.AdditionalInfoLabel1 = 'Type';
                
                if(unit.Unit_Type__c == 'COU') {
                    this.Type = 25;
                    this.ObjectName = 'Customer Unit';
                    this.ItemName = unit.Account__r.Name;
                    this.AdditionalInfoLabel2 = 'Plate/Rego#';
                    this.AdditionalInfo2 = unit.Plate__c;
                    this.AdditionalInfo1 = unit.VIN_Number__c;
                    this.AdditionalInfoLabel1 = 'VIN';
                } else if(unit.Unit_Type__c == 'STOCK') {
                    this.Type = 18;
                    this.ObjectName = 'Inventory Unit';
                    this.AdditionalInfoLabel2 = 'Stock#';
                    this.AdditionalInfo2 = unit.Stock_Id__c;
                } else if(unit.Unit_Type__c == 'ORDU') {
                    this.Type = 26;
                    this.ObjectName = 'Order Unit';
                    this.AdditionalInfoLabel2 = 'Unit#';
                    this.AdditionalInfo2 = unit.Unit_Number__c;
                } 
                
                this.AdditionalInfo3 = '';
                if(searchedObj.get(Constants.NAMESPACE +'Make_Name__c') != null){
                    this.AdditionalInfo3 = String.valueOf(searchedObj.get(Constants.NAMESPACE +'Make_Name__c'));
                }
                if(searchedObj.get(Constants.NAMESPACE +'Model_Name__c') != null){
                    this.AdditionalInfo3 = this.AdditionalInfo3 + ' ' +String.valueOf(searchedObj.get(Constants.NAMESPACE +'Model_Name__c'));
                }
                if(searchedObj.getSObject(Constants.NAMESPACE +'Sub_Model__r') != null && searchedObj.getSObject(Constants.NAMESPACE +'Sub_Model__r').get('Sub_Model_Name__c') != null){
                    this.AdditionalInfo3 = this.AdditionalInfo3 + ' ' +String.valueOf(searchedObj.getSObject(Constants.NAMESPACE +'Sub_Model__r').get('Sub_Model_Name__c'));
                }
                this.AdditionalInfoLabel3 = '';
                
                this.AdditionalInfoLabel4 = 'Status';
                this.AdditionalInfo4 = unit.Status__c;

                this.AdditionalInfoLabel5 = 'Formatted Name';
                this.AdditionalInfo5 = unit.Formatted_Name__c;
                
            } else if(objName == Constants.NAMESPACE + 'Technician__c') {
                this.Id = String.valueOf(searchedObj.get('Id'));
                this.Type = 23;
                this.ObjectName = 'Technician';
                this.ItemName = (searchedObj.get('Technician_Name__c') != null) ? String.valueOf(searchedObj.get('Technician_Name__c')) : '';
                this.AdditionalInfo1 = (searchedObj.getSobject(Constants.NAMESPACE +'User__r') != null && searchedObj.getSobject(Constants.NAMESPACE +'User__r').get('Email') != null) ? String.valueOf(searchedObj.getSObject(Constants.NAMESPACE +'User__r').get('Email')) : null;
                this.AdditionalInfo2 = (searchedObj.getSobject(Constants.NAMESPACE +'User__r') != null && searchedObj.getSobject(Constants.NAMESPACE +'User__r').get('Phone') != null) ? String.valueOf(searchedObj.getSObject(Constants.NAMESPACE +'User__r').get('Phone')) : null;
                this.AdditionalInfoLabel1 = 'Email';
                this.AdditionalInfoLabel2 = 'Phone';
            } else if(objName == Constants.NAMESPACE + 'Return_CR_Header__c') {
                this.Id = String.valueOf(searchedObj.get('Id'));
                this.Type = 24;
                this.ObjectName = 'Return Credit';
            
                this.ItemName = (searchedObj.get('Name') != null) ? String.valueOf(searchedObj.get('Name')) : '';
                this.AdditionalInfo1 = (searchedObj.getSobject(Constants.NAMESPACE +'Vendor__r') != null && searchedObj.getSobject(Constants.NAMESPACE +'Vendor__r').get('Name') != null) ? String.valueOf(searchedObj.getSObject(Constants.NAMESPACE +'Vendor__r').get('Name')) : null;
                this.AdditionalInfoLabel1 = 'Vendor Name';
                this.AdditionalInfoLabel2 = 'Credit Memo#';
                this.AdditionalInfo2 = (searchedObj.get('Credit_Memo__c') != null) ? String.valueOf(searchedObj.get('Credit_Memo__c')) : null;
                this.AdditionalInfoLabel3 = 'Total';                    
                this.AdditionalInfo3 = ((searchedObj.get(Constants.NAMESPACE +'Total_With_Tax__c') != null) ? String.valueOf((Decimal)searchedObj.get(Constants.NAMESPACE +'Total_With_Tax__c') * -1) : null);
                this.AdditionalInfo4 = (searchedObj.get(Constants.NAMESPACE +'Status__c') != null) ? String.valueOf(searchedObj.get(Constants.NAMESPACE +'Status__c')) : '';
                this.AdditionalInfoLabel4 = 'Status';
                this.LastModifiedDate = (searchedObj.get('LastModifiedDate') != null) ? ((DateTime)searchedObj.get('LastModifiedDate')).format('MMMM d,  yyyy') : '';
            }
        }
    }   
    /**
     * Name: GlobalQueryJSON
     * Description: Class to represent global search query JSON
    **/
    public class GlobalQueryJSON {
        public String GlobalSearchText; // Search text
        public String GlobalSearchKeyword; // Object label selected by user to search in
        public String GlobalSearchKeywordKey; // Object label selected by user to search in
        public Integer FromIndex;
        public Integer ToIndex;
    }
    
    public class COOpenOrderFilterJSON {
        public String CustomerId;
        public String VendorId;
        public Integer StartIndex;
        public Integer RecordCount;
    }
}