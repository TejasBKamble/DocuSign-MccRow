/**
 * @description       : 
 * @testing           : 
 * @author            : FSM
 * @last modified on  : 04-28-2025 - FSM
 * @last modified by  : FSM
**/
public class RingCentralCalloutSendSms extends RingCentralCallout {
    public RingCentralCalloutSendSms(String fromPhoneNumber, String fromExtensionId, List<String> toPhoneNumbers, String message, String accountId) {
        super();
        httpAction = 'POST';
        url += '/restapi/v' + config.API_Version__c + '/account/' + accountId + '/extension/' + fromExtensionId + '/sms';
        body = buildBody(fromPhoneNumber, toPhoneNumbers, message);

        createRequest();
    }

    private String buildBody(String fromPhoneNumber, List<String> toPhoneNumbers, String message) {
        Map<String,Object> m = new Map<String,Object>();

        Map<String,Object> mFrom = new Map<String,Object>();
        mFrom.put('phoneNumber', '+' + fromPhoneNumber);

        List<Object> lTo = new List<Object>();
        for (String toPhoneNumber : toPhoneNumbers) {
            Map<String,Object> m1 = new Map<String,Object>();
            m1.put('phoneNumber', '+' + toPhoneNumber);
            lTo.add(m1);
        }

        m.put('text', message);
        m.put('to', lTo);
        m.put('from', mFrom);

        String s = JSON.serialize(m);
        return s;
    }
}