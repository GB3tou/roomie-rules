import SwiftUI

/// Un evento del calendario del depa: ícono por tipo, título y detalle.
/// Mantener presionado ofrece eliminarlo.
struct HogarEventoFila: View {
    @EnvironmentObject private var store: HogarStore

    let evento: Evento

    var body: some View {
        HStack(spacing: 12) {
            IconoCuadrado(simbolo: evento.tipo.simbolo, fondo: Tema.verdeSuave, color: Tema.verde, tamano: 40)
            VStack(alignment: .leading, spacing: 2) {
                Text(evento.titulo)
                    .font(Tipografia.cuerpoFuerte)
                    .foregroundStyle(Tema.tinta)
                Text(detalle)
                    .font(Tipografia.secundario)
                    .foregroundStyle(Tema.tintaSecundaria)
            }
            Spacer(minLength: 0)
        }
        .contentShape(Rectangle())
        .contextMenu {
            Button(role: .destructive) {
                store.eliminarEvento(evento)
            } label: {
                Label("Eliminar", systemImage: "trash")
            }
        }
    }

    private var detalle: String {
        let hora = Formato.hora(evento.fecha)
        let quien = store.nombreOTu(evento.creadoPor)
        return "\(hora) · \(evento.tipo.nombre) · \(quien)"
    }
}

#Preview {
    let store = HogarStore.deEjemplo()
    return VStack {
        if let primero = store.eventos.first {
            HogarEventoFila(evento: primero)
                .tarjeta()
        }
    }
    .padding(Tema.margen)
    .background(Tema.fondo)
    .environmentObject(store)
    .environmentObject(Navegacion())
}
