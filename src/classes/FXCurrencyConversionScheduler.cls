/**
 * Author: Balveer Choudhary
 * Since: Sept 26, 2022
 * Name: FXCurrencyConversionScheduler
 * Description: Scheduler class for get FX currency conversion rate from Xe.com
**/
global without sharing class FXCurrencyConversionScheduler implements Schedulable {
    
    global void execute(SchedulableContext sc) {
        getFXCurrencyConversionRate();
    }

    @future (callout=true)
    public static void getFXCurrencyConversionRate() {
        getConversionRateFromXE();
        
        // Update Conversion Rate on countries
        DMLUtility.updateSobjectList('Country__c', ForeignExchangeUtil.countryListToUpdate);

        // Create webservice log
        DMLUtility.insertSobjectList('WebService_Log__c', BaseIntegration.webServiceLogs);
    }

    public static void getConversionRateFromXE() {
        //Get Ifw congigs
        List<IFW_IntegrationConfig__c> ifwList = IFW_SOQLUtil.getIntegrationConfigWithItems(new Map<String, Object>{'Integration_Name__c' => ForeignExchangeUtil.integrationName});
        if(ifwList.isEmpty()) throw new BlackPurlException('IFW Config for Organization not defined');
        if(ifwList[0].IFW_IntegrationConfigItems__r.isEmpty()) throw new BlackPurlException('IFW Config for Organization not defined');

        // Get Home Currency
        String covertToCurrency;
        covertToCurrency = QuickBooks_Configurations__c.getOrgDefaults().Home_Currency__c;
        if(String.isBlank(covertToCurrency)) covertToCurrency = UserInfo.getDefaultCurrency();
        
        HttpResponse response;
        Map<String, String> params = new Map<String, String>();

        // Get call in loop 
        List<Country__c> countryList = [SELECT Currency_Code__c, Conversion_Rate__c FROM Country__c WHERE Currency_Code__c != null ORDER BY CreatedDate DESC];
        for(Country__c countryRec : countryList) {
            if(String.isNotBlank(countryRec.Currency_Code__c) && !covertToCurrency.equalsIgnoreCase(countryRec.Currency_Code__c)) {
                params = new Map<String, String>{'to' => covertToCurrency, 'from' => countryRec.Currency_Code__c, 'decimal_places' => '6'};
                response = BaseIntegration.performCallout(ifwList[0], ifwList[0].IFW_IntegrationConfigItems__r[0], null, new List<CustomHttpHeaderWrapper>(), params, ForeignExchangeUtil.integrationEntityName);        
                updateConversionRate(response, countryRec);
            }
        }
        ForeignExchangeUtil.countryListToUpdate = countryList;
    }

    private static void updateConversionRate(HttpResponse response, Country__c countryRec) {
        if(response.getStatusCode() == 200) {
            CurrencyConversionWrapper currencyConversionWrapperObj = (CurrencyConversionWrapper)System.JSON.deserialize(response.getBody(), CurrencyConversionWrapper.class);
            countryRec.Conversion_Rate__c = currencyConversionWrapperObj.to[0].mid;
        }
    }

    public class CurrencyConversionWrapper {
        public List<ConversionRateWrapper> to;
    }
    public class ConversionRateWrapper {
        public String quotecurrency;
        public Decimal mid; 
    }
}