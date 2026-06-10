public class DocuSignDocumentQueueable implements Queueable, Database.AllowsCallouts {

    private String sessionId;

    public DocuSignDocumentQueueable(String sessionId) {
        this.sessionId = sessionId;
    }

    public void execute(QueueableContext ctx) {
        System.debug('=== DocuSignDocumentQueueable START: ' + sessionId);

        List<Intake_Session__c> sessions = [
            SELECT Id, Lead__c, Case__c,
                   DocuSign_Envelope_Id__c,
                   Signer_Name__c
            FROM   Intake_Session__c
            WHERE  Id                      = :sessionId
            AND    DocuSign_Envelope_Id__c != null
            AND    Document_Attached__c    != true
            LIMIT  1
        ];

        if (sessions.isEmpty()) {
            System.debug('⚠️ Session not found or already attached: ' + sessionId);
            return;
        }

        Intake_Session__c session = sessions[0];

        try {
            String accessToken          = DocuSignAuthService.getAccessToken();
            DocuSign_Config__mdt cfg    = DocuSignAuthService.loadConfig();

            // 1. Verify envelope is completed
            String status = getEnvelopeStatus(session.DocuSign_Envelope_Id__c, accessToken, cfg);
            System.debug('Envelope status: ' + status);

            if (status != 'completed') {
                System.debug('⚠️ Envelope not completed yet: ' + status);
                return;
            }

            // 2. Get document ID
            String docId = getFirstDocumentId(session.DocuSign_Envelope_Id__c, accessToken, cfg);

            // 3. Download PDF
            Blob pdfBlob = downloadDocument(session.DocuSign_Envelope_Id__c, docId, accessToken, cfg);

            if (pdfBlob == null || pdfBlob.size() == 0) {
                System.debug('❌ Empty PDF for session: ' + sessionId);
                return;
            }

            System.debug('PDF size: ' + pdfBlob.size());

            // 4. Build file name
            String safeName = String.isNotBlank(session.Signer_Name__c)
                ? session.Signer_Name__c
                          .replaceAll('[^a-zA-Z0-9 ]', '')
                          .trim()
                          .replace(' ', '_')
                : 'Client';

            String fileName = 'Signed_Intake_' + safeName +
                '_' + DateTime.now().format('yyyy-MM-dd') + '.pdf';

            // 5. Create ContentVersion — publish directly to Lead/Case
            ContentVersion cv         = new ContentVersion();
            cv.Title                  = fileName;
            cv.PathOnClient           = fileName;
            cv.VersionData            = pdfBlob;
            cv.IsMajorVersion         = true;
            cv.FirstPublishLocationId = session.Lead__c != null
                ? session.Lead__c : session.Case__c;
            insert cv;

            System.debug('✅ ContentVersion inserted: ' + cv.Id);

            // 6. Get ContentDocumentId
            ContentVersion inserted = [
                SELECT ContentDocumentId
                FROM   ContentVersion
                WHERE  Id = :cv.Id
                LIMIT  1
            ];

            // 7. Explicit link for visibility
            try {
                ContentDocumentLink cdl   = new ContentDocumentLink();
                cdl.ContentDocumentId     = inserted.ContentDocumentId;
                cdl.LinkedEntityId        = session.Lead__c != null
                    ? session.Lead__c : session.Case__c;
                cdl.ShareType             = 'V';
                cdl.Visibility            = 'AllUsers';
                insert cdl;
            } catch (Exception linkEx) {
                System.debug('Link note: ' + linkEx.getMessage());
            }

            // 8. Mark session as attached
            update new Intake_Session__c(
                Id                   = session.Id,
                Document_Attached__c = true,
                Document_Name__c     = fileName
            );

            System.debug('✅ Document attached to Lead/Case: ' + fileName);

        } catch (Exception e) {
            System.debug('❌ DocuSignDocumentQueueable failed: ' + e.getMessage());
            System.debug('Stack: ' + e.getStackTraceString());
        }
    }


    // ─────────────────────────────────────────
    // PRIVATE HELPERS
    // ─────────────────────────────────────────

    private String getEnvelopeStatus(
        String envelopeId, String accessToken, DocuSign_Config__mdt cfg
    ) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(cfg.Base_URI__c +
            '/restapi/v2.1/accounts/' + cfg.Account_ID__c +
            '/envelopes/' + envelopeId);
        req.setMethod('GET');
        req.setHeader('Authorization', 'Bearer ' + accessToken);
        req.setHeader('Content-Type', 'application/json');
        req.setTimeout(30000);

        HttpResponse res = new Http().send(req);
        if (res.getStatusCode() == 200) {
            Map<String, Object> resp =
                (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            return (String) resp.get('status');
        }
        return 'unknown';
    }


    private String getFirstDocumentId(
        String envelopeId, String accessToken, DocuSign_Config__mdt cfg
    ) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(cfg.Base_URI__c +
            '/restapi/v2.1/accounts/' + cfg.Account_ID__c +
            '/envelopes/' + envelopeId + '/documents');
        req.setMethod('GET');
        req.setHeader('Authorization', 'Bearer ' + accessToken);
        req.setHeader('Content-Type', 'application/json');
        req.setTimeout(30000);

        HttpResponse res = new Http().send(req);
        if (res.getStatusCode() == 200) {
            Map<String, Object> resp =
                (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            List<Object> docs = (List<Object>) resp.get('envelopeDocuments');
            for (Object docObj : docs) {
                Map<String, Object> doc = (Map<String, Object>) docObj;
                String docId   = (String) doc.get('documentId');
                String docType = (String) doc.get('type');
                System.debug('Doc: ' + docId + ' | Type: ' + docType);
                if (docType != 'summary' && docId != 'certificate') return docId;
            }
        }
        return '1';
    }


    private Blob downloadDocument(
        String envelopeId, String docId, String accessToken, DocuSign_Config__mdt cfg
    ) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(cfg.Base_URI__c +
            '/restapi/v2.1/accounts/' + cfg.Account_ID__c +
            '/envelopes/' + envelopeId +
            '/documents/' + docId);
        req.setMethod('GET');
        req.setHeader('Authorization', 'Bearer ' + accessToken);
        req.setHeader('Accept', 'application/pdf');
        req.setTimeout(30000);

        HttpResponse res = new Http().send(req);
        System.debug('Download status: ' + res.getStatusCode());
        if (res.getStatusCode() == 200) return res.getBodyAsBlob();
        System.debug('Download failed: ' + res.getBody());
        return null;
    }
}