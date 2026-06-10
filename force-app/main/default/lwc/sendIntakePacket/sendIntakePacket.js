import { LightningElement, api, track, wire } from 'lwc';
import { CloseActionScreenEvent }              from 'lightning/actions';
import { ShowToastEvent }                      from 'lightning/platformShowToastEvent';
import { getRecord, getFieldValue }            from 'lightning/uiRecordApi';
import sendIntakePacket from '@salesforce/apex/SendIntakePacketController.sendIntakePacket';

// Lead fields to prefill
import FIRSTNAME_FIELD      from '@salesforce/schema/Lead.FirstName';
import LASTNAME_FIELD       from '@salesforce/schema/Lead.LastName';
import EMAIL_FIELD          from '@salesforce/schema/Lead.Email';
import PHONE_FIELD          from '@salesforce/schema/Lead.Phone';
import INCIDENT_TYPE_FIELD  from '@salesforce/schema/Lead.Type_of_Accident__c';
import LEADSOURCE_FIELD from '@salesforce/schema/Lead.LeadSource';
import INCIDENT_DATE_FIELD from '@salesforce/schema/Lead.Incident_Date__c';

const FIELDS = [
    FIRSTNAME_FIELD,
    LASTNAME_FIELD,
    EMAIL_FIELD,
    PHONE_FIELD,
    INCIDENT_TYPE_FIELD,
     LEADSOURCE_FIELD,      
    INCIDENT_DATE_FIELD 
];

export default class SendIntakePacket extends LightningElement {

    @api recordId;

    @track incidentType  = '';
    @track signerType    = '';
    @track signerName    = '';
    @track signerEmail   = '';
    @track signerPhone   = '';
    @track sendChannel   = 'Email';
    @track isLoading     = false;
    @track errorMessage  = '';
    @track isDataLoaded  = false;

    // ── Wire Lead record ──
    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredLead({ data, error }) {
        if (data) {
            const firstName    = getFieldValue(data, FIRSTNAME_FIELD) || '';
            const lastName     = getFieldValue(data, LASTNAME_FIELD)  || '';
            const incidentType = getFieldValue(data, INCIDENT_TYPE_FIELD);

            // Prefill signer name from Lead
            this.signerName   = (firstName + ' ' + lastName).trim();

            // Prefill email
            const email = getFieldValue(data, EMAIL_FIELD);
            if (email) this.signerEmail = email;

            // Prefill phone
            const phone = getFieldValue(data, PHONE_FIELD);
            if (phone) this.signerPhone = phone;

            // Prefill incident type
            if (incidentType) this.incidentType = incidentType;

            this.isDataLoaded = true;
        }
        if (error) {
            console.error('Lead wire error:', error);
            this.isDataLoaded = true;
        }
    }
// ── SSN state ──
@track ssnError = '';

// ── Auto format as user types ──
handleSsnKeyup(event) {
    let raw = event.target.value
        .replace(/\D/g, '')        // remove non-digits
        .substring(0, 9);          // max 9 digits

    let formatted = '';
    if (raw.length <= 3) {
        formatted = raw;
    } else if (raw.length <= 5) {
        formatted = raw.slice(0, 3) + '-' + raw.slice(3);
    } else {
        formatted = raw.slice(0, 3) + '-' +
                    raw.slice(3, 5) + '-' +
                    raw.slice(5);
    }

    // Update display and formData
    event.target.value   = formatted;
    this.formData        = { ...this.formData, ssn: formatted };
    this.validateSsn(raw);
}

// ── On change save clean value ──
handleSsnChange(event) {
    let raw = event.detail.value
        .replace(/\D/g, '')
        .substring(0, 9);

    let formatted = '';
    if (raw.length <= 3) {
        formatted = raw;
    } else if (raw.length <= 5) {
        formatted = raw.slice(0, 3) + '-' + raw.slice(3);
    } else {
        formatted = raw.slice(0, 3) + '-' +
                    raw.slice(3, 5) + '-' +
                    raw.slice(5);
    }

    this.formData = { ...this.formData, ssn: formatted };
    this.validateSsn(raw);
}

// ── Validate SSN ──
validateSsn(raw) {
    if (raw.length === 0) {
        this.ssnError = '';
    } else if (raw.length < 9) {
        this.ssnError = 'SSN must be 9 digits (XXX-XX-XXXX)';
    } else if (raw.length === 9) {
        // Valid — check not all zeros
        if (raw === '000000000') {
            this.ssnError = 'Invalid SSN';
        } else {
            this.ssnError = '';
        }
    }
}

// ── Add SSN check to form validation ──
validateStep1() {
    // ... existing validation ...

    // SSN validation — if filled must be 9 digits
    if (this.formData.ssn) {
        const digits = this.formData.ssn.replace(/\D/g, '');
        if (digits.length !== 9) {
            this.hasStepError = true;
            this.stepErrorMessage = 'SSN must be 9 digits (XXX-XX-XXXX).';
            return false;
        }
    }
    return true;
}
    // ── Incident Type Options ──
    get incidentTypeOptions() {
        return [
            { label: '-- Select Incident Type --',     value: '' },
            { label: 'Motor Vehicle Accident',         value: 'Motor Vehicle Accident' },
            { label: 'Trucking / Commercial Accident', value: 'Trucking / Commercial Accident' },
            { label: 'Motorcycle Accident',            value: 'Motorcycle Accident' },
            { label: 'Premises Injury',                value: 'Premises Injury' },
            { label: 'Animal Attack',                  value: 'Animal Attack' },
            { label: 'Product Liability',              value: 'Product Liability' },
            { label: 'Other',                          value: 'Other' }
        ];
    }

