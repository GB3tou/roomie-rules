import Foundation

/// Conversión entre pesos (`Double`, lo que ve el usuario) y centavos (`Int`, con lo que se calcula).
///
/// Todas las cuentas de deudas se hacen en centavos enteros para que nunca aparezcan
/// errores de redondeo como 0.1 + 0.2 = 0.30000000000000004.
enum Dinero {
    /// Convierte pesos a centavos redondeando al centavo más cercano. Ej. 52.5 → 5250.
    ///
    /// Devuelve 0 si el valor no es un número (NaN, infinito) o es tan grande que no cabe
    /// en un `Int`: convertirlo tal cual tronaría la app.
    static func aCentavos(_ pesos: Double) -> Int {
        let centavos = (pesos * 100).rounded()
        guard centavos.isFinite, abs(centavos) < 1e17 else { return 0 }
        return Int(centavos)
    }

    /// Convierte centavos a pesos. Ej. 5250 → 52.5.
    static func aPesos(_ centavos: Int) -> Double {
        Double(centavos) / 100
    }
}
