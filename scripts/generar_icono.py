"""Genera el icono 1024x1024 de RoomieRules usando solo la biblioteca estandar.

Dibuja una casita blanca con una palomita verde sobre fondo verde #1F6F54.
Usa distancias con signo y antialiasing, y escribe un PNG RGB de 8 bits
sin canal alfa (iOS rechaza iconos con transparencia).
"""
import math
import os
import struct
import zlib

TAMANO = 1024
VERDE = (0x1F, 0x6F, 0x54)   # fondo y palomita
BLANCO = (255, 255, 255)     # casita
RAMPA = 1.5                  # ancho en pixeles de la transicion de bordes
GROSOR_TRAZO = 60            # grosor de la palomita en pixeles


def ruta_raiz():
    # scripts/generar_icono.py -> la raiz del repo esta un nivel arriba de scripts/
    return os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def sdf_rect_redondeado(px, py, cx, cy, mx, my, r):
    """Distancia con signo a un rectangulo redondeado centrado en (cx, cy)."""
    qx = abs(px - cx) - (mx - r)
    qy = abs(py - cy) - (my - r)
    fuera = math.hypot(max(qx, 0.0), max(qy, 0.0))
    dentro = min(max(qx, qy), 0.0)
    return fuera + dentro - r


def dist_segmento(px, py, ax, ay, bx, by):
    """Distancia de un punto a un segmento."""
    ex, ey = bx - ax, by - ay
    t = ((px - ax) * ex + (py - ay) * ey) / (ex * ex + ey * ey)
    t = min(1.0, max(0.0, t))
    return math.hypot(px - (ax + t * ex), py - (ay + t * ey))


def sdf_triangulo(px, py, vs):
    """Distancia con signo a un triangulo convexo de 3 vertices."""
    d = min(
        dist_segmento(px, py, vs[i][0], vs[i][1],
                      vs[(i + 1) % 3][0], vs[(i + 1) % 3][1])
        for i in range(3)
    )
    # Orientacion del triangulo y prueba de pertenencia por productos cruzados
    (x0, y0), (x1, y1), (x2, y2) = vs
    s = (x1 - x0) * (y2 - y0) - (y1 - y0) * (x2 - x0)
    dentro = True
    for i in range(3):
        ax, ay = vs[i]
        bx, by = vs[(i + 1) % 3]
        cruz = (bx - ax) * (py - ay) - (by - ay) * (px - ax)
        if cruz * s < 0:
            dentro = False
            break
    return -d if dentro else d


def cobertura(d):
    """Convierte una distancia con signo en cobertura 0..1 con rampa de RAMPA px."""
    v = 0.5 - d / RAMPA
    return 0.0 if v < 0.0 else (1.0 if v > 1.0 else v)


def dibujar():
    """Devuelve los bytes RGB (sin filtro) de todo el icono."""
    n = TAMANO
    c = n / 2

    # Cuerpo de la casa: rectangulo redondeado
    cuerpo_cx, cuerpo_cy = c, (415 + 819) / 2
    cuerpo_mx, cuerpo_my = 235, (819 - 415) / 2
    cuerpo_r = 36

    # Techo: triangulo mas ancho que el cuerpo (ancho total ~58 % del icono)
    techo = [(c, 205), (c + 296.5, 425), (c - 296.5, 425)]
    caja_techo = (215.5 - 3, 808.5 + 3, 205 - 3, 425 + 3)

    # Palomita: dos segmentos unidos, dibujados con grosor y puntas redondeadas
    A, B, C = (425, 615), (490, 680), (600, 555)
    caja_check = (395 - 3, 630 + 3, 525 - 3, 710 + 3)
    radio_trazo = GROSOR_TRAZO / 2

    fondo_r, fondo_g, fondo_b = VERDE
    salida = bytearray()

    for y in range(n):
        py = y + 0.5
        salida.append(0)  # byte de filtro 0 al inicio de cada fila
        en_franja_techo = caja_techo[2] <= py <= caja_techo[3]
        en_franja_check = caja_check[2] <= py <= caja_check[3]
        for x in range(n):
            px = x + 0.5

            d_cuerpo = sdf_rect_redondeado(
                px, py, cuerpo_cx, cuerpo_cy, cuerpo_mx, cuerpo_my, cuerpo_r)
            if en_franja_techo and caja_techo[0] <= px <= caja_techo[1]:
                d_techo = sdf_triangulo(px, py, techo)
            else:
                d_techo = 1e9
            d_casa = min(d_cuerpo, d_techo)

            if en_franja_check and caja_check[0] <= px <= caja_check[1]:
                d_palomita = min(
                    dist_segmento(px, py, A[0], A[1], B[0], B[1]),
                    dist_segmento(px, py, B[0], B[1], C[0], C[1]),
                ) - radio_trazo
            else:
                d_palomita = 1e9

            # Mezcla: fondo -> blanco (casa) -> verde (palomita dentro de la casa)
            t = cobertura(d_casa)
            r = fondo_r + (BLANCO[0] - fondo_r) * t
            g = fondo_g + (BLANCO[1] - fondo_g) * t
            b = fondo_b + (BLANCO[2] - fondo_b) * t
            k = cobertura(d_palomita) * t
            r = r + (fondo_r - r) * k
            g = g + (fondo_g - g) * k
            b = b + (fondo_b - b) * k

            salida.append(int(r + 0.5))
            salida.append(int(g + 0.5))
            salida.append(int(b + 0.5))

    return bytes(salida)


def fragmento(tipo, datos):
    """Bloque PNG: longitud, tipo, datos y CRC-32 sobre tipo + datos."""
    longitud = struct.pack(">I", len(datos))
    crc = struct.pack(">I", zlib.crc32(tipo + datos) & 0xFFFFFFFF)
    return longitud + tipo + datos + crc


def escribir_png(ruta, filas):
    """Escribe PNG RGB de 8 bits (tipo de color 2), sin alfa."""
    # IHDR: ancho, alto, profundidad 8, tipo de color 2 (RGB), compresion 0, filtro 0, entrelazado 0
    ihdr = struct.pack(">IIBBBBB", TAMANO, TAMANO, 8, 2, 0, 0, 0)
    png = (
        b"\x89PNG\r\n\x1a\n"
        + fragmento(b"IHDR", ihdr)
        + fragmento(b"IDAT", zlib.compress(filas, 9))
        + fragmento(b"IEND", b"")
    )
    with open(ruta, "wb") as f:
        f.write(png)


def main():
    carpeta = os.path.join(ruta_raiz(), "RoomieRules", "Assets.xcassets", "AppIcon.appiconset")
    os.makedirs(carpeta, exist_ok=True)
    ruta = os.path.join(carpeta, "AppIcon.png")
    escribir_png(ruta, dibujar())
    print("PNG escrito en:", ruta)
    print("Tamano:", os.path.getsize(ruta), "bytes")


if __name__ == "__main__":
    main()
