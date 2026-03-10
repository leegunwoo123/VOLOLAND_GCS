import QtQuick 6.8
import QGroundControl.ScreenTools
import QtQuick.Controls 6.8
import QtMultimedia 6.8
import QGroundControl.Controls

Rectangle {
    id: videoRoot
    implicitWidth: 350
    implicitHeight: width * 0.75
    color: "#1a1a1a"
    border.color: "#333"
    radius: 4

    // [기존 프로퍼티 유지]
    property string deviceName: ""
    property var backend: null
    property bool mapOverlayMode: false
    property bool mapToggleEnabled: true
    property bool showExpandButton: true
    property bool placeholderBlackMode: false
    property bool streamEnabled: true
    /// 채널 단위 재생: 비어 있지 않으면 이 URL 사용(설정/backend 대신). 멀티화면 시 Repeater에서 채널별 전달.
    property string channelUrl: ""
    /// 채널 표시 이름(연결 중 문구 등). 비어 있으면 deviceName 또는 "카메라" 사용.
    property string channelLabel: ""

    signal toggleMapVideoRequested()
    signal requestPopupMinimize()
    signal requestPopupToggleMaximize()
    signal requestPopupClose()
    signal requestPopupMove(real dx, real dy)
    signal requestPopupStartSystemMove()

    readonly property color _controlBaseColor: "#66000000"
    readonly property color _controlHoverColor: "#88353535"
    readonly property color _controlPressedColor: "#AA2C7BE5"
    readonly property color _controlBorderColor: "#99ffffff"
    readonly property real _directionButtonSize: 32
    readonly property int _rightControlCount: 7
    readonly property real _rightControlSpacing: 6
    readonly property real _rightControlMargin: 8
    readonly property real _topOverlayMargin: 8
    readonly property real _popupTitleBarHeight: 32
    readonly property real _topOverlayHeight: mapOverlayMode ? 20 : (connectingStatusText.implicitHeight > 0 ? connectingStatusText.implicitHeight : 20)

    // 레이아웃 모순 해결: 현재 가시적인 상단 영역의 실제 높이를 계산
    readonly property real _topReservedHeight: {
        if (placeholderBlackMode) return 0
        if (mapOverlayMode) return _popupTitleBarHeight
        return (connectingStatusText.visible && connectingStatusText.text !== "") ? (connectingStatusText.y + connectingStatusText.height) : 0
    }
    
    readonly property real _rightRailTopInset: _topReservedHeight + _topOverlayMargin
    
    readonly property real _rightControlButtonSize: {
        let availableHeight = videoOutput.height - _rightRailTopInset - _rightControlMargin
        if (availableHeight <= 0) return 18
        let spacingTotal = _rightControlSpacing * (_rightControlCount - 1)
        return Math.max(18, Math.min(34, (availableHeight - spacingTotal) / _rightControlCount))
    }

    // 테스트 단계: backend/설정 없을 때 127.0.0.1:8554/live 고정 사용
    // 연결(RTSP 제어)은 TCP, 영상(RTP)은 UDP. FFmpeg 백엔드에 RTP 전송을 UDP로 명시.
    readonly property string rtspSource: (backend && backend.rtspUrl)
        ? backend.rtspUrl
        : (String(QGroundControl.settingsManager.videoSettings.rtspUrl.rawValue || "").trim() || "rtsp://127.0.0.1:8554/live")
    /// 채널 URL이 있으면 우선 사용, 없으면 rtspSource(설정/backend)
    readonly property string _channelOrDefaultUrl: (typeof channelUrl !== "undefined" && channelUrl && String(channelUrl).trim() !== "")
        ? String(channelUrl).trim()
        : rtspSource
    readonly property string _effectiveRtspSource: (_channelOrDefaultUrl === "")
        ? ""
        : (_channelOrDefaultUrl.indexOf("?") >= 0 ? (_channelOrDefaultUrl + "&rtsp_transport=udp") : (_channelOrDefaultUrl + "?rtsp_transport=udp"))

    function _teardownSession() {
        mediaPlayer.stop()
    }

    function _applySourceAndPlay() {
        if (!streamEnabled || !_channelOrDefaultUrl) return
        var connectingOrActive = (mediaPlayer.mediaStatus !== MediaPlayer.NoMedia &&
                                  mediaPlayer.mediaStatus !== MediaPlayer.InvalidMedia)
        if (connectingOrActive)
            _teardownSession()
        mediaPlayer.play()
    }

    onRtspSourceChanged: Qt.callLater(_applySourceAndPlay)
    onChannelUrlChanged: Qt.callLater(_applySourceAndPlay)
    onStreamEnabledChanged: streamEnabled ? Qt.callLater(_applySourceAndPlay) : _teardownSession()

    VideoOutput {
        id: videoOutput
        anchors.fill: parent
        anchors.margins: 2
        fillMode: VideoOutput.PreserveAspectFit
        visible: !videoRoot.placeholderBlackMode

        Rectangle {
            anchors.fill: parent
            color: "black"
            visible: mediaPlayer.mediaStatus < MediaPlayer.BufferedMedia
            z: 1
        }

        Item {
            id: cameraControls
            anchors.fill: parent
            z: 20
            visible: !videoRoot.placeholderBlackMode

            // 우측 컨트롤 레일
            Item {
                id: rightControlRail
                width: videoRoot._rightControlButtonSize + 6
                height: (videoRoot._rightControlButtonSize * videoRoot._rightControlCount) + (videoRoot._rightControlSpacing * (videoRoot._rightControlCount - 1))
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.topMargin: videoRoot._rightRailTopInset
                anchors.rightMargin: videoRoot._rightControlMargin

                Column {
                    anchors.centerIn: parent
                    spacing: videoRoot._rightControlSpacing
                    
                    Repeater {
                        model: [
                            { icon: "qrc:/qmlimages/crossHair.svg", action: null },
                            { icon: "qrc:/qmlimages/ZoomPlus.svg", action: null },
                            { icon: "qrc:/qmlimages/ZoomMinus.svg", action: null },
                            { icon: "qrc:/qmlimages/camera_video.svg", action: null },
                            { icon: "qrc:/qmlimages/camera_photo.svg", action: null },
                            { icon: "qrc:/qmlimages/PaperPlane.svg", action: null },
                            { icon: "qrc:/qmlimages/Gears.svg", action: () => streamingSettingsPopup.open() }
                        ]
                        RoundButton {
                            width: videoRoot._rightControlButtonSize
                            height: videoRoot._rightControlButtonSize
                            icon.source: modelData.icon
                            icon.color: "white"
                            icon.width: width * 0.58
                            icon.height: height * 0.58
                            display: AbstractButton.IconOnly
                            onClicked: if (modelData.action) modelData.action()
                            background: Rectangle {
                                radius: width / 2
                                color: parent.pressed ? videoRoot._controlPressedColor : (parent.hovered ? videoRoot._controlHoverColor : videoRoot._controlBaseColor)
                                border.color: videoRoot._controlBorderColor
                                border.width: 1
                            }
                        }
                    }
                }
            }

            // 짐벌 패드
            Item {
                id: gimbalPad
                anchors.fill: parent
                
                Repeater {
                    model: [
                        { t: "▲", isVert: true, offset: -0.3, side: "" },
                        { t: "◀", isVert: false, offset: 0, side: "left" },
                        { t: "▶", isVert: false, offset: 0, side: "right" },
                        { t: "▼", isVert: true, offset: 0.3, side: "" }
                    ]
                    RoundButton {
                        width: videoRoot._directionButtonSize
                        height: videoRoot._directionButtonSize
                        text: modelData.t
                        anchors.horizontalCenter: modelData.side === "" ? parent.horizontalCenter : undefined
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: modelData.side === "left" ? parent.left : undefined
                        anchors.right: modelData.side === "right" ? parent.right : undefined
                        anchors.leftMargin: modelData.side === "left" ? parent.width * 0.3 : 0
                        anchors.rightMargin: modelData.side === "right" ? parent.width * 0.3 : 0
                        anchors.verticalCenterOffset: modelData.isVert ? parent.height * modelData.offset : 0
                        
                        background: Item {}
                        contentItem: Text {
                            text: parent.text
                            anchors.centerIn: parent
                            color: parent.pressed ? "#cccccc" : "white"
                            font.pixelSize: 14
                        }
                        scale: pressed ? 0.92 : 1.0
                        Behavior on scale { NumberAnimation { duration: 90 } }
                    }
                }
            }
        }
    }

    Popup {
        id: streamingSettingsPopup
        parent: videoRoot
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent
        width: 190
        x: Math.max(8, videoOutput.x + rightControlRail.x - width - 8)
        y: Math.max(8, videoOutput.y + rightControlRail.y)
        padding: 10
        background: Rectangle {
            radius: 8
            color: "#CC202020"
            border.width: 1
            border.color: "#66ffffff"
        }
        contentItem: Column {
            spacing: 8
            Label { text: qsTr("스트리밍 설정"); color: "white"; font.pixelSize: 13 }
            ComboBox { width: parent.width; model: ["720p", "1080p"] }
            ComboBox { width: parent.width; model: ["24 FPS", "30 FPS", "60 FPS"] }
            ComboBox { width: parent.width; model: ["2 Mbps", "4 Mbps", "8 Mbps"] }
        }
    }

    // 상단 타이틀바 (Overlay 모드 전용)
    Rectangle {
        id: popupTopBar
        visible: videoRoot.mapOverlayMode && !videoRoot.placeholderBlackMode
        z: 5000
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: videoRoot._popupTitleBarHeight
        color: "#222222"
        border.width: 1
        border.color: "#3a3a3a"

        Text {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 10
            text: qsTr("드론 비디오")
            color: "white"
            font.pixelSize: 12
        }

        MouseArea {
            id: popupTitleDragArea
            anchors.fill: parent
            property point _pressPos: Qt.point(0, 0)
            property bool _dragStarted: false
            onPressed: (mouse) => {
                if (mouse.button === Qt.LeftButton) {
                    _pressPos = Qt.point(mouse.x, mouse.y)
                    _dragStarted = false
                }
            }
            onPositionChanged: (mouse) => {
                if (mouse.buttons & Qt.LeftButton && !_dragStarted) {
                    if (Math.abs(mouse.x - _pressPos.x) > 5 || Math.abs(mouse.y - _pressPos.y) > 5) {
                        _dragStarted = true
                        videoRoot.requestPopupStartSystemMove()
                    }
                }
            }
            onDoubleClicked: videoRoot.requestPopupToggleMaximize()
        }

        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            height: parent.height
            
            Repeater {
                model: [
                    { t: "—", c: "#2f2f2f", s: 14, f: () => videoRoot.requestPopupMinimize() },
                    { t: "□", c: "#2f2f2f", s: 12, f: () => videoRoot.requestPopupToggleMaximize() },
                    { t: "×", c: "#C42B1C", s: 16, f: () => videoRoot.requestPopupClose() }
                ]
                Rectangle {
                    width: index === 2 ? 40 : 36
                    height: popupTopBar.height
                    color: ma.containsMouse ? modelData.c : "transparent"
                    Text { anchors.centerIn: parent; text: modelData.t; color: "white"; font.pixelSize: modelData.s }
                    MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; onClicked: modelData.f() }
                }
            }
        }
    }

    readonly property bool _showConnectingState: mediaPlayer.mediaStatus !== MediaPlayer.BufferedMedia && mediaPlayer.mediaStatus !== MediaPlayer.LoadedMedia

    BusyIndicator {
        anchors.centerIn: parent
        visible: !videoRoot.placeholderBlackMode && videoRoot._showConnectingState
        running: visible
        z: 2
    }

    Text {
        id: connectingStatusText
        anchors.left: parent.left
        anchors.top: videoRoot.mapOverlayMode ? popupTopBar.bottom : parent.top
        anchors.margins: 8
        visible: !videoRoot.placeholderBlackMode && videoRoot._showConnectingState
        text: (channelLabel || deviceName || "카메라") + " 연결 확인 중..."
        color: "#aaa"
        font.pixelSize: 11
        z: 3
    }

    // 확대/맵 전환 버튼 (축소 상태에서만 표시)
    Item {
        id: expandMapButton
        anchors.right: parent.right
        anchors.top: videoRoot.mapOverlayMode ? popupTopBar.bottom : parent.top
        anchors.margins: videoRoot._topOverlayMargin
        width: videoRoot._topOverlayHeight
        height: videoRoot._topOverlayHeight
        visible: videoRoot.showExpandButton && !videoRoot.mapOverlayMode && !videoRoot.placeholderBlackMode
        enabled: videoRoot.mapToggleEnabled
        opacity: enabled ? 1.0 : 0.45
        z: 10
        QGCColoredImage {
            anchors.centerIn: parent
            width: parent.width * 0.9
            height: parent.height * 0.9
            source: "qrc:/qmlimages/ZoomPlus.svg"
            color: expandMapMouseArea.pressed ? "#cccccc" : "white"
        }
        MouseArea {
            id: expandMapMouseArea
            anchors.fill: parent
            onClicked: videoRoot.toggleMapVideoRequested()
        }
    }

    MediaPlayer {
        id: mediaPlayer
        videoOutput: videoOutput
        source: videoRoot._effectiveRtspSource
        audioOutput: AudioOutput { muted: true }
        onMediaStatusChanged: {
            if (mediaStatus === MediaPlayer.InvalidMedia || mediaStatus === MediaPlayer.NoMedia) {
                reconnectTimer.restart()
            } else if (mediaStatus === MediaPlayer.EndOfMedia) {
                endOfMediaRestartTimer.start()
            }
        }
        onErrorOccurred: (error, errorString) => reconnectTimer.start()
    }

    Timer { id: reconnectTimer; interval: 3000; onTriggered: _applySourceAndPlay() }
    Timer { id: endOfMediaRestartTimer; interval: 400; onTriggered: _applySourceAndPlay() }

    Component.onCompleted: Qt.callLater(_applySourceAndPlay)
}
