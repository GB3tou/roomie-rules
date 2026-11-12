import SwiftUI

/// Colores y medidas de toda la app, tomados del diseño. Las pantallas nunca usan colores sueltos:
/// siempre piden el token a `Tema` para que un cambio de estilo se haga en un solo lugar.
enum Tema {
    // MARK: Superficies y bordes

    /// Fondo crema de todas las pantallas.
    static let fondo: Color = Color(hex: 0xF3F2EE)
    /// Fondo blanco de las tarjetas.
    static let tarjeta: Color = Color(hex: 0xFFFFFF)
    /// Borde fino de tarjetas y controles.
    static let borde: Color = Color(hex: 0xE4E2DA)
    /// Fondo del selector segmentado, de las píldoras y de la barra de progreso.
    static let pista: Color = Color(hex: 0xEBE9E3)
    /// Fondo de los campos de texto.
    static let campo: Color = Color(hex: 0xF8F7F3)

    // MARK: Texto

    /// Texto principal, botón oscuro y chip seleccionado.
    static let tinta: Color = Color(hex: 0x1B1B1F)
    /// Texto secundario.
    static let tintaSecundaria: Color = Color(hex: 0x6A6A70)
    /// Texto deshabilitado y bordes de casillas.
    static let tintaTerciaria: Color = Color(hex: 0xA3A29C)

    // MARK: Verde de marca

    /// Color de marca: tarjeta de balance, palomitas y botones.
    static let verde: Color = Color(hex: 0x1F6F54)
    /// Recuadros dentro de la tarjeta verde.
    static let verdeOscuro: Color = Color(hex: 0x185A44)
    /// Fondos seleccionados y avatar verde.
    static let verdeSuave: Color = Color(hex: 0xDCEEE5)
    /// Etiquetas sobre la tarjeta verde.
    static let textoSuaveSobreVerde: Color = Color(hex: 0xCFE9DD)

    // MARK: Alerta

    /// Saldos en contra y tareas atrasadas.
    static let alerta: Color = Color(hex: 0xB4432F)
    /// Fondo suave de alertas.
    static let alertaSuave: Color = Color(hex: 0xF8E0DA)

    // MARK: Tonos de acento (fuerte para símbolo y texto, suave para fondo)

    /// Ícono de luz.
    static let amarillo: Color = Color(hex: 0x7A5A00)
    /// Fondo del ícono de luz y de la tarjeta de Modo Compras.
    static let amarilloSuave: Color = Color(hex: 0xFDEFC2)
    /// Ícono de internet y avatar morado.
    static let morado: Color = Color(hex: 0x4A3A9A)
    /// Fondo suave morado.
    static let moradoSuave: Color = Color(hex: 0xE5E0F6)
    /// Texto del avatar naranja.
    static let naranja: Color = Color(hex: 0x7A4A0C)
    /// Fondo suave naranja.
    static let naranjaSuave: Color = Color(hex: 0xFCE4BF)
    /// Texto del avatar azul y ícono de agua.
    static let azul: Color = Color(hex: 0x26477E)
    /// Fondo suave azul.
    static let azulSuave: Color = Color(hex: 0xDCE8F8)
    /// Ícono de gas y avatar rosa.
    static let rosa: Color = Color(hex: 0xA03A2A)
    /// Fondo suave rosa.
    static let rosaSuave: Color = Color(hex: 0xF8E0DA)

    // MARK: Medidas

    /// Margen lateral de las pantallas.
    static let margen: CGFloat = 20
    /// Radio de esquina de las tarjetas.
    static let radioTarjeta: CGFloat = 22
    /// Radio de esquina de botones y campos.
    static let radioControl: CGFloat = 14
}
