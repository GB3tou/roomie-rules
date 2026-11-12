import Foundation

/// Reglas de la rotación semanal de tareas y del reinicio diario de las tareas diarias.
///
/// Es lógica pura: recibe las tareas y las fechas, y devuelve las tareas ya puestas al día.
enum RotadorDeTareas {
    /// Lo que devuelve `actualizar`: las tareas al día y las fechas que hay que guardar.
    struct Resultado: Equatable {
        var tareas: [Tarea]
        var inicioSemana: Date            // lunes 00:00 de la semana de `hoy`
        var ultimaRevisionDiaria: Date    // inicio del día de `hoy`
        var semanasRotadas: Int           // 0 si no cambió la semana
    }

    /// Avanza la asignación `semanas` semanas: cada tarea pasa al siguiente roomie en el orden de
    /// `usuarios` (el último le pasa al primero), se desmarca, se borra su `ultimoToque`
    /// y su `fechaLim` se recorre 7 días por semana.
    static func rotar(_ tareas: [Tarea], usuarios: [Usuario], semanas: Int,
                      calendario: Calendar = Calendar.roomie) -> [Tarea] {
        guard !usuarios.isEmpty, semanas != 0 else { return tareas }
        let n = usuarios.count

        return tareas.map { (tarea: Tarea) -> Tarea in
            var nueva = tarea
            // Si el responsable ya no está en el depa, la tarea arranca desde el primer roomie.
            let indice = usuarios.firstIndex(where: { $0.id == tarea.asignadoA }) ?? 0
            // La doble operación con `% n` deja el índice entre 0 y n − 1 aunque `semanas` sea negativo.
            let nuevoIndice = ((indice + semanas) % n + n) % n
            nueva.asignadoA = usuarios[nuevoIndice].id
            nueva.completada = false
            nueva.ultimoToque = nil
            nueva.fechaLim = calendario.sumar(dias: 7 * semanas, a: tarea.fechaLim)
            return nueva
        }
    }

    /// Pone las tareas al día respecto a `hoy`: rota si cambió la semana y, si cambió el día,
    /// desmarca las tareas diarias y les pone `fechaLim` = hoy.
    static func actualizar(tareas: [Tarea], usuarios: [Usuario], inicioSemanaRegistrado: Date,
                           ultimaRevisionDiaria: Date, hoy: Date,
                           calendario: Calendar = Calendar.roomie) -> Resultado {
        // Si el reloj se movió hacia atrás (o la semana registrada va adelantada por una
        // simulación), no rotamos "en reversa": simplemente esperamos.
        let semanas = max(0, calendario.semanasEntre(inicioSemanaRegistrado, y: hoy))

        var actualizadas = tareas
        if semanas > 0 {
            actualizadas = rotar(actualizadas, usuarios: usuarios, semanas: semanas, calendario: calendario)
        }

        let cambioDeDia = !calendario.esMismoDia(ultimaRevisionDiaria, hoy)
        let inicioDeHoy = calendario.startOfDay(for: hoy)
        for indice in actualizadas.indices where actualizadas[indice].frecuencia == .diaria {
            if cambioDeDia {
                actualizadas[indice].completada = false
                actualizadas[indice].ultimoToque = nil
            }
            // Una tarea diaria siempre vence "hoy".
            actualizadas[indice].fechaLim = inicioDeHoy
        }

        let inicioSemana: Date
        if semanas > 0 {
            inicioSemana = calendario.inicioDeSemana(para: hoy)
        } else {
            inicioSemana = calendario.inicioDeSemana(para: inicioSemanaRegistrado)
        }

        return Resultado(
            tareas: actualizadas,
            inicioSemana: inicioSemana,
            ultimaRevisionDiaria: inicioDeHoy,
            semanasRotadas: semanas
        )
    }
}
