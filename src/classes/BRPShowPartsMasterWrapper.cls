/** 
* Author: Raghav Khandelwal
* Since: Apr 10, 2021 
* Name: BRPShowPartsMasterWrapper 
* Description: Wrapper class used for GetpartMasterApi
**/
public without sharing class BRPShowPartsMasterWrapper {
    
    
    public ShowPartsMasterDataArea ShowPartsMasterDataArea;

    public class ShowPartsMasterDataArea {
        public PartMaster PartMaster;
    }

    public class PartMaster {
        public PartMasterHeader PartMasterHeader;
        public List<PartMasterLine> PartMasterLine;
    }

    public class PartMasterHeader {
        public String PartMasterCountryCode;
    }

    public class PartMasterLine {
        public PartsProductItem PartsProductItem;
        public List<PartMasterPricing> PartMasterPricing;
        public String FirstModelYear;
        public String LastModelYear;
        public String VintagePartIndicator;
        public String ItemWeightMeasure;
        public String AfterMarketCode;
        public List<String> ProductLineCode;
        public String PartCategoryCode;
        public List<SupersedingPartGroup> SupersedingPartGroup;
    }

    public class PartsProductItem {
        public String PartItemDescription;
        public ItemIdentificationGroup ItemIdentificationGroup;
        public String PackageQuantity;
        public String MinimumBuyQuantity;
        public String UnitCodeForPackageQty;
    }

    public class ItemIdentificationGroup {
        public List<ItemIdentification> ItemIdentification;
    }
  
    public class ItemIdentification {
        public String ItemID;
        public String AgencyRoleCode;
    }

    public class PartMasterPricing {
        public String PartMasterPriceTypeString;
        public String TotalAmount;
        public String UnitPriceAmount;
    }

    public class SupersedingPartGroup {
        public SupersedingPartDetail SupersedingPartDetail;
        public SupersedingPartDetail SupersededPartDetail;
    }

    public class SupersedingPartDetail {
        public String SupersedingPartNumberID;
    }
}