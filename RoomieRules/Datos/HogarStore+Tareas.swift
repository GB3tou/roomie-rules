import Foundation

/// Tareas del hogar: orden de la lista, palomear, mandar un Toque y rotar cada semana.
extension HogarStore {
    /// Tiempo mínimo entre dos Toques por la misma tarea (1 hora), para recordar sin atosigar.
    static let esperaEntreToques: TimeInterval = 60 * 60

    // MARK: - Lectura

    /// Lunes (00:00) de la semana a la que corresponde la asignación actual de tareas.
    /// Es lo que se le pasa a `Formato.rangoSemana(inicio:)` para el encabezado de Tareas.
    var inicioSemana: Date {
        estado.inicioSemanaRotacion
    }

    /// Todas las tareas en el orden en que se muestran: primero las mías pendientes, luego las
    /// pendientes de los demás y al final las completadas. Dentro de cada grupo, primero la que
    /// vence antes y, si vencen el mismo día, por título.
    var tareasOrdenadas: [Tarea] {
        let yo = usuarioActual.id
        return estado.tareas.sorted { (a: Tarea, b: Tarea) -> Bool in
            let grupoA = HogarStore.grupo(de: a, usuarioActualID: yo)
            let grupoB = HogarStore.grupo(de: b, usuarioActualID: yo)
            if grupoA != grupoB {
                return grupoA < grupoB
            }
            return HogarStore.venceAntes(a, b)
        }
    }

    /// Tareas del usuario actual que siguen pendientes; primero la que vence antes.
    var misTareasPendientes: [Tarea] {
        let yo = usuarioActual.id
        return estado.tareas
            .filter { (tarea: Tarea) -> Bool in tarea.asignadoA == yo && !tarea.completada }
            .sorted { (a: Tarea, b: Tarea) -> Bool in HogarStore.venceAntes(a, b) }
    }

    /// Cuántas tareas (de todos los roomies) ya están palomeadas.
    var tareasCompletadas: Int {
        estado.tareas.filter { $0.completada }.count
    }

    /// `true` si el usuario actual puede palomear esa tarea: solo quien la tiene asignada.
    func puedeCompletar(_ tarea: Tarea) -> Bool {
        guard let vigente = tareaVigente(tarea) else { return false }
        return vigente.asignadoA == usuarioActual.id
    }

    /// `true` si ya se mandó un Toque por esa tarea hace menos de una hora.
    func toqueReciente(_ tarea: Tarea) -> Bool {
        guard let vigente = tareaVigente(tarea), let ultimoToque = vigente.ultimoToque else { return false }
        return ahora.timeIntervalSince(ultimoToque) < HogarStore.esperaEntreToques
    }

    /// `true` si el usuario actual puede mandar un Toque por esa tarea:
    /// es de otro roomie, sigue pendiente y no hay un Toque reciente.
    func puedeDarToque(_ tarea: Tarea) -> Bool {
        guard let vigente = tareaVigente(tarea) else { return false }
        return vigente.asignadoA != usuarioActual.id && !vigente.completada && !toqueReciente(vigente)
    }

    // MARK: - Acciones

    /// Pone o quita la palomita de una tarea. Si no es del usuario actual, no hace nada.
    func alternarCompletada(_ tarea: Tarea) {
        guard puedeCompletar(tarea),
              let indice = estado.tareas.firstIndex(where: { $0.id == tarea.id }) else { return }
        let vigente = estado.tareas[indice]
        let yo = usuarioActual.id
        let texto = "completó \(vigente.titulo)"

        modificarEstado { borrador in
            if vigente.completada {
                // Se arrepintió: además de quitar la palomita se retira el aviso de "completó…"
                // más reciente, para que "Lo que pasa en casa" no presuma algo que no pasó.
                borrador.tareas[indice].completada = false
                let posicion = borrador.actividades.firstIndex { (actividad: Actividad) -> Bool in
                    actividad.tipo == .tareaCompletada && actividad.usuarioID == yo && actividad.texto == texto
                }
                if let posicion = posicion {
                    borrador.actividades.remove(at: posicion)
                }
            } else {
                borrador.tareas[indice].completada = true
                registrarActividad(.tareaCompletada, de: yo, texto: texto,
                                   detalle: vigente.area.nombre, en: &borrador)
            }
        }
    }

