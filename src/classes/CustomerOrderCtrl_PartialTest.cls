global without sharing class CustomerOrderCtrl_PartialTest {
    
    @future
	global static void moveLineItemFromOneServiceOrderToAnother(String sectionFrom, String sectionTo, String idToMove, String coHeaderId){
        CustomerOrderCtrl_V2.moveLineItem(BPUtility.getEncodedString(idToMove), BPUtility.getEncodedString(sectionTo), null, null);
	}
    
}