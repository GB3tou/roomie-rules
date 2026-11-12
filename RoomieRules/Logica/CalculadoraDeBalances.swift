import Foundation

/// Calcula cuánto le toca a cada roomie de cada gasto y el balance neto de cada uno.
///
/// Todo se hace en centavos enteros (ver `Dinero`) para que las sumas cuadren exactas.
enum CalculadoraDeBalances {
    /// Cuánto le toca a cada participante de un gasto, en centavos. La suma SIEMPRE es el total:
    /// si la división no es exacta, los centavos sobrantes se reparten de uno en uno
    /// entre los primeros participantes (en el orden de `divididoEntre`).
    ///
    /// Devuelve `[:]` si nadie participa o si el monto no es positivo.
    static func partesEnCentavos(de gasto: Gasto) -> [UUID: Int] {
        // Quitamos IDs repetidos conservando el orden, para que nadie pague doble
        // y para que el reparto de centavos sobrantes sea predecible.
        var vistos = Set<UUID>()
        var participantes: [UUID] = []
        for id in gasto.divididoEntre {
            if vistos.insert(id).inserted {
                participantes.append(id)
            }
        }

        // `isFinite` evita que un valor raro (infinito o NaN) truene al convertirlo a Int.
        guard !participantes.isEmpty, gasto.montoTotal.isFinite, gasto.montoTotal > 0 else {
            return [:]
        }
        let total = Dinero.aCentavos(gasto.montoTotal)
        guard total > 0 else { return [:] }

        let n = participantes.count
        let base = total / n
        let sobrante = total % n

        var partes: [UUID: Int] = [:]
        for (indice, id) in participantes.enumerated() {
            // Los primeros `sobrante` participantes ponen un centavo más.
            partes[id] = base + (indice < sobrante ? 1 : 0)
        }
        return partes
    }

    /// Parte en pesos de `usuarioID` en ese gasto (0 si no participa).
    static func parte(de usuarioID: UUID, en gasto: Gasto) -> Double {
        let partes = partesEnCentavos(de: gasto)
        return Dinero.aPesos(partes[usuarioID] ?? 0)
    }

    /// Balance neto por usuario en centavos: positivo = le deben, negativo = debe. Siempre suma 0.
    /// Incluye a todos los `usuarios` (con 0 si no aparecen en ningún gasto).
    ///
    /// Las liquidaciones no necesitan trato especial: quien debía aparece como `pagadoPor`
    /// y el acreedor como único participante, así que la misma fórmula salda a ambos.
    static func balancesEnCentavos(gastos: [Gasto], usuarios: [Usuario]) -> [UUID: Int] {
        var balances: [UUID: Int] = [:]
        for usuario in usuarios {
            balances[usuario.id] = 0
        }

        for gasto in gastos {
            let partes = partesEnCentavos(de: gasto)
            // Un gasto sin partes (monto 0 o sin participantes) no mueve ningún balance.
            if partes.isEmpty { continue }

            // Usamos la suma de las partes (que es exactamente el total en centavos)
            // para garantizar que los balances sumen 0.
            let total = partes.values.reduce(0, +)
            balances[gasto.pagadoPor, default: 0] += total
            for (id, parte) in partes {
                balances[id, default: 0] -= parte
            }
        }
        return balances
    }
}
