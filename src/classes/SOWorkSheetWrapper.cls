/**
* Author: Nidhi Sharma
* Since: September 24, 2016
* Name: SOWorkSheetWrapper
* Description: Wrapper class to handle JSON variables for SO worksheet. Created for ticket #129
**/

public class SOWorkSheetWrapper {
    public CustomerDetail.Company StoreInfo{get; private set;}
    public COWrapper COHeaderInfo{get; private set;}
    public List<UnitWrapper> UnitList{get; private set;}
    public Boolean IsPrintPreview{get; private set;}
    public WorksheetSummary WorksheetTotal{get; private set;}
    public Boolean IsTaxIncludePricing{get; private set;}
    public Boolean IsHideHoursRateOnServiceDocuments{get; private set;}
    public Boolean IsItemizedByLaborCode {get; set;}
    public String ServiceJobWarrantyText{get; private set;}
	public Boolean IsSignatureLineforServiceJob{get; private set;}

    public SOWorkSheetWrapper(List<Customer_Owned_Unit__c> unitList, List<Service_Order_Header__c> soHeaderList, 
                                BrandingLocationWrapper brandingLocationObj, List<Account> customerList,
                                CO_Header__c coHeaderRec, Boolean isPrint, Map<String, Decimal> salesTaxNameToTaxValue) {
        
        this.COHeaderInfo = new COWrapper(coHeaderRec);                     
        if(brandingLocationObj != null) {
        	this.StoreInfo = new CustomerDetail.Company(brandingLocationObj);
	        this.ServiceJobWarrantyText = (brandingLocationObj.DisclaimerforServiceJob != null) ? brandingLocationObj.DisclaimerforServiceJob : '';
	        this.IsSignatureLineforServiceJob = brandingLocationObj.IsSignatureforServiceJob;
        }
        this.UnitList = new List<UnitWrapper>();
        
        Map<Id, Customer_Owned_Unit__c> unitIdToUnitMap = new Map<Id, Customer_Owned_Unit__c>();
        Map<Id, List<Service_Order_Header__c>> unitIdToSOHeaderMap = new Map<Id, List<Service_Order_Header__c>>();
        
        for(Customer_Owned_Unit__c unitRec : unitList) {
            unitIdToUnitMap.put(unitRec.Id, unitRec);
        }
        
        for(Service_Order_Header__c soHeaderRec : soHeaderList) {
            if(soHeaderRec.Customer_Owned_Unit__c != null) {
                if(unitIdToSOHeaderMap.containsKey(soHeaderRec.Customer_Owned_Unit__c)) {
                    unitIdToSOHeaderMap.get(soHeaderRec.Customer_Owned_Unit__c).add(soHeaderRec);
                } else {
                    unitIdToSOHeaderMap.put(soHeaderRec.Customer_Owned_Unit__c, new List<Service_Order_Header__c>{soHeaderRec});
                }
            }
        } 
        
        for(Id unitId : unitIdToUnitMap.keySet()) {
            List<Service_Order_Header__c> sohList = (unitIdToSOHeaderMap.containsKey(unitId)) ? 
                                                            (unitIdToSOHeaderMap.get(unitId)) : new List<Service_Order_Header__c>();
            if(customerList.size() > 0) {                                               
                this.UnitList.add(new UnitWrapper(unitIdToUnitMap.get(unitId), sohList, customerList[0]));
            } else {
                this.UnitList.add(new UnitWrapper(unitIdToUnitMap.get(unitId), sohList, new Account()));
            }
        }
        this.IsPrintPreview = isPrint;
        this.WorksheetTotal = new WorksheetSummary(unitIdToSOHeaderMap, salesTaxNameToTaxValue);
        this.IsTaxIncludePricing = GeneralConfiguration.getTaxIncludingPricing();
        this.IsHideHoursRateOnServiceDocuments = GeneralConfiguration.isHideHoursRateOnServiceDocument();
        this.IsItemizedByLaborCode = GeneralConfiguration.isCalculationMethodAvailable() && GeneralConfiguration.isItemizedByLaborCode();
    }
    
