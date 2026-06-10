/**
 * @description       : 
 * @testing           : 
 * @author            : FSM
 * @last modified on  : 05-27-2025 - FSM
 * @last modified by  : FSM
**/
@isTest
public class SmartAdvTokenService_Stub implements System.StubProvider {
    private String mode;

    public SmartAdvTokenService_Stub(String mode) {
        this.mode = mode;
    }

    public Object handleMethodCall(
        Object stubbedObject,
        String methodName,
        Type returnType,
        List<Type> listOfParamTypes,
        List<String> listOfParamNames,
        List<Object> args) {

        if (methodName == 'getToken') {
            SmartAdvTokenService.ServiceResponse res = new SmartAdvTokenService.ServiceResponse();

            if (String.isBlank(mode) || mode == 'success') {
                res.isSuccess = true;
                res.errorMessage = null;
                res.token = 'abc';
            }
            else if (mode == 'error') {
                res.isSuccess = false;
                res.errorMessage = 'Simulated Error!';
                res.token = null;
            }

            return res;
        }
        else {
            return null;
        }
    }
}