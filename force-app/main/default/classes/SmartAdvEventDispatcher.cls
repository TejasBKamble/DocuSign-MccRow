/**
 * @description       : 
 * @testing           : 
 * @author            : FSM
 * @last modified on  : 06-23-2025 - FSM
 * @last modified by  : FSM
**/
public class SmartAdvEventDispatcher implements Queueable, Database.AllowsCallouts {
    private List<Id> allEventIds;
    private Integer batchSize;

    public SmartAdvEventDispatcher(List<Id> allEventIds) {
        this.allEventIds = allEventIds;
        batchSize = (Integer) SmartAdvocate_Config__mdt.getInstance('SmartAdvocate').Batch_Size__c;
    }

    public void execute(QueueableContext qc) {
        if (allEventIds.isEmpty()) return;

        List<Id> currentEventIds = new List<Id>();   // Current batch of API Events being processed in this Queueable transaction
        Integer i = 0;
        while (!allEventIds.isEmpty() && i < batchSize) {
            currentEventIds.add(allEventIds.remove(0));
            i++;
        }

        List<API_Event__c> events = [SELECT Event_Type__c, Related_Record_ID__c, Start_Date__c, End_Date__c, Page_Size__c, Page_Skip__c FROM API_Event__c WHERE Id IN : currentEventIds];

        for (API_Event__c event : events) {
            try {
                ISmartAdvEventHandler handler = SmartAdvEventHandlerRegistry.getHandler(event.Event_Type__c);
                ApiEventResponse res = handler.handle(event);
                event.Status__c = res.isSuccess ? 'Success' : 'Error';
                event.Error_Message__c = res.errorMessage;
            }
            catch (Exception e) {
                event.Status__c = 'Error';
                event.Error_Message__c = 'Unhandled Exception:\n' + e.getMessage() + '\n\n' + e.getStackTraceString();
            }
        }

        update events;

        if (!Test.isRunningTest() && !allEventIds.isEmpty()) {
            System.enqueueJob(this);
        }
    }
}