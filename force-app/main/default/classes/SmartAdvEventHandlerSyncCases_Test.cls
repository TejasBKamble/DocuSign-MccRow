/**
 * @description       : 
 * @testing           : 
 * @author            : FSM
 * @last modified on  : 05-27-2025 - FSM
 * @last modified by  : FSM
**/
@isTest
public class SmartAdvEventHandlerSyncCases_Test {
    @isTest
    static void testSuccess() {
        API_Event__c ev = new API_Event__c(
            Start_Date__c = Datetime.now(),
            End_Date__c = Datetime.now().addDays(-1),
            Page_Skip__c = 0,
            Page_Size__c = 200
        );
        insert ev;

        SmartAdvCaseService stub = (SmartAdvCaseService) System.Test.createStub(SmartAdvCaseService.class, new SmartAdvCaseService_Stub('success'));
        SmartAdvEventHandlerSyncCases handler = new SmartAdvEventHandlerSyncCases(stub);

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

        SmartAdvCaseService stub = (SmartAdvCaseService) System.Test.createStub(SmartAdvCaseService.class, new SmartAdvCaseService_Stub('success additional pages'));
        SmartAdvEventHandlerSyncCases handler = new SmartAdvEventHandlerSyncCases(stub);

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

        SmartAdvCaseService stub = (SmartAdvCaseService) System.Test.createStub(SmartAdvCaseService.class, new SmartAdvCaseService_Stub('error'));
        SmartAdvEventHandlerSyncCases handler = new SmartAdvEventHandlerSyncCases(stub);

        ApiEventResponse res = handler.handle(ev);

        System.assertEquals(false, res.isSuccess);
        System.assertEquals('Simulated Error!', res.errorMessage);
    }
}