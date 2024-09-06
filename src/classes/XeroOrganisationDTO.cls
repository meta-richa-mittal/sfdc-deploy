public without sharing class XeroOrganisationDTO {
    public String Name;
    public String OrganisationID;
    public String CountryCode;
    public String EndOfYearLockDate;
    public XeroPaymentTermDTO PaymentTerms;
    public String BaseCurrency;

    public class ActionDTO {
        public String Name;
        public String Status;
    }
}