import QtQuick 6.8
import QGroundControl
import QGroundControl.ScreenTools
import QtQuick.Controls 6.8
import QtMultimedia 6.8
import QGroundControl.Controls
import org.freedesktop.gstreamer.Qt6GLVideoItem

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
    /// true면 확대창 패스스루의 소스로 등록(메인 한 개만). CustomFlyView에서 index === 0 일 때 true.
    property bool isMainVideo: false
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
    readonly property int _bottomButtonCount: 6  // 확대(ZoomPlus) 제외
    readonly property real _bottomButtonSpacing: 6
    readonly property real _bottomBarHeight: 36
    readonly property real _bottomBarMargin: 6
    readonly property real _topOverlayMargin: 8
    readonly property real _popupTitleBarHeight: 32
    readonly property real _topOverlayHeight: mapOverlayMode ? 20 : (connectingStatusText.implicitHeight > 0 ? connectingStatusText.implicitHeight : 20)

    // 레이아웃: 하단 버튼바 높이만큼 비디오 하단 여백
    readonly property real _topReservedHeight: {
        if (placeholderBlackMode) return 0
        if (mapOverlayMode) return _popupTitleBarHeight
        return (connectingStatusText.visible && connectingStatusText.text !== "") ? (connectingStatusText.y + connectingStatusText.height) : 0
    }
    
    readonly property real _bottomButtonSize: Math.min(28, Math.max(22, (_bottomBarHeight - _bottomBarMargin * 2)))

    // 테스트 단계: backend/설정 없을 때 127.0.0.1:8554/live 고정 사용. QGroundControl 미로드 시(예: Toolbar만 로드) 기본 URL 사용.
    readonly property string rtspSource: (backend && backend.rtspUrl)
        ? backend.rtspUrl
        : (typeof QGroundControl !== "undefined" && QGroundControl.settingsManager && QGroundControl.settingsManager.videoSettings
            ? (String(QGroundControl.settingsManager.videoSettings.rtspUrl.rawValue || "").trim() || "rtsp://127.0.0.1:8554/live")
            : "rtsp://127.0.0.1:8554/live")
    /// 채널 URL이 있으면 우선 사용, 없으면 rtspSource(설정/backend)
    readonly property string _channelOrDefaultUrl: (typeof channelUrl !== "undefined" && channelUrl && String(channelUrl).trim() !== "")
        ? String(channelUrl).trim()
        : rtspSource
    /// rtsp:// 가 아닌 URL(udp:// 등)은 그대로. rtsp:// 이면 rtsp_transport 있으면 유지, 없으면 udp 추가.
    /// CustomFlyView에서 channelUrl에 이미 rtsp_transport=tcp 전달 시 TCP 유지(끊김 없음). 미전달 시 기본 udp.
    readonly property string _effectiveRtspSource: (_channelOrDefaultUrl === "")
        ? ""
        : (String(_channelOrDefaultUrl).indexOf("rtsp://") !== 0
            ? _channelOrDefaultUrl
            : (String(_channelOrDefaultUrl).indexOf("rtsp_transport=") >= 0
                ? _channelOrDefaultUrl
                : (_channelOrDefaultUrl.indexOf("?") >= 0 ? (_channelOrDefaultUrl + "&rtsp_transport=udp") : (_channelOrDefaultUrl + "?rtsp_transport=udp"))))
    /// 재연결 시 백엔드가 새 RTSP 세션을 열도록, 재생에 사용하는 소스(리셋 가능)
    property string _playbackSource: ""
    /// GStreamer 빌드에서 CustomRtspReceiver 사용(독립 파이프라인). VideoManager 미사용.
    readonly property bool useGStreamer: (typeof QGroundControl !== "undefined" && QGroundControl.videoManager && QGroundControl.videoManager.gstreamerEnabled && typeof CustomRtspReceiver !== "undefined")

    function _logVideo(msg) {
        var full = "[DroneVideo] " + msg
        if (typeof debugMessageModel !== "undefined" && debugMessageModel) {
            debugMessageModel.log(full)
            debugMessageModel.logToConsole(full)
        }
        console.warn("[DroneVideo]", msg)
    }

    function _teardownSession() {
        mediaPlayer.stop()
        _playbackSource = ""
    }

    function _mediaStatusString(s) {
        if (s === MediaPlayer.NoMedia) return "NoMedia"
        if (s === MediaPlayer.Loading) return "Loading"
        if (s === MediaPlayer.Loaded) return "Loaded"
        if (s === MediaPlayer.Stalled) return "Stalled"
        if (s === MediaPlayer.Buffering) return "Buffering"
        if (s === MediaPlayer.BufferedMedia) return "BufferedMedia"
        if (s === MediaPlayer.EndOfMedia) return "EndOfMedia"
        if (s === MediaPlayer.InvalidMedia) return "InvalidMedia"
        return "status=" + s
    }

    function _applySourceAndPlay() {
        if (videoRoot.useGStreamer) return
        if (!streamEnabled || !_channelOrDefaultUrl) {
            _playbackSource = ""
            return
        }
        _logVideo("play source: " + _effectiveRtspSource + " [transport=" + (_effectiveRtspSource.indexOf("rtsp_transport=tcp") >= 0 ? "tcp" : _effectiveRtspSource.indexOf("rtsp_transport=udp") >= 0 ? "udp" : "url-default") + "]")
        var connectingOrActive = (mediaPlayer.mediaStatus !== MediaPlayer.NoMedia &&
                                  mediaPlayer.mediaStatus !== MediaPlayer.InvalidMedia)
        if (connectingOrActive) {
            _teardownSession()
            _playbackSource = ""
            sourceResetRestartTimer.start()
            return
        }
        _playbackSource = _effectiveRtspSource
        mediaPlayer.play()
    }

    onRtspSourceChanged: Qt.callLater(_applySourceAndPlay)
    onChannelUrlChanged: Qt.callLater(_applySourceAndPlay)
    onStreamEnabledChanged: streamEnabled ? Qt.callLater(_applySourceAndPlay) : _teardownSession()

    // GStreamer 출력 (CustomRtspReceiver — VideoManager 미사용)
    Item {
        id: gstVideoArea
        anchors.fill: parent
        anchors.leftMargin: 1
        anchors.rightMargin: 1
        anchors.topMargin: 1
        anchors.bottomMargin: videoRoot.placeholderBlackMode ? 2 : videoRoot._bottomBarHeight
        visible: !videoRoot.placeholderBlackMode && videoRoot.useGStreamer
        z: 0
        GstGLQt6VideoItem {
            id: gstVideoItem
            anchors.fill: parent
            forceAspectRatio: false
        }
        Loader {
            active: videoRoot.useGStreamer
            anchors.fill: parent
            sourceComponent: Component {
                CustomRtspReceiver {
                    channelUrl: videoRoot._effectiveRtspSource
                    videoOutput: gstVideoItem
                    streamEnabled: videoRoot.streamEnabled
                }
            }
        }
    }

    VideoOutput {
        id: videoOutput
        anchors.fill: parent
        anchors.leftMargin: 1
        anchors.rightMargin: 1
        anchors.topMargin: 1
        anchors.bottomMargin: videoRoot.placeholderBlackMode ? 2 : videoRoot._bottomBarHeight
        fillMode: VideoOutput.PreserveAspectCrop
        visible: !videoRoot.placeholderBlackMode && !videoRoot.useGStreamer

        Rectangle {
            anchors.fill: parent
            color: "black"
            visible: mediaPlayer.mediaStatus < MediaPlayer.BufferedMedia
            z: 1
        }
    }

    Item {
        id: cameraControls
        anchors.fill: parent
        anchors.leftMargin: 1
        anchors.rightMargin: 1
        anchors.topMargin: 1
        anchors.bottomMargin: videoRoot.placeholderBlackMode ? 2 : videoRoot._bottomBarHeight
        z: 20
        visible: !videoRoot.placeholderBlackMode

        Item {
            id: gimbalPad
            anchors.fill: parent
            Repeater {
                model: [
                    { t: "▲", edge: "top" },
                    { t: "◀", edge: "left" },
                    { t: "▶", edge: "right" },
                    { t: "▼", edge: "bottom" }
                ]
                RoundButton {
                    width: videoRoot._directionButtonSize
                    height: videoRoot._directionButtonSize
                    text: modelData.t
                    anchors.horizontalCenter: (modelData.edge === "top" || modelData.edge === "bottom") ? parent.horizontalCenter : undefined
                    anchors.verticalCenter: (modelData.edge === "left" || modelData.edge === "right") ? parent.verticalCenter : undefined
                    anchors.left: modelData.edge === "left" ? parent.left : undefined
                    anchors.right: modelData.edge === "right" ? parent.right : undefined
                    anchors.top: modelData.edge === "top" ? parent.top : undefined
                    anchors.bottom: modelData.edge === "bottom" ? parent.bottom : undefined
                    anchors.leftMargin: modelData.edge === "left" ? 1 : 0
                    anchors.rightMargin: modelData.edge === "right" ? 1 : 0
                    anchors.topMargin: modelData.edge === "top" ? 1 : 0
                    anchors.bottomMargin: modelData.edge === "bottom" ? 1 : 0
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

    // 하단 버튼바 (확대 버튼 제외, 가로 정렬)
    Row {
        id: bottomButtonBar
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: videoRoot._bottomBarMargin
        spacing: videoRoot._bottomButtonSpacing
        layoutDirection: Qt.LeftToRight
        visible: !videoRoot.placeholderBlackMode

        Repeater {
            model: [
                { icon: "qrc:/qmlimages/crossHair.svg", action: null },
                { icon: "qrc:/qmlimages/ZoomMinus.svg", action: null },
                { icon: "qrc:/qmlimages/camera_video.svg", action: null },
                { icon: "qrc:/qmlimages/camera_photo.svg", action: null },
                { icon: "qrc:/qmlimages/PaperPlane.svg", action: null },
                { icon: "qrc:/qmlimages/Gears.svg", action: () => streamingSettingsPopup.open() }
            ]
            RoundButton {
                width: videoRoot._bottomButtonSize
                height: videoRoot._bottomButtonSize
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

    Popup {
        id: streamingSettingsPopup
        parent: videoRoot
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent
        width: 190
        x: Math.max(8, videoRoot.width - width - 8)
        y: Math.max(8, videoRoot.height - bottomButtonBar.height - videoRoot._bottomBarMargin * 2 - 8)
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

    readonly property bool _showConnectingState: videoRoot.useGStreamer ? false : (mediaPlayer.mediaStatus !== MediaPlayer.BufferedMedia && mediaPlayer.mediaStatus !== MediaPlayer.LoadedMedia)

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
        source: videoRoot.useGStreamer ? "" : videoRoot._playbackSource
        audioOutput: AudioOutput { muted: true }
        onMediaStatusChanged: {
            if (videoRoot.useGStreamer) return
            videoRoot._logVideo("mediaStatus: " + videoRoot._mediaStatusString(mediaStatus))
            if (mediaStatus === MediaPlayer.InvalidMedia || mediaStatus === MediaPlayer.NoMedia) {
                videoRoot._playbackSource = ""
                reconnectTimer.restart()
            } else if (mediaStatus === MediaPlayer.EndOfMedia) {
                endOfMediaRestartTimer.start()
            }
        }
        onErrorOccurred: (error, errorString) => {
            if (videoRoot.useGStreamer) return
            videoRoot._logVideo("error: " + error + " " + errorString + " source: " + videoRoot._effectiveRtspSource)
            videoRoot._playbackSource = ""
            reconnectTimer.start()
        }
    }

    Timer { id: reconnectTimer; interval: 3000; onTriggered: _applySourceAndPlay() }
    Timer { id: endOfMediaRestartTimer; interval: 400; onTriggered: _applySourceAndPlay() }
    Timer { id: sourceResetRestartTimer; interval: 200; repeat: false; onTriggered: () => { videoRoot._playbackSource = videoRoot._effectiveRtspSource; mediaPlayer.play() } }

    Component.onCompleted: {
        _logVideo("created, channelUrl=" + channelUrl + " streamEnabled=" + streamEnabled + " useGStreamer=" + videoRoot.useGStreamer)
        if (!videoRoot.useGStreamer) {
            Qt.callLater(_applySourceAndPlay)
            if (videoRoot.isMainVideo && typeof VideoPassthroughHelper !== "undefined")
                VideoPassthroughHelper.setSourceOutput(videoOutput)
        }
    }
}
