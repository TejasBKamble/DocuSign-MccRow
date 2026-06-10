/**
 * @description       : 
 * @testing           : 
 * @author            : FSM
 * @last modified on  : 06-23-2025 - FSM
 * @last modified by  : FSM
**/
@isTest
public class SmartAdvEventHandlerRegistry_Test {
    @isTest
    static void doTest() {
        ISmartAdvEventHandler createCaseHandler = SmartAdvEventHandlerRegistry.getHandler('Create Case');
        ISmartAdvEventHandler syncCasesHandler = SmartAdvEventHandlerRegistry.getHandler('Sync Cases');
        ISmartAdvEventHandler syncContactsHandler = SmartAdvEventHandlerRegistry.getHandler('Sync Contacts');
        ISmartAdvEventHandler createDocumentHandler = SmartAdvEventHandlerRegistry.getHandler('Create Document');

        try {
            ISmartAdvEventHandler badHandler = SmartAdvEventHandlerRegistry.getHandler('TEST');
        }
        catch (IllegalArgumentException e) {
            System.assertEquals('No handler for type: TEST', e.getMessage());
        }
    }
}