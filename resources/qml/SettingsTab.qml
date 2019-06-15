import QtQuick 2.0
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.1
import QtQuick.Controls.Styles 1.4

import UM 1.0 as UM
import Cura 1.1 as Cura
import "Preferences"

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
            iconSource: UM.Theme.getIcon("software")
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.bottom
                anchors.topMargin: 5
                color:"white"
                text: catalog.i18nc("@title:tab","Software")
                font: UM.Theme.getFont("default")
            }
        action:Cura.Actions.preferences
        }

        Button
            {
                style: UM.Theme.styles.tool_button
                iconSource: UM.Theme.getIcon("printer")
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.bottom
                    anchors.topMargin: 5
                    color:"white"
                    text: catalog.i18nc("@title:tab","Printers")
                    font: UM.Theme.getFont("default")
                }
               action:Cura.Actions.configureMachines
            }

        Button
            {
                style: UM.Theme.styles.tool_button
                iconSource: UM.Theme.getIcon("material")
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.bottom
                    anchors.topMargin: 5
                    color:"white"
                    text: catalog.i18nc("@title:tab","Materials")
                    font: UM.Theme.getFont("default")
                }
            action:Cura.Actions.manageMaterials
            }

        Button
            {
                style: UM.Theme.styles.tool_button
                iconSource: UM.Theme.getIcon("profile")
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.bottom
                    anchors.topMargin: 5
                    color:"white"
                    text: catalog.i18nc("@title:tab","Profiles")
                    font: UM.Theme.getFont("default")
                }
            action:Cura.Actions.manageProfiles
            }
    }
    UM.PreferencesDialog
    {
        id: preferences

        Component.onCompleted:
        {
            //; Remove & re-add the general page as we want to use our own instead of uranium standard.
            removePage(0);
            insertPage(0, catalog.i18nc("@title:tab","Software"), Qt.resolvedUrl("Preferences/GeneralPage.qml"));
            removePage(1);
            insertPage(1, catalog.i18nc("@title:tab", "Printers"), Qt.resolvedUrl("Preferences/MachinesPage.qml"));

            insertPage(2, catalog.i18nc("@title:tab", "Materials"), Qt.resolvedUrl("Preferences/MaterialsPage.qml"));

            insertPage(3, catalog.i18nc("@title:tab", "Profiles"), Qt.resolvedUrl("Preferences/ProfilesPage.qml"));
        }
    }
    Connections
    {
        target: Cura.Actions.preferences
        onTriggered:
        {
            preferences.visible = true;
            preferences.setPage(0);
        }
    }

    Connections
    {
        target: Cura.Actions.configureMachines
        onTriggered:
        {
            preferences.visible = true;
            preferences.setPage(1);
        }
    }

    Connections
    {
        target: Cura.Actions.manageProfiles
        onTriggered:
        {
            preferences.visible = true;
            preferences.setPage(3);
        }
    }

    Connections
    {
        target: Cura.Actions.manageMaterials
        onTriggered:
        {
            preferences.visible = true;
            preferences.setPage(2)
        }
    }

    Timer
    {
        id: createProfileTimer
        repeat: false
        interval: 1

        onTriggered: preferences.getCurrentItem().createProfile()
    }

    // BlurSettings is a way to force the focus away from any of the setting items.
    // We need to do this in order to keep the bindings intact.
}
