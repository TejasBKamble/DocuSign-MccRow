import { LightningElement, track, wire } from 'lwc';
import { CurrentPageReference }          from 'lightning/navigation';
import getSessionData from '@salesforce/apex/IntakePrefillController.getSessionData';
import submitForm     from '@salesforce/apex/IntakeSubmitController.submitForm';
import LOGO from '@salesforce/resourceUrl/MCcrowLogo';
import FutterLogo from '@salesforce/resourceUrl/MCcrowFutterLogo';
import getLeadSourcePicklistValues from '@salesforce/apex/IntakePrefillController.getLeadSourcePicklistValues';
const TOTAL_STEPS = 8;

export default class IntakeForm extends LightningElement {

    token        = '';
    sessionId    = '';
    incidentType = '';

    @track currentStep    = 0; // 0 = welcome
    @track isLoading      = true;
    @track isSubmitting   = false;
    @track hasError       = false;
    @track hasFormError   = false;
    @track errorMessage   = '';
    @track formErrorMessage = '';

    @track formData = {
        // Step 1 — Contact
        fullName        : '', street          : '',
        city            : '', state           : '',
        postalCode      : '', phone           : '',
        email           : '', howDidYouHear   : '',
        dateOfBirth     : '', ssn             : '',
        driversLicense  : '',
        // Step 2 — Emergency
        emergencyName    : '', emergencyAddress : '',
        emergencyPhone   : '', emergencyRelation : '',
        // Step 3 — Occupation
        currentEmployer    : '', lostWork           : '',
        lostWorkDescription: '',
        // Step 4 — Health Insurance
        hasInsurance       : '', insuranceCarrierName : '',
        hasGovBenefits     : '', govBenefitsName      : '',
        // Step 5 — Injuries
        injuries          : '', transportedByAmbulance : '',
        treatingProviders : '', priorInjuries          : '',
        // Step 6 — Incident
        incidentDate           : '', incidentLocation     : '',
        onJob                  : '', authoritiesArrived   : '',
        authoritiesWhom        : '', reportTaken          : '',
        citationGiven          : '', witnessDetails       : '',
        descriptionOfAccident  : '',
        // Step 7 — MV
        plaintiffCarrierName   : '', plaintiffPolicyClaim  : '',
        defendantCarrierName   : '', defendantPolicyClaim  : '',
        // Step 7 — Premise
        atFaultPartyName       : '', atFaultPartyAddressPhone : '',
        // Step 7 — Animal
        animalOwnerName        : '', animalOwnerAddressPhone : '',
        homeOwnerName          : '', animalBreed             : '',
        // Common
        additionalIncidentDetails : ''
    };

    // ── Read token from URL ──
    @wire(CurrentPageReference)
    getPageRef(pageRef) {
        if (pageRef) {
            let token = pageRef.state && pageRef.state.token
                        ? pageRef.state.token : null;
            if (!token) {
                const urlParams = new URLSearchParams(window.location.search);
                token = urlParams.get('token');
            }
            if (token) {
                this.token = token;
                this.loadSession();
            } else {
                this.isLoading    = false;
                this.hasError     = true;
                this.errorMessage = 'Invalid link. Please use the link provided.';
            }
        }
    }
        get countryOptions() {
            return [
                { label: 'United States', value: 'US' },
                { label: 'India',         value: 'IN' },
                { label: 'Canada',        value: 'CA' },
                { label: 'Other',         value: 'US' }
            ];
        }
    get logoURL() {
    return LOGO;
    }
     get FutterlogoURL() {
     return FutterLogo;
    }
    // ── Load session ──
    // loadSession() {
    //     getSessionData({ token: this.token })
    //     .then(result => {
    //         this.isLoading = false;
    //         if (result.error) {
    //             this.hasError     = true;
    //             this.errorMessage = result.error;
    //             return;
    //         }
    //         this.sessionId    = result.sessionId;
    //         this.incidentType = result.incidentType;

