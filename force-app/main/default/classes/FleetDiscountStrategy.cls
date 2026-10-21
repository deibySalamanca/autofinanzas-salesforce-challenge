public class FleetDiscountStrategy implements DiscountStrategy {

    public Decimal calculateDiscount(Opportunity oportunidad) {

        Integer vehiculos = oportunidad.Vehicle_Count__c == null
            ? 0
            : oportunidad.Vehicle_Count__c.intValue();

        // Cada grupo completo de 5 vehículos genera 3%.
        Integer grupos = vehiculos / 5;

        return Math.min(grupos * 3, 12);
    }
}