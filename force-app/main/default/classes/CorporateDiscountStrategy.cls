public class CorporateDiscountStrategy implements DiscountStrategy {

    public Decimal calculateDiscount(Opportunity oportunidad) {

        // Corporate siempre recibe un descuento del 5%.
        return 5;
    }
}