public class LeadUpdateService {

        @future
        public static void updateLeadFromForm(String leadId, String formDataJSON, String sessionId) {

            System.debug('=== LeadUpdateService START ===');
            System.debug('Lead ID: ' + leadId);
            System.debug('LeadUpdateService PDF session ID: ' + sessionId);

            try {
                // ── Unescape HTML entities ──
                String cleanJSON = formDataJSON
                    .replace('&quot;', '"')
                    .replace('&amp;',  '&')
                    .replace('&#39;',  '\'')
                    .replace('&lt;',   '<')
                    .replace('&gt;',   '>');

                Map<String, Object> f =
                    (Map<String, Object>) JSON.deserializeUntyped(cleanJSON);

                System.debug('Keys received: ' + f.keySet());

                Lead l = new Lead(Id = leadId);

                // ══ PERSONAL ══════════════════════════════════════════
                // New LWC sends fullName — split into First + Last
                if (val(f,'fullName')) {
                    String full        = str(f,'fullName').trim();
                    List<String> parts = full.split(' ', 2);
                    l.FirstName        = parts[0];
                    l.LastName         = parts.size() > 1 ? parts[1] : parts[0];
                }
                // Fallback — old LWC sends firstName/lastName separately
                if (val(f,'firstName'))    l.FirstName          = str(f,'firstName');
                if (val(f,'middleName'))   l.MiddleName         = str(f,'middleName');
                if (val(f,'lastName'))     l.LastName           = str(f,'lastName');

                if (val(f,'email'))        l.Email              = str(f,'email');
                if (val(f,'phone'))        l.Phone              = str(f,'phone');
                if (val(f,'mobile'))       l.MobilePhone        = str(f,'mobile');
                if (val(f,'dateOfBirth'))
                    l.Date_of_Birth__c = parseDate(str(f,'dateOfBirth'));
                if (val(f,'ssn'))
                    l.SSN__c                                    = str(f,'ssn');
                if (val(f,'driversLicense'))
                    l.Drivers_License__c                        = str(f,'driversLicense');
                if (val(f,'howDidYouHear'))
                    l.LeadSource                       = str(f,'howDidYouHear');
                if (val(f,'currentEmployer'))
                    l.Company                                   = str(f,'currentEmployer');

                // ══ ADDRESS ═══════════════════════════════════════════
                // if (val(f,'street'))       l.Street             = str(f,'street');
                // if (val(f,'city'))         l.City               = str(f,'city');
                // if (val(f,'state'))        l.State              = str(f,'state');
                // if (val(f,'postalCode'))   l.PostalCode         = str(f,'postalCode');
                // ══ ADDRESS ═══════════════════════════════════════════
if (val(f,'street'))     l.Street     = str(f,'street');
if (val(f,'city'))       l.City       = str(f,'city');
if (val(f,'postalCode')) l.PostalCode = str(f,'postalCode');

// ── Smart State/Country handler ──
// if (val(f,'state')) {
//     String stateVal   = str(f,'state').trim();
//     String countryVal = val(f,'country')
//         ? str(f,'country').trim() : 'US';

//     // Resolve state code
//     String stateCode   = resolveStateCode(stateVal, countryVal);
//     String countryCode = resolveCountryCode(countryVal);

//     if (String.isNotBlank(stateCode) &&
//         String.isNotBlank(countryCode)) {
//         try {
//             l.CountryCode = countryCode;
//             l.StateCode   = stateCode;
//             System.debug('✅ StateCode: ' + stateCode +
//                          ' CountryCode: ' + countryCode);
//         } catch (Exception e) {
//             System.debug('⚠️ State/Country skip: ' + e.getMessage());
//         }
//     } else {
//         System.debug('⚠️ Could not resolve state: ' + stateVal);
//     }
// }

                // ══ EMERGENCY CONTACT ══════════════════════════════════
                if (val(f,'emergencyName'))
                    l.Emergency_Contact_Name__c                 = str(f,'emergencyName');
                if (val(f,'emergencyAddress'))
                    l.Emergency_Contact_Address__c              = str(f,'emergencyAddress');
                if (val(f,'emergencyPhone'))
                    l.Emergency_Contact_Phone__c                = str(f,'emergencyPhone');
                if (val(f,'emergencyRelation'))
                    l.Emergency_Contact_Relation__c             = str(f,'emergencyRelation');

                // ══ OCCUPATION ════════════════════════════════════════
                // New LWC sends 'lostWork', old sends 'workersComp' picklist
                if (val(f,'lostWork'))
                    l.Lost_Wages_Missed_Work__c                 = str(f,'lostWork');
                if (val(f,'lostWorkDescription'))
                    l.Lost_Work_Description__c                  = str(f,'lostWorkDescription');

                // ══ HEALTH INSURANCE ══════════════════════════════════
                if (f.containsKey('hasInsurance'))
                    l.Health_Insurance_Carrier__c =
                        String.valueOf(f.get('hasInsurance')) == 'Yes';
                if (val(f,'insuranceCarrierName'))
                    l.Insurance_Details__c                      = str(f,'insuranceCarrierName');
                if (f.containsKey('hasGovBenefits')) {
                    Boolean isYes = String.valueOf(f.get('hasGovBenefits')) == 'Yes';
                    l.Medicare__c = isYes;
                    l.Medicaid__c = isYes;
                }
                if (val(f,'govBenefitsName'))
                    l.Gov_Benefits_Details__c                   = str(f,'govBenefitsName');

                // ══ INJURIES ══════════════════════════════════════════
                if (val(f,'injuries'))
                    l.Injuries__c                               = str(f,'injuries');
                if (val(f,'transportedByAmbulance'))
                    l.Transported_to_Hospital_by_Ambulance__c   = str(f,'transportedByAmbulance');
                if (val(f,'treatingProviders'))
                    l.Names_of_Treating_Providers__c            = str(f,'treatingProviders');
                if (val(f,'priorInjuries'))
                    l.Prior_Injuries__c                         = str(f,'priorInjuries');

                // ══ INCIDENT ══════════════════════════════════════════
                // New LWC sends 'incidentType', old sends 'typeOfAccident'
                if (val(f,'incidentType'))
                    l.Type_of_Accident__c                       = str(f,'incidentType');
                if (val(f,'typeOfAccident'))
                    l.Type_of_Accident__c                       = str(f,'typeOfAccident');

                if (val(f,'incidentDate'))
                    l.Incident_Date__c = Date.valueOf(str(f,'incidentDate'));
                if (val(f,'incidentLocation'))
                    l.Incident_Location__c                      = str(f,'incidentLocation');
                if (val(f,'descriptionOfAccident'))
                    l.Description_of_Accident__c                = str(f,'descriptionOfAccident');
                if (val(f,'travelDetails'))
                    l.Travel_Details__c                         = str(f,'travelDetails');
                if (val(f,'additionalIncidentDetails'))
                    l.Additional_Incident_Details__c            = str(f,'additionalIncidentDetails');
                if (val(f,'dangerousCondition'))
                    l.Dangerous_Condition__c                    = str(f,'dangerousCondition');

                // New LWC sends 'onJob', old sends 'workersComp'
                if (val(f,'onJob'))
                    l.Worker_s_Comp__c                          = str(f,'onJob');
                if (val(f,'workersComp'))
                    l.Worker_s_Comp__c                          = str(f,'workersComp');
                if (val(f,'workersCompDetails'))
                    l.Worker_s_Comp_Details__c                  = str(f,'workersCompDetails');

                // ══ CHECKBOXES ════════════════════════════════════════
                if (f.containsKey('wrongfulDeath'))
                    l.Wrongful_Death__c                         = bool(f,'wrongfulDeath');
                if (f.containsKey('police'))
                    l.Police__c                                 = bool(f,'police');
                if (f.containsKey('fireDepartment'))
                    l.Fire_Department__c                        = bool(f,'fireDepartment');
                if (f.containsKey('ambulance'))
                    l.Ambulance__c                              = bool(f,'ambulance');
                if (f.containsKey('bodilyInjuries'))
                    l.Bodily_Injuries__c                        = bool(f,'bodilyInjuries');
                if (f.containsKey('propertyDamages'))
                    l.Property_Damages__c                       = bool(f,'propertyDamages');

                // ══ EMERGENCY SERVICES ════════════════════════════════
                // New LWC sends 'authoritiesArrived'
                if (val(f,'authoritiesArrived'))
                    l.Police_Onsite__c                          = str(f,'authoritiesArrived');
                if (val(f,'authoritiesWhom'))
                    l.Responding_Agency_police__c               = str(f,'authoritiesWhom');
                if (val(f,'respondingPoliceAgency'))
                    l.Responding_Agency_police__c               = str(f,'respondingPoliceAgency');
                if (val(f,'respondingFireAgency'))
                    l.Responding_Agency_fire__c                 = str(f,'respondingFireAgency');
                if (val(f,'respondingAmbulanceAgency'))
                    l.Responding_Agency_ambulance__c            = str(f,'respondingAmbulanceAgency');
                if (val(f,'policeReportNumber'))
                    l.Police_Report_Number__c                   = str(f,'policeReportNumber');

                // ══ INCIDENT EXTRAS ═══════════════════════════════════
                // New LWC sends 'reportTaken'
                if (val(f,'reportTaken'))
                    l.Other_Incident_Report__c                  = str(f,'reportTaken');
                if (val(f,'otherIncidentReport'))
                    l.Other_Incident_Report__c                  = str(f,'otherIncidentReport');

                // New LWC sends 'citationGiven', old sends 'citationArrested'
                if (val(f,'citationGiven'))
                    l.Anyone_Given_Citation_Arrested_at_Scene__c = str(f,'citationGiven');
                if (val(f,'citationArrested'))
                    l.Anyone_Given_Citation_Arrested_at_Scene__c = str(f,'citationArrested');

                if (val(f,'citationArrestDetails'))
                    l.Other_Citation_Arrest_Details__c          = str(f,'citationArrestDetails');
                if (val(f,'witnessDetails'))
                    l.Witness_Details__c                        = str(f,'witnessDetails');
                if (val(f,'witnesses'))
                    l.Witnesses__c                              = str(f,'witnesses');
                if (val(f,'minorInjury'))
                    l.Minor_Injury__c                           = str(f,'minorInjury');
                if (val(f,'emergencyFacility'))
                    l.Name_of_Emergency_Facility__c             = str(f,'emergencyFacility');
                if (val(f,'otherIncidentReportDetails'))
                    l.Other_Incident_Report_Details__c          = str(f,'otherIncidentReportDetails');
                if (val(f,'otherFamilyMinors'))
                    l.Other_Family_Minors__c                    = str(f,'otherFamilyMinors');

                // ══ MOTOR VEHICLE ═════════════════════════════════════
                if (val(f,'driverDetails'))
                    l.Driver_Details__c                         = str(f,'driverDetails');
                if (val(f,'passengerDetails'))
                    l.Passenger_Details__c                      = str(f,'passengerDetails');
                if (val(f,'atFaultCompanyVehicle'))
                    l.At_Fault_Driver_Using_a_Company_Vehicle__c = str(f,'atFaultCompanyVehicle');
                if (val(f,'atFaultPartyName'))
                    l.Name_of_At_Fault_Party__c                 = str(f,'atFaultPartyName');
                if (val(f,'atFaultPartyPhone'))
                    l.At_Fault_Party_s_Phone_Number__c          = str(f,'atFaultPartyPhone');
                if (val(f,'atFaultPartyAddressPhone'))
                    l.Address_Phone_No_for_At_Fault_Party__c    = str(f,'atFaultPartyAddressPhone');
                if (val(f,'plaintiffCarrierName'))
                    l.Coverage_for_No_Fault_Plaintiff__c        = str(f,'plaintiffCarrierName');
                if (val(f,'plaintiffPolicyClaim'))
                    l.Plaintiff_Policy_Claim__c                 = str(f,'plaintiffPolicyClaim');
                if (val(f,'defendantCarrierName'))
                    l.Coverage_for_At_Fault_Defendant__c        = str(f,'defendantCarrierName');
                if (val(f,'defendantPolicyClaim'))
                    l.Defendant_Policy_Claim__c                 = str(f,'defendantPolicyClaim');
                // Fallback old LWC keys
                if (val(f,'coverageNoFault'))
                    l.Coverage_for_No_Fault_Plaintiff__c        = str(f,'coverageNoFault');
                if (val(f,'coverageAtFault'))
                    l.Coverage_for_At_Fault_Defendant__c        = str(f,'coverageAtFault');
                if (val(f,'communicationsAtFault'))
                    l.Communications_w_At_Fault_Party__c        = str(f,'communicationsAtFault');

                // ══ ANIMAL ATTACK ═════════════════════════════════════
                if (val(f,'animalOwnerName'))
                    l.Name_of_Animal_Owner__c                   = str(f,'animalOwnerName');
                if (val(f,'animalOwnerPhone'))
                    l.Animal_Owner_s_Phone_Number__c            = str(f,'animalOwnerPhone');
                if (val(f,'animalOwnerAddressPhone'))
                    l.Address_Phone_Number_of_Animal_Owner__c   = str(f,'animalOwnerAddressPhone');
                // New LWC sends 'animalBreed', old sends 'descriptionOfAnimal'
                if (val(f,'animalBreed'))
                    l.Description_of_Animal__c                  = str(f,'animalBreed');
                if (val(f,'descriptionOfAnimal'))
                    l.Description_of_Animal__c                  = str(f,'descriptionOfAnimal');
                if (val(f,'animalReport'))
                    l.Animal_Report__c                          = str(f,'animalReport');
                if (val(f,'animalReportDetails'))
                    l.Animal_Report_Details__c                  = str(f,'animalReportDetails');
                if (val(f,'communicationsWithAnimalOwner'))
                    l.Communications_with_Animal_Owner__c       = str(f,'communicationsWithAnimalOwner');
                if (val(f,'coverageAnimalOwner'))
                    l.Coverage_for_Animal_Owner_Defendant__c    = str(f,'coverageAnimalOwner');
                if (val(f,'homeOwnerName'))
                    l.Home_Owner_Name__c                        = str(f,'homeOwnerName');

                // ══ PREMISE ═══════════════════════════════════════════
                if (val(f,'atFaultPartyAddressPhone'))
                    l.Address_Phone_No_for_At_Fault_Party__c    = str(f,'atFaultPartyAddressPhone');

                // ══ INSURANCE ════════════════════════════════════════
                if (val(f,'claimNumber'))
                    l.Claim_Number__c                           = str(f,'claimNumber');
                if (val(f,'reportedClaim'))
                    l.Have_You_Reported_a_Claim__c              = str(f,'reportedClaim');
                if (val(f,'propertyDamageClaimStatus'))
                    l.Status_of_Property_Damage_Claim__c        = str(f,'propertyDamageClaimStatus');
                if (val(f,'propertyDamageDetails'))
                    l.Property_Damage_Details__c                = str(f,'propertyDamageDetails');
                    // ══ NEW UNMAPPED FIELDS ═════════════════════════════

    // Party/Witness Info
    if (val(f,'witnessDetails'))
        l.Party_Witness_Info__c = str(f,'witnessDetails');

    // On Duty During Incident?
    if (val(f,'onJob'))
        l.On_Duty_During_Incident__c = str(f,'onJob');

    // Did the authorities arrive?
    if (val(f,'authoritiesArrived'))
        l.Did_the_authorities_arrive__c = str(f,'authoritiesArrived');

    // If any, whom?
    if (val(f,'authoritiesWhom'))
        l.If_any_whom__c = str(f,'authoritiesWhom');

    // Was any report taken?
    if (val(f,'reportTaken'))
        l.Was_any_report_taken__c = str(f,'reportTaken');

    // Citation Issued?
    if (val(f,'citationGiven'))
        l.Citation_Issued__c = str(f,'citationGiven');

    // Date of Incident
    if (val(f,'incidentDate'))
        l.Date_of_Incident__c = Date.valueOf(str(f,'incidentDate'));

    // Lost Work Time Due to Injury?
    if (val(f,'lostWork'))
        l.Lost_Work_Time_Due_to_Injury__c = str(f,'lostWork');
                // Lost Work Time Due to Injury?
if (val(f,'lostWork'))
    l.Lost_Work_Time_Due_to_Injury__c = str(f,'lostWork');

    if (val(f,'animalOwnerAddressPhone'))
    l.Animal_Owner_Address_Phone__c = str(f,'animalOwnerAddressPhone');

System.debug('LeadUpdateService about to update Lead before PDF enqueue. leadId=' + leadId + ', sessionId=' + sessionId);
Database.SaveResult sr = Database.update(l, false);

if (sr.isSuccess()) {

    System.debug('✅ Lead updated successfully: ' + leadId);
    System.debug('LeadUpdateService Lead update succeeded, now creating PDF. sessionId=' + sessionId);
    sendBellNotification(leadId);
    createAndAttachIntakePdf(leadId, sessionId, l, f);

} else {

                for (Database.Error err : sr.getErrors()) {

                    System.debug('❌ STATUS CODE: ' + err.getStatusCode());
                    System.debug('❌ ERROR MSG : ' + err.getMessage());
                    System.debug('❌ FIELDS    : ' + err.getFields());

                }
            }
            // ── State/Country update — separate try/catch ──
            // Runs independently — never blocks main update
            if (val(f,'state')) {
                tryUpdateStateCountry(leadId, str(f,'state'),
                    val(f,'country') ? str(f,'country') : 'US');
            }
            } catch (Exception e) {
                System.debug('❌ FAILED: ' + e.getMessage());
                System.debug('Stack    : ' + e.getStackTraceString());
            }
        }
private static void tryUpdateStateCountry(
    String leadId,
    String stateVal,
    String countryVal
) {
    try {
        String stateCode   = resolveStateCode(stateVal, countryVal);
        String countryCode = resolveCountryCode(countryVal);

        if (String.isBlank(stateCode) || String.isBlank(countryCode)) {
            System.debug('⚠️ Cannot resolve state: ' + stateVal);
            return;
        }

        Lead sl        = new Lead(Id = leadId);
        sl.CountryCode = countryCode;
        sl.StateCode   = stateCode;

        Database.SaveResult sr = Database.update(sl, false);

        if (sr.isSuccess()) {
            System.debug('✅ State updated: ' +
                stateCode + ' / ' + countryCode);
        } else {
            for (Database.Error err : sr.getErrors()) {
                System.debug('⚠️ State update skipped: ' +
                    err.getMessage());
            }
        }
    } catch (Exception e) {
        // ── Never crash — just log and move on ──
        System.debug('⚠️ State skip: ' + e.getMessage());
    }
}
        // ── BELL NOTIFICATION ─────────────────────────────────────────
        private static void sendBellNotification(String leadId) {
            try {
                List<CustomNotificationType> types = [
                    SELECT Id
                    FROM   CustomNotificationType
                    WHERE  DeveloperName = 'Intake_Form_Submitted'
                    LIMIT  1
                ];
                if (types.isEmpty()) {
                    System.debug('⚠️ CustomNotificationType Intake_Form_Submitted not found');
                    return;
                }

                Lead l = [
                    SELECT OwnerId, FirstName, LastName
                    FROM   Lead
                    WHERE  Id = :leadId
                    LIMIT  1
                ];

                Messaging.CustomNotification notif = new Messaging.CustomNotification();
                notif.setNotificationTypeId(types[0].Id);
                notif.setTargetId((Id) leadId);
                notif.setTitle('Intake Form Submitted');
                notif.setBody(l.FirstName + ' ' + l.LastName + ' has completed their intake form.');
                notif.send(new Set<String>{ l.OwnerId });

                System.debug('✅ Bell notification sent to owner: ' + l.OwnerId);
            } catch (Exception e) {
                System.debug('⚠️ Bell notification failed: ' + e.getMessage());
            }
        }

