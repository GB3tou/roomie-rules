import SwiftUI

/// Cuadrado redondeado de color pastel con un SF Symbol al centro (íconos de gastos y avisos).
struct IconoCuadrado: View {
    /// Nombre del SF Symbol.
    let simbolo: String
    /// Color de fondo (tono "Suave").
    let fondo: Color
    /// Color del símbolo (tono fuerte).
    let color: Color
    /// Lado del cuadrado en puntos.
    var tamano: CGFloat = 48

    var body: some View {
        RoundedRectangle(cornerRadius: tamano * 0.3, style: .continuous)
            .fill(fondo)
            .frame(width: tamano, height: tamano)
            .overlay(
                Image(systemName: simbolo)
                    .font(.system(size: tamano * 0.42, weight: .semibold))
                    .foregroundStyle(color)
            )
            .accessibilityHidden(true)
    }
}

#Preview {
    HStack(spacing: 12) {
        IconoCuadrado(simbolo: "bolt", fondo: Tema.amarilloSuave, color: Tema.amarillo)
        IconoCuadrado(simbolo: "wifi", fondo: Tema.moradoSuave, color: Tema.morado, tamano: 56)
    }
    .padding()
    .background(Tema.fondo)
}
