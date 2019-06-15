// Copyright (c) 2016 Ultimaker B.V.
// Cura is released under the terms of the AGPLv3 or higher.

import QtQuick 2.2
import QtQuick.Controls 1.1
import QtQuick.Controls.Styles 1.1
import QtQuick.Layouts 1.1

import UM 1.2 as UM
import Cura 1.1 as Cura

Item
{
    id: base;

    signal showTooltip(Item item, point location, string text);
    signal hideTooltip();

    property Action configureSettings;
    property variant minimumPrintTime: PrintInformation.minimumPrintTime;
    property variant maximumPrintTime: PrintInformation.maximumPrintTime;
    property bool settingsEnabled: ExtruderManager.activeExtruderStackId || ExtruderManager.extruderCount == 0

    Component.onCompleted: PrintInformation.enabled = true
    Component.onDestruction: PrintInformation.enabled = false
    UM.I18nCatalog { id: catalog; name:"IntamSuite"}
    anchors
        {
            left: parent.left
            leftMargin: UM.Theme.getSize("default_margin").width
            right: parent.right
            rightMargin: UM.Theme.getSize("default_margin").width
        }

    Item
    {
        id: infillCellLeft
        anchors.top: parent.top
        anchors.left: parent.left
        //width: 170
        width: base.width * 0.35 - UM.Theme.getSize("default_margin").width
        height: childrenRect.height

        Label
        {
            id: infillLabel
            //: Infill selection label
            text: catalog.i18nc("@label", "Infill:");
            font: UM.Theme.getFont("default");
            color: UM.Theme.getColor("text_nontab");
            anchors.top: parent.top
            anchors.topMargin: UM.Theme.getSize("default_margin").height
            anchors.left: parent.left
        }
    }

    Flow
    {
        id: infillCellRight

        height: childrenRect.height;
        //width: 200
        width: base.width * .65
        spacing: 10

        anchors.left: infillCellLeft.right
        anchors.top: infillCellLeft.top

        Repeater
        {
            id: infillListView
            property int activeIndex:
            {
                var density = parseInt(infillDensity.properties.value)
                for(var i = 0; i < infillModel.count; ++i)
                {
                    if(density > infillModel.get(i).percentageMin && density <= infillModel.get(i).percentageMax )
                    {
                        return i;
                    }
                }

                return -1;
            }
            model: infillModel;

            Item
            {
                width: childrenRect.width;
                height: childrenRect.height;

                Rectangle
                {
                    id: infillIconLining

                    width: (infillCellRight.width - 3 * UM.Theme.getSize("default_margin").width) / 4;
                    height: width

                    border.color:
                    {
                        if(!base.settingsEnabled)
                        {
                            return UM.Theme.getColor("setting_control_disabled_border")
                        }
                        else if(infillListView.activeIndex == index)
                        {
                            return UM.Theme.getColor("setting_control_selected")
                        }
                        else if(infillMouseArea.containsMouse)
                        {
                            return UM.Theme.getColor("setting_control_border_highlight")
                        }
                        return UM.Theme.getColor("setting_control_border")
                    }
                    border.width: UM.Theme.getSize("default_lining").width
                    color:
                    {
                        if(infillListView.activeIndex == index)
                        {
                            if(!base.settingsEnabled)
                            {
                                return UM.Theme.getColor("setting_control_disabled_text")
                            }
                            return UM.Theme.getColor("setting_control_selected")
                        }
                        return "transparent"
                    }

                    UM.RecolorImage
                    {
                        id: infillIcon
                        anchors.fill: parent;
                        anchors.margins: UM.Theme.getSize("infill_button_margin").width

                        sourceSize.width: width
                        sourceSize.height: width
                        source: UM.Theme.getIcon(model.icon);
                        color: {
                            if(infillListView.activeIndex == index)
                            {
                                return UM.Theme.getColor("text_reversed")
                            }
                            if(!base.settingsEnabled)
                            {
                                return UM.Theme.getColor("setting_control_disabled_text")
                            }
                            return UM.Theme.getColor("setting_control_disabled_text")
                        }
                    }

                    MouseArea
                    {
                        id: infillMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: base.settingsEnabled
                        onClicked: {
                            if (infillListView.activeIndex != index)
                            {
                                infillDensity.setPropertyValue("value", model.percentage)
                            }
                        }
                        onEntered:
                        {
                            base.showTooltip(infillCellRight, Qt.point(0, 0), model.text);
                        }
                        onExited:
                        {
                            base.hideTooltip();
                        }
                    }
                }
                Label
                {
                    id: infillLabel
                    font: UM.Theme.getFont("default")
                    anchors.top: infillIconLining.bottom
                    anchors.horizontalCenter: infillIconLining.horizontalCenter
                    color: infillListView.activeIndex == index ? UM.Theme.getColor("setting_control_text") : UM.Theme.getColor("setting_control_border")
                    text: name
                }
            }
        }

        ListModel
        {
            id: infillModel

            Component.onCompleted:
            {
                infillModel.append({
                    name: catalog.i18nc("@label", "Hollow"),
                    percentage: 0,
                    percentageMin: -1,
                    percentageMax: 0,
                    text: catalog.i18nc("@label", "No (0%) infill will leave your model hollow at the cost of low strength"),
                    icon: "hollow"
                })
                infillModel.append({
                    name: catalog.i18nc("@label", "Light"),
                    percentage: 20,
                    percentageMin: 0,
                    percentageMax: 30,
                    text: catalog.i18nc("@label", "Light (20%) infill will give your model an average strength"),
                    icon: "sparse"
                })
                infillModel.append({
                    name: catalog.i18nc("@label", "Dense"),
                    percentage: 50,
                    percentageMin: 30,
                    percentageMax: 70,
                    text: catalog.i18nc("@label", "Dense (50%) infill will give your model an above average strength"),
                    icon: "dense"
                })
                infillModel.append({
                    name: catalog.i18nc("@label", "Solid"),
                    percentage: 100,
                    percentageMin: 70,
                    percentageMax: 100,
                    text: catalog.i18nc("@label", "Solid (100%) infill will make your model completely solid"),
                    icon: "solid"
                })
            }
        }
    }

    Item
    {
        id: helpersCell
        anchors.top: infillCellRight.bottom
        anchors.topMargin: UM.Theme.getSize("default_margin").height
        anchors.left: parent.left
        anchors.right: parent.right
        height: childrenRect.height

        Label
        {
            id: enableSupportLabel
            anchors.left: parent.left
            anchors.verticalCenter: enableSupportCheckBox.verticalCenter
            width: parent.width * 0.35 - UM.Theme.getSize("default_margin").width
            text: catalog.i18nc("@label", "Enable Support:");
            font: UM.Theme.getFont("default");
            color: UM.Theme.getColor("text_nontab");
        }

        CheckBox
        {
            id: enableSupportCheckBox
            anchors.top: adhesionOption.bottom
            anchors.topMargin: UM.Theme.getSize("default_margin").height
            anchors.left: enableSupportLabel.right

            style: UM.Theme.styles.checkbox;
            enabled: base.settingsEnabled

            checked: supportEnabled.properties.value == "True";

            MouseArea
            {
                id: enableSupportMouseArea
                anchors.fill: parent
                hoverEnabled: true
                enabled: true
                onClicked:
                {
                    // The value is a string "True" or "False"
                    supportEnabled.setPropertyValue("value", supportEnabled.properties.value != "True");
                }
                onEntered:
                {
                    base.showTooltip(enableSupportCheckBox, Qt.point(0, 0),
                        catalog.i18nc("@label", "Enable support structures. These structures support parts of the model with severe overhangs."));
                }
                onExited:
                {
                    base.hideTooltip();
                }
            }
        }
        Label
        {
            id: supportTypeLabel
            visible: supportEnabled.properties.value == "True"
            anchors.left: parent.left
            anchors.verticalCenter: supportTypeOption.verticalCenter
            width: base.width * 0.35 - UM.Theme.getSize("default_margin").width
            text: catalog.i18nc("@label", "Support Type:");
            font: UM.Theme.getFont("default");
            color: UM.Theme.getColor("text_nontab");
        }
        ComboBox
        {
            id:supportTypeOption
            visible: supportEnabled.properties.value == "True"
            anchors.top: enableSupportCheckBox.bottom
            anchors.topMargin: UM.Theme.getSize("default_margin").height
            anchors.left: supportTypeLabel.right
            height: UM.Theme.getSize("setting_control").height
            width: parent.width * 0.65 + UM.Theme.getSize("default_margin").width
            style: UM.Theme.styles.combobox
            activeFocusOnPress: true;
            model: [
                        catalog.i18nc("@labellist", "Touching Buildplate"),
                        catalog.i18nc("@labellist", "Everywhere"),
                    ]
            currentIndex:supportType.properties.value =="buildplate"? 0:1
            onCurrentIndexChanged: supportType.setPropertyValue("value", supportModel.get(currentIndex).value)
        }
        ListModel
        {
            id: supportModel
            ListElement { text: "Touching Buildplate"; value: "buildplate" }
            ListElement { text: "Everywhere"; value: "everywhere" }
        }

        Label
        {
            id: adhesionHelperLabel
            anchors.left: parent.left
            anchors.verticalCenter: adhesionOption.verticalCenter

            width: parent.width * 0.35 - UM.Theme.getSize("default_margin").width
            text: catalog.i18nc("@label", "Build Plate \nAdhesion:");
            font: UM.Theme.getFont("default");
            color: UM.Theme.getColor("text_nontab");
        }
        ComboBox
        {
            id: adhesionOption
            anchors.top: parent.top
            anchors.left: adhesionHelperLabel.right
            width: parent.width * 0.65 + UM.Theme.getSize("default_margin").width
            style: UM.Theme.styles.combobox
            activeFocusOnPress: true;
            model: [
                        catalog.i18nc("@labellist", "Skirt"),
                        catalog.i18nc("@labellist", "Brim"),
                        catalog.i18nc("@labellist", "Raft"),
                        catalog.i18nc("@labellist", "None")
                    ]
            currentIndex:
            {
                if(platformAdhesionType.properties.value =="skirt")
                {
                    return 0
                }
                if(platformAdhesionType.properties.value =="brim")
                {
                    return 1
                }
                if(platformAdhesionType.properties.value =="raft")
                {
                    return 2
                }
                if(platformAdhesionType.properties.value =="none")
                {
                    return 3
                }
            }
            onCurrentIndexChanged: platformAdhesionType.setPropertyValue("value", adhesionModel.get(currentIndex).value)

        }
        ListModel
        {
            id: adhesionModel
            ListElement { text: "Skirt"; value: "skirt" }
            ListElement { text: "Brim"; value: "brim" }
            ListElement { text: "Raft"; value: "raft" }
            ListElement { text: "None"; value: "none" }
        }

        ListModel
        {
            id: extruderModel
            Component.onCompleted: populateExtruderModel()
        }

        //: Model used to populate the extrudelModel
        Cura.ExtrudersModel
        {
            id: extruders
            onModelChanged: populateExtruderModel()
        }
    }

    function populateExtruderModel()
    {
        extruderModel.clear();
        for(var extruderNumber = 0; extruderNumber < extruders.rowCount() ; extruderNumber++)
        {
            extruderModel.append({
                text: extruders.getItem(extruderNumber).name,
                color: extruders.getItem(extruderNumber).color
            })
        }
        supportExtruderCombobox.updateCurrentColor();
    }

    UM.SettingPropertyProvider
    {
        id: infillDensity

        containerStackId: Cura.MachineManager.activeStackId
        key: "infill_sparse_density"
        watchedProperties: [ "value" ]
        storeIndex: 0
    }

    UM.SettingPropertyProvider
    {
        id: platformAdhesionType

        containerStackId: Cura.MachineManager.activeMachineId
        key: "adhesion_type"
        watchedProperties: [ "value" ]
        storeIndex: 0
    }

    UM.SettingPropertyProvider
    {
        id: supportEnabled

        containerStackId: Cura.MachineManager.activeMachineId
        key: "support_enable"
        watchedProperties: [ "value", "description" ]
        storeIndex: 0
    }

    UM.SettingPropertyProvider
    {
        id: supportType

        containerStackId: Cura.MachineManager.activeMachineId
        key: "support_type"
        watchedProperties: [ "value", "description" ]
        storeIndex: 0
    }

    UM.SettingPropertyProvider
    {
        id: machineExtruderCount

        containerStackId: Cura.MachineManager.activeMachineId
        key: "machine_extruder_count"
        watchedProperties: [ "value" ]
        storeIndex: 0
    }

    UM.SettingPropertyProvider
    {
        id: supportExtruderNr

        containerStackId: Cura.MachineManager.activeMachineId
        key: "support_extruder_nr"
        watchedProperties: [ "value" ]
        storeIndex: 0
    }
}
