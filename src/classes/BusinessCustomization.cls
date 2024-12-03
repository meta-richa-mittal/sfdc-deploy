public without sharing class BusinessCustomization {
    public Boolean IsMMSFieldLabelsCustomized;
    
    public BusinessCustomization(Business_Customization__c customizationRec) {
    	this.IsMMSFieldLabelsCustomized = customizationRec.Customize_MMS_Labels__c;
    }
}