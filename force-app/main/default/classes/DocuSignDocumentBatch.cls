/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* Main Document Creater batch class for Create a Document Related to Lead in a Salesforce .
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Tejas 
* @modifiedBy     Tejas 
* @maintainedBy   Tejas
* @version        1.1
* @created        2026-11-5
* @modified       2026-11-5
* ──────────────────────────────────────────────────────────────────────────────────────────────────
*/


public class DocuSignDocumentBatch implements Database.Batchable<SObject>,
                                               Database.AllowsCallouts,
                                               Database.Stateful {

    // ── Store results for logging ──
    private Integer processed = 0;
    private Integer success   = 0;
    private Integer failed    = 0;
    private List<String> errors = new List<String>();

    // ── Process only Signed sessions without attachment ──
  public Database.QueryLocator start(Database.BatchableContext bc) {
    System.debug('=== DocuSignDocumentBatch START ===');

    // ── Count matching records first ──
    Integer count = [
        SELECT COUNT()
        FROM   Intake_Session__c
        WHERE  Status__c               = 'Signed'
        AND    DocuSign_Envelope_Id__c != null
        AND    Lead__c                 != null
        AND    (Document_Attached__c   = false
                OR Document_Attached__c = null)
    ];
    System.debug('Records to process: ' + count);

    return Database.getQueryLocator([
        SELECT Id, Lead__c, Case__c,
               DocuSign_Envelope_Id__c,
               Signer_Name__c, Status__c,
               Document_Attached__c
        FROM   Intake_Session__c
        WHERE  Status__c               = 'Signed'
        AND    DocuSign_Envelope_Id__c != null
        AND    Lead__c                 != null
        AND    Document_Attached__c    != true  

    ]);
}


public void execute(
    Database.BatchableContext bc,
    List<Intake_Session__c> sessions
) {
    System.debug('Processing: ' + sessions.size() + ' sessions');

    String accessToken;
    DocuSign_Config__mdt cfg;

    try {
        accessToken = DocuSignAuthService.getAccessToken();
        cfg         = DocuSignAuthService.loadConfig();
    } catch (Exception e) {
        System.debug('❌ Auth failed: ' + e.getMessage());
        return;
    }

    List<Intake_Session__c> toUpdate = new List<Intake_Session__c>();

  

  for (Intake_Session__c session : sessions) {
    processed++;

    try {
        // ── ALL CALLOUTS FIRST ──
        String status = getEnvelopeStatus(
            session.DocuSign_Envelope_Id__c, accessToken, cfg
        );
        if (status != 'completed') continue;

        String docId = getFirstDocumentId(
            session.DocuSign_Envelope_Id__c, accessToken, cfg
        );
        Blob signedPdf = downloadDocument(
            session.DocuSign_Envelope_Id__c, docId, accessToken, cfg
        );
        Blob certPdf = downloadDocument(
            session.DocuSign_Envelope_Id__c, 'certificate', accessToken, cfg
        );

        // ── ALL DML AFTER CALLOUTS ──
        String safeName = String.isNotBlank(session.Signer_Name__c)
            ? session.Signer_Name__c
                      .replaceAll('[^a-zA-Z0-9 ]', '')
                      .trim().replace(' ', '_')
            : 'Client';

        String dateStr  = DateTime.now().format('yyyy-MM-dd');
        String linkedId = session.Lead__c != null
            ? session.Lead__c : session.Case__c;

        if (signedPdf != null && signedPdf.size() > 0) {
            String fileName = 'Signed_Intake_' + safeName +
                '_' + dateStr + '.pdf';
            attachToRecord(signedPdf, fileName, linkedId);
            System.debug('✅ Signed doc attached: ' + fileName);
        }

        if (certPdf != null && certPdf.size() > 0) {
            String certName = 'Signing_Certificate_' + safeName +
                '_' + dateStr + '.pdf';
            attachToRecord(certPdf, certName, linkedId);
            System.debug('✅ Certificate attached: ' + certName);
        }

        toUpdate.add(new Intake_Session__c(
            Id                   = session.Id,
            Document_Attached__c = true,
            Document_Name__c     = 'Signed_Intake_' + safeName +
                '_' + dateStr + '.pdf'
        ));

        success++;

    } catch (Exception e) {
        failed++;
        errors.add('Session ' + session.Id + ': ' + e.getMessage());
        System.debug('❌ Failed: ' + e.getMessage());
        System.debug('Stack: ' + e.getStackTraceString());
    }
}

// ── Single bulk DML at end ──
if (!toUpdate.isEmpty()) {
    update toUpdate;
}
}


    public void finish(Database.BatchableContext bc) {
        System.debug('=== DocuSignDocumentBatch FINISH ===');
        System.debug('Processed : ' + processed);
        System.debug('Success   : ' + success);
        System.debug('Failed    : ' + failed);

        if (!errors.isEmpty()) {
            for (String err : errors) {
                System.debug('Error: ' + err);
            }
        }

        // ── Send summary email to admin ──
        sendSummaryEmail();
    }


    // ─────────────────────────────────────────
    // PRIVATE HELPERS
    // ─────────────────────────────────────────

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

                if (docType != 'summary' && docId != 'certificate') {
                    return docId;
                }
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
        System.debug('Download Status: ' + res.getStatusCode());

        if (res.getStatusCode() == 200) {
            return res.getBodyAsBlob();
        }
        System.debug('Download failed: ' + res.getBody());
        return null;
    }


    private void sendSummaryEmail() {
        try {
            List<User> admins = [
                SELECT Email, Name
                FROM   User
                WHERE  Profile.Name = 'System Administrator'
                AND    IsActive     = true
                LIMIT  1
            ];

            if (admins.isEmpty()) return;

            Messaging.SingleEmailMessage mail =
                new Messaging.SingleEmailMessage();
            mail.setToAddresses(new List<String>{ admins[0].Email });
            mail.setSubject('DocuSign Document Batch — Completed');
            mail.setHtmlBody(
                '<p>Hi ' + admins[0].Name + ',</p>' +
                '<p>The DocuSign Document Batch has completed.</p>' +
                '<table border="1" cellpadding="6" cellspacing="0">' +
                '<tr><td><b>Processed</b></td><td>' + processed + '</td></tr>' +
                '<tr><td><b>Success</b></td><td>' + success + '</td></tr>' +
                '<tr><td><b>Failed</b></td><td>' + failed + '</td></tr>' +
                '</table>' +
                (errors.isEmpty() ? '' :
                    '<p><b>Errors:</b><br/>' +
                    String.join(errors, '<br/>') + '</p>') +
                '<p>Please review failed sessions if any.</p>'
            );
            mail.setSaveAsActivity(false);
            Messaging.sendEmail(
                new List<Messaging.SingleEmailMessage>{ mail }
            );
        } catch (Exception e) {
            System.debug('Email failed: ' + e.getMessage());
        }
    }
                                                   
    private void attachToRecord(
    Blob fileBlob,
    String fileName,
    String recordId
     ) {
    // ── Create ContentVersion ──
        ContentVersion cv = new ContentVersion();
        cv.Title                  = fileName.replace('.pdf', '');
        cv.PathOnClient           = fileName;
        cv.VersionData            = fileBlob;
        cv.IsMajorVersion         = true;
        cv.FirstPublishLocationId = recordId;
        insert cv;

            System.debug('✅ ContentVersion: ' + cv.Id + ' | ' + fileName);
        
            // ── Get ContentDocumentId ──
            ContentVersion inserted = [
                SELECT ContentDocumentId
                FROM   ContentVersion
                WHERE  Id = :cv.Id
                LIMIT  1
            ];

            // ── Explicit link ──
            try {
                ContentDocumentLink cdl = new ContentDocumentLink();
                cdl.ContentDocumentId   = inserted.ContentDocumentId;
                cdl.LinkedEntityId      = recordId;
                cdl.ShareType           = 'V';
                cdl.Visibility          = 'AllUsers';
                insert cdl;
            } catch (Exception linkEx) {
                // Already linked via FirstPublishLocationId
                System.debug('Link note: ' + linkEx.getMessage());
            }
        }
}