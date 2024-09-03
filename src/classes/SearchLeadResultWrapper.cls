public without sharing class SearchLeadResultWrapper {
	
	public Integer code;
	public List<LeadWrapper> data;
	public String message;
	
	public class LeadWrapper {
		public Integer id;
		public Integer lead_id;
		public String dealer_name;
		public String first_name;
		public String m_name;
		public String last_name;
		public String address;
		public String address2;
		public String city;
		public String zip;
		public String phone;
        public String mobile;
        public String work_number;
		public String email;
		public String alternate_email;
		
		public String state;
		public Integer user_id;
		public String company_id;
		public String status;
		public String lead_status;
		public String sales_step;
		public Integer year;
		public String make;
		public String model;
		
		public String makeId;
		public String modelId;
		
		public String vin;
        public String stock_num;
        public String class_replaceKey;
        public String created;
        public String modified;
        public String crm_lead_url;
        public String dealer_id;
        public String dealervu_customer_id;
        public String dealervu_deal_id;
        public String dealervu_inventory_id;
        
		public List<LeadUnitsWrapper> lead_units;
	}
	
	public class LeadUnitsWrapper {
	    public String vin;
	    public String unit_year;
	    public Integer unit_record_type;
	    public String unit_make;
	    public String unit_model;
        public String vehicle_selection_type;
        public String stock_num;
        public String unit_condition;
        public String unit_category;
        public String inv_instock_unit_id;
		public Decimal sale_price;
	}

	public static SearchLeadResultWrapper parse(String json){
		return (SearchLeadResultWrapper) System.JSON.deserialize(json, SearchLeadResultWrapper.class);
	}

}