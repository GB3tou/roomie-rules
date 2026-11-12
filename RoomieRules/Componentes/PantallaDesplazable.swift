import SwiftUI

/// Contenedor de las 4 pantallas principales: scroll vertical sobre el fondo crema,
/// con márgenes laterales y separación de 24 pt entre bloques.
struct PantallaDesplazable<Contenido: View>: View {
    private let contenido: Contenido

    /// - Parameter contenido: bloques de la pantalla; se apilan alineados a la izquierda.
    init(@ViewBuilder contenido: () -> Contenido) {
        self.contenido = contenido()
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                contenido
            }
            .padding(.horizontal, Tema.margen)
            .padding(.top, 12)
            .padding(.bottom, 32)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Tema.fondo.ignoresSafeArea())
    }
}

#Preview {
    PantallaDesplazable {
        Text("Hola, Roberto")
            .font(Tipografia.tituloPantalla)
        Text("Contenido de ejemplo")
            .tarjeta()
    }
}
