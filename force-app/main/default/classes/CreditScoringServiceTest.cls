@isTest
private class CreditScoringServiceTest {

    private class ScoreMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {

            System.assertEquals('POST', req.getMethod());
            System.assert(
                req.getEndpoint().endsWith('/v1/score'),
                'Debe utilizar el endpoint correcto.'
            );
            System.assertEquals(
                'application/json',
                req.getHeader('Content-Type')
            );

            Map<String, Object> payload =
                (Map<String, Object>) JSON.deserializeUntyped(
                    req.getBody()
                );

            System.assert(
                payload.containsKey('opportunityId'),
                'Debe enviar el ID de la oportunidad.'
            );
            System.assertEquals(
                Decimal.valueOf('30000'),
                (Decimal) payload.get('amount')
            );
            System.assertEquals('Fleet', payload.get('segment'));

            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"score":712,"status":"APPROVED"}');
            return res;
        }
    }
    
    
    private class ReviewMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"score":650,"status":"REVIEW"}');
            return res;
        }
    }
    
    private class RejectedMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');
    
            res.setBody('{"score":420,"status":"REJECTED"}');
            return res;
        }
    }
    
    @IsTest
	static void testEvaluarRespuestaReview() {
    Account cuenta = new Account(
        Name = 'Cuenta Review',
        Customer_Segment__c = 'Fleet'
    );
    insert cuenta;

    Opportunity o = new Opportunity(
        Name = 'Oportunidad Review',
        AccountId = cuenta.Id,
        StageName = 'Prospecting',
        CloseDate = Date.today().addDays(10),
        Amount = 30000,
        Vehicle_Count__c = 5
    );
    insert o;

    Test.setMock(HttpCalloutMock.class, new ReviewMock());

    Test.startTest();
    CreditScoringService.ScoreResponse resultado =
        CreditScoringService.evaluar(
            o.Id,
            o.Amount,
            cuenta.Customer_Segment__c
        );
    Test.stopTest();

    System.assertEquals(650, resultado.score);
    System.assertEquals('REVIEW', resultado.status);
	}

    @IsTest
    static void testEvaluarRespuestaRejected() {
        Account cuenta = new Account(
            Name = 'Cuenta Rejected',
            Customer_Segment__c = 'Fleet'
        );
        insert cuenta;
    
        Opportunity o = new Opportunity(
            Name = 'Oportunidad Rejected',
            AccountId = cuenta.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10),
            Amount = 30000,
            Vehicle_Count__c = 5
        );
        insert o;
    
        Test.setMock(HttpCalloutMock.class, new RejectedMock());
    
        Test.startTest();
        CreditScoringService.ScoreResponse resultado =
            CreditScoringService.evaluar(
                o.Id,
                o.Amount,
                cuenta.Customer_Segment__c
            );
        Test.stopTest();
    
        System.assertEquals(420, resultado.score);
        System.assertEquals('REJECTED', resultado.status);
    }

    @isTest
    static void testEvaluarRespuestaExitosa() {

        Account cuenta = new Account(
            Name = 'Cuenta de prueba',
            Customer_Segment__c = 'Fleet'
        );
        insert cuenta;

        Opportunity o = new Opportunity(
            Name = 'Oportunidad de scoring',
            AccountId = cuenta.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10),
            Amount = 30000,
            Vehicle_Count__c = 10
        );
        insert o;

        Test.setMock(HttpCalloutMock.class, new ScoreMock());

        Test.startTest();

        CreditScoringService.ScoreResponse resultado =
            CreditScoringService.evaluar(
                o.Id,
                o.Amount,
                cuenta.Customer_Segment__c
            );

        Test.stopTest();

        System.assertEquals(712, resultado.score);
        System.assertEquals('APPROVED', resultado.status);
    }

    @isTest
    static void testGuardarResultadoCreditScoring() {

        Account cuenta = new Account(
            Name = 'Cuenta Fleet',
            Customer_Segment__c = 'Fleet'
        );
        insert cuenta;

        Opportunity o = new Opportunity(
            Name = 'Prueba scoring asíncrono',
            AccountId = cuenta.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10),
            Amount = 30000,
            Vehicle_Count__c = 10
        );
        insert o;

        Test.setMock(HttpCalloutMock.class, new ScoreMock());

        Test.startTest();

        o.StageName = 'Credit Review';
        update o;

        Test.stopTest();

        Opportunity resultado = [
            SELECT StageName, Credit_Score__c, Credit_Status__c
            FROM Opportunity
            WHERE Id = :o.Id
        ];

        System.assertEquals('Credit Review', resultado.StageName);
        System.assertEquals(712, resultado.Credit_Score__c,'Debe guardar la puntuación recibida.');
        System.assertEquals('APPROVED', resultado.Credit_Status__c, 'Debe guardar el estado recibido.');
    }
    
    
    
