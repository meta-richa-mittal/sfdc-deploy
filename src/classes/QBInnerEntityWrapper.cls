public without sharing class QBInnerEntityWrapper {
    public String value;
    public String name;
    
    public QBInnerEntityWrapper(String value, String name) { 
        this.value = value;
        this.name = name;
    }

    public QBInnerEntityWrapper(AccountingVendorReturn.AccountRefWrapper AccountRef) {
        this.value = AccountRef.AccountingId;
    }
    
    public QBInnerEntityWrapper(String CategoryAccountRef) {
        this.value = CategoryAccountRef;
    }
}