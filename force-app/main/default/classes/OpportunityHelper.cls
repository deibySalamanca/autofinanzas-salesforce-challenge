public without sharing class OpportunityHelper {
    
   
    // Consulta las cuentas y delega las reglas al Domain.
    public static void applyDiscount(List<Opportunity> oportunidades) {
        Set<Id> accountIds = new Set<Id>();
    
        for (Opportunity o : oportunidades) {
            if (o.AccountId != null) {
                accountIds.add(o.AccountId);
            }
        }
    
        Map<Id, Account> cuentas = OpportunitySelector.selectAccountsByIds(accountIds);
        OpportunityDomain.applyDiscounts(oportunidades, cuentas);
    }
    
    public static void markForReview(List<Opportunity> oportunidades, Map<Id, Opportunity> anteriores) {
        OpportunityDomain.markForReview(oportunidades, anteriores);
    }

    public static void enqueueCreditScoring(List<Opportunity> opps, Map<Id, Opportunity> oldMap) {
        // Reunimos las oportunidades que acaban de entrar en revisión.
        List<Id> idsParaEvaluar = new List<Id>();
        for (Opportunity o : opps) {
            Opportunity anterior = oldMap.get(o.Id);
    
            if (o.StageName == 'Credit Review'
                && anterior.StageName != 'Credit Review') {
                idsParaEvaluar.add(o.Id);
            }
        }
    
        if (!idsParaEvaluar.isEmpty()) {
            System.enqueueJob(
                new CreditScoringJob(idsParaEvaluar)
            );
        }
    }

}