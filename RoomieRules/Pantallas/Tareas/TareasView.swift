import SwiftUI

/// Pantalla Tareas: avance de la semana, responsables por área, palomear y mandar un Toque.
struct TareasView: View {
    @EnvironmentObject private var store: HogarStore
    /// Mensaje breve tipo toast ("Toque enviado a Sara").
    @State private var aviso: String?

    var body: some View {
        PantallaDesplazable {
            EncabezadoPantalla(subtitulo: Formato.rangoSemana(inicio: store.inicioSemana), titulo: "Tareas")
            TareasProgresoCard()
            seccionLista
            notaAlPie
        }
        .aviso($aviso)
    }

    // MARK: - Partes

    private var seccionLista: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("RESPONSABLES POR ÁREA")
                .font(Tipografia.etiqueta)
                .tracking(0.8)
                .foregroundStyle(Tema.tintaSecundaria)
                .padding(.bottom, 2)
            lista
        }
    }

    @ViewBuilder
    private var lista: some View {
        if store.tareas.isEmpty {
            EstadoVacio(simbolo: "checklist", titulo: "Sin tareas",
                        mensaje: "Todavía no hay tareas asignadas esta semana.")
                .tarjeta()
        } else {
            ForEach(store.tareasOrdenadas) { tarea in
                TareasFila(tarea: tarea, alDarToque: darToque)
            }
        }
    }

    private var notaAlPie: some View {
        Text("El Toque manda un recordatorio amistoso ya escrito, para que nadie tenga que cobrar la limpieza en persona.")
            .font(Tipografia.secundario)
            .foregroundStyle(Tema.tintaSecundaria)
            .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - Acciones

    /// Manda el Toque al store y, si se envió, muestra el aviso.
    private func darToque(_ tarea: Tarea) {
        if store.darToque(tarea) != nil {
            aviso = "Toque enviado a \(store.nombre(de: tarea.asignadoA)) 🔔"
        }
    }
}

#Preview {
    TareasView()
        .environmentObject(HogarStore.deEjemplo())
        .environmentObject(Navegacion())
}
