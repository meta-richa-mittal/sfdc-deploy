/** 
* Author: Manoj Sharma
* Since: Dec 1, 2021
* Name: PopulateIndividualTaxSalesTaxBatch 
* Description: Batch class to set sales tax lookup value using sales tax item name.
**/
global without sharing class PopulateIndividualTaxSalesTaxBatch implements Database.Batchable<sobject>, Database.Stateful{
    public Map<String, Sales_Tax_Item__c> nameToSalesTaxMap;
    public Map<String, Integer> salesTaxNameToRecordCountMap = new Map<String, Integer>();

    global PopulateIndividualTaxSalesTaxBatch(){
        List<Sales_Tax_Item__c> salestaxList = [Select Name__c from Sales_Tax_Item__c Where Active__c = true];
        this.nameToSalesTaxMap = new Map<String, Sales_Tax_Item__c>();
        for(Sales_Tax_Item__c taxRec : salestaxList){
            nameToSalesTaxMap.put(taxRec.Name__c, taxRec);
        }
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        Set<String> salesTaxNameSet = this.salesTaxNameToRecordCountMap.keySet();
        String strQuery = 'Select Sales_Tax_Item_Name__c, Sales_Tax_Item__c from Individual_Tax__c where Sales_Tax_Item__c = null ';
        return Database.getQueryLocator(strQuery); 
    }
      
    global void execute(Database.batchableContext bc, List<Individual_Tax__c> invTaxList) {
        for(Individual_Tax__c taxRec : invTaxList){
            if(nameToSalesTaxMap.containsKey(taxRec.Sales_Tax_Item_Name__c)) {
                taxRec.Sales_Tax_Item__c = nameToSalesTaxMap.get(taxRec.Sales_Tax_Item_Name__c).id;
            } else {
                if(!this.salesTaxNameToRecordCountMap.containsKey(taxRec.Sales_Tax_Item_Name__c)) {
                    this.salesTaxNameToRecordCountMap.put(taxRec.Sales_Tax_Item_Name__c, 0);
                }
                this.salesTaxNameToRecordCountMap.put(taxRec.Sales_Tax_Item_Name__c, this.salesTaxNameToRecordCountMap.get(taxRec.Sales_Tax_Item_Name__c) + 1);
            }
        }
        update invTaxList;  
    }
      
    global void finish(Database.batchableContext bc) {
        if(this.salesTaxNameToRecordCountMap.keySet().size() > 0) {
            sendNotificationToAdmin(this.salesTaxNameToRecordCountMap);
        }
    }

    private static void sendNotificationToAdmin(Map<String, Integer> salesTaxNameToRecordCountMap) {
        String htmlBody = getEmailTemplateBody(salesTaxNameToRecordCountMap);
        String subject = UserInfo.getOrganizationName() +' - Sales Tax Populate Script Results';
        sendMail(subject, htmlBody);
    }

    private static void sendMail(String subject, String htmlBody) {
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        
        mail.setToAddresses(new List<String>{'blackpurl@metacube.com'});
        if(String.isNotBlank(Configurations__c.getOrgDefaults().Sent_From_Email_Id__c)){
            mail.setReplyTo(Configurations__c.getOrgDefaults().Sent_From_Email_Id__c);
        }
        mail.setSenderDisplayName('BlackPurl Team');
        mail.setSubject(subject);
        mail.setHtmlBody(htmlBody);
        mails.add(mail);
        if(!Test.isRunningTest()){
            Messaging.sendEmail(mails);
        }
    }

    private static String getEmailTemplateBody(Map<String, Integer> salesTaxNameToRecordCountMap){
        String htmlBody = '';
        htmlBody += '<span> Hi Support Team, </span>';
        htmlBody += '<p>Following records Sales Tax not get populated. Org Details are as follows - </p>';
        htmlBody += '<table >';
        htmlBody +=	  '<tr >';
        htmlBody +=	    '<td >Company Name - </td>';
        htmlBody +=	    '<td >' + UserInfo.getOrganizationName() + '</td>';
        htmlBody +=	  '</tr>';
        htmlBody +=	  '<tr >';
        htmlBody +=	    '<td>Org Id - </td>';
        htmlBody +=	    '<td>' + UserInfo.getOrganizationId() + '</td>';
        htmlBody +=	  '</tr>';
        htmlBody +=	 '</table>';
        htmlBody += '<p style="font-weight: bold;"> Information :</p>';
        htmlBody += '<table style="width:400px ;border-collapse: collapse;" >';
        htmlBody += '<tr>';
        htmlBody +=	    '<td style="border : 1px solid;font-weight: bold;">Sales Tax Item Name </td>';
        htmlBody +=	    '<td style="border : 1px solid;font-weight: bold;">Number of Individual Records ';
        htmlBody += '</tr>';	
        List<String> entityList = new List<String>(salesTaxNameToRecordCountMap.keySet()); 
        entityList.sort();
        for(String entity : entityList) {
            if(salesTaxNameToRecordCountMap.get(entity) > 0) {
                htmlBody +=      '<tr >';
                htmlBody +=     '<td style="border : 1px solid;">'+ entity + '</td>';
                htmlBody +=     '<td style="border : 1px solid; ">';
                htmlBody +=     (salesTaxNameToRecordCountMap.get(entity)) ;
                htmlBody +=     '</td>';
                htmlBody +=   '</tr>';
            }
        }
        htmlBody +=	 '</table>';
        htmlBody += '<p style="margin-top: 20px;margin-bottom:5px;">From</p>';
        htmlBody += '<p style="margin:0px;">Blackpurl Admin</p>';
        return htmlBody;
    }
}