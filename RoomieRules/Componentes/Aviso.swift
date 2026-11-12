import SwiftUI

/// Mensaje breve tipo toast: aparece abajo, encima del contenido, mientras el binding no sea `nil`,
/// y se oculta solo a los 2.5 segundos poniendo el binding en `nil`.
struct Aviso: ViewModifier {
    /// Texto a mostrar; `nil` = nada visible.
    @Binding var mensaje: String?

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                if let texto = mensaje {
                    Text(texto)
                        .font(Tipografia.cuerpoFuerte)
                        .foregroundStyle(Color.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Capsule().fill(Tema.tinta))
                        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
                        .padding(.horizontal, Tema.margen)
                        .padding(.bottom, 24)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .allowsHitTesting(false)
                        .accessibilityAddTraits(.isStaticText)
                }
            }
            .animation(.easeInOut(duration: 0.25), value: mensaje)
            .onAppear {
                programarOcultar(mensaje)
            }
            .onChange(of: mensaje) { _, nuevo in
                programarOcultar(nuevo)
            }
    }

    /// Oculta el aviso tras 2.5 s, pero solo si sigue siendo el mismo mensaje
    /// (si llegó otro, ese tendrá su propio temporizador).
    private func programarOcultar(_ texto: String?) {
        guard let texto = texto else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            if mensaje == texto {
                mensaje = nil
            }
        }
    }
}

extension View {
    /// Muestra un aviso breve abajo cuando `mensaje` no es `nil`; se borra solo.
    func aviso(_ mensaje: Binding<String?>) -> some View {
        modifier(Aviso(mensaje: mensaje))
    }
}

#Preview {
    AvisoPreview()
}

private struct AvisoPreview: View {
    @State private var mensaje: String? = nil

    var body: some View {
        VStack {
            Button("Mostrar aviso") {
                mensaje = "Gasto registrado"
            }
            .buttonStyle(EstiloBotonVerde())
            .padding(Tema.margen)
            Spacer()
        }
        .background(Tema.fondo)
        .aviso($mensaje)
    }
}
