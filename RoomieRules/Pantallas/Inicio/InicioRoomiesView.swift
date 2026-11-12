import SwiftUI

/// Hoja para elegir con qué roomie ver la app y para los atajos de demostración.
struct InicioRoomiesView: View {
    @EnvironmentObject private var store: HogarStore
    @Environment(\.dismiss) private var dismiss

    @State private var confirmandoRestablecer = false

    var body: some View {
        NavigationStack {
            List {
                seccionRoomies
                seccionDemo
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Roomies")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Listo") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var seccionRoomies: some View {
        Section {
            ForEach(store.usuarios) { usuario in
                Button {
                    store.cambiarUsuarioActual(a: usuario.id)
                } label: {
                    filaRoomie(usuario)
                }
                .buttonStyle(.plain)
            }
        } header: {
            Text("Ver la app como")
        } footer: {
            Text("Esta versión simula a los roomies del depa en un solo teléfono. Cambia de roomie para ver sus tareas y su balance.")
        }
    }

    private func filaRoomie(_ usuario: Usuario) -> some View {
        HStack(spacing: 12) {
            AvatarView(usuario: usuario, tamano: 36)
            Text(usuario.nombre)
                .font(Tipografia.cuerpo)
                .foregroundStyle(Tema.tinta)
            Spacer()
            if store.esUsuarioActual(usuario.id) {
                Image(systemName: "checkmark")
                    .font(Tipografia.cuerpoFuerte)
                    .foregroundStyle(Tema.verde)
            }
        }
        .contentShape(Rectangle())
    }

    private var seccionDemo: some View {
        Section {
            Button {
                store.simularCambioDeSemana()
            } label: {
                Label("Simular cambio de semana", systemImage: "arrow.triangle.2.circlepath")
            }
            Button(role: .destructive) {
                confirmandoRestablecer = true
            } label: {
                Text("Restablecer datos de ejemplo")
            }
            .confirmationDialog("¿Restablecer los datos de ejemplo?",
                                isPresented: $confirmandoRestablecer,
                                titleVisibility: .visible) {
                Button("Restablecer", role: .destructive) {
                    store.restablecerDatosDeEjemplo()
                }
                Button("Cancelar", role: .cancel) {}
            } message: {
                Text("Se borrará todo lo que hayas hecho.")
            }
        } header: {
            Text("Demostración")
        } footer: {
            Text("Simular el cambio de semana rota las tareas como si ya fuera lunes.")
        }
    }
}

#Preview {
    InicioRoomiesView()
        .environmentObject(HogarStore.deEjemplo())
}
