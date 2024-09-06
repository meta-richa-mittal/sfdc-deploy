/**
* Author: Nidhi Sharma
* Since: December 16, 2021
* Name: ServiceJobWorksheetWrapper
* Description: Wrapper class to handle JSON variables for SO worksheet.
**/
public class ServiceJobWorksheetWrapper {
    public Boolean IsSignatureLineforServiceJob{get; private set;}
    public Boolean IsSignatureLineforCustomerInvoice{get; private set;}
    public Boolean IsTaxIncludePricing{get; private set;}
    public Boolean IsHideHoursRateOnServiceDocuments{get; private set;}
    public Boolean IsItemizedByLaborCode {get; set;}

    public String FormattedCurrentDate{get; private set;}
    public String ServiceJobWarrantyText{get; private set;}
    public String CustomerInvoiceWarrantyText{get; private set;}
    
	public CustomerDetail.Company StoreInfo{get; private set;}
    public COWrapper COHeaderInfo{get; private set;}
    public CustomerInfoWrapper CustomerInfo{get; private set;}
    public WorksheetSummary WorksheetTotal{get; private set;}
    public List<SOWrapper> Services{get; private set;}
    
    public ServiceJobWorksheetWrapper(CO_Header__c coHeaderRec, List<Account> customerList, List<Service_Order_Header__c> soHeaderList, 
                                BrandingLocationWrapper brandingLocationObj, Map<String, Decimal> salesTaxNameToTaxValue) {
        
        this.COHeaderInfo = new COWrapper(coHeaderRec);  
        if(customerList != null && customerList.size() > 0) {
            this.CustomerInfo = new CustomerInfoWrapper(customerList[0]);
        }    

        if(brandingLocationObj != null) {
        	this.StoreInfo = new CustomerDetail.Company(brandingLocationObj);
	        this.ServiceJobWarrantyText = (brandingLocationObj.DisclaimerforServiceJob != null) ? brandingLocationObj.DisclaimerforServiceJob : '';
	        this.IsSignatureLineforServiceJob = brandingLocationObj.IsSignatureforServiceJob;
            this.CustomerInvoiceWarrantyText = (brandingLocationObj.DisclaimerforCustomerInvoice != null) ? brandingLocationObj.DisclaimerforCustomerInvoice : '';
	        this.IsSignatureLineforCustomerInvoice = brandingLocationObj.IsSignatureforCustomerInvoice;
        }
        Set<Id> soIdSet = new Set<Id>();
        for(Service_Order_Header__c soHeaderRec : soHeaderList) {
            soIdSet.add(soHeaderRec.Id);
        }
        List<Service_Order_Kit_Header__c> sokitHeadersList = SOQLUtil.getSOKHBySOHeaderId(soIdSet);
        Map<String, List<Service_Order_Kit_Header__c>> soIdToSoKitListMap = new Map<String, List<Service_Order_Kit_Header__c>>();
        for(Service_Order_Kit_Header__c sokh : sokitHeadersList) {
            if(!soIdToSoKitListMap.containsKey(sokh.Service_Order_Header__c)) {
                soIdToSoKitListMap.put(sokh.Service_Order_Header__c, new List<Service_Order_Kit_Header__c>());
            }
            soIdToSoKitListMap.get(sokh.Service_Order_Header__c).add(sokh);
        }
        this.Services = new List<SOWrapper>();
        for(Service_Order_Header__c soHeaderRec : soHeaderList) {
            List<Service_Order_Kit_Header__c> sokitList = soIdToSoKitListMap.containsKey(soHeaderRec.Id) ? soIdToSoKitListMap.get(soHeaderRec.Id) : new List<Service_Order_Kit_Header__c>();
            this.Services.add(new SOWrapper(soHeaderRec, sokitList));
        }

        this.WorksheetTotal = new WorksheetSummary(soHeaderList, salesTaxNameToTaxValue, coHeaderRec.CO_Deposits__r);
        this.IsTaxIncludePricing = GeneralConfiguration.getTaxIncludingPricing();
        this.IsHideHoursRateOnServiceDocuments = GeneralConfiguration.isHideHoursRateOnServiceDocument();
        this.IsItemizedByLaborCode = GeneralConfiguration.isCalculationMethodAvailable() && GeneralConfiguration.isItemizedByLaborCode();
        this.FormattedCurrentDate = (System.now()).format('MMMM dd, yyyy');
    }
    
