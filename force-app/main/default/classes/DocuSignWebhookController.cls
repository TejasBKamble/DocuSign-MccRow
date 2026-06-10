/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* Main Integration Web Hook Handeler Class,hit by DocuSign and update 
  Intake Session and Create a Document Related to Lead in a Salesforce .
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Tejas 
* @modifiedBy     Tejas 
* @maintainedBy   Tejas
* @version        1.3
* @created        2026-11-5
* @modified       2026-11-5
* ──────────────────────────────────────────────────────────────────────────────────────────────────
*/

@RestResource(urlMapping='/docusign/webhook/*')
global without sharing class DocuSignWebhookController {

    @HttpPost
    global static void handleWebhook() {
        RestRequest  req = RestContext.request;
        RestResponse res = RestContext.response;

        System.debug('=== DocuSign Webhook Received ===');

        try {
            String body = req.requestBody.toString();

            if (String.isBlank(body)) {
                res.statusCode = 400;
                return;
            }

            // ── Parse top level ──
            Map<String, Object> payload =
                (Map<String, Object>) JSON.deserializeUntyped(body);

            // ── Get event type ──
            String eventType = getStr(payload, 'event');
            System.debug('Event Type : ' + eventType);

            // ── Get data object ──
            if (!payload.containsKey('data') || payload.get('data') == null) {
                System.debug('❌ No data object');
                res.statusCode = 400;
                return;
            }
            Map<String, Object> data =
                (Map<String, Object>) payload.get('data');

            // ── Get envelopeId from data ──
            String envelopeId = getStr(data, 'envelopeId');
            System.debug('Envelope ID : ' + envelopeId);

            // ── Get status from data.envelopeSummary ──
            String status = null;
            if (data.containsKey('envelopeSummary') &&
                data.get('envelopeSummary') != null) {
                Map<String, Object> summary =
                    (Map<String, Object>) data.get('envelopeSummary');
                status = getStr(summary, 'status');
            }

            // ── Fallback status from event type ──
            if (String.isBlank(status)) {
                if (eventType == 'envelope-completed') status = 'completed';
                else if (eventType == 'envelope-declined') status = 'declined';
                else if (eventType == 'envelope-voided')   status = 'voided';
            }

            System.debug('Status      : ' + status);

            if (String.isBlank(envelopeId)) {
                System.debug('❌ No envelope ID found');
                res.statusCode = 400;
                return;
            }

            // ── Route by status ──
            if (status == 'completed') {
                handleCompleted(envelopeId);
            } else if (status == 'declined') {
                handleDeclined(envelopeId);
            } else if (status == 'voided') {
                handleVoided(envelopeId);
            } else {
                System.debug('ℹ️ Unhandled status: ' + status);
            }

            res.statusCode = 200;

        } catch (Exception e) {
            System.debug('❌ Error: ' + e.getMessage());
            System.debug('Stack: '   + e.getStackTraceString());
            res.statusCode = 500;
        }
    }

private static void handleCompleted(String envelopeId) {
    System.debug('=== Handling COMPLETED: ' + envelopeId);

    List<Intake_Session__c> sessions = [
        SELECT Id, Lead__c, Case__c,
               Status__c, Signer_Name__c,
               Incident_Type__c
        FROM   Intake_Session__c
        WHERE  DocuSign_Envelope_Id__c = :envelopeId
        LIMIT  1
    ];

    if (sessions.isEmpty()) {
        System.debug('❌ No session for: ' + envelopeId);
        return;
    }

    Intake_Session__c session = sessions[0];

    // 1. Update session status
    session.Status__c          = 'Signed';
    session.Signed_Datetime__c = DateTime.now();
    update session;
    System.debug('✅ Session marked Signed');

    // 2. Create task + send email
    createTask(
        session,
        'Intake Signed ✅ — Documents Ready for Review',
        'Normal',
        'Client ' + session.Signer_Name__c +
        ' completed signing. Incident: ' + session.Incident_Type__c
    );
    sendEmail(session);

    // 3. Enqueue document download for this session only
    try {
        System.enqueueJob(new DocuSignDocumentQueueable(session.Id));
        System.debug('✅ Queueable enqueued for session: ' + session.Id);
    } catch (Exception e) {
        System.debug('⚠️ Enqueue failed: ' + e.getMessage());
    }
}   


    private static void handleDeclined(String envelopeId) {
        System.debug('=== Handling DECLINED: ' + envelopeId);

        List<Intake_Session__c> sessions = [
            SELECT Id, Lead__c, Case__c, Status__c
            FROM   Intake_Session__c
            WHERE  DocuSign_Envelope_Id__c = :envelopeId
            LIMIT  1
        ];

        if (sessions.isEmpty()) return;

        Intake_Session__c session = sessions[0];
        session.Status__c        = 'Error';
        session.Error_Message__c = 'Client declined to sign.';
        update session;

        createTask(
            session,
            'DocuSign Declined — Follow Up Required',
            'High',
            'Client declined to sign intake documents.'
        );
        System.debug('⚠️ Session marked Error — Declined');
    }


    private static void handleVoided(String envelopeId) {
        System.debug('=== Handling VOIDED: ' + envelopeId);

        List<Intake_Session__c> sessions = [
            SELECT Id, Lead__c, Case__c, Status__c
            FROM   Intake_Session__c
            WHERE  DocuSign_Envelope_Id__c = :envelopeId
            LIMIT  1
        ];

        if (sessions.isEmpty()) return;

        Intake_Session__c session = sessions[0];
        session.Status__c        = 'Error';
        session.Error_Message__c = 'Envelope was voided.';
        update session;

        createTask(
            session,
            'DocuSign Voided — Action Required',
            'High',
            'The DocuSign envelope was voided.'
        );
        System.debug('⚠️ Session marked Error — Voided');
    }


    private static void createTask(
        Intake_Session__c session,
        String subject,
        String priority,
        String description
    ) {
        Task t = new Task(
            Subject      = subject,
            Status       = 'Not Started',
            Priority     = priority,
            ActivityDate = Date.today(),
            Description  = description
        );
        if (session.Lead__c != null) {
            t.WhoId = session.Lead__c;
        } else if (session.Case__c != null) {
            t.WhatId = session.Case__c;
        }
        insert t;
        System.debug('✅ Task created: ' + subject);
    }


    private static void sendEmail(Intake_Session__c session) {
        try {
            if (session.Lead__c == null) return;

            List<EmailTemplate> templates = [
                SELECT Id
                FROM   EmailTemplate
                WHERE  DeveloperName = 'Intake_Form_Submit_by_Client'
                LIMIT  1
            ];
            if (templates.isEmpty()) {
                System.debug('⚠️ Email template Intake_Form_Submit_by_Client not found');
                return;
            }

            Lead l = [
                SELECT OwnerId, Owner.Email
                FROM   Lead
                WHERE  Id = :session.Lead__c
                LIMIT  1
            ];

            Messaging.SingleEmailMessage mail =
                new Messaging.SingleEmailMessage();
            mail.setTemplateId(templates[0].Id);
            mail.setTargetObjectId(session.Lead__c);
            mail.setToAddresses(new List<String>{ l.Owner.Email });
            mail.setSaveAsActivity(false);

            // Messaging.sendEmail(
            //     new List<Messaging.SingleEmailMessage>{ mail }
            // );
            System.debug('✅ Template email sent to Lead Owner: ' + l.Owner.Email);

        } catch (Exception e) {
            System.debug('⚠️ Email failed: ' + e.getMessage());
        }
    }


    private static String getStr(Map<String, Object> m, String key) {
        if (m != null && m.containsKey(key) && m.get(key) != null) {
            return String.valueOf(m.get(key));
        }
        return null;
    }
}