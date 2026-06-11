public class DocuSignEnvelopeService {

    // ─────────────────────────────────────────
    // MAIN METHOD
    // ─────────────────────────────────────────
    public static String createEnvelopeAndGetSigningURL(
        String sessionId,
        String signerName,
        String signerEmail,
        String returnURL,
        String templateId,
        String formDataJSON
    ) {
        System.debug('=== DocuSignEnvelopeService START ===');
        System.debug('Session ID   : ' + sessionId);
        System.debug('Signer Name  : ' + signerName);
        System.debug('Signer Email : ' + signerEmail);
        System.debug('Template ID  : ' + templateId);

        DocuSign_Config__mdt cfg   = DocuSignAuthService.loadConfig();
        String accessToken         = DocuSignAuthService.getAccessToken();

        String envelopeId  = createEnvelope(
            accessToken, cfg, signerName, signerEmail,
            templateId, formDataJSON
        );
        String signingURL  = getRecipientViewURL(
            accessToken, cfg, envelopeId, signerName, signerEmail, returnURL
        );
        updateSessionAfterCallout(sessionId, envelopeId, signingURL);

        System.debug('✅ Signing URL: ' + signingURL);
        return signingURL;
    }
   

    // ─────────────────────────────────────────
    // CREATE ENVELOPE WITH PREFILL
    // ─────────────────────────────────────────
    private static String createEnvelope(
        String accessToken,
        DocuSign_Config__mdt cfg,
        String signerName,
        String signerEmail,
        String templateId,
        String formDataJSON
    ) {
        String endpoint = cfg.Base_URI__c +
            '/restapi/v2.1/accounts/' + cfg.Account_ID__c + '/envelopes';
String todayDate = Date.today().format();
        // ── Parse form data ──
        Map<String, Object> f = new Map<String, Object>();
        if (String.isNotBlank(formDataJSON)) {
            try {
                String cleanJSON = formDataJSON
                    .replace('&quot;', '"')
                    .replace('&amp;',  '&')
                    .replace('&#39;',  '\'')
                    .replace('&lt;',   '<')
                    .replace('&gt;',   '>');
                f = (Map<String, Object>) JSON.deserializeUntyped(cleanJSON);
                System.debug('Form keys: ' + f.keySet());
            } catch (Exception e) {
                System.debug('Form parse error: ' + e.getMessage());
            }
        }

        // ── TEXT TABS ──
        // Labels confirmed from DocuSign template API
        List<Map<String, String>> textTabs = new List<Map<String, String>>();

        // ── Contact Detail (Page 7) ──
        addTab(textTabs, 'Address',             getVal(f, 'street',          ''));
        addTab(textTabs, 'phoneNumber',          getVal(f, 'phone',           ''));
        addTab(textTabs, 'Email',               getVal(f, 'email',           signerEmail));
        addTab(textTabs, 'DateOfBirth',         getVal(f, 'dateOfBirth',     ''));
        addTab(textTabs, 'ssn',                 getVal(f, 'ssn',             ''));
        addTab(textTabs, 'DriverLicenseState',  getVal(f, 'driversLicense',  ''));
         
        addTab(textTabs, 'date', todayDate);
        // ── Emergency Contact (Page 7) ──
        addTab(textTabs, 'EmergencyContactName',    getVal(f, 'emergencyName',     ''));
        addTab(textTabs, 'EmergencyContactAddress', getVal(f, 'emergencyAddress',  ''));
        addTab(textTabs, 'EmergencyContactPhone',   getVal(f, 'emergencyPhone',    ''));
        // Set label 'emergencyRelation' in DocuSign template first
        addTab(textTabs, 'emergencyRelation',       getVal(f, 'emergencyRelation', ''));

        // ── Occupation (Page 7) ──
        addTab(textTabs, 'CurrentEmployer',         getVal(f, 'currentEmployer',      ''));
        // Set label 'lostWorkDescription' in DocuSign template first
        addTab(textTabs, 'lostWorkDescription',     getVal(f, 'lostWorkDescription',  ''));

        // ── Health Insurance (Page 7) ──
        addTab(textTabs, 'insuranceCarrierName',    getVal(f, 'insuranceCarrierName', ''));
        addTab(textTabs, 'govBenefitsName',         getVal(f, 'govBenefitsName',      ''));

        // ── Injuries (Page 8) ──
        addTab(textTabs, 'injuries',                getVal(f, 'injuries',             ''));
        addTab(textTabs, 'treatingProviders',       getVal(f, 'treatingProviders',    ''));
        addTab(textTabs, 'priorInjuries',           getVal(f, 'priorInjuries',        ''));

        // ── Incident Information (Page 8) ──
        addTab(textTabs, 'incidentDate',            getVal(f, 'incidentDate',         ''));
        addTab(textTabs, 'incidentLocation',        getVal(f, 'incidentLocation',     ''));
        addTab(textTabs, 'authoritiesWhom',         getVal(f, 'authoritiesWhom',      ''));
        addTab(textTabs, 'witnessDetails',          getVal(f, 'witnessDetails',       ''));
        addTab(textTabs, 'descriptionOfAccident',   getVal(f, 'descriptionOfAccident',''));

        // ── Attorney Contract Page 1 ──
        addTab(textTabs, 'incidentType',            getVal(f, 'incidentType',         ''));

        // ── Motor Vehicle (Page 9) ──
        addTab(textTabs, 'plaintiffCarrierName',    getVal(f, 'plaintiffCarrierName', ''));
        addTab(textTabs, 'plaintiffPolicyClaim',    getVal(f, 'plaintiffPolicyClaim', ''));
        addTab(textTabs, 'defendantCarrierName',    getVal(f, 'defendantCarrierName', ''));
        addTab(textTabs, 'defendantPolicyClaim',    getVal(f, 'defendantPolicyClaim', ''));

        // ── Premise (Page 9) ──
        addTab(textTabs, 'atFaultPartyName',        getVal(f, 'atFaultPartyName',         ''));
        addTab(textTabs, 'atFaultPartyAddressPhone',getVal(f, 'atFaultPartyAddressPhone',  ''));

        // ── Animal Attack (Page 9-10) ──
        addTab(textTabs, 'animalOwnerName',         getVal(f, 'animalOwnerName',       ''));
        addTab(textTabs, 'animalOwnerAddressPhone', getVal(f, 'animalOwnerAddressPhone',''));
        addTab(textTabs, 'homeOwnerName',           getVal(f, 'homeOwnerName',         ''));
        addTab(textTabs, 'animalBreed',             getVal(f, 'animalBreed',           ''));

        System.debug('Total text tabs: ' + textTabs.size());

        // ── CHECKBOX TABS ──
        List<Map<String, Object>> checkboxTabs = new List<Map<String, Object>>();

        // Lost Work
        String lostWork = getVal(f, 'lostWork', '');
        if (lostWork == 'Yes') {
            checkboxTabs.add(new Map<String, Object>{
                'tabLabel' => 'Yes_LostWork', 'selected' => true
            });
        } else if (lostWork == 'No') {
            checkboxTabs.add(new Map<String, Object>{
                'tabLabel' => 'No_LostWork', 'selected' => true
            });
        }

        // Has Insurance
        String hasInsurance = getVal(f, 'hasInsurance', '');
        if (hasInsurance == 'Yes') {
            checkboxTabs.add(new Map<String, Object>{
                'tabLabel' => 'Yes_Insurance', 'selected' => true
            });
        } else if (hasInsurance == 'No') {
            checkboxTabs.add(new Map<String, Object>{
                'tabLabel' => 'No_Insurance', 'selected' => true
            });
        }

        // Gov Benefits
        String hasGovBenefits = getVal(f, 'hasGovBenefits', '');
        if (hasGovBenefits == 'Yes') {
            checkboxTabs.add(new Map<String, Object>{
                'tabLabel' => 'Yes_GovBenefits', 'selected' => true
            });
        } else if (hasGovBenefits == 'No') {
            checkboxTabs.add(new Map<String, Object>{
                'tabLabel' => 'No_GovBenefits', 'selected' => true
            });
        }

        // On Job
        String onJob = getVal(f, 'onJob', '');
        if (onJob == 'Yes') {
            checkboxTabs.add(new Map<String, Object>{
                'tabLabel' => 'Yes_OnJob', 'selected' => true
            });
        } else if (onJob == 'No') {
            checkboxTabs.add(new Map<String, Object>{
                'tabLabel' => 'No_OnJob', 'selected' => true
            });
        }

        // Authorities Arrived
        String authArrived = getVal(f, 'authoritiesArrived', '');
        if (authArrived == 'Yes') {
            checkboxTabs.add(new Map<String, Object>{
                'tabLabel' => 'Yes_Authorities', 'selected' => true
            });
        } else if (authArrived == 'No') {
            checkboxTabs.add(new Map<String, Object>{
                'tabLabel' => 'No_Authorities', 'selected' => true
            });
        }

        // Report Taken
        String reportTaken = getVal(f, 'reportTaken', '');
        if (reportTaken == 'Yes') {
            checkboxTabs.add(new Map<String, Object>{
                'tabLabel' => 'Yes_Report', 'selected' => true
            });
        } else if (reportTaken == 'No') {
            checkboxTabs.add(new Map<String, Object>{
                'tabLabel' => 'No_Report', 'selected' => true
            });
        }

        // Citation Given
        String citationGiven = getVal(f, 'citationGiven', '');
        if (citationGiven == 'Yes') {
            checkboxTabs.add(new Map<String, Object>{
                'tabLabel' => 'Yes_Citation', 'selected' => true
            });
        } else if (citationGiven == 'No') {
            checkboxTabs.add(new Map<String, Object>{
                'tabLabel' => 'No_Citation', 'selected' => true
            });
        }

        System.debug('Total checkbox tabs: ' + checkboxTabs.size());

        // ── LIST/DROPDOWN TABS ──
        List<Map<String, Object>> listTabs = new List<Map<String, Object>>();

        String hearVal = getVal(f, 'howDidYouHear', '');
        if (String.isNotBlank(hearVal)) {
            listTabs.add(new Map<String, Object>{
                'tabLabel' => 'howDidYouHear',
                'value'    => hearVal
            });
        }

        // ── BUILD TABS ──
        Map<String, Object> tabs = new Map<String, Object>{
            'textTabs'     => textTabs,
            'checkboxTabs' => checkboxTabs,
            'listTabs'     => listTabs
        };

        // ── BUILD TEMPLATE ROLE ──
        Map<String, Object> templateRole = new Map<String, Object>{
            'roleName'     => 'Client',
            'name'         => signerName,
            'email'        => signerEmail,
            'clientUserId' => '1001',
            'tabs'         => tabs
        };

        // ── BUILD ENVELOPE ──
        Map<String, Object> envelopeBody = new Map<String, Object>{
            'status'        => 'sent',
            'templateId'    => templateId,
            'templateRoles' => new List<Object>{ templateRole }
        };

        System.debug('Envelope body: ' + JSON.serialize(envelopeBody));

        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('POST');
        req.setHeader('Authorization', 'Bearer ' + accessToken);
        req.setHeader('Content-Type',  'application/json');
        req.setBody(JSON.serialize(envelopeBody));
        req.setTimeout(30000);

        HttpResponse res = new Http().send(req);
        System.debug('Envelope Status: ' + res.getStatusCode());
        System.debug('Envelope Body  : ' + res.getBody());
        System.debug('Envelope Request: ' + JSON.serialize(envelopeBody));
        System.debug('Envelope Status: ' + res.getStatusCode());
        System.debug('Envelope Body  : ' + res.getBody());

        if (res.getStatusCode() == 201) {
            Map<String, Object> resp =
                (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            return (String) resp.get('envelopeId');
        } else {
            throw new DocuSignAuthService.DocuSignException(
                'Envelope Failed [' + res.getStatusCode() + ']: ' + res.getBody()
            );
        }
    }


    // ─────────────────────────────────────────
    // GET EMBEDDED SIGNING URL
    // ─────────────────────────────────────────
    private static String getRecipientViewURL(
        String accessToken,
        DocuSign_Config__mdt cfg,
        String envelopeId,
        String signerName,
        String signerEmail,
        String returnURL
    ) {
        String endpoint = cfg.Base_URI__c +
            '/restapi/v2.1/accounts/' + cfg.Account_ID__c +
            '/envelopes/' + envelopeId + '/views/recipient';

        Map<String, Object> viewBody = new Map<String, Object>{
            'returnUrl'            => returnURL,
            'authenticationMethod' => 'none',
            'email'                => signerEmail,
            'userName'             => signerName,
            'clientUserId'         => '1001'
        };

        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('POST');
        req.setHeader('Authorization', 'Bearer ' + accessToken);
        req.setHeader('Content-Type',  'application/json');
        req.setBody(JSON.serialize(viewBody));
        req.setTimeout(30000);

        HttpResponse res = new Http().send(req);

        System.debug('Recipient View Status: ' + res.getStatusCode());
        System.debug('Recipient View Body  : ' + res.getBody());

        if (res.getStatusCode() == 201) {
            Map<String, Object> resp =
                (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            return (String) resp.get('url');
        } else {
            throw new DocuSignAuthService.DocuSignException(
                'Recipient View Failed [' + res.getStatusCode() + ']: ' + res.getBody()
            );
        }
    }


    // ─────────────────────────────────────────
    // UPDATE SESSION AFTER CALLOUTS
    // ─────────────────────────────────────────
    private static void updateSessionAfterCallout(
        String sessionId,
        String envelopeId,
        String signingURL
    ) {
        update new Intake_Session__c(
            Id                      = sessionId,
            DocuSign_Envelope_Id__c = envelopeId,
            Signing_URL__c          = signingURL,
            Status__c               = 'Signing Started'
        );
    }


    // ─────────────────────────────────────────
    // HELPERS
    // ─────────────────────────────────────────
    private static void addTab(
        List<Map<String, String>> tabs,
        String label,
        String value
    ) {
        if (String.isNotBlank(value)) {
            tabs.add(new Map<String, String>{
                'tabLabel' => label,
                'value'    => value
            });
        }
    }

    private static String getVal(
        Map<String, Object> f,
        String key,
        String defaultVal
    ) {
        if (f.containsKey(key) && f.get(key) != null) {
            String val = String.valueOf(f.get(key)).trim();
            if (val != '' && val != 'null') return val;
        }
        return defaultVal;
    }
    
    public static String getEmbeddedSigningURL(
    String envelopeId,
    String signerName,
    String signerEmail
) {
    DocuSign_Config__mdt cfg = DocuSignAuthService.loadConfig();
    String accessToken       = DocuSignAuthService.getAccessToken();

    return getRecipientViewURL(
        accessToken, cfg, envelopeId,
        signerName, signerEmail,
        ''   // ← empty — DocuSign uses its own return URL
    );
}
}