    public class COWrapper {
        public String Name{get; private set;} 
        public String Status{get; private set;}
        public String COType{get; private set;}
        public String CustomerPONumber{get; private set;}
        public String SoldBy{get; private set;}
         
        public COWrapper(CO_Header__c coHeaderRec) {
            this.Name = coHeaderRec.Name;
            this.Status = coHeaderRec.Status__c;
            this.COType = coHeaderRec.CO_Type__c;
            this.CustomerPONumber = coHeaderRec.Customer_PO_Number__c;
            this.SoldBy = coHeaderRec.CreatedBy.Name;
        }
    }
    
    public class CustomerInfoWrapper {
        public String CustomerName{get; private set;}
        public String CustomerNumber{get; private set;}
        public String Email{get; private set;}
        public String Phone{get; private set;}
        public String BillingStreet1{get; private set;} 
        public String BillingStreet2{get; private set;}
        public String BillingCity{get; private set;}
        public String BillingState{get; private set;}
        public String BillingCountry{get; private set;}
        public String BillingPostalCode{get; private set;}
            
        public CustomerInfoWrapper(Account customerRec) {
            if(customerRec != null) {
                this.CustomerName = customerRec.Name;
                this.CustomerNumber = customerRec.Customer_Number__c;
                
                if(customerRec.Preferred_Email__c == null) {
                    if(customerRec.Email__c != null) {
                        this.Email = customerRec.Email__c;
                    } else if(customerRec.Work_Email__c != null) {
                        this.Email = customerRec.Work_Email__c;
                    } else if(customerRec.Other_Email__c != null) {
                        this.Email = customerRec.Other_Email__c;
                    }
                } else {
                    this.Email = customerRec.Preferred_Email__c;
                }
                
                if(customerRec.Preferred_Phone__c == null) {
                    if(customerRec.Formatted_Home_number__c != null) {
                        this.Phone = customerRec.Formatted_Home_number__c;
                    } else if(customerRec.Formatted_Mobile_Number__c != null) {
                        this.Phone = customerRec.Formatted_Mobile_Number__c;
                    } else if(customerRec.Formatted_Work_Number__c != null) {
                        this.Phone = customerRec.Formatted_Work_Number__c;
                    }
                } else {
                    this.Phone = customerRec.Formatted_Preferred_Phone__c;
                }
                
                String billingStreet = (customerRec.BillingStreet == null ) ? '' : customerRec.BillingStreet;
                List<String> bsList = billingStreet.split('\n');
                this.BillingStreet1 = (bsList.size() > 0) ? bsList[0] : '';
                this.BillingStreet2 = (bsList.size() > 1) ? bsList[1] : '';
                this.BillingCity = (customerRec.BillingCity == null) ? '' : customerRec.BillingCity;
                this.BillingState = (customerRec.BillingState == null) ? '' : customerRec.BillingState;
                this.BillingCountry = (customerRec.BillingCountry == null) ? '' : customerRec.BillingCountry;
                this.BillingPostalCode = (customerRec.BillingPostalCode == null) ? '' : customerRec.BillingPostalCode;
            }
        }
    }
    
    public class UnitInfoWrapper {
        public String UnitDetail{get; private set;}
        public String PlateNumber{get; private set;}
        public String StockNumber{get; private set;}
        public String Type{get; private set;}
        public String EngineSerialNo{get; private set;}
        public String OtherSerialNo{get; private set;}
        public List<UnitDataFieldWrapper> UnitDataFieldObjList{get; private set;}
        public String UnitData01{get; private set;}
        public String UnitData02{get; private set;}
        public String UnitData03{get; private set;}
        public String UnitData04{get; private set;}
        public String UnitData05{get; private set;}
        public String UnitData06{get; private set;}
        public String UnitData07{get; private set;}
        public String UnitData08{get; private set;}
        public String UnitData09{get; private set;}
        public String UnitData10{get; private set;}
        public String UnitData11{get; private set;}
        public String UnitData12{get; private set;}
        public String UnitData13{get; private set;}
        public String UnitData14{get; private set;}
        public String UnitData15{get; private set;}
        
