@isTest
private class AccountingExportCtrlTest {
	
	@isTest
    private static void getPreviousExportDetailsTest() {
    	AccountingExportCtrl ctrlObj = new AccountingExportCtrl();
    	ctrlObj = new AccountingExportCtrl(new NewHomePageCtrl());
    	
        AccountingExportCtrl.getPreviousExportDetails();
        AccountingExportCtrl.processExport(null, null, null, null);
        AccountingExportCtrl.getTimePeriodForExport();
        
        system.assertEquals(0, [SELECT Id FROM Account].size());
    }
}