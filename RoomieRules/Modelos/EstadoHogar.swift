import Foundation

/// Fotografía completa de los datos del departamento.
///
/// Es lo único que se guarda en disco (como JSON) y la única fuente de verdad de la app:
/// `HogarStore` la publica y todas las pantallas leen de ahí.
struct EstadoHogar: Codable, Equatable {
    /// Versión del formato guardado. Si algún día cambia el modelo, sirve para migrar o descartar datos viejos.
    var version: Int
    /// Ej. "Depa Mixcoac".
    var nombreHogar: String
    /// Roomies del depa. **El orden importa**: es el orden en que rotan las tareas.
    var usuarios: [Usuario]
    /// Roomie que está usando la app en este dispositivo ("Tú").
    var usuarioActualID: UUID
    var tareas: [Tarea]
    var gastos: [Gasto]
    var articulos: [ArtSuper]
    var eventos: [Evento]
    var actividades: [Actividad]
    /// Aviso de Modo Compras más reciente. `nil` si nadie lo ha activado o ya se terminó.
    var modoCompras: ModoCompras?
    /// Lunes (00:00) de la semana a la que corresponde la asignación actual de tareas.
    var inicioSemanaRotacion: Date
    /// Último día en que se revisaron las tareas diarias (para borrarles la palomita al día siguiente).
    var ultimaRevisionDiaria: Date

    /// Versión actual del formato.
    static let versionActual = 1

    init(
        version: Int = EstadoHogar.versionActual,
        nombreHogar: String,
        usuarios: [Usuario],
        usuarioActualID: UUID,
        tareas: [Tarea] = [],
        gastos: [Gasto] = [],
        articulos: [ArtSuper] = [],
        eventos: [Evento] = [],
        actividades: [Actividad] = [],
        modoCompras: ModoCompras? = nil,
        inicioSemanaRotacion: Date,
        ultimaRevisionDiaria: Date
    ) {
        self.version = version
        self.nombreHogar = nombreHogar
        self.usuarios = usuarios
        self.usuarioActualID = usuarioActualID
        self.tareas = tareas
        self.gastos = gastos
        self.articulos = articulos
        self.eventos = eventos
        self.actividades = actividades
        self.modoCompras = modoCompras
        self.inicioSemanaRotacion = inicioSemanaRotacion
        self.ultimaRevisionDiaria = ultimaRevisionDiaria
    }
}