        public UnitInfoWrapper(Customer_Owned_Unit__c unitRec) {
            if(unitRec!= null) {
                this.UnitDetail = '';
                this.UnitDetail += unitRec.Year__c != null ? unitRec.Year__c  + ' ' : '';
                this.UnitDetail += unitRec.Unit_Make__c != null ? unitRec.Unit_Make__r.Name  + ' ' : '';
                this.UnitDetail += unitRec.Unit_Model__c != null ? unitRec.Unit_Model__r.Name__c  + ' ' : '';
                this.UnitDetail += unitRec.Sub_Model__c != null ? unitRec.Sub_Model__r.Sub_Model_Name__c  + ' ' : '';
                this.UnitDetail += String.isNotBlank(this.UnitDetail) ? ' - ' : '';
                this.UnitDetail += unitRec.VIN_Number__c != null ? unitRec.VIN_Number__c  + ' ' : '';

                this.PlateNumber = unitRec.Plate__c;
                this.StockNumber = unitRec.Stock_Id__c;
                this.Type = unitRec.Unit_Type__c;
                this.EngineSerialNo = unitRec.Engine_Serial_No__c;
                this.OtherSerialNo = unitRec.Other_Serial_No__c;

                this.UnitDataFieldObjList = new List<UnitDataFieldWrapper>();
                for(GeneralConfiguration.UnitDataFieldConfigWrapper unitDataFieldConfig : GeneralConfiguration.getUnitDataFieldsConfig()) {
                    object fieldValue = unitRec.get(unitDataFieldConfig.FieldName.replaceAll(' ', '_') + '__c');
                    if(fieldValue != null && String.isNotBlank(String.valueOf(fieldValue))) {
                        this.UnitDataFieldObjList.add(new UnitDataFieldWrapper(unitDataFieldConfig.DisplayLabel, String.valueOf(fieldValue)));
                    }
                }
                this.UnitData01 = unitRec.Unit_Data_01__c;
                this.UnitData02 = unitRec.Unit_Data_02__c;
                this.UnitData03 = unitRec.Unit_Data_03__c;
                this.UnitData04 = unitRec.Unit_Data_04__c;
                this.UnitData05 = unitRec.Unit_Data_05__c;
                this.UnitData06 = unitRec.Unit_Data_06__c;
                this.UnitData07 = unitRec.Unit_Data_07__c;
                this.UnitData08 = unitRec.Unit_Data_08__c;
                this.UnitData09 = unitRec.Unit_Data_09__c;
                this.UnitData10 = unitRec.Unit_Data_10__c;
                this.UnitData11 = unitRec.Unit_Data_11__c;
                this.UnitData12 = unitRec.Unit_Data_12__c;
                this.UnitData13 = unitRec.Unit_Data_13__c;
                this.UnitData14 = unitRec.Unit_Data_14__c;
                this.UnitData15 = unitRec.Unit_Data_15__c;
            }
        }
    }

    public class UnitDataFieldWrapper {
        public String Label{get; private set;}
        public String Value{get; private set;}

        public UnitDataFieldWrapper(String label, String value) {
            this.Label = label;
            this.Value = value;
        }
    }
    
    public class SOWrapper {
        public String Id{get; private set;}
        public String Name{get; private set;}
        public Decimal DeductibleTotal{get; private set;}
        
        public List<String> CauseList{get; private set;}
        public List<String> CorrectionList{get; private set;}
        public List<String> ConcernList{get; private set;}
        public List<String> ManualNotes{get; private set;}
        
        public UnitInfoWrapper Unit{get; private set;}
        
        public String Appointment{get; private set;}
        public String Invoiced{get; private set;}
        public String AssignedTo{get; private set;}

        public Decimal MileageIn{get; private set;}
        public Decimal MileageOut{get; private set;}
        public String MileageType{get; private set;}
        public List<SOHeaderWrapper.SOGrid> SOGridItems{get; private set;}
        public String CreatedDate{get; private set;}
        public String ProviderName{get; private set;}
        
        public Decimal ShopSupplyTotal {get; private set;}
        public Set<String> ShopSupplyDetailSet {get; private set;}
        public Boolean isShopSupplySetValid{get; private set;}

        public String JobType{get; private set;}
        public String TransactionType{get; private set;}
        
