/**
 * @description       : 
 * @testing           : 
 * @author            : FSM
 * @last modified on  : 05-23-2025 - FSM
 * @last modified by  : FSM
**/
public class SmartAdvEventHandlerRegistry {
    private static Map<String, ISmartAdvEventHandler> handlers;

    static {
        handlers = new Map<String, ISmartAdvEventHandler>{
            'Create Case' => new SmartAdvEventHandlerCreateCase(),
            'Sync Cases' => new SmartAdvEventHandlerSyncCases(),
            //'Create Contact' => new SmartAdvEventHandlerCreateContact(),
            'Sync Contacts' => new SmartAdvEventHandlerSyncContacts(),
            'Create Document' => new SmartAdvEventHandlerCreateDocument()
        };
    }

    public static ISmartAdvEventHandler getHandler(String type) {
        if (!handlers.containsKey(type)) {
            throw new IllegalArgumentException('No handler for type: ' + type);
        }
        return handlers.get(type);
    }
}