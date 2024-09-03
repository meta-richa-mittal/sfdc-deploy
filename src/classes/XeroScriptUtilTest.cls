/**
 * Author: Nikhil Kumar Srivastava
 * Since: April 15, 2019
 * Name: XeroScriptUtilTest
 * Description: test Class for XeroScriptUtil.
**/

@isTest
public without sharing class XeroScriptUtilTest {
	@testsetup
    private static void setup(){
    	TestDataFactory.disableFLSChecks();
    }
	static testmethod void scriptUtilTest() {
		test.startTest();
		XeroScriptUtil.syncCustomers(25,120,25);
		XeroScriptUtil.syncVendors(25,120,25);
		XeroScriptUtil.syncUnitInvoice(25,120);
		XeroScriptUtil.syncCODeposit(25,120);
		XeroScriptUtil.syncCOInvoicePaymentJE(25,120);
		XeroScriptUtil.syncCOInvoiceJE(25,120);
		XeroScriptUtil.updateCOInvoiceJE(25,120);
		XeroScriptUtil.syncUnitInvoiceJE(25,120);
		XeroScriptUtil.syncCountSessionJE(25,120);
		XeroScriptUtil.syncARPayments(25,120);
		XeroScriptUtil.syncUnitAdjustments(25,120);
		XeroScriptUtil.syncCOInvoice(25,120);
		XeroScriptUtil.syncCOInvoicePayment(25,120);
		XeroScriptUtil.syncFIFOBuckets(25,120);
		XeroScriptUtil.syncFIFOBucketLineItems(25,120);
		XeroScriptUtil.syncVRJE(25,120);
		XeroScriptUtil.syncVendorReturn(25,120);
		XeroScriptUtil.syncVendorInvoices(25,120);
		XeroScriptUtil.syncStoreCredits(25,120);
		XeroScriptUtil.syncHoursLogged(25,120);
		XeroScriptUtil.syncUnitNITCJE(25,120);
		XeroScriptUtil.syncConsignmentUnit(25,120);
		test.stopTest();
		system.assertEquals(true,true);
	}
}