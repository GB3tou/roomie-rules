import XCTest
@testable import RoomieRules

/// Una deuda que se espera ver en la lista de transferencias.
private struct DeudaEsperada {
    let de: UUID
    let para: UUID
    let monto: Double
}

/// Pruebas del estado de la app (`HogarStore`) con los datos de ejemplo.
/// "Hoy" es el miércoles 11 de noviembre de 2026 a las 12:00 (semana del lunes 9 al domingo 15).
final class HogarStoreTests: XCTestCase {
    // MARK: - Ayudantes

    private let roberto = DatosDeEjemplo.robertoID
    private let sara = DatosDeEjemplo.saraID
    private let mauricio = DatosDeEjemplo.mauricioID
    private let ana = DatosDeEjemplo.anaID

    private var todos: [UUID] {
        DatosDeEjemplo.usuarios.map { $0.id }
    }

    /// Miércoles 11 de noviembre de 2026, 12:00.
    private var hoy: Date {
        let componentes = DateComponents(year: 2026, month: 11, day: 11, hour: 12)
        guard let resultado = Calendar.roomie.date(from: componentes) else {
            XCTFail("No se pudo construir la fecha de referencia")
            return Date()
        }
        return resultado
    }

    /// Store con datos de ejemplo, almacén en memoria y notificador de prueba.
    private func crearStore() -> (store: HogarStore, almacen: AlmacenEnMemoria, notificador: NotificadorDePrueba) {
        let momento = hoy
        let almacen = AlmacenEnMemoria()
        let notificador = NotificadorDePrueba()
        let store = HogarStore(almacen: almacen, notificador: notificador, reloj: { momento })
        return (store: store, almacen: almacen, notificador: notificador)
    }

    private func tarea(_ titulo: String, en store: HogarStore) throws -> Tarea {
        return try XCTUnwrap(store.tareas.first(where: { $0.titulo == titulo }))
    }

    private func verificar(_ transferencias: [Transferencia], _ esperadas: [DeudaEsperada],
                           file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(transferencias.count, esperadas.count, "cantidad de transferencias", file: file, line: line)
        guard transferencias.count == esperadas.count else { return }
        for (indice, esperada) in esperadas.enumerated() {
            let real = transferencias[indice]
            XCTAssertEqual(real.de, esperada.de, "de (\(indice))", file: file, line: line)
            XCTAssertEqual(real.para, esperada.para, "para (\(indice))", file: file, line: line)
            XCTAssertEqual(real.monto, esperada.monto, accuracy: 0.001, "monto (\(indice))", file: file, line: line)
        }
    }

    // MARK: - 1. Estado inicial

    func testEstadoInicialConLosDatosDeEjemplo() throws {
        let store = crearStore().store

        XCTAssertEqual(store.usuarios.count, 4)
        XCTAssertEqual(store.usuarioActual.id, roberto)
        XCTAssertEqual(store.nombreHogar, "Depa Mixcoac")
        XCTAssertEqual(store.miBalance, 50, accuracy: 0.001)
        XCTAssertEqual(store.totalDelMes, 3160, accuracy: 0.001)
        XCTAssertEqual(store.pagadoPorMiEsteMes, 840, accuracy: 0.001)
        XCTAssertEqual(store.miParteEsteMes, 790, accuracy: 0.001)
        XCTAssertEqual(store.gastos.count, 4)

        verificar(store.transferencias, [
            DeudaEsperada(de: ana, para: mauricio, monto: 310),
            DeudaEsperada(de: sara, para: mauricio, monto: 140),
            DeudaEsperada(de: sara, para: roberto, monto: 50)
        ])
        verificar(store.misTransferencias, [
            DeudaEsperada(de: sara, para: roberto, monto: 50)
        ])

        XCTAssertEqual(store.tareas.count, 5)
        XCTAssertEqual(store.tareasCompletadas, 1)
        XCTAssertEqual(store.misTareasPendientes.count, 2)
        XCTAssertEqual(store.articulosPorComprar, 4)

        let modo = try XCTUnwrap(store.modoCompras)
        XCTAssertEqual(modo.activadoPor, mauricio)
        XCTAssertEqual(modo.lugar, "Walmart Universidad")
    }

    func testLaSemanaInicialEmpiezaElLunes9() throws {
        let store = crearStore().store
        let lunes = try XCTUnwrap(Calendar.roomie.date(from: DateComponents(year: 2026, month: 11, day: 9)))
        XCTAssertEqual(store.inicioSemana, lunes)
    }

