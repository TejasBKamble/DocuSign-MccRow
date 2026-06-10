/**
 * @description       : 
 * @testing           : 
 * @author            : FSM
 * @last modified on  : 05-26-2025 - FSM
 * @last modified by  : FSM
**/
public class SmartAdvSchCaseSync implements Schedulable {
    public void execute(SchedulableContext ctx) {
        Date yesterday = Date.today().addDays(-1);
        API_Event__c ev = new API_Event__c(
            Integration__c = 'SmartAdvocate',
            Event_Type__c = 'Sync Cases',
            Page_Skip__c = 0,
            Page_Size__c = 200,
            Start_Date__c = Datetime.newInstance(yesterday.year(), yesterday.month(), yesterday.day(), 0, 0, 0),
            End_Date__c = Datetime.now()
        );
        insert ev;
    }
}