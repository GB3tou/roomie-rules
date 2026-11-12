# Arquitectura de RoomieRules

Documento de referencia del proyecto. Explica **cómo está organizada la app**, qué hace cada
carpeta y las reglas que sigue todo el código. Si vas a agregar algo, empieza por aquí.

---

## 1. Decisiones técnicas

| Tema | Decisión | Por qué |
|---|---|---|
| Interfaz | **SwiftUI**, solo iPhone, modo claro | Es lo que pide el curso y lo que muestran las pantallas. |
| Versión mínima | **iOS 17.0**, lenguaje **Swift 5** | Abre y compila en Xcode 15 o más nuevo. |
| Estado | Un solo `HogarStore` (`ObservableObject`) compartido con `.environmentObject` | Una única fuente de verdad: si se registra un gasto, todas las pantallas se actualizan solas. |
| Persistencia | Archivo **JSON local** (`Application Support`) | El PRD (riesgo 1) deja abierta la sincronización; la v1 usa datos simulados en un solo dispositivo. |
| Notificaciones | **Locales** (`UserNotifications`) | El PRD (riesgo 2) pide simular el push del "Toque" y del "Modo Compras" sin cuenta de desarrollador de pago. |
| Deudas | Balance neto por persona + emparejamiento de deudores con acreedores, en **centavos enteros** | Resuelve el riesgo 3 del PRD (cobros circulares) sin errores de redondeo. |
| Dependencias | **Ninguna** externa | Se clona y corre, sin instalar nada. |
| Idioma del código | Español. Identificadores y nombres de archivo **sin acentos ni ñ** | Coincide con el modelo de datos del PRD y evita problemas entre Windows, macOS y git. |

## 2. Estructura de carpetas

```
RoomieRules.xcodeproj/        Proyecto de Xcode (se genera con scripts/generar_proyecto_xcode.py)
RoomieRules/
├── App/                      Punto de entrada, pestañas y navegación entre pestañas
├── Modelos/                  Entidades del PRD: Usuario, Tarea, Gasto, ArtSuper… (solo datos)
├── Utilidades/               Calendario (semana que empieza en lunes) y formatos de dinero/fechas
├── Logica/                   Reglas puras, sin interfaz: balances, simplificación de deudas, rotación
├── Servicios/                Lo que toca al sistema: guardar en disco y mandar notificaciones
├── Datos/                    HogarStore (el estado de la app) y los datos de ejemplo
├── Tema/                     Colores, tipografías y medidas
├── Componentes/              Piezas visuales reutilizables (avatar, tarjeta, casillas, chips…)
├── Pantallas/
│   ├── Inicio/               Dashboard: balance, mis tareas, "Lo que pasa en casa"
│   ├── Tareas/               Responsables por área, palomear, botón "Toque"
│   ├── Gastos/               Historial, "Quién le debe a quién", formulario "Nuevo gasto"
│   └── Hogar/                Modo Compras, lista del súper, calendario del depa
└── Assets.xcassets/          Color de acento e ícono
RoomieRulesTests/             Pruebas unitarias (XCTest)
scripts/                      Utilidades de mantenimiento (generar el proyecto de Xcode, ícono)
docs/                         Esta documentación
```

**Flujo de datos:** `Pantalla` → llama un método de `HogarStore` → el store cambia `estado`
→ se guarda en disco → SwiftUI redibuja todas las pantallas que lo observan.
Las pantallas **nunca** modifican los datos directamente.

```
 Pantallas (SwiftUI) ──acciones──▶ HogarStore ──usa──▶ Logica (cálculos puros)
        ▲                              │      └─usa──▶ Servicios (disco, notificaciones)
        └────── @Published estado ─────┘
```

## 3. Modelo de datos (`RoomieRules/Modelos/`)

