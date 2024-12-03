/**
 * Author: Manoj Sharma
 * Since: April 21, 2021
 * Name: BRPPartOrderStatusCtrl
 * Description: Ctrl class for BRP part order status page
**/
global without sharing class BRPPartOrderStatusCtrl {
    global BRPPartOrderStatusCtrl(NewHomePageCtrl controller){} 
    public BRPPartOrderStatusCtrl() { }    
    
    @RemoteAction
    global static String getAllPartOrders(String filterJson, String paginationReferenceId) {
        filterJson = BPUtility.getDecodedString(filterJson);
        paginationReferenceId = BPUtility.getDecodedString(paginationReferenceId);
        try{
            return BPUtility.getEncodedString(BRPRetrievePartsOrderService.getPartsOrderByFilter(filterJson, paginationReferenceId));
        } catch(Exception e){
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }

    @RemoteAction
    global static String getPartOrderLineItems(String voNumber) {
        voNumber = BPUtility.getDecodedString(voNumber);
        try{
            return BPUtility.getEncodedString(BRPRetrievePartsOrderService.getPartOrderLineItems(voNumber));
        } catch(Exception e){
            throw new BlackPurlException(BlackPurlException.getErrorMessage(e.getMessage(), e.getStackTraceString()));
        }
    }
}
