import Foundation

/// Pantalla de Hogar: lista del súper, Modo Compras y calendario del depa.
/// También vive aquí "Lo que pasa en casa", el historial que muestra Inicio.
extension HogarStore {
    /// Cuántas líneas de "Lo que pasa en casa" se muestran como máximo.
    static let maximoDeActividadesRecientes = 30

    // MARK: - Lista del súper

    /// Artículos en el orden en que se muestran: primero los que faltan por comprar
    /// (del más viejo al más nuevo) y al final los ya comprados.
    var articulosOrdenados: [ArtSuper] {
        let porFecha = estado.articulos.sorted { (a: ArtSuper, b: ArtSuper) -> Bool in
            a.fechaAgregado < b.fechaAgregado
        }
        let porComprar = porFecha.filter { !$0.fueComprado }
        let comprados = porFecha.filter { $0.fueComprado }
        return porComprar + comprados
    }

    /// Cuántos artículos faltan por comprar.
    var articulosPorComprar: Int {
        estado.articulos.filter { !$0.fueComprado }.count
    }

    /// Agrega un artículo a la lista a nombre del usuario actual. No hace nada si el nombre
    /// está vacío o si ya hay un artículo por comprar que se llama igual (sin distinguir
    /// mayúsculas ni acentos).
    func agregarArticulo(_ nombre: String) {
        let nombreLimpio = nombre.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !nombreLimpio.isEmpty else { return }

        let clave = HogarStore.claveParaComparar(nombreLimpio)
        let yaEstaEnLaLista = estado.articulos.contains { (articulo: ArtSuper) -> Bool in
            !articulo.fueComprado && HogarStore.claveParaComparar(articulo.nombre) == clave
        }
        guard !yaEstaEnLaLista else { return }

        let nuevo = ArtSuper(nombre: nombreLimpio, agregadoPor: usuarioActual.id, fechaAgregado: ahora)
        modificarEstado { borrador in
            borrador.articulos.append(nuevo)
        }
    }

    /// Marca un artículo como comprado o, si ya lo estaba, lo regresa a "por comprar".
    func alternarComprado(_ articulo: ArtSuper) {
        guard let indice = estado.articulos.firstIndex(where: { $0.id == articulo.id }) else { return }
        modificarEstado { borrador in
            borrador.articulos[indice].fueComprado.toggle()
        }
    }

    /// Quita un artículo de la lista.
    func eliminarArticulo(_ articulo: ArtSuper) {
        let id = articulo.id
        modificarEstado { borrador in
            borrador.articulos.removeAll { (guardado: ArtSuper) -> Bool in guardado.id == id }
        }
    }

    /// Quita de la lista todos los artículos ya comprados.
    func limpiarComprados() {
        modificarEstado { borrador in
            borrador.articulos.removeAll { (guardado: ArtSuper) -> Bool in guardado.fueComprado }
        }
    }

    // MARK: - Modo Compras

    /// El aviso de "voy al súper" que está activo, o `nil` si nadie lo ha activado,
    /// ya se terminó o ya caducó (se apaga solo a las 2 horas).
    var modoCompras: ModoCompras? {
        guard let modo = estado.modoCompras, modo.estaVigente(en: ahora) else { return nil }
        return modo
    }

    /// `true` si quien está de compras es el usuario actual.
    var estoyDeCompras: Bool {
        guard let modo = modoCompras else { return false }
        return modo.activadoPor == usuarioActual.id
    }

