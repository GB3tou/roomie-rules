import SwiftUI

/// Calendario del depa: semana navegable, eventos del día elegido y botón para agregar.
struct HogarCalendarioCard: View {
    @EnvironmentObject private var store: HogarStore

    @State private var diaSeleccionado: Date = Calendar.roomie.startOfDay(for: Date())
    @State private var mostrandoNuevoEvento = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TituloSeccion("Calendario del depa") {
                Text(Formato.mes(diaSeleccionado))
                    .font(Tipografia.secundario)
                    .foregroundStyle(Tema.tintaSecundaria)
            }
            VStack(alignment: .leading, spacing: 14) {
                cabeceraDeSemana
                filaDeDias
                Divider()
                listaDeEventos
                Button {
                    mostrandoNuevoEvento = true
                } label: {
                    Label("Agregar visita o evento", systemImage: "plus")
                }
                .buttonStyle(EstiloBotonContorno())
            }
            .tarjeta()
        }
        .onAppear {
            diaSeleccionado = Calendar.roomie.startOfDay(for: store.ahora)
        }
        .sheet(isPresented: $mostrandoNuevoEvento) {
            HogarNuevoEventoView(dia: diaSeleccionado)
                .environmentObject(store)
        }
    }

    // MARK: - Cabecera

    private var cabeceraDeSemana: some View {
        HStack {
            botonDeSemana(simbolo: "chevron.left", etiqueta: "Semana anterior", dias: -7)
            Spacer()
            Text(Formato.rangoSemana(inicio: diaSeleccionado))
                .font(Tipografia.cuerpoFuerte)
                .foregroundStyle(Tema.tinta)
                .multilineTextAlignment(.center)
            Spacer()
            botonDeSemana(simbolo: "chevron.right", etiqueta: "Semana siguiente", dias: 7)
        }
    }

    private func botonDeSemana(simbolo: String, etiqueta: String, dias: Int) -> some View {
        Button {
            diaSeleccionado = Calendar.roomie.sumar(dias: dias, a: diaSeleccionado)
        } label: {
            Image(systemName: simbolo)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Tema.tinta)
                .frame(width: 36, height: 36)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(etiqueta)
    }

    // MARK: - Días

    private var filaDeDias: some View {
        HStack(spacing: 4) {
            ForEach(Calendar.roomie.diasDeLaSemana(para: diaSeleccionado), id: \.self) { dia in
                botonDeDia(dia)
            }
        }
    }

    private func botonDeDia(_ dia: Date) -> some View {
        let seleccionado = Calendar.roomie.esMismoDia(dia, diaSeleccionado)
        let esHoy = Calendar.roomie.esMismoDia(dia, store.ahora)
        return Button {
            diaSeleccionado = dia
        } label: {
            celdaDeDia(dia, seleccionado: seleccionado, esHoy: esHoy)
        }
        .buttonStyle(.plain)
    }

    private func celdaDeDia(_ dia: Date, seleccionado: Bool, esHoy: Bool) -> some View {
        let colorEtiqueta: Color = seleccionado ? Color.white : Tema.tintaSecundaria
        let colorNumero: Color = seleccionado ? Color.white : Tema.tinta
        let colorPunto: Color = puntoColor(dia, seleccionado: seleccionado)
        let colorBorde: Color = (esHoy && !seleccionado) ? Tema.verde : Color.clear
        let fondo: Color = seleccionado ? Tema.verde : Color.clear
        let forma = RoundedRectangle(cornerRadius: 14, style: .continuous)
        return VStack(spacing: 4) {
            Text(Formato.diaSemanaAbreviado(dia))
                .font(Tipografia.etiqueta)
                .foregroundStyle(colorEtiqueta)
            Text(Formato.numeroDeDia(dia))
                .font(Tipografia.cuerpoFuerte)
                .foregroundStyle(colorNumero)
            Circle()
                .fill(colorPunto)
                .frame(width: 6, height: 6)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(forma.fill(fondo))
        .overlay(forma.strokeBorder(colorBorde, lineWidth: 1.5))
        .contentShape(Rectangle())
    }

    private func puntoColor(_ dia: Date, seleccionado: Bool) -> Color {
        guard store.hayEventos(en: dia) else { return Color.clear }
        return seleccionado ? Color.white : Tema.verde
    }

    // MARK: - Eventos del día

    @ViewBuilder
    private var listaDeEventos: some View {
        let eventos = store.eventos(en: diaSeleccionado)
        if eventos.isEmpty {
            Text("Nada apuntado para este día.")
                .font(Tipografia.secundario)
                .foregroundStyle(Tema.tintaSecundaria)
        } else {
            VStack(alignment: .leading, spacing: 14) {
                ForEach(eventos) { evento in
                    HogarEventoFila(evento: evento)
                }
            }
        }
    }
}

#Preview {
    ScrollView {
        HogarCalendarioCard()
            .padding(Tema.margen)
    }
    .background(Tema.fondo)
    .environmentObject(HogarStore.deEjemplo())
    .environmentObject(Navegacion())
}
