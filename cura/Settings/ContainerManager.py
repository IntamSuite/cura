# Copyright (c) 2016 Ultimaker B.V.
# Cura is released under the terms of the AGPLv3 or higher.

import os.path
import urllib
from typing import Dict, Union

from PyQt5.QtCore import QObject, QUrl, QVariant
from UM.FlameProfiler import pyqtSlot
from PyQt5.QtWidgets import QMessageBox

from UM.PluginRegistry import PluginRegistry
from UM.SaveFile import SaveFile
from UM.Platform import Platform
from UM.MimeTypeDatabase import MimeTypeDatabase

from UM.Logger import Logger
from UM.Application import Application
from UM.Settings.ContainerStack import ContainerStack
from UM.Settings.DefinitionContainer import DefinitionContainer
from UM.Settings.InstanceContainer import InstanceContainer
from cura.QualityManager import QualityManager

from UM.MimeTypeDatabase import MimeTypeNotFoundError
from UM.Settings.ContainerRegistry import ContainerRegistry

from UM.i18n import i18nCatalog

from cura.Settings.ExtruderManager import ExtruderManager

catalog = i18nCatalog("IntamSuite")

##  Manager class that contains common actions to deal with containers in Cura.
#
#   This is primarily intended as a class to be able to perform certain actions
#   from within QML. We want to be able to trigger things like removing a container
#   when a certain action happens. This can be done through this class.
class ContainerManager(QObject):
    def __init__(self, parent = None):
        super().__init__(parent)

        self._container_registry = ContainerRegistry.getInstance()
        self._machine_manager = Application.getInstance().getMachineManager()
        self._container_name_filters = {}

    ##  Create a duplicate of the specified container
    #
    #   This will create and add a duplicate of the container corresponding
    #   to the container ID.
    #
    #   \param container_id \type{str} The ID of the container to duplicate.
    #
    #   \return The ID of the new container, or an empty string if duplication failed.
    @pyqtSlot(str, result = str)
    def duplicateContainer(self, container_id):
        containers = self._container_registry.findContainers(None, id = container_id)
        if not containers:
            Logger.log("w", "Could duplicate container %s because it was not found.", container_id)
            return ""

        container = containers[0]

        new_container = None
        new_name = self._container_registry.uniqueName(container.getName())
        # Only InstanceContainer has a duplicate method at the moment.
        # So fall back to serialize/deserialize when no duplicate method exists.
        if hasattr(container, "duplicate"):
            new_container = container.duplicate(new_name)
        else:
            new_container = container.__class__(new_name)
            new_container.deserialize(container.serialize())
            new_container.setName(new_name)

        if new_container:
            self._container_registry.addContainer(new_container)

        return new_container.getId()

    ##  Change the name of a specified container to a new name.
    #
    #   \param container_id \type{str} The ID of the container to change the name of.
    #   \param new_id \type{str} The new ID of the container.
    #   \param new_name \type{str} The new name of the specified container.
    #
    #   \return True if successful, False if not.
    @pyqtSlot(str, str, str, result = bool)
    def renameContainer(self, container_id, new_id, new_name):
        containers = self._container_registry.findContainers(None, id = container_id)
        if not containers:
            Logger.log("w", "Could rename container %s because it was not found.", container_id)
            return False

        container = containers[0]
        # First, remove the container from the registry. This will clean up any files related to the container.
        self._container_registry.removeContainer(container)

        # Ensure we have a unique name for the container
        new_name = self._container_registry.uniqueName(new_name)

        # Then, update the name and ID of the container
        container.setName(new_name)
        container._id = new_id # TODO: Find a nicer way to set a new, unique ID

        # Finally, re-add the container so it will be properly serialized again.
        self._container_registry.addContainer(container)

        return True

    ##  Remove the specified container.
    #
    #   \param container_id \type{str} The ID of the container to remove.
    #
    #   \return True if the container was successfully removed, False if not.
    @pyqtSlot(str, result = bool)
    def removeContainer(self, container_id):
        containers = self._container_registry.findContainers(None, id = container_id)
        if not containers:
            Logger.log("w", "Could remove container %s because it was not found.", container_id)
            return False

        self._container_registry.removeContainer(containers[0].getId())

        return True

    ##  Merge a container with another.
    #
    #   This will try to merge one container into the other, by going through the container
    #   and setting the right properties on the other container.
    #
    #   \param merge_into_id \type{str} The ID of the container to merge into.
    #   \param merge_id \type{str} The ID of the container to merge.
    #
    #   \return True if successfully merged, False if not.
    @pyqtSlot(str, result = bool)
    def mergeContainers(self, merge_into_id, merge_id):
        containers = self._container_registry.findContainers(None, id = merge_into_id)
        if not containers:
            Logger.log("w", "Could merge into container %s because it was not found.", merge_into_id)
            return False

        merge_into = containers[0]

        containers = self._container_registry.findContainers(None, id = merge_id)
        if not containers:
            Logger.log("w", "Could not merge container %s because it was not found", merge_id)
            return False

        merge = containers[0]

        if not isinstance(merge, type(merge_into)):
            Logger.log("w", "Cannot merge two containers of different types")
            return False

        self._performMerge(merge_into, merge)

        return True

    ##  Clear the contents of a container.
    #
    #   \param container_id \type{str} The ID of the container to clear.
    #
    #   \return True if successful, False if not.
    @pyqtSlot(str, result = bool)
    def clearContainer(self, container_id):
        containers = self._container_registry.findContainers(None, id = container_id)
        if not containers:
            Logger.log("w", "Could clear container %s because it was not found.", container_id)
            return False

        if containers[0].isReadOnly():
            Logger.log("w", "Cannot clear read-only container %s", container_id)
            return False

        containers[0].clear()

        return True

    @pyqtSlot(str, str, result=str)
    def getContainerMetaDataEntry(self, container_id, entry_name):
        containers = self._container_registry.findContainers(None, id=container_id)
        if not containers:
            Logger.log("w", "Could not get metadata of container %s because it was not found.", container_id)
            return ""

        result = containers[0].getMetaDataEntry(entry_name)
        if result is not None:
            return str(result)
        else:
            return ""

    ##  Set a metadata entry of the specified container.
    #
    #   This will set the specified entry of the container's metadata to the specified
    #   value. Note that entries containing dictionaries can have their entries changed
    #   by using "/" as a separator. For example, to change an entry "foo" in a
    #   dictionary entry "bar", you can specify "bar/foo" as entry name.
    #
    #   \param container_id \type{str} The ID of the container to change.
    #   \param entry_name \type{str} The name of the metadata entry to change.
    #   \param entry_value The new value of the entry.
    #
    #   \return True if successful, False if not.
    @pyqtSlot(str, str, str, result = bool)
    def setContainerMetaDataEntry(self, container_id, entry_name, entry_value):
        containers = self._container_registry.findContainers(None, id = container_id)
        if not containers:
            Logger.log("w", "Could not set metadata of container %s because it was not found.", container_id)
            return False

        container = containers[0]

        if container.isReadOnly():
            Logger.log("w", "Cannot set metadata of read-only container %s.", container_id)
            return False

        entries = entry_name.split("/")
        entry_name = entries.pop()

        if entries:
            root_name = entries.pop(0)
            root = container.getMetaDataEntry(root_name)

            item = root
            for entry in entries:
                item = item.get(entries.pop(0), { })

            item[entry_name] = entry_value

            entry_name = root_name
            entry_value = root

        container.setMetaDataEntry(entry_name, entry_value)

        return True

    ##  Set the name of the specified container.
    @pyqtSlot(str, str, result = bool)
    def setContainerName(self, container_id, new_name):
        containers = self._container_registry.findContainers(None, id = container_id)
        if not containers:
            Logger.log("w", "Could not set name of container %s because it was not found.", container_id)
            return False

        container = containers[0]

        if container.isReadOnly():
            Logger.log("w", "Cannot set name of read-only container %s.", container_id)
            return False

        container.setName(new_name)

        return True

    ##  Find instance containers matching certain criteria.
    #
    #   This effectively forwards to ContainerRegistry::findInstanceContainers.
    #
    #   \param criteria A dict of key - value pairs to search for.
    #
    #   \return A list of container IDs that match the given criteria.
    @pyqtSlot("QVariantMap", result = "QVariantList")
    def findInstanceContainers(self, criteria):
        result = []
        for entry in self._container_registry.findInstanceContainers(**criteria):
            result.append(entry.getId())

        return result

    @pyqtSlot(str, result = bool)
    def isContainerUsed(self, container_id):
        Logger.log("d", "Checking if container %s is currently used", container_id)
        containers = self._container_registry.findContainerStacks()
        for stack in containers:
            if container_id in [child.getId() for child in stack.getContainers()]:
                Logger.log("d", "The container is in use by %s", stack.getId())
                return True
        return False

    @pyqtSlot(str, result = str)
    def makeUniqueName(self, original_name):
        return self._container_registry.uniqueName(original_name)

    ##  Get a list of string that can be used as name filters for a Qt File Dialog
    #
    #   This will go through the list of available container types and generate a list of strings
    #   out of that. The strings are formatted as "description (*.extension)" and can be directly
    #   passed to a nameFilters property of a Qt File Dialog.
    #
    #   \param type_name Which types of containers to list. These types correspond to the "type"
    #                    key of the plugin metadata.
    #
    #   \return A string list with name filters.
    @pyqtSlot(str, result = "QStringList")
    def getContainerNameFilters(self, type_name):
        if not self._container_name_filters:
            self._updateContainerNameFilters()

        filters = []
        for filter_string, entry in self._container_name_filters.items():
            if not type_name or entry["type"] == type_name:
                filters.append(filter_string)

        filters.append("All Files (*)")
        return filters

    ##  Export a container to a file
    #
    #   \param container_id The ID of the container to export
    #   \param file_type The type of file to save as. Should be in the form of "description (*.extension, *.ext)"
    #   \param file_url_or_string The URL where to save the file.
    #
    #   \return A dictionary containing a key "status" with a status code and a key "message" with a message
    #           explaining the status.
    #           The status code can be one of "error", "cancelled", "success"
    @pyqtSlot(str, str, QUrl, result = "QVariantMap")
    def exportContainer(self, container_id: str, file_type: str, file_url_or_string: Union[QUrl, str]) -> Dict[str, str]:
        if not container_id or not file_type or not file_url_or_string:
            return { "status": "error", "message": "Invalid arguments"}

        if isinstance(file_url_or_string, QUrl):
            file_url = file_url_or_string.toLocalFile()
        else:
            file_url = file_url_or_string

        if not file_url:
            return { "status": "error", "message": "Invalid path"}

        mime_type = None
        if not file_type in self._container_name_filters:
            try:
                mime_type = MimeTypeDatabase.getMimeTypeForFile(file_url)
            except MimeTypeNotFoundError:
                return { "status": "error", "message": "Unknown File Type" }
        else:
            mime_type = self._container_name_filters[file_type]["mime"]

        containers = self._container_registry.findContainers(None, id = container_id)
        if not containers:
            return { "status": "error", "message": "Container not found"}
        container = containers[0]

        if Platform.isOSX() and "." in file_url:
            file_url = file_url[:file_url.rfind(".")]

        for suffix in mime_type.suffixes:
            if file_url.endswith(suffix):
                break
        else:
            file_url += "." + mime_type.preferredSuffix

        if not Platform.isWindows():
            if os.path.exists(file_url):
                result = QMessageBox.question(None, catalog.i18nc("@title:window", "File Already Exists"),
                                              catalog.i18nc("@label", "The file <filename>{0}</filename> already exists. Are you sure you want to overwrite it?").format(file_url))
                if result == QMessageBox.No:
                    return { "status": "cancelled", "message": "User cancelled"}

        try:
            contents = container.serialize()
        except NotImplementedError:
            return { "status": "error", "message": "Unable to serialize container"}

        if contents is None:
            return {"status": "error", "message": "Serialization returned None. Unable to write to file"}

        with SaveFile(file_url, "w") as f:
            f.write(contents)

        return { "status": "success", "message": "Succesfully exported container", "path": file_url}

    ##  Imports a profile from a file
    #
    #   \param file_url A URL that points to the file to import.
    #
    #   \return \type{Dict} dict with a 'status' key containing the string 'success' or 'error', and a 'message' key
    #       containing a message for the user
    @pyqtSlot(QUrl, result = "QVariantMap")
    def importContainer(self, file_url_or_string: Union[QUrl, str]) -> Dict[str, str]:
        if not file_url_or_string:
            return { "status": "error", "message": "Invalid path"}

        if isinstance(file_url_or_string, QUrl):
            file_url = file_url_or_string.toLocalFile()
        else:
            file_url = file_url_or_string

        if not file_url or not os.path.exists(file_url):
            return { "status": "error", "message": "Invalid path" }

        try:
            mime_type = MimeTypeDatabase.getMimeTypeForFile(file_url)
        except MimeTypeNotFoundError:
            return { "status": "error", "message": "Could not determine mime type of file" }

        container_type = self._container_registry.getContainerForMimeType(mime_type)
        if not container_type:
            return { "status": "error", "message": "Could not find a container to handle the specified file."}

        container_id = urllib.parse.unquote_plus(mime_type.stripExtension(os.path.basename(file_url)))
        container_id = self._container_registry.uniqueName(container_id)

        container = container_type(container_id)

        try:
            with open(file_url, "rt") as f:
                container.deserialize(f.read())
        except PermissionError:
            return { "status": "error", "message": "Permission denied when trying to read the file"}

        container.setName(container_id)

        self._container_registry.addContainer(container)

        return { "status": "success", "message": "Successfully imported container {0}".format(container.getName()) }

    ##  Update the current active quality changes container with the settings from the user container.
    #
    #   This will go through the active global stack and all active extruder stacks and merge the changes from the user
    #   container into the quality_changes container. After that, the user container is cleared.
    #
    #   \return \type{bool} True if successful, False if not.
    @pyqtSlot(result = bool)
    def updateQualityChanges(self):
        global_stack = Application.getInstance().getGlobalContainerStack()
        if not global_stack:
            return False

        self._machine_manager.blurSettings.emit()

        for stack in ExtruderManager.getInstance().getActiveGlobalAndExtruderStacks():
            # Find the quality_changes container for this stack and merge the contents of the top container into it.
            quality_changes = stack.findContainer(type = "quality_changes")
            if not quality_changes or quality_changes.isReadOnly():
                Logger.log("e", "Could not update quality of a nonexistant or read only quality profile in stack %s", stack.getId())
                continue

            self._performMerge(quality_changes, stack.getTop())

        self._machine_manager.activeQualityChanged.emit()

        return True

    ##  Clear the top-most (user) containers of the active stacks.
    @pyqtSlot()
    def clearUserContainers(self) -> None:
        self._machine_manager.blurSettings.emit()

        send_emits_containers = []

        # Go through global and extruder stacks and clear their topmost container (the user settings).
        for stack in ExtruderManager.getInstance().getActiveGlobalAndExtruderStacks():
            container = stack.getTop()
            container.clear()
            send_emits_containers.append(container)

        for container in send_emits_containers:
            container.sendPostponedEmits()

    ##  Create quality changes containers from the user containers in the active stacks.
    #
    #   This will go through the global and extruder stacks and create quality_changes containers from
    #   the user containers in each stack. These then replace the quality_changes containers in the
    #   stack and clear the user settings.
    #
    #   \return \type{bool} True if the operation was successfully, False if not.
    @pyqtSlot(str, result = bool)
    def createQualityChanges(self, base_name):
        global_stack = Application.getInstance().getGlobalContainerStack()
        if not global_stack:
            return False

        active_quality_name = self._machine_manager.activeQualityName
        if active_quality_name == "":
            Logger.log("w", "No quality container found in stack %s, cannot create profile", global_stack.getId())
            return False

        self._machine_manager.blurSettings.emit()
        if base_name is None or base_name == "":
            base_name = active_quality_name
        unique_name = self._container_registry.uniqueName(base_name)

        # Go through the active stacks and create quality_changes containers from the user containers.
        for stack in ExtruderManager.getInstance().getActiveGlobalAndExtruderStacks():
            user_container = stack.getTop()
            quality_container = stack.findContainer(type = "quality")
            quality_changes_container = stack.findContainer(type = "quality_changes")
            if not quality_container or not quality_changes_container:
                Logger.log("w", "No quality or quality changes container found in stack %s, ignoring it", stack.getId())
                continue

            extruder_id = None if stack is global_stack else QualityManager.getInstance().getParentMachineDefinition(stack.getBottom()).getId()
            new_changes = self._createQualityChanges(quality_container, unique_name,
                                                     Application.getInstance().getGlobalContainerStack().getBottom(),
                                                     extruder_id)
            self._performMerge(new_changes, quality_changes_container, clear_settings = False)
            self._performMerge(new_changes, user_container)

            self._container_registry.addContainer(new_changes)
            stack.replaceContainer(stack.getContainerIndex(quality_changes_container), new_changes)

        self._machine_manager.activeQualityChanged.emit()
        return True

    ##  Remove all quality changes containers matching a specified name.
    #
    #   This will search for quality_changes containers matching the supplied name and remove them.
    #   Note that if the machine specifies that qualities should be filtered by machine and/or material
    #   only the containers related to the active machine/material are removed.
    #
    #   \param quality_name The name of the quality changes to remove.
    #
    #   \return \type{bool} True if successful, False if not.
    @pyqtSlot(str, result = bool)
    def removeQualityChanges(self, quality_name):
        Logger.log("d", "Attempting to remove the quality change containers with name %s", quality_name)
        containers_found = False

        if not quality_name:
            return containers_found  # Without a name we will never find a container to remove.

        # If the container that is being removed is the currently active quality, set another quality as the active quality
        activate_quality = quality_name == self._machine_manager.activeQualityName
        activate_quality_type = None

        global_stack = Application.getInstance().getGlobalContainerStack()
        if not global_stack or not quality_name:
            return ""
        machine_definition = global_stack.getBottom()

        for container in QualityManager.getInstance().findQualityChangesByName(quality_name, machine_definition):
            containers_found = True
            if activate_quality and not activate_quality_type:
                activate_quality_type = container.getMetaDataEntry("quality")
            self._container_registry.removeContainer(container.getId())

        if not containers_found:
            Logger.log("d", "Unable to remove quality containers, as we did not find any by the name of %s", quality_name)

        elif activate_quality:
            definition_id = "fdmprinter" if not self._machine_manager.filterQualityByMachine else self._machine_manager.activeDefinitionId
            containers = self._container_registry.findInstanceContainers(type = "quality", definition = definition_id, quality_type = activate_quality_type)
            if containers:
                self._machine_manager.setActiveQuality(containers[0].getId())
                self._machine_manager.activeQualityChanged.emit()

        return containers_found

    ##  Rename a set of quality changes containers.
    #
    #   This will search for quality_changes containers matching the supplied name and rename them.
    #   Note that if the machine specifies that qualities should be filtered by machine and/or material
    #   only the containers related to the active machine/material are renamed.
    #
    #   \param quality_name The name of the quality changes containers to rename.
    #   \param new_name The new name of the quality changes.
    #
    #   \return True if successful, False if not.
    @pyqtSlot(str, str, result = bool)
    def renameQualityChanges(self, quality_name, new_name):
        Logger.log("d", "User requested QualityChanges container rename of %s to %s", quality_name, new_name)
        if not quality_name or not new_name:
            return False

        if quality_name == new_name:
            Logger.log("w", "Unable to rename %s to %s, because they are the same.", quality_name, new_name)
            return True

        global_stack = Application.getInstance().getGlobalContainerStack()
        if not global_stack:
            return False

        self._machine_manager.blurSettings.emit()

        new_name = self._container_registry.uniqueName(new_name)

        container_registry = self._container_registry

        containers_to_rename = self._container_registry.findInstanceContainers(type = "quality_changes", name = quality_name)

        for container in containers_to_rename:
            stack_id = container.getMetaDataEntry("extruder", global_stack.getId())
            container_registry.renameContainer(container.getId(), new_name, self._createUniqueId(stack_id, new_name))

        if not containers_to_rename:
            Logger.log("e", "Unable to rename %s, because we could not find the profile", quality_name)

        self._machine_manager.activeQualityChanged.emit()
        return True

    ##  Duplicate a specified set of quality or quality_changes containers.
    #
    #   This will search for containers matching the specified name. If the container is a "quality" type container, a new
    #   quality_changes container will be created with the specified quality as base. If the container is a "quality_changes"
    #   container, it is simply duplicated and renamed.
    #
    #   \param quality_name The name of the quality to duplicate.
    #
    #   \return A string containing the name of the duplicated containers, or an empty string if it failed.
    @pyqtSlot(str, str, result = str)
    def duplicateQualityOrQualityChanges(self, quality_name, base_name):
        global_stack = Application.getInstance().getGlobalContainerStack()
        if not global_stack or not quality_name:
            return ""
        machine_definition = global_stack.getBottom()

        active_stacks = ExtruderManager.getInstance().getActiveGlobalAndExtruderStacks()
        material_containers = [stack.findContainer(type="material") for stack in active_stacks]

        result = self._duplicateQualityOrQualityChangesForMachineType(quality_name, base_name,
                    QualityManager.getInstance().getParentMachineDefinition(machine_definition),
                    material_containers)
        return result[0].getName() if result else ""

    ##  Duplicate a quality or quality changes profile specific to a machine type
    #
    #   \param quality_name \type{str} the name of the quality or quality changes container to duplicate.
    #   \param base_name \type{str} the desired name for the new container.
    #   \param machine_definition \type{DefinitionContainer}
    #   \param material_instances \type{List[InstanceContainer]}
    #   \return \type{str} the name of the newly created container.
    def _duplicateQualityOrQualityChangesForMachineType(self, quality_name, base_name, machine_definition, material_instances):
        Logger.log("d", "Attempting to duplicate the quality %s", quality_name)

        if base_name is None:
            base_name = quality_name
        # Try to find a Quality with the name.
        container = QualityManager.getInstance().findQualityByName(quality_name, machine_definition, material_instances)
        if container:
            Logger.log("d", "We found a quality to duplicate.")
            return self._duplicateQualityForMachineType(container, base_name, machine_definition)
        Logger.log("d", "We found a quality_changes to duplicate.")
        # Assume it is a quality changes.
        return self._duplicateQualityChangesForMachineType(quality_name, base_name, machine_definition)

    # Duplicate a quality profile
    def _duplicateQualityForMachineType(self, quality_container, base_name, machine_definition):
        if base_name is None:
            base_name = quality_container.getName()
        new_name = self._container_registry.uniqueName(base_name)

        new_change_instances = []

        # Handle the global stack first.
        global_changes = self._createQualityChanges(quality_container, new_name, machine_definition, None)
        new_change_instances.append(global_changes)
        self._container_registry.addContainer(global_changes)

        # Handle the extruders if present.
        extruders = machine_definition.getMetaDataEntry("machine_extruder_trains")
        if extruders:
            for extruder_id in extruders:
                extruder = extruders[extruder_id]
                new_changes = self._createQualityChanges(quality_container, new_name, machine_definition, extruder)
                new_change_instances.append(new_changes)
                self._container_registry.addContainer(new_changes)

        return new_change_instances

    #  Duplicate a quality changes container
    def _duplicateQualityChangesForMachineType(self, quality_changes_name, base_name, machine_definition):
        new_change_instances = []
        for container in QualityManager.getInstance().findQualityChangesByName(quality_changes_name,
                                                              machine_definition):
            base_id = container.getMetaDataEntry("extruder")
            if not base_id:
                base_id = container.getDefinition().getId()
            new_unique_id = self._createUniqueId(base_id, base_name)
            new_container = container.duplicate(new_unique_id, base_name)
            new_change_instances.append(new_container)
            self._container_registry.addContainer(new_container)

        return new_change_instances

    @pyqtSlot(str, result = str)
    def duplicateMaterial(self, material_id: str) -> str:
        containers = self._container_registry.findInstanceContainers(id=material_id)
        if not containers:
            Logger.log("d", "Unable to duplicate the material with id %s, because it doesn't exist.", material_id)
            return ""

        # Ensure all settings are saved.
        Application.getInstance().saveSettings()

        # Create a new ID & container to hold the data.
        new_id = self._container_registry.uniqueName(material_id)
        container_type = type(containers[0])  # Could be either a XMLMaterialProfile or a InstanceContainer
        duplicated_container = container_type(new_id)

        # Instead of duplicating we load the data from the basefile again.
        # This ensures that the inheritance goes well and all "cut up" subclasses of the xmlMaterial profile
        # are also correctly created.
        with open(containers[0].getPath(), encoding="utf-8") as f:
            duplicated_container.deserialize(f.read())
        duplicated_container.setDirty(True)
        self._container_registry.addContainer(duplicated_container)

    ##  Get the singleton instance for this class.
    @classmethod
    def getInstance(cls) -> "ContainerManager":
        # Note: Explicit use of class name to prevent issues with inheritance.
        if ContainerManager.__instance is None:
            ContainerManager.__instance = cls()
        return ContainerManager.__instance

    __instance = None   # type: "ContainerManager"

    # Factory function, used by QML
    @staticmethod
    def createContainerManager(engine, js_engine):
        return ContainerManager.getInstance()

    def _performMerge(self, merge_into, merge, clear_settings = True):
        assert isinstance(merge, type(merge_into))

        if merge == merge_into:
            return

        for key in merge.getAllKeys():
            merge_into.setProperty(key, "value", merge.getProperty(key, "value"))

        if clear_settings:
            merge.clear()

    def _updateContainerNameFilters(self) -> None:
        self._container_name_filters = {}
        for plugin_id, container_type in self._container_registry.getContainerTypes():
            # Ignore default container types since those are not plugins
            if container_type in (InstanceContainer, ContainerStack, DefinitionContainer):
                continue

            serialize_type = ""
            try:
                plugin_metadata = PluginRegistry.getInstance().getMetaData(plugin_id)
                if plugin_metadata:
                    serialize_type = plugin_metadata["settings_container"]["type"]
                else:
                    continue
            except KeyError as e:
                continue

            mime_type = self._container_registry.getMimeTypeForContainer(container_type)

            entry = {
                "type": serialize_type,
                "mime": mime_type,
                "container": container_type
            }

            suffix = mime_type.preferredSuffix
            if Platform.isOSX() and "." in suffix:
                # OSX's File dialog is stupid and does not allow selecting files with a . in its name
                suffix = suffix[suffix.index(".") + 1:]

            suffix_list = "*." + suffix
            for suffix in mime_type.suffixes:
                if suffix == mime_type.preferredSuffix:
                    continue

                if Platform.isOSX() and "." in suffix:
                    # OSX's File dialog is stupid and does not allow selecting files with a . in its name
                    suffix = suffix[suffix.index("."):]

                suffix_list += ", *." + suffix

            name_filter = "{0} ({1})".format(mime_type.comment, suffix_list)
            self._container_name_filters[name_filter] = entry

    ##  Get containers filtered by machine type and material if required.
    #
    #   \param kwargs Initial search criteria that the containers need to match.
    #
    #   \return A list of containers matching the search criteria.
    def _getFilteredContainers(self, **kwargs):
        return QualityManager.getInstance()._getFilteredContainers(**kwargs)

    ##  Creates a unique ID for a container by prefixing the name with the stack ID.
    #
    #   This method creates a unique ID for a container by prefixing it with a specified stack ID.
    #   This is done to ensure we have an easily identified ID for quality changes, which have the
    #   same name across several stacks.
    #
    #   \param stack_id The ID of the stack to prepend.
    #   \param container_name The name of the container that we are creating a unique ID for.
    #
    #   \return Container name prefixed with stack ID, in lower case with spaces replaced by underscores.
    def _createUniqueId(self, stack_id, container_name):
        result = stack_id + "_" + container_name
        result = result.lower()
        result.replace(" ", "_")
        return result

    ##  Create a quality changes container for a specified quality container.
    #
    #   \param quality_container The quality container to create a changes container for.
    #   \param new_name The name of the new quality_changes container.
    #   \param machine_definition The machine definition this quality changes container is specific to.
    #   \param extruder_id
    #
    #   \return A new quality_changes container with the specified container as base.
    def _createQualityChanges(self, quality_container, new_name, machine_definition, extruder_id):
        base_id = machine_definition.getId() if extruder_id is None else extruder_id

        # Create a new quality_changes container for the quality.
        quality_changes = InstanceContainer(self._createUniqueId(base_id, new_name))
        quality_changes.setName(new_name)
        quality_changes.addMetaDataEntry("type", "quality_changes")
        quality_changes.addMetaDataEntry("quality_type", quality_container.getMetaDataEntry("quality_type"))

        # If we are creating a container for an extruder, ensure we add that to the container
        if extruder_id is not None:
            quality_changes.addMetaDataEntry("extruder", extruder_id)

        # If the machine specifies qualities should be filtered, ensure we match the current criteria.
        if not machine_definition.getMetaDataEntry("has_machine_quality"):
            quality_changes.setDefinition(self._container_registry.findContainers(id = "fdmprinter")[0])
        else:
            quality_changes.setDefinition(QualityManager.getInstance().getParentMachineDefinition(machine_definition))
        return quality_changes


    ##  Import profiles from a list of file_urls.
    #   Each QUrl item must end with .curaprofile, or it will not be imported.
    #
    #   \param QVariant<QUrl>, essentially a list with QUrl objects.
    #   \return Dict with keys status, text
    @pyqtSlot("QVariantList", result="QVariantMap")
    def importProfiles(self, file_urls):
        status = "ok"
        results = {"ok": [], "error": []}
        for file_url in file_urls:
            if not file_url.isValid():
                continue
            path = file_url.toLocalFile()
            if not path:
                continue
            if not path.endswith(".curaprofile"):
                continue

            single_result = self._container_registry.importProfile(path)
            if single_result["status"] == "error":
                status = "error"
            results[single_result["status"]].append(single_result["message"])

        return {
            "status": status,
            "message": "\n".join(results["ok"] + results["error"])}

    ##  Import single profile, file_url does not have to end with curaprofile
    @pyqtSlot(QUrl, result="QVariantMap")
    def importProfile(self, file_url):
        if not file_url.isValid():
            return
        path = file_url.toLocalFile()
        if not path:
            return
        return self._container_registry.importProfile(path)

    @pyqtSlot("QVariantList", QUrl, str)
    def exportProfile(self, instance_id: str, file_url: QUrl, file_type: str) -> None:
        if not file_url.isValid():
            return
        path = file_url.toLocalFile()
        if not path:
            return
        self._container_registry.exportProfile(instance_id, path, file_type)
