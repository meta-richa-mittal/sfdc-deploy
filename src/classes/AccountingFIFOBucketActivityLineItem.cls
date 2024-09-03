/**
 * Author: Richa Mittal
 * Since: Jan 2, 2017
 * Name: AccountingFIFOBucketActivityLineItem
 * Description: Apex class to handle JSON related oprations of FIFO Bucket Activity Line Item for Accounting.
**/
public without sharing class AccountingFIFOBucketActivityLineItem {
    public String Id {get; set;}
    // Cost
    public Decimal Cost;
    
    // PartDesc
    public String PartDesc;
    
    public String PartNumber;
        
    public String PartId;
        
    // Name
    public String Name;
    
    // Name
    public Date CreatedDate;
    
    public String VendorName;
    
    public Decimal QtyOut;
    
    public String Reference;
    
    public String FIFOSource;
    
    public String COGS_GL;
        
    public String Income_GL;
    
    public String Inventory_GL;
    
    // AccountingId
    public String AccountingId;
    public String XeroAccountingId;
    
    // SyncToken
    public String SyncToken;
    
    public String accountingResponse;
    
    //EntityRefWrapper
    public EntityRefWrapper EntityRef;
    
    public String UniqueId;
    
    //Return VO
    public String RMANumber;
    
    public String ReturnVOHeaderId;

    public Decimal BucketQtyRemaining;
    public Decimal BucketQtyIn;
    public Decimal BucketQtyOut;
    public Decimal BucketCost;
    
    // Constructor
    public AccountingFIFOBucketActivityLineItem(Part_FIFO_Bucket_Activity_Line_Item__c partFIFOBucketActivityLineItemRec) {
    	this.Id = partFIFOBucketActivityLineItemRec.Id;
        this.Cost = partFIFOBucketActivityLineItemRec.Part_FIFO_Bucket__r.Cost__c;
        this.QtyOut = partFIFOBucketActivityLineItemRec.Qty_Out__c;
        this.BucketQtyRemaining = partFIFOBucketActivityLineItemRec.Part_FIFO_Bucket__r.Remaining_Qty__c != null ? partFIFOBucketActivityLineItemRec.Part_FIFO_Bucket__r.Remaining_Qty__c : 0;
        this.BucketQtyIn = partFIFOBucketActivityLineItemRec.Part_FIFO_Bucket__r.Qty_In__c != null ? partFIFOBucketActivityLineItemRec.Part_FIFO_Bucket__r.Qty_In__c : 0;
        this.BucketQtyOut = partFIFOBucketActivityLineItemRec.Part_FIFO_Bucket__r.Qty_Out__c != null ? partFIFOBucketActivityLineItemRec.Part_FIFO_Bucket__r.Qty_Out__c : 0;
        this.BucketCost = partFIFOBucketActivityLineItemRec.Part_FIFO_Bucket__r.Cost__c != null ? partFIFOBucketActivityLineItemRec.Part_FIFO_Bucket__r.Cost__c.setScale(2, RoundingMode.HALF_UP) : 0;
        //this.PartDesc = partFIFOBucketActivityLineItemRec.Part_FIFO_Bucket__r.Part__r.Item_Description__c;
        this.PartDesc = partFIFOBucketActivityLineItemRec.Part_FIFO_Bucket__r.Part__r.Part_Number__c + ' - ' + partFIFOBucketActivityLineItemRec.Part_FIFO_Bucket__r.Part__r.Description__c;
        this.Name = partFIFOBucketActivityLineItemRec.Name;
        this.PartNumber = partFIFOBucketActivityLineItemRec.Part_FIFO_Bucket__r.Part__r.Part_Number__c;
        this.PartId = partFIFOBucketActivityLineItemRec.Part_FIFO_Bucket__r.Part__c;
        this.CreatedDate = DateTimeUtility.getDateFromFormattedDateStr(DateTimeUtility.getFormttedDateFromDateTime(partFIFOBucketActivityLineItemRec.CreatedDate, 'dd/MM/yyyy'));
        this.VendorName = partFIFOBucketActivityLineItemRec.Part_FIFO_Bucket__r.Part__r.Vendor__r.Name;
        this.FIFOSource = partFIFOBucketActivityLineItemRec.Part_FIFO_Bucket__r.Source_Name__c;
        String ref = partFIFOBucketActivityLineItemRec.Reference__c != null ? partFIFOBucketActivityLineItemRec.Reference__c : '';
        
        if(String.isNotBlank(ref) && ref.startsWithIgnoreCase('Presold on')) {
        	ref = 'Pre Sold Cost Adjustment On New FIFO';
        } else if(String.isNotBlank(partFIFOBucketActivityLineItemRec.Part_Adjustment__r.Reference__c) && String.isNotBlank(partFIFOBucketActivityLineItemRec.Unique_Id__c) && partFIFOBucketActivityLineItemRec.Unique_Id__c.containsIgnoreCase('Presold') && partFIFOBucketActivityLineItemRec.Part_Adjustment__r.Reference__c.startsWithIgnoreCase('Re:')) { // Added condition to Check it is come from presold cost adjustment
            ref = 'Pre Sold Cost Adjustment On Existing FIFO';
        } else if(!ref.equalsIgnoreCase('Count Adjustment') && !ref.equalsIgnoreCase('Cost Adjustment') && this.FIFOSource.equalsIgnoreCase('Cost Adjust')) {
        	ref = 'Cost Adjustment';
        }
        this.Reference = ref;
        
        this.COGS_GL = partFIFOBucketActivityLineItemRec.Part_FIFO_Bucket__r.Part__r.Category__r.COGS_GL__c;
        this.Income_GL = partFIFOBucketActivityLineItemRec.Part_FIFO_Bucket__r.Part__r.Category__r.Income_GL__c;
        this.Inventory_GL = partFIFOBucketActivityLineItemRec.Part_FIFO_Bucket__r.Part__r.Category__r.Inventory_GL__c;
        
        this.AccountingId = partFIFOBucketActivityLineItemRec.AccountingId__c;
        this.XeroAccountingId = partFIFOBucketActivityLineItemRec.Xero_Accounting_Id__c;
        this.SyncToken = partFIFOBucketActivityLineItemRec.SyncToken__c;
        this.accountingResponse = partFIFOBucketActivityLineItemRec.AccountingResponse__c; 
        
        this.EntityRef = new EntityRefWrapper(partFIFOBucketActivityLineItemRec.Part_FIFO_Bucket__r.Part__r.Vendor__r.Vendor_AccountingId__c, partFIFOBucketActivityLineItemRec.Part_FIFO_Bucket__r.Part__r.Vendor__r.Name);
        
        if(partFIFOBucketActivityLineItemRec.Part_Adjustment__c != null){
			this.UniqueId = (partFIFOBucketActivityLineItemRec.Part_Adjustment__c != null) ? partFIFOBucketActivityLineItemRec.Part_Adjustment__r.Unique_Id__c :  null;
		} else if(partFIFOBucketActivityLineItemRec.CO_Invoice_Header__c != null) {
			this.UniqueId = (partFIFOBucketActivityLineItemRec.CO_Invoice_Header__c != null) ? partFIFOBucketActivityLineItemRec.CO_Invoice_Header__r.Invoice_Number__c : null;
		}else if(partFIFOBucketActivityLineItemRec.Return_VO_Header__c != null) {
			this.UniqueId = (partFIFOBucketActivityLineItemRec.Return_VO_Header__c != null) ? partFIFOBucketActivityLineItemRec.Return_VO_Header__r.Name : '';
		}
		this.ReturnVOHeaderId = partFIFOBucketActivityLineItemRec.Return_VO_Header__c;
		this.RMANumber = partFIFOBucketActivityLineItemRec.Return_VO_Header__r.RMA__c != null ? partFIFOBucketActivityLineItemRec.Return_VO_Header__r.RMA__c : '';
    }
        
    
    /**
     * Name: fieldsList
     * Desc: Method Which contains all the field list to be quried
     * @param:  
     * @return: List<String> - Fields List
    **/
    public static List<String> fieldsList(){
        List<String> partFIFOBucketActivityLineItemFields = new List<String>{ 'Id',
                                                        'Name', 
                                                        'Cost__c',
            											'Qty_Out__c',
            											'Reference__c',
                                                        'Unique_Id__c',
            											'Part_FIFO_Bucket__r.Cost__c',
                                                        'Part_FIFO_Bucket__r.Remaining_Qty__c',
                                                        'Part_FIFO_Bucket__r.Qty_In__c',
                                                        'Part_FIFO_Bucket__r.Qty_Out__c',
            											'Part_FIFO_Bucket__r.Part__c',
            											'Part_FIFO_Bucket__r.Part__r.Part_Id__c',
            											'Part_FIFO_Bucket__r.Part__r.Part_Number__c',
            											'Part_FIFO_Bucket__r.Part__r.Description__c',
                                                        'Part_FIFO_Bucket__r.Part__r.Item_Description__c',
                                                        'Part_FIFO_Bucket__r.Part__r.Vendor__c',
            											'Part_FIFO_Bucket__r.Part__r.Vendor__r.Vendor_AccountingId__c',
            											'Part_FIFO_Bucket__r.Part__r.Vendor__r.Name',
            											'Part_FIFO_Bucket__r.Part__r.Category__r.COGS_GL__c',
            											'Part_FIFO_Bucket__r.Part__r.Category__r.Income_GL__c',
            											'Part_FIFO_Bucket__r.Part__r.Category__r.Inventory_GL__c',
                                                        'CO_Line_Item__r.CO_Header__r.customer__r.AccountingId__c',
                                                        'CO_Line_Item__r.CO_Header__r.customer__r.Name',
                                                        'CO_Invoice_Header__r.CO_Header__r.customer__r.Name',
                                                        'CO_Invoice_Header__r.CO_Header__r.customer__r.AccountingId__c',
                                                        'AccountingId__c',
                                                        'SyncToken__c',
                                                        'AccountingResponse__c',
                                                        'CreatedDate',
                                                        'Part_FIFO_Bucket__r.Source_Name__c',
                                                        'Part_Adjustment__c',
                                                        'Part_Adjustment__r.Unique_Id__c',
                                                        'Part_Adjustment__r.Reference__c',
                                                        'CO_Invoice_Header__c',
                                                        'CO_Invoice_Header__r.Invoice_Number__c',
                                                        'Return_VO_Header__c',
                                                        'Return_VO_Header__r.Name',
                                                        'Return_VO_Header__r.RMA__c',
                                                        'Xero_Accounting_Id__c'
                                                     };
        return partFIFOBucketActivityLineItemFields;
    }
    
    public class EntityRefWrapper{
        public String AccountingId;
        public String Name;
        
        public EntityRefWrapper(String AccountingId, String Name) {
            this.AccountingId = AccountingId;
            this.Name = Name;
        }
    }
}