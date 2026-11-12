import SwiftUI

/// Chip en forma de cápsula que funciona como botón de selección (por ejemplo para elegir
/// quién paga o entre quiénes se divide un gasto).
struct ChipSeleccionable: View {
    /// Texto del chip.
    let titulo: String
    /// `true` = fondo oscuro con texto blanco; `false` = fondo blanco con borde.
    let seleccionado: Bool
    /// Se ejecuta al tocar el chip.
    let accion: () -> Void

    init(_ titulo: String, seleccionado: Bool, accion: @escaping () -> Void) {
        self.titulo = titulo
        self.seleccionado = seleccionado
        self.accion = accion
    }

    var body: some View {
        Button(action: accion) {
            Text(titulo)
                .font(Tipografia.etiqueta)
                .foregroundStyle(seleccionado ? Color.white : Tema.tinta)
                .padding(.horizontal, 16)
                .padding(.vertical, 9)
                .background(Capsule().fill(seleccionado ? Tema.tinta : Tema.tarjeta))
                .overlay(Capsule().strokeBorder(seleccionado ? Tema.tinta : Tema.borde, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(seleccionado ? AccessibilityTraits.isSelected : AccessibilityTraits())
    }
}

#Preview {
    HStack(spacing: 8) {
        ChipSeleccionable("Roberto", seleccionado: true, accion: {})
        ChipSeleccionable("Sara", seleccionado: false, accion: {})
        ChipSeleccionable("Ana", seleccionado: false, accion: {})
    }
    .padding()
    .background(Tema.fondo)
}
