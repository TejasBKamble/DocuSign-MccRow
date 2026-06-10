/**
 * @description       : 
 * @testing           : 
 * @author            : FSM
 * @last modified on  : 05-27-2025 - FSM
 * @last modified by  : FSM
**/
@isTest
public class SmartAdvEventHandlerCreateCase_Test {
    @isTest
    static void testSuccess() {
        Incident_Detail__c ind = [SELECT Id FROM Incident_Detail__c LIMIT 1];
        API_Event__c ev = new API_Event__c(
            Related_Record_ID__c = ind.Id
        );
        insert ev;

        SmartAdvCaseService stub = (SmartAdvCaseService) System.Test.createStub(SmartAdvCaseService.class, new SmartAdvCaseService_Stub('success'));
        SmartAdvEventHandlerCreateCase handler = new SmartAdvEventHandlerCreateCase(stub);

        ApiEventResponse res = handler.handle(ev);

        System.assertEquals(true, res.isSuccess);
        System.assertEquals(null, res.errorMessage);
    }

    @isTest
    static void testError() {
        Incident_Detail__c ind = [SELECT Id FROM Incident_Detail__c LIMIT 1];
        API_Event__c ev = new API_Event__c(
            Related_Record_ID__c = ind.Id
        );
        insert ev;

        SmartAdvCaseService stub = (SmartAdvCaseService) System.Test.createStub(SmartAdvCaseService.class, new SmartAdvCaseService_Stub('error'));
        SmartAdvEventHandlerCreateCase handler = new SmartAdvEventHandlerCreateCase(stub);

        ApiEventResponse res = handler.handle(ev);

        System.assertEquals(false, res.isSuccess);
        System.assertEquals('Simulated Error!', res.errorMessage);
    }

    @TestSetup
    static void makeData(){
        Account acct = SmartAdvTestFactory.createAccount();
        Contact con = SmartAdvTestFactory.createContact(acct.Id, null);
        Incident_Detail__c ind = SmartAdvTestFactory.createIncidentDetail(con.Id, null);
    }
}