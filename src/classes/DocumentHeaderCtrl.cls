public without sharing class DocumentHeaderCtrl {
    
    public DocumentHeaderWrapper docHeaderObj {get; private set;}
    public Boolean ShowTBDOnInvoicePreviews { get {return Configurations__c.getOrgDefaults().Show_TBD_On_Invoice_Previews__c;} set;}
    
    public DocumentHeaderCtrl() {
        this.docHeaderObj = new DocumentHeaderWrapper();
        Boolean isCOInvoice = false;
        String recId;
        List<PrintCustomerOrderInvoiceCtrl.SelectedSectionsWrapper> selectedSectionsList;
        if(ApexPages.currentPage().getParameters().get('unitIds') != null) {
            String unitIds = BPUtility.getDecodedString(ApexPages.currentPage().getParameters().get('unitIds'));
            List<String> unitIdList = unitIds.split(',');
            recId = unitIdList[0];
        } else {
            recId = ApexPages.currentPage().getParameters().get('id');
            String selectedSectionJson =  BPUtility.getDecodedString(ApexPages.currentPage().getParameters().get('SelectedSectionsIds'));
            if(String.isNotBlank(selectedSectionJson)){
                selectedSectionsList = (List<PrintCustomerOrderInvoiceCtrl.SelectedSectionsWrapper>)System.JSON.deserialize(selectedSectionJson, List<PrintCustomerOrderInvoiceCtrl.SelectedSectionsWrapper>.class);
            }
        }
        String brandingLocationId = ApexPages.currentPage().getParameters().get('brandingLocationId');
        if(ApexPages.currentPage().getParameters().get('isFinalized') != null) {
            isCOInvoice  = Boolean.valueOf(ApexPages.currentPage().getParameters().get('isFinalized'));
        }
        if (String.isNotBlank(recId)) {
            setDocumentHeaderDetails(brandingLocationId, isCOInvoice, recId, selectedSectionsList);
        }
    }

    private void setDocumentHeaderDetails(String brandingLocationId, Boolean isCOInvoice, Id recordId, List<PrintCustomerOrderInvoiceCtrl.SelectedSectionsWrapper> selectedSectionsList) {
        BrandingLocationWrapper brandingLocationObj = COService.getBrandingLocationDataForPrint(brandingLocationId);
        this.docHeaderObj.companyInfo = new CustomerDetail.Company(brandingLocationObj);

        CO_Header__c coRec;
        CO_Invoice_Header__c coInvRec;
        Account tpProvider;
        String claimNumber;
        Boolean isInternalService = false;
        String objName = recordId.getSObjectType().getDescribe().getName();
        if(objName.equalsIgnoreCase(Constants.Namespace + 'CO_Invoice_Header__c')) {
            coInvRec = getCOInvoiceDetails(recordId);
            coRec = getCOHeaderDetails(coInvRec.CO_Header__c);
            Id thirdPartySOId;
            if(coInvRec.Status__c != null && coInvRec.Status__c.equalsIgnoreCase('Closed')) {
                if(coInvRec.Checkout_Type__c != null && coInvRec.Checkout_Type__c.equalsIgnoreCase('Third-Party') && !coInvRec.Service_Order_Headers__r.isEmpty()) {
                thirdPartySOId = coInvRec.Service_Order_Headers__r[0].Id;
                } else if(coInvRec.Checkout_Type__c != null && coInvRec.Checkout_Type__c.equalsIgnoreCase('Internal')) {
                    isInternalService = true;
                }
            } else if(selectedSectionsList != null) {
                for(PrintCustomerOrderInvoiceCtrl.SelectedSectionsWrapper selectedSectionsRec: selectedSectionsList) {
                    if(selectedSectionsRec.sectionName == 'Service job') {
                        thirdPartySOId = selectedSectionsRec.sectionId;
                        break;
                    }
                }
            }
            if(thirdPartySOId != null) {
                Service_Order_Header__c soRec = getSOHeaderDetails(thirdPartySOId);
                isInternalService = soRec.Transaction_Type__r.Type__c.equalsIgnoreCase('Internal') || soRec.Transaction_Type__r.Type__c.equalsIgnoreCase('Stock Unit');
                if(soRec.Transaction_Type__r.Type__c.equalsIgnoreCase('Third-Party') && soRec.Provider__c != null) {
                    tpProvider = soRec.Provider__r;
                    if(!soRec.Claims__r.isEmpty()) {
                        claimNumber = soRec.Claims__r[0].Provider_Claim_Number__c;
                    }
                }
            }
        } else if(objName.equalsIgnoreCase(Constants.Namespace + 'Deal__c')) {
            Deal__c dealRec = [Select Invoice_Number__c, CO_Header__c FROM Deal__c WHERE Id = :recordId];
            if(dealRec.Invoice_Number__c != null) {
                isCOInvoice = true;
                coInvRec = getCOInvoiceDetails(dealRec.Invoice_Number__c);
            }
            coRec = getCOHeaderDetails(dealRec.CO_Header__c);

        } else if(objName.equalsIgnoreCase(Constants.Namespace + 'CO_Header__c')) {
            coRec = getCOHeaderDetails(recordId);

        } else if(objName.equalsIgnoreCase(Constants.Namespace + 'Vendor_Order_Header__c')) {
            Vendor_Order_Header__c voRec = getVODetails(recordId);
            this.docHeaderObj.CustomerInfo = new CustomerVendorWrapper(voRec.Vendor__r, true);
            this.docHeaderObj.OrderInfo = new OrderDetail(voRec);

        } else if(objName.equalsIgnoreCase(Constants.Namespace + 'Vendor_Receiving_Header__c')) {
            Vendor_Receiving_Header__c vrRec = getVRDetails(recordId);
            this.docHeaderObj.CustomerInfo = new CustomerVendorWrapper(vrRec.Vendor__r, true);
            this.docHeaderObj.OrderInfo = new OrderDetail(vrRec);

        } else if(objName.equalsIgnoreCase(Constants.Namespace + 'Return_VO_Header__c')) {
            Return_VO_Header__c rvoRec = getRVODetails(recordId);
            this.docHeaderObj.CustomerInfo = new CustomerVendorWrapper(rvoRec.Vendor__r, true);
            this.docHeaderObj.OrderInfo = new OrderDetail(rvoRec);

        } else if(objName.equalsIgnoreCase(Constants.Namespace + 'Customer_Owned_Unit__c')) {
            Customer_Owned_Unit__c unitRec = getUnitOrderDetails(recordId);
            this.docHeaderObj.CustomerInfo = new CustomerVendorWrapper(unitRec.Vendor__r, true);
            this.docHeaderObj.OrderInfo = new OrderDetail(unitRec);
        } else if(objName.equalsIgnoreCase(Constants.Namespace + 'Payment_on_Account__c')) {
            Payment_on_Account__c poaRec = getPOADetails(recordId);
            this.docHeaderObj.CustomerInfo = new CustomerVendorWrapper(poaRec.Customer__r, false);
            this.docHeaderObj.OrderInfo = new OrderDetail(poaRec);
        }
        if(coRec != null) {
            if(tpProvider != null) {
                this.docHeaderObj.CustomerInfo = new CustomerVendorWrapper(tpProvider, true);
            } else {
            	this.docHeaderObj.CustomerInfo = new CustomerVendorWrapper(coRec.Customer__r, false);
            }
            if(isCOInvoice != null && isCOInvoice) {
                this.docHeaderObj.OrderInfo = new OrderDetail(coInvRec);
                setInvoiceContactAndShippingAddress(coInvRec);
            } else {
                this.docHeaderObj.OrderInfo = new OrderDetail(coRec);
                this.setCOContactAndShippingAddress(coRec);
            }
            if(coRec.Customer__c == null) {
                this.docHeaderObj.OrderInfo.COType = coRec.CO_Type__c;
            }
            this.docHeaderObj.OrderInfo.ClaimNo = claimNumber;
            this.docHeaderObj.OrderInfo.IsInternalService = isInternalService;
        }
    }

    private void setCOContactAndShippingAddress(CO_Header__c coRec) {
        this.docHeaderObj.ShippingAddress = new AddressInfo();
        Contact shippingAddress = coRec.Customer_Shipping_Address__r;
        if(shippingAddress != null && shippingAddress.Is_Shipping_Address__c) {
            this.docHeaderObj.ShippingAddress = new AddressInfo();
            String shippingStreet = String.isNotBlank(shippingAddress.MailingStreet) ? shippingAddress.MailingStreet : '';
            List<String> ssList = shippingStreet.split('\n');
            this.docHeaderObj.ShippingAddress.AddressLine1 = (ssList.size() > 0) ? ssList[0] : '';
            this.docHeaderObj.ShippingAddress.AddressLine2 = (ssList.size() > 1) ? ssList[1] : '';
            this.docHeaderObj.ShippingAddress.City = shippingAddress.MailingCity;
            this.docHeaderObj.ShippingAddress.State = shippingAddress.MailingState;
            this.docHeaderObj.ShippingAddress.PostalCode = shippingAddress.MailingPostalCode;
            this.docHeaderObj.ShippingAddress.Country = shippingAddress.MailingCountry;
        }
        if(coRec.Customer_Contact__c != null && coRec.Customer_Contact__r.Is_Contact__c) {
            this.docHeaderObj.CustomerContact = new ContactInfo();
            this.docHeaderObj.CustomerContact.Name = coRec.Customer_Contact__r.LastName;
            this.docHeaderObj.CustomerContact.Email = coRec.Customer_Contact__r.Email;
            this.docHeaderObj.CustomerContact.FormattedPhone = coRec.Customer_Contact__r.Formatted_Phone_number__c;
        }
    }

    private void setInvoiceContactAndShippingAddress(CO_Invoice_Header__c coInvRec) {
        if(coInvRec != null) {
            if(coInvRec.Shipping_Country__c != null) {
                this.docHeaderObj.ShippingAddress = new AddressInfo();
                String shippingStreet = String.isNotBlank(coInvRec.Shipping_Street__c) ? coInvRec.Shipping_Street__c : '';
                List<String> ssList = shippingStreet.split('\n');
                this.docHeaderObj.ShippingAddress.AddressLine1 = (ssList.size() > 0) ? ssList[0] : '';
                this.docHeaderObj.ShippingAddress.AddressLine2 = (ssList.size() > 1) ? ssList[1] : '';
                this.docHeaderObj.ShippingAddress.City = coInvRec.Shipping_City__c;
                this.docHeaderObj.ShippingAddress.State = coInvRec.Shipping_State__c;
                this.docHeaderObj.ShippingAddress.PostalCode = coInvRec.Shipping_Postal_Code__c;
                this.docHeaderObj.ShippingAddress.Country = coInvRec.Shipping_Country__c;
            }
            if(coInvRec.Contact_Formatted_Phone__c != null || coInvRec.Contact_Email__c != null) {
                this.docHeaderObj.CustomerContact = new ContactInfo();
                this.docHeaderObj.CustomerContact.Name = coInvRec.Contact_Name__c;
                this.docHeaderObj.CustomerContact.Email = coInvRec.Contact_Email__c;
                this.docHeaderObj.CustomerContact.FormattedPhone = coInvRec.Contact_Formatted_Phone__c;
            }
        }
    }

    public class DocumentHeaderWrapper {
        public String companyLogoURL { get{return GeneralConfiguration.getCompanyLogoUrl();} private set;}
        public CustomerDetail.Company companyInfo {get; set;}
        public CustomerVendorWrapper CustomerInfo {get; set;}
        public AddressInfo ShippingAddress {get; set;}
        public ContactInfo CustomerContact {get; set;}
        public String DocTitle {get; set;}
        public OrderDetail OrderInfo {get; set;}
    }

    public class CustomerVendorWrapper {
        public String Name {get; set;}
        public String CustomerNumber {get; set;}
        public String AccountNumber {get; set;}
        public ContactInfo ContactInfo {get; set;}
        public AddressInfo BillingAddress {get; set;}
        
        public CustomerVendorWrapper(Account accRec, Boolean isVendorDoc) {
            if(accRec != null) {
                this.Name = accRec.Name;

                this.BillingAddress = new AddressInfo();
                String billingStreet = (accRec.BillingStreet == null ) ? '' : accRec.BillingStreet;
                List<String> bsList = billingStreet.split('\n');
                this.BillingAddress.AddressLine1 = (bsList.size() > 0) ? bsList[0] : '';
                this.BillingAddress.AddressLine2 = (bsList.size() > 1) ? bsList[1] : '';
                this.BillingAddress.City = accRec.BillingCity;
                this.BillingAddress.State = accRec.BillingState;
                this.BillingAddress.PostalCode = accRec.BillingPostalCode;
                this.BillingAddress.Country = accRec.BillingCountry;
                
                if(isVendorDoc) {
                    setVendorFields(accRec);
                } else {
                    setCustomerFields(accRec);
                }
            }
        }

        private void setCustomerFields(Account accRec) {
            this.ContactInfo = new ContactInfo();
            this.CustomerNumber = accRec.Customer_Number__c != null ? accRec.Customer_Number__c : '';
            if(accRec.Preferred_Email__c != null) {
                this.ContactInfo.Email = accRec.Preferred_Email__c;
            } else {
                this.ContactInfo.Email = accRec.Email_Address__c;
                
            }
            
            if(accRec.Formatted_Preferred_Phone__c != null) {
                this.ContactInfo.FormattedPhone = accRec.Formatted_Preferred_Phone__c;
            } else {
                if(accRec.Formatted_Home_number__c != null) {
                    this.ContactInfo.FormattedPhone = accRec.Formatted_Home_number__c;
                } else if(accRec.Formatted_Mobile_Number__c != null) {
                    this.ContactInfo.FormattedPhone = accRec.Formatted_Mobile_Number__c;
                } else if(accRec.Formatted_Work_Number__c != null) {
                    this.ContactInfo.FormattedPhone = accRec.Formatted_Work_Number__c;
                }
            }
        }

        private void setVendorFields(Account accRec) {
            this.ContactInfo = new ContactInfo();
            this.CustomerNumber = accRec.Vendor_Number__c != null ? accRec.Vendor_Number__c : '';
            this.AccountNumber = accRec.AccountNumber;
            if(accRec.Preferred_Email__c != null) {
                this.ContactInfo.Email = accRec.Preferred_Email__c;
            } else {
                if(accRec.Work_Email__c != null) {
                    this.ContactInfo.Email = accRec.Work_Email__c;
                } else if(accRec.Other_Email__c != null) {
                    this.ContactInfo.Email = accRec.Other_Email__c;
                }
            }
            
            if(accRec.Formatted_Preferred_Phone__c != null) {
                this.ContactInfo.FormattedPhone = accRec.Formatted_Preferred_Phone__c;
            } else {
                if(accRec.Formatted_Mobile_Number__c != null) {
                    this.ContactInfo.FormattedPhone = accRec.Formatted_Mobile_Number__c;
                } else if(accRec.Formatted_Work_Number__c != null) {
                    this.ContactInfo.FormattedPhone = accRec.Formatted_Work_Number__c;
                }
            }
        }
    }

    public class AddressInfo {
        public String AddressLine1 {get; set;}
        public String AddressLine2 {get; set;}
        public String City {get; set;}
        public String State {get; set;}
        public String PostalCode {get; set;}
        public String Country {get; set;}
    }

    public class ContactInfo {
        public String Name {get; set;}
        public String FormattedPhone {get; set;}
        public String Email {get; set;}
    }

    public class OrderDetail {
        public String COType {get; set;}
        public String OrderNo {get; set;}
        public String InvoiceNo {get; set;}
        public String PONumber {get; set;}
        public String OrderDate {get; set;}
        public String SoldBy {get; set;}
        public String ClaimNo {get; set;}
        public Boolean IsInternalService {get; set;}

        //Vendor related docs
        public String Info1 {get; set;}
        public String Info2 {get; set;}
        public String Info3 {get; set;}
        public String Info4 {get; set;}
        public String Info5 {get; set;}

        public OrderDetail(CO_Header__c coRec) {
            this.OrderNo = coRec.Name;
            this.OrderDate = System.now().format('MMMM dd, yyyy');
            this.SoldBy = coRec.CreatedBy.Name;
            this.PONumber = coRec.Customer_PO_Number__c;
        }

        public OrderDetail(CO_Invoice_Header__c coInvRec) {
            this.InvoiceNo = coInvRec.Invoice_Number__c;
            this.OrderDate = (coInvRec.Invoice_Date__c != null) ? (coInvRec.Invoice_Date__c).format('MMMM dd, yyyy') : '';
            this.OrderNo = coInvRec.CO_Header__r.Name;
            this.SoldBy = coInvRec.Salesperson__c;
            this.PONumber = coInvRec.CO_Header__r.Customer_PO_Number__c;
        }

        public OrderDetail(Vendor_Order_Header__c voRec) {
            this.Info1 = voRec.Name;
            this.Info2 = (voRec.Ordered_Date__c != null) ? 
                (Datetime.newInstance(voRec.Ordered_Date__c.year(), voRec.Ordered_Date__c.month(), voRec.Ordered_Date__c.day())).format('MMMM dd, yyyy') 
                : '';
            this.Info3 = voRec.Vendor__r.AccountNumber;
            this.Info4 = voRec.CreatedBy.Name;
        }

        public OrderDetail(Vendor_Receiving_Header__c vrRec) {
            this.Info1 = vrRec.Receipt_Number__c;
            this.Info2 = (vrRec.Finalized_Date__c != null) ? 
                (Datetime.newInstance(vrRec.Finalized_Date__c.year(), vrRec.Finalized_Date__c.month(), vrRec.Finalized_Date__c.day())).format('MMMM dd, yyyy')
                : '';
            this.Info3 = vrRec.CreatedBy.Name;
            this.Info4 = vrRec.Name;
        }

        public OrderDetail(Return_VO_Header__c rvoRec) {
            this.Info1 = rvoRec.RMA__c;
            this.Info2 = (rvoRec.Returned_Date__c != null) ? (Datetime.newInstance(rvoRec.Returned_Date__c.year(), rvoRec.Returned_Date__c.month(), rvoRec.Returned_Date__c.day())).format('MMMM dd, yyyy') : '';
            this.Info3 = rvoRec.CreatedBy.Name;
            this.Info4 = rvoRec.Name;
        }

        public OrderDetail(Customer_Owned_Unit__c unitRec) {
            this.Info2 = (unitRec.Date_Ordered__c != null) ? (Datetime.newInstance(unitRec.Date_Ordered__c.year(), unitRec.Date_Ordered__c.month(), unitRec.Date_Ordered__c.day())).format('MMMM dd, yyyy') : '';
            this.Info3 = unitRec.Vendor__c != null ? unitRec.Vendor__r.AccountNumber : '';
            this.Info4 = unitRec.CreatedBy.Name;
        }

        public OrderDetail(Payment_on_Account__c poaRec) {
            this.Info1 = poaRec.Name;
            this.Info2 = (poaRec.Payment_Date__c != null) ? 
                (Datetime.newInstance(poaRec.Payment_Date__c.year(), poaRec.Payment_Date__c.month(), poaRec.Payment_Date__c.day())).format('MMMM dd, yyyy') 
                : '';
            this.Info3 = 'Payment Method: ' + poaRec.Payment_Method__c;
            this.Info4 = poaRec.Reference__c;
        }
    }

    private static CO_Header__c getCOHeaderDetails(String recId) {
        return [Select Id, Name, 
        CO_Type__c,
        Customer_PO_Number__c,
        CreatedBy.Name, 
        Customer__r.Name,
        Customer__r.Customer_Number__c,
        Customer__r.BillingStreet,
        Customer__r.BillingCity,
        Customer__r.BillingState,
        Customer__r.BillingPostalCode,
        Customer__r.BillingCountry,
        Customer__r.Email__c,
        Customer__r.Email_Address__c,
        Customer__r.Other_Email__c,
        Customer__r.Preferred_Email__c,
        Customer__r.Formatted_Preferred_Phone__c,
        Customer__r.Formatted_Mobile_Number__c,
        Customer__r.Formatted_Work_Number__c,
        Customer__r.Formatted_Home_number__c,
        Customer_Contact__r.Is_Contact__c, Customer_Shipping_Address__r.Is_Shipping_Address__c, 
        Customer_Contact__r.LastName, Customer_Contact__r.Formatted_Phone_number__c, Customer_Contact__r.Email, 
        Customer_Shipping_Address__r.MailingStreet, Customer_Shipping_Address__r.MailingCity, 
        Customer_Shipping_Address__r.Mailing_County_Parish__c, Customer_Shipping_Address__r.MailingPostalCode, 
        Customer_Shipping_Address__r.MailingState, Customer_Shipping_Address__r.MailingCountry FROM CO_Header__c WHERE Id = :recId];
    }

    private static Service_Order_Header__c getSOHeaderDetails(Id recId) {
        return [Select Id, Transaction_Type__r.Type__c,  
        Provider__r.AccountNumber,
        Provider__r.Name,
        Provider__r.Vendor_Number__c,
        Provider__r.BillingStreet,
        Provider__r.BillingCity,
        Provider__r.BillingState,
        Provider__r.BillingPostalCode,
        Provider__r.BillingCountry,
        Provider__r.Work_Email__c,
        Provider__r.Other_Email__c,
        Provider__r.Preferred_Email__c,
        Provider__r.Formatted_Preferred_Phone__c,
        Provider__r.Formatted_Mobile_Number__c,
        Provider__r.Formatted_Work_Number__c, (SELECT Provider_Claim_Number__c FROM Claims__r LIMIT 1) FROM Service_Order_Header__c WHERE Id = :recId];
    }

    private CO_Invoice_Header__c getCOInvoiceDetails(String recId) {
        return [Select Id, Salesperson__c, Shipping_Street__c, Shipping_City__c, Shipping_State__c, Shipping_Country__c, Shipping_Postal_Code__c, 
        Contact_Name__c, Contact_Email__c, Contact_Formatted_Phone__c, Invoice_Number__c, CO_Header__r.Name, CO_Header__r.Customer_PO_Number__c,
        CreatedBy.Name, Status__c, Invoice_Date__c, Checkout_Type__c, 
        (Select Id FROM Service_Order_Headers__r WHERE Transaction_Type__r.Type__c = 'Third-Party') FROM CO_Invoice_Header__c WHERE Id =: recId];
    }

    private Vendor_Order_Header__c getVODetails(String recId) {
        return [Select Name, Ordered_Date__c, CreatedBy.Name,
        Vendor__r.AccountNumber,
        Vendor__r.Name,
        Vendor__r.Vendor_Number__c,
        Vendor__r.BillingStreet,
        Vendor__r.BillingCity,
        Vendor__r.BillingState,
        Vendor__r.BillingPostalCode,
        Vendor__r.BillingCountry,
        Vendor__r.Work_Email__c,
        Vendor__r.Other_Email__c,
        Vendor__r.Preferred_Email__c,
        Vendor__r.Formatted_Preferred_Phone__c,
        Vendor__r.Formatted_Mobile_Number__c,
        Vendor__r.Formatted_Work_Number__c
        FROM Vendor_Order_Header__c WHERE Id = :recId];
    }

    private Vendor_Receiving_Header__c getVRDetails(String recId) {
        return [Select Name, Finalized_Date__c, Receipt_Number__c, CreatedBy.Name,
        Vendor__r.AccountNumber,
        Vendor__r.Name,
        Vendor__r.Vendor_Number__c,
        Vendor__r.BillingStreet,
        Vendor__r.BillingCity,
        Vendor__r.BillingState,
        Vendor__r.BillingPostalCode,
        Vendor__r.BillingCountry,
        Vendor__r.Work_Email__c,
        Vendor__r.Other_Email__c,
        Vendor__r.Preferred_Email__c,
        Vendor__r.Formatted_Preferred_Phone__c,
        Vendor__r.Formatted_Mobile_Number__c,
        Vendor__r.Formatted_Work_Number__c
        FROM Vendor_Receiving_Header__c WHERE Id = :recId];
    }

    private Return_VO_Header__c getRVODetails(String recId) {
        return [Select Name, Returned_Date__c, RMA__c, CreatedBy.Name,
        Vendor__r.AccountNumber,
        Vendor__r.Name,
        Vendor__r.Vendor_Number__c,
        Vendor__r.BillingStreet,
        Vendor__r.BillingCity,
        Vendor__r.BillingState,
        Vendor__r.BillingPostalCode,
        Vendor__r.BillingCountry,
        Vendor__r.Work_Email__c,
        Vendor__r.Other_Email__c,
        Vendor__r.Preferred_Email__c,
        Vendor__r.Formatted_Preferred_Phone__c,
        Vendor__r.Formatted_Mobile_Number__c,
        Vendor__r.Formatted_Work_Number__c
        FROM Return_VO_Header__c WHERE Id = :recId];
    }

    private Customer_Owned_Unit__c getUnitOrderDetails(String recId) {
        return [Select Date_Ordered__c, CreatedBy.Name,
        Vendor__r.AccountNumber,
        Vendor__r.Name,
        Vendor__r.Vendor_Number__c,
        Vendor__r.BillingStreet,
        Vendor__r.BillingCity,
        Vendor__r.BillingState,
        Vendor__r.BillingPostalCode,
        Vendor__r.BillingCountry,
        Vendor__r.Work_Email__c,
        Vendor__r.Other_Email__c,
        Vendor__r.Preferred_Email__c,
        Vendor__r.Formatted_Preferred_Phone__c,
        Vendor__r.Formatted_Mobile_Number__c,
        Vendor__r.Formatted_Work_Number__c
        FROM Customer_Owned_Unit__c WHERE Id = :recId];
    }

    private Payment_on_Account__c getPOADetails(String recId) {
        return [Select Id, Name, 
        Payment_Date__c, Reference__c, 
        Payment_Method__c, 
        Customer__r.Name,
        Customer__r.Customer_Number__c,
        Customer__r.BillingStreet,
        Customer__r.BillingCity,
        Customer__r.BillingState,
        Customer__r.BillingPostalCode,
        Customer__r.BillingCountry,
        Customer__r.Email__c,
        Customer__r.Email_Address__c,
        Customer__r.Other_Email__c,
        Customer__r.Preferred_Email__c,
        Customer__r.Formatted_Preferred_Phone__c,
        Customer__r.Formatted_Mobile_Number__c,
        Customer__r.Formatted_Work_Number__c,
        Customer__r.Formatted_Home_number__c 
        FROM Payment_on_Account__c WHERE Id = :recId];
    }
}