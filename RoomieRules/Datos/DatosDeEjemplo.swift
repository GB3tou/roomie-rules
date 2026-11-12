import Foundation

/// El depa de las pantallas de diseño, listo para usarse como datos iniciales de la app,
/// de las vistas previas y de las pruebas.
///
/// Las fechas son relativas al día en que se abre la app (tareas de esta semana, gastos de
/// este mes…), para que la demo siempre se vea viva.
enum DatosDeEjemplo {

    // MARK: - Roomies

    /// ID fijo de Roberto, el usuario actual de la demo.
    static let robertoID = UUID(uuidString: "11111111-1111-4111-8111-111111111111")!
    /// ID fijo de Sara.
    static let saraID = UUID(uuidString: "22222222-2222-4222-8222-222222222222")!
    /// ID fijo de Mauricio.
    static let mauricioID = UUID(uuidString: "33333333-3333-4333-8333-333333333333")!
    /// ID fijo de Ana.
    static let anaID = UUID(uuidString: "44444444-4444-4444-8444-444444444444")!

    /// Los cuatro roomies, en el orden en que rotan las tareas.
    static let usuarios: [Usuario] = [
        Usuario(id: robertoID, nombre: "Roberto", colorAvatar: .verde),
        Usuario(id: saraID, nombre: "Sara", colorAvatar: .morado),
        Usuario(id: mauricioID, nombre: "Mauricio", colorAvatar: .naranja),
        Usuario(id: anaID, nombre: "Ana", colorAvatar: .azul),
    ]

    // MARK: - Estado completo

