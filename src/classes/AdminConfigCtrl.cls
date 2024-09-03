/**
 * Author: Nidhi Sharma
 * Since: June 16, 2022
 * Name: AdminConfigService
**/
global without sharing class AdminConfigCtrl {

    global AdminConfigCtrl (NewHomePageCtrl controller){}
    public AdminConfigCtrl() {}

    @RemoteAction
    global static String getPreferredPaymentConfig() {
        return BPUtility.getEncodedString(System.JSON.serialize(AdminConfigService.getPreferredPaymentConfig()));
    }
    
    @RemoteAction
    global static String getAllPPTerminalList() {
        return BPUtility.getEncodedString(System.JSON.serialize(PreferredPaymentIntegrationService.getAllTerminals()));
    }

    @RemoteAction
    global static void configurePreferredPaymentIntegration(String preferredPaymentConfigJsonStr) {
        AdminConfigService.configurePreferredPaymentIntegration(BPUtility.getDecodedString(preferredPaymentConfigJsonStr));
    }
    
    @RemoteAction
    public static String getGeneralInfoConfig() {
        return BPUtility.getEncodedString(System.JSON.serialize(AdminConfigService.getGeneralInfoConfig()));
    }

    @RemoteAction
    public static void setCompanyGeneralInfo(string companyGeneralInfoJsonStr) {
        AdminConfigService.setCompanyGeneralInfo(BPUtility.getDecodedString(companyGeneralInfoJsonStr));
    }
    
    @RemoteAction
    global static void enableConfiguration(String configJson) {
        AdminConfigService.toggleConfigurations(BPUtility.getDecodedString(configJson));
    }
    
    @RemoteAction
    global static String syncTerminalDetailsFromPP(String ppTerminalJson) {
        return BPUtility.getEncodedString(System.JSON.serialize(AdminConfigService.syncTerminalDetailsFromPP(BPUtility.getDecodedString(ppTerminalJson))));
    }
    
    @RemoteAction
    global static String savePPConfigChange(String preferredPaymentConfigJsonStr) {
        AdminConfigService.savePPConfigChange(BPUtility.getDecodedString(preferredPaymentConfigJsonStr));
        return BPUtility.getEncodedString('');
    }

    @RemoteAction
    global static String getBRPConfig() {
        return BPUtility.getEncodedString(System.JSON.serialize(AdminConfigService.getBRPConfig()));
    }

    @RemoteAction
    global static String configureBRPIntegration(String brpConfigJsonStr) {
        AdminConfigService.configureBRPIntegration(BPUtility.getDecodedString(brpConfigJsonStr));
        return BPUtility.getEncodedString('');
    }

    @RemoteAction
    global static String getAllUnitMakes() {
        return BPUtility.getEncodedString(MakeModelSubModelService.getAllUnitMakes());
    }

    @RemoteAction
    global static String saveBRPConfig(String brpConfigJsonStr) {
        AdminBRPConfigWrapper config = (AdminBRPConfigWrapper) System.JSON.deserialize(BPUtility.getDecodedString(brpConfigJsonStr), AdminBRPConfigWrapper.class);
        AdminConfigService.saveBRPConfig(config);
        return BPUtility.getEncodedString('');
    }

    @RemoteAction
    global static String disableBRPPartsOrder() {
        AdminConfigService.disableBRPPartsOrder();
        return BPUtility.getEncodedString('');
    }

    @RemoteAction
    global static String authorizeBRP() {
        return BPUtility.getEncodedString(new BRPAuthorizationService().authorizeBRP());
    }
    
    @RemoteAction
    global static String resetAllUsersTimeZone(String timeZone) {
        return BPUtility.getEncodedString(AdminConfigService.resetAllUsersTimezone(BPUtility.getDecodedString(timeZone)));
    }

    @RemoteAction
    global static String getAccountingReconciliationTabURL() {
        return BPUtility.getEncodedString(AdminConfigService.getAccountingReconciliationTabURL());
    }

    @RemoteAction
    global static String getAccountingReconciliationByDate(String selectedDateStr) {
        return BPUtility.getEncodedString(System.JSON.serialize(AdminConfigService.getAccountingReconciliationByDate(BPUtility.getDecodedString(selectedDateStr))));
    }

    @RemoteAction
    global static String getUnitDataFieldConfig() {
        return BPUtility.getEncodedString(System.JSON.serialize(AdminConfigService.getUnitDataFieldConfig(), true));
    }

    @RemoteAction
    global static void saveUnitDataFieldConfig(String unitDataFieldConfigJsonStr) {
        AdminConfigService.saveUnitDataFieldConfig(BPUtility.getDecodedString(unitDataFieldConfigJsonStr));
    }

    global static void removeIntegrationsConfig() {
        AdminConfigService.removeIntegrationsConfig();
    }

    @RemoteAction
    global static String getFeatureToggleConfig() {
        return BPUtility.getEncodedString(System.JSON.serialize(AdminConfigService.getFeatureToggleConfig(), true));
    }

    @RemoteAction
    global static void saveFeatureToggleConfig(String featureToggleConfigJsonStr) {
        AdminConfigService.saveFeatureToggleConfig(BPUtility.getDecodedString(featureToggleConfigJsonStr));
    }

    @RemoteAction
    global static String generateJWTToken() {
        return BPUtility.getEncodedString(UniversalAPIService.generateJWTToken());
    }

    @RemoteAction
    global static void saveKenectIntegration(String kenectJsonStr) {
        AdminConfigService.saveKenectIntegration(kenectJsonStr);
    }
    
	@RemoteAction
    global static String getKenectConfig() {
        return BPUtility.getEncodedString(System.JSON.serialize(AdminConfigService.getKenectConfig()));
    }
    
    @RemoteAction
    global static String getAccountingSyncFailureDetails(Boolean fetchData) {
        return BPUtility.getEncodedString(System.JSON.serialize(AdminConfigService.getAccountingSyncFailureDetails(fetchData)));
    }

    @RemoteAction
    global static String getAccountingLogsDetails() {
        return BPUtility.getEncodedString(System.JSON.serialize(AdminConfigService.getAccountingLogsDetails()));
    }

    @RemoteAction
    global static void executeAccountingScript(String entityName) {
        AdminConfigService.executeAccountingScript(BPUtility.getDecodedString(entityName));
    }
}