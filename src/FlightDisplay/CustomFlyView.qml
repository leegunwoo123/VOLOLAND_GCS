import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import QtMultimedia 6.8

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
    property bool droneVideoOnMap: false
    /// true면 확대창은 숨기고 mapHolder 위에 최소화 오버레이만 표시
    property bool expandWindowMinimized: false
    property bool stationVideoOnMap: false

    readonly property real _panelHorizontalMargins: 4

    /// 비디오 채널 목록(멀티화면 대비). url 없으면 설정 기본값 사용. 나중에 녹화/활성화 시 채널 단위 확장.
    property var _videoChannels: [{ label: qsTr("카메라"), enabled: true }]
    property string _defaultRtspUrl: String(QGroundControl.settingsManager.videoSettings.rtspUrl.rawValue || "").trim() || "rtsp://127.0.0.1:8554/live"
    readonly property string _primaryEffectiveRtspUrl: (_defaultRtspUrl === "") ? "" : (_defaultRtspUrl.indexOf("?") >= 0 ? _defaultRtspUrl + "&rtsp_transport=udp" : _defaultRtspUrl + "?rtsp_transport=udp")

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

            ColumnLayout {
                id: droneVideoHome
                Layout.fillWidth: true
                Layout.minimumWidth: root.width > 0 ? 350 : 0
                Layout.minimumHeight: 200
                Layout.preferredWidth: droneStatus.width
                Layout.preferredHeight: 200
                Layout.maximumWidth: 350 * 1.25
                Layout.maximumHeight: 200 * 1.25
                spacing: 2
                Repeater {
                    model: root._videoChannels
                    delegate: Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 200
                        Layout.minimumHeight: 120
                        DroneVideo {
                            anchors.fill: parent
                            deviceName: droneList.selectedDevice
                            mapOverlayMode: false
                            mapToggleEnabled: true
                            showExpandButton: (index === 0)
                            placeholderBlackMode: false
                            streamEnabled: modelData.enabled !== false
                            channelUrl: (modelData.url !== undefined && String(modelData.url).trim() !== "") ? modelData.url : root._defaultRtspUrl
                            channelLabel: modelData.label || ""
                            onToggleMapVideoRequested: if (index === 0) root.droneVideoOnMap = true
                        }
                    }
                }
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

        // 최소화 시 vehicleCurrentPostion 좌측 위 — 기체 연결 표시 + 삭제/확대 버튼만 (화면 미표시)
        Item {
            id: droneVideoMinimizedOverlay
            visible: root.droneVideoOnMap && root.expandWindowMinimized
            z: 15
            width: 220
            height: 32
            anchors.left: mapHolder.left
            anchors.leftMargin: 4
            anchors.bottom: vehicleCurrentPostion.top
            anchors.bottomMargin: 4

            Rectangle {
                anchors.fill: parent
                color: "#1a1a1a"
                border.color: "#3a3a3a"
                border.width: 1
                radius: 4
            }
            Text {
                id: minimizedDeviceLabel
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 8
                text: root.selectedDeviceName ? root.selectedDeviceName : qsTr("연결된 기체")
                color: "#e0e0e0"
                font.pixelSize: 12
                elide: Text.ElideRight
                width: parent.width - (8 + 8 + 36 + 36 + 8)
            }
            Rectangle {
                width: 32
                height: 24
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: expandMinimizedBtn.left
                anchors.rightMargin: 4
                color: deleteMinimizedBtn.containsMouse ? "#5a2a2a" : "transparent"
                radius: 2
                Text { anchors.centerIn: parent; text: "×"; color: "white"; font.pixelSize: 14 }
                MouseArea {
                    id: deleteMinimizedBtn
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: { root.droneVideoOnMap = false; root.expandWindowMinimized = false }
                }
            }
            Rectangle {
                id: expandMinimizedBtn
                width: 32
                height: 24
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: 4
                color: expandMinimizedBtnArea.containsMouse ? "#2f2f2f" : "transparent"
                radius: 2
                Text { anchors.centerIn: parent; text: "□"; color: "white"; font.pixelSize: 12 }
                MouseArea {
                    id: expandMinimizedBtnArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.expandWindowMinimized = false
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

    // 확대창: 기본 영상(DroneVideo)과 별도 MediaPlayer로 같은 URL 재생 — 기본 화면 + 확대창 둘 다 표시. 앱 밖(다른 모니터) 이동·Aero Snap 지원.
    Window {
        id: droneVideoExpandWindow
        visibility: (root.droneVideoOnMap && !root.expandWindowMinimized) ? (droneVideoExpandWindow._maximized ? Window.Maximized : Window.Windowed) : Window.Hidden
        width: 520
        height: 400
        x: droneVideoExpandWindow._winX
        y: droneVideoExpandWindow._winY
        flags: Qt.Window | Qt.FramelessWindowHint

        property real _winX: 0
        property real _winY: 0
        property bool _maximized: false

        onVisibilityChanged: {
            _maximized = (visibility === Window.Maximized)
            if (visibility === Window.Windowed)
                _winX = x; _winY = y
            if ((visibility === Window.Windowed || visibility === Window.Maximized) && expandWindowPlayer.source)
                expandWindowPlayer.play()
        }
        onXChanged: { if (visibility === Window.Windowed) _winX = x }
        onYChanged: { if (visibility === Window.Windowed) _winY = y }

        Item {
            id: expandWindowContent
            anchors.fill: parent
            signal requestMinimize()
            signal requestToggleMaximize()
            signal requestClose()

            Column {
                anchors.fill: parent
                spacing: 0
                Rectangle {
                    id: expandTopBar
                    width: parent.width
                    height: 32
                    color: "#222222"
                    border.width: 1
                    border.color: "#3a3a3a"
                    z: 1
                    readonly property real _buttonRowWidth: 36 + 36 + 40
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        text: qsTr("드론 비디오")
                        color: "white"
                        font.pixelSize: 12
                    }
                    MouseArea {
                        id: expandTitleDragArea
                        anchors.fill: parent
                        anchors.rightMargin: expandTopBar._buttonRowWidth
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        hoverEnabled: true
                        property point _pressPos: Qt.point(0, 0)
                        property bool _dragStarted: false
                        onPressed: (mouse) => {
                            if (mouse.button === Qt.LeftButton) {
                                _pressPos = Qt.point(mouse.x, mouse.y)
                                _dragStarted = false
                            } else if (mouse.button === Qt.RightButton) {
                                var rootPos = mapToItem(expandWindowContent, mouse.x, mouse.y)
                                var globalX = droneVideoExpandWindow.x + rootPos.x
                                var globalY = droneVideoExpandWindow.y + rootPos.y
                                WindowHelper.showSystemMenu(droneVideoExpandWindow, globalX, globalY)
                            }
                        }
                        onPositionChanged: (mouse) => {
                            if (mouse.buttons & Qt.LeftButton && !_dragStarted) {
                                var deltaX = Math.abs(mouse.x - _pressPos.x)
                                var deltaY = Math.abs(mouse.y - _pressPos.y)
                                if (deltaX > 5 || deltaY > 5) {
                                    _dragStarted = true
                                    if (droneVideoExpandWindow.visibility === Window.Windowed) {
                                        var rootPos = mapToItem(expandWindowContent, _pressPos.x, _pressPos.y)
                                        WindowHelper.startSystemMove(droneVideoExpandWindow, rootPos.x, rootPos.y)
                                    }
                                }
                            }
                        }
                        onReleased: (mouse) => {
                            if (_dragStarted && mouse.button === Qt.LeftButton) {
                                var rootPos = mapToItem(expandWindowContent, mouse.x, mouse.y)
                                var globalX = droneVideoExpandWindow.x + rootPos.x
                                var globalY = droneVideoExpandWindow.y + rootPos.y
                                WindowHelper.handleAeroSnap(droneVideoExpandWindow, globalX, globalY)
                            }
                            _dragStarted = false
                        }
                        onDoubleClicked: (mouse) => {
                            if (mouse.button === Qt.LeftButton)
                                WindowHelper.toggleMaximizeRestore(droneVideoExpandWindow)
                        }
                    }
                    Row {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2
                        height: expandTopBar.height
                        z: 2
                        Rectangle {
                            width: 36
                            height: expandTopBar.height
                            color: minBtnArea.containsMouse ? "#2f2f2f" : "transparent"
                            Text { anchors.centerIn: parent; text: "—"; color: "white"; font.pixelSize: 14 }
                            MouseArea {
                                id: minBtnArea
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: expandWindowContent.requestMinimize()
                            }
                        }
                        Rectangle {
                            width: 36
                            height: expandTopBar.height
                            color: maxBtnArea.containsMouse ? "#2f2f2f" : "transparent"
                            Text { anchors.centerIn: parent; text: "□"; color: "white"; font.pixelSize: 12 }
                            MouseArea {
                                id: maxBtnArea
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: expandWindowContent.requestToggleMaximize()
                            }
                        }
                        Rectangle {
                            width: 40
                            height: expandTopBar.height
                            color: closeBtnArea.containsMouse ? "#C42B1C" : "transparent"
                            Text { anchors.centerIn: parent; text: "×"; color: "white"; font.pixelSize: 16 }
                            MouseArea {
                                id: closeBtnArea
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: expandWindowContent.requestClose()
                            }
                        }
                    }
                }
                Item {
                    id: expandVideoArea
                    width: expandTopBar.width
                    height: expandWindowContent.height - expandTopBar.height
                    VideoOutput {
                        id: expandVideoOutput
                        anchors.fill: parent
                        fillMode: VideoOutput.PreserveAspectFit
                    }
                    MediaPlayer {
                        id: expandWindowPlayer
                        videoOutput: expandVideoOutput
                        source: root._primaryEffectiveRtspUrl
                        audioOutput: AudioOutput { muted: true }
                        onSourceChanged: if (source) play()
                    }
                }
            }
        }

        Connections {
            target: expandWindowContent
            function onRequestMinimize() { root.expandWindowMinimized = true }
            function onRequestToggleMaximize() { WindowHelper.toggleMaximizeRestore(droneVideoExpandWindow) }
            function onRequestClose() { root.droneVideoOnMap = false; root.expandWindowMinimized = false }
        }
    }

    Component.onCompleted: {
        if (root.droneVideoOnMap) {
            droneVideoExpandWindow._winX = (Screen.width - droneVideoExpandWindow.width) / 2
            droneVideoExpandWindow._winY = (Screen.height - droneVideoExpandWindow.height) / 2
        }
    }
    onDroneVideoOnMapChanged: {
        if (root.droneVideoOnMap) {
            root.expandWindowMinimized = false
            droneVideoExpandWindow._maximized = false
            droneVideoExpandWindow._winX = (Screen.width - droneVideoExpandWindow.width) / 2
            droneVideoExpandWindow._winY = (Screen.height - droneVideoExpandWindow.height) / 2
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
