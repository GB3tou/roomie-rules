import SwiftUI

/// Casilla cuadrada redondeada (lista del súper). Solo dibuja; el botón lo pone quien la usa.
struct CasillaCuadrada: View {
    /// `true` = relleno verde con palomita; `false` = solo borde gris.
    let marcada: Bool
    /// Lado en puntos.
    var tamano: CGFloat = 26

    var body: some View {
        ZStack {
            if marcada {
                RoundedRectangle(cornerRadius: tamano * 0.3, style: .continuous)
                    .fill(Tema.verde)
                Image(systemName: "checkmark")
                    .font(.system(size: tamano * 0.5, weight: .bold))
                    .foregroundStyle(Color.white)
            } else {
                RoundedRectangle(cornerRadius: tamano * 0.3, style: .continuous)
                    .strokeBorder(Tema.tintaTerciaria, lineWidth: 2)
            }
        }
        .frame(width: tamano, height: tamano)
    }
}

#Preview {
    HStack(spacing: 16) {
        CasillaCuadrada(marcada: false)
        CasillaCuadrada(marcada: true)
    }
    .padding()
    .background(Tema.fondo)
}
