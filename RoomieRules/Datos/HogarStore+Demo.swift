import Foundation

/// Atajos para la demo: la v1 corre en un solo teléfono, así que para enseñar cómo ve la app
/// cada roomie hay que poder "cambiarse de persona" y regresar todo a como estaba.
extension HogarStore {
    /// Ver la app como otro roomie: a partir de aquí "Tú" es esa persona.
    /// No hace nada si ese ID no es de un roomie del depa.
    func cambiarUsuarioActual(a id: UUID) {
        guard usuario(id) != nil else { return }
        modificarEstado { borrador in
            borrador.usuarioActualID = id
        }
    }

    /// Borra todo lo que se haya hecho y vuelve a cargar los datos de ejemplo,
    /// con fechas relativas al día de hoy.
    func restablecerDatosDeEjemplo() {
        let ejemplo = DatosDeEjemplo.estado(hoy: ahora)
        modificarEstado { borrador in
            borrador = ejemplo
        }
    }
}