    func testCrearElStoreGuardaElEstadoInicialUnaSolaVez() {
        let creado = crearStore()
        XCTAssertEqual(creado.almacen.vecesGuardado, 1)
        XCTAssertEqual(creado.almacen.estadoGuardado, creado.store.estado)
    }

    // MARK: - 2. Criterio de éxito: registrar la luz actualiza las deudas

    func testRegistrarLaLuzActualizaLasDeudas() throws {
        let store = crearStore().store

        let gasto = try XCTUnwrap(store.agregarGasto(descripcion: "Recibo de luz", montoTotal: 840,
                                                    categoria: .servicios, pagadoPor: roberto,
                                                    divididoEntre: todos))
        XCTAssertEqual(gasto.montoTotal, 840, accuracy: 0.001)
        XCTAssertEqual(gasto.pagadoPor, roberto)
        XCTAssertEqual(gasto.divididoEntre.count, 4)

        XCTAssertEqual(store.gastos.count, 5)
        XCTAssertEqual(store.totalDelMes, 4000, accuracy: 0.001)
        XCTAssertEqual(store.miBalance, 680, accuracy: 0.001)
        XCTAssertEqual(store.balance(de: sara), -400, accuracy: 0.001)
        XCTAssertEqual(store.balance(de: mauricio), 240, accuracy: 0.001)
        XCTAssertEqual(store.balance(de: ana), -520, accuracy: 0.001)

        // Balances: Roberto +680, Sara -400, Mauricio +240, Ana -520.
        // Sin parejas exactas. Voraz: Ana 520 -> Roberto 680; Sara 400 -> Mauricio 240; Sara 160 -> Roberto 160.
        verificar(store.transferencias, [
            DeudaEsperada(de: ana, para: roberto, monto: 520),
            DeudaEsperada(de: sara, para: mauricio, monto: 240),
            DeudaEsperada(de: sara, para: roberto, monto: 160)
        ])
        verificar(store.misTransferencias, [
            DeudaEsperada(de: ana, para: roberto, monto: 520),
            DeudaEsperada(de: sara, para: roberto, monto: 160)
        ])

        let actividad = try XCTUnwrap(store.actividadesRecientes.first)
        XCTAssertEqual(actividad.tipo, .gasto)
        XCTAssertEqual(actividad.gastoID, gasto.id)
        XCTAssertEqual(actividad.usuarioID, roberto)
        XCTAssertEqual(actividad.texto, "registró Recibo de luz · $840")
        XCTAssertNil(actividad.detalle)
    }

    func testRegistrarUnGastoPagadoPorOtroLlevaElDetalleDeQuienPago() throws {
        let store = crearStore().store
        let gasto = try XCTUnwrap(store.agregarGasto(descripcion: "Pizza", montoTotal: 200,
                                                    categoria: .otro, pagadoPor: sara,
                                                    divididoEntre: todos))
        let actividad = try XCTUnwrap(store.actividadesRecientes.first)
        XCTAssertEqual(actividad.gastoID, gasto.id)
        XCTAssertEqual(actividad.detalle, "Pagó Sara")
    }

    func testAgregarUnGastoSeGuardaUnaSolaVez() {
        let creado = crearStore()
        let antes = creado.almacen.vecesGuardado
        creado.store.agregarGasto(descripcion: "Agua", montoTotal: 100, categoria: .servicios,
                                  pagadoPor: roberto, divididoEntre: todos)
        XCTAssertEqual(creado.almacen.vecesGuardado, antes + 1)
    }

    func testElMontoSeGuardaRedondeadoAlCentavo() throws {
        let store = crearStore().store
        let gasto = try XCTUnwrap(store.agregarGasto(descripcion: "Café", montoTotal: 10.006,
                                                    categoria: .otro, pagadoPor: roberto,
                                                    divididoEntre: todos))
        XCTAssertEqual(gasto.montoTotal, 10.01, accuracy: 0.0001)
    }

    // MARK: - 3. Validaciones de agregarGasto

