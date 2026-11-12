import Foundation

/// Lugar donde se guarda y de donde se recupera el estado completo del depa.
///
/// `HogarStore` solo conoce este protocolo: la app guarda en un archivo y las pruebas y vistas
/// previas en memoria. El día que haya servidor, solo habrá que escribir otro almacén.
protocol AlmacenDeEstado {
    /// Devuelve lo último que se guardó, o `nil` si no hay nada guardado o no se pudo leer.
    func cargar() -> EstadoHogar?
    /// Guarda el estado completo, reemplazando lo que hubiera.
    func guardar(_ estado: EstadoHogar)
    /// Borra lo guardado; después de esto `cargar()` devuelve `nil`.
    func borrar()
}
