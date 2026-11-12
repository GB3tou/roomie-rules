# RoomieRules

App para iPhone que ayuda a los roomies de un departamento a repartir tareas del hogar, gastos y la lista del súper, sin tener que cobrar ni exigir la limpieza en persona. Está pensada para jóvenes que comparten depa: todo queda a la vista en un solo lugar.

Proyecto universitario del Equipo 4 de la materia *Desarrollo de Aplicaciones para Dispositivos Inteligentes*.

## Qué hace

- **Inicio:** balance general del depa (por ejemplo, "Te deben $50"), tus tareas de la semana y "Lo que pasa en casa".
- **Tareas:** responsables por área con rotación semanal (cambia cada lunes), palomear tu tarea y mandar un "Toque" (recordatorio amistoso ya escrito) a otro roomie.
- **Gastos:** historial, registro de un gasto dividido a partes iguales, "Quién le debe a quién" con las deudas simplificadas y marcar una deuda como pagada.
- **Hogar:** Modo Compras (avisa que vas al súper), lista del súper compartida y calendario de visitas y eventos.
- **Demo:** simula 4 roomies en un solo teléfono. Tocando los avatares de Inicio puedes ver la app como cada uno, simular el cambio de semana y restablecer los datos de ejemplo.

## Requisitos

- Una Mac con Xcode 15 o más nuevo.
- iOS 17 o superior (simulador o iPhone).
- Sin dependencias externas: no hay que instalar nada más.

## Cómo correrla

1. Clona el repositorio:

```bash
git clone https://github.com/GB3tou/roomie-rules.git
```

2. Abre `RoomieRules.xcodeproj` con Xcode (doble clic).
3. Arriba, elige el esquema **RoomieRules** y un simulador de iPhone.
4. Presiona **⌘R** (Run).

Notas:

- Para correrla en un iPhone real, elige tu equipo en *Signing & Capabilities* del target RoomieRules. Si Xcode lo pide, cambia también el *Bundle Identifier*.
- La primera vez que mandes un Toque o actives Modo Compras, iOS pedirá permiso de notificaciones. Acéptalo para ver el aviso simulado.

## Pruebas

Presiona **⌘U** en Xcode para correr las pruebas unitarias de la carpeta `RoomieRulesTests/` (unas 100). Cubren:

- Balances (`CalculadoraDeBalances`).
- Simplificación de deudas (`SimplificadorDeDeudas`).
- Rotación de tareas (`RotadorDeTareas`).
- Formatos de dinero y fechas (`Formato`).
- El estado de la app (`HogarStore`): registrar un gasto y ver las deudas actualizadas, palomear tareas, Toque, lista del súper, Modo Compras y guardado en disco.

## Prueba rápida del criterio de éxito

1. Ve a **Gastos** y toca **+**. Escribe `840`, con la descripción "Recibo de luz", pagó *Tú*, entre los 4. Toca **Guardar**.
2. Ve a **Quién le debe a quién**. Las deudas se recalculan solas.
3. Ve a **Tareas** y palomea "Limpiar baño". El progreso de la semana avanza.
4. En **Inicio**, toca los avatares para ver la app como otro roomie, o simula el cambio de semana.

## Estructura del proyecto

```
RoomieRules.xcodeproj/   Proyecto de Xcode (se genera con scripts/generar_proyecto_xcode.py)
RoomieRules/
├── App/                 Punto de entrada, pestañas y navegación entre pestañas
├── Modelos/             Entidades del PRD: Usuario, Tarea, Gasto, ArtSuper…
├── Utilidades/          Calendario (semana que empieza en lunes) y formatos de dinero y fechas
├── Logica/              Reglas puras sin interfaz: balances, simplificación de deudas, rotación
├── Servicios/           Lo que toca al sistema: guardar en disco y mandar notificaciones
├── Datos/               HogarStore (el estado de la app) y los datos de ejemplo
├── Tema/                Colores, tipografías y medidas
├── Componentes/         Piezas visuales reutilizables (avatar, tarjeta, casillas, chips…)
├── Pantallas/
│   ├── Inicio/          Dashboard: balance, mis tareas, "Lo que pasa en casa"
│   ├── Tareas/          Responsables por área, palomear, botón "Toque"
│   ├── Gastos/          Historial, "Quién le debe a quién", formulario "Nuevo gasto"
│   └── Hogar/           Modo Compras, lista del súper, calendario del depa
└── Assets.xcassets/     Color de acento e ícono
RoomieRulesTests/        Pruebas unitarias (XCTest)
scripts/                 Utilidades de mantenimiento (generar el proyecto de Xcode, ícono)
docs/                    Documentación de arquitectura y plan de acción
.github/workflows/       Integración continua (GitHub Actions)
```

## Cómo está hecha

- Interfaz en **SwiftUI**, con Swift 5 e iOS 17 como versión mínima.
- Un solo `HogarStore` (`ObservableObject`) es la fuente de verdad. Las pantallas leen de él y solo llaman sus métodos.
- Los datos se guardan en un archivo JSON local, en Application Support.
- Las notificaciones son locales (`UserNotifications`) y simulan el push del Toque y de Modo Compras.
- Las deudas se calculan en centavos enteros: balance neto por persona, luego parejas exactas, luego el mayor deudor con el mayor acreedor. Da como máximo n − 1 pagos y nunca hay cobros en círculo.

Documentación: [Arquitectura](docs/ARQUITECTURA.md) y [Plan de acción](docs/PLAN_DE_ACCION.md).

## Agregar archivos al proyecto

Lo normal es crear los archivos desde Xcode. Si creas o mueves archivos `.swift` desde fuera de Xcode (por ejemplo, en Windows), hay que regenerar el proyecto.

En macOS:

```bash
python3 scripts/generar_proyecto_xcode.py
```

En Windows:

```bash
python scripts/generar_proyecto_xcode.py
```

Aviso: ese script reescribe `RoomieRules.xcodeproj` a partir de las carpetas `RoomieRules/` y `RoomieRulesTests/`. Los ajustes hechos a mano en el proyecto desde Xcode se pierden al regenerar.

## Integración continua

El repositorio incluye un workflow de GitHub Actions (`.github/workflows/ios.yml`) que compila la app y corre las pruebas en un simulador de iPhone en cada push a `main`. También corre en pull requests que cambien código y se puede lanzar a mano. En repositorios privados consume minutos de macOS de la cuenta; se puede desactivar desde la pestaña **Actions** de GitHub.

## Qué queda fuera de esta versión

Según el PRD:

- Sincronización en tiempo real entre teléfonos (por ejemplo, con Firebase).
- Notificaciones push reales.
- División por montos exactos o porcentajes.
- Fotos de recibos.
- Pagos dentro de la app.
