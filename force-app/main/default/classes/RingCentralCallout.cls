/**
 * @description       : 
 * @testing           : 
 * @author            : FSM
 * @last modified on  : 12-29-2025 - FSM
 * @last modified by  : FSM
**/
public virtual class RingCentralCallout {
    protected RingCentral_Config__mdt config;
    protected Http m_http;
    protected HttpRequest req;

    protected String body;
    protected String httpAction;
    protected String url;
    protected Map<String,String> headers;

    public RingCentralCallout() {
        this.config = RingCentral_Config__mdt.getInstance('ringcentral');

        m_http = new Http();
        url = config.Root_Endpoint__c;
        headers = new Map<String,String>();
    }

    protected void createRequest() {
        req = new HttpRequest();
        req.setHeader('Content-Type','application/json'); 
        req.setHeader('Accept','application/json');

        for (String key : headers.keyset()) {
            req.setHeader(key, headers.get(key));
        }

        if(httpAction == 'POST' || httpAction == 'PATCH' || httpAction == 'PUT') {
        	req.setBody(body);
        }

        req.setEndpoint(url);
        req.setMethod(httpAction);

        req.setTimeout(60000);
    }

    public HttpResponse doCallout() {
        System.debug(req.getBody());
        HttpResponse res = m_http.send(req);

        if (res.getStatusCode() >= 200 && res.getStatusCode() < 300) {
            System.debug('Callout successful');
            System.debug('Status Code: ' + res.getStatusCode());
            System.debug('Response Body: ' + res.getBody());
        } 
        else {
            System.debug('Callout failed');
            System.debug('Status Code: ' + res.getStatusCode());
            System.debug('Response Body: ' + res.getBody());
        }

        return res;
    }

    public class RingCentralCalloutException extends Exception {}
}