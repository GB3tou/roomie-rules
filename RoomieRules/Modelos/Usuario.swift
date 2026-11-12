import Foundation

/// Un roomie del departamento.
///
/// Corresponde a la entidad **Usuario** del PRD (`id`, `nombre`, `fotoPerfil`).
struct Usuario: Identifiable, Codable, Hashable {
    let id: UUID
    var nombre: String
    /// Nombre de la imagen de perfil dentro de los assets.
    /// En esta primera versión no se manejan fotos: si está vacío, el avatar muestra la inicial del nombre.
    var fotoPerfil: String
    /// Color pastel con el que se pinta el avatar del roomie.
    var colorAvatar: ColorAvatar

    init(id: UUID = UUID(), nombre: String, fotoPerfil: String = "", colorAvatar: ColorAvatar) {
        self.id = id
        self.nombre = nombre
        self.fotoPerfil = fotoPerfil
        self.colorAvatar = colorAvatar
    }

    /// Primera letra del nombre en mayúscula. Es lo que se dibuja dentro del avatar.
    var inicial: String {
        nombre.prefix(1).uppercased()
    }
}

/// Colores disponibles para los avatares.
///
/// Aquí solo se guarda *cuál* color le toca a cada roomie; los tonos reales
/// (fondo y texto) viven en la capa visual, en `Tema/`.
enum ColorAvatar: String, Codable, CaseIterable {
    case verde
    case morado
    case naranja
    case azul
    case rosa
    case amarillo
}
