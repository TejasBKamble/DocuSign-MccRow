/**
 * @description       : 
 * @testing           : 
 * @author            : FSM
 * @last modified on  : 05-27-2025 - FSM
 * @last modified by  : FSM
**/
@isTest
public class SmartAdvCaseService_Test {
    @isTest
    static void createCaseSuccess() {
        Account acct = SmartAdvTestFactory.createAccount();
        Contact con = SmartAdvTestFactory.createContact(acct.Id, null);
        Incident_Detail__c ind = SmartAdvTestFactory.createIncidentDetail(con.Id, null);
        SmartAdvCaseDto dto = SmartAdvTestFactory.createCaseDto(ind.Id, con.Id);

        Test.setMock(HttpCalloutMock.Class, new CreateCaseHttpResponse());

        SmartAdvTokenService stub = (SmartAdvTokenService) System.Test.createStub(SmartAdvTokenService.class, new SmartAdvTokenService_Stub('success'));
        SmartAdvCaseService caseService = new SmartAdvCaseService(stub);

        Test.startTest();
        List<SmartAdvCaseService.ServiceResponse> resList = caseService.createSmartAdvocateCase(new List<SmartAdvCaseDto> {dto});
        Test.stopTest();
    }

    @isTest
    static void createCaseTokenError() {
        Account acct = SmartAdvTestFactory.createAccount();
        Contact con = SmartAdvTestFactory.createContact(acct.Id, null);
        Incident_Detail__c ind = SmartAdvTestFactory.createIncidentDetail(con.Id, null);
        SmartAdvCaseDto dto = SmartAdvTestFactory.createCaseDto(ind.Id, con.Id);

        Test.setMock(HttpCalloutMock.Class, new CreateCaseHttpResponse());

        SmartAdvTokenService stub = (SmartAdvTokenService) System.Test.createStub(SmartAdvTokenService.class, new SmartAdvTokenService_Stub('error'));
        SmartAdvCaseService caseService = new SmartAdvCaseService(stub);

        Test.startTest();
        List<SmartAdvCaseService.ServiceResponse> resList = caseService.createSmartAdvocateCase(new List<SmartAdvCaseDto> {dto});
        Test.stopTest();
    }

    @isTest
    static void createCaseNoData() {
        Account acct = SmartAdvTestFactory.createAccount();
        Contact con = SmartAdvTestFactory.createContact(acct.Id, null);
        Incident_Detail__c ind = SmartAdvTestFactory.createIncidentDetail(con.Id, null);
        SmartAdvCaseDto dto = new SmartAdvCaseDto();

        Test.setMock(HttpCalloutMock.Class, new CreateCaseHttpResponse());

        SmartAdvTokenService stub = (SmartAdvTokenService) System.Test.createStub(SmartAdvTokenService.class, new SmartAdvTokenService_Stub('success'));
        SmartAdvCaseService caseService = new SmartAdvCaseService(stub);

        Test.startTest();
        List<SmartAdvCaseService.ServiceResponse> resList = caseService.createSmartAdvocateCase(new List<SmartAdvCaseDto> {dto});
        Test.stopTest();
    }

    @isTest
    static void createCaseHttpError() {
        Account acct = SmartAdvTestFactory.createAccount();
        Contact con = SmartAdvTestFactory.createContact(acct.Id, null);
        Incident_Detail__c ind = SmartAdvTestFactory.createIncidentDetail(con.Id, null);
        SmartAdvCaseDto dto = SmartAdvTestFactory.createCaseDto(ind.Id, con.Id);

        Test.setMock(HttpCalloutMock.Class, new CreateCaseHttpResponseError());

        SmartAdvTokenService stub = (SmartAdvTokenService) System.Test.createStub(SmartAdvTokenService.class, new SmartAdvTokenService_Stub('success'));
        SmartAdvCaseService caseService = new SmartAdvCaseService(stub);

        Test.startTest();
        List<SmartAdvCaseService.ServiceResponse> resList = caseService.createSmartAdvocateCase(new List<SmartAdvCaseDto> {dto});
        Test.stopTest();
    }