    get signerTypeOptions() {
        return [
            { label: '-- Select Signer Type --', value: '' },
            { label: 'Self',            value: 'Self' },
            { label: 'Parent/Guardian', value: 'Parent/Guardian' },
            { label: 'Family Member',   value: 'Family Member' }
        ];
    }

    get sendChannelOptions() {
        return [
            { label: 'Email', value: 'Email' }
            // ,
            // { label: 'SMS',   value: 'SMS'   },
            // { label: 'Both',  value: 'Both'  }
        ];
    }

    get sendButtonLabel() {
        return this.isLoading ? 'Sending...' : 'Send Intake Packet';
    }

    // ── Info box based on incident type ──
    get showIncidentInfo() {
        return this.incidentType !== '';
    }

    get incidentInfoText() {
        const mv = [
            'Motor Vehicle Accident',
            'Trucking / Commercial Accident',
            'Motorcycle Accident'
        ];
        if (mv.includes(this.incidentType))
            return 'Form will show: Personal Info + Incident + Motor Vehicle + Insurance';
        if (this.incidentType === 'Animal Attack')
            return 'Form will show: Personal Info + Incident + Animal Attack + Insurance';
        if (this.incidentType === 'Premises Injury')
            return 'Form will show: Personal Info + Incident + Premise + Insurance';
        return 'Form will show: Personal Info + Incident + Insurance';
    }

    // ── Handlers ──
    handleIncidentType(event) { this.incidentType = event.detail.value; }
    handleSignerType(event)   { this.signerType   = event.detail.value; }
    handleSignerName(event)   { this.signerName   = event.detail.value; }
    handleSignerEmail(event)  { this.signerEmail  = event.detail.value; }
    handleSignerPhone(event)  { this.signerPhone  = event.detail.value; }
    handleSendChannel(event)  { this.sendChannel  = event.detail.value; }

    // ── Validation ──
    isFormValid() {
        this.errorMessage = '';

        if (!this.incidentType) {
            this.errorMessage = 'Please select an Incident Type.';
            return false;
        }
        if (!this.signerType) {
            this.errorMessage = 'Please select a Signer Type.';
            return false;
        }
        if (!this.signerName || this.signerName.trim() === '') {
            this.errorMessage = 'Signer Full Name is required.';
            return false;
        }
        if (!this.signerEmail || this.signerEmail.trim() === '') {
            this.errorMessage = 'Signer Email is required.';
            return false;
        }
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        if (!emailRegex.test(this.signerEmail)) {
            this.errorMessage = 'Please enter a valid email address.';
            return false;
        }
        return true;
    }

    // ── Send ──
    handleSend() {
        if (!this.isFormValid()) return;

        this.isLoading = true;

        sendIntakePacket({
            recordId     : this.recordId,
            incidentType : this.incidentType,
            signerType   : this.signerType,
            signerName   : this.signerName,
            signerEmail  : this.signerEmail,
            signerPhone  : this.signerPhone,
            sendChannel  : this.sendChannel
        })
        .then(() => {
            this.isLoading = false;
            this.dispatchEvent(new ShowToastEvent({
                title   : '✅ Intake Packet Sent',
                message : 'Intake link sent to ' + this.signerName,
                variant : 'success'
            }));
            this.dispatchEvent(new CloseActionScreenEvent());
        })
        .catch(error => {
            this.isLoading    = false;
            this.errorMessage = error.body ? error.body.message : error.message;
        });
    }

    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}