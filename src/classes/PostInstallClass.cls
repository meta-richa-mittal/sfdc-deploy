global without sharing class PostInstallClass implements InstallHandler {
    public static final String NAMESPACE = 'BlackPurlCore__';
    
    global void onInstall(InstallContext context) {
        String emailTextBody;
        try {
            if (context.previousVersion() == null || Test.isRunningTest()) {
                ConfigurationScript.runAll();
                DataLoadForCountryState ds = new DataLoadForCountryState();
            } else if(context.isUpgrade()) {
                ConfigurationScript.deleteConfigurations();
                ConfigurationScript.createConfigurations();
                ConfigurationScript.createUserDependentFeature();
                ConfigurationScript.createQBIFWIntegrationConfig();
                ConfigurationScript.setDashboardRefreshMinutes();
				ConfigurationScript.createCOARestrictionConfig();
            }
            PostInstallService.getInstance(context).startService();
        } catch (Exception ex) {
            emailTextBody = 'Package got installed with post installed script failure. Please install configuration record manually.' +  ex.getMessage() + ex.getStackTraceString() ;
        }

        try {
	        if(context.installerID() != null && String.isNotBlank(emailTextBody)) {
	            User u = [Select Id, Email from User where Id =  : context.installerID()];
	            String toAddress = u.Email;
	            String[] toAddresses = new String[]{toAddress};
	    
	            if (AccessControl.ifSingleEmailSendAllowed() == false) {
	                throw new BlackPurlException(Constants.EMAIL_SEND_NOT_PERMIT);
	            }
	            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
	            mail.setToAddresses(toAddresses);
	            mail.setReplyTo('support@package.dev');
	            mail.setSenderDisplayName('My Package Support');
	            mail.setSubject('Package install successful');
	            mail.setPlainTextBody(emailTextBody);
	            Messaging.sendEmail(new Messaging.Email[]{mail});
	        }
        } catch (Exception ex) {}
    }
}