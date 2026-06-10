/**
 * @description       : 
 * @testing           : 
 * @author            : FSM
 * @last modified on  : 05-12-2025 - FSM
 * @last modified by  : FSM
**/
public class SmartAdvCalloutCreateCase extends SmartAdvCallout {
    public SmartAdvCalloutCreateCase(String token, SmartAdvCaseDto c) {
        super(token);

        httpAction = 'POST';
        url += '/case/CreateCase';
        body = buildBody(c);

        createRequest();

        req.setHeader('Content-Type', 'application/json');
    }

    String buildBody(SmartAdvCaseDto c) {
        Map<String,Object> bodyMap = new Map<String,Object>();
        bodyMap.put('firstName', c.firstName);
        bodyMap.put('lastName', c.lastName);
        bodyMap.put('phone', c.phone);
        bodyMap.put('email', c.email);
        bodyMap.put('summary', c.summary);
        bodyMap.put('searchEngineName', c.searchEngineName);
        bodyMap.put('address', c.address);
        bodyMap.put('city', c.city);
        bodyMap.put('state', c.state);
        bodyMap.put('zip', c.zip);
        bodyMap.put('referringURL', c.referringURL);
        bodyMap.put('keywords', c.keywords);
        bodyMap.put('intakeDate', c.intakeDate);
        bodyMap.put('dob', c.dob);
        bodyMap.put('gender', c.gender);
        bodyMap.put('ssn', c.ssn);
        bodyMap.put('caseType', c.caseType);   // Must be the exact actual text, not the index/number of the case type
        bodyMap.put('office', c.office);     // Must be the exact actual text, not the index/number of the office
        bodyMap.put('ssnEncoded', c.ssnEncoded);

        String body = JSON.serializePretty(bodyMap);
        return body;
    }
}