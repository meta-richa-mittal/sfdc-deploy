public without sharing class GenericSearchResultsWrapper {
    public String Id;
    public String Name;
    public String Description;
    public String Info;
    public AdditionalInfoWrapper AdditionalInfoObj;
    public EntityInfoWrapper EntityInfoObj;
    
    public GenericSearchResultsWrapper(GenericSearchUtil.SearchedSObjectWrapper resultWrapperRecord, Search_Configuration__mdt searchConfigRec) {
        this.Id = resultWrapperRecord.SearchedObj.Id;
        String displayFieldName = searchConfigRec != null ? searchConfigRec.Display_Field_Name__c : 'Name';
        String additionalDisplayField = searchConfigRec != null ? searchConfigRec.Additional_Info_To_Display__c : '';
        this.Name = GenericSearchUtil.getFieldValueFromSObject(resultWrapperRecord.SearchedObj, displayFieldName);
        this.Description = (resultWrapperRecord.objectName != 'Account' && resultWrapperRecord.objectName != 'Unit_Model__c') ? (String.isNotBlank(additionalDisplayField) ? String.valueOf(resultWrapperRecord.SearchedObj.get(additionalDisplayField)) : null) : null;
        
        if(resultWrapperRecord.objectName == 'Service_Order_Header__c') {
            this.Info = (resultWrapperRecord.SearchedObj.getSobject('Transaction_Type__r') != null) ? String.valueOf(resultWrapperRecord.SearchedObj.getSobject('Transaction_Type__r').get('Code_Label__c')) : '';
            this.AdditionalInfoObj = new AdditionalInfoWrapper((Service_Order_Header__c)resultWrapperRecord.SearchedObj, (searchConfigRec != null ? searchConfigRec.DeveloperName : ''));
        } else {
            if(GenericSearchUtil.objectNameToObjectDisplayLabel.containsKey(resultWrapperRecord.objectName)){
                this.info = GenericSearchUtil.objectNameToObjectDisplayLabel.get(resultWrapperRecord.objectName);
            }
            if(resultWrapperRecord.objectName == 'Account') {
            	if(((Account)(resultWrapperRecord.SearchedObj)).Is_Customer__c) {
            		this.info = 'Customer';
                	this.AdditionalInfoObj = new AdditionalInfoWrapper((Account)resultWrapperRecord.SearchedObj);
            	}
            	if(((Account)(resultWrapperRecord.SearchedObj)).Is_Vendor__c) {
            		this.Info = 'Vendor';
	                this.AdditionalInfoObj = new AdditionalInfoWrapper((Account)resultWrapperRecord.SearchedObj);
	            }
            } else if(resultWrapperRecord.objectName == 'Contact') {
                this.Info = 'Contact';
                Contact contactRec = (Contact)resultWrapperRecord.SearchedObj;
                this.Id = contactRec.Account.Id;
                this.AdditionalInfoObj = new AdditionalInfoWrapper(contactRec);
            
            } else if(resultWrapperRecord.objectName == 'Part__c') {
                this.AdditionalInfoObj = new AdditionalInfoWrapper((Part__c)resultWrapperRecord.SearchedObj);
                this.EntityInfoObj = new EntityInfoWrapper(resultWrapperRecord.SearchedObj.get('Part_Number__c'), 
                                                            resultWrapperRecord.SearchedObj.get('Description__c'));
            
            } else if (resultWrapperRecord.objectName == 'Kit_Header__c') {
                this.EntityInfoObj = new EntityInfoWrapper(resultWrapperRecord.SearchedObj.get('Code__c'), 
                                                            resultWrapperRecord.SearchedObj.get('Description__c'));
                this.AdditionalInfoObj = new AdditionalInfoWrapper((Kit_Header__c)resultWrapperRecord.SearchedObj);
            } else if(this.Info == 'Vendor') {
                this.AdditionalInfoObj = new AdditionalInfoWrapper((Account)resultWrapperRecord.SearchedObj);
            } else if (resultWrapperRecord.objectName == 'Product__c') {
                this.AdditionalInfoObj = new AdditionalInfoWrapper((Product__c)resultWrapperRecord.SearchedObj);
                this.EntityInfoObj = new EntityInfoWrapper(resultWrapperRecord.SearchedObj.get('Code__c'), 
                                                            resultWrapperRecord.SearchedObj.get('Description__c'));
            } else if(resultWrapperRecord.objectName == 'Customer_Owned_Unit__c') {
                this.AdditionalInfoObj = new AdditionalInfoWrapper((Customer_Owned_Unit__c)resultWrapperRecord.SearchedObj);
            } else if(resultWrapperRecord.objectName == 'Fee__c') {
                this.EntityInfoObj = new EntityInfoWrapper(resultWrapperRecord.SearchedObj.get('Code__c'), 
                                                            resultWrapperRecord.SearchedObj.get('Description__c'));
                this.AdditionalInfoObj = new AdditionalInfoWrapper((Fee__c)resultWrapperRecord.SearchedObj);
            } else if(resultWrapperRecord.objectName == 'Labour_Code__c') {
                this.EntityInfoObj = new EntityInfoWrapper(resultWrapperRecord.SearchedObj.get('Code__c'), 
                                                            resultWrapperRecord.SearchedObj.get('Description__c'));
                this.AdditionalInfoObj = new AdditionalInfoWrapper((Labour_Code__c)resultWrapperRecord.SearchedObj);
            } else if(resultWrapperRecord.objectName == 'Country__c') {
                this.AdditionalInfoObj = new AdditionalInfoWrapper((Country__c)resultWrapperRecord.SearchedObj);
            }  else if(resultWrapperRecord.objectName == 'CO_Header__c') {
                this.AdditionalInfoObj = new AdditionalInfoWrapper((CO_Header__c)resultWrapperRecord.SearchedObj);
            }
        }
    }

    public class EntityInfoWrapper {
        public String ItemCode;
        public String ItemDescription;

        public EntityInfoWrapper(Object itemCode, Object ItemDescription) {
            this.ItemCode = itemCode != null ? String.valueOf(itemCode) : null;
            this.ItemDescription = ItemDescription != null ? String.valueOf(ItemDescription) : null;
        }
    }
    
    public class AdditionalInfoWrapper {
        // Start: Customer additional fields
        public String Email;
        public String Phone;
        public String Type;
        public String Mobile;
        public String BillingAddress;
        // End: Customer additional fields
        
        // Start: Part additional fields
        public String Item;
        public Decimal Qty;
        public Decimal QtyCommitted;
        public Decimal QtyOnOrder;
        public String Status;
        public Decimal Price;
        public Decimal SubTotal;
        public String Invoice;
        public String FulfillDate;
        public String PartId;
        public String VendorId;
        public boolean IsServiceKit;
        public Decimal AvailableQty;
        public Boolean NonInventoryPart;
        public String Location;
        public String VendorName;
        public String ShopifyStatus;
        public String PartUniqueId;
        public String MFGNumber;
        public String SKUNumber;
        // End: Part additional fields
        
        // Start: SOHeader additional fields
        public String SearchName;
        public String COHeaderId;
        public String CustomerId;
        public String CustomerName;
        public Decimal EstimatedHours;
        public String JobTypeId;
        public String JobType;
        public String UnitId;
        public String UnitDesc;
        public List<String> Concern;
        public List<String> KitConcern;
        // End: SOHeader additional fields
        
        //Start: Vendor additional fields
        public String VendorCode;
        public String CategoryId;
        public String CategoryName;
        public Boolean IsCalculatePartRetailPriceFlag;
        public String RetailBaseValue;
        public Decimal RetailRate;
        public Boolean RetailRounding;
        public Decimal RetailRoundTo;
    	public String PurchaseTaxLevelId;
    	public String PurchaseTaxLevelName;
        public Boolean IsForeignVendor;
        // End: Vendor additional fields
        
        // Start: Product additional fields
        public String ProductType;
        // End: Produuct additional fields
        
        // Start: Unit additional fields
        public String VINNumber;
        public String FormattedName;
        public String StockNumber;
        public String UnitType;
        public String PlateNumber;
        // End: Unit additional fields

        //Country Field
        public String CurrencyCode;
        public String CurrencyName;
        public String CountryName;
        public String Flag;
        public String Symbol;
        public String FormattedFXCurrencyCode;
        public Boolean IsHomeCurrency;
        public Decimal ConversionRate;
        public Boolean Active;
        public String Id;

        public Decimal DealTotal;
        public Decimal ServiceTotal;
        public Decimal MerchTotal;
        public String COStatus;
        public String FeeType;


        
        public AdditionalInfoWrapper(Account accRec) {
            if(accRec.Is_Customer__c) {
                this.Type = accRec.Type__c;
                if(accRec.Preferred_Email__c == null) {
	                if(accRec.Email__c != null) {
	                    this.Email = accRec.Email__c;
	                } else if(accRec.Work_Email__c != null) {
	                    this.Email = accRec.Work_Email__c;
	                } else if(accRec.Other_Email__c != null) {
	                    this.Email = accRec.Other_Email__c;
	                }
	            } else {
	                this.Email = accRec.Preferred_Email__c;
	            }
            } 
            if(accRec.Is_Vendor__c) {
                this.VendorCode = accRec.Vendor_Code__c != null ? accRec.Vendor_Code__c : '';
                //this.CategoryId = accRec.Part_Category_Default__c;
                //this.CategoryName = (categoryId != null) ? accRec.Part_Category_Default__r.Name : '';
                this.RetailBaseValue = accRec.Retail_Base_Value__c != null ? accRec.Retail_Base_Value__c : 'MSRP';
                this.RetailRate = accRec.Retail_Rate__c != null ? accRec.Retail_Rate__c : 0;
                this.RetailRounding = accRec.Retail_Rounding__c;
                this.RetailRoundTo = accRec.Retail_Round_To__c != null ? accRec.Retail_Round_To__c : 0;
                this.PurchaseTaxLevelId = accRec.Purchase_Tax__c;
    			this.PurchaseTaxLevelName = (accRec.Purchase_Tax__c != null) ? accRec.Purchase_Tax__r.Name__c : '';
                this.IsCalculatePartRetailPriceFlag = accRec.Is_Calculate_Part_Retail_Price__c;
                this.IsForeignVendor = accRec.Is_Foreign_Vendor__c;
                if(accRec.Is_Foreign_Vendor__c && accRec.Country__c != null) {
                    this.Flag = accRec.Country__r.Flag_Encoded__c;
                    this.CurrencyCode = accRec.Country__r.Currency_Code__c;
                    this.ConversionRate = XeroUtility.isXeroEnabled() ? accRec.Country__r.Backward_Conversion_Rate__c : accRec.Country__r.Conversion_Rate_With_Markup__c;
                    this.FormattedFXCurrencyCode = accRec.Country__r.Formatted_FX_Currency_Code__c;
                }
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
            this.BillingAddress = String.join(addressPartList, ', ');

            if(accRec.Preferred_Phone__c == null) {
                if(accRec.Home_Number__c != null) {
                    this.Phone = accRec.Formatted_Home_number__c;
                } else if(accRec.Mobile__c != null) {
                    this.Phone = accRec.Formatted_Mobile_Number__c;
                } else if(accRec.Work_Number__c != null) {
                    this.Phone = accRec.Formatted_Work_Number__c;
                }
            } else {
                this.Phone = accRec.Formatted_Preferred_Phone__c;
            }
            this.Mobile = accRec.Formatted_Mobile_Number__c;
        }
        
        public AdditionalInfoWrapper(Contact conRec) {
            this.Id = conRec.Id;
            this.CustomerName = conRec.Account.Name;
            this.Email = conRec.Email;
            this.Phone = (conRec.Formatted_Phone_number__c == null ) ? '' : conRec.Formatted_Phone_number__c;
        }
        
        public AdditionalInfoWrapper(Part__c partRec) {
            this.Item = partRec.Part_Number__c + ' - ' + partRec.Description__c;
            this.Qty = 1;
            this.QtyCommitted = 0;
            partRec.Qty_In_Stock__c = partRec.Qty_In_Stock__c != null ? partRec.Qty_In_Stock__c : 0;
            partRec.Qty_Committed__c = partRec.Qty_Committed__c != null ? partRec.Qty_Committed__c : 0;
            this.Status = (partRec.Qty_In_Stock__c - partRec.Qty_Committed__c) > 0 ? 'In Stock' : 'Out of Stock';
            this.Price = partRec.Retail_Price__c != null ? partRec.Retail_Price__c : 0;
            this.SubTotal = this.Qty * this.price;
            this.Invoice = '';
            this.FulfillDate = String.valueOf(system.today());
            this.PartId = partRec.Id;
            this.VendorId = partRec.Vendor__c;
            this.AvailableQty = partRec.AvailableParts__c != null ?  partRec.AvailableParts__c : 0;
            this.NonInventoryPart = partRec.Non_Inventory_Part__c;
            this.Location = String.join(LocationManagementService.getLocationsList(partRec), ',');
            this.VendorName = partRec.Vendor__r.Name;
            this.ShopifyStatus = String.isNotBlank(partRec.Shopify_Product__c) ? 'Linked' : null;
            this.PartUniqueId = partRec.Part_Id_Text__c;
            this.MFGNumber = partRec.Mfg_Part__c;
            this.SKUNumber = partRec.SKU_Number__c;
            this.QtyOnOrder = partRec.Qty_On_Order__c != null ? partRec.Qty_On_Order__c : 0;
        }
        
        public AdditionalInfoWrapper(Service_Order_Header__c soHeaderRec, String searchConfigName) {
            this.SearchName = 'Service Job Search';
            this.COHeaderId = (soHeaderRec.CO_Header__c != null) ? soHeaderRec.CO_Header__c : '';
            this.CustomerId = soHeaderRec.CO_Header__c != null ? soHeaderRec.CO_Header__r.Customer__c : '';
            this.CustomerName = soHeaderRec.CO_Header__c != null ? soHeaderRec.CO_Header__r.Customer_Name__c : '';
            this.JobTypeId = soHeaderRec.Transaction_Type__c != null ? soHeaderRec.Transaction_Type__c : '';
            this.JobType = soHeaderRec.Transaction_Type__c != null ? soHeaderRec.Transaction_Type__r.Type__c : '';
            this.Concern = soHeaderRec.SO_Concern__c != null ? soHeaderRec.SO_Concern__c.split('\n') : new List<String>();
            if(String.isBlank(searchConfigName) || (String.isNotBlank(searchConfigName) && searchConfigName == 'Service_Order_Header')) {
                this.UnitId = soHeaderRec.Customer_Owned_Unit__c != null ? soHeaderRec.Customer_Owned_Unit__c : '';
                this.UnitDesc = soHeaderRec.Customer_Owned_Unit__c != null ? soHeaderRec.Customer_Owned_Unit__r.Formatted_Name__c : '';
                this.SearchName = 'Appointment Service Job Search';
                this.KitConcern = new List<String>();
                this.EstimatedHours = 0;
                for(Service_Order_Line_Item__c laborSOLI : soHeaderRec.Service_Order_Line_Items__r) {
                    this.EstimatedHours += (laborSOLI.Qty_Needed__c != null) ? laborSOLI.Qty_Needed__c : 0;
                }

                if(soHeaderRec.Service_Order_Kit_Headers__r != null && soHeaderRec.Service_Order_Kit_Headers__r.size() > 0) {
                    for(Service_Order_Kit_Header__c soKitHeaderRec : soHeaderRec.Service_Order_Kit_Headers__r) {
                        if(soKitHeaderRec.Kit_Header__c != null) {
                            this.KitConcern.addAll((soKitHeaderRec.Kit_Header__r.Concern__c != null) ? soKitHeaderRec.Kit_Header__r.Concern__c.split('\n') : new List<String>());
                        }
                    }
                }
            }
        }
        
        public AdditionalInfoWrapper(Product__c productRec) {
            this.ProductType = productRec.Type__c != null ? productRec.Type__c : '';
            this.VendorName = productRec.Vendor__r.Name;
            this.Price = productRec.Price__c;
        }
        
        public AdditionalInfoWrapper(Customer_Owned_Unit__c unitRec) {
            this.VINNumber = unitRec.VIN_Number_Formula__c != null ? unitRec.VIN_Number_Formula__c : '';
            this.StockNumber = unitRec.Stock_Id__c != null ? unitRec.Stock_Id__c : '';
            this.FormattedName = unitRec.Formatted_Name__c != null ? unitRec.Formatted_Name__c : '';
            this.UnitType = unitRec.Unit_Type__c != null ? unitRec.Unit_Type__c : '';
            this.PlateNumber = unitRec.Plate__c != null ? unitRec.Plate__c : '';
            this.Status = String.isNotBlank(unitRec.Status__c) ? unitRec.Status__c : '';
        }

        public AdditionalInfoWrapper(Labour_Code__c labRec) {
            this.Qty = labRec.Hours__c;
            this.Price = labRec.Rate__c;
        }
        
        public AdditionalInfoWrapper(Country__c countryRec) {
            this.Id = countryRec.Id;
            this.CurrencyCode = countryRec.Currency_Code__c;
            this.CurrencyName = countryRec.Currency_Name__c;
            this.CountryName = countryRec.Name__c;
            this.Flag = countryRec.Flag_Encoded__c	;
            this.Symbol = countryRec.Currency_Symbol__c;
            this.ConversionRate = countryRec.Conversion_Rate__c;
            this.Active = countryRec.Active__c;
            this.FormattedFXCurrencyCode = (String.isNotBlank(this.CurrencyCode) && String.isNotBlank(this.CountryName) && String.isNotBlank(this.CurrencyName)) ? (this.CurrencyCode + ' - ' + this.CountryName + ' ' + this.CurrencyName) : '';
        }

        public AdditionalInfoWrapper(CO_Header__c coHeaderRec) {
            this.COHeaderId = coHeaderRec.id;
            this.CustomerId = coHeaderRec.Customer__c;
            this.CustomerName = coHeaderRec.Customer_Name__c;
            this.DealTotal = coHeaderRec.NumberOfDeals__c > 0 ? coHeaderRec.Deal_Header_Total__c : null;
            this.ServiceTotal = coHeaderRec.TotalNumberOfSOHeader__c > 0 ? coHeaderRec.Service_Order_Subtotal__c : null;
            this.MerchTotal = ((coHeaderRec.TotalNumberOfCOLI__c > 0) && ((coHeaderRec.Selling_Group__c == 'Part Sale') || (coHeaderRec.Selling_Group__c == 'Cash Sale') ||
                                (coHeaderRec.Selling_Group__c != 'Internal Service'))) ? coHeaderRec.Merchandise_Total__c : null;
            this.COStatus = coHeaderRec.Order_status__c;
        }

        public AdditionalInfoWrapper(Fee__c feeRec) {
            this.Price = feeRec.Price__c != null ? feeRec.Price__c : 0;
            this.FeeType = feeRec.Type__c != null ? feeRec.Type__c : '';
        }

        public AdditionalInfoWrapper(Kit_Header__c kitRec) {
            this.Price = kitRec.Fixed_Price__c != null ? kitRec.Fixed_Price__c : 0;
            this.Type = kitRec.Service_Kit__c ? 'Service' : 'General';
        }
    }
}