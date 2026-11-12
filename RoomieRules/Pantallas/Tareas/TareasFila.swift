import SwiftUI

/// Una tarjeta de la lista: casilla, título, responsable con vencimiento y, si toca, el botón Toque.
struct TareasFila: View {
    @EnvironmentObject private var store: HogarStore

    /// Tarea que se dibuja.
    let tarea: Tarea
    /// Se llama cuando se pulsa "Toque" en esta fila.
    let alDarToque: (Tarea) -> Void

    private var atrasada: Bool {
        tarea.estaAtrasada(hoy: store.ahora)
    }

    /// "Tú · Baño · vie 13" y, si va tarde, " · atrasada".
    private var textoDetalle: String {
        let nombre = store.nombreOTu(tarea.asignadoA)
        let vence = Formato.vencimientoCorto(de: tarea, hoy: store.ahora)
        var texto = "\(nombre) · \(tarea.area.nombreCorto) · \(vence)"
        if atrasada {
            texto += " · atrasada"
        }
        return texto
    }

    private var colorDetalle: Color {
        atrasada ? Tema.alerta : Tema.tintaSecundaria
    }

    private var colorTitulo: Color {
        tarea.completada ? Tema.tintaSecundaria : Tema.tinta
    }

    private var mostrarToque: Bool {
        !tarea.completada && !store.puedeCompletar(tarea)
    }

    var body: some View {
        HStack(spacing: 14) {
            casilla
            textos
            Spacer(minLength: 8)
            if mostrarToque {
                TareasBotonToque(tarea: tarea, alDarToque: alDarToque)
            }
        }
        .tarjeta()
    }

    // MARK: - Partes

    @ViewBuilder
    private var casilla: some View {
        if store.puedeCompletar(tarea) {
            Button {
                withAnimation {
                    store.alternarCompletada(tarea)
                }
            } label: {
                CasillaCircular(estado: tarea.completada ? .completada : .pendiente, tamano: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(tarea.completada ? "Marcar como pendiente" : "Marcar como hecha")
        } else {
            CasillaCircular(estado: tarea.completada ? .completada : .ajena, tamano: 44)
        }
    }

    private var textos: some View {
        VStack(alignment: .leading, spacing: 6) {
            titulo
            detalle
        }
    }

    private var titulo: some View {
        Text(tarea.titulo)
            .font(Tipografia.tituloTarjeta)
            .strikethrough(tarea.completada)
            .foregroundStyle(colorTitulo)
            .lineLimit(2)
    }

    private var detalle: some View {
        HStack(spacing: 6) {
            if let responsable = store.usuario(tarea.asignadoA) {
                AvatarView(usuario: responsable, tamano: 22)
            }
            Text(textoDetalle)
                .font(Tipografia.secundario)
                .foregroundStyle(colorDetalle)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }
}

#Preview {
    let store = HogarStore.deEjemplo()
    return VStack(spacing: 12) {
        ForEach(store.tareasOrdenadas) { tarea in
            TareasFila(tarea: tarea, alDarToque: { _ in })
        }
    }
    .padding(Tema.margen)
    .background(Tema.fondo)
    .environmentObject(store)
}
