public with sharing class StampDutyService {
    public static final string SINGLE_RATE = 'Single rate';
    public static final string TIERED_RATE = 'Tiered rate'; 
    public static final string ESCALATING_RATE = 'Escalating rate';
    public static final string WA_SPECIAL_RATE = 'WA special rate';

    public static List<StampDuty> getAllStampDutyList() {
		List<StampDuty> sdWrapperObjList = new List<StampDuty>();
		for(Stamp_Duty_Calculators__c stampDutyRec : SOQLUtility.getAllStampDutyList()) {
			sdWrapperObjList.add(new StampDuty(stampDutyRec));
		}
        return sdWrapperObjList;
    }

    public static void deleteStampDutyById(String recordId) {
        List<Stamp_Duty_Calculators__c> stampDutyList = [SELECT Id, Default__c FROM Stamp_Duty_Calculators__c WHERE Id = :recordId];
        if(!stampDutyList.isEmpty()) {
            if(stampDutyList[0].Default__c) {
                throw new BlackPurlException('Cannot delete the default calculator.');
            }
            DMLUtility.deleteSobjectList('Stamp_Duty_Calculators__c', stampDutyList[0]);
        }
    }
   
    public static void setRecordOrDefaultConfiguration() {
    	List<Stamp_Duty_Calculators__c> stampDutyCalculationRecordList = new List<Stamp_Duty_Calculators__c>();
        stampDutyCalculationRecordList.add(new Stamp_Duty_Calculators__c(Name__c = 'Exempt from stamp duty', Calculation_Method__c = SINGLE_RATE, L1_Rate__c = 0.000 ,  L1_Per__c = 0.01, Active__c = true));
        stampDutyCalculationRecordList.add(new Stamp_Duty_Calculators__c(Name__c = 'NSW - All dutiable units', Calculation_Method__c = TIERED_RATE, L1_Value__c = 44999.99, L1_Rate__c = 3.000,  L1_Per__c = 100.00,
                                                                            L2_Rate__c = 5.000,  L2_Per__c = 100.00, Active__c = true));
        stampDutyCalculationRecordList.add(new Stamp_Duty_Calculators__c(Name__c = 'QLD - Hybrid, Electric', Calculation_Method__c = ESCALATING_RATE, L1_Value__c = 100000.00, L1_Rate__c = 2.000 ,  L1_Per__c = 100.00,
                                                                            L2_Rate__c = 4.000,  L2_Per__c = 100.00, Active__c = true));
        stampDutyCalculationRecordList.add(new Stamp_Duty_Calculators__c(Name__c = 'QLD - 1-4 cylinders, 2 rotors, steam', Calculation_Method__c = ESCALATING_RATE, L1_Value__c = 100000.00, L1_Rate__c = 3.000,  L1_Per__c = 100.00,
                                                                            L2_Rate__c = 5.000 ,  L2_Per__c = 100.00, Active__c = true));
        stampDutyCalculationRecordList.add(new Stamp_Duty_Calculators__c(Name__c = 'QLD - 5-6 cylinders, 3 rotors', Calculation_Method__c = ESCALATING_RATE, L1_Value__c = 100000.00, L1_Rate__c = 3.500,  L1_Per__c = 100.00,
                                                                            L2_Rate__c = 5.500 ,  L2_Per__c = 100.00, Active__c = true));                                                                    
        stampDutyCalculationRecordList.add(new Stamp_Duty_Calculators__c(Name__c = 'QLD - 7+ cylinders', Calculation_Method__c = ESCALATING_RATE, L1_Value__c = 100000.00, L1_Rate__c = 4.000,  L1_Per__c = 100.00,
                                                                            L2_Rate__c = 6.000 ,  L2_Per__c = 100.00, Active__c = true));                                                                    
        stampDutyCalculationRecordList.add(new Stamp_Duty_Calculators__c(Name__c = 'QLD - Hybrid, Electric over 4.5 tonnes', Calculation_Method__c = SINGLE_RATE, L1_Rate__c = 2.000 ,  L1_Per__c = 100.00, Active__c = true));
        stampDutyCalculationRecordList.add(new Stamp_Duty_Calculators__c(Name__c = 'QLD - 1-4 cylinders, 2 rotors, steam, over 4.5 tonnes', Calculation_Method__c = SINGLE_RATE, L1_Rate__c = 3.000 ,  L1_Per__c = 100.00, Active__c = true));
        stampDutyCalculationRecordList.add(new Stamp_Duty_Calculators__c(Name__c = 'QLD - 5-6 cylinders, 3 rotors, over 4.5 tonnes', Calculation_Method__c = SINGLE_RATE, L1_Rate__c = 3.500 ,  L1_Per__c = 100.00, Active__c = true));
        stampDutyCalculationRecordList.add(new Stamp_Duty_Calculators__c(Name__c = 'QLD - 7+ cylinders, over 4.5 tonnes', Calculation_Method__c = SINGLE_RATE, L1_Rate__c = 4.000 ,  L1_Per__c = 100.00, Active__c = true));
        stampDutyCalculationRecordList.add(new Stamp_Duty_Calculators__c(Name__c = 'QLD - Conditional registered units', Calculation_Method__c = SINGLE_RATE, Minimum__c = 25.00, Maximum__c = 25.00, L1_Rate__c = 0.000 ,  L1_Per__c = 100.00, Active__c = true));
        stampDutyCalculationRecordList.add(new Stamp_Duty_Calculators__c(Name__c = 'SA - Non commercial unit', Calculation_Method__c = TIERED_RATE, Minimum__c = 5.00, L1_Value__c = 1000.00, L1_Rate__c = 1.000,  L1_Per__c = 100.00,
                                                                            L2_value__c = 2000.00, L2_Rate__c = 2.000,  L2_Per__c = 100.00, L3_Value__c = 3000.00, L3_Rate__c = 3.000,  L3_Per__c = 100.00,
                                                                            L4_Rate__c = 4.000,  L4_Per__c = 100.00, Active__c = true));
        stampDutyCalculationRecordList.add(new Stamp_Duty_Calculators__c(Name__c = 'SA - Commercial unit', Calculation_Method__c = TIERED_RATE, L1_Value__c = 1000.00, L1_Rate__c = 1.000,  L1_Per__c = 100.00,
                                                                            L2_value__c = 2000.00, L2_Rate__c = 2.000,  L2_Per__c = 100.00, L3_Rate__c = 3.000,  L3_Per__c = 100.00, Active__c = true));
        stampDutyCalculationRecordList.add(new Stamp_Duty_Calculators__c(Name__c = 'TAS- Passenger vehicles', Calculation_Method__c = TIERED_RATE, Minimum__c = 20.00, L1_Value__c = 600.00, L1_Rate__c = 3.333,  L1_Per__c = 600.00,
                                                                            L2_value__c = 34999.99, L2_Rate__c = 3.000,  L2_Per__c = 100.00, L3_Value__c = 39999.99, L3_Rate__c = 11.000,  L3_Per__c = 100.00,
                                                                            L4_Rate__c = 4.000,  L4_Per__c = 100.00, Active__c = true));
        stampDutyCalculationRecordList.add(new Stamp_Duty_Calculators__c(Name__c = 'TAS- Heavy vehicles - over 4.5 tonnes', Calculation_Method__c = SINGLE_RATE, Minimum__c = 20.00, L1_Rate__c = 1.000 ,  L1_Per__c = 100.00, Active__c = true));
        stampDutyCalculationRecordList.add(new Stamp_Duty_Calculators__c(Name__c = 'TAS- MC & Other vehicles - 4.5 tonnes and under', Calculation_Method__c = SINGLE_RATE, Minimum__c = 20.00, L1_Rate__c = 3.000 ,  L1_Per__c = 100.00, Active__c = true));
        stampDutyCalculationRecordList.add(new Stamp_Duty_Calculators__c(Name__c = 'VIC - Low emmission passenger vehicle', Calculation_Method__c = SINGLE_RATE, L1_Rate__c = 4.200 ,  L1_Per__c = 200.00, Active__c = true));
        stampDutyCalculationRecordList.add(new Stamp_Duty_Calculators__c(Name__c = 'VIC - Primary producer passenger vehicle', Calculation_Method__c = SINGLE_RATE, L1_Rate__c = 4.200 ,  L1_Per__c = 200.00, Active__c = true));
        stampDutyCalculationRecordList.add(new Stamp_Duty_Calculators__c(Name__c = 'VIC - Passenger vehicle new or used', Calculation_Method__c = ESCALATING_RATE, L1_Value__c = 76950.00, L1_Rate__c = 4.200,  L1_Per__c = 200.00,
                                                                            L2_value__c = 100000.00, L2_Rate__c = 5.200,  L2_Per__c = 200.00, L3_Value__c = 150000.00, L3_Rate__c = 7.000,  L3_Per__c = 200.00,
                                                                            L4_Rate__c = 9.000,  L4_Per__c = 200.00, Active__c = true));
        stampDutyCalculationRecordList.add(new Stamp_Duty_Calculators__c(Name__c = 'VIC - Non passenger and MC new', Calculation_Method__c = SINGLE_RATE, L1_Rate__c = 2.700 ,  L1_Per__c = 200.00, Active__c = true));
        stampDutyCalculationRecordList.add(new Stamp_Duty_Calculators__c(Name__c = 'VIC - Heavy trailer/Non passenger and MC used', Calculation_Method__c = SINGLE_RATE, L1_Rate__c = 4.200 ,  L1_Per__c = 200.00, Active__c = true));
        stampDutyCalculationRecordList.add(new Stamp_Duty_Calculators__c(Name__c = 'ACT - Grade A (0-130 CO2/km)', Calculation_Method__c = SINGLE_RATE, L1_Rate__c = 0.000 ,  L1_Per__c = 0.01, Active__c = true));
        stampDutyCalculationRecordList.add(new Stamp_Duty_Calculators__c(Name__c = 'ACT - Grade B (131-175 CO2/km)', Calculation_Method__c = TIERED_RATE, L1_Value__c = 44999.99, L1_Rate__c = 1.000,  L1_Per__c = 100.00,
                                                                            L2_Rate__c = 2.000,  L2_Per__c = 100.00, Active__c = true));
        stampDutyCalculationRecordList.add(new Stamp_Duty_Calculators__c(Name__c = 'ACT - Grade C (176-220 CO2/km)', Calculation_Method__c = TIERED_RATE, L1_Value__c = 44999.99, L1_Rate__c = 3.050,  L1_Per__c = 100.00,
                                                                            L2_Rate__c = 5.110,  L2_Per__c = 100.00, Active__c = true));
        stampDutyCalculationRecordList.add(new Stamp_Duty_Calculators__c(Name__c = 'ACT - Grade D (200+ CO2/km)', Calculation_Method__c = TIERED_RATE, L1_Value__c = 44999.99, L1_Rate__c = 4.250,  L1_Per__c = 100.00,
                                                                            L2_Rate__c = 6.820,  L2_Per__c = 100.00, Active__c = true));
        stampDutyCalculationRecordList.add(new Stamp_Duty_Calculators__c(Name__c = 'ACT - Non-rated vehicles', Calculation_Method__c = TIERED_RATE, L1_Value__c = 44999.99, L1_Rate__c = 3.000,  L1_Per__c = 100.00,
                                                                            L2_Rate__c = 5.000,  L2_Per__c = 100.00, Active__c = true));
        stampDutyCalculationRecordList.add(new Stamp_Duty_Calculators__c(Name__c = 'NT - All dutiable units', Calculation_Method__c = SINGLE_RATE, L1_Rate__c = 3.000 ,  L1_Per__c = 100.00, Active__c = true));
        stampDutyCalculationRecordList.add(new Stamp_Duty_Calculators__c(Name__c = 'WA - Gross mass over 4.5 tonnes', Calculation_Method__c = SINGLE_RATE, L1_Rate__c = 3.000 ,  L1_Per__c = 0.01, Active__c = true));                                                        
        stampDutyCalculationRecordList.add(new Stamp_Duty_Calculators__c(Name__c = 'WA - Light vehicles', Calculation_Method__c = WA_SPECIAL_RATE, L1_Value__c = 25000.00, L1_Rate__c = 2.750,  L1_Per__c = 0.01,
                                                                            L2_value__c = 50000.00, L2_Rate__c = 0.000,  L2_Per__c = 0.01, L3_Rate__c = 6.500,  L3_Per__c = 0.01, Active__c = true));
        DMLUtility.insertSobjectList('Stamp_Duty_Calculators__c', stampDutyCalculationRecordList);

        List<Business_Profile__c> businessProfileRec = [SELECT Id, Business_Country__r.Name__c, Business_State__r.Display_Name__c FROM Business_Profile__c WHERE Business_Country__r.Name__c = 'Australia' ORDER BY CreatedDate Desc limit 1];
        if(!businessProfileRec.isEmpty()){
            String stampDutyName = 'QLD - 1-4 cylinders, 2 rotors, steam';
            if(businessProfileRec[0].Business_State__r.Display_Name__c == 'NSW'){
                stampDutyName = 'NSW - All dutiable units';
            } else if(businessProfileRec[0].Business_State__r.Display_Name__c == 'QLD'){
                stampDutyName = 'QLD - 1-4 cylinders, 2 rotors, steam';
            } else if(businessProfileRec[0].Business_State__r.Display_Name__c == 'SA'){
                stampDutyName = 'SA - Non commercial unit';
            } else if(businessProfileRec[0].Business_State__r.Display_Name__c == 'TAS'){
                stampDutyName = 'TAS- Passenger vehicles';
            } else if(businessProfileRec[0].Business_State__r.Display_Name__c == 'VIC'){
                stampDutyName = 'VIC - Non passenger and MC new';
            } else if(businessProfileRec[0].Business_State__r.Display_Name__c == 'ACT'){
                stampDutyName = 'ACT - Non-rated vehicles';
            } else if(businessProfileRec[0].Business_State__r.Display_Name__c == 'NT'){
                stampDutyName = 'NT - All dutiable units';
            } else if(businessProfileRec[0].Business_State__r.Display_Name__c == 'WA'){
                stampDutyName = 'WA - Light vehicles';
            }
            
            List<Stamp_Duty_Calculators__c> stampDutyRecordList = [Select Id, Default__c FROM Stamp_Duty_Calculators__c WHERE Name__c = :stampDutyName LIMIT 1];
            if(!stampDutyRecordList.isEmpty()){
                stampDutyRecordList[0].Default__c = true;
                DMLUtility.updateSobjectList('Stamp_Duty_Calculators__c', stampDutyRecordList[0]);
            }
        }
    }

    public static void saveStampDutyRecord(String stampDutyRecJson) {
        StampDuty stampDutyObj = (StampDuty) System.JSON.deserialize(stampDutyRecJson, StampDuty.class);
        Stamp_Duty_Calculators__c stampdutyRecord = new Stamp_Duty_Calculators__c();
        if(stampDutyObj.Id != null) {
            stampdutyRecord.Id = stampDutyObj.Id;
        }
        stampdutyRecord.Name__c = stampDutyObj.Name;
        stampdutyRecord.Calculation_Method__c = stampDutyObj.CalculationMethod;
        stampdutyRecord.Active__c = stampDutyObj.IsActive;
        stampdutyRecord.Default__c = stampDutyObj.IsDefault;
        stampdutyRecord.Maximum__c = stampDutyObj.Maximum != null ? stampDutyObj.Maximum.setScale(2, RoundingMode.HALF_UP) : null;
        stampdutyRecord.Minimum__c = stampDutyObj.Minimum != null ? stampDutyObj.Minimum.setScale(2, RoundingMode.HALF_UP) : 0;
        stampdutyRecord.L1_Rate__c = stampDutyObj.L1Rate != null ? stampDutyObj.L1Rate.setScale(4, RoundingMode.HALF_UP) : 0;
        stampdutyRecord.L2_Rate__c = stampDutyObj.L2Rate != null ? stampDutyObj.L2Rate.setScale(4, RoundingMode.HALF_UP) : null;
        stampdutyRecord.L3_Rate__c = stampDutyObj.L3Rate != null ? stampDutyObj.L3Rate.setScale(4, RoundingMode.HALF_UP) : null;
        stampdutyRecord.L4_Rate__c = stampDutyObj.L4Rate != null ? stampDutyObj.L4Rate.setScale(4, RoundingMode.HALF_UP) : null;
        stampdutyRecord.L1_Per__c = stampDutyObj.L1Per != null ? stampDutyObj.L1Per.setScale(2, RoundingMode.HALF_UP) : 0;
        stampdutyRecord.L2_Per__c = stampDutyObj.L2Per != null ? stampDutyObj.L2Per.setScale(2, RoundingMode.HALF_UP) : null;
        stampdutyRecord.L3_Per__c = stampDutyObj.L3Per != null ? stampDutyObj.L3Per.setScale(2, RoundingMode.HALF_UP) : null;
        stampdutyRecord.L4_Per__c = stampDutyObj.L4Per != null ? stampDutyObj.L4Per.setScale(2, RoundingMode.HALF_UP) : null;
        stampdutyRecord.L1_Value__c = stampDutyObj.L1Value != null ? stampDutyObj.L1Value.setScale(2, RoundingMode.HALF_UP) : null;
        stampdutyRecord.L2_Value__c = stampDutyObj.L2Value != null ? stampDutyObj.L2Value.setScale(2, RoundingMode.HALF_UP) : null;
        stampdutyRecord.L3_Value__c = stampDutyObj.L3Value != null ? stampDutyObj.L3Value.setScale(2, RoundingMode.HALF_UP) : null;
        stampdutyRecord.L4_Value__c = stampDutyObj.L4Value != null ? stampDutyObj.L4Value.setScale(2, RoundingMode.HALF_UP) : null;
    
        if(stampdutyRecord.Default__c) {
            List<Stamp_Duty_Calculators__c> stampDutyList = [SELECT Id, Default__c FROM Stamp_Duty_Calculators__c WHERE Default__c = true];
            for(Stamp_Duty_Calculators__c stamDutyRec : stampDutyList){
                stamDutyRec.Default__c = false;
            }
            if(!stampDutyList.isEmpty()){
                DMLUtility.updateSobjectList('Stamp_Duty_Calculators__c', stampDutyList);
            }
        }
        DMLUtility.upsertSobjectList('Stamp_Duty_Calculators__c', stampdutyRecord);
    }

    private static Decimal roundUpBasedOnPer(Decimal value, Decimal per) {
        if(per == null || per == 0) per = 1;
        return (Math.ceil(value / per) * per).setScale(2);
    }

    private static Decimal roundDownToNearest5Cents(Decimal value) {
        return (Math.floor(value * 20) / 20).setScale(2);
    }

    private static Decimal applyMinMax(Decimal value, Stamp_Duty_Calculators__c stampDutyCalRec) {
        stampDutyCalRec.Minimum__c = stampDutyCalRec.Minimum__c != null ? stampDutyCalRec.Minimum__c : 0;
        if (value < stampDutyCalRec.Minimum__c) {
            return stampDutyCalRec.Minimum__c;
        } else if (stampDutyCalRec.Maximum__c != null && value > stampDutyCalRec.Maximum__c) {
            return stampDutyCalRec.Maximum__c;
        }
        return value;
    }

    public static Decimal calculateSingleRateStampDuty(Decimal baseValue, Stamp_Duty_Calculators__c stampDutyCalRec) {
        stampDutyCalRec.L1_Per__c = stampDutyCalRec.L1_Per__c != null ? stampDutyCalRec.L1_Per__c : 100;
        Decimal roundedBaseValue = roundUpBasedOnPer(baseValue, stampDutyCalRec.L1_Per__c);
        stampDutyCalRec.L1_Rate__c = stampDutyCalRec.L1_Rate__c != null ? stampDutyCalRec.L1_Rate__c : 0;
        Decimal total = roundedBaseValue * (stampDutyCalRec.L1_Rate__c / 100);
        total = roundDownToNearest5Cents(total.setScale(2, RoundingMode.HALF_UP));
        total = applyMinMax(total, stampDutyCalRec);
        return total;
    }

    public static Decimal calculateEscalatingRateStampDuty(Decimal baseValue, Stamp_Duty_Calculators__c stampDutyCalRec) {

        Decimal applicableRate;
        Decimal applicablePer;
    	if(stampDutyCalRec.L1_Value__c == null || baseValue <= stampDutyCalRec.L1_Value__c) {
			applicableRate = stampDutyCalRec.L1_Rate__c != null ? stampDutyCalRec.L1_Rate__c : 0;
            applicablePer = stampDutyCalRec.L1_Per__c != null ? stampDutyCalRec.L1_Per__c : 100;
		} else if(stampDutyCalRec.L2_Value__c == null || baseValue <= stampDutyCalRec.L2_Value__c) {
			applicableRate = stampDutyCalRec.L2_Rate__c != null ? stampDutyCalRec.L2_Rate__c : 0;
            applicablePer = stampDutyCalRec.L2_Per__c != null ? stampDutyCalRec.L2_Per__c : 100;
		} else if(stampDutyCalRec.L3_Value__c == null || baseValue <= stampDutyCalRec.L3_Value__c) {
			applicableRate = stampDutyCalRec.L3_Rate__c != null ? stampDutyCalRec.L3_Rate__c : 0;
            applicablePer = stampDutyCalRec.L3_Per__c != null ? stampDutyCalRec.L3_Per__c : 100;
		} else {
			applicableRate = stampDutyCalRec.L4_Rate__c != null ? stampDutyCalRec.L4_Rate__c : 0;
            applicablePer = stampDutyCalRec.L4_Per__c != null ? stampDutyCalRec.L4_Per__c : 100;
		}


        Decimal roundedBaseValue = roundUpBasedOnPer(baseValue, applicablePer);
        Decimal total = roundedBaseValue * (applicableRate / 100);
        total = roundDownToNearest5Cents(total.setScale(2, RoundingMode.HALF_UP));
        total = applyMinMax(total, stampDutyCalRec);
        return total;
    }

    public static Decimal calculateTieredRateStampDuty(Decimal baseValue, Stamp_Duty_Calculators__c stampDutyCalRec) {
        Decimal tier1Amount = 0;
    	Decimal tier2Amount = 0;
    	Decimal tier3Amount = 0;
        Decimal tier4Amount = 0;
    	
		if(stampDutyCalRec.L1_Value__c == null || baseValue <= stampDutyCalRec.L1_Value__c) {
			tier1Amount = baseValue;
		} else if(stampDutyCalRec.L2_Value__c == null || baseValue <= stampDutyCalRec.L2_Value__c) {
			tier1Amount = stampDutyCalRec.L1_Value__c;
			tier2Amount = baseValue - stampDutyCalRec.L1_Value__c;
		} else if(stampDutyCalRec.L3_Value__c == null || baseValue <= stampDutyCalRec.L3_Value__c) {
			tier1Amount = stampDutyCalRec.L1_Value__c;
            tier2Amount = stampDutyCalRec.L2_Value__c - stampDutyCalRec.L1_Value__c;
			tier3Amount = baseValue - stampDutyCalRec.L2_Value__c;
		} else {
			tier1Amount = stampDutyCalRec.L1_Value__c;
			tier2Amount = stampDutyCalRec.L2_Value__c - stampDutyCalRec.L1_Value__c;
            tier3Amount = stampDutyCalRec.L3_Value__c - stampDutyCalRec.L2_Value__c;
			tier4Amount = baseValue - stampDutyCalRec.L3_Value__c;
		}
		
		stampDutyCalRec.L1_Rate__c = stampDutyCalRec.L1_Rate__c != null ? stampDutyCalRec.L1_Rate__c : 0;
    	stampDutyCalRec.L2_Rate__c = stampDutyCalRec.L2_Rate__c != null ? stampDutyCalRec.L2_Rate__c : 0;
    	stampDutyCalRec.L3_Rate__c = stampDutyCalRec.L3_Rate__c != null ? stampDutyCalRec.L3_Rate__c : 0;
        stampDutyCalRec.L4_Rate__c = stampDutyCalRec.L4_Rate__c != null ? stampDutyCalRec.L4_Rate__c : 0;
    	
        stampDutyCalRec.L1_Per__c = stampDutyCalRec.L1_Per__c != null ? stampDutyCalRec.L1_Per__c : 100;
    	stampDutyCalRec.L2_Per__c = stampDutyCalRec.L2_Per__c != null ? stampDutyCalRec.L2_Per__c : 100;
    	stampDutyCalRec.L3_Per__c = stampDutyCalRec.L3_Per__c != null ? stampDutyCalRec.L3_Per__c : 100;
        stampDutyCalRec.L4_Per__c = stampDutyCalRec.L4_Per__c != null ? stampDutyCalRec.L4_Per__c : 100;
    	

		Decimal total = ((roundUpBasedOnPer(tier1Amount, stampDutyCalRec.L1_Per__c) * stampDutyCalRec.L1_Rate__c) / 100);
		total += ((roundUpBasedOnPer(tier2Amount, stampDutyCalRec.L2_Per__c) * stampDutyCalRec.L2_Rate__c) / 100);
        total += ((roundUpBasedOnPer(tier3Amount, stampDutyCalRec.L3_Per__c) * stampDutyCalRec.L3_Rate__c) / 100);
        total += ((roundUpBasedOnPer(tier4Amount, stampDutyCalRec.L4_Per__c) * stampDutyCalRec.L4_Rate__c) / 100);
        total = roundDownToNearest5Cents(total.setScale(2, RoundingMode.HALF_UP));
        total = applyMinMax(total, stampDutyCalRec);
        return total;
    }

    public static Decimal calculateWASpecialRateStampDuty(Decimal baseValue, Stamp_Duty_Calculators__c stampDutyCalRec) {
        Decimal applicableRate;
        Decimal applicablePer;
    	if(stampDutyCalRec.L1_Value__c == null || baseValue <= stampDutyCalRec.L1_Value__c) {
			applicableRate = stampDutyCalRec.L1_Rate__c != null ? stampDutyCalRec.L1_Rate__c : 0;
            applicablePer = stampDutyCalRec.L1_Per__c != null ? stampDutyCalRec.L1_Per__c : 100;
		} else if(stampDutyCalRec.L2_Value__c == null || baseValue <= stampDutyCalRec.L2_Value__c) {
            applicableRate = (stampDutyCalRec.L1_Rate__c + ((baseValue - stampDutyCalRec.L1_Value__c) / 6666.66)).setScale(2, RoundingMode.HALF_UP);
            applicablePer = stampDutyCalRec.L2_Per__c != null ? stampDutyCalRec.L2_Per__c : 100;
		} else if(stampDutyCalRec.L3_Value__c == null || baseValue <= stampDutyCalRec.L3_Value__c) {
			applicableRate = stampDutyCalRec.L3_Rate__c != null ? stampDutyCalRec.L3_Rate__c : 0;
            applicablePer = stampDutyCalRec.L3_Per__c != null ? stampDutyCalRec.L3_Per__c : 100;
		} else {
			applicableRate = stampDutyCalRec.L4_Rate__c != null ? stampDutyCalRec.L4_Rate__c : 0;
            applicablePer = stampDutyCalRec.L4_Per__c != null ? stampDutyCalRec.L4_Per__c : 100;
		}


        Decimal roundedBaseValue = roundUpBasedOnPer(baseValue, applicablePer);
        Decimal total = (roundedBaseValue * applicableRate) / 100;
        total = roundDownToNearest5Cents(total.setScale(2, RoundingMode.HALF_UP));
        total = applyMinMax(total, stampDutyCalRec);
        return total;
    }

    public static Decimal getCalculatedStampDuty(Deal_Item__c dealItemRec, Decimal baseValue) {
        Decimal stampDuty = 0;
        if(dealItemRec.Stamp_Duty_Calculators__c == null) {
            return stampDuty;
        }
        
        if(dealItemRec.Stamp_Duty_Calculators__r.Calculation_Method__c == SINGLE_RATE) {
            stampDuty = calculateSingleRateStampDuty(baseValue, dealItemRec.Stamp_Duty_Calculators__r);
        } else if(dealItemRec.Stamp_Duty_Calculators__r.Calculation_Method__c == ESCALATING_RATE) {
            stampDuty = calculateEscalatingRateStampDuty(baseValue, dealItemRec.Stamp_Duty_Calculators__r);
        } else if(dealItemRec.Stamp_Duty_Calculators__r.Calculation_Method__c == TIERED_RATE) {
            stampDuty = calculateTieredRateStampDuty(baseValue, dealItemRec.Stamp_Duty_Calculators__r);
        } else if(dealItemRec.Stamp_Duty_Calculators__r.Calculation_Method__c == WA_SPECIAL_RATE) {
            stampDuty = calculateWASpecialRateStampDuty(baseValue, dealItemRec.Stamp_Duty_Calculators__r);
        }
        return stampDuty;
    }
}