/**
 * @description       : 
 * @testing           : 
 * @author            : FSM
 * @last modified on  : 05-27-2025 - FSM
 * @last modified by  : FSM
**/
public class SmartAdvCaseService {
    private SmartAdvTokenService tokenService;

    // Default constructor
    public SmartAdvCaseService() {
        this(new SmartAdvTokenService());
    }

    // Constructor for injecting mock/stub
    public SmartAdvCaseService(SmartAdvTokenService service) {
        this.tokenService = service;
    }

    /**
    * @description Using a Case DTO, create a Case in SmartAdvocate. Update the Salesforce Incident Detail with the SmartAdvocate Unique ID
    * @author FSM | 05-02-2025 - FSM 
    * @param SmartAdvCaseDto c 
    * @return ServiceResponse 
    **/
    public List<ServiceResponse> createSmartAdvocateCase(List<SmartAdvCaseDto> cList) {
        List<ServiceResponse> srList = new List<ServiceResponse>();
        for (SmartAdvCaseDto c : cList) {
            srList.add(new ServiceResponse());
        }

        String token;
        SmartAdvTokenService.ServiceResponse srToken = tokenService.getToken();
        if (srToken.isSuccess) {
            token = srToken.token;
        }
        else {
            for (Integer i=0; i < cList.size(); i++) {
                srList[i].isSuccess = false;
                srList[i].errorMessage = srToken.errorMessage;
            }
            return srList;
        }

        List<Incident_Detail__c> indUpdateList = new List<Incident_Detail__c>();    // Incident Details to be updated
        List<Integer> indUpdateIndexList = new List<Integer>();                     // Index of the updated Incident Detail in the flow input. Enables us to pass back ServiceResponses in the correct order
        List<Contact> conUpdateList = new List<Contact>();                          // Contacts to be updated
        List<Integer> conUpdateIndexList = new List<Integer>();                     // Index of the updated Contact in the flow input. Enables us to pass back ServiceResponses in the correct order

        for (Integer i=0; i < cList.size(); i++) {
            SmartAdvCaseDto c = cList[i];

            // Check that all required fields are provided, send back an error if not provided
            List<String> errors = new List<String>();

            if (String.isBlank(c.sfIncidentDetailId)) {
                errors.add('No Salesforce Incident Detail ID provided.');
            }
            if (String.isBlank(c.sfContactId)) {
                errors.add('No Salesforce Contact ID provided.');
            }
            if (String.isBlank(c.office)) {
                errors.add('No office provided.');
            }
            if (String.isBlank(c.caseType)) {
                errors.add('No caseType provided.');
            }
            if (errors.size() > 0) {
                srList[i].isSuccess = false;
                srList[i].errorMessage = String.join(errors, ' ');
                continue;
            }

            String saCaseId;
            String saContactId;
            try {
                SmartAdvCalloutCreateCase callCase = new SmartAdvCalloutCreateCase(token, c);
                HttpResponse resCase = callCase.doCallout();
                Map<String,Object> resMapCase = (Map<String,Object>) JSON.deserializeUntyped(resCase.getBody());
                saCaseId = String.valueOf(resMapCase.get('caseID'));

                List<Object> resListPlaintiffs = (List<Object>) resMapCase.get('plaintiffs');
                Map<String,Object> resMapPlaintiff = (Map<String,Object>) resListPlaintiffs[0];
                saContactId = String.valueOf((Integer) resMapPlaintiff.get('contactID'));
            }
            catch (Exception e) {
                srList[i].isSuccess = false;
                srList[i].errorMessage = 'HTTP Error (Create Case) -- ' + e.getMessage();
                continue;
            }

            // Save the CaseID back to the Salesforce Incident Detail
            Incident_Detail__c ind = new Incident_Detail__c(
                Id = c.sfIncidentDetailId,
                SmartAdvocate_ID__c = saCaseId
            );
            indUpdateList.add(ind);
            indUpdateIndexList.add(i);

            // Save the ContactID back to the Salesforce Contact
            Contact con = new Contact(
                Id = c.sfContactId,
                SmartAdvocate_ID__c = saContactId
            );
            conUpdateList.add(con);
            conUpdateIndexList.add(i);
        }

        // Save both the CaseID and the ContactID back to Salesforce
        // Log an error if one of these fails to save
        Database.SaveResult[] indSaveResultList = Database.update(indUpdateList, false);
        for (Integer j=0; j < indSaveResultList.size(); j++) {
            Database.SaveResult saveResult = indSaveResultList[j];
            Integer i = indUpdateIndexList[j];

            if (saveResult.success) {
                srList[i].isSuccess = (srList[i].isSuccess == null || srList[i].isSuccess == true);     // Don't hide errors by overwriting false with true
            }
            else {
                srList[i].isSuccess = false;
                String errorMsg = srList[i].errorMessage + ' ' ?? '';
                errorMsg += 'Error saving SmartAdvocate ID to Incident Detail -- ' + String.join(saveResult.errors, ' || ');
                srList[i].errorMessage = errorMsg;
            }   
        }

        Database.SaveResult[] conSaveResultList = Database.update(conUpdateList, false);
        for (Integer j=0; j < conSaveResultList.size(); j++) {
            Database.SaveResult saveResult = conSaveResultList[j];
            Integer i = conUpdateIndexList[j];

            if (saveResult.success) {
                srList[i].isSuccess = (srList[i].isSuccess == null || srList[i].isSuccess == true);     // Don't hide errors by overwriting false with true
            }
            else {
                srList[i].isSuccess = false;
                String errorMsg = srList[i].errorMessage + ' ' ?? '';
                errorMsg += 'Error saving SmartAdvocate ID to Contact -- ' + String.join(saveResult.errors, ' || ');
                srList[i].errorMessage = errorMsg;
            }   
        }

        return srList;
    }

