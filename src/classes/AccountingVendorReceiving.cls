/**
 * Author: Richa Mittal
 * Since: Jan 6, 2017
 * Name: AccountingVORHeader
 * Description: Apex class to handle all operations related to Vendor Order Receiving for Accounting.
**/
public without sharing class AccountingVendorReceiving {
   	// VR Header Id
    public String Id {get; set;} // Created for generalised error response handling in XeroService
   
    // VOR Header
    public AccountingVORHeader AccountingVORHeaderRec {get; set;}
    
    // VOR line Item
    //public List<AccountingVORLineItem> AccountingVORLineItemsRecs {get; set;}
    
    // List of Vendor Receiving group
    public List<AccountingVORGroup> AccountingVORGroupList;
    public List<AccountingVRGroupByGL> AccountingVRGroupByGLList;
    //EntityRefWrapper
    public EntityRefWrapper EntityRef;
    
    
    // constructor
    public AccountingVendorReceiving(Vendor_Receiving_Header__c VORHeaderRec, List<Vendor_Receiving_Group__c> VORGroupList ) {
        this.Id = VORHeaderRec.Id;
        this.AccountingVORHeaderRec = new AccountingVORHeader(VORHeaderRec);
        this.AccountingVORGroupList = new List<AccountingVORGroup>();
        Boolean isForeignExchangeCostingEnabled = GeneralConfiguration.getGeneralConfigurations().Enable_Foreign_Exchange_Costing__c;
        Map<String, Decimal> invGLToAmountMap = new Map<String, Decimal>();
        Decimal vorGroupTotal = 0;
        String invGL = '';
        for(Vendor_Receiving_Group__c VORGroupRec : VORGroupList) {
            //this.AccountingVORGroupList.add(new AccountingVORGroup(VORGroupRec));
            
            invGL = '';
            if(VORGroupRec.Part__c != null) {
            	invGL = VORGroupRec.Part__r.Category__r.Inventory_GL__c;
            } else if(VORGroupRec.Sublet__c != null) {
            	invGL = VORGroupRec.Sublet__r.Category__r.Inventory_GL__c;
            }
            if(!invGLToAmountMap.containsKey(invGL)) {
            	invGLToAmountMap.put(invGL, 0);
        }
            VORGroupRec.Total__c = VORGroupRec.Total__c != null ? VORGroupRec.Total__c : 0;
            if(VORHeaderRec.Vendor__r.Is_Foreign_Vendor__c && VORHeaderRec.Finalized_VR_Conversion_Rate__c != 0 && isForeignExchangeCostingEnabled) {
                VORGroupRec.Total__c = ForeignExchangeUtil.getConvertedAmountInLocalCurrency(VORGroupRec.Total__c, VORHeaderRec.Finalized_VR_Conversion_Rate__c);
            }
            vorGroupTotal += VORGroupRec.Total__c;
            invGLToAmountMap.put(invGL, invGLToAmountMap.get(invGL) + (VORGroupRec.Total__c));
        }
        if(invGLToAmountMap.containsKey(invGL) && vorGroupTotal != this.AccountingVORHeaderRec.ReceivingTotal) {
            invGLToAmountMap.put(invGL, invGLToAmountMap.get(invGL) + (this.AccountingVORHeaderRec.ReceivingTotal - vorGroupTotal));
        }
        this.AccountingVRGroupByGLList = new List<AccountingVRGroupByGL>();
        for(String invGLValue : invGLToAmountMap.keySet()) {
        	if(invGLToAmountMap.get(invGLValue) != null && invGLToAmountMap.get(invGLValue) != 0) {
        		this.AccountingVRGroupByGLList.add(new AccountingVRGroupByGL(invGLValue, invGLToAmountMap.get(invGLValue)));
        	}
        }
        
        this.EntityRef = new EntityRefWrapper(VORHeaderRec.Vendor__r.Vendor_AccountingId__c, VORHeaderRec.Vendor__r.Name);
        //system.assert(false, COInvoiceItesRecs);
    }
    
    public static Map<String, Set<String>> objectToFieldMap = new Map<String, Set<String>>{
        'VORHeader'     => new Set<String>{ 'Id', 
                                            'Vendor__c',
                                            'Vendor__r.Name',
                                            'Vendor__r.Vendor_AccountingId__c',
                                            'Status__c', 
                                            'Owner__c',
                                            'Owner__r.Name', 
                                            'Name',
                                            'Is_Receiving_From_Invoice__c',
                                            'Packing_Slip_Number__c',
                                            'Receiving_From_Invoice_Total__c',
                                            'Receiving_Total__c',
                                            'Finalized_Date__c',
                                            'availForQBJournalEntrySync__c',
                                            'AccountingResponseForJournalEntry__c',
                                            'AccountingIdForJournalEntry__c',
                                            'SyncTokenForJournalEntry__c',
                                            'Xero_Accounting_Id__c',
                                            'Vendor__r.Vendor_AvailForQBSync__c',
                                            'Vendor__r.Is_Foreign_Vendor__c', 
                                            'Finalized_VR_Conversion_Rate__c'
                                            },
          
         'VORGroup'     => new Set<String>{  'Id',
                                             'CreatedDate',
                                             'Cost__c',
                                             'Part__c', 
                                             'Part__r.Name',
                                             'Part__r.Part_Id__c',
                                             'Part__r.Part_Number__c',
                                             'Part__r.Description__c',
                                             'Part__r.Package_Unit__c',
                                             'Part__r.Packaged_Part__c',
                                             'Part__r.Package_Qty__c',
                                             'Part__r.Order_Lots__c',
                                             'Part__r.Last_Cost__c',
                                             'Part__r.Category__r.COGS_GL__c',
                                             'Part__r.Category__r.Income_GL__c',
                                             'Part__r.Category__r.Inventory_GL__c',
                                             'Sublet__c',
                                             'Sublet__r.Product_Unique_Name__c',
                                             'Sublet__r.Category__r.COGS_GL__c',
                                             'Sublet__r.Category__r.Income_GL__c',
                                             'Sublet__r.Category__r.Inventory_GL__c',
                                             'Vendor_Receiving_Header__c',
                                             'Recieved__c',
                                             'Total__c',
                                             'Vendor_Receiving_Header__r.Vendor__r.Purchase_Tax__r.Rate__c',
                                             'Service_Order_Line_Item__c',
                                             'Service_Order_Line_Item__r.Item_Code__c',
                                             'Service_Order_Line_Item__r.Item_Description__c',
                                             'Vendor_Receiving_Header__r.Xero_Accounting_Id__c', 
                                             'Vendor_Receiving_Header__r.Vendor__r.Is_Foreign_Vendor__c',
                                             'Vendor_Receiving_Header__r.Finalized_VR_Conversion_Rate__c'
                                            }
    };
    
    
    
    // Start: AccountingVORHeader Wraaper
    public class AccountingVORHeader{
        public String VORId;
        public String VORName;
        
        public String VendorId;
        public String VendorName;
        

        public decimal ReceivingFromInvoiceTotal;
        
        public String Status;
        public String PackagingSlipNumber;
        public decimal ReceivingTotal;
        public Date FinalizedDate;
        
        // Customer Invoice Journal Entry AccountingId
        public String JournalEntryAccountingId;
        
        // Customer Invoice Journal Entry SyncToken
        public String JournalEntrySyncToken;
        
        public String JournalEntryAccountingResponse;
    
        public String XeroAccountingId;
        
        // Constructor
        public AccountingVORHeader(Vendor_Receiving_Header__c VORHeaderRec) { 
            this.VORId = VORHeaderRec.Id;
            this.VORName = VORHeaderRec.Name;
            this.VendorId = VORHeaderRec.Vendor__c;
            this.VendorName = VORHeaderRec.Vendor__r.Name;
            this.ReceivingFromInvoiceTotal = VORHeaderRec.Receiving_From_Invoice_Total__c;
            this.Status = VORHeaderRec.Status__c;
            this.PackagingSlipNumber = VORHeaderRec.Packing_Slip_Number__c;
            this.ReceivingTotal = VORHeaderRec.Receiving_Total__c;
            if(VORHeaderRec.Vendor__r.Is_Foreign_Vendor__c && VORHeaderRec.Finalized_VR_Conversion_Rate__c != 0 && GeneralConfiguration.getGeneralConfigurations().Enable_Foreign_Exchange_Costing__c) {
                this.ReceivingTotal = ForeignExchangeUtil.getConvertedAmountInLocalCurrency(this.ReceivingTotal, VORHeaderRec.Finalized_VR_Conversion_Rate__c);
            }
            this.FinalizedDate = VORHeaderRec.Finalized_Date__c;
                        
            this.JournalEntryAccountingId = VORHeaderRec.AccountingIdForJournalEntry__c;
            this.JournalEntrySyncToken = VORHeaderRec.SyncTokenForJournalEntry__c;
            this.JournalEntryAccountingResponse = VORHeaderRec.AccountingResponseForJournalEntry__c;
            this.XeroAccountingId = VORHeaderRec.Xero_Accounting_Id__c;
        }
        
        /**
         * Name: parse
         * Desc: Method to Parse JSON String to class instance
         * @param:  (1) JSONString - String - JSON String 
         * @return: COLineItem - Class Object
        **/
        public AccountingVORHeader parse(String json) {
            return (AccountingVORHeader) System.JSON.deserialize(json, AccountingVORHeader.class);
        }
        
    }
    // End: AccountingVORHeader Wraaper 
    
    public without sharing class AccountingVRGroupByGL {
    	public String Inventory_GL;
    	public Decimal Total;
        
    	public AccountingVRGroupByGL(String invGL, Decimal total) {
    		this.Inventory_GL = invGL;
    		this.Total = total != null ? total.setScale(2, RoundingMode.HALF_UP) : 0;
    	}
    }
    
    public without sharing class AccountingVORGroup {
    
        // Id
        public String Id;
        
        // Part Number + Part desc
        public String ItemDesc;
        
        // Received Order
        public Decimal ReceivedQty;
        
        // CO Line Item price per Qty
        public Decimal Cost;
        
        // Need * Cost
        public Decimal Total;
        
        // Part Id
        public String PartId;
        
        public String COGS_GL;
        
        public String Income_GL;
        
        public String Inventory_GL;
        
        // List of Name of matching parts Vendor Order Header Name
        //public List<String> OtherVOHeaderNameList;
    
        
        // Constructor
        public AccountingVORGroup(Vendor_Receiving_Group__c vrGroupRec) {
            this.Id = vrGroupRec.Id;
            this.Total = (vrGroupRec.Total__c != null) ? vrGroupRec.Total__c : 0;
            this.PartId = vrGroupRec.Part__c;
            
            if(vrGroupRec.Part__c != null) {
                this.ItemDesc = vrGroupRec.Part__r.Part_Number__c + ' - ' + vrGroupRec.Part__r.Description__c;
                if(vrGroupRec.Cost__c != null) {
                    this.Cost = (vrGroupRec.Cost__c).setScale(2, RoundingMode.HALF_UP);
                } else {
                    this.Cost = (vrGroupRec.Part__r.Last_Cost__c).setScale(2, RoundingMode.HALF_UP);
                }
                if(vrGroupRec.Part__r.Packaged_Part__c) {
                    this.ReceivedQty = (vrGroupRec.Recieved__c).setScale(2, RoundingMode.HALF_UP);
                } else {
                    this.ReceivedQty = (vrGroupRec.Recieved__c).setScale(2, RoundingMode.HALF_UP);
                }
                this.COGS_GL = vrGroupRec.Part__r.Category__r.COGS_GL__c;
                this.Income_GL = vrGroupRec.Part__r.Category__r.Income_GL__c;
                this.Inventory_GL = vrGroupRec.Part__r.Category__r.Inventory_GL__c;
            } else if(vrGroupRec.Sublet__c != null) {
                if(vrGroupRec.Service_Order_Line_Item__c != null) {
					this.ItemDesc = ((vrGroupRec.Service_Order_Line_Item__r.Item_Code__c != null) ? vrGroupRec.Service_Order_Line_Item__r.Item_Code__c : '') 
						+ ((vrGroupRec.Service_Order_Line_Item__r.Item_Code__c.length() > 0 && vrGroupRec.Service_Order_Line_Item__r.Item_Description__c.length() > 0) ? ' - ' : '' ) + 
						((vrGroupRec.Service_Order_Line_Item__r.Item_Description__c != null) ? vrGroupRec.Service_Order_Line_Item__r.Item_Description__c : '');
		    	} else {
		    		this.ItemDesc = vrGroupRec.Sublet__r.Product_Unique_Name__c;
		    	}
                
                this.Cost = (vrGroupRec.Cost__c).setScale(2, RoundingMode.HALF_UP);
                this.ReceivedQty = (vrGroupRec.Recieved__c).setScale(2, RoundingMode.HALF_UP);
                this.COGS_GL = vrGroupRec.Sublet__r.Category__r.COGS_GL__c;
                this.Income_GL = vrGroupRec.Sublet__r.Category__r.Income_GL__c;
                this.Inventory_GL = vrGroupRec.Sublet__r.Category__r.Inventory_GL__c;
            }
        }
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
