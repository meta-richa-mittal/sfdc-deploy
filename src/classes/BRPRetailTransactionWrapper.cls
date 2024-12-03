public without sharing class BRPRetailTransactionWrapper {

    public List<TransactionWrapper> transactions;

    public class TransactionWrapper {
        // All Fields are Req. in this wrapper
        public HeaderWrapper header;
        public List<PartWrapper> parts;
        public List<UnitWrapper> units;
        public List<JobWrapper> jobs;
    }

    public class HeaderWrapper {
        // All Fields are Req. in this wrapper
        public String transaction_number; //Max Length:36     
        public String transaction_open_date; //yyyy-mm-ddThh:mm:ssZ
        public String transaction_close_date; //yyyy-mm-ddThh:mm:ssZ
        public String transaction_source; //In-Store, Online
        public Boolean cancel_flag;
        public String transaction_uuid; 
        public List<CustomerWrapper> customers;
    }

    public class CustomerWrapper {
        // Req. Field
        public String customer_id; //Max Length:36
        public String customer_hash; //Format: ^[a-fA-F0-9]{64}$
        public String recipient; // one from these three (Customer, Self, Dealership)

        // Non Req. Field
        public String city; //Max Length:128
        public String state_province; //Max Length:128
        public String country; //Max Length:128
    }

    public class PartWrapper {
        // Req. Field
        public String part_description;   // Max Length:128
        public String part_number;       //Max Length:18
        public Decimal quantity;        //Format ±9999999.99
        public String quantity_uom;     //Max Length:10
        public Boolean is_special_order;
        public Decimal total_customer_price;
        public Decimal dealer_price;
        public Decimal dealer_cost;
        public Decimal msrp;
        public String currency_code; // Renamed to avoid reserved keyword conflict
        public String associated_job_number;
        public List<AdditionalCostsWrapper> additional_costs;
    }

    public class UnitWrapper {
        // Req. Field
        public String vin;  // Max Length:17
        public String class_code; // New, Used, Demonstrator
        public Decimal total_customer_price;
        public Decimal dealer_price;
        public Decimal dealer_cost;
        public String currency_code; // Renamed to avoid reserved keyword conflict
        // Non Req. Field
        public Decimal odometer_reading;
        public Decimal hours;
        public String sales_lead_id;  // Max Length:36
        public Decimal msrp;
        public List<TradeInswrapper> trade_ins;
        public List<AdditionalCostsWrapper> additional_costs;
        public Decimal financed_amount;
        public Decimal financed_rate;   //Value between 0.0000 and 1.0000        
        public Decimal financed_term_duration;
        public String model; //Max Length:255
    }

    public class JobWrapper {
        // Req. Field
        public String job_number; //Max Length:36
        public String description; // Max Length:255
        public String job_code;//Max Length:3  DET, PDI, SMC, PAI, RPR, OTH
        public Boolean is_warranty_job;
        public Decimal total_customer_job_price;
        public String currency_code; // Renamed to avoid reserved keyword conflict
        public List<TimeCardWrapper> time_cards;
        public List<AdditionalCostsWrapper> additional_costs;
        // Non Req. Field
        public String warranty_claim_number; //Max Length:36
        public String vin; //Max Length:17
        public String manufacturer; //Max Length:36
        public String model; //Max Length:255
        public Integer year;
        public Decimal odometer_reading;
        public Decimal hours;

    }

    public class TimeCardWrapper {
        // Req. Field
        public Decimal labour_worked_hours;
        public Decimal labour_billed_hours;
        public String technician_party_id; //Max Length:36
        // Non Req. Field
        public Decimal labour_rate;
    }

    public class TradeInswrapper {
        // All Non Req. Field
        public String manufacturer; //Max Length:36
        public String vin;         //Max Length:17
        public Decimal odometer_reading;
        public Decimal hours;
        public Decimal price;
        public Integer year; 
    }

    public class AdditionalCostsWrapper {
        // Req. Field
        public String type; //Tax, Logistic, Discount, Other
        public String description; //Max Length:255
        public Decimal amount;
    } 
}