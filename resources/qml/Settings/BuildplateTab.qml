// Copyright (c) 2015 Ultimaker B.V.
// Uranium is released under the terms of the AGPLv3 or higher.

import QtQuick 2.2
import QtQuick.Controls 1.1
import QtQuick.Controls.Styles 1.1
import QtQuick.Layouts 1.1
import UM 1.2 as UM
import Cura 1.1 as Cura

Item {
    width: UM.Theme.getSize("settingtab").width
    height: UM.Theme.getSize("settingtab").height
    Label{
        anchors.left:parent.left
        anchors.leftMargin:10
        anchors.top:parent.top
        anchors.topMargin:8
        text:catalog.i18nc("@tabtitle","Build Plate Adhesion:")
        font.bold:true
        }
    ScrollView{
        id:buildplateView
        anchors.top: parent.top;
        anchors.topMargin:10
        anchors.left: parent.left;
        style: UM.Theme.styles.scrollview;
        verticalScrollBarPolicy:Qt.ScrollBarAlwaysOff
        width: UM.Theme.getSize("settingtab").width
        height: UM.Theme.getSize("settingtab").height-40
        flickableItem.flickableDirection: Flickable.VerticalFlick;

        GridView
        {
            id: contents2
            cellHeight: UM.Theme.getSize("section").height
            cellWidth:width/2
            flow :GridView.TopToBottom
            model: UM.SettingDefinitionsModel
            {
                id: buildPlateModel;
                containerId: Cura.MachineManager.activeDefinitionId
                visibilityHandler: UM.SettingPreferenceVisibilityHandler { }
                exclude: ["experimental", "resolution", "infill", "support", "material", "speed", "travel", "cooling", "meshfix", "dual", "shell", "blackmagic","machine_settings", "command_line_settings", "infill_mesh", "infill_mesh_order", "support_mesh", "anti_overhang_mesh"] // TODO: infill_mesh settigns are excluded hardcoded, but should be based on the fact that settable_globally, settable_per_meshgroup and settable_per_extruder are false.

            }

            delegate:
                UM.TooltipArea {
                    width: childrenRect.width;
                    height: childrenRect.height;
                    text: model.description
                    Loader
                    {
                        id: delegate2

                        width: UM.Theme.getSize("sidebar").width;
                        height: provider1.properties.enabled == "True" ? UM.Theme.getSize("section").height : - contents2.spacing
                        Behavior on height { NumberAnimation { duration: 100 } }
                        opacity: provider1.properties.enabled == "True" ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 100 } }

                        property var definition: model
                        property var settingDefinitionsModel: buildPlateModel
                        property var propertyProvider: provider2
                        property var globalPropertyProvider: inheritStackProvider2

                        asynchronous: model.type != "enum" && model.type != "extruder"
                        active: model.type != undefined

                        source:
                        {
                            switch(model.type)
                            {
                                case "int":
                                    return "SettingTextField.qml"
                                case "[int]":
                                    return "SettingTextField.qml"
                                case "float":
                                    return "SettingTextField.qml"
                                case "enum":
                                    return "SettingComboBox.qml"
                                case "extruder":
                                    return "SettingExtruder.qml"
                                case "bool":
                                    return "SettingCheckBox.qml"
                                case "str":
                                    return "SettingTextField.qml"
                                case "category":
                                    return buildPlateModel.expandAll(model.key)
                                default:
                                    return "SettingUnknown.qml"
                            }
                        }
                        Binding
                        {
                            target: provider2
                            property: "containerStackId"
                            when: model.settable_per_extruder || (inheritStackProvider1.properties.limit_to_extruder != null && inheritStackProvider2.properties.limit_to_extruder >= 0);
                            value:
                            {
                                if(!model.settable_per_extruder || machineExtruderCount.properties.value == 1)
                                {
                                    //Not settable per extruder or there only is global, so we must pick global.
                                    return Cura.MachineManager.activeMachineId;
                                }
                                if(inheritStackProvider1.properties.limit_to_extruder != null && inheritStackProvider1.properties.limit_to_extruder >= 0)
                                {
                                    //We have limit_to_extruder, so pick that stack.
                                    return ExtruderManager.extruderIds[String(inheritStackProvider1.properties.limit_to_extruder)];
                                }
                                if(ExtruderManager.activeExtruderStackId)
                                {
                                    //We're on an extruder tab. Pick the current extruder.
                                    return ExtruderManager.activeExtruderStackId;
                                }
                                //No extruder tab is selected. Pick the global stack. Shouldn't happen any more since we removed the global tab.
                                return Cura.MachineManager.activeMachineId;
                            }
                        }
                        UM.SettingPropertyProvider
                        {
                            id: inheritStackProvider2
                            containerStackId: Cura.MachineManager.activeMachineId
                            key: model.key
                            watchedProperties: [ "limit_to_extruder" ]
                        }

                        UM.SettingPropertyProvider
                        {
                            id: provider2

                            containerStackId: Cura.MachineManager.activeMachineId
                            key: model.key ? model.key : ""
                            watchedProperties: [ "value", "enabled", "state", "validationState", "settable_per_extruder", "resolve" ]
                            storeIndex: 0
                            // Due to the way setPropertyValue works, removeUnusedValue gives the correct output in case of resolve
                            removeUnusedValue: model.resolve == undefined
                        }

                        Connections
                        {
                            target: item
                            onContextMenuRequested:
                            {
                                contextMenu.key = model.key;
                                contextMenu.settingVisible = model.visible;
                                contextMenu.provider = provider2
                                contextMenu.popup();
                            }
                            onShowTooltip: base.showTooltip(delegate2, Qt.point(0, 0), text)
                            onHideTooltip: base.hideTooltip()
                            onShowAllHiddenInheritedSettings:
                            {
                                var children_with_override = Cura.SettingInheritanceManager.getChildrenKeysWithOverride(category_id)
                                for(var i = 0; i < children_with_override.length; i++)
                                {
                                    buildPlateModel.setVisible(children_with_override[i], true)
                                }
                                Cura.SettingInheritanceManager.manualRemoveOverride(category_id)
                            }
                        }
                    }
                }
        }
    }

}