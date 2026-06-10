/**
 * @description       : Event Parsing Class called from flow.
 * @testing           : RingCentralEventParsingTest
 * @author            : FSM
 * @last modified on  : 12-09-2025 - FSM
 * @last modified by  : FSM
**/
public without sharing class RingCentralEventParsing 
{
    @InvocableMethod(label='RingCentral - Parse API Event' description='Pass in API Event record for parsing.' category= 'RingCentral')
    public static void parseEvent(List<API_Event__c> events) 
    {
        System.debug('***** RingCentralEventParsing.parseEvent started *****');
        System.debug('events = ' + events);
        System.debug('events size = ' + events.size());

        //List of Events
        List<API_Event__c> eventsList = new List<API_Event__c>();

        for(API_Event__c ev :events)
        {
            if(ev.Status__c == 'Error') { continue; } //Continue if the event is in an error state

            if(ev.HTTP_Method__c == 'WEBHOOK')
            {
                if(ev.Message_Type__c == 'WEBHOOK')
                {
                    eventsList.add(ev);
                }
            }
            else
            {
                if(ev.Message_Type__c != null)
                {
                    eventsList.add(ev);
                }
            }
        }
        
        if(eventsList.size() > 0)
            checkEventAction(eventsList);
    }

    /**
    * @description Incoming and Outgoing Events
    * @author FSM | 12-04-2022 - FSM 
    * @param List<API_Event__c> eventsList
    **/
    private static void checkEventAction(List<API_Event__c> eventsList)
    {
        System.debug('eventsList = ' + eventsList);
        //Create lists to segment event types to allow for bulk processing
        
        //Incoming List
        List<API_Event__c> incomingEvents = new List<API_Event__c>();

        //Outgoing List Rank Status Sync
        List<API_Event__c> outgoingGetMessageStoreEvents = new List<API_Event__c>();

        for (API_Event__c event : eventsList) 
        {
            switch on event.Message_Type__c 
            {
                when 'WEBHOOK' 
                {
                    incomingEvents.add(event);
                }
                when 'RingCentralGetMessageStore'
                {
                    outgoingGetMessageStoreEvents.add(event);
                }
                when else {
                    //Ignore for now
                }
            }
        }

        //Send the lists to their specific classes based on functionality
        //In this example we had one processing class for all incoming webhook actions with their own method
        /*
        if(incomingEvents.size() > 0)
        {
            PensionProWebhookProcessingQueueable queueWebhook = new PensionProWebhookProcessingQueueable( incomingEvents );
            ID jobqueueWebhook = System.enqueueJob( queueWebhook );

            return;
        }
        */

        //In this example outgoing callouts were bulked up and sent to a queueable class for execution
        if(outgoingGetMessageStoreEvents.size() > 0)
        {
            RingCentralGetMessageStoreQueueable queueRingCentralGetMessageStore = new RingCentralGetMessageStoreQueueable(outgoingGetMessageStoreEvents);
            ID jobqueueRingCentralGetMessageStore = System.enqueueJob( queueRingCentralGetMessageStore );

            return;
        }

        return;
    }
}