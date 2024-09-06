@IsTest
private class XeroUtilityTest {
    
    @IsTest
    private static void testDueDateForBillsWhenPaymentTermIsDaysAfterBillDate() {
        Date invoiceDate = System.today();
        Date dueDate = XeroUtility.getDueDateForBills(invoiceDate, 'DAYSAFTERBILLDATE', 10);
        System.assertEquals(invoiceDate.addDays(10), dueDate);
    }
    
    @IsTest
    private static void testDueDateForBillsWhenPaymentTermIsDaysAfterBillMonth() {
        Date invoiceDate = System.today();
        Date dueDate = XeroUtility.getDueDateForBills(invoiceDate, 'DAYSAFTERBILLMONTH', 10);
        
        Integer year = invoiceDate.year();
        Integer month = invoiceDate.month();
        if(invoiceDate.month() == 12) {
            year++;
            month = 0;
        }
        System.assertEquals(Date.newInstance(year, month + 1, 10), dueDate);
    }
    
    @IsTest
    private static void testDueDateForBillsWhenPaymentTermIsOfFollowingMonth() {
        Date invoiceDate = System.today();
        Date dueDate = XeroUtility.getDueDateForBills(invoiceDate, 'OFFOLLOWINGMONTH', 10);
        
        Integer year = invoiceDate.year();
        Integer month = invoiceDate.month();
        if(invoiceDate.month() == 12) {
            year++;
            month = 0;
        }
        System.assertEquals(Date.newInstance(year, month + 1, 10), dueDate);
    }
    
    @IsTest
    private static void testDueDateForBillsWhenPaymentTermIsOfCurrentMonth() {
        Date invoiceDate = System.today();
        Date dueDate = XeroUtility.getDueDateForBills(invoiceDate, 'OFCURRENTMONTH', 10);
        
        Integer year = invoiceDate.year();
        Integer month = invoiceDate.month();
        if(invoiceDate.month() == 12) {
            year++;
            month = 0;
        }
        
        Integer day;
        if(invoiceDate.day() < 10) {
            day = 10;
        } else {
            day = invoiceDate.day();
        }
        System.assertEquals(Date.newInstance(year, month, day), dueDate);
    }
}