public with sharing class CreditScoringJob
    implements Queueable, Database.AllowsCallouts {

    private List<Id> opportunityIds;

    public CreditScoringJob(List<Id> opportunityIds) {
        
        this.opportunityIds = opportunityIds == null
            ? new List<Id>()
            : opportunityIds;
    }

    public void execute(QueueableContext context) {

        if (opportunityIds.isEmpty()) {
            return;
        }

        Integer limite = Math.min(100, opportunityIds.size());

        List<Id> idsActuales = new List<Id>();
        List<Id> idsPendientes = new List<Id>();

        for (Integer i = 0; i < opportunityIds.size(); i++) {
            if (i < limite) {
                idsActuales.add(opportunityIds[i]);
            } else {
                idsPendientes.add(opportunityIds[i]);
            }
        }

        Set<Id> idsConsulta = new Set<Id>(idsActuales);
        
        Map<Id, Opportunity> oportunidades =
            new Map<Id, Opportunity>(
                OpportunitySelector.selectByIds(idsConsulta)
            );

        List<Opportunity> actualizaciones = new List<Opportunity>();

        for (Id opportunityId : idsActuales) {
            Opportunity o = oportunidades.get(opportunityId);

            if (o == null
                || o.AccountId == null
                || o.Amount == null
                || o.Account.Customer_Segment__c == null) {
                continue;
            }

            try {
                CreditScoringService.ScoreResponse respuesta =
                    CreditScoringService.evaluar(
                        o.Id,
                        o.Amount,
                        o.Account.Customer_Segment__c
                    );

                actualizaciones.add(new Opportunity(
                    Id = o.Id,
                    Credit_Score__c = respuesta.score,
                    Credit_Status__c = respuesta.status
                ));

            } catch (Exception e) {
                System.debug(
                    LoggingLevel.ERROR,
                    'Error evaluando oportunidad ' + o.Id
                    + ': ' + e.getMessage()
                );
            }
        }

        if (!actualizaciones.isEmpty()) {
            update actualizaciones;
        }

        if (!idsPendientes.isEmpty()) {
            System.enqueueJob(new CreditScoringJob(idsPendientes));
        }
    }
}