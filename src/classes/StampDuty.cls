public with sharing class StampDuty {

    public Boolean IsActive;
	public Boolean IsDefault;
    public Decimal Maximum;
	public Decimal Minimum;
	public Decimal Per;
	public String Rates;
	public String CalculationMethod;
	public String Id;
    public String Name;
    public Decimal L1Rate;
	public Decimal L2Rate;
    public Decimal L3Rate;
	public Decimal L4Rate;
    public Decimal L1Per;
	public Decimal L2Per;
    public Decimal L3Per;
	public Decimal L4Per;
    public Decimal L1Value;
	public Decimal L2Value;
    public Decimal L3Value;
	public Decimal L4Value;
    

    public StampDuty(Stamp_Duty_Calculators__c stampDutyRec) {
        this.Name = stampDutyRec.Name__c;
    	this.Id = stampDutyRec.Id;
    	this.Minimum = stampDutyRec.Minimum__c != null ? stampDutyRec.Minimum__c.setScale(2, RoundingMode.HALF_UP) : 0;
        this.Maximum = stampDutyRec.Maximum__c != null ? stampDutyRec.Maximum__c.setScale(2, RoundingMode.HALF_UP) : null;
    	this.CalculationMethod = stampDutyRec.Calculation_Method__c;
    	this.IsActive = stampDutyRec.Active__c;
        this.IsDefault = stampDutyRec.Default__c;
        if(stampDutyRec.L1_Rate__c == null) {
            stampDutyRec.L1_Rate__c = 0;
        }
        if(stampDutyRec.Calculation_Method__c == 'Single rate') {
            this.Rates = stampDutyRec.L1_Rate__c + '%';
        } else if(stampDutyRec.Calculation_Method__c == 'WA special rate') {
            this.Rates = 'Calculated';
        } else if(stampDutyRec.Calculation_Method__c == 'Escalating rate' || stampDutyRec.Calculation_Method__c == 'Tiered rate') {
            Decimal minRate = stampDutyRec.L1_Rate__c;
            Decimal maxRate = minRate;
            if(stampDutyRec.L2_Rate__c != null){
                minRate = minRate > stampDutyRec.L2_Rate__c ? stampDutyRec.L2_Rate__c : minRate;
                maxRate = maxRate < stampDutyRec.L2_Rate__c  ? stampDutyRec.L2_Rate__c : maxRate;
            }
            if(stampDutyRec.L3_Rate__c != null){
                minRate = minRate > stampDutyRec.L3_Rate__c ? stampDutyRec.L3_Rate__c : minRate;
                maxRate = maxRate < stampDutyRec.L3_Rate__c  ? stampDutyRec.L3_Rate__c : maxRate;
            }
            if(stampDutyRec.L4_Rate__c != null){
                minRate = minRate > stampDutyRec.L4_Rate__c ? stampDutyRec.L4_Rate__c : minRate;
                maxRate = maxRate < stampDutyRec.L4_Rate__c  ? stampDutyRec.L4_Rate__c : maxRate;
            }
            this.Rates = minRate.setScale(4, RoundingMode.HALF_UP) + + '% to ' + maxRate.setScale(4, RoundingMode.HALF_UP) +'%';
        }

        if(stampDutyRec.L1_Per__c == null) {
            stampDutyRec.L1_Per__c = 0;
        }

        Decimal minPer = stampDutyRec.L1_Per__c;
        if(stampDutyRec.Calculation_Method__c != 'Single rate') {
            if(stampDutyRec.L2_Per__c != null && minPer > stampDutyRec.L2_Per__c){
                minPer = stampDutyRec.L2_Per__c;
            }
            if(stampDutyRec.L3_Per__c != null && minPer > stampDutyRec.L3_Per__c){
                minPer = stampDutyRec.L3_Per__c;
            }
            if(stampDutyRec.L4_Per__c != null && minPer > stampDutyRec.L4_Per__c){
                minPer = stampDutyRec.L4_Per__c;
            }
        }
        this.Per = minPer.setScale(2, RoundingMode.HALF_UP);

        this.L1Rate = stampDutyRec.L1_Rate__c != null ? stampDutyRec.L1_Rate__c.setScale(4, RoundingMode.HALF_UP) : 0;
        this.L2Rate = stampDutyRec.L2_Rate__c != null ? stampDutyRec.L2_Rate__c.setScale(4, RoundingMode.HALF_UP) : null;
        this.L3Rate = stampDutyRec.L3_Rate__c != null ? stampDutyRec.L3_Rate__c.setScale(4, RoundingMode.HALF_UP) : null;
        this.L4Rate = stampDutyRec.L4_Rate__c != null ? stampDutyRec.L4_Rate__c.setScale(4, RoundingMode.HALF_UP) : null;
        this.L1Per = stampDutyRec.L1_Per__c != null ? stampDutyRec.L1_Per__c.setScale(2, RoundingMode.HALF_UP) : 0;
        this.L2Per = stampDutyRec.L2_Per__c != null ? stampDutyRec.L2_Per__c.setScale(2, RoundingMode.HALF_UP) : null;
        this.L3Per = stampDutyRec.L3_Per__c != null ? stampDutyRec.L3_Per__c.setScale(2, RoundingMode.HALF_UP) : null;
        this.L4Per = stampDutyRec.L4_Per__c != null ? stampDutyRec.L4_Per__c.setScale(2, RoundingMode.HALF_UP) : null;
        this.L1Value = stampDutyRec.L1_Value__c != null ? stampDutyRec.L1_Value__c.setScale(2, RoundingMode.HALF_UP) : null;
        this.L2Value = stampDutyRec.L2_Value__c != null ? stampDutyRec.L2_Value__c.setScale(2, RoundingMode.HALF_UP) : null;
        this.L3Value = stampDutyRec.L3_Value__c != null ? stampDutyRec.L3_Value__c.setScale(2, RoundingMode.HALF_UP) : null;
        this.L4Value = stampDutyRec.L4_Value__c != null ? stampDutyRec.L4_Value__c.setScale(2, RoundingMode.HALF_UP) : null;
    }

    /**
     * Name: fieldsList
     * Desc: Method Which contains all the field list to be quried
     * @param:  
     * @return: List<String> - Fields List
    **/
    public static List<String> fieldsList(){
        List<String> stampDutyFields = new List<String>{ 
                                                    'Name__c', 
                                                    'Calculation_Method__c', 
                                                    'Minimum__c', 
                                                    'Maximum__c', 
                                                    'L1_Value__c', 
                                                    'L1_Rate__c',  
                                                    'L1_Per__c',
                                                    'L2_Value__c', 
                                                    'L2_Rate__c',  
                                                    'L2_Per__c', 
                                                    'L3_Value__c', 
                                                    'L3_Rate__c',  
                                                    'L3_Per__c',
                                                    'L4_Value__c', 
                                                    'L4_Rate__c',  
                                                    'L4_Per__c',
                                                    'Active__c',
                                                    'Default__c',
                                                    'Id'
                                               		};
        return stampDutyFields;
    }
}