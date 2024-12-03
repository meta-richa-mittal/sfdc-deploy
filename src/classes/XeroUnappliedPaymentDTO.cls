public without sharing class XeroUnappliedPaymentDTO {
    public String OverpaymentID;
    public String PrepaymentID;
    public Decimal RemainingCredit;
    public Decimal Total;
    public String DateString;
    public String Reference;

    public XeroUnappliedPaymentDTO(String type, String xeroId) {
        if(type == 'Overpayment') {
            this.OverpaymentID = xeroId;
        } else {
            this.PrepaymentID = xeroId;
        }
    }
}