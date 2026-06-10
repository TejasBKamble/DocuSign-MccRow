/**
 * @description       : 
 * @testing           : 
 * @author            : FSM
 * @last modified on  : 06-24-2025 - FSM
 * @last modified by  : FSM
**/
@isTest
public class SmartAdvTestFactory {
    public static Account createAccount() {
        Account acct = new Account();
        acct.Name = 'Test Account';
        insert acct;
        return acct;
    }

    public static Contact createContact(String accountId, String smartAdvId) {
        Contact con = new Contact();
        con.AccountId = accountId;
        con.FirstName = 'Test';
        con.LastName = 'Contact';
        con.Phone = '5555555555';
        con.Email = 'test@test.com';
        con.MailingStreet = '123 Test Ave';
        con.MailingCity = 'Test City';
        con.MailingState = 'Alabama';
        con.MailingPostalCode = '55555';
        con.Birthdate = Date.today().addYears(-30);
        con.Office__c = 'The McCraw Law Group';
        con.SmartAdvocate_ID__c = smartAdvId;
        insert con;
        return con;
    }

    public static Incident_Detail__c createIncidentDetail(String contactId, String smartAdvId) {
        Incident_Detail__c ind = new Incident_Detail__c();
        ind.Description_of_Accident__c = 'Test Accident';
        ind.Type_of_Accident__c = 'Premises Injury';
        ind.Contact__c = contactId;
        ind.SmartAdvocate_ID__c = smartAdvId;
        insert ind;
        return ind;
    }

    public static SmartAdvCaseDto createCaseDto(String incidentDetailId, String contactId) {
        SmartAdvCaseDto dto = new SmartAdvCaseDto();

        dto.sfIncidentDetailId = incidentDetailId;
        dto.sfContactId = contactId;
        dto.firstName = 'Test';
        dto.lastName = 'Contact';
        dto.phone = '5555555555';
        dto.email = 'test@test.com';
        dto.summary = 'I was bit by a dog';
        dto.searchEngineName = 'Google';
        dto.address = '123 Test Ave';
        dto.city = 'Test City';
        dto.state = 'Alabama';
        dto.zip = '55555';
        dto.referringURL = 'https://www.test.com';
        dto.keywords = 'abc';
        dto.intakeDate = String.valueOf(Date.today());
        dto.dob = String.valueOf(Date.today().addYears(-30));
        dto.caseType = 'Animal Attack';
        dto.office = 'The McCraw Law Group';

        return dto;
    }
}