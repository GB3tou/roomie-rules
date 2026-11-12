import SwiftUI

/// Botón "Toque" de una tarea ajena; si ya se mandó uno hace poco muestra "Enviado".
struct TareasBotonToque: View {
    @EnvironmentObject private var store: HogarStore

    /// Tarea por la que se manda el recordatorio.
    let tarea: Tarea
    /// Se llama al tocar el botón; la pantalla decide qué hacer (mandar el Toque y avisar).
    let alDarToque: (Tarea) -> Void

    var body: some View {
        if store.toqueReciente(tarea) {
            enviado
        } else {
            boton
        }
    }

    private var enviado: some View {
        HStack(spacing: 4) {
            Image(systemName: "checkmark")
            Text("Enviado")
        }
        .font(Tipografia.etiqueta)
        .foregroundStyle(Tema.tintaSecundaria)
        .accessibilityElement(children: .combine)
    }

    private var boton: some View {
        Button {
            alDarToque(tarea)
        } label: {
            Label("Toque", systemImage: "bell")
        }
        .buttonStyle(EstiloBotonContorno())
    }
}

#Preview {
    let store = HogarStore.deEjemplo()
    return VStack(spacing: 12) {
        ForEach(store.tareas) { tarea in
            TareasBotonToque(tarea: tarea, alDarToque: { _ in })
        }
    }
    .padding()
    .background(Tema.fondo)
    .environmentObject(store)
}
