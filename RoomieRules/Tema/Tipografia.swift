import SwiftUI

/// Estilos de texto de la app (fuente del sistema). Se usan con `.font(Tipografia.cuerpo)`.
enum Tipografia {
    /// Título grande de cada pantalla ("Hola, Roberto").
    static let tituloPantalla: Font = Font.system(size: 34, weight: .bold)
    /// Línea gris sobre el título de pantalla.
    static let subtituloPantalla: Font = Font.system(size: 16, weight: .medium)
    /// Título de una sección ("Tus tareas esta semana").
    static let tituloSeccion: Font = Font.system(size: 22, weight: .bold)
    /// Título dentro de una tarjeta.
    static let tituloTarjeta: Font = Font.system(size: 18, weight: .semibold)
    /// Texto de lectura normal.
    static let cuerpo: Font = Font.system(size: 16, weight: .regular)
    /// Texto normal con énfasis (nombres, botones).
    static let cuerpoFuerte: Font = Font.system(size: 16, weight: .semibold)
    /// Texto secundario más pequeño (fechas, detalles).
    static let secundario: Font = Font.system(size: 14, weight: .regular)
    /// Etiquetas, chips y píldoras.
    static let etiqueta: Font = Font.system(size: 13, weight: .semibold)
    /// Cifra principal de la tarjeta de balance.
    static let cifraGrande: Font = Font.system(size: 44, weight: .bold)
    /// Cifras medianas (montos en tarjetas).
    static let cifra: Font = Font.system(size: 22, weight: .bold)
}
