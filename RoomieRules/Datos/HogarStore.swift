import Combine
import Foundation

/// El estado de toda la app: la única fuente de verdad que comparten las cuatro pantallas.
///
/// Las pantallas leen sus propiedades y llaman sus métodos; nunca cambian los datos por su
/// cuenta. Cada cambio se publica (SwiftUI redibuja lo que haga falta) y se guarda en disco.
///
/// Este archivo tiene lo general. Lo demás está repartido por tema en `HogarStore+Tareas.swift`,
/// `HogarStore+Gastos.swift`, `HogarStore+Hogar.swift` y `HogarStore+Demo.swift`.
final class HogarStore: ObservableObject {
    /// Fotografía completa de los datos del depa. Desde fuera solo se puede leer;
    /// cada cambio se guarda en disco.
    @Published private(set) var estado: EstadoHogar {
        didSet { almacen.guardar(estado) }
    }

    /// Dónde se guarda el estado: un archivo en la app, la memoria en pruebas y vistas previas.
    private let almacen: AlmacenDeEstado
    /// Por dónde salen los avisos del Toque y del Modo Compras.
    /// Es de uso interno del store (lo necesitan sus extensiones); las pantallas no lo usan.
    let notificador: Notificador
    /// De dónde sale la hora actual. En pruebas y vistas previas devuelve una fecha fija.
    private let reloj: () -> Date

    /// Cuántas líneas de "Lo que pasa en casa" se conservan como máximo.
    static let maximoDeActividades = 50

    // MARK: - Creación

    /// Crea el store de la app. Si hay un estado guardado con el formato actual, lo usa;
    /// si no (primera vez, archivo dañado o de otra versión), arranca con los datos de ejemplo.
    ///
    /// - Parameters:
    ///   - almacen: dónde se guarda el estado. Por defecto, el archivo JSON de la app.
    ///   - notificador: cómo se mandan los avisos. Por defecto, notificaciones locales.
    ///   - reloj: de dónde sale la hora actual. Por defecto, el reloj del teléfono.
    init(almacen: AlmacenDeEstado = AlmacenEnArchivo(),
         notificador: Notificador = NotificadorLocal.compartido,
         reloj: @escaping () -> Date = { Date() }) {
        self.almacen = almacen
        self.notificador = notificador
        self.reloj = reloj

        let estadoInicial: EstadoHogar
        if let guardado = almacen.cargar(), guardado.version == EstadoHogar.versionActual {
            estadoInicial = guardado
        } else {
            estadoInicial = DatosDeEjemplo.estado(hoy: reloj())
        }
        // Se llena directamente el almacenamiento de `@Published`: es el valor inicial, no un cambio.
        _estado = Published(wrappedValue: estadoInicial)

        // El `didSet` de `estado` no corre dentro de `init`, así que el primer guardado se pide a mano
        // (para que los datos de ejemplo queden en disco desde el primer arranque).
        almacen.guardar(estadoInicial)
        // Si la app se abre en otra semana o en otro día, las tareas se ponen al corriente.
        actualizarRotacionSiHaceFalta()
    }

    /// Store con los datos de ejemplo, sin disco ni notificaciones y con el reloj detenido en `hoy`.
    /// Es el que usan las vistas previas (`#Preview`) y las pruebas.
    static func deEjemplo(hoy: Date = Date()) -> HogarStore {
        HogarStore(almacen: AlmacenEnMemoria(), notificador: NotificadorDePrueba(), reloj: { hoy })
    }

    /// Fecha y hora actuales según el reloj del store. Las pantallas la usan como "hoy"
    /// al pedir textos a `Formato` (por ejemplo, `Formato.tiempoRelativo(_:ahora:)`).
    var ahora: Date {
        reloj()
    }

    // MARK: - General

    /// Nombre del depa. Ej. "Depa Mixcoac".
    var nombreHogar: String {
        estado.nombreHogar
    }

    /// Roomies del depa, en el orden en que rotan las tareas.
    var usuarios: [Usuario] {
        estado.usuarios
    }

