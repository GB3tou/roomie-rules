import SwiftUI

/// Sección "Quién le debe a quién": las deudas ya simplificadas por el store,
/// el balance de cada roomie y una nota que explica cómo se calcula.
struct GastosDeudasView: View {
    @EnvironmentObject private var store: HogarStore

    /// Se llama después de marcar una deuda como pagada (la pantalla muestra el aviso).
    let alSaldar: () -> Void

    /// - Parameter alSaldar: se llama después de registrar el pago de una deuda.
    init(alSaldar: @escaping () -> Void) {
        self.alSaldar = alSaldar
    }

    var body: some View {
        let lista = store.transferencias
        return VStack(alignment: .leading, spacing: 24) {
            bloqueDeudas(lista)
            VStack(alignment: .leading, spacing: 12) {
                TituloSeccion("Balance de cada quien")
                GastosBalancesCard()
            }
            Text("RoomieRules calcula el balance neto de cada quien y lo convierte en la menor cantidad de pagos posible, sin cobros en círculo.")
                .font(Tipografia.secundario)
                .foregroundStyle(Tema.tintaSecundaria)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// Las tarjetas de deuda o, si nadie le debe a nadie, el estado vacío.
    @ViewBuilder
    private func bloqueDeudas(_ lista: [Transferencia]) -> some View {
        if lista.isEmpty {
            EstadoVacio(simbolo: "checkmark.seal",
                        titulo: "Todos a mano",
                        mensaje: "Nadie le debe a nadie. ¡Así da gusto!")
                .tarjeta()
        } else {
            VStack(alignment: .leading, spacing: 12) {
                Text(GastosDeudasView.resumen(cantidad: lista.count))
                    .font(Tipografia.cuerpo)
                    .foregroundStyle(Tema.tintaSecundaria)
                ForEach(lista) { transferencia in
                    GastosDeudaFila(transferencia: transferencia, alSaldar: alSaldar)
                }
            }
        }
    }

    /// "Con 1 pago quedan todos a mano." / "Con 3 pagos quedan todos a mano."
    private static func resumen(cantidad: Int) -> String {
        let pagos = cantidad == 1 ? "pago" : "pagos"
        return "Con \(cantidad) \(pagos) quedan todos a mano."
    }
}

#Preview {
    PantallaDesplazable {
        GastosDeudasView(alSaldar: {})
    }
    .environmentObject(HogarStore.deEjemplo())
    .environmentObject(Navegacion())
}
