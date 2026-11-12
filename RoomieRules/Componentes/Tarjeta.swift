import SwiftUI

/// Estilo de tarjeta: fondo blanco, esquinas muy redondeadas y borde fino.
/// Ocupa todo el ancho disponible con el contenido alineado a la izquierda.
struct Tarjeta: ViewModifier {
    /// Espacio entre el borde de la tarjeta y su contenido.
    var relleno: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .padding(relleno)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: Tema.radioTarjeta, style: .continuous)
                    .fill(Tema.tarjeta)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Tema.radioTarjeta, style: .continuous)
                    .strokeBorder(Tema.borde, lineWidth: 1)
            )
    }
}

extension View {
    /// Envuelve la vista en una tarjeta blanca con borde.
    /// - Parameter relleno: espacio interior; 16 por defecto.
    func tarjeta(relleno: CGFloat = 16) -> some View {
        modifier(Tarjeta(relleno: relleno))
    }
}

#Preview {
    VStack(spacing: 16) {
        Text("Tarjeta normal")
            .tarjeta()
        Text("Tarjeta con más relleno")
            .tarjeta(relleno: 24)
    }
    .padding(Tema.margen)
    .background(Tema.fondo)
}