        // ── HELPERS ───────────────────────────────────────────────────
        private static void createAndAttachIntakePdf(
            String leadId,
            String sessionId,
            Lead updatedLead,
            Map<String, Object> formData
        ) {
            try {
                String pdfHtml = buildIntakePdfHtml(leadId, sessionId, updatedLead, formData);
                Blob pdfBlob = Blob.toPdf(pdfHtml);

                String clientName = firstPresent(new List<String>{
                    strOrBlank(formData, 'fullName'),
                    ((updatedLead.FirstName == null ? '' : updatedLead.FirstName) + ' ' +
                        (updatedLead.LastName == null ? '' : updatedLead.LastName)).trim(),
                    (strOrBlank(formData, 'firstName') + ' ' + strOrBlank(formData, 'lastName')).trim()
                });
                if (String.isBlank(clientName)) {
                    clientName = 'Client';
                }

                String fileName = 'Intake_Form_' + safeFilePart(clientName) + '_' +
                    DateTime.now().format('yyyy-MM-dd') + '.pdf';

                ContentVersion cv = new ContentVersion();
                cv.Title = fileName.substring(0, fileName.length() - 4);
                cv.PathOnClient = fileName;
                cv.VersionData = pdfBlob;
                cv.IsMajorVersion = true;
                cv.FirstPublishLocationId = (Id) leadId;
                insert cv;

                System.debug('Intake PDF attached directly to Lead: ' + leadId +
                    ', fileName=' + fileName + ', size=' + pdfBlob.size());
            } catch (Exception e) {
                System.debug('PDF creation after Lead update failed: ' + e.getMessage());
            }
        }