    /// El depa de ejemplo con fechas relativas a `hoy`. Para la misma fecha devuelve siempre
    /// exactamente lo mismo (todos los IDs son fijos).
    ///
    /// - Parameters:
    ///   - hoy: el momento en que "se abre la app".
    ///   - calendario: calendario para las cuentas de días y semanas (por defecto, el de la app).
    static func estado(hoy: Date, calendario: Calendar = Calendar.roomie) -> EstadoHogar {
        let inicioDeHoy = calendario.startOfDay(for: hoy)
        let lunes = calendario.inicioDeSemana(para: hoy)
        let todos = usuarios.map { $0.id }

        // --- Tareas de la semana ---

        // Si el viernes o el sábado ya pasaron (la demo se abre en fin de semana), la tarea vence
        // hoy, para que la app no arranque con tareas atrasadas. El domingo nunca queda atrás.
        let viernes = max(calendario.sumar(dias: 4, a: lunes), inicioDeHoy)
        let sabado = max(calendario.sumar(dias: 5, a: lunes), inicioDeHoy)
        let domingo = calendario.sumar(dias: 6, a: lunes)

        let lavarTrastes = Tarea(id: idFijo(1, 5), titulo: "Lavar trastes", area: .cocina, asignadoA: mauricioID,
                                 completada: true, fechaLim: inicioDeHoy, frecuencia: .diaria)
        let tareas: [Tarea] = [
            Tarea(id: idFijo(1, 1), titulo: "Limpiar baño", area: .bano, asignadoA: robertoID, fechaLim: viernes),
            Tarea(id: idFijo(1, 2), titulo: "Trapear pasillo", area: .comunes, asignadoA: robertoID, fechaLim: domingo),
            Tarea(id: idFijo(1, 3), titulo: "Sacar la basura", area: .cocina, asignadoA: saraID, fechaLim: inicioDeHoy),
            Tarea(id: idFijo(1, 4), titulo: "Aspirar la sala", area: .sala, asignadoA: anaID, fechaLim: sabado),
            lavarTrastes,
        ]

        // --- Gastos del mes, todos repartidos entre los cuatro ---
        // Total $3,160 → a cada quien le tocan $790 → a Roberto, que pagó $840, le deben $50.

        let inicioDelMes = calendario.dateInterval(of: .month, for: hoy)?.start ?? inicioDeHoy

        // `indice` 0 es el gasto más nuevo. Si "hace N días" cae en el mes pasado (la demo se abre
        // a principios de mes), el gasto se registra el día 1 de este mes, separado un minuto del
        // siguiente para conservar el orden. Así el total del mes siempre es $3,160.
        func fechaDeGasto(_ indice: Int, haceDias dias: Int) -> Date {
            let deseada = calendario.sumar(dias: -dias, a: hoy)
            let minima = inicioDelMes.addingTimeInterval(TimeInterval((3 - indice) * 60))
            return max(deseada, minima)
        }

        let luz = Gasto(id: idFijo(2, 1), descripcion: "Recibo de luz", montoTotal: 840, pagadoPor: robertoID,
                        divididoEntre: todos, fecha: fechaDeGasto(0, haceDias: 1), categoria: .servicios)
        let internet = Gasto(id: idFijo(2, 2), descripcion: "Internet", montoTotal: 600, pagadoPor: saraID,
                             divididoEntre: todos, fecha: fechaDeGasto(1, haceDias: 3), categoria: .servicios)
        let superSemanal = Gasto(id: idFijo(2, 3), descripcion: "Súper semanal", montoTotal: 1240, pagadoPor: mauricioID,
                                 divididoEntre: todos, fecha: fechaDeGasto(2, haceDias: 5), categoria: .supermercado)
        let gas = Gasto(id: idFijo(2, 4), descripcion: "Tanque de gas", montoTotal: 480, pagadoPor: anaID,
                        divididoEntre: todos, fecha: fechaDeGasto(3, haceDias: 8), categoria: .servicios)

        // --- Lista del súper, en el orden en que se fue agregando ---

        let articulos: [ArtSuper] = [
            ArtSuper(id: idFijo(3, 1), nombre: "Huevo (30 pzas)", agregadoPor: saraID,
                     fechaAgregado: hace(minutos: 26 * 60, desde: hoy)),
            ArtSuper(id: idFijo(3, 2), nombre: "Papel de baño", agregadoPor: anaID,
                     fechaAgregado: hace(minutos: 20 * 60, desde: hoy)),
            ArtSuper(id: idFijo(3, 3), nombre: "Leche deslactosada", agregadoPor: robertoID,
                     fechaAgregado: hace(minutos: 8 * 60, desde: hoy)),
            ArtSuper(id: idFijo(3, 4), nombre: "Jabón para trastes", agregadoPor: mauricioID,
                     fechaAgregado: hace(minutos: 3 * 60, desde: hoy)),
            ArtSuper(id: idFijo(3, 5), nombre: "Tortillas", fueComprado: true, agregadoPor: saraID,
                     fechaAgregado: hace(minutos: 60, desde: hoy)),
        ]

        // --- Modo Compras: Mauricio salió al súper hace 10 minutos ---

        let lugarDeCompras = "Walmart Universidad"
        let modoCompras = ModoCompras(activadoPor: mauricioID, lugar: lugarDeCompras,
                                      inicio: hace(minutos: 10, desde: hoy))

        // --- Lo que pasa en casa, de lo más nuevo a lo más viejo ---
        // Los textos se arman igual que en `HogarStore`, para que se comporten como los reales
        // (por ejemplo, al quitar la palomita de "Lavar trastes" se retira su línea).

        let actividades: [Actividad] = [
            Actividad(id: idFijo(5, 1), tipo: .modoCompras, usuarioID: mauricioID,
                      texto: "activó Modo Compras", detalle: lugarDeCompras,
                      fecha: hace(minutos: 10, desde: hoy)),
            Actividad(id: idFijo(5, 2), tipo: .gasto, usuarioID: saraID,
                      texto: "registró \(internet.descripcion) · \(Formato.dinero(internet.montoTotal))",
                      gastoID: internet.id, fecha: hace(minutos: 2 * 60, desde: hoy)),
            Actividad(id: idFijo(5, 3), tipo: .tareaCompletada, usuarioID: mauricioID,
                      texto: "completó \(lavarTrastes.titulo)", detalle: lavarTrastes.area.nombre,
                      fecha: hace(minutos: 5 * 60, desde: hoy)),
            Actividad(id: idFijo(5, 4), tipo: .gasto, usuarioID: robertoID,
                      texto: "registró \(luz.descripcion) · \(Formato.dinero(luz.montoTotal))",
                      gastoID: luz.id, fecha: hace(minutos: 24 * 60, desde: hoy)),
        ]

        // --- Calendario del depa ---

        // `dia` cuenta desde el lunes de esta semana: 3 = jueves, 5 = sábado, 8 = martes siguiente.
        func fechaDeEvento(dia: Int, hora: Int) -> Date {
            let inicioDelDia = calendario.sumar(dias: dia, a: lunes)
            return calendario.date(bySettingHour: hora, minute: 0, second: 0, of: inicioDelDia) ?? inicioDelDia
        }

        let eventos: [Evento] = [
            Evento(id: idFijo(4, 1), titulo: "Junta de roomies", fecha: fechaDeEvento(dia: 3, hora: 20),
                   tipo: .evento, creadoPor: robertoID),
            Evento(id: idFijo(4, 2), titulo: "Visita de los papás de Sara", fecha: fechaDeEvento(dia: 5, hora: 14),
                   tipo: .visita, creadoPor: saraID),
            Evento(id: idFijo(4, 3), titulo: "Viene el plomero", fecha: fechaDeEvento(dia: 8, hora: 10),
                   tipo: .servicio, creadoPor: anaID),
        ]

        return EstadoHogar(
            nombreHogar: "Depa Mixcoac",
            usuarios: usuarios,
            usuarioActualID: robertoID,
            tareas: tareas,
            gastos: [luz, internet, superSemanal, gas],
            articulos: articulos,
            eventos: eventos,
            actividades: actividades,
            modoCompras: modoCompras,
            inicioSemanaRotacion: lunes,
            ultimaRevisionDiaria: inicioDeHoy
        )
    }

    // MARK: - Ayudantes

    /// El momento que fue `minutos` minutos antes de `hoy`.
    private static func hace(minutos: Int, desde hoy: Date) -> Date {
        hoy.addingTimeInterval(TimeInterval(-minutos * 60))
    }

    /// ID fijo para un dato de ejemplo: `grupo` dice qué es (1 tareas, 2 gastos, 3 artículos,
    /// 4 eventos, 5 actividades) y `numero` cuál de ellos. Se arma con los 16 bytes del UUID
    /// en vez de con un texto para no necesitar un `!` por cada dato.
    private static func idFijo(_ grupo: UInt8, _ numero: UInt8) -> UUID {
        UUID(uuid: (0xD0, 0xDA, 0x70, 0x05, 0x00, 0x00, 0x40, 0x00,
                    0x80, 0x00, 0x00, 0x00, 0x00, 0x00, grupo, numero))
    }
}
