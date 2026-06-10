/**
 * @description       : 
 * @testing           : 
 * @author            : FSM
 * @last modified on  : 05-30-2025 - FSM
 * @last modified by  : FSM
**/
public class SmartAdvCalloutUploadDoc extends SmartAdvCallout {
    public SmartAdvCalloutUploadDoc(String token, ContentDocumentLink cdl, String docId) {
        super(token);

        String boundary = '---------------------------162353818188025533064051';
        String delimiter = '--' + boundary;
        String lineBreak = '\r\n';

        String fileName = cdl.ContentDocument.Title + '.' + cdl.ContentDocument.LatestPublishedVersion.FileExtension;
        Blob fileBody = cdl.ContentDocument.LatestPublishedVersion.VersionData;

        String bodyStart = 
            delimiter + lineBreak +
            'Content-Disposition: form-data; name="files"; filename="' + fileName + '"' + lineBreak +
            'Content-Type: application/octet-stream' + lineBreak + lineBreak;
        String bodyEnd = lineBreak + delimiter + '--';

        if (Test.isRunningTest()) {
            bodyBlob = Blob.valueOf('123');
        }
        else {
            String bodyHex = EncodingUtil.convertToHex(Blob.valueOf(bodyStart)) + EncodingUtil.convertToHex(fileBody) + EncodingUtil.convertToHex(Blob.valueOf(bodyEnd));
            bodyBlob = EncodingUtil.convertFromHex(bodyHex);
        }

        httpAction = 'POST';
        url += '/case/document/' + docId + '/content';

        createRequest();

        req.setHeader('Content-Length', String.valueOf(bodyBlob.size()));
        req.setHeader('Content-Type', 'multipart/form-data; boundary=' + boundary);
    }
}