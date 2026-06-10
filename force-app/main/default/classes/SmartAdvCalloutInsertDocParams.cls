/**
 * @description       : 
 * @testing           : 
 * @author            : FSM
 * @last modified on  : 05-21-2025 - FSM
 * @last modified by  : FSM
**/
public class SmartAdvCalloutInsertDocParams extends SmartAdvCallout {
    public SmartAdvCalloutInsertDocParams(String token, SmartAdvDocumentDto d) {
        super(token);

        httpAction = 'POST';
        url += '/case/document';
        body = buildBody(d);

        createRequest();

        req.setHeader('Content-Type', 'application/json');
    }

    private String buildBody(SmartAdvDocumentDto d) {
        Map<String,Object> bodyMap = new Map<String,Object>();
        bodyMap.put('caseID', d.caseID);
        bodyMap.put('documentName', d.documentName);
        bodyMap.put('docType', d.docType);
        bodyMap.put('templateID', d.templateID);
        bodyMap.put('attachFlag', d.attachFlag);
        bodyMap.put('description', d.description);
        bodyMap.put('documentDate', d.documentDate);
        bodyMap.put('categoryId', d.categoryID);
        bodyMap.put('subCategoryId', d.subCategoryID);
        bodyMap.put('comments', d.comments);
        bodyMap.put('isReviewed', d.isReviewed);
        bodyMap.put('priority', d.priority);
        bodyMap.put('documentDirection', d.documentDirection);
        bodyMap.put('documentOrigin', d.documentOrigin);
        bodyMap.put('documentFolder', d.documentFolder);
        bodyMap.put('isSharedInPortal', d.isSharedInPortal);
        bodyMap.put('isSharedWithEveryoneInPortal', d.isSharedWithEveryoneInPortal);
        
        String body = JSON.serializePretty(bodyMap);
        return body;
    }
}