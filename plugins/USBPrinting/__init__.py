# Copyright (c) 2015 Ultimaker B.V.
# Cura is released under the terms of the AGPLv3 or higher.

from . import USBPrinterOutputDeviceManager
from PyQt5.QtQml import qmlRegisterType, qmlRegisterSingletonType
from UM.i18n import i18nCatalog
i18n_catalog = i18nCatalog("IntamSuite")

def getMetaData():
    return {
        "type": "extension",
        "plugin": {
            "name": i18n_catalog.i18nc("@label", "USB printing"),
            "author": "Ultimaker",
            "version": "1.0",
            "api": 3,
            "description": i18n_catalog.i18nc("@info:whatsthis","Accepts G-Code and sends them to a printer. Plugin can also update firmware.")
        }
    }

def register(app):
    # We are violating the QT API here (as we use a factory, which is technically not allowed).
    # but we don't really have another means for doing this (and it seems to you know -work-)
    qmlRegisterSingletonType(USBPrinterOutputDeviceManager.USBPrinterOutputDeviceManager, "Cura", 1, 0, "USBPrinterManager", USBPrinterOutputDeviceManager.USBPrinterOutputDeviceManager.getInstance)
    return {"extension":USBPrinterOutputDeviceManager.USBPrinterOutputDeviceManager.getInstance(), "output_device": USBPrinterOutputDeviceManager.USBPrinterOutputDeviceManager.getInstance()}
