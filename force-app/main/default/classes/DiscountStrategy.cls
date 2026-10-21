// Contrato común para las estrategias de descuento.
public interface DiscountStrategy {

    // Cada estrategia debe implementar este método.
    Decimal calculateDiscount(Opportunity oportunidad);
}