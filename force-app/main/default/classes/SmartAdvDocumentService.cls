/**
 * @description       : 
 * @testing           : 
 * @author            : FSM
 * @last modified on  : 05-29-2025 - FSM
 * @last modified by  : FSM
**/
public class SmartAdvDocumentService {
    private SmartAdvTokenService tokenService;

    // Default constructor
    public SmartAdvDocumentService() {
        this(new SmartAdvTokenService());
    }

    // Constructor for injecting mock/stub
    public SmartAdvDocumentService(SmartAdvTokenService service) {
        this.tokenService = service;
    }

    public List<ServiceResponse> insertDocParams(List<SmartAdvDocumentDto> dList) {
        List<ServiceResponse> srList = new List<ServiceResponse>();
        for (SmartAdvDocumentDto d : dList) {
            srList.add(new ServiceResponse());
        }

        String token;
        SmartAdvTokenService.ServiceResponse srToken = tokenService.getToken();
        if (srToken.isSuccess) {
            token = srToken.token;
        }
        else {
            for (Integer i=0; i < dList.size(); i++) {
                srList[i].isSuccess = false;
                srList[i].errorMessage = srToken.errorMessage;
            }
            return srList;
        }

        for (Integer i=0; i < dList.size(); i++) {
            SmartAdvDocumentDto d = dList[i];

            // Check that all required fields are provided, send back an error if not provided
            List<String> errors = new List<String>();

            if (d.caseID == null) {
                errors.add('No Case ID provided.');
            }
            if (String.isBlank(d.documentName)) {
                errors.add('No Document Name provided.');
            }
            if (d.docType == null) {
                errors.add('No Document Type provided.');
            }
            if (errors.size() > 0) {
                srList[i].isSuccess = false;
                srList[i].errorMessage = String.join(errors, ' ');
                continue;
            }

            String saDocId;
            try {
                SmartAdvCalloutInsertDocParams callInsertDocParams = new SmartAdvCalloutInsertDocParams(token, d);
                HttpResponse resInsertDocParams = callInsertDocParams.doCallout();
                Map<String,Object> resMapInsertDocParams = (Map<String,Object>) JSON.deserializeUntyped(resInsertDocParams.getBody());
                saDocId = String.valueOf(resMapInsertDocParams.get('documentID'));
            }
            catch (Exception e) {
                srList[i].isSuccess = false;
                srList[i].errorMessage = 'HTTP Error (Insert Doc Params) -- ' + e.getMessage();
                continue;
            }

            srList[i].isSuccess = true;
            srList[i].smartAdvId = saDocId;
        }

        return srList;
    }

    public List<ServiceResponse> uploadDocument(List<ContentDocumentLink> cdlList, List<String> docIdList) {
        List<ServiceResponse> srList = new List<ServiceResponse>();
        for (ContentDocumentLink cdl : cdlList) {
            srList.add(new ServiceResponse());
        }

        String token;
        SmartAdvTokenService.ServiceResponse srToken = tokenService.getToken();
        if (srToken.isSuccess) {
            token = srToken.token;
        }
        else {
            for (Integer i=0; i < cdlList.size(); i++) {
                srList[i].isSuccess = false;
                srList[i].errorMessage = srToken.errorMessage;
            }
            return srList;
        }

        for (Integer i=0; i < cdlList.size(); i++) {
            ContentDocumentLink cdl = cdlList[i];
            String docId = docIdList[i];

            // Check that all required fields are provided, send back an error if not provided
            List<String> errors = new List<String>();

            if (String.isBlank(docId)) {
                errors.add('No SmartAdvocate Document ID provided.');
            }
            if (errors.size() > 0) {
                srList[i].isSuccess = false;
                srList[i].errorMessage = String.join(errors, ' ');
                continue;
            }

            try {
                SmartAdvCalloutUploadDoc callUploadDoc = new SmartAdvCalloutUploadDoc(token, cdl, docId);
                HttpResponse resUploadDoc = callUploadDoc.doCallout();
            }
            catch (Exception e) {
                srList[i].isSuccess = false;
                srList[i].errorMessage = 'HTTP Error (Upload Document) -- ' + e.getMessage();
                continue;
            }

            srList[i].isSuccess = true;
        }

        return srList;
    }

    public class ServiceResponse {
        public Boolean isSuccess;
        public String errorMessage;
        public String smartAdvId;
    }
}