        private static String buildIntakePdfHtml(
            String leadId,
            String sessionId,
            Lead l,
            Map<String, Object> f
        ) {
            String clientName = firstPresent(new List<String>{
                strOrBlank(f, 'fullName'),
                ((l.FirstName == null ? '' : l.FirstName) + ' ' +
                    (l.LastName == null ? '' : l.LastName)).trim(),
                (strOrBlank(f, 'firstName') + ' ' + strOrBlank(f, 'lastName')).trim()
            });

            String incidentType = firstPresent(new List<String>{
                strOrBlank(f, 'incidentType'),
                strOrBlank(f, 'typeOfAccident'),
                l.Type_of_Accident__c
            });

            String address = joinParts(new List<String>{
                firstPresent(new List<String>{ strOrBlank(f, 'street'), l.Street }),
                firstPresent(new List<String>{ strOrBlank(f, 'city'), l.City }),
                firstPresent(new List<String>{ strOrBlank(f, 'state'), l.State }),
                firstPresent(new List<String>{ strOrBlank(f, 'postalCode'), l.PostalCode })
            }, ', ');

            String body = pdfHtmlStart();
            body += '<div class="hero">';
            body += '<div class="firm">McCraw Law Group</div>';
            body += '<div class="title">Client Intake Form</div>';
            body += '<div class="subtitle">Submitted Copy</div>';
            body += '</div>';
            body += '<div class="summary">';
            body += line('Generated', String.valueOf(System.now()));
            body += line('Lead Id', leadId);
            if (String.isNotBlank(sessionId)) body += line('Intake Session Id', sessionId);
            body += '</div>';

            body += section('Personal Information');
             body += '\r\n';
            body += line('Full Name', clientName);
             body += '\r\n';
            body += line('Date of Birth', firstPresent(new List<String>{ strOrBlank(f, 'dateOfBirth'), stringValue(l.Date_of_Birth__c) }));
            body += line('Email', firstPresent(new List<String>{ strOrBlank(f, 'email'), l.Email }));
            body += line('Phone', firstPresent(new List<String>{ strOrBlank(f, 'phone'), l.Phone }));
            body += line('Mobile', firstPresent(new List<String>{ strOrBlank(f, 'mobile'), l.MobilePhone }));
            body += line('Address', address);
            body += line('SSN', firstPresent(new List<String>{ strOrBlank(f, 'ssn'), l.SSN__c }));
            body += line('Driver License', firstPresent(new List<String>{ strOrBlank(f, 'driversLicense'), l.Drivers_License__c }));
            body += line('How Did You Hear', firstPresent(new List<String>{ strOrBlank(f, 'howDidYouHear'), l.LeadSource }));
            body += line('Current Employer', firstPresent(new List<String>{ strOrBlank(f, 'currentEmployer'), l.Company }));

            body += section('Emergency Contact');
            body += line('Name', firstPresent(new List<String>{ strOrBlank(f, 'emergencyName'), l.Emergency_Contact_Name__c }));
            body += line('Relationship', firstPresent(new List<String>{ strOrBlank(f, 'emergencyRelation'), l.Emergency_Contact_Relation__c }));
            body += line('Phone', firstPresent(new List<String>{ strOrBlank(f, 'emergencyPhone'), l.Emergency_Contact_Phone__c }));
            body += line('Address', firstPresent(new List<String>{ strOrBlank(f, 'emergencyAddress'), l.Emergency_Contact_Address__c }));

            body += section('Insurance and Work');
            body += line('Lost Work Due to Injury', firstPresent(new List<String>{ strOrBlank(f, 'lostWork'), l.Lost_Wages_Missed_Work__c }));
            body += line('Lost Work Description', firstPresent(new List<String>{ strOrBlank(f, 'lostWorkDescription'), l.Lost_Work_Description__c }));
            body += line('Has Health Insurance', firstPresent(new List<String>{ strOrBlank(f, 'hasInsurance'), stringValue(l.Health_Insurance_Carrier__c) }));
            body += line('Insurance Carrier', firstPresent(new List<String>{ strOrBlank(f, 'insuranceCarrierName'), l.Insurance_Details__c }));
            body += line('Government Benefits', firstPresent(new List<String>{ strOrBlank(f, 'hasGovBenefits'), boolText(l.Medicare__c == true || l.Medicaid__c == true) }));
            body += line('Benefits Name', firstPresent(new List<String>{ strOrBlank(f, 'govBenefitsName'), l.Gov_Benefits_Details__c }));

            body += section('Injuries');
            body += line('Injuries', firstPresent(new List<String>{ strOrBlank(f, 'injuries'), l.Injuries__c }));
            body += line('Transported By Ambulance', firstPresent(new List<String>{ strOrBlank(f, 'transportedByAmbulance'), l.Transported_to_Hospital_by_Ambulance__c }));
            body += line('Treating Providers', firstPresent(new List<String>{ strOrBlank(f, 'treatingProviders'), l.Names_of_Treating_Providers__c }));
            body += line('Prior Injuries', firstPresent(new List<String>{ strOrBlank(f, 'priorInjuries'), l.Prior_Injuries__c }));

            body += section('Incident Details');
            body += line('Incident Type', incidentType);
            body += line('Incident Date', firstPresent(new List<String>{ strOrBlank(f, 'incidentDate'), stringValue(l.Incident_Date__c), stringValue(l.Date_of_Incident__c) }));
            body += line('Location', firstPresent(new List<String>{ strOrBlank(f, 'incidentLocation'), l.Incident_Location__c }));
            body += line('Description', firstPresent(new List<String>{ strOrBlank(f, 'descriptionOfAccident'), l.Description_of_Accident__c }));
            body += line('Travel Details', firstPresent(new List<String>{ strOrBlank(f, 'travelDetails'), l.Travel_Details__c }));
            body += line('Additional Details', firstPresent(new List<String>{ strOrBlank(f, 'additionalIncidentDetails'), l.Additional_Incident_Details__c }));
            body += line('Dangerous Condition', firstPresent(new List<String>{ strOrBlank(f, 'dangerousCondition'), l.Dangerous_Condition__c }));
            body += line('On Job', firstPresent(new List<String>{ strOrBlank(f, 'onJob'), strOrBlank(f, 'workersComp'), l.Worker_s_Comp__c }));
            body += line('Workers Comp Details', firstPresent(new List<String>{ strOrBlank(f, 'workersCompDetails'), l.Worker_s_Comp_Details__c }));

            body += section('Emergency Services and Reports');
            body += line('Authorities Arrived', firstPresent(new List<String>{ strOrBlank(f, 'authoritiesArrived'), l.Police_Onsite__c }));
            body += line('Which Authorities', firstPresent(new List<String>{ strOrBlank(f, 'authoritiesWhom'), l.Responding_Agency_police__c }));
            body += line('Police Report Number', firstPresent(new List<String>{ strOrBlank(f, 'policeReportNumber'), l.Police_Report_Number__c }));
            body += line('Report Taken', firstPresent(new List<String>{ strOrBlank(f, 'reportTaken'), l.Other_Incident_Report__c }));
            body += line('Citation Issued', firstPresent(new List<String>{ strOrBlank(f, 'citationGiven'), strOrBlank(f, 'citationArrested'), l.Anyone_Given_Citation_Arrested_at_Scene__c }));
            body += line('Citation Details', firstPresent(new List<String>{ strOrBlank(f, 'citationArrestDetails'), l.Other_Citation_Arrest_Details__c }));
            body += line('Witness Details', firstPresent(new List<String>{ strOrBlank(f, 'witnessDetails'), l.Witness_Details__c }));

            body += section('Motor Vehicle / Premises / Animal Details');
            body += line('Driver Details', firstPresent(new List<String>{ strOrBlank(f, 'driverDetails'), l.Driver_Details__c }));
            body += line('Passenger Details', firstPresent(new List<String>{ strOrBlank(f, 'passengerDetails'), l.Passenger_Details__c }));
            body += line('At Fault Party Name', firstPresent(new List<String>{ strOrBlank(f, 'atFaultPartyName'), l.Name_of_At_Fault_Party__c }));
            body += line('At Fault Party Phone', firstPresent(new List<String>{ strOrBlank(f, 'atFaultPartyPhone'), l.At_Fault_Party_s_Phone_Number__c }));
            body += line('At Fault Party Address/Phone', firstPresent(new List<String>{ strOrBlank(f, 'atFaultPartyAddressPhone'), l.Address_Phone_No_for_At_Fault_Party__c }));
            body += line('Plaintiff Carrier', firstPresent(new List<String>{ strOrBlank(f, 'plaintiffCarrierName'), l.Coverage_for_No_Fault_Plaintiff__c }));
            body += line('Plaintiff Policy/Claim', firstPresent(new List<String>{ strOrBlank(f, 'plaintiffPolicyClaim'), l.Plaintiff_Policy_Claim__c }));
            body += line('Defendant Carrier', firstPresent(new List<String>{ strOrBlank(f, 'defendantCarrierName'), l.Coverage_for_At_Fault_Defendant__c }));
            body += line('Defendant Policy/Claim', firstPresent(new List<String>{ strOrBlank(f, 'defendantPolicyClaim'), l.Defendant_Policy_Claim__c }));
            body += line('Animal Owner Name', firstPresent(new List<String>{ strOrBlank(f, 'animalOwnerName'), l.Name_of_Animal_Owner__c }));
            body += line('Animal Owner Phone', firstPresent(new List<String>{ strOrBlank(f, 'animalOwnerPhone'), l.Animal_Owner_s_Phone_Number__c }));
            body += line('Animal Owner Address/Phone', firstPresent(new List<String>{ strOrBlank(f, 'animalOwnerAddressPhone'), l.Animal_Owner_Address_Phone__c, l.Address_Phone_Number_of_Animal_Owner__c }));
            body += line('Animal Description', firstPresent(new List<String>{ strOrBlank(f, 'animalBreed'), strOrBlank(f, 'descriptionOfAnimal'), l.Description_of_Animal__c }));
            body += line('Home Owner Name', firstPresent(new List<String>{ strOrBlank(f, 'homeOwnerName'), l.Home_Owner_Name__c }));

            body += section('Claim Details');
            body += line('Claim Number', firstPresent(new List<String>{ strOrBlank(f, 'claimNumber'), l.Claim_Number__c }));
            body += line('Reported Claim', firstPresent(new List<String>{ strOrBlank(f, 'reportedClaim'), l.Have_You_Reported_a_Claim__c }));
            body += line('Property Damage Claim Status', firstPresent(new List<String>{ strOrBlank(f, 'propertyDamageClaimStatus'), l.Status_of_Property_Damage_Claim__c }));
            body += line('Property Damage Details', firstPresent(new List<String>{ strOrBlank(f, 'propertyDamageDetails'), l.Property_Damage_Details__c }));

            body += '<div class="footer">Confidential client intake document. Generated automatically upon form submission.</div>';
            body += '</body></html>';

            return body;
        }

