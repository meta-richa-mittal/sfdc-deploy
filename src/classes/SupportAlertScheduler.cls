/**
 * Author: Richa Mittal
 * Since: May 31, 2024
 * Name: SupportAlertScheduler
 * Description: scheduler class for notifying any alert to support.
**/
global without sharing class SupportAlertScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        validatePartFields();
    }

    private static void validatePartFields() {
        Database.executeBatch(new PartFieldsRecalculationBatch(true));
    }

    public static String getRecipientEmail() {
        return GeneralConfiguration.getConfigurationByName(GeneralConfiguration.ACCOUNTING_RECONCILIATION_EMAIL);
    }
}