@isTest
static void testCreditScoringMasivo200Oportunidades() {

    // 1. Crear cuenta de prueba
    Account cuenta = new Account(
        Name = 'Cuenta Fleet Masiva 200',
        Customer_Segment__c = 'Fleet'
    );
    insert cuenta;

    // 2. Crear 200 oportunidades
    List<Opportunity> oportunidades = new List<Opportunity>();

    for (Integer i = 0; i < 200; i++) {
        oportunidades.add(new Opportunity(
            Name = 'Scoring masivo ' + i,
            AccountId = cuenta.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10),
            Amount = 30000,
            Vehicle_Count__c = 10
        ));
    }

    insert oportunidades;

    // 3. Obtener los IDs
    List<Id> ids = new List<Id>();

    for (Opportunity o : oportunidades) {
        ids.add(o.Id);
    }

    // 4. Simular respuesta exitosa del servicio externo
    Test.setMock(HttpCalloutMock.class, new ScoreMock());

    Test.startTest();

    AsyncOptions opciones = new AsyncOptions();
    opciones.MaximumQueueableStackDepth = 2;
    
    System.enqueueJob(
        new CreditScoringJob(ids),
        opciones
    );


    Test.stopTest();

    // 6. Consultar los resultados guardados
    List<Opportunity> resultados = [
        SELECT Id, Credit_Score__c, Credit_Status__c
        FROM Opportunity
        WHERE Id IN :ids
    ];

    Integer evaluadas = 0;

    for (Opportunity o : resultados) {
        if (o.Credit_Score__c == 712
            && o.Credit_Status__c == 'APPROVED') {
            evaluadas++;
        }
    }

    // 7. Validar que se procesaron las 200
    System.assertEquals(
        200,
        resultados.size(),
        'Deben existir las 200 oportunidades de prueba.'
    );

    System.assertEquals(
        200,
        evaluadas,
        'Las 200 oportunidades deben guardar el resultado del scoring.'
    );
}

    
    
    
    private class ErrorMock implements HttpCalloutMock {
        private Integer codigo;
        private String cuerpo;

        ErrorMock(Integer codigo, String cuerpo) {
            this.codigo = codigo;
            this.cuerpo = cuerpo;
        }

        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(codigo);
            res.setBody(cuerpo);
            return res;
        }
    }

    @isTest
    static void testParametrosInvalidos() {
        Boolean excepcionCapturada = false;

        try {
            CreditScoringService.evaluar(null, 30000, 'Fleet');
        } catch (CalloutException e) {
            excepcionCapturada = true;
            System.assertEquals(
                'El ID, el importe y el segmento son obligatorios.',
                e.getMessage()
            );
        }

        System.assert(
            excepcionCapturada,
            'Debe lanzar una excepción si falta el ID.'
        );
    }

   
    @isTest
    static void testJsonInvalido() {
        Test.setMock(
            HttpCalloutMock.class,
            new ErrorMock(200, 'esto no es JSON')
        );

        Boolean excepcionCapturada = false;

        Test.startTest();
        try {
            CreditScoringService.evaluar(
                '006000000000001AAA', 30000, 'Fleet'
            );
        } catch (CalloutException e) {
            excepcionCapturada = true;
            System.assertEquals(
                'La API devolvió una respuesta JSON inválida.',
                e.getMessage()
            );
        }
        Test.stopTest();

        System.assert(
            excepcionCapturada,
            'Debe rechazar el JSON mal formado.'
        );
    }

    @isTest
    static void testRespuestaIncompleta() {
        Test.setMock(
            HttpCalloutMock.class,
            new ErrorMock(200, '{"score":null,"status":""}')
        );

        Boolean excepcionCapturada = false;

        Test.startTest();
        try {
            CreditScoringService.evaluar(
                '006000000000001AAA', 30000, 'Fleet'
            );
        } catch (CalloutException e) {
            excepcionCapturada = true;
            System.assertEquals(
                'La respuesta de scoring está incompleta.',
                e.getMessage()
            );
        }
        Test.stopTest();

        System.assert(
            excepcionCapturada,
            'Debe rechazar la respuesta incompleta.'
        );
    }

    @isTest
    static void testEstadoNoPermitido() {
        Test.setMock(
            HttpCalloutMock.class,
            new ErrorMock(200, '{"score":712,"status":"UNKNOWN"}')
        );

        Boolean excepcionCapturada = false;

        Test.startTest();
        try {
            CreditScoringService.evaluar(
                '006000000000001AAA', 30000, 'Fleet'
            );
        } catch (CalloutException e) {
            excepcionCapturada = true;
            System.assertEquals(
                'La API devolvió un estado de scoring no permitido.',
                e.getMessage()
            );
        }
        Test.stopTest();

        System.assert(
            excepcionCapturada,
            'Debe rechazar los estados no permitidos.'
        );
    }


    private static void verificarErrorHttp(Integer codigoHttp) {
        Test.setMock(
            HttpCalloutMock.class,
            new ErrorMock(codigoHttp, '{"error":"Error simulado"}')
        );

        Boolean excepcionCapturada = false;

        Test.startTest();
        try {
            CreditScoringService.evaluar(
                '006000000000001AAA',
                30000,
                'Fleet'
            );
        } catch (CalloutException e) {
            excepcionCapturada = true;
            System.assert(
                !String.isBlank(e.getMessage()),
                'La excepción debe incluir un mensaje para HTTP ' + codigoHttp
            );
        }
        Test.stopTest();

        System.assert(
            excepcionCapturada,
            'El servicio debe lanzar una excepción para HTTP ' + codigoHttp
        );
    }

    @IsTest
    static void testErrorHttp400() {
        verificarErrorHttp(400);
    }

    @IsTest
    static void testErrorHttp429() {
        verificarErrorHttp(429);
    }

    @IsTest
    static void testErrorHttp500() {
        verificarErrorHttp(500);
    }

    private static void verificarPersistenciaResultado(
        String estadoEsperado,
        Integer puntajeEsperado
    ) {
        Account cuenta = new Account(
            Name = 'Cuenta ' + estadoEsperado,
            Customer_Segment__c = 'Fleet'
        );
        insert cuenta;

        Opportunity oportunidad = new Opportunity(
            Name = 'Prueba persistencia ' + estadoEsperado,
            AccountId = cuenta.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10),
            Amount = 30000,
            Vehicle_Count__c = 5
        );
        insert oportunidad;

        String cuerpo = '{"score":' + String.valueOf(puntajeEsperado)
            + ',"status":"' + estadoEsperado + '"}';

        Test.setMock(
            HttpCalloutMock.class,
            new ErrorMock(200, cuerpo)
        );

        Test.startTest();

        oportunidad.StageName = 'Credit Review';
        update oportunidad;

        Test.stopTest();

        Opportunity resultado = [
            SELECT StageName, Credit_Score__c, Credit_Status__c
            FROM Opportunity
            WHERE Id = :oportunidad.Id
        ];

        System.assertEquals(
            'Credit Review',
            resultado.StageName,
            'La oportunidad debe permanecer en Credit Review.'
        );
        System.assertEquals(
            Decimal.valueOf(String.valueOf(puntajeEsperado)),
            resultado.Credit_Score__c,
            'Debe persistir el puntaje recibido.'
        );
        System.assertEquals(
            estadoEsperado,
            resultado.Credit_Status__c,
            'Debe persistir el estado recibido.'
        );
    }

    @IsTest
    static void testPersistenciaReview() {
        verificarPersistenciaResultado('REVIEW', 650);
    }

    @IsTest
    static void testPersistenciaRejected() {
        verificarPersistenciaResultado('REJECTED', 420);
    }

}