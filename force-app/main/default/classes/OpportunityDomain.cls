public without sharing class OpportunityDomain {

    public static void applyDiscounts(List<Opportunity> oportunidades, Map<Id, Account> cuentas) {
        for (Opportunity o : oportunidades) {
    
            Account cuenta = cuentas.get(o.AccountId);
    
            if (cuenta == null) {
                o.Discount__c = 0;
                continue;
            }
    
            DiscountStrategy estrategia =
                DiscountStrategyRegistry.getStrategy(
                    cuenta.Customer_Segment__c
                );
    
            o.Discount__c = estrategia == null
                ? 0
                : estrategia.calculateDiscount(o);
        }
    }

    
    

    //Registra la fecha al entrar por primera vez en Credit Review.
    public static void markForReview(List<Opportunity> oportunidades, Map<Id, Opportunity> anteriores) {
        for (Opportunity o : oportunidades) {
            Opportunity anterior = anteriores.get(o.Id);

            if (o.StageName == 'Credit Review'
                && anterior.StageName != 'Credit Review') {
                o.Description = 'Sent to review on '
                    + System.now().format();
            }
        }
    }
}