// Copyright (c) 2017 Ultimaker B.V.
// Cura is released under the terms of the AGPLv3 or higher.

import QtQuick 2.2
import QtQuick.Controls 1.1
import QtQuick.Controls.Styles 1.1
import QtQuick.Layouts 1.1
import QtQuick.Window 2.0
import UM 1.2 as UM
import Cura 1.1 as Cura
import "Menus"

Rectangle
{
    id: base;
    height:UM.Theme.getSize("print_win").height;
    width:UM.Theme.getSize("print_win").width
    visible:false
    anchors.top:parent.top
    anchors.topMargin:12.6*UM.Theme.getSize("default_margin").height
    anchors.left:parent.left
    anchors.leftMargin:26
    color: "lightgrey"

    property int currentModeIndex;
    property bool monitoringPrint: false;  // When adding more "tabs", one want to replace this bool with a ListModel
    property bool hideSettings: PrintInformation.preSliced
    Connections
    {
        target: Printer
        onShowPrintMonitor:
        {
            base.monitoringPrint = show;
            showSettings.checked = !show;
            showMonitor.checked = show;
        }
    }

    // Is there an output device for this printer?
    property bool printerConnected: Cura.MachineManager.printerOutputDevices.length != 0
    property bool printerAcceptsCommands: printerConnected && Cura.MachineManager.printerOutputDevices[0].acceptsCommands
    property real progress: UM.Backend.progress;
    property int backendState: UM.Backend.state;

    property var backend: CuraApplication.getBackend();
    property bool activity: Printer.platformActivity;

    UM.I18nCatalog { id: catalog; name:"IntamSuite"}

    Timer {
        id: tooltipDelayTimer
        interval: 500
        repeat: false
        property var item
        property string text

        onTriggered:
        {
            base.showTooltip(base, {x:1, y:item.y}, text);
        }
    }

    function showTooltip(item, position, text)
    {
        tooltip.text = text;
        position = item.mapToItem(base, position.x, position.y);
        tooltip.show(position);
    }

    function hideTooltip()
    {
        tooltip.hide();
    }
    SidebarTooltip
    {
        id: tooltip;
    }

    function strPadLeft(string, pad, length) {
        return (new Array(length + 1).join(pad) + string).slice(-length);
    }

    function getPrettyTime(time)
    {
        var hours = Math.floor(time / 3600)
        time -= hours * 3600
        var minutes = Math.floor(time / 60);
        time -= minutes * 60
        var seconds = Math.floor(time);

        var finalTime = strPadLeft(hours, "0", 2) + ':' + strPadLeft(minutes,'0',2)+ ':' + strPadLeft(seconds,'0',2);
        return finalTime;
    }

    MouseArea
    {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons;

        onWheel:
        {
            wheel.accepted = true;
        }
    }

    // Printer selection and mode selection buttons for changing between Setting & Monitor print mode
    Rectangle{
        id:closeBtn
        height: 25
        width: parent.width
        //border.color:"grey"
        color: "lightgrey"
        Button{
            width:parent.height
            height:parent.height
            anchors.right:parent.right
            anchors.top:parent.top
            text:"X"
            onClicked:base.visible = false
        }
    }
    PrintSet1 {
        id: header
        width: parent.width

        anchors.top: closeBtn.bottom

        onShowTooltip: base.showTooltip(item, location, text)
        onHideTooltip: base.hideTooltip()
    }



    onCurrentModeIndexChanged:
    {
        UM.Preferences.setValue("cura/active_mode", currentModeIndex);
        if(modesListModel.count > base.currentModeIndex)
        {
            sidebarContents.push({ "item": modesListModel.get(base.currentModeIndex).item, "replace": true });
        }
    }

    StackView
    {
        id: sidebarContents

        anchors.bottom: footerSeparator.top
        anchors.top: settingsModeSelection.bottom
        anchors.left: base.left
        anchors.right: base.right
        visible: !monitoringPrint && !hideSettings

        delegate: StackViewDelegate
        {
            function transitionFinished(properties)
            {
                properties.exitItem.opacity = 1
            }

            pushTransition: StackViewTransition
            {
                PropertyAnimation
                {
                    target: enterItem
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: 100
                }
                PropertyAnimation
                {
                    target: exitItem
                    property: "opacity"
                    from: 1
                    to: 0
                    duration: 100
                }
            }
        }
    }

    Loader
    {
        anchors.bottom: footerSeparator.top
        anchors.top: headerSeparator.bottom
        anchors.left: base.left
        anchors.right: base.right
        source: monitoringPrint ? "PrintMonitor.qml": "SidebarContents.qml"
   }



    // SaveButton and MonitorButton are actually the bottom footer panels.
    // "!monitoringPrint" currently means "show-settings-mode"




    // Setting mode: Recommended or Custom

    PrintSet2
    {
        id: sidebarSimple;
        //visible: false;

        onShowTooltip: base.showTooltip(item, location, text)
        onHideTooltip: base.hideTooltip()
        anchors.top: header.bottom
        anchors.topMargin: UM.Theme.getSize("default_margin").height
    }
    Button
    {
        id:fullSettingBtn
        anchors.bottom:parent.bottom
        anchors.bottomMargin:6*UM.Theme.getSize("default_margin").height
        anchors.right:parent.right
        anchors.rightMargin: 30
        text:catalog.i18nc("@button","FULL SETTINGS")
        style: ButtonStyle {
                background: Rectangle
                {
                    color: UM.Theme.getColor("logocolor2")
                    implicitWidth: actualLabel.contentWidth + (UM.Theme.getSize("default_margin").width)
                    implicitHeight: actualLabel.contentHeight + (UM.Theme.getSize("default_margin").height)
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

        action: Cura.Actions.openFullSettings
    }


    Button{
        anchors.right:parent.right
        anchors.rightMargin: 20
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 2*UM.Theme.getSize("default_margin").height
        style: ButtonStyle {
                background: Rectangle
                {
                    color: UM.Theme.getColor("logocolor2")
                    implicitWidth: 2*actualLabel.contentWidth + 2*(UM.Theme.getSize("default_margin").width)
                    implicitHeight: actualLabel.contentHeight + (UM.Theme.getSize("default_margin").height)
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
        text:catalog.i18nc("@button","CANCEL")
        onClicked:base.visible = false
    }
    Button{
        anchors.left:parent.left
        anchors.leftMargin: 20
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 2*UM.Theme.getSize("default_margin").height
        property bool autoSlice

        onClicked:{
            backend.forceSlice()
            base.visible = false
            }

        style: ButtonStyle {
                background: Rectangle
                {
                    color: UM.Theme.getColor("logocolor2")
                    implicitWidth: actualLabel.contentWidth + (UM.Theme.getSize("default_margin").width)
                    implicitHeight: actualLabel.contentHeight + (UM.Theme.getSize("default_margin").height)
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
        text:catalog.i18nc("@button","START SLICING")
        //onClicked: backend.forceSlice();
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
        id: machineHeatedBed

        containerStackId: Cura.MachineManager.activeMachineId
        key: "machine_heated_bed"
        watchedProperties: [ "value" ]
        storeIndex: 0
    }
}