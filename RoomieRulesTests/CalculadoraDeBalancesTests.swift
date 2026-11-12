import XCTest
@testable import RoomieRules

/// Pruebas del reparto de cada gasto y de los balances netos (todo en centavos).
final class CalculadoraDeBalancesTests: XCTestCase {
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

    /// Los 4 gastos del depa, todos divididos entre los 4 roomies.
    private var gastosDelDepa: [Gasto] {
        [
            gasto(840, pagadoPor: roberto.id, entre: todos),
            gasto(600, pagadoPor: sara.id, entre: todos),
            gasto(1240, pagadoPor: mauricio.id, entre: todos),
            gasto(480, pagadoPor: ana.id, entre: todos),
        ]
    }

    // MARK: - Dinero

    func testDineroConvierteYRedondea() {
        XCTAssertEqual(Dinero.aCentavos(840), 84000)
        XCTAssertEqual(Dinero.aCentavos(52.5), 5250)
        XCTAssertEqual(Dinero.aCentavos(0.1 + 0.2), 30)
        XCTAssertEqual(Dinero.aPesos(5250), 52.5, accuracy: 0.0001)
        XCTAssertEqual(Dinero.aPesos(-31000), -310, accuracy: 0.0001)
    }

    // MARK: - partesEnCentavos

    func testPartesExactasEntreCuatro() {
        let partes = CalculadoraDeBalances.partesEnCentavos(de: gasto(840, pagadoPor: roberto.id, entre: todos))
        XCTAssertEqual(partes.count, 4)
        for id in todos {
            XCTAssertEqual(partes[id], 21000)
        }
    }

    func testCienEntreTresRepartaElCentavoSobranteAlPrimero() {
        let entre = [roberto.id, sara.id, mauricio.id]
        let partes = CalculadoraDeBalances.partesEnCentavos(de: gasto(100, pagadoPor: roberto.id, entre: entre))
        XCTAssertEqual(partes[roberto.id], 3334)
        XCTAssertEqual(partes[sara.id], 3333)
        XCTAssertEqual(partes[mauricio.id], 3333)
        XCTAssertEqual(partes.values.reduce(0, +), 10000)
    }

    func testSobrantesSeDanEnElOrdenDeDivididoEntre() {
        // $0.05 entre 3 = 1 centavo cada uno y sobran 2: van a los dos primeros de la lista.
        let entre = [ana.id, sara.id, roberto.id]
        let partes = CalculadoraDeBalances.partesEnCentavos(de: gasto(0.05, pagadoPor: roberto.id, entre: entre))
        XCTAssertEqual(partes[ana.id], 2)
        XCTAssertEqual(partes[sara.id], 2)
        XCTAssertEqual(partes[roberto.id], 1)
        XCTAssertEqual(partes.values.reduce(0, +), 5)
    }

    func testPartesIgnoranIDsRepetidos() {
        // Sara aparece dos veces: se cuenta una sola vez, así que es $100 entre 3.
        let entre = [sara.id, roberto.id, sara.id, mauricio.id]
        let partes = CalculadoraDeBalances.partesEnCentavos(de: gasto(100, pagadoPor: roberto.id, entre: entre))
        XCTAssertEqual(partes.count, 3)
        XCTAssertEqual(partes[sara.id], 3334)
        XCTAssertEqual(partes[roberto.id], 3333)
        XCTAssertEqual(partes[mauricio.id], 3333)
        XCTAssertEqual(partes.values.reduce(0, +), 10000)
    }

    func testPartesVaciasSinParticipantesOMontoNoPositivo() {
        XCTAssertEqual(CalculadoraDeBalances.partesEnCentavos(de: gasto(100, pagadoPor: roberto.id, entre: [])), [:])
        XCTAssertEqual(CalculadoraDeBalances.partesEnCentavos(de: gasto(0, pagadoPor: roberto.id, entre: todos)), [:])
        XCTAssertEqual(CalculadoraDeBalances.partesEnCentavos(de: gasto(-50, pagadoPor: roberto.id, entre: todos)), [:])
    }

    // MARK: - parte (en pesos)

