# Copyright (c) 2015 Ultimaker B.V.
# Cura is released under the terms of the AGPLv3 or higher.

from UM.Platform import Platform
from UM.Logger import Logger
from UM.i18n import i18nCatalog
catalog = i18nCatalog("IntamSuite")

def getMetaData():
    return {
        "plugin": {
            "name": catalog.i18nc("@label", "Removable Drive Output Device Plugin"),
            "author": "Ultimaker B.V.",
            "description": catalog.i18nc("@info:whatsthis", "Provides removable drive hotplugging and writing support."),
            "version": "1.0",
            "api": 3
        }
    }

def register(app):
    if Platform.isWindows():
        from . import WindowsRemovableDrivePlugin
        return { "output_device": WindowsRemovableDrivePlugin.WindowsRemovableDrivePlugin() }
    elif Platform.isOSX():
        from . import OSXRemovableDrivePlugin
        return { "output_device": OSXRemovableDrivePlugin.OSXRemovableDrivePlugin() }
    elif Platform.isLinux():
        from . import LinuxRemovableDrivePlugin
        return { "output_device": LinuxRemovableDrivePlugin.LinuxRemovableDrivePlugin() }
    else:
        Logger.log("e", "Unsupported system, thus no removable device hotplugging support available.")
        return { }
