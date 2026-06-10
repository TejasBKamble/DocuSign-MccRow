public class DocuSignAuthService {

    // ─────────────────────────────────────────
    // LOAD CONFIG FROM CUSTOM METADATA
    // ─────────────────────────────────────────
    private static DocuSign_Config__mdt getConfig() {
        return [
            SELECT Integration_Key__c, Account_ID__c,
                   User_ID__c, Base_URI__c, Auth_URI__c,
                   Template_ID__c, RSA_Private_Key__c
            FROM   DocuSign_Config__mdt
            LIMIT  1
        ];
    }


    // ─────────────────────────────────────────
    // GET ACCESS TOKEN USING JWT GRANT
    // ─────────────────────────────────────────
    public static String getAccessToken() {

        DocuSign_Config__mdt cfg = getConfig();

        // 1. Build JWT Header
        String header = JSON.serialize(new Map<String, String>{
            'alg' => 'RS256',
            'typ' => 'JWT'
        });

        // 2. Build JWT Payload
        Long issuedAt  = DateTime.now().getTime() / 1000;
        Long expiresAt = issuedAt + 3600;

        String payload = JSON.serialize(new Map<String, Object>{
            'iss'   => cfg.Integration_Key__c,
            'sub'   => cfg.User_ID__c,
            'aud'   => 'account-d.docusign.com',
            'iat'   => issuedAt,
            'exp'   => expiresAt,
            'scope' => 'signature impersonation'
        });

        // 3. Base64URL encode header and payload
        String encodedHeader  = base64UrlEncode(Blob.valueOf(header));
        String encodedPayload = base64UrlEncode(Blob.valueOf(payload));
        String signingInput   = encodedHeader + '.' + encodedPayload;

        // 4. Clean and sign with RSA Private Key
        String privateKeyStr = cfg.RSA_Private_Key__c
            .replace('-----BEGIN RSA PRIVATE KEY-----', '')
            .replace('-----END RSA PRIVATE KEY-----', '')
            .replaceAll('\\s+', '');

        Blob privateKeyBlob = EncodingUtil.base64Decode(privateKeyStr);
        Blob signatureBlob  = Crypto.sign('RSA-SHA256', Blob.valueOf(signingInput), privateKeyBlob);
        String signature    = base64UrlEncode(signatureBlob);

        // 5. Build final JWT
        String jwt = signingInput + '.' + signature;

        System.debug('JWT Generated: ' + jwt);

        // 6. Exchange JWT for Access Token
        String tokenEndpoint = cfg.Auth_URI__c + '/oauth/token';

        HttpRequest req = new HttpRequest();
        req.setEndpoint(tokenEndpoint);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        req.setBody(
            'grant_type=' + EncodingUtil.urlEncode(
                'urn:ietf:params:oauth:grant-type:jwt-bearer', 'UTF-8') +
            '&assertion=' + EncodingUtil.urlEncode(jwt, 'UTF-8')
        );

        Http http        = new Http();
        HttpResponse res = http.send(req);

        System.debug('Auth Status Code : ' + res.getStatusCode());
        System.debug('Auth Response    : ' + res.getBody());

        if (res.getStatusCode() == 200) {
            Map<String, Object> tokenResponse =
                (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            return (String) tokenResponse.get('access_token');
        } else {
            throw new DocuSignException(
                'Auth Failed [' + res.getStatusCode() + ']: ' + res.getBody()
            );
        }
    }


    // ─────────────────────────────────────────
    // BASE64 URL ENCODE HELPER
    // ─────────────────────────────────────────
    public static String base64UrlEncode(Blob input) {
        return EncodingUtil.base64Encode(input)
            .replace('+', '-')
            .replace('/', '_')
            .replace('=', '');
    }


    // ─────────────────────────────────────────
    // EXPOSE CONFIG FOR OTHER CLASSES
    // ─────────────────────────────────────────
    public static DocuSign_Config__mdt loadConfig() {
        return getConfig();
    }


    public class DocuSignException extends Exception {}
}