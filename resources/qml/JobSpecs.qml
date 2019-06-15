// Copyright (c) 2015 Ultimaker B.V.
// Cura is released under the terms of the AGPLv3 or higher.

import QtQuick 2.2
import QtQuick.Controls 1.1
import QtQuick.Controls.Styles 1.1
import QtQuick.Layouts 1.1

import UM 1.1 as UM
import Cura 1.1 as Cura

Item {
    id: base

    property bool activity: Printer.platformActivity
    property string fileBaseName
    property variant activeMachineName: Cura.MachineManager.activeMachineName

    onActiveMachineNameChanged:
    {
        printJobTextfield.text = PrintInformation.createJobName(base.fileBaseName);
    }

    UM.I18nCatalog { id: catalog; name:"IntamSuite"}

    property variant printDuration: PrintInformation.currentPrintTime
    property variant printMaterialLengths: PrintInformation.materialLengths
    property variant printMaterialWeights: PrintInformation.materialWeights
    property variant printMaterialCosts: PrintInformation.materialCosts

    height: childrenRect.height

    Connections
    {
        target: backgroundItem
        onHasMesh:
        {
            base.fileBaseName = name
        }
    }

    onActivityChanged: {
        if (activity == true && base.fileBaseName == ''){
            //this only runs when you open a file from the terminal (or something that works the same way; for example when you drag a file on the icon in MacOS or use 'open with' on Windows)
            base.fileBaseName = PrintInformation.jobName; //get the fileBaseName from PrintInformation.py because this saves the filebase when the file is opened using the terminal (or something alike)
            printJobTextfield.text = PrintInformation.createJobName(base.fileBaseName);
        }
        if (activity == true && base.fileBaseName != ''){
            //this runs in all other cases where there is a mesh on the buildplate (activity == true). It uses the fileBaseName from the hasMesh signal
            printJobTextfield.text = PrintInformation.createJobName(base.fileBaseName);
        }
        if (activity == false){
            //When there is no mesh in the buildplate; the printJobTextField is set to an empty string so it doesn't set an empty string as a jobName (which is later used for saving the file)
            printJobTextfield.text = '';
            base.printMaterialLengths.length = 0
        }
    }
    Text
    {
        id:filenameTag
        anchors.left:parent.left
        anchors.leftMargin:UM.Theme.getSize("default_margin").width
        anchors.top:parent.top
        font: UM.Theme.getFont("default");
        text:catalog.i18nc("@label","File Name:")
        visible: base.activity
    }
    Rectangle
    {
        id: jobNameRow
        anchors.top: parent.top
        anchors.left: filenameTag.right
        anchors.leftMargin:20
        height: UM.Theme.getSize("jobspecs_line").height
        visible: base.activity

        Item
        {
            width: parent.width
            height: parent.height

            Button
            {
                id: printJobPencilIcon
                anchors.left: printJobTextfield.right
                anchors.verticalCenter: parent.verticalCenter
                width: UM.Theme.getSize("save_button_specs_icons").width
                height: UM.Theme.getSize("save_button_specs_icons").height

                onClicked:
                {
                    printJobTextfield.selectAll();
                    printJobTextfield.focus = true;
                }
                style: ButtonStyle
                {
                    background: Item
                    {
                        UM.RecolorImage
                        {
                            width: UM.Theme.getSize("save_button_specs_icons").width;
                            height: UM.Theme.getSize("save_button_specs_icons").height;
                            sourceSize.width: width;
                            sourceSize.height: width;
                            color: control.hovered ? UM.Theme.getColor("setting_control_button_hover") : UM.Theme.getColor("text");
                            source: UM.Theme.getIcon("pencil");
                        }
                    }
                }
            }

            TextField
            {
                id: printJobTextfield
                anchors.left: parent.left
                //anchors.leftMargin: UM.Theme.getSize("default_margin").width/2
                height: UM.Theme.getSize("jobspecs_line").height
                width: Math.max(__contentWidth + UM.Theme.getSize("default_margin").width, 50)
                maximumLength: 120
                property int unremovableSpacing: 5
                text: ''
                horizontalAlignment: TextInput.AlignRight
                onTextChanged: {
                    PrintInformation.setJobName(text);
                }
                onEditingFinished: {
                    if (printJobTextfield.text != ''){
                        printJobTextfield.focus = false;
                    }
                }
                validator: RegExpValidator {
                    regExp: /^[^\\ \/ \*\?\|\[\]]*$/
                }
                style: TextFieldStyle{
                    textColor: UM.Theme.getColor("setting_control_text");
                    font: UM.Theme.getFont("default");
                    background: Rectangle {
                        opacity: 0
                        border.width: 0
                    }
                }
            }
        }
    }
    Text
    {
        id:dimensionTag
        anchors.left:filenameTag.left
        anchors.top:jobNameRow.bottom
        anchors.topMargin:5
        font: UM.Theme.getFont("default");
        text:catalog.i18nc("@label","Dimension:")
        height: UM.Theme.getSize("jobspecs_line").height
        visible: base.activity
    }
    Label
    {
        id: boundingSpec
        anchors.top: jobNameRow.bottom
        anchors.topMargin:5
        anchors.left: jobNameRow.left
        anchors.leftMargin:5
        height: UM.Theme.getSize("jobspecs_line").height
        font: UM.Theme.getFont("small")
        color: UM.Theme.getColor("text_subtext")
        text: Printer.getSceneBoundingBoxString
        visible: base.activity
    }
    Text
    {
        id:timeTag
        anchors.left:filenameTag.left
        anchors.top:boundingSpec.bottom
        anchors.topMargin:5
        font: UM.Theme.getFont("default");
        text:catalog.i18nc("@label","Time:")
        height: UM.Theme.getSize("jobspecs_line").height
        visible: base.printMaterialLengths!=0 && activity == true
    }

    Label
    {
        id: timeSpec
        anchors.left: jobNameRow.left
        anchors.leftMargin:5
        anchors.top: boundingSpec.bottom
        anchors.topMargin:5
        font: UM.Theme.getFont("small")
        height: UM.Theme.getSize("jobspecs_line").height
        color: UM.Theme.getColor("text_subtext")
        text: (!base.printDuration || !base.printDuration.valid) ? catalog.i18nc("@label", "00h 00min") : base.printDuration.getDisplayString(UM.DurationFormat.Short)
        visible: base.printMaterialLengths!=0 && activity == true
    }
    Text
    {
        id:lengthTag
        anchors.left:filenameTag.left
        anchors.top:timeTag.bottom
        anchors.topMargin:5
        font: UM.Theme.getFont("default");
        text:catalog.i18nc("@label","Consumption:")
        visible: base.printMaterialLengths!=0 && activity == true
    }
    Label
    {
        id: lengthSpec
        anchors.left: jobNameRow.left
        anchors.leftMargin:5
        anchors.top: timeTag.bottom
        anchors.topMargin:5
        font: UM.Theme.getFont("small")
        color: UM.Theme.getColor("text_subtext")
        visible: base.printMaterialLengths!=0 && activity == true
        text:
        {
            var lengths = [];
            var weights = [];
            var costs = [];
            var someCostsKnown = false;
            if(base.printMaterialLengths) {
                for(var index = 0; index < base.printMaterialLengths.length; index++)
                {
                    if(base.printMaterialLengths[index] > 0)
                    {
                        lengths.push(base.printMaterialLengths[index].toFixed(2));
                        weights.push(String(Math.floor(base.printMaterialWeights[index])));
                        costs.push(base.printMaterialCosts[index].toFixed(2));
                        if(base.printMaterialCosts[index] > 0)
                        {
                            someCostsKnown = true;
                        }
                    }
                }
            }
            if(lengths.length == 0)
            {
                lengths = ["0.00"];
                weights = ["0"];
                costs = ["0.00"];
            }
            if(someCostsKnown)
            {
                return catalog.i18nc("@label", "%1 m / ~ %2 g / ~ %4 %3").arg(lengths.join(" + "))
                        .arg(weights.join(" + ")).arg(costs.join(" + ")).arg(UM.Preferences.getValue("cura/currency"));
            }
            else
            {
                return catalog.i18nc("@label", "%1 m / ~ %2 g").arg(lengths.join(" + ")).arg(weights.join(" + "));
            }
        }
    }
}

