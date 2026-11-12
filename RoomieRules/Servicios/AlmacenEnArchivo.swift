import Foundation

/// Guarda el estado como JSON en `Application Support/RoomieRules/estado.json`.
///
/// Nunca truena: si algo falla al leer o escribir, lo anota en la consola y sigue. Lo peor que
/// puede pasar es que la app vuelva a arrancar con los datos de ejemplo.
struct AlmacenEnArchivo: AlmacenDeEstado {
    /// Archivo JSON donde se guarda el estado.
    let archivo: URL

    /// Almacén normal de la app: `Application Support/RoomieRules/estado.json`.
    init() {
        self.init(archivo: AlmacenEnArchivo.archivoPorDefecto)
    }

    /// Almacén en otro archivo. Sirve en pruebas, para no tocar los datos reales de la app.
    init(archivo: URL) {
        self.archivo = archivo
    }

    /// Ruta del archivo que usa la app: `Application Support/RoomieRules/estado.json`.
    static var archivoPorDefecto: URL {
        let administrador = FileManager.default
        // En iOS esta carpeta siempre existe como ruta; la temporal es solo un respaldo para no usar `!`.
        let base = administrador.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? administrador.temporaryDirectory
        return base
            .appendingPathComponent("RoomieRules", isDirectory: true)
            .appendingPathComponent("estado.json", isDirectory: false)
    }

    /// Lee el estado guardado. Devuelve `nil` si el archivo no existe, no se pudo leer
    /// o su contenido ya no corresponde al modelo actual.
    func cargar() -> EstadoHogar? {
        guard FileManager.default.fileExists(atPath: archivo.path) else { return nil }
        do {
            let datos = try Data(contentsOf: archivo)
            return try JSONDecoder().decode(EstadoHogar.self, from: datos)
        } catch {
            print("AlmacenEnArchivo: no se pudo leer el estado guardado: \(error)")
            return nil
        }
    }

    /// Escribe el estado completo en el archivo (crea la carpeta si hace falta).
    func guardar(_ estado: EstadoHogar) {
        do {
            let carpeta = archivo.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: carpeta, withIntermediateDirectories: true)

            let codificador = JSONEncoder()
            // Con sangría y llaves ordenadas el archivo se puede leer y comparar a simple vista.
            // Las fechas usan la estrategia por defecto (un número), que conserva el valor exacto:
            // lo que se carga es idéntico a lo que se guardó.
            codificador.outputFormatting = [.prettyPrinted, .sortedKeys]
            let datos = try codificador.encode(estado)

            // `.atomic` escribe primero en un archivo temporal y luego lo cambia de nombre:
            // si la app se cierra a media escritura, no queda un archivo a medias.
            try datos.write(to: archivo, options: .atomic)
        } catch {
            print("AlmacenEnArchivo: no se pudo guardar el estado: \(error)")
        }
    }

    /// Borra el archivo guardado (si existe).
    func borrar() {
        guard FileManager.default.fileExists(atPath: archivo.path) else { return }
        do {
            try FileManager.default.removeItem(at: archivo)
        } catch {
            print("AlmacenEnArchivo: no se pudo borrar el estado guardado: \(error)")
        }
    }
}
