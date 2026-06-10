/**
 * @description       : 
 * @testing           : 
 * @author            : FSM
 * @last modified on  : 05-30-2025 - FSM
 * @last modified by  : FSM
**/
@isTest
public class SmartAdvEventHandlerCreateDocument_Test {
    @isTest
    static void testSuccess() {
        Account acct = [SELECT Id FROM Account LIMIT 1];
        Contact con = [SELECT Id FROM Contact LIMIT 1];
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
        
        API_Event__c ev = new API_Event__c(
            Related_Record_ID__c = cdl.Id
        );
        insert ev;

        SmartAdvDocumentService stub = (SmartAdvDocumentService) System.Test.createStub(SmartAdvDocumentService.class, new SmartAdvDocumentService_Stub('success'));
        SmartAdvEventHandlerCreateDocument handler = new SmartAdvEventHandlerCreateDocument(stub);

        ApiEventResponse res = handler.handle(ev);

        System.assertEquals(true, res.isSuccess);
        System.assertEquals(null, res.errorMessage);
    }

    @isTest
    static void testErrorInsertDocParams() {
        Account acct = [SELECT Id FROM Account LIMIT 1];
        Contact con = [SELECT Id FROM Contact LIMIT 1];
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
        
        API_Event__c ev = new API_Event__c(
            Related_Record_ID__c = cdl.Id
        );
        insert ev;

        SmartAdvDocumentService stub = (SmartAdvDocumentService) System.Test.createStub(SmartAdvDocumentService.class, new SmartAdvDocumentService_Stub('error insertDocParams'));
        SmartAdvEventHandlerCreateDocument handler = new SmartAdvEventHandlerCreateDocument(stub);

        ApiEventResponse res = handler.handle(ev);

        System.assertEquals(false, res.isSuccess);
        System.assertEquals('Simulated Error insertDocParams!', res.errorMessage);
    }

    @isTest
    static void testErrorUploadDocument() {
        Account acct = [SELECT Id FROM Account LIMIT 1];
        Contact con = [SELECT Id FROM Contact LIMIT 1];
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
        
        API_Event__c ev = new API_Event__c(
            Related_Record_ID__c = cdl.Id
        );
        insert ev;

        SmartAdvDocumentService stub = (SmartAdvDocumentService) System.Test.createStub(SmartAdvDocumentService.class, new SmartAdvDocumentService_Stub('error uploadDocument'));
        SmartAdvEventHandlerCreateDocument handler = new SmartAdvEventHandlerCreateDocument(stub);

        ApiEventResponse res = handler.handle(ev);

        System.assertEquals(false, res.isSuccess);
        System.assertEquals('Simulated Error uploadDocument!', res.errorMessage);
    }

    @TestSetup
    static void makeData(){
        Account acct = SmartAdvTestFactory.createAccount();
        Contact con = SmartAdvTestFactory.createContact(acct.Id, '11111');
        Incident_Detail__c ind = SmartAdvTestFactory.createIncidentDetail(con.Id, '22222');
    }
}