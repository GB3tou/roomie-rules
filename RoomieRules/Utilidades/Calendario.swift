import Foundation

extension Locale {
    /// Idioma y región de la app: español de México.
    /// Se usa en todos los formatos de fecha y dinero para que la app se vea igual
    /// sin importar el idioma del teléfono o del simulador.
    static let roomie = Locale(identifier: "es_MX")
}

extension Calendar {
    /// Calendario de la app: gregoriano, en español y con la semana empezando en **lunes**
    /// (la rotación de tareas cambia cada lunes).
    static let roomie: Calendar = {
        var calendario = Calendar(identifier: .gregorian)
        calendario.locale = Locale.roomie
        calendario.firstWeekday = 2
        calendario.minimumDaysInFirstWeek = 4
        return calendario
    }()

    /// Lunes (a las 00:00) de la semana que contiene `fecha`.
    func inicioDeSemana(para fecha: Date) -> Date {
        dateInterval(of: .weekOfYear, for: fecha)?.start ?? startOfDay(for: fecha)
    }

    /// Los 7 días, de lunes a domingo (cada uno a las 00:00), de la semana que contiene `fecha`.
    func diasDeLaSemana(para fecha: Date) -> [Date] {
        let lunes = inicioDeSemana(para: fecha)
        return (0..<7).compactMap { date(byAdding: .day, value: $0, to: lunes) }
    }

    /// Domingo (a las 00:00) de la semana que contiene `fecha`.
    func finDeSemana(para fecha: Date) -> Date {
        sumar(dias: 6, a: inicioDeSemana(para: fecha))
    }

    /// Devuelve `fecha` movida `dias` días (negativo = hacia atrás).
    func sumar(dias: Int, a fecha: Date) -> Date {
        date(byAdding: .day, value: dias, to: fecha) ?? fecha
    }

    /// Cuántas semanas hay entre la semana de `inicio` y la semana de `fin`.
    /// Es 0 si ambas fechas caen en la misma semana y negativo si `fin` es anterior.
    func semanasEntre(_ inicio: Date, y fin: Date) -> Int {
        let lunesInicio = inicioDeSemana(para: inicio)
        let lunesFin = inicioDeSemana(para: fin)
        let dias = dateComponents([.day], from: lunesInicio, to: lunesFin).day ?? 0
        return dias / 7
    }

    /// `true` si las dos fechas caen en el mismo día.
    func esMismoDia(_ a: Date, _ b: Date) -> Bool {
        isDate(a, inSameDayAs: b)
    }

    /// `true` si las dos fechas caen en el mismo mes del mismo año.
    func esMismoMes(_ a: Date, _ b: Date) -> Bool {
        isDate(a, equalTo: b, toGranularity: .month)
    }
}
