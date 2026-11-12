#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Genera RoomieRules.xcodeproj a partir de los archivos que hay en disco.

Uso (desde cualquier carpeta):

    python scripts/generar_proyecto_xcode.py              # genera y verifica
    python scripts/generar_proyecto_xcode.py --verificar  # solo verifica lo que ya existe

Qué hace:
  * Todos los *.swift bajo RoomieRules/       -> fase Sources del target RoomieRules (app).
  * Cada carpeta *.xcassets bajo RoomieRules/ -> una referencia en la fase Resources.
  * Todos los *.swift bajo RoomieRulesTests/  -> fase Sources del target RoomieRulesTests.
  * Escribe RoomieRules.xcodeproj/project.pbxproj (formato OpenStep clásico, objectVersion 56,
    sin carpetas sincronizadas, para que abra en Xcode 15 o posterior) y el esquema compartido
    RoomieRules.xcodeproj/xcshareddata/xcschemes/RoomieRules.xcscheme.

Es determinista: los mismos archivos producen exactamente los mismos bytes. Los IDs de Xcode
son los primeros 24 caracteres del MD5 de "<tipo>:<ruta relativa>".

Importante: si agregas archivos desde Xcode, se perderán al volver a correr este script a menos
que existan en disco dentro de RoomieRules/ o RoomieRulesTests/ (que es lo normal). No edites
project.pbxproj a mano: agrega o mueve los .swift en disco y vuelve a correr el script.

