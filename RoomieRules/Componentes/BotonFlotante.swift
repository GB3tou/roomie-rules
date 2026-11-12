import SwiftUI

/// Botón circular verde flotante (por ejemplo "+" para registrar un gasto).
struct BotonFlotante: View {
    /// Nombre del SF Symbol; "plus" por defecto.
    let simbolo: String
    /// Texto que lee VoiceOver, ya que el botón solo tiene ícono.
    let etiqueta: String
    /// Se ejecuta al tocar el botón.
    let accion: () -> Void

    init(simbolo: String = "plus", etiqueta: String = "Agregar", accion: @escaping () -> Void) {
        self.simbolo = simbolo
        self.etiqueta = etiqueta
        self.accion = accion
    }

    var body: some View {
        Button(action: accion) {
            Image(systemName: simbolo)
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(Color.white)
                .frame(width: 60, height: 60)
                .background(Circle().fill(Tema.verde))
                .shadow(color: Tema.verde.opacity(0.35), radius: 10, x: 0, y: 5)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(etiqueta)
    }
}

#Preview {
    BotonFlotante(accion: {})
        .padding(40)
        .background(Tema.fondo)
}
