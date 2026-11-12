import SwiftUI

/// Tarjeta "Dividir entre": una fila por roomie con su parte y una casilla.
/// Tocar la fila completa lo agrega o lo quita de la división.
struct NuevoGastoDivisionCard: View {
    @EnvironmentObject private var store: HogarStore

    /// Parte de cada participante en pesos, ya calculada por quien usa la tarjeta.
    let partes: [UUID: Double]
    /// Roomies que NO participan en el gasto.
    let excluidos: Set<UUID>
    /// Se llama con el ID del roomie cuya fila se tocó.
    let alAlternar: (UUID) -> Void

    /// - Parameters:
    ///   - partes: parte de cada participante en pesos.
    ///   - excluidos: roomies que no participan.
    ///   - alAlternar: se llama con el ID del roomie cuya fila se tocó.
    init(partes: [UUID: Double], excluidos: Set<UUID>, alAlternar: @escaping (UUID) -> Void) {
        self.partes = partes
        self.excluidos = excluidos
        self.alAlternar = alAlternar
    }

    var body: some View {
        VStack(spacing: 0) {
            ForEach(store.usuarios) { usuario in
                if usuario.id != primerID {
                    Divider()
                }
                fila(usuario)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
        .tarjeta(relleno: 0)
    }

    /// ID del primer roomie: antes de él no va separador.
    private var primerID: UUID? {
        store.usuarios.first?.id
    }

    /// Fila-botón de un roomie: avatar, nombre, su parte y la casilla.
    private func fila(_ usuario: Usuario) -> some View {
        let participa = !excluidos.contains(usuario.id)
        return Button {
            alAlternar(usuario.id)
        } label: {
            HStack(alignment: .center, spacing: 12) {
                AvatarView(usuario: usuario, tamano: 36)
                Text(store.nombreOTu(usuario.id))
                    .font(Tipografia.cuerpo)
                    .foregroundStyle(Tema.tinta)
                    .lineLimit(1)
                Spacer(minLength: 8)
                Text(textoParte(de: usuario.id, participa: participa))
                    .font(Tipografia.cuerpo)
                    .foregroundStyle(Tema.tintaSecundaria)
                    .monospacedDigit()
                CasillaCuadrada(marcada: participa, tamano: 26)
            }
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(participa ? AccessibilityTraits.isSelected : AccessibilityTraits())
    }

    /// "$210.00" si participa; "—" si no.
    private func textoParte(de id: UUID, participa: Bool) -> String {
        guard participa else { return "—" }
        return Formato.dineroExacto(partes[id] ?? 0)
    }
}

#Preview {
    NuevoGastoDivisionCardPreview()
        .environmentObject(HogarStore.deEjemplo())
        .environmentObject(Navegacion())
}

/// Vista previa con un reparto fijo de $840 entre todos menos el último roomie.
private struct NuevoGastoDivisionCardPreview: View {
    @EnvironmentObject private var store: HogarStore

    var body: some View {
        let ids = store.usuarios.map { $0.id }
        let excluidos: Set<UUID> = Set(ids.suffix(1))
        var partes: [UUID: Double] = [:]
        for id in ids.dropLast() {
            partes[id] = 280
        }
        return NuevoGastoDivisionCard(partes: partes, excluidos: excluidos, alAlternar: { _ in })
            .padding(Tema.margen)
    }
}
