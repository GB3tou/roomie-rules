import SwiftUI

/// Bloque de Modo Compras: invita a activarlo, muestra que yo estoy de compras
/// o avisa que otro roomie está en el súper.
struct HogarModoComprasCard: View {
    @EnvironmentObject private var store: HogarStore

    /// Cierre para mostrar un aviso breve en la pantalla.
    let mostrarAviso: (String) -> Void

    @State private var pidiendoLugar = false
    @State private var lugar = ""

    var body: some View {
        VStack(spacing: 12) {
            if let modo = store.modoCompras {
                if store.estoyDeCompras {
                    tarjetaActiva(modo)
                } else {
                    avisoDeOtro(modo)
                    tarjetaInvitacion
                }
            } else {
                tarjetaInvitacion
            }
        }
        .alert("¿A qué súper vas?", isPresented: $pidiendoLugar) {
            TextField("Ej. Walmart Universidad", text: $lugar)
            Button("Activar") {
                activar()
            }
            Button("Cancelar", role: .cancel) { }
        } message: {
            Text("Es opcional. Tus roomies verán a dónde fuiste.")
        }
    }

    // MARK: - Nadie de compras

    private var tarjetaInvitacion: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 14) {
                IconoCuadrado(simbolo: "cart", fondo: Tema.amarilloSuave, color: Tema.amarillo)
                VStack(alignment: .leading, spacing: 4) {
                    Text("¿Vas al súper?")
                        .font(Tipografia.tituloTarjeta)
                        .foregroundStyle(Tema.tinta)
                    Text("Activa Modo Compras y avisamos a tus roomies para que agreguen lo que falte.")
                        .font(Tipografia.cuerpo)
                        .foregroundStyle(Tema.tintaSecundaria)
                }
            }
            Button("Activar Modo Compras") {
                pidiendoLugar = true
            }
            .buttonStyle(EstiloBotonOscuro())
        }
        .tarjeta()
    }

    private func activar() {
        store.activarModoCompras(lugar: lugar)
        lugar = ""
        mostrarAviso("Modo Compras activado. Ya avisamos a tus roomies 🛒")
    }

    // MARK: - Yo estoy de compras

    private func tarjetaActiva(_ modo: ModoCompras) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 14) {
                IconoCuadrado(simbolo: "cart", fondo: Tema.verdeSuave, color: Tema.verde)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Modo Compras activo")
                        .font(Tipografia.tituloTarjeta)
                        .foregroundStyle(Tema.tinta)
                    Text(textoActivo(modo))
                        .font(Tipografia.cuerpo)
                        .foregroundStyle(Tema.tintaSecundaria)
                    Text(textoDesde(modo))
                        .font(Tipografia.secundario)
                        .foregroundStyle(Tema.tintaSecundaria)
                }
            }
            Button("Terminar compras") {
                store.terminarModoCompras()
            }
            .buttonStyle(EstiloBotonOscuro())
        }
        .tarjeta()
    }

    private func textoActivo(_ modo: ModoCompras) -> String {
        let donde = modo.lugar.isEmpty ? "fuiste al súper" : "estás en \(modo.lugar)"
        return "Tus roomies ya saben que \(donde). Palomea lo que vayas echando al carrito."
    }

    private func textoDesde(_ modo: ModoCompras) -> String {
        "Desde \(Formato.tiempoRelativo(modo.inicio, ahora: store.ahora))"
    }

    // MARK: - Otro roomie de compras

    @ViewBuilder
    private func avisoDeOtro(_ modo: ModoCompras) -> some View {
        HStack(spacing: 12) {
            if let roomie = store.usuario(modo.activadoPor) {
                AvatarView(usuario: roomie, tamano: 40)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("\(store.nombre(de: modo.activadoPor)) está en el súper")
                    .font(Tipografia.cuerpoFuerte)
                    .foregroundStyle(Tema.tinta)
                Text(detalleDeOtro(modo))
                    .font(Tipografia.secundario)
                    .foregroundStyle(Tema.tintaSecundaria)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Tema.radioTarjeta, style: .continuous)
                .fill(Tema.amarilloSuave)
        )
    }

    private func detalleDeOtro(_ modo: ModoCompras) -> String {
        let tiempo = Formato.tiempoRelativo(modo.inicio, ahora: store.ahora)
        if modo.lugar.isEmpty {
            return "\(tiempo) · Agrega lo que te falte"
        }
        return "\(modo.lugar) · \(tiempo) · Agrega lo que te falte"
    }
}

#Preview {
    ScrollView {
        HogarModoComprasCard(mostrarAviso: { _ in })
            .padding(Tema.margen)
    }
    .background(Tema.fondo)
    .environmentObject(HogarStore.deEjemplo())
    .environmentObject(Navegacion())
}
