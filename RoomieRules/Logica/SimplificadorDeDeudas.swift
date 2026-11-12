import Foundation

// ¿Cómo se decide "quién le paga a quién"?
//
// Si cada roomie le pagara a cada otro su parte de cada gasto, habría un montón de
// transferencias y hasta cobros circulares (Ana le paga a Sara, Sara a Mauricio y
// Mauricio a Ana). Para evitarlo seguimos 4 pasos:
//
// 1. Balance neto: para cada roomie calculamos lo que pagó menos lo que le tocaba
//    (ver `CalculadoraDeBalances`). Quien queda en positivo es ACREEDOR (le deben);
//    quien queda en negativo es DEUDOR (debe). Los que quedan en 0 ya no participan.
//
// 2. Parejas exactas: si un deudor debe justo lo mismo que le deben a un acreedor,
//    los emparejamos. Una sola transferencia deja a los dos en cero.
//
// 3. Voraz: con los que quedan, el mayor deudor le paga al mayor acreedor lo más que
//    pueda (el menor de los dos montos). Quien quede en cero sale de la lista y se
//    repite hasta que ya no queden deudores o acreedores.
//
// 4. Resultado: cada transferencia deja en cero al menos a una persona, así que hay
//    como mucho n − 1 transferencias (n = número de roomies). Y como nadie es deudor
//    y acreedor a la vez, nunca hay cobros circulares.
//
// Ojo: encontrar el mínimo absoluto de transferencias es un problema difícil (NP-duro).
// El método voraz no garantiza ese mínimo en todos los casos, pero sí da un número
// pequeño de transferencias y es muy fácil de explicar y de comprobar a mano.
//
// Todo se calcula en centavos enteros para que no haya errores de redondeo.

/// Convierte los balances netos del depa en una lista corta de transferencias
/// ("Ana le paga $310 a Mauricio") sin cobros circulares.
enum SimplificadorDeDeudas {
    /// Lo que le falta pagar (deudor) o cobrar (acreedor) a una persona, en centavos (siempre positivo).
    private struct Saldo {
        let id: UUID
        var monto: Int
    }

    /// Una transferencia todavía en centavos, antes de convertirla a `Transferencia`.
    private struct Movimiento {
        let de: UUID
        let para: UUID
        let centavos: Int
    }

    /// Convierte balances netos en la menor cantidad práctica de transferencias (máximo n − 1).
    /// `orden` desempata de forma estable (se usa el orden de `usuarios`).
    static func simplificar(balances: [UUID: Int], orden: [UUID]) -> [Transferencia] {
        // Posición de cada ID en `orden` (si se repite, cuenta la primera aparición).
        var posicion: [UUID: Int] = [:]
        for (indice, id) in orden.enumerated() where posicion[id] == nil {
            posicion[id] = indice
        }

        // Paso 1: separar deudores y acreedores; los ceros se ignoran.
        var deudores: [Saldo] = []
        var acreedores: [Saldo] = []
        for (id, balance) in balances {
            if balance < 0 {
                deudores.append(Saldo(id: id, monto: -balance))
            } else if balance > 0 {
                acreedores.append(Saldo(id: id, monto: balance))
            }
        }
        deudores = ordenar(deudores, posicion: posicion)
        acreedores = ordenar(acreedores, posicion: posicion)

        var movimientos: [Movimiento] = []

        // Paso 2: parejas exactas.
        var deudoresRestantes: [Saldo] = []
        for deudor in deudores {
            if let indice = acreedores.firstIndex(where: { $0.monto == deudor.monto }) {
                movimientos.append(Movimiento(de: deudor.id, para: acreedores[indice].id, centavos: deudor.monto))
                acreedores.remove(at: indice)
            } else {
                deudoresRestantes.append(deudor)
            }
        }
        deudores = deudoresRestantes

        // Paso 3: voraz, mayor deudor contra mayor acreedor.
        // Siempre termina: en cada vuelta al menos uno de los dos queda en 0 y sale de su lista.
        while !deudores.isEmpty && !acreedores.isEmpty {
            deudores = ordenar(deudores, posicion: posicion)
            acreedores = ordenar(acreedores, posicion: posicion)

            let monto = min(deudores[0].monto, acreedores[0].monto)
            movimientos.append(Movimiento(de: deudores[0].id, para: acreedores[0].id, centavos: monto))

            deudores[0].monto -= monto
            acreedores[0].monto -= monto
            if deudores[0].monto == 0 {
                deudores.remove(at: 0)
            }
            if acreedores[0].monto == 0 {
                acreedores.remove(at: 0)
            }
        }

        // Paso 4: de mayor a menor monto, con desempate estable para que la lista no "brinque".
        let ordenados = movimientos.sorted { (a: Movimiento, b: Movimiento) -> Bool in
            if a.centavos != b.centavos {
                return a.centavos > b.centavos
            }
            if a.de != b.de {
                return viene(a.de, antesDe: b.de, posicion: posicion)
            }
            return viene(a.para, antesDe: b.para, posicion: posicion)
        }
        return ordenados.map { (movimiento: Movimiento) -> Transferencia in
            Transferencia(de: movimiento.de, para: movimiento.para, monto: Dinero.aPesos(movimiento.centavos))
        }
    }

    /// Atajo: calcula balances y simplifica.
    static func transferencias(gastos: [Gasto], usuarios: [Usuario]) -> [Transferencia] {
        simplificar(
            balances: CalculadoraDeBalances.balancesEnCentavos(gastos: gastos, usuarios: usuarios),
            orden: usuarios.map { $0.id }
        )
    }

    // MARK: - Ayudantes

    /// Ordena de mayor a menor monto; en empate, primero quien aparece antes en `orden`.
    private static func ordenar(_ saldos: [Saldo], posicion: [UUID: Int]) -> [Saldo] {
        saldos.sorted { (a: Saldo, b: Saldo) -> Bool in
            if a.monto != b.monto {
                return a.monto > b.monto
            }
            return viene(a.id, antesDe: b.id, posicion: posicion)
        }
    }

    /// `true` si `a` va antes que `b` según `orden`. Los IDs que no están en `orden`
    /// van al final, ordenados por su `uuidString` para que el resultado siempre sea el mismo.
    private static func viene(_ a: UUID, antesDe b: UUID, posicion: [UUID: Int]) -> Bool {
        switch (posicion[a], posicion[b]) {
        case let (.some(pa), .some(pb)):
            return pa < pb
        case (.some, .none):
            return true
        case (.none, .some):
            return false
        case (.none, .none):
            return a.uuidString < b.uuidString
        }
    }
}
