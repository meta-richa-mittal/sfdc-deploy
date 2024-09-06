global without sharing class PopulateStateFromAbbreviationBatch extends PostInstallScriptBaseBatch{
    global PopulateStateFromAbbreviationBatch() {
        this.scriptName = 'PopulateStateFromAbbreviationBatch()';
    }

    global override Database.QueryLocator startScript(Database.BatchableContext bc) {
        return Database.getQueryLocator('SELECT Id, BillingState, BillingCountry, ShippingState, ShippingCountry FROM Account where BillingState like \'__\' OR ShippingState like \'__\'');
    }

    global override void executeScript(Database.BatchableContext bc, List<SObject> accountList) {
        Map<String,String> stateAbbreviationToStateMap = AbbreviationsUtil.getStateAbbreviationToStateMap();
        for(Account accountRec: (List<Account>) accountList){
            if(String.isNotBlank(accountRec.BillingCountry) && String.isNotBlank(accountRec.BillingState) && accountRec.BillingState.length() == 2 && stateAbbreviationToStateMap.containsKey(accountRec.BillingCountry + '^&&^' + accountRec.BillingState)){
                accountRec.BillingState = stateAbbreviationToStateMap.get(accountRec.BillingCountry + '^&&^' + accountRec.BillingState);
            }
            if(String.isNotBlank(accountRec.ShippingCountry) && String.isNotBlank(accountRec.ShippingState) && accountRec.ShippingState.length() == 2 && stateAbbreviationToStateMap.containsKey(accountRec.ShippingCountry + '^&&^' + accountRec.ShippingState)){
                accountRec.ShippingState = stateAbbreviationToStateMap.get(accountRec.ShippingCountry + '^&&^' + accountRec.ShippingState);
            }
		}

        CustomerTriggerHelper.isForceStopTrigger = true;
        DMLUtility.updateSobjectList('Account',accountList);
        CustomerTriggerHelper.isForceStopTrigger = false;
    }

    global override void finishScript(Database.BatchableContext bc) {}
}
