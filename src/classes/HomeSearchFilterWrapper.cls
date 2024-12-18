/**
 * Author: Tarun Khandelwal
 * Since: March 10, 2016
 * Name: HomeSearchFilterWrapper
 * Description: Class is used for the Creation of the Json For Filters
**/
public without sharing class HomeSearchFilterWrapper {

    public TypeFilter Type; 
    public OwnerFilter Owner;
    public String SearchText;
    public String Status;
    public BetweenFilter ModifiedDate;
    public BetweenFilter CreatedDate;
    
    // Invoiced Item
    public Boolean IsSummaryFormat;
    public String InvoicedItem_Type;
    public String InvoicedItem_Item;
    public String InvoicedItem_Customer; 
    public BetweenFilter InvoicedItem_InvoiceDate;
    public String InvoicedItem_Category;
    public String InvoicedItem_InvoicedBy;
    public String InvoicedItem_Vendor;
    public BetweenFilter InvoicedItem_Quantity;
    public BetweenFilter InvoicedItem_Revenue;
    public String InvoicedItem_Invoice_Type;
    
    public BetweenFilter TechinicianPerformance_Date;
    public String TechinicianPerformance_Technician;
    
    // Technician Hours
    public String TechinicianHours_ItemType;
    public String TechinicianHours_Technician;
    public BetweenFilter TechinicianHours_Date;
    public String TechinicianHours_JobType;
    public BetweenFilter TechnicianHours_PausedHours;
    public String TechinicianHours_Customer;
    
    public String Special_Order_Sale_Type;
    public String SpecialOrder_Status;
    
    public Boolean IncludeInactiveRecords;
    // Payroll Hours
    public String Payroll_Employee;
    public BetweenFilter Payroll_Date;
    
    // Customer
    public String People_Id;
    public String People_Name;
    public String People_Email; 
    public String People_Phone;
    public String People_BillingAddress;
    public String People_BillingCity;
    public String People_StateProv;
    public String People_Country;
    public String People_SalesTax;
    public String People_PriceLevel;
    public String Customer_AccountType;
    public String Customers_Drivers_License;
    public BetweenFilter Customers_Store_Credits;
    
    // Vendor
    public String Vendor_PurchaseSalesTax; 
    public String Vendor_AccountType;
    
        // Product
    public String Product_Item;
    public String Product_Description;
    public String Product_Category;
    public BetweenFilter Product_Price;
    public BetweenFilter Product_QtyAvailable;
    public String Product_Type;
    
    // Part
    public String Part_Location;
    public BetweenFilter Part_Cost;
    public BetweenFilter Part_AverageCost;
    public BetweenFilter Part_InStock;
    public BetweenFilter Part_Committed;
    public BetweenFilter Part_OnOrder;
    public String Part_PackagedPart;
    public BetweenFilter Part_InventoryQty;
    public BetweenFilter Part_LastCounted;
    public BetweenFilter Part_LastSold;
    public BetweenFilter Part_LastStocked;
    public BetweenFilter Part_ReorderAt;
    public BetweenFilter Part_ReorderTo;
    public BetweenFilter Part_OversoldQty;
    public BetweenFilter Part_OversoldCost;
    public BetweenFilter Part_LastEdited;
    public BetweenFilter Part_LastPriceUpdate;
    public String Part_Status;
    public String Part_Vendor;
    public String Part_MfgPart; //Added by richa 29/11/2016
    public String Part_SKUNumber; //Added by richa 29/11/2016
    public String Part_NonInventory; //Added by richa 29/11/2016
    public BetweenFilter Part_PRD1Cost;
    public BetweenFilter Part_PRD1Qty;
    public BetweenFilter Part_PRD2Cost;
    public BetweenFilter Part_PRD2Qty;
    public BetweenFilter Part_PRD3Cost;
    public BetweenFilter Part_PRD3Qty;
    public BetweenFilter Part_PRD4Cost;
    public BetweenFilter Part_PRD4Qty;
	public String Part_Type;
	public BetweenFilter Part_Name;
    public BetweenFilter Part_SalePrice;
    public String Part_PublishInFeeds;
    
    // Kits
    public BetweenFilter Kit_KitPrice;
    public String Kit_FixedPrice;
    public String Kit_ServiceKit;
    
    //Fees
    public String Fee_FeeType;
    
    
    // Customer Sales
    public String Customer_Sales_Id;
    public String Customer_Sales_Customer;
    public BetweenFilter Customer_Sales_Total;
    public BetweenFilter Customer_Sales_Balance_Due;
    
    // Customer Orders
    public BetweenFilter Customer_Order_Deposits;
    public BetweenFilter Customer_Order_Payments;
    public String Customer_Order_Status;
    public BetweenFilter Customer_Order_Deal_Total;
    public Boolean Include_Quotes;
	public String Customer_Order_Notes;
	public String Customer_Order_Salesperson;
        
    // Customer Invoices
    public String CO_Invoice_Header_Customer_Order;
    public String CO_Invoice_Header_Status;
	public String CO_Invoice_Header_Salesperson;
	public BetweenFilter CO_Invoice_Header_Commission;
    
    public BetweenFilter CO_Invoice_Header_Part_Total;
    public BetweenFilter CO_Invoice_Header_Labour_Total;
    public BetweenFilter CO_Invoice_Header_Fee_Total;
    public BetweenFilter CO_Invoice_Header_LienPayout_Total;
    public BetweenFilter CO_Invoice_Header_AR_Balance;
    public BetweenFilter CO_Invoice_Header_Sublet_Total;
    public BetweenFilter CO_Invoice_Header_Unit_Total;
    public BetweenFilter CO_Invoice_Header_SalesTax_Total;
    public BetweenFilter COInvoice_InvoiceDate;
    
    // Customer Payments
    public String CO_Payment_Customer_Order;
    public BetweenFilter CO_Payment_Payment_Method;
    public String CO_Payment_Cash_Drawer;
    public BetweenFilter CO_Payment_Payment_Date;
    
    //Vendor Ordering - Group
    public String Vendor_Ordering_Id;
    public String Vendor_Ordering_Vendor;
    public BetweenFilter Vendor_Ordering_Total;
    
    //Vendor Order
    public String Vendor_Order_Purchase_Order;
    public BetweenFilter Vendor_Order_Total_Recieved;
    public String Vendor_Order_Status;
    
    //Vendor Recievings
    public String Vendor_Receiving_Header_Status;
    
    //Vendor Invoices
    public String Vendor_Invoicing_Header_Status;
    
    
    // Settings
    public String Settings_Name;
    
    //Inventory Units
    public String Inventory_Unit_VIN;
    public String Inventory_Unit_Stock_Number;
    public String Inventory_Unit_Year;
    public String Inventory_Unit_Make;
    public String Inventory_Unit_Model;
    public String Inventory_Unit_SubModel;
    
    public String Inventory_Unit_Ext_Colour;
    public String Inventory_Unit_New_Unit;
    public String Inventory_Unit_Vendor;

    public BetweenFilter Inventory_Unit_Base_Unit_Price;
    public BetweenFilter Inventory_Unit_Factory_Options;
    public BetweenFilter Inventory_Unit_Dealer_Options;
    public BetweenFilter Inventory_Unit_Total_Price;
    public BetweenFilter Inventory_Unit_Base_Unit_Cost;
    public BetweenFilter Inventory_Unit_Factory_Option_Cost;
    public BetweenFilter Inventory_Unit_Dealer_Option_Cost;
    public BetweenFilter Inventory_Unit_Deal_Options_WIP;
    public BetweenFilter Inventory_Unit_Total_Cost;
    public String Inventory_Unit_Location; 
    public String Inventory_Unit_Category;
    public BetweenFilter Inventory_Unit_Stocked_In;
    
    public BetweenFilter Inventory_Unit_Age;
    public String Inventory_Unit_Key_Number;
    public String Inventory_Unit_Engine_Number;
    public String Inventory_Unit_Other_Number;
    public String Inventory_Unit_Int_Colour;
        
    public BetweenFilter Inventory_Unit_Stocked_Out;
    public String Inventory_Unit_Taxable;
    public String Inventory_Unit_Applicable_Tax;
    public BetweenFilter Inventory_Unit_Cylinders;
    public String Inventory_Unit_Automatic;
    public BetweenFilter Inventory_Unit_Manufactured_Date;
    public BetweenFilter Inventory_Unit_Mileage;
    public String Inventory_Unit_Plate_Number;
    public BetweenFilter Inventory_Unit_Reg_Expiry;
    public String Inventory_Unit_Unit_Type;
    public String Inventory_Unit_Compliance_Date;
    public String Inventory_Unit_Year_Of_1st_Rego;
    public String Inventory_Unit_Registration_Serial;
    public BetweenFilter Inventory_Unit_In_Stock_As_Of;
    public BetweenFilter Inventory_Unit_NITC_Withheld;
    
    //Customer Units
    public String Customer_Unit_Unit_ID;
    public String Customer_Unit_Customer;
    public String Customer_Unit_Year;
    public String Customer_Unit_Make;
    public String Customer_Unit_Model;
    public String Customer_Unit_SubModel;
    public BetweenFilter Customer_Unit_Mileage;
    
    public String Customer_Unit_VIN;
    public String Customer_Unit_Plate_Number;
    public BetweenFilter Customer_Unit_Reg_Expiry;
    public String Customer_Unit_Key_Number;
    public String Customer_Unit_Engine_Number;
    public String Customer_Unit_Other_Number;
    public String Customer_Unit_Ext_Colour;
    public String Customer_Unit_Int_Colour;
    public String Customer_Unit_Compliance_Date;
    public String Customer_Unit_Year_Of_1st_Rego;
    public String Customer_Unit_Registration_Serial;
    public BetweenFilter Customer_Unit_Manufactured_Date;
    public Boolean IncludeConsignments;
    public Boolean ExcludeInternalInvoices;
    
    //Order Units
    public String Order_Unit_Make;
    public String Order_Unit_Model;
    public String Order_Unit_SubModel;
    public String Order_Unit_Year;
    public String Order_Unit_Unit_ID;
    public String Order_Unit_Category;
    public BetweenFilter Order_Unit_Ordered;
    public BetweenFilter Order_Unit_Expected;
    public BetweenFilter Order_Unit_Days_Out;
    public String Order_Unit_FO_Number;
    public String Order_Unit_Committed;
    public BetweenFilter Order_Unit_Unit_Cost;
    public BetweenFilter Order_Unit_Tax;
    public BetweenFilter Order_Unit_Total_Cost;
    public BetweenFilter Order_Unit_Retail_Price;
    public String Order_Unit_Vendor;
    public String Order_Unit_VIN;
    public String Order_Unit_Stock_Number;
    public String Order_Unit_Ext_Color;
    public String Order_Unit_Int_Color;
    
    // Service Jobs
    public String Service_Job_Customer;
    public String Service_Job_Job_Type;
    public String Service_Job_Job;
    public String Service_Job_Unit_Description;
    public String Service_Job_Technician;
    
    public String Service_Job_VIN;
	public String Service_Job_Plate_Number;
	public String Service_Job_Engine_Number;
	public String Service_Job_Unit_Number;
	public BetweenFilter Service_Job_Scheduled;
	public BetweenFilter Service_Job_Invoice_Date;
	public String Service_Job_Invoice_Number;
	public BetweenFilter Service_Job_Hrs_Billed;
	public BetweenFilter Service_Job_Hrs_Logged;
	
	public BetweenFilter Service_Job_Parts_Total;
	public BetweenFilter Service_Job_Labor_Total;
	public BetweenFilter Service_Job_Sublet_Total;
	public BetweenFilter Service_Job_Fees_Total;
	public BetweenFilter Service_Job_Tax_Total;
	public BetweenFilter Service_Job_Total;
	public BetweenFilter Service_Job_Odometer_In;
	public BetweenFilter Service_Job_Odometer_Out;
    
    public String Service_Job_SO_Type;	
	public String Service_Job_Provider;
	public String Service_Job_Claim_Status;
	public String Service_Job_Make;
	public String Service_Job_Model;
    public String Service_Job_SubModel;
	
    public String Service_Job_TransactionType;
    public BetweenFilter Service_Job_Date_Due_In;
    public BetweenFilter Service_Job_Date_Promised;
    public String Service_Job_Unit_Arrived;
    
    public List<String> AssignedTags;
    public List<String> AssignedLocations;
    public String Service_Job_Salesperson;
    
    // Part FIFO
    public String Part_FIFO_Category;
    public BetweenFilter Part_FIFO_Date;
    public String Part_FIFO_Part_Type;
    public String Part_FIFO_Vendor;
    public BetweenFilter Part_FIFO_Sales_Qty;
    public BetweenFilter Part_FIFO_Purchase_Qty;
    public BetweenFilter Part_FIFO_Adjusted_Qty;
    public String Part_FIFO_Part_Number;
    public Boolean IncludePartsWithoutActivity;
    
    //Tax detail
    public String Tax_Detail_Invoice_Type;
    public BetweenFilter Tax_Detail_Invoice_Date;
    public Set<String> Selected_Sales_Tax_Items;
    
    //Unit Deal
    public String Unit_Deals_Order_Number;
    public String Unit_Deals_Customer;
    public String Unit_Deals_Deal_Type;
    public BetweenFilter Unit_Deals_Total;
    public BetweenFilter Unit_Deals_Delivery;
    public BetweenFilter Unit_Deals_Units;
    public BetweenFilter Unit_Deals_Trade_Ins;
    public BetweenFilter Unit_Deals_Lien_payout;
    public BetweenFilter Unit_Deals_Parts_And_Labour;
    public BetweenFilter Unit_Deals_Other_Products;
    public BetweenFilter Unit_Deals_Fees;
    public BetweenFilter Unit_Deals_Stamp_Duty;
    public BetweenFilter Unit_Deals_Financing_Products;
    public BetweenFilter Unit_Deals_Sales_Tax;
    public String Unit_Deals_Salesperson;
    public BetweenFilter Unit_Deals_Option_Clearing;
    public BetweenFilter Unit_Deals_Stocked_Trades;
    
    
    //Deal Unit
    public String Deal_Units_Order_Number;
    public String Deal_Units_Stock_Number;
    public String Deal_Units_Status;
    public BetweenFilter Deal_Units_Date_Sold;
    public String Deal_Units_Invoice_Number;
    public String Deal_Units_Make;
    public String Deal_Units_Model;
    public String Deal_Units_Submodel;
    public String Deal_Units_Year;
    public String Deal_Units_Deal_Customer;
    public String Deal_Units_Deal_Type;
    public String Deal_Units_Salesperson;
    public BetweenFilter Deal_Units_Total_Price;
    public BetweenFilter Deal_Units_Total_Cost;
    public BetweenFilter Deal_Units_Total_Profit;
    public BetweenFilter Deal_Units_Total_Unit_Price;
    public BetweenFilter Deal_Units_Total_Unit_Cost;
    public BetweenFilter Deal_Units_Total_Unit_Profit;
    public BetweenFilter Deal_Units_Total_Unit_Option_Price;
    public BetweenFilter Deal_Units_Total_Unit_Option_Cost;
    public BetweenFilter Deal_Units_Total_Unit_Option_Profit;
    public BetweenFilter Deal_Units_Base_Price;
    public BetweenFilter Deal_Units_Factory_Options;
    public BetweenFilter Deal_Units_Dealer_Installed;
    public BetweenFilter Deal_Units_Part_Options;
    public BetweenFilter Deal_Units_Labor_Options;
    public BetweenFilter Deal_Units_Sublet_Options;
    public BetweenFilter Deal_Units_Fee_Options;
    public BetweenFilter Deal_Units_Warranty_Options;
    public BetweenFilter Deal_Units_Other_Products;
    public BetweenFilter Deal_Units_Stamp_Duty;
    public String Deal_Units_VIN;
    public String Deal_Units_New_Unit;
    public String Deal_Units_Category;
    public BetweenFilter Deal_Units_Stocked_In;
    public BetweenFilter Deal_Units_Age;
    public BetweenFilter Deal_Units_Confirmed_Sale;
    public String Deal_Units_Unit_Type;
    public BetweenFilter Deal_Units_Mileage;
    public String Deal_Units_Mileage_Type;
    public String Deal_Units_Ext_Color;
    public String Deal_Units_Int_Color;
    public String Deal_Units_Compliance_Date;
    public String Deal_Units_Year_Of_1st_Rego;
    public String Deal_Units_Registration_Serial;
    public BetweenFilter Deal_Units_Manufactured_Date;
    public String Deal_Units_First_Name;
    public String Deal_Units_Last_Name;
    public String Deal_Units_Address;
    public String Deal_Units_City;
    public String Deal_Units_State;
    public String Deal_Units_Postal;
    public String Deal_Units_Phone;
    public String Deal_Units_Mobile;
    public String Deal_Units_Email;
    public String Deal_Units_Other_Email;
    
    public String Parts_Order_Order_Number {get; private set;}
    public String Parts_Order_Customer {get; private set;}
    public String Parts_Order_Sale_Type {get; private set;}
    public BetweenFilter Parts_Order_Total {get; private set;}
    public BetweenFilter Parts_Order_Status {get; private set;}
    public BetweenFilter Parts_Order_Deposits {get; private set;}
    public BetweenFilter Parts_Order_Invoiced {get; private set;}
    public BetweenFilter Parts_Order_Modified {get; private set;}
    public BetweenFilter Parts_Order_Parts {get; private set;}
    public BetweenFilter Parts_Order_Fees {get; private set;}
    public BetweenFilter Parts_Order_Sales_Tax {get; private set;}
    public BetweenFilter Parts_Order_Parts_Profit {get; private set;}
    public String Parts_Order_Salesperson {get; private set;}
    
    public BetweenFilter Customer_Invoice_Detail_Invoice_Date;
    public String Customer_Invoice_Detail_Salesperson;
    public List<String> Customer_Invoice_Detail_Invoice_Ids;
    public List<String> Selected_Parts_Pull_Sale_Types;
    public List<String> Selected_Sale_Types;
    public List<String> Selected_Item_Types;
    
    
    // Vo Items
    public String VO_Items_Vendor;
    public String VO_Items_Item_Description;
    public String VO_Items_VO_Number;
    public BetweenFilter VO_Items_Quantity;
    public BetweenFilter VO_Items_Total_Cost;
    public BetweenFilter VO_Items_Ordered;
    public BetweenFilter VO_Items_Expected;
    public String VO_Items_Needed_For;
    public String VO_Items_Customer;
    
    // Sublet Items
    public String Sublet_Items_Order_Number;
    public String Sublet_Items_Customer;
    public String Sublet_Items_Job;
    public String Sublet_Items_Job_Status;
    public String Sublet_Items_Job_Type;
    public String Sublet_Items_Item_Description;
    public String Sublet_Items_Sublet_Status;
    public BetweenFilter Sublet_Items_Total_Price;
    public BetweenFilter Sublet_Items_Total_Cost;
    public BetweenFilter Sublet_Items_Expected;
    public BetweenFilter Sublet_Items_Modified;
    public String Sublet_Items_Vendor;
    public String Sublet_Items_VO_Number;
    public String Sublet_Items_VR_Number;
    public String Sublet_Items_VI_Number;
    public String Sublet_Items_VI_Invoice;
    
    public BetweenFilter Vendor_Return_Credits_Pending;
    public String Vendor_Return_RMA;
    public String Vendor_Return_Tracking;

    //Claim jobs
    public String Claim_Jobs_Provider;
    public String Claim_Jobs_Claim_Status;
    public BetweenFilter Claim_Jobs_Variance;

    //Unit Register
    public BetweenFilter Unit_Register_Stocked_In;
    public String Unit_Register_Make;
    public String Unit_Register_Model;
    public String Unit_Register_Submodel;
    public String Unit_Register_Year;
    public String Unit_Register_New_Unit;
    public String Unit_Register_How_Acquired;


	/*
     * Name:HomeSearchFilterWrapper
     * Description: Constructor
    **/
    public HomeSearchFilterWrapper() {
        this.Type = new TypeFilter(new List<String>());
        this.Owner = new OwnerFilter();
        this.SearchText = '';
        this.Status = '0';
        this.ModifiedDate = new BetweenFilter();
        this.CreatedDate = new BetweenFilter();
        this.IncludeInactiveRecords = false;
        this.IncludeConsignments = false;
        this.ExcludeInternalInvoices = true;
        this.IsSummaryFormat = false;
        this.IncludePartsWithoutActivity = false;
        
        this.Special_Order_Sale_Type = '0';
        this.SpecialOrder_Status = '0';
        
        this.People_Id = '';
        this.People_Name = '';
        this.People_Email = '';
        this.People_Phone = '';
        this.People_BillingAddress = '';
        this.People_BillingCity = '';
        this.People_StateProv = '';
        this.People_Country = '';
        this.Customer_AccountType = '0';
        this.Customers_Drivers_License = '';
        this.Customers_Store_Credits = new BetweenFilter();
                        
        this.People_SalesTax = '0';
        this.People_PriceLevel = '0';
        this.Vendor_PurchaseSalesTax = '0';
        this.Vendor_AccountType = '0';
        
        this.Product_Item = '';
        this.Product_Description = '';
        this.Product_Category = '0';
        this.Product_Price = new BetweenFilter();
        this.Product_QtyAvailable = new BetweenFilter();
        this.Product_Type = '0';
        
        this.InvoicedItem_Type = 'All';
        this.InvoicedItem_Item = '';
        this.InvoicedItem_Customer = ''; 
        this.InvoicedItem_InvoiceDate = new BetweenFilter();
        this.InvoicedItem_Category = '';
        this.InvoicedItem_InvoicedBy = '';
        this.InvoicedItem_Vendor = '';
        this.InvoicedItem_Quantity = new BetweenFilter();
        this.InvoicedItem_Revenue = new BetweenFilter();
        this.InvoicedItem_Invoice_Type = '0';
        
        this.TechinicianPerformance_Date = new BetweenFilter();
        this.TechinicianPerformance_Technician = '';
        
        this.TechinicianHours_ItemType = 'All';
        this.TechinicianHours_Technician = '';
        this.TechinicianHours_JobType = '0';
        this.TechnicianHours_PausedHours = new BetweenFilter();
        this.TechinicianHours_Date = new BetweenFilter();
    
        this.Payroll_Employee = '';
        this.Payroll_Date = new BetweenFilter();
        
        this.Part_Location = '';
        this.Part_Cost = new BetweenFilter();
        this.Part_AverageCost = new BetweenFilter();
        this.Part_InStock = new BetweenFilter();
        this.Part_Committed = new BetweenFilter();
        this.Part_OnOrder = new BetweenFilter();
        this.Part_LastCounted = new BetweenFilter();
        this.Part_LastSold = new BetweenFilter();
        this.Part_LastStocked = new BetweenFilter();
        this.Part_LastEdited = new BetweenFilter();
        this.Part_LastPriceUpdate = new BetweenFilter();
        this.Part_PackagedPart = '0';
        this.Part_InventoryQty = new BetweenFilter();
        this.Part_ReorderAt = new BetweenFilter();
        this.Part_ReorderTo = new BetweenFilter();
        this.Part_OversoldQty = new BetweenFilter();
        this.Part_OversoldCost = new BetweenFilter();
        this.Part_PRD1Qty = new BetweenFilter();
        this.Part_PRD1Cost = new BetweenFilter();
        this.Part_PRD2Qty = new BetweenFilter();
        this.Part_PRD2Cost = new BetweenFilter();
        this.Part_PRD3Qty = new BetweenFilter();
        this.Part_PRD3Cost = new BetweenFilter();
        this.Part_PRD4Qty = new BetweenFilter();
        this.Part_PRD4Cost = new BetweenFilter();
        
        this.Part_Status = '';
        this.Part_Vendor ='';
        this.Part_MfgPart = ''; //Added by richa 29/11/2016
        this.Part_SKUNumber = ''; //Added by richa 29/11/2016
        this.Part_NonInventory = '0'; //Added by richa 29/11/2016
        this.Part_PublishInFeeds = '0';
		this.Part_Type = 'All';
		this.Part_Name = new BetweenFilter();
        this.Part_SalePrice = new BetweenFilter();
        
        this.Kit_KitPrice = new BetweenFilter();
        this.Kit_FixedPrice = '0';
        this.Kit_ServiceKit = '0';
        this.Fee_FeeType = '0';
        
        this.Customer_Sales_Id = '';
        this.Customer_Sales_Customer = '';
        this.Customer_Sales_Total = new BetweenFilter();
        this.Customer_Sales_Balance_Due = new BetweenFilter();
        
        this.CO_Invoice_Header_Customer_Order = '';
        this.CO_Invoice_Header_Status = '';
		this.CO_Invoice_Header_Salesperson = '';
		this.CO_Invoice_Header_Commission = new BetweenFilter();
        this.CO_Invoice_Header_Part_Total = new BetweenFilter();
        this.CO_Invoice_Header_Fee_Total = new BetweenFilter();
        this.CO_Invoice_Header_LienPayout_Total = new BetweenFilter();
        this.CO_Invoice_Header_AR_Balance = new BetweenFilter();
        this.CO_Invoice_Header_Labour_Total = new BetweenFilter();
        this.CO_Invoice_Header_Sublet_Total = new BetweenFilter();
        this.CO_Invoice_Header_Unit_Total = new BetweenFilter();
        this.CO_Invoice_Header_SalesTax_Total = new BetweenFilter();
        this.COInvoice_InvoiceDate = new BetweenFilter();
        
        this.CO_Payment_Customer_Order = '';
        this.CO_Payment_Payment_Method = new BetweenFilter();
        this.CO_Payment_Cash_Drawer = '0';
        this.CO_Payment_Payment_Date = new BetweenFilter();
        
        this.Customer_Order_Deposits = new BetweenFilter();
        this.Customer_Order_Payments = new BetweenFilter();
        this.Customer_Order_Deal_Total = new BetweenFilter();
		this.Customer_Order_Notes = '';
		this.Customer_Order_Salesperson = '';
        this.Include_Quotes = false;
        
        this.Vendor_Ordering_Id = '';
        this.Vendor_Ordering_Vendor = '';
        this.Vendor_Ordering_Total = new BetweenFilter();
        
        this.Vendor_Order_Purchase_Order = '0';
        this.Vendor_Order_Total_Recieved = new BetweenFilter();
        this.Vendor_Order_Status = '' ;
        this.Vendor_Receiving_Header_Status = '';
        this.Vendor_Invoicing_Header_Status = '';
        this.Settings_Name = '';
        
        this.Inventory_Unit_VIN = '';
        this.Inventory_Unit_Stock_Number = '';
        this.Inventory_Unit_Year = '';
        this.Inventory_Unit_Make = '';
        this.Inventory_Unit_Vendor = '';
        this.Inventory_Unit_Model = '';
        this.Inventory_Unit_SubModel = '';
        this.Inventory_Unit_Ext_Colour = '';
        this.Inventory_Unit_New_Unit = '0';
        
        this.Inventory_Unit_Base_Unit_Price = new BetweenFilter();
        this.Inventory_Unit_Factory_Options = new BetweenFilter();
        this.Inventory_Unit_Dealer_Options = new BetweenFilter();
        this.Inventory_Unit_Total_Price = new BetweenFilter();
        this.Inventory_Unit_Base_Unit_Cost = new BetweenFilter();
        this.Inventory_Unit_Factory_Option_Cost = new BetweenFilter();
        this.Inventory_Unit_Dealer_Option_Cost = new BetweenFilter();
        this.Inventory_Unit_Deal_Options_WIP = new BetweenFilter();
        this.Inventory_Unit_Total_Cost = new BetweenFilter();
        this.Inventory_Unit_Location = ''; 
        this.Inventory_Unit_Category = '';
        this.Inventory_Unit_Stocked_In = new BetweenFilter();
        
        this.Inventory_Unit_Age = new BetweenFilter();
        this.Inventory_Unit_Key_Number = '';
        this.Inventory_Unit_Engine_Number = '';
        this.Inventory_Unit_Other_Number = '';
        this.Inventory_Unit_Int_Colour = '';
        
        this.Inventory_Unit_Stocked_Out = new BetweenFilter(); 
        this.Inventory_Unit_Taxable = '0';
        this.Inventory_Unit_Applicable_Tax = '';
        this.Inventory_Unit_Cylinders = new BetweenFilter(); 
        this.Inventory_Unit_Automatic = '0';
        this.Inventory_Unit_Manufactured_Date = new BetweenFilter(); 
        this.Inventory_Unit_Mileage = new BetweenFilter(); 
        this.Inventory_Unit_Plate_Number = '';
        this.Inventory_Unit_Reg_Expiry = new BetweenFilter(); 
        this.Inventory_Unit_Unit_Type = '0';
        this.Inventory_Unit_Compliance_Date = '';
        this.Inventory_Unit_Year_Of_1st_Rego = '';
        this.Inventory_Unit_Registration_Serial = '';
        this.Inventory_Unit_In_Stock_As_Of = new BetweenFilter();
        this.Inventory_Unit_NITC_Withheld = new BetweenFilter();
        
        this.Customer_Unit_Unit_ID = '';
        this.Customer_Unit_Customer = '';
        this.Customer_Unit_Year = '';
        this.Customer_Unit_Make = '';
        this.Customer_Unit_Model = '';
        this.Customer_Unit_SubModel = '';
        this.Customer_Unit_Mileage = new BetweenFilter(); 
        this.Customer_Unit_VIN = '';
        this.Customer_Unit_Plate_Number = '';
        this.Customer_Unit_Reg_Expiry = new BetweenFilter(); 
        this.Customer_Unit_Key_Number = '';
        this.Customer_Unit_Engine_Number = '';
        this.Customer_Unit_Other_Number = '';
        this.Customer_Unit_Ext_Colour = '';
        this.Customer_Unit_Int_Colour = '';
        this.Customer_Unit_Compliance_Date = '';
        this.Customer_Unit_Year_Of_1st_Rego = '';
        this.Customer_Unit_Registration_Serial = '';
        this.Customer_Unit_Manufactured_Date = new BetweenFilter();
        
        this.Order_Unit_Make = '';
	    this.Order_Unit_Model = '';
	    this.Order_Unit_SubModel = '';
	    this.Order_Unit_Year = '';
	    this.Order_Unit_Unit_ID = '';
	    this.Order_Unit_Category = '';
	    this.Order_Unit_Ordered = new BetweenFilter();
	    this.Order_Unit_Expected = new BetweenFilter();
	    this.Order_Unit_Days_Out = new BetweenFilter();
	    this.Order_Unit_FO_Number = '';
	    this.Order_Unit_Committed = '';
	    this.Order_Unit_Unit_Cost = new BetweenFilter();
	    this.Order_Unit_Tax = new BetweenFilter();
	    this.Order_Unit_Total_Cost = new BetweenFilter();
	    this.Order_Unit_Retail_Price = new BetweenFilter();
	    this.Order_Unit_Vendor = '';
	    this.Order_Unit_VIN = '';
	    this.Order_Unit_Stock_Number = '';
	    this.Order_Unit_Ext_Color = '';
	    this.Order_Unit_Int_Color = '';
        
        this.Service_Job_Job_Type = '0';
        this.Service_Job_Scheduled = new BetweenFilter();
        this.Service_Job_Invoice_Date = new BetweenFilter();
        this.Service_Job_Hrs_Billed = new BetweenFilter();
        this.Service_Job_Hrs_Logged = new BetweenFilter();
        this.Service_Job_Parts_Total = new BetweenFilter(); 
        this.Service_Job_Labor_Total = new BetweenFilter();
        this.Service_Job_Sublet_Total = new BetweenFilter();
        this.Service_Job_Fees_Total = new BetweenFilter(); 
        this.Service_Job_Tax_Total = new BetweenFilter();
        this.Service_Job_Total = new BetweenFilter();
        this.Service_Job_Odometer_In = new BetweenFilter();
        this.Service_Job_Odometer_Out = new BetweenFilter();
        this.Service_Job_Claim_Status = '0';
        this.Service_Job_Salesperson = '';
        
        this.AssignedTags = new List<String>();
        this.AssignedLocations = new List<String>();
		this.Service_Job_TransactionType = '';
		this.Service_Job_SO_Type = '0';
        this.Service_Job_VIN = '';
		this.Service_Job_Plate_Number = '';
		this.Service_Job_Date_Due_In = new BetweenFilter();
	    this.Service_Job_Date_Promised = new BetweenFilter();
	    this.Service_Job_Unit_Arrived = '0';
	    
		this.Part_FIFO_Category = '0';
		this.Part_FIFO_Part_type = '0';
        this.Part_FIFO_Vendor = '';
        this.Part_FIFO_Part_Number = '';
        this.Part_FIFO_Date = new BetweenFilter('4',null, null);
        this.Part_FIFO_Sales_Qty = new BetweenFilter('0', null, null);
        this.Part_FIFO_Purchase_Qty = new BetweenFilter('0', null, null);
        this.Part_FIFO_Adjusted_Qty = new BetweenFilter('0', null, null);
        
        this.Tax_Detail_Invoice_Type = '0';
        this.Tax_Detail_Invoice_Date = new BetweenFilter('3', null, null);
        this.Selected_Sales_Tax_Items = new Set<String>();
        
        this.Unit_Deals_Order_Number = '';
		this.Unit_Deals_Customer = '';
		this.Unit_Deals_Deal_Type = '0';
		this.Unit_Deals_Total = new BetweenFilter();
        this.Unit_Deals_Delivery 			= new BetweenFilter();
        this.Unit_Deals_Units 				= new BetweenFilter();
	    this.Unit_Deals_Trade_Ins     		= new BetweenFilter();
	    this.Unit_Deals_Lien_payout 		= new BetweenFilter();
	    this.Unit_Deals_Parts_And_Labour	= new BetweenFilter();
	    this.Unit_Deals_Other_Products 		= new BetweenFilter();
	    this.Unit_Deals_Fees 				= new BetweenFilter();
	    this.Unit_Deals_Stamp_Duty 			= new BetweenFilter();
	    this.Unit_Deals_Financing_Products 	= new BetweenFilter();
	    this.Unit_Deals_Sales_Tax 			= new BetweenFilter();
	    this.Unit_Deals_Salesperson = '';
        this.Unit_Deals_Option_Clearing 	= new BetweenFilter();
	    this.Unit_Deals_Stocked_Trades 		= new BetweenFilter();

 
	    this.Deal_Units_Order_Number = this.Deal_Units_Stock_Number = this.Deal_Units_Status = this.Deal_Units_Invoice_Number = 
        this.Deal_Units_Make = this.Deal_Units_Model = this.Deal_Units_Submodel = this.Deal_Units_Year = this.Deal_Units_Deal_Customer = 
        this.Deal_Units_Salesperson = '';

		this.Deal_Units_Date_Sold = new BetweenFilter();	
	    this.Deal_Units_Deal_Type = '0';

		this.Deal_Units_Total_Price = new BetweenFilter();
		this.Deal_Units_Total_Cost = new BetweenFilter();
		this.Deal_Units_Total_Profit = new BetweenFilter();
		this.Deal_Units_Total_Unit_Price = new BetweenFilter();
		this.Deal_Units_Total_Unit_Cost = new BetweenFilter();
		this.Deal_Units_Total_Unit_Profit = new BetweenFilter();
		this.Deal_Units_Total_Unit_Option_Price = new BetweenFilter();
		this.Deal_Units_Total_Unit_Option_Cost = new BetweenFilter();
		this.Deal_Units_Total_Unit_Option_Profit = new BetweenFilter();
		
	    this.Deal_Units_Base_Price = new BetweenFilter();
		this.Deal_Units_Factory_Options = new BetweenFilter();
		this.Deal_Units_Dealer_Installed = new BetweenFilter();
		this.Deal_Units_Part_Options = new BetweenFilter();
		this.Deal_Units_Labor_Options = new BetweenFilter();
		this.Deal_Units_Sublet_Options = new BetweenFilter();
		this.Deal_Units_Fee_Options = new BetweenFilter();
		this.Deal_Units_Warranty_Options = new BetweenFilter();
		this.Deal_Units_Other_Products = new BetweenFilter();
		this.Deal_Units_Stamp_Duty = new BetweenFilter();

        this.Deal_Units_VIN = this.Deal_Units_Category = this.Deal_Units_Mileage_Type = Deal_Units_Ext_Color = Deal_Units_Int_Color = 
        this.Deal_Units_Compliance_Date = this.Deal_Units_Year_Of_1st_Rego = this.Deal_Units_Registration_Serial = this.Deal_Units_Unit_Type = 
        this.Deal_Units_First_Name = this.Deal_Units_Last_Name = this.Deal_Units_Address = this.Deal_Units_City = this.Deal_Units_State = 
        this.Deal_Units_Postal = this.Deal_Units_Phone = this.Deal_Units_Mobile = this.Deal_Units_Email = this.Deal_Units_Other_Email = '';

		this.Deal_Units_New_Unit = '0';
		this.Deal_Units_Stocked_In = new BetweenFilter();
		this.Deal_Units_Age = new BetweenFilter();
        this.Deal_Units_Confirmed_Sale = new BetweenFilter();
		this.Deal_Units_Mileage = new BetweenFilter();
        this.Deal_Units_Manufactured_Date = new BetweenFilter();
	    
		this.Parts_Order_Order_Number = '';
		this.Parts_Order_Customer = '';
        this.Parts_Order_Sale_Type = '';
        this.Parts_Order_Total = new BetweenFilter();
        this.Parts_Order_Status = new BetweenFilter(); 
        this.Parts_Order_Deposits = new BetweenFilter();
        this.Parts_Order_Invoiced = new BetweenFilter();
        this.Parts_Order_Modified = new BetweenFilter(); 
        this.Parts_Order_Parts = new BetweenFilter();
        this.Parts_Order_Fees = new BetweenFilter(); 
        this.Parts_Order_Sales_Tax = new BetweenFilter();
        this.Parts_Order_Parts_Profit = new BetweenFilter();
        this.Parts_Order_Salesperson = '';
	    
	    this.Customer_Invoice_Detail_Invoice_Date = new BetweenFilter('1', null, null);
	    this.Customer_Invoice_Detail_Salesperson = '';
	    this.Selected_Sale_Types = new List<String>();
	    this.Selected_Parts_Pull_Sale_Types = new List<String>();
	    this.Selected_Item_Types = new List<String>();
        
        this.VO_Items_Vendor = '';
        this.VO_Items_Item_Description = '';
        this.VO_Items_VO_Number = '';
        this.VO_Items_Quantity = new BetweenFilter();
        this.VO_Items_Total_Cost = new BetweenFilter();
        this.VO_Items_Ordered = new BetweenFilter();
        this.VO_Items_Expected = new BetweenFilter();
        this.VO_Items_Needed_For = '0';
        this.VO_Items_Customer = '';

        this.Sublet_Items_Order_Number = '';
        this.Sublet_Items_Customer = '';
        this.Sublet_Items_Job = '';
        this.Sublet_Items_Job_Status = '0';
        this.Sublet_Items_Job_Type = '0';
        this.Sublet_Items_Item_Description = '';
        this.Sublet_Items_Sublet_Status = '0';
        this.Sublet_Items_Total_Price = new BetweenFilter();
        this.Sublet_Items_Total_Cost = new BetweenFilter();
        this.Sublet_Items_Expected = new BetweenFilter();
        this.Sublet_Items_Modified = new BetweenFilter();
        this.Sublet_Items_Vendor = '';
        this.Sublet_Items_VO_Number = '';
        this.Sublet_Items_VR_Number = '';
        this.Sublet_Items_VI_Number = '';
        this.Sublet_Items_VI_Invoice = '';

        this.Vendor_Return_Credits_Pending = new BetweenFilter();
        this.Vendor_Return_RMA = '';
        this.Vendor_Return_Tracking = '';

        this.Claim_Jobs_Provider = '';
        this.Claim_Jobs_Claim_Status = '0';
        this.Claim_Jobs_Variance = new BetweenFilter();

        this.Unit_Register_Stocked_In = new BetweenFilter();
        this.Unit_Register_Make = '';
        this.Unit_Register_Model = '';
        this.Unit_Register_Submodel = '';
        this.Unit_Register_Year = '';
        this.Unit_Register_New_Unit = '0';
        this.Unit_Register_How_Acquired = '0';
	} 
    
    /**
     * Name: TypeFilter
     * Description: Class Is used for wrapping up the Type of the Object 
    **/
    public class TypeFilter { 
        public Set<String> Objects;
        
        /**
         * Name: TypeFilter
         * Description: Constructor
        */
        public TypeFilter(List<String> selectedObjectList){
            Objects = new Set<String>();
            if(selectedObjectList != null){
                this.Objects.addAll(selectedObjectList);
            }
        }
    }
    
    /**
     * Name: OwnerFilter
     * Description: Class is used to create the Json according to the Owner Field
    **/
    public class OwnerFilter {
        public String SelectedOption;
        public String OwnerId;
        public String OwnerName;    
        
        /**
         * Name: OwnerFilter
         * Description: Constructor
         */
        public OwnerFilter(){
            this.SelectedOption = '0';
            this.OwnerId = '';
            this.OwnerName = '';
        }
        public OwnerFilter(String selectedOptionStr, String ownerId, String ownerName){
            this.SelectedOption = selectedOptionStr;
            this.OwnerId = ownerId;
            this.OwnerName = ownerName;
        }
    }
    
    /**
     * Name: BetweenFilter
     * Description: Class is used to create the json for the Between option
    **/
    public class BetweenFilter {
        public String SelectedOption;
        public String Value1;  
        public String Value2;  
        
        /**
         * Name: BetweenFilter
         * Description: Constructor
        **/
        public BetweenFilter(String selectedOptionStr, String value1Str, String value2Str){
            this.SelectedOption = selectedOptionStr;
            this.Value1 = value1Str;
            this.Value2 = value2Str;
        }
        public BetweenFilter(){
            this.SelectedOption = '0';
            this.Value1 = '';
            this.Value2 = '';
        }
    }
}