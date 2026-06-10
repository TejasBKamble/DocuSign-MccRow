/**
 * @description       : Scheduler to get list of messages in the message store from RingCentral
 * @testing           : RingCentralGetMessageStoreSchedTest
 * @author            : FSM
 * @last modified on  : 12-22-2025 - FSM
 * @last modified by  : FSM
**/
public without sharing class RingCentralGetMessageStoreScheduler implements Schedulable
{
    public void execute(SchedulableContext sc)
    {
        System.debug( '***** RingCentralGetMessageStoreScheduler.execute() started *****' );

        makeAPIEventGetMessageStore('hourly');
       
    }

    /*
    @InvocableMethod(label='RingCentral - Make API Event Get Message Store' category='RingCentral')
    public static void invokeMakeAPIEventGetMessageStore() 
    {
        makeAPIEventGetMessageStore('hourly');
    }
    */

    public static void makeAPIEventGetMessageStore( String retrievalType)
    {
        //Get the Picklist values for Account/Extension in Custom Metadata
        List<String> picklistValues = getPicklistValuesFromCustomMetadata();
        System.debug('Picklist Values: ' + picklistValues);

        //If no Picklist Values found, return
        if (picklistValues.size() == 0) {
            System.debug('No Picklist Values found');
            return;
        }

        //Create a new API Event for each Picklist Value
        List<API_Event__c> newEvents = new List<API_Event__c>();
        for (String picklistValue : picklistValues) 
        {
            System.debug('Single Picklist Value: ' + picklistValue);
            //Split the picklist value into AccountId and ExtensionId
            String[] splitValues = picklistValue.split('/');
            String accountId = splitValues[0] != null ? splitValues[0] : '~';
            String extensionId = splitValues[1] != null ? splitValues[1] : '~';

            API_Event__c newEvent = new API_Event__c();
            
            newEvent.Integration__c = 'RingCentral';
            newEvent.HTTP_Method__c = 'GET';
            newEvent.Message_Type__c = 'RingCentralGetMessageStore';
            newEvent.Retrieval_Type__c = retrievalType;

            //We can add values later if needed
            //AccountId
            newEvent.Account_Id__c = accountId;
            //ExtensionId
            newEvent.Extension_Id__c = extensionId;

            newEvents.add(newEvent);
        }
        insert newEvents;

        return;
    }

    public static List<String> getPicklistValuesFromCustomMetadata()
    {
        List<String> picklistValues = new List<String>();
        Schema.DescribeFieldResult fieldResult = RingCentral_Config__mdt.Account_and_Extension__c.getDescribe();
        List<Schema.PicklistEntry> picklistEntries = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry entry : picklistEntries) {
            picklistValues.add(entry.getValue());
        }
        return picklistValues;
    }

    public static void SchedulerMethod() {
        String testString = '';
        if (Test.isRunningTest()) { testString = 'Test '; }

        System.schedule(testString+ 'Get RingCentral Message Store',  '0 15 * * * ?', new RingCentralGetMessageStoreScheduler());
        return;
    }
}