    //         // Prefill from session
    //         if (result.prefill) {
    //             const p = result.prefill;
    //             this.formData = {
    //                 ...this.formData,
    //                 fullName       : (p.firstName || '') + (p.lastName ? ' ' + p.lastName : ''),
    //                 street         : p.street          || '',
    //                 city           : p.city            || '',
    //                 state          : p.state           || '',
    //                 postalCode     : p.postalCode      || '',
    //                 phone          : p.phone           || '',
    //                 email          : p.email           || '',
    //                 dateOfBirth    : p.dateOfBirth     || '',
    //                 ssn            : p.ssn             || '',
    //                 driversLicense : p.driversLicense  || '',
    //                 howDidYouHear  : p.howDidYouHear   || '',
    //                 currentEmployer: p.currentEmployer || ''
    //             };
    //         }
    //     })
    //     .catch(error => {
    //         this.isLoading    = false;
    //         this.hasError     = true;
    //         this.errorMessage = error.body ? error.body.message : error.message;
    //     });
    // }

    loadSession() {
    getSessionData({ token: this.token })
    .then(result => {
        this.isLoading = false;

        if (result.error) {
            this.hasError     = true;
            this.errorMessage = result.error;
            return;
        }

        this.sessionId    = result.sessionId    || '';
        this.incidentType = result.incidentType || '';

        // ── Apply prefill from Lead ──
        if (result.prefill) {
            const p = result.prefill;

            // ── Build full name ──
            // Controller returns 'fullName' directly
            // fallback to firstName+lastName if old format
            let fullName = '';
            if (p.fullName) {
                fullName = p.fullName;
            } else if (p.firstName || p.lastName) {
                fullName = ((p.firstName || '') + ' ' +
                           (p.lastName  || '')).trim();
            }

            this.formData = {
                ...this.formData,

                // ── Personal ──
                fullName        : fullName,
                email           : p.email           || '',
                phone           : p.phone           || '',
                dateOfBirth     : p.dateOfBirth     || '',
                ssn             : p.ssn             || '',
                driversLicense  : p.driversLicense  || '',

                // ── Address ──
                street          : p.street          || '',
                city            : p.city            || '',
                state           : p.state           || '',
                postalCode      : p.postalCode       || '',

                // ── Occupation ──
                currentEmployer : p.currentEmployer || '',

                // ── How Did You Hear — from LeadSource ──
                howDidYouHear   : p.howDidYouHear   || '',

                // ── Incident ──
                incidentDate            : this.cleanDate(p.incidentDate),
                incidentType            : p.incidentType            || this.incidentType || '',
                incidentLocation        : p.incidentLocation        || '',
                witnessDetails          : p.witnessDetails          || '',
                descriptionOfAccident   : p.descriptionOfAccident   || ''
            };

            // ── Also update incidentType at component level ──
            if (p.incidentType) {
                this.incidentType = p.incidentType;
            }

            console.log('✅ Prefill applied:', JSON.stringify({
                fullName      : this.formData.fullName,
                email         : this.formData.email,
                phone         : this.formData.phone,
                howDidYouHear : this.formData.howDidYouHear,
                incidentDate  : this.formData.incidentDate,
                incidentType  : this.incidentType
            }));
        }
    })
    .catch(error => {
        this.isLoading    = false;
        this.hasError     = true;
        this.errorMessage = error.body
            ? error.body.message : error.message;
        console.log('Load session error:', JSON.stringify(error));
    });
}
cleanDate(val) {
    if (!val) return '';
    // Remove time portion if present
    return String(val).substring(0, 10);
}

    // ── Step visibility ──
    get showForm()       { return !this.isLoading && !this.hasError; }
    get isWelcomeStep()  { return this.currentStep === 0; }
    get isStep1()        { return this.currentStep === 1; }
    get isStep2()        { return this.currentStep === 2; }
    get isStep3()        { return this.currentStep === 3; }
    get isStep4()        { return this.currentStep === 4; }
    get isStep5()        { return this.currentStep === 5; }
    get isStep6()        { return this.currentStep === 6; }
    get isStep7()        { return this.currentStep === 7; }
    get isStep8()        { return this.currentStep === 8; }

