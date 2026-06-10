/**
 * @description       : 
 * @testing           : 
 * @author            : FSM
 * @last modified on  : 06-24-2025 - FSM
 * @last modified by  : FSM
**/
public class SmartAdvEventHandlerCreateCase implements ISmartAdvEventHandler {
    private SmartAdvCaseService caseService;

    // Default constructor
    public SmartAdvEventHandlerCreateCase() {
        this(new SmartAdvCaseService());
    }

    // Constructor for injecting mock/stub
    public SmartAdvEventHandlerCreateCase(SmartAdvCaseService service) {
        this.caseService = service;
    }

    public ApiEventResponse handle(API_Event__c event) {
        ApiEventResponse res = new ApiEventResponse();

        Incident_Detail__c ind = [
            SELECT 
                Id,
                Description_of_Accident__c,
                CreatedDate,
                Smart_Advocate_Case_Type__c,
                Contact__r.Id,
                Contact__r.FirstName,
                Contact__r.LastName,
                Contact__r.Phone,
                Contact__r.Email,
                Contact__r.MailingStreet,
                Contact__r.MailingCity,
                Contact__r.MailingState,
                Contact__r.MailingPostalCode,
                Contact__r.Birthdate,
                Contact__r.Office__c
            FROM Incident_Detail__c
            WHERE Id =: event.Related_Record_ID__c
            LIMIT 1
        ];
        SmartAdvCaseDto caseDto = SmartAdvCaseTranslator.caseFromIncidentDetail(ind);

        List<SmartAdvCaseService.ServiceResponse> srList = caseService.createSmartAdvocateCase(new List<SmartAdvCaseDto> {caseDto});
        
        SmartAdvCaseService.ServiceResponse sr = srList[0];
        res.isSuccess = sr.isSuccess;
        res.errorMessage = sr.errorMessage;
        
        return res;
    }
}