    func testParteEnPesos() {
        let entre = [roberto.id, sara.id, mauricio.id]
        let g = gasto(100, pagadoPor: roberto.id, entre: entre)
        XCTAssertEqual(CalculadoraDeBalances.parte(de: roberto.id, en: g), 33.34, accuracy: 0.0001)
        XCTAssertEqual(CalculadoraDeBalances.parte(de: sara.id, en: g), 33.33, accuracy: 0.0001)
        XCTAssertEqual(CalculadoraDeBalances.parte(de: ana.id, en: g), 0, accuracy: 0.0001)
    }

    // MARK: - balancesEnCentavos

    func testBalancesDelDepa() {
        let balances = CalculadoraDeBalances.balancesEnCentavos(gastos: gastosDelDepa, usuarios: usuarios)
        XCTAssertEqual(balances.count, 4)
        XCTAssertEqual(balances[roberto.id], 5000)
        XCTAssertEqual(balances[sara.id], -19000)
        XCTAssertEqual(balances[mauricio.id], 45000)
        XCTAssertEqual(balances[ana.id], -31000)
        XCTAssertEqual(balances.values.reduce(0, +), 0)
    }

    func testBalancesCienEntreTres() {
        let tres = [roberto, sara, mauricio]
        let g = gasto(100, pagadoPor: roberto.id, entre: tres.map { $0.id })
        let balances = CalculadoraDeBalances.balancesEnCentavos(gastos: [g], usuarios: tres)
        XCTAssertEqual(balances[roberto.id], 6666)
        XCTAssertEqual(balances[sara.id], -3333)
        XCTAssertEqual(balances[mauricio.id], -3333)
        XCTAssertEqual(balances.values.reduce(0, +), 0)
    }

    func testLiquidacionAjustaLosBalances() {
        // Sara le paga $50 a Roberto: Roberto queda en 0 y Sara pasa de −190 a −140.
        let liquidacion = gasto(50, pagadoPor: sara.id, entre: [roberto.id], categoria: .liquidacion)
        let balances = CalculadoraDeBalances.balancesEnCentavos(gastos: gastosDelDepa + [liquidacion],
                                                                usuarios: usuarios)
        XCTAssertEqual(balances[roberto.id], 0)
        XCTAssertEqual(balances[sara.id], -14000)
        XCTAssertEqual(balances[mauricio.id], 45000)
        XCTAssertEqual(balances[ana.id], -31000)
        XCTAssertEqual(balances.values.reduce(0, +), 0)
    }

    func testPagadorQueNoParticipa() {
        let g = gasto(300, pagadoPor: roberto.id, entre: [sara.id, mauricio.id, ana.id])
        let balances = CalculadoraDeBalances.balancesEnCentavos(gastos: [g], usuarios: usuarios)
        XCTAssertEqual(balances[roberto.id], 30000)
        XCTAssertEqual(balances[sara.id], -10000)
        XCTAssertEqual(balances[mauricio.id], -10000)
        XCTAssertEqual(balances[ana.id], -10000)
    }

    func testSinGastosTodosEnCero() {
        let balances = CalculadoraDeBalances.balancesEnCentavos(gastos: [], usuarios: usuarios)
        XCTAssertEqual(balances.count, 4)
        for id in todos {
            XCTAssertEqual(balances[id], 0)
        }
    }

    func testGastoSinPartesSeIgnora() {
        let vacio = gasto(500, pagadoPor: roberto.id, entre: [])
        let balances = CalculadoraDeBalances.balancesEnCentavos(gastos: [vacio], usuarios: usuarios)
        XCTAssertEqual(balances[roberto.id], 0)
        XCTAssertEqual(balances.values.reduce(0, +), 0)
    }

    func testIDDesconocidoTambienAparece() {
        let visita = UUID()
        let g = gasto(100, pagadoPor: visita, entre: [roberto.id, sara.id])
        let balances = CalculadoraDeBalances.balancesEnCentavos(gastos: [g], usuarios: usuarios)
        XCTAssertEqual(balances.count, 5)
        XCTAssertEqual(balances[visita], 10000)
        XCTAssertEqual(balances[roberto.id], -5000)
        XCTAssertEqual(balances[sara.id], -5000)
        XCTAssertEqual(balances.values.reduce(0, +), 0)
    }
}
