import Foundation
import UserNotifications

/// Manda los avisos como notificaciones locales del teléfono.
///
/// La v1 no tiene servidor, así que el "push" del Toque y del Modo Compras se simula:
/// la notificación aparece en este mismo dispositivo un instante después de mandarla.
final class NotificadorLocal: NSObject, Notificador, UNUserNotificationCenterDelegate {
    /// Única instancia de la app (el centro de notificaciones solo admite un delegado).
    static let compartido = NotificadorLocal()

    /// Segundos entre que se manda el aviso y aparece el banner. El sistema exige un
    /// intervalo mayor que cero; con 1.5 s da tiempo de ver primero el cambio en pantalla.
    private static let retraso: TimeInterval = 1.5

    // Crear la instancia no toca el centro de notificaciones del sistema: eso solo pasa
    // en `configurar()` y en `enviar`, es decir, cuando la app de verdad lo usa.
    private override init() {
        super.init()
    }

    /// Se llama una vez al arrancar la app: registra esta instancia como delegado del centro
    /// de notificaciones para que los avisos se vean aunque la app esté abierta.
    func configurar() {
        UNUserNotificationCenter.current().delegate = self
    }

    /// Programa una notificación local con ese título y ese texto.
    /// La primera vez pide permiso al usuario; si lo niega, no hace nada.
    func enviar(titulo: String, cuerpo: String) {
        // El sistema contesta en otro hilo. No hay problema: desde ahí solo se programa
        // la notificación, nunca se toca el estado de la app.
        UNUserNotificationCenter.current().getNotificationSettings { ajustes in
            switch ajustes.authorizationStatus {
            case .notDetermined:
                NotificadorLocal.pedirPermisoYProgramar(titulo: titulo, cuerpo: cuerpo)
            case .authorized, .provisional, .ephemeral:
                NotificadorLocal.programar(titulo: titulo, cuerpo: cuerpo)
            case .denied:
                break
            @unknown default:
                break
            }
        }
    }

    // MARK: - UNUserNotificationCenterDelegate

    /// iOS no muestra las notificaciones de la app que está en pantalla, a menos que su delegado
    /// se lo pida. Aquí se pide: así el "push simulado" se ve como banner durante la demo.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .list, .sound])
    }

    // MARK: - Ayudantes

    /// Pide permiso para mostrar notificaciones y, si el usuario acepta, programa el aviso.
    private static func pedirPermisoYProgramar(titulo: String, cuerpo: String) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { concedido, _ in
            guard concedido else { return }
            NotificadorLocal.programar(titulo: titulo, cuerpo: cuerpo)
        }
    }

    /// Deja la notificación programada para que salga dentro de `retraso` segundos.
    private static func programar(titulo: String, cuerpo: String) {
        let contenido = UNMutableNotificationContent()
        contenido.title = titulo
        contenido.body = cuerpo
        contenido.sound = UNNotificationSound.default

        let disparador = UNTimeIntervalNotificationTrigger(timeInterval: NotificadorLocal.retraso, repeats: false)
        // Un identificador nuevo cada vez: si fuera el mismo, un aviso reemplazaría al anterior.
        let solicitud = UNNotificationRequest(identifier: UUID().uuidString, content: contenido, trigger: disparador)

        UNUserNotificationCenter.current().add(solicitud) { error in
            if let error = error {
                print("NotificadorLocal: no se pudo programar el aviso: \(error.localizedDescription)")
            }
        }
    }
}
