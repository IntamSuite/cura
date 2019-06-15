import QtQuick 2.2
import QtQuick.Controls 1.4
import QtQuick.Controls.Styles 1.1
import QtQuick.Layouts 1.1
import QtQuick.Window 2.0
import QtQuick.Dialogs 1.2

import UM 1.1 as UM
import Cura 1.1 as Cura

Window{
    id:base
    title: catalog.i18nc("@title:window","Contact Us")
    height:500
    width:500
    Label{
        anchors.top:parent.top
        anchors.topMargin:10
        anchors.left:parent.left
        anchors.leftMargin: 30
        text:catalog.i18nc("@label","Please fill the form and our representative will contact you as soon as possible")
    }
    Label{
        id:nameLabel
        anchors.left:parent.left
        anchors.leftMargin: 20
        anchors.top:parent.top
        anchors.topMargin:45
        width:150

        text:catalog.i18nc("@label","Name:")
        font: UM.Theme.getFont("default")
    }
    Label{
        id:emailLabel
        anchors.left:nameLabel.left
        anchors.top:nameLabel.bottom
        anchors.topMargin:20
        width:150

        text:catalog.i18nc("@label","Email Id:")
        font: UM.Theme.getFont("default")
    }
    Label{
        id:phoneLabel
        anchors.left:nameLabel.left
        anchors.top:emailLabel.bottom
        anchors.topMargin:20
        width:150

        text:catalog.i18nc("@label","Phone Number:")
        font: UM.Theme.getFont("default")
    }
    Label{
        id:countryLabel
        anchors.left:nameLabel.left
        anchors.top:phoneLabel.bottom
        anchors.topMargin:20
        width:150

        text:catalog.i18nc("@label","Country:")
        font: UM.Theme.getFont("default")
    }
    Label{
        id:departmentLabel
        anchors.left:nameLabel.left
        anchors.top:countryLabel.bottom
        anchors.topMargin:20
        width:150

        text:catalog.i18nc("@label","Department:")
        font: UM.Theme.getFont("default")
    }

    TextField{
        id:name
        anchors.verticalCenter:nameLabel.verticalCenter
        anchors.left:nameLabel.right
        placeholderText: catalog.i18nc("@label","Enter your name")
        font: UM.Theme.getFont("default")
        width:200

    }
    TextField{
        id:email
        anchors.verticalCenter:emailLabel.verticalCenter
        anchors.left:nameLabel.right
        placeholderText: catalog.i18nc("@label","Enter your email address")
        font: UM.Theme.getFont("default")
        width:200
    }
    TextField{
        id:phone
        anchors.verticalCenter:phoneLabel.verticalCenter
        anchors.left:nameLabel.right
        placeholderText: catalog.i18nc("@label","Enter your phone number")
        font: UM.Theme.getFont("default")
        width:200
    }
    ComboBox{
        id:countryChoice
        anchors.verticalCenter:countryLabel.verticalCenter
        anchors.left:nameLabel.right
        width:200
        model : [catalog.i18nc("@list","China"),catalog.i18nc("@list","France"),catalog.i18nc("@list","India"),catalog.i18nc("@list","United Kingdom"),catalog.i18nc("@list","United State")]
        style: ComboBoxStyle {
                label: Text {
                    anchors.left: parent.left;
                    anchors.leftMargin: Theme.getSize("default_lining").width
                    anchors.right: downArrow.left;
                    anchors.rightMargin: Theme.getSize("default_lining").width;
                    anchors.verticalCenter: parent.verticalCenter;
                    text: control.currentText;
                    font: UM.Theme.getFont("default")
                    elide: Text.ElideRight;
                    verticalAlignment: Text.AlignVCenter;
                }
            }
    }
    ComboBox{
        id: departmentChoice
        anchors.verticalCenter:departmentLabel.verticalCenter
        anchors.left:nameLabel.right
        width:200
        model : [catalog.i18nc("@list","Technical Support"),catalog.i18nc("@list","3D Printer Sales"),catalog.i18nc("@list","3D Filament Sales"),catalog.i18nc("@list","IT"),catalog.i18nc("@list","Others")]
        style: ComboBoxStyle {
                label: Text {
                    anchors.left: parent.left;
                    anchors.leftMargin: Theme.getSize("default_lining").width
                    anchors.right: downArrow.left;
                    anchors.rightMargin: Theme.getSize("default_lining").width;
                    anchors.verticalCenter: parent.verticalCenter;
                    text: control.currentText;
                    font: UM.Theme.getFont("default")
                    elide: Text.ElideRight;
                    verticalAlignment: Text.AlignVCenter;
                }
            }
    }
    Item{
        visible: departmentChoice.currentText != catalog.i18nc("@list","Technical Support") && departmentChoice.currentText != catalog.i18nc("@list","IT")
        anchors.top:departmentChoice.bottom
        anchors.left:nameLabel.left
        height:120
        Label{
            id:messageLabel
            anchors.left:nameLabel.left
            anchors.top:parent.top
            anchors.topMargin:20
            width:150
            text:catalog.i18nc("@label","Message:")
            font: UM.Theme.getFont("default")
        }
        TextArea{
            id:message3
            anchors.top:messageLabel.top
            anchors.left:messageLabel.right
            font: UM.Theme.getFont("default")
            width:200
            height:100
            wrapMode : Text.Wrap
            text:catalog.i18nc("@label","Fill your message here")
        }

    }

    Item{
        id:techOption
        height: 265
        visible: departmentChoice.currentText == catalog.i18nc("@list","Technical Support")
        anchors.top:departmentChoice.bottom
        anchors.topMargin:20
        anchors.left:nameLabel.left
        Label{
            id:printLabel
            anchors.top:parent.top
            anchors.left:parent.left
            width:150
            text:catalog.i18nc("@label","Printer:")
            font: UM.Theme.getFont("default")
        }
        ComboBox{
            id:printerChoice
            anchors.verticalCenter:printLabel.verticalCenter
            anchors.left:printLabel.right
            width:200
            model : ["BESSEN","FUNMAT","FUNMAT HT","FUNMAT PRO"]
            style: ComboBoxStyle {
                label: Text {
                    anchors.left: parent.left;
                    anchors.leftMargin: Theme.getSize("default_lining").width
                    anchors.right: downArrow.left;
                    anchors.rightMargin: Theme.getSize("default_lining").width;
                    anchors.verticalCenter: parent.verticalCenter;
                    text: control.currentText;
                    font: UM.Theme.getFont("default")
                    elide: Text.ElideRight;
                    verticalAlignment: Text.AlignVCenter;
                }
            }
        }
        Label{
            id:gcodeLabel
            anchors.top:printLabel.bottom
            anchors.topMargin:20
            anchors.left:parent.left
            width:150
            text:catalog.i18nc("@label","Upload GCode:")
            font: UM.Theme.getFont("default")
        }
        Button{
            id:loadGcodeBtn
            anchors.verticalCenter:gcodeLabel.verticalCenter
            anchors.left:gcodeLabel.right
            width:100
            text:catalog.i18nc("@label","Upload")
            style: ButtonStyle {
                label: Text {
                    renderType: Text.NativeRendering
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                    font: UM.Theme.getFont("default")
                    text: control.text
                }
            }
            onClicked: fileDialog.open();
        }
        Label{
            id:loadGcodeLabel
            anchors.left:loadGcodeBtn.left
            anchors.top:loadGcodeBtn.bottom
            text:fileDialog.fileUrl
        }
        Label{
            id:settingLabel
            anchors.top:loadGcodeLabel.bottom
            anchors.topMargin:20
            anchors.left:parent.left
            width:150
            text:catalog.i18nc("@label","Upload Settings:")
            font: UM.Theme.getFont("default")

        }
        Button{
            id:attachmentBtn
            anchors.verticalCenter:settingLabel.verticalCenter
            anchors.left:settingLabel.right
            width:100
            text:catalog.i18nc("@label","Upload")
            style: ButtonStyle {
                label: Text {
                    renderType: Text.NativeRendering
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                    font: UM.Theme.getFont("default")
                    text: control.text
                }
            }
            onClicked: attachmentDialog.open();
        }
        Label{
            anchors.left:attachmentBtn.right
            anchors.verticalCenter:attachmentBtn.verticalCenter
            text:catalog.i18nc("@label","Please limit it to four files")
        }
        Label{
            anchors.left:attachmentBtn.left
            anchors.top:attachmentBtn.bottom
            text:attachmentDialog.fileUrls.length == 0? catalog.i18nc("@label","\nSelect all files at once if you want to upload multiple files"):attachmentDialog.fileUrls[0] + '\n'+ attachmentDialog.fileUrls[1] + '\n'+ attachmentDialog.fileUrls[2] + '\n'+ attachmentDialog.fileUrls[3]
        }
        Item{
            anchors.bottom:parent.bottom
            height:120
            Label{
                id:messageLabel1
                anchors.left:nameLabel.left
                anchors.top:parent.top
                anchors.topMargin:20
                width:150
                text:catalog.i18nc("@label","Message:")
                font: UM.Theme.getFont("default")
            }
            TextArea{
                id:message1
                anchors.top:messageLabel1.top
                anchors.left:messageLabel1.right
                font: UM.Theme.getFont("default")
                width:200
                height:100
                wrapMode : Text.Wrap
                text:catalog.i18nc("@label","Fill your message here")
            }

        }
    }

    Item{
        id:itOption
        height: 180
        visible: departmentChoice.currentText == catalog.i18nc("@list","IT")
        anchors.top:departmentChoice.bottom
        anchors.topMargin:20
        anchors.left:nameLabel.left
        Label{
            id:problemLabel
            anchors.top:parent.top
            anchors.left:parent.left
            width:150
            text:catalog.i18nc("@label","Upload Screenshots:")
            font: UM.Theme.getFont("default")
        }
        Button{
            id:attachmentBtn2
            anchors.verticalCenter:problemLabel.verticalCenter
            anchors.left:problemLabel.right
            width:100
            text:catalog.i18nc("@label","Upload")
            style: ButtonStyle {
                label: Text {
                    renderType: Text.NativeRendering
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                    font: UM.Theme.getFont("default")
                    text: control.text
                }
            }
        onClicked: attachment1Dialog.open();
        }
        Label{
            anchors.left:attachmentBtn2.right
            anchors.verticalCenter:attachmentBtn2.verticalCenter
            text:catalog.i18nc("@label","Please limit it to four files")
        }
        Label{
            anchors.left:attachmentBtn2.left
            anchors.top:attachmentBtn2.bottom
            //text:attachment1Dialog.fileUrls.length
            text:attachment1Dialog.fileUrls.length == 0? catalog.i18nc("@label","\nSelect all files at once if you want to upload multiple files") : attachment1Dialog.fileUrls[0] + '\n'+ attachment1Dialog.fileUrls[1] + '\n'+ attachment1Dialog.fileUrls[2] + '\n'+ attachment1Dialog.fileUrls[3]
        }
        Item{
            anchors.bottom:parent.bottom
            height:120
            Label{
                id:messageLabel2
                anchors.left:nameLabel.left
                anchors.top:parent.top
                anchors.topMargin:20
                width:150
                text:catalog.i18nc("@label","Message:")
                font: UM.Theme.getFont("default")
            }
            TextArea{
                id:message2
                anchors.top:messageLabel2.top
                anchors.left:messageLabel2.right
                font: UM.Theme.getFont("default")
                width:200
                height:100
                wrapMode : Text.Wrap
                text:catalog.i18nc("@label","Fill your message here")
            }

        }
    }

    Button{
        anchors.right:parent.right
        anchors.rightMargin: 20
        anchors.bottom: parent.bottom
        anchors.bottomMargin:20

        onClicked:{
            if (departmentChoice.currentText == catalog.i18nc("@list","IT"))
            {
                var context = 'Name:' + name.text + '\n' + 'Email:'+ email.text + '\n' + 'PhoneNumber:'+ phone.text + '\n' + 'Country:'+ countryChoice.currentText + '\n' + 'Department:'+ departmentChoice.currentText + '\n' + 'Message:' + message1.text + '\n'+ ','+ attachment1Dialog.fileUrls
            }
            if (departmentChoice.currentText == catalog.i18nc("@list","Technical Support"))
            {
                var context = 'Name:' + name.text + '\n' + 'Email:'+ email.text + '\n' + 'PhoneNumber:'+ phone.text + '\n' + 'Country:'+ countryChoice.currentText + '\n' + 'Department:'+ departmentChoice.currentText + '\n' + 'Printer:' + printerChoice.currentText+ '\n'+ 'Message:' + message1.text + '\n'+ fileDialog.fileUrls + ',' + attachmentDialog.fileUrls
            }
            if (departmentChoice.currentText != catalog.i18nc("@list","Technical Support") && departmentChoice.currentText != catalog.i18nc("@list","IT"))
            {
                var context = 'Name:' + name.text + '\n' + 'Email:'+ email.text + '\n' + 'PhoneNumber:'+ phone.text + '\n' + 'Country:'+ countryChoice.currentText + '\n' + 'Department:'+ departmentChoice.currentText + '\n' + 'Message:' + message3.text + '\n'+ ","
            }
            ContactUs.send_email(context)
            if(ContactUs.getResult())
            {
                base.visible = false
            }
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
        text:catalog.i18nc("@label","SEND")
    }
    FileDialog
    {
        id: fileDialog;

        title: catalog.i18nc("@title:window","Open file")
        folder: CuraApplication.getDefaultPath("dialog_load_path")
        onAccepted:
        {
            console.log("You chose: " + fileDialog.fileUrls)
        }
    }
    FileDialog
    {
        id: attachmentDialog;
        selectMultiple:true
        title: catalog.i18nc("@title:window","Open file")
        folder: CuraApplication.getDefaultPath("dialog_load_path")
        onAccepted:
        {
            console.log("You chose: " + attachmentDialog.fileUrls)
        }
    }
    FileDialog
    {
        id: attachment1Dialog;
        selectMultiple:true
        title: catalog.i18nc("@title:window","Open file")
        folder: CuraApplication.getDefaultPath("dialog_load_path")
        onAccepted:
        {
            console.log("You chose: " + attachment1Dialog.fileUrls)
        }
    }
}