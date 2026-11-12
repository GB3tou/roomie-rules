import SwiftUI

/// Estado visual de una casilla de tarea.
enum EstadoCasilla {
    /// Tarea mía por hacer: círculo con borde continuo.
    case pendiente
    /// Tarea de otro roomie: no la puedo palomear (borde punteado y tenue).
    case ajena
    /// Tarea ya hecha: círculo verde con palomita.
    case completada
}

/// Casilla circular grande de las tareas. Solo dibuja; el botón lo pone quien la usa.
struct CasillaCircular: View {
    /// Qué aspecto tiene la casilla.
    let estado: EstadoCasilla
    /// Diámetro en puntos.
    var tamano: CGFloat = 44

    var body: some View {
        ZStack {
            switch estado {
            case .pendiente:
                Circle()
                    .strokeBorder(Tema.tintaTerciaria, lineWidth: 2)
            case .ajena:
                Circle()
                    .fill(Tema.campo)
                Circle()
                    .strokeBorder(Tema.borde, style: StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
            case .completada:
                Circle()
                    .fill(Tema.verde)
                Image(systemName: "checkmark")
                    .font(.system(size: tamano * 0.4, weight: .bold))
                    .foregroundStyle(Color.white)
            }
        }
        .frame(width: tamano, height: tamano)
    }
}

#Preview {
    HStack(spacing: 16) {
        CasillaCircular(estado: .pendiente)
        CasillaCircular(estado: .ajena)
        CasillaCircular(estado: .completada)
    }
    .padding()
    .background(Tema.fondo)
}
