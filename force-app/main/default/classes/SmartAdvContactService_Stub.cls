/**
 * @description       : 
 * @testing           : 
 * @author            : FSM
 * @last modified on  : 06-23-2025 - FSM
 * @last modified by  : FSM
**/
@isTest
public class SmartAdvContactService_Stub implements System.StubProvider {
    private String mode;

    public SmartAdvContactService_Stub(String mode) {
        this.mode = mode;
    }

    public Object handleMethodCall(
        Object stubbedObject,
        String methodName,
        Type returnType,
        List<Type> listOfParamTypes,
        List<String> listOfParamNames,
        List<Object> args) {

        if (methodName == 'updateAllRecentContactsFromSmartAdvocate') {
            SmartAdvContactService.ServiceResponse res = new SmartAdvContactService.ServiceResponse();
            if (mode == 'success') {
                res.isSuccess = true;
                res.errorMessage = null;
                res.hasAdditionalPages = false;
            }
            else if (mode == 'success additional pages') {
                res.isSuccess = true;
                res.errorMessage = null;
                res.hasAdditionalPages = true;
            }
            else if (mode == 'error') {
                res.isSuccess = false;
                res.errorMessage = 'Simulated Error!';
                res.hasAdditionalPages = false;
            }
            return res;
        }
        else {
            return null;
        }
    }
}