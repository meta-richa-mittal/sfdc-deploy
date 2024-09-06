@isTest
global class PreferredPaymentIntegrationServiceTest {
    
    @TestSetup
    static void setupTestData() {
    	TestDataFactory.disableFLSChecks();
    	
        General_Configurations__c genConfig = General_Configurations__c.getOrgDefaults();
        genConfig.Enable_Preferred_Payment__c = true;
        upsert genConfig;

        IFW_IntegrationConfig__c IFWConfigObj = TestUtil.createIFWConfigsForPreferredPayment();

        Payment_Terminal__c terminalRec = new Payment_Terminal__c();
        terminalRec.Registration_Code__c = 'Test001';
        terminalRec.Nickname__c = 'Terminal 02';
        terminalRec.Preferred_Payment_Id__c = '2342304203';
        terminalRec.Status__c = 'Active';
        DMLUtility.insertSobjectList('Payment_Terminal__c', terminalRec);

        Account vendor = TestUtil.createVendor(true, 'Test Vendor');
        Category__c testCategory = TestUtil.createCategory(true, 'Test Category');
        
        Price_Level__c defaultPriceLevel = TestUtil.createPriceLevel(true, 'Default Price Level', 'MSRP', 10 , true, true);
        Sales_Tax__c defaultSalesTax = TestUtil.createSalesTax(true, 'Test Sales Tax', true, true, true);
        
        CO_Header__c coHeader1 = TestUtil.createCOHeader(true, null);
        Part__c part = TestUtil.createPart(true, '123', vendor.Id, 'Test Part', testCategory.Id, 10, 20, 50, 100, 100);
        CO_Line_Item__c coLineItemRec = TestUtil.createCOLineItem(true, coHeader1.Id, part.Id, 50);
    }

    @isTest
    static void getAllActivePaymentTerminalsTest() {
        List<PaymentTerminalWrapper> paymentMethods = (List<PaymentTerminalWrapper>) System.Json.deserialize(BPUtility.getDecodedString(CustomerOrderCtrl_V2.getAllActivePaymentTerminals()), List<PaymentTerminalWrapper>.class);
        system.assertEquals(1, paymentMethods.size());
    }

    @isTest
    static void postTerminalTest() {
        Payment_Terminal__c terminalRec = new Payment_Terminal__c();
        terminalRec.Registration_Code__c = 'Test001';
        terminalRec.Nickname__c = 'Terminal 01';
        DMLUtility.insertSobjectList('Payment_Terminal__c', terminalRec);

        Test.setMock(HttpCalloutMock.class, new PreferredPaymentMockResponseGenerator());
        Test.startTest();
        PreferredPaymentIntegrationService.syncTerminal(terminalRec.Id);
        Test.stopTest();
        system.assertEquals('001', [Select Id, Preferred_Payment_Id__c FROM Payment_Terminal__c WHERE Id =: terminalRec.Id].Preferred_Payment_Id__c);
    }

    @isTest
    static void deleteTerminalTest() {
        Payment_Terminal__c terminalRec = new Payment_Terminal__c();
        terminalRec.Registration_Code__c = 'Test001';
        terminalRec.Nickname__c = 'Terminal 01';
        terminalRec.Preferred_Payment_Id__c = '001';
        DMLUtility.insertSobjectList('Payment_Terminal__c', terminalRec);

        Test.setMock(HttpCalloutMock.class, new PreferredPaymentMockResponseGenerator());
        Test.startTest();
        PreferredPaymentIntegrationService.disconnectTerminal(terminalRec.Id);
        Test.stopTest();
        system.assertEquals(null, [Select Id, Preferred_Payment_Id__c FROM Payment_Terminal__c WHERE Id =: terminalRec.Id].Preferred_Payment_Id__c);
    }
	/**
    @isTest
    static void authorizeAndCaptureDepositTest() {
        Payment_Terminal__c terminalRec = [Select Id, Preferred_Payment_Id__c from Payment_Terminal__c];
        CO_header__c coRec = [Select Id from CO_header__c LIMIT 1];
        CO_Deposit__c coDeposit = new CO_Deposit__c();
        coDeposit.CO_header__c = coRec.Id;
        coDeposit.Amount__c = 3.3;
        coDeposit.Payment_Method__c = PreferredPaymentService.PREFERRED_PAYMENTS;
        CODeposit depositObj = new CODeposit(coDeposit);
        depositObj.PaymentTerminalId = terminalRec.Id;

        Test.setMock(HttpCalloutMock.class, new PreferredPaymentMockResponseGenerator());
        Test.startTest();
        PreferredPaymentService.PaymentDetail paymentDetailObj  = new PreferredPaymentService.PaymentDetail();
        paymentDetailObj.Amount = 3.3;
        paymentDetailObj.TerminalId = '13dd2e56-8453-4715-af16-000000000000';
        CustomerOrderCtrl_V2.authorizeAndCaptureDeposit(
            BPUtility.getEncodedString(System.json.serialize(paymentDetailObj)), 
            BPUtility.getEncodedString(System.JSON.serialize(new List<CODeposit>{depositObj}))
        );
        Test.stopTest();
        system.assertNotEquals(null, [Select Id, Reference__c FROM CO_Deposit__c WHERE CO_header__c =: coRec.Id].Reference__c);
    }

    @isTest
    static void authorizeAndCaptureDepositFailureTest() {
        CO_header__c coRec = [Select Id from CO_header__c LIMIT 1];
        CO_Deposit__c coDeposit = new CO_Deposit__c();
        coDeposit.CO_header__c = coRec.Id;
        coDeposit.Amount__c = 3.3;
        coDeposit.Payment_Method__c = PreferredPaymentService.PREFERRED_PAYMENTS;
        CODeposit depositObj = new CODeposit(coDeposit);
                
        Test.setMock(HttpCalloutMock.class, new PreferredPaymentFailureResponseGenerator());
        Test.startTest();
        PreferredPaymentService.PaymentDetail paymentDetailObj  = new PreferredPaymentService.PaymentDetail();
        paymentDetailObj.Amount = 3.3;
        paymentDetailObj.TerminalId = '13dd2e56-8453-4715-af16-000000000000';
        try {
        CustomerOrderCtrl_V2.authorizeAndCaptureDeposit(
            BPUtility.getEncodedString(System.json.serialize(paymentDetailObj)), 
            BPUtility.getEncodedString(System.JSON.serialize(new List<CODeposit>{depositObj}))
        );
        } catch(Exception e) {
            system.assertEquals('Duplicate transaction', e.getMessage());
        }
        Test.stopTest();
    }**/

    global class PreferredPaymentMockResponseGenerator implements HttpCalloutMock {
        global HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            if(req.getHeader('X-API-Key') == '7349340374') {
                if(req.getMethod() == 'POST' && req.getEndpoint().containsIgnoreCase('https://api.preferredpayments.com/v1/terminals/')) {
                    res.setBody('{"terminals":[{"id":"001","make":"make01","model":"model01","nickname":"ncknm","serial_number":"sn01","status":"ACTIVE"}]}');
                } else if(req.getMethod() == 'GET' && req.getEndpoint().containsIgnoreCase('https://api.preferredpayments.com/v1/terminals/')) {
                    res.setBody('{"terminals":[{"id":"001","make":"make01","model":"model01","nickname":"ncknm","serial_number":"sn01","status":"ACTIVE"},{"id":"002","make":"make02","model":"model02","nickname":"ncknm","serial_number":"sn02","status":"ACTIVE"}]}');
                } else if(req.getMethod() == 'POST' && (req.getEndpoint().containsIgnoreCase('https://api.preferredpayments.com/v1/transactions/authorize') || 
                    req.getEndpoint().containsIgnoreCase('https://api.preferredpayments.com/v1/transactions/capture'))) {
                    res.setBody('{"transaction_id": "143177501","auth_code": "","response_code": "APPROVED","response_text": "APPROVED","latency": 542,"metadata": {},"request_id": "0HMFJ6UQ9KSGR00000006"}');
                }
                res.setStatusCode(200);
            } else {
                res.setBody('401 Unauthorized');
                res.setStatusCode(401);
            }
            return res;
        }
    }

    global class PreferredPaymentFailureResponseGenerator implements HttpCalloutMock {
        global HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            if(req.getHeader('X-API-Key') == '7349340374') {
                if(req.getMethod() == 'POST' && (req.getEndpoint().containsIgnoreCase('https://api.preferredpayments.com/v1/transactions/authorize') || 
                    req.getEndpoint().containsIgnoreCase('https://api.preferredpayments.com/v1/transactions/capture'))) {
                    res.setBody('{"transaction_id": "143177501","auth_code": "","response_code": "ERROR","response_text": "DUPLICATE_TRANSACTION","latency": 542,"metadata": {},"request_id": "0HMFJ6UQ9KSGR00000006","errors": [{"type": "transaction","message": "Duplicate transaction"}]}');
                }
                res.setStatusCode(200);
            } else {
                res.setBody('401 Unauthorized');
                res.setStatusCode(401);
            }
            return res;
        }
    }
}