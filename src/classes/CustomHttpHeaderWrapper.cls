public class CustomHttpHeaderWrapper {
    
    public string headerType{get;set;}
    public string headerValue{get;set;}
    
    public CustomHttpHeaderWrapper() { }
    
    public CustomHttpHeaderWrapper(String key, String value) {
        this.headerType = key;
        this.headerValue= value;
    }
}