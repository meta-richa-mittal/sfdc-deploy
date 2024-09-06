@RestResource(urlMapping = '/CreateAccount/*')
global without sharing class RestTesting {
    @HttpPost
    global static String doPost() {
        String accString = RestContext.request.requestBody.toString();
        AccWrapper accObj = (AccWrapper)System.JSON.deserialize(accString, AccWrapper.class);
        
        Account accRec = new Account(Name = accObj.name);
        insert accRec;
        
        return accRec.Id;
    }
    
    
    public class AccWrapper {
        public String name; 
    }
}