import Foundation

/// Cómo se reparte un gasto nuevo. En la v1 solo existe "Partes iguales";
/// "Montos exactos" se muestra deshabilitado como adelanto.
enum NuevoGastoModo: String, CaseIterable, Hashable {
    case iguales
    case exactos

    /// Texto del selector segmentado.
    var titulo: String {
        switch self {
        case .iguales: return "Partes iguales"
        case .exactos: return "Montos exactos · pronto"
        }
    }
}
