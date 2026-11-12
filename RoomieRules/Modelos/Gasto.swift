import Foundation

/// Un gasto compartido del departamento.
///
/// Corresponde a la entidad **Gasto** del PRD
/// (`id`, `descripcion`, `montoTotal`, `pagadoPor`, `divididoEntre`, `fecha`), más la categoría.
struct Gasto: Identifiable, Codable, Hashable {
    let id: UUID
    /// Qué se pagó. Ej. "Recibo de luz".
    var descripcion: String
    /// Monto total pagado, en pesos.
    var montoTotal: Double
    /// ID del `Usuario` que puso el dinero.
    var pagadoPor: UUID
    /// IDs de los `Usuario` entre quienes se reparte el gasto, a partes iguales.
    var divididoEntre: [UUID]
    var fecha: Date
    var categoria: CategoriaGasto

    init(
        id: UUID = UUID(),
        descripcion: String,
        montoTotal: Double,
        pagadoPor: UUID,
        divididoEntre: [UUID],
        fecha: Date,
        categoria: CategoriaGasto = .otro
    ) {
        self.id = id
        self.descripcion = descripcion
        self.montoTotal = montoTotal
        self.pagadoPor = pagadoPor
        self.divididoEntre = divididoEntre
        self.fecha = fecha
        self.categoria = categoria
    }

    /// `true` cuando no es un gasto del depa, sino el registro de que un roomie
    /// le pagó a otro lo que le debía (ver `CategoriaGasto.liquidacion`).
    var esLiquidacion: Bool {
        categoria == .liquidacion
    }
}

/// Tipo de gasto.
enum CategoriaGasto: String, Codable, CaseIterable, Identifiable {
    case servicios
    case supermercado
    case renta
    case otro
    /// Pago entre roomies para saldar una deuda. No se elige a mano: lo crea la app
    /// cuando alguien marca una deuda como pagada.
    ///
    /// Se guarda como un `Gasto` donde `pagadoPor` es quien debía y `divididoEntre`
    /// contiene solo a quien se le debía; así el balance de ambos se ajusta solo.
    case liquidacion

    var id: String { rawValue }

    /// Nombre que se muestra en pantalla.
    var nombre: String {
        switch self {
        case .servicios: return "Servicios"
        case .supermercado: return "Súper"
        case .renta: return "Renta"
        case .otro: return "Otro"
        case .liquidacion: return "Pago entre roomies"
        }
    }

    /// Categorías que el usuario puede elegir al registrar un gasto.
    static let seleccionables: [CategoriaGasto] = [.servicios, .supermercado, .renta, .otro]
}
