import SwiftUI

/// Botón oscuro de ancho completo ("Activar Modo Compras").
struct EstiloBotonOscuro: ButtonStyle {
    func makeBody(configuration: ButtonStyleConfiguration) -> some View {
        BotonEstilizado(
            configuration: configuration,
            fondo: Tema.tinta,
            color: Color.white,
            borde: nil,
            radio: Tema.radioControl,
            anchoCompleto: true
        )
    }
}

/// Botón verde de ancho completo (acciones principales de formularios).
struct EstiloBotonVerde: ButtonStyle {
    func makeBody(configuration: ButtonStyleConfiguration) -> some View {
        BotonEstilizado(
            configuration: configuration,
            fondo: Tema.verde,
            color: Color.white,
            borde: nil,
            radio: Tema.radioControl,
            anchoCompleto: true
        )
    }
}

/// Cápsula blanca con texto verde, para usarse sobre la tarjeta verde ("Ver desglose de deudas →").
struct EstiloBotonPildoraBlanca: ButtonStyle {
    func makeBody(configuration: ButtonStyleConfiguration) -> some View {
        BotonEstilizado(
            configuration: configuration,
            fondo: Color.white,
            color: Tema.verde,
            borde: nil,
            radio: 100,
            anchoCompleto: false
        )
    }
}

/// Cápsula con borde verde y fondo blanco (botón "Toque").
struct EstiloBotonContorno: ButtonStyle {
    func makeBody(configuration: ButtonStyleConfiguration) -> some View {
        BotonEstilizado(
            configuration: configuration,
            fondo: Color.white,
            color: Tema.verde,
            borde: Tema.verde,
            radio: 100,
            anchoCompleto: false
        )
    }
}

/// Vista común de los cuatro estilos. Es una vista aparte para poder leer `isEnabled`,
/// que un `ButtonStyle` no puede leer directamente.
private struct BotonEstilizado: View {
    let configuration: ButtonStyleConfiguration
    let fondo: Color
    let color: Color
    let borde: Color?
    let radio: CGFloat
    let anchoCompleto: Bool

    @Environment(\.isEnabled) private var habilitado

    var body: some View {
        let ancho: CGFloat? = anchoCompleto ? CGFloat.infinity : nil
        let forma = RoundedRectangle(cornerRadius: radio, style: .continuous)
        configuration.label
            .font(Tipografia.cuerpoFuerte)
            .foregroundStyle(color)
            .multilineTextAlignment(.center)
            .padding(.horizontal, anchoCompleto ? 16 : 18)
            .padding(.vertical, anchoCompleto ? 16 : 10)
            .frame(maxWidth: ancho)
            .background(forma.fill(fondo))
            .overlay(forma.strokeBorder(borde ?? Color.clear, lineWidth: 1.5))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(habilitado ? (configuration.isPressed ? 0.85 : 1) : 0.45)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

#Preview {
    VStack(spacing: 16) {
        Button("Activar Modo Compras") {}
            .buttonStyle(EstiloBotonOscuro())
        Button("Guardar gasto") {}
            .buttonStyle(EstiloBotonVerde())
        Button("Guardar gasto") {}
            .buttonStyle(EstiloBotonVerde())
            .disabled(true)
        Button("Toque") {}
            .buttonStyle(EstiloBotonContorno())
        Button("Ver desglose de deudas →") {}
            .buttonStyle(EstiloBotonPildoraBlanca())
            .padding()
            .background(Tema.verde)
    }
    .padding(Tema.margen)
    .background(Tema.fondo)
}
