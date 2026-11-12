import SwiftUI

/// Avatares encimados con un aro del color del fondo, como arriba a la derecha en Inicio.
struct GrupoAvataresView: View {
    /// Roomies a mostrar; el último queda por encima de los demás.
    let usuarios: [Usuario]
    /// Diámetro de cada avatar en puntos.
    var tamano: CGFloat = 40

    var body: some View {
        HStack(spacing: -tamano * 0.25) {
            ForEach(usuarios) { usuario in
                AvatarView(usuario: usuario, tamano: tamano)
                    // El aro hace que se distinga cada avatar del que tiene debajo.
                    .overlay(Circle().stroke(Tema.fondo, lineWidth: 2))
            }
        }
    }
}

#Preview {
    GrupoAvataresView(usuarios: [
        Usuario(nombre: "Roberto", colorAvatar: .verde),
        Usuario(nombre: "Sara", colorAvatar: .morado),
        Usuario(nombre: "Mauricio", colorAvatar: .naranja),
        Usuario(nombre: "Ana", colorAvatar: .azul)
    ])
    .padding()
    .background(Tema.fondo)
}
