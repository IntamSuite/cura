import QtQuick 2.0
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.1
import QtQuick.Controls.Styles 1.4

import UM 1.0 as UM
import Cura 1.1 as Cura

Item {
    id: base;

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
                style: UM.Theme.styles.tool_button
                iconSource: UM.Theme.getIcon("about")
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.bottom
                    anchors.topMargin: 5
                    color:"white"
                    text: catalog.i18nc("@action:inmenu menubar:help","About")
                    font: UM.Theme.getFont("default")
                }
                action: Cura.Actions.about
            }
        Button
            {
                style: UM.Theme.styles.tool_button
                iconSource: UM.Theme.getIcon("update")
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.bottom
                    anchors.topMargin: 5
                    color:"white"
                    text: catalog.i18nc("@action:inmenu menubar:help","Update")
                    font: UM.Theme.getFont("default")
                }
                action: Cura.Actions.updateCheck
            }
        Button
            {
                style: UM.Theme.styles.tool_button
                iconSource: UM.Theme.getIcon("contact")
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.bottom
                    anchors.topMargin: 5
                    color:"white"
                    text: catalog.i18nc("@action:inmenu menubar:help", "Contact")
                    font: UM.Theme.getFont("default")
                }
                action: Cura.Actions.contactUs
            }
        Button
            {
                style: UM.Theme.styles.tool_button
                iconSource: UM.Theme.getIcon("website")
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.bottom
                    anchors.topMargin: 5
                    color:"white"
                    text: catalog.i18nc("@action:inmenu menubar:help", "Website")
                    font: UM.Theme.getFont("default")
                }
                action: Cura.Actions.website
            }
        /*Button
            {
                style: UM.Theme.styles.tool_button
                iconSource: UM.Theme.getIcon("help")
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.bottom
                    anchors.topMargin: 5
                    color:"white"
                    text: catalog.i18nc("@action:inmenu menubar:help","Help Doc")
                    font: UM.Theme.getFont("default")
                }

            }
        */
    }

    ContactUs
    {
        id: contactUsDialog
    }

    Connections
    {
        target: Cura.Actions.contactUs
        onTriggered: contactUsDialog.visible = true;
    }

}
