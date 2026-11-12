import SwiftUI

/// Hoja "Nuevo gasto": monto, descripción, categoría, quién pagó y entre quiénes se divide.
/// Al guardar llama a `HogarStore.agregarGasto`; las deudas se recalculan solas en el store.
struct NuevoGastoView: View {
    @EnvironmentObject private var store: HogarStore
    @Environment(\.dismiss) private var dismiss

    /// Se llama después de guardar el gasto (la pantalla muestra el aviso).
    private let alGuardar: () -> Void

    /// Lo que se teclea en el monto, tal cual.
    @State private var montoTexto: String = ""
    @State private var descripcion: String = ""
    @State private var categoria: CategoriaGasto = .servicios
    /// Quién pagó; `nil` = el usuario actual (el store no está disponible en `init`).
    @State private var pagadoPor: UUID?
    /// Roomies que NO participan. Vacío = participan todos, que es lo normal.
    @State private var excluidos: Set<UUID> = []
    @State private var modo: NuevoGastoModo = .iguales
    /// `true` cuando el store rechazó el gasto.
    @State private var mostrandoError: Bool = false
    @FocusState private var montoEnfocado: Bool

    /// - Parameter alGuardar: se llama una vez que el gasto quedó guardado.
    init(alGuardar: @escaping () -> Void) {
        self.alGuardar = alGuardar
    }