| Tipo | Qué es | Campos del PRD | Campos añadidos |
|---|---|---|---|
| `Usuario` | Un roomie | `id`, `nombre`, `fotoPerfil` | `colorAvatar` |
| `Tarea` | Tarea del hogar | `id`, `titulo`, `asignadoA`, `completada`, `fechaLim` | `area`, `frecuencia`, `ultimoToque` |
| `Gasto` | Gasto compartido | `id`, `descripcion`, `montoTotal`, `pagadoPor`, `divididoEntre`, `fecha` | `categoria` |
| `ArtSuper` | Artículo del súper | `id`, `nombre`, `fueComprado` | `agregadoPor`, `fechaAgregado` |
| `Evento` | Visita o evento del calendario | — | (entidad nueva, la pide la pantalla de Hogar) |
| `Actividad` | Línea de "Lo que pasa en casa" | — | (entidad nueva, la pide la pantalla de Inicio) |
| `ModoCompras` | Aviso de "voy al súper" | — | (entidad nueva) |
| `Transferencia` | Deuda simplificada: `de` le debe `monto` a `para` | — | Se calcula, no se guarda |
| `EstadoHogar` | Todo lo anterior junto; es lo que se guarda en disco | — | — |

Todos los `id` son `UUID`. Las relaciones se guardan como IDs (`asignadoA: UUID`), igual que en el PRD.

Una **liquidación** ("Sara ya le pagó a Roberto") se guarda como un `Gasto` con
`categoria == .liquidacion`, `pagadoPor` = quien debía y `divididoEntre` = [a quien se le debía].
Así los balances se ajustan con la misma fórmula y no hace falta otra entidad.

## 4. Contratos entre capas

> Estas firmas son el acuerdo entre las capas. Las pantallas solo usan lo que aparece aquí.

### 4.1 Utilidades

`Utilidades/Calendario.swift` (ya escrito): `Locale.roomie` (es_MX), `Calendar.roomie` (semana
que empieza en lunes) y sus ayudantes `inicioDeSemana(para:)`, `diasDeLaSemana(para:)`,
`finDeSemana(para:)`, `sumar(dias:a:)`, `semanasEntre(_:y:)`, `esMismoDia(_:_:)`, `esMismoMes(_:_:)`.

`Utilidades/Formato.swift` — textos listos para mostrar (siempre en español de México):

```swift
enum Formato {
    static func dinero(_ monto: Double) -> String          // "$840", "$3,160", "$52.50" (sin decimales si es entero)
    static func dineroExacto(_ monto: Double) -> String    // "$210.00" (siempre 2 decimales)
    static func diaCorto(_ fecha: Date) -> String          // "vie 13"
    static func diaLargo(_ fecha: Date) -> String          // "viernes 13"
    static func diaSemana(_ fecha: Date) -> String         // "Viernes"
    static func diaSemanaAbreviado(_ fecha: Date) -> String // "Vie"
    static func numeroDeDia(_ fecha: Date) -> String       // "13"
    static func diaYMes(_ fecha: Date) -> String           // "10 nov"
    static func mes(_ fecha: Date) -> String               // "Noviembre"
    static func hora(_ fecha: Date) -> String              // "20:00"
    static func rangoSemana(inicio: Date) -> String        // "Semana del 9 al 15 de noviembre"
    static func tiempoRelativo(_ fecha: Date, ahora: Date) -> String  // "Ahora", "Hace 10 min", "Hace 2 h", "Ayer", "Hace 3 d", "3 nov"
    static func vencimientoCorto(de tarea: Tarea, hoy: Date) -> String   // "diario" | "hoy" | "mañana" | "vie 13"
    static func vencimientoLargo(de tarea: Tarea, hoy: Date) -> String   // "todos los días" | "vence hoy" | "vence mañana" | "vence viernes 13"
    static func etiquetaVencimiento(de tarea: Tarea, hoy: Date) -> String // "Diario" | "Hoy" | "Mañana" | "Viernes"
}
```

### 4.2 Lógica (`Logica/`) — funciones puras, sin SwiftUI, 100 % probables con XCTest

