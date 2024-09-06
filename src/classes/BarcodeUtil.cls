/**
 * Author: Manoj Sharma
 * Since: Jan 28, 2021
 * Name: BarcodeUtil
 * Description: Class used to hold utility methods, variables and mapping used for barcode.
**/
public without sharing class BarcodeUtil {
    public static Map<String, String> barCodeLabelSizeToAPINameMap = new Map<String, String> {
        'large' => 'Part_Label_Template__c',
        'small' => 'Part_Label_Template_Small__c' 
    };
    public static Map<String, String> dymoConnectBarCodeLabelSizeToAPINameMap = new Map<String, String> {
        'large' => 'Dymo_Connect_Large_Label__c',
        'small' => 'Dymo_Connect_Small_Label__c' 
    };
}