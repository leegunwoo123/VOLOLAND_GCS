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
// 확대창 GStreamer 폴백용 (패스스루 소스 미설정 시)
import org.freedesktop.gstreamer.Qt6GLVideoItem

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
    property bool stationExpandWindowMinimized: false

    readonly property real _panelHorizontalMargins: 4

    /// true면 서버 장비 목록 기반 메인/멀티뷰 사용. false면 기존 QGC 단일 카메라 경로만 사용.
    property bool useServerEquipmentList: true

    /// 메인 비디오용 주소 (서버 모드 미선택/폴백 시). udp:// 또는 rtsp://
    readonly property string _mainVideoRtspUrl: "rtsp://127.0.0.1:8554/live"
    /// 메인 비디오 RTSP 전송 방식. rtsp:// 일 때만 사용. "tcp"(VLC) / "udp"
    /// 참고: Qt Multimedia FFmpeg 백엔드는 URL 쿼리의 rtsp_transport를 FFmpeg에 전달하지 않을 수 있음. 실제 전송은 백엔드 기본값(TCP 등)일 수 있음.
    readonly property string _mainVideoRtspTransport: "udp"

    /// 서버에서 받아올 장비 목록. 요소: { id, name, rtspUrl }. 로컬 테스트용 하드코딩 → 추후 API로 교체.
    property var _equipmentList: [
        { id: "local-1", name: qsTr("로컬 카메라 1"), rtspUrl: "rtsp://127.0.0.1:8554/live" },
        { id: "local-2", name: qsTr("로컬 카메라 2"), rtspUrl: "rtsp://127.0.0.1:8554/live" }
    ]
    /// 선택된 장비 인덱스 (0-based). -1이면 미선택. 로컬 테스트: 0번 선택.
    property int selectedEquipmentIndex: 0
    /// rtsp:// URL에 rtsp_transport가 없으면 _mainVideoRtspTransport 값으로 추가 (로컬 RTSP는 tcp가 안정적).
    function _mainVideoUrlWithTransport(url) {
        var u = String(url || "").trim()
        if (u.indexOf("rtsp://") !== 0 || u.indexOf("rtsp_transport=") >= 0) return u
        return u + (u.indexOf("?") >= 0 ? "&" : "?") + "rtsp_transport=" + root._mainVideoRtspTransport
    }
    /// 메인 비디오에 쓸 URL. 서버 모드+선택 시 해당 장비 rtspUrl, 아니면 _mainVideoRtspUrl. rtsp면 rtsp_transport 추가.
    readonly property string _effectiveMainVideoRtspUrl: (root.useServerEquipmentList && root.selectedEquipmentIndex >= 0 && root._equipmentList.length > root.selectedEquipmentIndex && root._equipmentList[root.selectedEquipmentIndex].rtspUrl)
        ? root._mainVideoUrlWithTransport(root._equipmentList[root.selectedEquipmentIndex].rtspUrl)
        : root._mainVideoUrlWithTransport(root._mainVideoRtspUrl)
    /// 메인 비디오에 쓸 라벨. 서버 모드+선택 시 해당 장비 name, 아니면 "카메라".
    readonly property string _effectiveMainVideoChannelLabel: (root.useServerEquipmentList && root.selectedEquipmentIndex >= 0 && root._equipmentList.length > root.selectedEquipmentIndex && root._equipmentList[root.selectedEquipmentIndex].name)
        ? String(root._equipmentList[root.selectedEquipmentIndex].name)
        : qsTr("카메라")

    /// 비디오 채널 목록(멀티화면 대비). url 없으면 설정 기본값 사용. useServerEquipmentList false일 때만 사용.
    property var _videoChannels: [{ label: qsTr("카메라"), enabled: true }]

    /// 스테이션 비디오용 장비 목록. 요소: { stationName, rtspUrl }. selectedStation과 매칭.
    property var _stationEquipmentList: [
        { stationName: "VLS-770C", rtspUrl: "rtsp://127.0.0.1:8554/live" },
        { stationName: "VLS-1300C", rtspUrl: "rtsp://127.0.0.1:8554/live" },
        { stationName: "VLS-450S", rtspUrl: "rtsp://127.0.0.1:8554/live" },
        { stationName: "VLS-400C", rtspUrl: "rtsp://127.0.0.1:8554/live" },
        { stationName: "THEO-3", rtspUrl: "rtsp://127.0.0.1:8554/live" }
    ]
    readonly property string _stationVideoDefaultUrl: "rtsp://127.0.0.1:8554/live"
    function _stationVideoUrlWithTransport(url) {
        var u = String(url || "").trim()
        if (u.indexOf("rtsp://") !== 0 || u.indexOf("rtsp_transport=") >= 0) return u
        return u + (u.indexOf("?") >= 0 ? "&" : "?") + "rtsp_transport=" + root._mainVideoRtspTransport
    }
    function _getEffectiveStationVideoRtspUrl() {
        var sel = (typeof stationList !== "undefined" && stationList) ? String(stationList.selectedStation || "").trim() : ""
        if (!sel) return root._stationVideoUrlWithTransport(root._stationVideoDefaultUrl)
        for (var i = 0; i < root._stationEquipmentList.length; i++) {
            if (root._stationEquipmentList[i].stationName === sel && root._stationEquipmentList[i].rtspUrl)
                return root._stationVideoUrlWithTransport(root._stationEquipmentList[i].rtspUrl)
        }
        return root._stationVideoUrlWithTransport(root._stationVideoDefaultUrl)
    }
    function _getEffectiveStationVideoChannelLabel() {
        var sel = (typeof stationList !== "undefined" && stationList) ? String(stationList.selectedStation || "").trim() : ""
        return sel || qsTr("카메라")
    }
    /// 스테이션 비디오 URL. selectedStation 매칭 시 해당 rtspUrl, 없으면 기본값.
    readonly property string _effectiveStationVideoRtspUrl: root._getEffectiveStationVideoRtspUrl()
    /// 스테이션 비디오 라벨. selectedStation 또는 "카메라".
    readonly property string _effectiveStationVideoChannelLabel: root._getEffectiveStationVideoChannelLabel()
    property string _defaultRtspUrl: String(QGroundControl.settingsManager.videoSettings.rtspUrl.rawValue || "").trim() || "rtsp://127.0.0.1:8554/live"
    readonly property string _primaryEffectiveRtspUrl: (_defaultRtspUrl === "") ? "" : (_defaultRtspUrl.indexOf("?") >= 0 ? _defaultRtspUrl + "&rtsp_transport=udp" : _defaultRtspUrl + "?rtsp_transport=udp")

    /// VideoManager::_initVideoReceiver가 findChild로 찾는 위젯 플레이스홀더. 표시는 DroneVideo 사용, 레이아웃/시각 무영향.
    Item {
        width: 0
        height: 0
        visible: false
        z: -1
        QGCVideoBackground {
            objectName: "videoContent"
            visible: false
            width: 1
            height: 1
            x: 0
            y: 0
        }
        QGCVideoBackground {
            objectName: "thermalVideo"
            visible: false
            width: 1
            height: 1
            x: 0
            y: 0
        }
    }

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
            spacing: 0

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
                /// DroneVideo 하단 버튼바(36px)까지 보이도록 비디오 비율(0.75) + 바 높이
                Layout.preferredHeight: droneStatus.width * 0.75 + 36
                Layout.maximumWidth: 350 * 1.25
                Layout.maximumHeight: (350 * 1.25) * 0.75 + 36
                spacing: 2
                Repeater {
                    model: root._videoChannels
                    delegate: Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: droneStatus.width * 0.75 + 36
                        Layout.minimumHeight: 120
                        DroneVideo {
                            anchors.fill: parent
                            deviceName: droneList.selectedDevice
                            mapOverlayMode: false
                            mapToggleEnabled: true
                            showExpandButton: (index === 0)
                            isMainVideo: (index === 0)
                            placeholderBlackMode: false
                            streamEnabled: modelData.enabled !== false
                            channelUrl: root._effectiveMainVideoRtspUrl
                            channelLabel: root._effectiveMainVideoChannelLabel
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

        // 스테이션 비디오 최소화 시: 하단 가로정렬. 드론 있으면 그 오른쪽, 없으면 좌측하단(드론과 동일)
        Item {
            id: stationVideoMinimizedOverlay
            visible: root.stationVideoOnMap && root.stationExpandWindowMinimized
            z: 15
            width: 220
            height: 32
            anchors.left: droneVideoMinimizedOverlay.visible ? droneVideoMinimizedOverlay.right : mapHolder.left
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
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 8
                text: (typeof stationList !== "undefined" && stationList && stationList.selectedStation) ? stationList.selectedStation : qsTr("스테이션")
                color: "#e0e0e0"
                font.pixelSize: 12
                elide: Text.ElideRight
                width: parent.width - (8 + 8 + 36 + 36 + 8)
            }
            Rectangle {
                width: 32
                height: 24
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: stationExpandMinimizedBtn.left
                anchors.rightMargin: 4
                color: stationDeleteMinimizedBtn.containsMouse ? "#5a2a2a" : "transparent"
                radius: 2
                Text { anchors.centerIn: parent; text: "×"; color: "white"; font.pixelSize: 14 }
                MouseArea {
                    id: stationDeleteMinimizedBtn
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: { root.stationVideoOnMap = false; root.stationExpandWindowMinimized = false }
                }
            }
            Rectangle {
                id: stationExpandMinimizedBtn
                width: 32
                height: 24
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: 4
                color: stationExpandMinimizedBtnArea.containsMouse ? "#2f2f2f" : "transparent"
                radius: 2
                Text { anchors.centerIn: parent; text: "□"; color: "white"; font.pixelSize: 12 }
                MouseArea {
                    id: stationExpandMinimizedBtnArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.stationExpandWindowMinimized = false
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
                Layout.preferredHeight: Layout.preferredWidth * 0.75 + 36
                Layout.maximumWidth: 350 * 1.25
                Layout.maximumHeight: (350 * 1.25) * 0.75 + 36
                selectedStation: stationList.selectedStation
                channelUrl: root._effectiveStationVideoRtspUrl
                channelLabel: root._effectiveStationVideoChannelLabel
                streamEnabled: true
                showExpandButton: true
                onToggleMapVideoRequested: root.stationVideoOnMap = true
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

    // 확대창: 메인 DroneVideo 패스스루 — 한 번 디코딩한 프레임만 전달. 동기화·멀티화면 확장에 유리.
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

        onVisibilityChanged: (newVisibility) => {
            _maximized = (newVisibility === Window.Maximized)
            if (newVisibility === Window.Windowed)
                _winX = x; _winY = y
            // 패스스루: 메인 소스가 등록된 뒤에만 보조 등록 → 메인 수신 전 확대창에 영상 나오는 현상 방지
            if (newVisibility === Window.Windowed || newVisibility === Window.Maximized) {
                if (typeof VideoPassthroughHelper !== "undefined" && VideoPassthroughHelper.isSourceSet())
                    VideoPassthroughHelper.addSecondaryOutput(expandVideoOutput)
            } else {
                if (typeof VideoPassthroughHelper !== "undefined")
                    VideoPassthroughHelper.removeSecondaryOutput(expandVideoOutput)
            }
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
                    /// GStreamer 사용 시 확대창은 전용 스트림 재생(패스스루 소스 없음). 조건 단순화: gstreamerEnabled이면 폴백 사용.
                    readonly property bool _expandUseGStreamerFallback: (typeof QGroundControl !== "undefined" && QGroundControl.videoManager && QGroundControl.videoManager.gstreamerEnabled && typeof CustomRtspReceiver !== "undefined")
                    readonly property bool _expandWindowVisible: (droneVideoExpandWindow.visibility === Window.Windowed || droneVideoExpandWindow.visibility === Window.Maximized)
                    Loader {
                        id: expandFallbackLoader
                        anchors.fill: parent
                        active: expandVideoArea._expandUseGStreamerFallback && expandVideoArea._expandWindowVisible
                        visible: active
                        z: 0
                        sourceComponent: Component {
                            Item {
                                width: expandVideoArea.width
                                height: expandVideoArea.height
                                Rectangle {
                                    anchors.fill: parent
                                    color: "black"
                                    z: -1
                                }
                                GstGLQt6VideoItem {
                                    id: expandGstVideo
                                    anchors.fill: parent
                                }
                                CustomRtspReceiver {
                                    channelUrl: expandVideoArea._expandChannelUrl
                                    videoOutput: expandGstVideo
                                    streamEnabled: true
                                }
                            }
                        }
                    }
                    readonly property string _expandChannelUrl: root._effectiveMainVideoRtspUrl
                    VideoOutput {
                        id: expandVideoOutput
                        anchors.fill: parent
                        fillMode: VideoOutput.PreserveAspectFit
                        z: 1
                        visible: !expandVideoArea._expandUseGStreamerFallback && (typeof VideoPassthroughHelper !== "undefined" && VideoPassthroughHelper.isSourceSet())
                    }
                    // GStreamer: 폴백이 동일 URL 재생. Qt Multimedia: VideoPassthroughHelper가 프레임 전달.
                }
            }

            // 확대창 테두리·모서리 드래그 리사이즈 (메인 윈도우와 동일)
            Item {
                id: expandWindowResizeLayer
                anchors.fill: parent
                z: 50
                visible: droneVideoExpandWindow.visibility === Window.Windowed

                property int _edgeSize: 5
                property int _cornerSize: 10

                MouseArea {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: expandWindowResizeLayer._edgeSize
                    cursorShape: Qt.SizeHorCursor
                    acceptedButtons: Qt.LeftButton
                    onPressed: (mouse) => {
                        if (mouse.button === Qt.LeftButton)
                            WindowHelper.startSystemResize(droneVideoExpandWindow, Qt.LeftEdge)
                    }
                }
                MouseArea {
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: expandWindowResizeLayer._edgeSize
                    cursorShape: Qt.SizeHorCursor
                    acceptedButtons: Qt.LeftButton
                    onPressed: (mouse) => {
                        if (mouse.button === Qt.LeftButton)
                            WindowHelper.startSystemResize(droneVideoExpandWindow, Qt.RightEdge)
                    }
                }
                MouseArea {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    height: expandWindowResizeLayer._edgeSize
                    cursorShape: Qt.SizeVerCursor
                    acceptedButtons: Qt.LeftButton
                    onPressed: (mouse) => {
                        if (mouse.button === Qt.LeftButton)
                            WindowHelper.startSystemResize(droneVideoExpandWindow, Qt.TopEdge)
                    }
                }
                MouseArea {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: expandWindowResizeLayer._edgeSize
                    cursorShape: Qt.SizeVerCursor
                    acceptedButtons: Qt.LeftButton
                    onPressed: (mouse) => {
                        if (mouse.button === Qt.LeftButton)
                            WindowHelper.startSystemResize(droneVideoExpandWindow, Qt.BottomEdge)
                    }
                }
                MouseArea {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    width: expandWindowResizeLayer._cornerSize
                    height: expandWindowResizeLayer._cornerSize
                    cursorShape: Qt.SizeFDiagCursor
                    acceptedButtons: Qt.LeftButton
                    onPressed: (mouse) => {
                        if (mouse.button === Qt.LeftButton)
                            WindowHelper.startSystemResize(droneVideoExpandWindow, Qt.TopEdge | Qt.LeftEdge)
                    }
                }
                MouseArea {
                    anchors.right: parent.right
                    anchors.top: parent.top
                    width: expandWindowResizeLayer._cornerSize
                    height: expandWindowResizeLayer._cornerSize
                    cursorShape: Qt.SizeBDiagCursor
                    acceptedButtons: Qt.LeftButton
                    onPressed: (mouse) => {
                        if (mouse.button === Qt.LeftButton)
                            WindowHelper.startSystemResize(droneVideoExpandWindow, Qt.TopEdge | Qt.RightEdge)
                    }
                }
                MouseArea {
                    anchors.left: parent.left
                    anchors.bottom: parent.bottom
                    width: expandWindowResizeLayer._cornerSize
                    height: expandWindowResizeLayer._cornerSize
                    cursorShape: Qt.SizeBDiagCursor
                    acceptedButtons: Qt.LeftButton
                    onPressed: (mouse) => {
                        if (mouse.button === Qt.LeftButton)
                            WindowHelper.startSystemResize(droneVideoExpandWindow, Qt.BottomEdge | Qt.LeftEdge)
                    }
                }
                MouseArea {
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    width: expandWindowResizeLayer._cornerSize
                    height: expandWindowResizeLayer._cornerSize
                    cursorShape: Qt.SizeFDiagCursor
                    acceptedButtons: Qt.LeftButton
                    onPressed: (mouse) => {
                        if (mouse.button === Qt.LeftButton)
                            WindowHelper.startSystemResize(droneVideoExpandWindow, Qt.BottomEdge | Qt.RightEdge)
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
        // 메인 소스가 나중에 등록되면, 이미 열려 있는 확대창을 보조로 등록
        Connections {
            target: typeof VideoPassthroughHelper !== "undefined" ? VideoPassthroughHelper : null
            function onSourceSet() {
                if (droneVideoExpandWindow.visibility === Window.Windowed || droneVideoExpandWindow.visibility === Window.Maximized)
                    VideoPassthroughHelper.addSecondaryOutput(expandVideoOutput)
            }
        }
    }

    // 확대창: 스테이션 비디오 (CustomRtspReceiver로 직접 스트림 재생)
    Window {
        id: stationVideoExpandWindow
        visibility: (root.stationVideoOnMap && !root.stationExpandWindowMinimized) ? (stationVideoExpandWindow._maximized ? Window.Maximized : Window.Windowed) : Window.Hidden
        width: 520
        height: 400
        x: stationVideoExpandWindow._winX
        y: stationVideoExpandWindow._winY
        flags: Qt.Window | Qt.FramelessWindowHint

        property real _winX: 0
        property real _winY: 0
        property bool _maximized: false

        onVisibilityChanged: (newVisibility) => {
            _maximized = (newVisibility === Window.Maximized)
            if (newVisibility === Window.Windowed)
                _winX = x; _winY = y
        }
        onXChanged: { if (visibility === Window.Windowed) _winX = x }
        onYChanged: { if (visibility === Window.Windowed) _winY = y }

        Item {
            id: stationExpandWindowContent
            anchors.fill: parent
            signal requestMinimize()
            signal requestToggleMaximize()
            signal requestClose()

            Column {
                anchors.fill: parent
                spacing: 0
                Rectangle {
                    id: stationExpandTopBar
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
                        text: qsTr("스테이션 비디오")
                        color: "white"
                        font.pixelSize: 12
                    }
                    MouseArea {
                        id: stationExpandTitleDragArea
                        anchors.fill: parent
                        anchors.rightMargin: stationExpandTopBar._buttonRowWidth
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        hoverEnabled: true
                        property point _pressPos: Qt.point(0, 0)
                        property bool _dragStarted: false
                        onPressed: (mouse) => {
                            if (mouse.button === Qt.LeftButton) {
                                _pressPos = Qt.point(mouse.x, mouse.y)
                                _dragStarted = false
                            } else if (mouse.button === Qt.RightButton) {
                                var rootPos = mapToItem(stationExpandWindowContent, mouse.x, mouse.y)
                                var globalX = stationVideoExpandWindow.x + rootPos.x
                                var globalY = stationVideoExpandWindow.y + rootPos.y
                                WindowHelper.showSystemMenu(stationVideoExpandWindow, globalX, globalY)
                            }
                        }
                        onPositionChanged: (mouse) => {
                            if (mouse.buttons & Qt.LeftButton && !_dragStarted) {
                                var deltaX = Math.abs(mouse.x - _pressPos.x)
                                var deltaY = Math.abs(mouse.y - _pressPos.y)
                                if (deltaX > 5 || deltaY > 5) {
                                    _dragStarted = true
                                    if (stationVideoExpandWindow.visibility === Window.Windowed) {
                                        var rootPos = mapToItem(stationExpandWindowContent, _pressPos.x, _pressPos.y)
                                        WindowHelper.startSystemMove(stationVideoExpandWindow, rootPos.x, rootPos.y)
                                    }
                                }
                            }
                        }
                        onReleased: (mouse) => {
                            if (_dragStarted && mouse.button === Qt.LeftButton) {
                                var rootPos = mapToItem(stationExpandWindowContent, mouse.x, mouse.y)
                                var globalX = stationVideoExpandWindow.x + rootPos.x
                                var globalY = stationVideoExpandWindow.y + rootPos.y
                                WindowHelper.handleAeroSnap(stationVideoExpandWindow, globalX, globalY)
                            }
                            _dragStarted = false
                        }
                        onDoubleClicked: (mouse) => {
                            if (mouse.button === Qt.LeftButton)
                                WindowHelper.toggleMaximizeRestore(stationVideoExpandWindow)
                        }
                    }
                    Row {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2
                        height: stationExpandTopBar.height
                        z: 2
                        Rectangle {
                            width: 36
                            height: stationExpandTopBar.height
                            color: stationMinBtnArea.containsMouse ? "#2f2f2f" : "transparent"
                            Text { anchors.centerIn: parent; text: "—"; color: "white"; font.pixelSize: 14 }
                            MouseArea {
                                id: stationMinBtnArea
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: stationExpandWindowContent.requestMinimize()
                            }
                        }
                        Rectangle {
                            width: 36
                            height: stationExpandTopBar.height
                            color: stationMaxBtnArea.containsMouse ? "#2f2f2f" : "transparent"
                            Text { anchors.centerIn: parent; text: "□"; color: "white"; font.pixelSize: 12 }
                            MouseArea {
                                id: stationMaxBtnArea
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: stationExpandWindowContent.requestToggleMaximize()
                            }
                        }
                        Rectangle {
                            width: 40
                            height: stationExpandTopBar.height
                            color: stationCloseBtnArea.containsMouse ? "#C42B1C" : "transparent"
                            Text { anchors.centerIn: parent; text: "×"; color: "white"; font.pixelSize: 16 }
                            MouseArea {
                                id: stationCloseBtnArea
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: stationExpandWindowContent.requestClose()
                            }
                        }
                    }
                }
                Item {
                    id: stationExpandVideoArea
                    width: stationExpandTopBar.width
                    height: stationExpandWindowContent.height - stationExpandTopBar.height
                    readonly property bool _expandUseGStreamer: (typeof QGroundControl !== "undefined" && QGroundControl.videoManager && QGroundControl.videoManager.gstreamerEnabled && typeof CustomRtspReceiver !== "undefined")
                    readonly property bool _expandWindowVisible: (stationVideoExpandWindow.visibility === Window.Windowed || stationVideoExpandWindow.visibility === Window.Maximized)
                    Loader {
                        anchors.fill: parent
                        active: stationExpandVideoArea._expandUseGStreamer && stationExpandVideoArea._expandWindowVisible
                        visible: active
                        z: 0
                        sourceComponent: Component {
                            Item {
                                width: stationExpandVideoArea.width
                                height: stationExpandVideoArea.height
                                Rectangle {
                                    anchors.fill: parent
                                    color: "black"
                                    z: -1
                                }
                                GstGLQt6VideoItem {
                                    id: stationExpandGstVideo
                                    anchors.fill: parent
                                }
                                CustomRtspReceiver {
                                    channelUrl: root._effectiveStationVideoRtspUrl
                                    videoOutput: stationExpandGstVideo
                                    streamEnabled: true
                                }
                            }
                        }
                    }
                    Rectangle {
                        anchors.fill: parent
                        color: "black"
                        visible: !stationExpandVideoArea._expandUseGStreamer
                        z: 0
                        Text {
                            anchors.centerIn: parent
                            text: qsTr("GStreamer 필요")
                            color: "#888"
                            font.pixelSize: 14
                        }
                    }
                }
            }

            Item {
                id: stationExpandWindowResizeLayer
                anchors.fill: parent
                z: 50
                visible: stationVideoExpandWindow.visibility === Window.Windowed

                property int _edgeSize: 5
                property int _cornerSize: 10

                MouseArea {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: stationExpandWindowResizeLayer._edgeSize
                    cursorShape: Qt.SizeHorCursor
                    acceptedButtons: Qt.LeftButton
                    onPressed: (mouse) => {
                        if (mouse.button === Qt.LeftButton)
                            WindowHelper.startSystemResize(stationVideoExpandWindow, Qt.LeftEdge)
                    }
                }
                MouseArea {
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: stationExpandWindowResizeLayer._edgeSize
                    cursorShape: Qt.SizeHorCursor
                    acceptedButtons: Qt.LeftButton
                    onPressed: (mouse) => {
                        if (mouse.button === Qt.LeftButton)
                            WindowHelper.startSystemResize(stationVideoExpandWindow, Qt.RightEdge)
                    }
                }
                MouseArea {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    height: stationExpandWindowResizeLayer._edgeSize
                    cursorShape: Qt.SizeVerCursor
                    acceptedButtons: Qt.LeftButton
                    onPressed: (mouse) => {
                        if (mouse.button === Qt.LeftButton)
                            WindowHelper.startSystemResize(stationVideoExpandWindow, Qt.TopEdge)
                    }
                }
                MouseArea {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: stationExpandWindowResizeLayer._edgeSize
                    cursorShape: Qt.SizeVerCursor
                    acceptedButtons: Qt.LeftButton
                    onPressed: (mouse) => {
                        if (mouse.button === Qt.LeftButton)
                            WindowHelper.startSystemResize(stationVideoExpandWindow, Qt.BottomEdge)
                    }
                }
                MouseArea {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    width: stationExpandWindowResizeLayer._cornerSize
                    height: stationExpandWindowResizeLayer._cornerSize
                    cursorShape: Qt.SizeFDiagCursor
                    acceptedButtons: Qt.LeftButton
                    onPressed: (mouse) => {
                        if (mouse.button === Qt.LeftButton)
                            WindowHelper.startSystemResize(stationVideoExpandWindow, Qt.TopEdge | Qt.LeftEdge)
                    }
                }
                MouseArea {
                    anchors.right: parent.right
                    anchors.top: parent.top
                    width: stationExpandWindowResizeLayer._cornerSize
                    height: stationExpandWindowResizeLayer._cornerSize
                    cursorShape: Qt.SizeBDiagCursor
                    acceptedButtons: Qt.LeftButton
                    onPressed: (mouse) => {
                        if (mouse.button === Qt.LeftButton)
                            WindowHelper.startSystemResize(stationVideoExpandWindow, Qt.TopEdge | Qt.RightEdge)
                    }
                }
                MouseArea {
                    anchors.left: parent.left
                    anchors.bottom: parent.bottom
                    width: stationExpandWindowResizeLayer._cornerSize
                    height: stationExpandWindowResizeLayer._cornerSize
                    cursorShape: Qt.SizeBDiagCursor
                    acceptedButtons: Qt.LeftButton
                    onPressed: (mouse) => {
                        if (mouse.button === Qt.LeftButton)
                            WindowHelper.startSystemResize(stationVideoExpandWindow, Qt.BottomEdge | Qt.LeftEdge)
                    }
                }
                MouseArea {
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    width: stationExpandWindowResizeLayer._cornerSize
                    height: stationExpandWindowResizeLayer._cornerSize
                    cursorShape: Qt.SizeFDiagCursor
                    acceptedButtons: Qt.LeftButton
                    onPressed: (mouse) => {
                        if (mouse.button === Qt.LeftButton)
                            WindowHelper.startSystemResize(stationVideoExpandWindow, Qt.BottomEdge | Qt.RightEdge)
                    }
                }
            }
        }

        Connections {
            target: stationExpandWindowContent
            function onRequestMinimize() { root.stationExpandWindowMinimized = true }
            function onRequestToggleMaximize() { WindowHelper.toggleMaximizeRestore(stationVideoExpandWindow) }
            function onRequestClose() { root.stationVideoOnMap = false; root.stationExpandWindowMinimized = false }
        }
    }

    Component.onCompleted: {
        if (root.droneVideoOnMap) {
            droneVideoExpandWindow._winX = (Screen.width - droneVideoExpandWindow.width) / 2
            droneVideoExpandWindow._winY = (Screen.height - droneVideoExpandWindow.height) / 2
        }
        if (root.stationVideoOnMap) {
            stationVideoExpandWindow._winX = (Screen.width - stationVideoExpandWindow.width) / 2
            stationVideoExpandWindow._winY = (Screen.height - stationVideoExpandWindow.height) / 2
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
    onStationVideoOnMapChanged: {
        if (root.stationVideoOnMap) {
            root.stationExpandWindowMinimized = false
            stationVideoExpandWindow._maximized = false
            stationVideoExpandWindow._winX = (Screen.width - stationVideoExpandWindow.width) / 2
            stationVideoExpandWindow._winY = (Screen.height - stationVideoExpandWindow.height) / 2
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
