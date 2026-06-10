public with sharing class IntakeSessionService {

    // ─────────────────────────────────────────
    // MAIN METHOD — Called when staff clicks
    // "Send Intake Packet" on Lead or Case
    // ─────────────────────────────────────────
    public static Intake_Session__c createSession(
        Id       recordId,
        String   incidentType,
        String   signerType,
        String   signerName,
        String   signerEmail,
        String   signerPhone,
        String   sendChannel
    ) {
        // 1. Generate secure unique token
        String token = generateToken();

        // 2. Build the secure intake URL
        //    Replace with your actual Force.com / Experience Cloud site URL
        String siteBaseURL = Label.Intake_Site_Url;
        String intakeURL   = siteBaseURL + '?token=' + token;

        // 3. Build prefill JSON from Lead or Case
        String prefillJSON = buildPrefillJSON(recordId);

        // 4. Select DocuSign template based on incident + signer type
        String templateId = resolveTemplateId(incidentType, signerType);

        // 5. Determine if recordId is Lead or Case
        String objectType = recordId.getSObjectType().getDescribe().getName();

        // 6. Create the Intake Session record
        Intake_Session__c session = new Intake_Session__c(
            Session_Token__c        = token,
            Intake_Form_URL__c      = intakeURL,
            Status__c               = 'Created',
            Incident_Type__c        = incidentType,
            Signer_Type__c          = signerType,
            Signer_Name__c          = signerName,
            Signer_Email__c         = signerEmail,
            Signer_Phone__c         = signerPhone,
            Send_Channel__c         = sendChannel,
            Prefill_JSON__c         = prefillJSON,
            DocuSign_Template_Id__c = templateId,
            Sent_Datetime__c        = System.now()
        );

        // 7. Assign to Lead or Case
        if (objectType == 'Lead') {
            session.Lead__c = recordId;
        } else if (objectType == 'Case') {
            session.Case__c = recordId;
        }

        insert session;

        // 8. Send link to client (Email / SMS / Both)
        sendLink(session, sendChannel);

        return session;
    }


    // ─────────────────────────────────────────
    // GENERATE SECURE TOKEN
    // ─────────────────────────────────────────
    private static String generateToken() {
        Blob randomBlob = Crypto.generateAesKey(128);
        return EncodingUtil.convertToHex(randomBlob);
    }


private static String buildPrefillJSON(Id recordId) {
    String objectType = recordId.getSObjectType().getDescribe().getName();
    Map<String, String> prefillMap = new Map<String, String>();

    if (objectType == 'Lead') {
        Lead l = [
            SELECT FirstName, LastName, Email,
                   Phone, MobilePhone,
                   Street, City, State, PostalCode,
                   Date_of_Birth__c, SSN__c, Drivers_License__c,
                   Marketing_Source__c, Company
            FROM   Lead
            WHERE  Id = :recordId
            LIMIT  1
        ];

        if (l.FirstName          != null) prefillMap.put('firstName',      l.FirstName);
        if (l.LastName           != null) prefillMap.put('lastName',       l.LastName);
        if (l.Email              != null) prefillMap.put('email',          l.Email);
        if (l.Phone              != null) prefillMap.put('phone',          l.Phone);
        if (l.MobilePhone        != null) prefillMap.put('mobile',         l.MobilePhone);
        if (l.Street             != null) prefillMap.put('street',         l.Street);
        if (l.City               != null) prefillMap.put('city',           l.City);
        if (l.State              != null) prefillMap.put('state',          l.State);
        if (l.PostalCode         != null) prefillMap.put('postalCode',     l.PostalCode);
        if (l.Date_of_Birth__c   != null) prefillMap.put('dateOfBirth',    String.valueOf(l.Date_of_Birth__c));
        if (l.SSN__c             != null) prefillMap.put('ssn',            l.SSN__c);
        if (l.Drivers_License__c != null) prefillMap.put('driversLicense', l.Drivers_License__c);
        if (l.Marketing_Source__c!= null) prefillMap.put('howDidYouHear',  l.Marketing_Source__c);
        if (l.Company            != null) prefillMap.put('currentEmployer',l.Company);

    } else if (objectType == 'Case') {
        Case c = [
            SELECT Contact.FirstName, Contact.LastName,
                   Contact.Email, Contact.Phone
            FROM   Case
            WHERE  Id = :recordId
            LIMIT  1
        ];
        if (c.Contact != null) {
            if (c.Contact.FirstName != null) prefillMap.put('firstName', c.Contact.FirstName);
            if (c.Contact.LastName  != null) prefillMap.put('lastName',  c.Contact.LastName);
            if (c.Contact.Email     != null) prefillMap.put('email',     c.Contact.Email);
            if (c.Contact.Phone     != null) prefillMap.put('phone',     c.Contact.Phone);
        }
    }

    // ── Use serialize with false to avoid HTML encoding ──
    return prefillMap.isEmpty() ? '{}' : JSON.serialize(prefillMap, false);
}

    // ─────────────────────────────────────────
    // RESOLVE DOCUSIGN TEMPLATE
    // Based on incident type + signer type
    // We will replace this with Custom Metadata
    // in Module 4 — for now use a simple map
    // ─────────────────────────────────────────
 private static String resolveTemplateId(String incidentType, String signerType) {

    // Try exact match
    List<Intake_Template_Config__mdt> exactMatch = [
        SELECT DocuSign_Template_Id__c
        FROM   Intake_Template_Config__mdt
        WHERE  Incident_Type__c = :incidentType
        AND    Signer_Type__c   = :signerType
        AND    Is_Active__c     = true
        LIMIT  1
    ];
    if (!exactMatch.isEmpty()) {
        System.debug('Template (exact): ' + exactMatch[0].DocuSign_Template_Id__c);
        return exactMatch[0].DocuSign_Template_Id__c;
    }

    // Fallback — same incident any signer
    List<Intake_Template_Config__mdt> fallback = [
        SELECT DocuSign_Template_Id__c
        FROM   Intake_Template_Config__mdt
        WHERE  Incident_Type__c = :incidentType
        AND    Is_Active__c     = true
        LIMIT  1
    ];
    if (!fallback.isEmpty()) {
        System.debug('Template (fallback): ' + fallback[0].DocuSign_Template_Id__c);
        return fallback[0].DocuSign_Template_Id__c;
    }

    // Final fallback
    List<Intake_Template_Config__mdt> anyTmpl = [
        SELECT DocuSign_Template_Id__c
        FROM   Intake_Template_Config__mdt
        WHERE  Is_Active__c = true
        LIMIT  1
    ];
    if (!anyTmpl.isEmpty()) {
        System.debug('Template (any): ' + anyTmpl[0].DocuSign_Template_Id__c);
        return anyTmpl[0].DocuSign_Template_Id__c;
    }

    System.debug('❌ No template found');
    return null;
}


    // ─────────────────────────────────────────
    // SEND INTAKE LINK TO CLIENT
    // ─────────────────────────────────────────
    private static void sendLink(Intake_Session__c session, String sendChannel) {
        if (sendChannel == 'Email' || sendChannel == 'Both') {
            sendEmail(session);
        }
        if (sendChannel == 'SMS' || sendChannel == 'Both') {
            // SMS logic — plug in your SMS provider here
            // e.g. Twilio, Salesforce Messaging
            sendSMS(session);
        }
    }

    private static void sendEmail(Intake_Session__c session) {
    try {
        List<EmailTemplate> templates = [
            SELECT Id, HtmlValue, Body, Subject
            FROM   EmailTemplate
            WHERE  DeveloperName = 'Intake_Form_Email_Template'
            LIMIT  1
        ];
        if (templates.isEmpty()) {
            logError(session.Id,
                'Email template not found');
            return;
        }

        String intakeUrl = session.Intake_Form_URL__c;

        // ── Clickable button HTML ──
        String buttonHTML =
            '<div style="text-align:center;margin:32px 0;">' +
            '<a href="' + intakeUrl + '" ' +
            'style="background-color:#8b1a2c;color:#ffffff;' +
                   'padding:14px 32px;text-decoration:none;' +
                   'border-radius:4px;font-weight:bold;' +
                   'font-size:15px;display:inline-block;">' +
            'Click Here to Complete Your Intake Forms' +
            '</a>' +
            '</div>';

        // ── Render template for merge fields ──
        Messaging.SingleEmailMessage mail =
            Messaging.renderStoredEmailTemplate(
                templates[0].Id,
                session.Lead__c,
                null
            );

        String htmlBody  = mail.getHtmlBody();
        String textBody  = mail.getPlainTextBody();

        System.debug('HTML from template: ' + htmlBody);
        System.debug('Text from template: ' + textBody);

        // ── Force HTML even if template returns text only ──
        if (String.isNotBlank(htmlBody)) {
            // Template has HTML — replace placeholder
               String finalHtml =
        htmlBody.replace('{INTAKE_URL}', buttonHTML);

            mail.setHtmlBody(finalHtml);
        } else {
            // ── Template is Text only — build HTML manually ──
            String renderedText = String.isNotBlank(textBody)
                ? textBody : templates[0].Body;

            // Resolve Lead name manually if merge not resolved
            String firstName = '';
            if (session.Lead__c != null) {
                List<Lead> leads = [
                    SELECT FirstName FROM Lead
                    WHERE Id = :session.Lead__c LIMIT 1
                ];
                if (!leads.isEmpty())
                    firstName = leads[0].FirstName != null
                        ? leads[0].FirstName : '';
            }

            // ── Build full HTML email ──
            String builtHtml =
                '<!DOCTYPE html><html><body ' +
                'style="font-family:Arial,sans-serif;color:#333;' +
                'max-width:600px;margin:0 auto;">' +

                '<div style="background:#1a1f2e;padding:24px;' +
                'text-align:center;">' +
                '<h2 style="color:#fff;margin:0;">McCraw Law Group</h2>' +
                '</div>' +

                '<div style="padding:32px;">' +
                '<p>Dear ' + firstName + ',</p>' +
                '<p>Welcome to McCraw Law Group! We enjoyed speaking ' +
                'with you and are grateful for the opportunity to ' +
                'represent you in your personal injury case.</p>' +
                '<p>To get started, please complete our new client ' +
                'forms which include the <strong>Attorney-Client ' +
                'Contract</strong> and <strong>Questionnaire</strong>.' +
                '</p>' +
                '<p>Please also send any incident reports, photos, ' +
                'and relevant records to assist with your case.</p>' +
                '<p>If you have any questions, don\'t hesitate to ' +
                'reach out.</p>' +

                // ── Button ──
                buttonHTML +

                '<p>Thank you,<br>' +
                '<strong>McCraw Law Group</strong><br>' +
                '(972) 854-7900</p>' +
                '</div>' +

                '<div style="background:#1a1f2e;padding:16px;' +
                'text-align:center;">' +
                '<p style="color:#aaa;font-size:11px;margin:0;">' +
                '© 2026 McCraw Law Group. All rights reserved.</p>' +
                '</div>' +

                '</body></html>';

            mail.setHtmlBody(builtHtml);
        }

        // ── Plain text fallback ──
        String plainText =
            'Dear ' + (String.isNotBlank(textBody)
                ? textBody.replace('{INTAKE_URL}', intakeUrl)
                : intakeUrl);
        mail.setPlainTextBody(
            'Please complete your intake forms:\n' + intakeUrl
        );

        mail.setToAddresses(
            new List<String>{ session.Signer_Email__c }
        );
        mail.setSaveAsActivity(false);

        Messaging.sendEmail(
            new List<Messaging.SingleEmailMessage>{ mail }
        );
        System.debug('✅ Email sent to: ' + session.Signer_Email__c);

    } catch (Exception e) {
        logError(session.Id, 'Email failed: ' + e.getMessage());
    }
}

    // private static void sendEmail(Intake_Session__c session) {
    //     try {
    //         List<EmailTemplate> templates = [
    //             SELECT Id
    //             FROM   EmailTemplate
    //             WHERE  DeveloperName = 'Intake_Form_Email_Template'
    //             LIMIT  1
    //         ];
    //         if (templates.isEmpty()) {
    //             logError(session.Id, 'Email template Intake_Form_Email_Template not found');
    //             return;
    //         }

    //         // Render template so Lead merge fields (e.g. {!Lead.FirstName}) resolve
    //         Messaging.SingleEmailMessage mail = Messaging.renderStoredEmailTemplate(
    //             templates[0].Id,
    //             session.Lead__c,  // who — resolves {!Lead.*} merge fields; null for Case sessions
    //             null
    //         );

    //         // Inject intake URL — put {INTAKE_URL} in the template where the link should appear
    //         String intakeUrl = session.Intake_Form_URL__c;
    //         String htmlBody  = mail.getHtmlBody();
    //         String textBody  = mail.getPlainTextBody();

    //         if (htmlBody != null) {
    //             // Template has HTML body — inject a proper hyperlink
    //            mail.setHtmlBody(htmlBody.replace(
    //             '{INTAKE_URL}',
    //             '<a href="' + intakeUrl + '" ' +
    //             'style="background-color:#8b1a2c;color:#ffffff;' +
    //             'padding:12px 28px;text-decoration:none;' +
    //             'border-radius:4px;font-weight:bold;' +
    //             'display:inline-block;">' +
    //             'Click Here to Complete Your Intake Forms' +
    //             '</a>'
    //         ));
    //         } else if (textBody != null) {
    //             // Template is text-only — build an HTML version so the link is clickable
    //             String renderedText = textBody.replace('{INTAKE_URL}', intakeUrl);
    //             String builtHtml =
    //                 '<html><body style="font-family:Arial,sans-serif;font-size:14px;color:#333;">' +
    //                 renderedText
    //                     .escapeHtml4()
    //                     .replace(intakeUrl,
    //                         '<a href="' + intakeUrl + '">' + intakeUrl + '</a>')
    //                     .replace('\r\n', '<br/>').replace('\n', '<br/>') +
    //                 '</body></html>';
    //             mail.setHtmlBody(builtHtml);
    //         }

    //         if (textBody != null) {
    //             mail.setPlainTextBody(textBody.replace('{INTAKE_URL}', intakeUrl));
    //         }

    //         mail.setToAddresses(new List<String>{ session.Signer_Email__c });
    //         mail.setSaveAsActivity(false);

    //         Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });

    //     } catch (Exception e) {
    //         logError(session.Id, 'Email send failed: ' + e.getMessage());
    //     }
    // }

    private static void sendSMS(Intake_Session__c session) {
        // Placeholder — implement with your SMS provider
        // Example: Twilio via Named Credentials + HTTP Callout
        System.debug('SMS to: ' + session.Signer_Phone__c + ' | Link: ' + session.Intake_Form_URL__c);
    }


    // ─────────────────────────────────────────
    // ERROR LOGGING HELPER
    // ─────────────────────────────────────────
    public static void logError(Id sessionId, String errorMsg) {
        if (sessionId == null) return;
        Intake_Session__c s = new Intake_Session__c(
            Id            = sessionId,
            Status__c     = 'Error',
            Error_Message__c = errorMsg
        );
        update s;
    }
}