import Foundation

/// Una línea del historial "Lo que pasa en casa" de la pantalla de Inicio.
///
/// En pantalla se arma como: **{nombre de quien lo hizo}** + `texto`,
/// y debajo "Hace 10 min · `detalle`".
struct Actividad: Identifiable, Codable, Hashable {
    let id: UUID
    var tipo: TipoActividad
    /// ID del `Usuario` que hizo la acción.
    var usuarioID: UUID
    /// Lo que va después del nombre. Ej. "activó Modo Compras" o "registró Internet · $600".
    var texto: String
    /// Dato secundario opcional. Ej. "Walmart Universidad".
    var detalle: String?
    /// Si la actividad habla de un gasto, su ID (sirve para mostrar "Tu parte $150").
    var gastoID: UUID?
    var fecha: Date

    init(
        id: UUID = UUID(),
        tipo: TipoActividad,
        usuarioID: UUID,
        texto: String,
        detalle: String? = nil,
        gastoID: UUID? = nil,
        fecha: Date
    ) {
        self.id = id
        self.tipo = tipo
        self.usuarioID = usuarioID
        self.texto = texto
        self.detalle = detalle
        self.gastoID = gastoID
        self.fecha = fecha
    }
}

/// Qué clase de cosa pasó en casa.
enum TipoActividad: String, Codable, CaseIterable {
    /// Alguien avisó que va al súper.
    case modoCompras
    /// Alguien registró un gasto compartido.
    case gasto
    /// Alguien marcó una deuda como pagada.
    case liquidacion
    /// Alguien terminó una tarea.
    case tareaCompletada
    /// Alguien mandó un Toque (recordatorio amistoso).
    case toque
    /// Alguien apuntó una visita o evento en el calendario.
    case evento
}
