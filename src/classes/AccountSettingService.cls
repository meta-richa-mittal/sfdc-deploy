/*
* This class has CRUD methods related to settings & controls section of Acoount Settings module
* Since : May 2018
*/
public without sharing class AccountSettingService {
    
	public static final String INTEGRATED_PAYMENT_PROCESSOR = 'Integrated payment processor';

	/*
	* This method returns the shop setting configuration 
	*/
    public static List<ShopSettingWrapper> getShopSettingData() {
    	List<ShopSettingWrapper> shopSettingData;
    	List<Shop_Settings__c> shopSettingList = [Select Name, Day__c, Is_Working__c, From_Time__c, To_Time__c, Order_Number__c 
    		                                          from Shop_Settings__c where Name != null order by Order_Number__c];
    	if(shopSettingList.size() > 0) {
    		shopSettingData = new List<ShopSettingWrapper>();
    		for(Shop_Settings__c shopSettingInstance : shopSettingList) {
    			shopSettingData.add(new ShopSettingWrapper(shopSettingInstance, true));
    		}
    	}
    	return shopSettingData;
    }
    
    public static List<ShopSettingWrapper> getShopSettingDataForParticularDay(String day) {
    	List<ShopSettingWrapper> shopSettingData;
    	List<Shop_Settings__c> shopSettingList = [Select Name, Day__c, Is_Working__c, From_Time__c, To_Time__c 
    		                                          from Shop_Settings__c where Name != null And Day__c =: day order by Order_Number__c];
    	if(shopSettingList.size() > 0) {
    		shopSettingData = new List<ShopSettingWrapper>();
    		for(Shop_Settings__c shopSettingInstance : shopSettingList) {
    			shopSettingData.add(new ShopSettingWrapper(shopSettingInstance));
    		}
    	}
    	return shopSettingData;
    }
    
    public static List<String> getShopWorkingDays() {
    	List<String> shopSettingWorkingDays;
    	List<Shop_Settings__c> shopSettingList = [Select Day__c from Shop_Settings__c where Is_Working__c = true order by CreatedDate];
    	if(shopSettingList.size() > 0) {
    		shopSettingWorkingDays = new List<String>();
    		for(Shop_Settings__c shopSettingInstance : shopSettingList) {
    			shopSettingWorkingDays.add(shopSettingInstance.Day__c);
    		}
    	}
    	return shopSettingWorkingDays;
    }

	public static String getShopWorkingDaysString() {
		List<String> shopWorkingDaysList = getShopWorkingDays();
		return shopWorkingDaysList.size() > 0 ? String.join(shopWorkingDaysList, '; ') : Constants.EVERY_BUSINESS_DAY;
	}
    
    /*
    * Utility method to convert list of wrapper object to list of actual salesforce object
    */
    public static List<Shop_Settings__c> setShopSettingConfigRec(List<ShopSettingWrapper> shopSettingWrapperList) {
        List<Shop_Settings__c> shopSettingList = new List<Shop_Settings__c>();
    	for(ShopSettingWrapper shopSettingInstance : shopSettingWrapperList) {
    		Shop_Settings__c shopSettingObject = new Shop_Settings__c();
	        shopSettingObject.Id = shopSettingInstance.Id;
	        shopSettingObject.Day__c = shopSettingInstance.Day;
	        shopSettingObject.Is_Working__c = shopSettingInstance.IsWorking;
	        shopSettingObject.From_Time__c = shopSettingInstance.FromTime;
	        shopSettingObject.To_Time__c = shopSettingInstance.ToTime;
    		shopSettingList.add(shopSettingObject);
        }
    	return shopSettingList;
    }
    
    public static Boolean isWorkingDayByDate(Date dateToCheck) {
        if(AccessControl.ifObjectFieldIsAccessible('Shop_Settings__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        
        String day = getDayNameFromDate(dateToCheck);
        List<Shop_Settings__c> shopSettingList = [Select Id from Shop_Settings__c where Day__c =: day AND Is_Working__c = true];
        return (shopSettingList.size() > 0);
    }
    
    public static String getDayNameFromDate(Date dateToCheck) {
        Datetime dt = DateTime.newInstance(dateToCheck, Time.newInstance(0, 0, 0, 0));
        return dt.format('EEEE');
    }
    
    public static List<PaymentMethodWrapper> getPaymentMethodsData() {
    	List<PaymentMethodWrapper> paymentMethodObjList = new List<PaymentMethodWrapper>();
    	
    	if(AccessControl.ifObjectFieldIsAccessible('Payment_Method__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
    	List<Payment_Method__c> paymentMethodRecList = [Select Name, Is_Active__c, Icon_Link__c, Undeposited_Funds__c, Is_Surcharge_Applicable__c, Surcharge_Percentage__c from Payment_Method__c where Name != null 
    															AND Is_Only_Updeposited_Payment_Method__c = false order by Order_Number__c];
		for(Payment_Method__c paymentMethodRec : paymentMethodRecList) {
			paymentMethodObjList.add(new PaymentMethodWrapper(paymentMethodRec));
		}
    	return paymentMethodObjList;
    }
    
    public static List<Payment_Method__c> setPaymentMethodConfiguration(List<PaymentMethodWrapper> paymentMethodObjList) {
        List<Payment_Method__c> paymentMethodRecList = new List<Payment_Method__c>();
		Boolean isAllPaymentMethodDeactivated = false;
		paymentMethodObjList = setUndepositFundGLOnPaymentMethod(paymentMethodObjList, false);
    	for(PaymentMethodWrapper paymentMethodObj : paymentMethodObjList) {
    		Payment_Method__c paymentMethodRec = new Payment_Method__c(Id = paymentMethodObj.Id);
			paymentMethodRec.Is_Active__c = paymentMethodObj.IsActive;
			paymentMethodRec.Undeposited_Funds__c = paymentMethodObj.UndepositedFunds;
			paymentMethodRec.Surcharge_Percentage__c = paymentMethodObj.SurchargePercentage;
    		paymentMethodRecList.add(paymentMethodRec);
    		if(paymentMethodObj.IsActive) {
    			isAllPaymentMethodDeactivated = true;
    		}
        }
        if(!isAllPaymentMethodDeactivated)  {
        	throw new BlackpurlException('You must leave at least one payment method active');
        }
    	return paymentMethodRecList;
    }

    public static List<ServiceJobStatusWrapper> getServiceJobStatusConfiguration() {
        List<ServiceJobStatusWrapper> allSOStatusRecList = new List<ServiceJobStatusWrapper>();
        if(AccessControl.ifObjectFieldIsAccessible('SO_Status__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
		for(SO_Status__c soStatusRec : [Select Id, Name__c, Short_Name__c, Order_No__c, Is_Active__c, Is_Required__c, Text_Color__c, Background_Color__c, Default_Clock_ON_Status__c FROM SO_Status__c ORDER BY Order_No__c]) {
            allSOStatusRecList.add(new ServiceJobStatusWrapper(soStatusRec));
        }
        return allSOStatusRecList;
	}

	public static void saveServiceJobStatusConfiguration(List<ServiceJobStatusWrapper> soStatusObjList) {
        List<SO_Status__c> soStatusRecList = new List<SO_Status__c>();
    	for(ServiceJobStatusWrapper soStatusObj : soStatusObjList) {
    		SO_Status__c soStatusRec = new SO_Status__c(Id = soStatusObj.Id);
			soStatusRec.Is_Active__c = soStatusObj.IsActive != null ? soStatusObj.IsActive : false;
			if(String.isNotBlank(soStatusObj.Name)) soStatusRec.Name__c = soStatusObj.Name;
			if(String.isNotBlank(soStatusObj.ShortName)) soStatusRec.Short_Name__c = soStatusObj.ShortName;
			if(String.isNotBlank(soStatusObj.BgColor)) soStatusRec.Background_Color__c = soStatusObj.BgColor;
			if(String.isNotBlank(soStatusObj.TextColor)) soStatusRec.Text_Color__c = soStatusObj.TextColor;
			soStatusRec.Default_Clock_ON_Status__c = (soStatusObj.IsTechClockJobStatus != null && soStatusObj.IsTechClockJobStatus && soStatusObj.IsActive);
    		soStatusRecList.add(soStatusRec);
        }
		DMLUtility.updateSobjectList('SO_Status__c', soStatusRecList);
    }

    public static List<PaymentMethodWrapper> getActivePaymentMethodNameList() {
    	List<PaymentMethodWrapper> paymentMethodObjList = new List<PaymentMethodWrapper>();
    	
    	if(AccessControl.ifObjectFieldIsAccessible('Payment_Method__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
    	List<Payment_Method__c> paymentMethodRecList = [Select Name, Is_Active__c, Icon_Link__c, Undeposited_Funds__c, Is_Surcharge_Applicable__c, Surcharge_Percentage__c from Payment_Method__c where (Name != null AND Is_Active__c = true) OR 
															Name =: INTEGRATED_PAYMENT_PROCESSOR order by Order_Number__c];
		
		for(Payment_Method__c paymentMethodRec : paymentMethodRecList) {
			paymentMethodObjList.add(new PaymentMethodWrapper(paymentMethodRec));
		}
    	return paymentMethodObjList;
    }

	public static void setUndepositFundGLOnShopifyPaymentMethod(List<PaymentMethodWrapper> paymentMethodObjList, String shopifyPaymentMethodId) {
		List<PaymentMethodWrapper> shopifyPaymentMethodObjList = new List<PaymentMethodWrapper>();
		for(PaymentMethodWrapper paymentMethodObj : paymentMethodObjList) {
			if(paymentMethodObj.Id == shopifyPaymentMethodId) {
				shopifyPaymentMethodObjList  = new List<PaymentMethodWrapper>{paymentMethodObj};
				break;
			}
		}
		if(shopifyPaymentMethodObjList.size() > 0) {
			paymentMethodObjList = setUndepositFundGLOnPaymentMethod(shopifyPaymentMethodObjList, true);
			Payment_Method__c paymentMethodRec = new Payment_Method__c(Id = paymentMethodObjList[0].Id);
			paymentMethodRec.Undeposited_Funds__c = paymentMethodObjList[0].UndepositedFunds;
			DMLUtility.updateSobjectList('Payment_Method__c', paymentMethodRec);
        }
	}

    public static List<PaymentMethodWrapper> setUndepositFundGLOnPaymentMethod(List<PaymentMethodWrapper> paymentMethodObjList, Boolean isShopifyPaymentMethod) {
		Map<Id, Payment_Method__c> idToPaymentMethodRecMap = new Map<Id, Payment_Method__c>([SELECT Id, Name, Is_Active__c, Undeposited_Funds__c FROM Payment_Method__c]);
        String cashPaymentUndepositedFundsGl = getCashPaymentUndepositedFundsGl(idToPaymentMethodRecMap);
		for(PaymentMethodWrapper paymentMethodObj: paymentMethodObjList) {
			if((isShopifyPaymentMethod || paymentMethodObj.IsActive) && String.isBlank(idToPaymentMethodRecMap.get(paymentMethodObj.Id).Undeposited_Funds__c)) {
				paymentMethodObj.UndepositedFunds = cashPaymentUndepositedFundsGl;
			}
		}
		return paymentMethodObjList;
	}

	private static String getCashPaymentUndepositedFundsGl(Map<Id, Payment_Method__c> idToPaymentMethodRecMap) {
		for(Payment_Method__c paymentMethodRec: idToPaymentMethodRecMap.values()) {
			if(paymentMethodRec.Name == 'Cash') {
				return paymentMethodRec.Undeposited_Funds__c;
			}
		}
		return null;
	}
}