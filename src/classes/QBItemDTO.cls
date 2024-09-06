public without sharing class QBItemDTO {
    public String SFId;
    public String Id;
    public String SyncToken; 
    public String Name;
    public String Description;
    public Boolean Active;
    public String Type;
    public Boolean sparse;
    public QuickBooksCategoryAccountRefWrapper IncomeAccountRef;
    public QuickBooksCategoryAccountRefWrapper ExpenseAccountRef;
    public QuickBooksCategoryAccountRefWrapper AssetAccountRef;
        
    public QBItemDTO(AccountingItemCategory categoryObj) {
        this.SFId = categoryObj.Id;
        String updatedFields = categoryObj.QBUpdatedField;
        this.Id = categoryObj.AccountingId;
        this.SyncToken = categoryObj.SyncToken;
        this.sparse = true;
        
        if(String.isBlank(updatedFields) || (String.isNotBlank(updatedFields) && (updatedFields.contains('Name') || updatedFields.contains('Type__c'))) || String.isBlank(categoryObj.AccountingId) ) {
            this.Name = (categoryObj.CategoryName != null && categoryObj.CategoryName.length() > 80) ? categoryObj.CategoryName.substring(0,80) : 
                          categoryObj.CategoryName;
            this.Name = this.Name + ' [' + categoryObj.Type + ']';
                
            if(categoryObj.Type == 'Labour' || categoryObj.Type == 'Internal Expense') {
                this.Type = 'Service'; 
            } else {
                this.Type = 'Inventory'; 
            }
        }
        
        if(String.isBlank(updatedFields) || (String.isNotBlank(updatedFields) && updatedFields.contains('Description__c'))) {
            this.Description = categoryObj.Description; 
            if(String.isNotBlank(this.Description) && this.Description.trim().length() > 4000) {
                this.Description = this.Description.substring(0, 4000);
            }
        }
        if(String.isBlank(updatedFields) || (String.isNotBlank(updatedFields) && updatedFields.contains('Active__c'))) {
            this.Active = categoryObj.Active;
        }
        if(String.isBlank(updatedFields) || (String.isNotBlank(updatedFields) && updatedFields.contains('Income_GL__c'))) {
            this.IncomeAccountRef = new QuickBooksCategoryAccountRefWrapper(categoryObj.IncomeAccountRef);
        }
        if(String.isBlank(updatedFields) || (String.isNotBlank(updatedFields) && updatedFields.contains('COGS_GL__c'))) {
            this.ExpenseAccountRef = new QuickBooksCategoryAccountRefWrapper(categoryObj.ExpenseAccountRef);
        }
        if(String.isBlank(updatedFields) || (String.isNotBlank(updatedFields) && updatedFields.contains('Inventory_GL__c'))) {
            this.AssetAccountRef = new QuickBooksCategoryAccountRefWrapper(categoryObj.AssetAccountRef);
        }
    }
     
    public class QuickBooksCategoryAccountRefWrapper {
        public String value;
        public QuickBooksCategoryAccountRefWrapper(AccountingItemCategory.AccountRefWrapper accountRef) {
            this.value = accountRef.Id;
        }
    }
}