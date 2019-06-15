// Copyright (c) 2015 Ultimaker B.V.
// Cura is released under the terms of the AGPLv3 or higher.

import QtQuick 2.2
import QtQuick.Controls 1.1
import QtQuick.Controls.Styles 1.1

import UM 1.2 as UM
import Cura 1.1 as Cura

import "Menus"

Column
{
    id: base;

    property int currentExtruderIndex: ExtruderManager.activeExtruderIndex;

    spacing: UM.Theme.getSize("default_margin").height

    signal showTooltip(Item item, point location, string text)
    signal hideTooltip()



    Item
    {
        id: variantRowSpacer
        height: UM.Theme.getSize("default_margin").height / 4
        width: height
        visible: !extruderSelectionRow.visible
    }
    Row
    {
        id: materialRow

        height: UM.Theme.getSize("sidebar_setup").height
        visible: Cura.MachineManager.hasMaterials

        anchors
        {
            left: parent.left
            leftMargin: UM.Theme.getSize("default_margin").width
            right: parent.right
            rightMargin: UM.Theme.getSize("default_margin").width
        }

        Label
        {
            id: materialLabel
            text:
            {
                var label;
                label = catalog.i18nc("@label","Material");
                return "%1:".arg(label);
            }

            anchors.verticalCenter: parent.verticalCenter
            width: parent.width * 0.35 - UM.Theme.getSize("default_margin").width
            font: UM.Theme.getFont("default");
            color: UM.Theme.getColor("text_nontab");
        }

        Item
        {
            anchors.verticalCenter: parent.verticalCenter

            width: parent.width * 0.65 + UM.Theme.getSize("default_margin").width
            height: UM.Theme.getSize("setting_control").height

            ToolButton {
                id: materialSelection
                text: Cura.MachineManager.activeMaterialName
                tooltip: Cura.MachineManager.activeMaterialName
                visible: Cura.MachineManager.hasMaterials
                property var valueError:
                {
                    var data = Cura.ContainerManager.getContainerMetaDataEntry(Cura.MachineManager.activeMaterialId, "compatible")
                    if(data == "False")
                    {
                        return true
                    }
                    else
                    {
                        return false
                    }

                }
                property var valueWarning: ! Cura.MachineManager.isActiveQualitySupported

                enabled: !extrudersList.visible || base.currentExtruderIndex  > -1

                height: UM.Theme.getSize("setting_control").height
                width: parent.width
                anchors.right: parent.right
                style: UM.Theme.styles.sidebar_header_button
                activeFocusOnPress: true;

                menu: MaterialMenu { extruderIndex: base.currentExtruderIndex }
            }
        }
    }

    Row
    {
        id: variantRow

        height: UM.Theme.getSize("sidebar_setup").height
        visible: Cura.MachineManager.hasVariants

        anchors
        {
            left: parent.left
            leftMargin: UM.Theme.getSize("default_margin").width
            right: parent.right
            rightMargin: UM.Theme.getSize("default_margin").width
        }

        Label
        {
            id: variantLabel
            text:
            {
                var label;
                label = Cura.MachineManager.activeDefinitionVariantsName;
                return "%1:".arg(label);
            }

            anchors.verticalCenter: parent.verticalCenter
            width: parent.width * 0.35 - UM.Theme.getSize("default_margin").width
            font: UM.Theme.getFont("default");
            color: UM.Theme.getColor("text_nontab");
        }

        Item
        {
            anchors.verticalCenter: parent.verticalCenter

            width: parent.width * 0.65 + UM.Theme.getSize("default_margin").width
            height: UM.Theme.getSize("setting_control").height

            ToolButton {
                id: variantSelection
                text: Cura.MachineManager.activeVariantName
                tooltip: Cura.MachineManager.activeVariantName;
                visible: Cura.MachineManager.hasVariants
                enabled: !extrudersList.visible || base.currentExtruderIndex  > -1

                height: UM.Theme.getSize("setting_control").height
                width: parent.width
                anchors.left: parent.left
                style: UM.Theme.styles.sidebar_header_button
                activeFocusOnPress: true;

                menu: NozzleMenu { extruderIndex: base.currentExtruderIndex }
            }
        }
    }

    Row
    {
        id: globalProfileRow
        height: UM.Theme.getSize("sidebar_setup").height

        anchors
        {
            left: parent.left
            leftMargin: UM.Theme.getSize("default_margin").width
            right: parent.right
            rightMargin: UM.Theme.getSize("default_margin").width
        }


        Label
        {
            id: globalProfileLabel
            text: catalog.i18nc("@label","Profile:");
            width: parent.width * 0.35 - UM.Theme.getSize("default_margin").width
            font: UM.Theme.getFont("default");
            color: UM.Theme.getColor("text_nontab");
        }

        ToolButton
        {
            id: globalProfileSelection
            text: {
                var result = Cura.MachineManager.activeQualityName;
                if (Cura.MachineManager.activeQualityLayerHeight > 0) {
                    result += " <font color=\"" + UM.Theme.getColor("text_detail") + "\">";
                    result += " - ";
                    result += Cura.MachineManager.activeQualityLayerHeight + "mm";
                    result += "</font>";
                }
                return result;
            }
            enabled: !extrudersList.visible || base.currentExtruderIndex  > -1

            width: parent.width * 0.65 + UM.Theme.getSize("default_margin").width
            height: UM.Theme.getSize("setting_control").height
            tooltip: Cura.MachineManager.activeQualityName
            style: UM.Theme.styles.sidebar_header_button
            activeFocusOnPress: true;
            property var valueWarning: ! Cura.MachineManager.isActiveQualitySupported
            menu: ProfileMenu { }

            UM.SimpleButton
            {
                id: customisedSettings

                visible: Cura.MachineManager.hasUserSettings
                height: parent.height * 0.6
                width: parent.height * 0.6

                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: UM.Theme.getSize("setting_preferences_button_margin").width - UM.Theme.getSize("default_margin").width

                color: hovered ? UM.Theme.getColor("setting_control_button_hover") : UM.Theme.getColor("setting_control_button");
                iconSource: UM.Theme.getIcon("star");

                onClicked:
                {
                    forceActiveFocus();
                    Cura.Actions.manageProfiles.trigger()
                }
                onEntered:
                {
                    var content = catalog.i18nc("@tooltip","Some setting/override values are different from the values stored in the profile.\n\nClick to open the profile manager.")
                    base.showTooltip(globalProfileRow, Qt.point(40, globalProfileRow.height / 2),  content)
                }
                onExited: base.hideTooltip()
            }
        }
    }

    UM.SettingPropertyProvider
    {
        id: machineExtruderCount

        containerStackId: Cura.MachineManager.activeMachineId
        key: "machine_extruder_count"
        watchedProperties: [ "value" ]
        storeIndex: 0
    }

    UM.I18nCatalog { id: catalog; name:"IntamSuite" }
}
