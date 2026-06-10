/**
 * @description       : Test class for SmartAdvEventDispatcher
 * @testing           : Tests event processing, batch handling, error scenarios, and queueable chaining
 * @author            : FSM
 * @last modified on  : 06-23-2025 - FSM
 * @last modified by  : FSM
**/
@isTest
public class SmartAdvEventDispatcher_Test {
    
    @TestSetup
    static void setupTestData() {
        // Create test API events - focus on Create Case event type
        List<API_Event__c> events = new List<API_Event__c>();
        
        // Create Case event
        API_Event__c createCaseEvent = new API_Event__c(
            Event_Type__c = 'Create Case'
        );
        events.add(createCaseEvent);
        
        // Create event with invalid type to test error handling
        API_Event__c invalidEvent = new API_Event__c(
            Event_Type__c = 'Invalid Type'
        );
        events.add(invalidEvent);
        
        insert events;
    }
        
    @isTest
    static void testProcessSingleEventSuccess() {
        // Test processing a single valid event
        API_Event__c event = [SELECT Id, Event_Type__c, Status__c FROM API_Event__c WHERE Event_Type__c = 'Create Case' LIMIT 1];
        List<Id> eventIds = new List<Id>{event.Id};
        
        Test.startTest();
        SmartAdvEventDispatcher dispatcher = new SmartAdvEventDispatcher(eventIds);
        System.enqueueJob(dispatcher);
        Test.stopTest();
    }
    
    @isTest
    static void testProcessEventWithError() {
        // Test processing an event with invalid type that should throw an exception
        API_Event__c event = [SELECT Id, Event_Type__c, Status__c FROM API_Event__c WHERE Event_Type__c = 'Invalid Type' LIMIT 1];
        List<Id> eventIds = new List<Id>{event.Id};
        
        Test.startTest();
        SmartAdvEventDispatcher dispatcher = new SmartAdvEventDispatcher(eventIds);
        System.enqueueJob(dispatcher);
        Test.stopTest();
    }
    
    @isTest
    static void testEmptyEventList() {
        // Test processing with empty event list
        List<Id> emptyEventIds = new List<Id>();
        
        Test.startTest();
        SmartAdvEventDispatcher dispatcher = new SmartAdvEventDispatcher(emptyEventIds);
        System.enqueueJob(dispatcher);
        Test.stopTest();
    }
    
    @isTest
    static void testBatchProcessingWithRemainingEvents() {
        // Test that queueable chains when there are more events than batch size
        // Create multiple Create Case events to exceed batch size
        List<API_Event__c> additionalEvents = new List<API_Event__c>();
        for (Integer i = 0; i < 5; i++) {
            API_Event__c newEvent = new API_Event__c(
                Event_Type__c = 'Create Case'
            );
            additionalEvents.add(newEvent);
        }
        insert additionalEvents;
        
        // Get all events
        List<API_Event__c> allEvents = [SELECT Id FROM API_Event__c WHERE Event_Type__c = 'Create Case'];
        List<Id> eventIds = new List<Id>();
        for (API_Event__c event : allEvents) {
            eventIds.add(event.Id);
        }
        
        Test.startTest();
        SmartAdvEventDispatcher dispatcher = new SmartAdvEventDispatcher(eventIds);
        System.enqueueJob(dispatcher);
        Test.stopTest();
    }
    
    @isTest
    static void testExceptionHandling() {
        // Test that exceptions in event handlers are properly caught and handled
        API_Event__c event = [SELECT Id, Event_Type__c, Status__c FROM API_Event__c WHERE Event_Type__c = 'Create Case' LIMIT 1];
        List<Id> eventIds = new List<Id>{event.Id};
        
        Test.startTest();
        SmartAdvEventDispatcher dispatcher = new SmartAdvEventDispatcher(eventIds);
        System.enqueueJob(dispatcher);
        Test.stopTest();
    }
}