        public SOWrapper(Service_Order_Header__c soHeaderRec, List<Service_Order_Kit_Header__c> soKitHeaderList) {
            this.Id = soHeaderRec.Id;    
            this.JobType =  soHeaderRec.Transaction_Type__r.Code_Label__c;
            this.TransactionType = soHeaderRec.Transaction_Type__r.Type__c;
            
            this.Unit = new UnitInfoWrapper(soHeaderRec.Customer_Owned_Unit__r);
            
            if(this.TransactionType == 'Third-Party') {
                this.DeductibleTotal = 0;
                for(SO_Payment_Role__c soPaymentRole : soHeaderRec.SO_Payment_Roles__r) {
                    if(soPaymentRole.RecordType.DeveloperName == 'Deductible') {
                        this.DeductibleTotal += (soPaymentRole.Total_Amount__c != null ? soPaymentRole.Total_Amount__c : 0);
                    }
                }
                this.ProviderName = soHeaderRec.Provider__r.Name;
            }

            this.CauseList = (soHeaderRec.SO_Cause__c != null) ? ServiceJobService.getDeclineAddedNotesList(soHeaderRec.SO_Cause__c.split('\n')) : new List<String>();
            this.CorrectionList = (soHeaderRec.SO_Correction__c != null) ? ServiceJobService.getDeclineAddedNotesList(soHeaderRec.SO_Correction__c.split('\n')) : new List<String>();
            this.ConcernList = (soHeaderRec.SO_Concern__c != null) ? ServiceJobService.getDeclineAddedNotesList(soHeaderRec.SO_Concern__c.split('\n')) : new List<String>();
            this.ManualNotes = (soHeaderRec.SO_Notes_For_Customer__c != null) ? ServiceJobService.getDeclineAddedNotesList(soHeaderRec.SO_Notes_For_Customer__c.split('\n')) : new List<String>();
            
            this.ShopSupplyTotal = (soHeaderRec.Total_Shop_Supplies__c != null) ? soHeaderRec.Total_Shop_Supplies__c : 0;
            this.MileageIn = (soHeaderRec.Odometer_on_Arrival__c != null) ? soHeaderRec.Odometer_on_Arrival__c : 0;
            this.MileageOut = (soHeaderRec.Odometer_on_Departure__c != null) ? soHeaderRec.Odometer_on_Departure__c : 0;
            this.MileageType = soHeaderRec.Customer_Owned_Unit__c != null ? soHeaderRec.Customer_Owned_Unit__r.Mileage_Type__c : '';
            this.Name = soHeaderRec.Name__c;
            this.CreatedDate = BPUtility.getFormatedDateTime(soHeaderRec.CreatedDate);
            if(soHeaderRec.Events__r.size() > 0) {
                this.Appointment = BPUtility.getFormatedDateTime(soHeaderRec.Events__r[0].Start_DateTime__c) + ' at ' + soHeaderRec.Events__r[0].Start_DateTime__c.format('h:mm a');
            }
            if(soHeaderRec.Invoice_Number__c != null) {
                this.Invoiced = (soHeaderRec.Invoice_Number__r.Invoice_Date__c != null) ? 
                    BPUtility.getFormatedDateTime(soHeaderRec.Invoice_Number__r.Invoice_Date__c) + ' - ' : '';
                this.Invoiced += soHeaderRec.Invoice_Number__r.Invoice_Number__c;
            }
            this.AssignedTo = String.isNotBlank(soHeaderRec.Technician_Name__c) ? soHeaderRec.Technician_Name__c.replaceAll(';', ', ') : '';
            
            this.SOGridItems = new List<SOHeaderWrapper.SOGrid>();
            List<DateTime> sortedDateTimeList = new List<dateTime>();
            Set<Id> soliIdSet = new Set<Id>();
            for(Service_Order_Kit_Header__c soKHRec : soKitHeaderList) {
                sortedDateTimeList.add( soKHRec.CreatedDate );
                this.SOGridItems.add(new SOHeaderWrapper.SOGrid(soKHRec, soKHRec.Service_Order_Line_Items__r, true));
                for(Service_Order_Line_Item__c soliRec : sokhRec.Service_Order_Line_Items__r) {
                    soliIdSet.add(soliRec.Id);
                } 
            }
            Integer lastIndexValue = 0;
            system.debug('Sorting Started OF SOLIs -->>');
            system.debug(sortedDateTimeList);
            
            isShopSupplySetValid = false;
            ShopSupplyDetailSet = new Set<String>();
            for(Service_Order_Line_Item__c soliRec : soHeaderRec.Service_Order_Line_Items__r) {
                if(!soliIdSet.contains(soliRec.Id)) {
                    for(Integer i = lastIndexValue; i < sortedDateTimeList.size(); i++){
                        system.debug(i);
                        if(sortedDateTimeList[i] < soliRec.CreatedDate){
                            lastIndexValue ++;
                        } else {
                            break;
                        }
                    }
                    if(this.SOGridItems.size() > lastIndexValue){
                        this.SOGridItems.add(lastIndexValue, new SOHeaderWrapper.SOGrid(new Service_Order_Kit_Header__c(), new List<Service_Order_Line_Item__c>{soliRec}, false));
                        
                        if(sortedDateTimeList.size() > lastIndexValue){
                            sortedDateTimeList.add(lastIndexValue, soliRec.CreatedDate);
                        } else {
                            sortedDateTimeList.add(soliRec.CreatedDate);
                        }
                        
                        lastIndexValue++;
                    } else {
                        this.SOGridItems.add(new SOHeaderWrapper.SOGrid(new Service_Order_Kit_Header__c(), new List<Service_Order_Line_Item__c>{soliRec}, false));
                        lastIndexValue++;
                    }
                    
                    if(soliRec.Labour_Code__c != null && soliRec.Labour_Code__r.Calculate_Supplies__c && soliRec.Labour_Code__r.Supplies_Detail__c != null) {
                        for(String shopSupplyDetailStr : soliRec.Labour_Code__r.Supplies_Detail__c.split('\n')) {
                            ShopSupplyDetailSet.add(shopSupplyDetailStr);
                            isShopSupplySetValid = true;
                        }
                    }
                }
            }
        }
    }
    
