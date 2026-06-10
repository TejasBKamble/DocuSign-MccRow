/**
 * @description       : 
 * @testing           : 
 * @author            : FSM
 * @last modified on  : 05-02-2025 - FSM
 * @last modified by  : FSM
**/
public class SmartAdvCalloutGetFilteredCases extends SmartAdvCallout {
    public SmartAdvCalloutGetFilteredCases(String token, Datetime startDt, Datetime endDt, Integer currentPage, Integer pageSize) {
        super(token);

        httpAction = 'POST';
        url += '/case/byDatePaged';
        body = buildBody(startDt, endDt, currentPage, pageSize);

        createRequest();

        req.setHeader('Content-Type', 'application/json');
    }

    private String buildBody(Datetime startDt, Datetime endDt, Integer currentPage, Integer pageSize) {
        Map<String,Object> m1 = new Map<String,Object>();

        Map<String,Object> m2 = new Map<String,Object>();
        m2.put('pageSize', pageSize);
        m2.put('currentPage', currentPage);
        m1.put('pageRequest', m2);

        m1.put('caseNumbers', new List<Object>());
        m1.put('modifiedToDateTime', dtToString(endDt));
        m1.put('modifiedFromDateTime', dtToString(startDt));

        return JSON.serializePretty(m1);
    }

    private String dtToString(Datetime dt) {
        String s = String.valueOfGmt(dt).replace(' ', 'T') + '.0000000\u002B00:00';
        return s;
    }
}