public class BRPErrorHandler {

    public static ErrorMessageWrapper getMessageFromErrorPayload(HttpResponse response) {

        ErrorMessageWrapper errorObj = new ErrorMessageWrapper();

        if(response.getStatusCode() == 400 || response.getStatusCode() == 401 || response.getStatusCode() == 404) {
            BRPErrorWrapper errorResponse = (BRPErrorWrapper) System.JSON.deserialize(response.getBody(), BRPErrorWrapper.class);
            errorObj.title = errorResponse.meta.payload != null && errorResponse.meta.payload.errors != null ? errorResponse.meta.payload.errors[0].title : errorResponse.meta.detail;
            errorObj.code = errorResponse.meta.payload != null && errorResponse.meta.payload.errors != null ? errorResponse.meta.payload.errors[0].code : errorResponse.title;
        } else {
            errorObj.title = 'BRP Internal server error :: please contact your administrator';
        }

        return errorObj;
    }

    public static String getMessageFromMetaDetails(HttpResponse response) {
        String errorMessage = '';

        if(response.getStatusCode() == 400 || response.getStatusCode() == 401 || response.getStatusCode() == 404) {
            BRPErrorWrapper errorObj = (BRPErrorWrapper) System.JSON.deserialize(response.getBody(), BRPErrorWrapper.class);
            errorMessage = errorObj.meta.detail;
        } else {
            errorMessage = 'BRP Internal server error :: please contact your administrator';
        }
        
        return errorMessage;
    }
    
    public class ErrorMessageWrapper {
        public String title;
        public String code;
    }
}