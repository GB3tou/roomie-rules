import SwiftUI

/// Tarjeta de una tarea pendiente del usuario actual; la casilla la completa.
struct InicioTareaFila: View {
    @EnvironmentObject private var store: HogarStore

    let tarea: Tarea
    /// Se llama después de completarla (la pantalla muestra el aviso).
    let alCompletar: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Button {
                completar()
            } label: {
                CasillaCircular(estado: .pendiente)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Completar \(tarea.titulo)")

            VStack(alignment: .leading, spacing: 2) {
                Text(tarea.titulo)
                    .font(Tipografia.tituloTarjeta)
                    .foregroundStyle(Tema.tinta)
                Text(subtitulo)
                    .font(Tipografia.cuerpo)
                    .foregroundStyle(colorSubtitulo)
            }
            Spacer(minLength: 8)
            Pildora(Formato.etiquetaVencimiento(de: tarea, hoy: store.ahora))
        }
        .tarjeta()
    }

    private func completar() {
        withAnimation {
            store.alternarCompletada(tarea)
        }
        alCompletar()
    }

    private var subtitulo: String {
        "\(tarea.area.nombre) · \(Formato.vencimientoLargo(de: tarea, hoy: store.ahora))"
    }

    private var colorSubtitulo: Color {
        tarea.estaAtrasada(hoy: store.ahora) ? Tema.alerta : Tema.tintaSecundaria
    }
}

#Preview {
    let store = HogarStore.deEjemplo()
    return VStack {
        ForEach(store.misTareasPendientes) { tarea in
            InicioTareaFila(tarea: tarea) {}
        }
    }
    .padding(Tema.margen)
    .background(Tema.fondo)
    .environmentObject(store)
}
