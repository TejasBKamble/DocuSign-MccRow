/**
 * @description       : Callout to get the message store from RingCentral
 * @testing           : 
 * @author            : FSM
 * @last modified on  : 12-12-2025 - FSM
 * @last modified by  : FSM
**/
public without sharing class RingCentralCalloutGetMessageStore extends RingCentralCallout {
    public RingCentralCalloutGetMessageStore( API_Event__c event, Integer page )
    {
        super();
        httpAction = 'GET';

        //DateTo is Now in Zulu Time, ex format: 2025-12-12T12:00:00.000Z
        DateTime dateTo = System.now();
        String dateToFormatted = dateTo.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');
        String dateFromFormatted = '';

        if (event.Retrieval_Type__c == 'hourly')
        {
            //DateFrom is 1 hour ago in Zulu Time, ex format: 2025-12-12T11:00:00.000Z
            DateTime dateFrom = dateTo.addHours(-2);
            dateFromFormatted = dateFrom.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');

            //Example URL: https://platform.ringcentral.com/restapi/v1.0/account/62787479016/extension/62787479016/message-store?page=1&perPage=100
            url += '/restapi/v' + config.API_Version__c + '/account/' + event.Account_Id__c + '/extension/' + event.Extension_Id__c + '/message-store' + '?dateFrom=' + dateFromFormatted + '&dateTo=' + dateToFormatted + '&page=' + page + '&perPage=100';
        }
         //DateFrom is omitted from the URL if retrieval type is all
        if (event.Retrieval_Type__c == 'all')
        {
            //Example URL: https://platform.ringcentral.com/restapi/v1.0/account/62787479016/extension/62787479016/message-store?page=1&perPage=100
            url += '/restapi/v' + config.API_Version__c + '/account/' + event.Account_Id__c + '/extension/' + event.Extension_Id__c + '/message-store' + '?dateTo=' + dateToFormatted + '&page=' + page + '&perPage=100';
        }
        
        
        System.debug('URL: ' + url);
        createRequest();
    }
}