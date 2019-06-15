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
    ScrollView
    {
        id:infillView
        anchors.top: parent.top;
        anchors.left: parent.left;
        style: UM.Theme.styles.scrollview;
        width: UM.Theme.getSize("settingtab_section").width
        height: UM.Theme.getSize("settingtab_section").height
        flickableItem.flickableDirection: Flickable.VerticalFlick;
        Label{
            anchors.left:parent.left
            anchors.leftMargin:10
            anchors.top:parent.top
            anchors.topMargin:8
            text:catalog.i18nc("@tabtitle","Cooling:")
            font.bold:true
            }
        ListView
        {
            id: contents
            anchors.top:parent.top
            anchors.topMargin:10
            spacing: UM.Theme.getSize("default_lining").height;
            cacheBuffer: 1000000;   // Set a large cache to effectively just cache every list item.

            model: UM.SettingDefinitionsModel
            {
                id: definitionsModel;
                containerId: Cura.MachineManager.activeDefinitionId
                visibilityHandler: UM.SettingPreferenceVisibilityHandler { }
                exclude: ["experimental", "shell", "resolution", "support", "material", "infill", "travel", "speed", "meshfix", "platform_adhesion", "blackmagic","machine_settings", "command_line_settings", "infill_mesh", "infill_mesh_order", "support_mesh", "anti_overhang_mesh"] // TODO: infill_mesh settigns are excluded hardcoded, but should be based on the fact that settable_globally, settable_per_meshgroup and settable_per_extruder are false.
            }

            delegate:
                UM.TooltipArea {
                    width: childrenRect.width;
                    height: childrenRect.height;
                    text: model.description
                    Loader
                    {
                        id: delegate

                        width: UM.Theme.getSize("sidebar").width;
                        height: provider.properties.enabled == "True" ? UM.Theme.getSize("section").height : - contents.spacing
                        Behavior on height { NumberAnimation { duration: 100 } }
                        opacity: provider.properties.enabled == "True" ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 100 } }

                        property var definition: model
                        property var settingDefinitionsModel: definitionsModel
                        property var propertyProvider: provider
                        property var globalPropertyProvider: inheritStackProvider

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
                                    return definitionsModel.expandAll(model.key)
                                default:
                                    return "SettingUnknown.qml"
                            }
                        }
                        Binding
                        {
                            target: provider
                            property: "containerStackId"
                            when: model.settable_per_extruder || (inheritStackProvider.properties.limit_to_extruder != null && inheritStackProvider.properties.limit_to_extruder >= 0);
                            value:
                            {
                                if(!model.settable_per_extruder || machineExtruderCount.properties.value == 1)
                                {
                                    //Not settable per extruder or there only is global, so we must pick global.
                                    return Cura.MachineManager.activeMachineId;
                                }
                                if(inheritStackProvider.properties.limit_to_extruder != null && inheritStackProvider.properties.limit_to_extruder >= 0)
                                {
                                    //We have limit_to_extruder, so pick that stack.
                                    return ExtruderManager.extruderIds[String(inheritStackProvider.properties.limit_to_extruder)];
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
                            id: inheritStackProvider
                            containerStackId: Cura.MachineManager.activeMachineId
                            key: model.key
                            watchedProperties: [ "limit_to_extruder" ]
                        }

                        UM.SettingPropertyProvider
                        {
                            id: provider

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
                                contextMenu.provider = provider
                                contextMenu.popup();
                            }
                            onShowTooltip: base.showTooltip(delegate, { x: 0, y: delegate.height / 2 }, text)
                            onHideTooltip: base.hideTooltip()
                            onShowAllHiddenInheritedSettings:
                            {
                                var children_with_override = Cura.SettingInheritanceManager.getChildrenKeysWithOverride(category_id)
                                for(var i = 0; i < children_with_override.length; i++)
                                {
                                    definitionsModel.setVisible(children_with_override[i], true)
                                }
                                Cura.SettingInheritanceManager.manualRemoveOverride(category_id)
                            }
                        }
                    }
                }
        }
    }

}