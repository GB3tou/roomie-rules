import SwiftUI

/// Título de una sección con algo opcional a la derecha ("Ver todas", "4 por comprar").
struct TituloSeccion<Accesorio: View>: View {
    /// Texto del título ("Tus tareas esta semana").
    let titulo: String
    private let accesorio: Accesorio

    /// - Parameter accesorio: vista alineada a la derecha (un botón de texto, un contador…).
    init(_ titulo: String, @ViewBuilder accesorio: () -> Accesorio) {
        self.titulo = titulo
        self.accesorio = accesorio()
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(titulo)
                .font(Tipografia.tituloSeccion)
                .foregroundStyle(Tema.tinta)
            Spacer(minLength: 8)
            accesorio
        }
    }
}

extension TituloSeccion where Accesorio == EmptyView {
    /// Título de sección sin nada a la derecha.
    init(_ titulo: String) {
        self.init(titulo) {
            EmptyView()
        }
    }
}

#Preview {
    VStack(spacing: 24) {
        TituloSeccion("Tus tareas esta semana") {
            Text("Ver todas")
                .font(Tipografia.cuerpoFuerte)
                .foregroundStyle(Tema.verde)
        }
        TituloSeccion("Lo que pasa en casa")
    }
    .padding(Tema.margen)
    .background(Tema.fondo)
}
