// Copyright (c) 2015 Ultimaker B.V.
// Cura is released under the terms of the AGPLv3 or higher.

import QtQuick 2.2
import QtQuick.Controls 1.1
import QtQuick.Controls.Styles 1.1
import QtQuick.Layouts 1.1

import UM 1.0 as UM
import Cura 1.1 as Cura
Item {
    id: base;

    width: buttons.width;
    height: buttons.height
    //property int activeY
    property int backendState: UM.Backend.state;
    property bool activity: Printer.platformActivity;

    RowLayout {
        id: buttons;
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: 30
        spacing: 40

            Button {
                text: catalog.i18nc("@label","Solid View")
                iconSource: UM.Theme.getIcon("view_normal");

                checkable: true;
                //checked: model.active;
                enabled: !PrintInformation.preSliced;
                onClicked: UM.Controller.setActiveView("SolidView");

                style: UM.Theme.styles.tool_button;

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.bottom
                    anchors.topMargin: 5
                    color:"white"
                    text: catalog.i18nc("@item:inmenu","Solid")
                    font: UM.Theme.getFont("default")
                }
            }
            Button {
                text: catalog.i18nc("@label","X-Ray View")
                iconSource: UM.Theme.getIcon("view_xray");

                checkable: true;
                //checked: model.active;
                enabled: !PrintInformation.preSliced;
                onClicked: UM.Controller.setActiveView("XRayView");

                style: UM.Theme.styles.tool_button;

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.bottom
                    anchors.topMargin: 5
                    color:"white"
                    text: catalog.i18nc("@item:inlistbox","X-Ray")
                    font: UM.Theme.getFont("default")
                }
            }
            Button {
                text: catalog.i18nc("@label","Layer View")
                id:layerBtn
                iconSource: UM.Theme.getIcon("view_layer");

                checkable: true;
                //checked: model.active;
                enabled: !PrintInformation.preSliced && base.backendState == 3 && base.activity == true;
                onClicked: UM.Controller.setActiveView("LayerView");

                style: UM.Theme.styles.tool_button;

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.bottom
                    anchors.topMargin: 5
                    color:"white"
                    text: catalog.i18nc("@item:inlistbox","Layers")
                    font: UM.Theme.getFont("default")
                    opacity: !layerBtn.enabled ? 0.2 : 1.0
                }
            }

    }
    Loader
    {
        id: view_panel

        anchors.top: parent.bottom
        anchors.topMargin: UM.Theme.getSize("default_margin").height;
        anchors.left: parent.left;

        source: UM.ActiveView.valid ? UM.ActiveView.activeViewPanel : "";
    }

}
