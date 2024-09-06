global with sharing class CustomLoginCtrl {
    global CustomLoginCtrl () {}
    
     global PageReference forwardToHomePage() {
        PageReference pageRef = new PageReference(GeneralConfiguration.communityLink());
        
        return pageRef;
     }
}