Solo usa la biblioteca estándar; funciona con Python 3.8 o posterior.
"""

import argparse
import hashlib
import os
import re
import sys
import unicodedata
import xml.etree.ElementTree as ET

# --------------------------------------------------------------------------------------------
# Configuración
# --------------------------------------------------------------------------------------------

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

NOMBRE_APP = "RoomieRules"
NOMBRE_PRUEBAS = "RoomieRulesTests"
CARPETA_APP = "RoomieRules"
CARPETA_PRUEBAS = "RoomieRulesTests"
PROYECTO = "RoomieRules.xcodeproj"
RUTA_PBXPROJ = os.path.join(RAIZ, PROYECTO, "project.pbxproj")
RUTA_ESQUEMA = os.path.join(RAIZ, PROYECTO, "xcshareddata", "xcschemes", "RoomieRules.xcscheme")

BUNDLE_ID_APP = "mx.equipo4.RoomieRules"
BUNDLE_ID_PRUEBAS = "mx.equipo4.RoomieRulesTests"
DEPLOYMENT_TARGET = "17.0"

# Cadenas que pueden ir sin comillas en el formato OpenStep (criterio conservador).
SIN_COMILLAS = re.compile(r"^[A-Za-z0-9_$./]+$")

# --------------------------------------------------------------------------------------------
# Utilidades
# --------------------------------------------------------------------------------------------


class ErrorProyecto(Exception):
    """Error con un mensaje pensado para la persona que corre el script."""


def clave_orden(nombre):
    """Orden alfabético estable sin distinguir mayúsculas (desempata con el nombre original)."""
    return (nombre.lower(), nombre)


def es_ignorado(nombre):
    return nombre.startswith(".") or nombre == ".DS_Store"


def unir(*partes):
    """Une rutas relativas con '/' (siempre estilo POSIX, también en Windows)."""
    return "/".join(p for p in partes if p)


# --------------------------------------------------------------------------------------------
# Descubrimiento de archivos
# --------------------------------------------------------------------------------------------


def descubrir(carpeta, aceptar_assets):
    """Recorre RAIZ/carpeta y devuelve (swift, assets, ignorados) como rutas relativas a RAIZ.

    Las carpetas *.xcassets cuentan como un solo elemento (no se entra en ellas).
    """
    swift, assets, ignorados = [], [], []
    base = os.path.join(RAIZ, carpeta)
    if not os.path.isdir(base):
        return swift, assets, ignorados

    def recorrer(rel):
        absoluta = os.path.join(RAIZ, *rel.split("/"))
        for nombre in sorted(os.listdir(absoluta), key=clave_orden):
            if es_ignorado(nombre):
                continue
            ruta_rel = unir(rel, nombre)
            ruta_abs = os.path.join(absoluta, nombre)
            if os.path.isdir(ruta_abs):
                if nombre.endswith(".xcassets"):
                    if aceptar_assets:
                        assets.append(ruta_rel)
                    else:
                        ignorados.append(ruta_rel)
                else:
                    recorrer(ruta_rel)
            elif os.path.isfile(ruta_abs):
                if nombre.endswith(".swift"):
                    swift.append(ruta_rel)
                else:
                    ignorados.append(ruta_rel)

    recorrer(carpeta)
    return swift, assets, ignorados


# --------------------------------------------------------------------------------------------
# Modelo y serialización OpenStep
# --------------------------------------------------------------------------------------------


class Ref(object):
    """Referencia a un objeto del proyecto: se escribe como `ID /* comentario */`."""

    __slots__ = ("id", "comentario")

    def __init__(self, ident, comentario=None):
        self.id = ident
        self.comentario = comentario


def citar(texto):
    if texto != "" and SIN_COMILLAS.match(texto):
        return texto
    escapado = (
        texto.replace("\\", "\\\\")
        .replace('"', '\\"')
        .replace("\n", "\\n")
        .replace("\t", "\\t")
    )
    return '"' + escapado + '"'


def formatear(valor, nivel, en_linea):
    if isinstance(valor, Ref):
        if valor.comentario:
            return "%s /* %s */" % (valor.id, valor.comentario.replace("*/", "* /"))
        return valor.id
    if isinstance(valor, str):
        return citar(valor)
    if isinstance(valor, list):
        if en_linea:
            return "(" + "".join(formatear(v, nivel, True) + ", " for v in valor) + ")"
        sangria = "\t" * (nivel + 1)
        lineas = ["("]
        for v in valor:
            lineas.append(sangria + formatear(v, nivel + 1, False) + ",")
        lineas.append("\t" * nivel + ")")
        return "\n".join(lineas)
    if isinstance(valor, dict):
        if en_linea:
            partes = [
                "%s = %s; " % (formatear(k, nivel, True), formatear(v, nivel, True))
                for k, v in valor.items()
            ]
            return "{" + "".join(partes) + "}"
        sangria = "\t" * (nivel + 1)
        lineas = ["{"]
        for k, v in valor.items():
            lineas.append(
                "%s%s = %s;" % (sangria, formatear(k, nivel + 1, False), formatear(v, nivel + 1, False))
            )
        lineas.append("\t" * nivel + "}")
        return "\n".join(lineas)
    raise TypeError("Tipo no soportado en el pbxproj: %r" % (valor,))


def ordenar_propiedades(isa, props):
    """`isa` primero y el resto en orden alfabético, como lo escribe Xcode."""
    resultado = {"isa": isa}
    for clave in sorted(props):
        resultado[clave] = props[clave]
    return resultado


def ajustes_ordenados(ajustes):
    return {k: ajustes[k] for k in sorted(ajustes)}


class Proyecto(object):
    def __init__(self):
        self.objetos = {}  # id -> (isa, props, comentario)
        self.claves_id = {}  # id -> clave que lo generó (para detectar colisiones)

    def nuevo_id(self, clave):
        ident = hashlib.md5(clave.encode("utf-8")).hexdigest()[:24].upper()
        previa = self.claves_id.get(ident)
        if previa is not None and previa != clave:
            raise ErrorProyecto("Colisión de IDs: %r y %r generan %s" % (previa, clave, ident))
        if previa == clave:
            raise ErrorProyecto("Se intentó crear dos veces el objeto %r" % clave)
        self.claves_id[ident] = clave
        return ident

    def agregar(self, ident, isa, comentario, **props):
        self.objetos[ident] = (isa, ordenar_propiedades(isa, props), comentario)
        return Ref(ident, comentario)

    def serializar(self, raiz):
        en_linea = {"PBXBuildFile", "PBXFileReference"}
        por_isa = {}
        for ident, (isa, props, comentario) in self.objetos.items():
            por_isa.setdefault(isa, []).append((ident, props, comentario))

        salida = ["// !$*UTF8*$!", "{", "\tarchiveVersion = 1;", "\tclasses = {", "\t};",
                  "\tobjectVersion = 56;", "\tobjects = {"]
        for isa in sorted(por_isa):
            salida.append("")
            salida.append("/* Begin %s section */" % isa)
            for ident, props, comentario in sorted(por_isa[isa], key=lambda t: t[0]):
                cabeza = ident + (" /* %s */" % comentario if comentario else "")
                cuerpo = formatear(props, 2, isa in en_linea)
                salida.append("\t\t%s = %s;" % (cabeza, cuerpo))
            salida.append("/* End %s section */" % isa)
        salida.append("\t};")
        salida.append("\trootObject = %s;" % formatear(raiz, 1, True))
        salida.append("}")
        return "\n".join(salida) + "\n"


# --------------------------------------------------------------------------------------------
# Ajustes de compilación
# --------------------------------------------------------------------------------------------


def ajustes_proyecto(debug):
    comunes = {
        "ALWAYS_SEARCH_USER_PATHS": "NO",
        "CLANG_ANALYZER_NONNULL": "YES",
        "CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION": "YES_AGGRESSIVE",
        "CLANG_CXX_LANGUAGE_STANDARD": "gnu++20",
        "CLANG_ENABLE_MODULES": "YES",
        "CLANG_ENABLE_OBJC_ARC": "YES",
        "CLANG_ENABLE_OBJC_WEAK": "YES",
        "CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING": "YES",
        "CLANG_WARN_BOOL_CONVERSION": "YES",
        "CLANG_WARN_COMMA": "YES",
        "CLANG_WARN_CONSTANT_CONVERSION": "YES",
        "CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS": "YES",
        "CLANG_WARN_DIRECT_OBJC_ISA_USAGE": "YES_ERROR",
        "CLANG_WARN_DOCUMENTATION_COMMENTS": "YES",
        "CLANG_WARN_EMPTY_BODY": "YES",
        "CLANG_WARN_ENUM_CONVERSION": "YES",
        "CLANG_WARN_INFINITE_RECURSION": "YES",
        "CLANG_WARN_INT_CONVERSION": "YES",
        "CLANG_WARN_NON_LITERAL_NULL_CONVERSION": "YES",
        "CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF": "YES",
        "CLANG_WARN_OBJC_LITERAL_CONVERSION": "YES",
        "CLANG_WARN_OBJC_ROOT_CLASS": "YES_ERROR",
        "CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER": "YES",
        "CLANG_WARN_RANGE_LOOP_ANALYSIS": "YES",
        "CLANG_WARN_STRICT_PROTOTYPES": "YES",
        "CLANG_WARN_SUSPICIOUS_MOVE": "YES",
        "CLANG_WARN_UNGUARDED_AVAILABILITY": "YES_AGGRESSIVE",
        "CLANG_WARN_UNREACHABLE_CODE": "YES",
        "CLANG_WARN__DUPLICATE_METHOD_MATCH": "YES",
        "COPY_PHASE_STRIP": "NO",
        "ENABLE_STRICT_OBJC_MSGSEND": "YES",
        "ENABLE_USER_SCRIPT_SANDBOXING": "YES",
        "GCC_C_LANGUAGE_STANDARD": "gnu17",
        "GCC_NO_COMMON_BLOCKS": "YES",
        "GCC_WARN_64_TO_32_BIT_CONVERSION": "YES",
        "GCC_WARN_ABOUT_RETURN_TYPE": "YES_ERROR",
        "GCC_WARN_UNDECLARED_SELECTOR": "YES",
        "GCC_WARN_UNINITIALIZED_AUTOS": "YES_AGGRESSIVE",
        "GCC_WARN_UNUSED_FUNCTION": "YES",
        "GCC_WARN_UNUSED_VARIABLE": "YES",
        "IPHONEOS_DEPLOYMENT_TARGET": DEPLOYMENT_TARGET,
        "LOCALIZATION_PREFERS_STRING_CATALOGS": "YES",
        "MTL_FAST_MATH": "YES",
        "SDKROOT": "iphoneos",
    }
    if debug:
        comunes.update({
            "DEBUG_INFORMATION_FORMAT": "dwarf",
            "ENABLE_TESTABILITY": "YES",
            "GCC_DYNAMIC_NO_PIC": "NO",
            "GCC_OPTIMIZATION_LEVEL": "0",
            "GCC_PREPROCESSOR_DEFINITIONS": ["DEBUG=1", "$(inherited)"],
            "MTL_ENABLE_DEBUG_INFO": "INCLUDE_SOURCE",
            "ONLY_ACTIVE_ARCH": "YES",
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS": "DEBUG $(inherited)",
            "SWIFT_OPTIMIZATION_LEVEL": "-Onone",
        })
    else:
        comunes.update({
            "DEBUG_INFORMATION_FORMAT": "dwarf-with-dsym",
            "ENABLE_NS_ASSERTIONS": "NO",
            "MTL_ENABLE_DEBUG_INFO": "NO",
            "SWIFT_COMPILATION_MODE": "wholemodule",
            "VALIDATE_PRODUCT": "YES",
        })
    return ajustes_ordenados(comunes)


def ajustes_app():
    return ajustes_ordenados({
        "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
        "ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME": "AccentColor",
        "CODE_SIGN_STYLE": "Automatic",
        "CURRENT_PROJECT_VERSION": "1",
        "ENABLE_PREVIEWS": "YES",
        "GENERATE_INFOPLIST_FILE": "YES",
        "INFOPLIST_KEY_CFBundleDisplayName": NOMBRE_APP,
        "INFOPLIST_KEY_UIApplicationSceneManifest_Generation": "YES",
        "INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents": "YES",
        "INFOPLIST_KEY_UILaunchScreen_Generation": "YES",
        "INFOPLIST_KEY_UISupportedInterfaceOrientations": "UIInterfaceOrientationPortrait",
        "IPHONEOS_DEPLOYMENT_TARGET": DEPLOYMENT_TARGET,
        "LD_RUNPATH_SEARCH_PATHS": ["$(inherited)", "@executable_path/Frameworks"],
        "MARKETING_VERSION": "1.0",
        "PRODUCT_BUNDLE_IDENTIFIER": BUNDLE_ID_APP,
        "PRODUCT_NAME": "$(TARGET_NAME)",
        "SWIFT_EMIT_LOC_STRINGS": "YES",
        "SWIFT_VERSION": "5.0",
        "TARGETED_DEVICE_FAMILY": "1",
    })


def ajustes_pruebas():
    return ajustes_ordenados({
        "BUNDLE_LOADER": "$(TEST_HOST)",
        "CODE_SIGN_STYLE": "Automatic",
        "CURRENT_PROJECT_VERSION": "1",
        "GENERATE_INFOPLIST_FILE": "YES",
        "IPHONEOS_DEPLOYMENT_TARGET": DEPLOYMENT_TARGET,
        "MARKETING_VERSION": "1.0",
        "PRODUCT_BUNDLE_IDENTIFIER": BUNDLE_ID_PRUEBAS,
        "PRODUCT_NAME": "$(TARGET_NAME)",
        "SWIFT_EMIT_LOC_STRINGS": "NO",
        "SWIFT_VERSION": "5.0",
        "TARGETED_DEVICE_FAMILY": "1",
        "TEST_HOST": "$(BUILT_PRODUCTS_DIR)/%s.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/%s" % (NOMBRE_APP, NOMBRE_APP),
    })


# --------------------------------------------------------------------------------------------
# Construcción del proyecto
# --------------------------------------------------------------------------------------------


def construir_arbol(rutas):
    """Convierte rutas 'a/b/c.swift' en un árbol {carpeta: {...}, archivo: None}."""
    arbol = {}
    for ruta in rutas:
        nodo = arbol
        partes = ruta.split("/")
        for parte in partes[:-1]:
            nodo = nodo.setdefault(parte, {})
            if nodo is None:
                raise ErrorProyecto("Conflicto de rutas en %r" % ruta)
        nodo[partes[-1]] = None
    return arbol


def generar_contenido(app_swift, app_assets, pruebas_swift):
    p = Proyecto()

    # --- IDs fijos ---
    id_proyecto = p.nuevo_id("project:" + NOMBRE_APP)
    id_grupo_principal = p.nuevo_id("group:")
    id_grupo_productos = p.nuevo_id("group:Products")
    id_producto_app = p.nuevo_id("product:%s.app" % NOMBRE_APP)
    id_producto_pruebas = p.nuevo_id("product:%s.xctest" % NOMBRE_PRUEBAS)
    id_target_app = p.nuevo_id("target:" + NOMBRE_APP)
    id_target_pruebas = p.nuevo_id("target:" + NOMBRE_PRUEBAS)
    id_fases = {}
    for target in (NOMBRE_APP, NOMBRE_PRUEBAS):
        for fase in ("Sources", "Frameworks", "Resources"):
            id_fases[(target, fase)] = p.nuevo_id("phase:%s:%s" % (target, fase))
    id_lista_proyecto = p.nuevo_id("configlist:project")
    id_lista_app = p.nuevo_id("configlist:target:" + NOMBRE_APP)
    id_lista_pruebas = p.nuevo_id("configlist:target:" + NOMBRE_PRUEBAS)
    id_config = {}
    for duenio in ("project", NOMBRE_APP, NOMBRE_PRUEBAS):
        for conf in ("Debug", "Release"):
            id_config[(duenio, conf)] = p.nuevo_id("config:%s:%s" % (duenio, conf))
    id_proxy = p.nuevo_id("proxy:%s->%s" % (NOMBRE_PRUEBAS, NOMBRE_APP))
    id_dependencia = p.nuevo_id("dependency:%s->%s" % (NOMBRE_PRUEBAS, NOMBRE_APP))

    # --- Referencias de archivos y build files ---
    fuentes_por_target = {NOMBRE_APP: [], NOMBRE_PRUEBAS: []}
    recursos_app = []
    ref_archivo = {}  # ruta relativa -> Ref

    def agregar_archivo(ruta, tipo):
        ident = p.nuevo_id("fileref:" + ruta)
        nombre = ruta.split("/")[-1]
        ref_archivo[ruta] = p.agregar(
            ident, "PBXFileReference", nombre,
            lastKnownFileType=tipo, path=nombre, sourceTree="<group>",
        )
        return nombre

    def agregar_build_file(ruta, fase, lista):
        nombre = ruta.split("/")[-1]
        ident = p.nuevo_id("buildfile:%s:%s" % (fase, ruta))
        lista.append(p.agregar(
            ident, "PBXBuildFile", "%s in %s" % (nombre, fase),
            fileRef=ref_archivo[ruta],
        ))

    for ruta in app_swift:
        agregar_archivo(ruta, "sourcecode.swift")
        agregar_build_file(ruta, "Sources", fuentes_por_target[NOMBRE_APP])
    for ruta in app_assets:
        agregar_archivo(ruta, "folder.assetcatalog")
        agregar_build_file(ruta, "Resources", recursos_app)
    for ruta in pruebas_swift:
        agregar_archivo(ruta, "sourcecode.swift")
        agregar_build_file(ruta, "Sources", fuentes_por_target[NOMBRE_PRUEBAS])

    # Orden estable de las fases por ruta completa (sin distinguir mayúsculas).
    def ordenar_por_ruta(lista, rutas):
        orden = {ref_archivo[r].id: clave_orden(r) for r in rutas}
        lista.sort(key=lambda bf: orden[p.objetos[bf.id][1]["fileRef"].id])

    ordenar_por_ruta(fuentes_por_target[NOMBRE_APP], app_swift)
    ordenar_por_ruta(fuentes_por_target[NOMBRE_PRUEBAS], pruebas_swift)
    ordenar_por_ruta(recursos_app, app_assets)

    # --- Productos ---
    ref_producto_app = p.agregar(
        id_producto_app, "PBXFileReference", "%s.app" % NOMBRE_APP,
        explicitFileType="wrapper.application", includeInIndex="0",
        path="%s.app" % NOMBRE_APP, sourceTree="BUILT_PRODUCTS_DIR",
    )
    ref_producto_pruebas = p.agregar(
        id_producto_pruebas, "PBXFileReference", "%s.xctest" % NOMBRE_PRUEBAS,
        explicitFileType="wrapper.cfbundle", includeInIndex="0",
        path="%s.xctest" % NOMBRE_PRUEBAS, sourceTree="BUILT_PRODUCTS_DIR",
    )

    # --- Grupos ---
    def crear_grupo(ruta_rel, nodo):
        hijos_carpetas = sorted((k for k, v in nodo.items() if v is not None), key=clave_orden)
        hijos_archivos = sorted((k for k, v in nodo.items() if v is None), key=clave_orden)
        hijos = []
        for nombre in hijos_carpetas:
            hijos.append(crear_grupo(unir(ruta_rel, nombre), nodo[nombre]))
        for nombre in hijos_archivos:
            hijos.append(ref_archivo[unir(ruta_rel, nombre)])
        nombre = ruta_rel.split("/")[-1]
        return p.agregar(
            p.nuevo_id("group:" + ruta_rel), "PBXGroup", nombre,
            children=hijos, path=nombre, sourceTree="<group>",
        )

    arbol = construir_arbol(list(app_swift) + list(app_assets) + list(pruebas_swift))
    hijos_principal = [crear_grupo(nombre, arbol[nombre]) for nombre in sorted(arbol, key=clave_orden)]
    ref_productos = p.agregar(
        id_grupo_productos, "PBXGroup", "Products",
        children=[ref_producto_app, ref_producto_pruebas], name="Products", sourceTree="<group>",
    )
    hijos_principal.append(ref_productos)
    ref_principal = p.agregar(id_grupo_principal, "PBXGroup", None,
                              children=hijos_principal, sourceTree="<group>")

    # --- Fases ---
    def fase(target, nombre, isa, archivos):
        return p.agregar(
            id_fases[(target, nombre)], isa, nombre,
            buildActionMask="2147483647", files=archivos, runOnlyForDeploymentPostprocessing="0",
        )

    fases_app = [
        fase(NOMBRE_APP, "Sources", "PBXSourcesBuildPhase", fuentes_por_target[NOMBRE_APP]),
        fase(NOMBRE_APP, "Frameworks", "PBXFrameworksBuildPhase", []),
        fase(NOMBRE_APP, "Resources", "PBXResourcesBuildPhase", recursos_app),
    ]
    fases_pruebas = [
        fase(NOMBRE_PRUEBAS, "Sources", "PBXSourcesBuildPhase", fuentes_por_target[NOMBRE_PRUEBAS]),
        fase(NOMBRE_PRUEBAS, "Frameworks", "PBXFrameworksBuildPhase", []),
        fase(NOMBRE_PRUEBAS, "Resources", "PBXResourcesBuildPhase", []),
    ]

    # --- Configuraciones ---
    def config(duenio, nombre, ajustes):
        return p.agregar(id_config[(duenio, nombre)], "XCBuildConfiguration", nombre,
                         buildSettings=ajustes, name=nombre)

    def lista(ident, comentario, duenio, ajustes_debug, ajustes_release):
        return p.agregar(
            ident, "XCConfigurationList", comentario,
            buildConfigurations=[config(duenio, "Debug", ajustes_debug),
                                 config(duenio, "Release", ajustes_release)],
            defaultConfigurationIsVisible="0", defaultConfigurationName="Release",
        )

    lista_proyecto = lista(id_lista_proyecto,
                           'Build configuration list for PBXProject "%s"' % NOMBRE_APP,
                           "project", ajustes_proyecto(True), ajustes_proyecto(False))
    lista_app = lista(id_lista_app,
                      'Build configuration list for PBXNativeTarget "%s"' % NOMBRE_APP,
                      NOMBRE_APP, ajustes_app(), ajustes_app())
    lista_pruebas = lista(id_lista_pruebas,
                          'Build configuration list for PBXNativeTarget "%s"' % NOMBRE_PRUEBAS,
                          NOMBRE_PRUEBAS, ajustes_pruebas(), ajustes_pruebas())

    # --- Targets ---
    ref_proyecto = Ref(id_proyecto, "Project object")
    ref_target_app = p.agregar(
        id_target_app, "PBXNativeTarget", NOMBRE_APP,
        buildConfigurationList=lista_app, buildPhases=fases_app, buildRules=[],
        dependencies=[], name=NOMBRE_APP, productName=NOMBRE_APP,
        productReference=ref_producto_app, productType="com.apple.product-type.application",
    )
    ref_proxy = p.agregar(
        id_proxy, "PBXContainerItemProxy", "PBXContainerItemProxy",
        containerPortal=ref_proyecto, proxyType="1",
        remoteGlobalIDString=Ref(id_target_app), remoteInfo=NOMBRE_APP,
    )
    ref_dependencia = p.agregar(
        id_dependencia, "PBXTargetDependency", "PBXTargetDependency",
        target=ref_target_app, targetProxy=ref_proxy,
    )
    ref_target_pruebas = p.agregar(
        id_target_pruebas, "PBXNativeTarget", NOMBRE_PRUEBAS,
        buildConfigurationList=lista_pruebas, buildPhases=fases_pruebas, buildRules=[],
        dependencies=[ref_dependencia], name=NOMBRE_PRUEBAS, productName=NOMBRE_PRUEBAS,
        productReference=ref_producto_pruebas,
        productType="com.apple.product-type.bundle.unit-test",
    )

    # --- Proyecto ---
    atributos_targets = {
        Ref(id_target_app): {"CreatedOnToolsVersion": "15.0"},
        Ref(id_target_pruebas): {"CreatedOnToolsVersion": "15.0", "TestTargetID": Ref(id_target_app)},
    }
    p.agregar(
        id_proyecto, "PBXProject", "Project object",
        attributes={
            "BuildIndependentTargetsInParallel": "1",
            "LastSwiftUpdateCheck": "1500",
            "LastUpgradeCheck": "1500",
            "TargetAttributes": atributos_targets,
        },
        buildConfigurationList=lista_proyecto,
        compatibilityVersion="Xcode 14.0",
        developmentRegion="es",
        hasScannedForEncodings="0",
        knownRegions=["es", "Base"],
        mainGroup=ref_principal,
        productRefGroup=ref_productos,
        projectDirPath="",
        projectRoot="",
        targets=[ref_target_app, ref_target_pruebas],
    )

    pbxproj = p.serializar(ref_proyecto)
    esquema = generar_esquema(id_target_app, id_target_pruebas)
    return pbxproj, esquema


def referencia_xml(sangria, blueprint, producto, nombre):
    s = " " * sangria
    return (
        "%s<BuildableReference\n"
        "%s   BuildableIdentifier = \"primary\"\n"
        "%s   BlueprintIdentifier = \"%s\"\n"
        "%s   BuildableName = \"%s\"\n"
        "%s   BlueprintName = \"%s\"\n"
        "%s   ReferencedContainer = \"container:%s\">\n"
        "%s</BuildableReference>\n"
    ) % (s, s, s, blueprint, s, producto, s, nombre, s, PROYECTO, s)


def generar_esquema(id_app, id_pruebas):
    app = lambda n: referencia_xml(n, id_app, NOMBRE_APP + ".app", NOMBRE_APP)
    pruebas = referencia_xml(12, id_pruebas, NOMBRE_PRUEBAS + ".xctest", NOMBRE_PRUEBAS)
    return (
        '<?xml version="1.0" encoding="UTF-8"?>\n'
        "<Scheme\n"
        '   LastUpgradeVersion = "1500"\n'
        '   version = "1.7">\n'
        "   <BuildAction\n"
        '      parallelizeBuildables = "YES"\n'
        '      buildImplicitDependencies = "YES">\n'
        "      <BuildActionEntries>\n"
        "         <BuildActionEntry\n"
        '            buildForTesting = "YES"\n'
        '            buildForRunning = "YES"\n'
        '            buildForProfiling = "YES"\n'
        '            buildForArchiving = "YES"\n'
        '            buildForAnalyzing = "YES">\n'
        + app(12) +
        "         </BuildActionEntry>\n"
        "      </BuildActionEntries>\n"
        "   </BuildAction>\n"
        "   <TestAction\n"
        '      buildConfiguration = "Debug"\n'
        '      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"\n'
        '      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"\n'
        '      shouldUseLaunchSchemeArgsEnv = "YES">\n'
        "      <Testables>\n"
        "         <TestableReference\n"
        '            skipped = "NO"\n'
        '            parallelizable = "NO">\n'
        + pruebas +
        "         </TestableReference>\n"
        "      </Testables>\n"
        "   </TestAction>\n"
        "   <LaunchAction\n"
        '      buildConfiguration = "Debug"\n'
        '      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"\n'
        '      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"\n'
        '      launchStyle = "0"\n'
        '      useCustomWorkingDirectory = "NO"\n'
        '      ignoresPersistentStateOnLaunch = "NO"\n'
        '      debugDocumentVersioning = "YES"\n'
        '      debugServiceExtension = "internal"\n'
        '      allowLocationSimulation = "YES">\n'
        "      <BuildableProductRunnable\n"
        '         runnableDebuggingMode = "0">\n'
        + app(9) +
        "      </BuildableProductRunnable>\n"
        "   </LaunchAction>\n"
        "   <ProfileAction\n"
        '      buildConfiguration = "Release"\n'
        '      shouldUseLaunchSchemeArgsEnv = "YES"\n'
        '      savedToolIdentifier = ""\n'
        '      useCustomWorkingDirectory = "NO"\n'
        '      debugDocumentVersioning = "YES">\n'
        "      <BuildableProductRunnable\n"
        '         runnableDebuggingMode = "0">\n'
        + app(9) +
        "      </BuildableProductRunnable>\n"
        "   </ProfileAction>\n"
        "   <AnalyzeAction\n"
        '      buildConfiguration = "Debug">\n'
        "   </AnalyzeAction>\n"
        "   <ArchiveAction\n"
        '      buildConfiguration = "Release"\n'
        '      revealArchiveInOrganizer = "YES">\n'
        "   </ArchiveAction>\n"
        "</Scheme>\n"
    )


# --------------------------------------------------------------------------------------------
# Lector mínimo del formato OpenStep (para la autoverificación)
# --------------------------------------------------------------------------------------------

CARACTERES_SIN_COMILLAS = set(
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_$./:-"
)


class LectorOpenStep(object):
    def __init__(self, texto):
        self.t = texto
        self.i = 0
        self.n = len(texto)

    def error(self, mensaje):
        linea = self.t.count("\n", 0, self.i) + 1
        inicio = self.t.rfind("\n", 0, self.i) + 1
        columna = self.i - inicio + 1
        raise ErrorProyecto("project.pbxproj, línea %d, columna %d: %s" % (linea, columna, mensaje))

    def saltar(self):
        t, n = self.t, self.n
        while self.i < n:
            c = t[self.i]
            if c in " \t\r\n":
                self.i += 1
            elif t.startswith("//", self.i):
                fin = t.find("\n", self.i)
                self.i = n if fin < 0 else fin + 1
            elif t.startswith("/*", self.i):
                fin = t.find("*/", self.i + 2)
                if fin < 0:
                    self.error("comentario /* sin cerrar")
                self.i = fin + 2
            else:
                break

    def esperar(self, c):
        self.saltar()
        if self.i >= self.n or self.t[self.i] != c:
            encontrado = self.t[self.i] if self.i < self.n else "fin de archivo"
            self.error("se esperaba %r y se encontró %r" % (c, encontrado))
        self.i += 1

    def leer(self):
        valor = self.valor()
        self.saltar()
        if self.i != self.n:
            self.error("texto sobrante después del diccionario raíz")
        return valor

    def valor(self):
        self.saltar()
        if self.i >= self.n:
            self.error("fin de archivo inesperado")
        c = self.t[self.i]
        if c == "{":
            return self.diccionario()
        if c == "(":
            return self.arreglo()
        return self.cadena()

    def diccionario(self):
        self.esperar("{")
        resultado = {}
        while True:
            self.saltar()
            if self.i < self.n and self.t[self.i] == "}":
                self.i += 1
                return resultado
            inicio = self.i
            clave = self.cadena()
            if clave in resultado:
                self.i = inicio
                self.error("clave duplicada %r" % clave)
            self.esperar("=")
            resultado[clave] = self.valor()
            self.esperar(";")

    def arreglo(self):
        self.esperar("(")
        resultado = []
        while True:
            self.saltar()
            if self.i < self.n and self.t[self.i] == ")":
                self.i += 1
                return resultado
            resultado.append(self.valor())
            self.saltar()
            if self.i < self.n and self.t[self.i] == ",":
                self.i += 1
            elif self.i < self.n and self.t[self.i] == ")":
                continue
            else:
                self.error("se esperaba ',' o ')' en un arreglo")

    def cadena(self):
        self.saltar()
        if self.i >= self.n:
            self.error("fin de archivo inesperado")
        t = self.t
        if t[self.i] == '"':
            self.i += 1
            partes = []
            while True:
                if self.i >= self.n:
                    self.error("cadena entre comillas sin cerrar")
                c = t[self.i]
                if c == '"':
                    self.i += 1
                    return "".join(partes)
                if c == "\\":
                    if self.i + 1 >= self.n:
                        self.error("escape incompleto")
                    sig = t[self.i + 1]
                    partes.append({"n": "\n", "t": "\t", "r": "\r"}.get(sig, sig))
                    self.i += 2
                else:
                    partes.append(c)
                    self.i += 1
        inicio = self.i
        while self.i < self.n and t[self.i] in CARACTERES_SIN_COMILLAS:
            self.i += 1
        if self.i == inicio:
            self.error("carácter inesperado %r (¿falta entrecomillar una cadena?)" % t[self.i])
        return t[inicio:self.i]


# --------------------------------------------------------------------------------------------
# Verificación
# --------------------------------------------------------------------------------------------

CLAVES_ID = (
    "children", "files", "fileRef", "buildPhases", "buildConfigurations",
    "buildConfigurationList", "targets", "dependencies", "target", "targetProxy",
    "mainGroup", "productRefGroup", "productReference", "containerPortal",
    "remoteGlobalIDString",
)
FORMATO_ID = re.compile(r"^[0-9A-F]{24}$")


def verificar(app_swift, app_assets, pruebas_swift):
    """Relee los archivos generados y comprueba que son coherentes. Devuelve el resumen."""
    errores = []
    if not os.path.isfile(RUTA_PBXPROJ):
        raise ErrorProyecto("No existe %s; corre el script sin --verificar para generarlo." % RUTA_PBXPROJ)
    with open(RUTA_PBXPROJ, "r", encoding="utf-8", newline="") as f:
        texto = f.read()
    if "\r" in texto:
        errores.append("project.pbxproj contiene saltos de línea CRLF (deben ser LF).")
    if not texto.startswith("// !$*UTF8*$!\n"):
        errores.append("project.pbxproj no empieza con la cabecera '// !$*UTF8*$!'.")

    raiz = LectorOpenStep(texto).leer()
    if not isinstance(raiz, dict):
        raise ErrorProyecto("La raíz de project.pbxproj no es un diccionario.")
    for clave, esperado in (("archiveVersion", "1"), ("objectVersion", "56")):
        if raiz.get(clave) != esperado:
            errores.append("%s debería ser %s y es %r" % (clave, esperado, raiz.get(clave)))
    objetos = raiz.get("objects")
    if not isinstance(objetos, dict) or not objetos:
        raise ErrorProyecto("project.pbxproj no tiene diccionario 'objects'.")

    for ident, obj in objetos.items():
        if not FORMATO_ID.match(ident):
            errores.append("ID con formato inválido: %r" % ident)
        if not isinstance(obj, dict) or "isa" not in obj:
            errores.append("El objeto %s no tiene 'isa'." % ident)

    def revisar_id(valor, donde):
        if not isinstance(valor, str) or valor not in objetos:
            errores.append("%s referencia un ID que no existe: %r" % (donde, valor))

    revisar_id(raiz.get("rootObject"), "rootObject")
    for ident, obj in objetos.items():
        if not isinstance(obj, dict):
            continue
        for clave in CLAVES_ID:
            if clave not in obj:
                continue
            valor = obj[clave]
            donde = "%s (%s).%s" % (ident, obj.get("isa"), clave)
            if isinstance(valor, list):
                for v in valor:
                    revisar_id(v, donde)
            else:
                revisar_id(valor, donde)
        if obj.get("isa") == "PBXProject":
            atributos = obj.get("attributes", {}).get("TargetAttributes", {})
            for clave, valor in atributos.items():
                revisar_id(clave, "TargetAttributes")
                if isinstance(valor, dict) and "TestTargetID" in valor:
                    revisar_id(valor["TestTargetID"], "TargetAttributes.TestTargetID")

    if errores:
        raise ErrorProyecto("\n".join(errores))

    # Rutas de cada PBXFileReference siguiendo el árbol de grupos desde mainGroup.
    proyecto = objetos[raiz["rootObject"]]
    ruta_de = {}

    def recorrer(gid, base, visitados):
        if gid in visitados:
            errores.append("Ciclo en los grupos en %s" % gid)
            return
        visitados = visitados | {gid}
        for hijo in objetos[gid].get("children", []):
            obj = objetos[hijo]
            isa = obj.get("isa")
            if isa == "PBXGroup":
                if obj.get("sourceTree") != "<group>":
                    errores.append("El grupo %s no usa sourceTree = <group>" % hijo)
                recorrer(hijo, unir(base, obj.get("path", "")), visitados)
            elif isa == "PBXFileReference":
                if hijo in ruta_de:
                    errores.append("El archivo %s aparece en dos grupos" % hijo)
                if obj.get("sourceTree") == "<group>":
                    ruta_de[hijo] = unir(base, obj.get("path", ""))
                else:
                    ruta_de[hijo] = None  # productos (BUILT_PRODUCTS_DIR)
            else:
                errores.append("Hijo de grupo con isa inesperado: %s (%s)" % (hijo, isa))

    recorrer(proyecto["mainGroup"], "", frozenset())

    for ident, obj in objetos.items():
        if obj.get("isa") == "PBXFileReference":
            if ident not in ruta_de:
                errores.append("El PBXFileReference %s no está en ningún grupo" % ident)
                continue
            ruta = ruta_de[ident]
            if ruta is not None and not os.path.exists(os.path.join(RAIZ, *ruta.split("/"))):
                errores.append("El PBXFileReference %s apunta a un archivo inexistente: %s" % (ident, ruta))

    # Fuentes por target.
    fuentes = {}  # nombre target -> [rutas]
    recursos = {}
    for tid in proyecto.get("targets", []):
        target = objetos[tid]
        nombre = target.get("name")
        fuentes[nombre], recursos[nombre] = [], []
        for fid in target.get("buildPhases", []):
            fase = objetos[fid]
            destino = {"PBXSourcesBuildPhase": fuentes, "PBXResourcesBuildPhase": recursos}.get(fase.get("isa"))
            if destino is None:
                continue
            for bid in fase.get("files", []):
                ref = objetos[bid].get("fileRef")
                ruta = ruta_de.get(ref)
                if ruta is None:
                    errores.append("Build file %s sin ruta resoluble" % bid)
                else:
                    destino[nombre].append(ruta)

    if set(fuentes) != {NOMBRE_APP, NOMBRE_PRUEBAS}:
        errores.append("Los targets deberían ser %s y %s; hay %s"
                       % (NOMBRE_APP, NOMBRE_PRUEBAS, sorted(fuentes)))
    else:
        todas = fuentes[NOMBRE_APP] + fuentes[NOMBRE_PRUEBAS]
        for ruta, target in [(r, NOMBRE_APP) for r in app_swift] + [(r, NOMBRE_PRUEBAS) for r in pruebas_swift]:
            veces = todas.count(ruta)
            if veces != 1:
                errores.append("%s aparece %d veces en las fases Sources (debe ser 1). "
                               "Vuelve a generar el proyecto." % (ruta, veces))
            elif ruta not in fuentes[target]:
                errores.append("%s está en el target equivocado (debe ir en %s)" % (ruta, target))
        sobrantes = set(todas) - set(app_swift) - set(pruebas_swift)
        for ruta in sorted(sobrantes):
            errores.append("%s está en Sources pero ya no existe en disco. Vuelve a generar el proyecto." % ruta)
        if sorted(recursos[NOMBRE_APP]) != sorted(app_assets):
            errores.append("Recursos de la app %s no coinciden con los catálogos en disco %s"
                           % (recursos[NOMBRE_APP], app_assets))
        # Swift no permite dos archivos con el mismo nombre en un mismo target.
        for nombre_target, rutas in fuentes.items():
            vistos = {}
            for ruta in rutas:
                base = ruta.split("/")[-1].lower()
                if base in vistos:
                    errores.append("Dos archivos con el mismo nombre en %s: %s y %s "
                                   "(Swift no lo permite)" % (nombre_target, vistos[base], ruta))
                vistos[base] = ruta

    # Esquema compartido.
    ids_targets = {objetos[t].get("name"): t for t in proyecto.get("targets", [])}
    if not os.path.isfile(RUTA_ESQUEMA):
        errores.append("No existe el esquema %s" % RUTA_ESQUEMA)
    else:
        try:
            arbol = ET.parse(RUTA_ESQUEMA)
        except ET.ParseError as e:
            errores.append("El esquema no es XML válido: %s" % e)
        else:
            refs = arbol.getroot().iter("BuildableReference")
            for ref in refs:
                nombre = ref.get("BlueprintName")
                if ids_targets.get(nombre) != ref.get("BlueprintIdentifier"):
                    errores.append("El esquema referencia %s con ID %s, pero en el pbxproj es %s"
                                   % (nombre, ref.get("BlueprintIdentifier"), ids_targets.get(nombre)))
                if ref.get("ReferencedContainer") != "container:" + PROYECTO:
                    errores.append("ReferencedContainer incorrecto en el esquema: %s" % ref.get("ReferencedContainer"))

    if errores:
        raise ErrorProyecto("\n".join(errores))
    return {
        "objetos": len(objetos),
        "app_swift": len(fuentes[NOMBRE_APP]),
        "app_recursos": len(recursos[NOMBRE_APP]),
        "pruebas_swift": len(fuentes[NOMBRE_PRUEBAS]),
    }


# --------------------------------------------------------------------------------------------
# Programa principal
# --------------------------------------------------------------------------------------------


def configurar_consola():
    """Si la consola no es UTF-8 (p. ej. una tubería en Windows), escribe sin acentos."""
    for flujo in (sys.stdout, sys.stderr):
        codificacion = (getattr(flujo, "encoding", None) or "").lower().replace("-", "")
        if codificacion != "utf8" and hasattr(flujo, "reconfigure"):
            try:
                flujo.reconfigure(errors="replace")
            except Exception:
                pass
            original = flujo.write

            def escribir(texto, _original=original):
                sin_acentos = unicodedata.normalize("NFKD", texto)
                return _original("".join(c for c in sin_acentos if not unicodedata.combining(c)))

            try:
                flujo.write = escribir
            except Exception:
                pass


def escribir_si_cambia(ruta, contenido):
    actual = None
    if os.path.isfile(ruta):
        with open(ruta, "r", encoding="utf-8", newline="") as f:
            actual = f.read()
    if actual == contenido:
        return False
    os.makedirs(os.path.dirname(ruta), exist_ok=True)
    with open(ruta, "w", encoding="utf-8", newline="\n") as f:
        f.write(contenido)
    return True


def main(argv=None):
    configurar_consola()

    parser = argparse.ArgumentParser(description="Genera y verifica RoomieRules.xcodeproj.")
    parser.add_argument("--verificar", action="store_true",
                        help="no escribe nada: solo verifica el proyecto que ya existe")
    args = parser.parse_args(argv)

    try:
        if not os.path.isdir(os.path.join(RAIZ, CARPETA_APP)):
            raise ErrorProyecto("No se encontró la carpeta %s en %s" % (CARPETA_APP, RAIZ))
        app_swift, app_assets, ignorados_app = descubrir(CARPETA_APP, True)
        pruebas_swift, _, ignorados_pruebas = descubrir(CARPETA_PRUEBAS, False)
        if not app_swift:
            raise ErrorProyecto("No hay ningún archivo .swift en %s/" % CARPETA_APP)

        print("Raíz del repositorio: %s" % RAIZ)
        for ruta in ignorados_app + ignorados_pruebas:
            print("  (ignorado, no es .swift ni .xcassets: %s)" % ruta)

        if not args.verificar:
            pbxproj, esquema = generar_contenido(app_swift, app_assets, pruebas_swift)
            cambio1 = escribir_si_cambia(RUTA_PBXPROJ, pbxproj)
            cambio2 = escribir_si_cambia(RUTA_ESQUEMA, esquema)
            for ruta, cambio in ((RUTA_PBXPROJ, cambio1), (RUTA_ESQUEMA, cambio2)):
                print("%s %s" % ("Escrito:   " if cambio else "Sin cambios:", os.path.relpath(ruta, RAIZ).replace(os.sep, "/")))
            if not pruebas_swift:
                print("Aviso: %s/ no tiene archivos .swift; el target de pruebas queda vacío." % CARPETA_PRUEBAS)
        else:
            # Además de la coherencia interna, comprueba que el archivo está al día.
            pbxproj, esquema = generar_contenido(app_swift, app_assets, pruebas_swift)
            for ruta, esperado in ((RUTA_PBXPROJ, pbxproj), (RUTA_ESQUEMA, esquema)):
                actual = None
                if os.path.isfile(ruta):
                    with open(ruta, "r", encoding="utf-8", newline="") as f:
                        actual = f.read()
                if actual != esperado:
                    print("Aviso: %s no coincide con lo que generaría el script "
                          "(cambiaron archivos o se editó desde Xcode?)." % os.path.relpath(ruta, RAIZ).replace(os.sep, "/"))

        resumen = verificar(app_swift, app_assets, pruebas_swift)
    except ErrorProyecto as e:
        print("ERROR: la verificación del proyecto falló:", file=sys.stderr)
        for linea in str(e).splitlines():
            print("  - " + linea, file=sys.stderr)
        return 1

    print("Verificación correcta (%d objetos en project.pbxproj)." % resumen["objetos"])
    print("  %-17s %3d archivos .swift, %d catálogo(s) de assets" % (NOMBRE_APP + ":", resumen["app_swift"], resumen["app_recursos"]))
    print("  %-17s %3d archivos .swift" % (NOMBRE_PRUEBAS + ":", resumen["pruebas_swift"]))
    return 0


if __name__ == "__main__":
    sys.exit(main())
