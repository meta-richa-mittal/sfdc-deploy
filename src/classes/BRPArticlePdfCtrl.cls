public without sharing class BRPArticlePdfCtrl {
    public String base64content {get; private set;}
    public String contentType {get; private set;}
    
    public BRPArticlePdfCtrl() {}

    public PageReference getBRPArticle() {
        String articleNo = ApexPages.currentPage().getParameters().get('ArticleNo');
        BRPArticleResponseWrapper articleResponse = BRPAPIManager.getArticleByArticleNo(articleNo);
        
        if(articleResponse != null && articleResponse.SuccessResponse != null) {
            base64content = articleResponse.SuccessResponse.content;
            contentType = articleResponse.SuccessResponse.content_type;

            if(contentType.containsIgnoreCase('URL')) {
                PageReference page = new PageReference(base64content);
                page.setRedirect(true);
                return page;
            }
        }
        return null;
    }
}