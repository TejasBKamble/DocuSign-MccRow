global without sharing class IntakePrefillController {

    @AuraEnabled(cacheable=false)
    global static Map<String, Object> getSessionData(String token) {
        Map<String, Object> result = new Map<String, Object>();

        if (String.isBlank(token)) {
            result.put('error', 'Invalid or missing token.');
            return result;
        }

        // ── Get Session ──
        List<Intake_Session__c> sessions = [
            SELECT Id, Status__c, Incident_Type__c,
                   Signer_Type__c, Signer_Name__c,
                   Signer_Email__c, Prefill_JSON__c,
                   Signing_URL__c,
                   Lead__c
            FROM   Intake_Session__c
            WHERE  Session_Token__c = :token
            LIMIT  1
        ];

        if (sessions.isEmpty()) {
            result.put('error',
                'Session not found. Please contact the firm.');
            return result;
        }

        Intake_Session__c session = sessions[0];

        // ── Already fully signed — block ──
        if (session.Status__c == 'Signed' ||
            session.Status__c == 'Expired') {
            result.put('error',
                'This intake has already been completed. ' +
                'Please contact the firm if you need assistance.');
            return result;
        }

        // ── Submitted but not signed — Resume signing ──
       /* if (session.Status__c == 'Submitted') {
            if (String.isNotBlank(session.Signing_URL__c)) {
                // ── Has signing URL — let client resume ──
                System.debug('Resuming signing for session: ' + session.Id);
                result.put('sessionId',     session.Id);
                result.put('resumeSigning', true);
                result.put('signingURL',    session.Signing_URL__c);
                result.put('signerName',    session.Signer_Name__c);
                result.put('incidentType',  session.Incident_Type__c);
                result.put('error',         null);
                return result;
            } else {
                // ── No signing URL — reset so user can resubmit ──
                System.debug('No signing URL — resetting session: ' + session.Id);
                session.Status__c = 'Opened';
                update session;
                // Falls through to normal form load below
            }
        }*/
        
        // ── Submitted but not signed — Resume signing ──
if (session.Status__c == 'Submitted') {

    System.debug('Session submitted — attempting resume: ' + session.Id);

    // ── Always regenerate fresh signing URL ──
    // Stored URL expires after 5 minutes
    try {
        // Get signer details
        String signerName  = session.Signer_Name__c;
        String signerEmail = session.Signer_Email__c;

     

        // ── Generate fresh signing URL ──
        String freshURL = DocuSignEnvelopeService.getEmbeddedSigningURL(
          session.DocuSign_Envelope_Id__c,
        session.Signer_Name__c,
        session.Signer_Email__c
            
        );

        System.debug('✅ Fresh signing URL generated');

        // ── Save fresh URL to session ──
        update new Intake_Session__c(
            Id             = session.Id,
            Signing_URL__c = freshURL
        );

        result.put('sessionId',     session.Id);
        result.put('resumeSigning', true);
        result.put('signingURL',    freshURL);
        result.put('signerName',    session.Signer_Name__c);
        result.put('incidentType',  session.Incident_Type__c);
        result.put('error',         null);
        return result;

    } catch (Exception e) {
        System.debug('⚠️ Could not regenerate URL: ' + e.getMessage());

        // ── Reset to Opened so user can resubmit ──
        update new Intake_Session__c(
            Id        = session.Id,
            Status__c = 'Opened'
        );
        // Falls through to normal form load
    }
}

        // ── Mark Opened ──
        if (session.Status__c == 'Created') {
            session.Status__c          = 'Opened';
            session.Opened_Datetime__c = System.now();
            update session;
        }

        result.put('sessionId',    session.Id);
        result.put('incidentType', session.Incident_Type__c);
        result.put('signerType',   session.Signer_Type__c);
        result.put('signerName',   session.Signer_Name__c);
        result.put('signerEmail',  session.Signer_Email__c);
        result.put('resumeSigning',false);
        result.put('error',        null);

        // ── Build Prefill Map ──
        Map<String, Object> prefillMap = new Map<String, Object>();

        // ── Step 1: Load from Prefill_JSON__c ──
        if (String.isNotBlank(session.Prefill_JSON__c)) {
            try {
                String cleanJSON = session.Prefill_JSON__c
                    .replace('&quot;', '"')
                    .replace('&amp;',  '&')
                    .replace('&#39;',  '\'')
                    .replace('&lt;',   '<')
                    .replace('&gt;',   '>');

                Map<String, Object> storedPrefill =
                    (Map<String, Object>) JSON.deserializeUntyped(cleanJSON);

                prefillMap.putAll(storedPrefill);
                System.debug('Loaded from Prefill_JSON: ' +
                    prefillMap.keySet());

            } catch (Exception e) {
                System.debug('Prefill JSON parse error: ' + e.getMessage());
            }
        }

        // ── Step 2: Enrich from Lead directly ──
        if (session.Lead__c != null) {
            try {
                Lead l = [
                    SELECT Id, FirstName, LastName,
                           Email, Phone,
                           Type_of_Accident__c,
                           LeadSource,
                           Incident_Date__c,
                           Date_of_Birth__c,
                           Company,
                           Street, City, State, PostalCode,
                           Incident_Location__c,
                           Party_Witness_Info__c,
                           Description_of_Accident__c
                    FROM   Lead
                    WHERE  Id = :session.Lead__c
                    LIMIT  1
                ];

                // ── Full Name ──
                String fn = l.FirstName != null ? l.FirstName : '';
                String ln = l.LastName  != null ? l.LastName  : '';
                String fullName = (fn + ' ' + ln).trim();
                if (String.isNotBlank(fullName))
                    prefillMap.put('fullName', fullName);

                // ── Contact ──
                if (l.Email != null)
                    prefillMap.put('email', l.Email);
                if (l.Phone != null)
                    prefillMap.put('phone', l.Phone);

                // ── Incident ──
                if (l.Type_of_Accident__c != null)
                    prefillMap.put('incidentType', l.Type_of_Accident__c);

                // ── Incident Date — strip time ──
                if (l.Incident_Date__c != null)
                    prefillMap.put('incidentDate',
                        String.valueOf(l.Incident_Date__c).substring(0, 10));

                // ── Date of Birth — strip time ──
                if (l.Date_of_Birth__c != null)
                    prefillMap.put('dateOfBirth',
                        String.valueOf(l.Date_of_Birth__c).substring(0, 10));

                // ── How Did You Hear — LeadSource ──
                if (l.LeadSource != null)
                    prefillMap.put('howDidYouHear', l.LeadSource);

                // ── Other fields ──
                if (l.Company != null)
                    prefillMap.put('currentEmployer', l.Company);
                if (l.Street != null)
                    prefillMap.put('street', l.Street);
                if (l.City != null)
                    prefillMap.put('city', l.City);
                if (l.State != null)
                    prefillMap.put('state', l.State);
                if (l.PostalCode != null)
                    prefillMap.put('postalCode', l.PostalCode);

                // ── Incident detail fields ──
                if (l.Incident_Location__c != null)
                    prefillMap.put('incidentLocation',
                        l.Incident_Location__c);
                if (l.Party_Witness_Info__c != null)
                    prefillMap.put('witnessDetails',
                        l.Party_Witness_Info__c);
                if (l.Description_of_Accident__c != null)
                    prefillMap.put('descriptionOfAccident',
                        l.Description_of_Accident__c);

                System.debug('Prefill after Lead merge: ' +
                    prefillMap.keySet());

            } catch (Exception e) {
                System.debug('Lead prefill error: ' + e.getMessage());
            }
        }

        result.put('prefill', prefillMap);
        return result;
    }


    @AuraEnabled(cacheable=true)
    global static List<Map<String, String>> getLeadSourcePicklistValues() {
        List<Map<String, String>> options =
            new List<Map<String, String>>();
        options.add(new Map<String, String>{
            'label' => '--None--', 'value' => ''
        });
        Schema.DescribeFieldResult fieldResult =
            Schema.Lead.LeadSource.getDescribe();
        for (Schema.PicklistEntry entry :
                fieldResult.getPicklistValues()) {
            if (entry.isActive()) {
                options.add(new Map<String, String>{
                    'label' => entry.getLabel(),
                    'value' => entry.getValue()
                });
            }
        }
        return options;
    }
}