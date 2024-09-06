/**
 * Author: Balveer Choudahry
 * Since: Apr 28, 2023
 * Name: CollectiveWrapper
 * Description: Wrapper class to handle Collective Id Realted Info
**/
public class CollectiveWrapper {
    
    public String externalId;
    public Boolean isDefault;
    public String name;

    public CollectiveWrapper(Collective__c collectiveRec) {
        this.externalId = collectiveRec.External_Id__c != null ? collectiveRec.External_Id__c : '';
        this.isDefault = collectiveRec.Default__c;
        this.name = collectiveRec.Name__c != null ? collectiveRec.Name__c : '';
    }
}