    func testAgregarGastoConDatosInvalidosDevuelveNilYNoCambiaNada() {
        let store = crearStore().store
        let antes = store.estado

        func intentar(_ monto: Double, pagador: UUID, entre: [UUID]) -> Gasto? {
            return store.agregarGasto(descripcion: "Prueba", montoTotal: monto, categoria: .otro,
                                      pagadoPor: pagador, divididoEntre: entre)
        }

        XCTAssertNil(intentar(0, pagador: roberto, entre: todos), "monto 0")
        XCTAssertNil(intentar(-10, pagador: roberto, entre: todos), "monto negativo")
        XCTAssertNil(intentar(Double.nan, pagador: roberto, entre: todos), "monto NaN")
        XCTAssertNil(intentar(Double.infinity, pagador: roberto, entre: todos), "monto infinito")
        XCTAssertNil(intentar(10_000_001, pagador: roberto, entre: todos), "monto sobre el máximo")
        XCTAssertNil(intentar(0.004, pagador: roberto, entre: todos), "monto que se redondea a 0 centavos")
        XCTAssertNil(intentar(100, pagador: roberto, entre: []), "sin participantes")
        XCTAssertNil(intentar(100, pagador: roberto, entre: [UUID()]), "solo participantes desconocidos")
        XCTAssertNil(intentar(100, pagador: UUID(), entre: todos), "pagador inexistente")

        XCTAssertEqual(store.gastos.count, 4)
        XCTAssertEqual(store.estado, antes)
    }

    func testDescripcionVaciaUsaElNombreDeLaCategoria() throws {
        let store = crearStore().store

        let vacia = try XCTUnwrap(store.agregarGasto(descripcion: "", montoTotal: 100, categoria: .servicios,
                                                    pagadoPor: roberto, divididoEntre: todos))
        XCTAssertEqual(vacia.descripcion, "Servicios")

        let soloEspacios = try XCTUnwrap(store.agregarGasto(descripcion: "   ", montoTotal: 100, categoria: .renta,
                                                           pagadoPor: roberto, divididoEntre: todos))
        XCTAssertEqual(soloEspacios.descripcion, "Renta")
    }

    func testLosParticipantesSeGuardanSinRepetidosNiDesconocidosYEnElOrdenDelDepa() throws {
        let store = crearStore().store
        let gasto = try XCTUnwrap(store.agregarGasto(descripcion: "Cena", montoTotal: 90, categoria: .otro,
                                                    pagadoPor: roberto,
                                                    divididoEntre: [ana, sara, sara, UUID()]))
        XCTAssertEqual(gasto.divididoEntre, [sara, ana])
    }

    // MARK: - 4. eliminarGasto

    func testEliminarUnGastoRecienRegistradoQuitaSuActividad() throws {
        let store = crearStore().store
        let gasto = try XCTUnwrap(store.agregarGasto(descripcion: "Cena", montoTotal: 400, categoria: .otro,
                                                    pagadoPor: roberto, divididoEntre: todos))
        XCTAssertEqual(store.gastos.count, 5)
        XCTAssertEqual(store.actividadesRecientes.count, 5)

        store.eliminarGasto(gasto)

        XCTAssertEqual(store.gastos.count, 4)
        XCTAssertNil(store.gasto(gasto.id))
        XCTAssertEqual(store.actividadesRecientes.count, 4)
        XCTAssertFalse(store.actividadesRecientes.contains(where: { $0.gastoID == gasto.id }))
        XCTAssertEqual(store.miBalance, 50, accuracy: 0.001)
    }

    func testEliminarElGastoDeLuzDeEjemploRecalculaElBalance() throws {
        let store = crearStore().store
        let luz = try XCTUnwrap(store.gastos.first(where: { $0.descripcion == "Recibo de luz" }))

        store.eliminarGasto(luz)

        XCTAssertEqual(store.gastos.count, 3)
        XCTAssertEqual(store.actividadesRecientes.count, 3)
        XCTAssertFalse(store.actividadesRecientes.contains(where: { $0.gastoID == luz.id }))
        // Roberto: 50 - (840 pagados - 210 de su parte) = -580.
        XCTAssertEqual(store.miBalance, -580, accuracy: 0.001)
    }

    // MARK: - 5. Palomear tareas

