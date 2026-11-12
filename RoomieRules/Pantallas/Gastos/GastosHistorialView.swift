import SwiftUI

/// Sección "Historial": una tarjeta por gasto, del más reciente al más viejo
/// (incluye los pagos entre roomies).
struct GastosHistorialView: View {
    @EnvironmentObject private var store: HogarStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if gastos.isEmpty {
                EstadoVacio(simbolo: "creditcard",
                            titulo: "Aún no hay gastos",
                            mensaje: "Toca + para registrar el primero.")
                    .tarjeta()
            } else {
                ForEach(gastos) { gasto in
                    GastosFila(gasto: gasto)
                }
            }
        }
    }

    /// Gastos ya ordenados por el store.
    private var gastos: [Gasto] {
        store.gastosOrdenados
    }
}

#Preview {
    PantallaDesplazable {
        GastosHistorialView()
    }
    .environmentObject(HogarStore.deEjemplo())
    .environmentObject(Navegacion())
}
