/**
 * Author: Nidhi Sharma
 * Since: Feb 16, 2022
 * Name: PaymentTerminalWrapper
 * Description: Payment Terminal Wrapper class.
**/
public without sharing class PaymentTerminalWrapper {
    public String Id;
    public String Nickname;
    public String RegistrationCode;
    public String Status;
    public String PreferredPaymentId;
    public Boolean IsSignatureRequired;

    public PaymentTerminalWrapper(Payment_Terminal__c terminalRec) {
        if(terminalRec != null) {
            this.Id = terminalRec.Id;
            this.Nickname = terminalRec.Nickname__c;
            this.PreferredPaymentId = terminalRec.Preferred_Payment_Id__c;
            this.IsSignatureRequired = terminalRec.Is_Signature_Required__c;
        }
    }
}