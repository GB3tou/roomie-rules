import SwiftUI

/// Pantalla Inicio (dashboard): balance, tareas de la semana y lo que pasa en casa.
struct InicioView: View {
    @EnvironmentObject private var store: HogarStore
    @EnvironmentObject private var navegacion: Navegacion

    @State private var aviso: String?
    @State private var mostrandoRoomies = false

    var body: some View {
        PantallaDesplazable {
            encabezado
            InicioTarjetaBalance()
            seccionTareas
            seccionActividad
        }
        .aviso($aviso)
        .sheet(isPresented: $mostrandoRoomies) {
            InicioRoomiesView()
                .environmentObject(store)
        }
    }

    private var subtitulo: String {
        "\(store.nombreHogar) · \(store.usuarios.count) roomies"
    }

    private var tituloSaludo: String {
        "Hola, \(store.usuarioActual.nombre)"
    }

    private var encabezado: some View {
        EncabezadoPantalla(subtitulo: subtitulo, titulo: tituloSaludo) {
            Button {
                mostrandoRoomies = true
            } label: {
                GrupoAvataresView(usuarios: store.usuarios)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Roomies del depa")
        }
    }

    private var seccionTareas: some View {
        VStack(alignment: .leading, spacing: 12) {
            TituloSeccion("Tus tareas esta semana") {
                Button("Ver todas") {
                    navegacion.verTareas()
                }
                .font(Tipografia.cuerpoFuerte)
                .foregroundStyle(Tema.verde)
            }
            listaDeTareas
        }
    }

    @ViewBuilder
    private var listaDeTareas: some View {
        let pendientes = store.misTareasPendientes
        if pendientes.isEmpty {
            EstadoVacio(simbolo: "checkmark.circle", titulo: "¡Todo listo!",
                        mensaje: "No tienes tareas pendientes esta semana.")
                .tarjeta()
        } else {
            ForEach(pendientes) { tarea in
                InicioTareaFila(tarea: tarea) {
                    aviso = "¡Tarea completada! 🎉"
                }
            }
        }
    }

    private var seccionActividad: some View {
        VStack(alignment: .leading, spacing: 12) {
            TituloSeccion("Lo que pasa en casa")
            listaDeActividad
        }
    }

    @ViewBuilder
    private var listaDeActividad: some View {
        let recientes = Array(store.actividadesRecientes.prefix(5))
        if recientes.isEmpty {
            EstadoVacio(simbolo: "bubble.left.and.bubble.right", titulo: "Todo tranquilo",
                        mensaje: "Aquí verás lo que vaya pasando en el depa.")
                .tarjeta()
        } else {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(recientes.enumerated()), id: \.element.id) { indice, item in
                    if indice > 0 {
                        Divider()
                    }
                    InicioActividadFila(actividad: item)
                }
            }
            .tarjeta()
        }
    }
}

#Preview {
    InicioView()
        .environmentObject(HogarStore.deEjemplo())
        .environmentObject(Navegacion())
}
