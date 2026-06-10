/**
 * @description       : 
 * @testing           : 
 * @author            : FSM
 * @last modified on  : 05-29-2025 - FSM
 * @last modified by  : FSM
**/
public class RingCentralSmsService {
    // Returns the unique ID of this SMS send
    public static ServiceResponse sendSms(RingCentralSmsDto dto) {
        List<String> errors = new List<String>();

        // The '~' indicates the default Account or Extension for the current auth session
        if (String.isBlank(dto.fromExtensionId)) {
            dto.fromExtensionId = '~';
        }
        if (String.isBlank(dto.accountId)) {
            dto.accountId = '~';
        }

        // Validate that required fields are provided
        if (String.isBlank(dto.fromPhoneNumber)) {
            errors.add('No "from" phone number provided.');
        }
        if (String.isBlank(dto.message)) {
            errors.add('No message provided.');
        }
        if (dto.toPhoneNumbers == null || dto.toPhoneNumbers.size() == 0) {
            errors.add('No "to" phone number provided.');
        }
        if (errors.size() > 0) {
            ServiceResponse sr = new ServiceResponse();
            sr.isSuccess = false;
            sr.errorMessage = String.join(errors, ' ');
            return sr;
        }

        try {
            RingCentralCalloutSendSms call = new RingCentralCalloutSendSms(
                dto.fromPhoneNumber,
                dto.fromExtensionId,
                dto.toPhoneNumbers,
                dto.message,
                dto.accountId
            );
            HttpResponse res = call.doCallout();
            System.debug(res.getStatusCode());
            System.debug(res.getBody());
        }
        catch(Exception e) {
            ServiceResponse sr = new ServiceResponse();
            sr.isSuccess = false;
            sr.errorMessage = e.getMessage() + ' || ' + e.getStackTraceString();
            return sr;
        }

        ServiceResponse sr = new ServiceResponse();
        sr.isSuccess = true;
        return sr;
    }

    public class ServiceResponse {
        public Boolean isSuccess;
        public String errorMessage;
    }
}