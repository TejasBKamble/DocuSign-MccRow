/**
 * @description       : 
 * @testing           : 
 * @author            : FSM
 * @last modified on  : 06-23-2025 - FSM
 * @last modified by  : FSM
**/
public class SmartAdvContactTranslator {
    public static Contact contactFromJson(String j) {
        Map<String,Object> m = (Map<String,Object>) JSON.deserializeUntyped(j);
        Contact con = new Contact();

        con.SmartAdvocate_ID__c = String.valueOf((Integer) m.get('uniqueContactId'));
        con.FirstName = (String) m.get('firstName');
        con.LastName = (String) m.get('lastName');
        con.MailingStreet = (String) m.get('address1');
        con.MailingCity = (String) m.get('city');
        con.MailingStateCode = (String) m.get('state');
        con.MailingPostalCode = (String) m.get('zip');
        con.Phone = (String) m.get('contactNumber');
        con.Email = (String) m.get('contactEmail');
        if (m.get('dateOfBirth') != null) {
            con.Birthdate = Date.valueOf((String) m.get('dateOfBirth'));
        }

        return con;
    }

    // Query Contacts with exactly the fields that sync from SmartAdvocate. This lets us easily see if there have been any changes from SmartAdv and we need to update in Salesforce
    public static List<Contact> queryContacts(List<String> smartAdvUids) {
        List<Contact> cList = [
            SELECT
                SmartAdvocate_ID__c,
                FirstName,
                LastName,
                MailingStreet,
                MailingCity,
                MailingStateCode,
                MailingPostalCode,
                Phone,
                Email,
                Birthdate
            FROM Contact
            WHERE SmartAdvocate_ID__c IN : smartAdvUids
        ];

        List<Contact> returnList = new List<Contact>();
        for (Contact c : cList) {
            Contact ret = new Contact();
            ret.SmartAdvocate_ID__c = c.SmartAdvocate_ID__c;
            ret.FirstName = c.FirstName;
            ret.LastName = c.LastName;
            ret.MailingStreet = c.MailingStreet;
            ret.MailingCity = c.MailingCity;
            ret.MailingStateCode = c.MailingStateCode;
            ret.MailingPostalCode = c.MailingPostalCode;
            ret.Phone = c.Phone;
            ret.Email = c.Email;
            ret.Birthdate = c.Birthdate;
            returnList.add(ret);
        }
        return returnList;
    }
}