    public class COWrapper {
        public String Name{get; private set;} 
        public String Status{get; private set;} 
         
        public COWrapper(CO_Header__c coHeaderRec) {
            this.Name = coHeaderRec.Name;
            this.Status = coHeaderRec.Status__c;
        }
    }
    
    public class UnitWrapper {
        public CustomerInfoWrapper CustomerInfo{get; private set;}
        public UnitInfoWrapper UnitInfo{get; private set;}
        public List<SOWrapper> SOHeaderList{get; private set;}
        
        public UnitWrapper(Customer_Owned_Unit__c unitRec, List<Service_Order_Header__c> serviceOrderList, Account customer) {
            this.CustomerInfo = new CustomerInfoWrapper(customer);
            this.SOHeaderList = new List<SOWrapper>();
            
            if(unitRec != null) {
                this.UnitInfo = new UnitInfoWrapper(unitRec);
            }
            
            Map<Id, List<Service_Order_Kit_Header__c>> soHeaderIdToSOKitHeaderListMap = PrintCustomerOrderInvoiceCtrl.getSOIdToSOKitHeaderListMap(serviceOrderList);
            for(Service_Order_Header__c soHeaderRec : serviceOrderList) {
                List<Service_Order_Kit_Header__c> sokitHeadersList = soHeaderIdToSOKitHeaderListMap.containsKey(soHeaderRec.Id) ? soHeaderIdToSOKitHeaderListMap.get(soHeaderRec.Id) : new List<Service_Order_Kit_Header__c>();
                this.SOHeaderList.add(new SOWrapper(soHeaderRec, sokitHeadersList));
            }
        }
    }
    
    public class CustomerInfoWrapper {
        public String CustomerName{get; private set;}
        public String Email{get; private set;}
        public String Phone{get; private set;}
        public String BillingStreet1{get; private set;} 
        public String BillingStreet2{get; private set;}
        public String BillingCity{get; private set;}
        public String BillingState{get; private set;}
        public String BillingCountry{get; private set;}
        public String BillingPostalCode{get; private set;}
            
