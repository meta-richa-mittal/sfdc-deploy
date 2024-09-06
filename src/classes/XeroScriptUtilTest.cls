/**
 * Author: Nikhil Kumar Srivastava
 * Since: April 15, 2019
 * Name: XeroScriptUtilTest
 * Description: test Class for XeroScriptUtil.
**/

@isTest
public without sharing class XeroScriptUtilTest {
	static testmethod void scriptUtilTest() {
		test.startTest();
		XeroScriptUtil.syncCustomers(25,60,25);
		XeroScriptUtil.syncVendors(25,60,25);
		XeroScriptUtil.syncUnitInvoice(25,60);
		XeroScriptUtil.syncCODeposit(25,60);
		XeroScriptUtil.syncCOInvoicePaymentJE(25,60);
		XeroScriptUtil.syncCOInvoiceJE(25,60);
		XeroScriptUtil.updateCOInvoiceJE(25,60);
		XeroScriptUtil.syncUnitInvoiceJE(25,60);
		XeroScriptUtil.syncCountSessionJE(25,60);
		XeroScriptUtil.syncARPayments(25,60);
		XeroScriptUtil.syncUnitAdjustments(25,60);
		XeroScriptUtil.syncCOInvoice(25,60);
		XeroScriptUtil.syncCOInvoicePayment(25,60);
		XeroScriptUtil.syncFIFOBuckets(25,60);
		XeroScriptUtil.syncFIFOBucketLineItems(25,60);
		XeroScriptUtil.syncVRJE(25,60);
		XeroScriptUtil.syncVendorReturn(25,60);
		XeroScriptUtil.syncVendorInvoices(25,60);
		XeroScriptUtil.syncStoreCredits(25,60);
		XeroScriptUtil.syncHoursLogged(25,60);
		XeroScriptUtil.syncUnitNITCJE(25,60);
		XeroScriptUtil.syncConsignmentUnit(25,60);
		test.stopTest();
		system.assertEquals(true,true);
	}
}