        private static String pdfHtmlStart() {
            return '<!DOCTYPE html><html><head><meta charset="UTF-8"/><style>'
                + '@page{margin:28px;}'
                + 'body{font-family:Arial,Helvetica,sans-serif;color:#202124;font-size:11px;line-height:1.35;}'
                + '.hero{border-bottom:3px solid #1f4e79;padding-bottom:12px;margin-bottom:14px;}'
                + '.firm{font-size:23px;font-weight:700;color:#1f4e79;letter-spacing:.2px;}'
                + '.title{font-size:16px;font-weight:700;margin-top:4px;color:#222;}'
                + '.subtitle{font-size:11px;color:#666;text-transform:uppercase;margin-top:2px;}'
                + '.summary{background:#f3f7fb;border:1px solid #d7e3ee;padding:10px 12px;margin-bottom:14px;}'
                + 'h2{font-size:13px;text-transform:uppercase;color:#fff;background:#1f4e79;padding:7px 9px;margin:14px 0 0;}'
                + '.field{border:1px solid #e1e5ea;border-top:0;padding:7px 9px;page-break-inside:avoid;}'
                + '.label{font-size:9px;color:#56606b;text-transform:uppercase;font-weight:700;margin-bottom:3px;}'
                + '.value{font-size:11px;color:#111;white-space:pre-wrap;word-wrap:break-word;}'
                + '.footer{border-top:1px solid #c8d1da;margin-top:18px;padding-top:8px;font-size:9px;color:#68717a;text-align:center;}'
                + '</style></head><body>';
        }

