import SwiftUI

/// Pantalla Hogar: Modo Compras, lista del súper colaborativa y calendario del depa.
/// El aviso (toast) vive aquí y las sub-vistas lo disparan con un cierre.
struct HogarView: View {
    @State private var aviso: String? = nil

    var body: some View {
        PantallaDesplazable {
            EncabezadoPantalla(subtitulo: "Convivencia", titulo: "Hogar")
            HogarModoComprasCard(mostrarAviso: mostrarAviso)
            HogarListaSuperView()
            HogarCalendarioCard()
        }
        .aviso($aviso)
    }

    /// Muestra un mensaje breve abajo; el modificador `.aviso` lo borra solo.
    private func mostrarAviso(_ texto: String) {
        aviso = texto
    }
}

#Preview {
    HogarView()
        .environmentObject(HogarStore.deEjemplo())
        .environmentObject(Navegacion())
}
