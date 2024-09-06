@isTest
global class WebsiteProductMockResponseGenerator implements HttpCalloutMock {
	global HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        if(req.getMethod() == 'POST' && req.getEndpoint().containsIgnoreCase('https://super-connector.us.auth0.com/oauth/token')) {
		    res.setBody('{"access_token": "eyJhbGciOiJSUzI1NiIsIn","scope": "access:product access:order","expires_in": 86400,"token_type": "Bearer"}');
		} if(req.getMethod() == 'POST' && req.getEndpoint().containsIgnoreCase('https://api.super-connectors.com/product')) {
            res.setBody('[{"title":"Hello title","productNumber":"123","vendorCode":"VEN","shopifyId":"SHOPIFY1234"}]');
        } else if(req.getMethod() == 'GET' && req.getEndpoint().containsIgnoreCase('https://api.super-connectors.com/product/new')) {
		    res.setBody('{"cursor":"0","hasNextPage":false,"orders":[{}],"products":[{"Title":"Working title","shopifyId":"12345"}]}');
		} else if(req.getMethod() == 'PUT') {
		    res.setBody('{"shopifyId":"1232435"}');
		} else if(req.getMethod() == 'GET' && req.getEndpoint().containsIgnoreCase('https://api.super-connectors.com/product/order')) {
		    res.setBody('{"cursor":"0","hasNextPage":false,"orders":[{"shopifyId":"SHOPIFYID-1234","orderNumber":"ORDER1234"}],"products":[{}]}');
		} else if(req.getMethod() == 'DELETE') {
			res.setBody('{"Deleted successfully"}');
		} else if(req.getMethod() == 'GET' && req.getEndpoint().containsIgnoreCase('https://api.super-connectors.com/product/')) {
			res.setBody('[{"barcode": "","createdAt": "2021-10-19T07:01:58Z","description": "","descriptionHtml": "","hasOnlyDefaultVariant": false,"inactive": true,"optionName1": "Size","optionName2": "Color","optionName3": null,"optionValue1": "M","optionValue2": "Red","optionValue3": null,"position": 1,"price": 0,"productType": "","publishedAt": null,"qtyAvailable": 0,"salesPrice": null,"shopifyId": "7074368028833.41090144174241","sku": "","status": "DRAFT","storefrontId": "Z2lkOi8vc2hvcGlmeS9Qcm9kdWN0VmFyaWFudC80MTA5MDE0NDE3NDI0MQ==","tags": null,"taxable": true,"title": "Jumpsuit - M / Red","titleProduct": "Jumpsuit","unitCost": null,"updatedAt": "2021-10-19T07:01:58Z","vendor": "Cully\'s Custom Test","weight": 0,"weightUnit": "KILOGRAMS"}]');
		}
		res.setStatusCode(200);
		return res;
    }
}