# Plan de acción — RoomieRules v1

Cómo se construyó la primera versión de la app a partir del PRD y de las 5 pantallas de diseño.

## Objetivo (criterio de éxito del PRD)

Una app en Swift donde se simulan 3–4 roomies y el usuario puede:

1. Registrar que pagó la luz y **ver cómo se actualizan solas las deudas** de los demás.
2. **Palomear** su tarea de limpieza de la semana.
3. Navegar la interfaz completa: Inicio, Tareas, Gastos y Hogar.

## Alcance

| Entra en la v1 | Queda fuera (PRD §8) |
|---|---|
| 4 pantallas con TabBar + formulario "Nuevo gasto" | Fotos de recibos o de la limpieza |
| Grupo predefinido de 4 roomies (datos de ejemplo) y poder "ver la app como" cada uno | División por porcentajes o montos exactos (se muestra como "pronto") |
| Gastos a partes iguales, balance y deudas simplificadas, marcar deuda como pagada | Pagos reales dentro de la app |
| Rotación semanal de tareas, palomear, botón "Toque" | Sincronización en tiempo real entre teléfonos (backend) |
| Lista del súper colaborativa con Modo Compras, mini calendario de visitas/eventos | Notificaciones push reales (se simulan con notificaciones locales) |

## Cómo se resolvieron los 3 riesgos del PRD

| Riesgo | Decisión |
|---|---|
| Sincronización en tiempo real | v1 en un solo dispositivo: los datos viven en un archivo JSON local. Todo pasa por `HogarStore`, así que cambiar a Firebase después solo toca la capa `Servicios/`. |
| Notificaciones push | Notificaciones **locales** (`UserNotifications`): el "Toque" y el "Modo Compras" muestran el aviso que recibiría el roomie. |
| Algoritmo de deudas | Balance neto por persona en centavos enteros → parejas exactas → emparejar al mayor deudor con el mayor acreedor. Máximo *n − 1* transferencias y sin cobros circulares. Cubierto con pruebas unitarias. |

## Fases

El trabajo se repartió entre subagentes, cada uno con el modelo adecuado al tipo de tarea:
el más capaz para lo que es difícil de corregir después (estado central, algoritmos, formato del
proyecto de Xcode), uno intermedio para pantallas, y uno ligero para tareas mecánicas.

### Fase 0 — Arquitectura y contrato (orquestador)
- Leer PRD y pantallas; fijar decisiones técnicas (`docs/ARQUITECTURA.md`).
- Escribir el **modelo de datos** (`RoomieRules/Modelos/`) y el calendario de la app: es el contrato que usan todos los demás.

### Fase 1 — Cimientos (4 subagentes en paralelo)
| Tarea | Carpeta | Modelo | Por qué ese modelo |
|---|---|---|---|
| Lógica pura (balances, simplificación de deudas, rotación) + pruebas unitarias | `Logica/`, `RoomieRulesTests/` | Opus | Algoritmos donde un error se nota en dinero; requiere razonamiento cuidadoso. |
| Núcleo: `HogarStore`, persistencia, notificaciones, formatos, datos de ejemplo, arranque de la app | `Datos/`, `Servicios/`, `Utilidades/`, `App/` | Fable | Es la pieza de la que dependen todas las pantallas. |
| Sistema de diseño: colores, tipografías y componentes reutilizables | `Tema/`, `Componentes/` | Sonnet | Trabajo visual bien acotado. |
| Proyecto de Xcode generado por script, esquema, assets, `.gitignore`, CI | `scripts/`, `RoomieRules.xcodeproj/`, `.github/` | Opus | Un error de formato impide abrir el proyecto. |

### Fase 2 — Pantallas y documentación (en paralelo, leyendo el código de la fase 1)
| Tarea | Carpeta | Modelo |
|---|---|---|
| Inicio (dashboard) + hoja "Roomies" para cambiar de usuario y simular el cambio de semana | `Pantallas/Inicio/` | Sonnet |
| Tareas | `Pantallas/Tareas/` | Sonnet |
| Gastos: historial, "Quién le debe a quién", "Nuevo gasto" | `Pantallas/Gastos/` | Opus |
| Hogar: Modo Compras, lista del súper, calendario | `Pantallas/Hogar/` | Sonnet |
| Pruebas de `HogarStore` (flujo del criterio de éxito) | `RoomieRulesTests/` | Sonnet |
| README e ícono de la app | raíz, `Assets.xcassets/` | Haiku |

### Fase 3 — Integración y verificación
- Revisión cruzada de todo el código "como compilador" (nombres, firmas, APIs disponibles en iOS 17).
- Regenerar el proyecto de Xcode con todos los archivos.
- Subir a GitHub y **compilar + correr pruebas en GitHub Actions** (runner de macOS con Xcode), que es la
  verificación real porque el desarrollo se hizo en Windows. Corregir lo que marque el compilador.

## Cómo probar el criterio de éxito en la app

1. Abrir **Gastos → +**, escribir `840`, "Recibo de luz", pagó *Tú*, entre los 4 → **Guardar**.
2. Ir a **Quién le debe a quién**: las deudas se recalculan solas.
3. Ir a **Tareas** y palomear "Limpiar baño": el progreso de la semana avanza.
4. En **Inicio**, tocar los avatares para ver la app como otro roomie o simular el cambio de semana.
