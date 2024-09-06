/**
 * Author: Tarun Khandelwal
 * Since: Dec 27, 2019
 * Name: HondaMockResponseGenerator 
 * Description: Mock Response generator class for Honda callouts
**/
@isTest
global class HondaMockResponseGenerator implements HttpCalloutMock {
    
    global HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        HondaVendorInvoiceService.PartWrapper partWrapperRec = new HondaVendorInvoiceService.PartWrapper();
        res.setHeader('Content-Type', 'application/json');
        
        if(req.getEndpoint().contains('https://api.hondampe.com.au/dealer/dealer_invoices')) {
            res.setBody('{"InvoiceItems": ["0090876703", "0090876704", "0090876705"]}');
        }
        else if(req.getEndpoint().contains('https://api.hondampe.com.au/dealer/invoices')) {
            res.setBody('{"OrderType":"Merchandise","OrderDate":"02/01/2019","InvoiceNumber":"INV1234569","HoosInvoiceItems":[{"WholesalePrice":null,"PartQuantityAllocated":null,"PartNumber":null,"PartDescription":null,"ListPrice":null}],"CustomerReference":"TestVendor"}');
        }
        else if(req.getEndpoint().contains('https://api.hondampe.com.au/dealer/orders')) {
            res.setBody('{"dealer":"Merchandise","key":"857496","dealer_reference":"INV1234569","lines":[{"part_number":"P2569","order_quantity":5,"backorder":"vendor"}],"order_date":"02/01/2019","order_time":"12:45","order_type":"VendorOrder","ship_address_id":"85694"}');
        }
        else if(req.getEndpoint().contains('https://api.hondampe.com.au/dealer/invoice')) {
            res.setBody('Create repair order successfully.');
        }
        res.setStatusCode(200);
        return res;
    }
}