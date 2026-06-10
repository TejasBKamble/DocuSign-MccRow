/**
 * @description       : Gather list of messages in the message store from RingCentral
 * @testing           : RingCentralEventParsingTest
 * @author            : FSM
 * @last modified on  : 12-30-2025 - FSM
 * @last modified by  : FSM
**/
public without sharing class RingCentralGetMessageStoreQueueable implements Queueable, Database.AllowsCallouts
{
    public List<API_Event__c> eventList;

    public RingCentralGetMessageStoreQueueable(List<API_Event__c> dataList)
    {
        System.debug('***** RingCentralGetMessageStoreQueueable.RingCentralGetMessageStoreQueueable started *****');
        System.debug('Data List Size: ' + dataList.size());
        //System.debug('Data List: ' + JSON.serializePretty( dataList ));

        this.eventList = dataList;
    }

    public void execute(QueueableContext qc)
    {
        System.debug('***** RingCentralGetMessageStoreQueueable.execute started *****');

        List<RingCentral_Message__c> messagesToInsert = new List<RingCentral_Message__c>();
        Map<String,API_Event__c> eventMap = new Map<String,API_Event__c>();

        for (API_Event__c event : this.eventList)
        {
            RingCentralGetMessageStoreService.ServiceResponse sr = new RingCentralGetMessageStoreService.ServiceResponse();
            
            try 
            {
                sr = RingCentralGetMessageStoreService.getMessageStore( event );
                event.Response__c = sr.responseBody;
                event.Status__c = 'Success';
                if (!sr.isSuccess)
                {
                    throw new RingCentralGetMessageStoreException(sr.errorMessage);
                }
            } 
            catch (Exception e)
            {
                System.debug('Error: ' + e.getMessage());
                event.Status__c = 'Error';
                event.Error_Message__c = e.getMessage();
            }

            eventMap.put(event.Id, event);
            messagesToInsert.addAll(sr.messages);
        }

        if (!messagesToInsert.isEmpty())
        {
            //Upsert the messages by the RingCentral_Message_Id__c field
            Schema.SObjectField ringCentralMessageIdField = RingCentral_Message__c.Fields.RingCentral_Message_Id__c;
            List<Database.UpsertResult> upsertResults = Database.upsert(messagesToInsert, ringCentralMessageIdField, false);
            for (Integer i = 0; i < upsertResults.size(); i++)
            {
                if (upsertResults[i].isSuccess())
                {
                    //Do nothing
                    continue;
                }
                else
                {
                    //Add the error message to the API Event
                    RingCentral_Message__c message = messagesToInsert[i];
                    API_Event__c event = eventMap.get(message.API_Event_ID__c);
                    event.Error_Message__c += upsertResults[i].getErrors()[0].getMessage() + '\n';
                    event.Status__c = 'Error';
                }
            }
        }

        update eventMap.values();

        finalProcess();
    }

    public void finalProcess()
    {}

    /*
    public Boolean checkHeapSize()
    {
        Boolean result;
        result = Limits.getHeapSize() > 0.9*Limits.getLimitHeapSize() ? true : false;
        //System.debug('HeapSize = ' + Limits.getHeapSize());
        return result;
    }

    public Boolean checkCPUlimit()
    {
        Boolean result;
        result = Limits.getCpuTime() > 0.9*Limits.getLimitCpuTime() ? true : false;
        //System.debug('getCpuTime = ' + Limits.getCpuTime());
        return result;
    }

    public Boolean checkCalloutLimit()
    {
        Boolean result;
        result = Limits.getCallouts() >= 100 ? true : false;
        //System.debug('getCallouts = ' + Limits.getCallouts());
        return result;
    }
    */

    public class RingCentralGetMessageStoreException extends Exception {}
}