    func testPalomearUnaTareaPropiaYQuitarLaPalomita() throws {
        let store = crearStore().store
        let limpiar = try tarea("Limpiar baño", en: store)
        XCTAssertTrue(store.puedeCompletar(limpiar))

        store.alternarCompletada(limpiar)
        XCTAssertEqual(store.tareasCompletadas, 2)
        XCTAssertEqual(store.misTareasPendientes.count, 1)
        let actividad = try XCTUnwrap(store.actividadesRecientes.first)
        XCTAssertEqual(actividad.tipo, .tareaCompletada)
        XCTAssertEqual(actividad.texto, "completó Limpiar baño")
        XCTAssertEqual(store.actividadesRecientes.count, 5)

        store.alternarCompletada(limpiar)
        XCTAssertEqual(store.tareasCompletadas, 1)
        XCTAssertEqual(store.misTareasPendientes.count, 2)
        XCTAssertEqual(store.actividadesRecientes.count, 4)
    }

    func testNoSePuedePalomearLaTareaDeOtroRoomie() throws {
        let store = crearStore().store
        let basura = try tarea("Sacar la basura", en: store)
        XCTAssertFalse(store.puedeCompletar(basura))

        let antes = store.estado
        store.alternarCompletada(basura)

        XCTAssertEqual(store.estado, antes)
        XCTAssertEqual(store.tareasCompletadas, 1)
        XCTAssertEqual(store.misTareasPendientes.count, 2)
    }

    // MARK: - 6. Toque

    func testDarToqueALaTareaDeSara() throws {
        let creado = crearStore()
        let store = creado.store
        let basura = try tarea("Sacar la basura", en: store)
        XCTAssertTrue(store.puedeDarToque(basura))
        XCTAssertFalse(store.toqueReciente(basura))

        let mensaje = store.darToque(basura)

        let texto = try XCTUnwrap(mensaje)
        XCTAssertFalse(texto.isEmpty)
        XCTAssertTrue(texto.contains("Sara"))
        XCTAssertTrue(texto.contains("Sacar la basura"))
        XCTAssertEqual(creado.notificador.enviadas.count, 1)
        let aviso = try XCTUnwrap(creado.notificador.enviadas.first)
        XCTAssertEqual(aviso.cuerpo, texto)
        XCTAssertTrue(aviso.titulo.contains("Roberto"))
        XCTAssertTrue(store.toqueReciente(basura))
        XCTAssertFalse(store.puedeDarToque(basura))

        let actividad = try XCTUnwrap(store.actividadesRecientes.first)
        XCTAssertEqual(actividad.tipo, .toque)
        XCTAssertEqual(actividad.texto, "le dio un Toque a Sara")
    }

    func testUnSegundoToqueSeguidoNoSeEnvia() throws {
        let creado = crearStore()
        let store = creado.store
        let basura = try tarea("Sacar la basura", en: store)

        XCTAssertNotNil(store.darToque(basura))
        let antes = store.estado
        XCTAssertNil(store.darToque(basura))

        XCTAssertEqual(creado.notificador.enviadas.count, 1)
        XCTAssertEqual(store.estado, antes)
    }

    func testNoSePuedeDarToqueALaTareaPropiaNiALaYaCompletada() throws {
        let creado = crearStore()
        let store = creado.store
        let propia = try tarea("Limpiar baño", en: store)
        let completada = try tarea("Lavar trastes", en: store)

        XCTAssertNil(store.darToque(propia))
        XCTAssertNil(store.darToque(completada))
        XCTAssertEqual(creado.notificador.enviadas.count, 0)
    }

    // MARK: - 7. Liquidar

    func testLiquidarLaDeudaDeSaraConRoberto() throws {
        let store = crearStore().store
        let deuda = try XCTUnwrap(store.misTransferencias.first)
        XCTAssertEqual(deuda.de, sara)
        XCTAssertEqual(deuda.para, roberto)

        store.liquidar(deuda)

        XCTAssertEqual(store.miBalance, 0, accuracy: 0.001)
        XCTAssertEqual(store.balance(de: sara), -140, accuracy: 0.001)
        XCTAssertEqual(store.gastos.count, 5)
        let pago = try XCTUnwrap(store.gastos.first)
        XCTAssertTrue(pago.esLiquidacion)
        XCTAssertEqual(pago.pagadoPor, sara)
        XCTAssertEqual(pago.divididoEntre, [roberto])
        XCTAssertEqual(pago.montoTotal, 50, accuracy: 0.001)
        XCTAssertEqual(store.totalDelMes, 3160, accuracy: 0.001)

        verificar(store.transferencias, [
            DeudaEsperada(de: ana, para: mauricio, monto: 310),
            DeudaEsperada(de: sara, para: mauricio, monto: 140)
        ])
        XCTAssertEqual(store.misTransferencias.count, 0)

        let actividad = try XCTUnwrap(store.actividadesRecientes.first)
        XCTAssertEqual(actividad.tipo, .liquidacion)
        XCTAssertEqual(actividad.gastoID, pago.id)
    }

