import QtQuick 6.8
import QtQuick.Controls 6.8
import QtMultimedia 6.8

Rectangle {
    id: videoRoot
    implicitWidth: 350
    implicitHeight: width * 0.75
    color: "#1a1a1a" // 배경을 조금 더 어둡게 처리
    border.color: "#333"
    radius: 4

    property string selectedStation: ""
    property var backend: null

    readonly property string rtspSource: (backend && backend.rtspUrl) ?
                                              backend.rtspUrl :
                                              "rtsp://127.0.0.1:8554/live"

    // 1. 영상 출력 레이어 (가장 아래)
    VideoOutput {
        id: videoOutput
        anchors.fill: parent
        anchors.margins: 2
        fillMode: VideoOutput.PreserveAspectFit

        // 영상이 없을 때만 보이는 검은 화면
        Rectangle {
            anchors.fill: parent
            color: "black"
            visible: mediaPlayer.mediaStatus < MediaPlayer.BufferedMedia
        }
    }

    // 2. 상태 표시 레이어 (영상 위에 표시)
    Column {
        anchors.centerIn: parent
        spacing: 12
        // 로딩 중이거나 에러 상태일 때만 표시
        visible: mediaPlayer.mediaStatus !== MediaPlayer.BufferedMedia &&
                 mediaPlayer.mediaStatus !== MediaPlayer.LoadedMedia

        BusyIndicator {
            anchors.horizontalCenter: parent.horizontalCenter
            running: parent.visible
        }

        Text {
            // deviceName이 비어있으면 "카메라"로 표시
            text: (selectedStation === "" ? "카메라" : selectedStation) + " 연결 확인 중..."
            color: "#aaa"
            font.pixelSize: 11
            anchors.horizontalCenter: parent.horizontalCenter
            // Column 자식은 top/bottom/verticalCenter 사용 불가 → 제거
        }
    }

    // 3. 미디어 엔진
    MediaPlayer {
        id: mediaPlayer
        videoOutput: videoOutput
        source: videoRoot.rtspSource
        audioOutput: AudioOutput { muted: true } // 드론 영상은 보통 소음이라 뮤트 필수

        onMediaStatusChanged: {
            if (mediaStatus === MediaPlayer.InvalidMedia || mediaStatus === MediaPlayer.NoMedia)
                reconnectTimer.restart()
        }

        onErrorOccurred: (error, errorString) => reconnectTimer.start()
    }

    // 재연결 타이머 (이름 통일)
    Timer {
        id: reconnectTimer
        interval: 3000
        repeat: false
        onTriggered: {
            mediaPlayer.stop()
            mediaPlayer.play()
        }
    }

    Component.onCompleted: mediaPlayer.play()
}
