/**
 * @description       : 
 * @testing           : 
 * @author            : FSM
 * @last modified on  : 05-29-2025 - FSM
 * @last modified by  : FSM
**/
public class SmartAdvEventHandlerCreateDocument implements ISmartAdvEventHandler {
    private SmartAdvDocumentService documentService;

    // Default constructor
    public SmartAdvEventHandlerCreateDocument() {
        this(new SmartAdvDocumentService());
    }

    // Constructor for injecting mock/stub
    public SmartAdvEventHandlerCreateDocument(SmartAdvDocumentService service) {
        this.documentService = service;
    }

    public ApiEventResponse handle(API_Event__c event) {
        ApiEventResponse res = new ApiEventResponse();

        ContentDocumentLink cdl = [
            SELECT
                Id,
                LinkedEntityId,
                ContentDocument.Id,
                ContentDocument.Title,
                ContentDocument.CreatedDate,
                ContentDocument.LatestPublishedVersion.CreatedDate,
                ContentDocument.LatestPublishedVersion.Id,
                ContentDocument.LatestPublishedVersion.FileExtension,
                ContentDocument.LatestPublishedVersion.ContentSize,
                ContentDocument.LatestPublishedVersion.VersionData
            FROM ContentDocumentLink
            WHERE
                Id =: event.Related_Record_ID__c
        ];

        Incident_Detail__c ind = [SELECT Id, SmartAdvocate_ID__c FROM Incident_Detail__c WHERE Id =: cdl.LinkedEntityId];

        SmartAdvDocumentDto docDto = SmartAdvDocumentTranslator.documentFromCdl(cdl, ind.SmartAdvocate_ID__c);
        List<SmartAdvDocumentService.ServiceResponse> srListInsertDocParams = documentService.insertDocParams(new List<SmartAdvDocumentDto> {docDto});

        if (!srListInsertDocParams[0].isSuccess) {
            res.isSuccess = false;
            res.errorMessage = srListInsertDocParams[0].errorMessage;
            return res;
        }

        String docId = srListInsertDocParams[0].smartAdvId;
        List<SmartAdvDocumentService.ServiceResponse> srListUploadDoc = documentService.uploadDocument(new List<ContentDocumentLink> {cdl}, new List<String> {docId});
        
        if (!srListUploadDoc[0].isSuccess) {
            res.isSuccess = false;
            res.errorMessage = srListUploadDoc[0].errorMessage;
            return res;
        }
        
        res.isSuccess = true;
        return res;
    }
}