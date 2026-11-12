import XCTest
@testable import RoomieRules

/// Pruebas de los textos de `Formato`: dinero, fechas y vencimientos de tareas.
/// "Hoy" es el miércoles 11 de noviembre de 2026 a las 12:00.
final class FormatoTests: XCTestCase {
    // MARK: - Ayudantes

    private func fecha(mes: Int = 11, dia: Int, hora: Int = 12) -> Date {
        let componentes = DateComponents(year: 2026, month: mes, day: dia, hour: hora)
        guard let resultado = Calendar.roomie.date(from: componentes) else {
            XCTFail("No se pudo construir la fecha \(dia)/\(mes)/2026")
            return Date()
        }
        return resultado
    }

    /// Miércoles 11 de noviembre de 2026, 12:00.
    private var hoy: Date {
        fecha(dia: 11)
    }

    private func tarea(vence dia: Int, mes: Int = 11, frecuencia: FrecuenciaTarea = .semanal,
                       completada: Bool = false) -> Tarea {
        Tarea(titulo: "Tarea de prueba", area: .cocina, asignadoA: UUID(), completada: completada,
              fechaLim: fecha(mes: mes, dia: dia, hora: 0), frecuencia: frecuencia)
    }

    // MARK: - Dinero

    func testDineroSinCentavosCuandoEsEntero() {
        XCTAssertEqual(Formato.dinero(840), "$840")
        XCTAssertEqual(Formato.dinero(0), "$0")
    }

    func testDineroConSeparadorDeMiles() {
        XCTAssertEqual(Formato.dinero(3160), "$3,160")
        XCTAssertEqual(Formato.dinero(1234567.89), "$1,234,567.89")
    }

    func testDineroConCentavosCuandoNoEsEntero() {
        XCTAssertEqual(Formato.dinero(52.5), "$52.50")
        XCTAssertEqual(Formato.dinero(0.05), "$0.05")
    }

    func testDineroNegativoLlevaElSignoDelante() {
        XCTAssertEqual(Formato.dinero(-50), "-$50")
        XCTAssertEqual(Formato.dinero(-52.5), "-$52.50")
    }

    func testDineroConValoresQueNoSePuedenMostrarDa0() {
        XCTAssertEqual(Formato.dinero(Double.nan), "$0")
        XCTAssertEqual(Formato.dinero(Double.infinity), "$0")
    }

    func testDineroExactoSiempreLlevaDosDecimales() {
        XCTAssertEqual(Formato.dineroExacto(210), "$210.00")
        XCTAssertEqual(Formato.dineroExacto(1240), "$1,240.00")
        XCTAssertEqual(Formato.dineroExacto(52.5), "$52.50")
        XCTAssertEqual(Formato.dineroExacto(-52.5), "-$52.50")
    }

    // MARK: - Tiempo relativo

    func testTiempoRelativoMenosDeUnMinutoEsAhora() {
        XCTAssertEqual(Formato.tiempoRelativo(hoy.addingTimeInterval(-30), ahora: hoy), "Ahora")
        XCTAssertEqual(Formato.tiempoRelativo(hoy.addingTimeInterval(-59), ahora: hoy), "Ahora")
    }

    func testTiempoRelativoUnaFechaEnElFuturoSeMuestraComoAhora() {
        XCTAssertEqual(Formato.tiempoRelativo(hoy.addingTimeInterval(120), ahora: hoy), "Ahora")
    }

    func testTiempoRelativoEnMinutos() {
        XCTAssertEqual(Formato.tiempoRelativo(hoy.addingTimeInterval(-60), ahora: hoy), "Hace 1 min")
        XCTAssertEqual(Formato.tiempoRelativo(hoy.addingTimeInterval(-10 * 60), ahora: hoy), "Hace 10 min")
    }

    func testTiempoRelativoEnHoras() {
        XCTAssertEqual(Formato.tiempoRelativo(hoy.addingTimeInterval(-2 * 3600), ahora: hoy), "Hace 2 h")
    }

    func testTiempoRelativoDeAyer() {
        XCTAssertEqual(Formato.tiempoRelativo(hoy.addingTimeInterval(-30 * 3600), ahora: hoy), "Ayer")
    }

    func testTiempoRelativoEnDias() {
        XCTAssertEqual(Formato.tiempoRelativo(hoy.addingTimeInterval(-3 * 24 * 3600), ahora: hoy), "Hace 3 d")
    }

    func testTiempoRelativoDeUnaSemanaEnAdelanteMuestraLaFecha() {
        // 8 días antes del 11 de noviembre es el 3 de noviembre.
        XCTAssertEqual(Formato.tiempoRelativo(hoy.addingTimeInterval(-8 * 24 * 3600), ahora: hoy), "3 nov")
    }

