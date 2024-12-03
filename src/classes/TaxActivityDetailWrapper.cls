/**
 * Author: Nidhi Sharma
 * Since: March 26, 2024
 * Name: TaxActivityDetailWrapper
 * Description: 
**/
public without sharing class TaxActivityDetailWrapper {

    public TaxTypeWrapper SalesTaxActivityObj = new TaxTypeWrapper();
    public TaxTypeWrapper PurchaseTaxActivityObj = new TaxTypeWrapper();

    public class TaxTypeWrapper {
        public Decimal TaxAmount = 0;
        public Decimal TaxableAmount = 0;
        public Decimal NonTaxableAmount = 0;
        public List<TaxWrapper> TaxDetails;
    }

    public class TaxWrapper {
        public String TaxName;
        //public Integer TxnCount;
        public Decimal TaxableAmount;
        public Decimal TaxAmount;
        public Decimal NonTaxableAmount;
        public List<ActivityWrapper> Activities;
    }

    public class ActivityWrapper {
        public String Id;
        public String DocNumber;
        public String TxnDate;
        public String TxnType;
        public String RelatedTo;
        public Decimal TaxableAmount;
        public Decimal TaxRate;
        public Decimal TaxAmount;
        public Decimal NonTaxableAmount;
        public String Contents;
        
        public ActivityWrapper(Unit_Price_Cost__c upcRec, Decimal taxableAmount, Decimal taxRate, Decimal taxAmount, Decimal nonTaxableAmount) {
            if(upcRec != null) {
                this.Id = upcRec.Customer_Owned_Unit__c;
                this.TxnDate = upcRec.Adjustment_Date__c != null ? BPUtility.getFormatedDateTime(upcRec.Adjustment_Date__c) : '';
                if(upcRec.Vendor__c != null) {
                    this.DocNumber = upcRec.Vendor_Reference_Number__c;
                    this.RelatedTo = upcRec.Vendor__r.Name;
                } else if(upcRec.Customer__c != null) {
                    this.DocNumber = upcRec.Customer_Reference_Number__c;
                    this.RelatedTo = upcRec.Customer__r.Name;
                }
            }
            this.Contents = 'Unit adjustment';
            setFields(TaxActivityAndSettingService.UNIT_ADJUSTMENT, taxableAmount, taxRate, taxAmount, nonTaxableAmount);
        }

        public ActivityWrapper(Return_CR_Header__c vendorCreditRec, Decimal taxableAmount, Decimal taxRate, Decimal taxAmount, Decimal nonTaxableAmount) {
            if(vendorCreditRec != null) {
                this.Id = vendorCreditRec.Id;
                this.DocNumber = vendorCreditRec.Credit_Memo__c;
                this.RelatedTo = vendorCreditRec.Vendor__r.Name;
                this.TxnDate = vendorCreditRec.Credited_Date__c != null ? 
                    BPUtility.getFormatedDateTime(datetime.newInstance(vendorCreditRec.Credited_Date__c.year(), 
                    vendorCreditRec.Credited_Date__c.month(), vendorCreditRec.Credited_Date__c.day())) : '';
            }
            this.Contents = 'Parts return';
            setFields(TaxActivityAndSettingService.VENDOR_CREDIT, taxableAmount, taxRate, taxAmount, nonTaxableAmount);
        }

        public ActivityWrapper(Customer_Owned_Unit__c unitRec, Decimal taxableAmount, Decimal taxRate, Decimal taxAmount, Decimal nonTaxableAmount) {
            if(unitRec != null) {
                this.Id = unitRec.Id;
                this.DocNumber = unitRec.Referenced_Unit__r.Invoice_Number__c;
                this.TxnDate = unitRec.Date_Stocked_In__c != null ? BPUtility.getFormatedDateTime(unitRec.Date_Stocked_In__c) : '';
                this.RelatedTo = unitRec.Referenced_Unit__r.Vendor__r.Name;
            }
            this.Contents = 'Unit purchase';
            setFields(TaxActivityAndSettingService.UNIT_INVOICE, taxableAmount, taxRate, taxAmount, nonTaxableAmount);
        }

        public ActivityWrapper(Vendor_Invoicing_Header__c viRec, Decimal taxableAmount, Decimal taxRate, Decimal taxAmount, Decimal nonTaxableAmount, Set<String> contentSet) {
            if(viRec != null) {
                this.Id = viRec.Id;
                this.DocNumber = viRec.Vendor_Invoice_Number__c;
                this.TxnDate = viRec.Invoice_Date__c != null ? 
                    BPUtility.getFormatedDateTime(datetime.newInstance(viRec.Invoice_Date__c.year(), 
                    viRec.Invoice_Date__c.month(), viRec.Invoice_Date__c.day())) : '';
                this.RelatedTo = viRec.Vendor__r.Name;
            }
            if(contentSet != null) {
                List<String> contentsList = new List<String>(contentSet);
                contentsList.sort();
                this.Contents = String.join(contentsList, ', ');
            }
            setFields(TaxActivityAndSettingService.VO_INVOICE, taxableAmount, taxRate, taxAmount, nonTaxableAmount);
        }

        public ActivityWrapper(CO_Invoice_Header__c invRec, Decimal taxableAmount, Decimal taxRate, Decimal taxAmount, Decimal nonTaxableAmount, Set<String> contentSet) {
            if(invRec != null) {
                this.Id = invRec.CO_Header__c;
                this.DocNumber = invRec.Invoice_Number__c;
                this.TxnDate = (invRec.Invoice_Date__c != null) ? BPUtility.getFormatedDateTime(invRec.Invoice_Date__c) : null;
                this.RelatedTo = invRec.CO_Header__r.Customer_Name__c;
            }
            if(contentSet != null) {
                List<String> contentsList = new List<String>(contentSet);
                contentsList.sort();
                this.Contents = String.join(contentsList, ', ');
            }
            setFields(TaxActivityAndSettingService.CO_INVOICE, taxableAmount, taxRate, taxAmount, nonTaxableAmount);
        }

        private void setFields(String txnType, Decimal taxableAmount, Decimal taxRate, Decimal taxAmount, Decimal nonTaxableAmount) {
            this.TxnType = txnType;
            this.TaxableAmount = taxableAmount;
            this.TaxRate = taxRate;
            this.TaxAmount = taxAmount;
            this.NonTaxableAmount = nonTaxableAmount;
        }
    }

    public class ActivityReportFilterWrapper {
        public String entityName;
        public String startDate;
        public String endDate;
        public Boolean excludeInternalInvoices;
    }
}