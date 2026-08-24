import QtQuick 6.8
import QGroundControl
import QGroundControl.Toolbar

// 드론 비디오 타일. 공용 VideoTile에 드론 전용 값만 주입하는 얇은 래퍼.
// 공개 API(deviceName 등 + VideoTile의 모든 프로퍼티/시그널)는 그대로 유지된다.
VideoTile {
    id: droneVideo

    /// [기존 API 유지] 드론 목록 선택값. 변경 시 세션 재연결.
    property string deviceName: ""

    title: qsTr("드론 비디오")
    logTag: "DroneVideo"
    selectionToken: deviceName
    selectionLabel: deviceName
    // raw URL — transport는 rtpTransport가 붙인다(resolved* 에 tcp가 박히면 암호 OFF 평문 재생이 깨짐).
    fallbackUrl: (typeof QGroundControl !== "undefined" && QGroundControl.videoEndpointSettings)
        ? QGroundControl.videoEndpointSettings.droneUrl
        : "rtsp://127.0.0.1:8554/live"
    // 암호 on: interleaved TCP 필수. 암호 off: 일반 RTSP(ini, 기본 udp).
    rtpTransport: {
        if (typeof QGroundControl === "undefined")
            return "udp"
        if (QGroundControl.videoCryptoSettings && QGroundControl.videoCryptoSettings.enabled)
            return "tcp"
        return QGroundControl.videoEndpointSettings
            ? QGroundControl.videoEndpointSettings.droneRtpTransport
            : "udp"
    }
    // 암호 on/off·일반/고속 모두 AppSettings > Video Crypto SSoT.
    cryptoEnabled: (typeof QGroundControl !== "undefined" && QGroundControl.videoCryptoSettings)
        ? QGroundControl.videoCryptoSettings.enabled
        : false
    cryptoMode: (typeof QGroundControl !== "undefined" && QGroundControl.videoCryptoSettings)
        ? QGroundControl.videoCryptoSettings.speedMode
        : "normal"
}
