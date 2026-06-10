public without sharing class IntakeFormPDFController {

    public Intake_Session__c session { get; private set; }
    public String errorMessage { get; private set; }
    private Lead leadRecord;
    private Map<String,Object> data;

    public class Row {
        public String label { get; set; }
        public String val { get; set; }

        public Row(String label, String value) {
            this.label = label;
            this.val = String.isBlank(value) || value == 'null' ? '-' : value;
        }
    }

    public IntakeFormPDFController() {
        data = new Map<String,Object>();

        String sid = ApexPages.currentPage().getParameters().get('sessionId');
        if (String.isBlank(sid)) {
            errorMessage = 'Missing sessionId parameter.';
            return;
        }

        try {
        List<Intake_Session__c> rows = [
                SELECT Id, Lead__c, Case__c, Signer_Name__c, Incident_Type__c,
                    Submitted_Datetime__c, Submitted_Form_JSON__c,
                    PDF_HTML_Cache__c                              // ← add this
                FROM Intake_Session__c
                WHERE Id = :sid
                LIMIT 1
            ];

            if (rows.isEmpty()) {
                errorMessage = 'No intake session found for Id: ' + sid;
                return;
            }

            session = rows[0];
            System.debug('IntakeFormPDFController session row. sessionId=' + session.Id
                + ', leadId=' + session.Lead__c
                + ', caseId=' + session.Case__c
                + ', incidentType=' + session.Incident_Type__c
                + ', submitted=' + session.Submitted_Datetime__c
                + ', jsonLength=' + (session.Submitted_Form_JSON__c == null ? 0 : session.Submitted_Form_JSON__c.length()));
            System.debug('IntakeFormPDFController session JSON preview: ' + debugJsonPreview(session.Submitted_Form_JSON__c));
            loadLead();
            loadJson();
            System.debug('IntakeFormPDFController loaded. sessionId=' + session.Id
                + ', leadId=' + session.Lead__c
                + ', hasLead=' + (leadRecord != null)
                + ', jsonKeys=' + data.keySet());

            if (leadRecord == null && data.isEmpty()) {
                errorMessage = 'No submitted intake data found for this session.';
            }
        } catch (Exception e) {
            errorMessage = 'Unable to load submitted intake form: ' + e.getMessage();
        }
    }

    private void loadLead() {
        if (session == null || session.Lead__c == null) {
            return;
        }

        List<Lead> leads = [
            SELECT FirstName, LastName, Email, Phone, MobilePhone,
                   Street, City, State, PostalCode, Date_of_Birth__c, SSN__c,
                   Drivers_License__c, Marketing_Source__c, Company,
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
            FROM Lead
            WHERE Id = :session.Lead__c
            LIMIT 1
        ];

        if (!leads.isEmpty()) {
            leadRecord = leads[0];
            System.debug('IntakeFormPDFController lead loaded. name='
                + leadRecord.FirstName + ' ' + leadRecord.LastName
                + ', email=' + leadRecord.Email
                + ', phone=' + leadRecord.Phone
                + ', type=' + leadRecord.Type_of_Accident__c
                + ', incidentDate=' + leadRecord.Incident_Date__c
                + ', descriptionBlank=' + String.isBlank(leadRecord.Description_of_Accident__c));
        } else {
            System.debug('IntakeFormPDFController no Lead found for id: ' + session.Lead__c);
        }
    }

    private void loadJson() {
        if (session == null || String.isBlank(session.Submitted_Form_JSON__c)) {
            return;
        }

        try {
            String cleanJson = decodeHtmlJson(session.Submitted_Form_JSON__c);
            System.debug('IntakeFormPDFController clean JSON preview: ' + debugJsonPreview(cleanJson));
            data = (Map<String,Object>) JSON.deserializeUntyped(cleanJson);
            System.debug('IntakeFormPDFController parsed JSON keys: ' + data.keySet());
        } catch (Exception e) {
            System.debug('IntakeFormPDFController JSON parse failed: ' + e.getMessage());
            if (leadRecord == null) {
                throw e;
            }
        }
    }

    public Boolean getHasError() {
        return String.isNotBlank(errorMessage);
    }

    public String getSubmittedDateText() {
        if (session == null || session.Submitted_Datetime__c == null) {
            return '-';
        }
        return String.valueOf(session.Submitted_Datetime__c);
    }

    private String f(String key) {
        if (!data.containsKey(key) || data.get(key) == null) {
            return '';
        }

        String value = String.valueOf(data.get(key)).trim();
        return value == 'null' ? '' : value;
    }

    private String lf(String fieldApiName) {
        if (leadRecord == null) {
            return '';
        }

        Object value = leadRecord.get(fieldApiName);
        if (value == null) {
            return '';
        }
        if (value instanceof Boolean) {
            return (Boolean) value ? 'Yes' : 'No';
        }
        return String.valueOf(value);
    }

    private String firstValue(String leadField, String jsonKey) {
        String leadValue = lf(leadField);
        return String.isNotBlank(leadValue) ? leadValue : f(jsonKey);
    }

    private String incidentType() {
        String leadType = lf('Type_of_Accident__c');
        if (String.isNotBlank(leadType)) {
            return leadType;
        }
        if (session != null && String.isNotBlank(session.Incident_Type__c)) {
            return session.Incident_Type__c;
        }
        return f('incidentType');
    }

    public String getDisplayIncidentType() {
        return incidentType();
    }

    public String getDisplaySignerName() {
        if (leadRecord != null) {
            String name = ((lf('FirstName') + ' ' + lf('LastName')).trim());
            if (String.isNotBlank(name)) {
                return name;
            }
        }
        if (session != null && String.isNotBlank(session.Signer_Name__c)) {
            return session.Signer_Name__c;
        }
        return f('fullName');
    }

    public List<Row> getPersonalSection() {
        System.debug('IntakeFormPDFController rendering personal section. hasLead=' + (leadRecord != null));
        String addr = firstValue('Street', 'street');
        String city = firstValue('City', 'city');
        String state = firstValue('State', 'state');
        String postal = firstValue('PostalCode', 'postalCode');
        if (String.isNotBlank(city)) {
            addr += (String.isNotBlank(addr) ? ', ' : '') + city;
        }
        if (String.isNotBlank(state)) {
            addr += (String.isNotBlank(addr) ? ', ' : '') + state;
        }
        if (String.isNotBlank(postal)) {
            addr += (String.isNotBlank(addr) ? ' ' : '') + postal;
        }

        List<Row> rows = new List<Row>{
            new Row('Full Name', getDisplaySignerName()),
            new Row('Date of Birth', firstValue('Date_of_Birth__c', 'dateOfBirth')),
            new Row('Email', firstValue('Email', 'email')),
            new Row('Phone', firstValue('Phone', 'phone')),
            new Row('Address', addr),
            new Row('SSN', firstValue('SSN__c', 'ssn')),
            new Row('Driver\'s License', firstValue('Drivers_License__c', 'driversLicense')),
            new Row('How Did You Hear', firstValue('Marketing_Source__c', 'howDidYouHear')),
            new Row('Current Employer', firstValue('Company', 'currentEmployer'))
        };
        System.debug('IntakeFormPDFController personal rows: ' + rows.size()
            + ', name=' + rows[0].val
            + ', email=' + rows[2].val);
        return rows;
    }

    public List<Row> getEmergencySection() {
        return new List<Row>{
            new Row('Emergency Contact Name', firstValue('Emergency_Contact_Name__c', 'emergencyName')),
            new Row('Relationship', firstValue('Emergency_Contact_Relation__c', 'emergencyRelation')),
            new Row('Phone', firstValue('Emergency_Contact_Phone__c', 'emergencyPhone')),
            new Row('Address', firstValue('Emergency_Contact_Address__c', 'emergencyAddress'))
        };
    }

    public List<Row> getOccupationSection() {
        return new List<Row>{
            new Row('Lost Work Due to Injury', firstValue('Lost_Wages_Missed_Work__c', 'lostWork')),
            new Row('Lost Work Description', firstValue('Lost_Work_Description__c', 'lostWorkDescription'))
        };
    }

    public List<Row> getHealthSection() {
        String govBenefits = lf('Medicare__c') == 'Yes' || lf('Medicaid__c') == 'Yes'
            ? 'Yes'
            : f('hasGovBenefits');
        return new List<Row>{
            new Row('Has Health Insurance', firstValue('Health_Insurance_Carrier__c', 'hasInsurance')),
            new Row('Insurance Carrier', firstValue('Insurance_Details__c', 'insuranceCarrierName')),
            new Row('Government Benefits', govBenefits),
            new Row('Benefits Name', firstValue('Gov_Benefits_Details__c', 'govBenefitsName'))
        };
    }

    public List<Row> getInjuriesSection() {
        return new List<Row>{
            new Row('Injuries Sustained', firstValue('Injuries__c', 'injuries')),
            new Row('Transported by Ambulance', firstValue('Transported_to_Hospital_by_Ambulance__c', 'transportedByAmbulance')),
            new Row('Treating Providers', firstValue('Names_of_Treating_Providers__c', 'treatingProviders')),
            new Row('Prior Injuries', firstValue('Prior_Injuries__c', 'priorInjuries'))
        };
    }

    public List<Row> getIncidentSection() {
        String incidentDate = firstValue('Incident_Date__c', 'incidentDate');
        if (String.isBlank(incidentDate)) {
            incidentDate = firstValue('Date_of_Incident__c', 'incidentDate');
        }

        List<Row> rows = new List<Row>{
            new Row('Incident Date', incidentDate),
            new Row('Location', firstValue('Incident_Location__c', 'incidentLocation')),
            new Row('Description', firstValue('Description_of_Accident__c', 'descriptionOfAccident')),
            new Row('Work-Related', firstValue('Worker_s_Comp__c', 'onJob')),
            new Row('Authorities Arrived', firstValue('Police_Onsite__c', 'authoritiesArrived')),
            new Row('Which Authorities', firstValue('Responding_Agency_police__c', 'authoritiesWhom')),
            new Row('Report Taken', firstValue('Other_Incident_Report__c', 'reportTaken')),
            new Row('Citation Issued', firstValue('Anyone_Given_Citation_Arrested_at_Scene__c', 'citationGiven')),
            new Row('Witness Details', firstValue('Witness_Details__c', 'witnessDetails')),
            new Row('Additional Details', firstValue('Additional_Incident_Details__c', 'additionalIncidentDetails'))
        };
        System.debug('IntakeFormPDFController incident rows: ' + rows.size()
            + ', incidentDate=' + rows[0].val
            + ', descriptionBlank=' + (rows[2].val == '-'));
        return rows;
    }

    public List<Row> getMotorVehicleSection() {
        return new List<Row>{
            new Row('Plaintiff Carrier', firstValue('Coverage_for_No_Fault_Plaintiff__c', 'plaintiffCarrierName')),
            new Row('Plaintiff Policy/Claim', firstValue('Plaintiff_Policy_Claim__c', 'plaintiffPolicyClaim')),
            new Row('Defendant Carrier', firstValue('Coverage_for_At_Fault_Defendant__c', 'defendantCarrierName')),
            new Row('Defendant Policy/Claim', firstValue('Defendant_Policy_Claim__c', 'defendantPolicyClaim'))
        };
    }

    public List<Row> getAnimalSection() {
        String animalOwnerAddress = firstValue('Address_Phone_Number_of_Animal_Owner__c', 'animalOwnerAddressPhone');
        if (String.isBlank(animalOwnerAddress)) {
            animalOwnerAddress = lf('Animal_Owner_Address_Phone__c');
        }
        return new List<Row>{
            new Row('Animal Owner Name', firstValue('Name_of_Animal_Owner__c', 'animalOwnerName')),
            new Row('Owner Address/Phone', animalOwnerAddress),
            new Row('Home Owner Name', firstValue('Home_Owner_Name__c', 'homeOwnerName')),
            new Row('Animal Breed', firstValue('Description_of_Animal__c', 'animalBreed'))
        };
    }

    public List<Row> getPremiseSection() {
        return new List<Row>{
            new Row('At-Fault Party Name', firstValue('Name_of_At_Fault_Party__c', 'atFaultPartyName')),
            new Row('At-Fault Party Address/Phone', firstValue('Address_Phone_No_for_At_Fault_Party__c', 'atFaultPartyAddressPhone'))
        };
    }

    public Boolean getShowMotorVehicle() {
        String type = incidentType();
        return type == 'Motor Vehicle Accident'
            || type == 'Trucking / Commercial Accident'
            || type == 'Motorcycle Accident';
    }

    public Boolean getShowAnimal() {
        return incidentType() == 'Animal Attack';
    }

    public Boolean getShowPremise() {
        return incidentType() == 'Premises Injury';
    }
public Boolean getUseCache() {
    String param = ApexPages.currentPage().getParameters().get('useCache');
    return param == 'true'
        && session != null
        && String.isNotBlank(session.PDF_HTML_Cache__c);
}

public String getCachedHtml() {
    if (session == null) return '';
    return session.PDF_HTML_Cache__c != null ? session.PDF_HTML_Cache__c : '';
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

    private static String decodeHtmlJson(String rawJson) {
        if (String.isBlank(rawJson)) {
            return rawJson;
        }

        return rawJson
            .replace('&quot;', '"')
            .replace('&#34;', '"')
            .replace('&amp;', '&')
            .replace('&#39;', '\'')
            .replace('&apos;', '\'')
            .replace('&lt;', '<')
            .replace('&gt;', '>');
    }
}