```swift
enum Dinero {
    static func aCentavos(_ pesos: Double) -> Int      // redondea al centavo más cercano
    static func aPesos(_ centavos: Int) -> Double
}

enum CalculadoraDeBalances {
    /// Cuánto le toca a cada participante de un gasto, en centavos. La suma SIEMPRE es el total:
    /// si la división no es exacta, los centavos sobrantes se reparten de uno en uno
    /// entre los primeros participantes (en el orden de `divididoEntre`).
    static func partesEnCentavos(de gasto: Gasto) -> [UUID: Int]
    /// Parte en pesos de `usuarioID` en ese gasto (0 si no participa).
    static func parte(de usuarioID: UUID, en gasto: Gasto) -> Double
    /// Balance neto por usuario en centavos: positivo = le deben, negativo = debe. Siempre suma 0.
    /// Incluye a todos los `usuarios` (con 0 si no aparecen en ningún gasto).
    static func balancesEnCentavos(gastos: [Gasto], usuarios: [Usuario]) -> [UUID: Int]
}

enum SimplificadorDeDeudas {
    /// Convierte balances netos en la menor cantidad práctica de transferencias (máximo n − 1).
    /// `orden` desempata de forma estable (se usa el orden de `usuarios`).
    static func simplificar(balances: [UUID: Int], orden: [UUID]) -> [Transferencia]
    /// Atajo: calcula balances y simplifica.
    static func transferencias(gastos: [Gasto], usuarios: [Usuario]) -> [Transferencia]
}

enum RotadorDeTareas {
    struct Resultado: Equatable {
        var tareas: [Tarea]
        var inicioSemana: Date            // lunes 00:00 de la semana de `hoy`
        var ultimaRevisionDiaria: Date    // inicio del día de `hoy`
        var semanasRotadas: Int           // 0 si no cambió la semana
    }
    /// Avanza la asignación `semanas` semanas: cada tarea pasa al siguiente roomie en el orden de
    /// `usuarios` (el último le pasa al primero), se desmarca, se borra su `ultimoToque`
    /// y su `fechaLim` se recorre 7 días por semana.
    static func rotar(_ tareas: [Tarea], usuarios: [Usuario], semanas: Int, calendario: Calendar) -> [Tarea]
    /// Pone las tareas al día respecto a `hoy`: rota si cambió la semana y, si cambió el día,
    /// desmarca las tareas diarias y les pone `fechaLim` = hoy.
    static func actualizar(tareas: [Tarea], usuarios: [Usuario], inicioSemanaRegistrado: Date,
                           ultimaRevisionDiaria: Date, hoy: Date, calendario: Calendar) -> Resultado
}
```

Algoritmo de deudas (para explicarlo en clase):

1. **Balance neto** de cada roomie = lo que pagó − lo que le tocaba. Quien queda en positivo es acreedor; en negativo, deudor.
2. **Parejas exactas**: si un deudor debe justo lo que le deben a un acreedor, se emparejan (una sola transferencia salda a los dos).
3. **Voraz**: el mayor deudor le paga al mayor acreedor lo más que se pueda; quien quede en cero sale de la lista. Se repite.
4. Resultado: como mucho *n − 1* transferencias y **nunca hay cobros circulares**, porque nadie es deudor y acreedor a la vez.

### 4.3 Servicios (`Servicios/`)

```swift
protocol AlmacenDeEstado {
    func cargar() -> EstadoHogar?            // nil si no hay nada guardado o no se pudo leer
    func guardar(_ estado: EstadoHogar)
    func borrar()
}
struct AlmacenEnArchivo: AlmacenDeEstado     // JSON en Application Support/RoomieRules/estado.json
final class AlmacenEnMemoria: AlmacenDeEstado // para #Preview y pruebas

protocol Notificador: AnyObject {
    func enviar(titulo: String, cuerpo: String)
}
final class NotificadorLocal: NSObject, Notificador, UNUserNotificationCenterDelegate {
    static let compartido: NotificadorLocal
    func configurar()                         // se llama una vez al arrancar la app
}
final class NotificadorDePrueba: Notificador { // no manda nada; guarda lo "enviado"
    private(set) var enviadas: [(titulo: String, cuerpo: String)]
}

enum MensajesDeToque {                        // recordatorios amistosos ya escritos
    static func mensaje(tarea: Tarea, remitente: Usuario, destinatario: Usuario, hoy: Date) -> (titulo: String, cuerpo: String)
}
```

`NotificadorLocal` pide permiso la primera vez que hace falta y muestra el banner aunque la app esté abierta.

### 4.4 `HogarStore` (`Datos/`)

