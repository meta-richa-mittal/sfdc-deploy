public without sharing class UniversalAPIUtility {
    
    public final static String UNIVERSAL_API = 'Universal API';
    public final static String featureToggleName = 'Use Kenect For Text SMS';
    public final static String CONNECTION = 'Connection';
    public final static String errorMessage = 'Error occurred while sending SMS.';
    public final static String connectionError = 'Something went wrong, please try again later.';
    public static String messageUUID = '';
    public static String webhookURL = Label.webhookURL + '/' + UserInfo.getOrganizationId().substring(0, 15) + '?' + BPUtility.getEncodedString('nameSpace') + '=' + BPUtility.getEncodedString(GeneralConfiguration.getNamespace() == null ? '' : (GeneralConfiguration.getNamespace()).replace('__', ''));
    public final static String JWT_TOKEN = 'JWT Token';
    public final static String UNIVERSAL_INTERNAL = 'Universal Internal';
    	
    public static Map<String,String> getEntityNameToURLMap() {
        Map<String, String> entityNameToURLMap = new Map<String, String>();

        String nameSpace = GeneralConfiguration.getPackageNamespace();
        if(nameSpace == 'BlackPurlCore') {
            entityNameToURLMap.put('Connection', 'https://api.blackpurl.com/graphql');
            entityNameToURLMap.put('JWT Token', 'https://ms-auth-api-zu6w3drdfa-uc.a.run.app/api/auth/token/generate');
            entityNameToURLMap.put('Universal Internal', 'https://api-internal.blackpurl.com/graphql');
        } else if(nameSpace == 'BPUAT') {
            entityNameToURLMap.put('Connection', 'https://ms-universal-api-5niqfavtya-uc.a.run.app/graphql');
            entityNameToURLMap.put('JWT Token', 'https://ms-auth-api-5niqfavtya-uc.a.run.app/api/auth/token/generate');
            entityNameToURLMap.put('Universal Internal', 'https://api-internal-uat.blackpurl.com/graphql');
        } else {
            entityNameToURLMap.put('Connection', 'https://api-gql-test.blackpurl.com/graphql');
            entityNameToURLMap.put('JWT Token', 'https://ms-auth-api-fqhcp4gmhq-uc.a.run.app/api/auth/token/generate');
            entityNameToURLMap.put('Universal Internal', 'https://api-internal-dev.blackpurl.com/graphql');
        }
        return entityNameToURLMap;
    }
}