/**
 * @description       : Test class for RingCentralGetMessageStoreScheduler.cls
 * @testing           : N/A
 * @author            : FSM
 * @last modified on  : 12-02-2025 - FSM
 * @last modified by  : FSM
**/
@isTest
public without sharing class RingCentralGetMessageStoreSchedTest
{
    @IsTest
    static void testSchedulerMethod()
    {
        Test.startTest();
            RingCentralGetMessageStoreScheduler.SchedulerMethod();
        Test.stopTest();
    }
}