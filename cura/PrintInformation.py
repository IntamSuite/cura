# Copyright (c) 2015 Ultimaker B.V.
# Cura is released under the terms of the AGPLv3 or higher.

from PyQt5.QtCore import QObject, pyqtSignal, pyqtProperty
from UM.FlameProfiler import pyqtSlot

from UM.Application import Application
from UM.Logger import Logger
from UM.Qt.Duration import Duration
from UM.Preferences import Preferences
from UM.Settings.ContainerRegistry import ContainerRegistry

from cura.Settings.ExtruderManager import ExtruderManager

import math
import os.path
import unicodedata
import json

from UM.i18n import i18nCatalog
catalog = i18nCatalog("IntamSuite")

##  A class for processing and calculating minimum, current and maximum print time as well as managing the job name
#
#   This class contains all the logic relating to calculation and slicing for the
#   time/quality slider concept. It is a rather tricky combination of event handling
#   and state management. The logic behind this is as follows:
#
#   - A scene change or setting change event happens.
#        We track what the source was of the change, either a scene change, a setting change, an active machine change or something else.
#   - This triggers a new slice with the current settings - this is the "current settings pass".
#   - When the slice is done, we update the current print time and material amount.
#   - If the source of the slice was not a Setting change, we start the second slice pass, the "low quality settings pass". Otherwise we stop here.
#   - When that is done, we update the minimum print time and start the final slice pass, the "high quality settings pass".
#   - When the high quality pass is done, we update the maximum print time.
#
#   This class also mangles the current machine name and the filename of the first loaded mesh into a job name.
#   This job name is requested by the JobSpecs qml file.
class PrintInformation(QObject):
    class SlicePass:
        CurrentSettings = 1
        LowQualitySettings = 2
        HighQualitySettings = 3

    class SliceReason:
        SceneChanged = 1
        SettingChanged = 2
        ActiveMachineChanged = 3
        Other = 4

    def __init__(self, parent = None):
        super().__init__(parent)

        self._current_print_time = Duration(None, self)

        self._material_lengths = []
        self._material_weights = []
        self._material_costs = []

        self._pre_sliced = False

        self._backend = Application.getInstance().getBackend()
        if self._backend:
            self._backend.printDurationMessage.connect(self._onPrintDurationMessage)

        self._job_name = ""
        self._abbr_machine = ""

        Application.getInstance().globalContainerStackChanged.connect(self._setAbbreviatedMachineName)
        Application.getInstance().fileLoaded.connect(self.setJobName)

        Preferences.getInstance().preferenceChanged.connect(self._onPreferencesChanged)

        self._active_material_container = None
        Application.getInstance().getMachineManager().activeMaterialChanged.connect(self._onActiveMaterialChanged)
        self._onActiveMaterialChanged()

        self._material_amounts = []

    currentPrintTimeChanged = pyqtSignal()

    preSlicedChanged = pyqtSignal()

    @pyqtProperty(bool, notify=preSlicedChanged)
    def preSliced(self):
        return self._pre_sliced

    def setPreSliced(self, pre_sliced):
        self._pre_sliced = pre_sliced
        self.preSlicedChanged.emit()

    @pyqtProperty(Duration, notify = currentPrintTimeChanged)
    def currentPrintTime(self):
        return self._current_print_time

    materialLengthsChanged = pyqtSignal()

    @pyqtProperty("QVariantList", notify = materialLengthsChanged)
    def materialLengths(self):
        return self._material_lengths

    materialWeightsChanged = pyqtSignal()

    @pyqtProperty("QVariantList", notify = materialWeightsChanged)
    def materialWeights(self):
        return self._material_weights

    materialCostsChanged = pyqtSignal()

    @pyqtProperty("QVariantList", notify = materialCostsChanged)
    def materialCosts(self):
        return self._material_costs

    def _onPrintDurationMessage(self, total_time, material_amounts):
        if total_time != total_time:  # Check for NaN. Engine can sometimes give us weird values.
            Logger.log("w", "Received NaN for print duration message")
            self._current_print_time.setDuration(0)
        else:
            self._current_print_time.setDuration(total_time)

        self.currentPrintTimeChanged.emit()

        self._material_amounts = material_amounts
        self._calculateInformation()

    def _calculateInformation(self):
        if Application.getInstance().getGlobalContainerStack() is None:
            return

        # Material amount is sent as an amount of mm^3, so calculate length from that
        radius = Application.getInstance().getGlobalContainerStack().getProperty("material_diameter", "value") / 2
        self._material_lengths = []
        self._material_weights = []
        self._material_costs = []

        material_preference_values = json.loads(Preferences.getInstance().getValue("cura/material_settings"))

        extruder_stacks = list(ExtruderManager.getInstance().getMachineExtruders(Application.getInstance().getGlobalContainerStack().getId()))
        for index, amount in enumerate(self._material_amounts):
            ## Find the right extruder stack. As the list isn't sorted because it's a annoying generator, we do some
            #  list comprehension filtering to solve this for us.
            material = None
            if extruder_stacks:  # Multi extrusion machine
                extruder_stack = [extruder for extruder in extruder_stacks if extruder.getMetaDataEntry("position") == str(index)][0]
                density = extruder_stack.getMetaDataEntry("properties", {}).get("density", 0)
                material = extruder_stack.findContainer({"type": "material"})
            else:  # Machine with no extruder stacks
                density = Application.getInstance().getGlobalContainerStack().getMetaDataEntry("properties", {}).get("density", 0)
                material = Application.getInstance().getGlobalContainerStack().findContainer({"type": "material"})

            weight = float(amount) * float(density) / 1000
            cost = 0
            if material:
                material_guid = material.getMetaDataEntry("GUID")
                if material_guid in material_preference_values:
                    material_values = material_preference_values[material_guid]

                    weight_per_spool = float(material_values["spool_weight"] if material_values and "spool_weight" in material_values else 0)
                    cost_per_spool = float(material_values["spool_cost"] if material_values and "spool_cost" in material_values else 0)

                    if weight_per_spool != 0:
                        cost = cost_per_spool * weight / weight_per_spool
                    else:
                        cost = 0

            if radius != 0:
                length = round((amount / (math.pi * radius ** 2)) / 1000, 2)
            else:
                length = 0
            self._material_weights.append(weight)
            self._material_lengths.append(length)
            self._material_costs.append(cost)

        self.materialLengthsChanged.emit()
        self.materialWeightsChanged.emit()
        self.materialCostsChanged.emit()

    def _onPreferencesChanged(self, preference):
        if preference != "cura/material_settings":
            return

        self._calculateInformation()

    def _onActiveMaterialChanged(self):
        if self._active_material_container:
            self._active_material_container.metaDataChanged.disconnect(self._onMaterialMetaDataChanged)

        active_material_id = Application.getInstance().getMachineManager().activeMaterialId
        active_material_containers = ContainerRegistry.getInstance().findInstanceContainers(id=active_material_id)

        if active_material_containers:
            self._active_material_container = active_material_containers[0]
            self._active_material_container.metaDataChanged.connect(self._onMaterialMetaDataChanged)

    def _onMaterialMetaDataChanged(self, *args, **kwargs):
        self._calculateInformation()

    @pyqtSlot(str)
    def setJobName(self, name):
        # Ensure that we don't use entire path but only filename
        name = os.path.basename(name)

        # when a file is opened using the terminal; the filename comes from _onFileLoaded and still contains its
        # extension. This cuts the extension off if necessary.
        name = os.path.splitext(name)[0]
        if self._job_name != name:
            self._job_name = name
            self.jobNameChanged.emit()

    jobNameChanged = pyqtSignal()

    @pyqtProperty(str, notify = jobNameChanged)
    def jobName(self):
        return self._job_name

    @pyqtSlot(str, result = str)
    def createJobName(self, base_name):
        if base_name == "":
            return ""
        base_name = self._stripAccents(base_name)
        self._setAbbreviatedMachineName()
        if self._pre_sliced:
            return catalog.i18nc("@label", "Pre-sliced file {0}", base_name)
        elif Preferences.getInstance().getValue("cura/jobname_prefix"):
            # Don't add abbreviation if it already has the exact same abbreviation.
            if base_name.startswith(self._abbr_machine + "_"):
                return base_name
            return self._abbr_machine + "_" + base_name
        else:
            return base_name

    ##  Created an acronymn-like abbreviated machine name from the currently active machine name
    #   Called each time the global stack is switched
    def _setAbbreviatedMachineName(self):
        global_container_stack = Application.getInstance().getGlobalContainerStack()
        if not global_container_stack:
            self._abbr_machine = ""
            return

        global_stack_name = global_container_stack.getName()
        split_name = global_stack_name.split(" ")
        abbr_machine = ""
        for word in split_name:
            if word.lower() == "ultimaker":
                abbr_machine += "UM"
            elif word.isdigit():
                abbr_machine += word
            else:
                abbr_machine += self._stripAccents(word.strip("()[]{}#").upper())[0]

        self._abbr_machine = abbr_machine

    ##  Utility method that strips accents from characters (eg: â -> a)
    def _stripAccents(self, str):
       return ''.join(char for char in unicodedata.normalize('NFD', str) if unicodedata.category(char) != 'Mn')
