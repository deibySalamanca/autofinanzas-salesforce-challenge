public with sharing class CreditScoringService {

    public class ScoreResponse {
        public Integer score;
        public String status;
    }

    public static ScoreResponse evaluar(
        Id opportunityId,
        Decimal amount,
        String segment
    ) {
         if (opportunityId == null || amount == null
            || String.isBlank(segment)) {
            throw new CalloutException(
                'El ID, el importe y el segmento son obligatorios.'
            );
        }

        HttpRequest req = new HttpRequest();

        req.setEndpoint('callout:AutoFinanzas_Score/v1/score');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');

        Map<String, Object> payload = new Map<String, Object>{
            'opportunityId' => String.valueOf(opportunityId),
            'amount' => amount,
            'segment' => segment
        };
        req.setBody(JSON.serialize(payload));

        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() != 200) {
            throw new CalloutException(
                'Error del servicio de scoring: HTTP '
                + res.getStatusCode()
            );
        }

        ScoreResponse resultado;
        try {
            resultado = (ScoreResponse) JSON.deserialize(
                res.getBody(),
                ScoreResponse.class
            );
        } catch (Exception e) {
            throw new CalloutException(
                'La API devolvió una respuesta JSON inválida.'
            );
        }

        if (resultado == null || resultado.score == null
            || String.isBlank(resultado.status)) {
            throw new CalloutException(
                'La respuesta de scoring está incompleta.'
            );
        }

        Set<String> estadosPermitidos = new Set<String>{
            'APPROVED', 'REVIEW', 'REJECTED'
        };

        if (!estadosPermitidos.contains(resultado.status)) {
            throw new CalloutException(
                'La API devolvió un estado de scoring no permitido.'
            );
        }

        return resultado;
    }
}