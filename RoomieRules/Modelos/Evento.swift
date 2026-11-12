import Foundation

/// Una visita o evento apuntado en el calendario del depa (pantalla de Hogar).
struct Evento: Identifiable, Codable, Hashable {
    let id: UUID
    /// Ej. "Junta de roomies".
    var titulo: String
    /// Día y hora del evento.
    var fecha: Date
    var tipo: TipoEvento
    /// ID del `Usuario` que lo apuntó.
    var creadoPor: UUID

    init(
        id: UUID = UUID(),
        titulo: String,
        fecha: Date,
        tipo: TipoEvento = .evento,
        creadoPor: UUID
    ) {
        self.id = id
        self.titulo = titulo
        self.fecha = fecha
        self.tipo = tipo
        self.creadoPor = creadoPor
    }
}

/// Clase de evento del calendario.
enum TipoEvento: String, Codable, CaseIterable, Identifiable {
    /// Alguien viene de visita.
    case visita
    /// Reunión, fiesta o junta de roomies.
    case evento
    /// Viene alguien a arreglar o entregar algo (plomero, gas, internet…).
    case servicio

    var id: String { rawValue }

    /// Nombre que se muestra en pantalla.
    var nombre: String {
        switch self {
        case .visita: return "Visita"
        case .evento: return "Evento"
        case .servicio: return "Servicio"
        }
    }

    /// Nombre del SF Symbol que representa este tipo de evento.
    var simbolo: String {
        switch self {
        case .visita: return "person.2.fill"
        case .evento: return "party.popper.fill"
        case .servicio: return "wrench.and.screwdriver.fill"
        }
    }
}
