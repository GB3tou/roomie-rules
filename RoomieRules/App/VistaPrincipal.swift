import SwiftUI

/// La pantalla raíz: una barra con las cuatro pestañas de la app (Inicio, Tareas, Gastos y Hogar).
///
/// La pestaña elegida vive en `Navegacion`, para que cualquier pantalla pueda mandar a otra.
struct VistaPrincipal: View {
    @EnvironmentObject private var navegacion: Navegacion

    var body: some View {
        TabView(selection: $navegacion.tab) {
            InicioView()
                .pestana("Inicio", simbolo: "house", tab: .inicio)
            TareasView()
                .pestana("Tareas", simbolo: "checkmark.square", tab: .tareas)
            GastosView()
                .pestana("Gastos", simbolo: "creditcard", tab: .gastos)
            HogarView()
                .pestana("Hogar", simbolo: "sofa", tab: .hogar)
        }
    }
}

private extension View {
    /// Convierte una pantalla en pestaña: le pone ícono, título y la etiqueta con la que
    /// `TabView(selection:)` sabe cuál es. Se usa `.tabItem` + `.tag` (y no `Tab(...)`,
    /// que es de iOS 18) para que compile con iOS 17.
    func pestana(_ titulo: String, simbolo: String, tab: TabPrincipal) -> some View {
        self
            // El fondo de las pantallas es crema; la barra de pestañas va en blanco y siempre
            // visible, como en el diseño (por defecto se vuelve transparente al llegar al final).
            .toolbarBackground(.visible, for: .tabBar)
            .toolbarBackground(Color.white, for: .tabBar)
            .tabItem {
                Label(titulo, systemImage: simbolo)
            }
            .tag(tab)
    }
}

#Preview {
    VistaPrincipal()
        .environmentObject(HogarStore.deEjemplo())
        .environmentObject(Navegacion())
}
