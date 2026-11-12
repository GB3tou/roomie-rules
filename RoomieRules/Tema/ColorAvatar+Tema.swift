import SwiftUI

/// Aquí se traduce el color elegido para un roomie a los tonos reales del tema.
/// El modelo (`ColorAvatar`) no conoce colores; solo la capa visual los define.
extension ColorAvatar {
    /// Tono suave para el fondo del avatar.
    var fondo: Color {
        switch self {
        case .verde: return Tema.verdeSuave
        case .morado: return Tema.moradoSuave
        case .naranja: return Tema.naranjaSuave
        case .azul: return Tema.azulSuave
        case .rosa: return Tema.rosaSuave
        case .amarillo: return Tema.amarilloSuave
        }
    }

    /// Tono fuerte para la inicial dibujada sobre el fondo.
    var texto: Color {
        switch self {
        case .verde: return Tema.verde
        case .morado: return Tema.morado
        case .naranja: return Tema.naranja
        case .azul: return Tema.azul
        case .rosa: return Tema.rosa
        case .amarillo: return Tema.amarillo
        }
    }
}
