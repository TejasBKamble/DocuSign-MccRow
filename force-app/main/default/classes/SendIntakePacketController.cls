public with sharing class SendIntakePacketController {

    @AuraEnabled
    public static String sendIntakePacket(
        Id     recordId,
        String incidentType,
        String signerType,
        String signerName,
        String signerEmail,
        String signerPhone,
        String sendChannel
    ) {
        try {
            Intake_Session__c session = IntakeSessionService.createSession(
                recordId,
                incidentType,
                signerType,
                signerName,
                signerEmail,
                signerPhone,
                sendChannel
            );
            // Return the session ID back to LWC
            return session.Id;

        } catch (Exception e) {
            throw new AuraHandledException(
                'Failed to send intake packet: ' + e.getMessage()
            );
        }
    }
}