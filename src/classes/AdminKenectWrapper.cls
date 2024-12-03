/**
 * Author: Manoj Sharma
 * Since: Feb 27, 2024
 * Name: AdminKenectWrapper
**/
public without sharing class AdminKenectWrapper {
    public Decimal LocationId;
    public Boolean IsKenectConfigComplete = false; 
    public String SMSNumber;
    
    public AdminKenectWrapper() {}

    public AdminKenectWrapper(Decimal locationId, String smsNumber, Boolean isKenectConfigComplete) {
        this.LocationId =  locationId;
        this.IsKenectConfigComplete = isKenectConfigComplete;
        this.SMSNumber = smsNumber;
    }
}