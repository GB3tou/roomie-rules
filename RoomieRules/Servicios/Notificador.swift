import Foundation

/// Algo capaz de mandar un aviso a los roomies (el "Toque" y el "Modo Compras").
///
/// `HogarStore` solo conoce este protocolo: la app usa `NotificadorLocal` (notificaciones
/// del teléfono) y las pruebas y vistas previas usan `NotificadorDePrueba` (no manda nada).
protocol Notificador: AnyObject {
    /// Manda un aviso con ese título y ese texto.
    func enviar(titulo: String, cuerpo: String)
}
