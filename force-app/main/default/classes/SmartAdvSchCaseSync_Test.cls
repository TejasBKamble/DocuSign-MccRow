/**
 * @description       : 
 * @testing           : 
 * @author            : FSM
 * @last modified on  : 06-23-2025 - FSM
 * @last modified by  : FSM
**/
@isTest
public class SmartAdvSchCaseSync_Test {
    @isTest
    static void doTest() {
        String CRON_EXP = '0 0 0 3 9 ? 2100';

        Test.startTest();
        String jobId = System.schedule('ScheduledApexTest', CRON_EXP, new SmartAdvSchCaseSync());
        Test.stopTest();
    }
}