    // ── Add this tracked property at top of class ──
@track ssnError = '';
@track phoneError = '';
@track emergencyPhoneError = '';
@track howDidYouHearOptions = [{ label: '--None--', value: '' }];

@wire(getLeadSourcePicklistValues)
wiredLeadSource({ data }) {
    if (data) this.howDidYouHearOptions = data;
}

// ── Add these methods to intakeForm.js ──
handleSsnKeyup(event) {
    let raw = event.target.value
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

validateSsn(raw) {
    if (raw.length === 0) {
        this.ssnError = '';
    } else if (raw.length < 9) {
        this.ssnError = 'SSN must be 9 digits (XXX-XX-XXXX)';
    } else {
        this.ssnError = raw === '000000000'
            ? 'Invalid SSN'
            : '';
    }
}

handlePhoneKeyup(event) {
    let raw = event.target.value.replace(/\D/g, '').substring(0, 10);
    let formatted = '';
    if (raw.length <= 3) {
        formatted = raw;
    } else if (raw.length <= 6) {
        formatted = '(' + raw.slice(0, 3) + ') ' + raw.slice(3);
    } else {
        formatted = '(' + raw.slice(0, 3) + ') ' + raw.slice(3, 6) + '-' + raw.slice(6);
    }
    this.formData = { ...this.formData, phone: formatted };
    this.validatePhone(raw);
}

handlePhoneChange(event) {
    let raw = event.detail.value.replace(/\D/g, '').substring(0, 10);
    let formatted = '';
    if (raw.length <= 3) {
        formatted = raw;
    } else if (raw.length <= 6) {
        formatted = '(' + raw.slice(0, 3) + ') ' + raw.slice(3);
    } else {
        formatted = '(' + raw.slice(0, 3) + ') ' + raw.slice(3, 6) + '-' + raw.slice(6);
    }
    this.formData = { ...this.formData, phone: formatted };
    this.validatePhone(raw);
}

validatePhone(raw) {
    if (raw.length === 0) {
        this.phoneError = '';
    } else if (raw.length < 10) {
        this.phoneError = 'Phone number must be 10 digits.';
    } else {
        this.phoneError = '';
    }
}

handleEmergencyPhoneKeyup(event) {
    let raw = event.target.value.replace(/\D/g, '').substring(0, 10);
    let formatted = '';
    if (raw.length <= 3) {
        formatted = raw;
    } else if (raw.length <= 6) {
        formatted = '(' + raw.slice(0, 3) + ') ' + raw.slice(3);
    } else {
        formatted = '(' + raw.slice(0, 3) + ') ' + raw.slice(3, 6) + '-' + raw.slice(6);
    }
    this.formData = { ...this.formData, emergencyPhone: formatted };
    this.emergencyPhoneError = raw.length > 0 && raw.length < 10
        ? 'Phone number must be 10 digits.' : '';
}

handleEmergencyPhoneChange(event) {
    let raw = event.detail.value.replace(/\D/g, '').substring(0, 10);
    let formatted = '';
    if (raw.length <= 3) {
        formatted = raw;
    } else if (raw.length <= 6) {
        formatted = '(' + raw.slice(0, 3) + ') ' + raw.slice(3);
    } else {
        formatted = '(' + raw.slice(0, 3) + ') ' + raw.slice(3, 6) + '-' + raw.slice(6);
    }
    this.formData = { ...this.formData, emergencyPhone: formatted };
    this.emergencyPhoneError = raw.length > 0 && raw.length < 10
        ? 'Phone number must be 10 digits.' : '';
}

    get hasHowDidYouHear() {
        return !!this.formData.howDidYouHear;
    }
    get hasIncidentType() {
        return !!(this.formData.incidentType || this.incidentType);
    }
    get displayIncidentType() {
        return this.formData.incidentType || this.incidentType || '';
    }

    // ── Dynamic section visibility ──
    get showMotorVehicleSection() {
        return ['Motor Vehicle Accident',
                'Trucking / Commercial Accident',
                'Motorcycle Accident'].includes(this.incidentType);
    }
    get showAnimalSection() {
        return this.incidentType === 'Animal Attack';
    }
    get showPremiseSection() {
        return this.incidentType === 'Premises Injury';
    }
    get showOtherSection() {
        return ['Product Liability', 'Other'].includes(this.incidentType);
    }

    // ── Conditional show/hide within steps ──
    get showLostWorkDesc()     { return this.formData.lostWork === 'Yes'; }
    get showInsuranceCarrier() { return this.formData.hasInsurance === 'Yes'; }
    get showGovBenefitsName()  { return this.formData.hasGovBenefits === 'Yes'; }
    get showAuthoritiesWhom()  { return this.formData.authoritiesArrived === 'Yes'; }

    // ── Radio checked states ──
    get lostWorkYes()       { return this.formData.lostWork === 'Yes'; }
    get lostWorkNo()        { return this.formData.lostWork === 'No'; }
    get hasInsuranceYes()   { return this.formData.hasInsurance === 'Yes'; }
    get hasInsuranceNo()    { return this.formData.hasInsurance === 'No'; }
    get hasGovBenefitsYes() { return this.formData.hasGovBenefits === 'Yes'; }
    get hasGovBenefitsNo()  { return this.formData.hasGovBenefits === 'No'; }
    get ambulanceYes()      { return this.formData.transportedByAmbulance === 'Yes'; }
    get ambulanceNo()       { return this.formData.transportedByAmbulance === 'No'; }
    get onJobYes()          { return this.formData.onJob === 'Yes'; }
    get onJobNo()           { return this.formData.onJob === 'No'; }
    get authoritiesYes()    { return this.formData.authoritiesArrived === 'Yes'; }
    get authoritiesNo()     { return this.formData.authoritiesArrived === 'No'; }
    get reportTakenYes()    { return this.formData.reportTaken === 'Yes'; }
    get reportTakenNo()     { return this.formData.reportTaken === 'No'; }
    get citationYes()       { return this.formData.citationGiven === 'Yes'; }
    get citationNo()        { return this.formData.citationGiven === 'No'; }

    // ── Progress bar ──
    get progressPercent() {
        if (this.currentStep === 0) return 0;
        return Math.round((this.currentStep / TOTAL_STEPS) * 100);
    }
   get progressStyle() {
    return 'width:' + this.progressPercent + '%;';
   }

    // ── Button visibility ──
    get showBackButton()   { return this.currentStep > 1; }
    get showNextButton()   { return this.currentStep > 0 && this.currentStep < 8; }
    get showSubmitButton() { return this.currentStep === 8; }
    get submitButtonLabel(){
        return this.isSubmitting ? 'Submitting...' : 'Submit & Continue to Sign';
    }

    // ── Navigation ──
    handleStart() { this.currentStep = 1; }

    handleNext() {
        if (!this.validateCurrentStep()) return;
        this.currentStep++;
        window.scrollTo(0, 0);
    }

    handleBack() {
        this.currentStep--;
        window.scrollTo(0, 0);
    }

    // Jump to specific step from summary
    goToStep1() { this.currentStep = 1; }
    goToStep2() { this.currentStep = 2; }
    goToStep5() { this.currentStep = 5; }
    goToStep6() { this.currentStep = 6; }

    // ── Field handlers ──
    handleFieldChange(event) {
        const field = event.target.dataset.field;
        const value = event.detail.value;
        this.formData = { ...this.formData, [field]: value };
    }

    handleLostWork(event) {
        this.formData = { ...this.formData, lostWork: event.target.value };
    }
    handleHasInsurance(event) {
        this.formData = { ...this.formData, hasInsurance: event.target.value };
    }
    handleGovBenefits(event) {
        this.formData = { ...this.formData, hasGovBenefits: event.target.value };
    }
    handleAmbulance(event) {
        this.formData = {
            ...this.formData,
            transportedByAmbulance: event.target.value
        };
    }
    handleOnJob(event) {
        this.formData = { ...this.formData, onJob: event.target.value };
    }
    handleAuthorities(event) {
        this.formData = {
            ...this.formData,
            authoritiesArrived: event.target.value
        };
    }
    handleReportTaken(event) {
        this.formData = { ...this.formData, reportTaken: event.target.value };
    }
    handleCitation(event) {
        this.formData = { ...this.formData, citationGiven: event.target.value };
    }

    // ── Step validation ──
    validateCurrentStep() {
        this.hasFormError     = false;
        this.formErrorMessage = '';

        if (this.currentStep === 1) {
            if (!this.formData.fullName) {
                this.formErrorMessage = 'Full Name is required.';
                this.hasFormError = true; return false;
            }
            if (!this.formData.email) {
                this.formErrorMessage = 'Email is required.';
                this.hasFormError = true; return false;
            }
            if (!this.formData.dateOfBirth) {
                this.formErrorMessage = 'Date of Birth is required.';
                this.hasFormError = true; return false;
            }
            if (this.formData.phone) {
                const phoneRaw = this.formData.phone.replace(/\D/g, '');
                if (phoneRaw.length !== 10) {
                    this.formErrorMessage = 'Phone Number must be 10 digits.';
                    this.hasFormError = true; return false;
                }
            }
            if (this.formData.ssn) {
                const ssnRaw = this.formData.ssn.replace(/\D/g, '');
                if (ssnRaw.length !== 9) {
                    this.formErrorMessage = 'Social Security Number must be 9 digits (XXX-XX-XXXX).';
                    this.hasFormError = true; return false;
                }
            }
        }
        if (this.currentStep === 5) {
            if (!this.formData.injuries) {
                this.formErrorMessage = 'Please describe your injuries.';
                this.hasFormError = true; return false;
            }
        }
        if (this.currentStep === 6) {
            if (!this.formData.incidentDate) {
                this.formErrorMessage = 'Incident Date is required.';
                this.hasFormError = true; return false;
            }
            if (!this.formData.descriptionOfAccident) {
                this.formErrorMessage = 'Please describe how the incident happened.';
                this.hasFormError = true; return false;
            }
        }
        return true;
    }

    // ── Submit ──
   handleSubmit() {
    this.isSubmitting = true;

    const nameParts = (this.formData.fullName || '').trim().split(' ');
    const firstName = nameParts[0] || '';
    const lastName  = nameParts.slice(1).join(' ') || '';

    const submitData = {
        ...this.formData,
        firstName,
        lastName,
        incidentType : this.incidentType
    };

    const plainData  = JSON.parse(JSON.stringify(submitData));
    const jsonString = JSON.stringify(plainData);

    console.log('=== SUBMIT CALLED ===');
    console.log('Session ID   :', this.sessionId);
    console.log('Form Data    :', jsonString);

    submitForm({
        sessionId    : this.sessionId,
        formDataJSON : jsonString
    })
    .then(result => {
        this.isSubmitting = false;

        console.log('=== RESULT FROM APEX ===');
        console.log('Full result  :', JSON.stringify(result));
        console.log('signingURL   :', result.signingURL);
        console.log('error        :', result.error);
        console.log('success      :', result.success);

        if (result.error) {
            this.hasFormError     = true;
            this.formErrorMessage = result.error;
            return;
        }

        if (result.signingURL) {
            console.log('✅ Redirecting to:', result.signingURL);
            window.location.href = result.signingURL;
        } else {
            console.log('❌ No signingURL in result');
            this.hasFormError     = true;
            this.formErrorMessage = 'Could not get signing URL. Please try again.';
        }
    })
    .catch(error => {
        this.isSubmitting     = false;
        this.hasFormError     = true;
        console.log('=== APEX ERROR ===', JSON.stringify(error));
        this.formErrorMessage = error.body ? error.body.message : error.message;
    });
}
}