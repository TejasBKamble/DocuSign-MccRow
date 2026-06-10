/**
 * @description       : 
 * @testing           : 
 * @author            : FSM
 * @last modified on  : 06-23-2025 - FSM
 * @last modified by  : FSM
**/

@isTest
public class SmartAdvTokenService_Test {
    @isTest
        static void doTestSuccess() {
        Test.setMock(HttpCalloutMock.Class, new GetTokenHttpResponse());

        Test.startTest();
        SmartAdvTokenService service = new SmartAdvTokenService();
        SmartAdvTokenService.ServiceResponse res = service.getToken();
        Test.stopTest();

        System.assertEquals(true, res.isSuccess);
        System.assertEquals(null, res.errorMessage);
        System.assertEquals('abc', res.token);
    }

    @isTest
        static void doTestError() {
        Test.setMock(HttpCalloutMock.Class, new GetTokenHttpResponseError());

        Test.startTest();
        SmartAdvTokenService service = new SmartAdvTokenService();
        SmartAdvTokenService.ServiceResponse res = service.getToken();
        Test.stopTest();

        System.assertEquals(false, res.isSuccess);
        System.assertEquals(null, res.token);
    }

    private class GetTokenHttpResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            res.setBody('{"username":"test","userID":677,"token":"abc"}');
            return res;
        }
    }

    private class GetTokenHttpResponseError implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(400);
            res.setBody('{"message": "Username or password is incorrect"}');
            return res;
        }
    }
}