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
            String accessToken       = DocuSignAuthService.getAccessToken();
            DocuSign_Config__mdt cfg = DocuSignAuthService.loadConfig();

            // 1. Verify envelope is completed
            String status = getEnvelopeStatus(
                session.DocuSign_Envelope_Id__c, accessToken, cfg
            );
            System.debug('Envelope status: ' + status);

            if (status != 'completed') {
                System.debug('⚠️ Not completed yet: ' + status);
                return;
            }

            // ── Build shared values ──
            String safeName = String.isNotBlank(session.Signer_Name__c)
                ? session.Signer_Name__c
                          .replaceAll('[^a-zA-Z0-9 ]', '')
                          .trim()
                          .replace(' ', '_')
                : 'Client';

            String dateStr  = DateTime.now().format('yyyy-MM-dd');
            String linkedId = session.Lead__c != null
                ? session.Lead__c : session.Case__c;

            // ── ALL CALLOUTS FIRST ──

            // 2. Get document ID
            String docId = getFirstDocumentId(
                session.DocuSign_Envelope_Id__c, accessToken, cfg
            );
            System.debug('Document ID: ' + docId);

            // 3. Download signed PDF
            Blob signedPdf = downloadDocument(
                session.DocuSign_Envelope_Id__c, docId, accessToken, cfg
            );
            System.debug('Signed PDF size: ' +
                (signedPdf != null ? signedPdf.size() : 0));

            // 4. Download completion certificate
            Blob certPdf = downloadDocument(
                session.DocuSign_Envelope_Id__c, 'certificate', accessToken, cfg
            );
            System.debug('Certificate size: ' +
                (certPdf != null ? certPdf.size() : 0));

            // ── ALL DML AFTER CALLOUTS ──

            // 5. Attach signed document
            if (signedPdf != null && signedPdf.size() > 0) {
                String fileName = 'Signed_Intake_' + safeName +
                    '_' + dateStr + '.pdf';
                attachToRecord(signedPdf, fileName, linkedId);
                System.debug('✅ Signed doc attached: ' + fileName);
            } else {
                System.debug('❌ Signed PDF empty');
            }

            // 6. Attach completion certificate
            if (certPdf != null && certPdf.size() > 0) {
                String certName = 'Signing_Certificate_' + safeName +
                    '_' + dateStr + '.pdf';
                attachToRecord(certPdf, certName, linkedId);
                System.debug('✅ Certificate attached: ' + certName);
            } else {
                System.debug('❌ Certificate empty or null');
            }

            // 7. Mark session as attached
            update new Intake_Session__c(
                Id                   = session.Id,
                Document_Attached__c = true,
                Document_Name__c     = 'Signed_Intake_' + safeName +
                    '_' + dateStr + '.pdf'
            );

            System.debug('✅ Session marked attached: ' + session.Id);

        } catch (Exception e) {
            System.debug('❌ Failed: ' + e.getMessage());
            System.debug('Stack: ' + e.getStackTraceString());
        }
    }


    // ─────────────────────────────────────────
    // PRIVATE HELPERS
    // ─────────────────────────────────────────

    private void attachToRecord(
        Blob fileBlob,
        String fileName,
        String recordId
    ) {
        // Create ContentVersion — publish directly to Lead
        ContentVersion cv         = new ContentVersion();
        cv.Title                  = fileName.replace('.pdf', '');
        cv.PathOnClient           = fileName;
        cv.VersionData            = fileBlob;
        cv.IsMajorVersion         = true;
        cv.FirstPublishLocationId = recordId;
        insert cv;

        System.debug('✅ ContentVersion: ' + cv.Id + ' | ' + fileName);

        // Get ContentDocumentId
        ContentVersion inserted = [
            SELECT ContentDocumentId
            FROM   ContentVersion
            WHERE  Id = :cv.Id
            LIMIT  1
        ];

        // Explicit link — FirstPublishLocationId already links it
        // but add explicit for visibility
        try {
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.ContentDocumentId   = inserted.ContentDocumentId;
            cdl.LinkedEntityId      = recordId;
            cdl.ShareType           = 'V';
            cdl.Visibility          = 'AllUsers';
            insert cdl;
        } catch (Exception linkEx) {
            // Already linked via FirstPublishLocationId — OK
            System.debug('Link note: ' + linkEx.getMessage());
        }
    }


    private String getEnvelopeStatus(
        String envelopeId,
        String accessToken,
        DocuSign_Config__mdt cfg
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
        String envelopeId,
        String accessToken,
        DocuSign_Config__mdt cfg
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
                if (docType != 'summary' && docId != 'certificate')
                    return docId;
            }
        }
        return '1';
    }


    private Blob downloadDocument(
        String envelopeId,
        String docId,
        String accessToken,
        DocuSign_Config__mdt cfg
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
        System.debug('Download [' + docId + '] status: ' +
            res.getStatusCode());

        if (res.getStatusCode() == 200) return res.getBodyAsBlob();

        System.debug('Download failed [' + docId + ']: ' + res.getBody());
        return null;
    }
}