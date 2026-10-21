public class OpportunityTriggerHandler {

     public static void beforeUpdate(
        List<Opportunity> nuevas,
        Map<Id, Opportunity> anteriores
    ) {
        
        OpportunityHelper.applyDiscount(nuevas);

        OpportunityHelper.markForReview(nuevas, anteriores);

        OpportunityHelper.enqueueCreditScoring(nuevas, anteriores);
    }
}