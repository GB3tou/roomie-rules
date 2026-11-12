import XCTest
@testable import RoomieRules

/// Pruebas de la rotación semanal y del reinicio diario de tareas.
/// Referencia: el lunes 9 de noviembre de 2026 es lunes; esa semana va del 9 al 15.
final class RotadorDeTareasTests: XCTestCase {
    // MARK: - Datos de prueba propios (no dependen de DatosDeEjemplo)

    private let calendario = Calendar.roomie

    private let roberto = Usuario(nombre: "Roberto", colorAvatar: .verde)
    private let sara = Usuario(nombre: "Sara", colorAvatar: .morado)
    private let mauricio = Usuario(nombre: "Mauricio", colorAvatar: .naranja)
    private let ana = Usuario(nombre: "Ana", colorAvatar: .azul)

    private var usuarios: [Usuario] {
        [roberto, sara, mauricio, ana]
    }

    private func fecha(_ dia: Int, mes: Int = 11, hora: Int = 10) -> Date {
        calendario.date(from: DateComponents(year: 2026, month: mes, day: dia, hour: hora)) ?? Date.distantPast
    }

    /// Lunes 9 de noviembre de 2026 a las 00:00.
    private var lunes9: Date {
        calendario.inicioDeSemana(para: fecha(9))
    }

    /// Las 5 tareas de la semana del 9: asignadas a R, R, S, A y M (la última es diaria).
    private func tareasDeLaSemana(diariaVence: Date) -> [Tarea] {
        [
            Tarea(titulo: "Limpiar baño", area: .bano, asignadoA: roberto.id, completada: true,
                  fechaLim: fecha(13, hora: 23), ultimoToque: fecha(12)),
            Tarea(titulo: "Trapear pasillo", area: .comunes, asignadoA: roberto.id,
                  fechaLim: fecha(15, hora: 23)),
            Tarea(titulo: "Sacar la basura", area: .cocina, asignadoA: sara.id,
                  fechaLim: fecha(11, hora: 23), ultimoToque: fecha(11, hora: 9)),
            Tarea(titulo: "Aspirar la sala", area: .sala, asignadoA: ana.id, completada: true,
                  fechaLim: fecha(14, hora: 23)),
            Tarea(titulo: "Lavar trastes", area: .cocina, asignadoA: mauricio.id, completada: true,
                  fechaLim: diariaVence, frecuencia: .diaria, ultimoToque: fecha(10, hora: 20)),
        ]
    }

    // MARK: - rotar

    func testRotarUnaSemana() {
        let tareas = tareasDeLaSemana(diariaVence: calendario.startOfDay(for: fecha(11)))
        let rotadas = RotadorDeTareas.rotar(tareas, usuarios: usuarios, semanas: 1, calendario: calendario)

        XCTAssertEqual(rotadas.map { $0.asignadoA }, [sara.id, sara.id, mauricio.id, roberto.id, ana.id])
        XCTAssertEqual(rotadas.count, tareas.count)
        for (original, rotada) in zip(tareas, rotadas) {
            XCTAssertEqual(rotada.id, original.id)
            XCTAssertEqual(rotada.titulo, original.titulo)
            XCTAssertFalse(rotada.completada)
            XCTAssertNil(rotada.ultimoToque)
            XCTAssertEqual(rotada.fechaLim, calendario.sumar(dias: 7, a: original.fechaLim))
        }
        // Comprobación explícita: el viernes 13 pasa al viernes 20.
        XCTAssertEqual(rotadas[0].fechaLim, fecha(20, hora: 23))
    }

    func testRotarCuatroSemanasRegresaALosResponsablesOriginales() {
        let tareas = tareasDeLaSemana(diariaVence: calendario.startOfDay(for: fecha(11)))
        let rotadas = RotadorDeTareas.rotar(tareas, usuarios: usuarios, semanas: 4, calendario: calendario)
        XCTAssertEqual(rotadas.map { $0.asignadoA }, tareas.map { $0.asignadoA })
        XCTAssertEqual(rotadas[0].fechaLim, fecha(11, mes: 12, hora: 23))
    }

