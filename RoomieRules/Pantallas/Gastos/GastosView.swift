import SwiftUI

/// Pestaña Gastos: historial de gastos y "Quién le debe a quién", con el botón flotante
/// que abre el formulario "Nuevo gasto". Todo se lee de `HogarStore`, así que al guardar
/// un gasto las deudas se recalculan solas.
struct GastosView: View {
    @EnvironmentObject private var store: HogarStore
    @EnvironmentObject private var navegacion: Navegacion

    /// `true` mientras se muestra la hoja "Nuevo gasto".
    @State private var mostrandoFormulario: Bool = false
    /// Mensaje breve que aparece abajo ("Gasto registrado ✅").
    @State private var aviso: String?

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            contenido
            BotonFlotante(simbolo: "plus", etiqueta: "Nuevo gasto") {
                mostrandoFormulario = true
            }
            .padding(.trailing, Tema.margen)
            .padding(.bottom, Tema.margen)
        }
        .sheet(isPresented: $mostrandoFormulario) {
            NuevoGastoView(alGuardar: { aviso = "Gasto registrado ✅" })
                .environmentObject(store)
        }
        .aviso($aviso)
    }

    /// Encabezado, selector de sección y la sección elegida.
    private var contenido: some View {
        PantallaDesplazable {
            EncabezadoPantalla(subtitulo: subtitulo, titulo: "Gastos")
            SelectorSegmentado(opciones: SeccionGastos.allCases, seleccion: $navegacion.seccionGastos) { seccion in
                seccion.titulo
            }
            seccionElegida
            // Espacio libre al final (24 de separación + 56) para que el botón flotante
            // no tape la última tarjeta.
            Color.clear
                .frame(height: 56)
                .accessibilityHidden(true)
        }
    }

    /// La sección que eligió el selector. La elección vive en `Navegacion` porque Inicio
    /// puede mandar directo a "Quién le debe a quién".
    @ViewBuilder
    private var seccionElegida: some View {
        switch navegacion.seccionGastos {
        case .historial:
            GastosHistorialView()
        case .deudas:
            GastosDeudasView(alSaldar: { aviso = "Deuda saldada ✅" })
        }
    }

    /// "Noviembre · $3,160 en total".
    private var subtitulo: String {
        let mes = Formato.mes(store.ahora)
        let total = Formato.dinero(store.totalDelMes)
        return "\(mes) · \(total) en total"
    }
}

#Preview {
    GastosView()
        .environmentObject(HogarStore.deEjemplo())
        .environmentObject(Navegacion())
}
