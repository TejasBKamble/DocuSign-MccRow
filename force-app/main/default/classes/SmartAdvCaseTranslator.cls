/**
 * @description       : 
 * @testing           : 
 * @author            : FSM
 * @last modified on  : 06-24-2025 - FSM
 * @last modified by  : FSM
**/
public class SmartAdvCaseTranslator {
    public static SmartAdvCaseDto caseFromIncidentDetail(Incident_Detail__c ind) {
        SmartAdvCaseDto dto = new SmartAdvCaseDto();

        dto.sfIncidentDetailId = ind.Id;
        dto.sfContactId = ind.Contact__r.Id;
        dto.firstName = ind.Contact__r.FirstName;
        dto.lastName = ind.Contact__r.LastName;
        dto.phone = ind.Contact__r.Phone;
        dto.email = ind.Contact__r.Email;
        dto.summary = ind.Description_of_Accident__c;
        dto.searchEngineName = null;
        dto.address = ind.Contact__r.MailingStreet;
        dto.city = ind.Contact__r.MailingCity;
        dto.state = ind.Contact__r.MailingState;
        dto.zip = ind.Contact__r.MailingPostalCode;
        dto.referringURL = null;
        dto.keywords = null;
        dto.intakeDate = String.valueOf(ind.CreatedDate).replace(' ', 'T');
        dto.dob = String.valueOf(ind.Contact__r.Birthdate);
        dto.gender = null;
        dto.ssn = null;
        dto.ssnEncoded = false;
        dto.caseType = ind.Smart_Advocate_Case_Type__c;
        dto.office = ind.Contact__r.Office__c;

        return dto;
    }
}