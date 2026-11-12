import SwiftUI

/// Una línea de "Lo que pasa en casa": avatar, qué pasó, cuándo y una acción opcional.
struct InicioActividadFila: View {
    @EnvironmentObject private var store: HogarStore
    @EnvironmentObject private var navegacion: Navegacion

    let actividad: Actividad

    var body: some View {
        HStack(spacing: 12) {
            if let usuario = store.usuario(actividad.usuarioID) {
                AvatarView(usuario: usuario, tamano: 44)
            }
            VStack(alignment: .leading, spacing: 2) {
                textoPrincipal
                    .font(Tipografia.cuerpo)
                    .foregroundStyle(Tema.tinta)
                Text(lineaSecundaria)
                    .font(Tipografia.secundario)
                    .foregroundStyle(Tema.tintaSecundaria)
            }
            Spacer(minLength: 8)
            if mostrarAgregar {
                Button("Agregar") {
                    navegacion.verListaDelSuper()
                }
                .font(Tipografia.cuerpoFuerte)
                .foregroundStyle(Tema.verde)
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 12)
    }

    private var textoPrincipal: Text {
        let nombre = Text(store.nombre(de: actividad.usuarioID)).fontWeight(.semibold)
        return Text("\(nombre) \(actividad.texto)")
    }

    /// "Tu parte $X" si la actividad es de un gasto donde me toca algo; si no, el detalle.
    private var detalle: String? {
        if let id = actividad.gastoID, let gasto = store.gasto(id), !gasto.esLiquidacion {
            let parte = store.miParte(en: gasto)
            if parte > 0 {
                return "Tu parte \(Formato.dinero(parte))"
            }
        }
        return actividad.detalle
    }

    private var lineaSecundaria: String {
        let tiempo = Formato.tiempoRelativo(actividad.fecha, ahora: store.ahora)
        guard let texto = detalle, !texto.isEmpty else { return tiempo }
        return "\(tiempo) · \(texto)"
    }

    private var mostrarAgregar: Bool {
        guard actividad.tipo == .modoCompras, let modo = store.modoCompras else { return false }
        return modo.activadoPor == actividad.usuarioID && !store.esUsuarioActual(actividad.usuarioID)
    }
}

#Preview {
    let store = HogarStore.deEjemplo()
    return VStack(spacing: 0) {
        ForEach(store.actividadesRecientes) { actividad in
            InicioActividadFila(actividad: actividad)
        }
    }
    .tarjeta()
    .padding(Tema.margen)
    .background(Tema.fondo)
    .environmentObject(store)
    .environmentObject(Navegacion())
}
