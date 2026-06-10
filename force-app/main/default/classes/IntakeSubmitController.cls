global without sharing class IntakeSubmitController {

    @AuraEnabled
    global static Map<String, Object> submitForm(
        String sessionId,
        String formDataJSON
    ) {
        Map<String, Object> result = new Map<String, Object>();

        try {
            if (String.isBlank(sessionId)) {
                result.put('error', 'Session ID is missing.');
                return result;
            }
            if (String.isBlank(formDataJSON)) {
                result.put('error', 'Form data is empty.');
                return result;
            }

            // ── Clean HTML encoding ──
            String cleanFormJSON = formDataJSON
                .replace('&quot;', '"')
                .replace('&amp;',  '&')
                .replace('&#39;',  '\'')
                .replace('&lt;',   '<')
                .replace('&gt;',   '>');

            Map<String, Object> formData;
            try {
                formData = (Map<String, Object>) JSON.deserializeUntyped(cleanFormJSON);
                System.debug('IntakeSubmitController form JSON length: ' + cleanFormJSON.length());
                System.debug('IntakeSubmitController form JSON keys: ' + formData.keySet());
                System.debug('IntakeSubmitController form JSON preview: ' + debugJsonPreview(cleanFormJSON));
            } catch (Exception jsonEx) {
                result.put('error', 'Form data could not be read: ' + jsonEx.getMessage());
                return result;
            }

            // ── Get session ──
            Intake_Session__c session = [
                SELECT Id, Status__c, Lead__c, Case__c,
                       Signer_Name__c, Signer_Email__c,
                       Incident_Type__c, Signer_Type__c,
                       DocuSign_Template_Id__c
                FROM   Intake_Session__c
                WHERE  Id = :sessionId
                LIMIT  1
            ];

            // ── Block duplicate submit ──
            if (session.Status__c == 'Submitted' ||
                session.Status__c == 'Signed') {
                result.put('error', 'Form already submitted.');
                return result;
            }

            // ── Resolve signer info ──
            String signerEmail = session.Signer_Email__c;
            String signerName  = session.Signer_Name__c;

            if (String.isBlank(signerEmail) && formData.containsKey('email')) {
                signerEmail = String.valueOf(formData.get('email'));
            }
            if (String.isBlank(signerName)) {
                String fn = formData.containsKey('firstName')
                    ? String.valueOf(formData.get('firstName')) : '';
                String ln = formData.containsKey('lastName')
                    ? String.valueOf(formData.get('lastName')) : '';
                signerName = (fn + ' ' + ln).trim();
            }

            if (String.isBlank(signerEmail)) {
                result.put('error', 'Signer email is missing.');
                return result;
            }

            // ── Resolve Template ID from metadata ──
            String templateId = session.DocuSign_Template_Id__c;

            if (String.isBlank(templateId)) {
                List<Intake_Template_Config__mdt> tmpl = [
                    SELECT DocuSign_Template_Id__c
                    FROM   Intake_Template_Config__mdt
                    WHERE  Incident_Type__c = :session.Incident_Type__c
                    AND    Signer_Type__c   = :session.Signer_Type__c
                    AND    Is_Active__c     = true
                    LIMIT  1
                ];

                if (!tmpl.isEmpty()) {
                    templateId = tmpl[0].DocuSign_Template_Id__c;
                } else {
                    // Final fallback — any active template
                    List<Intake_Template_Config__mdt> anyTmpl = [
                        SELECT DocuSign_Template_Id__c
                        FROM   Intake_Template_Config__mdt
                        WHERE  Is_Active__c = true
                        LIMIT  1
                    ];
                    templateId = anyTmpl.isEmpty()
                        ? null : anyTmpl[0].DocuSign_Template_Id__c;
                }
            }

            System.debug('Template ID being used: ' + templateId);

            if (String.isBlank(templateId)) {
                result.put('error', 'No DocuSign template found for this incident type.');
                return result;
            }

            // ── ALL CALLOUTS FIRST ──
            String returnURL  = 'https://mccrawlawgroup.com/';
            String signingURL = DocuSignEnvelopeService.createEnvelopeAndGetSigningURL(
                session.Id,
                signerName,
                signerEmail,
                returnURL,
                templateId,
                cleanFormJSON 
            );

            // ── ALL DML AFTER CALLOUTS ──
            session.Status__c              = 'Submitted';
            session.Submitted_Datetime__c  = System.now();
            session.Submitted_Form_JSON__c = cleanFormJSON;
            update session;
            System.debug('IntakeSubmitController saved Submitted_Form_JSON__c for session: ' + session.Id);
            System.debug('IntakeSubmitController saved JSON length: ' + session.Submitted_Form_JSON__c.length());

            notifyInternalTeam(session);

            // ── Lead update in future ──
            if (session.Lead__c != null) {
                LeadUpdateService.updateLeadFromForm(
                    session.Lead__c,
                    cleanFormJSON,
                    session.Id
                );
            }

            // ── Generate intake form PDF and attach to Lead/Case ──
            try {
                if (session.Lead__c == null) {
                    System.enqueueJob(new IntakeFormPDFQueueable(session.Id));
                }
                if (session.Lead__c == null) {
                System.debug('✅ IntakeFormPDFQueueable enqueued for session: ' + session.Id);
                } else {
                    System.debug('Lead session PDF deferred until LeadUpdateService completes. session: ' + session.Id);
                }
            } catch (Exception e) {
                System.debug('⚠️ PDF enqueue failed: ' + e.getMessage());
            }

            result.put('success',    true);
            result.put('sessionId',  session.Id);
            result.put('signingURL', signingURL);
            result.put('error',      null);

        } catch (Exception e) {
            result.put('success', false);
            result.put('error',   e.getMessage());
        }

        return result;
    }


    private static void notifyInternalTeam(Intake_Session__c session) {
        Task t = new Task(
            Subject      = 'Intake Form Submitted — Review Required',
            Status       = 'Not Started',
            Priority     = 'High',
            ActivityDate = Date.today()
        );
        if (session.Lead__c != null) {
            t.WhoId = session.Lead__c;
        } else if (session.Case__c != null) {
            t.WhatId = session.Case__c;
        }
        insert t;
    }

    private static String debugJsonPreview(String rawJson) {
        if (String.isBlank(rawJson)) {
            return '[blank]';
        }

        String preview = rawJson;
        preview = preview.replaceAll('(?i)("ssn"\\s*:\\s*")[^"]*(")', '$1***REDACTED***$2');
        preview = preview.replaceAll('(?i)("driversLicense"\\s*:\\s*")[^"]*(")', '$1***REDACTED***$2');

        Integer maxLen = 1000;
        if (preview.length() > maxLen) {
            preview = preview.substring(0, maxLen) + '... [truncated]';
        }
        return preview;
    }
}