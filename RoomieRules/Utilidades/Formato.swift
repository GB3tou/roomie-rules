import Foundation

/// Textos listos para mostrar en pantalla: dinero, fechas y vencimientos de tareas.
///
/// Todo sale en español de México y con el calendario de la app (`Locale.roomie` y
/// `Calendar.roomie`), sin importar el idioma o la región configurados en el teléfono.
enum Formato {

    // MARK: - Dinero

    /// Monto en pesos: sin decimales si es entero al centavo y con dos si no.
    /// Ej. "$840", "$3,160", "$52.50". Los negativos llevan el signo delante: "-$50".
    static func dinero(_ monto: Double) -> String {
        let centavos = centavosRedondeados(monto)
        return textoDeDinero(centavos: centavos, conCentavos: centavos % 100 != 0)
    }

    /// Monto en pesos siempre con dos decimales. Ej. "$210.00", "-$52.50".
    static func dineroExacto(_ monto: Double) -> String {
        textoDeDinero(centavos: centavosRedondeados(monto), conCentavos: true)
    }

    // MARK: - Fechas

    /// Día de la semana abreviado y número del día, en minúsculas. Ej. "vie 13".
    static func diaCorto(_ fecha: Date) -> String {
        enMinusculasSinPuntos(formatoDiaCorto.string(from: fecha))
    }

    /// Día de la semana completo y número del día, en minúsculas. Ej. "viernes 13".
    static func diaLargo(_ fecha: Date) -> String {
        enMinusculasSinPuntos(formatoDiaLargo.string(from: fecha))
    }

    /// Nombre del día de la semana con mayúscula inicial. Ej. "Viernes".
    static func diaSemana(_ fecha: Date) -> String {
        conMayusculaInicial(enMinusculasSinPuntos(formatoDiaSemana.string(from: fecha)))
    }

    /// Día de la semana abreviado con mayúscula inicial. Ej. "Vie".
    static func diaSemanaAbreviado(_ fecha: Date) -> String {
        conMayusculaInicial(enMinusculasSinPuntos(formatoDiaSemanaAbreviado.string(from: fecha)))
    }

    /// Número del día del mes. Ej. "13".
    static func numeroDeDia(_ fecha: Date) -> String {
        formatoNumeroDeDia.string(from: fecha)
    }

    /// Día y mes abreviado, en minúsculas. Ej. "10 nov".
    static func diaYMes(_ fecha: Date) -> String {
        enMinusculasSinPuntos(formatoDiaYMes.string(from: fecha))
    }

    /// Nombre del mes con mayúscula inicial. Ej. "Noviembre".
    static func mes(_ fecha: Date) -> String {
        conMayusculaInicial(nombreDeMes(fecha))
    }

    /// Hora en formato de 24 horas. Ej. "20:00".
    static func hora(_ fecha: Date) -> String {
        formatoHora.string(from: fecha)
    }

    /// Semana (de lunes a domingo) que empieza en `inicio`. Ej. "Semana del 9 al 15 de noviembre";
    /// si cruza de mes, "Semana del 30 de noviembre al 6 de diciembre".
    static func rangoSemana(inicio: Date) -> String {
        let calendario = Calendar.roomie
        // Normalmente `inicio` ya es lunes; si llega otro día, se usa el lunes de su semana.
        let lunes = calendario.inicioDeSemana(para: inicio)
        let domingo = calendario.finDeSemana(para: lunes)
        let primerDia = numeroDeDia(lunes)
        let ultimoDia = numeroDeDia(domingo)
        let mesFinal = nombreDeMes(domingo)
        if calendario.esMismoMes(lunes, domingo) {
            return "Semana del \(primerDia) al \(ultimoDia) de \(mesFinal)"
        }
        return "Semana del \(primerDia) de \(nombreDeMes(lunes)) al \(ultimoDia) de \(mesFinal)"
    }

