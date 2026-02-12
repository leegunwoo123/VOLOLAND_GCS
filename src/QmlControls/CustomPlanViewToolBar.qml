import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

import QGroundControl
import QGroundControl.Controls
import QGroundControl.Palette
import QGroundControl.MultiVehicleManager
import QGroundControl.ScreenTools
import QGroundControl.Controllers
import QGroundControl.Toolbar

Rectangle{

    id: root
    width: parent.width
    height: ScreenTools.toolbarHeight
    color:  qgcPal.toolbarBackground

    property var    planMasterController

    property real   _controllerProgressPct: planMasterController && planMasterController.missionController ? planMasterController.missionController.progressPct : 0

    RowLayout {
        id:                     viewButtonRow
        anchors.bottomMargin:   1
        anchors.top:            parent.top
        anchors.bottom:         parent.bottom
        spacing:                ScreenTools.defaultFontPixelWidth / 2

        QGCLabel {
            font.pointSize: ScreenTools.largeFontPointSize
            text:           "<"
        }

        QGCLabel {
            text:           qsTr("Return")
            font.pointSize: ScreenTools.largeFontPointSize
        }
    }

    QGCMouseArea {
        anchors.fill:   viewButtonRow
        onClicked:      mainWindow.showCustomFlyView()
    }


}
