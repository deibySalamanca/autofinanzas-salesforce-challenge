public class DiscountStrategyRegistry {

    public static DiscountStrategy getStrategy(String segmento) {

        if (String.isBlank(segmento)) {
            return null;
        }

        List<Discount_Strategy__mdt> configuraciones = [
            SELECT Strategy_Class__c
            FROM Discount_Strategy__mdt
            WHERE DeveloperName = :segmento
            LIMIT 1
        ];

        if (configuraciones.isEmpty() ||
            String.isBlank(configuraciones[0].Strategy_Class__c)) {
            return null;
        }

        Type tipo = Type.forName(
            configuraciones[0].Strategy_Class__c
        );

        if (tipo == null) {
            return null;
        }

        return (DiscountStrategy) tipo.newInstance();
    }
}