import SwiftUI

/// Tarjeta de arriba de Tareas: "1 de 5 listas" y una barra con el avance de la semana.
struct TareasProgresoCard: View {
    @EnvironmentObject private var store: HogarStore

    /// Texto principal, armado aparte para mantener el cuerpo corto.
    private var textoAvance: String {
        "\(store.tareasCompletadas) de \(store.tareas.count) listas"
    }

    /// Proporción de tareas hechas (0 si no hay tareas).
    private var proporcion: Double {
        let total = store.tareas.count
        if total == 0 {
            return 0
        }
        return Double(store.tareasCompletadas) / Double(total)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(textoAvance)
                    .font(Tipografia.tituloTarjeta)
                    .fontWeight(.bold)
                    .foregroundStyle(Tema.tinta)
                Spacer(minLength: 8)
                Text("La rotación cambia el lunes")
                    .font(Tipografia.secundario)
                    .foregroundStyle(Tema.tintaSecundaria)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            barra
        }
        .tarjeta(relleno: 20)
        .accessibilityElement(children: .combine)
    }

    /// Barra: pista gris con el avance en verde; se anima al cambiar.
    private var barra: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Tema.pista)
                Capsule()
                    .fill(Tema.verde)
                    .frame(width: proxy.size.width * CGFloat(proporcion))
            }
        }
        .frame(height: 8)
        .animation(.easeInOut(duration: 0.3), value: proporcion)
    }
}

#Preview {
    TareasProgresoCard()
        .padding(Tema.margen)
        .background(Tema.fondo)
        .environmentObject(HogarStore.deEjemplo())
}
