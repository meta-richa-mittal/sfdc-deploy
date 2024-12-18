public without sharing class BRPDealerWrapper { 
    
    public String Id;
	public String PartyId;
	public String Telephone;
	public String Fax;
	public String Website;
	public String Email;
	public String AddressLine1;
	public String AddressLine2;
	public String City;
	public String Postcode;
	public String StateOrProvince;
	public String Country;
	public String Company;
	public List<BRPDealerProductLineWrapper> ProductLineList;
	
	public BRPDealerWrapper(BRP_Dealers__c brpDealerRec) {
		this.PartyId = brpDealerRec.Party_ID__c;
		this.Telephone = brpDealerRec.Telephone__c;
		this.Fax = brpDealerRec.Fax__c;
		this.Website = brpDealerRec.Website__c;
		this.Email = brpDealerRec.Email__c;
		this.AddressLine1 = brpDealerRec.Street__c; 
		this.AddressLine2 = brpDealerRec.Line_Two__c;
		this.City = brpDealerRec.City__c;
		this.Postcode = brpDealerRec.Postcode__c;
		this.StateOrProvince = brpDealerRec.State__c;
		this.Country = brpDealerRec.Country__c;
		this.Company = brpDealerRec.Company_Name__c;
		this.Id = brpDealerRec.Id;
		this.ProductLineList = new List<BRPDealerProductLineWrapper>();
		for(BRP_Dealer_Product_Line__c brpDealerProductLine : brpDealerRec.BRP_Dealer_Product_Lines__r) {
            this.ProductLineList.add(new BRPDealerProductLineWrapper(brpDealerProductLine));
        }
	}

	public BRPDealerWrapper(BRPDealerIntegration.DealerWrapper dealerObj) {
		this.PartyId = dealerObj.dealer_no;
		this.AddressLine1 = dealerObj.address.street;
		this.City = dealerObj.address.city;
		this.Postcode = dealerObj.address.postal_code;
		this.StateOrProvince = dealerObj.address.state;
		this.Country = BRPDealerIntegration.getCountryFromCode(dealerObj.address.country);
		this.Company = dealerObj.dealer_name + ' (' + dealerObj.legal_name + ')';

		this.ProductLineList = new List<BRPDealerProductLineWrapper>();
		for(String productLineCode : dealerObj.product_lines) {
            this.ProductLineList.add(new BRPDealerProductLineWrapper(productLineCode));
        }
	}
	
	public class BRPDealerProductLineWrapper {
		public String Name;
		public BRPDealerProductLineWrapper(BRP_Dealer_Product_Line__c brpDealerProductLineRec) {
			this.Name = brpDealerProductLineRec.Name;
		}
		public BRPDealerProductLineWrapper(String productLineCode) {
			this.Name = BRPDealerIntegration.getProductLineFromCode(productLineCode);
		}
	}

}