    public class WorksheetSummary {
        public Decimal TotalPart{get; private set;}
        public Decimal TotalLabor{get; private set;}
        public Decimal TotalSublet{get; private set;}
        public Decimal TotalFee{get; private set;}
        public Decimal SubTotal{get; private set;}
        public Decimal SalesTax{get; private set;}
        public Decimal Total{get; private set;}
        public Decimal TotalShopSupplies {get; private set;}
        public Decimal TotalDeductible {get; private set;}
        public Decimal ChargedOnAccount {get; private set;}
        public Decimal AmountPaid {get; private set;}
        public Decimal BalanceDue {get; private set;}
        public Decimal UnappliedDeposits {get; private set;}
        
        public List<TaxDetail> SalesTaxList{get; private set;}
        
        public WorksheetSummary(List<Service_Order_Header__c> soList,
                                    Map<String, Decimal> salesTaxNameToTaxValue, List<CO_Deposit__c> coDeposits) {
            this.TotalPart = 0;
            this.TotalLabor = 0;
            this.TotalSublet = 0;
            this.TotalFee = 0;
            this.SubTotal = 0;
            this.SalesTax = 0;
            this.Total = 0;
            this.TotalShopSupplies = 0;
            this.TotalDeductible = 0;
            this.ChargedOnAccount = this.AmountPaid = this.BalanceDue = this.UnappliedDeposits = 0;

            Set<String> closedINVHeaderIdSet = new Set<String>();
            Boolean isTaxIncludingPricing = GeneralConfiguration.getTaxIncludingPricing();
            for(Service_Order_Header__c soHeaderRec : soList) {
                if(soHeaderRec.Transaction_Type__r.Type__c.equalsIgnoreCase('Customer')) {
                    this.TotalPart += (soHeaderRec.Total_Parts__c != null) ? soHeaderRec.Total_Parts__c : 0;
                    this.TotalLabor += (soHeaderRec.Total_Labor__c != null) ? soHeaderRec.Total_Labor__c : 0;
                    this.TotalSublet += (soHeaderRec.Total_Sublet__c != null) ? soHeaderRec.Total_Sublet__c : 0;
                    this.TotalFee += (soHeaderRec.Total_Fees__c != null) ? soHeaderRec.Total_Fees__c : 0;
                    this.SubTotal += (soHeaderRec.Total__c != null) ? soHeaderRec.Total__c : 0;
                    this.Total += (soHeaderRec.Total__c != null) ? soHeaderRec.Total__c : 0;
                    this.TotalShopSupplies += (soHeaderRec.Total_Shop_Supplies__c != null) ? soHeaderRec.Total_Shop_Supplies__c : 0;

                    if(soHeaderRec.Invoice_Number__c != null) {
                        closedINVHeaderIdSet.add(soHeaderRec.Invoice_Number__c);
                    }

                } else if(soHeaderRec.Transaction_Type__r.Type__c.equalsIgnoreCase('Third-Party')) {
                    for(SO_Payment_Role__c soPaymentRole : soHeaderRec.SO_Payment_Roles__r) {
                        if(soPaymentRole.RecordType.DeveloperName == 'Deductible') {
                            soPaymentRole.Total_Amount__c = (soPaymentRole.Total_Amount__c != null ? soPaymentRole.Total_Amount__c : 0);
                            this.TotalDeductible += soPaymentRole.Total_Amount__c;
                            this.SubTotal += soPaymentRole.Total_Amount__c;
                            this.Total += soPaymentRole.Total_Amount__c;
                        }
                    }

                    for(CO_Invoice_Item__c invItemRec : soHeaderRec.CO_Invoice_Items__r) {
                        if(invItemRec.SO_Payment_Role__r.RecordType.DeveloperName == 'Deductible' && invItemRec.CO_Invoice_Header__r.Status__c.equalsIgnoreCase('Closed')) {
                            closedINVHeaderIdSet.add(invItemRec.CO_Invoice_Header__c);
                        }
                    }
                }
            }

            if(closedINVHeaderIdSet.size() > 0) {
                for(CO_Invoice_Payment__c invPayment : [Select Id, Amount__c, Payment_Method__c from CO_Invoice_Payment__c 
                where CO_Invoice_Header__c IN: closedINVHeaderIdSet AND Amount__c != null AND Payment_Method__c != null]) {
                    if(invPayment.Payment_Method__c.equalsIgnoreCase('Charge Account')) {
                        this.ChargedOnAccount += invPayment.Amount__c;
                    } else {
                        this.AmountPaid += invPayment.Amount__c;
                    }
                }
            }

            for(CO_Deposit__c coDepositRec : coDeposits) {
                if(coDepositRec.Payment_Method__c != 'Invoice' && coDepositRec.Deal__c == null) {
                    this.UnappliedDeposits += coDepositRec.Amount__c != null ? coDepositRec.Amount__c : 0;
                }
            }
            this.SalesTaxList = new List<TaxDetail>();
            for(String taxName : salesTaxNameToTaxValue.keySet()){
                this.SalesTaxList.add(new TaxDetail(taxName, salesTaxNameToTaxValue.get(taxName)));
                if(!GeneralConfiguration.getTaxIncludingPricing()){
                    this.Total += salesTaxNameToTaxValue.get(taxName);
                }
            }
            
            this.BalanceDue = (this.Total - (this.ChargedOnAccount + this.AmountPaid));
        }
    }
    
