/**
 * @description       : 
 * @testing           : 
 * @author            : FSM
 * @last modified on  : 05-27-2025 - FSM
 * @last modified by  : FSM
**/
public class SmartAdvContactService {
    private SmartAdvTokenService tokenService;

    // Default constructor
    public SmartAdvContactService() {
        this(new SmartAdvTokenService());
    }

    // Constructor for injecting mock/stub
    public SmartAdvContactService(SmartAdvTokenService service) {
        this.tokenService = service;
    }

    public ServiceResponse updateAllRecentContactsFromSmartAdvocate(Datetime startDt, Datetime endDt, Integer currentPage, Integer pageSize) {
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

        List<Contact> conUpsertList = new List<Contact>();
        List<Object> resList;
        try {
            SmartAdvCalloutGetFilteredContacts call = new SmartAdvCalloutGetFilteredContacts(token, startDt, endDt, currentPage, pageSize);
            HttpResponse res = call.doCallout();
            resList = (List<Object>) JSON.deserializeUntyped(res.getBody());

            List<String> contactUids = new List<String>();
            for (Object r : resList) {
                Map<String,Object> m = (Map<String,Object>) r;
                contactUids.add(String.valueOf((Integer) m.get('uniqueContactId')));     // All Contact UIDs that were in the JSON response
            }

            List<Contact> validContacts = SmartAdvContactTranslator.queryContacts(contactUids);
            Map<String,Contact> uidToValidContact = new Map<String,Contact>();
            for (Contact con : validContacts) {
                uidToValidContact.put(con.SmartAdvocate_ID__c, con);
            }

            for (Object r : resList) {
                Map<String,Object> m = (Map<String,Object>) r;
                String uid = String.valueOf((Integer) m.get('uniqueContactId'));
                if (uidToValidContact.keySet().contains(uid)) {
                    Contact con = SmartAdvContactTranslator.contactFromJson(JSON.serialize(r));
                    Contact existingCon = uidToValidContact.get(uid);
                    if (con != existingCon) {
                        System.debug('Contact ' + con.LastName + ' does not match existing. Updating...');
                        conUpsertList.add(con);
                    }
                    else {
                        System.debug('Contact ' + con.LastName + ' already matches existing. No update necessary');
                    }
                }
            }
        }
        catch (Exception e) {
            ServiceResponse sr = new ServiceResponse();
            sr.isSuccess = false;
            sr.errorMessage = 'HTTP Error (Get Filtered Contacts) -- ' + e.getMessage();
            sr.hasAdditionalPages = false;
            return sr;
        }

        Database.UpsertResult[] conUpsertResults = Database.upsert(conUpsertList, Contact.SmartAdvocate_ID__c, false);
        List<String> errors = new List<String>();
        for (Database.UpsertResult result : conUpsertResults) {
            if (!result.isSuccess()) {
                errors.add(String.valueOf(result.getErrors()));
            }
        }

        if (errors.size() > 0) {
            ServiceResponse sr = new ServiceResponse();
            sr.isSuccess = false;
            sr.errorMessage = 'Error saving Contacts -- ' + String.join(errors, ' || ');
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