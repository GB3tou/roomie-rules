import Foundation

/// Notificador que no manda nada: solo apunta lo que se le pidió enviar.
///
/// Lo usan las vistas previas (`#Preview`) y las pruebas, donde no hay permiso de
/// notificaciones ni hace falta molestar a nadie.
final class NotificadorDePrueba: Notificador {
    /// Avisos "enviados", del más viejo al más nuevo.
    private(set) var enviadas: [(titulo: String, cuerpo: String)] = []

    /// Crea un notificador sin avisos enviados.
    init() {}

    /// Apunta el aviso en `enviadas` en vez de mandarlo.
    func enviar(titulo: String, cuerpo: String) {
        enviadas.append((titulo: titulo, cuerpo: cuerpo))
    }
}