    /// Avisa a los roomies que el usuario actual va al súper, para que agreguen lo que les falte.
    /// Si ya había un aviso activo (suyo o de otro), este lo reemplaza.
    ///
    /// - Parameter lugar: a qué tienda va. Puede venir vacío.
    func activarModoCompras(lugar: String) {
        let yo = usuarioActual
        let lugarLimpio = lugar.trimmingCharacters(in: .whitespacesAndNewlines)
        let modo = ModoCompras(activadoPor: yo.id, lugar: lugarLimpio, inicio: ahora)

        modificarEstado { borrador in
            borrador.modoCompras = modo
            registrarActividad(.modoCompras, de: yo.id, texto: "activó Modo Compras",
                               detalle: lugarLimpio.isEmpty ? nil : lugarLimpio, en: &borrador)
        }

        let destino = lugarLimpio.isEmpty ? "" : " (\(lugarLimpio))"
        notificador.enviar(titulo: "🛒 Modo Compras",
                           cuerpo: "\(yo.nombre) va al súper\(destino). ¡Agrega a la lista lo que te falte!")
    }

    /// Termina el Modo Compras. Solo lo puede terminar quien lo activó.
    func terminarModoCompras() {
        guard estoyDeCompras else { return }
        modificarEstado { borrador in
            borrador.modoCompras = nil
        }
    }

    // MARK: - Calendario del depa

    /// Eventos de ese día, del más temprano al más tarde.
    func eventos(en dia: Date) -> [Evento] {
        let calendario = Calendar.roomie
        return estado.eventos
            .filter { (evento: Evento) -> Bool in calendario.esMismoDia(evento.fecha, dia) }
            .sorted { (a: Evento, b: Evento) -> Bool in a.fecha < b.fecha }
    }

    /// `true` si hay al menos un evento ese día (para marcar el día en el mini calendario).
    func hayEventos(en dia: Date) -> Bool {
        let calendario = Calendar.roomie
        return estado.eventos.contains { (evento: Evento) -> Bool in calendario.esMismoDia(evento.fecha, dia) }
    }

    /// Eventos de hoy en adelante (hoy cuenta desde las 00:00), del más cercano al más lejano.
    var proximosEventos: [Evento] {
        let inicioDeHoy = Calendar.roomie.startOfDay(for: ahora)
        return estado.eventos
            .filter { (evento: Evento) -> Bool in evento.fecha >= inicioDeHoy }
            .sorted { (a: Evento, b: Evento) -> Bool in a.fecha < b.fecha }
    }

    /// Apunta una visita o evento en el calendario a nombre del usuario actual.
    /// No hace nada si el título está vacío.
    func agregarEvento(titulo: String, fecha: Date, tipo: TipoEvento) {
        let tituloLimpio = titulo.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !tituloLimpio.isEmpty else { return }

        let yo = usuarioActual.id
        let nuevo = Evento(titulo: tituloLimpio, fecha: fecha, tipo: tipo, creadoPor: yo)
        let cuando = "\(Formato.diaCorto(fecha)) · \(Formato.hora(fecha))"

        modificarEstado { borrador in
            borrador.eventos.append(nuevo)
            registrarActividad(.evento, de: yo, texto: "apuntó \(tituloLimpio)",
                               detalle: cuando, en: &borrador)
        }
    }

    /// Quita un evento del calendario.
    func eliminarEvento(_ evento: Evento) {
        let id = evento.id
        modificarEstado { borrador in
            borrador.eventos.removeAll { (guardado: Evento) -> Bool in guardado.id == id }
        }
    }

    // MARK: - Lo que pasa en casa

    /// Las líneas más recientes de "Lo que pasa en casa", de la más nueva a la más vieja
    /// (como mucho `maximoDeActividadesRecientes`).
    var actividadesRecientes: [Actividad] {
        // `sorted` es estable: dos actividades con la misma fecha conservan su orden,
        // y como las nuevas se insertan al principio, la más nueva sigue saliendo primero.
        let ordenadas = estado.actividades.sorted { (a: Actividad, b: Actividad) -> Bool in a.fecha > b.fecha }
        return Array(ordenadas.prefix(HogarStore.maximoDeActividadesRecientes))
    }

    // MARK: - Ayudantes

    /// Versión de un nombre para compararlo sin distinguir mayúsculas ni acentos
    /// ("Jabón" y "jabon" dan lo mismo).
    private static func claveParaComparar(_ nombre: String) -> String {
        nombre.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale.roomie)
    }
}
