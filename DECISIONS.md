DECISIONS.md

Arquitectura

Se separó la lógica en Trigger Handler, Domain, Service y Selector para mantener responsabilidades claras, facilitar las pruebas y mejorar el mantenimiento. El trigger solo delega la ejecución.

Descuentos extensibles

Se implementó el patrón Strategy mediante DiscountStrategy y estrategias independientes por segmento. DiscountStrategyRegistry utiliza Custom Metadata (Discount_Strategy__mdt) para resolver la clase correspondiente. Así, agregar un segmento requiere crear una estrategia y configurar sus metadatos, sin modificar las clases existentes.

Scoring crediticio

La integración utiliza CreditScoringService y una llamada HTTP asíncrona mediante Queueable, para no ejecutar el callout directamente dentro del trigger. Se utiliza HttpCalloutMock para probar respuestas exitosas y errores sin depender de una API real.

Seguridad

Se creó el Permission Set Analista_de_Credito con permisos mínimos para consultar oportunidades y cuentas y editar la etapa de la oportunidad. Los resultados del scoring y los descuentos son de solo lectura para el analista. No se conceden permisos globales como View All o Modify All.

Pruebas y procesamiento masivo

Se implementaron pruebas para las reglas de descuento, cambios de etapa, errores del servicio y procesamiento masivo. Las consultas y operaciones se agrupan para reducir riesgos de superar los límites de Salesforce.

Principios SOLID

  SRP (Responsabilidad Única): separar las responsabilidades
  entre Handler, Domain, Service y Selector.
  OCP (Abierto/Cerrado): permitir agregar segmentos mediante
  nuevas estrategias y Custom Metadata, sin modificar las
  estrategias existentes.

     