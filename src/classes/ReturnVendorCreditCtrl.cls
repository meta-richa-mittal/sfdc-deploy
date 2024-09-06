public without sharing class ReturnVendorCreditCtrl {
    
    public ReturnVendorCreditCtrl(NewHomePageCtrl controller) {}
    public ReturnVendorCreditCtrl() {}
    
    @RemoteAction
    public static Integer getActiveReturnCRCountByVendorId(String vendorId) {
        return ReturnVendorCreditService.getActiveReturnCRCountByVendorId(vendorId);
    }

    @RemoteAction
    public static Object getActiveReturnCreditsByVendorId(GlobalSearchResultsWrapper.COOpenOrderFilterJSON filterObj) {
        return ReturnVendorCreditService.getActiveReturnCreditsByVendorId(filterObj);
    }

    @RemoteAction
    public static String addVendor(String vendorId, String returnCRId) {
    	return ReturnVendorCreditService.addVendor(vendorId, returnCRId);
    }

    @RemoteAction
    public static Object getReturnCreditDetails(String returnCRId) {
    	return ReturnVendorCreditService.getReturnCreditDetails(returnCRId);
    }

    @RemoteAction
    public static String saveReturnCreditDetails(Map<String, Object> rcrJsonMap) {
        return ReturnVendorCreditService.saveReturnCreditDetails(rcrJsonMap);
    }

    @RemoteAction
    public static Map<String, Object> getRVOListToCredit(String returnCRId, String vendorId, PaginationSorting pageSortAttrs) {
        return ReturnVendorCreditService.getRVOListToCredit(returnCRId, vendorId, pageSortAttrs);
    }

    @RemoteAction
    public static Object getRVODetailsById(String returnCRId, String rvoId) {
        return ReturnVendorCreditService.getRVODetailsById(returnCRId, rvoId);
    }

    @RemoteAction
    public static Map<String, Object> getRVOLIListToCredit(String returnCRId, String rvoId, Integer fromIndex, Integer toIndex) {
        return ReturnVendorCreditService.getRVOLIListToCredit(returnCRId, rvoId, fromIndex, toIndex);
    }

    @RemoteAction
    public static Boolean validateRVOLineItemsToCredit(String returnCRId, String recordId) {
        return ReturnVendorCreditService.validateRVOLineItemsToCredit(returnCRId, recordId);
    }

    @RemoteAction
    public static void createReturnCRLineItems(String returnCRId, String recordId) {
        ReturnVendorCreditService.createReturnCRLineItems(returnCRId, recordId);
    }

    @RemoteAction
    public static void removeReturnCRLineItems(String returnCRId, String recordId) {
        ReturnVendorCreditService.removeReturnCRLineItems(returnCRId, recordId);
    }

    @RemoteAction
    public static Map<String, Object> getItemsList(String returnCRId, PaginationSorting pageSortAttrs) {
        return ReturnVendorCreditService.getItemsList(returnCRId, pageSortAttrs);
    }

    @RemoteAction
    public static void updateRCRLineItemData(ReturnCRHeaderWrapper.ReturnCRLineItemWrapper itemObj) {
        ReturnVendorCreditService.updateRCRLineItemData(itemObj);
    }

    @RemoteAction
    public static String saveOtherCharge(String rcrId, VendorInvoicingCtrl.OtherChargesWrapper otherChargeObj) {
    	return ReturnVendorCreditService.saveOtherCharge(rcrId, otherChargeObj);
    }

    @RemoteAction
    public static void deleteOtherCharge(String otherChargeId) {
        ReturnVendorCreditService.deleteOtherCharge(otherChargeId);
    }

    @RemoteAction
    public static Object getOtherChargesList(String rcrId) {
        return ReturnVendorCreditService.getOtherChargesList(rcrId);
    }

    @RemoteAction
    public static String validateUniqueCreditMemoInAccounting(AccountingUtil.AccountingEntity txnObj) {
    	return AccountingUtil.validateVendorRefNumberInAccounting(txnObj);
    }

    @RemoteAction
    public static void processVendorCredit(String returnCRId) {
    	ReturnVendorCreditService.processVendorCredit(returnCRId);
    }
    
    @RemoteAction
    public static String deleteReturnVendorCredit(String returnCRId){
        return ReturnVendorCreditService.deleteReturnVendorCredit(returnCRId);
    }
}