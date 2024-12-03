public without sharing class Escalator {

    public String Type;
    public Decimal Markup1;
    public Decimal Markup2;
    public Decimal Markup3;
    public Decimal Markup4;
    public Decimal Markup5;
    public Decimal Markup6;
    public Decimal Markup7;
    public Decimal Markup8;
    public Decimal Markup9;
    public Decimal Markup10;
    public Decimal Markup11;
    public Decimal MaxAmount1;
    public Decimal MaxAmount2;
    public Decimal MaxAmount3;
    public Decimal MaxAmount4;
    public Decimal MaxAmount5;
    public Decimal MaxAmount6;
    public Decimal MaxAmount7;
    public Decimal MaxAmount8;
    public Decimal MaxAmount9;
    public Decimal MaxAmount10;

    public Escalator(Escalator__c escalatorRec) {
        this.Type = escalatorRec.Type__c;
        this.Markup1 = escalatorRec.Markup_1__c;
        this.Markup2 = escalatorRec.Markup_2__c;
        this.Markup3 = escalatorRec.Markup_3__c;
        this.Markup4 = escalatorRec.Markup_4__c;
        this.Markup5 = escalatorRec.Markup_5__c;
        this.Markup6 = escalatorRec.Markup_6__c;
        this.Markup7 = escalatorRec.Markup_7__c;
        this.Markup8 = escalatorRec.Markup_8__c;
        this.Markup9 = escalatorRec.Markup_9__c;
        this.Markup10 = escalatorRec.Markup_10__c;
        this.Markup11 = escalatorRec.Markup_11__c;
        this.MaxAmount1 = escalatorRec.Max_Amount_1__c;
        this.MaxAmount2 = escalatorRec.Max_Amount_2__c;
        this.MaxAmount3 = escalatorRec.Max_Amount_3__c;
        this.MaxAmount4 = escalatorRec.Max_Amount_4__c;
        this.MaxAmount5 = escalatorRec.Max_Amount_5__c;
        this.MaxAmount6 = escalatorRec.Max_Amount_6__c;
        this.MaxAmount7 = escalatorRec.Max_Amount_7__c;
        this.MaxAmount8 = escalatorRec.Max_Amount_8__c;
        this.MaxAmount9 = escalatorRec.Max_Amount_9__c;
        this.MaxAmount10 = escalatorRec.Max_Amount_10__c;
    }

    public static List<String> getFieldList() {
        return new List<String> {
            'Id', 'Type__c', 'Markup_1__c', 'Markup_2__c', 'Markup_3__c', 'Markup_4__c', 'Markup_5__c', 'Markup_6__c', 'Markup_7__c', 
            'Markup_8__c', 'Markup_9__c', 'Markup_10__c', 'Markup_11__c', 'Max_Amount_1__c', 'Max_Amount_2__c', 'Max_Amount_3__c', 
            'Max_Amount_4__c', 'Max_Amount_5__c', 'Max_Amount_6__c', 'Max_Amount_7__c', 'Max_Amount_8__c', 'Max_Amount_9__c', 
            'Max_Amount_10__c', 'Vendor__c'
        };
    }
}