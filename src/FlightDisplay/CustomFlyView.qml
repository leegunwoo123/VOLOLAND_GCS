import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

import QGroundControl
import QGroundControl.Controllers
import QGroundControl.Controls
import QGroundControl.FactSystem
import QGroundControl.FlightDisplay
import QGroundControl.FlightMap
import QGroundControl.Palette
import QGroundControl.ScreenTools
import QGroundControl.Vehicle
import QGroundControl.Toolbar
// 3D Viewer modules
import Viewer3D

RowLayout {
    id: root
    // 부모가 Layout로 크기 지정되므로 anchors 사용 시 경고/미정의 동작 가능
    spacing: 0

    property bool planViewActive: false
    property var planMasterController: null
    readonly property var planController: planMasterController
    readonly property var guidedController: null
    readonly property string selectedDeviceName: droneList.selectedDevice
    /// 좌측 droneStatus 단일 소스 폭(두 모드 공통)
    readonly property real droneStatusTargetWidth: Math.round(Math.min(sidebarWidth, sidebarMaxWidth))
    /// MainWindow/CustomPlanView에서 참조하는 좌측 패널 폭(펼침 상태 기준)
    readonly property real leftPanelWidth: leftPanelVisible ? droneStatusTargetWidth : 0
    readonly property real sidebarWidth: mainWindow.width * 0.20
    readonly property real sidebarMaxWidth: 350 * 1.25

    property bool _cursorOverSidePanels: _cursorOverLeftPanel || _cursorOverRightPanel
    property bool _cursorOverLeftPanel: leftPanelHoverArea.containsMouse
    property bool _cursorOverRightPanel: rightPanelHoverArea.containsMouse
    property bool rightPanelStationVisible: true
    property bool leftPanelVisible: true

    readonly property real _panelHorizontalMargins: 4

    // 좌측: 드론 상태 (빈 영역 드래그 시 맵으로 이벤트 전달 방지)
    Item {
        id: leftPanelItem
        visible: root.width > 0
        Layout.fillWidth: false
        // 레이아웃에서 실제 점유폭(item width + 좌우 마진)이 항상 droneStatusTargetWidth가 되도록 맞춘다.
        Layout.preferredWidth: root.width > 0 ? (root.leftPanelVisible ? Math.max(0, root.droneStatusTargetWidth - root._panelHorizontalMargins) : 0) : 0
        Layout.minimumWidth: root.width > 0 ? (root.leftPanelVisible ? Math.max(0, 200 - root._panelHorizontalMargins) : 0) : 0
        Layout.maximumWidth: root.width > 0 ? (root.leftPanelVisible ? Math.max(0, root.sidebarMaxWidth - root._panelHorizontalMargins) : 0) : 0
        Layout.fillHeight: root.width > 0
        Layout.leftMargin: 2
        Layout.topMargin: 2
        Layout.bottomMargin: 2
        Layout.rightMargin: 2

        MouseArea {
            anchors.fill: parent
            z: -1
            acceptedButtons: Qt.AllButtons
            onPressed: (mouse) => { mouse.accepted = true }
            onReleased: (mouse) => { mouse.accepted = true }
            onWheel: (wheel) => { wheel.accepted = true }
        }

        // 접기/펼치기 버튼: 패널 우측 끝 상단 (맵 쪽 가장자리, 우측 패널 토글과 대칭)
        Rectangle {
            id: droneStatusToggleButton
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.rightMargin: 4
            anchors.topMargin: 4
            width: 20
            height: 20
            radius: width / 2
            color: root.leftPanelVisible ? "#252525" : "transparent"
            z: 1000

            QGCMouseArea {
                anchors.fill: parent
                onClicked: {
                    root.leftPanelVisible = !root.leftPanelVisible
                }
            }

            Text {
                anchors.centerIn: parent
                text: root.leftPanelVisible ? "◀" : "▶"
                color: "#ffffff"
                font.pixelSize: 12
            }
        }

        ColumnLayout {
            id: droneStatus
            anchors.fill: parent
            visible: root.leftPanelVisible
            spacing: 2

            DroneList {
                id:                     droneList
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumWidth: root.width > 0 ? 350 : 0
                Layout.minimumHeight: 300
                Layout.preferredWidth: parent.width
                Layout.maximumWidth: 350 * 1.25
                utmspSendActTrigger:    _utmspSendActTrigger
            }

            CustomHUDWidget{
                id: customHUDWidget
                Layout.fillWidth: true
                Layout.preferredWidth: droneStatus.width
                Layout.maximumWidth: 350 * 1.25
            }

            DroneVideo{

                id: droneVideo
                Layout.fillWidth: true
                Layout.minimumWidth: root.width > 0 ? 350 : 0
                Layout.minimumHeight: 200
                Layout.preferredWidth: droneStatus.width
                Layout.preferredHeight: Layout.preferredWidth * 0.75
                Layout.maximumWidth: 350 * 1.25
                Layout.maximumHeight: 200 * 1.25

                deviceName: droneList.selectedDevice
                //visible: droneList.selectedDevice !== ""
            }

            DroneStatusMessage{

                id: droneStatusMessage
                Layout.fillWidth: true
                Layout.minimumHeight: 100
                Layout.minimumWidth: root.width > 0 ? 350 : 0
                Layout.preferredWidth: droneStatus.width
                Layout.preferredHeight: Layout.preferredWidth * 0.35
                Layout.maximumWidth: 350 * 1.25
                Layout.maximumHeight: 100 * 1.25

                deviceName: droneList.selectedDevice
                //visible: droneList.selectedDevice !== ""
            }

            DroneControlPanel{
                id: controlPanel
                Layout.fillWidth: true
                // 실제 높이는 DroneControlPanel 내부에서 implicitHeight로 결정되므로,
                // 여기서는 그 값을 그대로 사용하고, 내부 id(droneControlButton)는 직접 참조하지 않는다.
                Layout.minimumHeight: controlPanel.implicitHeight
                Layout.minimumWidth: root.width > 0 ? 350 : 0
                Layout.preferredWidth: droneStatus.width
                Layout.preferredHeight: controlPanel.implicitHeight
                Layout.maximumWidth: 350 * 1.25
                Layout.maximumHeight: 300 * 1.25
                Layout.alignment: Qt.AlignBottom

                deviceName: droneList.selectedDevice
                // backend 연동은 아직 구현 전이므로 일단 null로 둔다.
                backend: null

                //visible: droneList.selectedDevice !== ""
            }
        }

        MouseArea {
            id: leftPanelHoverArea
            anchors.fill: parent
            z: 1
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
        }
    }

    Item {
        id: mapHolder
        Layout.fillWidth: !root.planViewActive
        Layout.fillHeight: !root.planViewActive
        // QML double 속성에는 undefined를 넣지 않고, 중앙 맵 칼럼 폭은 fillWidth/visible로만 제어한다.
        Layout.preferredWidth: 0
        Layout.minimumWidth:  0
        visible: !root.planViewActive

        QtObject {
            id: _flyToolInsets
            property real leftEdgeCenterInset: 0
            property real leftEdgeTopInset: 0
            property real leftEdgeBottomInset: 0
            property real rightEdgeCenterInset: 0
            property real rightEdgeTopInset: 0
            property real rightEdgeBottomInset: 0
            property real topEdgeCenterInset: 0
            property real topEdgeLeftInset: 0
            property real topEdgeRightInset: 0
            property real bottomEdgeCenterInset: 0
            property real bottomEdgeLeftInset: 0
            property real bottomEdgeRightInset: 0
        }
        Item {
            id: _pipView
            visible: false
        }
        FlyViewMap {
            id: mapControl
            anchors.fill: parent
            planMasterController: root.planMasterController
            rightPanelWidth: ScreenTools.defaultFontPixelHeight * 9
            pipView: _pipView
            pipMode: false
            toolInsets: _flyToolInsets
            mapName: "FlightDisplayView"
            enabled: !viewer3DWindow.isOpen && !root._cursorOverSidePanels
        }
        Viewer3D {
            id: viewer3DWindow
            anchors.fill: parent
        }
        // 접었을 때만 맵 좌측에 좌측 패널 펼치기 버튼 (배경 없음)
        QGCMouseArea {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.leftMargin: 4
            anchors.topMargin: 4
            width: 24
            height: 24
            visible: !root.planViewActive && !root.leftPanelVisible
            z: 1000
            onClicked: root.leftPanelVisible = true
            Item {
                anchors.centerIn: parent
                width: 24
                height: 24
                Text {
                    anchors.centerIn: parent
                    text: "▶"
                    color: "#ffffff"
                    font.pixelSize: 14
                }
            }
        }
        // 접었을 때만 맵 우측에 우측 패널 펼치기 버튼 (배경 없음)
        QGCMouseArea {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.rightMargin: 4
            anchors.topMargin: 4
            width: 24
            height: 24
            visible: !root.planViewActive && !root.rightPanelStationVisible
            z: 1000
            onClicked: root.rightPanelStationVisible = true
            Item {
                anchors.centerIn: parent
                width: 24
                height: 24
                Text {
                    anchors.centerIn: parent
                    text: "◀"
                    color: "#ffffff"
                    font.pixelSize: 14
                }
            }
        }

        Item {
            id: vehicleCurrentPostion
            anchors.left:   parent.left
            anchors.right:  parent.right
            anchors.bottom: parent.bottom
            height: ScreenTools.defaultFontPixelHeight * 4
            z: 10

            Rectangle {
                id: vehicleCurrentPostion_background
                anchors.fill: parent
                color: qgcPal.window
                opacity: 0.85
                radius: 4
                border.color: qgcPal.windowShade
                border.width: 1
            }

            Canvas {
                id: currentPositionVisual
                anchors.fill: parent
                anchors.margins: ScreenTools.defaultFontPointSize

                onTotalWpCountChanged: requestPaint()
                onCurrentWpIndexChanged: requestPaint()

                property int totalWpCount: 15
                property int currentWpIndex: 8

                onPaint: {
                    var ctx = getContext("2d");
                    ctx.clearRect(0, 0, width, height);

                    if (totalWpCount < 2) return;

                    var padding = 40;
                    var drawWidth = width - (padding * 2);
                    var centerY = height / 2 + 10;
                    var stepX = drawWidth / (totalWpCount - 1);

                    ctx.strokeStyle = qgcPal.text;
                    ctx.setLineDash([6, 4]);
                    ctx.lineWidth = 1.5;
                    ctx.beginPath();
                    ctx.moveTo(padding, centerY);
                    ctx.lineTo(width - padding, centerY);
                    ctx.stroke();
                    ctx.setLineDash([]);
                    ctx.font = ScreenTools.smallFontPointSize + "pt " + ScreenTools.normalFontFamily;
                    ctx.textAlign = "center";

                    for (var i = 0; i < totalWpCount; i++) {
                        var posX = padding + (i * stepX);
                        ctx.fillStyle = (i === currentWpIndex) ? "#E05E00" : qgcPal.text;
                        ctx.fillText(i + 1, posX, centerY - 15);

                        ctx.beginPath();
                        if (i === currentWpIndex) {
                            ctx.fillStyle = "#E05E00";
                            ctx.arc(posX, centerY, 7, 0, 2 * Math.PI);
                            ctx.fill();
                            ctx.strokeStyle = "white";
                            ctx.lineWidth = 2;
                            ctx.stroke();
                        } else {
                            ctx.fillStyle = "white";
                            ctx.arc(posX, centerY, 4, 0, 2 * Math.PI);
                            ctx.fill();
                        }
                    }
                }
            }
        }
    }

    Item {
        id: rightPanelItem
        visible: !root.planViewActive
        // 접었을 때는 너비 0 (배경 없음), 펼치기 버튼은 맵 위에 표시
        Layout.preferredWidth: root.planViewActive ? 0 : (root.rightPanelStationVisible ? Math.min(root.sidebarWidth, root.sidebarMaxWidth) : 0)
        Layout.minimumWidth: root.planViewActive ? 0 : (root.rightPanelStationVisible ? 200 : 0)
        Layout.maximumWidth: root.planViewActive ? 0 : (root.rightPanelStationVisible ? root.sidebarMaxWidth : 0)
        Layout.fillHeight: !root.planViewActive
        Layout.leftMargin: 2
        Layout.topMargin: 2
        Layout.bottomMargin: 2
        Layout.rightMargin: 2

        MouseArea {
            anchors.fill: parent
            z: -1
            acceptedButtons: Qt.AllButtons
            onPressed: (mouse) => { mouse.accepted = true }
            onReleased: (mouse) => { mouse.accepted = true }
            onWheel: (wheel) => { wheel.accepted = true }
        }

        // 접기/펼치기 버튼: 패널 좌측 끝 상단에 고정 (접었을 때도 스트립 안에 있음)
        Rectangle {
            id: stationStatusToggleButton
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.leftMargin: 4
            anchors.topMargin: 4
            width: 20
            height: 20
            radius: width / 2
            color: root.rightPanelStationVisible ? "#252525" : "transparent"
            z: 1000

            QGCMouseArea {
                anchors.fill: parent
                onClicked: {
                    root.rightPanelStationVisible = !root.rightPanelStationVisible
                }
            }

            Text {
                anchors.centerIn: parent
                text: root.rightPanelStationVisible ? "▶" : "◀"
                color: "#ffffff"
                font.pixelSize: 12
            }
        }

        // 우측: 스테이션 상태 (좌측 droneStatus와 동일 마진·너비·구조로 대칭)
        ColumnLayout {
            id: stationStatus
            anchors.fill: parent
            visible: root.rightPanelStationVisible
            spacing: 2

            StationList {
                id: stationList
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumWidth: root.width > 0 ? 350 : 0
                Layout.minimumHeight: 300
                Layout.preferredWidth: stationStatus.width
                Layout.maximumWidth: 350 * 1.25
            }

            CustomStationMetrics {
                id: customStationMetrics
                Layout.fillWidth: true
                Layout.preferredWidth: stationStatus.width
                Layout.maximumWidth: 350 * 1.25
            }

            StationVideo {
                id: stationVideo
                Layout.fillWidth: true
                Layout.minimumWidth: root.width > 0 ? 350 : 0
                Layout.minimumHeight: 200
                Layout.preferredWidth: stationStatus.width
                Layout.preferredHeight: Layout.preferredWidth * 0.75
                Layout.maximumWidth: 350 * 1.25
                Layout.maximumHeight: 200 * 1.25
                selectedStation: stationList.selectedStation
            }

            StationStatusMessage {
                id: stationStatusMessage
                Layout.fillWidth: true
                Layout.minimumHeight: 100
                Layout.minimumWidth: root.width > 0 ? 350 : 0
                Layout.preferredWidth: stationStatus.width
                Layout.preferredHeight: Layout.preferredWidth * 0.35
                Layout.maximumWidth: 350 * 1.25
                Layout.maximumHeight: 100 * 1.25
                selectedStation: stationList.selectedStation
            }

            StationControlPanel {
                id: stationControlPanel
                Layout.fillWidth: true
                Layout.minimumHeight: stationControlPanel.implicitHeight
                Layout.minimumWidth: root.width > 0 ? 350 : 0
                Layout.preferredWidth: stationStatus.width
                Layout.preferredHeight: stationControlPanel.implicitHeight
                Layout.maximumWidth: 350 * 1.25
                Layout.maximumHeight: 300 * 1.25
                Layout.alignment: Qt.AlignBottom
                selectedStation: stationList.selectedStation
            }
        }

        MouseArea {
            id: rightPanelHoverArea
            anchors.fill: parent
            z: 1
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
        }
    }
}

/*
Column {
    anchors.top: parent.top
    anchors.right: parent.right
    anchors.margins: 10
    spacing: 8
    z:9999

    Text {
        text: "Debug JSON Input"
        color: "white"
        font.pixelSize: 14
    }
    TextArea {
        id: debugJsonInput
        width: 500
        height: 170
        wrapMode: TextEdit.WrapAnywhere
        placeholderText: "{\"type\":\"list\",\"data\":[...]}"
    }

    Row {
        spacing: 8
        Button {
            text: "Inject"
            onClicked: droneManager.injectJsonText(debugJsonInput.text)
        }
        Button {
            text: "Clear"
            onClicked: debugJsonInput.text = ""
        }
    }
}*/