    public class TaxDetail{
        public String TaxName{get; private set;}
        public Decimal TaxAmount{get; private set;} 
        
        public TaxDetail(String taxName, Decimal taxAmount){
            if(taxAmount == null){
                taxAmount = 0;
            }
            this.TaxName = taxName;
            this.TaxAmount = taxAmount;
        }
    }

    public static List<String> getCustomerFieldsList(){
        List<String> customerFields = new List<String>{'Id',
                                                        'Name',
                                                        'Customer_Number__c',
                                                        'FirstName__c',
                                                        'LastName__c',
                                                        'Email__c',
                                                        'Home_Number__c',
                                                        'Mobile__c',
                                                        'Preferred_Phone__c',
                                                        'Work_Number__c',
                                                        'Home_Number_SMS__c',
                                                        'Mobile_Number_SMS__c', 
                                                        'Preferred_SMS__c',
                                                        'Work_Number_SMS__c',
                                                        'Other_Email__c',
                                                        'Preferred_Email__c',
                                                        'Work_Email__c',
                                                        'BillingStreet',
                                                        'BillingCity',
                                                        'BillingState',
                                                        'BillingCountry',
                                                        'BillingPostalCode',                                                        
                                                        'Formatted_Home_number__c',
                                                        'Formatted_Mobile_Number__c',
                                                        'Formatted_Work_Number__c',
                                                        'Formatted_Preferred_Phone__c'
                                                };
        return customerFields;
    }