    func testLiquidarDosVecesLaMismaDeudaNoLaRegistraDosVeces() throws {
        let store = crearStore().store
        let deuda = try XCTUnwrap(store.misTransferencias.first)

        store.liquidar(deuda)
        let despuesDeLaPrimera = store.estado
        store.liquidar(deuda)

        XCTAssertEqual(store.estado, despuesDeLaPrimera)
        XCTAssertEqual(store.gastos.count, 5)
        XCTAssertEqual(store.miBalance, 0, accuracy: 0.001)
    }

    // MARK: - 8. Lista del súper

    func testAgregarUnArticuloALaLista() throws {
        let store = crearStore().store

        store.agregarArticulo("Pan")

        XCTAssertEqual(store.articulos.count, 6)
        XCTAssertEqual(store.articulosPorComprar, 5)
        let nuevo = try XCTUnwrap(store.articulos.last)
        XCTAssertEqual(nuevo.nombre, "Pan")
        XCTAssertEqual(nuevo.agregadoPor, roberto)
        XCTAssertFalse(nuevo.fueComprado)
    }

    func testNoSeAgregaUnArticuloVacioNiRepetido() {
        let store = crearStore().store
        let antes = store.estado

        store.agregarArticulo("  ")
        XCTAssertEqual(store.estado, antes)

        store.agregarArticulo("huevo (30 pzas)")
        XCTAssertEqual(store.estado, antes)
        XCTAssertEqual(store.articulosPorComprar, 4)
    }

    func testSePuedeVolverAAgregarUnArticuloYaComprado() throws {
        let store = crearStore().store

        // "Tortillas" ya está comprado en los datos de ejemplo, así que no estorba.
        store.agregarArticulo("Tortillas")

        XCTAssertEqual(store.articulos.count, 6)
        XCTAssertEqual(store.articulosPorComprar, 5)
    }

    func testAlternarCompradoYLimpiarComprados() throws {
        let store = crearStore().store
        let papel = try XCTUnwrap(store.articulos.first(where: { $0.nombre == "Papel de baño" }))

        store.alternarComprado(papel)
        XCTAssertEqual(store.articulosPorComprar, 3)

        store.alternarComprado(papel)
        XCTAssertEqual(store.articulosPorComprar, 4)

        store.alternarComprado(papel)
        XCTAssertEqual(store.articulosPorComprar, 3)

        store.limpiarComprados()
        XCTAssertFalse(store.articulos.contains(where: { $0.fueComprado }))
        // Quedan los 3 que seguían por comprar (Tortillas y Papel de baño se fueron).
        XCTAssertEqual(store.articulos.count, 3)
        XCTAssertEqual(store.articulosPorComprar, 3)
    }

    func testLosArticulosSeOrdenanPrimeroLosPendientes() {
        let store = crearStore().store
        let ordenados = store.articulosOrdenados
        XCTAssertEqual(ordenados.count, 5)
        XCTAssertEqual(ordenados.first?.nombre, "Huevo (30 pzas)")
        XCTAssertEqual(ordenados.last?.nombre, "Tortillas")
    }

    // MARK: - 9. Modo Compras

    func testActivarYTerminarModoCompras() throws {
        let creado = crearStore()
        let store = creado.store
        XCTAssertFalse(store.estoyDeCompras)

        store.activarModoCompras(lugar: "Chedraui")

        XCTAssertTrue(store.estoyDeCompras)
        let modo = try XCTUnwrap(store.modoCompras)
        XCTAssertEqual(modo.lugar, "Chedraui")
        XCTAssertEqual(modo.activadoPor, roberto)
        XCTAssertEqual(creado.notificador.enviadas.count, 1)
        let aviso = try XCTUnwrap(creado.notificador.enviadas.first)
        XCTAssertTrue(aviso.cuerpo.contains("Roberto"))
        XCTAssertTrue(aviso.cuerpo.contains("Chedraui"))
        let actividad = try XCTUnwrap(store.actividadesRecientes.first)
        XCTAssertEqual(actividad.tipo, .modoCompras)
        XCTAssertEqual(actividad.detalle, "Chedraui")

        store.terminarModoCompras()

        XCTAssertNil(store.modoCompras)
        XCTAssertFalse(store.estoyDeCompras)
    }

