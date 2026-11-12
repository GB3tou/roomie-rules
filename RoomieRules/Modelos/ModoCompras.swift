import Foundation

/// Aviso de que un roomie está (o va camino) al súper.
///
/// Mientras está vigente, los demás pueden agregar a la lista lo que les falte.
struct ModoCompras: Codable, Hashable {
    /// ID del `Usuario` que fue al súper.
    var activadoPor: UUID
    /// A qué tienda fue. Ej. "Walmart Universidad". Cadena vacía si no lo dijo.
    var lugar: String
    /// Momento en que lo activó.
    var inicio: Date

    /// El aviso se apaga solo después de este tiempo, por si a alguien se le olvida terminarlo.
    static let duracionMaxima: TimeInterval = 2 * 60 * 60

    init(activadoPor: UUID, lugar: String = "", inicio: Date) {
        self.activadoPor = activadoPor
        self.lugar = lugar
        self.inicio = inicio
    }

    /// `true` si el aviso sigue activo en el momento `fecha`.
    func estaVigente(en fecha: Date) -> Bool {
        fecha.timeIntervalSince(inicio) < ModoCompras.duracionMaxima
    }
}
