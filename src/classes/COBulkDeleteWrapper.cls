/**
 * Author: Nidhi Sharma
 * Since: March 05, 2024
 * Name: BPScriptManager
 * Description: Apex class for all scripts executed after package installation
**/
public without sharing class COBulkDeleteWrapper {
    
    public Id COHeaderId;
    public Boolean IsDeleteOrder;

    public SectionWrapper MerchSection;
    public List<SectionWrapper> ServiceSections;
    public SectionWrapper DealSection;

    public class SectionWrapper {
        public Id SectionId;
        public Boolean IsDeleteSection;
        public Boolean IsDeleteNotes;
        public Boolean IsDeleteTechnicianTimes;
        public Boolean IsDeleteCustomerApprovals;
        public Boolean IsDeleteDocuments;
        public List<Id> LineItemIds;
        public List<Id> UnitIds;
        public List<Id> TradeInIds;
        public SectionWrapper DealFinanceSection;
    }
}