```swift
final class HogarStore: ObservableObject {
    @Published private(set) var estado: EstadoHogar        // cada cambio se guarda en disco

    init(almacen: AlmacenDeEstado = AlmacenEnArchivo(),
         notificador: Notificador = NotificadorLocal.compartido,
         reloj: @escaping () -> Date = { Date() })
    static func deEjemplo(hoy: Date = Date()) -> HogarStore // datos de ejemplo, sin disco ni notificaciones

    var ahora: Date

    // General
    var nombreHogar: String
    var usuarios: [Usuario]
    var usuarioActual: Usuario
    var tareas: [Tarea]
    var gastos: [Gasto]
    var articulos: [ArtSuper]
    var eventos: [Evento]
    func usuario(_ id: UUID) -> Usuario?
    func esUsuarioActual(_ id: UUID) -> Bool
    func nombre(de id: UUID) -> String          // "Sara"
    func nombreOTu(_ id: UUID) -> String        // "Tú" si es el usuario actual; si no, su nombre
    func gasto(_ id: UUID) -> Gasto?            // para mostrar "Tu parte" junto a una Actividad

    // Uso interno del store (las pantallas NO lo llaman): único punto por el que cambia `estado`.
    func modificarEstado(_ cambios: (inout EstadoHogar) -> Void)

    // Tareas  (HogarStore+Tareas.swift)
    var inicioSemana: Date
    var tareasOrdenadas: [Tarea]                // mías pendientes → de otros pendientes → completadas
    var misTareasPendientes: [Tarea]
    var tareasCompletadas: Int
    func puedeCompletar(_ tarea: Tarea) -> Bool // solo quien la tiene asignada
    func alternarCompletada(_ tarea: Tarea)
    func puedeDarToque(_ tarea: Tarea) -> Bool  // es de otro, está pendiente y no hay toque reciente
    func toqueReciente(_ tarea: Tarea) -> Bool  // ya se mandó un Toque hace menos de 1 hora
    @discardableResult func darToque(_ tarea: Tarea) -> String?  // devuelve el recordatorio enviado
    func actualizarRotacionSiHaceFalta()        // al abrir la app o volver a primer plano
    func simularCambioDeSemana()                // demo: rota como si ya fuera lunes

    // Gastos  (HogarStore+Gastos.swift)
    var gastosOrdenados: [Gasto]                // más reciente primero (incluye liquidaciones)
    var totalDelMes: Double                     // mes en curso, sin liquidaciones
    var pagadoPorMiEsteMes: Double
    var miParteEsteMes: Double
    func parte(de usuarioID: UUID, en gasto: Gasto) -> Double
    func miParte(en gasto: Gasto) -> Double
    func balance(de usuarioID: UUID) -> Double  // + le deben, − debe
    var miBalance: Double
    var transferencias: [Transferencia]         // deudas simplificadas de todo el depa
    var misTransferencias: [Transferencia]      // solo donde participa el usuario actual
    @discardableResult func agregarGasto(descripcion: String, montoTotal: Double, categoria: CategoriaGasto,
                                         pagadoPor: UUID, divididoEntre: [UUID]) -> Gasto?
    func eliminarGasto(_ gasto: Gasto)
    func liquidar(_ transferencia: Transferencia)

    // Hogar  (HogarStore+Hogar.swift)
    var articulosOrdenados: [ArtSuper]          // por comprar primero, comprados al final
    var articulosPorComprar: Int
    func agregarArticulo(_ nombre: String)
    func alternarComprado(_ articulo: ArtSuper)
    func eliminarArticulo(_ articulo: ArtSuper)
    func limpiarComprados()
    var modoCompras: ModoCompras?               // solo si sigue vigente
    var estoyDeCompras: Bool
    func activarModoCompras(lugar: String)
    func terminarModoCompras()
    func eventos(en dia: Date) -> [Evento]
    func hayEventos(en dia: Date) -> Bool
    var proximosEventos: [Evento]
    func agregarEvento(titulo: String, fecha: Date, tipo: TipoEvento)
    func eliminarEvento(_ evento: Evento)

    // Actividad
    var actividadesRecientes: [Actividad]       // más nuevas primero

    // Demo  (HogarStore+Demo.swift)
    func cambiarUsuarioActual(a id: UUID)       // "ver la app como otro roomie"
    func restablecerDatosDeEjemplo()
}
```

### 4.5 Navegación (`App/Navegacion.swift`)

```swift
enum TabPrincipal: Hashable { case inicio, tareas, gastos, hogar }
enum SeccionGastos: String, CaseIterable, Identifiable { case historial, deudas }   // .titulo: "Historial" / "Quién le debe a quién"

final class Navegacion: ObservableObject {
    @Published var tab: TabPrincipal
    @Published var seccionGastos: SeccionGastos
    @Published var enfocarNuevoArticulo: Bool
    func verTareas()            // Inicio → pestaña Tareas
    func verDeudas()            // Inicio → pestaña Gastos, sección "Quién le debe a quién"
    func verListaDelSuper()     // Inicio → pestaña Hogar, con el cursor en "Agregar artículo…"
}
```

