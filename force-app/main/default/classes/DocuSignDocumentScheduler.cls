public class DocuSignDocumentScheduler implements Schedulable {
    public void execute(SchedulableContext sc) {
        System.debug('=== DocuSignDocumentScheduler FIRED ===');
        Database.executeBatch(new DocuSignDocumentBatch(), 1);
    }
}