    /// Hace cuánto pasó algo, contado desde `ahora`.
    /// Ej. "Ahora" (menos de 1 minuto), "Hace 10 min", "Hace 2 h", "Ayer", "Hace 3 d" y,
    /// a partir de una semana, la fecha: "3 nov".
    static func tiempoRelativo(_ fecha: Date, ahora: Date) -> String {
        let segundos = ahora.timeIntervalSince(fecha)
        // También cubre fechas un poco "en el futuro" (relojes desfasados): se muestran como "Ahora".
        if segundos < 60 {
            return "Ahora"
        }
        // De una semana en adelante se muestra la fecha.
        let unaSemana: TimeInterval = 7 * 24 * 60 * 60
        guard segundos < unaSemana else {
            return diaYMes(fecha)
        }
        let minutos = Int(segundos / 60)
        if minutos < 60 {
            return "Hace \(minutos) min"
        }
        let horas = minutos / 60
        if horas < 24 {
            return "Hace \(horas) h"
        }
        let dias = horas / 24
        return dias == 1 ? "Ayer" : "Hace \(dias) d"
    }

    // MARK: - Vencimiento de tareas

    /// Vencimiento en una o dos palabras, para listas.
    /// "diario" (tarea diaria) | "hoy" | "mañana" | "vie 13" (cualquier otra fecha, futura o pasada).
    static func vencimientoCorto(de tarea: Tarea, hoy: Date) -> String {
        if tarea.frecuencia == .diaria {
            return "diario"
        }
        let dias = diasDesde(hoy, hasta: tarea.fechaLim)
        if dias == 0 {
            return "hoy"
        }
        if dias == 1 {
            return "mañana"
        }
        return diaCorto(tarea.fechaLim)
    }

    /// Vencimiento como frase, para detalles y recordatorios.
    /// "todos los días" (tarea diaria) | "vence hoy" | "vence mañana" | "vence viernes 13" |
    /// "venció viernes 13" (pendiente y con la fecha ya pasada) |
    /// "vencía viernes 13" (ya completada y con la fecha ya pasada).
    static func vencimientoLargo(de tarea: Tarea, hoy: Date) -> String {
        if tarea.frecuencia == .diaria {
            return "todos los días"
        }
        let dias = diasDesde(hoy, hasta: tarea.fechaLim)
        if dias == 0 {
            return "vence hoy"
        }
        if dias == 1 {
            return "vence mañana"
        }
        let dia = diaLargo(tarea.fechaLim)
        if dias > 1 {
            return "vence \(dia)"
        }
        // La fecha ya pasó. Si la tarea se cumplió no tiene caso decir que "venció".
        return tarea.completada ? "vencía \(dia)" : "venció \(dia)"
    }

    /// Etiqueta de una palabra para la píldora de la tarea.
    /// "Diario" (tarea diaria) | "Hoy" | "Mañana" | "Atrasada" (pendiente y con la fecha ya pasada,
    /// igual que `Tarea.estaAtrasada`) | "Viernes" (el día de la semana, en cualquier otro caso).
    static func etiquetaVencimiento(de tarea: Tarea, hoy: Date) -> String {
        if tarea.frecuencia == .diaria {
            return "Diario"
        }
        let dias = diasDesde(hoy, hasta: tarea.fechaLim)
        if dias == 0 {
            return "Hoy"
        }
        if dias == 1 {
            return "Mañana"
        }
        if dias < 0 && !tarea.completada {
            return "Atrasada"
        }
        return diaSemana(tarea.fechaLim)
    }

    // MARK: - Ayudantes de dinero

    /// Redondea al centavo más cercano. Devuelve 0 con valores que no se pueden mostrar
    /// (NaN, infinito o montos gigantescos), porque convertirlos a `Int` tronaría la app.
    private static func centavosRedondeados(_ monto: Double) -> Int {
        let centavos = (monto * 100).rounded()
        guard centavos.isFinite, abs(centavos) < 1e17 else { return 0 }
        return Int(centavos)
    }

