@RestResource(urlMapping='/Users/*')
global with sharing class RestAPI {
 @HttpPost 
global static boolean doPost(){
     String jsonString = RestContext.request.requestBody.toString();
     TrialWrapper trialWrapperReq = (TrialWrapper) System.JSON.deserialize(jsonString, TrialWrapper.class);
    //System.assert(false,trialWrapperReq.LastName);
     
     //system.assert(false,jsonString);
    Database.DMLOptions dlo = new Database.DMLOptions(); 
    dlo.EmailHeader.triggerUserEmail   = true; 
    Profile ProfileRec = [SELECT Id, Name from Profile where Name = 'Blackpurl'];
    List<organization> organizationRec = [ SELECT ID, Name FROM ORGANIZATION];
    List<user> userRecList = new List<user>();
    User u = new User();
    u.FirstName = trialWrapperReq.FirstName;
    u.LastName = trialWrapperReq.LastName;
    u.Alias =  trialWrapperReq.FirstName.length() > 1 ? (trialWrapperReq.FirstName.substring(0,1) + trialWrapperReq.LastName.substring(0, (trialWrapperReq.LastName.length() > 4) ? 4 : trialWrapperReq.LastName.length())) : (trialWrapperReq.LastName.substring(0,(trialWrapperReq.LastName.length() > 4) ? 4 : trialWrapperReq.LastName.length()));
        // )
        u.Email = trialWrapperReq.Email ;
    u.Username = '';
    u.CommunityNickname = '';
    u.ProfileId = ProfileRec.Id;
    u.TimeZoneSidKey = trialWrapperReq.TimeZoneSidKey;
    u.LocaleSidKey = 'en_US';
    u.EmailEncodingKey = 'ISO-8859-1';
    u.LanguageLocaleKey = 'en_US';   
    String orgName = (organizationRec[0].Name).replace(' ','');
    orgName = orgName.toLowerCase();
    u.FederationIdentifier = orgName+'.admin1@bp.community.fedid';
    u.Username = trialWrapperReq.Email;
    u.CommunityNickname = trialWrapperReq.Email.split('@').get(0)+Math.round(Math.random()*1000);
    userRecList.add(u);
    Database.SaveResult SR = Database.insert(u,dlo);
    //system.assert(false,SR.getErrors().Database.Error);
    
    
    if (! sr.isSuccess()) {
        for(Database.Error err : sr.getErrors()) {
            if((err.getStatusCode()) ==StatusCode.DUPLICATE_USERNAME || (err.getStatusCode()) ==StatusCode.DUPLICATE_COMM_NICKNAME){            
				System.debug(err.getStatusCode() + ': ' + err.getMessage());
				u.Username = trialWrapperReq.Email.split('@').get(0)+Math.round(Math.random()*1000)+'@blackpurl.com';
				u.CommunityNickname = trialWrapperReq.Email.split('@').get(0)+'bp'+Math.round(Math.random()*1000);
				System.debug('\n\n\n\n'+ u);
				SR =  Database.insert(u,dlo);
			}
	  }
	} 
	if(Sr.isSuccess()){
		Business_Profile__c businessprofileRec = new Business_Profile__c();
		businessprofileRec.Business_Email__c = trialWrapperReq.Email;
		if(trialWrapperReq.PhoneNumber.isNumeric()){
			businessprofileRec.Business_Phone__c = trialWrapperReq.PhoneNumber;
		}
		businessprofileRec.Business_Postal_Code__c = trialWrapperReq.PostalCode;
		businessprofileRec.Same_As_Business_Address__c = true;
		businessprofileRec.Business_City__c = trialWrapperReq.City;
		businessprofileRec.Business_Name__c = trialWrapperReq.CompanyName; 
		businessprofileRec.Business_Street_Address1__c = trialWrapperReq.Street;
		List<Country__c> countryRec = [Select Id,Name__c,(Select Id,Name__c From States__r) from Country__c where Name__c =: trialWrapperReq.Country];
		if(countryRec.size() > 0){
			businessprofileRec.Business_Country__c = countryRec[0].Id;
			for(State__c stateRec : countryRec[0].States__r){
				if(StateRec.Name__c.containsIgnoreCase(trialWrapperReq.State)){
					businessprofileRec.Business_State__c = stateRec.Id; 
					if(StateRec.Name__c.equalsIgnoreCase(trialWrapperReq.State)){
						break;
					}
				}
					
			}
			if(String.IsBlank( businessprofileRec.Business_State__c)){
				system.debug('test');
				 businessprofileRec.Business_State__c = countryRec[0].States__r[0].Id;
			}
			
		}
		insert businessprofileRec;
		Configurations__c config = Configurations__c.getOrgDefaults();
		if(trialWrapperReq.IncludeTax.equalsIgnorecase('1')){
			config.Tax_Included_Pricing__c = true;
			
		}else{
			config.Tax_Included_Pricing__c = false;
		}
		 
		List<Sales_Tax__c> salesTaxDefault = [Select Id from Sales_Tax__c where Default__c = true];
				//system.assert(false,salesTaxDefault[0].Id);                
				
		if(salesTaxDefault.size() > 0){
			String salestaxId = String.valueOf(salesTaxDefault[0].Id).substring(0,15);
			config.Default_Tax_on_Labor__c = salestaxId;
			config.Default_Tax_on_Vendor_Product__c = salestaxId;
			config.Default_Tax_on_Part__c = salestaxId;
			config.Default_Tax_on_Fee__c = salestaxId;
			config.Default_Tax_on_Unit__c = salestaxId;
		}
		config.Country_Id__c = businessprofileRec.Business_Country__c;
		config.State_Id__c = businessprofileRec.Business_State__c;
		        
		List<Timezone__c> timeZoneRecList = [Select Id From Timezone__c where Country__c = :businessprofileRec.Business_Country__c and State__c =:businessprofileRec.Business_State__c  ];
		if(timeZoneRecList.size() == 0){
			Timezone__c timeZoneRec = new Timezone__c();
			timeZoneRec.Country__c = businessprofileRec.Business_Country__c;
			timeZoneRec.State__c = businessprofileRec.Business_State__c;
			timeZoneRec.Timezone_Label__c = trialWrapperReq.TimeZoneDisplayName;
			insert timeZoneRec;
			system.debug(timeZoneRec);
			config.Time_Zone__c = timeZoneRec.Id;
		} else{
			config.Time_Zone__c = timeZoneRecList[0].Id;
		}
		upsert config ;
		system.debug(config);
		return true;
                
		}else if(!Sr.isSuccess()){
			String Subject;
			String htmlBody;
			List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
			for(Database.Error err : sr.getErrors()) {
				if((err.getStatusCode()) ==StatusCode.DUPLICATE_USERNAME){  
					Subject = 'User Already Exist with this EmailAddress';
					htmlBody ='<p>Hi '+ trialWrapperReq.FirstName +',</p>' ;
					htmlBody += '<p>Your email address is already registered with Blackpurl. Please, use that email address to login to your account.</p>';
					htmlBody += '<p>Thanks,</p>';
					htmlBody += 'Blackpurl';
					Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
					List<String> sendTo = new List<String>();
					sendTo.add( trialWrapperReq.Email);
					mail.setToAddresses(sendTo);
					//mail.setReplyTo(sentFromEmailString);
					mail.setSenderDisplayName('BlackPurl Team');
					mail.setSubject(subject);
					mail.setHtmlBody(htmlBody);
					mails.add(mail); 
				}
			}
                
                
                
			if(mails.size()> 0){
				Messaging.sendEmail(mails);    
			}
			return false;
		}
   
		return false;
    }

}