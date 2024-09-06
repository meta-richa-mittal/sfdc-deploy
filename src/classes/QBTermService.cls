/**
 * Author: Tarun Khandelwal
 * Since: Sept. 3, 2019
 * Name: QBTermService
 * Description: Service Class for syncing QB Terms used for Vendor Invoice Due date
**/
public without sharing class QBTermService {
    
    public static void pullTerms() {
        List<QB_Term__c> qbTermList = new List<QB_Term__c>();
        //HttpResponse response = QuickbookConnector.getRequestFromQuickBooks('query?query=' + getQBTermQuery(), null);
        QuickbookConnector.ResponseWrapper resObj = QuickbookConnector.getRequestFromQB('query?query=' + getQBTermQuery(), null);
        HttpResponse response = resObj.Response;
        if(resObj.RefreshToken !=  null) {
			QBUtil.saveRefreshToken(resObj.RefreshToken, resObj.RefreshTokenExpiresIn);
		}
        if(response.getStatusCode() == 200) {
            QBTermResponseWrapper termObj = (QBTermResponseWrapper)System.JSON.deserialize(response.getBody(), QBTermResponseWrapper.class);
            if(termObj.QueryResponse != null && termObj.QueryResponse.Term != null) {
                for(QBTerm qbTermObj : termObj.QueryResponse.Term) {
                    qbTermList.add(mapFields(qbTermObj));
                }
            }
        } else {
            new LogService().createErrorLog('QBTermService', 'pullTerms()', response.getBody(), response.getStatusCode(), null, 
                                              null, LogService.QuickBooks, true);
        }
        if(qbTermList.size() > 0) {
            deleteExistingTermsInBP();
            if(!AccessControl.ifObjectFieldIsCreateable('QB_Term__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_CREATEABLE); }
            insert qbTermList;
        }
    }
    
    private static void deleteExistingTermsInBP() {
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
    
    public class QBTermResponseWrapper {
        public QueryResponseWrapper QueryResponse;
    }
    
    public class QueryResponseWrapper {
        public List<QBTerm> Term;
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