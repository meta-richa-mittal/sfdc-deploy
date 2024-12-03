global without sharing class BRPDealersController {  

    global BRPDealersController(NewHomePageCtrl controller){} 
    public BRPDealersController() { }    
 
    @RemoteAction
    global static String getDealer() {
        return BPUtility.getEncodedString(BRPDealerIntegration.getDealersList());
    }

    @RemoteAction
    global static String getDealerByDealerNo(String dealerNo) {
        return BPUtility.getEncodedString(BRPAPIManager.getDealer(BPUtility.getDecodedString(dealerNo)));
    }

    @RemoteAction
    global static String getArticleByArticleNo(String articleNo) {
        return BPUtility.getEncodedString(System.JSON.serialize(BRPAPIManager.getArticleByArticleNo(BPUtility.getDecodedString(articleNo))));
    }

    @RemoteAction
    global static String getCampaignsByVIN(String vin) {
        return BPUtility.getEncodedString(System.JSON.serialize(BRPAPIManager.getCampaignsByVIN(BPUtility.getDecodedString(vin))));
    }
}
