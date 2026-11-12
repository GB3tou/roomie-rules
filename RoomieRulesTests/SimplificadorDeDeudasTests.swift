import XCTest
@testable import RoomieRules

/// Pruebas de la simplificación de deudas (balance neto → parejas exactas → voraz).
final class SimplificadorDeDeudasTests: XCTestCase {
    // MARK: - Datos de prueba propios (no dependen de DatosDeEjemplo)

    private let roberto = Usuario(nombre: "Roberto", colorAvatar: .verde)
    private let sara = Usuario(nombre: "Sara", colorAvatar: .morado)
    private let mauricio = Usuario(nombre: "Mauricio", colorAvatar: .naranja)
    private let ana = Usuario(nombre: "Ana", colorAvatar: .azul)

    private var usuarios: [Usuario] {
        [roberto, sara, mauricio, ana]
    }

    private var todos: [UUID] {
        usuarios.map { $0.id }
    }

    private func fecha(_ dia: Int) -> Date {
        Calendar.roomie.date(from: DateComponents(year: 2026, month: 11, day: dia, hour: 12)) ?? Date.distantPast
    }

    private func gasto(_ monto: Double, pagadoPor: UUID, entre: [UUID],
                       categoria: CategoriaGasto = .otro) -> Gasto {
        Gasto(descripcion: "Gasto de prueba", montoTotal: monto, pagadoPor: pagadoPor,
              divididoEntre: entre, fecha: fecha(10), categoria: categoria)
    }

    private var gastosDelDepa: [Gasto] {
        [
            gasto(840, pagadoPor: roberto.id, entre: todos),
            gasto(600, pagadoPor: sara.id, entre: todos),
            gasto(1240, pagadoPor: mauricio.id, entre: todos),
            gasto(480, pagadoPor: ana.id, entre: todos),
        ]
    }

    /// Compara una transferencia con lo esperado (monto en pesos).
    private func verificar(_ transferencia: Transferencia, de: UUID, para: UUID, monto: Double,
                           file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(transferencia.de, de, "de", file: file, line: line)
        XCTAssertEqual(transferencia.para, para, "para", file: file, line: line)
        XCTAssertEqual(transferencia.monto, monto, accuracy: 0.0001, "monto", file: file, line: line)
    }

    /// Propiedades que SIEMPRE deben cumplirse: aplicar las transferencias deja todo en 0,
    /// nadie paga y cobra a la vez, y hay como mucho n − 1 transferencias.
    private func verificarPropiedades(balances: [UUID: Int], transferencias: [Transferencia],
                                      file: StaticString = #filePath, line: UInt = #line) {
        var restantes = balances
        for t in transferencias {
            let centavos = Dinero.aCentavos(t.monto)
            XCTAssertGreaterThan(centavos, 0, "monto positivo", file: file, line: line)
            restantes[t.de, default: 0] += centavos
            restantes[t.para, default: 0] -= centavos
        }
        for (_, valor) in restantes {
            XCTAssertEqual(valor, 0, "todos los balances quedan en 0", file: file, line: line)
        }

        let pagan = Set(transferencias.map { $0.de })
        let cobran = Set(transferencias.map { $0.para })
        XCTAssertTrue(pagan.isDisjoint(with: cobran), "nadie paga y cobra a la vez", file: file, line: line)

        XCTAssertLessThanOrEqual(transferencias.count, max(0, balances.count - 1),
                                 "como mucho n − 1 transferencias", file: file, line: line)
    }

    // MARK: - Casos concretos

    func testEscenarioDelDepa() {
        let resultado = SimplificadorDeDeudas.transferencias(gastos: gastosDelDepa, usuarios: usuarios)
        XCTAssertEqual(resultado.count, 3)
        guard resultado.count == 3 else { return }
        verificar(resultado[0], de: ana.id, para: mauricio.id, monto: 310.0)
        verificar(resultado[1], de: sara.id, para: mauricio.id, monto: 140.0)
        verificar(resultado[2], de: sara.id, para: roberto.id, monto: 50.0)
    }

    func testEscenarioDelDepaConLiquidacion() {
        let liquidacion = gasto(50, pagadoPor: sara.id, entre: [roberto.id], categoria: .liquidacion)
        let resultado = SimplificadorDeDeudas.transferencias(gastos: gastosDelDepa + [liquidacion],
                                                             usuarios: usuarios)
        XCTAssertEqual(resultado.count, 2)
        guard resultado.count == 2 else { return }
        verificar(resultado[0], de: ana.id, para: mauricio.id, monto: 310.0)
        verificar(resultado[1], de: sara.id, para: mauricio.id, monto: 140.0)
    }

