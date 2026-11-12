import SwiftUI

/// Punto de entrada de la app: crea el estado compartido y lo reparte a todas las pantallas.
@main
struct RoomieRulesApp: App {
    /// Los datos del depa. `@StateObject` lo crea una sola vez y lo mantiene vivo mientras dure la app.
    @StateObject private var store = HogarStore()
    /// En qué pestaña está la app.
    @StateObject private var navegacion = Navegacion()
    /// Si la app está en primer plano, inactiva o en segundo plano.
    @Environment(\.scenePhase) private var fase

    /// Prepara las notificaciones antes de mostrar la primera pantalla.
    init() {
        // Para que los avisos (Toque, Modo Compras) se vean como banner aunque la app esté abierta.
        NotificadorLocal.compartido.configurar()
    }

    var body: some Scene {
        WindowGroup {
            VistaPrincipal()
                .environmentObject(store)
                .environmentObject(navegacion)
                // Español de México y semana que empieza en lunes, sin importar cómo esté el teléfono.
                .environment(\.locale, Locale.roomie)
                .environment(\.calendar, Calendar.roomie)
                // El diseño solo contempla modo claro.
                .preferredColorScheme(.light)
                .tint(Tema.verde)
                .onChange(of: fase) { _, nueva in
                    // Al volver a la app puede ser otro día u otra semana: las tareas se ponen al corriente.
                    if nueva == .active {
                        store.actualizarRotacionSiHaceFalta()
                    }
                }
        }
    }
}
