AI_USAGE.md
Se utilizó ChatGPT como apoyo durante el desarrollo del reto para:

Implementar el patrón Strategy y la resolución dinámica de estrategias mediante Custom Metadata.

Diseñar pruebas unitarias con HttpCalloutMock, incluyendo respuestas exitosas y escenarios de error.

Validación

Las sugerencias se revisaron y adaptaron al proyecto. Se ejecutaron pruebas unitarias en Salesforce Developer Edition y se verificaron los resultados y la cobertura reportada por Salesforce.

Sugerencia evaluada

Se consideró implementar todas las reglas de descuento mediante
condicionales en una sola clase. Se descartó esa alternativa
porque el requerimiento exige facilitar la incorporación de
nuevos segmentos sin modificar las reglas existentes.

Se optó por Strategy y Custom Metadata, y se validó la solución
mediante pruebas Apex.
