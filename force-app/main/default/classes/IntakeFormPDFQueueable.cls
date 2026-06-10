public class IntakeFormPDFQueueable implements Queueable, Database.AllowsCallouts {

    private String sessionId;

    public IntakeFormPDFQueueable(String sessionId) {
        this.sessionId = sessionId;
    }

    public void execute(QueueableContext ctx) {
        System.debug('=== IntakeFormPDFQueueable START: ' + sessionId);

        List<Intake_Session__c> sessions = [
            SELECT Id, Lead__c, Case__c, Signer_Name__c, Incident_Type__c,
                   Submitted_Datetime__c, Submitted_Form_JSON__c
            FROM Intake_Session__c
            WHERE Id = :sessionId
            LIMIT 1
        ];

        if (sessions.isEmpty()) {
            System.debug('Session not found: ' + sessionId);
            return;
        }

        Intake_Session__c session = sessions[0];
        Id linkedId = session.Lead__c != null ? session.Lead__c : session.Case__c;

        if (linkedId == null) {
            logPdfError(session.Id, 'No Lead or Case linked to intake session.');
            return;
        }

        try {
            // ── Decode stored JSON ──
            String cleanJson = decodeHtmlJson(session.Submitted_Form_JSON__c);
            Map<String, Object> formData = new Map<String, Object>();
            if (String.isNotBlank(cleanJson)) {
                formData = (Map<String, Object>) JSON.deserializeUntyped(cleanJson);
            }

            // ── Load Lead if linked ──
            Lead leadRecord = null;
            if (session.Lead__c != null) {
                List<Lead> leads = [
                    SELECT FirstName, LastName, Email, Phone,
                           Street, City, State, PostalCode,
                           Date_of_Birth__c, SSN__c, Drivers_License__c,
                           Marketing_Source__c, Company,
                           Emergency_Contact_Name__c, Emergency_Contact_Address__c,
                           Emergency_Contact_Phone__c, Emergency_Contact_Relation__c,
                           Lost_Wages_Missed_Work__c, Lost_Work_Description__c,
                           Health_Insurance_Carrier__c, Insurance_Details__c,
                           Medicare__c, Medicaid__c, Gov_Benefits_Details__c,
                           Injuries__c, Transported_to_Hospital_by_Ambulance__c,
                           Names_of_Treating_Providers__c, Prior_Injuries__c,
                           Type_of_Accident__c, Incident_Date__c, Date_of_Incident__c,
                           Incident_Location__c, Description_of_Accident__c,
                           Worker_s_Comp__c, Police_Onsite__c, Responding_Agency_police__c,
                           Other_Incident_Report__c, Anyone_Given_Citation_Arrested_at_Scene__c,
                           Witness_Details__c, Additional_Incident_Details__c,
                           Coverage_for_No_Fault_Plaintiff__c, Plaintiff_Policy_Claim__c,
                           Coverage_for_At_Fault_Defendant__c, Defendant_Policy_Claim__c,
                           Name_of_Animal_Owner__c, Address_Phone_Number_of_Animal_Owner__c,
                           Animal_Owner_Address_Phone__c, Home_Owner_Name__c,
                           Description_of_Animal__c, Name_of_At_Fault_Party__c,
                           Address_Phone_No_for_At_Fault_Party__c
                    FROM Lead WHERE Id = :session.Lead__c LIMIT 1
                ];
                if (!leads.isEmpty()) leadRecord = leads[0];
            }

            // ── Build HTML then convert to PDF ──
            String htmlContent = buildPdfHtml(session, leadRecord, formData);

            // Store HTML in a static VF page param approach is unreliable from Queueable.
            // Instead: save HTML to a temp ContentVersion, render via PageReference
            // OR: use the reliable approach — ContentVersion with direct blob:
            Blob pdfBlob = generatePdfFromHtml(session.Id, htmlContent);

            if (pdfBlob == null || pdfBlob.size() < 2000) {
                logPdfError(session.Id,
                    'Generated PDF too small: ' + (pdfBlob == null ? 0 : pdfBlob.size()) + ' bytes.');
                return;
            }

            String safeName = String.isNotBlank(session.Signer_Name__c)
                ? session.Signer_Name__c.replaceAll('[^a-zA-Z0-9 ]', '').trim().replace(' ', '_')
                : 'Client';
            if (String.isBlank(safeName)) safeName = 'Client';

            String fileName = 'Intake_Form_' + safeName + '_' +
                DateTime.now().format('yyyy-MM-dd') + '.pdf';

            ContentVersion cv = new ContentVersion();
            cv.Title                  = fileName;
            cv.PathOnClient           = fileName;
            cv.VersionData            = pdfBlob;
            cv.IsMajorVersion         = true;
            cv.FirstPublishLocationId = linkedId;
            insert cv;

            System.debug('✅ Intake Form PDF attached: ' + fileName
                + ' | size=' + pdfBlob.size() + ' bytes');

        } catch (Exception e) {
            logPdfError(session.Id, 'Intake PDF generation failed: ' + e.getMessage());
            System.debug('Stack: ' + e.getStackTraceString());
        }
    }

    // ── Core fix: set session data on a dedicated static resource VF page ──
    // OR use the approach below — pass sessionId AND a pre-auth token via
    // the existing VF page but rendered by a DIFFERENT PageReference strategy.
    //
    // MOST RELIABLE: Use the VF page but call it via PageReference from a
    // with sharing context. Since Queueable runs as the automation user,
    // use System.runAs or redesign.
    //
    // SIMPLEST FIX THAT WORKS: Build PDF HTML in Apex and use
    // PageReference of a VF page that reads from a Custom Setting / Cache
    // seeded by this class. Here we use a simple approach:
    // save HTML to Intake_Session__c.PDF_HTML__c (Long Text) temporarily.

    private Blob generatePdfFromHtml(Id sessionId, String htmlContent) {
        // Save rendered HTML to a temp field on the session so VF page can read it
        // instead of re-querying (avoids the guest-user re-auth problem)
        update new Intake_Session__c(
            Id = sessionId,
            PDF_HTML_Cache__c = htmlContent   // Long Text Area field — add this to the object
        );

        PageReference pdfPage = Page.IntakeFormPDF;
        pdfPage.getParameters().put('sessionId', sessionId);
        pdfPage.getParameters().put('useCache', 'true');   // signal VF page to use cached HTML
        pdfPage.setRedirect(false);

        return Test.isRunningTest()
            ? Blob.valueOf('%PDF-1.4 Test Content That Is Long Enough To Pass Validation Check 12345678901234567890')
            : pdfPage.getContentAsPDF();
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Build full PDF HTML string from session + lead data + form JSON
    // ─────────────────────────────────────────────────────────────────────────
    private String buildPdfHtml(
        Intake_Session__c session,
        Lead leadRecord,
        Map<String, Object> formData
    ) {
        String incidentType = leadRecord != null && String.isNotBlank(String.valueOf(leadRecord.get('Type_of_Accident__c')))
            ? String.valueOf(leadRecord.get('Type_of_Accident__c'))
            : session.Incident_Type__c;
        if (String.isBlank(incidentType)) incidentType = fj(formData, 'incidentType');

        String clientName = '';
        if (leadRecord != null) {
            clientName = (fl(leadRecord, 'FirstName') + ' ' + fl(leadRecord, 'LastName')).trim();
        }
        if (String.isBlank(clientName)) clientName = session.Signer_Name__c;
        if (String.isBlank(clientName)) clientName = fj(formData, 'fullName');

        String submittedText = session.Submitted_Datetime__c != null
            ? String.valueOf(session.Submitted_Datetime__c) : '-';

        String html = '<!DOCTYPE html><html><head><style>'
            + 'body{font-family:Arial,Helvetica,sans-serif;font-size:10pt;color:#222}'
            + '.header{text-align:center;border-bottom:2px solid #1a237e;padding-bottom:10px;margin-bottom:12px}'
            + '.firm-name{font-size:18pt;font-weight:bold;color:#1a237e}'
            + '.doc-title{font-size:11pt;color:#444;margin-top:3px}'
            + '.meta{font-size:9pt;color:#555;margin-top:5px}'
            + '.section-title{background-color:#1a237e;color:#fff;font-size:10pt;font-weight:bold;padding:5px 8px;margin-top:12px}'
            + 'table{width:100%;border-collapse:collapse}'
            + 'td{padding:5px 8px;border-bottom:1px solid #ddd;vertical-align:top;font-size:9pt}'
            + 'td.lbl{font-weight:bold;width:38%;background-color:#f5f5f5}'
            + '.footer{margin-top:18px;border-top:1px solid #ccc;padding-top:6px;font-size:8pt;color:#777;text-align:center}'
            + '</style></head><body>';

        // ── Header ──
        html += '<div class="header">'
            + '<div class="firm-name">McCraw Law Group</div>'
            + '<div class="doc-title">Client Intake Form - Submitted Copy</div>'
            + '<div class="meta">Incident Type: <strong>' + escHtml(incidentType) + '</strong>'
            + ' | Client: <strong>' + escHtml(clientName) + '</strong>'
            + ' | Submitted: <strong>' + escHtml(submittedText) + '</strong></div>'
            + '</div>';

        // ── Address ──
        String addr  = fv(leadRecord, 'Street',     formData, 'street');
        String city  = fv(leadRecord, 'City',       formData, 'city');
        String state = fv(leadRecord, 'State',      formData, 'state');
        String zip   = fv(leadRecord, 'PostalCode', formData, 'postalCode');
        String fullAddr = addr;
        if (String.isNotBlank(city))  fullAddr += (String.isNotBlank(fullAddr) ? ', ' : '') + city;
        if (String.isNotBlank(state)) fullAddr += (String.isNotBlank(fullAddr) ? ', ' : '') + state;
        if (String.isNotBlank(zip))   fullAddr += (String.isNotBlank(fullAddr) ? ' '  : '') + zip;

        // ── Personal ──
        html += sectionTitle('Personal Information');
        html += tableStart();
        html += row('Full Name',        clientName);
        html += row('Date of Birth',    fv(leadRecord, 'Date_of_Birth__c', formData, 'dateOfBirth'));
        html += row('Email',            fv(leadRecord, 'Email',            formData, 'email'));
        html += row('Phone',            fv(leadRecord, 'Phone',            formData, 'phone'));
        html += row('Address',          fullAddr);
        html += row('SSN',              fv(leadRecord, 'SSN__c',           formData, 'ssn'));
        html += row('Driver\'s License',fv(leadRecord, 'Drivers_License__c', formData, 'driversLicense'));
        html += row('How Did You Hear', fv(leadRecord, 'Marketing_Source__c', formData, 'howDidYouHear'));
        html += row('Current Employer', fv(leadRecord, 'Company',          formData, 'currentEmployer'));
        html += tableEnd();

        // ── Emergency Contact ──
        html += sectionTitle('Emergency Contact');
        html += tableStart();
        html += row('Name',         fv(leadRecord, 'Emergency_Contact_Name__c',     formData, 'emergencyName'));
        html += row('Relationship', fv(leadRecord, 'Emergency_Contact_Relation__c', formData, 'emergencyRelation'));
        html += row('Phone',        fv(leadRecord, 'Emergency_Contact_Phone__c',    formData, 'emergencyPhone'));
        html += row('Address',      fv(leadRecord, 'Emergency_Contact_Address__c',  formData, 'emergencyAddress'));
        html += tableEnd();

        // ── Occupation ──
        html += sectionTitle('Occupation');
        html += tableStart();
        html += row('Lost Work Due to Injury',  fv(leadRecord, 'Lost_Wages_Missed_Work__c', formData, 'lostWork'));
        html += row('Lost Work Description',    fv(leadRecord, 'Lost_Work_Description__c',  formData, 'lostWorkDescription'));
        html += tableEnd();

        // ── Health Insurance ──
        String medicare  = leadRecord != null ? fl(leadRecord, 'Medicare__c')  : '';
        String medicaid  = leadRecord != null ? fl(leadRecord, 'Medicaid__c')  : '';
        String govBen    = (medicare == 'true' || medicaid == 'true') ? 'Yes' : fj(formData, 'hasGovBenefits');
        html += sectionTitle('Health Insurance');
        html += tableStart();
        html += row('Has Health Insurance', fv(leadRecord, 'Health_Insurance_Carrier__c', formData, 'hasInsurance'));
        html += row('Insurance Carrier',    fv(leadRecord, 'Insurance_Details__c',        formData, 'insuranceCarrierName'));
        html += row('Government Benefits',  govBen);
        html += row('Benefits Name',        fv(leadRecord, 'Gov_Benefits_Details__c',     formData, 'govBenefitsName'));
        html += tableEnd();

        // ── Injuries ──
        html += sectionTitle('Injuries');
        html += tableStart();
        html += row('Injuries Sustained',       fv(leadRecord, 'Injuries__c',                          formData, 'injuries'));
        html += row('Transported by Ambulance', fv(leadRecord, 'Transported_to_Hospital_by_Ambulance__c', formData, 'transportedByAmbulance'));
        html += row('Treating Providers',       fv(leadRecord, 'Names_of_Treating_Providers__c',        formData, 'treatingProviders'));
        html += row('Prior Injuries',           fv(leadRecord, 'Prior_Injuries__c',                     formData, 'priorInjuries'));
        html += tableEnd();

        // ── Incident ──
        String incidentDate = fv(leadRecord, 'Incident_Date__c', formData, 'incidentDate');
        if (String.isBlank(incidentDate)) incidentDate = fv(leadRecord, 'Date_of_Incident__c', formData, 'incidentDate');
        html += sectionTitle('Incident Details');
        html += tableStart();
        html += row('Incident Date',       incidentDate);
        html += row('Location',            fv(leadRecord, 'Incident_Location__c',          formData, 'incidentLocation'));
        html += row('Description',         fv(leadRecord, 'Description_of_Accident__c',    formData, 'descriptionOfAccident'));
        html += row('Work-Related',        fv(leadRecord, 'Worker_s_Comp__c',              formData, 'onJob'));
        html += row('Authorities Arrived', fv(leadRecord, 'Police_Onsite__c',              formData, 'authoritiesArrived'));
        html += row('Which Authorities',   fv(leadRecord, 'Responding_Agency_police__c',   formData, 'authoritiesWhom'));
        html += row('Report Taken',        fv(leadRecord, 'Other_Incident_Report__c',      formData, 'reportTaken'));
        html += row('Citation Issued',     fv(leadRecord, 'Anyone_Given_Citation_Arrested_at_Scene__c', formData, 'citationGiven'));
        html += row('Witness Details',     fv(leadRecord, 'Witness_Details__c',            formData, 'witnessDetails'));
        html += row('Additional Details',  fv(leadRecord, 'Additional_Incident_Details__c',formData, 'additionalIncidentDetails'));
        html += tableEnd();

        // ── Conditional sections ──
        Boolean isMV = incidentType == 'Motor Vehicle Accident'
            || incidentType == 'Trucking / Commercial Accident'
            || incidentType == 'Motorcycle Accident';
        Boolean isAnimal  = incidentType == 'Animal Attack';
        Boolean isPremise = incidentType == 'Premises Injury';

        if (isMV) {
            html += sectionTitle('Motor Vehicle Insurance');
            html += tableStart();
            html += row('Plaintiff Carrier',      fv(leadRecord, 'Coverage_for_No_Fault_Plaintiff__c', formData, 'plaintiffCarrierName'));
            html += row('Plaintiff Policy/Claim', fv(leadRecord, 'Plaintiff_Policy_Claim__c',          formData, 'plaintiffPolicyClaim'));
            html += row('Defendant Carrier',      fv(leadRecord, 'Coverage_for_At_Fault_Defendant__c', formData, 'defendantCarrierName'));
            html += row('Defendant Policy/Claim', fv(leadRecord, 'Defendant_Policy_Claim__c',          formData, 'defendantPolicyClaim'));
            html += tableEnd();
        }

        if (isAnimal) {
            String animalOwnerAddr = fv(leadRecord, 'Address_Phone_Number_of_Animal_Owner__c', formData, 'animalOwnerAddressPhone');
            if (String.isBlank(animalOwnerAddr)) animalOwnerAddr = fl(leadRecord, 'Animal_Owner_Address_Phone__c');
            html += sectionTitle('Animal Attack Details');
            html += tableStart();
            html += row('Animal Owner Name',  fv(leadRecord, 'Name_of_Animal_Owner__c', formData, 'animalOwnerName'));
            html += row('Owner Address/Phone', animalOwnerAddr);
            html += row('Home Owner Name',    fv(leadRecord, 'Home_Owner_Name__c',       formData, 'homeOwnerName'));
            html += row('Animal Breed',       fv(leadRecord, 'Description_of_Animal__c', formData, 'animalBreed'));
            html += tableEnd();
        }

        if (isPremise) {
            html += sectionTitle('Premises Details');
            html += tableStart();
            html += row('At-Fault Party Name',         fv(leadRecord, 'Name_of_At_Fault_Party__c',           formData, 'atFaultPartyName'));
            html += row('At-Fault Party Address/Phone',fv(leadRecord, 'Address_Phone_No_for_At_Fault_Party__c', formData, 'atFaultPartyAddressPhone'));
            html += tableEnd();
        }

        html += '<div class="footer">McCraw Law Group - Confidential Client Intake Document | '
            + 'Generated automatically upon form submission.</div>'
            + '</body></html>';

        return html;
    }

    // ── HTML helpers ──────────────────────────────────────────────────────────

    private String sectionTitle(String title) {
        return '<div class="section-title">' + escHtml(title) + '</div>';
    }
    private String tableStart() { return '<table>'; }
    private String tableEnd()   { return '</table>'; }
    private String row(String label, String val) {
        String display = String.isBlank(val) || val == 'null' ? '-' : val;
        return '<tr><td class="lbl">' + escHtml(label) + '</td><td>' + escHtml(display) + '</td></tr>';
    }
    private String escHtml(String s) {
        if (s == null) return '';
        return s.replace('&','&amp;').replace('<','&lt;').replace('>','&gt;').replace('"','&quot;');
    }

    // ── Data helpers ──────────────────────────────────────────────────────────

    /** Lead field value → fallback to JSON key */
    private String fv(Lead lr, String leadField, Map<String,Object> fd, String jsonKey) {
        String lv = fl(lr, leadField);
        return String.isNotBlank(lv) ? lv : fj(fd, jsonKey);
    }

    /** Safe Lead field getter */
    private String fl(Lead lr, String fieldName) {
        if (lr == null) return '';
        Object v = lr.get(fieldName);
        if (v == null) return '';
        if (v instanceof Boolean) return (Boolean)v ? 'Yes' : 'No';
        String s = String.valueOf(v).trim();
        return s == 'null' ? '' : s;
    }

    /** Safe JSON map getter */
    private String fj(Map<String,Object> fd, String key) {
        if (fd == null || !fd.containsKey(key) || fd.get(key) == null) return '';
        String s = String.valueOf(fd.get(key)).trim();
        return s == 'null' ? '' : s;
    }

    // ── Error / utility ───────────────────────────────────────────────────────

    private static void logPdfError(Id sessionId, String message) {
        System.debug('PDF ERROR: ' + message);
        if (sessionId == null) return;
        try {
            update new Intake_Session__c(Id = sessionId, Error_Message__c = message);
        } catch (Exception e) {
            System.debug('Unable to write error to session: ' + e.getMessage());
        }
    }

    private static String decodeHtmlJson(String rawJson) {
        if (String.isBlank(rawJson)) return rawJson;
        return rawJson
            .replace('&quot;', '"').replace('&#34;', '"')
            .replace('&amp;',  '&').replace('&#39;', '\'')
            .replace('&apos;', '\'').replace('&lt;', '<').replace('&gt;', '>');
    }
}