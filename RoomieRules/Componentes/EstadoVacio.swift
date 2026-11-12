import SwiftUI

/// Mensaje centrado para cuando una lista no tiene nada que mostrar.
struct EstadoVacio: View {
    /// SF Symbol grande de arriba.
    let simbolo: String
    /// Título corto ("Sin gastos todavía").
    let titulo: String
    /// Explicación o invitación a la acción.
    let mensaje: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: simbolo)
                .font(.system(size: 36, weight: .regular))
                .foregroundStyle(Tema.tintaTerciaria)
                .padding(.bottom, 4)
            Text(titulo)
                .font(Tipografia.tituloTarjeta)
                .foregroundStyle(Tema.tinta)
                .multilineTextAlignment(.center)
            Text(mensaje)
                .font(Tipografia.secundario)
                .foregroundStyle(Tema.tintaSecundaria)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .padding(.horizontal, 16)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    EstadoVacio(simbolo: "tray", titulo: "Sin gastos todavía", mensaje: "Toca el botón + para registrar el primero.")
        .background(Tema.fondo)
}
