import SwiftUI

/// Tarjeta verde con el balance general del usuario actual y sus cifras del mes.
struct InicioTarjetaBalance: View {
    @EnvironmentObject private var store: HogarStore
    @EnvironmentObject private var navegacion: Navegacion

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Tu balance general")
                .font(Tipografia.cuerpoFuerte)
                .foregroundStyle(Tema.textoSuaveSobreVerde)
            Text(titular)
                .font(Tipografia.cifraGrande)
                .foregroundStyle(Color.white)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(detalle)
                .font(Tipografia.cuerpo)
                .foregroundStyle(Color.white)
            recuadros
                .padding(.top, 10)
            botonDesglose
                .padding(.top, 6)
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Tema.verde)
        )
    }

    private var titular: String {
        let balance = store.miBalance
        if balance > 0.005 {
            return "Te deben \(Formato.dinero(balance))"
        }
        if balance < -0.005 {
            return "Debes \(Formato.dinero(abs(balance)))"
        }
        return "Estás al corriente"
    }

    private func frase(de transferencia: Transferencia) -> String {
        let monto = Formato.dinero(transferencia.monto)
        if store.esUsuarioActual(transferencia.para) {
            return "\(store.nombre(de: transferencia.de)) te debe \(monto)"
        }
        return "Le debes \(monto) a \(store.nombre(de: transferencia.para))"
    }

    private var detalle: String {
        let lista = store.misTransferencias
        guard let primera = lista.first else {
            return "No le debes a nadie y nadie te debe."
        }
        let inicio = frase(de: primera)
        if lista.count == 1 {
            return inicio
        }
        if lista.count == 2 {
            return "\(inicio) y \(frase(de: lista[1]))"
        }
        return "\(inicio) y \(lista.count - 1) más"
    }

    private var recuadros: some View {
        HStack(spacing: 12) {
            recuadro(etiqueta: "Pagaste este mes", monto: store.pagadoPorMiEsteMes)
            recuadro(etiqueta: "Tu parte", monto: store.miParteEsteMes)
        }
    }

    private func recuadro(etiqueta: String, monto: Double) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(etiqueta)
                .font(Tipografia.secundario)
                .foregroundStyle(Tema.textoSuaveSobreVerde)
            Text(Formato.dinero(monto))
                .font(Tipografia.cifra)
                .foregroundStyle(Color.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Tema.verdeOscuro)
        )
    }

    private var botonDesglose: some View {
        Button {
            navegacion.verDeudas()
        } label: {
            HStack(spacing: 8) {
                Text("Ver desglose de deudas")
                Image(systemName: "arrow.right")
            }
        }
        .buttonStyle(EstiloBotonPildoraBlanca())
    }
}

#Preview {
    InicioTarjetaBalance()
        .padding(Tema.margen)
        .background(Tema.fondo)
        .environmentObject(HogarStore.deEjemplo())
        .environmentObject(Navegacion())
}
