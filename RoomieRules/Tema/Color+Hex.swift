import SwiftUI

extension Color {
    /// Crea un color sRGB a partir de un número hexadecimal de 6 dígitos, por ejemplo `Color(hex: 0x1F6F54)`.
    /// Así los tokens de `Tema` se copian tal cual del diseño.
    init(hex: UInt32) {
        let rojo = Double((hex >> 16) & 0xFF) / 255.0
        let verde = Double((hex >> 8) & 0xFF) / 255.0
        let azul = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: rojo, green: verde, blue: azul, opacity: 1.0)
    }
}
