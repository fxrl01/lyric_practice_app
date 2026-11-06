# Specification-Driven Development

LyricFlow se desarrollará mediante **SDD (Specification-Driven Development)**.
La especificación será el contrato previo de cada cambio; el código y las
pruebas deben demostrar ese contrato.

## Flujo obligatorio

```text
Idea
  -> Especificación
  -> Revisión de alcance y riesgos
  -> Diseño técnico
  -> Criterios de aceptación
  -> Tareas pequeñas
  -> Tests primero o junto al cambio
  -> Implementación
  -> Validación
  -> Actualización de documentación y ADR si aplica
```

## Artefactos

Cada feature relevante debe tener un documento en `docs/specs/` usando
[template.md](./template.md). Una especificación debe contener:

1. Problema y objetivo.
2. Fuera de alcance.
3. Actores y casos de uso.
4. Contratos de entrada y salida.
5. Reglas de negocio y estados.
6. Criterios de aceptación medibles.
7. Diseño técnico y módulos afectados.
8. Riesgos, seguridad y privacidad.
9. Plan de pruebas.
10. Estado de implementación.

## Reglas de calidad

- No implementar comportamiento ambiguo: registrar la decisión en la spec.
- Cada criterio de aceptación debe tener una prueba o una verificación
  reproducible.
- La spec no debe describir detalles internos que no afecten el contrato.
- Los errores, timeouts, reintentos y estados no disponibles deben estar
  definidos explícitamente.
- Si cambia una frontera arquitectónica, agregar o actualizar un ADR.
- Una spec implementada se conserva como historial; no se reescribe para
  ocultar decisiones anteriores.

## Estados

```text
draft -> approved -> in_progress -> implemented -> verified
```

`blocked` se usa cuando existe una dependencia externa que impide verificar un
criterio. Una dependencia sin API key no debe bloquear el desarrollo de
contratos, mocks y pruebas.

## Definition of Ready

Una spec está lista para implementarse cuando:

- el objetivo es verificable;
- el alcance y las exclusiones están claros;
- los módulos y contratos afectados están identificados;
- los criterios de aceptación tienen datos de prueba;
- los riesgos de seguridad y datos están revisados.

## Definition of Done

Un cambio está terminado cuando:

- sus criterios de aceptación pasan;
- existen pruebas proporcionales al riesgo;
- lint, type-check o build aplicables pasan;
- no se exponen secretos;
- la documentación y los ADR relacionados están actualizados;
- el estado de la spec es `verified`.

## Relación con la arquitectura

SDD no reemplaza Clean Architecture, arquitectura hexagonal ni C4:

- SDD define **qué** debe hacer el cambio.
- Clean/hexagonal define **dónde** vive la lógica.
- C4 describe **cómo** se relaciona el sistema.
- ADR registra **por qué** se tomó una decisión.

