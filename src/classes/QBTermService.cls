/**
 * Author: Tarun Khandelwal
 * Since: Sept. 3, 2019
 * Name: QBTermService
 * Description: Service Class for syncing QB Terms used for Vendor Invoice Due date
**/
public without sharing class QBTermService {

    public static List<QB_Term__c> pullTerms(IFW_IntegrationConfig__c integrationConfigRec) {
        List<QB_Term__c> qbTermList = new List<QB_Term__c>();
        try {
            QBQueryResponseWrapper.QBResponseWrapper resObj;
            if(integrationConfigRec == null) {
                resObj = QBCalloutManager.getDataAndUpdateRecords('Term', getQBTermQuery(), null);
            } else {
                resObj = QBCalloutManager.getData('Term', getQBTermQuery(), integrationConfigRec);
            }
            if(resObj != null && resObj.Term != null) {
                for(QBTerm qbTermObj : resObj.Term) {
                    qbTermList.add(mapFields(qbTermObj));
                }
            }
        } catch(Exception e) {
            // just need to catch the error so that records already created/updated in QBCalloutManager are saved
        }

        if(qbTermList.size() > 0 && integrationConfigRec == null) {
            deleteExistingTermsInBP();
            if(!AccessControl.ifObjectFieldIsCreateable('QB_Term__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_CREATEABLE); }
            insert qbTermList;
        }
        return qbTermList;
    }
    
    public static void deleteExistingTermsInBP() {
        if(!AccessControl.ifObjectIsDeletable('QB_Term__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
        delete [SELECT Id FROM QB_Term__c WHERE Name != null];
    }
    
    private static String getQBTermQuery() {
        String query = 'select Id, Name, Active, DueDays, DayOfMonthDue, DueNextMonthDays from Term';
        query = EncodingUtil.urlEncode(query, 'UTF-8').replaceAll('\\+','%20');
        return query;
    }
    
    private static QB_Term__c mapFields(QBTerm qbTermObj) {
        QB_Term__c termRec = new QB_Term__c(Name = qbTermObj.Name);
        termRec.Active__c = qbTermObj.Active;
        termRec.Type__c = qbTermObj.Type;
        termRec.Accounting_Id__c = qbTermObj.Id;
        termRec.Due_Days__c = qbTermObj.DueDays;
        termRec.Day_of_Month_Due__c = qbTermObj.DayOfMonthDue;
        termRec.Due_Next_Month_Days__c = qbTermObj.DueNextMonthDays;
        return termRec;
    }
    
    public class QBTerm {
        public String Name;
        public Boolean Active;
        public String Type;
        public String Id;
        public Integer DueDays;
        public Integer DayOfMonthDue;
        public Integer DueNextMonthDays;
    }
}