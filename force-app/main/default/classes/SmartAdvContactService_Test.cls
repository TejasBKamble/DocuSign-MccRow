/**
 * @description       : 
 * @testing           : 
 * @author            : FSM
 * @last modified on  : 05-27-2025 - FSM
 * @last modified by  : FSM
**/
@isTest
public class SmartAdvContactService_Test {
    @isTest
    static void syncContactsSuccess() {
        Account acct = SmartAdvTestFactory.createAccount();
        Contact con = SmartAdvTestFactory.createContact(acct.Id, '188514');

        Test.setMock(HttpCalloutMock.Class, new GetFilteredContactsHttpResponse());

        SmartAdvTokenService stub = (SmartAdvTokenService) System.Test.createStub(SmartAdvTokenService.class, new SmartAdvTokenService_Stub('success'));
        SmartAdvContactService contactService = new SmartAdvContactService(stub);

        Test.startTest();
        SmartAdvContactService.ServiceResponse res = contactService.updateAllRecentContactsFromSmartAdvocate(Datetime.now().addDays(-1), Datetime.now(), 0, 200);
        Test.stopTest();
    }

    @isTest
    static void syncContactsTokenError() {
        Account acct = SmartAdvTestFactory.createAccount();
        Contact con = SmartAdvTestFactory.createContact(acct.Id, '188514');

        Test.setMock(HttpCalloutMock.Class, new GetFilteredContactsHttpResponse());

        SmartAdvTokenService stub = (SmartAdvTokenService) System.Test.createStub(SmartAdvTokenService.class, new SmartAdvTokenService_Stub('error'));
        SmartAdvContactService contactService = new SmartAdvContactService(stub);

        Test.startTest();
        SmartAdvContactService.ServiceResponse res = contactService.updateAllRecentContactsFromSmartAdvocate(Datetime.now().addDays(-1), Datetime.now(), 0, 200);
        Test.stopTest();
    }

    @isTest
    static void syncContactsHttpError() {
        Account acct = SmartAdvTestFactory.createAccount();
        Contact con = SmartAdvTestFactory.createContact(acct.Id, '188514');

        Test.setMock(HttpCalloutMock.Class, new GetFilteredContactsHttpResponseError());

        SmartAdvTokenService stub = (SmartAdvTokenService) System.Test.createStub(SmartAdvTokenService.class, new SmartAdvTokenService_Stub('success'));
        SmartAdvContactService contactService = new SmartAdvContactService(stub);

        Test.startTest();
        SmartAdvContactService.ServiceResponse res = contactService.updateAllRecentContactsFromSmartAdvocate(Datetime.now().addDays(-1), Datetime.now(), 0, 200);
        Test.stopTest();
    }

    private class GetFilteredContactsHttpResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            res.setBody('[{"uniqueContactId":188514,"firstName":"Alina","lastName":"Ivanova","otherName":"","contactTypeId":10,"contactType":"General","comments":"","isDeleted":false,"dateOfBirth":"2015-06-08T00:00:00","ssnNo":"   -  -","isActive":true,"locked":false},{"uniqueContactId":188513,"firstName":"Marina","lastName":"Ivanova","otherName":"","contactTypeId":10,"contactType":"General","comments":"","isDeleted":false,"dateOfBirth":"1982-02-17T00:00:00","ssnNo":"   -  -","isActive":true,"locked":false},{"uniqueContactId":188512,"firstName":"Oleg","lastName":"Ivanov","otherName":"","contactTypeId":43,"contactType":"Client","comments":"","isDeleted":false,"dateOfBirth":"1980-10-24T00:00:00","ssnNo":"   -  -","isActive":true,"locked":false}]');
            return res;
        }
    }

    private class GetFilteredContactsHttpResponseError implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(400);
            res.setBody('');
            return res;
        }
    }
}