### 4.6 App (`App/`)

- `RoomieRulesApp` (`@main`): crea `HogarStore` y `Navegacion`, los inyecta con `.environmentObject`,
  fija `.environment(\.locale, Locale.roomie)`, modo claro y el color de acento; al volver a
  primer plano llama `store.actualizarRotacionSiHaceFalta()`.
- `VistaPrincipal`: `TabView` con las 4 pestañas — `InicioView()`, `TareasView()`, `GastosView()`, `HogarView()`
  (ninguna recibe parámetros: leen `HogarStore` y `Navegacion` con `@EnvironmentObject`).

## 5. Sistema de diseño (`Tema/` y `Componentes/`)

Colores (`Tema`), tomados de las pantallas:

| Token | Hex | Uso |
|---|---|---|
| `fondo` | `#F3F2EE` | Fondo de todas las pantallas |
| `tarjeta` | `#FFFFFF` | Tarjetas |
| `borde` | `#E4E2DA` | Borde de tarjetas y controles |
| `tinta` | `#1B1B1F` | Texto principal, botón oscuro, chip seleccionado |
| `tintaSecundaria` | `#6A6A70` | Texto secundario |
| `tintaTerciaria` | `#A3A29C` | Texto deshabilitado, bordes de casillas |
| `verde` | `#1F6F54` | Color de marca: tarjeta de balance, palomitas, botones |
| `verdeOscuro` | `#185A44` | Recuadros dentro de la tarjeta verde |
| `verdeSuave` | `#DCEEE5` | Fondos seleccionados, avatar verde |
| `textoSuaveSobreVerde` | `#CFE9DD` | Etiquetas sobre la tarjeta verde |
| `pista` | `#EBE9E3` | Fondo de selector segmentado, píldoras y barra de progreso |
| `campo` | `#F8F7F3` | Fondo de campos de texto |
| `alerta` / `alertaSuave` | `#B4432F` / `#F8E0DA` | Saldos en contra, tareas atrasadas |
| `amarillo` / `amarilloSuave` | `#7A5A00` / `#FDEFC2` | Ícono de luz, tarjeta de Modo Compras |
| `morado` / `moradoSuave` | `#4A3A9A` / `#E5E0F6` | Ícono de internet, avatar morado |
| `naranja` / `naranjaSuave` | `#7A4A0C` / `#FCE4BF` | Avatar naranja |
| `azul` / `azulSuave` | `#26477E` / `#DCE8F8` | Avatar azul |
| `rosa` / `rosaSuave` | `#A03A2A` / `#F8E0DA` | Ícono de gas, avatar rosa |

Medidas: `Tema.margen = 20` (margen lateral de pantalla), `Tema.radioTarjeta = 22`, `Tema.radioControl = 14`.

Componentes reutilizables (cada uno en su archivo dentro de `Componentes/`, con comentario y `#Preview`):
`AvatarView`, `GrupoAvataresView`, `PantallaDesplazable`, `EncabezadoPantalla`, `TituloSeccion`,
modificador `.tarjeta()`, `CasillaCircular`, `CasillaCuadrada`, `ChipSeleccionable`, `Pildora`,
`SelectorSegmentado`, `IconoCuadrado`, `IconoGasto`, estilos de botón (`EstiloBotonOscuro`,
`EstiloBotonVerde`, `EstiloBotonPildoraBlanca`, `EstiloBotonContorno`), `BotonFlotante`,
`EstadoVacio` y el modificador `.aviso(_:)` (mensaje breve tipo *toast*).

## 6. Reglas de código (obligatorias)

Nadie del equipo de desarrollo tiene compilador a la mano en todo momento (parte del trabajo se
hace en Windows), así que estas reglas existen para que el proyecto **compile a la primera** en Xcode 15+:

1. **Solo APIs de iOS 17 o anteriores.** Prohibido lo que nació en iOS 18/26 o Xcode 16+:
   `Tab(...)` dentro de `TabView` (usar `.tabItem` + `.tag`), `@Entry`, `@Previewable`, `MeshGradient`,
   `ScrollPosition`, `.onScrollGeometryChange`, `.presentationSizing`, `.navigationTransition`,
   efectos de símbolo `.wiggle/.breathe/.rotate`, `glassEffect`, Swift Testing (`import Testing`).
