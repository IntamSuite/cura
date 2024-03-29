# Copyright (c) 2015 Ultimaker B.V.
# Cura is released under the terms of the AGPLv3 or higher.

from UM.i18n import i18nCatalog
from UM.Extension import Extension
from UM.Preferences import Preferences
from UM.Application import Application
from UM.PluginRegistry import PluginRegistry
from UM.Version import Version

from PyQt5.QtQuick import QQuickView
from PyQt5.QtQml import QQmlComponent, QQmlContext
from PyQt5.QtCore import QUrl, pyqtSlot, QObject

import os.path
import collections

catalog = i18nCatalog("IntamSuite")

class ChangeLog(Extension, QObject,):
    def __init__(self, parent = None):
        QObject.__init__(self, parent)
        Extension.__init__(self)
        self._changelog_window = None
        self._changelog_context = None
        version_string = Application.getInstance().getVersion()
        if version_string is not "master":
            self._version = Version(version_string)
        else:
            self._version = None

        self._change_logs = None
        Application.getInstance().engineCreatedSignal.connect(self._onEngineCreated)
        Preferences.getInstance().addPreference("general/latest_version_changelog_shown", "2.0.0") #First version of CURA with uranium
        self.addMenuItem(catalog.i18nc("@item:inmenu", "Show Changelog"), self.showChangelog)

    def getChangeLogs(self):
        if not self._change_logs:
            self.loadChangeLogs()
        return self._change_logs

    @pyqtSlot(result = str)
    def getChangeLogString(self):
        logs = self.getChangeLogs()
        result = ""
        for version in logs:
            result += "<h1>" + str(version) + "</h1><br>"
            result += ""
            for change in logs[version]:
                if str(change) != "":
                    result += "<b>" + str(change) + "</b><br>"
                for line in logs[version][change]:
                    result += str(line) + "<br>"
                result += "<br>"

        pass
        return result

    def loadChangeLogs(self):
        self._change_logs = collections.OrderedDict()
        with open(os.path.join(PluginRegistry.getInstance().getPluginPath(self.getPluginId()), "ChangeLog.txt"), "r",-1, "utf-8") as f:
            open_version = None
            open_header = "" # Initialise to an empty header in case there is no "*" in the first line of the changelog
            for line in f:
                line = line.replace("\n","")
                if "[" in line and "]" in line:
                    line = line.replace("[","")
                    line = line.replace("]","")
                    open_version = Version(line)
                    open_header = ""
                    self._change_logs[open_version] = collections.OrderedDict()
                elif line.startswith("*"):
                    open_header = line.replace("*","")
                    self._change_logs[open_version][open_header] = []
                elif line != "":
                    if open_header not in self._change_logs[open_version]:
                        self._change_logs[open_version][open_header] = []
                    self._change_logs[open_version][open_header].append(line)

    def _onEngineCreated(self):
        if not self._version:
            return #We're on dev branch.

        if Preferences.getInstance().getValue("general/latest_version_changelog_shown") == "master":
            latest_version_shown = Version("0.0.0")
        else:
            latest_version_shown = Version(Preferences.getInstance().getValue("general/latest_version_changelog_shown"))

        Preferences.getInstance().setValue("general/latest_version_changelog_shown", Application.getInstance().getVersion())

        # Do not show the changelog when there is no global container stack
        # This implies we are running Cura for the first time.
        if not Application.getInstance().getGlobalContainerStack():
            return

        if self._version > latest_version_shown:
            self.showChangelog()

    def showChangelog(self):
        if not self._changelog_window:
            self.createChangelogWindow()

        self._changelog_window.show()

    def hideChangelog(self):
        if self._changelog_window:
            self._changelog_window.hide()

    def createChangelogWindow(self):
        path = QUrl.fromLocalFile(os.path.join(PluginRegistry.getInstance().getPluginPath(self.getPluginId()), "ChangeLog.qml"))

        component = QQmlComponent(Application.getInstance()._engine, path)
        self._changelog_context = QQmlContext(Application.getInstance()._engine.rootContext())
        self._changelog_context.setContextProperty("manager", self)
        self._changelog_window = component.create(self._changelog_context)
