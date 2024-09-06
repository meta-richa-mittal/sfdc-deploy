global without sharing class PartQtyCommittedRecalculationBatch extends PostInstallScriptBaseBatch{
    public Boolean recalculateQtyCommitted = false;
    
    global PartQtyCommittedRecalculationBatch() {}
    
    global PartQtyCommittedRecalculationBatch(Boolean recalculateQtyCommitted) {
        this.scriptName = 'executePartQtyCommittedRecalculationBatch()';
    	if(recalculateQtyCommitted != null) {
    		this.recalculateQtyCommitted = recalculateQtyCommitted;
    	}
    }
    
    global override Database.QueryLocator startScript(Database.BatchableContext bc) {
        String strQuery = 'SELECT Id FROM Part__c';
        return Database.getQueryLocator(strQuery); 
    }
    
    global override void executeScript(Database.batchableContext bc, List<SObject> partList) {
        List<Part__c> partListToUpdate = new List<Part__c>();
        if(recalculateQtyCommitted) {
            partListToUpdate = updatePartQtyCommitted(partList);
        }
        
        if(partListToUpdate.size() > 0) {
        	DMLUtility.updateSobjectList('Part__c', partListToUpdate); // do not stop trigger as change in qty available create/delete Required for stock VOLI
        }
    }
    
    global override void finishScript(Database.batchableContext bc) {}
    
    public static List<Part__c> updatePartQtyCommitted(List<SObject> partList) {
        List<Part__c> partListWithChild = [SELECT Qty_Committed__c,
                                            (SELECT Qty_Committed__c, Oversold_Qty__c FROM CO_Line_Items__r WHERE Closed_CO_Invoice_link__c = null AND 
                                                Invoice_Number__c = null AND CO_Header__r.Order_Status__c != 'Quote'),
                                            (SELECT Return_Qty__c FROM Return_VO_Line_Items__r WHERE Return_VO_Header__r.Status__c NOT IN('Approved','Credited'))
                                            FROM Part__c WHERE Id In :partList];
        List<Part__c> partListToUpdate = new List<Part__c>();
        for(Part__c partRec: partListWithChild) {
            partRec.Qty_Committed__c = partRec.Qty_Committed__c != null ? partRec.Qty_Committed__c : 0;
            Decimal qtyCommittedNew = 0;
            for(CO_Line_Item__c coli: partRec.CO_Line_Items__r) {
                qtyCommittedNew += ((coli.Qty_Committed__c != null ? coli.Qty_Committed__c : 0) - (coli.Oversold_Qty__c != null ? coli.Oversold_Qty__c : 0));
            }

            for(Return_VO_Line_Item__c rvoli: partRec.Return_VO_Line_Items__r) {
                if(rvoli.Return_Qty__c != null) {
                    qtyCommittedNew += rvoli.Return_Qty__c;
                }
            }
            if(qtyCommittedNew != partRec.Qty_Committed__c) {
                partRec.Qty_Committed__c = qtyCommittedNew;
                partListToUpdate.add(partRec);
            }
        }
        
        return partListToUpdate;
    }
}