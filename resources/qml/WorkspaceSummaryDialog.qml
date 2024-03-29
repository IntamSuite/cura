// Copyright (c) 2016 Ultimaker B.V.
// Cura is released under the terms of the AGPLv3 or higher.

import QtQuick 2.1
import QtQuick.Controls 1.1
import QtQuick.Layouts 1.1
import QtQuick.Window 2.1

import UM 1.2 as UM
import Cura 1.1 as Cura

UM.Dialog
{
    title: catalog.i18nc("@title:window", "Save Project")

    width: 550
    minimumWidth: 550

    height: 350
    minimumHeight: 350

    property int spacerHeight: 10

    property bool dontShowAgain: true

    signal yes();


    onClosing:
    {
        UM.Preferences.setValue("cura/dialog_on_project_save", !dontShowAgainCheckbox.checked)
    }

    onVisibleChanged:
    {
        if(visible)
        {
            dontShowAgain = !UM.Preferences.getValue("cura/dialog_on_project_save")
        }
    }

    Item
    {
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right

        anchors.topMargin: 20
        anchors.bottomMargin: 20
        anchors.leftMargin:20
        anchors.rightMargin: 20

        UM.SettingDefinitionsModel
        {
            id: definitionsModel
            containerId: Cura.MachineManager.activeDefinitionId
            showAll: true
            exclude: ["command_line_settings"]
            showAncestors: true
            expanded: ["*"]
            visibilityHandler: UM.SettingPreferenceVisibilityHandler { }
        }
        UM.I18nCatalog
        {
            id: catalog;
            name: "cura";
        }

        Column
        {
            anchors.fill: parent
            spacing: 2
            Label
            {
                id: titleLabel
                text: catalog.i18nc("@action:title", "Summary - Cura Project")
                font.pixelSize: 22
            }
            Rectangle
            {
                id: separator
                color: "black"
                width: parent.width
                height: 1
            }
            Item // Spacer
            {
                height: spacerHeight
                width: height
            }

            Label
            {
                text: catalog.i18nc("@action:label", "Printer settings")
                font.bold: true
            }
            Row
            {
                width: parent.width
                height: childrenRect.height
                Label
                {
                    text: catalog.i18nc("@action:label", "Type")
                    width: parent.width / 3
                }
                Label
                {
                    text: Cura.MachineManager.activeDefinitionName
                    width: parent.width / 3
                }
            }
            Row
            {
                width: parent.width
                height: childrenRect.height
                Label
                {
                    text: catalog.i18nc("@action:label", "Name")
                    width: parent.width / 3
                }
                Label
                {
                    text: Cura.MachineManager.activeMachineName
                    width: parent.width / 3
                }
            }

            Repeater
            {
                model: Cura.MachineManager.activeMaterialNames
                delegate: Column
                {
                    Item // Spacer
                    {
                        height: spacerHeight
                        width: height
                    }
                    Label
                    {
                        text: catalog.i18nc("@action:label", "Extruder %1").arg(index+1)
                    }
                    height: childrenRect.height
                    width: parent.width
                    Row
                    {
                        width: parent.width
                        height: childrenRect.height
                        Label
                        {
                            text: catalog.i18nc("@action:label", "%1 & material").arg(Cura.MachineManager.activeDefinitionVariantsName)
                            width: parent.width / 3
                        }
                        Label
                        {
                            text: Cura.MachineManager.activeVariantNames[index] + ", " + modelData
                            width: parent.width / 3
                        }
                    }
                }
            }

            Item // Spacer
            {
                height: spacerHeight
                width: height
            }

            Label
            {
                text: catalog.i18nc("@action:label", "Profile settings")
                font.bold: true
            }
            Row
            {
                width: parent.width
                Label
                {
                    text: catalog.i18nc("@action:label", "Not in profile")
                    width: parent.width / 3
                }
                Label
                {
                    text: catalog.i18ncp("@action:label", "%1 override", "%1 overrides", Cura.MachineManager.numUserSettings).arg(Cura.MachineManager.numUserSettings)
                    width: parent.width / 3
                }
                visible: Cura.MachineManager.numUserSettings
            }
            Row
            {
                width: parent.width
                height: childrenRect.height
                Label
                {
                    text: catalog.i18nc("@action:label", "Name")
                    width: parent.width / 3
                }
                Label
                {
                    text: Cura.MachineManager.activeQualityName
                    width: parent.width / 3
                }

            }

            Item // Spacer
            {
                height: spacerHeight
                width: height
            }

            Label
            {
                text: catalog.i18nc("@action:label", "Setting visibility")
                font.bold: true
            }
            Row
            {
                width: parent.width
                height: childrenRect.height
                Label
                {
                    text: catalog.i18nc("@action:label", "Visible settings:")
                    width: parent.width / 3
                }
                Label
                {
                    text: catalog.i18nc("@action:label", "%1 out of %2" ).arg(definitionsModel.visibleCount).arg(Cura.MachineManager.totalNumberOfSettings)
                    width: parent.width / 3
                }
            }
            CheckBox
            {
                id: dontShowAgainCheckbox
                text: catalog.i18nc("@action:label", "Don't show project summary on save again")
                checked: dontShowAgain
            }
        }


        Button
        {
            id: ok_button
            text: catalog.i18nc("@action:button","Save");
            enabled: true
            onClicked: {
                close()
                yes()
            }
            anchors.bottomMargin: - 0.5 * height
            anchors.bottom: parent.bottom
            anchors.right: parent.right
        }

        Button
        {
            id: cancel_button
            text: catalog.i18nc("@action:button","Cancel");
            enabled: true
            onClicked: close()

            anchors.bottom: parent.bottom
            anchors.right: ok_button.left
            anchors.bottomMargin: - 0.5 * height
            anchors.rightMargin:2

        }
    }
}