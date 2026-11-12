import SwiftUI

/// Ícono cuadrado de un gasto (luz, internet, súper…) según `EstiloGasto`.
struct IconoGasto: View {
    /// Gasto del que se elige el ícono.
    let gasto: Gasto
    /// Lado del cuadrado en puntos.
    var tamano: CGFloat = 48

    var body: some View {
        let estilo = EstiloGasto.de(gasto)
        IconoCuadrado(simbolo: estilo.simbolo, fondo: estilo.fondo, color: estilo.color, tamano: tamano)
    }
}

#Preview {
    let quien = UUID()
    HStack(spacing: 12) {
        IconoGasto(gasto: Gasto(descripcion: "Recibo de luz", montoTotal: 840, pagadoPor: quien, divididoEntre: [quien], fecha: Date(), categoria: .servicios))
        IconoGasto(gasto: Gasto(descripcion: "Internet", montoTotal: 600, pagadoPor: quien, divididoEntre: [quien], fecha: Date(), categoria: .servicios))
        IconoGasto(gasto: Gasto(descripcion: "Tanque de gas", montoTotal: 480, pagadoPor: quien, divididoEntre: [quien], fecha: Date(), categoria: .otro))
        IconoGasto(gasto: Gasto(descripcion: "Súper semanal", montoTotal: 1240, pagadoPor: quien, divididoEntre: [quien], fecha: Date(), categoria: .supermercado))
        IconoGasto(gasto: Gasto(descripcion: "Pago", montoTotal: 50, pagadoPor: quien, divididoEntre: [quien], fecha: Date(), categoria: .liquidacion))
    }
    .padding()
    .background(Tema.fondo)
}
