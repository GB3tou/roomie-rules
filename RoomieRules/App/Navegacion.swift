import Combine
import Foundation

/// Las cuatro pestañas de la app.
enum TabPrincipal: Hashable {
    case inicio, tareas, gastos, hogar
}

/// Las dos secciones de la pantalla de Gastos (lo que elige el selector de arriba).
enum SeccionGastos: String, CaseIterable, Identifiable {
    case historial, deudas

    /// Identificador para usar la sección en un `ForEach`.
    var id: String {
        rawValue
    }

    /// Texto que se muestra en el selector.
    var titulo: String {
        switch self {
        case .historial: return "Historial"
        case .deudas: return "Quién le debe a quién"
        }
    }
}

/// Navegación entre pestañas: en qué pestaña está la app y a dónde saltan los atajos de Inicio.
///
/// Se comparte con `.environmentObject`, igual que `HogarStore`. Así una pantalla puede mandar
/// a otra (por ejemplo, de la tarjeta de balance a "Quién le debe a quién") sin conocerla.
final class Navegacion: ObservableObject {
    /// Pestaña que se está viendo.
    @Published var tab: TabPrincipal = .inicio
    /// Sección elegida en la pantalla de Gastos.
    @Published var seccionGastos: SeccionGastos = .historial
    /// `true` cuando la pantalla de Hogar debe poner el cursor en "Agregar artículo…".
    /// Hogar lo regresa a `false` en cuanto lo atiende.
    @Published var enfocarNuevoArticulo: Bool = false

    /// Empieza en Inicio, con el historial de gastos y sin pedir el cursor.
    init() {}

    /// Va a la pestaña Tareas.
    func verTareas() {
        tab = .tareas
    }

    /// Va a la pestaña Gastos, directo a la sección "Quién le debe a quién".
    func verDeudas() {
        seccionGastos = .deudas
        tab = .gastos
    }

    /// Va a la pestaña Hogar y pide el cursor en "Agregar artículo…" de la lista del súper.
    func verListaDelSuper() {
        enfocarNuevoArticulo = true
        tab = .hogar
    }
}
