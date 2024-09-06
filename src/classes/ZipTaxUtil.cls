public without sharing class ZipTaxUtil {
    public final static String ZIP_TAX = 'Zip Tax';
    public final static String FETCH_TAX = 'Fetch Tax';
    public final static String ZIP_TAX_ENCODED_API_KEY = 'TDZEVWVRNFRTRXl6OEZWUA==';
    public final static String STATE_TAX = 'State Tax';
    public final static String COUNTY_TAX = 'County Tax';
    public final static String CITY_TAX = 'City Tax';
    public final static String DISTRICT_1_TAX = 'District 1 Tax';
    public final static String DISTRICT_2_TAX = 'District 2 Tax';
    public final static String DISTRICT_3_TAX = 'District 3 Tax';
    public final static String DISTRICT_4_TAX = 'District 4 Tax';
    public final static String DISTRICT_5_TAX = 'District 5 Tax';
    public final static String DISTRICT_TAX_PREFIX = 'District';
    public final static String DISTRICT_TAX = 'District Tax';

    public static void createZipTaxIfwAndItem() {
        List<IFW_IntegrationConfig__c> configList = IFW_SOQLUtil.getIntegrationConfig(new Map<String, Object>{'Integration_Name__c' => ZIP_TAX,
                                                                                                            'Accounting_Enabled__c' => true});

        if(!configList.isEmpty()) return;
        String integrationBaseURL = 'https://api.zip-tax.com/request/v40';
        IFW_IntegrationConfig__c ifwConfig = IntegrationServiceFactory.createIFWConfig(false, ZIP_TAX,'Basic', null, null, null);
        ifwConfig.Consumer_Key__c = BPUtility.getdecodedString(ZIP_TAX_ENCODED_API_KEY);
        DMLUtility.insertSobjectList('IFW_IntegrationConfig__c', ifwConfig);

        IFW_IntegrationConfigItem__c ifwConfigItem = IntegrationServiceFactory.createIFWConfigItem(ifwConfig.Id, FETCH_TAX,
                                                                                                    integrationBaseURL, 'GET');
        DMLUtility.insertSobjectList('IFW_IntegrationConfigItem__c', ifwConfigItem);
    }
}