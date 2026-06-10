/**
 * @description       : Test class for RingCentralEventParsing.cls
 * @testing           : RingCentralEventParsingTest
 * @author            : FSM
 * @last modified on  : 12-22-2025 - FSM
 * @last modified by  : FSM
**/
@isTest
public class RingCentralEventParsingTest {
    
    @isTest
    static void testParseEventCreatesAndRunsQueueable() {
        // Test that events with Message_Type__c = 'RingCentralGetMessageStore' create and run the queueable
        // Create and insert API_Event__c record
        API_Event__c event = new API_Event__c();
        event.HTTP_Method__c = 'GET';
        event.Message_Type__c = 'RingCentralGetMessageStore';
        event.Account_Id__c = '62787479016';
        event.Extension_Id__c = '62787479016';
        event.Retrieval_Type__c = 'hourly';
        insert event;
        
        // Set up mock HTTP callout for the queueable
        Test.setMock(HttpCalloutMock.class, new RingCentralGetMessageStoreMockHttpResponse());
        
        List<API_Event__c> events = new List<API_Event__c>{event};
        
        Test.startTest();
        RingCentralEventParsing.parseEvent(events);
        Test.stopTest();
    }
    
    // Mock HTTP Response class for GetMessageStore callout
    private class RingCentralGetMessageStoreMockHttpResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            // Mock response with paging and records structure expected by RingCentralGetMessageStoreService
            res.setBody('{' +
                '"uri":"https://platform.ringcentral.com/restapi/v1.0/account/62787479016/extension/62787479016/message-store",' +
                '"records":[' +
                    '{' +
                        '"uri":"https://platform.ringcentral.com/restapi/v1.0/account/62787479016/extension/62787479016/message-store/2951501896016",' +
                        '"id":2951501896016,' +
                        '"to":[{"phoneNumber":"+15555555555"}],' +
                        '"from":{"phoneNumber":"+19999999999","name":"Test User"},' +
                        '"type":"SMS",' +
                        '"creationTime":"2025-12-22T19:36:32.000Z",' +
                        '"readStatus":"Read",' +
                        '"priority":"Normal",' +
                        '"attachments":[{"id":2951501896016,"uri":"https://platform.ringcentral.com/restapi/v1.0/account/62787479016/extension/62787479016/message-store/2951501896016/content/2951501896016","type":"Text","contentType":"text/plain"}],' +
                        '"direction":"Outbound",' +
                        '"availability":"Alive",' +
                        '"subject":"Test message",' +
                        '"messageStatus":"Delivered",' +
                        '"smsSendingAttemptsCount":1,' +
                        '"conversationId":8686941724314729272' +
                    '}' +
                '],' +
                '"paging":{' +
                    '"page":1,' +
                    '"perPage":100,' +
                    '"pageStart":0,' +
                    '"pageEnd":0,' +
                    '"totalPages":1,' +
                    '"totalElements":1' +
                '}' +
            '}');
            return res;
        }
    }
}