    public static List<String> getSOHeaderFieldsList(){
        return new List<String>{ 'Id',
                                                        'Name__c',
                                                        'SO_Cause__c',
                                                        'SO_Concern__c',
                                                        'SO_Correction__c',
                                                        'Promised_By__c',
                                                        'Total__c',
                                                        'Stock__c',
                                                        'Estimated_Hours__c',
                                                        'Customer_Owned_Unit__r.VIN_Number__c',
                                                        'Customer_Owned_Unit__r.Unit_Id__c',
                                                        'Customer_Owned_Unit__r.Stock_Id__c',
                                                        'Customer_Owned_Unit__r.Unit_Type__c',
                                                        'Customer_Owned_Unit__r.Year__c',
                                                        'Customer_Owned_Unit__r.Unit_Make__r.Name',
                                                        'Customer_Owned_Unit__r.Unit_Model__r.Name__c',
                                                        'Customer_Owned_Unit__r.Unit_Model__r.Sub_Model__c',
                                                        'Customer_Owned_Unit__r.Sub_Model__r.Sub_Model_Name__c',
                                                        'Customer_Owned_Unit__r.Submodel__r.Name__c',
                                                        'Customer_Owned_Unit__r.Colour__c',
                                                        'Customer_Owned_Unit__r.Formatted_Name__c',
                                                        'Customer_Owned_Unit__r.Mileage_Type__c',
                                                        'Customer_Owned_Unit__r.Plate__c',
                                                        'Customer_Owned_Unit__r.Engine_Serial_No__c',
                                                        'Customer_Owned_Unit__r.Other_Serial_No__c',
                                                        'Customer_Owned_Unit__r.Unit_Data_01__c',
                                                        'Customer_Owned_Unit__r.Unit_Data_02__c',
                                                        'Customer_Owned_Unit__r.Unit_Data_03__c',
                                                        'Customer_Owned_Unit__r.Unit_Data_04__c',
                                                        'Customer_Owned_Unit__r.Unit_Data_05__c',
                                                        'Customer_Owned_Unit__r.Unit_Data_06__c',
                                                        'Customer_Owned_Unit__r.Unit_Data_07__c',
                                                        'Customer_Owned_Unit__r.Unit_Data_08__c',
                                                        'Customer_Owned_Unit__r.Unit_Data_09__c',
                                                        'Customer_Owned_Unit__r.Unit_Data_10__c',
                                                        'Customer_Owned_Unit__r.Unit_Data_11__c',
                                                        'Customer_Owned_Unit__r.Unit_Data_12__c',
                                                        'Customer_Owned_Unit__r.Unit_Data_13__c',
                                                        'Customer_Owned_Unit__r.Unit_Data_14__c',
                                                        'Customer_Owned_Unit__r.Unit_Data_15__c',
                                                        'CO_Header__c',
                                                        'Provider__c',
                                                        'Provider__r.Name',
                                                        'Category__c',
                                                        'Category__r.Name',
                                                        'Odometer_on_Arrival__c',
                                                        'Odometer_on_Departure__c',
                                                        'Transaction_Type__c',
                                                        'SO_Notes_For_Customer__c',
                                                        'Transaction_Type__r.Type__c',
                                                        'Transaction_Type__r.Code_Label__c',
                                                        'IsPromisedBy_AmPm__c',            
                                                        'Status__c',   
                                                        'SO_Notes__c',
                                                        'Work_Status__c',
                                                        'Claim_Status__c',
                                                        'Deal_Item__c',
                                                        'Deal__c',
                                                        'Scheduled_Date__c',
                                                        'CO_Header__r.Invoiced_Amount__c',
                                                        'CO_Header__r.Uninvoiced_Amount__c',
                                                        'CO_Header__r.Total_Payment__c',
                                                        'Total_Parts__c',
                                                        'Total_Fees__c',
                                                        'Total_Labor__c',
                                                        'Total_Sublet__c',
                                                        'Total_Tax__c',
                                                        'Total_With_Tax__c',
                                                        'Total_Shop_Supplies__c',
                                                        'CreatedDate',
                                                        'Unit_Arrived__c',
                                                        'Due_In_DateTime__c',
                                                        'Promised_By_DateTime__c',
                                                        'Due_In_Time__c',
                                                        'Promised_By_Time__c',
                                                        'Customer_Owned_Unit__r.Notes__c',
                                                        'Unit_Location__c',
                                                        'Actual_Invoice_Date_Time__c',
                                                        'Invoice_Number__r.Invoice_Date__c',
                                                        'Invoice_Number__r.Invoice_Number__c',
                                                        'Technician_Name__c'
                                                };
    }
}