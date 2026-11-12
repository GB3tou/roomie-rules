import Foundation

/// Gastos compartidos: historial, totales del mes, balances y deudas simplificadas.
extension HogarStore {
    /// Monto más grande que se acepta en un solo gasto (10 millones de pesos). Ningún gasto de
    /// un depa se acerca; el tope evita que un número tecleado por error (o absurdamente grande)
    /// desborde las cuentas en centavos.
    static let montoMaximoPorGasto: Double = 10_000_000

    // MARK: - Lectura

    /// Todos los gastos, del más reciente al más viejo. Incluye las liquidaciones.
    var gastosOrdenados: [Gasto] {
        // `sorted` es estable: si dos gastos tienen la misma fecha conservan su orden,
        // y como los nuevos se insertan al principio, el más nuevo sigue saliendo primero.
        estado.gastos.sorted { (a: Gasto, b: Gasto) -> Bool in a.fecha > b.fecha }
    }

    /// Suma de los gastos del mes en curso. No cuenta las liquidaciones (no son gastos del depa).
    var totalDelMes: Double {
        HogarStore.sumaEnPesos(gastosDelMes.map { $0.montoTotal })
    }

    /// Cuánto ha pagado de su bolsa el usuario actual este mes (sin liquidaciones).
    var pagadoPorMiEsteMes: Double {
        let yo = usuarioActual.id
        let pagadosPorMi = gastosDelMes.filter { (gasto: Gasto) -> Bool in gasto.pagadoPor == yo }
        return HogarStore.sumaEnPesos(pagadosPorMi.map { $0.montoTotal })
    }

    /// Cuánto le toca al usuario actual de los gastos de este mes (la suma de sus partes).
    var miParteEsteMes: Double {
        let yo = usuarioActual.id
        var centavos = 0
        for gasto in gastosDelMes {
            centavos += CalculadoraDeBalances.partesEnCentavos(de: gasto)[yo] ?? 0
        }
        return Dinero.aPesos(centavos)
    }

    /// Cuánto le toca a ese roomie de ese gasto, en pesos (0 si no participa).
    func parte(de usuarioID: UUID, en gasto: Gasto) -> Double {
        // La vista puede traer una copia vieja: si el gasto sigue guardado, se usa la versión actual.
        let vigente = self.gasto(gasto.id) ?? gasto
        return CalculadoraDeBalances.parte(de: usuarioID, en: vigente)
    }

    /// Cuánto le toca al usuario actual de ese gasto, en pesos (0 si no participa).
    func miParte(en gasto: Gasto) -> Double {
        parte(de: usuarioActual.id, en: gasto)
    }

    /// Balance de ese roomie tomando en cuenta todos los gastos y liquidaciones:
    /// positivo = le deben, negativo = debe, 0 = está a mano.
    func balance(de usuarioID: UUID) -> Double {
        let balances = CalculadoraDeBalances.balancesEnCentavos(gastos: estado.gastos, usuarios: estado.usuarios)
        return Dinero.aPesos(balances[usuarioID] ?? 0)
    }

    /// Balance del usuario actual: positivo = le deben, negativo = debe.
    var miBalance: Double {
        balance(de: usuarioActual.id)
    }

    /// "Quién le debe a quién" en todo el depa, ya simplificado (ver `SimplificadorDeDeudas`).
    var transferencias: [Transferencia] {
        SimplificadorDeDeudas.transferencias(gastos: estado.gastos, usuarios: estado.usuarios)
    }

    /// Solo las deudas simplificadas en las que el usuario actual paga o cobra.
    var misTransferencias: [Transferencia] {
        let yo = usuarioActual.id
        return transferencias.filter { (transferencia: Transferencia) -> Bool in
            transferencia.de == yo || transferencia.para == yo
        }
    }

    // MARK: - Acciones

