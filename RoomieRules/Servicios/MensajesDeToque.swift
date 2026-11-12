import Foundation

/// Recordatorios amistosos ya escritos para el "Toque".
///
/// La idea del Toque es recordar sin regañar, así que el texto no lo escribe quien lo manda:
/// la app elige una de estas plantillas y le pone el nombre, la tarea y cuándo vence.
enum MensajesDeToque {
    /// Arma el aviso que recibe `destinatario` cuando `remitente` le da un Toque por `tarea`.
    ///
    /// - Returns: `titulo` (ej. "🔔 Toque de Roberto") y `cuerpo` (ej. "¡Hola, Sara! Recordatorio
    ///   amistoso: «Sacar la basura» vence hoy. ¡Tú puedes! 💪").
    static func mensaje(tarea: Tarea, remitente: Usuario, destinatario: Usuario, hoy: Date) -> (titulo: String, cuerpo: String) {
        let tituloDelAviso = "🔔 Toque de \(remitente.nombre)"

        let nombre = destinatario.nombre
        let tituloDeLaTarea = tarea.titulo
        // "vence hoy", "vence viernes 13", "venció viernes 13"… En las tareas diarias el formato
        // dice "todos los días", que necesita un verbo para leerse bien dentro de la frase.
        let vencimiento = Formato.vencimientoLargo(de: tarea, hoy: hoy)
        let cuando = tarea.frecuencia == .diaria ? "toca \(vencimiento)" : vencimiento

        let plantillas: [String] = [
            "¡Hola, \(nombre)! Recordatorio amistoso: «\(tituloDeLaTarea)» \(cuando). ¡Tú puedes! 💪",
            "\(nombre), el depa te lo va a agradecer: «\(tituloDeLaTarea)» \(cuando). 🙌",
            "Pst, \(nombre)… que no se te pase: «\(tituloDeLaTarea)» \(cuando). 😉",
            "¡Ey, \(nombre)! Solo paso a recordarte que «\(tituloDeLaTarea)» \(cuando). ¡Gracias por tu ayuda! ✨",
            "\(nombre), va un toquecito con cariño: «\(tituloDeLaTarea)» \(cuando). ¡Ánimo, sale rápido! 🧹",
        ]

        // La plantilla se elige con una cuenta fija (letras del título + día del mes), no al azar:
        // la misma tarea da el mismo mensaje el mismo día y las pruebas pueden comprobarlo.
        let diaDelMes = Calendar.roomie.component(.day, from: hoy)
        let indice = (tituloDeLaTarea.count + diaDelMes) % plantillas.count
        return (titulo: tituloDelAviso, cuerpo: plantillas[indice])
    }
}
