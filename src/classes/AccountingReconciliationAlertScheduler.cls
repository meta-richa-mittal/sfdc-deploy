/**
 * Author: Nidhi Sharma
 * Since: May 02, 2022
 * Name: AccountingReconciliationAlertScheduler
 * Description: Accounting daily reconciliation notification scheduler class.
**/
global class AccountingReconciliationAlertScheduler implements Schedulable {

    private static String companyName = getCompanyName();
    private static Organization orgDetail = getOrgDetails();

    global void execute(SchedulableContext SC) {
        if(IntegrationServiceFactory.getActiveAccountingIntegrationName() != null) {
            checkForVarianceAndSendEmail();
        }
    }

    public static void checkForVarianceAndSendEmail() {
        if(String.isNotBlank(AccountingUtil.activeAccIntegrationName)) {
            List<Accounting_Reconciliation__c> accReconcilicationList = getAccReconcilicationList();
            if(!accReconcilicationList.isEmpty()) {
                SendEmail.sendSupportMailWithAttachment(SupportAlertScheduler.getRecipientEmail().split(';'),'Org Reconciliation - '+ companyName , getEmailBody(accReconcilicationList), null);
            }
        }
    }

    private static List<Accounting_Reconciliation__c> getAccReconcilicationList() {
        return (List<Accounting_Reconciliation__c>)SOQLUtility.getQueryResults('Accounting_Reconciliation__c', 'SELECT Id, Name, Reconciliation_Date__c, Type__c, GL_Account_ID__c, GL_Account_Number__c, Number_of_BP_records__c, Blackpurl_Balance__c, GL_Balance__c, Variance__c, Parts_Instock_Qty__c, Parts_Instock_Cost__c, Parts_Oversold_Qty__c, Parts_Oversold_Cost__c, Units_Instock_Cost__c, Units_Deal_Options_WIP__c, WIP_Hours_Logged__c, AP_Inventory_VR_Stocked__c, AP_Inventory_Return_Approved__c, GL_Account_Name__c, CreatedDate, Variance_Change__c FROM Accounting_Reconciliation__c WHERE Reconciliation_Date__c = Today AND Variance_Change__c != 0 Order By CreatedDate DESC');
    }
    
    private static String getCompanyName() {
        String companyName = '';
   	 	List<Business_Profile__c> businessOrgDetails = SOQLUtility.getQueryResults('Business_Profile__c', 'Select Id, Business_Name__c From Business_Profile__c LIMIT 1'); 
        if(!businessOrgDetails.isEmpty()){
        	companyName = businessOrgDetails[0].Business_Name__c;
        } else {
            companyName = orgDetail.Name;
        }
        return companyName;
    }

    private static Organization getOrgDetails() {
        return ((List<Organization>) SOQLUtility.getQueryResults('Organization', 'Select Id, Name  From Organization LIMIT 1'))[0];
    }

    private static String getEmailBody(List<Accounting_Reconciliation__c> accReconcilicationList) {
        String htmlBodyString = '<p>Company Name: ' + companyName + '<br/>Org ID: ' + orgDetail.Id + '</p>';
        htmlBodyString += '<h3>The variance for the following reconcilications has changed - </h3>';
        htmlBodyString += '<table border= \'1px solid black;\' style=\' border-collapse: collapse;\' >';
        htmlBodyString += '<tr> ';
        htmlBodyString += '<th style =\' text-align: center;padding-left:5px;padding-right:5px;\'> Date </th> ';
        htmlBodyString += '<th style =\' text-align: center;padding-left:5px;padding-right:5px;\'> Reconciliation Type </th> ';
        htmlBodyString += '<th style =\' text-align: center;padding-left:5px;padding-right:5px;\'> GL Account Name </th> ';
        htmlBodyString += '<th style =\' text-align: center;padding-left:5px;padding-right:5px;\'> Blackpurl Balance </th> ';
        htmlBodyString += '<th style =\' text-align: center;padding-left:5px;padding-right:5px;\'> GL Balance </th> ';
        htmlBodyString += '<th style =\' text-align: center;padding-left:5px;padding-right:5px;\'> Variance </th> ';
        htmlBodyString += '<th style =\' text-align: center;padding-left:5px;padding-right:5px;\'> Variance Change </th> ';
        htmlBodyString += '</tr>';
        for(Accounting_Reconciliation__c accReconcilicationRec : accReconcilicationList) {
            if(accReconcilicationRec.Variance_Change__c != null && accReconcilicationRec.Variance_Change__c != 0) {
                htmlBodyString += '<tr> ';
                htmlBodyString += '<td style =\' text-align: center;padding-left:5px;padding-right:5px;\'>' + Date.valueOf(accReconcilicationRec.Reconciliation_Date__c).format() + '</td>';
                htmlBodyString += '<td style =\' text-align: center;padding-left:5px;padding-right:5px;\'>' + accReconcilicationRec.Type__c + '</td>';
                htmlBodyString += '<td style =\' text-align: center;padding-left:5px;padding-right:5px;\'>' + (String.isNotBlank(accReconcilicationRec.GL_Account_Name__c) ? accReconcilicationRec.GL_Account_Name__c : '') + '</td>';
                htmlBodyString += '<td style =\' text-align: center;padding-left:5px;padding-right:5px;\'>' + getFormattedValueForCurrency(accReconcilicationRec.Blackpurl_Balance__c) + '</td>';
                htmlBodyString += '<td style =\' text-align: center;padding-left:5px;padding-right:5px;\'>' + getFormattedValueForCurrency(accReconcilicationRec.GL_Balance__c) + '</td>';
                htmlBodyString += '<td style =\' text-align: center;padding-left:5px;padding-right:5px;\'>' + getFormattedValueForCurrency(accReconcilicationRec.Variance__c) + '</td>';
                htmlBodyString += '<td style =\' text-align: center;padding-left:5px;padding-right:5px;\'>' + getFormattedValueForCurrency(accReconcilicationRec.Variance_Change__c) + '</td>';
                htmlBodyString += '</tr>';
            }
        }
        htmlBodyString += '</table>';
        htmlBodyString += '<br/><br/>';
        htmlBodyString += 'Team Blackpurl';
        return htmlBodyString;
    }

    private static String getFormattedValueForCurrency(Decimal currValue) {
        currValue = currValue != null ? currValue : 0;
        String formattedDecimalValue = BPUtility.formatToDecimal(currValue);
        return (String.isNotBlank(formattedDecimalValue) ? ('$' + formattedDecimalValue) : '');
    }
}