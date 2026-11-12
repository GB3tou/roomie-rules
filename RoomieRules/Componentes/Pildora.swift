import SwiftUI

/// Etiqueta pequeña en cápsula, por ejemplo el día de vencimiento ("Viernes").
struct Pildora: View {
    /// Texto de la etiqueta.
    let texto: String
    /// Color de fondo de la cápsula.
    let fondo: Color
    /// Color del texto.
    let color: Color

    init(_ texto: String, fondo: Color = Tema.pista, color: Color = Tema.tinta) {
        self.texto = texto
        self.fondo = fondo
        self.color = color
    }

    var body: some View {
        Text(texto)
            .font(Tipografia.etiqueta)
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Capsule().fill(fondo))
    }
}

#Preview {
    HStack(spacing: 8) {
        Pildora("Viernes")
        Pildora("Atrasada", fondo: Tema.alertaSuave, color: Tema.alerta)
        Pildora("Hecha", fondo: Tema.verdeSuave, color: Tema.verde)
    }
    .padding()
    .background(Tema.fondo)
}
