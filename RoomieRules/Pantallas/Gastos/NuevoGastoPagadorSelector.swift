import SwiftUI

/// "¿Quién pagó?": una tarjetita por roomie, todas del mismo ancho;
/// la elegida lleva borde verde y fondo verde suave.
struct NuevoGastoPagadorSelector: View {
    @EnvironmentObject private var store: HogarStore

    /// ID del roomie elegido.
    let seleccionado: UUID
    /// Se llama con el ID del roomie que se tocó.
    let alElegir: (UUID) -> Void

    /// - Parameters:
    ///   - seleccionado: ID del roomie elegido.
    ///   - alElegir: se llama con el ID del roomie que se tocó.
    init(seleccionado: UUID, alElegir: @escaping (UUID) -> Void) {
        self.seleccionado = seleccionado
        self.alElegir = alElegir
    }

    var body: some View {
        HStack(spacing: 8) {
            ForEach(store.usuarios) { usuario in
                opcion(usuario)
            }
        }
    }

    /// Tarjetita de un roomie: avatar y nombre ("Tú" para el usuario actual).
    private func opcion(_ usuario: Usuario) -> some View {
        let elegido = usuario.id == seleccionado
        let forma = RoundedRectangle(cornerRadius: 16, style: .continuous)
        let fondo: Color = elegido ? Tema.verdeSuave.opacity(0.5) : Tema.tarjeta
        let borde: Color = elegido ? Tema.verde : Tema.borde
        let grosor: CGFloat = elegido ? 2 : 1
        return Button {
            alElegir(usuario.id)
        } label: {
            VStack(spacing: 8) {
                AvatarView(usuario: usuario, tamano: 44)
                Text(store.nombreOTu(usuario.id))
                    .font(Tipografia.cuerpoFuerte)
                    .foregroundStyle(Tema.tinta)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 4)
            .frame(maxWidth: .infinity)
            .background(forma.fill(fondo))
            .overlay(forma.strokeBorder(borde, lineWidth: grosor))
            .contentShape(forma)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(elegido ? AccessibilityTraits.isSelected : AccessibilityTraits())
    }
}

#Preview {
    NuevoGastoPagadorSelectorPreview()
        .environmentObject(HogarStore.deEjemplo())
        .environmentObject(Navegacion())
}

/// Vista previa que guarda la elección para poder probar el toque.
private struct NuevoGastoPagadorSelectorPreview: View {
    @EnvironmentObject private var store: HogarStore
    @State private var elegido: UUID?

    var body: some View {
        NuevoGastoPagadorSelector(seleccionado: elegido ?? store.usuarioActual.id) { id in
            elegido = id
        }
        .padding(Tema.margen)
    }
}
