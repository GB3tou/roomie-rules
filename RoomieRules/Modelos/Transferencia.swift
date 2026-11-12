import Foundation

/// Una deuda ya simplificada: "`de` le debe `monto` a `para`".
///
/// No se guarda en disco: se calcula cada vez a partir de los gastos
/// (ver `Logica/SimplificadorDeDeudas.swift`).
struct Transferencia: Identifiable, Hashable {
    /// ID del `Usuario` que debe el dinero.
    let de: UUID
    /// ID del `Usuario` al que se le debe.
    let para: UUID
    /// Cantidad a pagar, en pesos.
    let monto: Double

    var id: String {
        de.uuidString + ">" + para.uuidString
    }
}
