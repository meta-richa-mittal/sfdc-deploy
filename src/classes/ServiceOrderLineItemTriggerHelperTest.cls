/**
 * Author: Reena Singh
 * Since: July 17, 2020
 * Name: ServiceOrderLineItemTriggerHelper Test
 * Description: Controller test Class of SO line item Trigger.
**/
@isTest
private class ServiceOrderLineItemTriggerHelperTest {
    /**
     * Name: addLineItemTest
     * Desc: Test to add SO line item
     * @param: 
     * @return:  
    **/ 
    
    static testMethod void createServiceOrderLineItemEnhancedTest() {
      TestUtil.createEnhancedTaxSettingInGeneralConfig();
		
      Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(true, 'Default Price Level', 'Price', 0 , true, true);
      Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
      Category__c defaultTestCategory = TestUtil.createCategory(true, 'Tax Default1');
      Sales_Tax__c standardSalestax = TestUtil.createMixedTaxForEnhancedTaxCalculation();
      Account vendor = TestUtil.createVendor(true, 'Test Vendor');
      Account customer =  TestUtil.createCustomer(false, 'customerName', 'abc@abc.com', 'jaipur', '1111111111', defaultPriceLevel.Id, null, false, true,'Individual');
      customer.Is_Customer__c = true;
      insert customer;
        
      Part__c testPart = TestUtil.createPart(false, '123', vendor.Id, 'Test Part', testCategory.Id, 20, 40, 50, 100, 200);
      testPart.Taxable__c = true;
      testPart.Applicable_Tax__c = standardSalestax.Id;
      insert testPart;

      CO_Header__c coHeader = TestUtil.createCOHeader(true, customer.Id);
      Labour_Code__c labourCode = TestUtil.createLabourCode(false, true, testCategory.Id, 'Code', coHeader.Id, 'Description', True, 10, 'LabourCodeName', 10, true);
      labourCode.Taxable__c = true;
      labourCode.Applicable_Tax__c = standardSalestax.Id;
      insert labourCode;

      Test.startTest();

      String soHeader = BPUtility.getDecodedString(CustomerOrderCtrl.createSOHeader(BPUtility.getEncodedString(coHeader.Id)));
      String SOHeaderDetails = BPUtility.getDecodedString(CustomerOrderCtrl.getSOHeaderDetails(BPUtility.getEncodedString(coHeader.Id), BPUtility.getEncodedString('soHeader')));
      SOHeaderWrapper soHeaderDetailsObj = (SOHeaderWrapper) System.JSON.deserialize(SOHeaderDetails, SOHeaderWrapper.class);
      System.assertEquals(soHeaderDetailsObj.SOList[0].SOHeaderInfo.Name, 'Service Job 1');
      String partLineitems = BPUtility.getDecodedString(CustomerOrderCtrl.addLineItems(BPUtility.getEncodedString(testPart.Id), BPUtility.getEncodedString(soHeaderDetailsObj.SOList[0].SOHeaderInfo.Id), BPUtility.getEncodedString(coHeader.Id), BPUtility.getEncodedString(customer.Id)));
      String labourLineitems = BPUtility.getDecodedString(CustomerOrderCtrl.addLineItems(BPUtility.getEncodedString(labourCode.Id), BPUtility.getEncodedString(soHeaderDetailsObj.SOList[0].SOHeaderInfo.Id), BPUtility.getEncodedString(coHeader.Id), BPUtility.getEncodedString(customer.Id)));
      List<Service_Order_Line_Item__c> SOLineItems = [SELECT Id,Part__c, Labour_Code__c,Kit_Price__c,(SELECT Enhanced_Tax_Amount__c,Sales_Tax_Item__r.Name__c,Tax_Rate__c FROM Individual_Taxes__r) 
                                                      FROM Service_Order_Line_Item__c where Service_Order_Header__c =: soHeaderDetailsObj.SOList[0].SOHeaderInfo.Id];
      System.assertEquals(2, SOLineItems.size());
      for (Service_Order_Line_Item__c soOrderLineItemRec : SOLineItems) {
        for (Individual_Tax__c individualTaxRec : soOrderLineItemRec.Individual_Taxes__r) {
          if (soOrderLineItemRec.Part__c != null) {
            system.assertEquals (100, soOrderLineItemRec.Kit_Price__c);
            if (individualTaxRec.Sales_Tax_Item__r.Name__c == 'State Escalating') {
              system.assertEquals(3.00, individualTaxRec.Enhanced_Tax_Amount__c);
              system.assertEquals(null, individualTaxRec.Tax_Rate__c);
            } else if (individualTaxRec.Sales_Tax_Item__r.Name__c == 'State Tiered') {
              system.assertEquals(2.50, individualTaxRec.Enhanced_Tax_Amount__c);
              system.assertEquals(null, individualTaxRec.Tax_Rate__c);
            } else if (individualTaxRec.Sales_Tax_Item__r.Name__c == 'Fixed Rate 2') {
              system.assertEquals(8.00, individualTaxRec.Tax_Rate__c );
              system.assertEquals(null, individualTaxRec.Enhanced_Tax_Amount__c);
            }  else if (individualTaxRec.Sales_Tax_Item__r.Name__c == 'Fixed Rate 1') {
              system.assertEquals(5.00, individualTaxRec.Tax_Rate__c);
              system.assertEquals(null, individualTaxRec.Enhanced_Tax_Amount__c);
            } else {
              system.assert(false, 'Incorrect tax item');
            }
          } else if (soOrderLineItemRec.Labour_Code__c != null) {
            if (individualTaxRec.Sales_Tax_Item__r.Name__c == 'State Escalating') {
              system.assertEquals(15.00, individualTaxRec.Enhanced_Tax_Amount__c);
              system.assertEquals(null, individualTaxRec.Tax_Rate__c);
            } else if (individualTaxRec.Sales_Tax_Item__r.Name__c == 'State Tiered') {
              system.assertEquals(12.50, individualTaxRec.Enhanced_Tax_Amount__c);
              system.assertEquals(null, individualTaxRec.Tax_Rate__c);
            } else if (individualTaxRec.Sales_Tax_Item__r.Name__c == 'Fixed Rate 2') {
              system.assertEquals(8.00, individualTaxRec.Tax_Rate__c );
              system.assertEquals(null, individualTaxRec.Enhanced_Tax_Amount__c);
            }  else if (individualTaxRec.Sales_Tax_Item__r.Name__c == 'Fixed Rate 1') {
              system.assertEquals(5.00, individualTaxRec.Tax_Rate__c);
              system.assertEquals(null, individualTaxRec.Enhanced_Tax_Amount__c);
            } else {
              system.assert(false, 'Incorrect tax item');
            }
        }
      }  
    }
    Test.stopTest();
  }

