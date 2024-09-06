/**
 * Author: Nidhi Sharma
 * Since: June 16, 2022
 * Name: AdminPreferredPaymentConfigWrapper
**/
public without sharing class AdminPreferredPaymentConfigWrapper {

    public String IntegrationConfigured;
    public String PublicKey; 
    public String PrivateKey;
    public Boolean Enabled;
    public List<PaymentTerminalWrapper> TerminalList; 
    public String AddTerminalURL;
    public String ManageTerminalsURL;
    public Decimal MaxCreditAmount;
}