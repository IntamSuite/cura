# Copyright (c) 2016 Ultimaker B.V.
# Cura is released under the terms of the AGPLv3 or higher.

from . import AutoSave

from UM.i18n import i18nCatalog
catalog = i18nCatalog("IntamSuite")

def getMetaData():
    return {
        "plugin": {
            "name": catalog.i18nc("@label", "Auto Save"),
            "author": "Ultimaker",
            "version": "1.0",
            "description": catalog.i18nc("@info:whatsthis", "Automatically saves Preferences, Machines and Profiles after changes."),
            "api": 3
        },
    }

def register(app):
    return { "extension": AutoSave.AutoSave() }
