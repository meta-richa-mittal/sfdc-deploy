/**
 * Author: Nidhi Sharma
 * Since: June 25, 2023
 * Name: COSalesperson
**/
public class COSalesperson {
    public String TechnicianId;
    public String TechnicianName;
    public String NameInitials;
    public String SectionId;
    public String DealId;
    public String SectionName;

    public COSalesperson(CO_Salesperson__c coSalespersonRec) {
        if(coSalespersonRec != null) {
            this.TechnicianId = coSalespersonRec.Technician__c;
            this.TechnicianName = coSalespersonRec.Technician__r.Technician_Name__c;
            this.NameInitials = (String.isNotBlank(coSalespersonRec.Technician__r.First_Name__c) ? coSalespersonRec.Technician__r.First_Name__c.subString(0, 1) : '') +
                            (String.isNotBlank(coSalespersonRec.Technician__r.Last_Name__c) ? coSalespersonRec.Technician__r.Last_Name__c.subString(0, 1) : '');
        }
    }
}