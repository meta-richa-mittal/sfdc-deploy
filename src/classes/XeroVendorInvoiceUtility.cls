public without sharing class XeroVendorInvoiceUtility {
    public static List<XeroLineItemDTO> setAllInvoiceItemRec(AccountingVendorInvoice vendorInvoiceRecord) {
        
        List<XeroLineItemDTO> xeroInvoiceLineItemDtoList = new List<XeroLineItemDTO>();
        
	    String description = vendorInvoiceRecord.AccountingVIHeaderRec.VIHeaderNumber + ';' + vendorInvoiceRecord.AccountingVIHeaderRec.VendorName + ';' +
	    						vendorInvoiceRecord.AccountingVIHeaderRec.InvoiceNumber + ';';
	    String VRNumberFoDesc = vendorInvoiceRecord.VRNumberSet.size() == 1 ? new List<String>(vendorInvoiceRecord.VRNumberSet)[0] + ';' : '';
	    for(AccountingVendorInvoice.AccountingVIGroupByGLAndType accVIGRec: vendorInvoiceRecord.AccountingVIGroupByGLAndTypeList) {
        	xeroInvoiceLineItemDtoList.add(new XeroLineItemDTO((VRNumberFoDesc + description + accVIGRec.Type), 1, accVIGRec.Total, accVIGRec.GLNumber, accVIGRec.TaxCodeAccId));
        }
	    
	    /*other charges handling*/
        for(AccountingVendorInvoice.OtherChargesWrapper otherChargesRec : vendorInvoiceRecord.AccountingOtherChargesList) {
            otherChargesRec.Cost = otherChargesRec.Cost != null ? otherChargesRec.Cost : 0;
            if(otherChargesRec.IsTaxable) {
                xeroInvoiceLineItemDtoList.add(
                    new XeroLineItemDTO(description + 'Other Charge - '+otherChargesRec.ItemDesc, 1, otherChargesRec.Cost, otherChargesRec.CategoyRef, 
                    						vendorInvoiceRecord.AppliedQBTaxCode)
                );
            } else {
                xeroInvoiceLineItemDtoList.add(
                    new XeroLineItemDTO(description + 'Other Charge - '+otherChargesRec.ItemDesc, 1, otherChargesRec.Cost, otherChargesRec.CategoyRef, QBUtil.nonTaxablePurchaseCodeAccId)
                );
            }
        }
        return xeroInvoiceLineItemDtoList;
    }
    
    public static List<XeroLineItemDTO> setAllInvoiceItemRec(AccountingVendorReturn vendorReturn) {
        List<XeroLineItemDTO> xeroInvoiceLineItemDtoList = new List<XeroLineItemDTO>();
        for(AccountingVendorReturn.ReturnVoLineItemWrapper returnVOLI : vendorReturn.ReturnVOLIList) {
            xeroInvoiceLineItemDtoList.add(new XeroLineItemDTO(returnVOLI, vendorReturn.TaxCodeAccountingId));
            
            Decimal variance = ((returnVOLI.ReturnQty * returnVOLI.ItemCost) - returnVOLI.InventoryCost);
            String description = returnVOLI.ItemDescription;
            if(variance != 0) {
                xeroInvoiceLineItemDtoList.add(new XeroLineItemDTO(description+';Return Cost Variance', 1, -1 * variance,  AccountingUtil.getChartofAccount('A/P Inventory Accrual'), QBUtil.nonTaxablePurchaseCodeAccId, 0));
                xeroInvoiceLineItemDtoList.add(new XeroLineItemDTO(description+';Return Inventory Adjustment', 1, variance,  AccountingUtil.getChartofAccount('Inventory Adjustments'), QBUtil.nonTaxablePurchaseCodeAccId, 0));
            } 
        }
        return xeroInvoiceLineItemDtoList;
    }
    
    public static List<XeroLineItemDTO> setAllInvoiceItemRec(AccountingUnit unitRecord, Boolean isConsignment) {
        List<XeroLineItemDTO> xeroInvoiceLineItemDtoList = new List<XeroLineItemDTO>();
        xeroInvoiceLineItemDtoList.add(new XeroLineItemDTO(unitRecord, isConsignment));
        return xeroInvoiceLineItemDtoList;
    }
    
    public static List<XeroLineItemDTO> setAllInvoiceItemRec(AccountingUnitPriceAndCost unitPriceAndCostRec) {
        List<XeroLineItemDTO> xeroInvoiceLineItemDtoList = new List<XeroLineItemDTO>();
        String description = '';
		
		if(unitPriceAndCostRec.RefrenceNumber != null) {
			description += unitPriceAndCostRec.RefrenceNumber + ';' + 'Unit Cost Adjustment' + ';';
		}
        if(unitPriceAndCostRec.ItemDescription != null) {
        	description += unitPriceAndCostRec.ItemDescription + ';';
        }
        if(unitPriceAndCostRec.UnitId != null) {
        	description += unitPriceAndCostRec.UnitId + ';';
        }
        if(unitPriceAndCostRec.StockNumber != null) {
        	description += unitPriceAndCostRec.StockNumber + ';';
        }
        if(unitPriceAndCostRec.VIN != null) {
        	description += unitPriceAndCostRec.VIN;
        }
        
        Decimal totalCost = unitPriceAndCostRec.TotalCost;
        if(unitPriceAndCostRec.TotalCost != null && unitPriceAndCostRec.TotalCost < 0) {
        	totalCost = (-1 * unitPriceAndCostRec.TotalCost);
        }
        
        String inventoryGLNumber;
        if(unitPriceAndCostRec.UnitStatus == 'Available' || unitPriceAndCostRec.UnitStatus == 'Reserved') {
            inventoryGLNumber = unitPriceAndCostRec.Unit_Inventory_GL;
        } else {
            inventoryGLNumber = unitPriceAndCostRec.Unit_COGS_GL;
        }
        if(QBUtil.isQBTaxCodesEnabled) {
            if(unitPriceAndCostRec.TaxAmount < 0) {
                unitPriceAndCostRec.TaxAmount *= -1;
            }
            xeroInvoiceLineItemDtoList.add(new XeroLineItemDTO(description, 1, totalCost, inventoryGLNumber, unitPriceAndCostRec.ApplicableTaxAccId, unitPriceAndCostRec.TaxAmount));          
        } else {
            xeroInvoiceLineItemDtoList.add(new XeroLineItemDTO(description, 1, totalCost, 
        					inventoryGLNumber, QBUtil.nonTaxablePurchaseCodeAccId, 0));
        }					
        return xeroInvoiceLineItemDtoList;
    }
}