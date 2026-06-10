/**
 * @description       : 
 * @testing           : 
 * @author            : FSM
 * @last modified on  : 05-01-2025 - FSM
 * @last modified by  : FSM
**/
public virtual class SmartAdvCallout {
    protected SmartAdvocate_Config__mdt config;
    protected Http m_http;
    protected HttpRequest req;

    protected String body;
    protected Blob bodyBlob;
    protected String httpAction;
    protected String url;
    protected Map<String,String> headers;
    protected String token;

    public SmartAdvCallout(String token) {
        this.config = SmartAdvocate_Config__mdt.getInstance('SmartAdvocate');
        this.token = token;

        m_http = new Http();
        url = config.Root_Endpoint__c;
        headers = new Map<String,String>();
    }

    protected void createRequest() {
        req = new HttpRequest();

        for (String key : headers.keyset()) {
            req.setHeader(key, headers.get(key));
        }

        if(httpAction == 'POST' || httpAction == 'PATCH' || httpAction == 'PUT')
        {   
            if (bodyBlob != null) {
                req.setBodyAsBlob(bodyBlob);
            }
            else {
                req.setBody(body);
            }
        }

        req.setEndpoint(url);
        req.setMethod(httpAction);

        if (String.isNotBlank(token)) {
            req.setHeader('Authorization', 'Bearer ' + token);
        }

        req.setTimeout(120000);     // Set callout time limit to 120 seconds
    }

    public HttpResponse doCallout() {
        System.debug(req.getBody());
        HttpResponse res = m_http.send(req);

        if (res.getStatusCode() >= 200 && res.getStatusCode() < 300) {
            System.debug('Callout successful');
            System.debug(res.getBody());
        } 
        else {
            throw new HttpException('Status code: ' + res.getStatusCode() + '. Response: ' + res.getBody());
        }

        return res;
    }

    public class HttpException extends Exception {}
}