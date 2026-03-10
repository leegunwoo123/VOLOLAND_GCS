import QtQuick 6.8
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

    property string selectedStation: ""
    property var backend: null
    readonly property color _controlBaseColor: "#66000000"
    readonly property color _controlHoverColor: "#88353535"
    readonly property color _controlPressedColor: "#AA2C7BE5"
    readonly property color _controlBorderColor: "#99ffffff"
    readonly property real _directionButtonSize: 32
    readonly property int _rightControlCount: 6
    readonly property real _rightControlSpacing: 6
    readonly property real _rightControlMargin: 8
    readonly property real _rightControlButtonSize: Math.max(22, Math.min(34,
        (videoOutput.height - (_rightControlMargin * 2) - (_rightControlSpacing * (_rightControlCount - 1))) / _rightControlCount))

    // 테스트: 기체가 아닌 로컬 스트림 사용 시 기본값 127.0.0.1:8554/live
    readonly property string rtspSource: (backend && backend.rtspUrl) ?
                                              backend.rtspUrl :
                                              "rtsp://127.0.0.1:82554/live"

    /// 연결중/대기중인 세션을 닫음 (새 연결 전 호출)
    function _teardownSession() {
        mediaPlayer.stop()
    }

    /// 소스가 유효할 때만 세션 정리 후 재생 (연결중이면 먼저 세션 닫기)
    function _applySourceAndPlay() {
        if (!rtspSource)
            return
        var status = mediaPlayer.mediaStatus
        var connectingOrActive = (status !== MediaPlayer.NoMedia && status !== MediaPlayer.InvalidMedia)
        if (connectingOrActive)
            _teardownSession()
        mediaPlayer.play()
    }

    onRtspSourceChanged: Qt.callLater(_applySourceAndPlay)

    VideoOutput {
        id: videoOutput
        anchors.fill: parent
        anchors.margins: 2
        fillMode: VideoOutput.PreserveAspectFit

        Rectangle {
            anchors.fill: parent
            color: "black"
            visible: mediaPlayer.mediaStatus < MediaPlayer.BufferedMedia
        }

        Item {
            id: cameraControls
            anchors.fill: parent
            z: 20

            Item {
                id: rightControlRail
                width: videoRoot._rightControlButtonSize + 6
                height: Math.min(parent.height - (videoRoot._rightControlMargin * 2),
                                 (videoRoot._rightControlButtonSize * videoRoot._rightControlCount) +
                                 (videoRoot._rightControlSpacing * (videoRoot._rightControlCount - 1)))
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.rightMargin: videoRoot._rightControlMargin
                z: 21

                Column {
                    anchors.centerIn: parent
                    spacing: videoRoot._rightControlSpacing

                    RoundButton {
                        width: videoRoot._rightControlButtonSize
                        height: videoRoot._rightControlButtonSize
                        icon.source: "qrc:/qmlimages/crossHair.svg"
                        icon.color: "white"
                        icon.width: width * 0.58
                        icon.height: height * 0.58
                        display: AbstractButton.IconOnly
                        background: Rectangle {
                            radius: width / 2
                            color: parent.pressed ? videoRoot._controlPressedColor
                                                  : (parent.hovered ? videoRoot._controlHoverColor : videoRoot._controlBaseColor)
                            border.color: videoRoot._controlBorderColor
                            border.width: 1
                        }
                    }

                    RoundButton {
                        width: videoRoot._rightControlButtonSize
                        height: videoRoot._rightControlButtonSize
                        icon.source: "qrc:/qmlimages/ZoomPlus.svg"
                        icon.color: "white"
                        icon.width: width * 0.58
                        icon.height: height * 0.58
                        display: AbstractButton.IconOnly
                        background: Rectangle {
                            radius: width / 2
                            color: parent.pressed ? videoRoot._controlPressedColor
                                                  : (parent.hovered ? videoRoot._controlHoverColor : videoRoot._controlBaseColor)
                            border.color: videoRoot._controlBorderColor
                            border.width: 1
                        }
                    }

                    RoundButton {
                        width: videoRoot._rightControlButtonSize
                        height: videoRoot._rightControlButtonSize
                        icon.source: "qrc:/qmlimages/ZoomMinus.svg"
                        icon.color: "white"
                        icon.width: width * 0.58
                        icon.height: height * 0.58
                        display: AbstractButton.IconOnly
                        background: Rectangle {
                            radius: width / 2
                            color: parent.pressed ? videoRoot._controlPressedColor
                                                  : (parent.hovered ? videoRoot._controlHoverColor : videoRoot._controlBaseColor)
                            border.color: videoRoot._controlBorderColor
                            border.width: 1
                        }
                    }

                    RoundButton {
                        width: videoRoot._rightControlButtonSize
                        height: videoRoot._rightControlButtonSize
                        icon.source: "qrc:/qmlimages/camera_video.svg"
                        icon.color: "white"
                        icon.width: width * 0.58
                        icon.height: height * 0.58
                        display: AbstractButton.IconOnly
                        background: Rectangle {
                            radius: width / 2
                            color: parent.pressed ? videoRoot._controlPressedColor
                                                  : (parent.hovered ? videoRoot._controlHoverColor : videoRoot._controlBaseColor)
                            border.color: videoRoot._controlBorderColor
                            border.width: 1
                        }
                    }

                    RoundButton {
                        width: videoRoot._rightControlButtonSize
                        height: videoRoot._rightControlButtonSize
                        icon.source: "qrc:/qmlimages/camera_photo.svg"
                        icon.color: "white"
                        icon.width: width * 0.58
                        icon.height: height * 0.58
                        display: AbstractButton.IconOnly
                        background: Rectangle {
                            radius: width / 2
                            color: parent.pressed ? videoRoot._controlPressedColor
                                                  : (parent.hovered ? videoRoot._controlHoverColor : videoRoot._controlBaseColor)
                            border.color: videoRoot._controlBorderColor
                            border.width: 1
                        }
                    }

                    RoundButton {
                        id: videoSettingsButton
                        width: videoRoot._rightControlButtonSize
                        height: videoRoot._rightControlButtonSize
                        icon.source: "qrc:/qmlimages/Gears.svg"
                        icon.color: "white"
                        icon.width: width * 0.58
                        icon.height: height * 0.58
                        display: AbstractButton.IconOnly
                        onClicked: videoSettingsPopup.open()
                        background: Rectangle {
                            radius: width / 2
                            color: parent.pressed ? videoRoot._controlPressedColor
                                                  : (parent.hovered ? videoRoot._controlHoverColor : videoRoot._controlBaseColor)
                            border.color: videoRoot._controlBorderColor
                            border.width: 1
                        }
                    }
                }
            }

            Item {
                id: gimbalPad
                anchors.fill: parent

                RoundButton {
                    id: gimbalUp
                    width: videoRoot._directionButtonSize; height: videoRoot._directionButtonSize
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: -parent.height * 0.3
                    text: "▲"
                    background: Rectangle {
                        anchors.fill: parent
                        color: "transparent"
                        border.width: 0
                        radius: 0
                    }
                    contentItem: Text {
                        text: gimbalUp.text
                        anchors.centerIn: parent
                        color: (gimbalUp.pressed || gimbalUp.down) ? "#cccccc" : "white"
                        font.pixelSize: 14
                    }
                    scale: pressed ? 0.92 : 1.0
                    Behavior on scale { NumberAnimation { duration: 90 } }
                }

                RoundButton {
                    id: gimbalLeft
                    width: videoRoot._directionButtonSize; height: videoRoot._directionButtonSize
                    anchors.left: parent.left
                    anchors.leftMargin: parent.width * 0.3
                    anchors.verticalCenter: parent.verticalCenter
                    text: "◀"
                    background: Rectangle {
                        anchors.fill: parent
                        color: "transparent"
                        border.width: 0
                        radius: 0
                    }
                    contentItem: Text {
                        text: gimbalLeft.text
                        anchors.centerIn: parent
                        color: (gimbalLeft.pressed || gimbalLeft.down) ? "#cccccc" : "white"
                        font.pixelSize: 14
                    }
                    scale: pressed ? 0.92 : 1.0
                    Behavior on scale { NumberAnimation { duration: 90 } }
                }

                RoundButton {
                    id: gimbalRight
                    width: videoRoot._directionButtonSize; height: videoRoot._directionButtonSize
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.rightMargin: parent.width * 0.3
                    text: "▶"
                    background: Rectangle {
                        anchors.fill: parent
                        color: "transparent"
                        border.width: 0
                        radius: 0
                    }
                    contentItem: Text {
                        text: gimbalRight.text
                        anchors.centerIn: parent
                        color: (gimbalRight.pressed || gimbalRight.down) ? "#cccccc" : "white"
                        font.pixelSize: 14
                    }
                    scale: pressed ? 0.92 : 1.0
                    Behavior on scale { NumberAnimation { duration: 90 } }
                }

                RoundButton {
                    id: gimbalDown
                    width: videoRoot._directionButtonSize
                    height: videoRoot._directionButtonSize
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: +parent.height * 0.3
                    text: "▼"
                    background: Rectangle {
                        anchors.fill: parent
                        color: "transparent"
                        border.width: 0
                        radius: 0
                    }
                    contentItem: Text {
                        text: gimbalDown.text
                        anchors.centerIn: parent
                        color: (gimbalDown.pressed || gimbalDown.down) ? "#cccccc" : "white"
                        font.pixelSize: 14
                    }
                    scale: pressed ? 0.92 : 1.0
                    Behavior on scale { NumberAnimation { duration: 90 } }
                }
            }
        }
    }

    Popup {
        id: videoSettingsPopup
        parent: videoRoot
        modal: false
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

            Label {
                text: qsTr("비디오 설정")
                color: "white"
                font.pixelSize: 13
            }

            ComboBox {
                width: parent.width
                model: ["720p", "1080p"]
            }

            ComboBox {
                width: parent.width
                model: ["24 FPS", "30 FPS", "60 FPS"]
            }

            ComboBox {
                width: parent.width
                model: ["2 Mbps", "4 Mbps", "8 Mbps"]
            }
        }
    }

    readonly property bool _showConnectingState: mediaPlayer.mediaStatus !== MediaPlayer.BufferedMedia &&
                                                 mediaPlayer.mediaStatus !== MediaPlayer.LoadedMedia

    BusyIndicator {
        anchors.centerIn: parent
        visible: videoRoot._showConnectingState
        running: visible
    }

    Text {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.leftMargin: 8
        anchors.topMargin: 8
        visible: videoRoot._showConnectingState
        text: (selectedStation === "" ? "카메라" : selectedStation) + " 연결 확인 중..."
        color: "#aaa"
        font.pixelSize: 11
    }

    MediaPlayer {
        id: mediaPlayer
        videoOutput: videoOutput
        source: videoRoot.rtspSource
        audioOutput: AudioOutput { muted: true }

        onMediaStatusChanged: {
            if (mediaStatus === MediaPlayer.InvalidMedia || mediaStatus === MediaPlayer.NoMedia)
                reconnectTimer.restart()
        }

        onErrorOccurred: (error, errorString) => reconnectTimer.start()
    }

    Timer {
        id: reconnectTimer
        interval: 3000
        repeat: false
        onTriggered: _applySourceAndPlay()
    }

    Component.onCompleted: Qt.callLater(_applySourceAndPlay)
}
