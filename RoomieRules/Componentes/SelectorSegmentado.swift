import SwiftUI

/// Selector segmentado propio: pista gris con la opción elegida como pastilla blanca.
/// Sirve para "Historial | Quién le debe a quién" y para "Partes iguales | Montos exactos · pronto".
struct SelectorSegmentado<Opcion: Hashable>: View {
    /// Opciones en el orden en que se muestran.
    let opciones: [Opcion]
    /// Opción elegida actualmente.
    @Binding var seleccion: Opcion
    /// Opciones que se ven tenues y no responden al toque.
    let deshabilitadas: [Opcion]
    /// Convierte una opción en el texto que se muestra (puede partirse en dos líneas).
    let titulo: (Opcion) -> String

    @Namespace private var espacioPastilla

    init(opciones: [Opcion],
         seleccion: Binding<Opcion>,
         deshabilitadas: [Opcion] = [],
         titulo: @escaping (Opcion) -> String) {
        self.opciones = opciones
        self._seleccion = seleccion
        self.deshabilitadas = deshabilitadas
        self.titulo = titulo
    }

    var body: some View {
        HStack(spacing: 4) {
            ForEach(opciones, id: \.self) { opcion in
                segmento(opcion)
            }
        }
        .padding(4)
        .fixedSize(horizontal: false, vertical: true)
        .background(
            RoundedRectangle(cornerRadius: Tema.radioControl, style: .continuous)
                .fill(Tema.pista)
        )
    }

    private func segmento(_ opcion: Opcion) -> some View {
        let esElegida = (opcion == seleccion)
        let estaDeshabilitada = deshabilitadas.contains(opcion)
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                seleccion = opcion
            }
        } label: {
            Text(titulo(opcion))
                .font(Tipografia.cuerpoFuerte)
                .foregroundStyle(esElegida ? Tema.tinta : Tema.tintaSecundaria)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 8)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    ZStack {
                        if esElegida {
                            RoundedRectangle(cornerRadius: Tema.radioControl - 3, style: .continuous)
                                .fill(Tema.tarjeta)
                                .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
                                .matchedGeometryEffect(id: "pastilla", in: espacioPastilla)
                        }
                    }
                )
        }
        .buttonStyle(.plain)
        .disabled(estaDeshabilitada)
        .opacity(estaDeshabilitada ? 0.45 : 1)
        .accessibilityAddTraits(esElegida ? AccessibilityTraits.isSelected : AccessibilityTraits())
    }
}

#Preview {
    SelectorSegmentadoPreview()
}

private struct SelectorSegmentadoPreview: View {
    @State private var seccion = "historial"
    @State private var reparto = "iguales"

    var body: some View {
        VStack(spacing: 24) {
            SelectorSegmentado(
                opciones: ["historial", "deudas"],
                seleccion: $seccion,
                titulo: { $0 == "historial" ? "Historial" : "Quién le debe a quién" }
            )
            SelectorSegmentado(
                opciones: ["iguales", "exactos"],
                seleccion: $reparto,
                deshabilitadas: ["exactos"],
                titulo: { $0 == "iguales" ? "Partes iguales" : "Montos exactos · pronto" }
            )
        }
        .padding(Tema.margen)
        .background(Tema.fondo)
    }
}
