// Copyright (c) 2015 Ultimaker B.V.
// Uranium is released under the terms of the AGPLv3 or higher.

import QtQuick 2.1
import QtQuick.Layouts 1.1
import QtQuick.Controls 1.1
import QtQuick.Controls.Styles 1.1

import UM 1.1 as UM
import Cura 1.1 as Cura

import "."

Item {
    id: base;

    height: UM.Theme.getSize("section").height;

    property alias contents: controlContainer.children;
    property alias hovered: mouse.containsMouse

    property var showRevertButton: true
    property var showInheritButton: true
    property var showLinkedSettingIcon: true
    property var doDepthIndentation: true
    property var doQualityUserSettingEmphasis: true

    // Create properties to put property provider stuff in (bindings break in qt 5.5.1 otherwise)
    property var state: propertyProvider.properties.state
    // There is no resolve property if there is only one stack.
    property var resolve: Cura.MachineManager.activeStackId != Cura.MachineManager.activeMachineId ? propertyProvider.properties.resolve : "None"
    property var stackLevels: propertyProvider.stackLevels
    property var stackLevel: stackLevels[0]

    signal contextMenuRequested()
    signal showTooltip(string text);
    signal hideTooltip();
    signal showAllHiddenInheritedSettings(string category_id)
    property string tooltipText:
    {
        var affects = settingDefinitionsModel.getRequiredBy(definition.key, "value")
        var affected_by = settingDefinitionsModel.getRequires(definition.key, "value")

        var affected_by_list = ""
        for(var i in affected_by)
        {
            affected_by_list += "<li>%1</li>\n".arg(affected_by[i].label)
        }

        var affects_list = ""
        for(var i in affects)
        {
            affects_list += "<li>%1</li>\n".arg(affects[i].label)
        }

        var tooltip = "<b>%1</b>\n<p>%2</p>".arg(definition.label).arg(definition.description)

        if(affects_list != "")
        {
            tooltip += "<br/><b>%1</b>\n<ul>\n%2</ul>".arg(catalog.i18nc("@label Header for list of settings.", "Affects")).arg(affects_list)
        }

        if(affected_by_list != "")
        {
            tooltip += "<br/><b>%1</b>\n<ul>\n%2</ul>".arg(catalog.i18nc("@label Header for list of settings.", "Affected By")).arg(affected_by_list)
        }

        return tooltip
    }

    MouseArea
    {
        id: mouse;

        anchors.fill: parent;

        acceptedButtons: Qt.RightButton;
        hoverEnabled: true;

        onClicked: base.contextMenuRequested();

        onEntered: {
            hoverTimer.start();
        }

        onExited: {
            if(controlContainer.item && controlContainer.item.hovered) {
                return;
            }
            hoverTimer.stop();
            base.hideTooltip();
        }

        Timer {
            id: hoverTimer;
            interval: 500;
            repeat: false;

            onTriggered:
            {
                base.showTooltip(base.tooltipText);
            }
        }

        Label
        {
            id: label;

            anchors.left: parent.left;
            anchors.leftMargin: doDepthIndentation ? (UM.Theme.getSize("section_icon_column").width + 5) + ((definition.depth - 1) * UM.Theme.getSize("setting_control_depth_margin").width) : 0
            anchors.right: settingControls.left;
            anchors.verticalCenter: parent.verticalCenter

            height: UM.Theme.getSize("section").height;
            verticalAlignment: Text.AlignVCenter;

            text: definition.label
            elide: Text.ElideMiddle;

            color: UM.Theme.getColor("setting_control_text");
            //opacity: (definition.visible) ? 1 : 0.5
            opacity: 1
            // emphasize the setting if it has a value in the user or quality profile
            font: base.doQualityUserSettingEmphasis && base.stackLevel != undefined && base.stackLevel <= 1 ? UM.Theme.getFont("default_italic") : UM.Theme.getFont("default")
        }

        Row
        {
            id: settingControls

            height: parent.height / 2
            spacing: UM.Theme.getSize("default_margin").width / 2

            anchors {
                right: controlContainer.left
                rightMargin: UM.Theme.getSize("default_margin").width / 2
                verticalCenter: parent.verticalCenter
            }

            UM.SimpleButton
            {
                id: linkedSettingIcon;

                visible: Cura.MachineManager.activeStackId != Cura.MachineManager.activeMachineId && (!definition.settable_per_extruder || definition.limit_to_extruder != "-1") && base.showLinkedSettingIcon

                height: parent.height;
                width: height;

                color: UM.Theme.getColor("setting_control_button")
                hoverColor: UM.Theme.getColor("setting_control_button")

                iconSource: UM.Theme.getIcon("link")

                onEntered: {
                    hoverTimer.stop();
                    var tooltipText = catalog.i18nc("@label", "This setting is always shared between all extruders. Changing it here will change the value for all extruders") + ".";
                    if ((resolve != "None") && (stackLevel != 0)) {
                        // We come here if a setting has a resolve and the setting is not manually edited.
                        tooltipText += " " + catalog.i18nc("@label", "The value is resolved from per-extruder values ") + "[" + ExtruderManager.getInstanceExtruderValues(definition.key) + "].";
                    }
                    base.showTooltip(tooltipText);
                }
                onExited: base.showTooltip(base.tooltipText);
            }

            UM.SimpleButton
            {
                id: revertButton;

                visible: base.stackLevel == 0 && base.showRevertButton

                height: parent.height;
                width: height;

                color: UM.Theme.getColor("setting_control_button")
                hoverColor: UM.Theme.getColor("setting_control_button_hover")

                iconSource: UM.Theme.getIcon("reset")

                onClicked: {
                    revertButton.focus = true;
                    Cura.MachineManager.clearUserSettingAllCurrentStacks(propertyProvider.key);
                }

                onEntered: { hoverTimer.stop(); base.showTooltip(catalog.i18nc("@label", "This setting has a value that is different from the profile.\n\nClick to restore the value of the profile.")) }
                onExited: base.showTooltip(base.tooltipText);
            }

            UM.SimpleButton
            {
                // This button shows when the setting has an inherited function, but is overriden by profile.
                id: inheritButton;
                // Inherit button needs to be visible if;
                // - User made changes that override any loaded settings
                // - This setting item uses inherit button at all
                // - The type of the value of any deeper container is an "object" (eg; is a function)
                visible:
                {
                    if(!base.showInheritButton)
                    {
                        return false;
                    }

                    if(!propertyProvider.properties.enabled)
                    {
                        // Note: This is not strictly necessary since a disabled setting is hidden anyway.
                        // But this will cause the binding to be re-evaluated when the enabled property changes.
                        return false;
                    }

                    // There are no settings with any warning.
                    if(Cura.SettingInheritanceManager.settingsWithInheritanceWarning.length == 0)
                    {
                        return false;
                    }

                    // This setting has a resolve value, so an inheritance warning doesn't do anything.
                    if(resolve != "None")
                    {
                        return false
                    }

                    // If the setting does not have a limit_to_extruder property (or is -1), use the active stack.
                    if(globalPropertyProvider.properties.limit_to_extruder == null || globalPropertyProvider.properties.limit_to_extruder == -1)
                    {
                        return Cura.SettingInheritanceManager.settingsWithInheritanceWarning.indexOf(definition.key) >= 0;
                    }

                    // Setting does have a limit_to_extruder property, so use that one instead.
                    if (definition.key === undefined) {
                        // Observed when loading workspace, probably when SettingItems are removed.
                        return false;
                    }
                    return Cura.SettingInheritanceManager.getOverridesForExtruder(definition.key, globalPropertyProvider.properties.limit_to_extruder).indexOf(definition.key) >= 0;
                }

                height: parent.height;
                width: height;

                onClicked: {
                    focus = true;

                    // Get the most shallow function value (eg not a number) that we can find.
                    var last_entry = propertyProvider.stackLevels[propertyProvider.stackLevels.length - 1]
                    for (var i = 1; i < base.stackLevels.length; i++)
                    {
                        var has_setting_function = typeof(propertyProvider.getPropertyValue("value", base.stackLevels[i])) == "object";
                        if(has_setting_function)
                        {
                            last_entry = propertyProvider.stackLevels[i]
                            break;
                        }
                    }
                    if((last_entry == 4 || last_entry == 11) && base.stackLevel == 0 && base.stackLevels.length == 2)
                    {
                        // Special case of the inherit reset. If only the definition (4th or 11th) container) and the first
                        // entry (user container) are set, we can simply remove the container.
                        propertyProvider.removeFromContainer(0)
                    }
                    else if(last_entry - 1 == base.stackLevel)
                    {
                        // Another special case. The setting that is overriden is only 1 instance container deeper,
                        // so we can remove it.
                        propertyProvider.removeFromContainer(0)
                    }
                    else
                    {
                        // Put that entry into the "top" instance container.
                        // This ensures that the value in any of the deeper containers need not be removed, which is
                        // needed for the reset button (which deletes the top value) to correctly go back to profile
                        // defaults.
                        propertyProvider.setPropertyValue("value", propertyProvider.getPropertyValue("value", last_entry))
                        propertyProvider.setPropertyValue("state", "InstanceState.Calculated")

                    }
                }

                color: UM.Theme.getColor("setting_control_button")
                hoverColor: UM.Theme.getColor("setting_control_button_hover")

                iconSource: UM.Theme.getIcon("notice");

                onEntered: { hoverTimer.stop(); base.showTooltip(catalog.i18nc("@label", "This setting is normally calculated, but it currently has an absolute value set.\n\nClick to restore the calculated value.")) }
                onExited: base.showTooltip(base.tooltipText);
            }
        }

        Item
        {
            id: controlContainer;

            enabled: propertyProvider.isValueUsed

            anchors.right: parent.right;
            anchors.rightMargin: UM.Theme.getSize("default_margin").width
            anchors.verticalCenter: parent.verticalCenter;
            width: UM.Theme.getSize("setting_control").width;
            height: UM.Theme.getSize("setting_control").height
        }
    }

    UM.I18nCatalog { id: catalog; name: "IntamSuite" }
}