    /**
    * @description Pass in pagination and filtering params. Retrieve the status of any recently changed Cases and update the Salesforce Incident Details if needed
    * @author FSM | 05-02-2025 - FSM 
    * @param Datetime startDt 
    * @param Datetime endDt 
    * @param Integer pageNo 
    * @param Integer pageSize 
    * @return ServiceResponse 
    **/
    public ServiceResponse updateAllRecentCaseStatusFromSmartAdvocate(Datetime startDt, Datetime endDt, Integer currentPage, Integer pageSize) {
        String token;
        SmartAdvTokenService.ServiceResponse srToken = tokenService.getToken();
        if (srToken.isSuccess) {
            token = srToken.token;
        }
        else {
            ServiceResponse sr = new ServiceResponse();
            sr.isSuccess = false;
            sr.errorMessage = srToken.errorMessage;
            sr.hasAdditionalPages = false;
            return sr;
        }

        List<Incident_Detail__c> indUpsertList = new List<Incident_Detail__c>();
        List<Object> resList;
        try {
            SmartAdvCalloutGetFilteredCases call = new SmartAdvCalloutGetFilteredCases(token, startDt, endDt, currentPage, pageSize);
            HttpResponse res = call.doCallout();
            resList = (List<Object>) JSON.deserializeUntyped(res.getBody());

            List<String> caseUids = new List<String>();
            for (Object r : resList) {
                Map<String,Object> m = (Map<String,Object>) r;
                caseUids.add(String.valueOf((Integer) m.get('caseID')));     // All Case UIDs that were in the JSON response
            }

            List<Incident_Detail__c> validInds = [SELECT Name, SmartAdvocate_Status__c, SmartAdvocate_ID__c FROM Incident_Detail__c WHERE SmartAdvocate_ID__c IN : caseUids];
            Map<String,Incident_Detail__c> uidToValidInd = new Map<String,Incident_Detail__c>();
            for (Incident_Detail__c ind : validInds) {
                uidToValidInd.put(ind.SmartAdvocate_ID__c, ind);
            }

            for (Object r : resList) {
                Map<String,Object> m = (Map<String,Object>) r;
                String uid = String.valueOf((Integer) m.get('caseID'));
                String smartAdvStatus = (String) m.get('caseStatus');
                if (uidToValidInd.keySet().contains(uid)) {
                    Incident_Detail__c existingInd = uidToValidInd.get(uid);
                    if (existingInd.SmartAdvocate_Status__c != smartAdvStatus) {
                        System.debug('Incident Detail ' + existingInd.Name + ' status does not match existing. Updating...');
                        Incident_Detail__c ind = new Incident_Detail__c(
                            SmartAdvocate_ID__c = uid,
                            SmartAdvocate_Status__c = smartAdvStatus
                        );
                        indUpsertList.add(ind);
                    }
                    else {
                        System.debug('Incident Detail ' + existingInd.Name + ' status already matches existing. No update necessary');
                    }
                }
            }
        }
        catch (Exception e) {
            ServiceResponse sr = new ServiceResponse();
            sr.isSuccess = false;
            sr.errorMessage = 'HTTP Error (Get Filtered Cases) -- ' + e.getMessage();
            sr.hasAdditionalPages = false;
            return sr;
        }

        Database.UpsertResult[] indUpsertResults = Database.upsert(indUpsertList, Incident_Detail__c.SmartAdvocate_ID__c, false);
        List<String> errors = new List<String>();
        for (Database.UpsertResult result : indUpsertResults) {
            if (!result.isSuccess()) {
                errors.add(String.valueOf(result.getErrors()));
            }
        }

        if (errors.size() > 0) {
            ServiceResponse sr = new ServiceResponse();
            sr.isSuccess = false;
            sr.errorMessage = 'Error saving Status to Cases -- ' + String.join(errors, ' || ');
            sr.hasAdditionalPages = false;
            return sr;
        }

        ServiceResponse sr = new ServiceResponse();
        sr.isSuccess = true;
        sr.hasAdditionalPages = resList.size() == pageSize;
        return sr;
    }
    
    public class ServiceResponse {
        public Boolean isSuccess;
        public String errorMessage;
        public Boolean hasAdditionalPages;
    }
}