        private static String section(String title) {
            String normalizedTitle = title == null ? '' : title.toUpperCase();
            return '<h2>' + escHtml(normalizedTitle) + '</h2>';
        }

        private static String line(String label, String value) {
            String display = String.isBlank(value) || value == 'null' ? '-' : value;
            return '<div class="field"><div class="label">' + escHtml(label) + '</div>'
                + '<div class="value">' + escHtml(display) + '</div></div>';
        }

        private static String escHtml(String value) {
            if (value == null) {
                return '';
            }
            return value
                .replace('&', '&amp;')
                .replace('<', '&lt;')
                .replace('>', '&gt;')
                .replace('"', '&quot;')
                .replace('\'', '&#39;');
        }

        private static String wrapText(String raw, String indent, Integer maxWidth) {
            String value = String.isBlank(raw) ? '-' : raw.trim();
            value = value.replace('\r\n', '\n').replace('\r', '\n').replace('\t', ' ');

            List<String> paragraphs = value.split('\n');
            List<String> wrappedLines = new List<String>();

            for (String paragraph : paragraphs) {
                String cleanParagraph = paragraph == null ? '' : paragraph.trim();
                if (String.isBlank(cleanParagraph)) {
                    wrappedLines.add(indent);
                    continue;
                }

                List<String> words = cleanParagraph.split('\\s+');
                String currentLine = indent;

                for (String word : words) {
                    if (String.isBlank(word)) {
                        continue;
                    }

                    Integer proposedLength = currentLine == indent
                        ? indent.length() + word.length()
                        : currentLine.length() + 1 + word.length();

                    if (proposedLength > maxWidth && currentLine != indent) {
                        wrappedLines.add(currentLine);
                        currentLine = indent + word;
                    } else {
                        currentLine += currentLine == indent ? word : ' ' + word;
                    }
                }

                if (currentLine != indent) {
                    wrappedLines.add(currentLine);
                }
            }

            return String.join(wrappedLines, '\r\n');
        }

