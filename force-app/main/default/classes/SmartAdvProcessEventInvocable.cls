/**
 * @description       : 
 * @testing           : SmartAdvProcessEventInvocable_Test
 * @author            : FSM
 * @last modified on  : 01-05-2026 - FSM
 * @last modified by  : FSM
**/
public class SmartAdvProcessEventInvocable {
    @InvocableMethod(label='SmartAdvocate - Process API Event' category='SmartAdvocate')
    public static void invocableMethod(List<Id> apiEventId) {
        //Commented out to allow for moving API Event Assets to Production
        //SmartAdvEventDispatcher queueable = new SmartAdvEventDispatcher(apiEventId);
        //System.enqueueJob(queueable);
    }
}