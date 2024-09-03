public without sharing class PrintPaymentOnAccountCtrl {
    
    public POADetail poaObj {get; private set;}
    public PrintPaymentOnAccountCtrl() {
        poaObj = new POADetail(getPOARecord(ApexPages.currentPage().getParameters().get('id')));
    }

    private Payment_on_Account__c getPOARecord(String poaId) {
        poaId = String.escapeSingleQuotes(poaId);
        return [SELECT Total_Payment__c,
                (SELECT Id, Name, CO_Invoice_Header__r.Invoice_Number__c, 
                Amount_Paid__c, Invoice_Date__c, Original_Amount__c 
                FROM AR_Payments__r) 
                FROM Payment_on_Account__c WHERE Id = :poaId LIMIT 1];
    }

    public class POADetail {
        public String Id {get;set;}
        public Decimal AmountPaid {get;set;}
        public List<ARPWrapper> arPayWrapperList {get;set;}
    
        public POADetail(Payment_on_Account__c poaRec) {
            this.Id = poaRec.Id;
            this.AmountPaid = poaRec.Total_Payment__c != null ? poaRec.Total_Payment__c : 0.00;
            this.arPayWrapperList = new List<ARPWrapper>();
            for(AR_Payment__c arPayRec: poaRec.AR_Payments__r) {
                arPayWrapperList.add(new ARPWrapper(arPayRec));
            }
        }
    }

    public class ARPWrapper {
        public String InvoiceNumber {get;set;}
        public String InvoiceDate {get;set;}
        public Decimal OriginalAmount {get;set;}
        public Decimal AmountPaid {get;set;}

        public ARPWrapper(AR_Payment__c arPayRec) {
            this.InvoiceNumber = arPayRec.CO_Invoice_Header__c != null ? arPayRec.CO_Invoice_Header__r.Invoice_Number__c : arPayRec.Name;
            this.OriginalAmount = arPayRec.Original_Amount__c != null ? arPayRec.Original_Amount__c : 0.00;
            this.AmountPaid = arPayRec.Amount_Paid__c != null ? arPayRec.Amount_Paid__c : 0.00;
            this.InvoiceDate = String.valueOf(arPayRec.Invoice_Date__c);
        }
    }
}