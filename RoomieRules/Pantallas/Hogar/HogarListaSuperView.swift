import SwiftUI

/// Lista del súper colaborativa: campo para agregar, tarjeta con los artículos
/// y botón para quitar los ya comprados.
struct HogarListaSuperView: View {
    @EnvironmentObject private var store: HogarStore
    @EnvironmentObject private var navegacion: Navegacion

    @State private var nuevoArticulo = ""
    @FocusState private var campoEnfocado: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TituloSeccion("Lista del súper") {
                Text("\(store.articulosPorComprar) por comprar")
                    .font(Tipografia.secundario)
                    .foregroundStyle(Tema.tintaSecundaria)
            }
            filaParaAgregar
            tarjetaDeArticulos
            botonQuitarComprados
        }
        .onAppear {
            atenderFoco()
        }
        .onChange(of: navegacion.enfocarNuevoArticulo) { _, nuevo in
            if nuevo {
                atenderFoco()
            }
        }
    }

    // MARK: - Agregar

    private var filaParaAgregar: some View {
        HStack(spacing: 12) {
            TextField("Agregar artículo...", text: $nuevoArticulo)
                .font(Tipografia.cuerpo)
                .focused($campoEnfocado)
                .submitLabel(.done)
                .onSubmit {
                    agregar()
                }
                .padding(14)
                .frame(minHeight: 52)
                .background(campoFondo)
                .overlay(campoBorde)
            Button {
                agregar()
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Color.white)
                    .frame(width: 52, height: 52)
                    .background(
                        RoundedRectangle(cornerRadius: Tema.radioControl, style: .continuous)
                            .fill(Tema.verde)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Agregar artículo")
        }
    }

    private var campoFondo: some View {
        RoundedRectangle(cornerRadius: Tema.radioControl, style: .continuous)
            .fill(Color.white)
    }

    private var campoBorde: some View {
        RoundedRectangle(cornerRadius: Tema.radioControl, style: .continuous)
            .strokeBorder(Tema.borde, lineWidth: 1)
    }

    private func agregar() {
        store.agregarArticulo(nuevoArticulo)
        nuevoArticulo = ""
    }

    // MARK: - Artículos

    @ViewBuilder
    private var tarjetaDeArticulos: some View {
        let articulos = store.articulosOrdenados
        if articulos.isEmpty {
            EstadoVacio(simbolo: "cart",
                        titulo: "La lista está vacía",
                        mensaje: "Agrega lo que haga falta en el depa.")
                .tarjeta(relleno: 0)
        } else {
            VStack(spacing: 0) {
                ForEach(articulos) { articulo in
                    HogarArticuloFila(articulo: articulo)
                    if articulo.id != articulos.last?.id {
                        Divider()
                    }
                }
            }
            .padding(.horizontal, 16)
            .tarjeta(relleno: 0)
        }
    }

    @ViewBuilder
    private var botonQuitarComprados: some View {
        if store.articulos.contains(where: { $0.fueComprado }) {
            HStack {
                Spacer()
                Button("Quitar comprados") {
                    withAnimation {
                        store.limpiarComprados()
                    }
                }
                .font(Tipografia.secundario)
                .foregroundStyle(Tema.verde)
            }
        }
    }

    // MARK: - Foco desde Inicio

    /// Si Inicio mandó aquí con "Agregar", pone el cursor en el campo.
    /// El retraso deja que termine el cambio de pestaña antes de enfocar.
    private func atenderFoco() {
        guard navegacion.enfocarNuevoArticulo else { return }
        navegacion.enfocarNuevoArticulo = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            campoEnfocado = true
        }
    }
}

#Preview {
    ScrollView {
        HogarListaSuperView()
            .padding(Tema.margen)
    }
    .background(Tema.fondo)
    .environmentObject(HogarStore.deEjemplo())
    .environmentObject(Navegacion())
}
