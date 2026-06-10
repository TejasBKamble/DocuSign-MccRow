public class IntakeSessionTriggerHandler {

    public static void handleSignedSessions(Set<Id> sessionIds) {
        System.debug('=== handleSignedSessions ===');
        System.debug('Session IDs: ' + sessionIds);

        // ── Run batch for each signed session ──
        // Batch size 1 ensures one callout per execute
        Database.executeBatch(
            new DocuSignDocumentBatch(sessionIds), 1
        );
    }
}