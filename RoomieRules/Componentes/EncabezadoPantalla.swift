import SwiftUI

/// Encabezado de pantalla: subtítulo gris, título grande y un accesorio opcional a la derecha
/// (por ejemplo el grupo de avatares).
struct EncabezadoPantalla<Accesorio: View>: View {
    /// Línea gris pequeña de arriba ("Depa Mixcoac · 4 roomies").
    let subtitulo: String
    /// Título grande ("Hola, Roberto").
    let titulo: String
    private let accesorio: Accesorio

    /// - Parameter accesorio: vista alineada a la derecha del encabezado.
    init(subtitulo: String, titulo: String, @ViewBuilder accesorio: () -> Accesorio) {
        self.subtitulo = subtitulo
        self.titulo = titulo
        self.accesorio = accesorio()
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(subtitulo)
                    .font(Tipografia.subtituloPantalla)
                    .foregroundStyle(Tema.tintaSecundaria)
                Text(titulo)
                    .font(Tipografia.tituloPantalla)
                    .foregroundStyle(Tema.tinta)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            Spacer(minLength: 8)
            accesorio
        }
    }
}

extension EncabezadoPantalla where Accesorio == EmptyView {
    /// Encabezado sin nada a la derecha.
    init(subtitulo: String, titulo: String) {
        self.init(subtitulo: subtitulo, titulo: titulo) {
            EmptyView()
        }
    }
}

#Preview {
    VStack(spacing: 24) {
        EncabezadoPantalla(subtitulo: "Depa Mixcoac · 4 roomies", titulo: "Hola, Roberto") {
            GrupoAvataresView(usuarios: [
                Usuario(nombre: "Roberto", colorAvatar: .verde),
                Usuario(nombre: "Sara", colorAvatar: .morado)
            ])
        }
        EncabezadoPantalla(subtitulo: "Semana del 9 al 15 de noviembre", titulo: "Tareas")
    }
    .padding(Tema.margen)
    .background(Tema.fondo)
}
