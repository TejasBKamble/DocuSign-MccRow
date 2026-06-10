/**
 * @description       : 
 * @testing           : 
 * @author            : FSM
 * @last modified on  : 05-29-2025 - FSM
 * @last modified by  : FSM
**/
public class RingCentralSendSmsInvocable {
    @InvocableMethod(label='RingCentral - Send SMS' category='RingCentral')
    public static List<FlowOutputs> RingCentralSendSms(List<FlowInputs> inputs) {
        List<FlowOutputs> outputs = new List<FlowOutputs>();

        if (inputs.size() == 1) {
            FlowInputs input = inputs[0];
            RingCentralSmsDto dto = new RingCentralSmsDto();
            dto.fromPhoneNumber = input.fromPhoneNumber;
            dto.fromExtensionId = input.fromExtensionId;
            dto.toPhoneNumbers = input.toPhoneNumbers;
            dto.message = input.message;
            dto.accountId = input.accountId;

            RingCentralSmsService.ServiceResponse sr = RingCentralSmsService.sendSms(dto);
            FlowOutputs output = new FlowOutputs();
            output.isSuccess = sr.isSuccess;
            output.errorMessage = sr.errorMessage;
            outputs.add(output);
        }
        else {
            for (FlowInputs input : inputs) {
                FlowOutputs output = new FlowOutputs();
                output.isSuccess = false;
                output.errorMessage = 'Input size: ' + inputs.size() + '. For bulk SMS, use action \"RingCentral - Send SMS Bulk.\"';
                outputs.add(output);
            }
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
        public Boolean isSuccess;

        @InvocableVariable
        public String errorMessage;
    }
}