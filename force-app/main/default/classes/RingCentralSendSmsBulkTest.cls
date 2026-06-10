/**
 * @description       : 
 * @testing           : 
 * @author            : FSM
 * @last modified on  : 07-30-2025 - FSM
 * @last modified by  : FSM
**/
@isTest
public class RingCentralSendSmsBulkTest {
    @isTest
    static void doTestSuccess() {
        List<RingCentralSendSmsBulkInvocable.FlowInputs> inputs = new List<RingCentralSendSmsBulkInvocable.FlowInputs>();
        RingCentralSendSmsBulkInvocable.FlowInputs input = new RingCentralSendSmsBulkInvocable.FlowInputs();
        input.accountId = 'abc';
        input.fromExtensionId = '123';
        input.fromPhoneNumber = '15556667777';
        input.message = 'test message';
        input.toPhoneNumbers = new List<String> {'12223334444'};
        inputs.add(input);

        Test.setMock(HttpCalloutMock.class, new RingCentralMockHttpResponse());

        Test.startTest();
        List<RingCentralSendSmsBulkInvocable.FlowOutputs> outputs = RingCentralSendSmsBulkInvocable.RingCentralSendSmsBulk(inputs);
        Test.stopTest();
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
}