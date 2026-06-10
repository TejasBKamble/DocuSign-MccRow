/**
 * @description       : 
 * @testing           : 
 * @author            : FSM
 * @last modified on  : 05-27-2025 - FSM
 * @last modified by  : FSM
**/
@isTest
public class SmartAdvCaseService_Stub implements System.StubProvider {
    private String mode;

    public SmartAdvCaseService_Stub(String mode) {
        this.mode = mode;
    }

    public Object handleMethodCall(
        Object stubbedObject,
        String methodName,
        Type returnType,
        List<Type> listOfParamTypes,
        List<String> listOfParamNames,
        List<Object> args) {

        if (methodName == 'createSmartAdvocateCase') {
            List<SmartAdvCaseService.ServiceResponse> resList = new List<SmartAdvCaseService.ServiceResponse>();
            List<SmartAdvCaseDto> cList = (List<SmartAdvCaseDto>) args[0];

            for (SmartAdvCaseDto c : cList) {
                SmartAdvCaseService.ServiceResponse res = new SmartAdvCaseService.ServiceResponse();
                if (String.isBlank(mode) || mode == 'success') {
                    res.isSuccess = true;
                    res.errorMessage = null;
                }
                else if (mode == 'error') {
                    res.isSuccess = false;
                    res.errorMessage = 'Simulated Error!';
                }
                resList.add(res);
            }
            return resList;
        }
        else if (methodName == 'updateAllRecentCaseStatusFromSmartAdvocate') {
            SmartAdvCaseService.ServiceResponse res = new SmartAdvCaseService.ServiceResponse();
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