    func testRotarCeroSemanasNoCambiaNada() {
        let tareas = tareasDeLaSemana(diariaVence: calendario.startOfDay(for: fecha(11)))
        XCTAssertEqual(RotadorDeTareas.rotar(tareas, usuarios: usuarios, semanas: 0, calendario: calendario), tareas)
    }

    func testRotarSinUsuariosNoCambiaNada() {
        let tareas = tareasDeLaSemana(diariaVence: calendario.startOfDay(for: fecha(11)))
        XCTAssertEqual(RotadorDeTareas.rotar(tareas, usuarios: [], semanas: 2, calendario: calendario), tareas)
    }

    func testRotarResponsableDesconocidoEmpiezaDesdeElPrimero() {
        let tarea = Tarea(titulo: "Regar plantas", area: .sala, asignadoA: UUID(), fechaLim: fecha(13))
        let rotadas = RotadorDeTareas.rotar([tarea], usuarios: usuarios, semanas: 1, calendario: calendario)
        XCTAssertEqual(rotadas.first?.asignadoA, sara.id)
    }

    // MARK: - actualizar

    func testActualizarMismoDiaNoCambiaNada() {
        let hoy = fecha(11, hora: 18)
        let tareas = tareasDeLaSemana(diariaVence: calendario.startOfDay(for: hoy))
        let resultado = RotadorDeTareas.actualizar(tareas: tareas, usuarios: usuarios,
                                                   inicioSemanaRegistrado: lunes9,
                                                   ultimaRevisionDiaria: fecha(11, hora: 7),
                                                   hoy: hoy, calendario: calendario)
        XCTAssertEqual(resultado.tareas, tareas)
        XCTAssertEqual(resultado.semanasRotadas, 0)
        XCTAssertEqual(resultado.inicioSemana, lunes9)
        XCTAssertEqual(resultado.ultimaRevisionDiaria, calendario.startOfDay(for: hoy))
    }

    func testActualizarOtroDiaDeLaMismaSemanaDesmarcaSoloLaDiaria() {
        let hoy = fecha(12, hora: 9)
        let tareas = tareasDeLaSemana(diariaVence: calendario.startOfDay(for: fecha(11)))
        let resultado = RotadorDeTareas.actualizar(tareas: tareas, usuarios: usuarios,
                                                   inicioSemanaRegistrado: lunes9,
                                                   ultimaRevisionDiaria: calendario.startOfDay(for: fecha(11)),
                                                   hoy: hoy, calendario: calendario)
        XCTAssertEqual(resultado.semanasRotadas, 0)
        XCTAssertEqual(resultado.inicioSemana, lunes9)
        XCTAssertEqual(resultado.ultimaRevisionDiaria, calendario.startOfDay(for: hoy))

        // Las semanales quedan exactamente igual.
        XCTAssertEqual(Array(resultado.tareas.prefix(4)), Array(tareas.prefix(4)))

        // La diaria se desmarca, pierde su toque y vence hoy; sigue con el mismo responsable.
        let diaria = resultado.tareas[4]
        XCTAssertFalse(diaria.completada)
        XCTAssertNil(diaria.ultimoToque)
        XCTAssertEqual(diaria.asignadoA, mauricio.id)
        XCTAssertEqual(diaria.fechaLim, calendario.startOfDay(for: hoy))
    }

    func testActualizarElLunesSiguienteRotaUnaSemana() {
        let hoy = fecha(16, hora: 8)
        let tareas = tareasDeLaSemana(diariaVence: calendario.startOfDay(for: fecha(15)))
        let resultado = RotadorDeTareas.actualizar(tareas: tareas, usuarios: usuarios,
                                                   inicioSemanaRegistrado: lunes9,
                                                   ultimaRevisionDiaria: calendario.startOfDay(for: fecha(15)),
                                                   hoy: hoy, calendario: calendario)
        XCTAssertEqual(resultado.semanasRotadas, 1)
        XCTAssertEqual(resultado.inicioSemana, calendario.startOfDay(for: fecha(16)))
        XCTAssertEqual(resultado.ultimaRevisionDiaria, calendario.startOfDay(for: hoy))
        XCTAssertEqual(resultado.tareas.map { $0.asignadoA }, [sara.id, sara.id, mauricio.id, roberto.id, ana.id])
        XCTAssertEqual(resultado.tareas[0].fechaLim, fecha(20, hora: 23))
        XCTAssertTrue(resultado.tareas.allSatisfy { !$0.completada && $0.ultimoToque == nil })
        XCTAssertEqual(resultado.tareas[4].fechaLim, calendario.startOfDay(for: hoy))
    }

