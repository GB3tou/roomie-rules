import SwiftUI

/// Tarjeta "Balance de cada quien": una fila por roomie con cuánto le deben o cuánto debe,
/// según los balances que calcula el store.
struct GastosBalancesCard: View {
    @EnvironmentObject private var store: HogarStore

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

    /// Avatar, nombre y, a la derecha, el balance con su etiqueta.
    private func fila(_ usuario: Usuario) -> some View {
        let balance = store.balance(de: usuario.id)
        return HStack(alignment: .center, spacing: 12) {
            AvatarView(usuario: usuario, tamano: 36)
            Text(store.nombreOTu(usuario.id))
                .font(Tipografia.cuerpoFuerte)
                .foregroundStyle(Tema.tinta)
                .lineLimit(1)
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 2) {
                Text(GastosBalancesCard.monto(balance))
                    .font(Tipografia.cuerpoFuerte)
                    .foregroundStyle(GastosBalancesCard.color(balance))
                Text(GastosBalancesCard.etiqueta(balance))
                    .font(Tipografia.secundario)
                    .foregroundStyle(Tema.tintaSecundaria)
            }
            .fixedSize()
        }
        .padding(.vertical, 12)
        .accessibilityElement(children: .combine)
    }

    // Se usa medio centavo como margen para que un residuo de `Double` no se vea como deuda.

    /// "+$50", "-$50" o "$0".
    private static func monto(_ balance: Double) -> String {
        if balance > 0.005 {
            return "+" + Formato.dinero(balance)
        }
        if balance < -0.005 {
            return "-" + Formato.dinero(abs(balance))
        }
        return "$0"
    }

    /// Verde si le deben, rojo si debe, gris si está a mano.
    private static func color(_ balance: Double) -> Color {
        if balance > 0.005 {
            return Tema.verde
        }
        if balance < -0.005 {
            return Tema.alerta
        }
        return Tema.tintaSecundaria
    }

    /// "le deben", "debe" o "a mano".
    private static func etiqueta(_ balance: Double) -> String {
        if balance > 0.005 {
            return "le deben"
        }
        if balance < -0.005 {
            return "debe"
        }
        return "a mano"
    }
}

#Preview {
    PantallaDesplazable {
        GastosBalancesCard()
    }
    .environmentObject(HogarStore.deEjemplo())
    .environmentObject(Navegacion())
}
