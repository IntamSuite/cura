// Copyright (c) 2015 Ultimaker B.V.
// Cura is released under the terms of the AGPLv3 or higher.

import QtQuick 2.2
import QtQuick.Controls 1.1
import QtQuick.Controls.Styles 1.1
import QtQuick.Layouts 1.1

import UM 1.3 as UM
import Cura 1.1 as Cura
Item {

    width: buttons.width;
    height: buttons.height
    property int activeY

    RowLayout {
        id: buttons;
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: 30
        spacing: 40
        Button
            {
                id: openFileButton;
                text: catalog.i18nc("@action:button","Open File");
                iconSource: UM.Theme.getIcon("open")
                style: UM.Theme.styles.tool_button
                tooltip: '';
                action: Cura.Actions.open;
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.bottom
                    anchors.topMargin: 5
                    color:"white"
                    text: catalog.i18nc("@action:button","Open File")
                    font: UM.Theme.getFont("default")
                }
            }

        Button
            {
                id: saveFile
                style: UM.Theme.styles.tool_button
                iconSource: UM.Theme.getIcon("save")
                text:catalog.i18nc("@action:buttontip","Save Gcode")
                onClicked:
                    {
                            UM.OutputDeviceManager.requestWriteToDevice("local_file", PrintInformation.jobName, { "filter_by_machine": true })
                    }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.bottom
                    anchors.topMargin: 5
                    color:"white"
                    text: catalog.i18nc("@action:button","Save")
                    font: UM.Theme.getFont("default")
                }
            }
        Connections {
            target: Printer
            onAdditionalComponentsChanged:
            {
                if(areaId == "saveButton") {
                    for (var component in Printer.additionalComponents["saveButton"]) {
                        Printer.additionalComponents["saveButton"][component].parent = additionalComponentsRow
                    }
                }
            }
        }
        Button
            {
                id: printPage
                style: UM.Theme.styles.tool_button
                iconSource: UM.Theme.getIcon("print")
                text:catalog.i18nc("@action:buttontip","Print Settings")
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.bottom
                    anchors.topMargin: 5
                    color:"white"
                    text: catalog.i18nc("@action:button", "Print")
                    font: UM.Theme.getFont("default")
                }
                MouseArea {
                            id:printSettingsArea
                            anchors.fill: parent
                            //onClicked: btn.state == 'clicked' ? btn.state = "" : btn.state = 'clicked';
                            onClicked: printPage.state == 'clicked' ? printPage.state = "" : printPage.state = 'clicked';

                        }
                states: [
                    State {
                        name: "clicked"
                        PropertyChanges { target:printWindow; visible:true}
                        //action: Cura.Actions.printSettings;
                    }
                ]
                //action: Cura.Actions.printSettings;
            }
        }
        Connections
            {
                target: Cura.Actions.printSettings
                onTriggered:
                {
                    printWindow.visible = true
                    tabMenu.currentIndex = 0
                }
            }
        PrintWin{
                id:printWindow
            }

}
