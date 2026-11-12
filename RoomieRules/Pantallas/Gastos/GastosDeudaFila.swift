import SwiftUI

/// Tarjeta de una deuda: quién le debe a quién, cuánto, y el botón para marcarla
/// como pagada (pide confirmación antes de registrar el pago).
struct GastosDeudaFila: View {
    @EnvironmentObject private var store: HogarStore

    /// Deuda simplificada que se muestra.
    let transferencia: Transferencia
    /// Se llama después de registrar el pago.
    let alSaldar: () -> Void

    /// `true` mientras se muestra la pregunta "¿… ya pagó …?".
    @State private var confirmando: Bool = false

    /// - Parameters:
    ///   - transferencia: deuda que se muestra.
    ///   - alSaldar: se llama después de registrar el pago.
    init(transferencia: Transferencia, alSaldar: @escaping () -> Void) {
        self.transferencia = transferencia
        self.alSaldar = alSaldar
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                avatares
                Spacer(minLength: 8)
                Text(Formato.dinero(transferencia.monto))
                    .font(Tipografia.cifra)
                    .foregroundStyle(colorMonto)
                    .fixedSize()
            }
            Text(descripcion)
                .font(Tipografia.cuerpoFuerte)
                .foregroundStyle(Tema.tinta)
                .fixedSize(horizontal: false, vertical: true)
            Button("Marcar como pagada") {
                confirmando = true
            }
            .buttonStyle(EstiloBotonContorno())
        }
        .tarjeta()
        .confirmationDialog(tituloConfirmacion, isPresented: $confirmando, titleVisibility: .visible) {
            Button("Sí, ya se pagó") {
                store.liquidar(transferencia)
                alSaldar()
            }
            Button("Cancelar", role: .cancel) {}
        }
    }

    /// Avatar de quien debe → avatar de quien cobra.
    private var avatares: some View {
        HStack(spacing: 8) {
            avatar(transferencia.de)
            Image(systemName: "arrow.right")
                .font(Tipografia.etiqueta)
                .foregroundStyle(Tema.tintaTerciaria)
                .accessibilityHidden(true)
            avatar(transferencia.para)
        }
    }

    /// Avatar del roomie con ese ID (nada si ya no existe).
    @ViewBuilder
    private func avatar(_ id: UUID) -> some View {
        if let usuario = store.usuario(id) {
            AvatarView(usuario: usuario, tamano: 36)
        }
    }

    /// "Le debes a Roberto", "Sara te debe" o "Sara le debe a Roberto".
    private var descripcion: String {
        let deudor = transferencia.de
        let acreedor = transferencia.para
        if store.esUsuarioActual(deudor) {
            return "Le debes a \(store.nombre(de: acreedor))"
        }
        if store.esUsuarioActual(acreedor) {
            return "\(store.nombre(de: deudor)) te debe"
        }
        return "\(store.nombre(de: deudor)) le debe a \(store.nombre(de: acreedor))"
    }

    /// Rojo si yo debo, verde si me deben, tinta normal si no participo.
    private var colorMonto: Color {
        if store.esUsuarioActual(transferencia.de) {
            return Tema.alerta
        }
        if store.esUsuarioActual(transferencia.para) {
            return Tema.verde
        }
        return Tema.tinta
    }

    /// "¿Sara ya pagó $50 a Roberto?"
    private var tituloConfirmacion: String {
        let deudor = store.nombre(de: transferencia.de)
        let acreedor = store.nombre(de: transferencia.para)
        let monto = Formato.dinero(transferencia.monto)
        return "¿\(deudor) ya pagó \(monto) a \(acreedor)?"
    }
}

#Preview {
    GastosDeudaFilaPreview()
        .environmentObject(HogarStore.deEjemplo())
        .environmentObject(Navegacion())
}

/// Vista previa con las deudas de los datos de ejemplo.
private struct GastosDeudaFilaPreview: View {
    @EnvironmentObject private var store: HogarStore

    var body: some View {
        PantallaDesplazable {
            ForEach(store.transferencias) { transferencia in
                GastosDeudaFila(transferencia: transferencia, alSaldar: {})
            }
        }
    }
}