    func testSoloQuienActivoElModoComprasPuedeTerminarlo() {
        let store = crearStore().store
        XCTAssertNotNil(store.modoCompras)

        // El de ejemplo es de Mauricio y el usuario actual es Roberto.
        store.terminarModoCompras()
        XCTAssertNotNil(store.modoCompras)

        store.cambiarUsuarioActual(a: mauricio)
        XCTAssertTrue(store.estoyDeCompras)
        store.terminarModoCompras()
        XCTAssertNil(store.modoCompras)
    }

    func testElModoComprasDeEjemploCaducaDespuesDeDosHoras() {
        let momento = hoy
        let almacen = AlmacenEnMemoria(estadoInicial: DatosDeEjemplo.estado(hoy: momento))

        // El de ejemplo empezó 10 minutos antes de `hoy`: una hora después sigue vigente.
        let unaHoraDespues = momento.addingTimeInterval(60 * 60)
        let storeTemprano = HogarStore(almacen: almacen, notificador: NotificadorDePrueba(),
                                       reloj: { unaHoraDespues })
        XCTAssertNotNil(storeTemprano.modoCompras)

        // Tres horas después ya pasaron más de 2 horas desde su inicio.
        let tresHorasDespues = momento.addingTimeInterval(3 * 60 * 60)
        let storeTarde = HogarStore(almacen: almacen, notificador: NotificadorDePrueba(),
                                    reloj: { tresHorasDespues })
        XCTAssertNil(storeTarde.modoCompras)
        XCTAssertFalse(storeTarde.estoyDeCompras)
    }

    // MARK: - 10. Eventos

    func testAgregarEventoConTituloVacioNoHaceNada() {
        let store = crearStore().store
        let antes = store.estado

        store.agregarEvento(titulo: "   ", fecha: hoy, tipo: .evento)

        XCTAssertEqual(store.estado, antes)
        XCTAssertEqual(store.eventos.count, 3)
    }

    func testAgregarEventoConTituloValidoApareceEnSuDia() throws {
        let store = crearStore().store
        let dia = hoy
        XCTAssertFalse(store.hayEventos(en: dia))

        let alAnochecer = dia.addingTimeInterval(6 * 60 * 60)
        store.agregarEvento(titulo: "Noche de películas", fecha: alAnochecer, tipo: .evento)

        XCTAssertEqual(store.eventos.count, 4)
        XCTAssertTrue(store.hayEventos(en: dia))
        let delDia = store.eventos(en: dia)
        XCTAssertEqual(delDia.count, 1)
        XCTAssertEqual(delDia.first?.titulo, "Noche de películas")
        XCTAssertEqual(delDia.first?.creadoPor, roberto)
        let actividad = try XCTUnwrap(store.actividadesRecientes.first)
        XCTAssertEqual(actividad.tipo, .evento)
        XCTAssertEqual(actividad.texto, "apuntó Noche de películas")
    }

    func testLosEventosDeEjemploCaenEnSusDias() throws {
        let store = crearStore().store
        // Jueves 12 de noviembre: la junta de roomies. Viernes 13: nada.
        let jueves = try XCTUnwrap(Calendar.roomie.date(from: DateComponents(year: 2026, month: 11, day: 12, hour: 9)))
        let viernes = try XCTUnwrap(Calendar.roomie.date(from: DateComponents(year: 2026, month: 11, day: 13, hour: 9)))
        XCTAssertTrue(store.hayEventos(en: jueves))
        XCTAssertEqual(store.eventos(en: jueves).first?.titulo, "Junta de roomies")
        XCTAssertFalse(store.hayEventos(en: viernes))
    }

    // MARK: - 11. Cambiar de roomie

    func testCambiarDeRoomieCambiaElBalanceYLasTransferencias() {
        let store = crearStore().store

        store.cambiarUsuarioActual(a: sara)

        XCTAssertEqual(store.usuarioActual.id, sara)
        XCTAssertEqual(store.miBalance, -190, accuracy: 0.001)
        verificar(store.misTransferencias, [
            DeudaEsperada(de: sara, para: mauricio, monto: 140),
            DeudaEsperada(de: sara, para: roberto, monto: 50)
        ])
    }

    func testCambiarAUnRoomieQueNoExisteNoHaceNada() {
        let store = crearStore().store
        let antes = store.estado

        store.cambiarUsuarioActual(a: UUID())

        XCTAssertEqual(store.estado, antes)
        XCTAssertEqual(store.usuarioActual.id, roberto)
    }

