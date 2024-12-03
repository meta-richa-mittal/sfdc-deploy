/**
 * Author: Nidhi Sharma
 * Since: April 07, 2022
 * Name: BRPArticleResponseWrapper
 * Description: Wrapper class for GET Article API Response
**/
public class BRPArticleResponseWrapper {

    public Integer StatusCode;
    public SuccessWrapper SuccessResponse;
    public FailureWrapper ErrorResponse;

    public class SuccessWrapper {
        public String last_publish_date;
        public String content_type;
        public String content;
        public String article_url;
        public String article_no;
        public String article_id;
        public String article_descr;
    }

    public class SuccessWrapperV4 {
        public Datetime last_publish_date;
        public String content_type;
        public String content;
        public String article_url;
        public String article_no;
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

    public static SuccessWrapper parseArticleResponse(SuccessWrapperV4 response) {
        SuccessWrapper responseObj = new SuccessWrapper();
        responseObj.article_no = response.article_no;
        responseObj.article_descr = response.article_descr;
        responseObj.article_url = response.article_url;
        responseObj.last_publish_date = String.valueOf(response.last_publish_date);
        responseObj.content_type = response.content_type;
        responseObj.content = response.content;
        return responseObj;
    }
}
