public class DocuSignDocumentService {

    public static void attachSignedDocument(
        String envelopeId,
        String leadId,
        String signerName
    ) {
        System.debug('=== Attaching Signed Document ===');
        System.debug('Envelope ID: ' + envelopeId);
        System.debug('Lead ID    : ' + leadId);

        try {
            String accessToken = DocuSignAuthService.getAccessToken();
            DocuSign_Config__mdt cfg = DocuSignAuthService.loadConfig();

            // ── Step 1: Check envelope status first ──
            String envelopeStatus = getEnvelopeStatus(
                envelopeId, accessToken, cfg
            );
            System.debug('Envelope Status: ' + envelopeStatus);

            if (envelopeStatus != 'completed') {
                System.debug('❌ Envelope not completed yet: ' + envelopeStatus);
                return;
            }

            // ── Step 2: Get document list ──
            String docId = getFirstDocumentId(
                envelopeId, accessToken, cfg
            );
            System.debug('Document ID: ' + docId);

            // ── Step 3: Download the specific signed document ──
            String endpoint = cfg.Base_URI__c +
                '/restapi/v2.1/accounts/' + cfg.Account_ID__c +
                '/envelopes/' + envelopeId +
                '/documents/' + docId;

            HttpRequest req = new HttpRequest();
            req.setEndpoint(endpoint);
            req.setMethod('GET');
            req.setHeader('Authorization', 'Bearer ' + accessToken);
            req.setHeader('Accept', 'application/pdf');
            req.setTimeout(30000);

            HttpResponse res = new Http().send(req);

            System.debug('Download Status: ' + res.getStatusCode());

            if (res.getStatusCode() != 200) {
                System.debug('❌ Download failed: ' + res.getBody());
                return;
            }

            Blob pdfBlob = res.getBodyAsBlob();
            System.debug('PDF Size: ' + pdfBlob.size() + ' bytes');

            if (pdfBlob.size() == 0) {
                System.debug('❌ Empty PDF');
                return;
            }

            // ── Step 4: Create Salesforce File ──
            String safeName = String.isNotBlank(signerName)
                ? signerName.replaceAll('[^a-zA-Z0-9 ]', '')
                            .trim()
                            .replace(' ', '_')
                : 'Client';

            String fileName = 'Signed_Intake_' + safeName +
                '_' + DateTime.now().format('yyyy-MM-dd') + '.pdf';

            ContentVersion cv = new ContentVersion();
            cv.Title          = fileName;
            cv.PathOnClient   = fileName;
            cv.VersionData    = pdfBlob;
            cv.IsMajorVersion = true;
            insert cv;

            System.debug('✅ File created: ' + cv.Id);

            // ── Step 5: Link to Lead ──
            ContentVersion inserted = [
                SELECT ContentDocumentId
                FROM   ContentVersion
                WHERE  Id = :cv.Id
                LIMIT  1
            ];

            if (String.isNotBlank(leadId)) {
                ContentDocumentLink cdl = new ContentDocumentLink();
                cdl.ContentDocumentId  = inserted.ContentDocumentId;
                cdl.LinkedEntityId     = leadId;
                cdl.ShareType          = 'V';
                cdl.Visibility         = 'AllUsers';
                insert cdl;
                System.debug('✅ Linked to Lead: ' + leadId);
            }

        } catch (Exception e) {
            System.debug('❌ FAILED: ' + e.getMessage());
            System.debug('Stack   : ' + e.getStackTraceString());
        }
    }


    // ── Get envelope status ──
    private static String getEnvelopeStatus(
        String envelopeId,
        String accessToken,
        DocuSign_Config__mdt cfg
    ) {
        String endpoint = cfg.Base_URI__c +
            '/restapi/v2.1/accounts/' + cfg.Account_ID__c +
            '/envelopes/' + envelopeId;

        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('GET');
        req.setHeader('Authorization', 'Bearer ' + accessToken);
        req.setHeader('Content-Type', 'application/json');
        req.setTimeout(30000);

        HttpResponse res = new Http().send(req);
        System.debug('Status Check Response: ' + res.getBody());

        if (res.getStatusCode() == 200) {
            Map<String, Object> resp =
                (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            return (String) resp.get('status');
        }
        return 'unknown';
    }


    // ── Get first document ID from envelope ──
    private static String getFirstDocumentId(
        String envelopeId,
        String accessToken,
        DocuSign_Config__mdt cfg
    ) {
        String endpoint = cfg.Base_URI__c +
            '/restapi/v2.1/accounts/' + cfg.Account_ID__c +
            '/envelopes/' + envelopeId + '/documents';

        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('GET');
        req.setHeader('Authorization', 'Bearer ' + accessToken);
        req.setHeader('Content-Type', 'application/json');
        req.setTimeout(30000);

        HttpResponse res = new Http().send(req);
        System.debug('Document List: ' + res.getBody());

        if (res.getStatusCode() == 200) {
            Map<String, Object> resp =
                (Map<String, Object>) JSON.deserializeUntyped(res.getBody());

            List<Object> docs = (List<Object>) resp.get('envelopeDocuments');
            System.debug('Total documents: ' + docs.size());

            for (Object docObj : docs) {
                Map<String, Object> doc = (Map<String, Object>) docObj;
                String docId   = (String) doc.get('documentId');
                String docName = (String) doc.get('name');
                String docType = (String) doc.get('type');
                System.debug('Doc: ' + docId + ' | ' + docName + ' | ' + docType);

                // Skip summary/certificate documents
                if (docType != 'summary' && docId != 'certificate') {
                    return docId;
                }
            }
        }
        // Default fallback
        return '1';
    }
}