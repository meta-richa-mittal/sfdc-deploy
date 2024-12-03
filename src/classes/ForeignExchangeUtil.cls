/**
 * Author: Manoj Sharma
 * Since: Sept. 22, 2022
 * Name: ForeignExchangeUtil
 * Description: Util class which holds common and general methods used for foreign exchange
**/
public without sharing class ForeignExchangeUtil {
    public final static String integrationName = 'XE';
    public final static String integrationEntityName = 'Historic Rate';
    public static String HOME_CURRENCY;
    public static List<Country__c> countryListToUpdate;
    public static String xeAPIId = 'blackpurl351544008';
    public static String xeAPIkey = '86lhqcko0hopk4tigcue5irvb4';

    public static CurrencyWrapper getHomeCurrencyDetails() {
        if(String.isBlank(HOME_CURRENCY)) {
            HOME_CURRENCY = QuickBooks_Configurations__c.getOrgDefaults().Home_Currency__c;
        }
        List<Country__c> countriesList = SOQLUtil.getCountryByFilter(Country.fieldsList(), new Map<String, object>{'Currency_Code__c'=> HOME_CURRENCY});
        return (countriesList.isEmpty() ? new CurrencyWrapper() : new CurrencyWrapper(countriesList[0]));
    }
    
    public static List<CurrencyWrapper> getActiveForeignCurrencyList() {
        List<Country__c> countriesList = SOQLUtil.getCountryByFilter(Country.fieldsList(), new Map<String, object>{'Active__c'=> true});
        List<CurrencyWrapper> currencyDetailList = new List<CurrencyWrapper>();
        for(Country__c countryRec : countriesList) {
            CurrencyWrapper currencyDetailObj = new CurrencyWrapper(countryRec);
            currencyDetailList.add(currencyDetailObj);
        }
        CurrencyWrapper homeCurrencyDetailObj = getHomeCurrencyDetails();
        if(homeCurrencyDetailObj != null && String.isNotBlank(homeCurrencyDetailObj.CurrencyCode)) {
            homeCurrencyDetailObj.IsHomeCurrency = true;
            currencyDetailList.add(homeCurrencyDetailObj);
        }
        return currencyDetailList;
    }

    public static String getFormattedCurrencyCode(Country__c countryRec) {
        return (String.isNotBlank(countryRec.Currency_Code__c) && String.isNotBlank(countryRec.Name__c) && String.isNotBlank(countryRec.Currency_Name__c)) ? (countryRec.Currency_Code__c + ' - ' + countryRec.Name__c + ' ' + countryRec.Currency_Name__c) : '';
    }

    public static FXDetailWrapper getForeignExchangeDetail() {
        CurrencyWrapper homeCurrency = getHomeCurrencyDetails();
        List<CurrencyWrapper> foreignCurrencyList = getForeignCurrencyList(homeCurrency);
        Decimal exchangeRateMarkupValue = GeneralConfiguration.getConfigurations().Exchange_Rate_Markup__c;
        exchangeRateMarkupValue = exchangeRateMarkupValue != null ? exchangeRateMarkupValue : 0.00;
        Boolean isExchangeRateMarkupEnabled = GeneralConfiguration.getConfigurations().Is_Exchange_Rate_Markup_Enable__c;
        return new FXDetailWrapper(homeCurrency, foreignCurrencyList, exchangeRateMarkupValue, isExchangeRateMarkupEnabled);
    }

    public static List<CurrencyWrapper> getForeignCurrencyList(CurrencyWrapper homeCurrency) {
        List<CurrencyWrapper> foreignCurrencyList;
        if(QBUtil.isQBEnabled()) {
            foreignCurrencyList = AccountingUtil.getActiveCurrenciesFromQB(homeCurrency);
        } else if(XeroUtility.isXeroEnabled()) {
            foreignCurrencyList = AccountingUtil.getActiveCurrenciesFromXERO(homeCurrency);
        } else {
            foreignCurrencyList = getActiveForeignCurrencyList();
        }
        return foreignCurrencyList;
    }

    public static Decimal getConvertedAmountInLocalCurrency(Decimal amount, Decimal conversionRateWithMarkup) {
        amount = amount != null ? amount : 0;
        conversionRateWithMarkup = conversionRateWithMarkup != null && conversionRateWithMarkup != 0 ? conversionRateWithMarkup : 1;
        return getConvertedAmountInLocalCurrencyNotRounded(amount, conversionRateWithMarkup).setScale(2, RoundingMode.HALF_UP);
    }

    public static Decimal getConvertedAmountInLocalCurrencyNotRounded(Decimal amount, Decimal conversionRateWithMarkup) {
        amount = amount != null ? amount : 0;
        conversionRateWithMarkup = conversionRateWithMarkup != null && conversionRateWithMarkup != 0 ? conversionRateWithMarkup : 1;
        if(XeroUtility.isXeroEnabled()) {
            return (amount / (1/conversionRateWithMarkup).setScale(6, RoundingMode.HALF_UP));
        }
        return (amount * conversionRateWithMarkup);
    }

    public static Decimal getConvertedAmountInForeignCurrency(Decimal amount, Decimal conversionRateWithMarkup) {
        amount = amount != null ? amount : 0;
        conversionRateWithMarkup = conversionRateWithMarkup != null && conversionRateWithMarkup != 0 ? conversionRateWithMarkup : 1;
        return (amount / conversionRateWithMarkup).setScale(2, RoundingMode.HALF_UP);
    }

    public static String getVendorCurrencyCode(Account vendorRec) {
        String currencyCode;
        if(AccountingUtil.isMultiCurrencyEnabled()) {
            if(vendorRec != null && vendorRec.Is_Foreign_Vendor__c && vendorRec.Country__c != null) {
                currencyCode = vendorRec.Country__r.Currency_Code__c;
            } else {
                currencyCode = AccountingUtil.getHomeCurrency();
            }
        }
        return currencyCode;
    }

    public static Decimal getConversionRateWithMarkupByVendorId(String vendorId) {
        Decimal conversionRateWithMarkup;
        Boolean isForeignVendor = false;
        for(Account vendorRec : [Select Id, Is_Foreign_Vendor__c, Country__r.Conversion_Rate_With_Markup__c From Account Where Id =: vendorId AND Is_Foreign_Vendor__c = true AND Country__c != null]) {
            isForeignVendor = vendorRec.Is_Foreign_Vendor__c;
            conversionRateWithMarkup = vendorRec.Country__r.Conversion_Rate_With_Markup__c;
        }
        if(!isForeignVendor) return null;
        else return (conversionRateWithMarkup != null && conversionRateWithMarkup != 0) ? conversionRateWithMarkup : 1;
    }

    public static Map<Id, Decimal> getConversionRateWithMarkupByVendorIds(Set<Id> vendorIds) {
        Map<Id, Decimal> vendorIdToConversionRateWithMarkup = new Map<Id, Decimal>();
        if(vendorIds != null && !vendorIds.isEmpty()) {
            for(Account vendorRec : [Select Id, Is_Foreign_Vendor__c, Country__r.Conversion_Rate_With_Markup__c From Account Where Id IN: vendorIds AND Is_Foreign_Vendor__c = true AND Country__c != null]) {
                vendorIdToConversionRateWithMarkup.put(vendorRec.Id, vendorRec.Country__r.Conversion_Rate_With_Markup__c);
            }
        }
        return vendorIdToConversionRateWithMarkup;
    }

    public static Boolean isForeignVendor(String vendorId) {
        return ([SELECT Id FROM Account WHERE Id =: vendorId AND Is_Foreign_Vendor__c = true LIMIT 1].size() > 0);
    }

    public static FXDetailWrapper updateConversionRate(FXDetailWrapper FXDetailWrapper) {
        Map<Id, Decimal> countryToConversionRateMap = new Map<Id, Decimal>();
        for(Country__c countryRec : countryListToUpdate) {
            countryToConversionRateMap.put(countryRec.Id, countryRec.Conversion_Rate__c);
        }
        for(CurrencyWrapper foreignCurrencyRec : FXDetailWrapper.ForeignCurrencyList) {
            if(countryToConversionRateMap.get(foreignCurrencyRec.Id) != null) {
                foreignCurrencyRec.ConversionRate = countryToConversionRateMap.get(foreignCurrencyRec.Id);
            }
        }
        return FXDetailWrapper;
    } 

    public static void createIFWConfigAndConfigItemsForXE() {
        List<IFW_IntegrationConfig__c> ifwConfigList  = IFW_SOQLUtil.getIntegrationConfig(new Map<String, Object>{'Integration_Name__c' => ForeignExchangeUtil.integrationName});
        if(!ifwConfigList.isEmpty()) return;
        String integrationBaseURL = 'https://xecdapi.xe.com/v1/historic_rate.json';
        IFW_IntegrationConfig__c ifwConfig = IntegrationServiceFactory.createIFWConfig(false, integrationName,'Basic', null, null, null, 
                                                                                            xeAPIId, xeAPIkey);
        DMLUtility.insertSobjectList('IFW_IntegrationConfig__c', ifwConfig);

        IFW_IntegrationConfigItem__c ifwConfigItem = IntegrationServiceFactory.createIFWConfigItem(ifwConfig.Id, integrationEntityName,
                                                                                                    integrationBaseURL, 'GET');
        DMLUtility.insertSobjectList('IFW_IntegrationConfigItem__c', ifwConfigItem);
    } 

    public class CurrencyWrapper {
        public String Id;
        public String CurrencyCode;
        public String CurrencyName;
        public String CountryName;
        public String Flag;
        public String Symbol;
        public String FormattedFXCurrencyCode;
        public Boolean IsHomeCurrency;
        public Boolean Active;
        public Decimal ConversionRate;
        public Decimal ConversionRateWithMarkup;

        public CurrencyWrapper(){}

        public CurrencyWrapper(Country__c countryRec) {
            this.Id = countryRec.Id;
            this.CurrencyCode = countryRec.Currency_Code__c;
            this.CurrencyName = countryRec.Currency_Name__c;
            this.CountryName = countryRec.Name__c;
            this.Flag = countryRec.Flag_Encoded__c	;
            this.Symbol = countryRec.Currency_Symbol__c;
            this.Active = countryRec.Active__c;
            this.ConversionRate = countryRec.Conversion_Rate__c;
            this.FormattedFXCurrencyCode = (String.isNotBlank(this.CurrencyCode) && String.isNotBlank(this.CountryName) && String.isNotBlank(this.CurrencyName)) ? (this.CurrencyCode + ' - ' + this.CountryName + ' ' + this.CurrencyName) : '';
        }

        public CurrencyWrapper(Country__c countryRec, Boolean showBanner) {
            if(showBanner != null && showBanner) {
                this.FormattedFXCurrencyCode = countryRec.Formatted_FX_Currency_Code__c;
                this.ConversionRateWithMarkup = XeroUtility.isXeroEnabled() ? countryRec.Backward_Conversion_Rate__c : countryRec.Conversion_Rate_With_Markup__c;
            }
            this.CurrencyCode = countryRec.Currency_Code__c;
        }
    }

    public class FXDetailWrapper {
        public CurrencyWrapper HomeCurrency;
        public List<CurrencyWrapper> ForeignCurrencyList;
        public Decimal ExchangeRateMarkupValue; 
        public Boolean IsExchangeRateMarkupEnabled;
        
        public FXDetailWrapper(CurrencyWrapper homeCurrency, List<CurrencyWrapper> foreignCurrencyList, Decimal exchangeRateMarkupValue, Boolean isExchangeRateMarkupEnabled) {
            this.HomeCurrency = homeCurrency;
            this.ForeignCurrencyList = new List<CurrencyWrapper>();
            for(CurrencyWrapper foreignCurrency : foreignCurrencyList) {
                if(homeCurrency.Id != foreignCurrency.Id) {
                    this.ForeignCurrencyList.add(foreignCurrency);
                }
            }
            this.ExchangeRateMarkupValue = exchangeRateMarkupValue;
            this.IsExchangeRateMarkupEnabled = isExchangeRateMarkupEnabled;
        }
    }
}