    /// Arma el texto a partir de centavos enteros, para que el redondeo sea exacto.
    /// Los separadores son fijos ("," para miles y "." para decimales), que es como se escribe
    /// el dinero en México; así no dependen de la configuración regional del teléfono.
    private static func textoDeDinero(centavos: Int, conCentavos: Bool) -> String {
        let signo = centavos < 0 ? "-" : ""
        let valor = abs(centavos)
        var texto = signo + "$" + conSeparadorDeMiles(valor / 100)
        if conCentavos {
            let resto = valor % 100
            texto += resto < 10 ? ".0\(resto)" : ".\(resto)"
        }
        return texto
    }

    /// Escribe un entero no negativo con una coma cada tres cifras. Ej. 3160 → "3,160".
    private static func conSeparadorDeMiles(_ numero: Int) -> String {
        let cifras = Array(String(numero))
        var texto = ""
        for (indice, cifra) in cifras.enumerated() {
            let cifrasRestantes = cifras.count - indice
            if indice > 0 && cifrasRestantes % 3 == 0 {
                texto.append(",")
            }
            texto.append(cifra)
        }
        return texto
    }

    // MARK: - Ayudantes de fechas

    /// Días de calendario desde `hoy` hasta `fecha`: 0 = hoy, 1 = mañana, negativo = ya pasó.
    private static func diasDesde(_ hoy: Date, hasta fecha: Date) -> Int {
        let calendario = Calendar.roomie
        let inicioDeHoy = calendario.startOfDay(for: hoy)
        let inicioDeFecha = calendario.startOfDay(for: fecha)
        return calendario.dateComponents([.day], from: inicioDeHoy, to: inicioDeFecha).day ?? 0
    }

    /// Nombre del mes en minúsculas. Ej. "noviembre".
    private static func nombreDeMes(_ fecha: Date) -> String {
        enMinusculasSinPuntos(formatoMes.string(from: fecha))
    }

    /// Según la versión de iOS, las abreviaturas en español llegan con punto ("vie.", "nov.")
    /// o sin él. Aquí se quitan los puntos y se pasa todo a minúsculas para que siempre salga igual.
    private static func enMinusculasSinPuntos(_ texto: String) -> String {
        texto.replacingOccurrences(of: ".", with: "").lowercased(with: Locale.roomie)
    }

    /// Pone en mayúscula solo la primera letra. Ej. "viernes" → "Viernes".
    private static func conMayusculaInicial(_ texto: String) -> String {
        guard let primera = texto.first else { return texto }
        return String(primera).uppercased(with: Locale.roomie) + String(texto.dropFirst())
    }

    // MARK: - Formateadores

    // Crear un `DateFormatter` es caro, así que cada uno se crea una sola vez y se reutiliza.

    private static let formatoDiaCorto: DateFormatter = crearFormateador("EEE d")
    private static let formatoDiaLargo: DateFormatter = crearFormateador("EEEE d")
    private static let formatoDiaSemana: DateFormatter = crearFormateador("EEEE")
    private static let formatoDiaSemanaAbreviado: DateFormatter = crearFormateador("EEE")
    private static let formatoNumeroDeDia: DateFormatter = crearFormateador("d")
    private static let formatoDiaYMes: DateFormatter = crearFormateador("d MMM")
    private static let formatoMes: DateFormatter = crearFormateador("MMMM")
    private static let formatoHora: DateFormatter = crearFormateador("HH:mm")

    /// Formateador con el idioma, el calendario y la zona horaria de la app.
    /// Usar la zona horaria de `Calendar.roomie` garantiza que lo que se muestra coincide
    /// con las cuentas de días que se hacen con ese mismo calendario.
    private static func crearFormateador(_ formato: String) -> DateFormatter {
        let formateador = DateFormatter()
        formateador.locale = Locale.roomie
        formateador.calendar = Calendar.roomie
        formateador.timeZone = Calendar.roomie.timeZone
        formateador.dateFormat = formato
        return formateador
    }
}