    func testActualizarTresSemanasDespues() {
        // Miércoles 2 de diciembre: su semana empieza el lunes 30 de noviembre (3 semanas después del 9).
        let hoy = fecha(2, mes: 12, hora: 13)
        let tareas = tareasDeLaSemana(diariaVence: calendario.startOfDay(for: fecha(12)))
        let resultado = RotadorDeTareas.actualizar(tareas: tareas, usuarios: usuarios,
                                                   inicioSemanaRegistrado: lunes9,
                                                   ultimaRevisionDiaria: calendario.startOfDay(for: fecha(12)),
                                                   hoy: hoy, calendario: calendario)
        XCTAssertEqual(resultado.semanasRotadas, 3)
        XCTAssertEqual(resultado.inicioSemana, calendario.startOfDay(for: fecha(30)))
        // R(0)+3 → A, S(1)+3 → R, A(3)+3 → M, M(2)+3 → S.
        XCTAssertEqual(resultado.tareas.map { $0.asignadoA }, [ana.id, ana.id, roberto.id, mauricio.id, sara.id])
        XCTAssertEqual(resultado.tareas[0].fechaLim, fecha(4, mes: 12, hora: 23))
        XCTAssertEqual(resultado.tareas[4].fechaLim, calendario.startOfDay(for: hoy))
    }

    func testActualizarConHoyAnteriorALaSemanaRegistradaNoRota() {
        // La semana registrada va adelantada (por ejemplo, tras simular el cambio de semana).
        let lunes16 = calendario.startOfDay(for: fecha(16))
        let hoy = fecha(11, hora: 18)
        let tareas = tareasDeLaSemana(diariaVence: calendario.startOfDay(for: fecha(10)))
        let resultado = RotadorDeTareas.actualizar(tareas: tareas, usuarios: usuarios,
                                                   inicioSemanaRegistrado: lunes16,
                                                   ultimaRevisionDiaria: fecha(11, hora: 7),
                                                   hoy: hoy, calendario: calendario)
        XCTAssertEqual(resultado.semanasRotadas, 0)
        XCTAssertEqual(resultado.inicioSemana, lunes16)
        XCTAssertEqual(resultado.tareas.map { $0.asignadoA }, tareas.map { $0.asignadoA })
        XCTAssertEqual(Array(resultado.tareas.prefix(4)), Array(tareas.prefix(4)))

        // Mismo día que la última revisión: la diaria conserva su palomita, pero vence hoy.
        let diaria = resultado.tareas[4]
        XCTAssertTrue(diaria.completada)
        XCTAssertNotNil(diaria.ultimoToque)
        XCTAssertEqual(diaria.fechaLim, calendario.startOfDay(for: hoy))
    }

    func testActualizarSiemprePoneLaDiariaParaHoy() {
        // Aunque sea el mismo día, si la diaria tenía otra fecha límite se corrige a hoy.
        let hoy = fecha(13, hora: 22)
        let tareas = tareasDeLaSemana(diariaVence: fecha(9, hora: 15))
        let resultado = RotadorDeTareas.actualizar(tareas: tareas, usuarios: usuarios,
                                                   inicioSemanaRegistrado: lunes9,
                                                   ultimaRevisionDiaria: fecha(13, hora: 6),
                                                   hoy: hoy, calendario: calendario)
        XCTAssertEqual(resultado.semanasRotadas, 0)
        XCTAssertEqual(resultado.tareas[4].fechaLim, calendario.startOfDay(for: hoy))
        XCTAssertTrue(resultado.tareas[4].completada)
    }
}
