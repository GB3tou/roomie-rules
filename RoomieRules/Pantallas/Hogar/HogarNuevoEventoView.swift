import SwiftUI

/// Hoja para apuntar una visita o evento en el calendario del depa.
struct HogarNuevoEventoView: View {
    @EnvironmentObject private var store: HogarStore
    @Environment(\.dismiss) private var dismiss

    @State private var titulo = ""
    @State private var tipo: TipoEvento = .visita
    @State private var fecha: Date

    /// - Parameter dia: día elegido en el calendario; la hora inicial es las 18:00.
    init(dia: Date) {
        let inicial = Calendar.roomie.date(bySettingHour: 18, minute: 0, second: 0, of: dia) ?? dia
        _fecha = State(initialValue: inicial)
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Ej. Visita de mis papás", text: $titulo)
                Picker("Tipo", selection: $tipo) {
                    ForEach(TipoEvento.allCases) { opcion in
                        Text(opcion.nombre).tag(opcion)
                    }
                }
                .pickerStyle(.segmented)
                DatePicker("Fecha y hora", selection: $fecha, displayedComponents: [.date, .hourAndMinute])
            }
            .navigationTitle("Nuevo evento")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        guardar()
                    }
                    .disabled(tituloVacio)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var tituloVacio: Bool {
        titulo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func guardar() {
        store.agregarEvento(titulo: titulo, fecha: fecha, tipo: tipo)
        dismiss()
    }
}

#Preview {
    HogarNuevoEventoView(dia: Date())
        .environmentObject(HogarStore.deEjemplo())
        .environmentObject(Navegacion())
}