    var body: some View {
        NavigationStack {
            formulario
                .navigationTitle("Nuevo gasto")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    barraDeHerramientas
                }
                .alert("No se pudo guardar", isPresented: $mostrandoError) {
                    Button("Entendido", role: .cancel) {}
                } message: {
                    Text("Revisa el monto y que haya al menos una persona en la división.")
                }
        }
        .presentationDragIndicator(.visible)
        .onAppear(perform: enfocarMonto)
    }

    // MARK: - Secciones

    /// Contenido desplazable del formulario, sobre fondo blanco.
    private var formulario: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 24) {
                seccionMonto
                seccionDescripcion
                seccionPagador
                seccionDivision
            }
            .padding(.horizontal, Tema.margen)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Tema.tarjeta.ignoresSafeArea())
    }

    /// "Monto total" y el número grande.
    private var seccionMonto: some View {
        VStack(spacing: 4) {
            Text("Monto total")
                .font(Tipografia.etiqueta)
                .foregroundStyle(Tema.tintaSecundaria)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("$")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(Tema.tintaSecundaria)
                campoMonto
            }
        }
        .frame(maxWidth: .infinity)
    }

    /// Campo del monto: crece con lo que se teclea en lugar de ocupar todo el ancho.
    private var campoMonto: some View {
        TextField("0", text: $montoTexto)
            .font(.system(size: 56, weight: .bold))
            .foregroundStyle(Tema.tinta)
            .keyboardType(.decimalPad)
            .focused($montoEnfocado)
            .fixedSize()
            .accessibilityLabel("Monto total")
    }

    /// "Descripción", su campo y, justo debajo, las categorías.
    private var seccionDescripcion: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                etiqueta("Descripción")
                campoDescripcion
            }
            chipsDeCategoria
        }
    }

    /// Campo de texto con fondo crema y borde fino.
    private var campoDescripcion: some View {
        let forma = RoundedRectangle(cornerRadius: Tema.radioControl, style: .continuous)
        return TextField("Ej. Recibo de luz", text: $descripcion)
            .font(Tipografia.cuerpo)
            .foregroundStyle(Tema.tinta)
            .submitLabel(.done)
            .padding(16)
            .background(forma.fill(Tema.campo))
            .overlay(forma.strokeBorder(Tema.borde, lineWidth: 1))
    }

    /// Un chip por categoría elegible. Se desplaza de lado por si no cabe en pantallas angostas.
    private var chipsDeCategoria: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(CategoriaGasto.seleccionables) { opcion in
                    ChipSeleccionable(opcion.nombre, seleccionado: opcion == categoria) {
                        categoria = opcion
                    }
                }
            }
        }
    }

    /// "¿Quién pagó?" y las tarjetitas de cada roomie.
    private var seccionPagador: some View {
        VStack(alignment: .leading, spacing: 8) {
            etiqueta("¿Quién pagó?")
            NuevoGastoPagadorSelector(seleccionado: pagadorElegido) { id in
                pagadoPor = id
            }
        }
    }

    /// "Dividir entre", el modo de reparto y la tarjeta con la parte de cada quien.
    private var seccionDivision: some View {
        VStack(alignment: .leading, spacing: 12) {
            etiqueta("Dividir entre")
            SelectorSegmentado(opciones: NuevoGastoModo.allCases,
                               seleccion: $modo,
                               deshabilitadas: [NuevoGastoModo.exactos]) { opcion in
                opcion.titulo
            }
            NuevoGastoDivisionCard(partes: partes, excluidos: excluidos) { id in
                alternarParticipante(id)
            }
        }
    }

    /// Botones "Cancelar" y "Guardar" de la barra superior.
    @ToolbarContentBuilder
    private var barraDeHerramientas: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancelar") {
                dismiss()
            }
            .tint(Tema.tintaSecundaria)
        }
        ToolbarItem(placement: .confirmationAction) {
            Button(action: guardar) {
                Text("Guardar")
                    .fontWeight(.semibold)
            }
            .tint(Tema.verde)
            .disabled(!esValido)
        }
    }

    /// Etiqueta gris pequeña sobre cada sección.
    private func etiqueta(_ texto: String) -> some View {
        Text(texto)
            .font(Tipografia.etiqueta)
            .foregroundStyle(Tema.tintaSecundaria)
    }

    // MARK: - Datos del formulario

    /// El monto tecleado como número, o `nil` si no es un número mayor que 0.
    /// Acepta coma o punto como separador decimal.
    private var monto: Double? {
        let limpio = montoTexto
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")
        guard let valor = Double(limpio), valor.isFinite, valor > 0 else { return nil }
        return valor
    }

    /// Quién pagó: lo que se eligió o, si no se ha tocado nada, el usuario actual.
    private var pagadorElegido: UUID {
        pagadoPor ?? store.usuarioActual.id
    }

    /// IDs de quienes participan, en el orden de `store.usuarios` (el mismo que usa el store
    /// para repartir los centavos sobrantes).
    private var participantes: [UUID] {
        store.usuarios
            .map { (usuario: Usuario) -> UUID in usuario.id }
            .filter { (id: UUID) -> Bool in !excluidos.contains(id) }
    }

    /// Se puede guardar si hay un monto válido y al menos una persona en la división.
    /// La descripción puede ir vacía: el store usa el nombre de la categoría.
    private var esValido: Bool {
        monto != nil && !participantes.isEmpty
    }

    /// Parte de cada participante en pesos, calculada con la misma función que usará el store,
    /// para que lo que se ve coincida al centavo con lo que se guarda.
    private var partes: [UUID: Double] {
        let quienes = participantes
        guard let total = monto, !quienes.isEmpty else { return [:] }
        // Por encima del tope el store no acepta el gasto, y un número gigantesco
        // no se puede pasar a centavos: no se muestra ninguna parte.
        guard total <= HogarStore.montoMaximoPorGasto else { return [:] }
        let temporal = Gasto(descripcion: descripcion,
                             montoTotal: total,
                             pagadoPor: pagadorElegido,
                             divididoEntre: quienes,
                             fecha: store.ahora,
                             categoria: categoria)
        let centavos = CalculadoraDeBalances.partesEnCentavos(de: temporal)
        return centavos.mapValues { (valor: Int) -> Double in Dinero.aPesos(valor) }
    }

    // MARK: - Acciones

    /// Agrega o quita a un roomie de la división.
    private func alternarParticipante(_ id: UUID) {
        if excluidos.contains(id) {
            excluidos.remove(id)
        } else {
            excluidos.insert(id)
        }
    }

    /// Pide al store que guarde el gasto; si lo rechaza, avisa con una alerta.
    private func guardar() {
        guard let total = monto else {
            mostrandoError = true
            return
        }
        let guardado = store.agregarGasto(descripcion: descripcion,
                                          montoTotal: total,
                                          categoria: categoria,
                                          pagadoPor: pagadorElegido,
                                          divididoEntre: participantes)
        if guardado == nil {
            mostrandoError = true
            return
        }
        alGuardar()
        dismiss()
    }

    /// Pone el cursor en el monto. Se espera a que termine de subir la hoja,
    /// porque antes de eso el teclado a veces no aparece.
    private func enfocarMonto() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            montoEnfocado = true
        }
    }
}

#Preview {
    NuevoGastoView(alGuardar: {})
        .environmentObject(HogarStore.deEjemplo())
        .environmentObject(Navegacion())
}
