public class RetailDiscountStrategy implements DiscountStrategy {

    public Decimal calculateDiscount(Opportunity oportunidad) {

        // Retail recibe 2% si el importe supera 20.000.
        if (oportunidad.Amount != null &&
            oportunidad.Amount > 20000) {
            return 2;
        }
        return 0;
    }
}