        public CustomerInfoWrapper(Account customerRec) {
            this.CustomerName = customerRec.Name;
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
                if(customerRec.Home_Number__c != null) {
                    this.Phone = customerRec.Home_Number__c;
                } else if(customerRec.Mobile__c != null) {
                    this.Phone = customerRec.Mobile__c;
                } else if(customerRec.Work_Number__c != null) {
                    this.Phone = customerRec.Work_Number__c;
                }
            } else {
                this.Phone = customerRec.Preferred_Phone__c;
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
    
    public class UnitInfoWrapper {
        public String VINNumber{get; private set;}
        public Decimal Year{get; private set;}
        public String MakeName{get; private set;}
        public String Rego{get; private set;}
        public String Mileage{get; private set;}
        public String ModelName{get; private set;}
        public String SubModelName{get; private set;}
        public String Colour{get; private set;}
        public String StockNumber{get; private set;}
        public String MakeModelDescription{get; private set;}
        
        public UnitInfoWrapper(Customer_Owned_Unit__c unitRec) {
            this.VINNumber = unitRec.VIN_Number__c;
            this.Year = unitRec.Year__c;
            this.MakeName = (unitRec.Unit_Make__c != null) ? unitRec.Unit_Make__r.Name : '';
            this.Colour = (unitRec.Colour__c != null) ? unitRec.Colour__c : '';
            if(unitRec.Unit_Model__c != null) {
                this.ModelName = unitRec.Unit_Model__r.Name__c;
            } else {
                this.ModelName = '';
            }
            this.Mileage = (unitRec.Mileage_Value__c != null) ? unitRec.Mileage_Value__c + ' ' + unitRec.Mileage_Type__c : '';
            this.Rego = (unitRec.Plate__c != null) ? unitRec.Plate__c : '';
            this.SubModelName = (unitRec.Sub_Model__c != null) ? unitRec.Sub_Model__r.Sub_Model_Name__c : '';
            this.MakeModelDescription = (unitRec.Sub_Model__c != null) ? unitRec.Sub_Model__r.Description__c : '';
            this.StockNumber = unitRec.Stock_Id__c;
        }
    }
    
    public class SOWrapper {
        public List<String> CauseList{get; private set;}
        public List<String> CorrectionList{get; private set;}
        public List<String> ConcernList{get; private set;}
        public List<String> ManualNotes{get; private set;}
        public String SoHeaderName{get; private set;}
        public String Id{get; private set;}
        public String SoHeaderInvoiceStatus{get; private set;}
        public List<SOLIWrapper> SOLIList{get; private set;}
        public Decimal Total{get; private set;}
        public Decimal MileageIn{get; private set;}
        public Decimal MileageOut{get; private set;}
        public String MileageType{get; private set;}
        public List<SOHeaderWrapper.SOGrid> SOGridItems{get; private set;} // Added by richa 14 april
        public String CreatedDate{get; private set;}
        
        public Decimal ShopSupplyTotal {get; private set;}
        public Set<String> ShopSupplyDetailSet {get; private set;}
        
        /*public SOWrapper(Service_Order_Header__c soHeaderRec) {
            this.Id = soHeaderRec.Id;
            this.CauseList = new List<String>();
            this.CorrectionList = new List<String>();
            this.ConcernList = new List<String>();
            this.MileageIn = (soHeaderRec.Odometer_on_Arrival__c != null) ? soHeaderRec.Odometer_on_Arrival__c : 0;
            this.MileageOut = (soHeaderRec.Odometer_on_Departure__c != null) ? soHeaderRec.Odometer_on_Departure__c : 0;
            this.MileageType = soHeaderRec.Customer_Owned_Unit__c != null ? soHeaderRec.Customer_Owned_Unit__r.Mileage_Type__c : '';
            
            if(soHeaderRec.SO_Cause__c != null) {
                for(String cause : soHeaderRec.SO_Cause__c.split('\n')) {
                    this.CauseList.add(cause);  
                }
            }
            
            if(soHeaderRec.SO_Correction__c != null)    {
                for(String correction : soHeaderRec.SO_Correction__c.split('\n'))   {
                    this.CorrectionList.add(correction);    
                }
            }
            
            if(soHeaderRec.SO_Concern__c != null)   {
                for(String concern : soHeaderRec.SO_Concern__c.split('\n')) {
                    this.ConcernList.add(concern);  
                }
            }
            
            this.ManualNotes = (soHeaderRec.SO_Notes_For_Customer__c != null) ? soHeaderRec.SO_Notes_For_Customer__c.split('\n') : new List<String>();
            this.SOLIList = new List<SOLIWrapper>();
            for(Service_Order_Line_Item__c soliRec : soHeaderRec.Service_Order_Line_Items__r) {
                this.SOLIList.add(new SOLIWrapper(soliRec));
            }
            this.Total =  soHeaderRec.Total__c;
            this.SoHeaderName = soHeaderRec.Name__c;
        }*/
        
        public SOWrapper(Service_Order_Header__c soHeaderRec, List<Service_Order_Kit_Header__c> soKitHeaderList) {
            this.Id = soHeaderRec.Id;
             
            this.CauseList = (soHeaderRec.SO_Cause__c != null) ? ServiceJobService.getDeclineAddedNotesList(soHeaderRec.SO_Cause__c.split('\n')) : new List<String>();
            this.CorrectionList = (soHeaderRec.SO_Correction__c != null) ? ServiceJobService.getDeclineAddedNotesList(soHeaderRec.SO_Correction__c.split('\n')) : new List<String>();
            this.ConcernList = (soHeaderRec.SO_Concern__c != null) ? ServiceJobService.getDeclineAddedNotesList(soHeaderRec.SO_Concern__c.split('\n')) : new List<String>();
            this.ManualNotes = (soHeaderRec.SO_Notes_For_Customer__c != null) ? ServiceJobService.getDeclineAddedNotesList(soHeaderRec.SO_Notes_For_Customer__c.split('\n')) : new List<String>();
            this.SOLIList = new List<SOLIWrapper>();
            for(Service_Order_Line_Item__c soliRec : soHeaderRec.Service_Order_Line_Items__r) {
                this.SOLIList.add(new SOLIWrapper(soliRec));
            }
            this.ShopSupplyTotal = (soHeaderRec.Total_Shop_Supplies__c != null) ? soHeaderRec.Total_Shop_Supplies__c : 0;
            this.Total =  soHeaderRec.Total__c;
            this.MileageIn = (soHeaderRec.Odometer_on_Arrival__c != null) ? soHeaderRec.Odometer_on_Arrival__c : 0;
            this.MileageOut = (soHeaderRec.Odometer_on_Departure__c != null) ? soHeaderRec.Odometer_on_Departure__c : 0;
            this.MileageType = soHeaderRec.Customer_Owned_Unit__c != null ? soHeaderRec.Customer_Owned_Unit__r.Mileage_Type__c : '';
            this.SoHeaderName = soHeaderRec.Name__c;
            this.SoHeaderInvoiceStatus = soHeaderRec.SO_Status__c;
            this.CreatedDate = BPUtility.getFormatedDateTime(soHeaderRec.CreatedDate);
            
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
                        }
                    }
                }
            }
        }
    }
    
    public class SOLIWrapper {
        public String ItemDesc{get; private set;}
        public String Type{get; private set;} 
        public Decimal Need{get; private set;}
        public Decimal StockCommited{get; private set;}
        public String Status{get; private set;}
        public Decimal Price{get; private set;}
        public Decimal Total{get; private set;}
        public Boolean IsNonInventoryPart{get; private set;}
        
        public SOLIWrapper(Service_Order_Line_Item__c soliRec) {
            String itemCode = (soliRec.Item_Code__c != null) ? soliRec.Item_Code__c : '';
            String itemDescription = (soliRec.Item_Description__c != null) ? soliRec.Item_Description__c : '';
            this.ItemDesc = itemCode + ' - ' + itemDescription;
            
            if(soliRec.Part__c != null) {
                this.Type = 'Part'; 
                this.IsNonInventoryPart = soliRec.Part__r.Non_Inventory_Part__c;
            } else if(soliRec.Labour_Code__c != null) {
                this.Type = 'Labor';    
            } else if(soliRec.Fee__c != null) {
                this.Type = 'Fee';  
            }
            this.Need = (soliRec.Qty_Needed__c != null ) ? soliRec.Qty_Needed__c : 0;
            this.StockCommited = (soliRec.Qty_Committed__c != null) ? soliRec.Qty_Committed__c : 0;
            
            if(soliRec.CO_Line_Item__r.Closed_CO_Invoice_link__c != null) {
                this.Status = 'Invoiced'; 
            } else {
                if(this.Need == this.StockCommited) {
                    this.Status = 'In Stock';
                } else if(this.Need > this.StockCommited) {
                    if(soliRec.CO_Line_Item__c != null && !soliRec.CO_Line_Item__r.Special_Order__c) {
                        this.Status = 'Required';
                    } else {
                        this.Status = 'Ordered';
                    }
                } else if(soliRec.Qty_Needed__c < 0) {
                    this.Status = 'RETURN';
                }
            }
            
            if(soliRec.Labour_Code__c != null || soliRec.Fee__c != null) {
                this.Status = 'Ready';
            }
            
            Boolean isTaxIncludingPricing = GeneralConfiguration.getTaxIncludingPricing();
            if(isTaxIncludingPricing && String.isBlank(soliRec.Deal__c)) {
                if(soliRec.Tax_Percent__c == null) {
                    soliRec.Tax_Percent__c = 0;
                }
                if(soliRec.Kit_Price__c == null) {
                    soliRec.Kit_Price__c = 0;
                }
                this.Price = (soliRec.Kit_Price__c * (1 + (soliRec.Tax_Percent__c / 100))).setScale(2, RoundingMode.HALF_UP);
            } else {
                this.Price = (soliRec.Kit_Price__c != null) ? soliRec.Kit_Price__c.SetScale(2, RoundingMode.HALF_UP) : soliRec.Kit_Price__c;
            }
            if(this.Price == null) {
                this.Price = 0;
            }
            this.Total = this.Price * this.Need;
        }
    }
    
    public class ServiceWorkSheetPrintDetail {
        public String UnitId{get; private set;}
        public String VINNumber{get; private set;}
        public Boolean IsUnitSelected{get; private set;}
        public List<SOInfoWrapper> SOInfoWrapperList{get; private set;}
        public Boolean IsPrintPreview{get; private set;}
        public String UnitName{get; private set;}
    
        public ServiceWorkSheetPrintDetail(Customer_Owned_Unit__c unitRec, List<Service_Order_Header__c> soHeaderList) {
            this.UnitId = unitRec.Id;
            this.VinNumber = unitRec.VIN_Number__c;
            this.IsUnitSelected = true;
            this.SOInfoWrapperList = new List<SOInfoWrapper>(); 
            for(Service_Order_Header__c soHeaderRec : soHeaderList) {
                SOInfoWrapperList.add(new SOInfoWrapper(soHeaderRec));
            }
            this.IsPrintPreview = false;
            this.UnitName = unitRec.Search_Tag__c; // Custom logic to get formatted Name
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
        public List<TaxDetail> SalesTaxList{get; private set;}
        
        public WorksheetSummary(Map<Id, List<Service_Order_Header__c>> unitIdToSOHeaderMap,
                                    Map<String, Decimal> salesTaxNameToTaxValue) {
            this.TotalPart = 0;
            this.TotalLabor = 0;
            this.TotalSublet = 0;
            this.TotalFee = 0;
            this.SubTotal = 0;
            this.SalesTax = 0;
            this.Total = 0;
            this.TotalShopSupplies = 0;
            
            Boolean isTaxIncludingPricing = GeneralConfiguration.getTaxIncludingPricing();
            for(List<Service_Order_Header__c> soHeaderList : unitIdToSOHeaderMap.values()) {
                for(Service_Order_Header__c soHeaderRec : soHeaderList) {
                    this.TotalPart += (soHeaderRec.Total_Parts__c != null) ? soHeaderRec.Total_Parts__c : 0;
                    this.TotalLabor += (soHeaderRec.Total_Labor__c != null) ? soHeaderRec.Total_Labor__c : 0;
                    this.TotalSublet += (soHeaderRec.Total_Sublet__c != null) ? soHeaderRec.Total_Sublet__c : 0;
                    this.TotalFee += (soHeaderRec.Total_Fees__c != null) ? soHeaderRec.Total_Fees__c : 0;
                    this.SubTotal += (soHeaderRec.Total__c != null) ? soHeaderRec.Total__c : 0;
                    this.Total += (soHeaderRec.Total__c != null) ? soHeaderRec.Total__c : 0;
                    this.TotalShopSupplies += (soHeaderRec.Total_Shop_Supplies__c != null) ? soHeaderRec.Total_Shop_Supplies__c : 0;
                }
            }
            
            this.SalesTaxList = new List<TaxDetail>();
            for(String taxName : salesTaxNameToTaxValue.keySet()){
                this.SalesTaxList.add(new TaxDetail(taxName, salesTaxNameToTaxValue.get(taxName)));
                if(!GeneralConfiguration.getTaxIncludingPricing()){
                    this.Total += salesTaxNameToTaxValue.get(taxName);
                }
            }
        }
    }
    
    
    public class SOInfoWrapper {
        public String SOHeaderId{get; private set;}
        public String Name{get; private set;}
        public Boolean IsSOHeaderSelected{get; private set;}
        public String JobType{get; private set;}
        public String TransactionType{get; private set;}
        public String WorkStatus{get; private set;}
        
        public SOInfoWrapper(Service_Order_Header__c serviceOrderRec) {
            this.SOHeaderId = serviceOrderRec.Id;
            this.Name = serviceOrderRec.Name__c;
            this.IsSOHeaderSelected = true;     
            this.JobType =  serviceOrderRec.Transaction_Type__r.Code_Label__c;
            this.TransactionType = serviceOrderRec.Transaction_Type__r.Type__c;
            this.WorkStatus =   serviceOrderRec.SO_Status__c;
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
}