    /// Registra un gasto compartido con fecha de ahora, repartido a partes iguales.
    ///
    /// - Parameters:
    ///   - descripcion: qué se pagó. Si viene vacía se usa el nombre de la categoría.
    ///   - montoTotal: total pagado en pesos; se guarda redondeado al centavo.
    ///   - categoria: tipo de gasto.
    ///   - pagadoPor: ID del roomie que puso el dinero.
    ///   - divididoEntre: IDs de los roomies entre quienes se reparte. Se ignoran los repetidos
    ///     y los que no existen, y se guardan en el orden de `usuarios`.
    /// - Returns: el gasto guardado, o `nil` si los datos no son válidos: el monto no es un
    ///   número mayor que 0 (o pasa de `montoMaximoPorGasto`), quien pagó no existe
    ///   o no quedó nadie entre quien repartirlo.
    @discardableResult
    func agregarGasto(descripcion: String, montoTotal: Double, categoria: CategoriaGasto,
                      pagadoPor: UUID, divididoEntre: [UUID]) -> Gasto? {
        // `isFinite` va primero: descarta NaN e infinito, que tronarían al pasarlos a centavos.
        guard montoTotal.isFinite, montoTotal > 0, montoTotal <= HogarStore.montoMaximoPorGasto else { return nil }
        let centavos = Dinero.aCentavos(montoTotal)
        // Un monto como 0.004 es mayor que 0, pero se redondea a 0 centavos: tampoco es un gasto.
        guard centavos > 0 else { return nil }
        guard usuario(pagadoPor) != nil else { return nil }

        // Recorrer `usuarios` (y no `divididoEntre`) deja fuera los IDs desconocidos y los
        // repetidos, y fija el orden: así el reparto de centavos sobrantes siempre es el mismo.
        let participantes = estado.usuarios
            .map { $0.id }
            .filter { (id: UUID) -> Bool in divididoEntre.contains(id) }
        guard !participantes.isEmpty else { return nil }

        let descripcionLimpia = descripcion.trimmingCharacters(in: .whitespacesAndNewlines)
        let nuevo = Gasto(
            descripcion: descripcionLimpia.isEmpty ? categoria.nombre : descripcionLimpia,
            montoTotal: Dinero.aPesos(centavos),
            pagadoPor: pagadoPor,
            divididoEntre: participantes,
            fecha: ahora,
            categoria: categoria
        )

        let yo = usuarioActual.id
        let texto = "registró \(nuevo.descripcion) · \(Formato.dinero(nuevo.montoTotal))"
        // Si lo registró quien pagó, no hace falta repetir su nombre en el detalle.
        let detalle: String? = pagadoPor == yo ? nil : "Pagó \(nombre(de: pagadoPor))"

        modificarEstado { borrador in
            // Al principio, para que la lista guardada vaya siempre del más nuevo al más viejo.
            borrador.gastos.insert(nuevo, at: 0)
            registrarActividad(.gasto, de: yo, texto: texto, detalle: detalle,
                               gastoID: nuevo.id, en: &borrador)
        }
        return nuevo
    }

    /// Elimina un gasto (o una liquidación) y las líneas de "Lo que pasa en casa" que hablaban de él.
    /// Los balances se recalculan solos.
    func eliminarGasto(_ gasto: Gasto) {
        let id = gasto.id
        modificarEstado { borrador in
            borrador.gastos.removeAll { (guardado: Gasto) -> Bool in guardado.id == id }
            borrador.actividades.removeAll { (actividad: Actividad) -> Bool in actividad.gastoID == id }
        }
    }

    /// Marca una deuda como pagada: "`transferencia.de` ya le pagó a `transferencia.para`".
    ///
    /// Se guarda como un `Gasto` de categoría `.liquidacion`, así que los balances de los dos
    /// se ajustan con la misma fórmula de siempre. No hace nada si esa deuda ya no existe
    /// (quien paga ya no debe nada o a quien cobra ya no le deben nada): así, tocar dos veces
    /// el botón no registra el pago dos veces.
    func liquidar(_ transferencia: Transferencia) {
        guard transferencia.monto.isFinite, transferencia.monto > 0,
              usuario(transferencia.de) != nil, usuario(transferencia.para) != nil else { return }

        // La vista puede traer una transferencia vieja: se comprueba contra los balances actuales.
        let balances = CalculadoraDeBalances.balancesEnCentavos(gastos: estado.gastos, usuarios: estado.usuarios)
        let balanceDeQuienPaga = balances[transferencia.de] ?? 0
        let balanceDeQuienCobra = balances[transferencia.para] ?? 0
        guard balanceDeQuienPaga < 0, balanceDeQuienCobra > 0 else { return }

        let nombreDeQuienPaga = nombre(de: transferencia.de)
        let nombreDeQuienCobra = nombre(de: transferencia.para)
        let pago = Gasto(
            descripcion: "Pago de \(nombreDeQuienPaga) a \(nombreDeQuienCobra)",
            montoTotal: transferencia.monto,
            pagadoPor: transferencia.de,
            divididoEntre: [transferencia.para],
            fecha: ahora,
            categoria: .liquidacion
        )
        let texto = "le pagó \(Formato.dinero(transferencia.monto)) a \(nombreDeQuienCobra)"

        modificarEstado { borrador in
            borrador.gastos.insert(pago, at: 0)
            registrarActividad(.liquidacion, de: transferencia.de, texto: texto,
                               gastoID: pago.id, en: &borrador)
        }
    }

    // MARK: - Ayudantes

    /// Gastos del mes en curso, sin contar las liquidaciones.
    private var gastosDelMes: [Gasto] {
        let hoy = ahora
        let calendario = Calendar.roomie
        return estado.gastos.filter { (gasto: Gasto) -> Bool in
            !gasto.esLiquidacion && calendario.esMismoMes(gasto.fecha, hoy)
        }
    }

    /// Suma montos en pesos pasando por centavos enteros, para que no se cuelen errores
    /// de redondeo (0.1 + 0.2 no da exactamente 0.3 con `Double`).
    private static func sumaEnPesos(_ montos: [Double]) -> Double {
        var centavos = 0
        for monto in montos {
            centavos += Dinero.aCentavos(monto)
        }
        return Dinero.aPesos(centavos)
    }
}
