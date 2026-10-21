ASSUMPTIONS.md

Supuestos del reto

 API de scoring: El servicio externo es simulado mediante HttpCalloutMock, ya que no se proporcionaron una API operativa ni una clave de autenticación real.

 Momento de evaluación: El scoring se solicita únicamente cuando una oportunidad cambia a la etapa Credit Review, no en cada actualización posterior.

 Descuentos: Los descuentos se calculan según el segmento de la cuenta:
    Retail: 2 % si el importe supera 20.000.
    Corporate: 5 % fijo.
    Fleet: 3 % por cada grupo completo de cinco vehículos, con un máximo del 12 %.

 Segmentos futuros: Cada nuevo segmento tendrá su propia clase que implemente DiscountStrategy y su registro correspondiente en Custom Metadata.

 Errores externos: Las respuestas HTTP distintas de 200 o las respuestas inválidas se consideran errores de scoring. Las pruebas simulan estos escenarios sin depender del servicio externo.

 Permisos: El Permission Set Analista_de_Credito concede únicamente los accesos necesarios para la funcionalidad descrita; los permisos efectivos también dependen del perfil, la licencia y el acceso a los registros.

 Datos de prueba: Las pruebas crean sus propios registros y utilizan mocks para evitar dependencias de datos o servicios externos.