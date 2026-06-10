/**
 * @description       : 
 * @testing           : 
 * @author            : FSM
 * @last modified on  : 05-30-2025 - FSM
 * @last modified by  : FSM
**/
@isTest
public class SmartAdvDocumentService_Test {
    @isTest
    static void insertDocParamsSuccess() {
        List<SmartAdvDocumentDto> dtoList = new List<SmartAdvDocumentDto>();
        SmartAdvDocumentDto dto = new SmartAdvDocumentDto();
        dto.caseID = 123;
        dto.documentName = 'My Test Doc';
        dto.docType = 'Img';
        dtoList.add(dto);

        Test.setMock(HttpCalloutMock.Class, new InsertDocParamsHttpResponse());

        SmartAdvTokenService stub = (SmartAdvTokenService) System.Test.createStub(SmartAdvTokenService.class, new SmartAdvTokenService_Stub('success'));
        SmartAdvDocumentService documentService = new SmartAdvDocumentService(stub);

        Test.startTest();
        List<SmartAdvDocumentService.ServiceResponse> resList = documentService.insertDocParams(dtoList);
        Test.stopTest();
    }

    @isTest
    static void insertDocParamsTokenError() {
        List<SmartAdvDocumentDto> dtoList = new List<SmartAdvDocumentDto>();
        SmartAdvDocumentDto dto = new SmartAdvDocumentDto();
        dto.caseID = 123;
        dto.documentName = 'My Test Doc';
        dto.docType = 'Img';
        dtoList.add(dto);

        Test.setMock(HttpCalloutMock.Class, new InsertDocParamsHttpResponse());

        SmartAdvTokenService stub = (SmartAdvTokenService) System.Test.createStub(SmartAdvTokenService.class, new SmartAdvTokenService_Stub('error'));
        SmartAdvDocumentService documentService = new SmartAdvDocumentService(stub);

        Test.startTest();
        List<SmartAdvDocumentService.ServiceResponse> resList = documentService.insertDocParams(dtoList);
        Test.stopTest();
    }

    @isTest
    static void insertDocParamsHttpError() {
        List<SmartAdvDocumentDto> dtoList = new List<SmartAdvDocumentDto>();
        SmartAdvDocumentDto dto = new SmartAdvDocumentDto();
        dto.caseID = 123;
        dto.documentName = 'My Test Doc';
        dto.docType = 'Img';
        dtoList.add(dto);

        Test.setMock(HttpCalloutMock.Class, new InsertDocParamsHttpResponseError());

        SmartAdvTokenService stub = (SmartAdvTokenService) System.Test.createStub(SmartAdvTokenService.class, new SmartAdvTokenService_Stub('success'));
        SmartAdvDocumentService documentService = new SmartAdvDocumentService(stub);

        Test.startTest();
        List<SmartAdvDocumentService.ServiceResponse> resList = documentService.insertDocParams(dtoList);
        Test.stopTest();
    }

    @isTest
    static void insertDocParamsRequiredFieldError() {
        List<SmartAdvDocumentDto> dtoList = new List<SmartAdvDocumentDto>();
        SmartAdvDocumentDto dto = new SmartAdvDocumentDto();
        dtoList.add(dto);

        Test.setMock(HttpCalloutMock.Class, new InsertDocParamsHttpResponse());

        SmartAdvTokenService stub = (SmartAdvTokenService) System.Test.createStub(SmartAdvTokenService.class, new SmartAdvTokenService_Stub('success'));
        SmartAdvDocumentService documentService = new SmartAdvDocumentService(stub);

        Test.startTest();
        List<SmartAdvDocumentService.ServiceResponse> resList = documentService.insertDocParams(dtoList);
        Test.stopTest();
    }

    @isTest
    static void uploadDocSuccess() {
        Incident_Detail__c ind = [SELECT Id FROM Incident_Detail__c LIMIT 1];

        ContentVersion cv = new ContentVersion(
            Title = 'Test Document',
            PathOnClient = 'test.pdf',
            VersionData = Blob.valueOf('Test Content'),
            IsMajorVersion = true
        );
        insert cv;

        Id cdId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;
        
        ContentDocumentLink cdl = new ContentDocumentLink(
            LinkedEntityId = ind.Id,
            ContentDocumentId = cdId,
            ShareType = 'V'
        );
        insert cdl;

        Test.setMock(HttpCalloutMock.Class, new UploadDocHttpResponse());

        SmartAdvTokenService stub = (SmartAdvTokenService) System.Test.createStub(SmartAdvTokenService.class, new SmartAdvTokenService_Stub('success'));
        SmartAdvDocumentService documentService = new SmartAdvDocumentService(stub);

        Test.startTest();
        List<SmartAdvDocumentService.ServiceResponse> resList = documentService.uploadDocument(new List<ContentDocumentLink> {cdl}, new List<String> {'2182309'});
        Test.stopTest();
    }

    @isTest
    static void uploadDocTokenError() {
        Incident_Detail__c ind = [SELECT Id FROM Incident_Detail__c LIMIT 1];
        
        ContentVersion cv = new ContentVersion(
            Title = 'Test Document',
            PathOnClient = 'test.pdf',
            VersionData = Blob.valueOf('Test Content'),
            IsMajorVersion = true
        );
        insert cv;

        Id cdId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;
        
        ContentDocumentLink cdl = new ContentDocumentLink(
            LinkedEntityId = ind.Id,
            ContentDocumentId = cdId,
            ShareType = 'V'
        );
        insert cdl;

        Test.setMock(HttpCalloutMock.Class, new UploadDocHttpResponse());

        SmartAdvTokenService stub = (SmartAdvTokenService) System.Test.createStub(SmartAdvTokenService.class, new SmartAdvTokenService_Stub('error'));
        SmartAdvDocumentService documentService = new SmartAdvDocumentService(stub);

        Test.startTest();
        List<SmartAdvDocumentService.ServiceResponse> resList = documentService.uploadDocument(new List<ContentDocumentLink> {cdl}, new List<String> {'2182309'});
        Test.stopTest();
    }

