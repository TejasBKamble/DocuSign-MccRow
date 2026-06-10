/**
 * @description       : 
 * @testing           : 
 * @author            : FSM
 * @last modified on  : 05-29-2025 - FSM
 * @last modified by  : FSM
**/
public class RingCentralSendSmsBulkInvocable {
    @InvocableMethod(label='RingCentral - Send SMS Bulk' category='RingCentral')
    public static List<FlowOutputs> RingCentralSendSmsBulk(List<FlowInputs> inputs) {
        List<FlowOutputs> outputs = new List<FlowOutputs>();

        List<RingCentralSmsDto> dtoList = new List<RingCentralSmsDto>();
        for (FlowInputs input : inputs) {
            RingCentralSmsDto dto = new RingCentralSmsDto();
            dto.fromPhoneNumber = input.fromPhoneNumber;
            dto.fromExtensionId = input.fromExtensionId;
            dto.toPhoneNumbers = input.toPhoneNumbers;
            dto.message = input.message;
            dto.accountId = input.accountId;
            dtoList.add(dto);
        }

        // Enqueue, get job ID
        RingCentralSendSmsQueueable queueable = new RingCentralSendSmsQueueable(dtoList);
        String jobId = System.enqueueJob(queueable);

        for (FlowInputs input : inputs) {
            FlowOutputs output = new FlowOutputs();
            output.jobId = jobId;
            outputs.add(output);
        }

        return outputs;
    }

    public class FlowInputs {
        @InvocableVariable (required=true label='From Phone Number')
        public String fromPhoneNumber;

        @InvocableVariable (required=false label='From Extension ID')
        public String fromExtensionId;

        @InvocableVariable (required=true label='To Phone Numbers')
        public List<String> toPhoneNumbers;

        @InvocableVariable (required=true label='Message')
        public String message;

        @InvocableVariable (required=false label='Account ID')
        public String accountId;
    }

    public class FlowOutputs {
        @InvocableVariable
        public String jobId;
    }
}