/**
 * Author: Nidhi Sharma
 * Since: April 20, 2023
 * Name: CORecalculationWrapper
 * Description: Wrapper related to recalculate CO pricing and taxes
**/
public without sharing class CORecalculationWrapper {
    
    public String COHeaderId;
    public String CustomerId;
    public String SOHeaderId;
    public Boolean IsRecalculateTaxes;
    public Boolean IsResetPricing;
}