        private static String repeatChar(String value, Integer count) {
            String repeated = '';
            for (Integer i = 0; i < count; i++) {
                repeated += value;
            }
            return repeated;
        }

        private static String strOrBlank(Map<String, Object> m, String k) {
            return val(m, k) ? str(m, k).trim() : '';
        }

        private static String stringValue(Object value) {
            return value == null ? '' : String.valueOf(value);
        }

        private static String boolText(Boolean value) {
            return value == true ? 'Yes' : '';
        }

        private static String firstPresent(List<String> values) {
            for (String value : values) {
                if (String.isNotBlank(value) && value.trim() != 'null') {
                    return value.trim();
                }
            }
            return '';
        }

        private static String joinParts(List<String> values, String separator) {
            List<String> clean = new List<String>();
            for (String value : values) {
                if (String.isNotBlank(value) && value.trim() != 'null') {
                    clean.add(value.trim());
                }
            }
            return String.join(clean, separator);
        }

        private static String safeFilePart(String raw) {
            String cleaned = String.isBlank(raw)
                ? 'Client'
                : raw.replaceAll('[^a-zA-Z0-9 ]', '').trim().replace(' ', '_');
            return String.isBlank(cleaned) ? 'Client' : cleaned;
        }

        private static Boolean val(Map<String,Object> m, String k) {
            return m.containsKey(k)
                && m.get(k) != null
                && String.valueOf(m.get(k)).trim() != ''
                && String.valueOf(m.get(k)) != 'null';
        }