    func testParejasExactasPrimero() {
        let a = UUID(), b = UUID(), c = UUID(), d = UUID(), e = UUID()
        let balances: [UUID: Int] = [a: -4000, b: -6000, c: 5000, d: 4000, e: 1000]
        let resultado = SimplificadorDeDeudas.simplificar(balances: balances, orden: [a, b, c, d, e])
        XCTAssertEqual(resultado.count, 3)
        guard resultado.count == 3 else { return }
        verificar(resultado[0], de: b, para: c, monto: 50)
        verificar(resultado[1], de: a, para: d, monto: 40)
        verificar(resultado[2], de: b, para: e, monto: 10)
        verificarPropiedades(balances: balances, transferencias: resultado)
    }

    func testPagadorQueNoParticipa() {
        let g = gasto(300, pagadoPor: roberto.id, entre: [sara.id, mauricio.id, ana.id])
        let resultado = SimplificadorDeDeudas.transferencias(gastos: [g], usuarios: usuarios)
        // Tres deudores de $100 y un solo acreedor: en empate manda el orden de `usuarios`.
        XCTAssertEqual(resultado.count, 3)
        guard resultado.count == 3 else { return }
        verificar(resultado[0], de: sara.id, para: roberto.id, monto: 100)
        verificar(resultado[1], de: mauricio.id, para: roberto.id, monto: 100)
        verificar(resultado[2], de: ana.id, para: roberto.id, monto: 100)
    }

    func testSinGastosNoHayTransferencias() {
        XCTAssertTrue(SimplificadorDeDeudas.transferencias(gastos: [], usuarios: usuarios).isEmpty)
    }

    func testTodoEnCerosNoHayTransferencias() {
        let balances: [UUID: Int] = [roberto.id: 0, sara.id: 0, mauricio.id: 0]
        XCTAssertTrue(SimplificadorDeDeudas.simplificar(balances: balances, orden: todos).isEmpty)
        XCTAssertTrue(SimplificadorDeDeudas.simplificar(balances: [:], orden: []).isEmpty)
    }

    func testBalancesQueNoSumanCeroTerminan() {
        // Datos inconsistentes: no debe ciclarse, solo terminar cuando se acaba una lista.
        let balances: [UUID: Int] = [roberto.id: 10000, sara.id: -3000]
        let resultado = SimplificadorDeDeudas.simplificar(balances: balances, orden: todos)
        XCTAssertEqual(resultado.count, 1)
        guard resultado.count == 1 else { return }
        verificar(resultado[0], de: sara.id, para: roberto.id, monto: 30)
    }

    // MARK: - Propiedades generales en escenarios fijos

    func testPropiedadesEscenarioDelDepa() {
        let balances = CalculadoraDeBalances.balancesEnCentavos(gastos: gastosDelDepa, usuarios: usuarios)
        let resultado = SimplificadorDeDeudas.simplificar(balances: balances, orden: todos)
        verificarPropiedades(balances: balances, transferencias: resultado)
    }

    func testPropiedadesConCentavosSobrantes() {
        let gastos = [
            gasto(100, pagadoPor: roberto.id, entre: [roberto.id, sara.id, mauricio.id]),
            gasto(57.31, pagadoPor: sara.id, entre: todos),
            gasto(999.99, pagadoPor: ana.id, entre: [mauricio.id, roberto.id, ana.id]),
            gasto(12.5, pagadoPor: mauricio.id, entre: [sara.id]),
        ]
        let balances = CalculadoraDeBalances.balancesEnCentavos(gastos: gastos, usuarios: usuarios)
        XCTAssertEqual(balances.values.reduce(0, +), 0)
        let resultado = SimplificadorDeDeudas.simplificar(balances: balances, orden: todos)
        verificarPropiedades(balances: balances, transferencias: resultado)
    }

    func testPropiedadesConCincoPersonas() {
        let ids = (0..<5).map { _ in UUID() }
        let balances: [UUID: Int] = [ids[0]: -12345, ids[1]: 7000, ids[2]: -2655, ids[3]: 10000, ids[4]: -2000]
        XCTAssertEqual(balances.values.reduce(0, +), 0)
        let resultado = SimplificadorDeDeudas.simplificar(balances: balances, orden: ids)
        verificarPropiedades(balances: balances, transferencias: resultado)
    }

    func testPropiedadesConLiquidacionYPagadorAusente() {
        let gastos = gastosDelDepa + [
            gasto(50, pagadoPor: sara.id, entre: [roberto.id], categoria: .liquidacion),
            gasto(300, pagadoPor: roberto.id, entre: [sara.id, mauricio.id, ana.id]),
        ]
        let balances = CalculadoraDeBalances.balancesEnCentavos(gastos: gastos, usuarios: usuarios)
        let resultado = SimplificadorDeDeudas.simplificar(balances: balances, orden: todos)
        verificarPropiedades(balances: balances, transferencias: resultado)
    }
}
