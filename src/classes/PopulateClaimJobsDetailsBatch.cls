global without sharing class PopulateClaimJobsDetailsBatch extends PostInstallScriptBaseBatch {
    global PopulateClaimJobsDetailsBatch() {
        this.scriptName = 'executePopulateClaimJobsDetailsBatch()';
    }

    global override Database.QueryLocator startScript(Database.BatchableContext bc) {
        String strQuery = 'SELECT Id, Deductible_SO_Payment__c, Claim__c FROM Service_Order_Header__c';
        return Database.getQueryLocator(strQuery);
    }
    
    global override void executeScript(Database.BatchableContext bc, List<SObject> soList) {
        List<Service_Order_Header__c> soHeaderList = [SELECT CO_Header__c, (SELECT Pre_Tax_Part_Sales__c, Pre_Tax_Labor_Sales__c, Pre_Tax_Fee_Sales__c, Pre_Tax_Supplies_Sales__c, Pre_Tax_Sublet_Sales__c
                                                            FROM Service_Order_Line_Items__r) FROM Service_Order_Header__c WHERE Id IN: soList];
        List<SO_Payment_Role__c> deductibleSOPaymentRoleList = [SELECT Id, Invoice_Number__c, Service_Order_Header__c, (SELECT Id, CO_Invoice_Header__c FROM CO_Invoice_Items__r WHERE Invoice_Header_Status__c = 'Closed' LIMIT 1) FROM SO_Payment_Role__c WHERE RecordType.DeveloperName ='Deductible' AND Service_Order_Header__c IN: soList]; 
        List<Claim__c> claimList = [SELECT Id, Claimed_Total__c, Total_Variance__c, Service_Order_Header__c, (SELECT Variance__c, Claimed_Subtotal__c FROM Claim_Line_Items__r WHERE Is_Variance__c = false) FROM Claim__c WHERE Service_Order_Header__c IN: soList];
        List<Individual_Tax__c> individualTaxList = [SELECT Deal__c, Taxable_Amount_for_Section_Header__c, CO_Line_Item__c, Tax_Rate__c, 
                                                            Form_Label__c, Sales_Tax_Item__r.Name__c, Tax_Amount__c, Tax_Amount_To_Invoice__c, 
                                                            Enhanced_Tax_Amount__c, Taxable_Amount__c, Taxable_Amount_To_Invoice__c, Service_Order_Line_Item__r.Service_Order_Header__c,
                                                            Applicable_Tax__c, List_Tax_items_on_forms__c, SO_Payment_Role__c 
                                                            FROM Individual_Tax__c WHERE Service_Order_Line_Item__c != null AND 
                                                            Service_Order_Line_Item__r.Service_Order_Header__c IN: soList];
    
        Map<Id, Claim__c> soIdToClaimMap = new Map<Id, Claim__c>();
        Decimal claimedAmount = 0;
        Decimal varianceAmount = 0;
        for(Claim__c claimRec: claimList) {
            claimedAmount = 0;
            varianceAmount = 0;
            for(Claim_Line_Item__c cliRec : claimRec.Claim_Line_Items__r) {
                claimedAmount += cliRec.Claimed_Subtotal__c != null ? cliRec.Claimed_Subtotal__c : 0;
                varianceAmount += cliRec.Variance__c != null ? cliRec.Variance__c : 0;
            }
            claimRec.Claimed_Total__c = claimedAmount;
            claimRec.Total_Variance__c = varianceAmount;
            soIdToClaimMap.put(claimRec.Service_Order_Header__c, claimRec);
        }

        Map<Id, SO_Payment_Role__c> soIdToSOPaymentRoleMap = new Map<Id, SO_Payment_Role__c>();
        for(SO_Payment_Role__c soPaymentRec : deductibleSOPaymentRoleList) {
            for(CO_Invoice_Item__c coInvItemRec : soPaymentRec.CO_Invoice_Items__r) {
                soPaymentRec.Invoice_Number__c = coInvItemRec.CO_Invoice_Header__c;
            }
            soIdToSOPaymentRoleMap.put(soPaymentRec.Service_Order_Header__c, soPaymentRec);
        }

        Map<Id, List<Individual_Tax__c>> soIdToIndividualTaxListMap = new Map<Id, List<Individual_Tax__c>>();
        
        for(Individual_Tax__c indTaxRec : individualTaxList) {
            if(!soIdToIndividualTaxListMap.containsKey(indTaxRec.Service_Order_Line_Item__r.Service_Order_Header__c)) {
                soIdToIndividualTaxListMap.put(indTaxRec.Service_Order_Line_Item__r.Service_Order_Header__c, new List<Individual_Tax__c>());
            } 
            soIdToIndividualTaxListMap.get(indTaxRec.Service_Order_Line_Item__r.Service_Order_Header__c).add(indTaxRec);
        }

        Decimal preTaxPartTotal = 0;
        Decimal preTaxLabourTotal = 0;
        Decimal preTaxFeeTotal = 0;
        Decimal preTaxShopSuppliesTotal = 0;
        Decimal preTaxSubletTotal = 0;

        for(Service_Order_Header__c soRec : soHeaderList) {
            preTaxPartTotal = 0;
            preTaxLabourTotal = 0;
            preTaxFeeTotal = 0;
            preTaxShopSuppliesTotal = 0;
            preTaxSubletTotal = 0;

            if(soIdToIndividualTaxListMap.containsKey(soRec.Id)) {
                List<Individual_Tax__c> indiTaxList = soIdToIndividualTaxListMap.get(soRec.Id);
                if(!indiTaxList.isEmpty()) {
                    soRec.Total_Tax__c = TaxCalculation.getTaxAmount_V2(indiTaxList);
                }
            }
            if(soIdToClaimMap.containsKey(soRec.Id)) {
                soRec.Claim__c = soIdToClaimMap.get(soRec.Id).Id;
            }
            if(soIdToSOPaymentRoleMap.containsKey(soRec.Id)) {
                soRec.Deductible_SO_Payment__c = soIdToSOPaymentRoleMap.get(soRec.Id).Id;
            }
            
            for(Service_Order_Line_Item__c soli : soRec.Service_Order_Line_Items__r) {
                preTaxPartTotal += soli.Pre_Tax_Part_Sales__c;
                preTaxLabourTotal += soli.Pre_Tax_Labor_Sales__c;
                preTaxFeeTotal += soli.Pre_Tax_Fee_Sales__c;
                preTaxShopSuppliesTotal += soli.Pre_Tax_Supplies_Sales__c;
                preTaxSubletTotal += soli.Pre_Tax_Sublet_Sales__c;
                
            }
            soRec.Pre_Tax_Shop_Supplies_Total__c = preTaxShopSuppliesTotal.setScale(2, RoundingMode.HALF_UP);
            soRec.Pre_Tax_Fees_Total__c = preTaxFeeTotal.setScale(2, RoundingMode.HALF_UP);
            soRec.Pre_Tax_Labor_Total__c = preTaxLabourTotal.setScale(2, RoundingMode.HALF_UP);
            soRec.Pre_Tax_Parts_Total__c = preTaxPartTotal.setScale(2, RoundingMode.HALF_UP);
            soRec.Pre_Tax_Sublet_Total__c = preTaxSubletTotal.setScale(2, RoundingMode.HALF_UP);
        }

        SOTriggerHelper.isForceStopTrigger = true;
        DMLUtility.updateSobjectList('Service_Order_Header__c', soHeaderList);
        DMLUtility.updateSobjectList('Claim__c', soIdToClaimMap.values());
        DMLUtility.updateSobjectList('SO_Payment_Role__c', soIdToSOPaymentRoleMap.values());
        SOTriggerHelper.isForceStopTrigger = false;
    }
    global override void finishScript(Database.BatchableContext bc) {}
}