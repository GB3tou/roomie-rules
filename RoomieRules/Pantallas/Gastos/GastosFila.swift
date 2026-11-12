import SwiftUI

/// Tarjeta de un gasto en el historial: ícono, descripción, quién pagó y, a la derecha,
/// el total y "Tu parte". Con un toque largo se puede eliminar.
struct GastosFila: View {
    @EnvironmentObject private var store: HogarStore

    /// Gasto (o pago entre roomies) que se muestra.
    let gasto: Gasto

    /// Inicializador explícito: así no depende de las reglas del inicializador automático
    /// con propiedades `private`.
    init(gasto: Gasto) {
        self.gasto = gasto
    }

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            IconoGasto(gasto: gasto, tamano: 48)
            textos
            Spacer(minLength: 8)
            montos
        }
        .accessibilityElement(children: .combine)
        .tarjeta()
        .contentShape(.contextMenuPreview, RoundedRectangle(cornerRadius: Tema.radioTarjeta, style: .continuous))
        .contextMenu {
            Button(role: .destructive) {
                store.eliminarGasto(gasto)
            } label: {
                Label("Eliminar", systemImage: "trash")
            }
        }
    }

    /// Descripción y la línea gris de detalle.
    private var textos: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(gasto.descripcion)
                .font(Tipografia.tituloTarjeta)
                .foregroundStyle(Tema.tinta)
                .lineLimit(2)
            Text(detalle)
                .font(Tipografia.secundario)
                .foregroundStyle(Tema.tintaSecundaria)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// Total del gasto y, debajo, la parte del usuario actual.
    private var montos: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(Formato.dinero(gasto.montoTotal))
                .font(Tipografia.cifra)
                .foregroundStyle(Tema.tinta)
            if let parte = textoMiParte {
                Text(parte)
                    .font(Tipografia.secundario)
                    .foregroundStyle(Tema.tintaSecundaria)
            }
        }
        // Las cifras nunca se cortan: si falta espacio, se acomoda la descripción.
        .fixedSize()
    }

    /// "Pagó tú · entre 4 · 10 nov" o, si es un pago entre roomies, "Pago entre roomies · 10 nov".
    private var detalle: String {
        let fecha = Formato.diaYMes(gasto.fecha)
        if gasto.esLiquidacion {
            return "Pago entre roomies · \(fecha)"
        }
        let personas = gasto.divididoEntre.count
        return "Pagó \(quienPago) · entre \(personas) · \(fecha)"
    }

    /// "tú" (en minúscula, como en el diseño) si pagó el usuario actual; si no, el nombre.
    private var quienPago: String {
        if store.esUsuarioActual(gasto.pagadoPor) {
            return "tú"
        }
        return store.nombre(de: gasto.pagadoPor)
    }

    /// "Tu parte $210", "No participas" o `nil` en los pagos entre roomies.
    private var textoMiParte: String? {
        if gasto.esLiquidacion {
            return nil
        }
        let parte = store.miParte(en: gasto)
        if parte < 0.005 {
            return "No participas"
        }
        return "Tu parte \(Formato.dinero(parte))"
    }
}

#Preview {
    GastosFilaPreview()
        .environmentObject(HogarStore.deEjemplo())
        .environmentObject(Navegacion())
}

/// Vista previa con los dos gastos más recientes de los datos de ejemplo.
private struct GastosFilaPreview: View {
    @EnvironmentObject private var store: HogarStore

    var body: some View {
        PantallaDesplazable {
            ForEach(store.gastosOrdenados.prefix(2)) { gasto in
                GastosFila(gasto: gasto)
            }
        }
    }
}
