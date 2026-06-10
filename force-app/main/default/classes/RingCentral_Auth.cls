/**
 * @description       : 
 * @testing           : 
 * @author            : FSM
 * @last modified on  : 01-07-2025 - FSM
 * @last modified by  : FSM
**/
global class RingCentral_Auth extends Auth.AuthProviderPluginClass {
    private String clientId;
    private String clientSecret;
    private String accessTokenUrl;
    private String authorizationUrl;
    private String userInfoUrl;
    private String redirectUri;
    
    // The Custom Metadata that holds the Authentication information
    global String getCustomMetadataType() {
        return 'RingCentral_Config__mdt';
    }
    
    // Build the url that starts the Authentication flow
    global PageReference initiate(Map<String, String> authProviderConfiguration, String stateToPropagate) {
        clientId = authProviderConfiguration.get('Client_ID__c');
        authorizationUrl = authProviderConfiguration.get('Authorization_URL__c');
        redirectUri = authProviderConfiguration.get('Redirect_URI__c');
        String url = authorizationUrl + 
            '?client_id=' + clientId + 
            '&redirect_uri=' + redirectUri + 
            '&response_type=code' +
            '&state=' + stateToPropagate;
        
        return new PageReference(url);
    }

    // Handle the request and response from the Authentication request
    global Auth.AuthProviderTokenResponse handleCallback(Map<String, String> authProviderConfiguration, Auth.AuthProviderCallbackState state) {
        
        clientId = authProviderConfiguration.get('Client_ID__c');
        clientSecret = authProviderConfiguration.get('Client_Secret__c');
        redirectUri = authProviderConfiguration.get('Redirect_URI__c');
        accessTokenUrl = authProviderConfiguration.get('Access_Token_URL__c');
        
        Map<String,String> queryParams = state.queryParameters;
        String code = queryParams.get('code');
        String sfdcState = queryParams.get('state');
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(accessTokenURL);
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        req.setHeader('Accept','application/json');

        String basicAuth = 'Basic ' + EncodingUtil.base64Encode(Blob.valueOf(clientId + ':' + clientSecret));
        req.setHeader('Authorization', basicAuth);

        req.setMethod('POST');
        String body =
            'grant_type=authorization_code' +
            '&code=' + code +
            '&redirect_uri=' + redirectUri;
        req.setBody(body);
        
        Http http = new Http();
        HTTPResponse res = http.send(req);
        String responseBody = res.getBody();
        
        GetTokenResponse response = (GetTokenResponse) JSON.deserialize(responseBody, GetTokenResponse.class);
        
        return new Auth.AuthProviderTokenResponse('RingCentral_Auth', response.access_token, response.refresh_token, sfdcState);
    }
    
    //if access token expired, reuse named credential to retrieve access token
    public override Auth.OAuthRefreshResult refresh(Map<String,String> authProviderConfiguration, String refreshToken) {
        
        clientId = authProviderConfiguration.get('Client_ID__c');
        clientSecret = authProviderConfiguration.get('Client_Secret__c');
        redirectUri = authProviderConfiguration.get('Redirect_URI__c');
        accessTokenUrl = authProviderConfiguration.get('Access_Token_URL__c');
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(accessTokenURL);
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        req.setHeader('Accept','application/json');

        String basicAuth = 'Basic ' + EncodingUtil.base64Encode(Blob.valueOf(clientId + ':' + clientSecret));
        req.setHeader('Authorization', basicAuth);

        req.setMethod('POST');
        String body = 
            'refresh_token=' +  refreshToken +
            '&grant_type=refresh_token';
        req.setBody(body);
        
        Http http = new Http();
        HTTPResponse res = http.send(req);
        String responseBody = res.getBody();
        
        GetTokenResponse response = (GetTokenResponse) JSON.deserialize(responseBody, GetTokenResponse.class);
        
        return new Auth.OAuthRefreshResult(response.access_token, response.refresh_token);
    }
    
    // Return the User Info for the Authenticated User
    global Auth.UserData getUserInfo(Map<String, String> authProviderConfiguration, Auth.AuthProviderTokenResponse response) {
        String userId, fullName, firstName, lastName, locale, loginURL;
        
        userId = '123';
        fullName = 'Fast Slow Motion';
        firstName = 'Fast';
        lastName = 'Slow Motion';
        locale = 'en-us';
        loginURL = 'https://www.ringcentral.com';
        
        return new Auth.UserData(
            userId,
            firstName,
            lastName,
            fullName,
            null,
            null, 
            userId,
            locale,
            'RingCentral',
            loginURL,
            null
        );
    }
    
    public class GetTokenResponse {
        public String refresh_token;
        public String access_token;
    }
    
}