/**
 * @description       : 
 * @testing           : 
 * @author            : FSM
 * @last modified on  : 05-01-2025 - FSM
 * @last modified by  : FSM
**/
public class SmartAdvCalloutGetToken extends SmartAdvCallout {
    public SmartAdvCalloutGetToken() {
        super(null);

        httpAction = 'POST';
        url += '/Users/authenticate';
        body = buildBody(config);
        
        createRequest();

        req.setHeader('Content-Type', 'application/json');
    }

    private String buildBody(SmartAdvocate_Config__mdt config) {
        String body = '{"Username": "' + config.Username__c + '", "Password": "' + config.Password__c + '"}';
        return body;
    }
}