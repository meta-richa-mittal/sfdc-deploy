public without sharing class AdditionalFormCtrl {
    
    public List<Attachment> ImageList { 
        get {
            String formIdToIncludeOnDealDocuments = GeneralConfiguration.getFormIdToIncludeOnDealDocuments();
            List<Attachment> attList = new List<Attachment>();
            if(String.isNotBlank(formIdToIncludeOnDealDocuments)) {
                String attNameStr = formIdToIncludeOnDealDocuments + '%';
                attList = [SELECT Id FROM Attachment WHERE ParentId =: formIdToIncludeOnDealDocuments AND Name LIKE :attNameStr Order By Name ASC];
            }
            return attList;
        }
    }
}