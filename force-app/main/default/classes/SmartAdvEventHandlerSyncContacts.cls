/**
 * @description       : 
 * @testing           : 
 * @author            : FSM
 * @last modified on  : 05-27-2025 - FSM
 * @last modified by  : FSM
**/
public class SmartAdvEventHandlerSyncContacts implements ISmartAdvEventHandler {
    private SmartAdvContactService contactService;

    // Default constructor
    public SmartAdvEventHandlerSyncContacts() {
        this(new SmartAdvContactService());
    }

    // Constructor for injecting mock/stub
    public SmartAdvEventHandlerSyncContacts(SmartAdvContactService service) {
        this.contactService = service;
    }

    public ApiEventResponse handle(API_Event__c event) {
        ApiEventResponse res = new ApiEventResponse();

        SmartAdvContactService.ServiceResponse sr = contactService.updateAllRecentContactsFromSmartAdvocate(event.Start_Date__c, event.End_Date__c, (Integer) event.Page_Skip__c, (Integer) event.Page_Size__c);
    
        if (sr.isSuccess && sr.hasAdditionalPages) {
            API_Event__c nextEvent = event.clone(false, true, false, false);
            nextEvent.Status__c = null;
            nextEvent.Response__c = null;
            nextEvent.Error_Message__c = null;
            nextEvent.Page_Skip__c += nextEvent.Page_Size__c;

            if (!Test.isRunningTest()) {
                insert nextEvent;
            }
        }

        res.isSuccess = sr.isSuccess;
        res.errorMessage = sr.errorMessage;
        
        return res;
    }
}