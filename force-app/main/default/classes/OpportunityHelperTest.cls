@IsTest
private class OpportunityHelperTest {

    private static Opportunity crearOportunidad(
        Id cuentaId,
        String nombre,
        Decimal importe,
        Decimal vehiculos
    ) {
        return new Opportunity(
            Name = nombre,
            AccountId = cuentaId,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10),
            Amount = importe,
            Vehicle_Count__c = vehiculos
        );
    }

    private class ScoreMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();

            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');

            res.setBody('{"score":712,"status":"APPROVED"}');

            return res;
        }
    }

    @IsTest
    static void testReglasDescuento() {

        List<Account> cuentas = new List<Account>{
            new Account(Name = 'Retail', Customer_Segment__c = 'Retail'),
            new Account(Name = 'Corporate', Customer_Segment__c = 'Corporate'),
            new Account(Name = 'Fleet', Customer_Segment__c = 'Fleet')
        };
        insert cuentas;

        List<Opportunity> oportunidades = new List<Opportunity>{
            crearOportunidad(cuentas[0].Id, 'Retail mayor a 20000', 20001, 0),
            crearOportunidad(cuentas[0].Id, 'Retail igual a 20000', 20000, 0),
            crearOportunidad(cuentas[1].Id, 'Corporate', 1000, 0),
            crearOportunidad(cuentas[2].Id, 'Fleet 15 vehículos', 1000, 15),
            crearOportunidad(cuentas[2].Id, 'Fleet máximo', 1000, 25)
        };
        insert oportunidades;

        for (Opportunity o : oportunidades) {
            o.Description = 'Prueba de descuento';
        }

        Test.startTest();
        update oportunidades;
        Test.stopTest();

        Map<Id, Opportunity> resultados = new Map<Id, Opportunity>([
            SELECT Id, Discount__c
            FROM Opportunity
            WHERE Id IN :oportunidades
        ]);

        // Retail: más de 20000 debe recibir 2%.
        System.assertEquals(
            2, resultados.get(oportunidades[0].Id).Discount__c,
            'Retail por encima de 20000 debe recibir 2%.'
        );

        // Retail: exactamente 20000 no debe recibir descuento.
        System.assertEquals(
            0, resultados.get(oportunidades[1].Id).Discount__c,
            'Retail exactamente en 20000 debe recibir 0%.'
        );

        // Corporate siempre 5%.
        System.assertEquals(
            5, resultados.get(oportunidades[2].Id).Discount__c,
            'Corporate debe recibir 5%.'
        );

        // Fleet recibe 3% por cada grupo completo de cinco vehículos.
        System.assertEquals(
            9, resultados.get(oportunidades[3].Id).Discount__c,
            'Fleet con 15 vehículos debe recibir 9%.'
        );

        // Fleet nunca puede superar el máximo del 12%.
        System.assertEquals(
            12, resultados.get(oportunidades[4].Id).Discount__c,
            'Fleet debe tener un máximo de 12%.'
        );
    }

    @IsTest
    static void testScoringSoloAlEntrarEnCreditReview() {

        Account cuenta = new Account(
            Name = 'Cuenta prueba scoring',
            Customer_Segment__c = 'Retail'
        );
        insert cuenta;

        Opportunity oportunidad = crearOportunidad(
            cuenta.Id, 'Prueba entrada Credit Review', 30000, 5
        );
        insert oportunidad;

        Test.setMock(HttpCalloutMock.class, new ScoreMock());

        Test.startTest();

        oportunidad.StageName = 'Credit Review';
        update oportunidad;

        Integer trabajosTrasEntrar = Limits.getQueueableJobs();

        System.assertEquals(
            1, trabajosTrasEntrar,
            'Al entrar en Credit Review debe encolarse un trabajo.'
        );

        
        oportunidad.Description = 'Descripción escrita por el usuario';
        update oportunidad;

        System.assertEquals(
            trabajosTrasEntrar,
            Limits.getQueueableJobs(),
            'Modificar la descripción no debe volver a encolar el scoring.'
        );

        
        Opportunity yaEnRevision = new Opportunity(
            Name = 'Oportunidad ya en revisión',
            AccountId = cuenta.Id,
            StageName = 'Credit Review',
            CloseDate = Date.today().addDays(10),
            Amount = 30000,
            Vehicle_Count__c = 5
        );
        insert yaEnRevision;

        Integer trabajosAntesDeActualizar = Limits.getQueueableJobs();

        yaEnRevision.Name = 'Nombre actualizado';
        update yaEnRevision;

        System.assertEquals(
            trabajosAntesDeActualizar,
            Limits.getQueueableJobs(),
            'Actualizar una oportunidad que ya estaba en revisión no debe encolar scoring.'
        );

        Test.stopTest();

        Opportunity resultado = [
            SELECT StageName, Description
            FROM Opportunity
            WHERE Id = :oportunidad.Id
        ];

        System.assertEquals(
            'Credit Review', resultado.StageName,
            'La oportunidad debe permanecer en Credit Review.'
        );

        System.assertEquals(
            'Descripción escrita por el usuario',
            resultado.Description,
            'El trigger no debe sobrescribir la descripción en una actualización posterior.'
        );
    }

    @IsTest
    static void testProcesamientoMasivo200() {

        Account cuenta = new Account(
            Name = 'Cuenta masiva',
            Customer_Segment__c = 'Retail'
        );
        insert cuenta;

        List<Opportunity> oportunidades = new List<Opportunity>();

        for (Integer i = 0; i < 200; i++) {
            oportunidades.add(
                crearOportunidad(
                    cuenta.Id, 'Oportunidad masiva ' + i, 30000, 0
                )
            );
        }
        insert oportunidades;

        Test.setMock(HttpCalloutMock.class, new ScoreMock());

        for (Opportunity o : oportunidades) {
            o.Description = 'Prueba masiva';
        }

        Test.startTest();
        update oportunidades;
        Test.stopTest();
        Integer correctos = [
            SELECT COUNT()
            FROM Opportunity
            WHERE Id IN :oportunidades
            AND Discount__c = 2
        ];

        System.assertEquals(
            200, correctos,
            'Las 200 oportunidades deben recibir el descuento del 2%.'
        );
    }
}