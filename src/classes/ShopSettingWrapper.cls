public class ShopSettingWrapper {
    public String Id;
    public String Day;
    public Boolean IsWorking;
    public String FromTime;
    public String ToTime;
    public Integer OrderNumber;
    
    public ShopSettingWrapper(Shop_Settings__c shopSettingInstance, Boolean isSetOrderNumber) {
    	setfields(shopSettingInstance, true);
    }
    
    public ShopSettingWrapper(Shop_Settings__c shopSettingInstance) {
    	setfields(shopSettingInstance, false);
    }
    
    private void setfields(Shop_Settings__c shopSettingInstance, Boolean isSetOrderNumber) {
    	this.Id = shopSettingInstance.Id;
    	this.Day = shopSettingInstance.Day__c;
    	this.IsWorking = shopSettingInstance.Is_Working__c;
    	this.FromTime = shopSettingInstance.From_Time__c;
    	this.ToTime = shopSettingInstance.To_Time__c;
    	if(isSetOrderNumber) {
    		this.OrderNumber = (Integer)shopSettingInstance.Order_Number__c;
    	}
    }
}