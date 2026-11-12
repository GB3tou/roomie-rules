import Foundation

/// Una tarea del hogar asignada a un roomie.
///
/// Corresponde a la entidad **Tarea** del PRD (`id`, `titulo`, `asignadoA`, `completada`, `fechaLim`),
/// más el área de la casa y la frecuencia, que hacen falta para dibujar las pantallas.
struct Tarea: Identifiable, Codable, Hashable {
    let id: UUID
    /// Qué hay que hacer. Ej. "Limpiar baño".
    var titulo: String
    /// Zona de la casa a la que pertenece la tarea.
    var area: AreaHogar
    /// ID del `Usuario` responsable esta semana. Cambia solo cuando rota la semana.
    var asignadoA: UUID
    var completada: Bool
    /// Fecha límite para cumplirla (en tareas diarias siempre es "hoy").
    var fechaLim: Date
    var frecuencia: FrecuenciaTarea
    /// Última vez que alguien mandó un "Toque" por esta tarea. `nil` si nunca.
    var ultimoToque: Date?

    init(
        id: UUID = UUID(),
        titulo: String,
        area: AreaHogar,
        asignadoA: UUID,
        completada: Bool = false,
        fechaLim: Date,
        frecuencia: FrecuenciaTarea = .semanal,
        ultimoToque: Date? = nil
    ) {
        self.id = id
        self.titulo = titulo
        self.area = area
        self.asignadoA = asignadoA
        self.completada = completada
        self.fechaLim = fechaLim
        self.frecuencia = frecuencia
        self.ultimoToque = ultimoToque
    }

    /// `true` si la tarea sigue pendiente y su fecha límite ya pasó.
    /// Las tareas diarias nunca se consideran atrasadas: se reinician cada día.
    func estaAtrasada(hoy: Date, calendario: Calendar = Calendar.roomie) -> Bool {
        guard !completada, frecuencia == .semanal else { return false }
        return calendario.startOfDay(for: fechaLim) < calendario.startOfDay(for: hoy)
    }
}

/// Zonas de la casa entre las que se reparten las tareas.
enum AreaHogar: String, Codable, CaseIterable, Identifiable {
    case bano
    case cocina
    case sala
    case comunes

    var id: String { rawValue }

    /// Nombre completo. Ej. "Áreas comunes".
    var nombre: String {
        switch self {
        case .bano: return "Baño"
        case .cocina: return "Cocina"
        case .sala: return "Sala"
        case .comunes: return "Áreas comunes"
        }
    }

    /// Nombre para espacios chicos. Ej. "Comunes".
    var nombreCorto: String {
        switch self {
        case .comunes: return "Comunes"
        default: return nombre
        }
    }
}

/// Cada cuánto se repite una tarea.
enum FrecuenciaTarea: String, Codable, CaseIterable {
    /// Se hace una vez por semana, antes de `fechaLim`.
    case semanal
    /// Se hace todos los días; la palomita se borra al día siguiente.
    case diaria
}
