/**
 * @description       : 
 * @testing           : 
 * @author            : FSM
 * @last modified on  : 06-23-2025 - FSM
 * @last modified by  : FSM
**/
public class SmartAdvDocumentDto {
    public Integer caseID {get;set;}
    public String documentName {get;set;}
    public String docType {get;set;}
    public Integer templateID {get;set;}
    public Boolean attachFlag {get;set;}
    public String description {get;set;}
    public Datetime documentDate {get;set;}
    public Integer categoryID {get;set;}
    public Integer subCategoryID {get;set;}
    public String comments {get;set;}
    public Boolean isReviewed {get;set;}
    public Integer priority {get;set;}
    public Integer documentDirection {get;set;}
    public Integer documentOrigin {get;set;}
    public String documentFolder {get;set;}
    public Boolean isSharedInPortal {get;set;}
    public Boolean isSharedWithEveryoneInPortal {get;set;}
}