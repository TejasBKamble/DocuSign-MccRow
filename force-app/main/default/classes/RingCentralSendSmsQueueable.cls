/**
 * @description       : 
 * @testing           : 
 * @author            : FSM
 * @last modified on  : 05-29-2025 - FSM
 * @last modified by  : FSM
**/
public class RingCentralSendSmsQueueable implements Queueable, Database.AllowsCallouts {
    private List<RingCentralSmsDto> dtoList;

    public RingCentralSendSmsQueueable(List<RingCentralSmsDto> dtoList) {
        this.dtoList = dtoList;
    }

    public void execute(QueueableContext qc) {
        // Execute the Send SMS service method
        RingCentralSmsDto dto = dtoList[0];
        RingCentralSmsService.ServiceResponse sr = RingCentralSmsService.sendSms(dto);

        // Throw an error if there was an error
        if (String.isNotBlank(sr.errorMessage)) {
            throw new RingCentralSmsException(sr.errorMessage);
        }

        // Remove current DTO from the list
        dtoList.remove(0);

        // Re-enqueue
        if (!dtoList.isEmpty() && !Test.isRunningTest()) {
            System.enqueueJob(this);
        }
    }

    public class RingCentralSmsException extends Exception {}
}