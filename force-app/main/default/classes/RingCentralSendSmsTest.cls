/**
 * @description       : Test class for RingCentralSendSmsInvocable
 * @testing           : Tests successful SMS sending via RingCentral API
 * @author            : FSM
 * @last modified on  : 05-16-2025 - FSM
 * @last modified by  : FSM
**/
@isTest
public class RingCentralSendSmsTest {
    @isTest
    static void testSuccessfulSmsSend() {
        // Create test input
        RingCentralSendSmsInvocable.FlowInputs input = new RingCentralSendSmsInvocable.FlowInputs();
        input.fromPhoneNumber = '19999999999';
        input.fromExtensionId = '62787479016';
        input.toPhoneNumbers = new List<String>{'15555555555'};
        input.message = 'Hello, this is a test message sent via the RingCentral API';
        input.accountId = '62787479016';
        
        // Set up mock callout
        Test.setMock(HttpCalloutMock.class, new RingCentralMockHttpResponse());
        
        // Call the invocable method
        Test.startTest();
        List<RingCentralSendSmsInvocable.FlowOutputs> results = 
            RingCentralSendSmsInvocable.RingCentralSendSms(new List<RingCentralSendSmsInvocable.FlowInputs>{input});
        Test.stopTest();
        
        // Verify results
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(true, results[0].isSuccess, 'Should be successful');
        System.assertEquals(null, results[0].errorMessage, 'Should have no error message');
    }

    @isTest
    static void testInvalidPhoneNumberError() {
        // Create test input
        RingCentralSendSmsInvocable.FlowInputs input = new RingCentralSendSmsInvocable.FlowInputs();
        input.fromPhoneNumber = '19999999999';
        input.fromExtensionId = '62787479016';
        input.toPhoneNumbers = new List<String>{'15555555555'};
        input.message = 'Hello, this is a test message sent via the RingCentral API';
        input.accountId = '62787479016';
        
        // Set up mock callout with error response
        Test.setMock(HttpCalloutMock.class, new RingCentralErrorMockHttpResponse());
        
        // Call the invocable method
        Test.startTest();
        List<RingCentralSendSmsInvocable.FlowOutputs> results = 
            RingCentralSendSmsInvocable.RingCentralSendSms(new List<RingCentralSendSmsInvocable.FlowInputs>{input});
        Test.stopTest();
        
        // Verify results
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(false, results[0].isSuccess, 'Should not be successful');
        System.assert(results[0].errorMessage.contains('Phone number doesn\'t belong to extension'), 
            'Error message should contain the API error message');
    }

    @isTest
    static void testMissingRequiredFields() {
        // Create test input with missing required fields
        RingCentralSendSmsInvocable.FlowInputs input = new RingCentralSendSmsInvocable.FlowInputs();
        
        // Call the invocable method
        Test.startTest();
        List<RingCentralSendSmsInvocable.FlowOutputs> results = 
            RingCentralSendSmsInvocable.RingCentralSendSms(new List<RingCentralSendSmsInvocable.FlowInputs>{input});
        Test.stopTest();
        
        // Verify results
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(false, results[0].isSuccess, 'Should not be successful');
        System.assert(results[0].errorMessage.contains('No "from" phone number provided'), 
            'Error message should indicate missing from phone number');
        System.assert(results[0].errorMessage.contains('No message provided'), 
            'Error message should indicate missing message');
        System.assert(results[0].errorMessage.contains('No "to" phone number provided'), 
            'Error message should indicate missing to phone number');
    }

    @isTest
    static void testErrorTooManyInputs() {
        // Create two test inputs (action is not currently setup for this)
        RingCentralSendSmsInvocable.FlowInputs input1 = new RingCentralSendSmsInvocable.FlowInputs();
        input1.fromPhoneNumber = '19999999999';
        input1.fromExtensionId = '62787479016';
        input1.toPhoneNumbers = new List<String>{'15555555555'};
        input1.message = 'Hello, this is a test message sent via the RingCentral API';
        input1.accountId = '62787479016';

        RingCentralSendSmsInvocable.FlowInputs input2 = new RingCentralSendSmsInvocable.FlowInputs();
        input2.fromPhoneNumber = '19999999999';
        input2.fromExtensionId = '62787479016';
        input2.toPhoneNumbers = new List<String>{'15555555555'};
        input2.message = 'Hello, this is a test message sent via the RingCentral API';
        input2.accountId = '62787479016';
        
        // Set up mock callout
        Test.setMock(HttpCalloutMock.class, new RingCentralMockHttpResponse());
        
        // Call the invocable method
        Test.startTest();
        List<RingCentralSendSmsInvocable.FlowOutputs> results = 
            RingCentralSendSmsInvocable.RingCentralSendSms(new List<RingCentralSendSmsInvocable.FlowInputs>{input1, input2});
        Test.stopTest();
        
        // Verify results
        System.assertEquals(false, results[0].isSuccess, 'Should be error');
        System.assertEquals(false, results[1].isSuccess, 'Should be error');
    }
    
    // Mock HTTP Response class for successful response
    private class RingCentralMockHttpResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            res.setBody('{"uri":"https://platform.ringcentral.com/restapi/v1.0/account/62787479016/extension/62787479016/message-store/2951501896016","id":2951501896016,"to":[{"phoneNumber":"+15555555555"}],"from":{"phoneNumber":"+19999999999","name":"Mister Rogers","location":"Boston, MA"},"type":"SMS","creationTime":"2025-04-25T19:36:32.000Z","readStatus":"Read","priority":"Normal","attachments":[{"id":2951501896016,"uri":"https://platform.ringcentral.com/restapi/v1.0/account/62787479016/extension/62787479016/message-store/2951501896016/content/2951501896016","type":"Text","contentType":"text/plain"}],"direction":"Outbound","availability":"Alive","subject":"Hello, this is a test message sent via the RingCentral API","messageStatus":"Queued","smsSendingAttemptsCount":1,"conversationId":8686941724314729272,"conversation":{"id":"8686941724314729272","uri":"https://platform.ringcentral.com/restapi/v1.0/conversation/8686941724314729272"},"lastModifiedTime":"2025-04-25T19:36:32.767Z"}');
            return res;
        }
    }

    // Mock HTTP Response class for error response
    private class RingCentralErrorMockHttpResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(400);
            res.setBody('{"errorCode":"FeatureNotAvailable","message":"Phone number doesn\'t belong to extension","errors":[{"errorCode":"MSG-304","message":"Phone number doesn\'t belong to extension"}]}');
            return res;
        }
    }
}