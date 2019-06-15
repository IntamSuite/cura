import QtQuick 2.2
import QtQuick.Controls 1.1
import QtQuick.Controls.Styles 1.1
import QtQuick.Layouts 1.1
import QtQuick.Dialogs 1.2

import UM 1.3 as UM
import Cura 1.1 as Cura

import "Menus"
import "Settings"

UM.MainWindow
{
    id: base
    title: catalog.i18nc("@title:window","INTAM-SUITE");
    viewportRect: Qt.rect(0, 0, 1.0, 1.0)

    Component.onCompleted:
    {
        Printer.setMinimumWindowSize(UM.Theme.getSize("window_minimum_size"))

        Cura.Actions.parent = backgroundItem
    }

    Item
    {
        id: backgroundItem;
        anchors.fill: parent;
        UM.I18nCatalog{id: catalog; name:"IntamSuite"}

        signal hasMesh(string name) //this signal sends the filebase name so it can be used for the JobSpecs.qml
        function getMeshName(path){
            //takes the path the complete path of the meshname and returns only the filebase
            var fileName = path.slice(path.lastIndexOf("/") + 1)
            var fileBase = fileName.slice(0, fileName.indexOf("."))
            return fileBase
        }

        //DeleteSelection on the keypress backspace event
        Keys.onPressed: {
            if (event.key == Qt.Key_Backspace)
            {
                Cura.Actions.deleteSelection.trigger()
            }
        }

        Rectangle{
            color: "white"
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.left: parent.left
            z:-1
            height:124
        }
         Rectangle{
            color: "white"
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.left: parent.left
            anchors.leftMargin:395
            height:30
            z:1
        }
        TabView{
            id:tabMenu
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.left: parent.left
            style: UM.Theme.styles.view_tab
            height: UM.Theme.getSize("sidebar").height;
            Tab{
                title: catalog.i18nc("@title:topleveltab","File")
                FileTab
                {
                    id: fileTab;
                }
            }
            Tab{
                title: catalog.i18nc("@title:topleveltab","Edit")
                EditTab
                {
                    id: editTab;
                    property int mouseX: base.mouseX
                    property int mouseY: base.mouseY
                }

            }
           Tab{
                title: catalog.i18nc("@title:topleveltab","View")
                ViewTab
                {
                    id: viewTab;
                }
            }
           Tab{
                title: catalog.i18nc("@title:topleveltab","Settings")
                SettingsTab
                {
                    id: settingsTab;
                }
           }
           Tab{
                title: catalog.i18nc("@title:topleveltab","Help")
                HelpTab
                {
                    id: helpTab;
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

        Item
        {
            id: contentItem;

            y: tabMenu.height
            width: parent.width;
            height: parent.height - tabMenu.height;

            Keys.forwardTo: tabMenu

            DropArea
            {
                anchors.fill: parent;
                onDropped:
                {
                    tabMenu.currentIndex=1
                    if (drop.urls.length > 0)
                    {
                        // Import models
                        var imported_model = -1;
                        for (var i in drop.urls)
                        {
                            // There is no endsWith in this version of JS...
                            if ((drop.urls[i].length <= 12) || (drop.urls[i].substring(drop.urls[i].length-12) !== ".curaprofile")) {
                                // Drop an object
                                Printer.readLocalFile(drop.urls[i]);
                                if (imported_model == -1)
                                {
                                    imported_model = i;
                                }
                            }
                        }

                        // Import profiles
                        var import_result = Cura.ContainerManager.importProfiles(drop.urls);
                        if (import_result.message !== "") {
                            messageDialog.text = import_result.message
                            if (import_result.status == "ok")
                            {
                                messageDialog.icon = StandardIcon.Information
                            }
                            else
                            {
                                messageDialog.icon = StandardIcon.Critical
                            }
                            messageDialog.open()
                        }
                        if (imported_model != -1)
                        {
                            var meshName = backgroundItem.getMeshName(drop.urls[imported_model].toString())
                            backgroundItem.hasMesh(decodeURIComponent(meshName))
                        }
                    }
                }
            }



            Rectangle
            {
                id:infoBox
                height:UM.Theme.getSize("info_Box").height;
                width:UM.Theme.getSize("info_Box").width;
                color:"lightgrey"
                anchors.right: parent.right
                anchors.verticalCenter:parent.verticalCenter


                SaveButton
                {
                    id: saveButton
                    implicitWidth: infoBox.width
                    implicitHeight: totalHeight
                    anchors.top: parent.top
                    anchors.topMargin:14*UM.Theme.getSize("default_margin").height
                }
                JobSpecs
                {
                    id: jobSpecs
                    anchors
                    {
                        bottom:saveButton.top
                        bottomMargin: 2*UM.Theme.getSize("default_margin").height;
                    }
                    implicitWidth: infoBox.width
                    implicitHeight: totalHeight
                }
            }

            Image
            {
                id: logo
                anchors
                {
                    left: parent.left
                    leftMargin: UM.Theme.getSize("default_margin").width;
                    bottom: parent.bottom
                    bottomMargin: UM.Theme.getSize("default_margin").height;
                }

                source: UM.Theme.getImage("logo");
                width: UM.Theme.getSize("logo").width;
                height: UM.Theme.getSize("logo").height;
                z: -1;

                sourceSize.width: width;
                sourceSize.height: height;
            }

            UM.MessageStack
            {
                anchors
                {
                    horizontalCenter: parent.horizontalCenter
                    //horizontalCenterOffset: -(UM.Theme.getSize("sidebar").width/ 2)
                    bottom: parent.bottom;
                }
            }
        }
    }

    WorkspaceSummaryDialog
    {
        id: saveWorkspaceDialog
        onYes: UM.OutputDeviceManager.requestWriteToDevice("local_file", PrintInformation.jobName, { "filter_by_machine": false, "file_type": "workspace" })
    }

    // BlurSettings is a way to force the focus away from any of the setting items.
    // We need to do this in order to keep the bindings intact.
    Connections
    {
        target: Cura.MachineManager
        onBlurSettings:
        {
            contentItem.forceActiveFocus()
        }
    }


    Menu
    {
        id: objectContextMenu;

        property variant objectId: -1;
        MenuItem { action: Cura.Actions.centerObject; }
        MenuItem { action: Cura.Actions.deleteObject; }
        MenuItem { action: Cura.Actions.multiplyObject; }
        MenuSeparator { }
        MenuItem { action: Cura.Actions.selectAll; }
        MenuItem { action: Cura.Actions.deleteAll; }
        MenuItem { action: Cura.Actions.reloadAll; }
        MenuItem { action: Cura.Actions.resetAllTranslation; }
        MenuItem { text: catalog.i18nc("@action:inmenu menubar:edit","Reset")
            action: Cura.Actions.resetAll; }
        MenuSeparator { }
        MenuItem { text:catalog.i18nc("@action:inmenu menubar:edit","Group")
            action: Cura.Actions.groupObjects; }
        MenuItem { text: catalog.i18nc("@action:inmenu menubar:edit","Merge Models")
            action: Cura.Actions.mergeObjects; }
        MenuItem { action: Cura.Actions.unGroupObjects; }

        Connections
        {
            target: Cura.Actions.deleteObject
            onTriggered:
            {
                if(objectContextMenu.objectId != 0)
                {
                    Printer.deleteObject(objectContextMenu.objectId);
                    objectContextMenu.objectId = 0;
                }
            }
        }

        MultiplyObjectOptions
        {
            id: multiplyObjectOptions
        }

        Connections
        {
            target: Cura.Actions.multiplyObject
            onTriggered:
            {
                if(objectContextMenu.objectId != 0)
                {
                    multiplyObjectOptions.objectId = objectContextMenu.objectId;
                    multiplyObjectOptions.visible = true;
                    multiplyObjectOptions.reset();
                    objectContextMenu.objectId = 0;
                }
            }
        }

        Connections
        {
            target: Cura.Actions.centerObject
            onTriggered:
            {
                if(objectContextMenu.objectId != 0)
                {
                    Printer.centerObject(objectContextMenu.objectId);
                    objectContextMenu.objectId = 0;
                }
            }
        }
    }

    Menu
    {
        id: contextMenu;
        MenuItem { action: Cura.Actions.selectAll; }
        MenuItem { action: Cura.Actions.deleteAll; }
        MenuItem { action: Cura.Actions.reloadAll; }
        MenuItem { action: Cura.Actions.resetAllTranslation; }
        MenuItem { text: catalog.i18nc("@action:inmenu menubar:edit","Reset")
            action: Cura.Actions.resetAll; }
        MenuSeparator { }
        MenuItem { text:catalog.i18nc("@action:inmenu menubar:edit","Group")
            action: Cura.Actions.groupObjects; }
        MenuItem { text: catalog.i18nc("@action:inmenu menubar:edit","Merge Models")
            action: Cura.Actions.mergeObjects; }
        MenuItem { action: Cura.Actions.unGroupObjects; }
    }

    Connections
    {
        target: UM.Controller
        onContextMenuRequested:
        {
            if(objectId == 0)
            {
                contextMenu.popup();
            } else
            {
                objectContextMenu.objectId = objectId;
                objectContextMenu.popup();
            }
        }
    }

    Connections
    {
        target: Cura.Actions.quit
        onTriggered: base.visible = false;
    }

    Connections
    {
        target: Cura.Actions.toggleFullScreen
        onTriggered: base.toggleFullscreen();
    }

    FileDialog
    {
        id: openDialog;

        //: File open dialog title
        title: catalog.i18nc("@title:window","Open file")
        modality: UM.Application.platform == "linux" ? Qt.NonModal : Qt.WindowModal;
        selectMultiple: true
        nameFilters: UM.MeshFileHandler.supportedReadFileTypes;
        folder: CuraApplication.getDefaultPath("dialog_load_path")
        onAccepted:
        {
            //Because several implementations of the file dialog only update the folder
            //when it is explicitly set.
            var f = folder;
            folder = f;

            CuraApplication.setDefaultPath("dialog_load_path", folder);

            for(var i in fileUrls)
            {
                Printer.readLocalFile(fileUrls[i])
            }

            var meshName = backgroundItem.getMeshName(fileUrls[0].toString())
            backgroundItem.hasMesh(decodeURIComponent(meshName))
        }
    }

    Connections
    {
        target: Cura.Actions.open
        onTriggered:
        {
            openDialog.open()
            tabMenu.currentIndex = 1
        }
    }

    FileDialog
    {
        id: openWorkspaceDialog;

        //: File open dialog title
        title: catalog.i18nc("@title:window","Open workspace")
        modality: UM.Application.platform == "linux" ? Qt.NonModal : Qt.WindowModal;
        selectMultiple: false
        nameFilters: UM.WorkspaceFileHandler.supportedReadFileTypes;
        folder: CuraApplication.getDefaultPath("dialog_load_path")
        onAccepted:
        {
            //Because several implementations of the file dialog only update the folder
            //when it is explicitly set.
            var f = folder;
            folder = f;

            CuraApplication.setDefaultPath("dialog_load_path", folder);

            for(var i in fileUrls)
            {
                UM.WorkspaceFileHandler.readLocalFile(fileUrls[i])
            }
            var meshName = backgroundItem.getMeshName(fileUrls[0].toString())
            backgroundItem.hasMesh(decodeURIComponent(meshName))
        }
    }

    Connections
    {
        target: Cura.Actions.loadWorkspace
        onTriggered: openWorkspaceDialog.open()
    }

    EngineLog
    {
        id: engineLog;
    }

    Connections
    {
        target: Cura.Actions.showProfileFolder
        onTriggered:
        {
            var path = UM.Resources.getPath(UM.Resources.Preferences, "");
            if(Qt.platform.os == "windows") {
                path = path.replace(/\\/g,"/");
            }
            Qt.openUrlExternally(path);
        }
    }

    AddMachineDialog
    {
        id: addMachineDialog
        onMachineAdded:
        {
            machineActionsWizard.firstRun = addMachineDialog.firstRun
            machineActionsWizard.start(id)
        }
    }

    // Dialog to handle first run machine actions
    UM.Wizard
    {
        id: machineActionsWizard;

        title: catalog.i18nc("@title:window", "Add Printer")
        property var machine;

        function start(id)
        {
            var actions =  Cura.MachineActionManager.getFirstStartActions(id)
            resetPages() // Remove previous pages

            for (var i = 0; i < actions.length; i++)
            {
                actions[i].displayItem.reset()
                machineActionsWizard.appendPage(actions[i].displayItem, catalog.i18nc("@title", actions[i].label));
            }

            //Only start if there are actions to perform.
            if (actions.length > 0)
            {
                machineActionsWizard.currentPage = 0;
                show()
            }
        }
    }

    MessageDialog
    {
        id: messageDialog
        modality: Qt.ApplicationModal
        onAccepted: Printer.messageBoxClosed(clickedButton)
        onApply: Printer.messageBoxClosed(clickedButton)
        onDiscard: Printer.messageBoxClosed(clickedButton)
        onHelp: Printer.messageBoxClosed(clickedButton)
        onNo: Printer.messageBoxClosed(clickedButton)
        onRejected: Printer.messageBoxClosed(clickedButton)
        onReset: Printer.messageBoxClosed(clickedButton)
        onYes: Printer.messageBoxClosed(clickedButton)
    }

    Connections
    {
        target: Printer
        onShowMessageBox:
        {
            messageDialog.title = title
            messageDialog.text = text
            messageDialog.informativeText = informativeText
            messageDialog.detailedText = detailedText
            messageDialog.standardButtons = buttons
            messageDialog.icon = icon
            messageDialog.visible = true
        }
    }

    DiscardOrKeepProfileChangesDialog
    {
        id: discardOrKeepProfileChangesDialog
    }

    Connections
    {
        target: Printer
        onShowDiscardOrKeepProfileChanges:
        {
            discardOrKeepProfileChangesDialog.show()
        }

    }

    Connections
    {
        target: Cura.Actions.addMachine
        onTriggered: addMachineDialog.visible = true;
    }

    AboutDialog
    {
        id: aboutDialog
    }

    Connections
    {
        target: Cura.Actions.about
        onTriggered: aboutDialog.visible = true;
    }

    SettingView
    {
        id: fullSettings
     }
     Connections
    {
        target: Cura.Actions.openFullSettings
        onTriggered: fullSettings.visible = true;
    }

    Connections
    {
        target: Printer
        onRequestAddPrinter:
        {
            addMachineDialog.visible = true
            addMachineDialog.firstRun = false
        }
    }

    Timer
    {
        id: startupTimer;
        interval: 100;
        repeat: false;
        running: true;
        onTriggered:
        {
            if(!base.visible)
            {
                base.visible = true;
                restart();
            }
            else if(Cura.MachineManager.activeMachineId == null || Cura.MachineManager.activeMachineId == "")
            {
                addMachineDialog.open();
            }
        }
    }
}

