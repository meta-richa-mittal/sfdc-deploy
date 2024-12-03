/**
* Author: Nidhi Sharma
* Since: Sept 17, 2020
* Name: PaymentMethodWrapper
* Description: Apex class to wrap variables for payment method section in user settings page
**/
public without sharing class PaymentMethodWrapper {
	public String Id;
    public String Name;
    public Boolean IsActive;
    public String IconLink;
    public String UndepositedFunds;
    public Boolean IsSurchargeApplicable;
    public Decimal SurchargePercentage;
    
    public PaymentMethodWrapper(Payment_Method__c paymentMethodRec) {
    	this.Id = paymentMethodRec.Id;
    	this.Name = paymentMethodRec.Name;
    	this.IsActive = paymentMethodRec.Is_Active__c;
    	this.IconLink = paymentMethodRec.Icon_Link__c;
        this.UndepositedFunds = paymentMethodRec.Undeposited_Funds__c;
        this.IsSurchargeApplicable = paymentMethodRec.Is_Surcharge_Applicable__c;
        this.SurchargePercentage = paymentMethodRec.Surcharge_Percentage__c;
    }
}