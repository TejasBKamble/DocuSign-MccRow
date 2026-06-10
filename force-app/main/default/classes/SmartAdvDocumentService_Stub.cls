/**
 * @description       : 
 * @testing           : 
 * @author            : FSM
 * @last modified on  : 05-30-2025 - FSM
 * @last modified by  : FSM
**/
@isTest
public class SmartAdvDocumentService_Stub implements System.StubProvider {
    private String mode;

    public SmartAdvDocumentService_Stub(String mode) {
        this.mode = mode;
    }

    public Object handleMethodCall(
        Object stubbedObject,
        String methodName,
        Type returnType,
        List<Type> listOfParamTypes,
        List<String> listOfParamNames,
        List<Object> args) {

        if (methodName == 'insertDocParams') {
            List<SmartAdvDocumentService.ServiceResponse> resList = new List<SmartAdvDocumentService.ServiceResponse>();
            List<SmartAdvDocumentDto> dList = (List<SmartAdvDocumentDto>) args[0];

            for (Integer i=0; i < dList.size(); i++) {
                SmartAdvDocumentService.ServiceResponse res = new SmartAdvDocumentService.ServiceResponse();
                if (String.isBlank(mode) || mode == 'success' || mode == 'error uploadDocument') {
                    res.isSuccess = true;
                    res.smartAdvId = String.valueOf(i);
                }
                else if (mode == 'error insertDocParams') {
                    res.isSuccess = false;
                    res.errorMessage = 'Simulated Error insertDocParams!';
                }
                resList.add(res);
            }
            return resList;
        }
        else if (methodName == 'uploadDocument') {
            List<SmartAdvDocumentService.ServiceResponse> resList = new List<SmartAdvDocumentService.ServiceResponse>();
            List<ContentDocumentLink> cdlList = (List<ContentDocumentLink>) args[0];

            for (Integer i=0; i < cdlList.size(); i++) {
                SmartAdvDocumentService.ServiceResponse res = new SmartAdvDocumentService.ServiceResponse();
                if (String.isBlank(mode) || mode == 'success' || mode == 'error insertDocParams') {
                    res.isSuccess = true;
                    res.smartAdvId = String.valueOf(i);
                }
                else if (mode == 'error uploadDocument') {
                    res.isSuccess = false;
                    res.errorMessage = 'Simulated Error uploadDocument!';
                }
                resList.add(res);
            }
            return resList;
        }
        else {
            return null;
        }
    }
}