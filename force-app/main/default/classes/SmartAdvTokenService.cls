/**
 * @description       : 
 * @testing           : 
 * @author            : FSM
 * @last modified on  : 05-27-2025 - FSM
 * @last modified by  : FSM
**/
public class SmartAdvTokenService {
    public ServiceResponse getToken() {
        String token;
        try {
            SmartAdvCalloutGetToken callToken = new SmartAdvCalloutGetToken();
            HttpResponse resToken = callToken.doCallout();
            Map<String,Object> resMapToken = (Map<String,Object>) JSON.deserializeUntyped(resToken.getBody());
            token = (String) resMapToken.get('token');
        }
        catch (Exception e) {
            ServiceResponse sr = new ServiceResponse();
            sr.isSuccess = false;
            sr.errorMessage = 'HTTP Error (Get Token) -- ' + e.getMessage();
            return sr;
        }

        ServiceResponse sr = new ServiceResponse();
        sr.isSuccess = true;
        sr.token = token;
        return sr;
    }

    public class ServiceResponse {
        public Boolean isSuccess;
        public String errorMessage;
        public String token;
    }
}