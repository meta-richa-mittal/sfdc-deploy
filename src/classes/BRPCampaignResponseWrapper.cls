/**
 * Author: Nidhi Sharma
 * Since: April 07, 2022
 * Name: BRPCampaignResponseWrapper
 * Description: Wrapper class for GET Campaign API Response
**/
public class BRPCampaignResponseWrapper {

    public Integer StatusCode;
    public SuccessWrapper SuccessResponse;
    public FailureWrapper ErrorResponse;
    public String ButtonName;

    public class SuccessWrapper {
        public String vin;
        public String usage_descr;
        public String target_market_descr;
        public String product_code;
        public String platform_descr;
        public String package_descr;
        public String model_year;
        public String model_descr;
        public String length;
        public boolean is_cross_border;
        public String engine_type;
        public String comments;
        public String color_descr;
        public List<Campaign> campaigns;
        public String brand_descr;
    }

    public class Campaign {
		public String type_descr;	//Regular
		public String period_valid_to;	//2022-01-31
		public String period_valid_from;	//2019-01-22
		public boolean is_claimed;
		public String campaing_no;	//0010
		public String campaign_descr;	//ENGINE COOLANT OUTLET HOSE LEAK
		public String bulletin_no;	//2019-9
		public List<Article> articles;
	}

	public class Article {
		public String last_publish_date;	//2019-03-11T17:10:42.000Z
		public String content_type;	//PDF
		public String article_url;	//https://brp--qauat.my.salesforce.com/kAA0c000000fxSR?lang=en_US
		public String article_no;	//000136062
		public String article_id;	//kaA0c000000L42WEAS
		public String article_descr;	//SKI-DOO 2019-9 Engine Coolant Outlet Hose Leak_136062_WCN11Y019S01_en
	}

    public class SuccessWrapperV4 {
        public String serial_no;
        public String usage_descr;
        public String target_market_descr;
        public String product_code;
        public String platform_descr;
        public String package_descr;
        public Integer model_year;
        public String model_descr;
        public String length;
        public Boolean is_cross_border;
        public String engine_type;
        public String comments;
        public String color_descr;
        public List<CampaignV4> campaigns;
        public String brand_descr;
    }

	public class CampaignV4 {
		public String type_descr;
		public Date period_valid_to;
		public Date period_valid_from;
		public Boolean is_claimed;
		public String campaing_no;
		public String campaign_descr;
		public String bulletin_no;	
		public List<ArticleV4> articles;
	}

	public class ArticleV4 {
		public Datetime last_publish_date;
		public String content_type;
		public String article_url;	
		public String article_no;	
		public String article_id;	
		public String article_descr;
	}

    public class FailureWrapper {
        public String status;
        public List<ErrorWrapper> errors;
    }

    public class ErrorWrapper {
        public String title;
        public String code;
    }

    public static SuccessWrapper parseCampaignsResponse(SuccessWrapperV4 response) {
        SuccessWrapper responseObj = new SuccessWrapper();
        responseObj.vin = response.serial_no;
        responseObj.usage_descr = response.usage_descr;
        responseObj.target_market_descr = response.target_market_descr;
        responseObj.product_code = response.product_code;
        responseObj.platform_descr = response.platform_descr;
        responseObj.package_descr = response.package_descr;
        responseObj.model_year = String.valueOf(response.model_year);
        responseObj.model_descr = response.model_descr;
        responseObj.length = response.length;
        responseObj.is_cross_border = response.is_cross_border;
        responseObj.engine_type = response.engine_type;
        responseObj.comments = response.comments;
        responseObj.color_descr = response.color_descr;
        responseObj.brand_descr = response.brand_descr;
        if(response.campaigns != null) {
            responseObj.campaigns = new List<Campaign>();
            for(CampaignV4 campaignV4 : response.campaigns) {
                Campaign campaign = new Campaign();
                campaign.campaing_no = campaignV4.campaing_no;
                campaign.campaign_descr = campaignV4.campaign_descr;
                campaign.type_descr = campaignV4.type_descr;
                campaign.period_valid_from = String.valueOf(campaignV4.period_valid_from);
                campaign.period_valid_to = String.valueOf(campaignV4.period_valid_to);
                campaign.is_claimed = campaignV4.is_claimed;
                campaign.bulletin_no = campaignV4.bulletin_no;
                if(campaignV4.articles != null) {
                    campaign.articles = new List<Article>();
                    for(ArticleV4 articleV4 : campaignV4.articles) {
                        Article article = new Article();
                        article.article_no = articleV4.article_no;
                        article.article_descr = articleV4.article_descr;
                        article.content_type = articleV4.content_type;
                        article.article_url = articleV4.article_url;
                        article.last_publish_date = String.valueOf(articleV4.last_publish_date);
                        campaign.articles.add(article);
                    }  
                }
                responseObj.campaigns.add(campaign);
            }
        }
        return responseObj;
    }
}