public without sharing class TaxEngine {

    private static Boolean isTaxIncludingPricing = GeneralConfiguration.getTaxIncludingPricing();
    private static Sales_Tax__c defaultSalesTax;
    private static Decimal totalTaxAmountForLine = 0;
    private static Decimal totalRateForLine = 0;
    private static Boolean refreshSOPRTax = false;

    private static final String SERVICE_ORDER_LINE_ITEM = 'Service_Order_Line_Item__c';
    private static final String OPTION_FEE = 'Option_Fee__c';
    private static final String DUPC = 'Deal_Unit_Price_Cost__c';
    private static final String DEAL_ITEM = 'Deal_Item__c';
    private static final String FI_PRODUCT = 'F_I_Product__c';
    private static final String UPC = 'Unit_Price_Cost__c';

    public static final String DEAL = 'Deal__c';
    public static final String DEAL_STORE = 'DEAL_STORE';

    public static final String CO_LINE_ITEM = 'CO_Line_Item__c';
    public static final String CO_LINE_ITEM_V2 = 'COLI';    //For few extra conditions where colineitem behave differently when caled from coli trigger or co trigger
    public static final String COKH = 'CO_Kit_Header__c';
    public static final String SOKH = 'Service_Order_Kit_Header__c';
    public static final String DKH = 'Deal_Kit_Header__c';
    public static final String SOPR = 'SO_Payment_Role__c';

    public static Map<Id, Service_Order_Line_Item__c> merchSOLIMap = new Map<Id, Service_Order_Line_Item__c>();
    public static Map<Id, Map<Id, Tax_Exemption__c>> sectionIdToExemptedSTIIdToExemptRecMap = new  Map<Id, Map<Id, Tax_Exemption__c>>();
    public static Map<Id, Map<Id, Tax_Exemption__c>> sectionIdToStoreSTIIdToExemptRecMap = new  Map<Id, Map<Id, Tax_Exemption__c>>();
    public static Map<Id, Map<Id, Tax_Exemption__c>> sectionIdToCustSTIIdToExemptRecMap = new  Map<Id, Map<Id, Tax_Exemption__c>>();
    
    public static Map<Id, Decimal> dealTaxRateIdToTaxableAmountMap = new Map<Id, Decimal>();
    public static Map<Id, Decimal> dealTaxRateIdToStoreTaxableAmountMap;
        
    public static Map<Id, List<Applicable_Taxes__c>> salesTaxIdToAppTaxRecordsMap;
    public static Map<Id, Decimal> salesTaxIdToTaxRateMap;

    public static void applySalesTaxonCOLIList(List<SObject> sobjList, Map<Id, Service_Order_Line_Item__c> soliMap) {
        merchSOLIMap = soliMap;
        applySalesTax(CO_LINE_ITEM, sobjList);
    }

    public static void applySalesTaxOnSOPRList(List<SObject> sobjList, Boolean refreshTax) {
        refreshSOPRTax = refreshTax;
        applySalesTax(SOPR, sobjList);
    }

    public static void applySalesTaxonSOLIList(List<SObject> sobjList) {
        applySalesTax(SERVICE_ORDER_LINE_ITEM, sobjList);
    }

    public static void applySalesTaxonOptionFeeList(List<SObject> sobjList) {
        applySalesTax(OPTION_FEE, sobjList);
    }

    public static void applySalesTaxonDUPCList(List<SObject> sobjList) {
        applySalesTax(DUPC, sobjList);
    }

    public static void applySalesTaxonDealItemList(List<SObject> sobjList) {
        applySalesTax(DEAL_ITEM, sobjList);
    }

    public static void applySalesTaxonFIProdList(List<SObject> sobjList) {
        applySalesTax(FI_PRODUCT, sobjList);
    }

    private static void applySalesTax(String sobjName, List<SObject> sobjList) {
        if(!sobjList.isEmpty()) {
            populateExemptionMap(getSectionIdsForExemptions(sobjName, sobjList));
            
            List<Individual_Tax__c> individualTaxDeleteList = new List<Individual_Tax__c>();
            Map<Id, Id> recIdToApplicableTaxIdMap = new Map<Id, Id>();
            setApplicableTaxes(sobjName, sobjList, individualTaxDeleteList, recIdToApplicableTaxIdMap);
            
            List<Individual_Tax__c> individualTaxToInsert = new List<Individual_Tax__c>();
            List<SObject> sobjListToUpdate = new List<SObject>();
            for(SObject sobjRec : sobjList) {
                Id oldTaxId = sobjRec.get('Applicable_Tax__c') != null ? (Id)sobjRec.get('Applicable_Tax__c') : null;
                Id newTaxId = recIdToApplicableTaxIdMap.get(String.valueOf(sobjRec.get('Id')));
                if(!isTaxApplicable(newTaxId, sobjName, sobjRec)) {
                    sobjListToUpdate.add(sobjRec);
                    continue;
                }
                Decimal exemptionRate = getExemptionAndIndividualTaxes(sobjName, sobjRec, newTaxId, individualTaxToInsert);
                
                populateTaxFields(sobjName, sobjRec, oldTaxId, newTaxId, totalRateForLine, exemptionRate);
                sobjListToUpdate.add(sobjRec);
            }
            if(sobjName.equalsIgnoreCase(SERVICE_ORDER_LINE_ITEM)) {
                if(TaxCalculation.IsEnhancedTaxCalculationApplicable || ServiceOrderLineItemTriggerHelper.isMoveLineItem) {
                    DMLUtility.deleteSobjectList('Individual_Tax__c', individualTaxDeleteList);
                }
            } else if(sobjName.equalsIgnoreCase(OPTION_FEE)) {
                if(OptionAndFeeTriggerHelper.isCustomerPLUpdate || TaxCalculation.IsEnhancedTaxCalculationApplicable) {
                    DMLUtility.deleteSobjectList('Individual_Tax__c', individualTaxDeleteList);
                }
            } else if(sobjName.equalsIgnoreCase(DUPC)) {
                if(DealUnitPriceAndCostTriggerHelper.isCustomerPLUpdate || TaxCalculation.IsEnhancedTaxCalculationApplicable) {
                    DMLUtility.deleteSobjectList('Individual_Tax__c', individualTaxDeleteList);
                }
            } else if(sobjName.equalsIgnoreCase(DEAL_ITEM)) {
                DMLUtility.deleteSobjectList('Individual_Tax__c', individualTaxDeleteList);
                
            } else if(sobjName.equalsIgnoreCase(FI_PRODUCT)) {
                if(FIProductTriggerHelper.isCustomerPLUpdate || TaxCalculation.IsEnhancedTaxCalculationApplicable) {
                    DMLUtility.deleteSobjectList('Individual_Tax__c', individualTaxDeleteList);
                }
            }
            
            DMLUtility.insertSobjectList('Individual_Tax__c', individualTaxToInsert);
            DMLUtility.updateSobjectList(sobjName, sobjListToUpdate);
        }
    }

    public static Set<Id> getSectionIdsForExemptions(String sobjName, List<SObject> sobjList) {
        Set<Id> sectionIds = new Set<Id>();
        for(SObject sobjRec : sobjList) {
            if(sobjName.equalsIgnoreCase(SERVICE_ORDER_LINE_ITEM)) {
                Service_Order_Line_Item__c soliRec = (Service_Order_Line_Item__c) sobjRec;
                if(soliRec.Service_Order_Header__r.Provider__c != null) sectionIds.add(soliRec.Service_Order_Header__c);
                sectionIds.add(soliRec.Service_Order_Header__r.CO_Header__c);
            } else if(sobjName.equalsIgnoreCase(CO_LINE_ITEM)) {
                CO_Line_Item__c coliRec = (CO_Line_Item__c) sobjRec;
                if(coliRec.Service_Order_Line_Item__c != null && merchSOLIMap != null) {
                    Service_Order_Line_Item__c soliRec = merchSOLIMap.get(coliRec.Service_Order_Line_Item__c);
                    if(soliRec != null && soliRec.Service_Order_Header__r.Provider__c != null) sectionIds.add(soliRec.Service_Order_Header__c);
                }
                sectionIds.add(coliRec.CO_Header__c);
            } else if(sobjName.equalsIgnoreCase(CO_LINE_ITEM_V2)) {
                CO_Line_Item__c coliRec = (CO_Line_Item__c) sobjRec;
                if(coliRec.Service_Order_Line_Item__r.Service_Order_Header__r.Provider__c != null) sectionIds.add(coliRec.Service_Order_Line_Item__r.Service_Order_Header__c);
                sectionIds.add(coliRec.CO_Header__c);
            } else if(sobjName.equalsIgnoreCase(OPTION_FEE)) {
                Option_Fee__c ofRec = (Option_Fee__c) sobjRec;
                sectionIds.add(ofRec.Deal_Item__r.Deal__r.CO_Header__c);
            } else if(sobjName.equalsIgnoreCase(DUPC)) {
                Deal_Unit_Price_Cost__c dupcRec = (Deal_Unit_Price_Cost__c) sobjRec;
                sectionIds.add(dupcRec.Deal_Item__r.Deal__r.CO_Header__c);
            } else if(sobjName.equalsIgnoreCase(DEAL_ITEM)) {
                Deal_Item__c dealItemRec = (Deal_Item__c) sobjRec;
                sectionIds.add(dealItemRec.Deal__r.CO_Header__c);
            } else if(sobjName.equalsIgnoreCase(FI_PRODUCT)) {
                F_I_Product__c fiProdRec = (F_I_Product__c) sobjRec;
                sectionIds.add(fiProdRec.Deal__r.CO_Header__c);
            } else if(sobjName.equalsIgnoreCase(DEAL)) {
                Deal__c dealRec = (Deal__c) sobjRec;
                sectionIds.add(dealRec.CO_Header__c);
            } else if(sobjName.equalsIgnoreCase(COKH)) {
                CO_Kit_Header__c cokhRec = (CO_Kit_Header__c) sobjRec;
                sectionIds.add(cokhRec.CO_Header__c);
            } else if(sobjName.equalsIgnoreCase(SOKH)) {
                Service_Order_Kit_Header__c sokhRec = (Service_Order_Kit_Header__c) sobjRec;
                if(sokhRec.Service_Order_Header__r.Job_Type__c != 'Internal' && sokhRec.Service_Order_Header__r.Provider__c != null) {
                    sectionIds.add(sokhRec.Service_Order_Header__c);
                }
                sectionIds.add(sokhRec.Service_Order_Header__r.CO_Header__c);
            } else if(sobjName.equalsIgnoreCase(DKH)) {
                Deal_Kit_Header__c dkhRec = (Deal_Kit_Header__c) sobjRec;
                sectionIds.add(dkhRec.Deal_Item__r.Deal__r.CO_Header__c);

            } else if(sobjName.equalsIgnoreCase(SOPR)) {
                SO_Payment_Role__c soprRec = (SO_Payment_Role__c) sobjRec;
                sectionIds.add(soprRec.Service_Order_Header__r.CO_Header__c);
                sectionIds.add(soprRec.Service_Order_Header__c);
            }
        }
        sectionIds.remove(null);
        return sectionIds;
    }

    public static void populateExemptionMap(Set<Id> sectionIds) {
        sectionIdToExemptedSTIIdToExemptRecMap = new  Map<Id, Map<Id, Tax_Exemption__c>>();
        sectionIdToStoreSTIIdToExemptRecMap = new  Map<Id, Map<Id, Tax_Exemption__c>>();
        sectionIdToCustSTIIdToExemptRecMap = new  Map<Id, Map<Id, Tax_Exemption__c>>();
        if(sectionIds != null) sectionIds.remove(null);
        if(sectionIds != null && !sectionIds.isEmpty()) {
            // Get list of Tax Exemptions for given customer/provider ids
            for(Tax_Exemption__c taxExemptionRec : [SELECT Type__c, Description__c, Rate_Override__c, CO_Header__r.Customer__c, Service_Order_Header__r.Provider__c, Sales_Tax_Item__r.Rate__c from Tax_Exemption__c where (CO_Header__c IN: sectionIds OR Service_Order_Header__c IN: sectionIds)]) {
                String sectionId = taxExemptionRec.Service_Order_Header__c != null ? taxExemptionRec.Service_Order_Header__c : taxExemptionRec.CO_Header__c;
                if(String.isNotBlank(sectionId)) {
                    if(taxExemptionRec.Type__c == null || taxExemptionRec.Type__c.equalsIgnoreCase(TaxUtility.EXEMPTION)) {
                        if(!sectionIdToExemptedSTIIdToExemptRecMap.containsKey(sectionId)) {
                            sectionIdToExemptedSTIIdToExemptRecMap.put(sectionId, new Map<Id, Tax_Exemption__c>());
                        }
                        sectionIdToExemptedSTIIdToExemptRecMap.get(sectionId).put(taxExemptionRec.Sales_Tax_Item__c, taxExemptionRec);
                    } else if(taxExemptionRec.Type__c.equalsIgnoreCase(TaxUtility.AUTOMATED_STORE)) {
                        if(!sectionIdToStoreSTIIdToExemptRecMap.containsKey(sectionId)) {
                            sectionIdToStoreSTIIdToExemptRecMap.put(sectionId, new Map<Id, Tax_Exemption__c>());
                        }
                        sectionIdToStoreSTIIdToExemptRecMap.get(sectionId).put(taxExemptionRec.Sales_Tax_Item__c, taxExemptionRec);
                    } else if(taxExemptionRec.Type__c.equalsIgnoreCase(TaxUtility.AUTOMATED_CUSTOMER)) {
                        if(!sectionIdToCustSTIIdToExemptRecMap.containsKey(sectionId)) {
                            sectionIdToCustSTIIdToExemptRecMap.put(sectionId, new Map<Id, Tax_Exemption__c>());
                        }
                        sectionIdToCustSTIIdToExemptRecMap.get(sectionId).put(taxExemptionRec.Sales_Tax_Item__c, taxExemptionRec);
                    }
                }
            }
        }
    }

    public static void populateApplicableTaxes(Set<Id> salesTaxIdSet) {
        List<Applicable_Taxes__c> applicableTaxList = new List<Applicable_Taxes__c>();
        salesTaxIdToAppTaxRecordsMap = new Map<Id, List<Applicable_Taxes__c>>();
        salesTaxIdToTaxRateMap = new Map<Id, Decimal>();
        if(salesTaxIdSet != null && !salesTaxIdSet.isEmpty()) {
            applicableTaxList = TaxManagementSOQLUtil.getApplicableTaxListBySalesTaxIdList(new List<Id>(salesTaxIdSet));
            
            for(Applicable_Taxes__c appTax : applicableTaxList) {
                if(!salesTaxIdToAppTaxRecordsMap.containsKey(appTax.Sales_Tax__c)) {
                    salesTaxIdToAppTaxRecordsMap.put(appTax.Sales_Tax__c, new List<Applicable_Taxes__c>());
                } 
                salesTaxIdToAppTaxRecordsMap.get(appTax.Sales_Tax__c).add(appTax);
            }
            for(Id salesTaxId : salesTaxIdToAppTaxRecordsMap.keyset()) {
                Decimal salesTaxRate = 0;
                for(Applicable_Taxes__c appTax : salesTaxIdToAppTaxRecordsMap.get(salesTaxId)) {
                    salesTaxRate += appTax.Sales_Tax_Item__r.Rate__c;
                }
                salesTaxIdToTaxRateMap.put(salesTaxId, salesTaxRate);
            }
        }
        system.debug('salesTaxIdToAppTaxRecordsMap>> ' + salesTaxIdToAppTaxRecordsMap);
        system.debug('salesTaxIdToTaxRateMap>> ' + salesTaxIdToTaxRateMap);
    }

    public static void setApplicableTaxes(String sobjName, List<SObject> sobjList, List<Individual_Tax__c> individualTaxList, Map<Id, Id> recIdToApplicableTaxIdMap) {
        // Entity Tax Rate
        Set<Id> salesTaxIdSet = new Set<Id>();
        Id salesTaxId;
        for(SObject sobjRec : sobjList) {
            if(sobjName.equalsIgnoreCase(COKH)) {
                CO_Kit_Header__c cokhRec = (CO_Kit_Header__c) sobjRec;
                if(cokhRec.Deal__c == null) {
                    for(CO_Line_Item__c coliRec : cokhRec.CO_Line_Items__r) {
                        salesTaxId = getApplicableTaxCodeId(sobjName, coliRec);
                        if(salesTaxId != null) {
                            recIdToApplicableTaxIdMap.put(coliRec.Id, salesTaxId);
                            salesTaxIdSet.add(salesTaxId);
                        }
                    }
                }
            } else if(sobjName.equalsIgnoreCase(SOKH)) {
                Service_Order_Kit_Header__c sokhRec = (Service_Order_Kit_Header__c) sobjRec;
                if(sokhRec.Deal__c == null) {
                    for(Service_Order_Line_Item__c soliRec : sokhRec.Service_Order_Line_Items__r) {
                        salesTaxId = getApplicableTaxCodeId(sobjName, soliRec);
                        if(salesTaxId != null) {
                            recIdToApplicableTaxIdMap.put(soliRec.Id, salesTaxId);
                            salesTaxIdSet.add(salesTaxId);
                        }
                    }
                }
            } else if(sobjName.equalsIgnoreCase(DKH)) {
                Deal_Kit_Header__c dkhRec = (Deal_Kit_Header__c) sobjRec;
                for(Option_Fee__c ofRec : dkhRec.Options_Fees__r) {
                    salesTaxId = getApplicableTaxCodeId(sobjName, ofRec);
                    if(salesTaxId != null) {
                        recIdToApplicableTaxIdMap.put(ofRec.Id, salesTaxId);
                        salesTaxIdSet.add(salesTaxId);
                    }
                }
            } else {
                salesTaxId = getApplicableTaxCodeId(sobjName, sobjRec);
                if(salesTaxId != null) {
                    recIdToApplicableTaxIdMap.put(Id.valueOf(String.valueOf(sobjRec.get('Id'))), salesTaxId);
                    salesTaxIdSet.add(salesTaxId);
                }
                if(sobjName.equalsIgnoreCase(SERVICE_ORDER_LINE_ITEM)) {
                    Service_Order_Line_Item__c soliRec = (Service_Order_Line_Item__c) sobjRec;
                    individualTaxList.addAll(soliRec.Individual_Taxes__r);

                } else if(sobjName.equalsIgnoreCase(OPTION_FEE)) {
                    Option_Fee__c ofRec = (Option_Fee__c) sobjRec;
                    individualTaxList.addAll(ofRec.Individual_Taxes__r);

                } else if(sobjName.equalsIgnoreCase(DUPC)) {
                    Deal_Unit_Price_Cost__c dupcRec = (Deal_Unit_Price_Cost__c) sobjRec;
                    individualTaxList.addAll(dupcRec.Individual_Taxes__r);

                } else if(sobjName.equalsIgnoreCase(DEAL_ITEM)) {
                    Deal_Item__c dealItemRec = (Deal_Item__c) sobjRec;
                    individualTaxList.addAll(dealItemRec.Individual_Taxes__r);

                } else if(sobjName.equalsIgnoreCase(FI_PRODUCT)) {
                    F_I_Product__c fiProdRec = (F_I_Product__c) sobjRec;
                    individualTaxList.addAll(fiProdRec.Individual_Taxes__r);
                }
            }
        }
        salesTaxIdSet.remove(null);
        populateApplicableTaxes(salesTaxIdSet);
    }

    private static Id getApplicableTaxCodeId(String sobjName, SObject sobjRec) {
        if(sobjName.equalsIgnoreCase(SERVICE_ORDER_LINE_ITEM) || sobjName.equalsIgnoreCase(SOKH)) {
            Service_Order_Line_Item__c soliRec = (Service_Order_Line_Item__c) sobjRec;
            if(!sobjName.equalsIgnoreCase(SERVICE_ORDER_LINE_ITEM) || soliRec.Labour_Code__c != null || soliRec.Sublet__c != null) {
                return ServiceJobUtil.getApplicableTaxOnSOLI(soliRec);
            }
        } else if(sobjName.equalsIgnoreCase(COKH) || sobjName.equalsIgnoreCase(CO_LINE_ITEM_V2)) {
            CO_Line_Item__c coliRec = (CO_Line_Item__c)sobjRec;
            return MerchandiseUtil.getApplicableTaxOnCOLI(coliRec);

        } else if(sobjName.equalsIgnoreCase(CO_LINE_ITEM)) {
            CO_Line_Item__c coliRec = (CO_Line_Item__c)sobjRec;
            return COLineItemTriggerHelper.getAppliedSalesTaxId(coliRec, COLineItemTriggerHelper.partIdToPartRecordMap, COLineItemTriggerHelper.feeIdToFeeRecordMap, merchSOLIMap);
        
        } else if(sobjName.equalsIgnoreCase(OPTION_FEE) || sobjName.equalsIgnoreCase(DKH)) {
            Option_Fee__c ofRec = (Option_Fee__c) sobjRec;
            return DealUtil.getApplicableTaxOnOptionAndFee(ofRec);

        } else if(sobjName.equalsIgnoreCase(DUPC)) {
            Deal_Unit_Price_Cost__c dupcRec = (Deal_Unit_Price_Cost__c) sobjRec;
            if(dupcRec.Deal_Item__r.Taxable__c) {
                if(dupcRec.Deal_Item__r.Applicable_Tax__c != null) {
                    return dupcRec.Deal_Item__r.Applicable_Tax__c;
                } else if(Configurations__c.getOrgDefaults().Default_Tax_on_Unit__c != null) {
                    return Configurations__c.getInstance().Default_Tax_on_Unit__c;
                } else {
                    if(defaultSalesTax == null) populateDefaultSalesTax();
                    if(defaultSalesTax != null) return defaultSalesTax.Id;
                }
            }
            
        } else if(sobjName.equalsIgnoreCase(DEAL_ITEM)) {
            Deal_Item__c dealItemRec = (Deal_Item__c) sobjRec;
            if(dealItemRec.Taxable__c && dealItemRec.Applicable_Tax__c != null) {
                return dealItemRec.Applicable_Tax__c;
            }
        } else if(sobjName.equalsIgnoreCase(FI_PRODUCT)) {
            F_I_Product__c fiProdRec = (F_I_Product__c) sobjRec;
            return fiProdRec.Vendor_Product__r.Applicable_Tax__c;
        } else if(sobjName.equalsIgnoreCase(SOPR)) {
            SO_Payment_Role__c soprRec = (SO_Payment_Role__c) sobjRec;
            if(soprRec.Applicable_Tax__c == null || (refreshSOPRTax != null && refreshSOPRTax)) {
                return GeneralConfiguration.getDefaultTaxOnClaimDeductibles();
            }
            return soprRec.Applicable_Tax__c;
        }
        
        return null;
    }
    
    private static void populateDefaultSalesTax() {
        if(AccessControl.ifObjectFieldIsAccessible('Sales_Tax__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        for(Sales_Tax__c salesTaxRec : [SELECT Rate__c FROM Sales_Tax__c WHERE default__c = true LIMIT 1]) {
            defaultSalesTax = salesTaxRec;
        }
    }

    public static Boolean isTaxApplicable(String newTaxId, String sobjName, SObject sobjRec) {
        if(sobjName.equalsIgnoreCase(SERVICE_ORDER_LINE_ITEM)) {
            Service_Order_Line_Item__c soliRec = (Service_Order_Line_Item__c) sobjRec;
            if(newTaxId == null || soliRec.Service_Order_Header__r.Job_Type__c == 'Deal') {
                sobjRec.put('Applicable_Tax__c', null);
                if(isTaxIncludingPricing) {
                    if((ServiceOrderLineItemTriggerHelper.isMoveLineItem || (soliRec.Labour_Code__c == null && soliRec.Part__c == null && COTriggerHelper.isRetainItemPrices)) && soliRec.Price_When_Tax_Included__c != null) {
                        sobjRec.put('Kit_Price__c', soliRec.Price_When_Tax_Included__c);
                    } else if(soliRec.Kit_Price__c != null) {
                        sobjRec.put('Price_When_Tax_Included__c', soliRec.Kit_Price__c);
                    }
                }
                return false;
            }
        } else if(sobjName.equalsIgnoreCase(CO_LINE_ITEM)) {
            CO_Line_Item__c coliRec = (CO_Line_Item__c)sobjRec;
            if(newTaxId == null || coliRec.Deal__c != null) {
                if(isTaxIncludingPricing && coliRec.Price__c != null) {
                    sobjRec.put('Price_When_Tax_Included__c', coliRec.Price__c);
                }
                sobjRec.put('Applicable_Tax__c', null);
                sobjRec.put('Sales_Tax_Percentage__c', 0);
                return false;
            }  
        } else if(sobjName.equalsIgnoreCase(OPTION_FEE)) {
            Option_Fee__c optionAndFeeRec = (Option_Fee__c) sobjRec;
            if(newTaxId == null) {
                if(isTaxIncludingPricing) {
                    if(COTriggerHelper.isRetainItemPrices && optionAndFeeRec.Part__c == null && optionAndFeeRec.Labour_Code__c == null && optionAndFeeRec.Price_When_Tax_Included__c != null) {
                        sobjRec.put('Price__c', optionAndFeeRec.Price_When_Tax_Included__c);
                    } else if(optionAndFeeRec.Price__c != null) {
                        sobjRec.put('Price_When_Tax_Included__c', optionAndFeeRec.Price__c);
                    }
                }
                sobjRec.put('Applicable_Tax__c', null);
                sobjRec.put('Sales_Tax_Percentage__c', 0);
                return false;
            }
        } else if(sobjName.equalsIgnoreCase(DUPC)) {
            Deal_Unit_Price_Cost__c dupcRec = (Deal_Unit_Price_Cost__c)sobjRec;
            if(newTaxId == null) {
                if(isTaxIncludingPricing && dupcRec.Price__c != null) {
                    sobjRec.put('Price_When_Tax_Included__c', dupcRec.Price__c);
                }
                sobjRec.put('Applicable_Tax__c', null);
                sobjRec.put('Sales_Tax_Percentage__c', 0);
                return false;
            }  
        } else if(sobjName.equalsIgnoreCase(DEAL_ITEM)) {
            Deal_Item__c dealItemRec = (Deal_Item__c) sobjRec;
            return (dealItemRec.Taxable__c && dealItemRec.Applicable_Tax__c != null);

        } else if(sobjName.equalsIgnoreCase(FI_PRODUCT)) {
            F_I_Product__c fiProdRec = (F_I_Product__c) sobjRec;
            if(newTaxId == null) {
                if(isTaxIncludingPricing && fiProdRec.Price__c != null) {
                    sobjRec.put('Price_When_Tax_Included__c', fiProdRec.Price__c);
                }
                sobjRec.put('Applicable_Tax__c', null);
                sobjRec.put('Sales_Tax_Percentage__c', 0);
                return false;
            }
        } else if(sobjName.equalsIgnoreCase(SOPR)) {
            SO_Payment_Role__c soprRec = (SO_Payment_Role__c) sobjRec;
            if(newTaxId == null) {
                sobjRec.put('Applicable_Tax__c', null);
                sobjRec.put('Tax__c', 0);
                sobjRec.put('Tax_Amount__c', 0);
                return false;
            }  
        }

        return true;
    }

    public static Decimal getExemptionAndIndividualTaxes(String sobjName, SObject sobjRec, Id newTaxId, List<Individual_Tax__c> individualTaxInsertList) {
        return getExemptionAndIndividualTaxes(sobjName, null, sobjRec, newTaxId, individualTaxInsertList);
    }

    public static Decimal getExemptionAndIndividualTaxes(String sobjName, SObject sectionKitObj, SObject sobjRec, Id newTaxId, List<Individual_Tax__c> individualTaxInsertList) {
        Decimal exemptionRate = 0;
        //Set entity object name
        String lineItemObjName = getLineItemObjName(sobjName);
        if(newTaxId != null && salesTaxIdToAppTaxRecordsMap.get(newTaxId) != null) {
            system.debug('Applicables Tax Items>> ' + salesTaxIdToAppTaxRecordsMap.get(newTaxId));
            system.debug('Applicables Tax Items size>> ' + salesTaxIdToAppTaxRecordsMap.get(newTaxId).size());
            totalRateForLine = 0;
            totalTaxAmountForLine = 0;
            for(Applicable_Taxes__c appTax : salesTaxIdToAppTaxRecordsMap.get(newTaxId)) {
                exemptionRate += applyTaxRate(sobjName, sectionKitObj, lineItemObjName, sobjRec, appTax, individualTaxInsertList);
            }
        }
        return exemptionRate;
    }

    private static Decimal applyTaxRate(String kitSObjName, SObject sectionKitObj, String lineItemObjName, SObject sobjRec, Applicable_Taxes__c applicableTax, List<Individual_Tax__c> individualTaxInsertList) {
        Decimal exemptionRate = 0;
        Sales_Tax_Item__c stiRec = applicableTax.Sales_Tax_Item__r;
        if(!stiRec.Is_Automated__c || stiRec.Active__c) {
            system.debug('Sales_Tax_Item__c Rec>> ' + stiRec);
            OverrideTax overrideTaxObj;
            if(sectionKitObj != null) {
                overrideTaxObj = getRateOverride(kitSObjName, sectionKitObj, stiRec.Id);
            } else {
                overrideTaxObj = getRateOverride(lineItemObjName, sobjRec, stiRec.Id);
            }
            system.debug('overridden tax obj>> ' + overrideTaxObj);
            if(overrideTaxObj.taxRate == null) {
                totalRateForLine += (stiRec.Rate__c != null ? stiRec.Rate__c : 0);
                exemptionRate = stiRec.Rate__c;
            } else if(individualTaxInsertList != null) {
                Individual_Tax__c indTaxRec = createIndividualTaxRec(lineItemObjName, sobjRec, applicableTax, overrideTaxObj);
                if(((indTaxRec.Tax_Rate__c != null && indTaxRec.Tax_Rate__c != 0) || 
                (indTaxRec.Enhanced_Tax_Amount__c != null && indTaxRec.Enhanced_Tax_Amount__c != 0)) && 
                isCreateIndividualTaxRec(lineItemObjName, sobjRec)) {
                    individualTaxInsertList.add(indTaxRec);
                }
            }
        }
        return (exemptionRate != null ? exemptionRate : 0);
    }

    public static Boolean isCreateIndividualTaxRec(String sobjName, SObject sobjRec) {
        if(String.isNotBlank(sobjName)) {
            if(sobjName.equalsIgnoreCase(SERVICE_ORDER_LINE_ITEM)) {
                Service_Order_Line_Item__c soliRec = (Service_Order_Line_Item__c) sobjRec;
                return (soliRec.Deal__c == null);
            } else if(sobjName.equalsIgnoreCase(CO_LINE_ITEM) || sobjName.equalsIgnoreCase(CO_LINE_ITEM_V2)) {
                CO_Line_Item__c coliRec = (CO_Line_Item__c) sobjRec;
                return (coliRec.Deal__c == null);
            } else if(sobjName.equalsIgnoreCase(OPTION_FEE)) {
                return isTaxIncludingPricing;   //In Tax exclude pricing deal is taxed by invoice
            } else if(sobjName.equalsIgnoreCase(DUPC)) {
                return isTaxIncludingPricing;   //In Tax exclude pricing deal is taxed by invoice
            } else if(sobjName.equalsIgnoreCase(DEAL_ITEM)) {
                return isTaxIncludingPricing;   //In Tax exclude pricing deal is taxed by invoice
            } else if(sobjName.equalsIgnoreCase(FI_PRODUCT)) {
                return isTaxIncludingPricing;   //In Tax exclude pricing deal is taxed by invoice
            }
        }
        
        return true;
    }
    
    private static Individual_Tax__c createIndividualTaxRec(String sobjName, SObject sobjRec, Applicable_Taxes__c applicableTax, OverrideTax overrideTaxObj) {
        Sales_Tax_Item__c stiRec = applicableTax.Sales_Tax_Item__r;
        Decimal taxableAmount = getTaxableAmount(sobjName, sobjRec, stiRec.Id);
        
        Individual_Tax__c individualTaxRec = new Individual_Tax__c();
        sobjName = (sobjName.equalsIgnoreCase(CO_LINE_ITEM_V2) ? CO_LINE_ITEM : sobjName);
        sobjName = (sobjName.equalsIgnoreCase(DEAL_STORE) ? DEAL : sobjName);

        individualTaxRec.put(sobjName, sobjRec.get('Id'));
        if(sobjName.equalsIgnoreCase(CO_LINE_ITEM) && sobjRec.get('Service_Order_Line_Item__c') != null) {
            individualTaxRec.put('Service_Order_Line_Item__c', String.valueOf(sobjRec.get('Service_Order_Line_Item__c')));
        }
        individualTaxRec.Sales_Tax_Item__c = stiRec.Id;
        individualTaxRec.Sales_Tax_Item_Name__c = (String.isNotBlank(overrideTaxObj.taxName) ? overrideTaxObj.taxName : stiRec.Name__c);
        individualTaxRec.Taxable_Amount_for_Section_Header__c = taxableAmount;
        Decimal overriddenTaxRate = overrideTaxObj.taxRate;

        if(stiRec.Rate_Type__c == TaxManagementService.FIXED_RATE || stiRec.Is_Automated__c || (overriddenTaxRate != null &&  overriddenTaxRate != 0)) {
            Decimal taxRate = (stiRec.Is_Automated__c || (overriddenTaxRate != null && overriddenTaxRate != 0) ? overriddenTaxRate : stiRec.Rate__c);
            individualTaxRec.Enhanced_Tax_Amount__c = getFixedTaxAmount(taxableAmount, taxRate, applicableTax);
            individualTaxRec.Tax_Rate__c = taxRate;
        } else {
            individualTaxRec.Enhanced_Tax_Amount__c = getEnhancedTaxAmount(taxableAmount, stiRec);
        }
        if(individualTaxRec.Enhanced_Tax_Amount__c != null) {
            totalTaxAmountForLine += individualTaxRec.Enhanced_Tax_Amount__c;
        } else if(individualTaxRec.Tax_Rate__c != null) {
            totalRateForLine += individualTaxRec.Tax_Rate__c;
        }
        return individualTaxRec;
    }

    private static Decimal getTaxableAmount(String sobjName, SObject sobjRec, Id stiId) {
        Decimal qty, price;
        if(sobjName.equalsIgnoreCase(SERVICE_ORDER_LINE_ITEM)) {
            qty = sobjRec.get('Qty_Needed__c') != null ? Decimal.valueOf(String.valueOf(sobjRec.get('Qty_Needed__c'))) : 1;
            price = sobjRec.get('Kit_Price__c') != null ? Decimal.valueOf(String.valueOf(sobjRec.get('Kit_Price__c'))) : 0;
        } else if(sobjName.equalsIgnoreCase(CO_LINE_ITEM) || sobjName.equalsIgnoreCase(CO_LINE_ITEM_V2) || sobjName.equalsIgnoreCase(OPTION_FEE) || sobjName.equalsIgnoreCase(DUPC)) {
            qty = sobjRec.get('Qty__c') != null ? Decimal.valueOf(String.valueOf(sobjRec.get('Qty__c'))) : 1;
            price = sobjRec.get('Price__c') != null ? Decimal.valueOf(String.valueOf(sobjRec.get('Price__c'))) : 0;
        } else if(sobjName.equalsIgnoreCase(DEAL_ITEM)) {
            price = sobjRec.get('Agreed_Value__c') != null ? Decimal.valueOf(String.valueOf(sobjRec.get('Agreed_Value__c'))) : 0;
        } else if(sobjName.equalsIgnoreCase(FI_PRODUCT)) {
            price = sobjRec.get('Price__c') != null ? Decimal.valueOf(String.valueOf(sobjRec.get('Price__c'))) : 0;
        } else if(sobjName.equalsIgnoreCase(DEAL) && dealTaxRateIdToTaxableAmountMap.get(stiId) != null) {
            price = dealTaxRateIdToTaxableAmountMap.get(stiId);
        } else if(sobjName.equalsIgnoreCase(DEAL_STORE) && dealTaxRateIdToStoreTaxableAmountMap.get(stiId) != null) {
            price = dealTaxRateIdToStoreTaxableAmountMap.get(stiId);
        } else if(sobjName.equalsIgnoreCase(UPC)) {
            price = sobjRec.get('Total_Cost__c') != null ? Decimal.valueOf(String.valueOf(sobjRec.get('Total_Cost__c'))) : 0;
        }
        return ((qty != null ? qty : 1) * (price != null ? price : 0));
    }

    public static OverrideTax getRateOverride(String sobjName, SObject sobjRec, Id stiId) {
        String coId, sectionId;
        Boolean isInternalJob = false;
        Boolean isTaxBasedOnCustomerAddress = false;
        if(sobjName.equalsIgnoreCase(SERVICE_ORDER_LINE_ITEM)) {
            Service_Order_Line_Item__c soliRec = (Service_Order_Line_Item__c)sobjRec;
            isInternalJob = String.isNotBlank(soliRec.Service_Order_Header__r.Job_Type__c) ? soliRec.Service_Order_Header__r.Job_Type__c.equalsIgnoreCase('Internal') : false;
            isTaxBasedOnCustomerAddress = soliRec.Service_Order_Header__r.Is_Tax_Based_On_Customer_Address__c;
            sectionId = (soliRec.Service_Order_Header__r.Provider__c != null ? soliRec.Service_Order_Header__c : soliRec.Service_Order_Header__r.CO_Header__c);
            coId = soliRec.Service_Order_Header__r.CO_Header__c;

        } else if(sobjName.equalsIgnoreCase(SOKH)) {
            Service_Order_Kit_Header__c sokhRec = (Service_Order_Kit_Header__c)sobjRec;
            isInternalJob = String.isNotBlank(sokhRec.Service_Order_Header__r.Job_Type__c) ? sokhRec.Service_Order_Header__r.Job_Type__c.equalsIgnoreCase('Internal') : false;
            isTaxBasedOnCustomerAddress = sokhRec.Service_Order_Header__r.Is_Tax_Based_On_Customer_Address__c;
            sectionId = (sokhRec.Service_Order_Header__r.Provider__c != null ? sokhRec.Service_Order_Header__c : sokhRec.Service_Order_Header__r.CO_Header__c);
            coId = sokhRec.Service_Order_Header__r.CO_Header__c;

        } else if(sobjName.equalsIgnoreCase(CO_LINE_ITEM)) {
            CO_Line_Item__c coliRec = (CO_Line_Item__c)sobjRec;
            if(coliRec.Service_Order_Line_Item__c != null && merchSOLIMap != null && merchSOLIMap.get(coliRec.Service_Order_Line_Item__c) != null) {
                Service_Order_Line_Item__c soliRec = merchSOLIMap.get(coliRec.Service_Order_Line_Item__c);
                isInternalJob = String.isNotBlank(soliRec.Service_Order_Header__r.Job_Type__c) ? soliRec.Service_Order_Header__r.Job_Type__c.equalsIgnoreCase('Internal') : false;
                isTaxBasedOnCustomerAddress = soliRec.Service_Order_Header__r.Is_Tax_Based_On_Customer_Address__c;
                sectionId = (soliRec.Service_Order_Header__r.Provider__c != null ? soliRec.Service_Order_Header__c : soliRec.Service_Order_Header__r.CO_Header__c);
            } else {
                if(COLineItemTriggerHelper.coHeaderIdToCoHeaderRecMap != null && COLineItemTriggerHelper.coHeaderIdToCoHeaderRecMap.get(coliRec.CO_Header__c) != null) {
                    isTaxBasedOnCustomerAddress = COLineItemTriggerHelper.coHeaderIdToCoHeaderRecMap.get(coliRec.CO_Header__c).Is_Tax_Based_On_Customer_Address__c;
                } else {
                    isTaxBasedOnCustomerAddress = coliRec.CO_Header__r.Is_Tax_Based_On_Customer_Address__c;
                }
                sectionId = coliRec.CO_Header__c;
            }
            coId = coliRec.CO_Header__c;
        } else if(sobjName.equalsIgnoreCase(CO_LINE_ITEM_V2)) {
            CO_Line_Item__c coliRec = (CO_Line_Item__c)sobjRec;
            if(coliRec.Service_Order_Line_Item__c != null) {
                isInternalJob = coliRec.Service_Order_Line_Item__r.Service_Order_Header__r.Job_Type__c.equalsIgnoreCase('Internal');
                isTaxBasedOnCustomerAddress = coliRec.Service_Order_Line_Item__r.Service_Order_Header__r.Is_Tax_Based_On_Customer_Address__c;
                sectionId = (coliRec.Service_Order_Line_Item__r.Service_Order_Header__r.Provider__c != null ? coliRec.Service_Order_Line_Item__r.Service_Order_Header__c : coliRec.CO_Header__c);
            } else {
                isTaxBasedOnCustomerAddress = coliRec.CO_Header__r.Is_Tax_Based_On_Customer_Address__c;
                sectionId = coliRec.CO_Header__c;
            }
            coId = coliRec.CO_Header__c;
        } else if(sobjName.equalsIgnoreCase(COKH)) {
            CO_Kit_Header__c cokhRec = (CO_Kit_Header__c)sobjRec;
            isTaxBasedOnCustomerAddress = cokhRec.CO_Header__r.Is_Tax_Based_On_Customer_Address__c;
            sectionId = coId = cokhRec.CO_Header__c;

        } else if(sobjName.equalsIgnoreCase(OPTION_FEE)) {
            Option_Fee__c ofRec = (Option_Fee__c)sobjRec;
            isTaxBasedOnCustomerAddress = ofRec.Deal_Item__r.Deal__r.Is_Tax_Based_On_Customer_Address__c && DealUtil.isOptionAndFeeTaxedSameAsUnit(ofRec);
            sectionId = coId = ofRec.Deal_Item__r.Deal__r.CO_Header__c;

        } else if(sobjName.equalsIgnoreCase(DKH)) {
            Deal_Kit_Header__c dkhRec = (Deal_Kit_Header__c) sobjRec;
            isTaxBasedOnCustomerAddress = dkhRec.Deal_Item__r.Deal__r.Is_Tax_Based_On_Customer_Address__c;
            sectionId = coId = dkhRec.Deal_Item__r.Deal__r.CO_Header__c;
        
        } else if(sobjName.equalsIgnoreCase(DUPC)) {
            Deal_Unit_Price_Cost__c dupcRec = (Deal_Unit_Price_Cost__c) sobjRec;
            isTaxBasedOnCustomerAddress = dupcRec.Deal_Item__r.Deal__r.Is_Tax_Based_On_Customer_Address__c;
            sectionId = coId = dupcRec.Deal_Item__r.Deal__r.CO_Header__c;

        } else if(sobjName.equalsIgnoreCase(DEAL_ITEM)) {
            Deal_Item__c dealItemRec = (Deal_Item__c) sobjRec;
            isTaxBasedOnCustomerAddress = dealItemRec.Deal__r.Is_Tax_Based_On_Customer_Address__c;
            sectionId = coId = dealItemRec.Deal__r.CO_Header__c;

        } else if(sobjName.equalsIgnoreCase(FI_PRODUCT)) {
            F_I_Product__c fiProdRec = (F_I_Product__c) sobjRec;
            isTaxBasedOnCustomerAddress = fiProdRec.Deal__r.Is_Tax_Based_On_Customer_Address__c;
            sectionId = coId = fiProdRec.Deal__r.CO_Header__c;

        } else if(sobjName.equalsIgnoreCase(DEAL)) {
            Deal__c dealRec = (Deal__c) sobjRec;
            isTaxBasedOnCustomerAddress = dealRec.Is_Tax_Based_On_Customer_Address__c;
            sectionId = coId = dealRec.CO_Header__c;

        } else if(sobjName.equalsIgnoreCase(DEAL_STORE)) {
            Deal__c dealRec = (Deal__c) sobjRec;
            isTaxBasedOnCustomerAddress = false;
            sectionId = coId = dealRec.CO_Header__c;

        } else if(sobjName.equalsIgnoreCase(SOPR)) {
            SO_Payment_Role__c soprRec = (SO_Payment_Role__c) sobjRec;
            isTaxBasedOnCustomerAddress = soprRec.Service_Order_Header__r.Is_Tax_Based_On_Customer_Address__c;
            sectionId = soprRec.Service_Order_Header__c;
            coId = soprRec.Service_Order_Header__r.CO_Header__c;
        }

        system.debug('sectionIdToExemptedSTIIdToExemptRecMap>> ' + sectionIdToExemptedSTIIdToExemptRecMap);
        system.debug('sectionIdToCustSTIIdToExemptRecMap>> ' + sectionIdToCustSTIIdToExemptRecMap);
        system.debug('sectionIdToStoreSTIIdToExemptRecMap>> ' + sectionIdToStoreSTIIdToExemptRecMap);
        
        String taxName;
        Decimal taxRate = 0;
        if(String.isNotBlank(sectionId)) {
            //Get Tax Override Rate - Fist find if there is any tax override for this section from tax exemption record
            if(!isInternalJob && sectionIdToExemptedSTIIdToExemptRecMap.containsKey(sectionId) && sectionIdToExemptedSTIIdToExemptRecMap.get(sectionId).containsKey(stiId)) {
                Tax_Exemption__c exemptRec = sectionIdToExemptedSTIIdToExemptRecMap.get(sectionId).get(stiId);
                taxRate = (exemptRec.Rate_Override__c != null && exemptRec.Rate_Override__c != 0 ? exemptRec.Rate_Override__c : null);
            } else if(!isTaxIncludingPricing && GeneralConfiguration.getConfigurations().Automatic_Tax_Rates__c) {
                if(isTaxBasedOnCustomerAddress && sectionIdToCustSTIIdToExemptRecMap.containsKey(sectionId) && sectionIdToCustSTIIdToExemptRecMap.get(sectionId).get(stiId) != null) {
                    taxRate = sectionIdToCustSTIIdToExemptRecMap.get(sectionId).get(stiId).Rate_Override__c;
                } else if(!isTaxBasedOnCustomerAddress && sectionIdToStoreSTIIdToExemptRecMap.containsKey(coId) && sectionIdToStoreSTIIdToExemptRecMap.get(coId).get(stiId) != null) {
                    taxRate = sectionIdToStoreSTIIdToExemptRecMap.get(coId).get(stiId).Rate_Override__c;
                }
            }
            //Get Tax Name
            if(!isTaxIncludingPricing && GeneralConfiguration.getConfigurations().Automatic_Tax_Rates__c) {
                if(isTaxBasedOnCustomerAddress && sectionIdToCustSTIIdToExemptRecMap.containsKey(sectionId) && sectionIdToCustSTIIdToExemptRecMap.get(sectionId).get(stiId) != null) {
                    taxName = sectionIdToCustSTIIdToExemptRecMap.get(sectionId).get(stiId).Description__c;
                } else if(!isTaxBasedOnCustomerAddress && sectionIdToStoreSTIIdToExemptRecMap.containsKey(coId) && sectionIdToStoreSTIIdToExemptRecMap.get(coId).get(stiId) != null) {
                    taxName = sectionIdToStoreSTIIdToExemptRecMap.get(coId).get(stiId).Description__c;
                }
            }
        }
        return new OverrideTax(taxName, taxRate);   //This will be handled later in logic when overriding taxes on manual tax rates
    }

    private static void populateTaxFields(String sobjName, SObject sobjRec, String prevTaxId, String newTaxId, Decimal rate, Decimal exemptionRate) {
        //In case of Deal tax by Invoice - Populate tax rate on record (FI product shows estimated taxes on UI)
        if(sobjName.equalsIgnoreCase(DEAL) && !isTaxIncludingPricing) {
            rate = salesTaxIdToTaxRateMap.get(newTaxId);
        }
        rate = rate != null ? rate : 0;
        exemptionRate = exemptionRate != null ? exemptionRate : 0;
        if(sobjName.equalsIgnoreCase(SERVICE_ORDER_LINE_ITEM)) {
            Service_Order_Line_Item__c soliRec = (Service_Order_Line_Item__c) sobjRec;
            soliRec.Applicable_Tax__c = (soliRec.Deal__c != null ? null : newTaxId);
            soliRec.Tax_Percent__c = (soliRec.Deal__c != null ? 0 : (rate - exemptionRate));

            if(isTaxIncludingPricing) {
                if((ServiceOrderLineItemTriggerHelper.isMoveLineItem || (soliRec.Labour_Code__c == null && soliRec.Part__c == null && COTriggerHelper.isRetainItemPrices)) && soliRec.Price_When_Tax_Included__c != null) {
                    soliRec.Kit_Price__c = (soliRec.Price_When_Tax_Included__c/(1 + soliRec.Tax_Percent__c/100)).setScale(2, RoundingMode.HALF_UP);
                } else if(soliRec.Kit_Price__c != null && isUpdatePriceWhenTaxIncluded(sobjName, soliRec, prevTaxId, exemptionRate)) {
                    soliRec.Price_When_Tax_Included__c = (soliRec.Kit_Price__c + (soliRec.Kit_Price__c * soliRec.Tax_Percent__c / 100).setScale(2, RoundingMode.HALF_UP));
                    if(ServiceOrderLineItemTriggerHelper.isInsertOperation && soliRec.Calculated_Customer_Price__c != null && soliRec.Calculated_Customer_Price__c != 0) {
                        soliRec.Calculated_Customer_Price__c = (soliRec.Calculated_Customer_Price__c + (soliRec.Calculated_Customer_Price__c * soliRec.Tax_Percent__c / 100).setScale(2, RoundingMode.HALF_UP));
                    } 
                }
            }
        } else if(sobjName.equalsIgnoreCase(OPTION_FEE)) {
            Option_Fee__c ofRec = (Option_Fee__c) sobjRec;
            Boolean isTaxChange = (COTriggerHelper.isRecalculateTaxes && ofRec.Sales_Tax_Percentage__c != (rate - exemptionRate));
            ofRec.Applicable_Tax__c = newTaxId;
            ofRec.Sales_Tax_Percentage__c = (rate - exemptionRate);

            Decimal price = OptionAndFeeTriggerHelper.OptionAndFeeNewMap.get(ofRec.Id).Price__c;
            if(isTaxIncludingPricing && COTriggerHelper.isRetainItemPrices && ofRec.Part__c == null && ofRec.Labour_Code__c == null && ofRec.Price_When_Tax_Included__c != null) {
                ofRec.Price__c = (ofRec.Price_When_Tax_Included__c / (1 + (ofRec.Sales_Tax_Percentage__c / 100))).setScale(2, RoundingMode.HALF_UP);
            } else if(isTaxChange || isUpdatePriceWhenTaxIncluded(sobjName, ofRec, prevTaxId, exemptionRate)) {
                ofRec.Price_When_Tax_Included__c = (price * (1 + ofRec.Sales_Tax_Percentage__c/100)).setScale(2, RoundingMode.HALF_UP);
            }
            
        } else if(sobjName.equalsIgnoreCase(DUPC)) {
            Deal_Unit_Price_Cost__c dupcRec = (Deal_Unit_Price_Cost__c) sobjRec;
            Boolean isTaxChange = ((prevTaxId != newTaxId) || (DealUnitPriceAndCostTriggerHelper.isCustomerPLUpdate && dupcRec.Sales_Tax_Percentage__c != (rate - exemptionRate)));
            dupcRec.Applicable_Tax__c = newTaxId;
            dupcRec.Sales_Tax_Percentage__c = (rate - exemptionRate);

            if(isTaxIncludingPricing) {
                if(dupcRec.Deal_Item__r.Is_Rideaway_Pricing_Enabled__c) {
                    dupcRec.Price__c = (dupcRec.Price_When_Tax_Included__c / (1 + (dupcRec.Sales_Tax_Percentage__c / 100))).setScale(2, RoundingMode.HALF_UP);
                } else {
                    dupcRec.Price__c = (dupcRec.Price__c != null) ? dupcRec.Price__c : 0;
                    if(!DealUnitPriceAndCostTriggerHelper.isCustomerPLUpdate) {
                        dupcRec.Price__c = (dupcRec.Price__c / (1 + (rate / 100))).setScale(2, RoundingMode.HALF_UP);
                    }
                    if(exemptionRate != 0 || isTaxChange) {
                        dupcRec.Price_When_Tax_Included__c = (dupcRec.Price__c * (1 + dupcRec.Sales_Tax_Percentage__c/100)).setScale(2, RoundingMode.HALF_UP);
                    }
                }
            }
        } else if(sobjName.equalsIgnoreCase(DEAL_ITEM)) {
            Deal_Item__c dealItemRec = (Deal_Item__c) sobjRec;
            dealItemRec.Default_Unit_Sales_Tax_Percentage__c = (rate - exemptionRate);
            if(isTaxIncludingPricing && dealItemRec.Type__c == Constants.DEAL_ITEM_TYPE_TRADE_IN && !dealItemRec.Is_Stocked_In__c && 
                DealItemTriggerHelper.dealItemOldMap != null && 
                (dealItemRec.Agreed_Value__c != DealItemTriggerHelper.dealItemOldMap.get(dealItemRec.Id).Agreed_Value__c || 
                dealItemRec.Applicable_Tax__c != DealItemTriggerHelper.dealItemOldMap.get(dealItemRec.Id).Applicable_Tax__c || 
                DealItemTriggerHelper.isCustomerPLUpdate)) {
                dealItemRec.Actual_Cash_Value__c = ((dealItemRec.Agreed_Value__c != null ? dealItemRec.Agreed_Value__c : 0) / (1 + dealItemRec.Default_Unit_Sales_Tax_Percentage__c / 100)).setScale(2, RoundingMode.HALF_UP);
            }
        } else if(sobjName.equalsIgnoreCase(FI_PRODUCT)) {
            F_I_Product__c fiProdRec = (F_I_Product__c) sobjRec;
            fiProdRec.Applicable_Tax__c = newTaxId;
            fiProdRec.Sales_Tax_Percentage__c = (rate - exemptionRate);
            if(isTaxIncludingPricing) {
                Decimal price = FIProductTriggerHelper.FIProductNewMap.get(fiProdRec.Id).Price__c;
                fiProdRec.Price_When_Tax_Included__c = (price * (1 + fiProdRec.Sales_Tax_Percentage__c/100)).setScale(2, RoundingMode.HALF_UP);
            } else if(TaxCalculation.IsEnhancedTaxCalculationApplicable) {
                totalTaxAmountForLine += (fiProdRec.Price__c * fiProdRec.Sales_Tax_Percentage__c / 100).setScale(2, RoundingMode.HALF_UP);
                fiProdRec.Sales_Tax__c = totalTaxAmountForLine;
            }
        } else if(sobjName.equalsIgnoreCase(SOPR)) {
            SO_Payment_Role__c soprRec = (SO_Payment_Role__c) sobjRec;
            soprRec.Applicable_Tax__c = newTaxId;
            soprRec.Tax__c = (rate - exemptionRate);
            if(isTaxIncludingPricing) {
                soprRec.Tax_Amount__c = (soprRec.Total_Amount__c - (soprRec.Total_Amount__c / (1 + (soprRec.Tax__c / 100))).setScale(2, RoundingMode.HALF_UP));
            } else {
                totalTaxAmountForLine += ((soprRec.Total_Amount__c * soprRec.Tax__c)/100).setScale(2, RoundingMode.HALF_UP);
                soprRec.Tax_Amount__c = totalTaxAmountForLine;
            }
        }
    }

    private static Boolean isUpdatePriceWhenTaxIncluded(String sobjName, SObject sobjRec, String oldTaxId, Decimal exemptionRate) {
        if(sobjName.equalsIgnoreCase(SERVICE_ORDER_LINE_ITEM)) {
            Service_Order_Line_Item__c soliRec = (Service_Order_Line_Item__c) sobjRec;
            return (soliRec.Price_When_Tax_Included__c == null || exemptionRate != 0 || 
            oldTaxId != soliRec.Applicable_Tax__c || 
            soliRec.Applicable_Tax__c != ServiceJobUtil.getApplicableTaxOnEntity(soliRec));
        } else if(sobjName.equalsIgnoreCase(OPTION_FEE)) {
            Option_Fee__c ofRec = (Option_Fee__c) sobjRec;
            return (ofRec.Price_When_Tax_Included__c == null || exemptionRate != 0 || 
            oldTaxId != ofRec.Applicable_Tax__c || 
            ofRec.Applicable_Tax__c != DealUtil.getApplicableTaxOnEntity(ofRec));
        }  else if(sobjName.equalsIgnoreCase(CO_LINE_ITEM)) {
            CO_Line_Item__c coliRec = (CO_Line_Item__c) sobjRec;
            return (coliRec.Price__c != null && 
            (coliRec.Price_When_Tax_Included__c == null || exemptionRate != 0 || 
            oldTaxId != coliRec.Applicable_Tax__c || 
            coliRec.Applicable_Tax__c != MerchandiseUtil.getApplicableTaxOnEntity(coliRec)));
        }
        return true;
    }

    public static List<Individual_Tax__c> calculateDealTaxesByInvoice(List<Deal__c> dealList, Map<String, List<Deal_Unit_Price_Cost__c>> dealIdToDealUnitPriceCostListMap) {
        List<Individual_Tax__c> individualTaxUpsertList = new List<Individual_Tax__c>();
        if(!isTaxIncludingPricing && dealList != null && !dealList.isEmpty()) {
            List<Individual_Tax__c> individualTaxDeleteList = new List<Individual_Tax__c>();
            Map<Id, List<Individual_Tax__c>> dealIdToExistingIndividualTaxListMap = getDealIdToIndividualTaxListMap(dealList);

            populateExemptionMap(getSectionIdsForExemptions(DEAL, dealList));
            for(Deal__c dealRec : dealList) {

                Map<Id, List<Individual_Tax__c>> existingTaxRateIdToIndividualTaxesMap = getTaxRateIdToIndividualTaxesMap(dealIdToExistingIndividualTaxListMap.get(dealRec.Id));
                Map<Id, Applicable_Taxes__c> taxRateMap = new Map<Id, Applicable_Taxes__c>();

                Map<Id, Decimal> taxCodeIdToStoreTaxableAmountMap = new Map<Id, Decimal>();
                Map<Id, Decimal> taxCodeIdToTaxableAmountMap = getTaxCodeIdToTaxableAmountMap(dealRec, dealIdToDealUnitPriceCostListMap.get(dealRec.Id), taxCodeIdToStoreTaxableAmountMap);
                dealTaxRateIdToTaxableAmountMap = getTaxRateIdToTaxableAmountMap(taxCodeIdToTaxableAmountMap, taxCodeIdToStoreTaxableAmountMap, taxRateMap);
                
                for(String taxRateId : dealTaxRateIdToTaxableAmountMap.keySet()) {
                    applyTaxRate(null, null, DEAL, dealRec, taxRateMap.get(taxRateId), individualTaxUpsertList);
                }
                for(String taxRateId : dealTaxRateIdToStoreTaxableAmountMap.keySet()) {
                    applyTaxRate(null, null, DEAL_STORE, dealRec, taxRateMap.get(taxRateId), individualTaxUpsertList);
                }
                for(Individual_Tax__c indiTaxRec : individualTaxUpsertList) {
                    List<Individual_Tax__c> indiTaxes = existingTaxRateIdToIndividualTaxesMap.get(indiTaxRec.Sales_Tax_Item__c);
                    if(indiTaxes != null && !indiTaxes.isEmpty()) {
                        indiTaxRec.Id = indiTaxes[0].Id;
                        if(indiTaxes.size() > 1) {
                            indiTaxes.remove(0);
                        } else {
                            existingTaxRateIdToIndividualTaxesMap.remove(indiTaxRec.Sales_Tax_Item__c);
                        }
                    }
                }
                for(List<Individual_Tax__c> individualTaxListToDelete : existingTaxRateIdToIndividualTaxesMap.values()) {
                    individualTaxDeleteList.addAll(individualTaxListToDelete);
                }
            }
            DMLUtility.deleteSobjectList('Individual_Tax__c', individualTaxDeleteList);
            DMLUtility.upsertSobjectList('Individual_Tax__c', individualTaxUpsertList);
        }
        return individualTaxUpsertList;
    }

    public static List<PrintCustomerOrderInvoiceCtrl.TaxDetail> setTaxDetails(Map<String, Decimal> taxNameToTaxValue) {
        List<PrintCustomerOrderInvoiceCtrl.TaxDetail> taxDetails = new List<PrintCustomerOrderInvoiceCtrl.TaxDetail>();
        for(String taxName : taxNameToTaxValue.keySet()){
            taxDetails.add(new PrintCustomerOrderInvoiceCtrl.TaxDetail(getAutoDistTaxLabelFromIndTax(taxName), taxNameToTaxValue.get(taxName)));
        }
        return taxDetails;
    }

    public static String getAutoDistTaxLabelFromIndTax(String formattedFormLabel) {
        if(String.isNotBlank(formattedFormLabel) && formattedFormLabel.contains('(AUTO-DST-TAX)')) {
            return formattedFormLabel.substringBeforeLast('-District') + formattedFormLabel.substringAfterLast('(AUTO-DST-TAX)');
        }
        return formattedFormLabel;
    }

    private static Map<Id, List<Individual_Tax__c>> getDealIdToIndividualTaxListMap(List<Deal__c> dealList) {
        Map<Id, List<Individual_Tax__c>> dealIdToIndividualTaxListMap = new Map<Id, List<Individual_Tax__c>>();
        for(Individual_Tax__c individualTaxRec : [select Deal__c, Taxable_Amount_for_Section_Header__c, Taxable_Amount__c, Tax_Rate__c, Option_Fee__r.Deal_Item__c, 
            Option_Fee__r.Deal__c, Deal_Unit_Price_Cost__r.Deal_Item__r.Deal__c, Deal_Unit_Price_Cost__r.Deal_Item__c, 
            Deal_Item__r.Deal__c, Form_Label__c, Applicable_Tax__c, Enhanced_Tax_Amount__c, 
            Sales_Tax_Item__r.Name__c from Individual_Tax__c where Deal__c IN: dealList]) {
                if(!dealIdToIndividualTaxListMap.containsKey(individualTaxRec.Deal__c)) {
                    dealIdToIndividualTaxListMap.put(individualTaxRec.Deal__c, new List<Individual_Tax__c>{individualTaxRec});
                } else {
                    dealIdToIndividualTaxListMap.get(individualTaxRec.Deal__c).add(individualTaxRec);
                }
        }
        return dealIdToIndividualTaxListMap;
    }

    private static Map<Id, List<Individual_Tax__c>> getTaxRateIdToIndividualTaxesMap(List<Individual_Tax__c> individualTaxList) {
        Map<Id, List<Individual_Tax__c>> taxRateIdToIndividualTaxesMap = new Map<Id, List<Individual_Tax__c>>();
        if(individualTaxList != null) {
            for(Individual_Tax__c individualTaxRec : individualTaxList) {
                if(!taxRateIdToIndividualTaxesMap.containsKey(individualTaxRec.Sales_Tax_Item__c)) {
                    taxRateIdToIndividualTaxesMap.put(individualTaxRec.Sales_Tax_Item__c, new List<Individual_Tax__c>{individualTaxRec});
                } else {
                    taxRateIdToIndividualTaxesMap.get(individualTaxRec.Sales_Tax_Item__c).add(individualTaxRec);
                }
            }
        }
        return taxRateIdToIndividualTaxesMap;
    }

    private static Map<Id, Decimal> getTaxCodeIdToTaxableAmountMap(Deal__c dealRec, List<Deal_Unit_Price_Cost__c> dealUnitPriceCostList, Map<Id, Decimal> taxCodeIdToStoreTaxableAmountMap) {
        Map<Id, Decimal> taxCodeIdToTaxableAmountMap = new Map<Id, Decimal>();

        Decimal unitTaxableAmount = 0;
        Decimal tradeInTaxableAmount = 0;

        if(dealUnitPriceCostList != null && !dealUnitPriceCostList.isEmpty()) {
            for(Deal_Unit_Price_Cost__c dupcRec : dealUnitPriceCostList) {
                if(dupcRec.Applicable_Tax__c != null && dupcRec.Price__c != null && dupcRec.Price__c != 0) {
                    dupcRec.Qty__c = dupcRec.Qty__c != null ? dupcRec.Qty__c : 1;
                    Decimal taxableAmount = dupcRec.Qty__c * dupcRec.Price__c;
                    if(!taxCodeIdToTaxableAmountMap.containsKey(dupcRec.Applicable_Tax__c)) {
                        taxCodeIdToTaxableAmountMap.put(dupcRec.Applicable_Tax__c, taxableAmount);
                    } else {
                        taxCodeIdToTaxableAmountMap.put(dupcRec.Applicable_Tax__c, taxCodeIdToTaxableAmountMap.get(dupcRec.Applicable_Tax__c) + taxableAmount);
                    }
                    unitTaxableAmount += taxableAmount;
                }
            }
        }
        
        for(Option_Fee__c optionFeeRec : dealRec.Options_Fees__r) {
            if(optionFeeRec.Applicable_Tax__c != null && optionFeeRec.Price__c != null && optionFeeRec.Price__c != 0) {
                optionFeeRec.Qty__c = optionFeeRec.Qty__c != null ? optionFeeRec.Qty__c : 1;
                Decimal taxableAmount = optionFeeRec.Qty__c * optionFeeRec.Price__c;
                if(dealRec.Is_Tax_Based_On_Customer_Address__c && !DealUtil.isOptionAndFeeTaxedSameAsUnit(optionFeeRec)) {
                    if(!taxCodeIdToStoreTaxableAmountMap.containsKey(optionFeeRec.Applicable_Tax__c)) {
                        taxCodeIdToStoreTaxableAmountMap.put(optionFeeRec.Applicable_Tax__c, taxableAmount);
                    } else {
                        taxCodeIdToStoreTaxableAmountMap.put(optionFeeRec.Applicable_Tax__c, taxCodeIdToTaxableAmountMap.get(optionFeeRec.Applicable_Tax__c) + taxableAmount);
                    }
                } else {
                    if(!taxCodeIdToTaxableAmountMap.containsKey(optionFeeRec.Applicable_Tax__c)) {
                        taxCodeIdToTaxableAmountMap.put(optionFeeRec.Applicable_Tax__c, taxableAmount);
                    } else {
                        taxCodeIdToTaxableAmountMap.put(optionFeeRec.Applicable_Tax__c, taxCodeIdToTaxableAmountMap.get(optionFeeRec.Applicable_Tax__c) + taxableAmount);
                    }
                }
            }
        }

        for(F_I_Product__c fiProductRec : dealRec.F_I_Products__r) {
            if(fiProductRec.Applicable_Tax__c != null && fiProductRec.Price__c != null && fiProductRec.Price__c != 0) {
                Decimal taxableAmount = fiProductRec.Price__c;
                if(!taxCodeIdToTaxableAmountMap.containsKey(fiProductRec.Applicable_Tax__c)) {
                    taxCodeIdToTaxableAmountMap.put(fiProductRec.Applicable_Tax__c, taxableAmount);
                } else {
                    taxCodeIdToTaxableAmountMap.put(fiProductRec.Applicable_Tax__c, taxCodeIdToTaxableAmountMap.get(fiProductRec.Applicable_Tax__c) + taxableAmount);
                }
            }
        }

        for(Deal_Item__c dealItemRec : dealRec.Deal_Items__r) {
            if(dealItemRec.Type__c == 'Trade In' && dealItemRec.Taxable__c && dealItemRec.Applicable_Tax__c != null && dealItemRec.Agreed_Value__c != null && dealItemRec.Agreed_Value__c != 0) {
                tradeInTaxableAmount += dealItemRec.Agreed_Value__c;
            }
        }
        Decimal exceededTradeInTaxableAmount = (tradeInTaxableAmount - unitTaxableAmount).setScale(2, RoundingMode.HALF_UP);
        Boolean limitDealTradeTax = (!isTaxIncludingPricing && GeneralConfiguration.isTradeTaxCreditCanNotExceedUnitTax() && !dealRec.Deal_Section_Trade_Only__c);
        
        List<Deal_Item__c> tradeInUpdateList = new List<Deal_Item__c>();
        for(Deal_Item__c tradeInRec : dealRec.Deal_Items__r) {
            if(tradeInRec.Type__c == 'Trade In' && tradeInRec.Taxable__c && tradeInRec.Agreed_Value__c != null) {
                tradeInRec.Agreed_Value_Taxable_Amount__c = tradeInRec.Agreed_Value__c;
                if(limitDealTradeTax && exceededTradeInTaxableAmount > 0) {
                    if(tradeInRec.Agreed_Value__c >= exceededTradeInTaxableAmount) {
                        tradeInRec.Agreed_Value_Taxable_Amount__c = tradeInRec.Agreed_Value__c - exceededTradeInTaxableAmount;
                        exceededTradeInTaxableAmount = 0;
                    } else {
                        tradeInRec.Agreed_Value_Taxable_Amount__c = 0;
                        exceededTradeInTaxableAmount = exceededTradeInTaxableAmount - tradeInRec.Agreed_Value__c;
                    }
                    tradeInUpdateList.add(tradeInRec);
                }
                if(!taxCodeIdToTaxableAmountMap.containsKey(tradeInRec.Applicable_Tax__c)) {
                    taxCodeIdToTaxableAmountMap.put(tradeInRec.Applicable_Tax__c, (tradeInRec.Agreed_Value_Taxable_Amount__c * -1));
                } else {
                    taxCodeIdToTaxableAmountMap.put(tradeInRec.Applicable_Tax__c, taxCodeIdToTaxableAmountMap.get(tradeInRec.Applicable_Tax__c) + (tradeInRec.Agreed_Value_Taxable_Amount__c * -1));
                }
            }
        }
        DealItemTriggerHelper.isForceStopTrigger = true;
        DMLUtility.updateSobjectList('Deal_Item__c', tradeInUpdateList);
        DealItemTriggerHelper.isForceStopTrigger = false;
        return taxCodeIdToTaxableAmountMap;
    }

    private static Map<Id, Decimal> getTaxRateIdToTaxableAmountMap(Map<Id, Decimal> taxCodeIdToTaxableAmountMap, Map<Id, Decimal> taxCodeIdToStoreTaxableAmountMap, Map<Id, Applicable_Taxes__c> taxRateMap) {
        Map<Id, Decimal> taxRateIdToTaxableAmountMap = new Map<Id, Decimal>();
        dealTaxRateIdToStoreTaxableAmountMap = new Map<Id, Decimal>();

        if(taxCodeIdToTaxableAmountMap != null && !taxCodeIdToTaxableAmountMap.isEmpty()) {
            Set<Id> taxCodeIdSet = new Set<Id>(taxCodeIdToTaxableAmountMap.keySet());
            taxCodeIdSet.addAll(taxCodeIdToStoreTaxableAmountMap.keySet());

            List<Applicable_Taxes__c> applicableTaxes = TaxManagementSOQLUtil.getApplicableTaxListBySalesTaxIdList(taxCodeIdSet);
            for(Applicable_Taxes__c applicableTaxRec : applicableTaxes) {
                Decimal taxableAmount = 0;
                Decimal storeTaxableAmount = 0;
                if(taxCodeIdToStoreTaxableAmountMap.get(applicableTaxRec.Sales_Tax__c) != null) {
                    if(applicableTaxRec.Sales_Tax_Item__r.Is_Automated__c) {
                        storeTaxableAmount = taxCodeIdToStoreTaxableAmountMap.get(applicableTaxRec.Sales_Tax__c);
                    } else {
                        taxableAmount += taxCodeIdToStoreTaxableAmountMap.get(applicableTaxRec.Sales_Tax__c);
                    }
                }
                if(taxCodeIdToTaxableAmountMap.get(applicableTaxRec.Sales_Tax__c) != null) {
                    taxableAmount += taxCodeIdToTaxableAmountMap.get(applicableTaxRec.Sales_Tax__c);
                }
                if(storeTaxableAmount != 0) {
                    if(!dealTaxRateIdToStoreTaxableAmountMap.containsKey(applicableTaxRec.Sales_Tax_Item__c)) {
                        dealTaxRateIdToStoreTaxableAmountMap.put(applicableTaxRec.Sales_Tax_Item__c, storeTaxableAmount);
                    } else {
                        dealTaxRateIdToStoreTaxableAmountMap.put(applicableTaxRec.Sales_Tax_Item__c, dealTaxRateIdToStoreTaxableAmountMap.get(applicableTaxRec.Sales_Tax_Item__c) + storeTaxableAmount);
                    }
                }
                if(taxableAmount != 0) {
                    if(!taxRateIdToTaxableAmountMap.containsKey(applicableTaxRec.Sales_Tax_Item__c)) {
                        taxRateIdToTaxableAmountMap.put(applicableTaxRec.Sales_Tax_Item__c, taxableAmount);
                    } else {
                        taxRateIdToTaxableAmountMap.put(applicableTaxRec.Sales_Tax_Item__c, taxRateIdToTaxableAmountMap.get(applicableTaxRec.Sales_Tax_Item__c) + taxableAmount);
                    }
                }
                taxRateMap.put(applicableTaxRec.Sales_Tax_Item__c, applicableTaxRec);
            }
        }
        return taxRateIdToTaxableAmountMap;

    }

    public static List<CO_Line_Item__c> salesTaxCalculationFromCOTrigger(List<CO_Line_Item__c> coLineItemList) {
        Map<Id, Id> recIdToApplicableTaxIdMap = new Map<Id, Id>();
        populateExemptionMap(getSectionIdsForExemptions(CO_LINE_ITEM_V2, coLineItemList));             
        setApplicableTaxes(CO_LINE_ITEM_V2, coLineItemList, null, recIdToApplicableTaxIdMap);
        
        DMLUtility.deleteSobjectList('Individual_Tax__c', [select Id from Individual_Tax__c where CO_Line_Item__c IN: coLineItemList]);

        List<Sobject> coLineItemToUpdate = new List<Sobject>();
        List<Individual_Tax__c> individualTaxToInsert = new List<Individual_Tax__c>();
        for(CO_Line_Item__c coLineItemRec : coLineItemList) {
            Id coliOldTaxId = coLineItemRec.Applicable_Tax__c;
            Id salesTaxId = recIdToApplicableTaxIdMap.get(coLineItemRec.Id);
            if(salesTaxId == null || coLineItemRec.Deal__c != null) {
                if(isTaxIncludingPricing) {
                    if((COLineItemTriggerHelper.isMoveLineItem || (coLineItemRec.Part__c == null && COTriggerHelper.isRetainItemPrices)) && coLineItemRec.Price_When_Tax_Included__c != null) {
                        coLineItemRec.Price__c = coLineItemRec.Price_When_Tax_Included__c;
                    } else if(coLineItemRec.Price__c != null) {
                        coLineItemRec.Price_When_Tax_Included__c = coLineItemRec.Price__c;
                    }
                    coLineItemToUpdate.add(coLineItemRec);
                }
                continue;
            }
            coLineItemRec.Applicable_Tax__c = salesTaxId;
            Decimal exemptionRate = getExemptionAndIndividualTaxes(CO_LINE_ITEM_V2, coLineItemRec, salesTaxId, individualTaxToInsert);
            Decimal rate = salesTaxIdToTaxRateMap.get(salesTaxId);
            rate = (rate != null ? rate : 0);
            
            Boolean isTaxRateChange = (COTriggerHelper.isRecalculateCOPLAndTax && !COTriggerHelper.isResetPricing && coLineItemRec.Tax__c != rate - exemptionRate);
            coLineItemRec.Tax__c = (rate - exemptionRate);

            if(isTaxIncludingPricing) {
                if((COLineItemTriggerHelper.isMoveLineItem || (coLineItemRec.Part__c == null && COTriggerHelper.isRetainItemPrices)) && coLineItemRec.Price_When_Tax_Included__c != null) {
                    coLineItemRec.Price__c = (coLineItemRec.Price_When_Tax_Included__c / (1 + coLineItemRec.Tax__c / 100).setScale(2, RoundingMode.HALF_UP));
                } else {
                    if(coLineItemRec.Type__c == Constants.SHOP_SUPPLY) {
                        coLineItemRec.Price_When_Tax_Included__c = (coLineItemRec.Price__c + (coLineItemRec.Price__c * rate / 100).setScale(2, RoundingMode.HALF_UP));
                        coLineItemRec.Price__c = (coLineItemRec.Price_When_Tax_Included__c / (1 + coLineItemRec.Tax__c / 100).setScale(2, RoundingMode.HALF_UP));
                    } else if(isTaxRateChange || isUpdatePriceWhenTaxIncluded(CO_LINE_ITEM, coLineItemRec, coliOldTaxId, exemptionRate)) {
                        coLineItemRec.Price_When_Tax_Included__c = (coLineItemRec.Price__c + (coLineItemRec.Price__c * coLineItemRec.Tax__c / 100).setScale(2, RoundingMode.HALF_UP));
                    }
                }
            }
            coLineItemToUpdate.add(coLineItemRec);
        }
        DMLUtility.insertSobjectList('Individual_Tax__c', individualTaxToInsert);
        return coLineItemToUpdate;
    }

    private static String getLineItemObjName(String sobjName) {
        String lineItemObjName = sobjName;
        if(sobjName != null) {
            if(sobjName.equalsIgnoreCase(SOKH)) {
                lineItemObjName = SERVICE_ORDER_LINE_ITEM;
            } else if(sobjName.equalsIgnoreCase(COKH)) {
                lineItemObjName = CO_LINE_ITEM;
            } else if(sobjName.equalsIgnoreCase(DKH)) {
                lineItemObjName = OPTION_FEE;
            }
        }
        return lineItemObjName;
    }
    
    public static Decimal getEnhancedTaxAmount(Decimal taxableAmount, Sales_Tax_Item__c stiRec) {
    	Boolean isTaxableAmountNegative = taxableAmount < 0 ? true : false;
    	taxableAmount = (taxableAmount != null ? (taxableAmount < 0 ? taxableAmount * -1 : taxableAmount) : 0).setScale(2, RoundingMode.HALF_UP);
    	
    	Decimal enhancedTaxAmount;
    	if(TaxCalculation.IsEnhancedTaxCalculationApplicable) {
    		if(taxableAmount == 0) {
    			enhancedTaxAmount = 0;
    		} else {
	    		if(stiRec.Rate_Type__c == TaxManagementService.ESCALATING_RATE) {
	    			enhancedTaxAmount = getEscalatingTaxAmount(taxableAmount, stiRec);
	    		} else if(stiRec.Rate_Type__c == TaxManagementService.TIERED_RATE) {
	    			enhancedTaxAmount = getTieredTaxAmount(taxableAmount, stiRec);
	    		}
	
	    		enhancedTaxAmount = checkMinAndMaxTaxableAmount(enhancedTaxAmount, stiRec);
	    		enhancedTaxAmount = enhancedTaxAmount != null ? enhancedTaxAmount.setScale(2, RoundingMode.HALF_UP) : 0;
    		}
    	}
    	if(isTaxableAmountNegative) {
    		enhancedTaxAmount = enhancedTaxAmount * -1;
    	}
    	return enhancedTaxAmount;
    }

    private static Decimal getFixedTaxAmount(Decimal taxableAmount, Decimal overrideTaxRate, Applicable_Taxes__c appTax) {
    	Boolean isTaxableAmountNegative = taxableAmount < 0 ? true : false;
    	taxableAmount = (taxableAmount != null ? (taxableAmount < 0 ? taxableAmount * -1 : taxableAmount) : 0).setScale(2, RoundingMode.HALF_UP);
    	
        Boolean setEnhancedTax = false;
        if(appTax.Sales_Tax_Item__r.Is_Automated__c && appTax.Maximum_Taxable_Amount__c != null && appTax.Maximum_Taxable_Amount__c != 0 && taxableAmount > appTax.Maximum_Taxable_Amount__c) {
            setEnhancedTax = true;
            taxableAmount = appTax.Maximum_Taxable_Amount__c;
        }
    	Decimal applicableTaxPercent = (overrideTaxRate != null ? overrideTaxRate : 0);
    	Decimal fixedTaxAmount = (taxableAmount * applicableTaxPercent / 100).setScale(2, RoundingMode.HALF_UP);

        Decimal limitTax;
        appTax.Sales_Tax_Item__r.Minimum_Tax_Amount__c = appTax.Sales_Tax_Item__r.Minimum_Tax_Amount__c != null ? appTax.Sales_Tax_Item__r.Minimum_Tax_Amount__c : 0;
		if(fixedTaxAmount < appTax.Sales_Tax_Item__r.Minimum_Tax_Amount__c) {
			limitTax = appTax.Sales_Tax_Item__r.Minimum_Tax_Amount__c;
		} else if(appTax.Sales_Tax_Item__r.Maximum_Tax_Amount__c != null && appTax.Sales_Tax_Item__r.Maximum_Tax_Amount__c != 0 && fixedTaxAmount > appTax.Sales_Tax_Item__r.Maximum_Tax_Amount__c) {
			limitTax = appTax.Sales_Tax_Item__r.Maximum_Tax_Amount__c;
		} else if(setEnhancedTax) {
            limitTax = fixedTaxAmount;
        }
        if(limitTax != null && isTaxableAmountNegative) {
    		limitTax = limitTax * -1;
    	}
        return limitTax;
    }
    
    private static Decimal getEscalatingTaxAmount(Decimal taxableAmount, Sales_Tax_Item__c stiRec) {
    	taxableAmount = (taxableAmount != null ? (taxableAmount < 0 ? (taxableAmount * -1) : taxableAmount) : 0).setScale(2, RoundingMode.HALF_UP);
    	
    	Decimal applicableTaxPercent;
    	if(stiRec.Max_Taxable_Amount_Tier_1__c == null || taxableAmount <= stiRec.Max_Taxable_Amount_Tier_1__c) {
			applicableTaxPercent = stiRec.Tax_Rate_Tier_1__c;
		} else if(stiRec.Max_Taxable_Amount_Tier_2__c == null || taxableAmount <= stiRec.Max_Taxable_Amount_Tier_2__c) {
			applicableTaxPercent = stiRec.Tax_Rate_Tier_2__c;
		} else {
			applicableTaxPercent = stiRec.Tax_Rate_Tier_3__c;
		}
    	
    	applicableTaxPercent = (applicableTaxPercent != null ? applicableTaxPercent : 0);
    	Decimal enhancedTaxAmount = (taxableAmount * applicableTaxPercent / 100).setScale(2, RoundingMode.HALF_UP);
		return enhancedTaxAmount;
    }
    
    private static Decimal getTieredTaxAmount(Decimal taxableAmount, Sales_Tax_Item__c stiRec) {
    	taxableAmount = (taxableAmount != null ? (taxableAmount < 0 ? (taxableAmount * -1) : taxableAmount) : 0).setScale(2, RoundingMode.HALF_UP);
    	
    	Decimal tier1TaxableAmount = 0;
    	Decimal tier2TaxableAmount = 0;
    	Decimal tier3TaxableAmount = 0;
    	
		if(stiRec.Max_Taxable_Amount_Tier_1__c == null || taxableAmount <= stiRec.Max_Taxable_Amount_Tier_1__c) {
			tier1TaxableAmount = taxableAmount;
		} else if(stiRec.Max_Taxable_Amount_Tier_2__c == null || taxableAmount <= stiRec.Max_Taxable_Amount_Tier_2__c) {
			tier1TaxableAmount = stiRec.Max_Taxable_Amount_Tier_1__c;
			tier2TaxableAmount = taxableAmount - stiRec.Max_Taxable_Amount_Tier_1__c;
		} else {
			tier1TaxableAmount = stiRec.Max_Taxable_Amount_Tier_1__c;
			tier2TaxableAmount = stiRec.Max_Taxable_Amount_Tier_2__c - stiRec.Max_Taxable_Amount_Tier_1__c;
			tier3TaxableAmount = taxableAmount - stiRec.Max_Taxable_Amount_Tier_2__c;
		}
		
		stiRec.Tax_Rate_Tier_1__c = stiRec.Tax_Rate_Tier_1__c != null ? stiRec.Tax_Rate_Tier_1__c : 0;
    	stiRec.Tax_Rate_Tier_2__c = stiRec.Tax_Rate_Tier_2__c != null ? stiRec.Tax_Rate_Tier_2__c : 0;
    	stiRec.Tax_Rate_Tier_3__c = stiRec.Tax_Rate_Tier_3__c != null ? stiRec.Tax_Rate_Tier_3__c : 0;
    	
		Decimal enhancedTaxAmount = ((tier1TaxableAmount * stiRec.Tax_Rate_Tier_1__c) / 100).setScale(2, RoundingMode.HALF_UP);
		enhancedTaxAmount += ((tier2TaxableAmount * stiRec.Tax_Rate_Tier_2__c) / 100).setScale(2, RoundingMode.HALF_UP);
		enhancedTaxAmount += ((tier3TaxableAmount * stiRec.Tax_Rate_Tier_3__c) / 100).setScale(2, RoundingMode.HALF_UP);
		
		return enhancedTaxAmount.setScale(2, RoundingMode.HALF_UP);
    }
    
    private static Decimal checkMinAndMaxTaxableAmount(Decimal enhancedTaxAmount, Sales_Tax_Item__c stiRec) {
    	stiRec.Minimum_Tax_Amount__c = stiRec.Minimum_Tax_Amount__c != null ? stiRec.Minimum_Tax_Amount__c : 0;
    	
		if(enhancedTaxAmount < stiRec.Minimum_Tax_Amount__c) {
			enhancedTaxAmount = stiRec.Minimum_Tax_Amount__c;
		} else if(stiRec.Maximum_Tax_Amount__c != null && enhancedTaxAmount > stiRec.Maximum_Tax_Amount__c) {
			enhancedTaxAmount = stiRec.Maximum_Tax_Amount__c;
		}
		return enhancedTaxAmount;
    }

    public static void applySalesTaxOnUPC(Unit_Price_Cost__c upcRec) {
        if(upcRec.Applicable_Tax__c != null && (upcRec.Customer__c != null || upcRec.Vendor__c != null)) {
            //query sales tax
            List<Applicable_Taxes__c> applicableTaxList = TaxManagementSOQLUtil.getApplicableTaxListBySalesTaxIdList(new List<Id>{upcRec.Applicable_Tax__c});
            Map<Id, Tax_Exemption__c> stiIdToTaxExemptRecMap = new Map<Id, Tax_Exemption__c>();
            Map<Id, Sales_Tax_Item__c> automatedSTIIdToSTIMap = new Map<Id, Sales_Tax_Item__c>();
            if(upcRec.Customer__c != null) {
                Set<Id> automatedSTIIdSet = new Set<Id>();
                for(Applicable_Taxes__c tax : applicableTaxList) {
                    if(tax.Sales_Tax_Item__r.Is_Automated__c) {
                        automatedSTIIdSet.add(tax.Sales_Tax_Item__c);
                    }
                }
                if(!automatedSTIIdSet.isEmpty()) {
                    Id accTypeId = [Select Account_Type__c FROM Account WHERE Id =: upcRec.Customer__c].Account_Type__c;
                    if(accTypeId != null) {
                        List<Tax_Exemption__c> taxExemptions = [Select Rate_Override__c, Sales_Tax_Item__c FROM Tax_Exemption__c WHERE Account_Type__c =: accTypeId];
                        for(Tax_Exemption__c taxExemption : taxExemptions) {
                            stiIdToTaxExemptRecMap.put(taxExemption.Sales_Tax_Item__c, taxExemption);
                            if(automatedSTIIdSet.contains(taxExemption.Sales_Tax_Item__c)) {
                                automatedSTIIdSet.remove(taxExemption.Sales_Tax_Item__c);
                            }
                        }
                    }
                    if(!automatedSTIIdSet.isEmpty()) {
                        for(Sales_Tax_Item__c sti : Customer_Service.getCustomerTaxesByAddress(upcRec.Customer__c)) {
                            automatedSTIIdToSTIMap.put(sti.Id, sti);
                        }
                    }
                }
            }
            if(upcRec.Id == null) {
                DMLUtility.insertSobjectList('Unit_Price_Cost__c', upcRec);
            }
            system.debug('stiIdToTaxExemptRecMap>>> ' + stiIdToTaxExemptRecMap);
            system.debug('automatedSTIIdToSTIMap>>> ' + automatedSTIIdToSTIMap);
            List<Individual_Tax__c> individualTaxInsertList = new List<Individual_Tax__c>();
            List<Unit_Price_Cost__c> upcUpdateList = new List<Unit_Price_Cost__c>();

            Decimal taxRate = 0;
            for(Applicable_Taxes__c apptaxRec : applicableTaxList) {
                Decimal overriddenTaxRate;
                String overriddenTaxName;
                if(stiIdToTaxExemptRecMap.get(apptaxRec.Sales_Tax_Item__c) != null) {
                    Decimal exemptRateOverride = stiIdToTaxExemptRecMap.get(apptaxRec.Sales_Tax_Item__c).Rate_Override__c;
                    if(exemptRateOverride != null && exemptRateOverride != 0) {
                        overriddenTaxRate = exemptRateOverride;
                    }
                } else if(apptaxRec.Sales_Tax_Item__r.Is_Automated__c) {
                    Sales_Tax_Item__c automatedSTI = (automatedSTIIdToSTIMap.containsKey(apptaxRec.Sales_Tax_Item__c) ? 
                    automatedSTIIdToSTIMap.get(apptaxRec.Sales_Tax_Item__c) : apptaxRec.Sales_Tax_Item__r);
                    overriddenTaxRate = automatedSTI.Rate__c;
                    overriddenTaxName = automatedSTI.Automated_Tax_Rate_Name__c;
                } else {
                    overriddenTaxRate = 0;
                }
                if(overriddenTaxRate != null) {
                    Individual_Tax__c indTaxRec = createIndividualTaxRec(UPC, upcRec, apptaxRec, new OverrideTax(overriddenTaxName, overriddenTaxRate));
                    if((indTaxRec.Tax_Rate__c != null && indTaxRec.Tax_Rate__c != 0) || (indTaxRec.Enhanced_Tax_Amount__c != null && indTaxRec.Enhanced_Tax_Amount__c != 0)) {
                        individualTaxInsertList.add(indTaxRec);
                    }
                    if(indTaxRec.Tax_Rate__c != null) taxRate += indTaxRec.Tax_Rate__c;
                }
            }
            if(GeneralConfiguration.getTaxIncludingPricing()) {
                upcUpdateList.add(new Unit_Price_Cost__c(Id = upcRec.Id, Tax__c = taxRate));
            }
            DMLUtility.insertSobjectList('Individual_Tax__c', individualTaxInsertList);
            UnitPriceAndCostTriggerHelper.isForceStopTrigger = true;
            DMLUtility.updateSobjectList('Unit_Price_Cost__c', upcUpdateList);
            UnitPriceAndCostTriggerHelper.isForceStopTrigger = false;
        }
    }

    private class OverrideTax {
        String taxName;
        Decimal taxRate;

        public OverrideTax(String name, Decimal rate) {
            this.taxName = name;
            this.taxRate = rate;
        }
    }
}