    @isTest
    static void syncCasesSuccess() {
        Account acct = SmartAdvTestFactory.createAccount();
        Contact con = SmartAdvTestFactory.createContact(acct.Id, null);
        Incident_Detail__c ind = SmartAdvTestFactory.createIncidentDetail(con.Id, '518512');

        Test.setMock(HttpCalloutMock.Class, new GetFilteredCasesHttpResponse());

        SmartAdvTokenService stub = (SmartAdvTokenService) System.Test.createStub(SmartAdvTokenService.class, new SmartAdvTokenService_Stub('success'));
        SmartAdvCaseService caseService = new SmartAdvCaseService(stub);

        Test.startTest();
        SmartAdvCaseService.ServiceResponse res = caseService.updateAllRecentCaseStatusFromSmartAdvocate(Datetime.now().addDays(-1), Datetime.now(), 0, 200);
        Test.stopTest();
    }

    @isTest
    static void syncCasesTokenError() {
        Account acct = SmartAdvTestFactory.createAccount();
        Contact con = SmartAdvTestFactory.createContact(acct.Id, null);
        Incident_Detail__c ind = SmartAdvTestFactory.createIncidentDetail(con.Id, '518512');

        Test.setMock(HttpCalloutMock.Class, new GetFilteredCasesHttpResponse());

        SmartAdvTokenService stub = (SmartAdvTokenService) System.Test.createStub(SmartAdvTokenService.class, new SmartAdvTokenService_Stub('error'));
        SmartAdvCaseService caseService = new SmartAdvCaseService(stub);

        Test.startTest();
        SmartAdvCaseService.ServiceResponse res = caseService.updateAllRecentCaseStatusFromSmartAdvocate(Datetime.now().addDays(-1), Datetime.now(), 0, 200);
        Test.stopTest();
    }

    @isTest
    static void syncCasesHttpError() {
        Account acct = SmartAdvTestFactory.createAccount();
        Contact con = SmartAdvTestFactory.createContact(acct.Id, null);
        Incident_Detail__c ind = SmartAdvTestFactory.createIncidentDetail(con.Id, '518512');

        Test.setMock(HttpCalloutMock.Class, new GetFilteredCasesHttpResponseError());

        SmartAdvTokenService stub = (SmartAdvTokenService) System.Test.createStub(SmartAdvTokenService.class, new SmartAdvTokenService_Stub('success'));
        SmartAdvCaseService caseService = new SmartAdvCaseService(stub);

        Test.startTest();
        SmartAdvCaseService.ServiceResponse res = caseService.updateAllRecentCaseStatusFromSmartAdvocate(Datetime.now().addDays(-1), Datetime.now(), 0, 200);
        Test.stopTest();
    }

