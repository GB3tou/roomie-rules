import SwiftUI

/// Ícono y colores con los que se dibuja un gasto en las listas.
/// Se decide por palabras de la descripción y, si no hay pista, por la categoría.
struct EstiloGasto {
    /// Nombre del SF Symbol.
    let simbolo: String
    /// Color de fondo (tono "Suave").
    let fondo: Color
    /// Color del símbolo (tono fuerte).
    let color: Color

    /// Elige el estilo de un gasto. Compara palabras completas sin distinguir mayúsculas ni
    /// acentos, así "gas" no coincide con "gasolina".
    static func de(_ gasto: Gasto) -> EstiloGasto {
        if gasto.esLiquidacion {
            return EstiloGasto(simbolo: "arrow.left.arrow.right", fondo: Tema.verdeSuave, color: Tema.verde)
        }

        let normalizada = gasto.descripcion.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: nil)
        let separadas = normalizada.components(separatedBy: CharacterSet.letters.inverted)
        let palabras = Set(separadas.filter { !$0.isEmpty })

        func tiene(_ claves: [String]) -> Bool {
            return claves.contains { palabras.contains($0) }
        }

        if tiene(["luz", "cfe", "electricidad"]) {
            return EstiloGasto(simbolo: "bolt", fondo: Tema.amarilloSuave, color: Tema.amarillo)
        }
        if tiene(["internet", "wifi", "telmex", "izzi", "totalplay"]) {
            return EstiloGasto(simbolo: "wifi", fondo: Tema.moradoSuave, color: Tema.morado)
        }
        if tiene(["gas"]) {
            return EstiloGasto(simbolo: "flame", fondo: Tema.rosaSuave, color: Tema.rosa)
        }
        if tiene(["agua"]) {
            return EstiloGasto(simbolo: "drop", fondo: Tema.azulSuave, color: Tema.azul)
        }
        if gasto.categoria == .supermercado || tiene(["super", "despensa", "mercado"]) {
            return EstiloGasto(simbolo: "cart", fondo: Tema.verdeSuave, color: Tema.verde)
        }
        if gasto.categoria == .renta || tiene(["renta"]) {
            return EstiloGasto(simbolo: "house", fondo: Tema.naranjaSuave, color: Tema.naranja)
        }
        if gasto.categoria == .servicios {
            return EstiloGasto(simbolo: "bolt", fondo: Tema.amarilloSuave, color: Tema.amarillo)
        }
        return EstiloGasto(simbolo: "tag", fondo: Tema.pista, color: Tema.tintaSecundaria)
    }
}