    // MARK: - 12. Simular cambio de semana

    func testSimularCambioDeSemanaRotaLasTareas() throws {
        let store = crearStore().store
        let semanaAntes = store.inicioSemana

        store.simularCambioDeSemana()

        // Orden de rotación: Roberto -> Sara -> Mauricio -> Ana -> Roberto.
        XCTAssertEqual(try tarea("Limpiar baño", en: store).asignadoA, sara)
        XCTAssertEqual(try tarea("Trapear pasillo", en: store).asignadoA, sara)
        XCTAssertEqual(try tarea("Sacar la basura", en: store).asignadoA, mauricio)
        XCTAssertEqual(try tarea("Aspirar la sala", en: store).asignadoA, roberto)
        XCTAssertEqual(try tarea("Lavar trastes", en: store).asignadoA, ana)

        XCTAssertFalse(store.tareas.contains(where: { $0.completada }))
        XCTAssertEqual(store.tareasCompletadas, 0)
        XCTAssertEqual(store.inicioSemana, Calendar.roomie.sumar(dias: 7, a: semanaAntes))
    }

    // MARK: - 13. Persistencia y restablecer

    func testCadaCambioSeGuardaEnElAlmacen() {
        let creado = crearStore()

        creado.store.agregarArticulo("Pan")

        XCTAssertEqual(creado.almacen.estadoGuardado, creado.store.estado)
        XCTAssertEqual(creado.almacen.vecesGuardado, 2)
    }

    func testUnCambioQueNoCambiaNadaNoSeGuarda() {
        let creado = crearStore()
        let guardadosAntes = creado.almacen.vecesGuardado

        creado.store.agregarArticulo("  ")
        creado.store.limpiarComprados()
        creado.store.limpiarComprados()

        // `limpiarComprados` la primera vez sí quita "Tortillas".
        XCTAssertEqual(creado.almacen.vecesGuardado, guardadosAntes + 1)
    }

    func testUnSegundoStoreArrancaConLoQueSeGuardo() {
        let creado = crearStore()
        creado.store.agregarArticulo("Pan")
        creado.store.cambiarUsuarioActual(a: sara)

        let momento = hoy
        let segundo = HogarStore(almacen: creado.almacen, notificador: NotificadorDePrueba(),
                                 reloj: { momento })

        XCTAssertEqual(segundo.estado, creado.store.estado)
        XCTAssertEqual(segundo.usuarioActual.id, sara)
        XCTAssertEqual(segundo.articulosPorComprar, 5)
    }

    func testRestablecerDatosDeEjemploRegresaAlEstadoOriginal() {
        let creado = crearStore()
        let store = creado.store
        store.agregarGasto(descripcion: "Pizza", montoTotal: 300, categoria: .otro,
                           pagadoPor: roberto, divididoEntre: todos)
        store.agregarArticulo("Pan")
        store.cambiarUsuarioActual(a: ana)
        XCTAssertNotEqual(store.estado, DatosDeEjemplo.estado(hoy: hoy))

        store.restablecerDatosDeEjemplo()

        XCTAssertEqual(store.estado, DatosDeEjemplo.estado(hoy: hoy))
        XCTAssertEqual(creado.almacen.estadoGuardado, store.estado)
        XCTAssertEqual(store.usuarioActual.id, roberto)
    }

    func testElStoreDeEjemploUsaLosDatosDeEjemplo() {
        let store = HogarStore.deEjemplo(hoy: hoy)
        XCTAssertEqual(store.estado, DatosDeEjemplo.estado(hoy: hoy))
        XCTAssertEqual(store.ahora, hoy)
    }

    func testUnAlmacenConUnaVersionDistintaSeDescartaYArrancaConLosDatosDeEjemplo() {
        let momento = hoy
        var viejo = DatosDeEjemplo.estado(hoy: momento)
        viejo.version = EstadoHogar.versionActual + 1
        viejo.nombreHogar = "Depa viejo"
        let almacen = AlmacenEnMemoria(estadoInicial: viejo)

        let store = HogarStore(almacen: almacen, notificador: NotificadorDePrueba(), reloj: { momento })

        XCTAssertEqual(store.nombreHogar, "Depa Mixcoac")
        XCTAssertEqual(store.estado.version, EstadoHogar.versionActual)
    }
}
