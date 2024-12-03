/**
 * Name: CustomerMessageAndEmailCtrl 
 * Description: 
 * 
**/
global without sharing class CustomerMessageAndEmailCtrl {
    global CustomerMessageAndEmailCtrl (NewHomePageCtrl controller){}
    public CustomerMessageAndEmailCtrl() {}
    
    @RemoteAction
    global static String saveDeviceInfo(String loggedInDeviceJson) {
        loggedInDeviceJson = BPUtility.getDecodedString(loggedInDeviceJson);
        try {
        	LoggedInDeviceService.saveDeviceInfo(loggedInDeviceJson);
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
        return 'Success';
    }
    
    
    @RemoteAction
    global static String getBrandingLocationList() {
        try {
            List<BrandingLocationWrapper> brandingLocationObjList = BrandingLocationService.getBrandingLocationList();
            return BPUtility.getEncodedString(system.JSON.serialize(brandingLocationObjList, true));
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    @RemoteAction
    global static String getDeviceInfoByDeviceUUID(String UUID) {
        UUID = BPUtility.getDecodedString(UUID);
        try {
        	LoggedInDeviceWrapper loggedInDeviceObj = LoggedInDeviceService.getDeviceInfoByDeviceUUID(UUID);
        	String loggedInDeviceObjStr = (loggedInDeviceObj != null) ? system.JSON.serialize(loggedInDeviceObj) : null;
            return BPUtility.getEncodedString(loggedInDeviceObjStr);
        } catch(Exception e) {
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    @RemoteAction
    global static String emailCustomerApproval(String customerApprovalRecId, String emailAddressJson){
        customerApprovalRecId = BPUtility.getDecodedString(customerApprovalRecId );
        emailAddressJson = BPUtility.getDecodedString(emailAddressJson);
        
        SendEmail.EmailAddressWrapper emailAddressObj = (SendEmail.EmailAddressWrapper) system.JSON.deserialize(emailAddressJson, SendEmail.EmailAddressWrapper.class);
        
        List<String> emailList = String.isNotBlank(emailAddressObj.ToEmail) ? new List<String>{emailAddressObj.ToEmail} : new List<String>(); 
        List<String> ccEmailList = String.isNotBlank(emailAddressObj.CcEmail) ? new List<String>{emailAddressObj.CcEmail} : new List<String>();
        List<Service_Job_To_Customer_Approval__c> customerApprovalList = [SELECT Name, Service_Order_Header__r.CO_Header__r.Name, Service_Order_Header__r.CO_Header__r.Customer_Name__c FROM Service_Job_To_Customer_Approval__c WHERE Customer_Approval__c =: customerApprovalRecId Limit 1];
        String subject = '';
        if(customerApprovalList.size() > 0) {
            subject =  customerApprovalList[0].Service_Order_Header__r.CO_Header__r.Name +' - ' +  customerApprovalList[0].Service_Order_Header__r.CO_Header__r.Customer_Name__c;
            subject = 'Job approval - ' + subject;
        } else {
            subject = 'Customer Approval Record';
        }
        String optionalMessage = String.isNotBlank(emailAddressObj.OptionalMessage) ? emailAddressObj.OptionalMessage : ''; 
        String response = SendEmail.sendInvoice(emailList, ccEmailList, subject, optionalMessage, customerApprovalRecId, null, null, emailAddressObj.ReplyTo);
        return response;
    }
    
    @RemoteAction
    global static String updateEmail(String jSONString) {
    	jSONString = BPUtility.getDecodedString(jSONString);
    	AccountWrapper accObj = (AccountWrapper) System.JSON.deserialize(jSONString, AccountWrapper.class);
    	try {
    		Account accRec = new Account(Id = accObj.Id);
    		if(accObj.Type == 'Individual' && String.isNotBlank(accObj.PrimaryEmail)) {
    			accRec.Email__c	= accObj.PrimaryEmail;
    		} else if(accObj.Type == 'Business' && String.isNotBlank(accObj.PrimaryEmail)) {
    			accRec.Work_Email__c = accObj.PrimaryEmail;
    		} else if(String.isNotBlank(accObj.AlternateEmail)) {
    			accRec.Other_Email__c = accObj.AlternateEmail;
    		}
    		update accRec;
    	} catch (Exception e) {
    		throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
    	}
    	
    	return 'Success';
    }

    @RemoteAction
    global static String getReplyToEmalList() {
    	List<Object> emailObjList = new List<Object>();
        OrgWideEmailAddress oweaRec = SendEmail.getOWEA_UserSelection();
        if(oweaRec != null) {
            emailObjList.add(new Map<String, Object>{'Email' => oweaRec.Address, 'IsDefault' => true});
        }
        emailObjList.add(new Map<String, Object>{'Email' => UserInfo.getUserEmail(), 'IsDefault' => false});
        return BPUtility.getEncodedString(System.json.serialize(emailObjList));
    }
    
    public class AccountWrapper {
    	 public String Id;
    	 public String Type;
    	 public String PrimaryEmail;
    	 public String AlternateEmail;
    }
}