/**
 * Author: Manoj Sharma
 * Since: June 20, 2022
 * Name: AdminGeneralInformationConfigWrapper
**/
public without sharing class AdminGeneralInformationConfigWrapper {
    public String OrgName;
    public String Locale; 
    public String Language;
    public String TimeZone;
    public String OrgCurrency; 
    public Integer Licenses;
    public String LogoURL;
    public Integer ReportRecordsPerPage;
    public Integer RelatedListSize;
    public Integer MaxUsers;
    public Integer MaxTechnicians;
    public String LabelSize;
    public Integer DashboardRefresh;
    public String DealershipCountry;
    public Integer CashPaymentRounding;
    public Boolean IsPricesIncludeTax;
    public Boolean IsDisplayTaxInvoice;
    public Boolean IsUseAccountingTaxCodes;
    public Boolean IsEnhancedTaxCalculations;
    public Boolean IsTechnicianScheduling;
    public Boolean IsTechnicianHoursCosting;
    public Integer VRRelatedListPageSize;
    public Boolean IsUsingDYMOConnect;
    public List<PicklistEntry> TimeZoneList;
    public Boolean IsCOAsyncActionUsed;
    public Boolean IsMESHEnabled;
    public Boolean IsUseNewPaymentAccounting;
    public String NewPaymentAccountingAllowDate;
}
