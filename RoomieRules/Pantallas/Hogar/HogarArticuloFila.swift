import SwiftUI

/// Una fila de la lista del súper: casilla, nombre y quién lo agregó.
/// Tocar la fila palomea o despalomea; mantener presionado ofrece eliminar.
struct HogarArticuloFila: View {
    @EnvironmentObject private var store: HogarStore

    let articulo: ArtSuper

    var body: some View {
        Button {
            withAnimation {
                store.alternarComprado(articulo)
            }
        } label: {
            contenido
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive) {
                store.eliminarArticulo(articulo)
            } label: {
                Label("Eliminar", systemImage: "trash")
            }
        }
    }

    private var contenido: some View {
        HStack(spacing: 14) {
            CasillaCuadrada(marcada: articulo.fueComprado)
            Text(articulo.nombre)
                .font(Tipografia.cuerpo)
                .strikethrough(articulo.fueComprado)
                .foregroundStyle(colorDelNombre)
            Spacer(minLength: 8)
            Text(store.nombreOTu(articulo.agregadoPor))
                .font(Tipografia.secundario)
                .foregroundStyle(Tema.tintaSecundaria)
        }
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }

    private var colorDelNombre: Color {
        articulo.fueComprado ? Tema.tintaSecundaria : Tema.tinta
    }
}

#Preview {
    let store = HogarStore.deEjemplo()
    return VStack {
        if let primero = store.articulosOrdenados.first {
            HogarArticuloFila(articulo: primero)
                .tarjeta()
        }
    }
    .padding(Tema.margen)
    .background(Tema.fondo)
    .environmentObject(store)
    .environmentObject(Navegacion())
}
