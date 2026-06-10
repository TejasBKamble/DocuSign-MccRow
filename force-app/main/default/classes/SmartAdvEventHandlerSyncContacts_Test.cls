/**
 * @description       : 
 * @testing           : 
 * @author            : FSM
 * @last modified on  : 05-27-2025 - FSM
 * @last modified by  : FSM
**/
@isTest
public class SmartAdvEventHandlerSyncContacts_Test {
    @isTest
    static void testSuccess() {
        API_Event__c ev = new API_Event__c(
            Start_Date__c = Datetime.now(),
            End_Date__c = Datetime.now().addDays(-1),
            Page_Skip__c = 0,
            Page_Size__c = 200
        );
        insert ev;

        SmartAdvContactService stub = (SmartAdvContactService) System.Test.createStub(SmartAdvContactService.class, new SmartAdvContactService_Stub('success'));
        SmartAdvEventHandlerSyncContacts handler = new SmartAdvEventHandlerSyncContacts(stub);

        ApiEventResponse res = handler.handle(ev);

        System.assertEquals(true, res.isSuccess);
        System.assertEquals(null, res.errorMessage);
    }

    @isTest
    static void testSuccessAdditionalPages() {
        API_Event__c ev = new API_Event__c(
            Start_Date__c = Datetime.now(),
            End_Date__c = Datetime.now().addDays(-1),
            Page_Skip__c = 0,
            Page_Size__c = 200
        );
        insert ev;

        SmartAdvContactService stub = (SmartAdvContactService) System.Test.createStub(SmartAdvContactService.class, new SmartAdvContactService_Stub('success additional pages'));
        SmartAdvEventHandlerSyncContacts handler = new SmartAdvEventHandlerSyncContacts(stub);

        ApiEventResponse res = handler.handle(ev);

        System.assertEquals(true, res.isSuccess);
        System.assertEquals(null, res.errorMessage);
    }

    @isTest
    static void testError() {
        API_Event__c ev = new API_Event__c(
            Start_Date__c = Datetime.now(),
            End_Date__c = Datetime.now().addDays(-1),
            Page_Skip__c = 0,
            Page_Size__c = 200
        );
        insert ev;

        SmartAdvContactService stub = (SmartAdvContactService) System.Test.createStub(SmartAdvContactService.class, new SmartAdvContactService_Stub('error'));
        SmartAdvEventHandlerSyncContacts handler = new SmartAdvEventHandlerSyncContacts(stub);

        ApiEventResponse res = handler.handle(ev);

        System.assertEquals(false, res.isSuccess);
        System.assertEquals('Simulated Error!', res.errorMessage);
    }
}