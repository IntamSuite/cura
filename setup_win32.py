#  Needed build-ins
import sys
import os.path

# Importing preinstalled modules to get their paths
import PyQt5
import numpy

from cx_Freeze import setup, Executable, hooks

def load_numpy(finder, module):
    finder.IncludePackage("numpy.core._methods")
    finder.IncludePackage("numpy._globals")
    finder.IncludePackage("numpy.lib.format")
    finder.IncludePackage("numpy.linalg._umath_linalg")

    # Include all MKL files that are needed to get Numpy with MKL working.
    npy_core_dir = os.path.join(module.path[0], "core")
    required_mkl_files = [
        "mkl_intel_thread.dll",
        "mkl_core.dll",
        "mkl_avx.dll",
        "mkl_avx2.dll",
        "libiomp5md.dll",
        "libimalloc.dll",
        "libmmd.dll",
    ]
#"mkl_msg.dll""mkl_avx512.dll""mkl_def.dll","mkl_mc.dll","mkl_mc3.dll",

    for file in required_mkl_files:
        finder.IncludeFiles(os.path.join(npy_core_dir, file), file)

hooks.load_numpy = load_numpy

def load_scipy(finder, module):
    finder.IncludePackage("scipy._lib")
    finder.IncludePackage("scipy.misc")
    finder.IncludePackage("scipy.sparse.csgraph._validation")
    finder.IncludePackage("scipy.sparse._csparsetools")

hooks.load_scipy = load_scipy

def load_pyqt5_qtquick(finder, module):
    finder.IncludeModule("PyQt5.QtCore")
    finder.IncludeModule("PyQt5.QtGui")
    finder.IncludeModule("PyQt5.QtQml")
    finder.IncludeModule("PyQt5.QtNetwork")
    finder.IncludeModule("PyQt5._QOpenGLFunctions_2_0")
    finder.IncludeModule("PyQt5._QOpenGLFunctions_2_1")
    finder.IncludeModule("PyQt5._QOpenGLFunctions_4_1_Core")

hooks.load_PyQt5_QtQuick = load_pyqt5_qtquick

search_path = sys.path.copy()
search_path.insert(1, "C:/Users/INTAMSYS/Desktop/IntamBeta/")
search_path.insert(2, "C:/Users/INTAMSYS/Desktop/IntamBeta/")

# Dependencies are automatically detected, but it might need
# fine tuning.
build_options = {
    "build_exe": "package",
    "zip_include_packages": "*",
    "zip_exclude_packages": "",
    "path": search_path,
    "packages": [
        "xml.etree",
        "uuid",
        "serial",
        "zeroconf",
        "UM",
        "cura",
        "stl",
    ],
    "include_files": [
        ("C:/Users/INTAMSYS/Desktop/IntamBeta/IntamDrive.exe", ""),
        ("C:/Users/INTAMSYS/Desktop/IntamBeta/plugins", ""),
        ("C:/Users/INTAMSYS/Desktop/IntamBeta/UM/Qt/qml/UM", "qml/UM"),
        ("C:/Users/INTAMSYS/Desktop/IntamBeta/resources", "resources"),
        # Preinstalled PyQt5 installation
        (PyQt5.__path__[0] + "/Qt/qml/Qt", "qml/Qt"),
        (PyQt5.__path__[0] + "/Qt/qml/QtQml", "qml/QtQml"),
        (PyQt5.__path__[0] + "/Qt/qml/QtQuick", "qml/QtQuick"),
        (PyQt5.__path__[0] + "/Qt/qml/QtQuick.2", "qml/QtQuick.2"),
    ],
    "excludes": [ ]
}

executables = [
    Executable(script="C:/Users/INTAMSYS/Desktop/IntamBeta//cura_app.py",
               base="Win32GUI",
               targetName = "IntamSuite.exe",
               icon="C:/Users/INTAMSYS/Desktop/IntamBeta/intamsuite.ico"
               )
]

setup(
    name = "IntamSuite",
    version = "3.1.3",
    description = "3D Printing Software",
    author = "Intamsys",
    url = "http://software.intamsys.com/",

    options = {"build_exe": build_options},
    executables = executables
)
