// Copyright (c) 2015 Ultimaker B.V.
// Cura is released under the terms of the AGPLv3 or higher.

import QtQuick 2.2
import QtQuick.Controls 1.1
import QtQuick.Window 2.1

import UM 1.1 as UM

UM.Dialog
{
    id: base

    //: About dialog title
    title: catalog.i18nc("@title:window","About IntamSuite")

    minimumWidth: 450 * Screen.devicePixelRatio
    minimumHeight: 450 * Screen.devicePixelRatio
    width: minimumWidth
    height: minimumHeight

    Image
    {
        id: logo
        width: base.minimumWidth * 0.85
        height: width * (1/4.25)

        source: UM.Theme.getImage("logo")

        sourceSize.width: width
        sourceSize.height: height
        anchors.bottom: parent.bottom
        anchors.bottomMargin: (base.minimumWidth - width) / 2
        anchors.horizontalCenter: parent.horizontalCenter

        UM.I18nCatalog{id: catalog; name:"IntamSuite"}
    }

    Label
    {
        id: version

        text: "IntamSuite %1".arg(UM.Application.version)
        font: UM.Theme.getFont("large")
        anchors.right : logo.right
        anchors.top: logo.bottom
        anchors.topMargin: UM.Theme.getSize("default_margin").height / 2
    }

    Label
    {
        id: title
        width: parent.width

        //: About dialog application description
        text: catalog.i18nc("@label","About INTAMSYS")
        font: UM.Theme.getFont("about")
        wrapMode: Text.WordWrap
        anchors.top:parent.top
        anchors.topMargin: 2*UM.Theme.getSize("default_margin").height
    }
    Label
    {
        id: description
        width: parent.width

        //: About dialog application description
        text: catalog.i18nc("@label","INTAMSYS is an industrial 3D Printer manufacturer renowned for our ‘world’s most affordable’ PEEK 3D Printer, FUNMAT HT. The company is based out of Shanghai, China with manufacturing facilities in Shanghai, Nanjing, Dongguan. The company has a portfolio of 5 printers to suit varied needs of customers.")
        font: UM.Theme.getFont("about")
        wrapMode: Text.WordWrap
        anchors.top:title.bottom
        //anchors.top: version.bottom
        anchors.topMargin: 2*UM.Theme.getSize("default_margin").height
    }

    Label
    {
        id: creditsNotes
        width: parent.width

        //: About dialog application author note
        text: catalog.i18nc("@info:credit","Please visit www.intamsys.com to know more or email us at info@intamsys.com to reach out to us")
        font: UM.Theme.getFont("about")
        wrapMode: Text.WordWrap
        anchors.top: description.bottom
        anchors.topMargin: 4*UM.Theme.getSize("default_margin").height
    }

    rightButtons: Button
    {
        //: Close about dialog button
        id: closeButton
        text: catalog.i18nc("@action:button","Close");

        onClicked: base.visible = false;
    }
}

