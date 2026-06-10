/**
 * @description       : 
 * @testing           : 
 * @author            : FSM
 * @last modified on  : 05-16-2025 - FSM
 * @last modified by  : FSM
**/
@isTest
private class RingCentral_Auth_Test {
    @isTest
    static void testInitiate() {
        Map<String, String> authProviderConfiguration = buildAuthProviderConfiguration();
        String stateToPropagate = '';
        RingCentral_Auth rc = new RingCentral_Auth();
        String mdt = rc.getCustomMetadataType();

        Test.startTest();
        rc.initiate(authProviderConfiguration, stateToPropagate);
        Test.stopTest();
    }

    @isTest
    static void testRefresh() {
        Test.setMock(HttpCalloutMock.class, new HttpMockAccessTokens());

        Map<String, String> authProviderConfiguration = buildAuthProviderConfiguration();
        RingCentral_Auth rc = new RingCentral_Auth();

        Test.startTest();
        rc.refresh(authProviderConfiguration, 'abc');
        Test.stopTest();
    }

    @isTest
    static void testHandleCallback() {
        Test.setMock(HttpCalloutMock.class, new HttpMockAccessTokens());

        Map<String,String> queryParameters = new Map<String,String>();
        queryParameters.put('code', 'abc');
        queryParameters.put('state', 'def');
        Auth.AuthProviderCallbackState state = new Auth.AuthProviderCallbackState(Null, Null, queryParameters);

        Map<String, String> authProviderConfiguration = buildAuthProviderConfiguration();
        RingCentral_Auth rc = new RingCentral_Auth();

        Test.startTest();
        rc.handleCallback(authProviderConfiguration, state);
        Test.stopTest();
    }

    @isTest
    static void testGetUserInfo() {
        Test.setMock(HttpCalloutMock.class, new HttpMockUserInfo());

        Auth.AuthProviderTokenResponse tokenResponse = new Auth.AuthProviderTokenResponse('QboAuth', 'access_token_123', 'refresh_token_456', 'state');

        Map<String, String> authProviderConfiguration = buildAuthProviderConfiguration();
        RingCentral_Auth rc = new RingCentral_Auth();

        Test.startTest();
        rc.getUserInfo(authProviderConfiguration, tokenResponse);
        Test.stopTest();
    }

    private static Map<String, String> buildAuthProviderConfiguration(){
        Map<String, String> authProviderConfiguration = new Map<String, String>();
        authProviderConfiguration.put('Client_Id__c', 'test');
        authProviderConfiguration.put('Client_Secret__c', 'test');
        authProviderConfiguration.put('Scope__c', 'test');
        authProviderConfiguration.put('Redirect_URI__c', 'test');
        authProviderConfiguration.put('Access_Token_URL__c', 'test');
        authProviderConfiguration.put('User_Info_URL__c', 'test');
        return authProviderConfiguration;
    }

    private class HttpMockAccessTokens implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            res.setBody('{"token_type":"bearer","expires_in":3600,"refresh_token":"abc","x_refresh_token_expires_in":15551893,"access_token":"def"}');
            return res;
        }
    }

    private class HttpMockUserInfo implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            res.setBody('{"id": "abc","login": "login","name": "name"}');
            return res;
        }
    }
}