    /// Manda un Toque (recordatorio amistoso) a quien tiene asignada la tarea.
    ///
    /// - Returns: el texto del recordatorio que se envió, o `nil` si no se pudo mandar
    ///   (la tarea es mía, ya está hecha o ya hubo un Toque hace menos de una hora).
    @discardableResult
    func darToque(_ tarea: Tarea) -> String? {
        guard puedeDarToque(tarea),
              let indice = estado.tareas.firstIndex(where: { $0.id == tarea.id }) else { return nil }
        let vigente = estado.tareas[indice]
        guard let destinatario = usuario(vigente.asignadoA) else { return nil }
        let remitente = usuarioActual
        let momento = ahora

        let mensaje = MensajesDeToque.mensaje(tarea: vigente, remitente: remitente,
                                              destinatario: destinatario, hoy: momento)
        notificador.enviar(titulo: mensaje.titulo, cuerpo: mensaje.cuerpo)

        modificarEstado { borrador in
            borrador.tareas[indice].ultimoToque = momento
            registrarActividad(.toque, de: remitente.id, texto: "le dio un Toque a \(destinatario.nombre)",
                               detalle: vigente.titulo, en: &borrador)
        }
        return mensaje.cuerpo
    }

    /// Pone las tareas al día: si ya empezó otra semana, rota a los responsables; si ya es otro
    /// día, les quita la palomita a las tareas diarias. Se llama al abrir la app y cada vez que
    /// vuelve a primer plano; si no hay nada que actualizar, no cambia nada.
    func actualizarRotacionSiHaceFalta() {
        let resultado = RotadorDeTareas.actualizar(
            tareas: estado.tareas,
            usuarios: estado.usuarios,
            inicioSemanaRegistrado: estado.inicioSemanaRotacion,
            ultimaRevisionDiaria: estado.ultimaRevisionDiaria,
            hoy: ahora,
            calendario: Calendar.roomie
        )
        modificarEstado { borrador in
            borrador.tareas = resultado.tareas
            borrador.inicioSemanaRotacion = resultado.inicioSemana
            borrador.ultimaRevisionDiaria = resultado.ultimaRevisionDiaria
        }
    }

    /// Para la demo: rota las tareas como si ya fuera el lunes siguiente, sin esperar una semana.
    func simularCambioDeSemana() {
        let calendario = Calendar.roomie
        let rotadas = RotadorDeTareas.rotar(estado.tareas, usuarios: estado.usuarios,
                                            semanas: 1, calendario: calendario)
        let inicioDeHoy = calendario.startOfDay(for: ahora)

        modificarEstado { borrador in
            borrador.tareas = rotadas
            // `rotar` recorre 7 días todas las fechas límite, pero una tarea diaria siempre vence hoy.
            for indice in borrador.tareas.indices where borrador.tareas[indice].frecuencia == .diaria {
                borrador.tareas[indice].fechaLim = inicioDeHoy
            }
            // La semana registrada se adelanta: el encabezado de Tareas muestra la semana siguiente
            // y, cuando llegue ese lunes de verdad, `actualizarRotacionSiHaceFalta` ya no vuelve a rotar.
            borrador.inicioSemanaRotacion = calendario.sumar(dias: 7, a: borrador.inicioSemanaRotacion)
        }
    }

    // MARK: - Ayudantes

    /// La versión guardada de la tarea. La vista puede traer una copia vieja (por ejemplo,
    /// de antes de palomearla), así que las decisiones siempre se toman con la del estado actual.
    private func tareaVigente(_ tarea: Tarea) -> Tarea? {
        estado.tareas.first { $0.id == tarea.id }
    }

    /// Grupo de la lista al que pertenece una tarea: 0 = mía pendiente, 1 = pendiente de otro, 2 = completada.
    private static func grupo(de tarea: Tarea, usuarioActualID: UUID) -> Int {
        if tarea.completada {
            return 2
        }
        return tarea.asignadoA == usuarioActualID ? 0 : 1
    }

    /// Orden dentro de un grupo: primero la que vence antes; si vencen igual, por título
    /// (sin distinguir mayúsculas ni acentos).
    private static func venceAntes(_ a: Tarea, _ b: Tarea) -> Bool {
        if a.fechaLim != b.fechaLim {
            return a.fechaLim < b.fechaLim
        }
        let orden = a.titulo.compare(b.titulo, options: [.caseInsensitive, .diacriticInsensitive],
                                     range: nil, locale: Locale.roomie)
        return orden == .orderedAscending
    }
}