  static testMethod void createServiceOrderKitLineItemEnhancedTest() {
    TestUtil.createEnhancedTaxSettingInGeneralConfig();
  
    Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(true, 'Default Price Level', 'Price', 0 , true, true);
    Sales_Tax__c defaultSalesTax = TestUtil.createSalesTax(true, 'Test Sales Tax', true, true, true);
    Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
    Category__c defaultTestCategory = TestUtil.createCategory(true, 'Tax Default1');
    Sales_Tax__c standardSalestax = TestUtil.createMixedTaxForEnhancedTaxCalculation();
    Account vendor = TestUtil.createVendor(true, 'Test Vendor');
    Account customer =  TestUtil.createCustomer(false, 'customerName', 'abc@abc.com', 'jaipur', '1111111111', defaultPriceLevel.Id, null, false, true,'Individual');
    customer.Is_Customer__c = true;
    insert customer;
    Unit_Make__c unitmake = TestUtil.createUnitMake(true, 'unitMakeName', '12A', true);
    Unit_Model__c unitmodel = TestUtil.createUnitModel(true, 'unitModelName', '12A', true, unitMake.Id);
    Part__c testPart = TestUtil.createPart(false, '123', vendor.Id, 'Test Part', testCategory.Id, 20, 40, 50, 100, 200);
    testPart.Taxable__c = true;
    testPart.Applicable_Tax__c = standardSalestax.Id;
    insert testPart;

    CO_Header__c coHeader = TestUtil.createCOHeader(true, customer.Id);
    Labour_Code__c labourCode = TestUtil.createLabourCode(false, true, testCategory.Id, 'Code', coHeader.Id, 'Description', True, 10, 'LabourCodeName', 10, true);
    labourCode.Taxable__c = true;
    labourCode.Applicable_Tax__c = standardSalestax.Id;
    insert labourCode;

    Fee__c fee = TestUtil.createFee(false, true, testCategory.Id, 'FeeCode', null, 'Description', 100, true);
    fee.Taxable__c = true;
    fee.Applicable_Tax__c = standardSalestax.Id;
    insert fee;

    Kit_Header__c kitHeader = TestUtil.createKitHeader(true, true, true, 'Cause', 'Code', 'Concern', 'Correction', 'Description', 10.0, true, true, unitMake.Id, unitModel.Id);
    Kit_Header_Line_Item__c kitHeaderLineItem = TestUtil.createKitHeaderLineItem(true, false, false, KitHeader.Id, 5.0, null, testPart.Id, 3, 5.0);
    Kit_Header_Line_Item__c kitHeaderLineItem1 = TestUtil.createKitHeaderLineItem(false, true, true, KitHeader.Id, 5.0, null, null, 1, 5.0);
    kitHeaderLineItem1.Fee__c = fee.Id;
    insert kitHeaderLineItem1;
    Kit_Header_Line_Item__c kitHeaderLineItem2 = TestUtil.createKitHeaderLineItem(true, false, false, KitHeader.Id, 5.0, labourCode.Id, null, 1, 5.0); 

    Test.startTest();
    String soHeader = BPUtility.getDecodedString(CustomerOrderCtrl.createSOHeader(BPUtility.getEncodedString(coHeader.Id)));
    String SOHeaderDetails = BPUtility.getDecodedString(CustomerOrderCtrl.getSOHeaderDetails(BPUtility.getEncodedString(coHeader.Id), BPUtility.getEncodedString('soHeader')));
    SOHeaderWrapper soHeaderDetailsObj = (SOHeaderWrapper) System.JSON.deserialize(SOHeaderDetails, SOHeaderWrapper.class);
    System.assertEquals(soHeaderDetailsObj.SOList[0].SOHeaderInfo.Name, 'Service Job 1');

    String kitLineitems = BPUtility.getDecodedString(CustomerOrderCtrl.addLineItems(BPUtility.getEncodedString(kitHeader.Id), BPUtility.getEncodedString(soHeaderDetailsObj.SOList[0].SOHeaderInfo.Id), BPUtility.getEncodedString(coHeader.Id), BPUtility.getEncodedString(customer.Id)));
    
    List<Service_Order_Line_Item__c> SOLineItems = [SELECT Id, Part__c, Fee__c, Labour_Code__c, Kit_Price__c, (SELECT Enhanced_Tax_Amount__c,Sales_Tax_Item__r.Name__c,Tax_Rate__c FROM Individual_Taxes__r) 
                                                    FROM Service_Order_Line_Item__c where Service_Order_Header__c =: soHeaderDetailsObj.SOList[0].SOHeaderInfo.Id];
    
    String SOHeaderDetails1 = BPUtility.getDecodedString(CustomerOrderCtrl.getSOHeaderDetails(BPUtility.getEncodedString(coHeader.Id), BPUtility.getEncodedString(null)));
    SOHeaderWrapper soHeaderDetailsObj1 = (SOHeaderWrapper) System.JSON.deserialize(SOHeaderDetails1, SOHeaderWrapper.class);
      
    soHeaderDetailsObj1.SOList[0].SOGridItems[0].SOKH.FixedPrice = 20.00 ;
    System.JSON.serialize(soHeaderDetailsObj1.SOList[0].SOGridItems[0]);

    String updatedSOKH = BPUtility.getDecodedString(CustomerOrderCtrl.updateSOKHLineItems(BPUtility.getEncodedString(System.JSON.serialize(soHeaderDetailsObj1.SOList[0].SOGridItems[0])), BPUtility.getEncodedString(coHeader.Id)));
    System.assertEquals(3, SOLineItems.size());
    
    for (Service_Order_Line_Item__c soOrderLineItemRec : SOLineItems) {
      for (Individual_Tax__c individualTaxRec : soOrderLineItemRec.Individual_Taxes__r) {
        if (soOrderLineItemRec.Part__c != null) {
          if (individualTaxRec.Sales_Tax_Item__r.Name__c == 'State Escalating') {
              system.assertEquals(0.30, individualTaxRec.Enhanced_Tax_Amount__c);
              system.assertEquals(null, individualTaxRec.Tax_Rate__c);
          } else if (individualTaxRec.Sales_Tax_Item__r.Name__c == 'State Tiered') {
              system.assertEquals(0.25, individualTaxRec.Enhanced_Tax_Amount__c);
              system.assertEquals(null, individualTaxRec.Tax_Rate__c);
          } else if (individualTaxRec.Sales_Tax_Item__r.Name__c == 'Fixed Rate 2') {
              system.assertEquals(8.00, individualTaxRec.Tax_Rate__c );
              system.assertEquals(null, individualTaxRec.Enhanced_Tax_Amount__c);
          }  else if (individualTaxRec.Sales_Tax_Item__r.Name__c == 'Fixed Rate 1') {
              system.assertEquals(5.00, individualTaxRec.Tax_Rate__c);
              system.assertEquals(null, individualTaxRec.Enhanced_Tax_Amount__c);
          } else {
              system.assert(false, 'Incorrect tax item');
          }
      } else if (soOrderLineItemRec.Labour_Code__c != null) {
          system.assertEquals (5.000, soOrderLineItemRec.Kit_Price__c);
          if (individualTaxRec.Sales_Tax_Item__r.Name__c == 'State Escalating') {
              system.assertEquals(0.15, individualTaxRec.Enhanced_Tax_Amount__c);
              system.assertEquals(null, individualTaxRec.Tax_Rate__c);
          } else if (individualTaxRec.Sales_Tax_Item__r.Name__c == 'State Tiered') {
              system.assertEquals(0.13, individualTaxRec.Enhanced_Tax_Amount__c);
              system.assertEquals(null, individualTaxRec.Tax_Rate__c);
          } else if (individualTaxRec.Sales_Tax_Item__r.Name__c == 'Fixed Rate 2') {
              system.assertEquals(8.00, individualTaxRec.Tax_Rate__c );
              system.assertEquals(null, individualTaxRec.Enhanced_Tax_Amount__c);
          }  else if (individualTaxRec.Sales_Tax_Item__r.Name__c == 'Fixed Rate 1') {
              system.assertEquals(5.00, individualTaxRec.Tax_Rate__c);
              system.assertEquals(null, individualTaxRec.Enhanced_Tax_Amount__c);
          } else {
              system.assert(false, 'Incorrect tax item');
          }
      }  else if (soOrderLineItemRec.Fee__c!= null) {
          system.assertEquals (5.000, soOrderLineItemRec.Kit_Price__c);
          if (individualTaxRec.Sales_Tax_Item__r.Name__c == 'State Escalating') {
              system.assertEquals(0.15, individualTaxRec.Enhanced_Tax_Amount__c);
              system.assertEquals(null, individualTaxRec.Tax_Rate__c);
          } else if (individualTaxRec.Sales_Tax_Item__r.Name__c == 'State Tiered') {
              system.assertEquals(0.13, individualTaxRec.Enhanced_Tax_Amount__c);
              system.assertEquals(null, individualTaxRec.Tax_Rate__c);
          } else if (individualTaxRec.Sales_Tax_Item__r.Name__c == 'Fixed Rate 2') {
              system.assertEquals(8.00, individualTaxRec.Tax_Rate__c );
              system.assertEquals(null, individualTaxRec.Enhanced_Tax_Amount__c);
          }  else if (individualTaxRec.Sales_Tax_Item__r.Name__c == 'Fixed Rate 1') {
              system.assertEquals(5.00, individualTaxRec.Tax_Rate__c);
              system.assertEquals(null, individualTaxRec.Enhanced_Tax_Amount__c);
          } else {
              system.assert(false, 'Incorrect tax item');
          }
        } 
      }     
    }
    test.stoptest(); 
  }
}