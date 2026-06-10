/**
 * @description       : 
 * @testing           : 
 * @author            : FSM
 * @last modified on  : 06-13-2025 - FSM
 * @last modified by  : FSM
**/
public class SmartAdvDocumentTranslator {
    public static SmartAdvDocumentDto documentFromCdl(ContentDocumentLink cdl, String caseId) {
        SmartAdvDocumentDto dto = new SmartAdvDocumentDto();

        dto.caseID = Integer.valueOf(caseId);
        dto.documentName = cdl.ContentDocument.Title + '.' + cdl.ContentDocument.LatestPublishedVersion.FileExtension;
        dto.docType = getDocType(cdl.ContentDocument.LatestPublishedVersion.FileExtension);
        dto.templateID = 0;
        dto.attachFlag = true;
        dto.description = cdl.ContentDocument.Title;
        dto.documentDate = cdl.ContentDocument.LatestPublishedVersion.CreatedDate;
        dto.categoryID = 25;        // Category "Plaintiff"
        dto.subCategoryID = 928;    // Sub-category "Other Document"
        dto.comments = cdl.ContentDocument.Title;
        dto.isReviewed = false;
        dto.priority = 3;
        dto.documentDirection = 1;  // 1 = Incoming, 2 = Outgoing
        dto.documentOrigin = 2;     // 1 = Generated, 2 = Attached
        dto.documentFolder = null;
        dto.isSharedInPortal = false;
        dto.isSharedWithEveryoneInPortal = false;

        return dto;
    }

    private static String getDocType(String fileExt) {
        if (fileExt == 'doc' || fileExt == 'docx') {
            return 'Doc';
        }
        else if (fileExt == 'pdf') {
            return 'Pdf'; 
        }
        else {
            return 'Img';
        }
    }
}