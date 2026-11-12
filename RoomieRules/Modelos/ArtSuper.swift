import Foundation

/// Un artículo de la lista del súper compartida.
///
/// Corresponde a la entidad **ArtSuper** del PRD (`id`, `nombre`, `fueComprado`),
/// más quién lo agregó y cuándo (la pantalla de Hogar muestra el nombre de quien lo pidió).
struct ArtSuper: Identifiable, Codable, Hashable {
    let id: UUID
    /// Ej. "Huevo (30 pzas)".
    var nombre: String
    var fueComprado: Bool
    /// ID del `Usuario` que agregó el artículo a la lista.
    var agregadoPor: UUID
    var fechaAgregado: Date

    init(
        id: UUID = UUID(),
        nombre: String,
        fueComprado: Bool = false,
        agregadoPor: UUID,
        fechaAgregado: Date
    ) {
        self.id = id
        self.nombre = nombre
        self.fueComprado = fueComprado
        self.agregadoPor = agregadoPor
        self.fechaAgregado = fechaAgregado
    }
}
