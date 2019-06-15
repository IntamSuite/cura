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

    width: buttons.width;
    height: buttons.height
    property int activeY
    RowLayout {
        id: buttons;
        anchors.left: parent.left
        anchors.leftMargin: 30
        anchors.verticalCenter: parent.verticalCenter
        spacing:40
        //spacing: UM.Theme.getSize("button_lining").width

        Repeater {
            id: repeat

            model: UM.ToolModel { }

            Button {
                text: model.name
                id:functionBtn
                iconSource: UM.Theme.getIcon(model.icon);

                checkable: true;
                checked: model.active;
                enabled: model.enabled && UM.Selection.hasSelection && UM.Controller.toolsEnabled;

                style: UM.Theme.styles.tool_button;
                onCheckedChanged:
                {
                    if(checked)
                    {
                        base.activeY = y
                    }
                }
                //Workaround since using ToolButton"s onClicked would break the binding of the checked property, instead
                //just catch the click so we do not trigger that behaviour.
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.bottom
                    anchors.topMargin: 5
                    color:"white"
                    text: model.name
                    font: UM.Theme.getFont("default")
                    opacity: !functionBtn.enabled ? 0.2 : 1.0
                }
                MouseArea {
                    anchors.fill: parent;
                    onClicked: {
                        forceActiveFocus() //First grab focus, so all the text fields are updated
                        if(parent.checked)
                        {
                            UM.Controller.setActiveTool(null)
                        }
                        else
                        {
                            UM.Controller.setActiveTool(model.id);
                        }
                    }
                }
            }
        }
         Button
            {
                id: layFlatButton

                anchors.left: resetRotationButton.right;
                anchors.leftMargin: UM.Theme.getSize("default_margin").width;
                enabled:UM.Selection.hasSelection && UM.Controller.toolsEnabled;
                //: Lay Flat tool button
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.bottom
                    anchors.topMargin: 5
                    color:"white"
                    text: catalog.i18nc("@action:button","Lay flat")
                    font: UM.Theme.getFont("default")
                    opacity: !layFlatButton.enabled ? 0.2 : 1.0
                }
                iconSource: UM.Theme.getIcon("rotate_layflat");

                style: UM.Theme.styles.tool_button;

                onClicked: UM.ActiveTool.triggerAction("layFlat");
                tooltip:catalog.i18nc("@action:buttontooltip","Lay the object flat to the platform automatically")
            }

        Button
            {
                id: undo
                style: UM.Theme.styles.tool_button
                iconSource: UM.Theme.getIcon("undo")
                action: Cura.Actions.undo
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.bottom
                    anchors.topMargin: 5
                    color:"white"
                    text: catalog.i18nc("@action:inmenu menubar:edit","Undo")
                    font: UM.Theme.getFont("default")
                    opacity: !undo.enabled ? 0.2 : 1.0
                }
            }
        Button
            {
                id: redo
                style: UM.Theme.styles.tool_button
                iconSource: UM.Theme.getIcon("redo")
                action: Cura.Actions.redo
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.bottom
                    anchors.topMargin: 5
                    color:"white"
                    text: catalog.i18nc("@action:inmenu menubar:edit","Redo")
                    font: UM.Theme.getFont("default")
                    opacity: !redo.enabled ? 0.2 : 1.0
                }
            }
        Button
            {
                id: selectAll
                style: UM.Theme.styles.tool_button
                iconSource: UM.Theme.getIcon("select-all")
                action: Cura.Actions.selectAll
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.bottom
                    anchors.topMargin: 5
                    color:"white"
                    text: catalog.i18nc("@action:inmenu menubar:edit","Select All")
                    font: UM.Theme.getFont("default")
                }
            }
        Button
            {
                id: deleteSelec
                style: UM.Theme.styles.tool_button
                iconSource: UM.Theme.getIcon("delete")
                action: Cura.Actions.deleteSelection
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.bottom
                    anchors.topMargin: 5
                    color:"white"
                    text: catalog.i18nc("@action:inmenu menubar:edit","Delete")
                    font: UM.Theme.getFont("default")
                }
            }
        Button
            {
                id: deleteAll
                style: UM.Theme.styles.tool_button
                iconSource: UM.Theme.getIcon("clear")
                action: Cura.Actions.deleteAll
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.bottom
                    anchors.topMargin: 5
                    color:"white"
                    text: catalog.i18nc("@action:inmenu menubar:edit","Clear")
                    font: UM.Theme.getFont("default")
                }
            }
        Button
            {
                id: resetAll
                style: UM.Theme.styles.tool_button
                iconSource: UM.Theme.getIcon("resetall")
                action: Cura.Actions.resetAll
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.bottom
                    anchors.topMargin: 5
                    color:"white"
                    text: catalog.i18nc("@action:inmenu menubar:edit","Reset")
                    font: UM.Theme.getFont("default")
                }
            }
        Button
            {
                id: groupObjects
                style: UM.Theme.styles.tool_button
                iconSource: UM.Theme.getIcon("group")
                action: Cura.Actions.groupObjects
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.bottom
                    anchors.topMargin: 5
                    color:"white"
                    text: catalog.i18nc("@action:inmenu menubar:edit","Group")
                    font: UM.Theme.getFont("default")
                    opacity: !groupObjects.enabled ? 0.2 : 1.0
                }
            }
        Button
            {
                id: mergeObjects
                style: UM.Theme.styles.tool_button
                iconSource: UM.Theme.getIcon("merge")
                action: Cura.Actions.mergeObjects
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.bottom
                    anchors.topMargin: 5
                    color:"white"
                    text: catalog.i18nc("@action:inmenu menubar:edit","Merge")
                    font: UM.Theme.getFont("default")
                    opacity: !mergeObjects.enabled ? 0.2 : 1.0
                }
            }
        Button
            {
                id: unGroupObjects
                style: UM.Theme.styles.tool_button
                iconSource: UM.Theme.getIcon("ungroup")
                action: Cura.Actions.unGroupObjects
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.bottom
                    anchors.topMargin: 5
                    color:"white"
                    text: catalog.i18nc("@action:inmenu menubar:edit","UnGroup")
                    font: UM.Theme.getFont("default")
                    opacity: !unGroupObjects.enabled ? 0.2 : 1.0
                }
            }
    }

    UM.PointingRectangle {
        id: panelBorder;
        anchors.left: parent.left;
        anchors.leftMargin: UM.Theme.getSize("default_margin").width;
        anchors.top: base.bottom;
        anchors.topMargin: 10*UM.Theme.getSize("default_margin").width;
        z: buttons.z -1

        target: Qt.point(parent.right, base.activeY +  UM.Theme.getSize("button").height/2)
        arrowSize: 0

        width: {
            if (panel.item && panel.width > 0){
                 return Math.max(panel.width + 2 * UM.Theme.getSize("default_margin").width)
            }
            else {
                return 0
            }
        }
        height: panel.item ? panel.height + 2 * UM.Theme.getSize("default_margin").height : 0;

        opacity: panel.item && panel.width > 0 ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 100 } }

        color: UM.Theme.getColor("lining");

        UM.PointingRectangle {
            id: panelBackground;

            color: UM.Theme.getColor("tool_panel_background");
            anchors.fill: parent
            anchors.margins: UM.Theme.getSize("default_lining").width

            target: Qt.point(-UM.Theme.getSize("default_margin").width, UM.Theme.getSize("button").height/2)
            arrowSize: parent.arrowSize
            MouseArea //Catch all mouse events (so scene doesnt handle them)
            {
                anchors.fill: parent
            }
        }

        Loader {
            id: panel

            x: UM.Theme.getSize("default_margin").width;
            y: UM.Theme.getSize("default_margin").height;

            source: UM.ActiveTool.valid? UM.ActiveTool.activeToolPanel : "";
            enabled: UM.Controller.toolsEnabled;
        }
    }

    Rectangle
    {
        x: -base.x + base.mouseX + UM.Theme.getSize("default_margin").width
        y: -base.y + base.mouseY + UM.Theme.getSize("default_margin").height

        width: toolHint.width + UM.Theme.getSize("default_margin").width
        height: toolHint.height;
        color: UM.Theme.getColor("tooltip")
        Label
        {
            id: toolHint
            text: UM.ActiveTool.properties.getValue("ToolHint") != undefined ? UM.ActiveTool.properties.getValue("ToolHint") : ""
            color: UM.Theme.getColor("tooltip_text")
            font: UM.Theme.getFont("default")
            anchors.horizontalCenter: parent.horizontalCenter
        }

        visible: toolHint.text != "";
    }
}
