// Copyright (c) 2015 Ultimaker B.V.
// Uranium is released under the terms of the AGPLv3 or higher.

import QtQuick 2.3
import QtQuick.Controls 1.2
import QtQuick.Controls.Styles 1.2
import QtQuick.Layouts 1.1
import QtQuick.Window 2.0
import QtQuick.Dialogs 1.2
import UM 1.2 as UM
import Cura 1.1 as Cura

UM.Dialog
{
    id: base;
    title:catalog.i18nc("@windowtitle","Full Settings")
    width: UM.Theme.getSize("fullsetting").width
    height: UM.Theme.getSize("fullsetting").height
    visible:false
    TabView {
        anchors.fill: parent
        anchors.margins: 8
        Tab {
            title: catalog.i18nc("@tabtitle","Quality")
            QualityTab{ }
        }
        Tab {
            title: catalog.i18nc("@tabtitle","Shell")
            ShellTab{ }
        }

        Tab {
            title: catalog.i18nc("@tabtitle","Infill")
            InfillTab{ }
        }
        Tab {
            title: catalog.i18nc("@tabtitle","Speed")
            SpeedTab{ }
        }
        Tab {
            title: catalog.i18nc("@tabtitle","Support")
            SupportTab{ }
        }
        Tab {
            title: catalog.i18nc("@tabtitle","Build Plate")
            BuildplateTab{ }
        }
        Tab {
            title: catalog.i18nc("@tabtitle","Retractions")
            RetractionTab{ }
        }
        Tab {
            title: catalog.i18nc("@tabtitle","Cooling")
            CoolingTab{ }
        }
        Tab {
            title: catalog.i18nc("@tabtitle","More..")
            MoreTab{ }
        }
    }
}