2. **Sintaxis de Swift 5.9.** Nada de comas finales en llamadas, parámetros o tuplas
   (`foo(a: 1, b: 2,)` no compila antes de Swift 6.1); sí se permiten en arreglos y diccionarios.
   Sin *typed throws*, sin `nonisolated(unsafe)`, sin macros propias.
3. **Estado con `ObservableObject`**: `@Published`, `@StateObject`, `@EnvironmentObject`. No usar `@Observable` ni SwiftData.
4. **Sin `@MainActor` propio ni `async/await` innecesario.** Todo cambio de estado ocurre en el hilo principal desde la interfaz.
   Si un callback del sistema llega en otro hilo, se regresa con `DispatchQueue.main.async`.
5. **`onChange`** con la forma de iOS 17: `.onChange(of: valor) { _, nuevo in … }` o `.onChange(of: valor) { … }`.
6. **Identificadores y nombres de archivo en ASCII** (sin acentos ni ñ). Los textos visibles sí llevan acentos.
7. **Un tipo principal por archivo**, con el mismo nombre que el archivo. Los tipos auxiliares de una
   pantalla llevan el prefijo de su pantalla (`Inicio…`, `Tareas…`, `Gastos…`, `Hogar…`) o son `private`,
   para que no choquen nombres entre carpetas.
8. **Las pantallas no calculan ni guardan**: leen propiedades de `HogarStore` y llaman sus métodos.
   Nada de `UserDefaults`, archivos o notificaciones desde una vista.
9. **Fechas y dinero siempre con `Formato` y `Calendar.roomie`** (nunca `Calendar.current` ni formateadores sueltos).
10. **Colores y medidas siempre de `Tema`** (nada de `Color.green` ni hex sueltos en las pantallas).
11. **Sin `!` (force unwrap)** salvo en constantes literales comprobadas (por ejemplo `UUID(uuidString:)` de los datos de ejemplo).
12. **Comentarios en español** que expliquen el *porqué*. Cada tipo lleva un comentario `///` de una o dos líneas.
13. Cada vista principal incluye un `#Preview` que usa `HogarStore.deEjemplo()` y `Navegacion()`.
14. Sin dependencias externas, sin imágenes ni fuentes añadidas: solo SF Symbols y la fuente del sistema.

## 7. Datos de ejemplo (`Datos/DatosDeEjemplo.swift`)

La app arranca con el depa de las pantallas, con fechas **relativas al día en que se abre**
para que siempre se vea viva:

- **Depa Mixcoac** con 4 roomies, en este orden de rotación: Roberto (verde, usuario actual), Sara (morado), Mauricio (naranja), Ana (azul).
- **Tareas de la semana**: Limpiar baño (Roberto, baño, viernes) · Trapear pasillo (Roberto, comunes, domingo) ·
  Sacar la basura (Sara, cocina, hoy) · Aspirar la sala (Ana, sala, sábado) · Lavar trastes (Mauricio, cocina, diaria, ya hecha).
- **Gastos del mes**, todos entre los 4: Recibo de luz $840 (Roberto, ayer) · Internet $600 (Sara, hace 3 días) ·
  Súper semanal $1,240 (Mauricio, hace 5 días) · Tanque de gas $480 (Ana, hace 8 días).
  Total $3,160 → a cada quien le tocan $790 → **a Roberto le deben $50** (Sara).
- **Lista del súper**: Huevo (30 pzas) — Sara · Papel de baño — Ana · Leche deslactosada — Roberto ·
  Jabón para trastes — Mauricio · Tortillas — Sara (ya comprado).
- **Modo Compras** activo: Mauricio, "Walmart Universidad", desde hace 10 minutos.
- **Lo que pasa en casa**: Mauricio activó Modo Compras (hace 10 min) · Sara registró Internet · $600 (hace 2 h).
- **Calendario**: Junta de roomies (jueves 20:00) · Visita de los papás de Sara (sábado 14:00) · Viene el plomero (martes siguiente 10:00).

Los IDs de los cuatro roomies son constantes (`DatosDeEjemplo.robertoID`, `saraID`, `mauricioID`, `anaID`)
para poder usarlos en pruebas y vistas previas.