    /// Roomie que está usando la app ("Tú").
    var usuarioActual: Usuario {
        if let actual = usuario(estado.usuarioActualID) {
            return actual
        }
        // Nunca debería pasar (el estado siempre trae a sus roomies), pero así no hace falta
        // un `!`: se usa al primero y, si no hay nadie, un roomie genérico.
        if let primero = estado.usuarios.first {
            return primero
        }
        return Usuario(id: estado.usuarioActualID, nombre: "Tú", colorAvatar: .verde)
    }

    /// Todas las tareas, en el orden en que están guardadas (para mostrarlas, usa `tareasOrdenadas`).
    var tareas: [Tarea] {
        estado.tareas
    }

    /// Todos los gastos, incluidas las liquidaciones (para mostrarlos, usa `gastosOrdenados`).
    var gastos: [Gasto] {
        estado.gastos
    }

    /// Todos los artículos de la lista del súper (para mostrarlos, usa `articulosOrdenados`).
    var articulos: [ArtSuper] {
        estado.articulos
    }

    /// Todos los eventos del calendario del depa (para mostrarlos, usa `eventos(en:)` o `proximosEventos`).
    var eventos: [Evento] {
        estado.eventos
    }

    /// El roomie con ese ID, o `nil` si no existe.
    func usuario(_ id: UUID) -> Usuario? {
        estado.usuarios.first { $0.id == id }
    }

    /// `true` si ese ID es el del roomie que está usando la app.
    func esUsuarioActual(_ id: UUID) -> Bool {
        id == usuarioActual.id
    }

    /// Nombre del roomie con ese ID. Ej. "Sara". Si no existe, "Alguien".
    func nombre(de id: UUID) -> String {
        usuario(id)?.nombre ?? "Alguien"
    }

    /// "Tú" si ese ID es el del usuario actual; si no, su nombre.
    func nombreOTu(_ id: UUID) -> String {
        esUsuarioActual(id) ? "Tú" : nombre(de: id)
    }

    /// El gasto con ese ID, o `nil` si no existe (por ejemplo, si ya se eliminó).
    /// Sirve para mostrar "Tu parte" junto a una `Actividad` que trae `gastoID`.
    func gasto(_ id: UUID) -> Gasto? {
        estado.gastos.first { $0.id == id }
    }

    // MARK: - Mutación (uso interno del store)

    /// Único punto por el que cambia `estado`. **Las pantallas no deben llamarlo**: es para las
    /// extensiones de `HogarStore`, que viven en otros archivos y no pueden escribir `estado`
    /// directamente porque es `private(set)`.
    ///
    /// Trabaja sobre una copia y la asigna una sola vez, para que un cambio compuesto (por
    /// ejemplo, agregar un gasto y su línea de actividad) dé un solo aviso a SwiftUI y un solo
    /// guardado en disco. Si al final nada cambió, no publica ni guarda.
    func modificarEstado(_ cambios: (inout EstadoHogar) -> Void) {
        var borrador = estado
        cambios(&borrador)
        guard borrador != estado else { return }
        estado = borrador
    }

    /// Anota una línea en "Lo que pasa en casa". Es de uso interno: se llama dentro de un cambio
    /// hecho con `modificarEstado`, pasándole el mismo `borrador`.
    ///
    /// La línea nueva queda al principio (la lista siempre va de la más nueva a la más vieja)
    /// y solo se conservan las `maximoDeActividades` más recientes.
    func registrarActividad(_ tipo: TipoActividad, de usuarioID: UUID, texto: String,
                            detalle: String? = nil, gastoID: UUID? = nil,
                            en borrador: inout EstadoHogar) {
        let actividad = Actividad(tipo: tipo, usuarioID: usuarioID, texto: texto,
                                  detalle: detalle, gastoID: gastoID, fecha: ahora)
        borrador.actividades.insert(actividad, at: 0)
        if borrador.actividades.count > HogarStore.maximoDeActividades {
            borrador.actividades = Array(borrador.actividades.prefix(HogarStore.maximoDeActividades))
        }
    }
}
