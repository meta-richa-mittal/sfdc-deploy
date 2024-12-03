@isTest
public without sharing class AccDataMigrationVendorReceivingTest{

 	@isTest
 	private static void ConstructorCallTest(){
        AccDataMigrationVendorReceiving obj1 = new AccDataMigrationVendorReceiving();
        AccDataMigrationVendorReceiving obj2 = new AccDataMigrationVendorReceiving(null, true);
        AccDataMigrationVendorReceiving obj3 = new AccDataMigrationVendorReceiving(null, true, null, null, null);
        AccDataMigrationVendorReceiving obj4 = new AccDataMigrationVendorReceiving(null, null, null, null, 'abc');
        
        obj4.start(null);
        obj4.execute(null, null);
        obj4.finish(null);
  		System.assertEquals(0, [SELECT count() FROM Account]);
	}
	 
	@isTest
 	private static void ConstructorCallTest2(){
        AccountingDataMigrationvendorReceiving obj1 = new AccountingDataMigrationvendorReceiving();
        AccountingDataMigrationvendorReceiving obj2 = new AccountingDataMigrationvendorReceiving(null, true);
        AccountingDataMigrationvendorReceiving obj3 = new AccountingDataMigrationvendorReceiving(null, true, null, null, null);
        AccountingDataMigrationvendorReceiving obj4 = new AccountingDataMigrationvendorReceiving(null, null, null, null, 'abc');
        
        obj4.start(null);
        obj4.execute(null, null);
        obj4.finish(null);
  		System.assertEquals(0, [SELECT count() FROM Account]);
	}
	 
	@isTest
 	private static void ConstructorCallTest3(){
        AccDataMigrationFIFOBkt obj1 = new AccDataMigrationFIFOBkt();
        AccDataMigrationFIFOBkt obj2 = new AccDataMigrationFIFOBkt(null, true);
        AccDataMigrationFIFOBkt obj3 = new AccDataMigrationFIFOBkt(null, true, null, null, null);
        AccDataMigrationFIFOBkt obj4 = new AccDataMigrationFIFOBkt(null, null, null, null, 'abc');
        
        obj4.start(null);
        obj4.execute(null, null);
        obj4.finish(null);
  		System.assertEquals(0, [SELECT count() FROM Account]);
	}
	 
	@isTest
 	private static void ConstructorCallTest4(){
        AccountingDataMigrationCustomers obj1 = new AccountingDataMigrationCustomers();
        AccountingDataMigrationCustomers obj2 = new AccountingDataMigrationCustomers(null, true);
        AccountingDataMigrationCustomers obj3 = new AccountingDataMigrationCustomers(null, true, null, null, null);
        AccountingDataMigrationCustomers obj4 = new AccountingDataMigrationCustomers(null, null, null, null, 'abc');
        
        obj4.start(null);
        obj4.execute(null, null);
        obj4.finish(null);
  		System.assertEquals(0, [SELECT count() FROM Account]);
	}
	 
	@isTest
 	private static void ConstructorCallTest5(){
        AccountingDataMigrationDeposits obj1 = new AccountingDataMigrationDeposits();
        AccountingDataMigrationDeposits obj2 = new AccountingDataMigrationDeposits(null, true);
        AccountingDataMigrationDeposits obj3 = new AccountingDataMigrationDeposits(null, true, null, null, null);
        AccountingDataMigrationDeposits obj4 = new AccountingDataMigrationDeposits(null, null, null, null, 'abc');
        
        obj4.start(null);
        obj4.execute(null, null);
        obj4.finish(null);
  		System.assertEquals(0, [SELECT count() FROM Account]);
	}
	
	@isTest
 	private static void ConstructorCallTest6(){
        AccountingDataMigrationFifoBucket obj1 = new AccountingDataMigrationFifoBucket();
        AccountingDataMigrationFifoBucket obj2 = new AccountingDataMigrationFifoBucket(null, true);
        AccountingDataMigrationFifoBucket obj3 = new AccountingDataMigrationFifoBucket(null, true, null, null, null);
        AccountingDataMigrationFifoBucket obj4 = new AccountingDataMigrationFifoBucket(null, null, null, null, 'abc');
        
        obj4.start(null);
        obj4.execute(null, null);
        obj4.finish(null);
  		System.assertEquals(0, [SELECT count() FROM Account]);
	}
	
	@isTest
 	private static void ConstructorCallTest7(){
        AccountingDataMigrationSalesInvoice obj1 = new AccountingDataMigrationSalesInvoice();
        AccountingDataMigrationSalesInvoice obj2 = new AccountingDataMigrationSalesInvoice(null, true);
        AccountingDataMigrationSalesInvoice obj3 = new AccountingDataMigrationSalesInvoice(null, true, null, null, null);
        AccountingDataMigrationSalesInvoice obj4 = new AccountingDataMigrationSalesInvoice(null, null, null, null, 'abc');
        
        obj4.start(null);
        obj4.execute(null, null);
        obj4.finish(null);
  		System.assertEquals(0, [SELECT count() FROM Account]);
	}
	
	@isTest
 	private static void ConstructorCallTest8(){
        AccountingDataMigrationPayment obj1 = new AccountingDataMigrationPayment();
        AccountingDataMigrationPayment obj2 = new AccountingDataMigrationPayment(null, true);
        AccountingDataMigrationPayment obj3 = new AccountingDataMigrationPayment(null, true, null, null, null);
        AccountingDataMigrationPayment obj4 = new AccountingDataMigrationPayment(null, null, null, null, 'abc');
        
        obj4.start(null);
        obj4.execute(null, null);
        obj4.finish(null);
  		System.assertEquals(0, [SELECT count() FROM Account]);
	}
	
	@isTest
 	private static void ConstructorCallTest9(){
        AccountingDataMigrationRMPayment obj1 = new AccountingDataMigrationRMPayment();
        AccountingDataMigrationRMPayment obj2 = new AccountingDataMigrationRMPayment(null, true);
        AccountingDataMigrationRMPayment obj3 = new AccountingDataMigrationRMPayment(null, true, null, null, null);
        AccountingDataMigrationRMPayment obj4 = new AccountingDataMigrationRMPayment(null, null, null, null, 'abc');
        
        obj4.start(null);
        obj4.execute(null, null);
        obj4.finish(null);
  		System.assertEquals(0, [SELECT count() FROM Account]);
	}
	
	@isTest
 	private static void ConstructorCallTest10(){
        AccountingDataMigrationVendorInvoice obj1 = new AccountingDataMigrationVendorInvoice();
        AccountingDataMigrationVendorInvoice obj2 = new AccountingDataMigrationVendorInvoice(null, true);
        AccountingDataMigrationVendorInvoice obj3 = new AccountingDataMigrationVendorInvoice(null, true, null, null, null);
        AccountingDataMigrationVendorInvoice obj4 = new AccountingDataMigrationVendorInvoice(null, null, null, null, 'abc');
        
        obj4.start(null);
        obj4.execute(null, null);
        obj4.finish(null);
  		System.assertEquals(0, [SELECT count() FROM Account]);
	}
	
	private static void ConstructorCallTest11(){
        AccountingDataMigrationVendors obj1 = new AccountingDataMigrationVendors();
        AccountingDataMigrationVendors obj2 = new AccountingDataMigrationVendors(null, true);
        AccountingDataMigrationVendors obj3 = new AccountingDataMigrationVendors(null, true, null, null, null);
        
        obj3.start(null);
        obj3.execute(null, null);
        obj3.finish(null);
  		System.assertEquals(0, [SELECT count() FROM Account]);
	}
	
	@isTest
 	private static void ConstructorCallTest12(){
        AccountingDataMigrationVI obj1 = new AccountingDataMigrationVI();
        AccountingDataMigrationVI obj2 = new AccountingDataMigrationVI(null, true);
        AccountingDataMigrationVI obj3 = new AccountingDataMigrationVI(null, true, null, null, null);
        AccountingDataMigrationVI obj4 = new AccountingDataMigrationVI(null, null, null, null, 'abc');
        
        obj4.start(null);
        obj4.execute(null, null);
        obj4.finish(null);
  		System.assertEquals(0, [SELECT count() FROM Account]);
	}
	
	@isTest
 	private static void ConstructorCallTest13(){
        MYOBSalesInvoice obj1 = new MYOBSalesInvoice();
        MYOBSalesInvoice obj2 = new MYOBSalesInvoice(null, true);
        MYOBSalesInvoice obj3 = new MYOBSalesInvoice(null, true, null, null, null);
        MYOBSalesInvoice obj4 = new MYOBSalesInvoice(null, null, null, null, 'abc');
        
        obj4.start(null);
        obj4.execute(null, null);
        obj4.finish(null);
  		System.assertEquals(0, [SELECT count() FROM Account]);
	}
}