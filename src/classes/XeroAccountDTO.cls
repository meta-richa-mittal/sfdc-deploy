public without sharing class XeroAccountDTO {
    public String AccountID;
    public String Name;
    public String Type;
    public String Status;
    public String Code;
    public String TaxType;
    public Boolean EnablePaymentsToAccount;
    
    public XeroAccountDTO(String code) {
		this.Code = code;
	}
}