    @isTest
    static void uploadDocHttpError() {
        Incident_Detail__c ind = [SELECT Id FROM Incident_Detail__c LIMIT 1];
        
        ContentVersion cv = new ContentVersion(
            Title = 'Test Document',
            PathOnClient = 'test.pdf',
            VersionData = Blob.valueOf('Test Content'),
            IsMajorVersion = true
        );
        insert cv;

        Id cdId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;
        
        ContentDocumentLink cdl = new ContentDocumentLink(
            LinkedEntityId = ind.Id,
            ContentDocumentId = cdId,
            ShareType = 'V'
        );
        insert cdl;

        Test.setMock(HttpCalloutMock.Class, new UploadDocHttpResponseError());

        SmartAdvTokenService stub = (SmartAdvTokenService) System.Test.createStub(SmartAdvTokenService.class, new SmartAdvTokenService_Stub('success'));
        SmartAdvDocumentService documentService = new SmartAdvDocumentService(stub);

        Test.startTest();
        List<SmartAdvDocumentService.ServiceResponse> resList = documentService.uploadDocument(new List<ContentDocumentLink> {cdl}, new List<String> {'2182309'});
        Test.stopTest();
    }

    @isTest
    static void uploadDocRequiredFieldError() {
        Incident_Detail__c ind = [SELECT Id FROM Incident_Detail__c LIMIT 1];
        
        ContentVersion cv = new ContentVersion(
            Title = 'Test Document',
            PathOnClient = 'test.pdf',
            VersionData = Blob.valueOf('Test Content'),
            IsMajorVersion = true
        );
        insert cv;

        Id cdId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;
        
        ContentDocumentLink cdl = new ContentDocumentLink(
            LinkedEntityId = ind.Id,
            ContentDocumentId = cdId,
            ShareType = 'V'
        );
        insert cdl;

        Test.setMock(HttpCalloutMock.Class, new UploadDocHttpResponse());

        SmartAdvTokenService stub = (SmartAdvTokenService) System.Test.createStub(SmartAdvTokenService.class, new SmartAdvTokenService_Stub('success'));
        SmartAdvDocumentService documentService = new SmartAdvDocumentService(stub);

        Test.startTest();
        List<SmartAdvDocumentService.ServiceResponse> resList = documentService.uploadDocument(new List<ContentDocumentLink> {cdl}, new List<String> {''});
        Test.stopTest();
    }

    private class InsertDocParamsHttpResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            res.setBody('{"documentID":2182309,"caseID":516718,"caseNumber":"9000002","documentName":"IS190323 Forms Retainer Agreements SmartAdvocate, LLC 06-23-2020.pdf","fromUniqueContactID":258104,"fromContactName":"Parker Waichman LLP","docType":"Img","templateID":0,"attachFlag":true,"description":"test","createdUserID":677,"createdDate":"2021-05-28T15:33:00Z","categoryID":1,"categoryName":"Appeals","subCategoryID":1,"subCategoryName":"Brief","medProvUniqueContactID":276115,"comments":"test","isReviewed":false,"toUniqueContactID":258104,"priority":3,"priorityName":"Normal","documentDirection":1,"directionName":"Incoming","documentOrigin":2,"originName":"Attached","isSharedInPortal":false,"isSharedWithEveryoneInPortal":true,"documentFolder":"TestFolder","deliveryMethodId":3,"deliveryName":"FedEx","caseDocumentID":129,"medProviderName":"Moody Airforce Base -PHARMACY"}');
            return res;
        }
    }

    private class InsertDocParamsHttpResponseError implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(400);
            res.setBody('');
            return res;
        }
    }

    private class UploadDocHttpResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            res.setBody('{"documentID":2182313,"caseID":516718,"caseNumber":"9000002","documentName":"swg_icon_2.pdf","fromUniqueContactID":249798,"toContactName":"Parker Waichman LLP","fromContactName":"2775 Linden Blvd.,LLC","docType":"pdf","templateID":0,"attachFlag":true,"description":"swg_icon.pdf (Received from Retrieval Service)","createdUserID":368,"createdDate":"2021-05-28T16:53:00Z","modifiedDate":"2021-05-28T16:53:00Z","categoryID":21,"categoryName":"Medical","subCategoryID":553,"subCategoryName":"Medical Records Summary","comments":"test doc comment","reviewerContactId":368,"reviewDate":"2021-05-28T16:53:15.377Z","isReviewed":false,"toUniqueContactID":258104,"documentDate":"2021-05-28T16:53:00Z","priority":2,"priorityName":"High","documentDirection":1,"directionName":"Incoming","documentOrigin":2,"originName":"Attached","reviewerName":"Fre, "}');
            return res;
        }
    }

    private class UploadDocHttpResponseError implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(400);
            res.setBody('');
            return res;
        }
    }

    @TestSetup
    static void makeData(){
        Account acct = SmartAdvTestFactory.createAccount();
        Contact con = SmartAdvTestFactory.createContact(acct.Id, '11111');
        Incident_Detail__c ind = SmartAdvTestFactory.createIncidentDetail(con.Id, '22222');
    }
}