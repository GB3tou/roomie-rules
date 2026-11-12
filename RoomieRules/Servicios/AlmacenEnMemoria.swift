import Foundation

/// Almacén que no toca el disco: guarda el estado en una variable.
///
/// Lo usan las vistas previas (`#Preview`) y las pruebas, para que nada de lo que hagan
/// se mezcle con los datos reales de la app.
final class AlmacenEnMemoria: AlmacenDeEstado {
    /// Lo último que se guardó (o el estado inicial). `nil` si no hay nada.
    private(set) var estadoGuardado: EstadoHogar?
    /// Cuántas veces se ha llamado a `guardar`. Sirve en pruebas para comprobar
    /// que un cambio se guarda una sola vez.
    private(set) var vecesGuardado: Int = 0

    /// - Parameter estadoInicial: lo que devolverá `cargar()` antes del primer guardado.
    init(estadoInicial: EstadoHogar? = nil) {
        self.estadoGuardado = estadoInicial
    }

    /// Devuelve lo último que se guardó, o `nil` si no hay nada.
    func cargar() -> EstadoHogar? {
        estadoGuardado
    }

    /// Reemplaza lo guardado por `estado`.
    func guardar(_ estado: EstadoHogar) {
        estadoGuardado = estado
        vecesGuardado += 1
    }

    /// Olvida lo guardado.
    func borrar() {
        estadoGuardado = nil
    }
}
