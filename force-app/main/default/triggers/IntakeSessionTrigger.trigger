trigger IntakeSessionTrigger on Intake_Session__c (after update) {
/*
    Set<Id> signedSessionIds = new Set<Id>();

    for (Intake_Session__c newSession : Trigger.new) {
        Intake_Session__c oldSession = Trigger.oldMap.get(newSession.Id);

        // ── Fire only when Status changes TO Signed ──
        if (newSession.Status__c == 'Signed'
            && oldSession.Status__c != 'Signed'
            && newSession.DocuSign_Envelope_Id__c != null
            && newSession.Lead__c != null
            && newSession.Document_Attached__c != true) {

            signedSessionIds.add(newSession.Id);
        }
    }

    if (!signedSessionIds.isEmpty()) {
        System.debug('Signed sessions found: ' + signedSessionIds.size());
        IntakeSessionTriggerHandler.handleSignedSessions(signedSessionIds);
    }*/
}