    // MARK: - Semana

    func testRangoDeSemanaDentroDelMismoMes() {
        XCTAssertEqual(Formato.rangoSemana(inicio: fecha(dia: 9, hora: 0)),
                       "Semana del 9 al 15 de noviembre")
    }

    func testRangoDeSemanaQueCruzaDeMes() {
        XCTAssertEqual(Formato.rangoSemana(inicio: fecha(dia: 30, hora: 0)),
                       "Semana del 30 de noviembre al 6 de diciembre")
    }

    // MARK: - Fechas sueltas

    func testDiaSemanaConMayusculaInicial() {
        XCTAssertEqual(Formato.diaSemana(fecha(dia: 13)), "Viernes")
    }

    func testMesConMayusculaInicial() {
        XCTAssertEqual(Formato.mes(fecha(dia: 13)), "Noviembre")
    }

    func testNumeroDeDia() {
        XCTAssertEqual(Formato.numeroDeDia(fecha(dia: 13)), "13")
        XCTAssertEqual(Formato.numeroDeDia(fecha(dia: 9)), "9")
    }

    func testDiaCortoYDiaLargo() {
        XCTAssertEqual(Formato.diaCorto(fecha(dia: 13)), "vie 13")
        XCTAssertEqual(Formato.diaLargo(fecha(dia: 13)), "viernes 13")
    }

    func testDiaYMes() {
        XCTAssertEqual(Formato.diaYMes(fecha(dia: 10)), "10 nov")
    }

    func testHoraEnFormatoDe24Horas() {
        XCTAssertEqual(Formato.hora(fecha(dia: 13, hora: 20)), "20:00")
        XCTAssertEqual(Formato.hora(fecha(dia: 13, hora: 8)), "08:00")
    }

    // MARK: - Vencimiento de tareas (hoy = miércoles 11)

    func testVencimientoDeUnaTareaDiaria() {
        let diaria = tarea(vence: 11, frecuencia: .diaria)
        XCTAssertEqual(Formato.vencimientoCorto(de: diaria, hoy: hoy), "diario")
        XCTAssertEqual(Formato.vencimientoLargo(de: diaria, hoy: hoy), "todos los días")
        XCTAssertEqual(Formato.etiquetaVencimiento(de: diaria, hoy: hoy), "Diario")
    }

    func testVencimientoDeUnaTareaQueVenceHoy() {
        let venceHoy = tarea(vence: 11)
        XCTAssertEqual(Formato.vencimientoCorto(de: venceHoy, hoy: hoy), "hoy")
        XCTAssertEqual(Formato.vencimientoLargo(de: venceHoy, hoy: hoy), "vence hoy")
        XCTAssertEqual(Formato.etiquetaVencimiento(de: venceHoy, hoy: hoy), "Hoy")
    }

    func testVencimientoDeUnaTareaQueVenceManana() {
        let venceManana = tarea(vence: 12)
        XCTAssertEqual(Formato.vencimientoCorto(de: venceManana, hoy: hoy), "mañana")
        XCTAssertEqual(Formato.vencimientoLargo(de: venceManana, hoy: hoy), "vence mañana")
        XCTAssertEqual(Formato.etiquetaVencimiento(de: venceManana, hoy: hoy), "Mañana")
    }

    func testVencimientoDeUnaTareaQueVenceElViernes() {
        let venceViernes = tarea(vence: 13)
        XCTAssertEqual(Formato.vencimientoCorto(de: venceViernes, hoy: hoy), "vie 13")
        XCTAssertEqual(Formato.vencimientoLargo(de: venceViernes, hoy: hoy), "vence viernes 13")
        XCTAssertEqual(Formato.etiquetaVencimiento(de: venceViernes, hoy: hoy), "Viernes")
    }

    func testVencimientoDeUnaTareaPendienteYAtrasada() {
        // Venció el lunes 9, dos días antes de "hoy".
        let atrasada = tarea(vence: 9)
        XCTAssertEqual(Formato.vencimientoCorto(de: atrasada, hoy: hoy), "lun 9")
        XCTAssertEqual(Formato.vencimientoLargo(de: atrasada, hoy: hoy), "venció lunes 9")
        XCTAssertEqual(Formato.etiquetaVencimiento(de: atrasada, hoy: hoy), "Atrasada")
    }

    func testVencimientoDeUnaTareaCompletadaConFechaPasada() {
        let cumplida = tarea(vence: 9, completada: true)
        XCTAssertEqual(Formato.vencimientoLargo(de: cumplida, hoy: hoy), "vencía lunes 9")
        XCTAssertEqual(Formato.etiquetaVencimiento(de: cumplida, hoy: hoy), "Lunes")
    }
}