    private class CreateCaseHttpResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            res.setBody('{"caseID":4706,"caseNumber":"25-0196","caseName":"Test Case Contact, Test v. Doe, John","caseGroupID":142,"caseGroup":"3 Premises Liability","caseTypeID":1625,"caseType":"Animal Attack","caseStatusID":52,"caseStatus":"Pre-Lit 00 - Under Consideration","caseStatusFrom":"2025-05-01T15:24:00-04:00","caseOpenedDate":"2025-05-01T15:24:24.33-04:00","officeID":6,"officeName":"McCraw Law Group - Valliance Bldg","incident":{"incidentFacts":"Fourth Case with Test Case Contact","mergedFacts":"","comments":"","state":"IN"},"plaintiffs":[{"id":6956,"name":"Test Case Contact, Test","roleID":25633,"role":"(P)-Plaintiff","contactID":155754,"primary":true,"primaryContact":true,"missing":false,"markedAsRemoved":false,"client":false,"group":1,"tableType":"Main"}],"defendant":[{"id":7889,"name":"Doe, John","roleID":25640,"contactID":19,"primary":true,"comments":"","markedAsRemoved":false,"client":false}],"secondStatuses":[],"caseStaff":[{"uniqueContactId":18,"firstName":"Staff","lastName":"Unassigned","email":"smartadvocate@mccrawlawgroup.com","createdDate":"2025-05-01T15:24:00-04:00"},{"uniqueContactId":16783,"firstName":"Kyra","lastName":"Stull","email":"kstull@mccrawlawgroup.com","role":"Paralegal","phone":"(469) 500-5028","createdDate":"2025-05-01T15:24:00-04:00"}],"subTypes":[],"createdDate":"2025-05-01T15:24:24.33-04:00","modifiedDate":"2025-05-01T15:24:25.437-04:00"}');
            return res;
        }
    }

    private class CreateCaseHttpResponseError implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(400);
            res.setBody('');
            return res;
        }
    }

    private class GetFilteredCasesHttpResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            res.setBody('[{"caseID":518512,"caseNumber":"2 - 000015","caseName":"Langust (ADU) v. ","caseGroupID":138,"caseGroup":"General Negligence","caseTypeID":1347,"caseType":"Boat Accident","caseStatusID":665,"caseStatus":"Presign - Out Attorney Needs to Respond","caseStatusFrom":"2022-08-26T16:39:00-04:00","officeID":2,"officeName":"New York","incident":{"incidentDate":"2022-04-01T00:00:00-04:00","incidentFacts":"Got cought","mergedFacts":"","comments":"","state":"AK"},"plaintiffs":[{"id":622292,"name":"Langust, Mikurilo","roleID":21638,"role":"(P)-Boat Passenger","contactID":1697660,"primary":true,"primaryContact":true,"missing":false,"markedAsRemoved":false,"client":false,"contact":{"contactId":1697660,"contactCtg":1,"firstName":"Mikurilo","lastName":"Langust","middleName":"","prefix":"Mr.","suffix":"","nickName":"","maidenName":"","contactTypeId":10,"contactSubCtgID":1,"contactType":"General","contactSubCtg":"Adult","comments":"","dateOfBirth":"1980-07-29T00:00:00","genderID":1,"birthPlace":"","occupation":"","spouse":"","einNo":"","ssnNo":"   -  -","primaryLanguage":"","secondaryLanguage":"","licenseNo":"","licenseStateID":0,"noSSN":false,"active":true,"preventAutoContact":false,"preventMailing":false,"locked":false,"addresses":[{"addressID":840248,"primary":true,"residence":false,"current":true,"mailing":true,"createdDate":"2022-04-08T12:49:00-04:00"}],"emails":[],"phones":[{"phoneID":433,"name":"Originating Phone","phoneNumber":"(123) 325-4565","primary":true,"useForTexting":false,"preventAutoContact":false,"createdDate":"2022-04-08T12:49:00-04:00","modifiedDate":"2022-04-08T12:50:00-04:00"}],"createdDate":"2022-04-08T12:48:59.607-04:00","modifiedDate":"2022-07-28T13:19:54.3-04:00"},"tableType":"Main"}],"defendant":[{"id":834083,"roleID":21622,"role":"(D)-MUN Boat Operator","primary":true,"markedAsRemoved":false,"client":false}],"secondStatuses":[],"caseStaff":[{"uniqueContactId":1492959,"firstName":"Andrey","lastName":"OKrasnoov","email":"andrey@smartadvocate.com","role":"Paralegal","phone":"(267) 992-0922","createdDate":"2022-06-10T12:47:00-04:00"},{"uniqueContactId":1504572,"firstName":"Stephanie","lastName":"Alvarez","email":"salvarez@zzyourlawyer.com","role":"Case Manager","createdDate":"2023-06-16T09:29:00-04:00"}],"subTypes":[{"id":9126,"description":"Defective Boat"}],"referrals":[{"contactID":268330,"type":"Paid Advertisement","name":"800-BIG-SPILL"}],"createdDate":"2022-08-26T16:39:00-04:00","modifiedDate":"2022-07-29T15:35:00-04:00"}]');
            return res;
        }
    }

    private class GetFilteredCasesHttpResponseError implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(400);
            res.setBody('');
            return res;
        }
    }
}