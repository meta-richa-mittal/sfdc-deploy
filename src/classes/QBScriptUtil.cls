/**
 * Author: Tarun Khandelwal
 * Since: May 21, 2018
 * Name: QBScriptUtil
 * Description: Apex class for all scripts related to QB
**/
global class QBScriptUtil {
    global static void syncCustomers(Integer maxNumberOfRecord, Integer timeIntervalForJobsInSec, Integer batchSize) {}
    global static void syncVendors(Integer maxNumberOfRecord, Integer timeIntervalForJobsInSec, Integer batchSize) {}
    global static void syncCategory() {}
    global static void syncInvoices(Integer maxNumberOfRecord, Integer timeIntervalForJobsInSec, Integer batchSize) {}
    global static void updateInvoices(Integer maxNumberOfRecord, Integer timeIntervalForJobsInSec) {}
    global static void syncJournalEntryForInvoices(Integer maxNumberOfRecord, Integer timeIntervalForJobsInSec, Integer batchSize) {}
    global static void syncJournalEntryForUnitInvoices(Integer maxNumberOfRecord, Integer timeIntervalForJobsInSec, Integer batchSize) {}
    global static void syncVendorInvoices(Integer maxNumberOfRecord, Integer timeIntervalForJobsInSec, Integer batchSize) {}
    global static void syncUnits(Integer maxNumberOfRecord, Integer timeIntervalForJobsInSec, Integer batchSize) {}
    global static void syncVendorReturn(Integer maxNumberOfRecord, Integer timeIntervalForJobsInSec, Integer batchSize) {}
    global static void syncDeposits(Integer maxNumberOfRecord, Integer timeIntervalForJobsInSec, Integer batchSize) {}
    global static void syncUnitPriceAndCost(Integer maxNumberOfRecord, Integer timeIntervalForJobsInSec, Integer batchSize) {}
    global static void syncStoreCredits(Integer maxNumberOfRecord, Integer timeIntervalForJobsInSec, Integer batchSize) {}
    global static void syncCOInvoicePayments(Integer maxNumberOfRecord, Integer timeIntervalForJobsInSec, Integer batchSize) {}
    global static void syncFIFOBuckets(Integer maxNumberOfRecord, Integer timeIntervalForJobsInSec, Integer batchSize) {}
    global static void syncFIFOBucketLineItems(Integer maxNumberOfRecord, Integer timeIntervalForJobsInSec, Integer batchSize) {}
    global static void syncVRJE(Integer maxNumberOfRecord, Integer timeIntervalForJobsInSec, Integer batchSize) {}
    global static void resetSyncFlagForCOInvoiceNotPostedToQB() {}
    global static void resetSyncFlagForCOInvoiceJENotPostedToQB() {}
    global static void setSyncFlagForCOInvoicePaymentPostedToQB() {}
    global static void resetSyncFlagForCOInvoicePaymentJENotPostedToQB() {}
    global static void resetSyncFlagForVendorInvoiceNotPostedToQB() {}
    global static void resetSyncFlagForVendorReturnNotPostedToQB() {}
    global static void resetSyncFlagForStoreCreditJENotPostedToQB() {}
    global static void resetSyncFlagForVendorReceivingJENotPostedToQB() {}
    global static void resetSyncFlagForPartFIFOJENotPostedToQB() {}
    global static void resetSyncFlagForPartFIFOActivityLIJENotPostedToQB() {}
    global static void resetSyncFlagForUnitNotPostedToQB() {}
    global static void resetSyncFlagForUnitPriceAndCostNotPostedToQB() {}
    global static void syncHoursLogged(Integer maxNumberOfRecord, Integer timeIntervalForJobsInSec) {}
    global static void syncUnitNITCJE(Integer maxNumberOfRecord, Integer timeIntervalForJobsInSec) {}
    global static void syncConsignmentUnit(Integer maxNumberOfRecord, Integer timeIntervalForJobsInSec) {}
    global static void syncVIVarianceJE(Integer maxNumberOfRecord, Integer timeIntervalForJobsInSec) {}
    global static void syncRVOVarianceJE(Integer maxNumberOfRecord, Integer timeIntervalForJobsInSec) {}
}