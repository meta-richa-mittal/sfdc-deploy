global  with sharing class AutoCompleteCtrl_Ankit {
    public static Map<String,Map<String,List<SearchObjectWrapper>>> objectLabelToSearchObjectWrapperMap = new Map<String,Map<String,List<SearchObjectWrapper>>>
    {
    	'Customer'=> new Map<String, List<SearchObjectWrapper>>{ 'Account' => new List<SearchObjectWrapper>{
    																					new SearchObjectWrapper('Name',1),
    																					new SearchObjectWrapper('FirstName__c',2),
    																					new SearchObjectWrapper('LastName__c',3),
    																					new SearchObjectWrapper('Preferred_Email__c',4),
    																					new SearchObjectWrapper('Preferred_Phone__c',5)
    																					}
    															},						
    	'Vendor'=> new Map<String, List<SearchObjectWrapper>>{ 'Account' => new List<SearchObjectWrapper>{
    																					new SearchObjectWrapper('Name',1)
    																					}
    																					
															}
    };
    @RemoteAction
    global static String getSearchResults(String JSONString) {
    	JSONString = BPUtility.getDecodedString(JSONString); 
        QueryJSON searchQueryJSON = parseQuery(JSONString);	
        String resultStr = getSearchResult(searchQueryJSON);
    	return BPUtility.getEncodedString(resultStr);
    }
    public static QueryJSON parseQuery(String jsonString) {
        return (QueryJSON) System.JSON.deserialize(jsonString, QueryJSON.class);
    }    
    public static String getSearchResult(QueryJSON searchQueryJSON) {
    	//system.assert(false, searchQueryJSON);
    	String textToSearch = String.escapeSingleQuotes(searchQueryJSON.SearchText.toLowerCase());
    	String objectLabel = String.escapeSingleQuotes(searchQueryJSON.ObjectLabel);
    	Set<String> objectApiNametoQuery = objectLabelToSearchObjectWrapperMap.get(objectLabel).keySet();
    	String soqlQuery='Select ';
    	String fieldvaluescommaSeparated = '';
    	String defaultwhereClause = ''; 
    	for(String objName : objectApiNametoQuery){
    		List<SearchObjectWrapper> searchObjectWrapperList  = objectLabelToSearchObjectWrapperMap.get(objectLabel).get(objName);
    		searchObjectWrapperList.sort();
    		for(SearchObjectWrapper searchObjectWrapperRec : searchObjectWrapperList){
    			soqlQuery+= searchObjectWrapperRec.FieldApiName + ',';
    			fieldvaluescommaSeparated += searchObjectWrapperRec.FieldApiName + ',';
    		}
    		soqlQuery = soqlQuery.substring(0,soqlQuery.length() - 1);
    		soqlQuery += ' from ' +  objName;
    		soqlQuery +=  ' where ' ;
    		for(SearchObjectWrapper searchObjectWrapperRec : searchObjectWrapperList){
    			soqlQuery +=  searchObjectWrapperRec.FieldApiName  +  ' like %' + textToSearch + '% OR ';
    		}
    		
    		soqlQuery = soqlQuery.substring(0,soqlQuery.length() - 3);
    		if(objectLabel == 'Customer'){
    			defaultwhereClause = ' and Is_Customer__c = true';
    		}
    		else
    		if(objectLabel == 'Vendor'){
    			defaultwhereClause = ' and Is_Vendor__c = true';
    		}
    		soqlQuery += defaultwhereClause;
    		soqlQuery += ' Order by ' + fieldvaluescommaSeparated;
    		soqlQuery = soqlQuery.substring(0,soqlQuery.length() - 1);
    		soqlQuery += ' Limit ' + Limits.getLimitQueryRows();
    	}
    	List<Sobject> sobjectList = Database.query(soqlQuery);
    	List<Sobject> searchResultList = new List<Sobject>();
    	/*for(Sobject sobjRec : sobjectList){
    		searchObjectWrapperList.sort();
    		for(SearchObjectWrapper searchObjectWrapperRec : searchObjectWrapperList){
    			if(String.valueOf(sobjRec.get(searchObjectWrapperRec.FieldApiName)).contains(textToSearch)){
    				searchResultList.add(sobjRec);
    			}
    		}
    	}
    	*/
    	
    	String searchResultJson = Json.serialize(searchResultList);
    	return searchResultJson;
    }
    
    public class SearchObjectWrapper implements Comparable{
    	String FieldApiName;
    	Integer priority;
    	public SearchObjectWrapper(String FieldApiName,Integer priority){
    		this.FieldApiName = FieldApiName;
    		this.priority = priority;
    	}
    	public Integer compareTo(Object compareTo) {
	    	SearchObjectWrapper compareToWrapperObj = ((SearchObjectWrapper)compareTo);
	    	Integer returnValue = 0;
	    	if(priority == compareToWrapperObj.priority) return 0;
	        if(priority > compareToWrapperObj.priority) return 1;
	        return -1; 
    	}
    }
     public class QueryJSON {
        public String ObjectLabel {get; set;}
        public String SearchText {get; set;}
        public String SearchFieldName {get; set;}
    }
    	
}