public without sharing class AbbreviationsUtil {

    public static Map<String,String> getStateAbbreviationToStateMap(){
        Map<String,String> stateAbbrToStateMap = new Map<String,String>();
        for(State_Abbreviation__mdt stateAbbrRec: State_Abbreviation__mdt.getAll().values()) {
            stateAbbrToStateMap.put(stateAbbrRec.Country__c + '^&&^' + stateAbbrRec.Abbreviation__c , stateAbbrRec.State__c);
        }
        return stateAbbrToStateMap;
    }

    public static String getStateNameByAbbreviations(String country, String abbrevaition){
        if(String.isBlank(country)) { return abbrevaition;}
        List<State_Abbreviation__mdt> stateAbbreviationList = [Select Id, State__c From State_Abbreviation__mdt where Country__c =: country And Abbreviation__c =: abbrevaition Limit 1]; 
        if(stateAbbreviationList.size() != 0){
            return stateAbbreviationList[0].State__c;
        } else {
            return abbrevaition;
        }
    }

    public static String getStateAbbreviationsByName(String country, String stateFullName){
        if(String.isBlank(country)) { return stateFullName;}
        List<State_Abbreviation__mdt> stateAbbreviationList = [Select Id, Abbreviation__c From State_Abbreviation__mdt where Country__c =: country And State__c =: stateFullName Limit 1]; 
        if(stateAbbreviationList.size() != 0) {
            return stateAbbreviationList[0].Abbreviation__c;
        } else {
            return stateFullName;
        }
    }
}