        private static String str(Map<String,Object> m, String k) {
            return String.valueOf(m.get(k));
        }

        private static Boolean bool(Map<String,Object> m, String k) {
            Object v = m.get(k);
            if (v instanceof Boolean) return (Boolean) v;
            return String.valueOf(v) == 'true';
        }

        private static Date parseDate(String raw) {
            if (String.isBlank(raw)) return null;
            raw = raw.trim();

            // ISO format YYYY-MM-DD
            try { return Date.valueOf(raw); } catch (Exception e) {}

            // "Month D, YYYY" — e.g. "May 12, 2026"
            Map<String,Integer> months = new Map<String,Integer>{
                'january'=>1,'february'=>2,'march'=>3,'april'=>4,
                'may'=>5,'june'=>6,'july'=>7,'august'=>8,
                'september'=>9,'october'=>10,'november'=>11,'december'=>12
            };
            try {
                String[] parts = raw.replace(',','').split('\\s+');
                if (parts.size() == 3) {
                    Integer month = months.get(parts[0].toLowerCase());
                    Integer day   = Integer.valueOf(parts[1]);
                    Integer year  = Integer.valueOf(parts[2]);
                    if (month != null) return Date.newInstance(year, month, day);
                }
            } catch (Exception e) {}

            System.debug('⚠️ Could not parse date: ' + raw);
            return null;
        }
        // ── Resolve StateCode from full name or code ──
        private static String resolveStateCode(
            String stateVal,
            String countryVal
        ) {
            if (String.isBlank(stateVal)) return null;

            String s = stateVal.trim().toUpperCase();

            // Already a 2-letter code
            if (s.length() == 2) return s;

            // ── US States ──
            Map<String, String> usStates = new Map<String, String>{
                'ALABAMA'              => 'AL', 'ALASKA'               => 'AK',
                'ARIZONA'             => 'AZ', 'ARKANSAS'             => 'AR',
                'CALIFORNIA'          => 'CA', 'COLORADO'             => 'CO',
                'CONNECTICUT'         => 'CT', 'DELAWARE'             => 'DE',
                'FLORIDA'             => 'FL', 'GEORGIA'              => 'GA',
                'HAWAII'              => 'HI', 'IDAHO'                => 'ID',
                'ILLINOIS'            => 'IL', 'INDIANA'              => 'IN',
                'IOWA'                => 'IA', 'KANSAS'               => 'KS',
                'KENTUCKY'            => 'KY', 'LOUISIANA'            => 'LA',
                'MAINE'               => 'ME', 'MARYLAND'             => 'MD',
                'MASSACHUSETTS'       => 'MA', 'MICHIGAN'             => 'MI',
                'MINNESOTA'           => 'MN', 'MISSISSIPPI'          => 'MS',
                'MISSOURI'            => 'MO', 'MONTANA'              => 'MT',
                'NEBRASKA'            => 'NE', 'NEVADA'               => 'NV',
                'NEW HAMPSHIRE'       => 'NH', 'NEW JERSEY'           => 'NJ',
                'NEW MEXICO'          => 'NM', 'NEW YORK'             => 'NY',
                'NORTH CAROLINA'      => 'NC', 'NORTH DAKOTA'         => 'ND',
                'OHIO'                => 'OH', 'OKLAHOMA'             => 'OK',
                'OREGON'              => 'OR', 'PENNSYLVANIA'         => 'PA',
                'RHODE ISLAND'        => 'RI', 'SOUTH CAROLINA'       => 'SC',
                'SOUTH DAKOTA'        => 'SD', 'TENNESSEE'            => 'TN',
                'TEXAS'               => 'TX', 'UTAH'                 => 'UT',
                'VERMONT'             => 'VT', 'VIRGINIA'             => 'VA',
                'WASHINGTON'          => 'WA', 'WEST VIRGINIA'        => 'WV',
                'WISCONSIN'           => 'WI', 'WYOMING'              => 'WY',
                'DISTRICT OF COLUMBIA'=> 'DC', 'WASHINGTON DC'        => 'DC'
            };

            // ── Indian States ──
            Map<String, String> inStates = new Map<String, String>{
                'ANDHRA PRADESH'      => 'AP', 'ARUNACHAL PRADESH'    => 'AR',
                'ASSAM'               => 'AS', 'BIHAR'                => 'BR',
                'CHHATTISGARH'        => 'CG', 'GOA'                  => 'GA',
                'GUJARAT'             => 'GJ', 'HARYANA'              => 'HR',
                'HIMACHAL PRADESH'    => 'HP', 'JHARKHAND'            => 'JH',
                'KARNATAKA'           => 'KA', 'KERALA'               => 'KL',
                'MADHYA PRADESH'      => 'MP', 'MAHARASHTRA'          => 'MH',
                'MANIPUR'             => 'MN', 'MEGHALAYA'            => 'ML',
                'MIZORAM'             => 'MZ', 'NAGALAND'             => 'NL',
                'ODISHA'              => 'OR', 'PUNJAB'               => 'PB',
                'RAJASTHAN'           => 'RJ', 'SIKKIM'               => 'SK',
                'TAMIL NADU'          => 'TN', 'TELANGANA'            => 'TG',
                'TRIPURA'             => 'TR', 'UTTAR PRADESH'        => 'UP',
                'UTTARAKHAND'         => 'UK', 'WEST BENGAL'          => 'WB',
                'DELHI'               => 'DL', 'NEW DELHI'            => 'DL'
            };

            String country = String.isBlank(countryVal)
                ? 'US' : countryVal.trim().toUpperCase();

            if (country == 'IN' || country == 'INDIA') {
                if (inStates.containsKey(s)) return inStates.get(s);
            }

            // Default → try US states
            if (usStates.containsKey(s)) return usStates.get(s);

            // Try Indian states as fallback
            if (inStates.containsKey(s)) return inStates.get(s);

            // Already a valid code — return as-is
            return s.length() <= 3 ? s : null;
        }


        // ── Resolve CountryCode ──
        private static String resolveCountryCode(String countryVal) {
            if (String.isBlank(countryVal)) return 'US';

            String c = countryVal.trim().toUpperCase();

            // Already a 2-letter code
            if (c.length() == 2) return c;

            Map<String, String> countries = new Map<String, String>{
                'UNITED STATES'       => 'US', 'USA'        => 'US',
                'AMERICA'             => 'US', 'US'         => 'US',
                'INDIA'               => 'IN', 'CANADA'     => 'CA',
                'UNITED KINGDOM'      => 'GB', 'UK'         => 'GB',
                'AUSTRALIA'           => 'AU', 'GERMANY'    => 'DE',
                'FRANCE'              => 'FR', 'MEXICO'     => 'MX',
                'BRAZIL'              => 'BR', 'CHINA'      => 'CN',
                'JAPAN'               => 'JP', 'PAKISTAN'   => 'PK',
                'BANGLADESH'          => 'BD', 'NIGERIA'    => 'NG',
                'SOUTH AFRICA'        => 'ZA', 'KENYA'      => 'KE'
            };

            return countries.containsKey(c) ? countries.get(c) : 'US';
        }
    }