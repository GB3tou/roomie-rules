import SwiftUI

/// Círculo pastel con la inicial del roomie, como en las listas de tareas y gastos.
struct AvatarView: View {
    /// Roomie del que se dibuja la inicial y se toma el color.
    let usuario: Usuario
    /// Diámetro del círculo en puntos; la letra se escala en proporción.
    var tamano: CGFloat = 40

    var body: some View {
        Text(usuario.inicial)
            .font(.system(size: tamano * 0.42, weight: .semibold))
            .foregroundStyle(usuario.colorAvatar.texto)
            .frame(width: tamano, height: tamano)
            .background(Circle().fill(usuario.colorAvatar.fondo))
            .accessibilityLabel(usuario.nombre)
    }
}

#Preview {
    HStack(spacing: 12) {
        AvatarView(usuario: Usuario(nombre: "Roberto", colorAvatar: .verde))
        AvatarView(usuario: Usuario(nombre: "Sara", colorAvatar: .morado), tamano: 52)
        AvatarView(usuario: Usuario(nombre: "Mauricio", colorAvatar: .naranja), tamano: 30)
    }
    .padding()
    .background(Tema.fondo)
}
