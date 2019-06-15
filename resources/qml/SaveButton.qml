// Copyright (c) 2015 Ultimaker B.V.
// Cura is released under the terms of the AGPLv3 or higher.

import QtQuick 2.2
import QtQuick.Controls 1.1
import QtQuick.Controls.Styles 1.1
import QtQuick.Layouts 1.1

import UM 1.1 as UM
import Cura 1.1 as Cura
Item {
    id: base;
    UM.I18nCatalog { id: catalog; name:"IntamSuite"}

    property real progress: UM.Backend.progress;
    property int backendState: UM.Backend.state;

    property var backend: CuraApplication.getBackend();
    property bool activity: Printer.platformActivity;

    property int totalHeight: childrenRect.height + UM.Theme.getSize("default_margin").height
    property string fileBaseName
    property string statusText:
    {
        if(!activity)
        {
            return catalog.i18nc("@label:PrintjobStatus", "Step 1: Please LOAD STL file to start");

        }

        switch(base.backendState)
        {
            case 1:
                return catalog.i18nc("@label:PrintjobStatus", "Step 2: Click PRINT SETTINGS to choose print mode or click Edit tab to edit STL file");
            case 2:
                return catalog.i18nc("@label:PrintjobStatus", "Step 3: Slicing in process...");
            case 3:
                return catalog.i18nc("@label:PrintjobStatus","Step 4: Click SAVE GCODE to save Gcode file, or if you want to change settings again, you can click PRINT AGAIN");
            case 4:
                return catalog.i18nc("@label:PrintjobStatus", "Unable to Slice");
            case 5:
                return catalog.i18nc("@label:PrintjobStatus", "Slicing unavailable");
            default:
                return "";
        }
    }

    Label {
        id: statusLabel
        width: parent.width - 2 * UM.Theme.getSize("default_margin").width
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.leftMargin: UM.Theme.getSize("default_margin").width

        color: "black"
        font: UM.Theme.getFont("default")
        lineHeight: 2
        text: statusText;
        wrapMode: Text.WordWrap

    }



    Rectangle {
        id: progressBar
        width: parent.width - 2 * UM.Theme.getSize("default_margin").width
        height: UM.Theme.getSize("progressbar").height
        anchors.top: statusLabel.bottom
        anchors.topMargin: UM.Theme.getSize("default_margin").height/4
        anchors.left: parent.left
        anchors.leftMargin: UM.Theme.getSize("default_margin").width
        color: UM.Theme.getColor("progressbar_background")
        visible: base.backendState == 2 && base.activity == true
        Rectangle {
            width: Math.max(parent.width * base.progress)
            height: parent.height
            color: UM.Theme.getColor("logocolor2")
            visible: base.backendState == 2 ? true : false
        }
    }

    Item {
        id: saveRow
        width: base.width
        height: saveToButton.height
        anchors.top: progressBar.bottom
        anchors.topMargin: UM.Theme.getSize("default_margin").height
        anchors.left: parent.left

        Row {
            id: additionalComponentsRow
            anchors.top: parent.top
            anchors.right: saveToButton.visible ? saveToButton.left : parent.right
            anchors.rightMargin: UM.Theme.getSize("default_margin").width

            spacing: UM.Theme.getSize("default_margin").width
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


        Button {
            id:loadButton
            anchors.horizontalCenter:parent.horizontalCenter
            enabled: base.activity == false
            visible: {
                    base.activity == false;
                }
            style: ButtonStyle {
                background: Rectangle
                {
                    color: UM.Theme.getColor("logocolor2")

                    implicitWidth: actualLabel.contentWidth + (UM.Theme.getSize("default_margin").width * 2)
                    implicitHeight: actualLabel.contentHeight + (UM.Theme.getSize("default_margin").height * 2)
                    Label {
                        id: actualLabel
                        anchors.centerIn: parent
                        color:"white"
                        font: UM.Theme.getFont("action_button")
                        text: control.text;
                    }
                }
                label: Item { }
            }
            text: catalog.i18nc("@button","LOAD STL")
            action: Cura.Actions.open;
         }

        Button {
            id: printButton
            tooltip: UM.OutputDeviceManager.activeDeviceDescription;
            // 3 = done, 5 = disabled
            enabled: base.backendState == 1 && base.activity == true
            visible: {
             base.backendState == 1 && base.activity == true;
            }
            height: UM.Theme.getSize("save_button_save_to_button").height

            anchors.top: parent.top
            anchors.horizontalCenter:parent.horizontalCenter
            style: ButtonStyle {
                background: Rectangle
                {
                    color: UM.Theme.getColor("logocolor2")
                    implicitWidth: actualLabel.contentWidth + (UM.Theme.getSize("default_margin").width)

                    Label {
                        id: actualLabel
                        anchors.centerIn: parent
                        color: "white"

                        font: UM.Theme.getFont("action_button")
                        text: control.text;
                    }
                }
                label: Item { }
            }

            text: catalog.i18nc("@button","PRINT SETTINGS")
            action: Cura.Actions.printSettings

        }
        // Prepare button, only shows if auto_slice is off
        Button {
            id: prepareButton

            tooltip: UM.OutputDeviceManager.activeDeviceDescription;
            // 1 = not started, 2 = Processing
            enabled: base.backendState == 2 && base.activity == true
            visible: {
                base.backendState == 2 && base.activity == true;
                }
            height: UM.Theme.getSize("save_button_save_to_button").height

            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            //anchors.rightMargin: UM.Theme.getSize("default_margin").width

            // 1 = not started, 5 = disabled
            text:  catalog.i18nc("@button", "CANCEL")
            onClicked:
            {
                    backend.stopSlicing();
            }

            style: ButtonStyle {
                background: Rectangle
                {
                    color: UM.Theme.getColor("logocolor2")

                    implicitWidth: actualLabel.contentWidth + (UM.Theme.getSize("default_margin").width * 2)

                    Label {
                        id: actualLabel
                        anchors.centerIn: parent
                        color:"white"
                        font: UM.Theme.getFont("action_button")
                        text: control.text;
                    }
                }
                label: Item { }
            }
        }
        Button {
            id: printAgainButton
            tooltip: "go back to PRINT SETTINGS";
            // 3 = done, 5 = disabled
            enabled: (base.backendState == 3 || base.backendState == 5) && base.activity == true
            visible: {
                ((base.backendState == 3 || base.backendState == 5) && base.activity == true);
            }
            height: UM.Theme.getSize("save_button_save_to_button").height

            anchors.top: parent.top
            anchors.left:parent.left
            anchors.leftMargin:UM.Theme.getSize("default_margin").width
            style: ButtonStyle {
                background: Rectangle
                {
                    color: UM.Theme.getColor("logocolor2")
                    implicitWidth: actualLabel.contentWidth + (UM.Theme.getSize("default_margin").width)

                    Label {
                        id: actualLabel
                        anchors.centerIn: parent
                        color: "white"

                        font: UM.Theme.getFont("action_button")
                        text: control.text;
                    }
                }
                label: Item { }
            }

            text: catalog.i18nc("@button","PRINT AGAIN")
            action:
            {
                Cura.Actions.changeTab
                Cura.Actions.printSettings
            }
        }


        Button {
            id: saveToButton

            tooltip: UM.OutputDeviceManager.activeDeviceDescription;
            // 3 = done, 5 = disabled
            enabled: (base.backendState == 3 || base.backendState == 5) && base.activity == true
            visible: {
                return ((base.backendState == 3 || base.backendState == 5) && base.activity == true);
            }
            height: UM.Theme.getSize("save_button_save_to_button").height

            anchors.top: parent.top
            anchors.right: deviceSelectionMenu.visible ? deviceSelectionMenu.left : parent.right
            anchors.rightMargin: deviceSelectionMenu.visible ? -3 * UM.Theme.getSize("default_lining").width : UM.Theme.getSize("default_margin").width

            text: catalog.i18nc("@button","SAVE GCODE")
            onClicked:
            {
                UM.OutputDeviceManager.requestWriteToDevice(UM.OutputDeviceManager.activeDevice, PrintInformation.jobName, { "filter_by_machine": true })
            }

            style: ButtonStyle {
                background: Rectangle
                {
                    color: UM.Theme.getColor("logocolor2")

                    implicitWidth: actualLabel.contentWidth + (UM.Theme.getSize("default_margin").width)

                    Label {
                        id: actualLabel
                        anchors.centerIn: parent
                        color: "white"

                        font: UM.Theme.getFont("action_button")
                        text: control.text;
                    }
                }
                label: Item { }
            }
        }

        Button {
            id: deviceSelectionMenu
            tooltip: catalog.i18nc("@info:tooltip","Select the active output device");
            anchors.top: parent.top
            anchors.right: parent.right

            anchors.rightMargin: UM.Theme.getSize("default_margin").width
            width: UM.Theme.getSize("save_button_save_to_button").height
            height: UM.Theme.getSize("save_button_save_to_button").height
            // 3 = Done, 5 = Disabled
            enabled: (base.backendState == 3 || base.backendState == 5) && base.activity == true
            visible: (devicesModel.deviceCount > 1) && (base.backendState == 3 || base.backendState == 5) && base.activity == true


            style: ButtonStyle {
                background: Rectangle {
                    id: deviceSelectionIcon
                    color: UM.Theme.getColor("logocolor2")
                    anchors.left: parent.left
                    anchors.leftMargin: UM.Theme.getSize("save_button_text_margin").width / 2;
                    width: parent.height/2
                    height: parent.height

                    UM.RecolorImage {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: UM.Theme.getSize("standard_arrow").width
                        height: UM.Theme.getSize("standard_arrow").height
                        sourceSize.width: width
                        sourceSize.height: height
                        color:
                        {
                            if(!control.enabled)
                                return UM.Theme.getColor("action_button_disabled_text");
                            else if(control.pressed)
                                return UM.Theme.getColor("action_button_active_text");
                            else if(control.hovered)
                                return UM.Theme.getColor("action_button_hovered_text");
                            else
                                return UM.Theme.getColor("action_button_text");
                        }
                        source: UM.Theme.getIcon("arrow_bottom");
                    }
                }
                label: Label{ }
            }

            menu: Menu {
                id: devicesMenu;
                Instantiator {
                    model: devicesModel;
                    MenuItem {
                        text: model.description
                        checkable: true;
                        checked: model.id == UM.OutputDeviceManager.activeDevice;
                        exclusiveGroup: devicesMenuGroup;
                        onTriggered: {
                            UM.OutputDeviceManager.setActiveDevice(model.id);
                            UM.OutputDeviceManager.requestWriteToDevice(UM.OutputDeviceManager.activeDevice, PrintInformation.jobName, { "filter_by_machine": true })
                        }
                    }
                    onObjectAdded: devicesMenu.insertItem(index, object)
                    onObjectRemoved: devicesMenu.removeItem(object)
                }
                ExclusiveGroup { id: devicesMenuGroup; }
            }
        }
        UM.OutputDevicesModel { id: devicesModel; }
    }

}
